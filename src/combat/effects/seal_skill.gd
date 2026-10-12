extends EffectHandler
## 봉인: {"type": "seal_skill", "rounds": 2} — 대상의 액티브(기본 스킬 제외) 하나를 무작위로 골라 rounds 차례 쓰지 못하게 한다.
## 상태 [봉인]을 함께 건다(저항 판정은 apply_status와 같다). 전투 중에만(Battle이 사건을 받아 쿨타임으로 막는다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.target
	if t == null or t.dead:
		return false
	if ctx.source != null and ctx.source != t and ctx.rng.chance(t.statuses.resist_chance("seal")):
		ctx.say("effect.status_resisted", {"name": t.display_name, "status": DataNames.entry(ctx.db, "statuses", "seal")}, "info")
		return false
	var pool: Array = t.skills.filter(func(id: String) -> bool:
		return id != Battle.BASIC_ATTACK and not JsonUtil.get_bool(ctx.db.get_entry("skills", id), "innate"))
	if pool.is_empty():
		return false
	var sid := str(ctx.rng.pick(pool))
	t.statuses.apply("seal", float(JsonUtil.get_int(data, "rounds", 2)))
	ctx.events.append({"type": "seal", "target": t, "skill": sid, "rounds": JsonUtil.get_int(data, "rounds", 2)})
	ctx.say("combat.sealed", {"name": t.display_name, "skill": DataNames.entry(ctx.db, "skills", sid)}, "warn")
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	return PackedStringArray() if JsonUtil.get_int(data, "rounds", 0) >= 1 else PackedStringArray(["seal_skill: rounds는 1 이상"])
