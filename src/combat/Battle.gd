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
var killed: Array[String] = []  ## 쓰러뜨린 몬스터 id (도감·경험치는 M3)

var _announced: Dictionary = {}  # Combatant -> true (쓰러짐을 알렸다)


func _init(p_db: GameDatabase, p_effects: EffectRegistry, p_ai: ScriptRegistry, p_rng: Rng) -> void:
	db = p_db
	effects = p_effects
	ai = p_ai
	rng = p_rng
	timeline = Timeline.new(float(db.bal("combat.gauge_threshold", 100)), float(db.bal("combat.min_speed", 1)),
		float(db.bal("combat.speed_base", 0)))


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
		var label := " " + "ABCDEFGH"[mini(int(seen[id]) - 1, 7)] if int(total[id]) > 1 else ""
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
	var bonus := float(db.bal("combat.ambush_gauge", 50))
	var names := PackedStringArray()
	for u in units:
		u.gauge = bonus if (u.side == Combatant.SIDE_PARTY) == party_first else 0.0
		if u.side == Combatant.SIDE_ENEMY:
			names.append(u.label())
	BattleRules.on_start(self)
	message.emit("combat.start" if party_first else "combat.start_ambushed", {"enemies": ", ".join(names)}, "danger")
	BattleKnowledge.on_start(self)


func side_units(side: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for u in units:
		if u.side == side and u.is_active():
			out.append(u)
	return out


func opponents(c: Combatant) -> Array[Combatant]:
	return side_units(Combatant.SIDE_ENEMY if c.side == Combatant.SIDE_PARTY else Combatant.SIDE_PARTY)


func is_player_controlled(c: Combatant) -> bool:
	return c.side == Combatant.SIDE_PARTY


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
		var stunned := c.actor.statuses.has_flag("skip_turn")
		c.actor.advance_turns(1.0)
		c.tick_cooldowns()
		_after_effects()
		if not result.is_empty() or not c.is_active():
			continue
		if stunned:
			message.emit("combat.skip", {"name": c.label()}, "warn")
			timeline.consume(c)
			continue
		current = c
		phase = PHASE_AWAIT
		event.emit({"type": "turn", "unit": c})
		return c
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
	var delay := 0.0
	match str(action.get("kind", "")):
		"skill":
			delay = _use_skill(c, str(action.get("skill", BASIC_ATTACK)), action.get("target"), bool(action.get("aim_weak", false)))
		"guard":
			c.actor.statuses.apply("guarding")
			message.emit("combat.guard", {"name": c.label()}, "info")
		"item":
			_use_item(c, str(action.get("item", "")))
		"flee":
			try_flee(c)
	phase = PHASE_TURN_END
	c.acted += 1
	c.was_hit = false
	timeline.consume(c, delay)
	current = null
	event.emit({"type": "turn_end", "unit": c})
	_after_effects()
	phase = PHASE_ENDED if not result.is_empty() else PHASE_IDLE
	return true


## 스킬을 쓸 수 있으면 "", 아니면 이유(문자열 키).
func can_use(c: Combatant, skill_id: String) -> String:
	if skill_id != BASIC_ATTACK and c.actor.statuses.has_flag("no_skills"):
		return "combat.reason_sealed"
	if c.cooldowns.has(skill_id) or not BattleRules.uses_left(self, c, skill_id):
		return "combat.reason_cooldown"
	if not c.actor.pool.can_afford(JsonUtil.get_dict(db.get_entry("skills", skill_id), "cost")):
		return "combat.reason_cost"
	return ""


func flee_chance(c: Combatant) -> float:
	var fastest := 0.0
	for o in opponents(c):
		fastest = maxf(fastest, o.actor.stats.get_value("agi"))
	var k := float(db.bal("combat.flee_base", 0.5)) + (c.actor.stats.get_value("agi") - fastest) * float(db.bal("combat.flee_agi_coef", 0.03))
	k = BattleRules.flee_adjust(self, c, k)
	if is_zero_approx(k):
		return 0.0
	return clampf(k, float(db.bal("combat.flee_min", 0.05)), float(db.bal("combat.flee_max", 0.95)))


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
	for t in _targets(c, JsonUtil.get_str(sk, "target"), chosen):
		var ctx := EffectContext.new(db, c.actor, t.actor, rng)
		ctx.info = {"aim_weak": aim_weak}
		ctx.registry = effects
		effects.apply_all(ctx, JsonUtil.get_array(sk, "effects"))
		_relay(ctx, c)
	return JsonUtil.get_float(sk, "delay_cost")


func _use_item(c: Combatant, item_id: String) -> void:
	var ctx := ItemUser.use(effects, c.actor, item_id, rng)
	if ctx == null:
		message.emit("combat.no_item", {"name": c.label()}, "warn")
		return
	message.emit("combat.use_item", {"name": c.label(), "item": DataNames.entry(db, "items", item_id)}, "system")
	_relay(ctx, c)


func _targets(c: Combatant, kind: String, chosen: Variant) -> Array[Combatant]:
	var foes := opponents(c)
	var picked: Combatant = chosen as Combatant if chosen is Combatant and (chosen as Combatant).is_active() else null
	var out: Array[Combatant] = []
	match kind:
		"self":
			out.append(c)
		"enemy_all":
			out = foes
		"ally_all":
			out = side_units(c.side)
		"ally_single":
			out.append(picked if picked != null and picked.side == c.side else c)
		"any_single":
			if picked != null:
				out.append(picked)
		"enemy_row":
			var row := picked.row if picked != null else "front"
			for u in foes:
				if u.row == row:
					out.append(u)
		_:
			if picked == null or picked.side == c.side or not BattleRules.is_targetable(self, c, picked):
				picked = rng.pick(BattleRules.targetable(self, c)) as Combatant
			if picked != null:
				out.append(picked)
	return out


func _relay(ctx: EffectContext, c: Combatant) -> void:
	BattleRules.relay(self, ctx, c)


func try_flee(c: Combatant) -> void:
	if rng.chance(flee_chance(c)):
		c.fled = true
		message.emit("combat.flee_ok", {"name": c.label()}, "warn")
		event.emit({"type": "fled", "unit": c})
	else:
		message.emit("combat.flee_fail", {"name": c.label()}, "info")


func _after_effects() -> void:
	for u in units:
		if u.actor.dead and not _announced.has(u):
			_announced[u] = true
			if u.actor is Monster:
				killed.append((u.actor as Monster).monster_id)
				message.emit("combat.down_monster", {"name": u.label()}, "good")
			else:
				message.emit("combat.down_party", {"name": u.label()}, "danger")
			event.emit({"type": "down", "unit": u})
	_check_end()


func _check_end() -> void:
	if not result.is_empty():
		return
	if side_units(Combatant.SIDE_PARTY).is_empty():
		var any_fled := units.any(func(u: Combatant) -> bool: return u.side == Combatant.SIDE_PARTY and u.fled and not u.actor.dead)
		result = RESULT_FLED if any_fled else RESULT_DEFEAT
	elif side_units(Combatant.SIDE_ENEMY).is_empty():
		result = RESULT_VICTORY
	if not result.is_empty():
		phase = PHASE_ENDED
		current = null
		message.emit("combat.end_" + result, {}, "good" if result == RESULT_VICTORY else "warn")
		event.emit({"type": "end", "result": result})
