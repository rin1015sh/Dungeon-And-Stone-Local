extends TestCase
## 거주 등급(사용자 2026-10-27, CT50·CT51·CT53): 은행 이사 · 여관 식사 등급 · 상점 판매 목록·매입가 · 대장간 소재 단계 · 거리 사건 · 건물 외관 · 저장.


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _state(tier: int = 1) -> CityState:
	var s := CityState.new(db, 7)
	s.start()
	s.residence = tier
	return s


func _reg() -> ScriptRegistry:
	return ContentRegistries.new().city_effects


func test_move_up_pays_next_tier_and_stops_at_top() -> void:
	var s := _state()
	var pc := _pc()
	s.facility = "bank"
	var cost := CityResidence.next_cost(s)
	assert_true(cost > 0, "다음 등급 값")
	assert_eq(CityActions.check(s, pc, "bank_move"), "city.reason_no_money", "돈이 모자라면 못 옮긴다")
	pc.inventory.add_money(cost)
	var money := pc.inventory.money
	assert_true(CityActions.perform(s, pc, "bank_move", _reg()).ok)
	assert_eq([CityResidence.tier(s), pc.inventory.money], [2, money - cost], "한 등급 오르고 값을 낸다")
	s.residence = CityResidence.max_tier(s)
	assert_eq(CityResidence.next_cost(s), -1)
	assert_eq(CityActions.check(s, pc, "bank_move"), "city.reason_residence_max", "가장 높으면 더 못 옮긴다")
	assert_eq(CityResidence.max_tier(s), 4, "4단계")


func test_inn_meals_split_by_tier() -> void:
	var want := {1: ["inn_rest", "inn_snack"], 2: ["inn_rest", "inn_snack", "inn_meal"],
		3: ["inn_rest", "inn_snack", "inn_meal", "inn_hearty"], 4: ["inn_rest", "inn_snack", "inn_meal", "inn_hearty", "inn_feast"]}
	for t: int in want:
		var got := CityActions.activities_of(_state(t), "inn")
		assert_eq(got, (want[t] as Array).map(func(v: Variant) -> String: return str(v)), "%d등급 여관" % t)
	var s := _state(3)
	s.happenings.assign(["inn_special"])
	assert_true(CityActions.activities_of(s, "inn").has("inn_feast"), "상인 거리는 여관 특식 사건이 걸린 순에 특식")
	var low := _state(2)
	low.happenings.assign(["inn_special"])
	assert_false(CityActions.activities_of(low, "inn").has("inn_feast"), "장인 거리는 사건이 걸려도 특식 없음")
	assert_false(CityHappenings.eligible(_state(2)).has("inn_special"), "그 아래 등급에는 여관 특식 사건이 걸리지 않는다")


func test_shop_stock_and_sell_ratio_by_tier() -> void:
	var t1 := CityShop.stock(_state(1), "shop_trade")
	var t3 := CityShop.stock(_state(3), "shop_trade")
	assert_true(t1.has("ration") and not t1.has("medium_potion") and not t1.has("lantern"), "뒷골목: 기본 물건만")
	assert_true(t3.has("ration") and t3.has("medium_potion") and t3.has("lantern"), "상인 거리: 아래 등급 물건도 그대로 + 새 물건")
	assert_true(CityShop.sell_price(_state(4), "torch") > CityShop.sell_price(_state(1), "torch"), "고지대는 비싸게 사 준다")


func test_smithy_material_cap_follows_tier() -> void:
	var tier_of := func(id: String) -> int:
		return JsonUtil.get_int(db.get_entry("items", id), "tier", 1)
	for t in range(1, 5):
		var stock := CityShop.stock(_state(t), "smithy_trade")
		var top := 0
		for id in stock:
			top = maxi(top, int(tier_of.call(id)))
		assert_eq(top, t, "%d등급 대장간 소재 단계 상한" % t)
	assert_true(CityShop.stock(_state(2), "smithy_trade").has("lightium_sword"), "장인 거리 = 라이티늄")
	assert_false(CityShop.stock(_state(1), "smithy_trade").has("lightium_sword"), "뒷골목엔 없다")


func test_street_events_lean_on_tier() -> void:
	var low := CityAmbient._weight(_state(1), CityAmbient.entry(_state(1), "pickpocket"))
	var high := CityAmbient._weight(_state(4), CityAmbient.entry(_state(4), "pickpocket"))
	assert_true(low > high * 3.0, "소매치기는 뒷골목에 잦다")
	var c_low := CityAmbient._weight(_state(1), CityAmbient.entry(_state(1), "checkpoint"))
	var c_high := CityAmbient._weight(_state(4), CityAmbient.entry(_state(4), "checkpoint"))
	assert_true(c_high > c_low, "검문은 고지대에 잦다")


func test_building_art_per_tier_and_save() -> void:
	var base := JsonUtil.get_str(db.get_entry("facilities", "inn"), "building")
	assert_eq(CityResidence.building_path(base, 1), base, "1등급 = 기본 그림")
	for t in range(2, 5):
		for id: String in db.get_collection("facilities"):
			var b := JsonUtil.get_str(db.get_entry("facilities", id), "building")
			assert_true(CityResidence.building_path(b, t) != b, "%s %d등급 그림" % [id, t])
	var s := _state(3)
	s.reach_floor(2)
	var copy := CityState.new(db, 1)
	copy.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq([copy.residence, copy.reached_floor], [3, 2], "저장 왕복")
	copy.load_dict({})
	assert_eq([copy.residence, copy.reached_floor], [1, 1], "옛 저장 = 뒷골목·1층")
