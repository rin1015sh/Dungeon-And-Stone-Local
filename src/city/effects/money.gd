extends CityEffect
## 소지금 증감(거리 사건 — 소매치기·심부름 등): {"type": "money", "amount": n}(늘림) 또는
## {"type": "money", "lose_ratio": 0~1, "min": n, "max": n}(들고 있는 돈의 비율만큼 잃음 — min·max로 자름, 가진 것보다 많이는 아니다).
## 은행 잔액은 건드리지 않는다. 값이 모두 null(미정)이면 바꾸지 않는다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	if CityValues.is_set(data, "lose_ratio"):
		var n := floori(ctx.pc.inventory.money * clampf(CityValues.num(data, "lose_ratio"), 0.0, 1.0))
		if CityValues.is_set(data, "min"):
			n = maxi(n, int(CityValues.num(data, "min")))
		if CityValues.is_set(data, "max"):
			n = mini(n, int(CityValues.num(data, "max")))
		n = clampi(n, 0, ctx.pc.inventory.money)
		ctx.pc.inventory.add_money(-n)
		ctx.say("city.fx.money_lost", {"n": n}, "warn")
	elif CityValues.is_set(data, "amount"):
		var gain := int(CityValues.num(data, "amount"))
		ctx.pc.inventory.add_money(maxi(gain, -ctx.pc.inventory.money))
		ctx.say("city.fx.money_got" if gain >= 0 else "city.fx.money_lost", {"n": absi(gain)}, "good" if gain >= 0 else "warn")


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if data.has("lose_ratio") and data.has("amount"):
		out.append("money: lose_ratio와 amount 중 하나만")
	return out
