class_name MonsterSteering
extends RefCounted
## 필드 몬스터 무리의 판단·이동(순수 로직). FieldMonsters가 가진다(이쪽은 FieldMonsters를 참조하지 않는다 → 순환 없음).
##   decide: 대기(idle) / 추적(chase: 플레이어를 알아챔) / 귀환(return: 영역 이탈·도망친 플레이어 유예)
##   walk:   칸 길찾기로 다음 칸 중심(waypoint)을 정하고 그쪽으로 연속으로 걷는다(Kinematics 충돌).
##           플레이어가 direct_chase_tiles 안에서 보이면 곧장 다가가 닿는 거리에서 멈춘다.
## 거리 장(플레이어에서 시작하는 BFS)은 플레이어 칸이 바뀔 때만 다시 만든다(매 프레임 호출 대비).

var groups: Array  ## FieldMonsters.groups (같은 배열을 공유)

var _db: GameDatabase
var _map: FloorMap
var _rng: Rng
var _mpt: float = 1.0
var _field_cell: Vector2i = Vector2i(-1, -1)
var _field: Dictionary = {}


func _init(db: GameDatabase, map: FloorMap, rng: Rng, p_groups: Array) -> void:
	_db = db
	_map = map
	_rng = rng
	groups = p_groups
	_mpt = maxf(0.01, float(db.bal("explore.meters_per_tile", 1.0)))


func decide(g: FieldMonsters.Group, player: Vector2i, now: float) -> void:
	var before := g.state
	var leash := JsonUtil.get_int(_behavior(g.leader()), "leash_tiles")
	if g.grace_until > now:
		g.state = FieldMonsters.STATE_RETURN
	elif leash > 0 and Vector2(g.pos - g.home).length() > leash:
		g.state = FieldMonsters.STATE_RETURN
	elif g.alert_until > now or _notices(g, player):
		g.state = FieldMonsters.STATE_CHASE
	elif g.state == FieldMonsters.STATE_CHASE:
		g.state = FieldMonsters.STATE_RETURN
	if g.state == FieldMonsters.STATE_RETURN and g.pos == g.home and g.waypoint.x < 0.0:
		g.state = FieldMonsters.STATE_IDLE
	if g.state != before:
		g.waypoint = Vector2(-1, -1)  # 상태가 바뀌면 새로 길을 정한다


## 플레이어 은신(FieldStealth, 0~1). FieldMonsters가 넣는다.
var player_stealth: float = 0.0
## 플레이어에게 걸린 상태 id들(벤시: behavior "passive_unless_status"가 없으면 알아채지 않고, 있으면 반경 × aggro_mult_if_status).
var player_marks: Array = []


func _notices(g: FieldMonsters.Group, player: Vector2i) -> bool:
	var beh := _behavior(g.leader())
	var radius := JsonUtil.get_float(beh, "aggro_radius_m", 4.0) / _mpt
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	if not need.is_empty():
		if not player_marks.has(need):
			return false
		radius *= JsonUtil.get_float(beh, "aggro_mult_if_status", 1.0)
	if not JsonUtil.get_bool(beh, "ignores_stealth"):
		radius *= 1.0 - player_stealth
	return Vector2(g.pos - player).length() <= radius and _line_of_sight(g.pos, player)


## 무리를 budget(칸)만큼 걷게 한다. 움직였으면 true.
func walk(g: FieldMonsters.Group, player: Vector2, pcell: Vector2i, budget: float) -> bool:
	var left := budget
	var moved := false
	var contact := float(_db.bal("monsters.contact_tiles", 1.05))
	var half := float(_db.bal("monsters.body_half_extent", 0.3))
	var direct_ok := true  # 곧장 다가가다 모서리에 막히면 이번엔 칸 길로 돌아간다
	for guard in 64:
		if left <= 0.00001:
			break
		if g.state == FieldMonsters.STATE_CHASE and in_contact(g, player):
			break
		var target := Vector2(-1, -1)
		var stop_short := 0.0
		if direct_ok and g.state == FieldMonsters.STATE_CHASE and g.fpos.distance_to(player) <= float(_db.bal("monsters.direct_chase_tiles", 2.0)) 				and _line_of_sight(g.pos, pcell):
			target = player
			stop_short = contact - 0.05
			g.waypoint = Vector2(-1, -1)
		else:
			if g.waypoint.x < 0.0:
				g.waypoint = _next_waypoint(g, pcell)
			target = g.waypoint
		if target.x < 0.0:
			left -= 1.0  # 가만히 있기로 했다(배회 안 함) — 한 칸 시간만큼 쉰다
			continue
		var to := target - g.fpos
		var d := to.length() - stop_short
		if d <= 0.0001:
			g.waypoint = Vector2(-1, -1)
			if stop_short > 0.0:
				break
			continue
		var step := minf(d, left)
		var np := Kinematics.move(_map, g.fpos, to.normalized() * step, half)
		left -= step
		if np.distance_to(g.fpos) < 0.00001:
			left += step
			if stop_short > 0.0 and direct_ok:
				direct_ok = false
				continue
			# 막혔다 — 지금 칸 중심으로 돌아가 격자에 다시 맞춘다(제자리에 끼지 않게).
			var c := Kinematics.center_of(g.pos)
			g.waypoint = c if g.fpos.distance_to(c) > 0.01 and g.waypoint != c else Vector2(-1, -1)
			if g.waypoint.x < 0.0:
				break
			continue
		g.fpos = np
		g.pos = Kinematics.cell_of(np)
		moved = true
		if g.waypoint.x >= 0.0 and g.fpos.distance_to(g.waypoint) <= 0.0001:
			g.waypoint = Vector2(-1, -1)
	return moved


## 다음에 걸어갈 칸 중심. 추적: 플레이어까지의 거리 장을 따라 내려간다. 귀환: 집 쪽으로. 대기: 가끔 배회.
## 갈 곳이 없으면 (-1, -1).
func _next_waypoint(g: FieldMonsters.Group, pcell: Vector2i) -> Vector2:
	var best := g.pos
	match g.state:
		FieldMonsters.STATE_CHASE:
			var field := distance_field(pcell)
			var here: int = field.get(g.pos, 1 << 20)
			for d in FloorMap.DIRS4:
				var q := g.pos + d
				if q != pcell and can_enter(q, g) and int(field.get(q, 1 << 20)) < here:
					here = field[q]
					best = q
		FieldMonsters.STATE_RETURN:
			for d in FloorMap.DIRS4:
				var q := g.pos + d
				if can_enter(q, g) and (q - g.home).length_squared() < (best - g.home).length_squared():
					best = q
		_:
			if _rng.chance(float(_db.bal("monsters.wander_chance", 0.3))):
				var q := g.pos + FloorMap.DIRS4[_rng.randi_range(0, 3)]
				if can_enter(q, g) and Vector2(q - g.home).length() <= float(_db.bal("monsters.wander_radius", 4)):
					best = q
	if best == g.pos:
		# 칸 한가운데가 아니면(직접 추적 뒤 등) 지금 칸 중심으로 돌아가 격자에 맞춘다.
		var c := Kinematics.center_of(g.pos)
		return c if g.fpos.distance_to(c) > 0.01 and g.state != FieldMonsters.STATE_IDLE else Vector2(-1, -1)
	return Kinematics.center_of(best)


func in_contact(g: FieldMonsters.Group, player: Vector2) -> bool:
	return g.fpos.distance_to(player) <= float(_db.bal("monsters.contact_tiles", 1.05)) + 0.0001


## 칸 p에 들어갈 수 있는가: 걸을 수 있고 안전지대가 아니며, 다른 무리가 서 있거나 가는 중이 아니다.
func can_enter(p: Vector2i, self_group: FieldMonsters.Group = null) -> bool:
	if not _map.is_walkable(p) or _map.in_safe_zone(p):
		return false
	for o: FieldMonsters.Group in groups:
		if o != self_group and (o.pos == p or (o.waypoint.x >= 0.0 and Kinematics.cell_of(o.waypoint) == p)):
			return false
	return true


## 플레이어에서 시작하는 걸음 수 장(BFS). 몬스터는 안전지대에 들어가지 못한다.
## 지도가 바뀌지 않으므로 플레이어 칸이 같으면 지난 결과를 그대로 쓴다(매 프레임 갱신 비용 절약).
func distance_field(player: Vector2i) -> Dictionary:
	if player == _field_cell:
		return _field
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
	_field_cell = player
	_field = field
	return field


func _line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(1, n):
		var p := Vector2i(Vector2(a).lerp(Vector2(b), float(i) / n).round())
		if _map.blocks_sight(p):
			return false
	return true


func move_hours(monster_id: String) -> float:
	var agi := JsonUtil.get_float(JsonUtil.get_dict(_db.get_entry("monsters", monster_id), "stats"), "agi")
	return maxf(0.0001, float(_db.bal("explore.move_hours_base", 0.02)) / (1.0 + agi * float(_db.bal("explore.move_agi_coef", 0.02))))


func _behavior(monster_id: String) -> Dictionary:
	return JsonUtil.get_dict(_db.get_entry("monsters", monster_id), "behavior")
