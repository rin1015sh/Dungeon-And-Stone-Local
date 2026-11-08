extends TestCase
## 도시 생활(2026-10-20): 세금(CityTax) · 저장 · 도시 사건 없음(CT114).


func _pc(race: String = "human", stats: Dictionary = {}) -> PlayerCharacter:
	var base := {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6}
	base.merge(stats, true)
	var pc := PlayerCharacter.create(db, race, "warrior", "시험", base)
	pc.inventory.add_money(100000)
	return pc


func _state(seed_value: int = 7) -> CityState:
	var s := CityState.new(db, seed_value)
	s.start()
	return s


func _reg() -> ScriptRegistry:
	return ContentRegistries.new().city_effects


## 도시 사건은 없다(사용자 결정 2026-11-08, CT114): 옛 사건 전용 활동은 늘 그 시설에 있다.
func test_no_city_events_and_former_event_activities_always_open() -> void:
	assert_false(db.collections.has("city_events") or db.collections.has("street_events"), "도시 사건 데이터 없음")
	var s := _state()
	var pc := _pc()
	for pair: Array in [["temple", "temple_cleanse"], ["temple", "temple_feast"], ["inn", "inn_hearty"], ["inn", "inn_feast"],
			["shop", "shop_peddler"], ["library", "library_rare"]]:
		assert_true(CityActions.activities_of(s, str(pair[0])).has(str(pair[1])), "늘 있다: " + str(pair[1]))
	s.facility = "library"
	assert_eq(CityActions.check(s, pc, "library_rare"), "")
	for i in 6:
		s.next_period()
	assert_true(CityActions.activities_of(s, "library").has("library_rare"), "순이 바뀌어도 그대로")


func test_tax_by_race_year_and_deadline() -> void:
	var s := _state()
	var human := _pc("human")
	var barb := _pc("barbarian")
	var cfg := CityTax.config(s)
	var base1 := floori(700000 * CityValues.num(cfg, "scale"))
	assert_eq(CityTax.amount(s, "barbarian"), floori(base1 * 0.5), "바바리안 1~2년 차 감면")
	assert_true(CityTax.amount(s, "human") < CityTax.amount(s, "barbarian"), "인간이 더 적다")
	assert_eq(CityTax.amount(s, "dragonkin"), 0, "용인 면제")
	s.month = 25  # 3년 차
	assert_eq(CityTax.amount(s, "barbarian"), floori(800000 * CityValues.num(cfg, "scale")), "3년 차부터 감면 끝 · 2년 차부터 80만 기준")
	assert_true(CityTax.amount(s, "human") < CityTax.amount(s, "barbarian") / 2, "인간은 이종족보다 몇 배 적다")
	s.month = 12
	s.period = 0
	assert_false(CityTax.overdue(s, "human"), "기한 달 상순은 아직")
	s.period = 2
	assert_true(CityTax.overdue(s, "human"), "기한 달 하순이 끝나면 미납 = 처형")
	s.facility = "bank"
	var money := human.inventory.money
	var ctx := CityActions.perform(s, human, "bank_tax", _reg())
	assert_true(ctx.ok)
	assert_eq(human.inventory.money, money - CityTax.amount(s, "human"))
	assert_false(CityTax.overdue(s, "human"))
	assert_eq(CityActions.check(s, human, "bank_tax"), "city.reason_tax_none", "올해는 다 냈다")
	s.month = 13
	assert_true(CityTax.owed(s, "human"), "새해에는 다시")
	var poor := _pc("human")
	poor.inventory.add_money(-poor.inventory.money)
	assert_eq(CityActions.check(s, poor, "bank_tax"), "city.reason_no_money")
	assert_true(barb.race_id == "barbarian")


func test_life_state_round_trip() -> void:
	var s := _state()
	s.tax_paid_year = 1
	var t := CityState.new(db, 1)
	t.start()
	t.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(t.tax_paid_year, 1)
	assert_false(s.to_dict().has("happenings") or s.to_dict().has("ambient"), "사건은 저장하지 않는다")
	var old := s.to_dict()  # 옛 저장(사건 키가 남은 것)도 읽는다
	old.merge({"happenings": ["rare_books"], "seen_once": ["peddler"], "ambient": "fire", "ambient_pending": true,
		"ambient_seen": {"fire": 1}, "closed": ["shop"], "price_mods": {"sell:magic_stone": 0.8}})
	var u := CityState.new(db, 1)
	u.load_dict(JSON.parse_string(JSON.stringify(old)))
	assert_eq(u.tax_paid_year, 1)
	assert_eq(u.enter_facility("shop"), "", "옛 저장의 닫힌 시설도 들어간다")


func test_equipment_only_at_smithy() -> void:
	var s := _state()
	var pc := _pc()
	for id in CityShop.stock(s, "smithy_trade"):
		assert_true(CityShop.is_equipment(s, id), "대장간은 장비만 판다: " + id)
	for id in CityShop.stock(s, "shop_trade"):
		assert_false(CityShop.is_equipment(s, id), "상점은 장비를 팔지 않는다: " + id)
	assert_false(CityShop.stock(s, "smithy_trade").is_empty())
	s.facility = "smithy"
	var sword := "steel_sword"
	assert_true(CityShop.buy(s, pc, "smithy_trade", sword).ok, "대장간에서 장비를 산다")
	pc.inventory.add("ration", 1)
	assert_false(CityShop.sell(s, pc, "smithy_trade", "ration").ok)
	assert_false(CityShop.sell(s, pc, "smithy_trade", sword).ok, "대장간은 사 주지 않는다(2026-11-03 — 사기만)")
	assert_eq(CityShop.tabs(s, "smithy_trade"), ["buy"] as Array[String], "대장간 창구 = 구매만")
	s.facility = "shop"
	pc.inventory.add(sword, 1)
	assert_false(CityShop.sellable(s, pc, "shop_trade").has(sword), "상점은 장비를 받지 않는다")
	assert_false(CityShop.buy(s, pc, "shop_trade", sword).ok, "상점에서는 장비를 못 산다")
	assert_true(CityShop.sellable(s, pc, "shop_trade").has("ration"))
