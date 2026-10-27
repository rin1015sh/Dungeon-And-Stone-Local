class_name MonsterPatrol
extends RefCounted
## 필드 몬스터의 경계 순찰(순수 로직, MonsterSteering이 가진다). 몬스터가 쫓지 않을 때 어디로 걸을지 정한다.
##   대기(idle): 순찰 지점에 서서 monsters.patrol_pause_hours 동안 둘러보고(patrol_look_hours마다 트인 쪽으로 고개를 돌린다),
##     behavior wander_chance 확률로 집 둘레 wander_radius 안의 다른 지점(patrol_min_tiles 이상 떨어지고 되도록 앞쪽)까지
##     칸 길로 걸어간다. 아니면 그 자리에서 더 선다. (예전엔 칸마다 무작위 한 걸음이라 제자리에서 맴돌았다.)
##     쉬는 시간은 짧고, 지점을 고를 때 home_drift_chance로 그 지점이 새 집이 된다 — 같은 둘레를 맴돌지 않고 굴을 따라 옮겨 다닌다(V14).
##     칸 길은 곧게 걸을 수 있는 데까지(straight_lookahead_tiles) 건너뛰어 칸칸이 꺾어 걷지 않는다(V14).
##   수색(search): 쫓던 플레이어를 놓치면 마지막으로 본 칸(Group.last_seen)까지 가서 search_hours 동안 둘러본다.
##   귀환(return): 칸 길(FieldRoutes)로 집까지(예전엔 집 쪽으로 욕심껏 한 칸이라 굽은 굴에서 왔다 갔다 했다).
##   고개 돌리기: Group.look 쪽으로 한 칸 걷는 시간마다 turn_deg_per_tile씩 돈다.

const DIRS8: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1)]

var _map: FloorMap
var _rng: Rng
var _can_enter: Callable  ## (칸, 무리) -> bool — MonsterSteering.can_enter
var _pause: Array = [0.1, 0.3]
var _look: Array = [0.04, 0.1]
var _search_hours: float = 0.3
var _min_tiles: float = 3.0
var _wander_chance: float = 0.5
var _wander_radius: float = 6.0
var _turn_per_hour: float = 0.0
var _route_radius: int = 90
var _search_radius: int = 48
var _clear: Callable  ## (점 a, 점 b) -> bool — MonsterSteering.clear_walk
var _lookahead: int = 8
var _drift: float = 0.25


func _init(db: GameDatabase, map: FloorMap, rng: Rng, can_enter: Callable, clear: Callable) -> void:
	_map = map
	_rng = rng
	_can_enter = can_enter
	_clear = clear
	_lookahead = int(db.bal("monsters.straight_lookahead_tiles", 8))
	_drift = float(db.bal("monsters.home_drift_chance", 0.25))
	_pause = db.bal("monsters.patrol_pause_hours", [0.1, 0.3])
	_look = db.bal("monsters.patrol_look_hours", [0.04, 0.1])
	_search_hours = float(db.bal("monsters.search_hours", 0.3))
	_min_tiles = float(db.bal("monsters.patrol_min_tiles", 3))
	_wander_chance = float(db.bal("monsters.wander_chance", 0.5))
	_wander_radius = float(db.bal("monsters.wander_radius", 6))
	var move_hours := maxf(0.0001, float(db.bal("explore.move_hours_base", 0.02)))
	_turn_per_hour = deg_to_rad(float(db.bal("monsters.turn_deg_per_tile", 30))) / move_hours
	_route_radius = int(db.bal("monsters.route_radius", 90))
	_search_radius = int(db.bal("monsters.chase_path_radius", 24)) * 2


## 상태가 바뀌었다: 걷던 길을 버리고 새로 정한다. 수색이면 마지막으로 본 칸까지의 길.
func enter(g: FieldMonsters.Group) -> void:
	g.patrol.clear()
	g.rest_until = -1.0
	g.look = Vector2.ZERO
	if g.state == FieldMonsters.STATE_SEARCH and g.last_seen.x >= 0:
		g.patrol = FieldRoutes.path(_map, g.pos, g.last_seen, _search_radius)


## 수색을 마쳤는가(놓친 자리에 닿아 둘러보는 시간이 지났다).
func search_done(g: FieldMonsters.Group, now: float) -> bool:
	return g.patrol.is_empty() and g.rest_until >= 0.0 and now >= g.rest_until


## 쫓지 않는 무리가 다음에 걸어갈 칸. 서서 둘러보는 중이면 (-1, -1).
func next_cell(g: FieldMonsters.Group, now: float, beh: Dictionary) -> Vector2i:
	if g.state == FieldMonsters.STATE_RETURN and g.patrol.is_empty() and g.pos != g.home and now >= g.rest_until:
		g.patrol = FieldRoutes.path(_map, g.pos, g.home, _route_radius)
		if g.patrol.is_empty():
			g.rest_until = now + _pause[0]  # 길이 없다(막힘) — 잠시 뒤 다시 찾는다
	var step := _follow(g, now)
	if step.x >= 0 or g.state == FieldMonsters.STATE_RETURN:
		return step
	if g.rest_until < 0.0:  # 지점에 닿았다 — 서서 둘러본다
		g.rest_until = now + (_search_hours if g.state == FieldMonsters.STATE_SEARCH else _span(_pause))
		g.next_look = now + (0.0 if g.state == FieldMonsters.STATE_SEARCH else _span(_look))
		return step
	if g.state != FieldMonsters.STATE_IDLE or now < g.rest_until:
		return step
	if _rng.chance(JsonUtil.get_float(beh, "wander_chance", _wander_chance)):
		g.patrol = _plan(g, JsonUtil.get_float(beh, "wander_radius", _wander_radius))
		if not g.patrol.is_empty() and JsonUtil.get_int(beh, "leash_tiles") <= 0 and _rng.chance(_drift):
			g.home = g.patrol.back()  # 집이 옮겨 간다(영역이 있는 몬스터는 그대로)
	if g.patrol.is_empty():
		g.rest_until = now + _span(_pause)  # 그 자리에 더 선다
		return step
	g.rest_until = -1.0
	return _follow(g, now)


## 시간이 hours만큼 흘렀다: 서 있는 무리는 가끔 트인 쪽으로 고개를 돌리고, 돌아볼 쪽(look)이 있으면 그쪽으로 돈다.
func turn(g: FieldMonsters.Group, hours: float, now: float) -> void:
	var standing := g.patrol.is_empty() and g.rest_until >= 0.0 and g.route.is_empty() \
		and (g.state == FieldMonsters.STATE_IDLE or g.state == FieldMonsters.STATE_SEARCH)
	if standing and now >= g.next_look and g.look == Vector2.ZERO:
		g.look = _open_look(g)
		g.next_look = now + _span(_look) * (0.6 if g.state == FieldMonsters.STATE_SEARCH else 1.0)
	if g.look == Vector2.ZERO:
		return
	var a := g.facing.angle_to(g.look)
	var most := _turn_per_hour * hours
	if absf(a) <= most:
		g.facing = g.look
		g.look = Vector2.ZERO
	else:
		g.facing = g.facing.rotated(signf(a) * most)


## 스폰 때 바라보는 쪽: 트인 쪽 하나(무리마다 다르게, 무작위를 쓰지 않는다).
func face_open(g: FieldMonsters.Group) -> void:
	for k in DIRS8.size():
		var d := DIRS8[(g.id * 3 + k) % DIRS8.size()]
		if _map.is_walkable(g.pos + d):
			g.facing = Vector2(d).normalized()
			return


func _follow(g: FieldMonsters.Group, now: float) -> Vector2i:
	if g.patrol.is_empty():
		return Vector2i(-1, -1)
	var nxt: Vector2i = g.patrol[0]
	if (nxt - g.pos).length_squared() == 1 and bool(_can_enter.call(nxt, g)):
		g.patrol.pop_front()
		var from := Kinematics.center_of(g.pos)
		for k in _lookahead - 1:  # 곧게 걸을 수 있는 데까지 건너뛴다
			if g.patrol.is_empty():
				break
			var far: Vector2i = g.patrol[0]
			if not bool(_can_enter.call(far, g)) or not bool(_clear.call(from, Kinematics.center_of(far))):
				break
			nxt = g.patrol.pop_front()
		return nxt
	g.patrol.clear()  # 다른 무리가 막았다 — 여기서 멈춘다(귀환은 잠시 뒤 길을 다시 찾는다)
	if g.state == FieldMonsters.STATE_RETURN:
		g.rest_until = now + _pause[0]
	return Vector2i(-1, -1)


## 집 둘레 radius 안의 순찰 지점까지 칸 길. 되도록 지금 바라보는 쪽(뒤로 되돌아가지 않게).
func _plan(g: FieldMonsters.Group, radius: float) -> Array[Vector2i]:
	var r := maxi(1, int(radius))
	var accept := func(q: Vector2i) -> bool:
		return Vector2(q - g.pos).length() >= minf(_min_tiles, radius) and Vector2(q - g.home).length() <= radius \
			and bool(_can_enter.call(q, g))
	for attempt in 10:
		var q := FieldRoutes.random_cell_near(_map, _rng, g.home, r, accept)
		if q.x < 0:
			break
		if attempt < 6 and Vector2(q - g.pos).normalized().dot(g.facing) < -0.3:
			continue
		var path := FieldRoutes.path(_map, g.pos, q, r * 3)
		if not path.is_empty():
			return path
	var none: Array[Vector2i] = []
	return none


## 둘러볼 쪽: 지금 보는 쪽이 아닌 트인 방향 하나.
func _open_look(g: FieldMonsters.Group) -> Vector2:
	var open: Array[Vector2] = []
	for d in DIRS8:
		var v := Vector2(d).normalized()
		if _map.is_walkable(g.pos + d) and v.dot(g.facing) < 0.9:
			open.append(v)
	if open.is_empty():
		return -g.facing
	var v: Vector2 = _rng.pick(open)
	return v


func _span(range_: Array) -> float:
	return _rng.randf_range(float(range_[0]), float(range_[1])) if range_.size() == 2 else 0.1
