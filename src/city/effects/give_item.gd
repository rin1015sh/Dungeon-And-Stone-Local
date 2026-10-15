extends CityEffect
## 아이템 받기(여관 식사의 남은 음식): {"type": "give_item", "item": "<아이템 id>", "count": n}.
## 가방에 자리가 없으면 받지 못한다(item_no_room). item·count가 null(미정)이면 주지 않는다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	var id := JsonUtil.get_str(data, "item")
	if id.is_empty() or not CityValues.is_set(data, "count"):
		ctx.say("city.fx.item_undecided")
		return
	var n := maxi(1, int(CityValues.num(data, "count")))
	var name := JsonUtil.get_str(ctx.state.db.get_entry("items", id), "name_ko", id)
	if not ctx.pc.inventory.fits(id, n):
		ctx.say("city.fx.item_no_room", {"name": name}, "warn")
		return
	ctx.pc.inventory.add(id, n)
	ctx.say("city.fx.item_got", {"name": name, "n": n}, "good")


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var id := JsonUtil.get_str(data, "item")
	if not id.is_empty() and not db.has_entry("items", id):
		out.append("give_item: 아이템 '%s' 없음" % id)
	return out
