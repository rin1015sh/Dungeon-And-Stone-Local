extends EffectHandler
## 상태이상 해제: {"type": "remove_status", "status": "bleeding"} (붕대·해독제 등)
## {"type": "remove_status", "kind": "debuff", "count": 1} — 약화 상태 count개를 무작위로 푼다(키르뒤 초재생). 필드 효과는 빼고.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.subject()
	if actor == null:
		return false
	if not data.has("status"):
		var any := false
		for i in JsonUtil.get_int(data, "count", 1):
			var id := actor.statuses.pick_debuff(ctx.rng)
			if id.is_empty() or not actor.statuses.remove(id):
				break
			any = true
			ctx.say("effect.status_off", {"status": DataNames.entry(ctx.db, "statuses", id)}, "good")
		return any
	var status_id := JsonUtil.get_str(data, "status")
	if not actor.statuses.remove(status_id):
		return false
	var status_name := JsonUtil.get_str(ctx.db.get_entry("statuses", status_id), "name_ko", status_id)
	ctx.say("effect.status_off", {"status": status_name}, "good")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	if not data.has("status"):
		return PackedStringArray() if JsonUtil.get_str(data, "kind") == "debuff" else PackedStringArray(["remove_status: status 또는 kind debuff"])
	if not db.has_entry("statuses", JsonUtil.get_str(data, "status")):
		return PackedStringArray(["remove_status: status '%s' 없음" % data.get("status")])
	return PackedStringArray()
