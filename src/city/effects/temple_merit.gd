extends CityEffect
## 신전 공적치(봉사활동): {"type": "temple_merit", "amount": n}. amount null(미정)이면 쌓이지 않는다.
## 신관 영입 조건·기능은 미정이라 값만 쌓는다(신전 패널에 보인다).


func apply(ctx: CityContext, data: Dictionary) -> void:
	if not CityValues.is_set(data, "amount"):
		ctx.say("city.fx.merit_undecided")
		return
	var d := CityValues.num(data, "amount")
	ctx.state.temple_merit += d
	ctx.say("city.fx.merit", {"delta": CityContext.signed(d), "total": CityContext.fmt(ctx.state.temple_merit)}, "good")
