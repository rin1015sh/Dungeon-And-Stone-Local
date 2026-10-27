class_name MonsterSteering
extends RefCounted
## 필드 몬스터 무리의 판단·이동(순수 로직). FieldMonsters가 가진다(이쪽은 FieldMonsters를 참조하지 않는다 → 순환 없음).
##   decide: 대기(idle: 순찰) / 추적(chase: 플레이어를 알아챔) / 수색(search: 놓친 자리 둘러보기) /
##           귀환(return: 영역 이탈·도망친 플레이어 유예·수색 끝)
##   감지:   시야각(바라보는 쪽과의 내적)·가까운 기척·움직이는 소리(돌아보기) — MonsterSenses
##   walk:   칸 길찾기로 다음 칸 중심(waypoint)을 정하고 그쪽으로 연속으로 걷는다(Kinematics 충돌).
##           먼 곳으로 보낸 무리(route)는 대기 중에 그 길을 따라 걷는다. 쫓지 않을 때 갈 곳은 MonsterPatrol.
## 몬스터별 지도 행동(behavior): wander_radius·wander_chance(순찰 범위·빈도 — 고블린은 넓게 순찰)·view_cone_deg(시야각),
##   tracks_scent {radius_tiles, hours}: 플레이어가 지나간 지 hours 안 된 칸이 radius 안이면 알아채고 그 냄새를 따라온다(칼날늑대).
##   hunts_tiles: 움직이는 플레이어가 그 걸음 수(거리 장) 안이면 보이지 않아도 알아채고 쫓는다(늑대·고블린 — 화면 밖에서부터 따라온다).
##           플레이어가 direct_chase_tiles 안이고 곧게 걸어갈 수 있으면 곧장 다가가 닿는 거리에서 멈춘다.
## 거리 장(플레이어에서 시작하는 BFS)은 플레이어 칸이 바뀔 때만 다시 만든다(매 프레임 호출 대비).

var groups: Array  ## FieldMonsters.groups (같은 배열을 공유)

var _db: GameDatabase
var _map: FloorMap
var _rng: Rng
var _mpt: float = 1.0
# balance 값(매 프레임 무리마다 경로 문자열로 찾지 않게 한 번 읽어 둔다)
var _contact: float = 1.05
var _half: float = 0.3
var _direct: float = 2.0
var _move_hours: float = 0.02
var _lookahead: int = 8
var _now: float = 0.0
var _senses: MonsterSenses
var _patrol: MonsterPatrol
var _field_cell: Vector2i = Vector2i(-1, -1)
var _field: Dictionary = {}


func _init(db: GameDatabase, map: FloorMap, rng: Rng, p_groups: Array) -> void:
	_db = db
	_map = map
	_rng = rng
	groups = p_groups
	_mpt = maxf(0.01, float(db.bal("explore.meters_per_tile", 1.0)))
	_contact = float(db.bal("monsters.contact_tiles", 1.05))
	_half = float(db.bal("monsters.body_half_extent", 0.3))
	_direct = float(db.bal("monsters.direct_chase_tiles", 2.0))
	_move_hours = maxf(0.0001, float(db.bal("explore.move_hours_base", 0.02)))
	_lookahead = int(db.bal("monsters.straight_lookahead_tiles", 8))
	_senses = MonsterSenses.new(db)
	_patrol = MonsterPatrol.new(db, map, rng, can_enter, clear_walk)


func decide(g: FieldMonsters.Group, player: Vector2i, now: float) -> void:
	_now = now
	var before := g.state
	var leash := JsonUtil.get_int(_behavior(g.leader()), "leash_tiles")
	var from_home := Vector2(g.pos - g.home).length()
	if g.grace_until > now:
		g.state = FieldMonsters.STATE_RETURN
	elif leash > 0 and (from_home > leash or (g.leashed and from_home > leash * 0.5)):
		g.state = FieldMonsters.STATE_RETURN  # 영역을 벗어났으면 반쯤 돌아갈 때까지는 다시 쫓지 않는다(경계에서 왔다 갔다 하지 않게)
		g.leashed = true
	elif g.hostile() and (g.alert_until > now or _notices(g, player, now)):
		g.leashed = false
		g.state = FieldMonsters.STATE_CHASE
		g.last_seen = player
		g.look = Vector2.ZERO
		if player != g.pos:
			g.facing = Vector2(player - g.pos).normalized()
	elif g.state == FieldMonsters.STATE_CHASE:
		g.state = FieldMonsters.STATE_SEARCH if g.last_seen.x >= 0 else FieldMonsters.STATE_RETURN
	elif g.state == FieldMonsters.STATE_SEARCH and _patrol.search_done(g, now):
		g.state = FieldMonsters.STATE_RETURN
	elif g.hostile() and _hears(g, player):
		g.look = Vector2(player - g.pos).normalized()  # 무슨 소리지 — 멈춰서 그쪽을 돌아본다
		g.hold_until = now + _senses.hear_hold_hours
	if g.state == FieldMonsters.STATE_RETURN and g.pos == g.home and g.waypoint.x < 0.0:
		g.state = FieldMonsters.STATE_IDLE
		g.leashed = false
	if g.state != before:
		g.waypoint = Vector2(-1, -1)  # 상태가 바뀌면 새로 길을 정한다
		_patrol.enter(g)


## 시간이 hours만큼 흘렀다: 서서 둘러보거나 돌아본다(FieldMonsters.update가 걷기 전에 부른다).
func turn(g: FieldMonsters.Group, hours: float, now: float) -> void:
	_patrol.turn(g, hours, now)


## 스폰 때 바라보는 쪽(트인 쪽).
func face_open(g: FieldMonsters.Group) -> void:
	_patrol.face_open(g)


## 플레이어 은신(FieldStealth, 0~1). FieldMonsters가 넣는다.
var player_stealth: float = 0.0
## 플레이어가 지나온 칸 [[칸, 시각], …](오래된 것이 앞). FieldMonsters가 넣는다(ExploreSession이 기록).
var player_trail: Array = []
## 플레이어에게 걸린 상태 id들(벤시: behavior "passive_unless_status"가 없으면 알아채지 않고, 있으면 반경 × aggro_mult_if_status).
var player_marks: Array = []
## 플레이어가 방금 움직였는가(소리 — 등 뒤의 몬스터가 돌아본다). FieldMonsters가 넣는다.
var player_moving: bool = false


## 알아챘는가: 냄새, 또는 감지 반경 안·벽에 가리지 않음 + (가까운 기척 · 쫓는 중 · 시야각 안).
func _notices(g: FieldMonsters.Group, player: Vector2i, now: float = 0.0) -> bool:
	var beh := _behavior(g.leader())
	if _smells(g, beh, now):
		return true
	var radius := _sense_radius(beh)
	var to := Vector2(player - g.pos)
	var d := to.length()
	if _hunts(g, beh, player, radius):
		return true
	if g.state == FieldMonsters.STATE_CHASE:
		radius *= _senses.keep_mult  # 한 번 본 것은 쉽게 놓치지 않는다
	if d > radius or not _line_of_sight(g.pos, player):
		return false
	return d <= _senses.near or g.state == FieldMonsters.STATE_CHASE or _senses.in_cone(g.facing, to, beh)


## 사냥(behavior hunts_tiles): 움직이는 플레이어가 그 걸음 수 안이면 벽 너머라도 안다(은신만큼 줄어든다).
func _hunts(g: FieldMonsters.Group, beh: Dictionary, player: Vector2i, radius: float) -> bool:
	var steps := JsonUtil.get_float(beh, "hunts_tiles")
	if steps <= 0.0 or radius < 0.0 or not (player_moving or g.state == FieldMonsters.STATE_CHASE):
		return false
	if not JsonUtil.get_bool(beh, "ignores_stealth"):
		steps *= 1.0 - player_stealth
	if Vector2(player - g.pos).length() > steps:
		return false
	return float(distance_field(player).get(g.pos, 1 << 20)) <= steps


## 움직이는 플레이어 소리가 들리는가(감지 반경 × hear_ratio, 벽에 가리지 않음).
func _hears(g: FieldMonsters.Group, player: Vector2i) -> bool:
	if not player_moving:
		return false
	var d := Vector2(player - g.pos).length()
	return d <= _sense_radius(_behavior(g.leader())) * _senses.hear_ratio and _line_of_sight(g.pos, player)


## 감지 반경(칸): aggro_radius_m, 상태 조건(passive_unless_status)이 없으면 −1, 은신만큼 줄어든다.
func _sense_radius(beh: Dictionary) -> float:
	var radius := minf(JsonUtil.get_float(beh, "aggro_radius_m", 4.0) / _mpt * _senses.sight_mult, _senses.sight_max)
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	if not need.is_empty():
		if not player_marks.has(need):
			return -1.0
		radius *= JsonUtil.get_float(beh, "aggro_mult_if_status", 1.0)
	if not JsonUtil.get_bool(beh, "ignores_stealth"):
		radius *= 1.0 - player_stealth
	return radius


## 냄새: 지나간 지 얼마 안 된 플레이어 발자국이 반경 안에 있으면 가장 새 것을 쫓는다(g.scent).
func _smells(g: FieldMonsters.Group, beh: Dictionary, now: float) -> bool:
	var sc := JsonUtil.get_dict(beh, "tracks_scent")
	if sc.is_empty() or player_trail.is_empty():
		return false
	var r2 := pow(JsonUtil.get_float(sc, "radius_tiles", 5.0), 2.0)
	var hours := JsonUtil.get_float(sc, "hours", 1.0)
	for i in range(player_trail.size() - 1, -1, -1):
		var e: Array = player_trail[i]
		if now - float(e[1]) > hours:
			break
		if Vector2(e[0] - g.pos).length_squared() <= r2:
			g.scent = e[0]
			return true
	return false


## 무리를 budget(칸)만큼 걷게 한다. 움직였으면 true.
func walk(g: FieldMonsters.Group, player: Vector2, pcell: Vector2i, budget: float) -> bool:
	if g.boss != "":  # 보스는 방 가운데서 움직이지 않는다
		return false
	if g.state != FieldMonsters.STATE_CHASE and g.hold_until > _now:
		return false  # 소리를 듣고 멈춰 돌아보는 중
	var left := budget
	var moved := false
	var contact := _contact
	var half := _half
	var direct_ok := true  # 곧장 다가가다 모서리에 막히면 이번엔 칸 길로 돌아간다
	for guard in 64:
		if left <= 0.00001:
			break
		if g.state == FieldMonsters.STATE_CHASE and in_contact(g, player):
			break
		var target := Vector2(-1, -1)
		var stop_short := 0.0
		if direct_ok and g.state == FieldMonsters.STATE_CHASE and g.fpos.distance_to(player) <= _direct \
				and clear_walk(g.fpos, player):
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
		g.facing = (np - g.fpos).normalized()
		g.look = Vector2.ZERO
		g.fpos = np
		g.pos = Kinematics.cell_of(np)
		moved = true
		if g.waypoint.x >= 0.0 and g.fpos.distance_to(g.waypoint) <= 0.0001:
			g.waypoint = Vector2(-1, -1)
	return moved


## 다음에 걸어갈 칸 중심. 추적: 플레이어까지의 거리 장을 따라 내려간다. 그 밖(순찰·수색·귀환): MonsterPatrol.
## 갈 곳이 없으면 (-1, -1).
func _next_waypoint(g: FieldMonsters.Group, pcell: Vector2i) -> Vector2:
	var best := g.pos
	if g.state != FieldMonsters.STATE_CHASE and not g.route.is_empty():
		var nxt: Vector2i = g.route.pop_front()
		if (nxt - g.pos).length_squared() == 1 and can_enter(nxt, g):
			return Kinematics.center_of(nxt)
		g.route.clear()  # 막혔다(다른 무리) — 남은 길은 버리고 집 쪽으로 다가간다
	match g.state:
		FieldMonsters.STATE_CHASE:
			var field := distance_field(pcell)
			if not field.has(g.pos) and g.scent.x >= 0:  # 플레이어는 멀다 — 냄새 칸 쪽으로
				best = _toward(g, g.scent)
			var here: int = field.get(g.pos, 1 << 20)
			for d in FloorMap.DIRS4:
				var q := g.pos + d
				if q != pcell and can_enter(q, g) and int(field.get(q, 1 << 20)) < here:
					here = field[q]
					best = q
			if best != g.pos:
				best = _straight_descent(g, best, field, pcell)
		_:
			var q := _patrol.next_cell(g, _now, _behavior(g.leader()))
			if q.x >= 0:
				best = q
	if best == g.pos:
		# 칸 한가운데가 아니면(직접 추적 뒤 등) 지금 칸 중심으로 돌아가 격자에 맞춘다.
		var c := Kinematics.center_of(g.pos)
		return c if g.fpos.distance_to(c) > 0.01 and g.state != FieldMonsters.STATE_IDLE else Vector2(-1, -1)
	return Kinematics.center_of(best)


## 쫓는 길을 곧게(V14): 거리 장을 따라 몇 칸 더 내려가 보고, 지금 칸에서 곧게 걸어갈 수 있는 가장 먼 칸.
func _straight_descent(g: FieldMonsters.Group, first: Vector2i, field: Dictionary, pcell: Vector2i) -> Vector2i:
	var best := first
	var cur := first
	var from := Kinematics.center_of(g.pos)
	for k in _lookahead - 1:
		var here: int = field.get(cur, 1 << 20)
		var nxt := cur
		for d in FloorMap.DIRS4:
			var q := cur + d
			if q != pcell and int(field.get(q, 1 << 20)) < here:
				here = field[q]
				nxt = q
		if nxt == cur or not can_enter(nxt, g) or not clear_walk(from, Kinematics.center_of(nxt)):
			break
		cur = nxt
		best = cur
	return best


## target 쪽으로 한 칸(4방향 중 가장 가까워지는 칸). 없으면 지금 칸.
func _toward(g: FieldMonsters.Group, target: Vector2i) -> Vector2i:
	var best := g.pos
	for d in FloorMap.DIRS4:
		var q := g.pos + d
		if can_enter(q, g) and (q - target).length_squared() < (best - target).length_squared():
			best = q
	return best


func in_contact(g: FieldMonsters.Group, player: Vector2) -> bool:
	return g.fpos.distance_to(player) <= _contact + 0.0001


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


## 점 a에서 b까지 곧게 걸어갈 수 있는가: 몸 폭(body_half_extent) 양옆까지 걸을 수 있는 칸이고 안전지대가 아니다.
func clear_walk(a: Vector2, b: Vector2) -> bool:
	var to := b - a
	var n := maxi(1, int(ceil(to.length() / 0.25)))
	var side := to.orthogonal().normalized() * _half
	for i in range(1, n + 1):
		var p := a + to * (float(i) / n)
		for q: Vector2 in [p, p + side, p - side]:
			var c := Kinematics.cell_of(q)
			if not _map.is_walkable(c) or _map.in_safe_zone(c):
				return false
	return true


## 칸 a에서 b가 보이는가(벽이 막지 않음).
func sees(a: Vector2i, b: Vector2i) -> bool:
	return _line_of_sight(a, b)


func _line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(1, n):
		var p := Vector2i(Vector2(a).lerp(Vector2(b), float(i) / n).round())
		if _map.blocks_sight(p):
			return false
	return true


## 한 칸을 가는 데 드는 게임 시간 — 플레이어와 같다(민첩과 무관, 사용자 결정 2026-10-17).
func move_hours(_monster_id: String) -> float:
	return _move_hours


func _behavior(monster_id: String) -> Dictionary:
	return JsonUtil.get_dict(_db.get_entry("monsters", monster_id), "behavior")
