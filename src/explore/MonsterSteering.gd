class_name MonsterSteering
extends RefCounted
## 필드 몬스터 무리의 판단·이동(순수 로직). FieldMonsters가 가진다(이쪽은 FieldMonsters를 참조하지 않는다 → 순환 없음).
##   decide: 대기(idle: 순찰) / 의심(suspect: 봤다 — 멈칫하고 그쪽을 본다) / 추적(chase: 의심 끝에도 보임) / 수색(search: 놓친 자리 둘러보기) /
##           귀환(return: 영역 이탈·도망친 플레이어 유예·수색 끝)
##   감지:   화면 안 + 벽에 안 가림 + 바라보는 쪽이면 알아채고 화면 밖이면 모른다(V19·V20) — MonsterSenses
##   walk:   칸 길찾기로 다음 칸 중심(waypoint)을 정하고 그쪽으로 연속으로 걷는다(Kinematics 충돌).
##           먼 곳으로 보낸 무리(route)는 대기 중에 그 길을 따라 걷는다. 쫓지 않을 때 갈 곳은 MonsterPatrol.
## 몬스터별 지도 행동(behavior): wander_radius·wander_chance(순찰 범위·빈도 — 고블린은 넓게 순찰)·leash_tiles(영역)·
##   passive_unless_status(그 상태가 없으면 알아채지 않음)·ignores_stealth(은신 무시)·move_mult(빠르기 배율)·alert_sfx(쫓기 시작할 때 소리)·aggro_radius_m(숨는·먼저 덤비지 않는 몬스터만 — 그 거리 안이어야 안다).
##   추적: 플레이어가 direct_chase_tiles 안이고 곧게 걸어갈 수 있으면 곧장 다가가 닿는 거리에서 멈춘다.
## 거리 장(플레이어에서 시작하는 BFS)은 플레이어 칸이 바뀔 때만 다시 만든다(매 프레임 호출 대비).

var groups: Array  ## FieldMonsters.groups (같은 배열을 공유)

var _db: GameDatabase
var _map: FloorMap
var _rng: Rng
# balance 값(매 프레임 무리마다 경로 문자열로 찾지 않게 한 번 읽어 둔다)
var _contact: float = 1.05
var _half: float = 0.3
var _direct: float = 2.0
var _move_hours: float = 0.02
var _lookahead: int = 8
var _mpt: float = 1.0
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
	_contact = float(db.bal("monsters.contact_tiles", 1.05))
	_half = float(db.bal("monsters.body_half_extent", 0.3))
	_direct = float(db.bal("monsters.direct_chase_tiles", 2.0))
	_move_hours = maxf(0.0001, float(db.bal("explore.move_hours_base", 0.02)))
	_lookahead = int(db.bal("monsters.straight_lookahead_tiles", 8))
	_mpt = maxf(0.01, float(db.bal("explore.meters_per_tile", 1.0)))
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
		g.last_seen = player
		if g.alert_until > now or g.state == FieldMonsters.STATE_CHASE or (g.state == FieldMonsters.STATE_SUSPECT and now >= g.suspect_until):
			g.state = FieldMonsters.STATE_CHASE  # 계속 보인다 — 쫓는다
			g.look = Vector2.ZERO
			if player != g.pos:
				g.facing = Vector2(player - g.pos).normalized()
		elif g.state != FieldMonsters.STATE_SUSPECT:  # 처음 봤다 — 멈칫하고 그쪽을 본다(멀수록·처음 보는 상대일수록 오래)
			g.suspect_until = now + _suspect_hours(g, player, before == FieldMonsters.STATE_SEARCH)
			g.state = FieldMonsters.STATE_SUSPECT
	elif g.state == FieldMonsters.STATE_SUSPECT:
		g.state = FieldMonsters.STATE_SEARCH  # 사라졌다 — 본 자리까지 가서 두리번거린다
	elif g.state == FieldMonsters.STATE_CHASE:
		g.state = FieldMonsters.STATE_SEARCH if g.last_seen.x >= 0 else FieldMonsters.STATE_RETURN
	elif g.state == FieldMonsters.STATE_SEARCH and _patrol.search_done(g, now):
		g.state = FieldMonsters.STATE_RETURN
	if g.state == FieldMonsters.STATE_RETURN and g.pos == g.home and g.waypoint.x < 0.0:
		g.state = FieldMonsters.STATE_IDLE
		g.leashed = false
	if g.state != before:
		g.waypoint = Vector2(-1, -1)  # 상태가 바뀌면 새로 길을 정한다
		_patrol.enter(g)
	if g.state == FieldMonsters.STATE_SUSPECT and player != g.pos:
		g.look = Vector2(player - g.pos).normalized()  # 의심: 그쪽으로 고개를 돌린다(MonsterPatrol.turn)
	elif g.hostile() and g.state != FieldMonsters.STATE_CHASE and g.hold_until <= now and _hears(g, player):
		g.look = Vector2(player - g.pos).normalized()  # 바로 곁에서 움직이는 기척 — 멈춰 돌아본다(알아채는 것은 돌아본 뒤 시야로)
		g.hold_until = now + _senses.hear_hold


## 의심 시간(게임 시간): 화면 가장자리에 가까울수록 길게(suspect_hours [가까이, 화면 끝]), 쫓다 놓친 상대(수색 중)면 짧게.
func _suspect_hours(g: FieldMonsters.Group, player: Vector2i, known: bool) -> float:
	var to := Vector2(player - g.pos).abs()
	var f := clampf(maxf(to.x / maxf(1.0, _senses.half.x), to.y / maxf(1.0, _senses.half.y)), 0.0, 1.0)
	var t := lerpf(_senses.suspect_min, _senses.suspect_max, f)
	return t * _senses.known_mult if known else t


## 바로 곁(hear_tiles — 은신만큼 준다)에서 플레이어가 움직이고 벽에 가리지 않으면 들린다. 서 있으면 들리지 않는다.
func _hears(g: FieldMonsters.Group, player: Vector2i) -> bool:
	if not player_moving:
		return false
	var beh := _behavior(g.leader())
	var shrink := 0.0 if JsonUtil.get_bool(beh, "ignores_stealth") else player_stealth
	return Vector2(player - g.pos).length() <= _senses.hear_tiles * (1.0 - shrink) and _line_of_sight(g.pos, player)


## 시간이 hours만큼 흘렀다: 서서 둘러보거나 돌아본다(FieldMonsters.update가 걷기 전에 부른다).
func turn(g: FieldMonsters.Group, hours: float, now: float) -> void:
	_patrol.turn(g, hours, now)


## 스폰 때 바라보는 쪽(트인 쪽).
func face_open(g: FieldMonsters.Group) -> void:
	_patrol.face_open(g)


## 플레이어 은신(FieldStealth, 0~1) — 그만큼 화면 사각형이 줄어든다. FieldMonsters가 넣는다.
var player_stealth: float = 0.0
## 플레이어에게 걸린 상태 id들(벤시: behavior "passive_unless_status"가 없으면 알아채지 않는다).
var player_marks: Array = []
## 플레이어가 방금 움직였는가(바로 곁의 몬스터가 돌아본다). FieldMonsters가 넣는다.
var player_moving: bool = false


## 알아챘는가(V19·V20): 화면 안 + 벽에 가리지 않음 + 바라보는 쪽(시야각)이면 안다, 화면 밖이면 모른다.
## 쫓는 중이면 시야각은 보지 않고(모퉁이를 돌 때마다 놓치지 않게) 화면을 chase_keep_tiles만큼 넓게 본다 — 벽에 가리면 놓친다.
## 예외 — 숨어 기다리는 몬스터(reveal_radius_m: 노움)와 먼저 덤비지 않는 몬스터(aggressive false: 구울·문지기)는
## aggro_radius_m 안으로 다가와야 안다(한 번 알아채면 화면 규칙으로 쫓는다).
func _notices(g: FieldMonsters.Group, player: Vector2i, _now_h: float = 0.0) -> bool:
	var chasing := g.state == FieldMonsters.STATE_CHASE
	if not on_screen(g, player, chasing) or not _line_of_sight(g.pos, player):
		return false
	if not chasing and not _senses.in_cone(g.facing, Vector2(player - g.pos)):
		return false  # 등 돌리고 있다
	var beh := _behavior(g.leader())
	if chasing or not _lurks(beh):
		return true
	var shrink := 0.0 if JsonUtil.get_bool(beh, "ignores_stealth") else player_stealth
	return Vector2(g.pos - player).length() <= JsonUtil.get_float(beh, "aggro_radius_m", 2.0) / _mpt * (1.0 - shrink)


## 숨어 기다리거나 먼저 덤비지 않는 몬스터(상태 조건을 채운 벤시는 덤빈다).
func _lurks(beh: Dictionary) -> bool:
	if JsonUtil.get_float(beh, "reveal_radius_m") > 0.0:
		return true
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	return not JsonUtil.get_bool(beh, "aggressive", true) and (need.is_empty() or not player_marks.has(need))


## 무리 g가 플레이어 화면 안에 있는가(은신·상태 조건 반영).
func on_screen(g: FieldMonsters.Group, player: Vector2i, chasing: bool = false) -> bool:
	var beh := _behavior(g.leader())
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	if not need.is_empty() and not player_marks.has(need):
		return false
	var shrink := 0.0 if JsonUtil.get_bool(beh, "ignores_stealth") else player_stealth
	return _senses.on_screen(Vector2(g.pos - player), shrink, chasing)


## 무리를 budget(칸)만큼 걷게 한다. 움직였으면 true.
func walk(g: FieldMonsters.Group, player: Vector2, pcell: Vector2i, budget: float) -> bool:
	if g.boss != "":  # 보스는 방 가운데서 움직이지 않는다
		return false
	if g.state == FieldMonsters.STATE_SUSPECT:
		return false  # 멈칫하고 보는 중
	if g.state != FieldMonsters.STATE_CHASE and g.hold_until > _now:
		return false  # 기척에 멈춰 돌아보는 중
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
## 한 칸 걷는 게임 시간: 플레이어와 같은 기본값 ÷ behavior move_mult(종마다 빠르기 — 늑대는 빠르고 슬라임·구울은 느리다, V21).
func move_hours(monster_id: String) -> float:
	return _move_hours / maxf(0.1, JsonUtil.get_float(_behavior(monster_id), "move_mult", 1.0))


func _behavior(monster_id: String) -> Dictionary:
	return JsonUtil.get_dict(_db.get_entry("monsters", monster_id), "behavior")
