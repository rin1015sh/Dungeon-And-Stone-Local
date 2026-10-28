extends TestCase
## 알미너스 중앙 거래소(사용자 2026-10-27, CT54): 컴멜비 5구역부터 거리에 선다 · 팔기만 · 상점보다 후한 매입.
## 마석 시세는 폐기 — 마석은 어느 창구도 사지 않고 귀환 정산(CT58)으로만 스톤이 된다.


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _state(tier: int = 1) -> CityState:
	var s := CityState.new(db, 7)
	s.start()
	s.residence = tier
	s.next_period()  # 새 순(그 구역에 거래소가 서 있으면 시세를 굴린다)
	return s


func test_stands_from_fifth_district() -> void:
	for t in range(1, 5):
		var s := _state(t)
		assert_eq(s.facility_ids().has("exchange"), t >= 3, "%d등급 거리에 거래소" % t)
	assert_eq(_state(2).enter_facility("exchange"), "city.reason_residence", "7구역엔 없는 곳")
	assert_eq(_state(3).enter_facility("exchange"), "", "5구역부터 들어간다")


func test_sell_only_and_better_than_shop() -> void:
	var s := _state(3)
	assert_eq(CityShop.tabs(s, "exchange_trade"), ["sell"] as Array[String], "팔기만")
	assert_eq(CityShop.tabs(s, "shop_trade"), ["buy", "sell"] as Array[String], "상점은 둘 다")
	assert_true(CityShop.sell_price(s, "torch", "exchange_trade") > CityShop.sell_price(s, "torch", "shop_trade"), "잡화를 더 후하게")
	var gear := "steel_sword"
	assert_true(CityShop.can_sell(s, gear, "exchange_trade"), "장비도 받는다")
	assert_true(CityShop.sell_price(s, gear, "exchange_trade") > CityShop.sell_price(s, gear, "smithy_trade"), "장비도 대장간보다 후하게")


func test_no_one_buys_magic_stones() -> void:
	var s := _state(4)
	for act: String in ["exchange_trade", "shop_trade"]:
		assert_false(CityShop.can_sell(s, "magic_stone_9", act), "%s: 마석은 사지 않는다(귀환 정산 — CT58)" % act)


func test_sell_pays() -> void:
	var s := _state(4)
	var pc := _pc()
	var have := pc.inventory.count("torch")
	pc.inventory.add("torch", 3)
	s.facility = "exchange"
	var each := CityShop.sell_price(s, "torch", "exchange_trade")
	var money := pc.inventory.money
	assert_true(CityShop.sell(s, pc, "exchange_trade", "torch", 2).ok, "판다")
	assert_eq([pc.inventory.money, pc.inventory.count("torch")], [money + each * 2, have + 1], "매입가대로 받는다")
	assert_false(CityShop.buy(s, pc, "exchange_trade", "torch", 1).ok, "사는 창구는 없다")


## 거래소는 상점 바로 옆(사용자 2026-10-27). 서지 않는 구역에선 그 자리를 당겨 예전 거리 그대로.
func test_next_to_shop_and_gap_closed_below() -> void:
	var ids := _state(3).facility_ids()
	assert_eq(ids.find("exchange"), ids.find("shop") + 1, "상점 다음 건물")
	var shop_end := CityResidence.facility_x(db, "shop", 3) + 400.0 * 0.85
	var ex := CityResidence.facility_x(db, "exchange", 3)
	assert_true(ex > shop_end and ex - shop_end < 150.0, "상점 바로 옆")
	assert_true(CityResidence.facility_x(db, "smithy", 3) > ex + 560.0, "대장간은 거래소 뒤로")
	var slot := JsonUtil.get_float(db.get_entry("facilities", "exchange"), "slot")
	for id: String in ["smithy", "bank", "training"]:
		assert_eq(CityResidence.facility_x(db, id, 1), CityResidence.facility_x(db, id, 3) - slot, id + " 13구역에선 당긴다")
	assert_eq(CityResidence.facility_x(db, "shop", 1), CityResidence.facility_x(db, "shop", 4), "앞쪽 건물은 그대로")
	var w := JsonUtil.get_float(JsonUtil.get_dict(db.singletons.get("city", {}), "street"), "width")
	assert_eq(CityResidence.street_width(db, w, 1), w - slot, "13구역 거리는 짧다")
	assert_eq(CityResidence.street_width(db, w, 3), w, "5구역부터 전체")
