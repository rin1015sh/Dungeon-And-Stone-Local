extends TestCase
## 도시(M4 라비기온): 순 달력·행동력·피로도·시설 활동·상점·은행·정수 제거·미정(null) 값·디버그 임시값·직렬화.
## 미정 값이 필요한 시험은 CityState.overrides(디버그 임시값)로 테스트 안에서만 넣는다 — 데이터 파일은 그대로.


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _state(seed_value: int = 7) -> CityState:
	var s := CityState.new(db, seed_value)
	s.start()
	return s


func _reg() -> ScriptRegistry:
	return ContentRegistries.new().city_effects


## 모든 도시 규칙 값을 미정(null)으로 덮는다(임시값 — 데이터는 그대로). "미정이면 효과 없음" 규칙을 볼 때.
func _all_undecided(s: CityState, pc: PlayerCharacter = null) -> void:
	for path in CityValues.tunables(db):
		if path.begins_with("activities/") and (path.ends_with("/stats") or path.ends_with("/pick")) or path.contains("/calendar/") and not path.ends_with("_rule"):
			continue
		s.set_override(path, null)
	if pc != null:
		pc.fatigue.setup(CityValues.city_section(db, s.overrides, "fatigue"), false)


## 시설에 들어가 있게 한다(행동력 소모 없이 — 활동 규칙만 볼 때).
func _inside(s: CityState, facility: String) -> void:
	s.facility = facility


func test_period_cycle_and_action_points() -> void:
	var s := _state()
	assert_eq(s.month, 1, "첫 달")
	assert_eq(s.period_name(), "상순")
	assert_eq(s.ap, 3, "순이 시작되면 행동력 3")
	var seen: Array[String] = []
	for i in 3:
		s.spend_ap(1)
		s.next_period()
		seen.append("%d:%s:%d" % [s.month, s.period_name(), s.ap])
	assert_eq(seen, ["1:중순:3", "1:하순:3", "2:상순:3"], "상순 → 중순 → 하순 → 다음 달 상순, 매번 행동력 3(이월 없음)")
	assert_eq([s.year(), s.month_of_year()], [1, 2])
	s.month = 13
	assert_eq([s.year(), s.month_of_year()], [2, 1], "열두 달이 한 해")


func test_spending_all_ap_moves_to_next_period() -> void:
	var s := _state()
	for f: String in ["inn", "library", "temple"]:
		assert_eq(s.enter_facility(f), "", "들어가기 " + f)
		var advanced := s.leave_facility()
		assert_eq(advanced, f == "temple", "행동력을 다 쓰면(3번째) 다음 순")
	assert_eq(s.period_name(), "중순")
	assert_eq(s.ap, 3)


## 행동력은 시설 한 번 다녀오기에 1 — 나올 때 쓴다(어느 시설이든, CT62). 시설 안 활동은 행동력을 쓰지 않는다.
func test_only_visit_costs_ap() -> void:
	var s := _state()
	var pc := _pc()
	for f: String in s.facility_ids():
		var t := _state()
		assert_eq(t.enter_facility(f), "", "들어가기 " + f)
		assert_eq(t.ap, 3, f + " 안에서는 아직 행동력 그대로")
		t.leave_facility()
		var stub := JsonUtil.get_bool(db.get_entry("facilities", f), "placeholder")
		assert_eq(t.ap, 3 if stub else 2, f + (" 다녀와도 행동력 그대로(기능 없는 자리)" if stub else " 다녀오면 행동력 1"))
	assert_eq(s.enter_facility("inn"), "")
	for i in 5:
		assert_true(CityActions.perform(s, pc, "inn_rest", _reg()).ok, "안에서는 몇 번이든")
	assert_eq(s.ap, 3, "시설 안 활동은 행동력을 쓰지 않는다")
	assert_false(s.spend_ap(4), "모자라면 쓰지 않는다")
	s.leave_facility()
	assert_eq(s.ap, 2, "나오면서 1")
	s.leave_facility()
	assert_eq(s.ap, 2, "거리에서 다시 나가기 = 쓰지 않는다")
	s.ap = 0
	assert_eq(s.enter_facility("library"), "city.reason_no_ap", "행동력 0이면 시설에 못 들어간다")
	assert_eq(s.ap, 0)


## 하순에 행동력을 다 쓰고 나오면 순을 넘기지 않고 미궁으로(expedition_due). 돌아오면 다음 달 상순·행동력 3.
func test_late_period_ends_in_dungeon_and_return_starts_next_month() -> void:
	var s := _state()
	var due: Array[int] = []
	s.expedition_due.connect(func() -> void: due.append(1))
	for p in 3:
		for f: String in ["inn", "library", "temple"]:
			s.enter_facility(f)
			s.leave_facility()
	assert_eq(due.size(), 1, "하순이 끝나면 미궁으로 떠난다")
	assert_eq([s.month, s.period_name(), s.ap], [1, "하순", 0], "순은 넘기지 않는다(미궁에 가 있는 동안)")
	s.return_from_dungeon()
	assert_eq([s.month, s.period_name(), s.ap], [2, "상순", 3], "귀환하면 다음 달 상순")
	s.period = 1
	s.return_from_dungeon()
	assert_eq([s.month, s.period_name()], [3, "상순"], "중간에 들어갔다 와도 다음 달 상순")


func test_rest_lowers_and_read_train_raise_fatigue_and_stats() -> void:
	var s := _state()
	var pc := _pc()
	for kv: Array in [["activities/inn_rest/effects/1/amount", 5], ["activities/library_dungeon/effects/2/amount", 3],
			["activities/library_dungeon/effects/1/chance", 1.0], ["activities/library_dungeon/effects/1/amount", 2],
			["activities/training_train/effects/0/stats", ["str"]], ["activities/training_train/effects/0/chance", 1.0],
			["activities/training_train/effects/0/amount", 1], ["activities/training_train/effects/1/amount", 4]]:
		s.set_override(str(kv[0]), kv[1])
	pc.fatigue.set_value(10.0)
	_inside(s, "inn")
	CityActions.perform(s, pc, "inn_rest", _reg())
	assert_near(pc.fatigue.value, 5.0, 0.001, "휴식은 피로도를 줄인다")
	var int_before := pc.stats.get_base("int")
	_inside(s, "library")
	CityActions.perform(s, pc, "library_dungeon", _reg())
	assert_near(pc.fatigue.value, 8.0, 0.001, "독서는 피로도를 늘린다")
	assert_near(pc.stats.get_base("int"), int_before + 2.0, 0.001, "판정 성공 → 정신력 상승(영구)")
	var str_before := pc.stats.get_base("str")
	_inside(s, "training")
	CityActions.perform(s, pc, "training_train", _reg())
	assert_near(pc.fatigue.value, 12.0, 0.001, "훈련은 피로도를 늘린다")
	assert_near(pc.stats.get_base("str"), str_before + 1.0, 0.001, "판정 성공 → 근력 상승")
	assert_eq(pc.stat_history.size(), 2, "어떤 활동으로 올랐는지 기록")
	assert_eq(str(pc.stat_history[0]["activity"]), "library_dungeon")
	assert_eq(str(pc.stat_history[1]["stat"]), "str")


func test_failed_roll_still_costs_fatigue() -> void:
	var s := _state()
	var pc := _pc()
	s.set_override("activities/training_train/effects/0/stats", ["str"])
	s.set_override("activities/training_train/effects/0/chance", 0.0)
	s.set_override("activities/training_train/effects/0/amount", 1)
	s.set_override("activities/training_train/effects/1/amount", 4)
	_inside(s, "training")
	var before := pc.stats.get_base("str")
	var ctx := CityActions.perform(s, pc, "training_train", _reg())
	assert_true(ctx.ok)
	assert_eq(pc.stats.get_base("str"), before, "판정 실패 → 능력치 그대로")
	assert_near(pc.fatigue.value, 4.0, 0.001, "피로도는 판정과 상관없이")
	assert_eq(s.ap, 3, "활동은 행동력을 쓰지 않는다")


func test_same_seed_same_rolls() -> void:
	var runs: Array = []
	for r in 2:
		var s := _state(1234)
		var pc := _pc()
		s.set_override("activities/training_train/effects/0/stats", ["str", "agi", "p_res"])
		s.set_override("activities/training_train/effects/0/chance", 0.5)
		s.set_override("activities/training_train/effects/0/amount", 1)
		_inside(s, "training")
		for i in 30:
			CityActions.perform(s, pc, "training_train", _reg())
		runs.append(pc.stat_history.map(func(h: Dictionary) -> String: return str(h["stat"])))
	assert_true((runs[0] as Array).size() > 0, "성공이 한 번은 있다")
	assert_eq(runs[0], runs[1], "같은 시드 → 같은 판정·같은 능력치")


func test_every_activity_runs_with_all_values_null() -> void:
	var s := _state()
	var pc := _pc()
	pc.inventory.add_money(20000000)
	pc.inventory.add("torch", 1)
	var inst := EssenceDrop.make(db, "goblin", "", Rng.new(3))
	assert_eq(pc.essences.absorb(pc, inst), "", "정수 흡수(제거 시험용)")
	_all_undecided(s, pc)
	s.ap = 99
	var fatigue_before := pc.fatigue.value
	for f in s.facility_ids():
		s.facility = ""
		assert_eq(s.enter_facility(f), "", "들어가기 " + f)
		for act_id in CityActions.activities_of(s, f):
			var act := s.activity(act_id)
			match JsonUtil.get_str(act, "panel"):
				"":
					if CityActions.check(s, pc, act_id) == "city.reason_tax_none":
						continue  # 세금이 미정(없음)이면 납부를 고를 수 없다
					var ctx := CityActions.perform(s, pc, act_id, _reg())
					assert_true(ctx.ok and not ctx.messages.is_empty(), "미정 값으로도 실행되고 결과 문구가 있다: " + act_id)
				"shop":
					var item: String = CityShop.stock(s, act_id)[0]
					assert_true(CityShop.buy(s, pc, act_id, item).ok, "사기")
					assert_true(CityShop.sell(s, pc, act_id, item).ok, "팔기")
				"bank":
					assert_true(CityBank.deposit(s, pc, act_id, 100).ok, "맡기기")
					assert_true(CityBank.withdraw(s, pc, act_id, 100).ok, "찾기")
				"essence_remove":
					assert_true(CityTemple.remove_essence(s, pc, act_id, 0).ok, "정수 제거")
					assert_eq(pc.essences.absorbed.size(), 0)
					assert_eq(pc.essences.deletions, 1, "기존 삭제 로직(비용 증가 횟수)")
	assert_eq(pc.fatigue.value, fatigue_before, "미정이면 피로도 그대로")
	assert_eq(s.temple_merit, 0.0, "미정이면 공적치 그대로")
	assert_true(s.known_info.is_empty(), "미정이면 소문·정보 없음")


func test_bank_conserves_money_without_fee() -> void:
	var s := _state()
	var pc := _pc()
	s.set_override("city/bank/withdraw_fee", 0)
	_inside(s, "bank")
	var total := pc.inventory.money + s.bank_balance
	for step: Array in [["d", 300], ["w", 120], ["d", 77], ["w", 257]]:
		var ctx := CityBank.deposit(s, pc, "bank_account", int(step[1])) if step[0] == "d" else CityBank.withdraw(s, pc, "bank_account", int(step[1]))
		assert_true(ctx.ok, "거래 %s" % [step])
		assert_eq(pc.inventory.money + s.bank_balance, total, "소지금 + 잔액 합이 같다")
	assert_false(CityBank.withdraw(s, pc, "bank_account", s.bank_balance + 1).ok, "잔액보다 많이 못 찾는다")
	assert_false(CityBank.deposit(s, pc, "bank_account", pc.inventory.money + 1).ok, "소지금보다 많이 못 맡긴다")
	assert_false(CityBank.deposit(s, pc, "bank_account", 0).ok, "0원은 안 된다")
	assert_eq(pc.inventory.money + s.bank_balance, total)


func test_shop_uses_item_prices() -> void:
	var s := _state()
	var pc := _pc()
	_all_undecided(s)
	_inside(s, "shop")
	var stock := CityShop.stock(s)
	assert_false(stock.is_empty(), "판매 목록(거주 등급별 — 미정 값으로 덮지 않는다)")
	for id in stock:
		assert_true(CityShop.price(db, id) > 0)
		assert_true(JsonUtil.get_str(db.get_entry("items", id), "category") != "magic_stone", "마석은 안 판다")
	var money := pc.inventory.money
	var cheap: String = stock[0]
	assert_true(CityShop.buy(s, pc, "shop_trade", cheap).ok)
	assert_eq(pc.inventory.money, money - CityShop.price(db, cheap))
	pc.inventory.add("magic_stone_9", 1)
	assert_false(CityShop.sell(s, pc, "shop_trade", "magic_stone_9").ok, "마석 매입 미정 → 받지 않음")
	assert_false(CityShop.buy(s, pc, "shop_trade", "magic_stone_9").ok, "판매 목록에 없는 것은 못 산다")
	var t := _state()  # 정한 값: 판매 목록 · 판매가 50% · 마석은 제값
	_inside(t, "shop")
	assert_eq(CityShop.stock(t), (JsonUtil.get_array(JsonUtil.get_dict(db.singletons["city"], "shop"), "stock_by_residence")[0] as Array).map(func(v: Variant) -> String: return str(v)), "뒷골목 판매 목록(CT51)")
	assert_eq(CityShop.sell_price(t, "torch"), CityShop.price(db, "torch") / 2, "판매가 = 가격 50%")
	assert_false(CityShop.sell(t, pc, "shop_trade", "magic_stone_9").ok, "마석은 받지 않는다(귀환 정산 — CT58)")


func test_fatigue_carries_over_city_dungeon_city() -> void:
	var pc := _pc()
	pc.fatigue.setup({"min": 0}, false)  # 미궁 규칙 미정
	pc.fatigue.set_value(7.0)
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(3))
	var sess := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(4), reg.effects)
	sess.monsters_enabled = false
	sess.start()
	sess.wait(3.0)
	sess.rest()
	ExploreDebug.to_monument(sess)
	sess.resolve_encounter(null, "", 5)  # 전투 차례 소모 연결 지점(무리 없음)
	assert_near(pc.fatigue.value, 7.0, 0.001, "미궁에서 규칙이 미정이면 피로도 그대로 이어진다")
	var s := _state()
	_all_undecided(s)
	_inside(s, "inn")
	CityActions.perform(s, pc, "inn_rest", reg.city_effects)
	assert_near(pc.fatigue.value, 7.0, 0.001, "도시로 돌아와도 같은 값(초기화 없음)")
	pc.fatigue.setup({"dungeon": {"per_hour": 0.5, "per_combat_turn": 1.0}}, false)
	sess.wait(2.0)
	sess.resolve_encounter(null, "", 3)
	assert_near(pc.fatigue.value, 7.0 + 2.0 * 0.5 + 3.0 + _combat_hours(3) * 0.5, 0.001, "연결 지점: 규칙을 넣으면 시간·전투로 변한다")


func _combat_hours(turns: int) -> float:
	return turns * float(db.bal("combat.hours_per_turn", 0.01))


func test_fatigue_bounds_only_when_set() -> void:
	var f := Fatigue.new()
	f.setup({"start": null, "min": null, "max": null})
	assert_eq(f.value, 0.0, "start null → 0")
	f.add(-50.0)
	assert_eq(f.value, -50.0, "min null → 제한 없음")
	f.setup({"start": 10, "min": 0, "max": 20})
	f.add(100.0)
	assert_eq(f.value, 20.0, "max")
	f.add(-100.0)
	assert_eq(f.value, 0.0, "min")
	assert_true(f.effects().is_empty(), "피로도 효과는 미정 — 비어 있다")


func test_state_and_player_round_trip() -> void:
	var s := _state(99)
	var pc := _pc()
	s.next_period()
	s.spend_ap(2)
	s.temple_merit = 4.0
	s.bank_balance = 321
	s.known_info.append("d_cave_shape")
	s.set_override("city/fatigue/max", 50)
	pc.fatigue.set_value(13.0)
	pc.stat_history.append({"stat": "int", "amount": 1.0, "activity": "library_dungeon", "month": 1, "period": 1})
	var copy := CityState.new(db, 1)
	copy.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq([copy.month, copy.period, copy.ap, copy.temple_merit, copy.bank_balance, copy.known_info],
		[s.month, s.period, s.ap, s.temple_merit, s.bank_balance, s.known_info], "날짜·행동력·공적치·잔액·소문/정보")
	assert_true(copy.overrides.is_empty(), "디버그 임시값은 저장하지 않는다")
	assert_eq(copy.rng.randi_range(0, 1000000), s.rng.randi_range(0, 1000000), "난수 상태도 이어진다")
	var pc2 := _pc()
	pc2.progress_load_dict(JSON.parse_string(JSON.stringify(pc.progress_to_dict())))
	assert_near(pc2.fatigue.value, 13.0, 0.001, "피로도")
	assert_eq(pc2.stat_history.size(), 1, "활동 능력치 기록")


func test_overrides_do_not_touch_data() -> void:
	var s := _state()
	assert_true(CityValues.nulls(db).is_empty(), "미정 값이 없다(2026-10-15 모두 채움)")
	assert_true(CityValues.tunables(db).has("activities/inn_rest/effects/1/amount"), "디버그로 바꿀 수 있는 값 목록")
	assert_true(CityValues.tunables(db).has("city/fatigue/max"))
	assert_eq(CityValues.value_at(db, "activities/inn_rest/effects/1/amount"), 40.0)
	s.set_override("activities/inn_rest/effects/1/amount", 9)
	assert_eq(JsonUtil.get_float(JsonUtil.get_array(s.activity("inn_rest"), "effects")[1], "amount"), 9.0, "임시값 반영")
	assert_eq(JsonUtil.get_array(db.get_entry("activities", "inn_rest"), "effects")[1]["amount"], 40.0, "원본 데이터는 그대로")


func test_validator_lists_undecided_as_warnings() -> void:
	var v := ContentRegistries.new().make_validator()
	assert_true(v.validate(db), "도시 데이터 오류 없음: " + ", ".join(v.errors))
	for w in v.warnings:
		assert_false(w.contains("도시 미정 값"), "미정 값이 없으면 경고도 없다")
	var bad := db.get_entry("activities", "inn_rest").duplicate(true)
	bad["effects"] = [{"type": "no_such_effect"}]
	bad["panel"] = "nope"
	bad["ap_cost"] = 1
	bad["cost_stones"] = null
	db.put_entry("activities", bad)
	var v2 := ContentRegistries.new().make_validator()
	v2.validate(db)
	db.load_all("res://data")
	assert_true(v2.errors.size() >= 3, "모르는 효과·패널·ap_cost(활동은 행동력을 안 쓴다)는 오류")
	var found := false
	for w in v2.warnings:
		found = found or w.contains("도시 미정 값")
	assert_true(found, "null은 경고 목록으로")


## 피로도 단계: 50 이상 지침(민첩·정신력 −10%), 80 이상 탈진(근력·민첩·정신력 −20%). 내려가면 풀린다.
func test_fatigue_tiers_apply_modifiers() -> void:
	var pc := _pc()
	var agi := pc.stats.get_value("agi")
	pc.fatigue.set_value(55.0)
	assert_eq(pc.fatigue.tier_name(), "지침")
	assert_near(pc.stats.get_value("agi"), agi * 0.9, 0.01, "지침: 민첩 −10%")
	pc.fatigue.set_value(90.0)
	assert_eq(pc.fatigue.tier_name(), "탈진")
	assert_near(pc.stats.get_value("agi"), agi * 0.8, 0.01, "탈진: 민첩 −20%(겹치지 않는다)")
	pc.fatigue.set_value(150.0)
	assert_near(pc.fatigue.value, 100.0, 0.001, "최댓값 100")
	pc.fatigue.set_value(10.0)
	assert_eq(pc.fatigue.tier_name(), "")
	assert_near(pc.stats.get_value("agi"), agi, 0.01, "피로가 풀리면 원래대로")
	pc.fatigue.set_value(-5.0)
	assert_near(pc.fatigue.value, 0.0, 0.001, "최솟값 0")


## 은행 이자: 순이 바뀔 때마다 잔액 × 1%(내림). 찾을 때 수수료 1%.
func test_bank_interest_and_fee() -> void:
	var s := _state()
	var pc := _pc()
	s.bank_balance = 1000
	s.next_period()
	assert_eq(s.bank_balance, 1010, "순이 바뀌면 이자 1%")
	s.return_from_dungeon()
	assert_eq(s.bank_balance, 1020, "귀환(새 순)에도 이자")
	_inside(s, "bank")
	var money := pc.inventory.money
	assert_true(CityBank.withdraw(s, pc, "bank_account", 500).ok)
	assert_eq(pc.inventory.money, money + 495, "찾을 때 수수료 1%")
	assert_eq(s.bank_balance, 520)


## 달력 규칙을 비우면(null) 하순 뒤에도 미궁으로 가지 않고 다음 달로 넘어간다.
func test_calendar_rules_can_be_turned_off() -> void:
	var s := _state()
	s.set_override("city/calendar/portal_rule", null)
	s.set_override("city/calendar/return_date_rule", null)
	var due: Array[int] = []
	s.expedition_due.connect(func() -> void: due.append(1))
	s.period = 2
	s.ap = 0
	s.advance_if_spent()
	assert_eq(due.size(), 0)
	assert_eq([s.month, s.period], [2, 0], "그냥 다음 달 상순")
	s.period = 1
	s.return_from_dungeon()
	assert_eq([s.month, s.period, s.ap], [2, 1, 3], "귀환해도 날짜 그대로(행동력만 채움)")


func test_entry_is_not_refunded() -> void:
	var s := _state()
	assert_eq(s.enter_facility("shop"), "")
	assert_eq(s.enter_facility("bank"), "city.reason_inside", "안에서 다른 시설로 못 간다")
	s.leave_facility()
	assert_eq(s.ap, 2, "나와도 행동력은 돌려받지 않는다")


## 거리 그림: 레이어·건물·내부 그림이 모두 있고, 건물은 거리 안에서 서로 겹치지 않는다. 잘못된 레이어는 검증 오류.
func test_street_layers_and_art() -> void:
	var city: Dictionary = db.singletons.get("city", {})
	var street := JsonUtil.get_dict(city, "street")
	var width := JsonUtil.get_float(street, "width")
	var layers := JsonUtil.get_array(street, "layers")
	assert_true(layers.size() >= 4, "뒷배경 레이어가 여럿(하늘·원경·중경·거리…)")
	var far_layers := 0
	for v: Variant in layers:
		var d := v as Dictionary
		assert_true(ResourceLoader.exists(JsonUtil.get_str(d, "path")), "레이어 그림 있음: " + JsonUtil.get_str(d, "id"))
		if not JsonUtil.get_bool(d, "screen") and JsonUtil.get_float(d, "parallax", 1.0) < 1.0:
			far_layers += 1
	assert_true(far_layers >= 2, "시차로 움직이는 뒷배경 레이어가 둘 이상")
	var k := float(GameDatabase.single(db.render, "city.building_scale", 0.85))
	var spans: Array = []
	for id: String in db.get_collection("facilities"):
		var f := db.get_entry("facilities", id)
		for key: String in ["building", "interior"]:
			assert_true(ResourceLoader.exists(JsonUtil.get_str(f, key)), "%s %s 그림 있음" % [id, key])
		var tex := load(JsonUtil.get_str(f, "building")) as Texture2D
		var x := float(JsonUtil.get_int(f, "x"))
		spans.append([x, x + tex.get_width() * k])
		assert_true(x >= 0.0 and x + tex.get_width() * k <= width, id + "는 거리 안에")
	spans.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for i in range(1, spans.size()):
		assert_true(float(spans[i][0]) >= float(spans[i - 1][1]), "건물끼리 겹치지 않음")
	var bad := city.duplicate(true)
	bad["street"]["layers"].append({"id": "sky", "path": "assets/x.webp", "parallax": 2.0})
	db.singletons["city"] = bad
	var v2 := ContentRegistries.new().make_validator()
	v2.validate(db)
	db.load_all("res://data")
	assert_true(v2.errors.size() >= 3, "겹친 id·res:// 아닌 경로·시차 범위는 오류")


## 날씨: 순마다 weight 비율로 새로(같은 시드면 같은 날씨), 저장 왕복, 신관 영입 공적치 5000.
func test_weather_rolls_per_period() -> void:
	var seen := {}
	var a := _state(99)
	var b := _state(99)
	for i in 30:
		assert_eq(a.weather, b.weather, "같은 시드 → 같은 날씨")
		assert_false(a.weather_def().is_empty(), "정의된 날씨")
		seen[a.weather] = true
		a.next_period()
		b.next_period()
	assert_true(seen.has("clear") and seen.has("overcast"), "맑은 날과 흐린 날이 섞인다")
	var copy := CityState.new(db, 1)
	copy.load_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	assert_eq(copy.weather, a.weather, "날씨도 저장된다")
	assert_eq(JsonUtil.get_float(JsonUtil.get_dict(db.singletons["city"], "temple"), "recruit_merit"), 5000.0)


## 여관 휴식: 생명력·영혼력을 다 채운다(이미 가득이면 restore_full).
func test_inn_rest_restores_hp_and_soul() -> void:
	var s := _state()
	var pc := _pc()
	pc.pool.modify("hp", -40.0)
	pc.pool.modify("soul", -5.0)
	_inside(s, "inn")
	var ctx := CityActions.perform(s, pc, "inn_rest", _reg())
	assert_true(ctx.ok)
	assert_near(pc.pool.get_current("hp"), pc.pool.get_max("hp"), 0.01, "생명력 회복")
	assert_near(pc.pool.get_current("soul"), pc.pool.get_max("soul"), 0.01, "영혼력 회복")
	assert_true(ctx.messages.any(func(m: Dictionary) -> bool: return str(m["key"]) == "city.fx.restore"))
	var again := CityActions.perform(s, pc, "inn_rest", _reg())
	assert_true(again.messages.any(func(m: Dictionary) -> bool: return str(m["key"]) == "city.fx.restore_full"), "가득이면 다른 문구")


func test_dungeon_opens_once_a_month() -> void:
	var s := _state()
	var due: Array[int] = []
	s.expedition_due.connect(func() -> void: due.append(1))
	s.period = s.periods().size() - 1
	s.ap = 0
	s.advance_if_spent()
	assert_eq(due.size(), 1, "하순이 끝나면 포탈이 열린다")
	assert_eq(s.expedition_month, 1)
	s.ap = 0
	s.advance_if_spent()  # 같은 달에 또 하순이 끝난 것처럼(날짜를 그대로 두는 귀환 규칙 등)
	assert_eq(due.size(), 1, "같은 달에는 다시 열리지 않는다")
	assert_eq([s.month, s.period_name()], [2, "상순"], "대신 다음 달로 넘어간다")
	var copy := CityState.new(db, 1)
	copy.start()
	copy.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(copy.expedition_month, 1, "저장에 포탈 연 달이 남는다")
