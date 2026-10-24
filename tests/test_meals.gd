extends TestCase
## 여관 식사(Meals — 사용자 결정 2026-10-23): 요리 = 미궁에서 잠깐 받는 버프 상태(meal_<id>), 전투 수·미궁 시간만큼, 한 번에 하나.


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _battle(pc: PlayerCharacter) -> Battle:
	var party: Array[Actor] = [pc]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["goblin"], Combatant.SIDE_PARTY)


func test_every_meal_is_a_buff_with_a_scene() -> void:
	var meals := db.get_collection("meals")
	assert_true(meals.size() >= 20, "요리가 여럿")
	for id: String in meals:
		assert_true(Strings.has("city.meal." + id), "장면 문구 city.meal." + id)
		if JsonUtil.get_str(meals[id], "menu") == "plain":
			assert_false(db.has_entry("statuses", Meals.PREFIX + id), id + "는 버프 없는 요기")
			continue
		var st := db.get_entry("statuses", Meals.PREFIX + id)
		assert_eq(JsonUtil.get_str(st, "kind"), "buff", id)
		assert_eq(JsonUtil.get_str(st, "name_ko"), JsonUtil.get_str(meals[id], "name_ko"), "상태 이름 = 요리 이름")
		assert_true(Strings.has("city.meal." + id), "장면 문구 city.meal." + id)
		var art := JsonUtil.get_str(meals[id], "art")
		assert_true(not art.is_empty() and FileAccess.file_exists(art), "요리 그림 " + art)
	for menu: String in ["plain", "light", "hearty", "special"]:
		assert_false(Meals.pick(db, menu, Rng.new(1)).is_empty(), menu)


func test_pick_is_random_over_the_menu() -> void:
	var seen := {}
	var rng := Rng.new(5)
	for i in 200:
		var id := Meals.pick(db, "hearty", rng)
		assert_eq(JsonUtil.get_str(db.get_entry("meals", id), "menu"), "hearty", "그 차림표에서만")
		seen[id] = true
	assert_true(seen.size() >= 8, "여러 가지가 나온다(%d)" % seen.size())


func test_one_meal_at_a_time_and_stat_buff() -> void:
	var pc := _pc()
	var base := pc.stats.get_value("str")
	assert_true(Meals.eat(pc, "boar_rib_grill"))
	assert_near(pc.stats.get_value("str"), base * 1.1, 0.01, "멧돼지 갈비 → 근력 +10%")
	Meals.eat(pc, "honey_quail")
	assert_eq(Meals.current(pc), Meals.PREFIX + "honey_quail", "새로 먹으면 앞의 것은 사라진다")
	assert_near(pc.stats.get_value("str"), base, 0.01, "근력은 원래대로")


func test_battle_meal_counts_battles() -> void:
	var pc := _pc()
	Meals.eat(pc, "squid_ink_fry")
	var b := _battle(pc)
	var c := b.next_turn()
	var with_meal := b.flee_chance(c)
	pc.statuses.remove(Meals.PREFIX + "squid_ink_fry")
	assert_true(b.flee_chance(c) < with_meal, "먹물 튀김 → 도주 확률이 오른다")
	Meals.eat(pc, "squid_ink_fry")
	pc.advance_hours(48.0)
	assert_true(pc.statuses.has(Meals.PREFIX + "squid_ink_fry"), "전투 수 단위는 시간으로 줄지 않는다")
	for i in 3:
		assert_true(pc.statuses.has(Meals.PREFIX + "squid_ink_fry"), "전투 %d 전" % (i + 1))
		BattleRules.cleanup(_battle(pc))
	assert_false(pc.statuses.has(Meals.PREFIX + "squid_ink_fry"), "전투 3번 뒤 사라진다")


func test_hour_meal_counts_dungeon_hours() -> void:
	var pc := _pc()
	Meals.eat(pc, "bitter_herb_gukbap")
	assert_near(pc.stats.get_value("resist_poison"), 25.0, 0.01, "쓴나물 국밥 → 독 내성 +25")
	BattleRules.cleanup(_battle(pc))
	assert_true(pc.statuses.has(Meals.PREFIX + "bitter_herb_gukbap"), "시간 단위는 전투로 줄지 않는다")
	pc.advance_hours(11.0)
	assert_true(pc.statuses.has(Meals.PREFIX + "bitter_herb_gukbap"))
	pc.advance_hours(1.5)
	assert_false(pc.statuses.has(Meals.PREFIX + "bitter_herb_gukbap"), "12시간 뒤 사라진다")


func test_inn_meal_serves_a_dish_and_eases_fatigue() -> void:
	var s := CityState.new(db, 7)
	s.start()
	s.facility = "inn"
	var pc := _pc()
	pc.fatigue.set_value(40.0)
	var ctx := CityActions.perform(s, pc, "inn_meal", ContentRegistries.new().city_effects)
	assert_true(ctx.ok)
	assert_near(pc.fatigue.value, 25.0, 0.01, "식사 → 피로도 −15")
	var cur := Meals.current(pc)
	assert_false(cur.is_empty(), "요리 효과가 걸렸다")
	assert_eq(JsonUtil.get_str(db.get_entry("meals", cur.trim_prefix(Meals.PREFIX)), "menu"), "light")
	assert_true(ctx.messages.any(func(m: Dictionary) -> bool: return str(m["key"]) == "city.meal." + cur.trim_prefix(Meals.PREFIX)), "요리 장면")


func test_meal_survives_save_and_clears_after_expedition() -> void:
	var pc := _pc()
	Meals.eat(pc, "smoked_eel_rice")
	var hp := pc.pool.get_max("hp")
	BattleRules.cleanup(_battle(pc))
	var d := pc.statuses.to_dict()
	var back := _pc()
	back.statuses.load_dict(d)
	assert_eq(back.statuses.remaining(Meals.PREFIX + "smoked_eel_rice"), [2.0, "battle"], "남은 전투 수가 저장된다")
	Meals.clear(pc)
	assert_eq(Meals.current(pc), "")
	assert_true(pc.pool.get_max("hp") < hp, "생명력 최대치 +10%가 빠졌다")


## 값대(CT48): 요기 < 식사 < 든든한 식사 < 특식 — 좋은 버프일수록 비싸다. 요기는 버프 없이 피로만, 걸린 요리 효과는 그대로.
func test_menus_are_priced_by_tier() -> void:
	var last := -1
	for act in ["inn_snack", "inn_meal", "inn_hearty", "inn_feast"]:
		var cost := JsonUtil.get_int(db.get_entry("activities", act), "cost_stones")
		assert_true(cost > last, "%s %d스톤" % [act, cost])
		last = cost
	var pc := _pc()
	Meals.eat(pc, "boar_rib_grill")
	assert_true(Meals.eat(pc, "barley_porridge"))
	assert_eq(Meals.current(pc), Meals.PREFIX + "boar_rib_grill", "요기는 버프를 지우지 않는다")
	Meals.eat(pc, "drake_tail_steak")
	assert_eq(Meals.current(pc), Meals.PREFIX + "drake_tail_steak", "두 번 먹으면 마지막 것만")


func test_snack_only_eases_fatigue() -> void:
	var s := CityState.new(db, 7)
	s.start()
	s.facility = "inn"
	var pc := _pc()
	pc.fatigue.set_value(40.0)
	var ctx := CityActions.perform(s, pc, "inn_snack", ContentRegistries.new().city_effects)
	assert_true(ctx.ok)
	assert_near(pc.fatigue.value, 30.0, 0.01, "요기 → 피로도 −10")
	assert_eq(Meals.current(pc), "", "버프 없음")
