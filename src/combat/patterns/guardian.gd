extends BossPattern
## 범용 수호자·중간 보스 패턴(G5~). 수치는 몬스터 "pattern_params", 페이즈는 "phases"(BossHooks).
##   every         [{"rounds": 3, "skill": "<스킬>"}] — n라운드마다 그 스킬(적 전체 스킬이면 적 전원, 아니면 자기에게)
##   extra_status  이 상태면 라운드당 2회 행동(예: 체력 50% 이하 페이즈의 self_statuses)
##   mumbles       [문자열 키] — 라운드마다 하나를 무작위로 띄운다(시체골렘 웅얼거림)
##   force_phase   {"status": "<상태>", "phase": "<페이즈>"} — 그 상태가 되면 체력과 무관하게 그 페이즈로
##   per_foe_status {"status": "sacrifice_mark", "buff": "<중첩 상태>"} — 그 상태인 적 수만큼 자기 버프 중첩(캠보르미어 제물)
##   intro         문자열 키 — 전투 시작 대사


func on_start(b: Battle, c: Combatant) -> void:
	var intro := JsonUtil.get_str(BossHooks.params(c), "intro")
	if not intro.is_empty():
		b.message.emit(intro, {"name": c.label()}, "danger")


func wants_extra_action(_b: Battle, c: Combatant) -> bool:
	var st := JsonUtil.get_str(BossHooks.params(c), "extra_status")
	return not st.is_empty() and c.actor.statuses.has(st)


func on_round_end(b: Battle, c: Combatant) -> void:
	var p := BossHooks.params(c)
	var r := int(c.memo["round"])
	for e: Variant in JsonUtil.get_array(p, "every"):
		var ed: Dictionary = e if e is Dictionary else {}
		var n := JsonUtil.get_int(ed, "rounds", 0)
		if n > 0 and r % n == 0:
			_use(b, c, JsonUtil.get_str(ed, "skill"))
	var mumbles := JsonUtil.get_array(p, "mumbles")
	if not mumbles.is_empty():
		b.message.emit(str(b.rng.pick(mumbles)), {"name": c.label()}, "system")
	var fp := JsonUtil.get_dict(p, "force_phase")
	if not fp.is_empty() and c.actor.statuses.has(JsonUtil.get_str(fp, "status")):
		BossHooks.enter_phase(b, c, JsonUtil.get_str(fp, "phase"))
	update_feast(b, c)


## 제물 수만큼 버프 중첩을 맞춘다(낙인을 찍은 직후에도 부른다).
func update_feast(b: Battle, c: Combatant) -> void:
	var pf := JsonUtil.get_dict(BossHooks.params(c), "per_foe_status")
	if pf.is_empty():
		return
	var marked := b.opponents(c).filter(func(f: Combatant) -> bool: return f.actor.statuses.has(JsonUtil.get_str(pf, "status"))).size()
	var buff := JsonUtil.get_str(pf, "buff")
	c.actor.statuses.remove(buff)
	for i in marked:
		c.actor.statuses.apply(buff)


func _use(b: Battle, c: Combatant, skill_id: String) -> void:
	var sk := b.db.get_entry("skills", skill_id)
	if sk.is_empty():
		return
	b.message.emit("combat.use_skill", {"name": c.label(), "skill": JsonUtil.get_str(sk, "name_ko", skill_id)}, "system")
	var targets: Array = b.opponents(c) if JsonUtil.get_str(sk, "target") == "enemy_all" else [c]
	for t: Combatant in targets:
		BossHooks.apply_effects(b, c, t, JsonUtil.get_array(sk, "effects"))


func validate(def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var p := JsonUtil.get_dict(def, "pattern_params")
	for e: Variant in JsonUtil.get_array(p, "every"):
		if not db.has_entry("skills", JsonUtil.get_str(e if e is Dictionary else {}, "skill")):
			out.append("guardian: every의 스킬 없음")
	for key in ["extra_status"]:
		if p.has(key) and not db.has_entry("statuses", JsonUtil.get_str(p, key)):
			out.append("guardian: %s 상태 없음" % key)
	return out
