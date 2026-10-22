extends TestCase
## 거리 사건(2026-10-21, CT42 — CityAmbient): 순마다 행동력 없이 · 교수형·포고(반드시) · 판정·선택지 · 닫힘·값 배율 · 저장.


func _pc(race: String = "human", stats: Dictionary = {}) -> PlayerCharacter:
	var base := {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6}
	base.merge(stats, true)
	var pc := PlayerCharacter.create(db, race, "warrior", "시험", base)
	pc.inventory.add_money(10000)
	return pc


func _state(seed_value: int = 7) -> CityState:
	var s := CityState.new(db, seed_value)
	s.start()
	return s


func _reg() -> ScriptRegistry:
	return ContentRegistries.new().city_effects


func test_rolls_once_per_period_without_ap() -> void:
	var s := _state(3)
	var seen := 0
	for i in 40:
		s.next_period()
		var ap := s.ap
		var id := CityAmbient.roll(s, "human")
		assert_eq(CityAmbient.roll(s, "human"), "", "한 순에 한 번만 굴린다")
		assert_eq(s.ap, ap, "행동력을 쓰지 않는다")
		if not id.is_empty():
			seen += 1
			assert_true(db.has_entry(CityAmbient.COL, id))
			assert_false(CityAmbient.line_keys(id, "intro").is_empty(), "장면 문구: " + id)
	assert_true(seen > 5 and seen < 40, "확률로 일어난다(%d/40)" % seen)
	var t := _state(3)
	var u := _state(3)
	for i in 6:
		t.next_period()
		u.next_period()
		assert_eq(CityAmbient.roll(t, "human"), CityAmbient.roll(u, "human"), "같은 시드면 같은 사건")


func test_hanging_and_notice_are_forced() -> void:
	var s := _state()
	s.month = CityTax.due_month(s) + 1  # 기한 다음 달(2년 차 1월) 상순
	s.period = 0
	s.ambient_pending = true
	assert_eq(CityAmbient.roll(s, "human"), "hanging", "세금 기한 다음 달 상순 = 교수형")
	s.period = 1
	s.ambient_pending = true
	assert_true(CityAmbient.roll(s, "human") != "hanging", "상순에만")
	s.month = CityTax.due_month(s)
	s.period = 0
	s.ambient_pending = true
	assert_eq(CityAmbient.roll(s, "human"), "tax_notice", "기한 달 상순 + 안 냈으면 포고")
	s.tax_paid_year = s.year()
	s.ambient_pending = true
	assert_true(CityAmbient.roll(s, "human") != "tax_notice", "냈으면 포고 없음")
	s.tax_paid_year = 0
	s.ambient_pending = true
	assert_true(CityAmbient.roll(s, "dragonkin") != "tax_notice", "면제 종족은 포고 없음")


func test_cooldown_and_weather() -> void:
	var s := _state()
	s.month = 5
	s.period = 1
	s.weather = "fog"
	assert_true(CityAmbient.eligible(s, "human").has("pickpocket"))
	assert_eq(CityAmbient.force(s, "pickpocket"), "pickpocket")
	assert_false(CityAmbient.eligible(s, "human").has("pickpocket"), "쿨다운 동안 다시 안 나온다")
	s.month = 7
	assert_true(CityAmbient.eligible(s, "human").has("pickpocket"))
	assert_true(CityAmbient._weight(s, db.get_entry(CityAmbient.COL, "pickpocket")) > CityAmbient._weight(s, db.get_entry(CityAmbient.COL, "drunk")), "안개 낀 날 소매치기가 잦다")


func test_pickpocket_check() -> void:
	var s := _state()
	var quick := _pc("human", {"agi": 40})
	var slow := _pc("human", {"agi": 1})
	var chk := JsonUtil.get_dict(db.get_entry(CityAmbient.COL, "pickpocket"), "check")
	assert_true(CityAmbient.check_chance(quick, chk) > CityAmbient.check_chance(slow, chk), "민첩이 높으면 잘 막는다")
	var lost := 0
	for i in 20:
		CityAmbient.force(s, "pickpocket")
		var before := slow.inventory.money
		var r := CityAmbient.resolve(s, slow, -1, _reg())
		assert_true(str(r["outcome"]) in ["result_ok", "result_fail"])
		if r["outcome"] == "result_fail":
			assert_true(slow.inventory.money < before, "털리면 돈이 준다")
			lost += 1
		else:
			assert_eq(slow.inventory.money, before)
	assert_true(lost > 0)
	assert_eq(s.ap, s.ap_per_period(), "행동력 그대로")


func test_choices_cost_and_effects() -> void:
	var s := _state()
	var pc := _pc()
	CityAmbient.force(s, "beggar")
	var money := pc.inventory.money
	var merit := s.temple_merit
	var r := CityAmbient.resolve(s, pc, 0, _reg())
	assert_eq(r["outcome"], "give")
	assert_eq(pc.inventory.money, money - 10, "동전을 넣었다")
	assert_true(s.temple_merit > merit, "공적치")
	CityAmbient.force(s, "beggar")
	assert_eq(CityAmbient.resolve(s, pc, 1, _reg())["outcome"], "pass")
	var poor := _pc()
	poor.inventory.add_money(-poor.inventory.money)
	CityAmbient.force(s, "dubious_peddler")
	assert_false(CityAmbient.can_choose(poor, CityAmbient.choices(s)[0]), "돈이 없으면 못 산다")
	for id: String in db.get_collection(CityAmbient.COL):
		for c: Variant in JsonUtil.get_array(db.get_entry(CityAmbient.COL, id), "choices"):
			assert_true(Strings.has("city.street.%s.choice.%s" % [id, JsonUtil.get_str(c, "id")]), "선택지 이름: " + id)


func test_closed_facility_and_prices() -> void:
	var s := _state()
	var pc := _pc()
	s.happenings.clear()
	CityAmbient.force(s, "checkpoint")
	CityAmbient.resolve(s, pc, -1, _reg())
	assert_eq(s.closed.size(), 1, "시설 하나가 닫혔다")
	assert_true(s.closed[0] != "bank", "은행은 닫지 않는다")
	assert_eq(s.enter_facility(s.closed[0]), "city.reason_closed")
	var potion := CityShop.buy_price(s, "minor_potion")
	CityAmbient.force(s, "potion_shortage")
	CityAmbient.resolve(s, pc, -1, _reg())
	assert_eq(CityShop.buy_price(s, "minor_potion"), floori(potion * 1.5), "포션 품귀")
	var stone := CityShop.sell_price(s, "magic_stone_8")
	CityAmbient.force(s, "stone_demand")
	CityAmbient.resolve(s, pc, -1, _reg())
	assert_true(CityShop.sell_price(s, "magic_stone_8") > stone, "마석 매집")
	var rest := CityActions.cost(s, "inn_rest")
	CityAmbient.force(s, "plague")
	CityAmbient.resolve(s, pc, -1, _reg())
	assert_true(CityActions.cost(s, "inn_rest") > rest, "역병 소문 — 여관 값")
	s.next_period()
	assert_true(s.closed.is_empty() and s.price_mods.is_empty(), "순이 바뀌면 원래대로")
	assert_eq(CityShop.buy_price(s, "minor_potion"), CityShop.price(db, "minor_potion"))


## 사건마다 일러스트 한 장(CT45 — 일어나면 도시를 덮는다).
func test_every_event_has_art() -> void:
	for id: String in db.get_collection(CityAmbient.COL):
		var art := JsonUtil.get_str(db.get_entry(CityAmbient.COL, id), "art")
		assert_true(not art.is_empty() and ResourceLoader.exists(art), "일러스트: " + id)


func test_round_trip() -> void:
	var s := _state()
	CityAmbient.force(s, "fire")
	CityAmbient.resolve(s, _pc(), -1, _reg())
	s.price_mods["sell:magic_stone"] = 0.8
	var t := CityState.new(db, 1)
	t.start()
	t.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(t.ambient, "fire")
	assert_false(t.ambient_pending)
	assert_eq(t.closed, s.closed)
	assert_eq(t.price_mult("sell:magic_stone"), 0.8)
	assert_true(t.ambient_seen.has("fire"))
