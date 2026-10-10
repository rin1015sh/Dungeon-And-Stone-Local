extends EffectHandler
## 광원 켜기: {"type": "light_source", "radius_m": 7.0, "hours": 72}
## 이미 불이 타고 있으면 아무 일도 없다(아이템도 소모되지 않는다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.subject()
	if actor == null:
		return false
	if actor.light.is_lit():
		ctx.say("effect.light_already", {"hours": roundi(actor.light.hours_left)}, "warn")
		return false
	var hours := JsonUtil.get_float(data, "hours")
	actor.light.ignite(ctx.item_id, JsonUtil.get_float(data, "radius_m"), hours)
	ctx.say("effect.light_on", {"hours": roundi(hours)}, "good")
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if JsonUtil.get_float(data, "radius_m") <= 0.0:
		out.append("light_source: radius_m는 0보다 커야 한다")
	if JsonUtil.get_float(data, "hours") <= 0.0:
		out.append("light_source: hours는 0보다 커야 한다")
	return out
