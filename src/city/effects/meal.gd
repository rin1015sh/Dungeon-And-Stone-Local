extends CityEffect
## 여관 식사: {"type": "meal", "menu": "plain"|"light"|"hearty"|"special"} — 그 차림표(data/meals.json)에서 요리 하나를 무게대로 골라 먹는다(Meals).
## 결과 문구는 요리마다 한 장면(city.meal.<요리 id>). 효과 수치는 캐릭터 쪽 "걸린 상태"에 보인다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	var id := Meals.pick(ctx.db, JsonUtil.get_str(data, "menu", "light"), ctx.rng())
	if id.is_empty() or not Meals.eat(ctx.pc, id):
		ctx.say("city.fx.meal_none")
		return
	ctx.say("city.meal." + id, {"name": JsonUtil.get_str(ctx.db.get_entry("meals", id), "name_ko", id)}, "good")


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var menu := JsonUtil.get_str(data, "menu", "light")
	if not db.get_collection("meals").keys().any(func(id: String) -> bool: return JsonUtil.get_str(db.get_entry("meals", id), "menu") == menu):
		out.append("meal: 차림표 '%s'에 요리가 없다" % menu)
	return out
