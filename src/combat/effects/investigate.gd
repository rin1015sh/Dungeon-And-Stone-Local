extends EffectHandler
## 조사: {"type": "investigate"}. 예전 전투 커맨드 '정보'를 대신하는 기본 스킬(턴을 쓴다).
## 몬스터: 이름 · 등급 · 계열 · 생명력 · 핵심 스탯 · 알아낸 상성(모르면 ???) · 설명 — 적 생명력을 알 수 있는 유일한 길(ASSUMPTIONS UI12). 아군: 이름 · 생명력 비율.
## 조사한 몬스터는 Knowledge에 스탯을 안다고 기록한다(도감에 공개). 상성은 직접 쳐 봐야 안다.


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
		args["hp_now"] = ceili(a.pool.get_current("hp"))
		args["hp_max"] = roundi(a.pool.get_max("hp"))
		var aff := Strings.t("knowledge.unknown")
		if ctx.source is PlayerCharacter:
			var k := (ctx.source as PlayerCharacter).knowledge
			k.learn_stats(m.monster_id)
			aff = BattleKnowledge.describe_affinities(ctx.db, k, m.monster_id)
		args["aff"] = aff
		ctx.say("combat.info_monster", args, "system")
	else:
		ctx.say("combat.info_ally", args, "system")
	ctx.events.append({"type": "investigate", "target": a})
	return true
