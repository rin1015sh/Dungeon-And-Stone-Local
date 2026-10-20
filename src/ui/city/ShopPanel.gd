class_name ShopPanel
extends CityPanel
## 상점·대장간 창구: 먼저 탭(구매 / 판매 — W/S·Enter)을 고르고, 그 탭의 목록에서 고른다(사용자 결정 2026-10-20).
##   구매 = 판매 목록(CityShop.stock — 활동의 stock·deals), 판매 = 가방에서 이 창구에 팔 수 있는 것(CityShop.sellable).
##   목록에서 Backspace·맨 끝 돌아가기 = 탭으로, 탭에서 Backspace·나가기 = 거리로. 가격은 아이템 데이터 price.

const TABS := ["buy", "sell"]

var mode: String = ""  ## "" = 탭 고르기, buy, sell


func build() -> void:
	var tab := Strings.t("city.shop_tab_" + mode) if not mode.is_empty() else ""
	head(Strings.t("city.shop_money", {"money": pc.inventory.money}) + ("" if tab.is_empty() else "  ·  " + tab))
	choices()


func options() -> Array[Dictionary]:
	var opts: Array[Dictionary] = []
	match mode:
		"":
			for t: String in TABS:
				opts.append({"text": Strings.t("city.shop_tab_" + t), "on_pick": func() -> void: open_tab(t)})
		"buy":
			for id in CityShop.stock(state, activity_id):
				var price := CityShop.price(state.db, id)
				opts.append({"text": _name(id), "sub": Strings.t("city.shop_sub_buy", {"price": price}), "enabled": pc.inventory.money >= price,
					"on_pick": func() -> void: done(CityShop.buy(state, pc, activity_id, id, 1))})
		"sell":
			for id in CityShop.sellable(state, pc, activity_id):
				opts.append({"text": Strings.t("city.shop_sell_name", {"item": _name(id), "n": pc.inventory.count(id)}),
					"sub": Strings.t("city.shop_sub_sell", {"price": CityShop.sell_price(state, id)}),
					"on_pick": func() -> void: done(CityShop.sell(state, pc, activity_id, id, 1))})
	return opts


## 목록 맨 끝은 돌아가기(탭으로), 탭 화면은 나가기.
func grid_options() -> Array[Dictionary]:
	if mode.is_empty():
		return super.grid_options()
	var opts := options()
	opts.append({"text": Strings.t("menu.back"), "on_pick": back_to_tabs})
	return opts


func back_action() -> Callable:
	return leave if mode.is_empty() else back_to_tabs


## 탭을 연다(buy·sell) — 커서는 맨 위.
func open_tab(t: String) -> void:
	mode = t
	rebuild(0)


## 탭 고르기로 돌아간다(커서는 방금 탭에).
func back_to_tabs() -> void:
	var was := TABS.find(mode)
	mode = ""
	rebuild(maxi(0, was))


func _name(id: String) -> String:
	return DataNames.entry(state.db, "items", id)
