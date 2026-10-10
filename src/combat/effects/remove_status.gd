extends EffectHandler
## 상태이상 해제: {"type": "remove_status", "status": "bleeding"} (붕대·해독제 등)


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.subject()
	if actor == null:
		return false
	var status_id := JsonUtil.get_str(data, "status")
	if not actor.statuses.remove(status_id):
		return false
	var status_name := JsonUtil.get_str(ctx.db.get_entry("statuses", status_id), "name_ko", status_id)
	ctx.say("effect.status_off", {"status": status_name}, "good")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	if not db.has_entry("statuses", JsonUtil.get_str(data, "status")):
		return PackedStringArray(["remove_status: status '%s' 없음" % data.get("status")])
	return PackedStringArray()
