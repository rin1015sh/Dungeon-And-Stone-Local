extends TestCase
## 도시 생활(2026-10-20): 오늘의 거리(CityHappenings) · 세금(CityTax) · 저장.


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


func test_happenings_roll_by_rules_and_open_activities() -> void:
	var a := _state(11)
	var b := _state(11)
	assert_eq(a.happenings, b.happenings, "같은 시드면 같은 사건")
	var seen := {}
	for i in 30:
		a.next_period()
		var facs: Array[String] = []
		for id in a.happenings:
			var f := CityHappenings.facility_of(db, id)
			assert_false(facs.has(f), "한 시설에 사건 둘은 없다")
			facs.append(f)
			seen[id] = true
			assert_true(CityHappenings.lit(a, f), "걸린 시설은 등롱")
		assert_true(a.happenings.size() >= 1 and a.happenings.size() <= 2, "순마다 1~2개")
	var s := _state()
	s.weather = "fog"
	assert_false(CityHappenings.eligible(s).has("feast_day"), "축일은 맑은 날만")
	s.weather = "clear"
	assert_true(CityHappenings.eligible(s).has("feast_day"))
	s.happenings.assign(["lecture"])
	s.facility = "training"
	var pc := _pc()
	assert_eq(CityActions.activities_of(s, "training")[0], "training_lecture", "사건 활동이 맨 앞")
	assert_eq(CityActions.check(s, pc, "training_lecture"), "")
	s.happenings.clear()
	assert_eq(CityActions.check(s, pc, "training_lecture"), "city.reason_not_here", "사건이 없으면 고를 수 없다")


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
	s.seen_once.assign(["peddler"])
	var t := CityState.new(db, 1)
	t.start()
	t.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(t.tax_paid_year, 1)
	assert_eq(t.happenings, s.happenings, "이번 순 사건")
	assert_eq(t.seen_once, s.seen_once)


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
	assert_true(CityShop.sellable(s, pc, "smithy_trade").has(sword))
	pc.inventory.add("ration", 1)
	assert_false(CityShop.sellable(s, pc, "smithy_trade").has("ration"), "대장간은 식량을 받지 않는다")
	assert_false(CityShop.sell(s, pc, "smithy_trade", "ration").ok)
	assert_true(CityShop.sell(s, pc, "smithy_trade", sword).ok, "장비는 대장간에 판다")
	s.facility = "shop"
	pc.inventory.add(sword, 1)
	assert_false(CityShop.sellable(s, pc, "shop_trade").has(sword), "상점은 장비를 받지 않는다")
	assert_false(CityShop.buy(s, pc, "shop_trade", sword).ok, "상점에서는 장비를 못 산다")
	assert_true(CityShop.sellable(s, pc, "shop_trade").has("ration"))
