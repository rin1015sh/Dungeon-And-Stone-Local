extends TestCase
## 도시 생활(2026-10-20): 오늘의 거리(CityHappenings) · 귀환 결산·명성(CityRenown) · 인연(CityBonds) · 세금(CityTax) · 저장.


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
	assert_false(seen.has("sparring") or seen.has("adventurers"), "명성 1단계 전에는 대련·모험가 무리가 오지 않는다")
	var s := _state()
	s.weather = "fog"
	assert_false(CityHappenings.eligible(s).has("feast_day"), "축일은 맑은 날만")
	s.weather = "clear"
	assert_true(CityHappenings.eligible(s).has("feast_day"))
	s.renown = 25
	assert_true(CityHappenings.eligible(s).has("sparring"), "명성 1단계면 대련")
	s.happenings.assign(["lecture"])
	s.facility = "training"
	var pc := _pc()
	assert_eq(CityActions.activities_of(s, "training")[0], "training_lecture", "사건 활동이 맨 앞")
	assert_eq(CityActions.check(s, pc, "training_lecture"), "")
	s.happenings.clear()
	assert_eq(CityActions.check(s, pc, "training_lecture"), "city.reason_not_here", "사건이 없으면 고를 수 없다")


func test_return_settles_renown_and_leaves_scene() -> void:
	var s := _state()
	s.return_from_dungeon({"explore.lord_defeated": 1, "kill": 12})
	assert_eq(s.renown, 25 + 12, "군주 25 + 처치 12")
	assert_eq(CityRenown.stage(s), 1)
	assert_eq(s.pending_lines.size(), 2, "군주 장면 + 단계 오름")
	assert_true(s.pending_lines[0].begins_with("city.return.lord."))
	assert_eq(s.pending_lines[1], "city.return.stage_up.1")
	assert_true(Strings.has(s.pending_lines[0]) and Strings.has(s.pending_lines[1]))
	var t := _state()
	t.return_from_dungeon({"kill": 5})
	assert_eq(t.renown, 0, "처치가 min_count(10) 미만이면 점수 없음")
	assert_true(t.pending_lines.is_empty(), "장면도 없음")
	t.return_from_dungeon({})
	assert_eq([t.month, t.period], [3, 0], "날짜는 그대로 다음 달 상순")


func test_bond_stages_scenes_perks_and_checks() -> void:
	var s := _state()
	var pc := _pc()
	s.facility = "inn"
	var meal := CityActions.cost(s, "inn_meal")
	var ctx := CityActions.perform(s, pc, "inn_talk", _reg())
	assert_true(ctx.ok)
	assert_eq(CityBonds.stage(s, "innkeeper"), 1, "말 걸기 2점 = 첫 장면")
	assert_true(ctx.messages.any(func(m: Dictionary) -> bool: return str(m["key"]) == "city.people.innkeeper.s1"), "장면 문구")
	CityActions.perform(s, pc, "inn_talk", _reg())
	CityActions.perform(s, pc, "inn_talk", _reg())
	assert_eq(CityBonds.stage(s, "innkeeper"), 2, "6점 = 둘째 장면")
	assert_eq(CityActions.cost(s, "inn_meal"), meal / 2, "식사 반값")
	for i in 4:
		CityActions.perform(s, pc, "inn_talk", _reg())
	assert_eq(CityBonds.stage(s, "innkeeper"), 2, "셋째 장면은 명성 1단계가 필요하다")
	s.renown = 25
	var bag := pc.inventory.count("leftovers")
	CityActions.perform(s, pc, "inn_talk", _reg())
	assert_eq(CityBonds.stage(s, "innkeeper"), 3)
	assert_eq(pc.inventory.count("leftovers"), bag + 2, "장면 효과(선물)는 그때 한 번")
	# 판정: 물리내성 12 이상이면 통과 → 휴식 할인
	var strong := _pc("barbarian", {"p_res": 13})
	var s2 := _state()
	s2.facility = "inn"
	s2.bonds["innkeeper"] = 19.0
	s2.bond_stage["innkeeper"] = 3
	var rest := CityActions.cost(s2, "inn_rest")
	CityActions.perform(s2, strong, "inn_talk", _reg())
	assert_eq(CityBonds.stage(s2, "innkeeper"), 4)
	assert_true(bool(s2.bond_checks.get("innkeeper:4")), "판정 통과 기록")
	assert_eq(CityActions.cost(s2, "inn_rest"), floori(rest * 0.7), "통과 보상 = 휴식 할인")
	var weak := _pc("human", {"p_res": 3})
	assert_true(weak.stats.get_value("p_res") < 12.0, "판정 시험용 — 물리내성 낮음(%s)" % weak.stats.get_value("p_res"))
	var s3 := _state()
	s3.facility = "inn"
	s3.bonds["innkeeper"] = 19.0
	s3.bond_stage["innkeeper"] = 3
	CityActions.perform(s3, weak, "inn_talk", _reg())
	assert_false(bool(s3.bond_checks.get("innkeeper:4", true)), "물리내성이 모자라면 실패")
	assert_eq(CityActions.cost(s3, "inn_rest"), rest, "실패하면 할인 없음")


func test_bond_unlocks_activity_and_shop_discount() -> void:
	var s := _state()
	var pc := _pc("human", {"str": 13})
	s.renown = 25
	s.facility = "training"
	s.bonds["instructor"] = 11.0
	s.bond_stage["instructor"] = 2
	assert_false(CityActions.activities_of(s, "training").has("training_private"))
	CityActions.perform(s, pc, "training_talk", _reg())
	assert_true(CityActions.activities_of(s, "training").has("training_private"), "근력 판정 통과 = 개인 지도")
	s.facility = "shop"
	var full := CityShop.buy_price(s, "torch")
	s.bonds["merchant"] = 5.0
	s.bond_stage["merchant"] = 1
	CityActions.perform(s, pc, "shop_talk", _reg())
	assert_eq(CityShop.buy_price(s, "torch"), floori(full * 0.9), "상점 주인 둘째 장면 = 10% 할인")
	var money := pc.inventory.money
	assert_true(CityShop.buy(s, pc, "shop_trade", "torch").ok)
	assert_eq(pc.inventory.money, money - floori(full * 0.9))


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
	s.renown = 33
	s.bonds = {"priest": 7.0}
	s.bond_stage = {"priest": 2}
	s.bond_checks = {"priest:4": true}
	s.tax_paid_year = 1
	s.seen_once.assign(["peddler"])
	var t := CityState.new(db, 1)
	t.start()
	t.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq([t.renown, t.tax_paid_year, CityBonds.stage(t, "priest"), CityBonds.points(t, "priest")], [33, 1, 2, 7.0])
	assert_eq(t.happenings, s.happenings, "이번 순 사건")
	assert_eq(t.seen_once, s.seen_once)
	assert_true(bool(t.bond_checks.get("priest:4")))
