class_name CityShop
extends RefCounted
## 상점(구매·판매): 기존 아이템 데이터의 price를 그대로 쓴다. 규칙 값은 city.json shop.
##   stock null → 임시로 price > 0인 아이템 전부(마석·균열 귀속 제외), sell_ratio null → 임시로 1,
##   accepts_magic_stones null → 마석을 받지 않는다. 거래마다 활동(shop_trade)의 행동력·비용을 낸다.

const MAGIC_STONE := "magic_stone"


static func config(state: CityState) -> Dictionary:
	return CityValues.city_section(state.db, state.overrides, "shop")


static func stock(state: CityState) -> Array[String]:
	var db := state.db
	var out: Array[String] = []
	var list: Variant = config(state).get("stock")
	if list is Array:
		for v: Variant in list:
			if db.has_entry("items", str(v)):
				out.append(str(v))
		return out
	for id: String in db.get_collection("items"):
		var e := db.get_entry("items", id)
		if price(db, id) > 0 and JsonUtil.get_str(e, "category") != MAGIC_STONE and JsonUtil.get_str(e, "rift_bound").is_empty():
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		return price(db, a) < price(db, b) or (price(db, a) == price(db, b) and a < b))
	return out


static func price(db: GameDatabase, item_id: String) -> int:
	return maxi(0, JsonUtil.get_int(db.get_entry("items", item_id), "price"))


static func sell_ratio(state: CityState) -> float:
	var c := config(state)
	return maxf(0.0, CityValues.num(c, "sell_ratio")) if CityValues.is_set(c, "sell_ratio") else 1.0


static func can_sell(state: CityState, item_id: String) -> bool:
	var e := state.db.get_entry("items", item_id)
	if e.is_empty() or price(state.db, item_id) <= 0 or not JsonUtil.get_str(e, "rift_bound").is_empty():
		return false
	if JsonUtil.get_str(e, "category") == MAGIC_STONE:
		return JsonUtil.get_bool(config(state), "accepts_magic_stones")
	return true


static func sell_price(state: CityState, item_id: String) -> int:
	return floori(price(state.db, item_id) * sell_ratio(state))


## 가방에서 팔 수 있는 아이템 id.
static func sellable(state: CityState, pc: PlayerCharacter) -> Array[String]:
	var out: Array[String] = []
	for id in pc.inventory.ids():
		if can_sell(state, id):
			out.append(id)
	return out


static func buy(state: CityState, pc: PlayerCharacter, act_id: String, item_id: String, n: int = 1) -> CityContext:
	var ctx := CityContext.new(state, pc, act_id)
	if n <= 0 or not stock(state).has(item_id):
		return ctx.fail("city.reason_not_sold")
	var total := price(state.db, item_id) * n
	var why := CityActions.check(state, pc, act_id, total)
	if not why.is_empty():
		return ctx.fail(why)
	if not pc.inventory.fits(item_id, n):
		return ctx.fail("city.reason_bag_full")
	CityActions.charge(ctx, act_id)
	pc.inventory.add_money(-total)
	pc.inventory.add(item_id, n)
	ctx.say("city.shop_bought", {"item": _name(state, item_id), "n": n, "price": total, "money": pc.inventory.money}, "good")
	state.changed.emit()
	return ctx


static func sell(state: CityState, pc: PlayerCharacter, act_id: String, item_id: String, n: int = 1) -> CityContext:
	var ctx := CityContext.new(state, pc, act_id)
	if n <= 0 or not can_sell(state, item_id) or not pc.inventory.has(item_id, n):
		return ctx.fail("city.reason_cannot_sell")
	var why := CityActions.check(state, pc, act_id)
	if not why.is_empty():
		return ctx.fail(why)
	CityActions.charge(ctx, act_id)
	var total := sell_price(state, item_id) * n
	pc.inventory.remove(item_id, n)
	pc.inventory.add_money(total)
	ctx.say("city.shop_sold", {"item": _name(state, item_id), "n": n, "price": total, "money": pc.inventory.money}, "good")
	state.changed.emit()
	return ctx


static func _name(state: CityState, item_id: String) -> String:
	return JsonUtil.get_str(state.db.get_entry("items", item_id), "name_ko", item_id)
