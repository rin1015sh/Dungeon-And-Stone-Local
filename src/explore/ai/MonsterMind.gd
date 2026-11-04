class_name MonsterMind
extends RefCounted
## 필드 몬스터 무리의 판단(순수 로직 — MonsterSteering이 가진다, V22 → 단순화 V28).
## 사용자 2026-11-02 "그냥 플레이어 화면 안에 들어오면 어그로 · 이리저리 움직이면 바로 어그로가 풀린다":
##   보기 = 플레이어 화면 사각형 안(MonsterSight.on_screen — 은신만큼 준다, 쫓는 중엔 chase_keep_tiles만큼 넓게)뿐.
##   바라보는 쪽·벽·경계도·의심·발소리는 보지 않는다 — 화면에 들어오면 바로 추적, 화면 안에 있는 동안은 놓치지 않는다
##   (영역 leash_tiles도 화면 안에서는 보지 않는다).
##
##   대기(idle)      순찰(MonsterPatrol). 화면에 들어오면 추적.
##   추적(chase)     화면 안이면 곧장(거리 장 — MonsterSteering). 화면 밖으로 벗어나면 기억으로 쫓는다(MonsterHunt):
##                   마지막으로 본 칸 → 움직이던 쪽으로 내다본 칸 → 수색. 기억은 ai.memory_hours(× 성격 tenacity) — 그새 화면에 다시 들면 계속.
##                   영역(leash_tiles)을 벗어난 채 놓치면 바로 귀환.
##   수색(search)    둘레 몇 곳을 돌며 둘러본다(MonsterHunt.sweep_points). ai.search_hours가 지나면 귀환.
##   조사(investigate) 동료가 부른 칸까지 달려가 둘러본다.
##   귀환(return)    집으로(영역 이탈·도망친 플레이어 유예·수색 끝).
##
## 무리 부르기: 추적을 시작한 무리(behavior ai.calls)는 길 거리 ai.call_tiles 안의 같은 편(같은 종 또는 ai.calls) 무리를 부른다 —
##   불린 무리는 그 자리를 조사하러 온다(화면에 들면 쫓는다).
## 성격(behavior ai — 없으면 1): tenacity(기억·수색 길이) · calls(동료를 부르는가).
## 예외는 그대로: 숨어 기다리는 몬스터(reveal_radius_m)·먼저 덤비지 않는 몬스터(aggressive false — 구울)는 behavior aggro_radius_m 안이어야 보고,
##   passive_unless_status는 그 상태가 없으면 보지 않는다. 보스(Group.boss)는 생각하지 않는다(FieldMonsters가 따로 — 방에서 기다린다).

const IDLE := "idle"
const CHASE := "chase"
const RETURN := "return"
const SEARCH := "search"
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
var _memory: float = 0.5
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
	_memory = float(db.bal("monsters.ai.memory_hours", 0.5))
	_search = float(db.bal("monsters.ai.search_hours", 0.45))
	_investigate = float(db.bal("monsters.ai.investigate_hours", 0.15))
	_call = int(db.bal("monsters.ai.call_tiles", 12))
	_speed = db.bal("monsters.ai.speed", {})


## 플레이어 자리(연속 좌표)를 받아 움직임을 잰다(갱신마다 한 번).
func track_player(p: Vector2, hours: float) -> void:
	if _plast.x >= 0.0 and hours > 0.0:
		_pvel = _pvel.lerp((p - _plast) / hours, clampf(hours / 0.05, 0.0, 1.0))
	_plast = p


## 그 상태에서 걷는 빠르기 배율(ai.speed).
func speed(g: FieldMonsters.Group) -> float:
	if g.called and g.state == INVESTIGATE:
		return float(_speed.get(CHASE, 1.0))  # 동료가 불러 달려온다
	return float(_speed.get(g.state, 1.0))


## 한 번 생각한다(걷기 전·뒤에 FieldMonsters가 부른다). 추적을 새로 시작했으면 true(소리 — alerted).
func think(g: FieldMonsters.Group, p: Vector2, pcell: Vector2i, _hours: float, now: float) -> bool:
	if g.boss != "":
		return false
	var before := g.state
	var beh := _behavior(g)
	var leash := JsonUtil.get_int(beh, "leash_tiles")
	var away := leash > 0 and Vector2(g.pos - g.home).length() > leash
	g.sees = false
	if g.grace_until > now and not is_equal_approx(g.grace_until, g.flee_until):  # 도주 유예는 물러나지 않는다(C25 — 사용자 2026-11-04 "도주시 적 도망치는거 없애")
		_go_state(g, RETURN)
	elif not g.hostile():
		pass
	elif g.alert_until > now:
		_saw(g, pcell, now)  # 사건(은닉처 경보·매복)으로 자리를 안다
		_go_state(g, CHASE)
	elif _visible(g, pcell, beh):
		g.sees = true  # 화면 안 — 바로 쫓고, 화면 안에 있는 동안은 놓치지 않는다
		_saw(g, pcell, now)
		_go_state(g, CHASE)
	elif away and g.state != RETURN and g.state != IDLE:
		_go_state(g, RETURN)  # 영역 밖에서 놓쳤다 — 바로 돌아간다
	elif g.state == CHASE and now - g.seen_at > _memory * JsonUtil.get_float(JsonUtil.get_dict(beh, "ai"), "tenacity", 1.0):
		_go_state(g, SEARCH)
	if g.state == RETURN and g.pos == g.home and g.waypoint.x < 0.0:
		_go_state(g, IDLE)
	_plan(g, now, beh)
	var started := g.state == CHASE and before != CHASE
	if started:
		_call_allies(g, pcell, beh)
	return started


## 무리 g가 지금 플레이어를 볼 수 있는가(상태·은신·숨는 몬스터 조건 포함 — 테스트·디버그).
func can_see(g: FieldMonsters.Group, p: Vector2) -> bool:
	return _visible(g, Kinematics.cell_of(p), _behavior(g))


## 지금 보이는가: 화면 안(은신만큼 좁게, 쫓는 중엔 조금 넓게) + 숨는·먼저 덤비지 않는 몬스터는 aggro_radius_m 안 + 상태 조건.
func _visible(g: FieldMonsters.Group, pcell: Vector2i, beh: Dictionary) -> bool:
	var need := JsonUtil.get_str(beh, "passive_unless_status")
	if not need.is_empty() and not marks.has(need):
		return false
	var shrink := 0.0 if JsonUtil.get_bool(beh, "ignores_stealth") else stealth
	var chasing := g.state == CHASE
	if not sight.on_screen(Vector2(g.pos - pcell), shrink, chasing):
		return false
	if not chasing and _lurks(beh) and Vector2(g.pos - pcell).length() > JsonUtil.get_float(beh, "aggro_radius_m", 2.0) / _mpt * (1.0 - shrink):
		return false
	return true


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


func _go_state(g: FieldMonsters.Group, state: String) -> void:
	if g.state == state:
		return
	g.state = state
	g.phase = ""
	g.called = g.called and state == INVESTIGATE
	g.waypoint = Vector2(-1, -1)  # 상태가 바뀌면 새로 길을 정한다
	_patrol.enter(g)


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
		_go_state(o, INVESTIGATE)
		o.called = true


func _behavior(g: FieldMonsters.Group) -> Dictionary:
	return JsonUtil.get_dict(_db.get_entry("monsters", g.leader()), "behavior")
