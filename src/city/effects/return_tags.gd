extends CityEffect
## 탐험가 신원패 반납(모험가 길드): {"type": "return_tags", "item": "explorer_tag", "stones_each": n}.
## 가방의 신원패를 모두 내고 한 장마다 stones_each 스톤을 받는다. 없으면 못 한다(city.fx.no_tags).


func apply(ctx: CityContext, data: Dictionary) -> void:
	var item := JsonUtil.get_str(data, "item", "explorer_tag")
	var n := ctx.pc.inventory.count(item)
	if n <= 0:
		ctx.say("city.fx.no_tags", {}, "warn")
		return
	ctx.pc.inventory.remove(item, n)
	var pay := n * maxi(0, int(CityValues.num(data, "stones_each")))
	ctx.pc.inventory.add_money(pay)
	ctx.say("city.fx.tags_returned", {"n": n, "stones": pay}, "good")


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var id := JsonUtil.get_str(data, "item", "explorer_tag")
	if not db.has_entry("items", id):
		out.append("return_tags: 아이템 '%s' 없음" % id)
	return out
