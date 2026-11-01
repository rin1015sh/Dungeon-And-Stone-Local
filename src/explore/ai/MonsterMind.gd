class_name MonsterMind
extends RefCounted
## 필드 몬스터 무리의 판단(순수 로직 — MonsterSteering이 가진다, 사용자 2026-11-01 "적 AI 대대적 개편 — 오래 쓸 AI", V22).
## 무리마다 경계도(Group.awareness 0~1)와 기억(마지막으로 본·들은 칸 target · 그때 움직임 vel · 시각 seen_at)을 가진다.
##
##   대기(idle)      순찰(MonsterPatrol). 보이면 경계도가 차오른다 — 가까울수록·정면일수록·움직일수록 빠르다(ai.notice_hours [바로 앞, 화면 끝]).
##   의심(suspect)   경계도가 ai.suspect_at을 넘었다: 멈춰 그쪽을 본다. 1이 되면 추적, 그새 사라지면 조사.
##   조사(investigate) 흘끗 본 곳·발소리·동료의 외침이 있던 칸까지 조심스럽게(느리게) 가서 둘러본다. 다시 보이면 이미 경계 중이라 금방 알아챈다.
##   추적(chase)     보이는 동안은 곧장(거리 장 — MonsterSteering). 안 보이면 기억으로 쫓는다(MonsterHunt):
##                   마지막으로 본 칸 → 움직이던 쪽으로 내다본 칸 → 수색. 쫓는 중엔 모퉁이 너머라도 길 거리 ai.chase_hear_tiles 안의
##                   발소리로 자리를 다시 안다(서 있거나 은신하면 들리지 않는다). 기억은 ai.memory_hours(× 성격 tenacity)만큼.
##   수색(search)    둘레 몇 곳을 돌며 둘러본다(MonsterHunt.sweep_points). ai.search_hours가 지나면 귀환.
##   귀환(return)    집으로(영역 이탈·도망친 플레이어 유예·수색 끝). 오는 길에 다시 보면 이미 아는 상대라 빨리 알아챈다(ai.known_mult).
##
## 무리 부르기: 추적을 시작한 무리(behavior ai.calls)는 길 거리 ai.call_tiles 안의 같은 편(같은 종 또는 ai.calls) 무리를 부른다 —
##   불린 무리는 그 자리를 조사하러 온다(바로 쫓지는 않는다).
## 성격(behavior ai — 없으면 1): alertness(경계도 차오르는 빠르기) · tenacity(기억·수색 길이) · calls(동료를 부르는가).
## 예외는 그대로: 숨어 기다리는 몬스터(reveal_radius_m)·먼저 덤비지 않는 몬스터(aggressive false)는 behavior aggro_radius_m 안이어야 보고,
##   passive_unless_status는 그 상태가 없으면 보지 않는다. 보스(Group.boss)는 생각하지 않는다(FieldMonsters가 따로 — 방에서 기다린다).

const IDLE := "idle"
const CHASE := "chase"
const RETURN := "return"
const SEARCH := "search"
const SUSPECT := "suspect"
const INVESTIGATE := "investigate"

var sight: MonsterSight
var hunt: MonsterHunt
var groups: Array  ## FieldMonsters.groups(공유)

## FieldMonsters가 매 갱신 넣는 플레이어 상태.
var stealth: float = 0.0
var marks: Array = []
var moving: bool = false

var _db: GameDatabase
var _patrol: MonsterPatrol
var _mpt: float = 1.0
var _notice := Vector2(0.02, 0.08)
var _side: float = 0.45
var _still: float = 0.6
var _known: float = 2.5
var _suspect_at: float = 0.25
var _decay: float = 0.12
var _memory: float = 0.5
var _chase_hear: int = 5
var _hear: float = 2.5
var _hear_gain: float = 0.35
var _hear_hold: float = 0.05
var _search: float = 0.45
var _investigate: float = 0.15
var _call: int = 12
var _speed: Dictionary = {}
var _pvel := Vector2.ZERO  # 플레이어 움직임(칸/게임 시간) — 갱신마다 부드럽게
var _plast := Vector2(-1, -1)


func _init(db: GameDatabase, map: FloorMap, rng: Rng, patrol: MonsterPatrol, p_groups: Array) -> void:
	_db = db
	_patrol = patrol
	groups = p_groups
	sight = MonsterSight.new(db, map)
	hunt = MonsterHunt.new(db, map, rng, sight, patrol)
	_mpt = maxf(0.01, float(db.bal("explore.meters_per_tile", 1.0)))
	var n: Array = db.bal("monsters.ai.notice_hours", [0.02, 0.08])
	_notice = Vector2(float(n[0]), float(n[1]))
	_side = float(db.bal("monsters.ai.peripheral_mult", 0.45))
	_still = float(db.bal("monsters.ai.still_mult", 0.6))
	_known = float(db.bal("monsters.ai.known_mult", 2.5))
	_suspect_at = float(db.bal("monsters.ai.suspect_at", 0.25))
	_decay = maxf(0.001, float(db.bal("monsters.ai.decay_hours", 0.12)))
	_memory = float(db.bal("monsters.ai.memory_hours", 0.5))
	_chase_hear = int(db.bal("monsters.ai.chase_hear_tiles", 5))
	_hear = float(db.bal("monsters.ai.hear_tiles", 2.5))
	_hear_gain = float(db.bal("monsters.ai.hear_gain", 0.35))
	_hear_hold = float(db.bal("monsters.ai.hear_hold_hours", 0.05))
	_search = float(db.bal("monsters.ai.search_hours", 0.45))
	_investigate = float(db.bal("monsters.ai.investigate_hours", 0.15))
	_call = int(db.bal("monsters.ai.call_tiles", 12))
	_speed = db.bal("monsters.ai.speed", {})


## 플레이어 자리(연속 좌표)를 받아 움직임을 잰다(갱신마다 한 번).
func track_player(p: Vector2, hours: float) -> void:
	if _plast.x >= 0.0 and hours > 0.0:
		_pvel = _pvel.lerp((p - _plast) / hours, clampf(hours / 0.05, 0.0, 1.0))
	_plast = p


## 그 상태에서 걷는 빠르기 배율(ai.speed — 의심 중엔 서 있다).
func speed(g: FieldMonsters.Group) -> float:
	if g.called and g.state == INVESTIGATE:
		return float(_speed.get(CHASE, 1.0))  # 동료가 불러 달려온다
	return float(_speed.get(g.state, 1.0))


## 한 번 생각한다(걷기 전·뒤에 FieldMonsters가 부른다). 추적을 새로 시작했으면 true(소리 — alerted).
func think(g: FieldMonsters.Group, p: Vector2, pcell: Vector2i, hours: float, now: float) -> bool:
	if g.boss != "":
		return false
	var before := g.state
	var beh := _behavior(g)
	var leash := JsonUtil.get_int(beh, "leash_tiles")
	var from_home := Vector2(g.pos - g.home).length()
	g.sees = false
	if g.grace_until > now:
		_go_state(g, RETURN)
		g.awareness = 0.0
	elif leash > 0 and (from_home > leash or (g.leashed and from_home > leash * 0.5)):
		_go_state(g, RETURN)  # 영역을 벗어났으면 반쯤 돌아갈 때까지는 다시 쫓지 않는다(경계에서 왔다 갔다 하지 않게)
		g.leashed = true
		g.awareness = minf(g.awareness, _suspect_at)
	elif g.hostile() and g.alert_until > now:
		_saw(g, pcell, now)  # 사건(은닉처 경보·매복)으로 자리를 안다
		g.awareness = 1.0
		_go_state(g, CHASE)
	elif g.hostile():
		_perceive(g, p, pcell, hours, now, beh)
	if g.state == RETURN and g.pos == g.home and g.waypoint.x < 0.0:
		_go_state(g, IDLE)
		g.leashed = false
	_plan(g, now, beh)
	var started := g.state == CHASE and before != CHASE
	if started:
		g.known = true
		_call_allies(g, pcell, beh)
	return started


## 보고 듣는다 → 경계도·기억·상태.
func _perceive(g: FieldMonsters.Group, p: Vector2, pcell: Vector2i, hours: float, now: float, beh: Dictionary) -> void:
	var ai := JsonUtil.get_dict(beh, "ai")
	var shrink := 0.0 if JsonUtil.get_bool(beh, "ignores_stealth") else stealth
	var seen := _visibility(g, p, pcell, beh, shrink)
	if seen > 0.0:
		g.sees = true
		_saw(g, pcell, now)
		if g.state == CHASE:
			return
		var to := Vector2(pcell - g.pos).abs()
		var f := clampf(maxf(to.x / maxf(1.0, sight.half.x), to.y / maxf(1.0, sight.half.y)), 0.0, 1.0)
		var rate := seen / lerpf(_notice.x, _notice.y, f) * JsonUtil.get_float(ai, "alertness", 1.0) * (1.0 if moving else _still) * (1.0 - shrink * 0.5)
		if g.known or g.state in [SEARCH, INVESTIGATE]:
			rate *= _known
		g.awareness = minf(1.0, g.awareness + rate * hours)
		if g.awareness >= 1.0:
			_go_state(g, CHASE)
		elif g.awareness >= _suspect_at and g.state != SUSPECT:
			_go_state(g, SUSPECT)
		if g.state == SUSPECT:
			g.look = Vector2(pcell - g.pos).normalized() if pcell != g.pos else Vector2.ZERO
		return
	var steps := sight.path_steps(g.pos, pcell, _chase_hear) if moving else -1
	var heard_far := steps >= 0 and float(steps) <= _chase_hear * (1.0 - shrink)
	if g.state == CHASE:
		if heard_far:  # 모퉁이 너머 발소리 — 자리를 다시 안다
			_saw(g, pcell, now)
		elif now - g.seen_at > _memory * JsonUtil.get_float(ai, "tenacity", 1.0):
			_go_state(g, SEARCH)
		return
	g.awareness = maxf(0.0, g.awareness - hours / _decay)
	if heard_far and float(steps) <= _hear * (1.0 - shrink) and g.hold_until <= now:
		g.look = Vector2(pcell - g.pos).normalized() if pcell != g.pos else Vector2.ZERO  # 곁에서 움직이는 기척 — 멈춰 돌아본다
		g.hold_until = now + _hear_hold
		g.stimulus = pcell
		g.awareness = minf(0.99, g.awareness + _hear_gain)
		if g.awareness >= _suspect_at and g.state != SUSPECT:
			_go_state(g, SUSPECT)
	elif g.state == SUSPECT and g.hold_until <= now:
		_go_state(g, INVESTIGATE)  # 사라졌다 — 본 자리를 보러 간다


## 무리 g가 지금 플레이어를 볼 수 있는가(상태·은신·숨는 몬스터 조건 포함 — 테스트·디버그).
func can_see(g: FieldMonsters.Group, p: Vector2) -> bool:
	var beh := _behavior(g)
	var shrink := 0.0 if JsonUtil.get_bool(beh, "ignores_stealth") else stealth
	return _visibility(g, p, Kinematics.cell_of(p), beh, shrink) > 0.0


## 지금 보이는 정도(0 = 못 봄, 곁눈이면 작다).
func _visibility(g: FieldMonsters.Group, p: Vector2, pcell: Vector2i, beh: Dictionary, shrink: float) -> float:
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	if not need.is_empty() and not marks.has(need):
		return 0.0
	var chasing := g.state == CHASE
	if not sight.on_screen(Vector2(g.pos - pcell), shrink, chasing):
		return 0.0
	var k := 1.0 if chasing else sight.cone(g.facing, p - g.fpos, _side)
	if k <= 0.0:
		return 0.0  # 등 뒤
	if not chasing and _lurks(beh) and Vector2(g.pos - pcell).length() > JsonUtil.get_float(beh, "aggro_radius_m", 2.0) / _mpt * (1.0 - shrink):
		return 0.0
	return k if sight.sees(g.fpos, p) else 0.0


## 숨어 기다리거나 먼저 덤비지 않는 몬스터(상태 조건을 채운 벤시는 덤빈다).
func _lurks(beh: Dictionary) -> bool:
	if JsonUtil.get_float(beh, "reveal_radius_m") > 0.0:
		return true
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	return not JsonUtil.get_bool(beh, "aggressive", true) and (need.is_empty() or not marks.has(need))


func _saw(g: FieldMonsters.Group, pcell: Vector2i, now: float) -> void:
	g.target = pcell
	g.stimulus = pcell
	g.seen_at = now
	g.vel = _pvel
	g.leashed = false


func _go_state(g: FieldMonsters.Group, state: String) -> void:
	if g.state == state:
		return
	g.state = state
	g.phase = ""
	g.called = g.called and state == INVESTIGATE
	g.waypoint = Vector2(-1, -1)  # 상태가 바뀌면 새로 길을 정한다
	_patrol.enter(g)
	if state == CHASE:
		g.look = Vector2.ZERO


## 상태마다 걸어갈 길을 정한다(놓친 상대 · 조사 · 수색). 대기·귀환은 MonsterPatrol, 보이는 추적은 MonsterSteering이 곧장.
func _plan(g: FieldMonsters.Group, now: float, beh: Dictionary) -> void:
	var tenacity := JsonUtil.get_float(JsonUtil.get_dict(beh, "ai"), "tenacity", 1.0)
	match g.state:
		CHASE:
			if g.sees:
				g.phase = ""
				g.patrol.clear()
				return
			if g.phase == "" or (g.phase == "pursue" and not g.patrol.is_empty() and g.patrol.back() != g.target):
				g.phase = "pursue"  # 마지막으로 본·들은 칸까지
				hunt.go(g, g.target)
			elif g.phase == "pursue" and hunt.arrived(g):
				var ahead := hunt.predict(g.target, g.vel)
				if ahead.x < 0:
					_go_state(g, SEARCH)
				else:
					g.phase = "predict"  # 움직이던 쪽으로 더
					hunt.go(g, ahead)
			elif g.phase == "predict" and hunt.arrived(g):
				_go_state(g, SEARCH)
			if g.state == SEARCH:
				_plan(g, now, beh)
		SEARCH:
			if g.phase == "":
				g.phase = "sweep"
				g.hunt_until = now + _search * tenacity
				g.points = hunt.sweep_points(g.pos, g.vel, tenacity)
				g.rest_until = now + hunt.look_hours()  # 먼저 그 자리에서 둘러본다
				g.next_look = now
			elif now >= g.hunt_until:
				_go_state(g, RETURN)
			else:
				_step_points(g, now)
		INVESTIGATE:
			if g.phase == "":
				g.phase = "go"
				hunt.go(g, g.stimulus)
			elif g.phase == "go" and hunt.arrived(g):
				g.phase = "look"
				g.rest_until = now + _investigate
				g.next_look = now
			elif g.phase == "look" and now >= g.rest_until:
				_go_state(g, IDLE)  # 아무것도 없었다 — 하던 순찰로(집은 그대로라 결국 돌아간다)


## 수색: 지금 지점에서 둘러보기가 끝났으면 다음 지점으로, 지점이 다 떨어지면 귀환.
func _step_points(g: FieldMonsters.Group, now: float) -> void:
	if not hunt.arrived(g):
		return
	if g.rest_until < 0.0:
		g.rest_until = now + hunt.look_hours()
		g.next_look = now
		return
	if now < g.rest_until:
		return
	if g.points.is_empty():
		_go_state(g, RETURN)
		return
	hunt.go(g, g.points.pop_front())


## 추적을 시작했다: 같은 편 무리를 부른다(길 거리 call_tiles 안 — 그 자리를 조사하러 달려온다).
func _call_allies(g: FieldMonsters.Group, pcell: Vector2i, beh: Dictionary) -> void:
	if not JsonUtil.get_bool(JsonUtil.get_dict(beh, "ai"), "calls"):
		return
	for o: FieldMonsters.Group in groups:
		if o == g or o.boss != "" or not o.hostile() or o.state == CHASE or o.grace_until > g.seen_at:
			continue
		var ob := _behavior(o)
		if o.leader() != g.leader() and not JsonUtil.get_bool(JsonUtil.get_dict(ob, "ai"), "calls"):
			continue
		if Vector2(o.pos - g.pos).length() > _call or sight.path_steps(o.pos, g.pos, roundi(_call * 1.5)) < 0:
			continue
		o.stimulus = pcell
		o.awareness = maxf(o.awareness, _suspect_at)
		_go_state(o, INVESTIGATE)
		o.called = true


func _behavior(g: FieldMonsters.Group) -> Dictionary:
	return JsonUtil.get_dict(_db.get_entry("monsters", g.leader()), "behavior")
