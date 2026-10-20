extends CityEffect
## 명성(모험가들과 한잔 등): {"type": "renown", "amount": n} — 이름이 조금 퍼진다(CityRenown 점수). 수치는 보이지 않는다.
## amount null(미정)이면 그대로.


func apply(ctx: CityContext, data: Dictionary) -> void:
	if not CityValues.is_set(data, "amount"):
		return
	ctx.state.renown = maxi(0, ctx.state.renown + int(CityValues.num(data, "amount")))
	ctx.say("city.fx.renown")
