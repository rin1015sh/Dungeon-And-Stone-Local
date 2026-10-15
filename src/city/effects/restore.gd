extends CityEffect
## 자원 회복(여관 휴식): {"type": "restore", "resources": {"hp": 1.0, "soul": 1.0}} — 값 = 최대치에 대한 비율.
## 하나라도 늘었으면 restore, 이미 가득이면 restore_full. resources가 null(미정)이면 회복하지 않는다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	var res: Variant = data.get("resources")
	if not res is Dictionary:
		ctx.say("city.fx.restore_undecided")
		return
	var gained := false
	for id: Variant in res:
		var key := str(id)
		var ratio: Variant = res[id]
		if not ctx.pc.pool.has_resource(key) or not (ratio is float or ratio is int):
			continue
		var before := ctx.pc.pool.get_current(key)
		ctx.pc.pool.modify(key, ctx.pc.pool.get_max(key) * clampf(float(ratio), 0.0, 1.0), "city:" + ctx.activity_id)
		gained = gained or ctx.pc.pool.get_current(key) > before
	ctx.say("city.fx.restore" if gained else "city.fx.restore_full", {}, "good" if gained else "info")


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var res: Variant = data.get("resources")
	if res != null and not res is Dictionary:
		out.append("restore: resources는 {자원 id: 비율}")
	elif res is Dictionary:
		for id: Variant in res:
			if not db.resources.has(str(id)):
				out.append("restore: 자원 '%s' 없음" % id)
	return out
