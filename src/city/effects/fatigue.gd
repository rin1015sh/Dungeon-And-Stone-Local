extends CityEffect
## 피로도 증감: {"type": "fatigue", "direction": "down"|"up", "amount": n} — amount는 크기(방향은 direction).
## amount null(미정)이면 바꾸지 않는다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	if not CityValues.is_set(data, "amount"):
		ctx.say("city.fx.fatigue_undecided")
		return
	var sign := -1.0 if JsonUtil.get_str(data, "direction") == "down" else 1.0
	var before := ctx.pc.fatigue.value
	var d := ctx.pc.fatigue.add(sign * absf(CityValues.num(data, "amount")), "city:" + ctx.activity_id)
	if is_zero_approx(d):
		ctx.say("city.fx.fatigue_same", {"value": CityContext.fmt(before)})
	else:
		ctx.say("city.fx.fatigue_down" if d < 0.0 else "city.fx.fatigue_up", {"from": CityContext.fmt(before),
			"to": CityContext.fmt(ctx.pc.fatigue.value), "delta": CityContext.signed(d)}, "good" if d < 0.0 else "warn")


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not JsonUtil.get_str(data, "direction") in ["down", "up"]:
		out.append("fatigue: direction은 down|up")
	return out
