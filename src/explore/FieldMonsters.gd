class_name FieldMonsters
extends RefCounted
## 탐험 맵 위의 몬스터 무리(순수 로직): 지역별 스폰, 리스폰, 머문 시간에 따른 증가, 배회·추적·영역 이탈, 접촉.
## 무리 하나 = 지도 한 칸을 차지하는 대표 + 구성(몬스터 id 목록). 접촉하면 무리 전체와 전투한다.
## 몬스터는 게임 시간에 따라 움직인다. 탐험 시간은 실시간으로 흐르므로(RealtimeDriver) 플레이어가 가만히 있어도 움직인다.

signal changed

const STATE_IDLE := "idle"
const STATE_CHASE := "chase"
const STATE_RETURN := "return"


class Group extends RefCounted:
	var id: int = 0
	var monster_ids: Array[String] = []
	var region: String = ""
	var pos: Vector2i
	var home: Vector2i
	var state: String = "idle"
	var budget: float = 0.0
	var grace_until: float = -1.0

	func leader() -> String:
		return monster_ids[0] if not monster_ids.is_empty() else ""


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


func _init(db: GameDatabase, map: FloorMap, floor_def: Dictionary, rng: Rng) -> void:
	_db = db
	_map = map
	_floor_def = floor_def
	_rng = rng
	_mpt = maxf(0.01, float(db.bal("explore.meters_per_tile", 1.0)))
	var keep_out := 3.0
	for z: Dictionary in map.safe_zones:
		keep_out = maxf(keep_out, float(z["radius"]) + 3.0)
	for region in _regions():
		var cells: Array[Vector2i] = []
		for i in map.tiles.size():
			var p := map.pos_of(i)
			if map.is_walkable(p) and map.portal_at(p).is_empty() and Vector2(p - map.center).length() > keep_out \
					and _direction_of(p - map.center) == JsonUtil.get_str(region, "dir"):
				cells.append(p)
		_region_cells[JsonUtil.get_str(region, "id")] = cells


func spawn_initial(avoid: Vector2i) -> void:
	var range_ := JsonUtil.get_array(_spawn(), "groups_per_region")
	for region in _regions():
		if JsonUtil.get_array(region, "monsters").is_empty():
			continue
		var n := _rng.randi_range(int(range_[0]), int(range_[1])) if range_.size() == 2 else 1
		for i in n:
			spawn_group(region, avoid)
	changed.emit()


## 지역의 몬스터로 무리를 만든다. near가 주어지면 그 옆 칸에(습격·디버그), 아니면 지역 안 무작위 칸에.
func spawn_group(region: Dictionary, avoid: Vector2i, near: Vector2i = Vector2i(-1, -1), monster_id: String = "") -> Group:
	var mid := monster_id if not monster_id.is_empty() else str(_rng.pick(JsonUtil.get_array(region, "monsters")))
	var cell := _free_cell_near(near) if near.x >= 0 else _free_region_cell(JsonUtil.get_str(region, "id"), avoid)
	if cell.x < 0 or not _db.has_entry("monsters", mid):
		return null
	var g := Group.new()
	g.id = _next_id
	_next_id += 1
	var pack := JsonUtil.get_array(JsonUtil.get_dict(_db.get_entry("monsters", mid), "behavior"), "pack_size")
	for i in (_rng.randi_range(int(pack[0]), int(pack[1])) if pack.size() == 2 else 1):
		g.monster_ids.append(mid)
	g.region = JsonUtil.get_str(region, "id")
	g.pos = cell
	g.home = cell
	groups.append(g)
	return g


func group_at(p: Vector2i) -> Group:
	for g in groups:
		if g.pos == p:
			return g
	return null


## 쓰러뜨린 무리: 지도에서 지우고, 정해진 시간 뒤 같은 지역에 다시 나타난다.
func remove(g: Group, now: float) -> void:
	groups.erase(g)
	_respawns.append({"region": g.region, "at": now + JsonUtil.get_float(_spawn(), "respawn_hours", 24.0)})
	changed.emit()


## 플레이어가 도망친 무리: 잠시 쫓지 않고 제자리로 돌아간다.
func set_grace(g: Group, now: float) -> void:
	g.grace_until = now + float(_db.bal("combat.flee_grace_hours", 0.5))
	g.state = STATE_RETURN


## 시간이 hours만큼 흘렀다. 몬스터를 움직이고, 플레이어에게 붙은 무리가 있으면 돌려준다(전투 시작).
func update(player: Vector2i, hours: float, now: float, player_safe: bool) -> Group:
	_process_respawns(player, now)
	var field := _distance_field(player)
	var max_moves := int(_db.bal("monsters.update_max_moves", 12))
	var moved := false
	for g in groups:
		var mh := _move_hours(g.leader())
		g.budget += hours / mh
		var moves := mini(floori(g.budget), max_moves)
		g.budget = 0.0 if floori(g.budget) > max_moves else g.budget - moves
		_decide(g, player, now)
		for i in moves:
			if _adjacent(g.pos, player) and g.state == STATE_CHASE:
				break
			if _step(g, player, field):
				moved = true
		_decide(g, player, now)
	if moved:
		changed.emit()
	if player_safe:
		return null
	for g in groups:
		if _adjacent(g.pos, player) and g.grace_until <= now and (g.state == STATE_CHASE or _aggressive(g.leader())):
			return g
	return null


## 휴식 중 습격: 플레이어 옆에 무리를 만든다(플레이어가 있는 방향의 지역 몬스터).
func ambush_near(player: Vector2i) -> Group:
	var dir := _direction_of(player - _map.center)
	var choices: Array = []
	for region in _regions():
		if not JsonUtil.get_array(region, "monsters").is_empty():
			choices.append(region)
			if JsonUtil.get_str(region, "dir") == dir:
				choices = [region]
				break
	if choices.is_empty():
		return null
	var g := spawn_group(_rng.pick(choices), player, player)
	if g != null:
		g.state = STATE_CHASE
		changed.emit()
	return g


## 플레이어에게 보이는가: 지금 보이는 칸이고, 은신(reveal_radius_m)이면 그 거리 안.
func is_visible(g: Group, player: Vector2i) -> bool:
	if _map.visible_now[_map.idx(g.pos)] == 0:
		return false
	var reveal := JsonUtil.get_float(_behavior(g.leader()), "reveal_radius_m")
	return reveal <= 0.0 or Vector2(g.pos - player).length() * _mpt <= reveal


func region_cells(region_id: String) -> Array[Vector2i]:
	if _region_cells.has(region_id):
		return _region_cells[region_id]
	var empty: Array[Vector2i] = []
	return empty


# ── 내부 ─────────────────────────────────────────────────

func _decide(g: Group, player: Vector2i, now: float) -> void:
	var leash := JsonUtil.get_int(_behavior(g.leader()), "leash_tiles")
	if g.grace_until > now:
		g.state = STATE_RETURN
	elif leash > 0 and Vector2(g.pos - g.home).length() > leash:
		g.state = STATE_RETURN
	elif _notices(g, player):
		g.state = STATE_CHASE
	elif g.state == STATE_CHASE:
		g.state = STATE_RETURN
	if g.state == STATE_RETURN and g.pos == g.home:
		g.state = STATE_IDLE


func _notices(g: Group, player: Vector2i) -> bool:
	var radius := JsonUtil.get_float(_behavior(g.leader()), "aggro_radius_m", 4.0) / _mpt
	return Vector2(g.pos - player).length() <= radius and _line_of_sight(g.pos, player)


## 한 칸 움직인다. 추적: 플레이어까지의 거리 장을 따라 내려간다. 귀환: 집 쪽으로. 대기: 가끔 배회.
func _step(g: Group, player: Vector2i, field: Dictionary) -> bool:
	var best := g.pos
	match g.state:
		STATE_CHASE:
			var here: int = field.get(g.pos, 1 << 20)
			for d in FloorMap.DIRS4:
				var q := g.pos + d
				if q != player and _can_enter(q) and int(field.get(q, 1 << 20)) < here:
					here = field[q]
					best = q
		STATE_RETURN:
			for d in FloorMap.DIRS4:
				var q := g.pos + d
				if _can_enter(q) and (q - g.home).length_squared() < (best - g.home).length_squared():
					best = q
		_:
			if _rng.chance(float(_db.bal("monsters.wander_chance", 0.3))):
				var q := g.pos + FloorMap.DIRS4[_rng.randi_range(0, 3)]
				if _can_enter(q) and Vector2(q - g.home).length() <= float(_db.bal("monsters.wander_radius", 4)):
					best = q
	if best == g.pos:
		return false
	g.pos = best
	return true


func _can_enter(p: Vector2i) -> bool:
	return _map.is_walkable(p) and not _map.in_safe_zone(p) and group_at(p) == null


## 플레이어에서 시작하는 걸음 수 장(BFS). 몬스터는 안전지대에 들어가지 못한다.
func _distance_field(player: Vector2i) -> Dictionary:
	var field := {player: 0}
	var queue: Array[Vector2i] = [player]
	var radius := int(_db.bal("monsters.chase_path_radius", 24))
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		var d: int = field[p]
		if d >= radius:
			continue
		for dir in FloorMap.DIRS4:
			var q := p + dir
			if not field.has(q) and _map.is_walkable(q) and not _map.in_safe_zone(q):
				field[q] = d + 1
				queue.append(q)
	return field


func _line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(1, n):
		var p := Vector2i(Vector2(a).lerp(Vector2(b), float(i) / n).round())
		if _map.blocks_sight(p):
			return false
	return true


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
			spawn_group(_rng.pick(regions), player)
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
			if _can_enter(q):
				return q
	return Vector2i(-1, -1)


func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


func _move_hours(monster_id: String) -> float:
	var agi := JsonUtil.get_float(JsonUtil.get_dict(_db.get_entry("monsters", monster_id), "stats"), "agi")
	return maxf(0.0001, float(_db.bal("explore.move_hours_base", 0.02)) / (1.0 + agi * float(_db.bal("explore.move_agi_coef", 0.02))))


func _aggressive(monster_id: String) -> bool:
	return JsonUtil.get_bool(_behavior(monster_id), "aggressive", true)


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


static func _direction_of(d: Vector2i) -> String:
	if absi(d.x) >= absi(d.y):
		return "east" if d.x > 0 else "west"
	return "south" if d.y > 0 else "north"
