extends EffectHandler
## 조사: {"type": "investigate"}. 예전 전투 커맨드 '정보'를 대신하는 기본 스킬(턴을 쓴다).
## 몬스터: 이름 · 등급 · 계열 · 핵심 스탯 · 설명. 아군: 이름 · 생명력 비율.
## 생명력·상성은 전투 중에 보이지 않는다 — 조사한 몬스터는 Knowledge에 스탯을 안다고 기록해 도감 B에서만 보인다(사용자 2026-10-27, UI12·UI22).
## 상성은 직접 쳐 봐야 안다.


func apply(ctx: EffectContext, _data: Dictionary) -> bool:
	var a := ctx.target
	if a == null or a.dead:
		return false
	var args := {"name": a.display_name, "hp": roundi(a.pool.get_ratio("hp") * 100.0)}
	if a is Monster:
		var def := (a as Monster).def
		var fam := PackedStringArray()
		for f: Variant in JsonUtil.get_array(def, "family"):
			fam.append(DataNames.tag(ctx.db, "families", str(f)))
		args["grade"] = JsonUtil.get_int(def, "grade")
		args["family"] = ", ".join(fam)
		args["desc"] = JsonUtil.get_str(def, "desc_ko")
		var m := a as Monster
		for s: String in ["str", "agi", "p_res", "m_res"]:
			args[s] = roundi(a.stats.get_value(s))
		if ctx.source is PlayerCharacter:
			var k := (ctx.source as PlayerCharacter).knowledge
			k.learn_stats(m.monster_id)
			if not m.has_meta("surveyed"):  # 길드 조사 의뢰 — 한 마리에 한 번(CityGuild)
				m.set_meta("surveyed", true)
				k.note_survey(m.monster_id)
		ctx.say("combat.info_monster", args, "system")
	else:
		ctx.say("combat.info_ally", args, "system")
	ctx.events.append({"type": "investigate", "target": a})
	return true
