class_name FieldMonsters
extends RefCounted
## 탐험 맵 위의 몬스터 무리(순수 로직): 지역별 스폰, 리스폰, 머문 시간에 따른 증가, 배회·추적·영역 이탈, 접촉.
## 무리 하나 = 대표 하나(연속 좌표 fpos, 칸 단위) + 구성(몬스터 id 목록). 닿으면(contact_tiles) 무리 전체와 전투한다.
## 이동은 부드럽다: 칸 길찾기(거리 장·귀환·배회)로 다음 칸 중심(waypoint)을 정하고 그쪽으로 연속으로 걷는다.
## 플레이어가 direct_chase_tiles 안에서 보이면 곧장 플레이어 쪽으로 다가가 닿는 거리에서 멈춘다.
## 지역(regions): {"id", "zone" 또는 "dir", "monsters", "weights": {id: 가중치}} — 몬스터 표는 층 JSON에만 둔다.
##   zone이 있고 지도에 구역 층(FloorMap.zones)이 있으면 그 구역 칸에만(1층 십자가), 없으면 중심에서 본 방향(dir) 원뿔.
## 변이종(명세 §6.0): 지역 variants {monsters, min_day, outer_ratio, chance} — min_day일 차부터 지역 바깥쪽
## (중심에서 지역 최대 거리의 outer_ratio 이상, 2층 포탈 쪽)에 생긴 무리의 각 마리가 chance 확률로 변이종이 된다.
## 몬스터는 게임 시간에 따라 움직인다. 탐험 시간은 실시간으로 흐르므로(RealtimeDriver) 플레이어가 가만히 있어도 움직인다.

signal changed

const STATE_IDLE := "idle"
const STATE_CHASE := "chase"
const STATE_RETURN := "return"


class Group extends RefCounted:
	var id: int = 0
	var monster_ids: Array[String] = []
	var region: String = ""
	var pos: Vector2i                    ## 몸 중심이 있는 칸
	var fpos: Vector2 = Vector2.ZERO      ## 몸 중심의 연속 좌표
	var home: Vector2i
	var state: String = "idle"
	var grace_until: float = -1.0
	var alert_until: float = -1.0          ## 이 시각까지는 보지 못해도 플레이어를 쫓는다(노움 은닉처를 건드렸다 — FieldFeatureAct)
	var waypoint: Vector2 = Vector2(-1, -1)  ## 걸어가는 중인 칸 중심(없으면 x < 0)
	var tag: String = ""                  ## 균열 조우 종류(battle/chain/waves/guardian), 필드 무리는 ""
	var waves: Array = []                 ## 연전: 이기면 바로 이어지는 다음 구성들(몬스터 id 배열)
	var battle_rules: Dictionary = {}     ## 전투 목표(BattleObjective — 생존 웨이브)
	var boss: String = ""                 ## 방에서 기다리는 보스·중간보스(구성이나 연전에 있으면) — 움직이지 않고, 가까이 오면 바로 전투
	var route: Array[Vector2i] = []       ## 멀리 걸어갈 길(send_to — 대기 중에 따라 걷는다)
	var scent: Vector2i = Vector2i(-1, -1)  ## 쫓는 냄새 칸(behavior tracks_scent — 플레이어가 멀면 이쪽으로)
	var party: Dictionary = {}            ## 탐험가 무리(FieldParties): {"kind", …} — 비어 있으면 몬스터 무리

	func leader() -> String:
		return monster_ids[0] if not monster_ids.is_empty() else ""

	## 몬스터 무리이거나 통행세를 받지 않은 약탈자(닿으면 싸움이 된다). 다른 탐험가 무리는 false.
	func hostile() -> bool:
		return party.is_empty() or (str(party.get("kind", "")) == "raider" and not bool(party.get("paid", false)))

	## 칸 cell의 중심에 세운다(스폰·테스트).
	func place(cell: Vector2i) -> void:
		pos = cell
		fpos = Kinematics.center_of(cell)
		waypoint = Vector2(-1, -1)


var groups: Array[Group] = []

var _db: GameDatabase
var _map: FloorMap
var _floor_def: Dictionary
var _rng: Rng
var _region_cells: Dictionary = {}  # 지역 id -> Array[Vector2i]
var _respawns: Array[Dictionary] = []  # {"region": id, "at": 시각}
var _extra_added: int = 0
var _next_id: int = 1
var _mpt: float = 1.0
var _steer: MonsterSteering
var _now: float = 0.0
var _region_far: Dictionary = {}  # 지역 id -> 중심에서 가장 먼 칸까지의 거리
var _active: float = 0.0  # monsters.active_radius_tiles(0 = 모두 움직임)


func _init(db: GameDatabase, map: FloorMap, floor_def: Dictionary, rng: Rng) -> void:
	_db = db
	_map = map
	_floor_def = floor_def
	_rng = rng
	_mpt = maxf(0.01, float(db.bal("explore.meters_per_tile", 1.0)))
	_active = float(db.bal("monsters.active_radius_tiles", 0))
	_steer = MonsterSteering.new(db, map, rng, groups)
	var keep_out := 3.0
	for z: Dictionary in map.safe_zones:
		keep_out = maxf(keep_out, float(z["radius"]) + 3.0)
	# 지도를 한 번만 훑어 구역(area)별로 칸을 모은다(큰 지도에서 지역마다 다시 훑지 않게).
	var by_area := {}
	for region in _regions():
		var bucket: Array[Vector2i] = []
		by_area[_region_area(region)] = bucket
	for i in map.tiles.size():
		if not map.defs[map.tiles[i]].walkable:
			continue
		var p := map.pos_of(i)
		var area := _area_of(p)
		if by_area.has(area) and Vector2(p - map.center).length() > keep_out and map.portal_at(p).is_empty():
			var into: Array[Vector2i] = by_area[area]
			into.append(p)
	for region in _regions():
		var found: Array[Vector2i] = by_area[_region_area(region)]
		var cells: Array[Vector2i] = found.duplicate()
		_region_cells[JsonUtil.get_str(region, "id")] = cells
		var far := 0.0
		for c in cells:
			far = maxf(far, Vector2(c - map.center).length())
		_region_far[JsonUtil.get_str(region, "id")] = far


func spawn_initial(avoid: Vector2i) -> void:
	var range_ := JsonUtil.get_array(_spawn(), "groups_per_region")
	var cluster := JsonUtil.get_dict(_spawn(), "cluster")
	for region in _regions():
		if JsonUtil.get_array(region, "monsters").is_empty():
			continue
		var n := _rng.randi_range(int(range_[0]), int(range_[1])) if range_.size() == 2 else 1
		for i in n:
			var spot := FieldSpawnBias.cluster_spot(_map, _rng, cluster, region, avoid,
				func(p: Vector2i) -> bool: return _area_of(p) == _region_area(region))
			if spot.is_empty() or spawn_group(region, avoid, spot["cell"], str(spot["monster"])) == null:
				spawn_group(region, avoid)
	changed.emit()


## 지역의 몬스터로 무리를 만든다. near가 주어지면 그 옆 칸에(습격·디버그), 아니면 지역 안 무작위 칸에.
func spawn_group(region: Dictionary, avoid: Vector2i, near: Vector2i = Vector2i(-1, -1), monster_id: String = "") -> Group:
	var mid := monster_id if not monster_id.is_empty() else pick_monster(region)
	var cell := _free_cell_near(near) if near.x >= 0 else _free_region_cell(JsonUtil.get_str(region, "id"), avoid)
	if cell.x < 0 or not _db.has_entry("monsters", mid):
		return null
	var g := Group.new()
	g.id = _next_id
	_next_id += 1
	var pack := JsonUtil.get_array(JsonUtil.get_dict(_db.get_entry("monsters", mid), "behavior"), "pack_size")
	for i in (_rng.randi_range(int(pack[0]), int(pack[1])) if pack.size() == 2 else 1):
		g.monster_ids.append(mid)
	if monster_id.is_empty():
		_mix_variants(g, region, cell)
	g.region = JsonUtil.get_str(region, "id")
	g.place(cell)
	g.home = cell
	groups.append(g)
	return g


## 정해진 구성의 무리를 칸 cell 근처에 세운다(균열 고정 조우). 지역이 없어 리스폰하지 않는다.
func add_fixed(ids: Array, cell: Vector2i) -> Group:
	var at := cell if _steer.can_enter(cell) else _free_cell_near(cell)
	if at.x < 0 or ids.is_empty():
		return null
	var g := Group.new()
	g.id = _next_id
	_next_id += 1
	for id: Variant in ids:
		g.monster_ids.append(str(id))
	g.place(at)
	g.home = at
	mark_boss(g)
	groups.append(g)
	changed.emit()
	return g


## 탐험가 무리(FieldParties)를 cell 근처에 세운다. ids = 전투 구성(약탈자) — 싸우지 않는 무리는 빈 배열.
func add_party(ids: Array, cell: Vector2i, party: Dictionary) -> Group:
	var at := cell if _steer.can_enter(cell) else _free_cell_near(cell)
	if at.x < 0:
		return null
	var g := Group.new()
	g.id = _next_id
	_next_id += 1
	for id: Variant in ids:
		g.monster_ids.append(str(id))
	g.party = party
	g.place(at)
	g.home = at
	groups.append(g)
	changed.emit()
	return g


## 구성·연전에 보스 등급(balance monsters.boss_ranks) 몬스터가 있으면 그 무리는 보스가 기다리는 방이다(맵 그림도 보스).
func mark_boss(g: Group) -> void:
	var ranks: Array = _db.bal("monsters.boss_ranks", [])
	var all: Array = g.monster_ids.duplicate()
	for w: Variant in g.waves:
		if w is Array:
			all.append_array(w)
	g.boss = ""
	for id: Variant in all:
		if ranks.has(JsonUtil.get_str(_db.get_entry("monsters", str(id)), "rank")):
			g.boss = str(id)
			return


func group_at(p: Vector2i) -> Group:
	for g in groups:
		if g.pos == p:
			return g
	return null


## 쓰러뜨린 무리: 지도에서 지우고, 정해진 시간 뒤 같은 지역에 다시 나타난다.
func remove(g: Group, now: float) -> void:
	groups.erase(g)
	if not g.region.is_empty():  # 지역 무리만 다시 나타난다(균열 고정 조우·탐험가 무리는 아니다)
		_respawns.append({"region": g.region, "at": now + JsonUtil.get_float(_spawn(), "respawn_hours", 24.0)})
	changed.emit()


## 플레이어가 도망친 무리: 잠시 쫓지 않고 제자리로 돌아간다.
func set_grace(g: Group, now: float) -> void:
	g.grace_until = now + float(_db.bal("combat.flee_grace_hours", 0.5))
	g.state = STATE_RETURN


## 시간이 hours만큼 흘렀다. 몬스터를 움직이고, 플레이어(연속 좌표 player)에 닿은 무리가 있으면 돌려준다(전투 시작).
func update(player: Vector2, hours: float, now: float, player_safe: bool) -> Group:
	_now = now
	var pcell := Kinematics.cell_of(player)
	_process_respawns(pcell, now)
	var max_moves := float(_db.bal("monsters.update_max_moves", 12))
	var moved := false
	var near: Array[Group] = []
	for g in groups:
		if not is_awake(g, pcell):
			continue  # 멀리(시야·화면 밖) 있는 무리는 쉰다 — 큰 지도에서 계산량이 무리 수에 비례해 늘지 않게
		near.append(g)
		var budget := minf(hours / _steer.move_hours(g.leader()), max_moves)
		_steer.decide(g, pcell, now)
		if budget > 0.0 and _steer.walk(g, player, pcell, budget):
			moved = true
		_steer.decide(g, pcell, now)
	if moved:
		changed.emit()
	if player_safe:
		return null
	var boss_engage := float(_db.bal("monsters.boss_engage_tiles", 3.5))
	for g in near:  # 쉬는 무리는 멀어서 닿을 수 없다
		if g.grace_until > now or not g.hostile():
			continue
		if g.boss != "":  # 보스: 방에 들어와 보이는 거리면 바로
			if g.fpos.distance_to(player) <= boss_engage and _steer.sees(g.pos, pcell):
				return g
		elif _steer.in_contact(g, player) and (g.state == STATE_CHASE or _aggressive(g.leader())):
			return g
	return null


## 플레이어 칸 pcell 둘레 monsters.active_radius_tiles 안이라 움직이는 무리인가(0 = 모두).
func is_awake(g: Group, pcell: Vector2i) -> bool:
	return _active <= 0.0 or (g.pos - pcell).length_squared() <= _active * _active


## 플레이어가 delta 쪽으로 움직이려 할 때 닿아 있고 그쪽으로 다가가는 무리(플레이어가 먼저 건 전투).
func touching(player: Vector2, delta: Vector2) -> Group:
	for g in groups:
		if not g.party.is_empty() and g.grace_until > _now:
			continue  # 방금 이야기를 나눈 탐험가 무리 — 바로 다시 말을 걸지 않는다
		if _steer.in_contact(g, player) and (g.fpos - player).dot(delta) > 0.0:
			return g
	return null


## 휴식 중 습격: 플레이어 옆에 무리를 만든다(플레이어가 있는 구역·방향의 지역 몬스터).
func ambush_near(player: Vector2i) -> Group:
	var area := _area_of(player)
	var choices: Array = []
	for region in _regions():
		if not JsonUtil.get_array(region, "monsters").is_empty():
			choices.append(region)
			if _region_area(region) == area:
				choices = [region]
				break
	if choices.is_empty():
		return null
	var g := spawn_group(_rng.pick(choices), player, player)
	if g != null:
		g.state = STATE_CHASE
		changed.emit()
	return g


## 지역 몬스터 표에서 하나(weights 가중치, 없으면 같은 확률).
func pick_monster(region: Dictionary) -> String:
	var list := JsonUtil.get_array(region, "monsters")
	var wt := JsonUtil.get_dict(region, "weights")
	if wt.is_empty():
		return str(_rng.pick(list))
	var weights: Array = []
	for id: Variant in list:
		weights.append(JsonUtil.get_float(wt, str(id), 1.0))
	var k := _rng.weighted_index(weights)
	return str(list[k]) if k >= 0 else ""


## 플레이어에게 보이는가: 지금 보이는 칸이고, 은신(reveal_radius_m)이면 그 거리 안.
func is_visible(g: Group, player: Vector2i) -> bool:
	if _map.visible_now[_map.idx(g.pos)] == 0:
		return false
	var reveal := JsonUtil.get_float(_behavior(g.leader()), "reveal_radius_m")
	return reveal <= 0.0 or Vector2(g.pos - player).length() * _mpt <= reveal


## 무리를 cell로 보낸다(그곳이 새 집). 플레이어 곁(깨어 있음)이면 길을 따라 걸어가고, 멀리 쉬는 무리는 바로 옮긴다.
func send_to(g: Group, cell: Vector2i, pcell: Vector2i) -> void:
	g.home = cell
	g.waypoint = Vector2(-1, -1)
	if not is_awake(g, pcell):
		var at := cell if _steer.can_enter(cell, g) else _free_cell_near(cell)
		if at.x >= 0:
			g.place(at)
			g.home = at
		g.route.clear()
		return
	g.route = FieldRoutes.path(_map, g.pos, cell, int(_db.bal("monsters.route_radius", 90)))
	g.state = STATE_IDLE


## 플레이어가 지나온 칸 [[칸, 시각], …](오래된 것이 앞). 냄새를 쫓는 몬스터(behavior tracks_scent)가 쓴다.
func set_player_trail(trail: Array) -> void:
	_steer.player_trail = trail


func region_cells(region_id: String) -> Array[Vector2i]:
	if _region_cells.has(region_id):
		return _region_cells[region_id]
	var empty: Array[Vector2i] = []
	return empty


func set_player_stealth(v: float) -> void:
	_steer.player_stealth = v


## 플레이어에게 걸린 상태(원한의 징표 등). ExploreSession이 시간 흐름마다 넣는다.
func set_player_marks(ids: Array) -> void:
	_steer.player_marks = ids


## 지금 시각(미궁 n일 차)과 칸 위치로 무리에 변이종을 섞는다.
func _mix_variants(g: Group, region: Dictionary, cell: Vector2i) -> void:
	var v := JsonUtil.get_dict(region, "variants")
	var list := JsonUtil.get_array(v, "monsters")
	if list.is_empty() or floori(_now / 24.0) + 1 < JsonUtil.get_int(v, "min_day", 3):
		return
	var far := float(_region_far.get(g.region, 0.0))
	if Vector2(cell - _map.center).length() < far * JsonUtil.get_float(v, "outer_ratio", 0.5):
		return
	for i in g.monster_ids.size():
		if _rng.chance(JsonUtil.get_float(v, "chance", 0.2)):
			g.monster_ids[i] = str(_rng.pick(list))


# ── 내부 ─────────────────────────────────────────────────

func _process_respawns(player: Vector2i, now: float) -> void:
	var due: Array[Dictionary] = []
	for r in _respawns:
		if float(r["at"]) <= now:
			due.append(r)
	for r in due:
		_respawns.erase(r)
		spawn_group(_region(str(r["region"])), player)
	var every := JsonUtil.get_float(_spawn(), "growth_every_hours", 24.0)
	var target := mini(JsonUtil.get_int(_spawn(), "max_extra_groups"), floori(now / maxf(1.0, every)))
	while _extra_added < target:
		_extra_added += 1
		var regions := _regions().filter(func(r: Dictionary) -> bool: return not JsonUtil.get_array(r, "monsters").is_empty())
		if not regions.is_empty():
			spawn_group(_rng.pick(regions), player, Vector2i(-1, -1), FieldSpawnBias.growth_monster(_db, _rng, _spawn(), now))
	if not due.is_empty():
		changed.emit()


func _free_region_cell(region_id: String, avoid: Vector2i) -> Vector2i:
	var cells := region_cells(region_id)
	var min_dist := float(_db.bal("monsters.spawn_min_dist_from_entry", 10))
	for attempt in 40:
		if cells.is_empty():
			break
		var p: Vector2i = _rng.pick(cells)
		if group_at(p) == null and Vector2(p - avoid).length() >= min_dist:
			return p
	return Vector2i(-1, -1)


func _free_cell_near(p: Vector2i) -> Vector2i:
	for r in range(1, 4):
		for d in FloorMap.DIRS4:
			var q := p + d * r
			if _steer.can_enter(q):
				return q
	return Vector2i(-1, -1)


func _aggressive(monster_id: String) -> bool:
	var beh := _behavior(monster_id)
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	if not need.is_empty() and _steer.player_marks.has(need):
		return true
	return JsonUtil.get_bool(beh, "aggressive", true)


func _behavior(monster_id: String) -> Dictionary:
	return JsonUtil.get_dict(_db.get_entry("monsters", monster_id), "behavior")


func _spawn() -> Dictionary:
	return JsonUtil.get_dict(_floor_def, "spawn")


func _regions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Variant in JsonUtil.get_array(_floor_def, "regions"):
		if r is Dictionary:
			out.append(r)
	return out


func _region(id: String) -> Dictionary:
	for r in _regions():
		if JsonUtil.get_str(r, "id") == id:
			return r
	return {}


## 칸이 속한 스폰 영역: 지도에 구역 층이 있으면 그 구역 id, 없으면 중심에서 본 방향.
func _area_of(p: Vector2i) -> String:
	return _map.zone_at(p) if _map.has_zones() else _direction_of(p - _map.center)


func _region_area(region: Dictionary) -> String:
	var zone := JsonUtil.get_str(region, "zone")
	return zone if not zone.is_empty() and _map.has_zones() else JsonUtil.get_str(region, "dir")


static func _direction_of(d: Vector2i) -> String:
	if absi(d.x) >= absi(d.y):
		return "east" if d.x > 0 else "west"
	return "south" if d.y > 0 else "north"
