extends BossPattern
## 드레드피어(1층 계층군주, docs/PROMPT_FLOOR1_V2.md §7). 수치는 monsters/dreadfear.json "pattern_params".
## 페이즈 진입(상태·패시브·대상 규칙·역병 확산)은 데이터 phases로 BossHooks가 처리하고, 여기서는:
##   gnaw        라운드 끝마다 적 전원에게 효과(갉아먹는 공포: 공포 게이지 +max(3, 10 − 정신력/10))
##   proliferate {every, status, extra_at, phases} — every 라운드마다 공포의 증식 1중첩, extra_at 중첩부터 라운드당 2회 행동
##   maggots     {every, skill, phases} — every 라운드마다 구더기 소환 스킬
##   hatred      {meter, per_round, phases} — 라운드마다 증오 게이지
##   cycle       {phases, veil_status, veil_rounds, groggy_status, groggy_rounds} — 배신의 장막 → 보호기제(그로기) → 버프 → 반복
##   buffs       [{status, passive?, round_self_effects?}] — 순환이 한 바퀴 돌 때마다 아직 없는 것 하나
##   extra_status 이 상태면 라운드당 2회 행동(P4 사람의 형체)
##   flags       {phase, old_memory_max_party, twisted_status, twisted_passive} — P4 분기 플래그(memo flags)만 남긴다


func on_start(_b: Battle, c: Combatant) -> void:
	c.memo["flags"] = {}
	c.memo["buffs"] = []


func on_phase(b: Battle, c: Combatant, phase: Dictionary) -> void:
	var p := BossHooks.params(c)
	var id := JsonUtil.get_str(phase, "id")
	var cyc := JsonUtil.get_dict(p, "cycle")
	if JsonUtil.get_array(cyc, "phases").has(id) and not c.memo.has("cycle"):
		_start_veil(b, c, cyc)
	elif c.memo.has("cycle") and not JsonUtil.get_array(cyc, "phases").has(id):
		c.memo.erase("cycle")
	var fl := JsonUtil.get_dict(p, "flags")
	if id == JsonUtil.get_str(fl, "phase"):
		_set_flags(b, c, fl)


func wants_extra_action(_b: Battle, c: Combatant) -> bool:
	var p := BossHooks.params(c)
	if c.actor.statuses.has(JsonUtil.get_str(p, "extra_status")):
		return true
	var pr := JsonUtil.get_dict(p, "proliferate")
	return c.actor.statuses.stacks(JsonUtil.get_str(pr, "status")) >= JsonUtil.get_int(pr, "extra_at", 999)


func on_round_end(b: Battle, c: Combatant, skipped: bool = false) -> void:
	var p := BossHooks.params(c)
	var r := int(c.memo["round"])
	for f in b.opponents(c):
		BossHooks.apply_effects(b, c, f, JsonUtil.get_array(p, "gnaw"))
	var pr := JsonUtil.get_dict(p, "proliferate")
	if _due(c, pr, r):
		c.actor.statuses.apply(JsonUtil.get_str(pr, "status"))
		b.message.emit("combat.dread_proliferate", {"name": c.label(), "stacks": c.actor.statuses.stacks(JsonUtil.get_str(pr, "status"))}, "danger")
	var mg := JsonUtil.get_dict(p, "maggots")
	if _due(c, mg, r) and not skipped:
		BossHooks.use_skill(b, c, JsonUtil.get_str(mg, "skill"))
	var ht := JsonUtil.get_dict(p, "hatred")
	if JsonUtil.get_array(ht, "phases").has(str(c.memo.get("phase", ""))):
		BossHooks.apply_effects(b, c, c, [{"type": "meter", "meter": JsonUtil.get_str(ht, "meter"), "amount": JsonUtil.get_float(ht, "per_round"), "to": "self"}])
	for buff: Variant in JsonUtil.get_array(p, "buffs"):
		if buff is Dictionary and c.actor.statuses.has(JsonUtil.get_str(buff, "status")) and not skipped:
			BossHooks.apply_effects(b, c, c, JsonUtil.get_array(buff, "round_self_effects"))
	if c.memo.has("cycle"):
		_advance_cycle(b, c, JsonUtil.get_dict(p, "cycle"))


## every 라운드마다(해당 페이즈일 때만).
func _due(c: Combatant, rule: Dictionary, r: int) -> bool:
	var every := JsonUtil.get_int(rule, "every", 0)
	return every > 0 and r % every == 0 and JsonUtil.get_array(rule, "phases").has(str(c.memo.get("phase", "")))


func _use(b: Battle, c: Combatant, skill_id: String) -> void:
	var sk := b.db.get_entry("skills", skill_id)
	if sk.is_empty():
		return
	b.message.emit("combat.use_skill", {"name": c.label(), "skill": JsonUtil.get_str(sk, "name_ko", skill_id)}, "system")
	BossHooks.apply_effects(b, c, c, JsonUtil.get_array(sk, "effects"))


func _start_veil(b: Battle, c: Combatant, cyc: Dictionary) -> void:
	c.memo["cycle"] = {"stage": "veil", "left": JsonUtil.get_int(cyc, "veil_rounds", 3)}
	for f in b.opponents(c):
		Passives.try_status(b.db, null, c.actor, f.actor, JsonUtil.get_str(cyc, "veil_status"))
	b.message.emit("combat.dread_veil", {"name": c.label()}, "danger")


## 장막(veil_rounds) → 그로기(groggy_rounds) → 버프 하나 → 다시 장막.
func _advance_cycle(b: Battle, c: Combatant, cyc: Dictionary) -> void:
	var st: Dictionary = c.memo["cycle"]
	st["left"] = int(st["left"]) - 1
	if int(st["left"]) > 0:
		return
	if str(st["stage"]) == "veil":
		for f in b.side_units(Combatant.SIDE_PARTY if c.side == Combatant.SIDE_ENEMY else Combatant.SIDE_ENEMY):
			f.actor.statuses.remove(JsonUtil.get_str(cyc, "veil_status"))
		var g := JsonUtil.get_int(cyc, "groggy_rounds", 2)
		c.actor.statuses.apply(JsonUtil.get_str(cyc, "groggy_status"), float(g))
		st["stage"] = "groggy"
		st["left"] = g
		b.message.emit("combat.dread_groggy", {"name": c.label()}, "good")
		return
	_grant_buff(b, c)
	_start_veil(b, c, cyc)


func _grant_buff(b: Battle, c: Combatant) -> void:
	var have: Array = c.memo["buffs"]
	var left: Array = JsonUtil.get_array(BossHooks.params(c), "buffs").filter(func(x: Variant) -> bool:
		return x is Dictionary and not have.has(JsonUtil.get_str(x, "status")))
	if left.is_empty():
		return
	var buff: Dictionary = b.rng.pick(left)
	have.append(JsonUtil.get_str(buff, "status"))
	c.actor.statuses.apply(JsonUtil.get_str(buff, "status"))
	if buff.has("passive"):
		BossHooks.add_phase_passive(b, c, JsonUtil.get_dict(buff, "passive"))
	b.message.emit("combat.dread_buff", {"name": c.label(), "buff": DataNames.entry(b.db, "statuses", JsonUtil.get_str(buff, "status"))}, "danger")


## P4 분기(원작의 두 갈래 — 지금은 플래그와 메시지만): 아군 수, 마비독 보유자.
func _set_flags(b: Battle, c: Combatant, fl: Dictionary) -> void:
	var foes := b.opponents(c)
	var flags: Dictionary = c.memo["flags"]
	if foes.size() <= JsonUtil.get_int(fl, "old_memory_max_party", 5):
		flags["old_memory"] = true
	var st := JsonUtil.get_str(fl, "twisted_status")
	var pa := JsonUtil.get_str(fl, "twisted_passive")
	for f in foes:
		if f.actor.statuses.has(st) or f.actor.passives.any(func(x: Dictionary) -> bool: return str(x.get("id", "")) == pa):
			flags["twisted_memory"] = true
	for k: String in flags:
		b.message.emit("combat.dread_flag_" + k, {"name": c.label()}, "system")


func validate(def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var p := JsonUtil.get_dict(def, "pattern_params")
	for key in ["proliferate", "cycle"]:
		if JsonUtil.get_dict(p, key).is_empty():
			out.append("dreadfear: pattern_params.%s 없음" % key)
	var cyc := JsonUtil.get_dict(p, "cycle")
	for key in ["veil_status", "groggy_status"]:
		if not db.has_entry("statuses", JsonUtil.get_str(cyc, key)):
			out.append("dreadfear: cycle.%s 상태이상 없음" % key)
	if not db.has_entry("skills", JsonUtil.get_str(JsonUtil.get_dict(p, "maggots"), "skill")):
		out.append("dreadfear: maggots.skill 스킬 없음")
	for buff: Variant in JsonUtil.get_array(p, "buffs"):
		if not db.has_entry("statuses", JsonUtil.get_str(buff if buff is Dictionary else {}, "status")):
			out.append("dreadfear: buffs의 상태이상 없음")
	return out
