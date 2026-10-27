class_name ShopPanel
extends CityPanel
## 상점·대장간 창구: 시설 선택 창의 [구매]·[판매]가 이 창을 그 쪽으로 바로 연다(사용자 결정 2026-10-24 — 예전엔 [구매·판매] 안에 탭이 한 번 더 있었다).
##   구매 = 판매 목록(CityShop.stock — 활동의 stock·deals), 판매 = 가방에서 이 창구에 팔 수 있는 것(CityShop.sellable).
##   목록 맨 끝 돌아가기 = 시설 선택 창으로(back — FacilityView가 넣는다. Backspace는 쓰지 않는다 — 사용자 결정 2026-10-20). 가격은 아이템 데이터 price.

const TABS := CityShop.TABS

var mode: String = "buy"  ## buy, sell
## 돌아가기(목록 맨 끝). FacilityView가 넣는다.
var back: Callable = Callable()


func build() -> void:
	head(Strings.t("city.shop_money", {"money": pc.inventory.money}) + "  ·  " + Strings.t("city.shop_tab_" + mode))
	choices()


func options() -> Array[Dictionary]:
	var opts: Array[Dictionary] = []
	match mode:
		"buy":
			for id in CityShop.stock(state, activity_id):
				var price := CityShop.buy_price(state, id)
				opts.append({"text": _name(id), "sub": Strings.t("city.shop_sub_buy", {"price": price}), "enabled": pc.inventory.money >= price,
					"on_pick": func() -> void: done(CityShop.buy(state, pc, activity_id, id, 1))})
		"sell":
			for id in CityShop.sellable(state, pc, activity_id):
				opts.append({"text": Strings.t("city.shop_sell_name", {"item": _name(id), "n": pc.inventory.count(id)}),
					"sub": Strings.t("city.shop_sub_sell", {"price": CityShop.sell_price(state, id, activity_id)}),
					"on_pick": func() -> void: done(CityShop.sell(state, pc, activity_id, id, 1))})
	return opts


## 목록 맨 끝은 돌아가기(시설 선택 창으로).
func grid_options() -> Array[Dictionary]:
	var opts := options()
	opts.append({"text": Strings.t("menu.back"), "on_pick": back if back.is_valid() else leave})
	return opts


## 쪽을 바꾼다(buy·sell) — 커서는 맨 위.
func open_tab(t: String) -> void:
	mode = t
	rebuild(0)


func _name(id: String) -> String:
	return DataNames.entry(state.db, "items", id)
