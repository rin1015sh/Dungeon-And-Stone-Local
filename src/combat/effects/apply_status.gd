extends EffectHandler
## 상태이상 부여: {"type": "apply_status", "status": "bleeding", "chance": 0.2, "duration": 3}
## chance가 없으면 확정. duration이 없으면 상태이상 정의의 지속시간.
## 남(적)이 건 상태는 정의의 resist {stats}로 저항한다: 확률 = min(status.resist_max, Σ 스탯 × status.resist_per_point).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.subject()
	if actor == null:
		return false
	if data.has("chance") and not ctx.rng.chance(JsonUtil.get_float(data, "chance", 1.0)):
		return false
	var status_id := JsonUtil.get_str(data, "status")
	if Passives.is_immune(actor, status_id) or actor.statuses.immune(status_id):
		ctx.say("effect.status_immune", {"name": actor.display_name,
			"status": JsonUtil.get_str(ctx.db.get_entry("statuses", status_id), "name_ko", status_id)}, "info")
		return false
	if ctx.source != null and ctx.source != actor and ctx.rng.chance(actor.statuses.resist_chance(status_id)):
		ctx.say("effect.status_resisted", {"name": actor.display_name,
			"status": JsonUtil.get_str(ctx.db.get_entry("statuses", status_id), "name_ko", status_id)}, "info")
		return false
	var dur := JsonUtil.get_float(data, "duration", -1.0)
	var cap := Passives.duration_cap(actor, status_id)
	if cap >= 0.0:
		var base := dur if dur >= 0.0 else JsonUtil.get_float(JsonUtil.get_dict(ctx.db.get_entry("statuses", status_id), "duration"), "amount", cap)
		dur = minf(base, cap)
	if not actor.statuses.apply(status_id, dur):
		return false
	var status_name := JsonUtil.get_str(ctx.db.get_entry("statuses", status_id), "name_ko", status_id)
	ctx.say("effect.status_on", {"status": status_name}, "warn")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.has_entry("statuses", JsonUtil.get_str(data, "status")):
		out.append("apply_status: status '%s' 없음" % data.get("status"))
	if data.has("chance"):
		var c := JsonUtil.get_float(data, "chance", -1.0)
		if c < 0.0 or c > 1.0:
			out.append("apply_status: chance는 0~1")
	return out
