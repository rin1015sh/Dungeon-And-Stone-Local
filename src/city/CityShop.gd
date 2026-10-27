class_name CityShop
extends RefCounted
## 상점(구매·판매): 기존 아이템 데이터의 price를 그대로 쓴다. 규칙 값은 city.json shop.
##   stock null → 임시로 price > 0인 아이템 전부(마석·균열 귀속 제외), sell_ratio null → 임시로 1,
##   accepts_magic_stones null → 마석을 받지 않는다, magic_stone_ratio = 마석 매입가 비율. 거래마다 활동(shop_trade)의 이용료를 낸다.
## 창구마다 다루는 물건(활동 deals — 사용자 결정 2026-10-20): equipment = 장비(category가 shop.equipment_categories)만 — 대장간,
##   goods = 장비가 아닌 것만 — 상점·떠돌이 상인, 없으면 모두. 사기(stock 걸러냄)·팔기(sellable·can_sell) 모두에 걸린다.

const MAGIC_STONE := "magic_stone"


static func config(state: CityState) -> Dictionary:
	return CityValues.city_section(state.db, state.overrides, "shop")


## 판매 목록. act_id의 활동에 stock이 있으면 그것(대장간·떠돌이 상인), 없으면 city.json shop.stock_by_residence(거주 등급까지 쌓아서 — CT51)
## 또는 shop.stock — 그 창구가 다루는 물건만(deals). 활동 material_tiers면 2단계 ~ 거주 등급 소재 상한의 장비를 종류마다 하나씩 덧붙인다(대장간).
static func stock(state: CityState, act_id: String = "") -> Array[String]:
	var db := state.db
	var out: Array[String] = []
	var list: Variant = config(state).get("stock")
	var by_tier: Variant = config(state).get("stock_by_residence")
	if by_tier is Array:
		list = []
		for i in mini(CityResidence.tier(state), (by_tier as Array).size()):
			if by_tier[i] is Array:
				(list as Array).append_array(by_tier[i])
	var act := state.activity(act_id) if not act_id.is_empty() else {}
	var own: Variant = act.get("stock")
	if own is Array:
		list = (own as Array).duplicate()
		if JsonUtil.get_bool(act, "material_tiers"):
			for t in range(2, CityResidence.smithy_material_tier(state) + 1):
				(list as Array).append_array(tier_gear(db, t))
	if list is Array:
		for v: Variant in list:
			if db.has_entry("items", str(v)) and deals(state, act_id, str(v)) and not out.has(str(v)):
				out.append(str(v))
		return out
	for id: String in db.get_collection("items"):
		var e := db.get_entry("items", id)
		if price(db, id) > 0 and JsonUtil.get_str(e, "category") != MAGIC_STONE and JsonUtil.get_str(e, "rift_bound").is_empty() and deals(state, act_id, id):
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		return price(db, a) < price(db, b) or (price(db, a) == price(db, b) and a < b))
	return out


## 장비인가(category가 city.json shop.equipment_categories — 무기·방어구).
static func is_equipment(state: CityState, item_id: String) -> bool:
	return JsonUtil.get_str(state.db.get_entry("items", item_id), "category") in JsonUtil.get_array(config(state), "equipment_categories")


## 이 창구(act_id)가 이 물건을 다루는가(활동 deals: equipment·goods·없음 = 모두).
static func deals(state: CityState, act_id: String, item_id: String) -> bool:
	match JsonUtil.get_str(state.activity(act_id), "deals") if not act_id.is_empty() else "":
		"equipment":
			return is_equipment(state, item_id)
		"goods":
			return not is_equipment(state, item_id)
	return true


static func price(db: GameDatabase, item_id: String) -> int:
	return maxi(0, JsonUtil.get_int(db.get_entry("items", item_id), "price"))


## 사는 값: 제값 × 이번 순 배율(거리 사건 — CityState.price_mods "buy:<분류>").
static func buy_price(state: CityState, item_id: String) -> int:
	return floori(price(state.db, item_id) * state.price_mult("buy:" + _category(state, item_id)) * CityResidence.price_mult(state))  # × 거주 구역 물가(CT50)


static func _category(state: CityState, item_id: String) -> String:
	return JsonUtil.get_str(state.db.get_entry("items", item_id), "category")



## 소재 단계 t의 장비: 종류(item_types 순서)마다 그 종류가 쓰는 소재 중 단계 t의 첫 소재(materials 순서, buyable이 false면 뺀다) 하나.
static func tier_gear(db: GameDatabase, t: int) -> Array[String]:
	var out: Array[String] = []
	var mats := db.get_collection("materials")
	for tid: String in db.get_collection("item_types"):
		var kinds := JsonUtil.get_array(db.get_entry("item_types", tid), "kinds")
		for mid: String in mats:
			var m: Dictionary = mats[mid]
			if JsonUtil.get_int(m, "tier") == t and kinds.has(JsonUtil.get_str(m, "kind")) and m.get("buyable") != false:
				if db.has_entry("items", "%s_%s" % [mid, tid]):
					out.append("%s_%s" % [mid, tid])
				break
	return out


## 매입 비율: sell_ratio_by_residence[거주 등급 − 1](CT51), 없으면 sell_ratio.
static func sell_ratio(state: CityState) -> float:
	var c := config(state)
	var by_tier: Variant = c.get("sell_ratio_by_residence")
	if by_tier is Array and (by_tier as Array).size() >= CityResidence.tier(state):
		var v: Variant = by_tier[CityResidence.tier(state) - 1]
		if v is float or v is int:
			return maxf(0.0, float(v))
	return maxf(0.0, CityValues.num(c, "sell_ratio")) if CityValues.is_set(c, "sell_ratio") else 1.0


static func can_sell(state: CityState, item_id: String, act_id: String = "") -> bool:
	var e := state.db.get_entry("items", item_id)
	if e.is_empty() or price(state.db, item_id) <= 0 or not JsonUtil.get_str(e, "rift_bound").is_empty() or not deals(state, act_id, item_id):
		return false
	if JsonUtil.get_str(e, "category") == MAGIC_STONE:
		return JsonUtil.get_bool(config(state), "accepts_magic_stones")
	return true


## 판매가: 마석은 magic_stone_ratio(없으면 sell_ratio), 그 밖은 sell_ratio. × 이번 순 배율("sell:<분류>").
static func sell_price(state: CityState, item_id: String) -> int:
	var c := config(state)
	var ratio := sell_ratio(state)
	if JsonUtil.get_str(state.db.get_entry("items", item_id), "category") == MAGIC_STONE and CityValues.is_set(c, "magic_stone_ratio"):
		ratio = maxf(0.0, CityValues.num(c, "magic_stone_ratio"))
	return floori(price(state.db, item_id) * ratio * state.price_mult("sell:" + _category(state, item_id)))


## 가방에서 이 창구에 팔 수 있는 아이템 id.
static func sellable(state: CityState, pc: PlayerCharacter, act_id: String = "") -> Array[String]:
	var out: Array[String] = []
	for id in pc.inventory.ids():
		if can_sell(state, id, act_id):
			out.append(id)
	return out


static func buy(state: CityState, pc: PlayerCharacter, act_id: String, item_id: String, n: int = 1) -> CityContext:
	var ctx := CityContext.new(state, pc, act_id)
	if n <= 0 or not stock(state, act_id).has(item_id):
		return ctx.fail("city.reason_not_sold")
	var total := buy_price(state, item_id) * n
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
	if n <= 0 or not can_sell(state, item_id, act_id) or not pc.inventory.has(item_id, n):
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
