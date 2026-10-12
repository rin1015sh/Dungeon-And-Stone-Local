extends EffectHandler
## 상태이상 부여: {"type": "apply_status", "status": "bleeding", "chance": 0.2, "duration": 3}
## chance가 없으면 확정. duration이 없으면 상태이상 정의의 지속시간.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.subject()
	if actor == null:
		return false
	if data.has("chance") and not ctx.rng.chance(JsonUtil.get_float(data, "chance", 1.0)):
		return false
	var status_id := JsonUtil.get_str(data, "status")
	if Passives.is_immune(actor, status_id):
		ctx.say("effect.status_immune", {"name": actor.display_name,
			"status": JsonUtil.get_str(ctx.db.get_entry("statuses", status_id), "name_ko", status_id)}, "info")
		return false
	if not actor.statuses.apply(status_id, JsonUtil.get_float(data, "duration", -1.0)):
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
