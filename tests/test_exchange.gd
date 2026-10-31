extends TestCase
## 알미너스 중앙 거래소(사용자 2026-10-27, CT54): 특별 시설 — 거리에 서지 않고 거리 끝에서 따로 간다(CT63) · 팔기만 · 상점보다 후한 매입.
## 마석 시세는 폐기 — 마석은 어느 창구도 사지 않고 귀환 정산(CT58)으로만 스톤이 된다.


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _state() -> CityState:
	var s := CityState.new(db, 7)
	s.start()
	return s


func test_sell_only_and_better_than_shop() -> void:
	var s := _state()
	assert_eq(CityShop.tabs(s, "exchange_trade"), ["sell"] as Array[String], "팔기만")
	assert_eq(CityShop.tabs(s, "shop_trade"), ["buy", "sell"] as Array[String], "상점은 둘 다")
	assert_true(CityShop.sell_price(s, "torch", "exchange_trade") > CityShop.sell_price(s, "torch", "shop_trade"), "잡화를 더 후하게")
	var gear := "steel_sword"
	assert_true(CityShop.can_sell(s, gear, "exchange_trade"), "장비도 받는다")
	assert_true(CityShop.sell_price(s, gear, "exchange_trade") > CityShop.sell_price(s, gear, "smithy_trade"), "장비도 대장간보다 후하게")


func test_no_one_buys_magic_stones() -> void:
	var s := _state()
	for act: String in ["exchange_trade", "shop_trade"]:
		assert_false(CityShop.can_sell(s, "magic_stone_9", act), "%s: 마석은 사지 않는다(귀환 정산 — CT58)" % act)


func test_sell_pays() -> void:
	var s := _state()
	var pc := _pc()
	var have := pc.inventory.count("torch")
	pc.inventory.add("torch", 3)
	s.facility = "exchange"
	var each := CityShop.sell_price(s, "torch", "exchange_trade")
	var money := pc.inventory.money
	assert_true(CityShop.sell(s, pc, "exchange_trade", "torch", 2).ok, "판다")
	assert_eq([pc.inventory.money, pc.inventory.count("torch")], [money + each * 2, have + 1], "매입가대로 받는다")
	assert_false(CityShop.buy(s, pc, "exchange_trade", "torch", 1).ok, "사는 창구는 없다")
