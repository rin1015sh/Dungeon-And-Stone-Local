class_name ShopPanel
extends CityPanel
## 상점 패널: 사기(판매 목록 — CityShop.stock) / 팔기(가방에서 팔 수 있는 것). 가격은 아이템 데이터 price(인연 할인 — CityShop.buy_price). 떠돌이 상인·뒷방은 그 활동의 stock.


func build() -> void:
	head(Strings.t("city.shop_money", {"money": pc.inventory.money}))
	choices()


func options() -> Array[Dictionary]:
	var opts: Array[Dictionary] = []
	for id in CityShop.stock(state, activity_id):
		var price := CityShop.buy_price(state, id)
		opts.append({"text": _name(id), "sub": Strings.t("city.shop_sub_buy", {"price": price}), "enabled": pc.inventory.money >= price,
			"on_pick": func() -> void: done(CityShop.buy(state, pc, activity_id, id, 1))})
	for id in CityShop.sellable(state, pc):
		opts.append({"text": Strings.t("city.shop_sell_name", {"item": _name(id), "n": pc.inventory.count(id)}),
			"sub": Strings.t("city.shop_sub_sell", {"price": CityShop.sell_price(state, id)}),
			"on_pick": func() -> void: done(CityShop.sell(state, pc, activity_id, id, 1))})
	return opts


func _name(id: String) -> String:
	return DataNames.entry(state.db, "items", id)
