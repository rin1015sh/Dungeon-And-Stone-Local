extends EffectHandler
## 조사: {"type": "investigate"}. 예전 전투 커맨드 '정보'를 대신하는 기본 스킬(턴을 쓴다).
## 몬스터: 이름 · 등급 · 계열 · 생명력 비율 · 설명. 아군: 이름 · 생명력 비율.
## (약점·상성 같은 `???` 정보 공개는 M3 Knowledge가 여기에 붙는다.)


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
		ctx.say("combat.info_monster", args, "system")
	else:
		ctx.say("combat.info_ally", args, "system")
	ctx.events.append({"type": "investigate", "target": a})
	return true
