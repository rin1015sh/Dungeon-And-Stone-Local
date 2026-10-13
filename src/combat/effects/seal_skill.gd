extends EffectHandler
## 봉인: {"type": "seal_skill", "rounds": 2} — 대상의 액티브(기본 스킬 제외) 하나를 무작위로 골라 rounds 차례 쓰지 못하게 한다.
## 상태 [봉인]을 함께 건다(면역·저항은 apply_status와 같다 — 걸리지 않으면 스킬도 막히지 않는다). 전투 중에만(Battle이 사건을 받아 쿨타임으로 막는다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.target
	if t == null or t.dead:
		return false
	var pool: Array = t.skills.filter(func(id: String) -> bool:
		return id != Battle.BASIC_ATTACK and not JsonUtil.get_bool(ctx.db.get_entry("skills", id), "innate"))
	if pool.is_empty():
		return false
	# 상태 [봉인]이 걸려야 스킬도 막힌다(면역 패시브·저항). 지속은 쿨타임과 같이 rounds + 1(자기 차례 시작에 하나씩 준다).
	var args := {"name": t.display_name, "status": DataNames.entry(ctx.db, "statuses", "seal")}
	match Passives.try_status(ctx.db, ctx.rng, ctx.source, t, "seal", float(JsonUtil.get_int(data, "rounds", 2) + 1)):
		"immune":
			ctx.say("effect.status_immune", args, "info")
			return false
		"resisted":
			ctx.say("effect.status_resisted", args, "info")
			return false
		"failed":
			return false
	var sid := str(ctx.rng.pick(pool))
	ctx.events.append({"type": "seal", "target": t, "skill": sid, "rounds": JsonUtil.get_int(data, "rounds", 2)})
	ctx.say("combat.sealed", {"name": t.display_name, "skill": DataNames.entry(ctx.db, "skills", sid)}, "warn")
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	return PackedStringArray() if JsonUtil.get_int(data, "rounds", 0) >= 1 else PackedStringArray(["seal_skill: rounds는 1 이상"])
