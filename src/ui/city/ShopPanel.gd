class_name ShopPanel
extends CityPanel
## 상점 패널: 사기(판매 목록 — CityShop.stock) / 팔기(가방에서 팔 수 있는 것). 가격은 아이템 데이터 price.


func build() -> void:
	add_child(UiTheme.label(Strings.t("city.shop_buy_title", {"money": pc.inventory.money}), "body", "text_title"))
	var buy := scroll_list(UiTheme.render_float("city.list_height", 92.0))
	for id in CityShop.stock(state):
		var price := CityShop.price(state.db, id)
		row(buy, Strings.t("city.shop_line", {"item": _name(id), "price": price}), Strings.t("city.shop_buy"),
			func() -> void: done(CityShop.buy(state, pc, activity_id, id, 1)), pc.inventory.money >= price)
	add_child(UiTheme.label(Strings.t("city.shop_sell_title", {"ratio": UiTheme.num(CityShop.sell_ratio(state) * 100.0)}), "body", "text_title"))
	var sell := scroll_list(UiTheme.render_float("city.list_height", 92.0))
	var list := CityShop.sellable(state, pc)
	if list.is_empty():
		sell.add_child(UiTheme.label(Strings.t("city.shop_nothing_to_sell"), "small", "text_dim"))
	for id in list:
		row(sell, Strings.t("city.shop_sell_line", {"item": _name(id), "n": pc.inventory.count(id), "price": CityShop.sell_price(state, id)}),
			Strings.t("city.shop_sell"), func() -> void: done(CityShop.sell(state, pc, activity_id, id, 1)))


func _name(id: String) -> String:
	return DataNames.entry(state.db, "items", id)
