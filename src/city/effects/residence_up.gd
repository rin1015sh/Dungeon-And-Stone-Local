extends CityEffect
## 이사(은행): {"type": "residence_up"} — 다음 거주 등급의 upgrade_cost를 내고 한 단계 올린다(CityResidence, CT50).
## 값은 CityActions.check가 미리 본다(가장 높으면 고를 수 없다).


func apply(ctx: CityContext, _data: Dictionary) -> void:
	var why := CityResidence.upgrade(ctx.state, ctx.pc)
	if not why.is_empty():
		ctx.say(why, {}, "warn")
		return
	ctx.say("city.fx.residence_up", {"name": CityResidence.name_of(ctx.state)}, "good")
