class_name BossHooks
extends RefCounted
## 보스 공통 처리(Battle이 부른다): 패턴 찾기, 페이즈 전환, 라운드 종료, 추가 행동.
## 몬스터 데이터:
##   "pattern": "<src/combat/patterns/ 파일 이름>", "pattern_params": { … 패턴 수치 … }
##   "phases": [{"id": "p1", "hp_above": 0.7, "message": "<문자열 키>", "self_statuses": [..], "foe_statuses": [..],
##               "remove_foe_statuses": [..], "remove_self_statuses": [..], "self_passives": [{패시브}],
##               "target_rule": "guard_front", "round_effects": [{효과 — 라운드 끝에 적 전원에게}],
##               "cast": "<스킬 id — 들어설 때 한 번 자동으로 쓴다(시체골렘 살점폭발)>"}, …]
##   위에서부터 체력 비율이 hp_above보다 큰 첫 페이즈. 페이즈는 앞으로만 간다.
##   한 번에 여러 구간을 넘으면 건너뛴 페이즈의 상태·패시브·대상 규칙만 쌓고, 메시지·시전(cast)은 마지막 페이즈만(ASSUMPTIONS GM3).
##   self_passives의 modifiers는 붙인다(출처 "phase:<패시브 id>").
##   기절 등으로 건너뛴 라운드는 세지만 패턴의 행동(주기 스킬·소환)은 하지 않는다(BossPattern.on_round_end의 skipped).
## 상태는 Combatant.memo: {round, phase, in_extra, …패턴이 쓰는 값}.

const PATTERN_DIR := "res://src/combat/patterns"


static func pattern(b: Battle, c: Combatant) -> BossPattern:
	var id := JsonUtil.get_str(_def(c), "pattern")
	if id.is_empty():
		return null
	if b.patterns == null:
		b.patterns = ScriptRegistry.new(PATTERN_DIR)
	return b.patterns.instance(id) as BossPattern


static func params(c: Combatant) -> Dictionary:
	return JsonUtil.get_dict(_def(c), "pattern_params")


static func phase(c: Combatant) -> Dictionary:
	for ph: Variant in JsonUtil.get_array(_def(c), "phases"):
		if ph is Dictionary and JsonUtil.get_str(ph, "id") == str(c.memo.get("phase", "")):
			return ph
	return {}


static func on_start(b: Battle) -> void:
	for u in b.units.duplicate():
		on_join(b, u)


## 패턴·페이즈가 있는 개체의 시작 처리(전투 시작, 또는 전투 중에 들어왔을 때).
static func on_join(b: Battle, u: Combatant) -> void:
	if u.memo.has("round"):
		return
	var p := pattern(b, u)
	if p == null and JsonUtil.get_array(_def(u), "phases").is_empty():
		return
	u.memo["round"] = 0
	u.memo["phase"] = ""
	if p != null:
		p.on_start(b, u)
	check_phase(b, u)


## 체력 비율에 맞는 페이즈로 옮긴다(앞으로만). 바뀌었으면 true.
static func check_phase(b: Battle, c: Combatant) -> bool:
	var phases := JsonUtil.get_array(_def(c), "phases")
	if phases.is_empty() or not c.is_active():
		return false
	var ratio := c.actor.pool.get_ratio("hp")
	var cur := -1
	var want := -1
	for i in phases.size():
		var ph: Dictionary = phases[i]
		if JsonUtil.get_str(ph, "id") == str(c.memo.get("phase", "")):
			cur = i
		if want < 0 and ratio > JsonUtil.get_float(ph, "hp_above", 0.0):
			want = i
	if want < 0:
		want = phases.size() - 1
	if want <= cur:
		return false
	for i in range(cur + 1, want + 1):
		_enter(b, c, phases[i], i == want)
	return true


## 체력과 무관하게 그 페이즈로 옮긴다(패턴이 조건을 판단할 때 — 시체골렘의 화염 누적). 앞으로만.
static func enter_phase(b: Battle, c: Combatant, phase_id: String) -> void:
	var phases := JsonUtil.get_array(_def(c), "phases")
	var cur := -1
	var want := -1
	for i in phases.size():
		if JsonUtil.get_str(phases[i], "id") == str(c.memo.get("phase", "")):
			cur = i
		if JsonUtil.get_str(phases[i], "id") == phase_id:
			want = i
	for i in range(cur + 1, want + 1):
		_enter(b, c, phases[i], i == want)


## 페이즈를 다시 본다. 하나라도 바뀌었으면 true.
static func check_all(b: Battle) -> bool:
	var any := false
	for u in b.units.duplicate():
		if not JsonUtil.get_array(_def(u), "phases").is_empty():
			any = check_phase(b, u) or any
	return any


## 보스 차례가 끝났다(skipped = 기절 등으로 건너뜀). 추가 행동이면 라운드를 끝내지 않고 바로 다시 행동하게 한다.
static func turn_end(b: Battle, c: Combatant, skipped: bool) -> void:
	var p := pattern(b, c)
	if p == null or not c.is_active():
		return
	if not skipped and not bool(c.memo.get("in_extra", false)) and p.wants_extra_action(b, c):
		c.memo["in_extra"] = true
		c.gauge += b.timeline.threshold
		b.message.emit("combat.extra_action", {"name": c.label()}, "danger")
		return
	c.memo["in_extra"] = false
	c.memo["round"] = int(c.memo.get("round", 0)) + 1
	var fx := JsonUtil.get_array(phase(c), "round_effects")
	if not fx.is_empty():
		for f in b.opponents(c):
			apply_effects(b, c, f, fx)
	p.on_round_end(b, c, skipped)


## 효과 목록을 c가 target에게 적용하고 결과를 전투에 반영한다.
static func apply_effects(b: Battle, c: Combatant, target: Combatant, fx: Array, info: Dictionary = {}) -> void:
	var ctx := EffectContext.new(b.db, c.actor, target.actor if target != null else null, b.rng)
	ctx.registry = b.effects
	ctx.info = info
	b.effects.apply_all(ctx, fx)
	BattleRules.relay(b, ctx, c)


## last = 이번에 도착한 페이즈(건너뛰는 중간 페이즈는 메시지·시전 없이 상태·패시브만).
static func _enter(b: Battle, c: Combatant, ph: Dictionary, last: bool = true) -> void:
	c.memo["phase"] = JsonUtil.get_str(ph, "id")
	var msg := JsonUtil.get_str(ph, "message")
	if not msg.is_empty() and last:
		b.message.emit(msg, {"name": c.label()}, "danger")
	for st: Variant in JsonUtil.get_array(ph, "remove_self_statuses"):
		c.actor.statuses.remove(str(st))
	for st: Variant in JsonUtil.get_array(ph, "self_statuses"):
		Passives.try_status(b.db, null, c.actor, c.actor, str(st))
	for pa: Variant in JsonUtil.get_array(ph, "self_passives"):
		if pa is Dictionary:
			add_phase_passive(b, c, pa)
	for f in b.opponents(c):
		for st: Variant in JsonUtil.get_array(ph, "remove_foe_statuses"):
			f.actor.statuses.remove(str(st))
		for st: Variant in JsonUtil.get_array(ph, "foe_statuses"):
			Passives.try_status(b.db, null, c.actor, f.actor, str(st))
	if ph.has("target_rule"):
		c.memo["target_rule"] = JsonUtil.get_str(ph, "target_rule")
	var cast := b.db.get_entry("skills", JsonUtil.get_str(ph, "cast"))
	if not cast.is_empty() and last:
		use_skill(b, c, JsonUtil.get_str(ph, "cast"))
	var p := pattern(b, c)
	if p != null:
		p.on_phase(b, c, ph)
	b.event.emit({"type": "phase", "unit": c, "phase": c.memo["phase"]})


## 패턴·페이즈가 스킬을 자동으로 쓴다: 대상 종류(target)를 따른다 — 적 전체·적 하나(무작위)·아군 전체·자기.
static func use_skill(b: Battle, c: Combatant, skill_id: String) -> void:
	var sk := b.db.get_entry("skills", skill_id)
	if sk.is_empty() or not c.is_active():
		return
	b.message.emit("combat.use_skill", {"name": c.label(), "skill": JsonUtil.get_str(sk, "name_ko", skill_id)}, "system")
	var targets: Array[Combatant] = []
	match JsonUtil.get_str(sk, "target"):
		"enemy_all", "ally_all", "enemy_row":
			targets = BattleTargets.resolve(b, c, JsonUtil.get_str(sk, "target"), null)
		"enemy_single", "any_single", "":
			targets = BattleTargets.resolve(b, c, "enemy_single", null)
		_:
			targets = [c]
	var info := {"skill_name": JsonUtil.get_str(sk, "name_ko", skill_id)}  # 대상들이 함께 쓴다(예고 안내 한 번)
	for t in targets:
		apply_effects(b, c, t, JsonUtil.get_array(sk, "effects"), info)


## 페이즈·패턴이 주는 패시브: 패시브를 달고 modifiers도 붙인다(ally_aura는 다시 계산).
static func add_phase_passive(b: Battle, c: Combatant, pa: Dictionary) -> void:
	var src := "phase:" + JsonUtil.get_str(pa, "id")
	c.actor.stats.remove_source(src)
	c.actor.add_passive(pa)
	c.actor.stats.add_modifiers_from_data(src, JsonUtil.get_array(pa, "modifiers"))
	if pa.has("ally_aura"):
		BattlePassives.refresh_auras(b)


static func _def(c: Combatant) -> Dictionary:
	return (c.actor as Monster).def if c != null and c.actor is Monster else {}
