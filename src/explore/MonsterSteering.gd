class_name MonsterSteering
extends RefCounted
## 필드 몬스터 무리의 걷기(순수 로직). FieldMonsters가 가진다. 판단은 MonsterMind(src/explore/ai — 감각·경계도·기억·수색, V22),
## 쫓지 않을 때 갈 곳은 MonsterPatrol(순찰·귀환), 놓친 상대·조사·수색 길은 MonsterHunt가 Group.patrol에 넣는다.
##   walk: 칸 길로 다음 칸 중심(waypoint)을 정하고 그쪽으로 연속으로 걷는다(Kinematics 충돌). 보이는 상대를 쫓을 때는 거리 장(플레이어에서 BFS)을
##         따라 내려가고, direct_chase_tiles 안이고 곧게 걸어갈 수 있으면 곧장 다가가 닿는 거리에서 멈춘다.
##         먼 곳으로 보낸 무리(route)는 대기 중에 그 길을 따라 걷는다.
## 몬스터별 지도 행동(behavior): wander_radius·wander_chance·leash_tiles·passive_unless_status·ignores_stealth·move_mult(빠르기 배율)·
##   alert_sfx·aggro_radius_m·reveal_radius_m·aggressive, 성격 ai {alertness, tenacity, calls}(MonsterMind).
## 거리 장은 플레이어 칸이 바뀔 때만 다시 만든다(매 프레임 호출 대비).

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
var _patrol: MonsterPatrol
var mind: MonsterMind
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
	_patrol = MonsterPatrol.new(db, map, rng, can_enter, clear_walk)
	mind = MonsterMind.new(db, map, rng, _patrol, p_groups)


## 한 번 생각한다(MonsterMind.think). 추적을 새로 시작했으면 true.
func decide(g: FieldMonsters.Group, player: Vector2, pcell: Vector2i, hours: float, now: float) -> bool:
	_now = now
	return mind.think(g, player, pcell, hours, now)


## 시간이 hours만큼 흘렀다: 서서 둘러보거나 돌아본다(FieldMonsters.update가 걷기 전에 부른다).
func turn(g: FieldMonsters.Group, hours: float, now: float) -> void:
	_patrol.turn(g, hours, now)


## 스폰 때 바라보는 쪽(트인 쪽).
func face_open(g: FieldMonsters.Group) -> void:
	_patrol.face_open(g)


## 무리 g가 플레이어 화면 안에 있는가(은신·상태 조건 반영 — 보스 조우 · 테스트).
func on_screen(g: FieldMonsters.Group, player: Vector2i, chasing: bool = false) -> bool:
	var beh := _behavior(g.leader())
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	if not need.is_empty() and not mind.marks.has(need):
		return false
	var shrink := 0.0 if JsonUtil.get_bool(beh, "ignores_stealth") else mind.stealth
	return mind.sight.on_screen(Vector2(g.pos - player), shrink, chasing)


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
		if g.state == FieldMonsters.STATE_CHASE and g.sees and in_contact(g, player):
			break
		var target := Vector2(-1, -1)
		var stop_short := 0.0
		if direct_ok and g.state == FieldMonsters.STATE_CHASE and g.sees and g.fpos.distance_to(player) <= _direct \
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


## 다음에 걸어갈 칸 중심. 보이는 상대를 쫓을 때: 플레이어까지의 거리 장을 따라 내려간다. 놓친 상대·조사·수색: MonsterHunt가 정한 길.
## 순찰·귀환: MonsterPatrol. 갈 곳이 없으면 (-1, -1).
func _next_waypoint(g: FieldMonsters.Group, pcell: Vector2i) -> Vector2:
	var best := g.pos
	if g.state == FieldMonsters.STATE_IDLE and not g.route.is_empty():
		var nxt: Vector2i = g.route.pop_front()
		if (nxt - g.pos).length_squared() == 1 and can_enter(nxt, g):
			return Kinematics.center_of(nxt)
		g.route.clear()  # 막혔다(다른 무리) — 남은 길은 버리고 집 쪽으로 다가간다
	if g.state == FieldMonsters.STATE_CHASE and g.sees:
		var field := distance_field(pcell)
		var here: int = field.get(g.pos, 1 << 20)
		for d in FloorMap.DIRS4:
			var q := g.pos + d
			if q != pcell and can_enter(q, g) and int(field.get(q, 1 << 20)) < here:
				here = field[q]
				best = q
		if best != g.pos:
			best = _straight_descent(g, best, field, pcell)
	elif g.state in [FieldMonsters.STATE_CHASE, FieldMonsters.STATE_SEARCH, FieldMonsters.STATE_INVESTIGATE]:
		var q := mind.hunt.next_cell(g, _now)
		if q.x >= 0:
			best = q
	else:
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


## 칸 a에서 b가 보이는가(몬스터 시선 — 몸 세 줄, 서 있는 장식은 막지 않는다 — MonsterSight).
func sees(a: Vector2i, b: Vector2i) -> bool:
	return mind.sight.sees(Kinematics.center_of(a), Kinematics.center_of(b))


## 한 칸을 가는 데 드는 게임 시간 — 플레이어와 같다(민첩과 무관, 사용자 결정 2026-10-17).
## 한 칸 걷는 게임 시간: 플레이어와 같은 기본값 ÷ behavior move_mult(종마다 빠르기 — 늑대는 빠르고 슬라임·구울은 느리다, V21).
func move_hours(monster_id: String) -> float:
	return _move_hours / maxf(0.1, JsonUtil.get_float(_behavior(monster_id), "move_mult", 1.0))


func _behavior(monster_id: String) -> Dictionary:
	return JsonUtil.get_dict(_db.get_entry("monsters", monster_id), "behavior")
