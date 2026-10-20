extends CityEffect
## 세금 납부(은행): {"type": "pay_tax"}. 올해 세금(CityTax.amount)을 소지금에서 낸다. 이미 냈거나 낼 게 없으면 그렇다고만.


func apply(ctx: CityContext, _data: Dictionary) -> void:
	var n := CityTax.amount(ctx.state, ctx.pc.race_id)
	var why := CityTax.pay(ctx.state, ctx.pc)
	if why.is_empty():
		ctx.say("city.fx.tax_paid", {"n": n}, "good")
	else:
		ctx.say(why, {"n": n}, "warn")
