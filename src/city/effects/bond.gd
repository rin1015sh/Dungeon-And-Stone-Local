extends CityEffect
## 인연(말 걸기): {"type": "bond", "amount": n} — 이 시설 사람(CityBonds.person_at)과의 인연 점수를 더한다.
## 채운 단계가 있으면 그 장면이 이어지고, 없으면 짧은 한마디(city.lines.<활동>.bond.<번호>). amount null(미정)이면 그대로.


func apply(ctx: CityContext, data: Dictionary) -> void:
	var person := CityBonds.person_at(ctx.db, ctx.state.facility)
	if person.is_empty() or not CityValues.is_set(data, "amount"):
		ctx.say("city.fx.bond_none")
		return
	var before := CityBonds.stage(ctx.state, person)
	CityBonds.add(ctx, person, CityValues.num(data, "amount"))
	if CityBonds.stage(ctx.state, person) == before:
		ctx.say("city.fx.bond")


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if data.get("amount") != null and not (data["amount"] is float or data["amount"] is int):
		out.append("bond: amount는 수 또는 null")
	return out
