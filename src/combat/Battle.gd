class_name Battle
extends RefCounted
## 전투 한 판(순수 로직). CTB Timeline으로 차례를 정하고 행동(스킬·방어·아이템·도주)을 적용한다.
## 아군 차례에는 화면이 행동을 골라 act()를 부르고, 적 차례에는 ai_action()을 골라 act()를 부른다.
## 화면은 message(문자열 키)·event(연출용 사건) 시그널만 받는다. 오토로드를 참조하지 않는다.
##
## 상태(phase): idle(차례 사이) → await_input(next_turn이 차례를 정함, 행동 대기)
##   → executing(act 적용 중) → turn_end(게이지 소모·쓰러짐 판정) → idle … → ended(결과 확정).
## CTB라 라운드가 따로 없다 — "차례 종료"가 라운드 종료 처리(쿨타임·지속시간은 자기 차례 시작 때)를 맡는다.
## act()는 await_input 상태의 현재 차례에만 한 번 적용된다(중복 실행 방지). 잘못된 행동은 차례를 쓰지 않고 false.

signal message(key: String, args: Dictionary, kind: String)
signal event(e: Dictionary)

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const BASIC_ATTACK := "basic_attack"
const RESULT_VICTORY := "victory"
const RESULT_DEFEAT := "defeat"
const RESULT_FLED := "fled"
const MAX_SKIPS := 1000
const PHASE_IDLE := "idle"
const PHASE_AWAIT := "await_input"
const PHASE_EXECUTING := "executing"
const PHASE_TURN_END := "turn_end"
const PHASE_ENDED := "ended"

var db: GameDatabase
var effects: EffectRegistry
var ai: ScriptRegistry
var rng: Rng
var units: Array[Combatant] = []
var timeline: Timeline
var current: Combatant = null
var result: String = ""
var phase: String = PHASE_IDLE
var turns: int = 0
var killed: Array[String] = []  ## 쓰러뜨린 몬스터 id (도감·경험치)
var killed_colors: Array[String] = []  ## killed와 같은 순서: 타입이 정수 색을 정하면 그 색(본 나이트 types[].essence_color), 아니면 ""
var patterns: ScriptRegistry = null  ## 보스 패턴(src/combat/patterns/) — 없으면 BossHooks가 만든다
var objective: Dictionary = {}       ## 전투 목표(BattleObjective — 생존 웨이브). 비면 없음
## 지금까지 나온 메시지 {key, args, kind} — 화면이 시그널을 잇기 전(전투 시작 안내·수호자 대사)의 것도 다시 보여 준다.
var history: Array[Dictionary] = []

var _announced: Dictionary = {}  # Combatant -> true (쓰러짐을 알렸다)
var _busy: int = 0               # 행동·차례 처리 중이면 > 0 — 그동안 finish는 처리가 끝난 뒤 한 번에
var _finish_req: String = ""


func _init(p_db: GameDatabase, p_effects: EffectRegistry, p_ai: ScriptRegistry, p_rng: Rng) -> void:
	db = p_db
	effects = p_effects
	ai = p_ai
	rng = p_rng
	timeline = Timeline.new(float(db.bal("combat.gauge_threshold", 100)), float(db.bal("combat.min_speed", 1)),
		float(db.bal("combat.speed_base", 0)))
	message.connect(_record)


func _record(key: String, args: Dictionary, kind: String) -> void:
	history.append({"key": key, "args": args, "kind": kind})


## 탐험 조우로 전투를 꾸린다. 같은 몬스터가 여럿이면 이름 뒤에 A, B, C를 붙인다.
static func from_encounter(p_db: GameDatabase, regs: ContentRegistries, p_rng: Rng, party: Array[Actor],
		monster_ids: Array, party_first: bool) -> Battle:
	var b := Battle.new(p_db, regs.effects, regs.ai_conditions, p_rng)
	for a in party:
		b.add(a, Combatant.SIDE_PARTY)
	var total := {}
	for id: Variant in monster_ids:
		total[id] = int(total.get(id, 0)) + 1
	var seen := {}
	for id: Variant in monster_ids:
		seen[id] = int(seen.get(id, 0)) + 1
		var label := " " + LETTERS[mini(int(seen[id]) - 1, LETTERS.length() - 1)] if int(total[id]) > 1 else ""
		var m := Monster.create(p_db, str(id), label)
		b.add(m, Combatant.SIDE_ENEMY, JsonUtil.get_str(m.behavior(), "row", "front"))
	b.start(party_first)
	return b


func add(actor: Actor, side: int, row: String = "front") -> Combatant:
	var c := Combatant.new(actor, side, row, units.size())
	units.append(c)
	timeline.add(c)
	return c


## 먼저 발견한 쪽이 행동 게이지를 앞서 시작한다.
func start(party_first: bool) -> void:
	var names := PackedStringArray()
	for u in units:
		u.gauge = 0.0
		if u.side == Combatant.SIDE_ENEMY:
			names.append(u.label())
	message.emit("combat.start" if party_first else "combat.start_ambushed", {"enemies": ", ".join(names)}, "danger")
	BattleRules.on_start(self)  # 동반 소환(start_summons)도 여기서 생긴다 — 선공 게이지는 그 뒤에 준다
	var bonus := float(db.bal("combat.ambush_gauge", 50))
	for u in units:
		if (u.side == Combatant.SIDE_PARTY) == party_first:
			u.gauge += bonus
	BossHooks.on_start(self)
	BattleKnowledge.on_start(self)


func side_units(side: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for u in units:
		if u.side == side and u.is_active():
			out.append(u)
	return out


func opponents(c: Combatant) -> Array[Combatant]:
	return side_units(Combatant.SIDE_ENEMY if c.side == Combatant.SIDE_PARTY else Combatant.SIDE_PARTY)


## 아군 소환수(전투 중 생겨난 개체)는 AI가 움직인다.
func is_player_controlled(c: Combatant) -> bool:
	return c.side == Combatant.SIDE_PARTY and not c.summoned


func preview(n: int) -> Array[Combatant]:
	return timeline.preview(n)


## 다음 차례로 넘긴다. 차례 시작 처리(주기 효과·지속시간·재생·쿨타임) 뒤 기절이면 건너뛴다.
## 이미 행동을 기다리는 차례가 있으면 그 차례를 그대로 돌려준다(게이지를 두 번 진행하지 않는다).
func next_turn() -> Combatant:
	if phase == PHASE_AWAIT and current != null:
		return current
	for i in MAX_SKIPS:
		if not result.is_empty():
			return null
		var c := timeline.next()
		if c == null:
			_check_end()
			return null
		turns += 1
		_busy += 1
		var stunned := c.actor.statuses.has_flag("skip_turn") or BattleRules.fear_skip(self, c)
		if not bool(c.memo.get("in_extra", false)):  # 추가 행동(같은 라운드의 두 번째 차례)은 지속시간·쿨타임을 다시 세지 않는다
			var hp_before := c.actor.pool.get_current("hp")
			c.actor.advance_turns(1.0)
			BattleRules.report_dot(self, c, hp_before)
			c.tick_cooldowns()
		BattleDelayed.tick(self, c)
		_after_effects()
		if _finish_req.is_empty() and c.is_active() and stunned:
			message.emit("combat.skip", {"name": c.label()}, "warn")
			timeline.consume(c)
			BattlePassives.turn_end(self, c)
			BossHooks.turn_end(self, c, true)
			_after_effects()
			BattleObjective.after_turn(self, c)  # 건너뛴 차례도 생존 라운드로 센다
			event.emit({"type": "turn_end", "unit": c})
			_after_effects()
			_end_busy()
			continue
		_end_busy()
		if not result.is_empty() or not c.is_active():
			continue
		current = c
		phase = PHASE_AWAIT
		event.emit({"type": "turn", "unit": c})
		return c
	finish(RESULT_FLED)  # 아무도 움직일 수 없다(모두 기절 등) — 전투를 거둔다
	return null


## 행동 적용. {"kind": "skill", "skill": id, "target": Combatant, "aim_weak": bool}
##          | {"kind": "guard"} | {"kind": "item", "item": id} | {"kind": "flee"}
## 적용했으면 true. 현재 차례가 아니거나 이미 처리했거나 행동이 잘못됐으면 false(차례를 쓰지 않는다).
func act(c: Combatant, action: Dictionary) -> bool:
	if not result.is_empty() or c == null or c != current or phase != PHASE_AWAIT:
		return false
	var why := ActionCheck.reason(self, c, action)
	if not why.is_empty():
		message.emit(why, {"name": c.label()}, "warn")
		return false
	phase = PHASE_EXECUTING
	_busy += 1
	var delay := 0.0
	match str(action.get("kind", "")):
		"skill":
			delay = _use_skill(c, str(action.get("skill", BASIC_ATTACK)), action.get("target"), bool(action.get("aim_weak", false)))
		"guard":
			c.actor.statuses.apply("guarding")
			message.emit("combat.guard", {"name": c.label()}, "info")
		"item":
			if not _use_item(c, str(action.get("item", ""))):
				phase = PHASE_AWAIT  # 아무 일도 일어나지 않았다(생명력이 이미 가득 등) — 차례를 쓰지 않는다
				_busy -= 1
				return false
		"flee":
			try_flee(c)
	phase = PHASE_TURN_END
	var hp_before := c.actor.pool.get_current("hp")
	c.actor.statuses.on_acted()  # 출혈: 움직일수록 흘린다
	BattleRules.report_dot(self, c, hp_before)
	c.acted += 1
	c.was_hit = false
	timeline.consume(c, delay)
	BattlePassives.turn_end(self, c)
	BossHooks.turn_end(self, c, false)
	_after_effects()  # 마지막 적을 쓰러뜨렸으면 증원보다 승리가 먼저
	BattleObjective.after_turn(self, c)
	current = null
	event.emit({"type": "turn_end", "unit": c})
	_after_effects()
	_end_busy()
	phase = PHASE_ENDED if not result.is_empty() else PHASE_IDLE
	return true


## 스킬을 쓸 수 있으면 "", 아니면 이유(문자열 키).
func can_use(c: Combatant, skill_id: String) -> String:
	if skill_id != BASIC_ATTACK and c.actor.statuses.has_flag("no_skills") \
			and not JsonUtil.get_bool(db.get_entry("skills", skill_id), "innate"):  # 대화·조사는 이능이 아니다(seal_skill과 같게)
		return "combat.reason_sealed"
	if c.cooldowns.has(skill_id) or not BattleRules.uses_left(self, c, skill_id):
		return "combat.reason_cooldown"
	var sk := db.get_entry("skills", skill_id)
	if not c.actor.pool.can_afford(JsonUtil.get_dict(sk, "cost")):
		return "combat.reason_cost"
	if c.actor.pool.get_ratio("hp") <= JsonUtil.get_float(sk, "min_hp_ratio", 0.0):
		return "combat.reason_cost"  # 생명력을 대가로 치르는 스킬(정수판 분열): 그만큼 남아 있어야 쓴다
	return ""


## 끝났거나(result) 끝내기로 정해졌다(처리 중 finish).
func is_over() -> bool:
	return not result.is_empty() or not _finish_req.is_empty()


func flee_chance(c: Combatant) -> float:
	return BattleRules.flee_chance(self, c)


## 몬스터 AI 행동(규칙은 MonsterAi).
func ai_action(c: Combatant) -> Dictionary:
	return MonsterAi.choose(self, c)


func unit_of(actor: Actor) -> Combatant:
	for u in units:
		if u.actor == actor:
			return u
	return null


func _use_skill(c: Combatant, skill_id: String, chosen: Variant, aim_weak: bool) -> float:
	var sk := db.get_entry("skills", skill_id)
	var why := can_use(c, skill_id)
	if sk.is_empty() or not why.is_empty():
		message.emit(why if not why.is_empty() else "combat.reason_unknown", {"name": c.label()}, "warn")
		return 0.0
	c.actor.pool.spend(JsonUtil.get_dict(sk, "cost"), "skill:" + skill_id)
	c.uses[skill_id] = int(c.uses.get(skill_id, 0)) + 1
	var cooldown := JsonUtil.get_int(sk, "cooldown")
	if cooldown > 0:
		c.cooldowns[skill_id] = cooldown + 1
	if skill_id != BASIC_ATTACK:
		message.emit("combat.use_skill", {"name": c.label(), "skill": JsonUtil.get_str(sk, "name_ko", skill_id)}, "system")
	var kind := JsonUtil.get_str(sk, "target")
	var fx := BattlePassives.skill_effects(self, c, skill_id, sk)
	var targets := BattleTargets.resolve(self, c, kind, chosen)
	BattleRules.apply_cover(self, c, kind, targets)  # 대신 맞기
	var mis := BattleTargets.misdirect(self, c, kind) if not targets.is_empty() else {}
	if not mis.is_empty():
		targets.clear()
		targets.append(mis["target"] as Combatant)
		fx = BattleTargets.boosted(fx, mis)
		message.emit("combat.misdirect", {"name": c.label(), "target": (mis["target"] as Combatant).label()}, "danger")
	var said := history.size()
	var info := {"aim_weak": aim_weak, "skill_id": skill_id, "skill_name": JsonUtil.get_str(sk, "name_ko", skill_id),  # 대상들이 함께 쓴다(예고 안내 한 번)
		"summons": side_units(c.side).filter(func(u: Combatant) -> bool: return u.summoned and u.is_active()).size()}
	for t in targets:
		if c.actor.dead:
			break  # 반사·반격으로 쓰러졌다 — 남은 대상은 치지 못한다
		var ctx := EffectContext.new(db, c.actor, t.actor, rng)
		ctx.info = info
		ctx.registry = effects
		effects.apply_all(ctx, fx)
		_relay(ctx, c)
	if fx.any(func(e: Variant) -> bool: return e is Dictionary and JsonUtil.get_str(e, "type") == "damage"):
		BattleRules.consume_on_attack(self, c)  # 진군 명령 등: 스킬 한 번(광역·연타 전체)에 쓰고 사라진다
	if skill_id != BASIC_ATTACK and history.size() == said:  # 확률 상태가 안 걸리는 등 조용히 끝났다 — 썼다는 것은 알린다
		message.emit("combat.no_effect", {"name": c.label(), "skill": JsonUtil.get_str(sk, "name_ko", skill_id)}, "info")
	return JsonUtil.get_float(sk, "delay_cost")


## 아이템을 쓴다. 효과가 하나도 일어나지 않았으면(소모도 없음) 이유만 알리고 false.
func _use_item(c: Combatant, item_id: String) -> bool:
	var ctx := ItemUser.use(effects, c.actor, item_id, rng, null, {"in_battle": true})
	if ctx == null:
		message.emit("combat.no_item", {"name": c.label()}, "warn")
		return false
	if not ctx.success:
		for m: Dictionary in ctx.messages:
			message.emit(str(m["key"]), m["args"], str(m["kind"]))
		return false
	message.emit("combat.use_item", {"name": c.label(), "item": DataNames.entry(db, "items", item_id)}, "system")
	_relay(ctx, c)
	return true


## 전투 중 새로 생긴 몬스터의 이름 꼬리표: 같은 몬스터가 이미 n마리 있었으면 n+1번째 글자(" B", " C" …).
func spawn_label(monster_id: String) -> String:
	var n := 0
	for u in units:
		if u.actor is Monster and (u.actor as Monster).monster_id == monster_id:
			n += 1
	return " " + (LETTERS[n] if n < LETTERS.length() else str(n + 1))


func _relay(ctx: EffectContext, c: Combatant) -> void:
	BattleRules.relay(self, ctx, c)


func try_flee(c: Combatant) -> void:
	if rng.chance(flee_chance(c)):
		c.fled = true
		message.emit("combat.flee_ok", {"name": c.label()}, "warn")
		event.emit({"type": "fled", "unit": c})
		BattleRules.left_battle(self, c)
	else:
		message.emit("combat.flee_fail", {"name": c.label()}, "info")


func _after_effects() -> void:
	for i in MAX_SKIPS:  # 쓰러지며 터지는 것(death_effects)·페이즈 진입 시전이 또 쓰러뜨릴 수 있다
		var downed := false
		for u in units.duplicate():
			if u.actor.dead and not _announced.has(u):
				_announced[u] = true
				downed = true
				if u.side == Combatant.SIDE_ENEMY and u.actor is Monster:
					killed.append((u.actor as Monster).monster_id)
					killed_colors.append(BattlePassives.type_essence_color(u.actor as Monster))
					message.emit("combat.down_monster", {"name": u.label()}, "good")
				elif u.summoned:
					message.emit("combat.down_summon", {"name": u.label()}, "warn")
				else:
					message.emit("combat.down_party", {"name": u.label()}, "danger")
				event.emit({"type": "down", "unit": u})
				BattleDelayed.drop(self, u)
				BattlePassives.on_down(self, u)
		if downed:
			BattlePassives.refresh_auras(self)  # 오러를 주던 개체가 쓰러지면 버프도 사라진다
		BossHooks.check_all(self)
		if not units.any(func(u: Combatant) -> bool: return u.actor.dead and not _announced.has(u)):
			break
	_check_end()


## 승패: 적이 모두 없으면 승리. 아군은 소환수가 아닌 참가자가 모두 없으면 끝(도망친 사람이 있으면 도주).
func _check_end() -> void:
	if not result.is_empty() or not _finish_req.is_empty():
		return
	var core := units.filter(func(u: Combatant) -> bool: return u.side == Combatant.SIDE_PARTY and not u.summoned)
	if not core.any(func(u: Combatant) -> bool: return u.is_active()):
		var any_fled := core.any(func(u: Combatant) -> bool: return u.fled and not u.actor.dead)
		finish(RESULT_FLED if any_fled else RESULT_DEFEAT)
	elif side_units(Combatant.SIDE_ENEMY).is_empty():
		finish(RESULT_VICTORY)


## 전투를 끝낸다(전멸·도주 판정 또는 목표 달성). 행동을 처리하는 중이면 그 처리가 끝난 뒤에 한 번 끝낸다.
func finish(r: String) -> void:
	if not result.is_empty() or not _finish_req.is_empty():
		return
	_finish_req = r
	if _busy <= 0:
		_do_finish()


func _end_busy() -> void:
	_busy = maxi(0, _busy - 1)
	if _busy == 0 and not _finish_req.is_empty() and result.is_empty():
		_do_finish()


func _do_finish() -> void:
	result = _finish_req
	phase = PHASE_ENDED
	current = null
	BattleRules.cleanup(self)
	message.emit("combat.end_" + result, {}, "good" if result == RESULT_VICTORY else "warn")
	event.emit({"type": "end", "result": result})
