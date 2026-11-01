extends TestCase
## 동료의 허기·피로(사용자 2026-10-27, C19): 미궁에서 시간·휴식·전투로 플레이어와 같이 변한다.
## 도시에서는 쉬고 먹는 회복(여관·신전)만 같이, 훈련·독서처럼 플레이어 혼자 한 일의 피로는 플레이어만.


func _pc(name: String = "시험") -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", name, {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.pool.fill_all()
	return pc


func _session(pc: PlayerCharacter, mates: Array[PlayerCharacter]) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), pc, GameClock.new(), Rng.new(5), reg.effects)
	s.monsters_enabled = false
	s.companions = mates
	s.start()
	return s


func test_time_moves_mates_hunger_and_fatigue_like_player() -> void:
	var pc := _pc()
	var mate := _pc("동료")
	var s := _session(pc, [mate])
	s.pass_time(10.0)
	assert_true(pc.pool.get_current("hunger") < 100.0, "플레이어 허기가 준다")
	assert_near(mate.pool.get_current("hunger"), pc.pool.get_current("hunger"), 0.001, "동료 허기도 같이")
	assert_true(pc.fatigue.value > 0.0, "플레이어 피로가 오른다")
	assert_near(mate.fatigue.value, pc.fatigue.value, 0.001, "동료 피로도 같이")
	s.rest()
	assert_near(mate.fatigue.value, pc.fatigue.value, 0.001, "휴식도 같이")
	s.resolve_encounter(null, "", 6)  # 무리 없는 전투 차례 소모(test_city와 같은 길)
	assert_near(mate.fatigue.value, pc.fatigue.value, 0.001, "전투 차례 피로도 같이")


func test_starved_mate_leaves_party() -> void:
	var pc := _pc()
	var mate := _pc("동료")
	var s := _session(pc, [mate])
	mate.pool.set_current("hunger", 0.0)
	mate.pool.set_current("hp", 1.0)
	s.pass_time(3.0)
	assert_true(mate.dead, "굶어 쓰러진다")
	assert_false(s.companions.has(mate), "파티에서 빠진다")
	assert_false(pc.dead, "플레이어는 멀쩡")


func test_city_rest_heals_mates_but_reading_is_players_own() -> void:
	var s := CityState.new(db, 7)
	s.start()
	var pc := _pc()
	var mate := _pc("동료")
	s.mates = [mate]
	s.set_override("activities/inn_rest/effects/1/amount", 5)
	s.set_override("activities/library_dungeon/effects/2/amount", 4)
	pc.fatigue.set_value(10.0)
	mate.fatigue.set_value(10.0)
	mate.pool.set_current("hp", 5.0)
	mate.pool.set_current("soul", 1.0)
	var reg := ContentRegistries.new().city_effects
	s.facility = "inn"
	CityActions.perform(s, pc, "inn_rest", reg)
	assert_near(mate.fatigue.value, 5.0, 0.001, "여관 휴식은 동료도")
	assert_eq(mate.pool.get_current("hp"), mate.pool.get_max("hp"), "생명력도 같이 회복")
	assert_eq(mate.pool.get_current("soul"), mate.pool.get_max("soul"), "영혼력도")
	s.facility = "library"
	CityActions.perform(s, pc, "library_dungeon", reg)
	assert_near(pc.fatigue.value, 9.0, 0.001, "독서 피로는 플레이어")
	assert_near(mate.fatigue.value, 5.0, 0.001, "동료는 그대로")


func test_feed_mate_from_shared_bag_but_torch_lights_player() -> void:
	var pc := _pc()
	var mate := _pc("동료")
	var s := _session(pc, [mate])
	mate.pool.set_current("hunger", 30.0)
	pc.inventory.add("ration", 1)
	var before := pc.pool.get_current("hunger")
	assert_true(s.use_item("ration", mate), "동료에게 먹인다")
	assert_true(mate.pool.get_current("hunger") > 30.0, "동료 허기가 찬다")
	assert_eq(pc.pool.get_current("hunger"), before, "플레이어는 그대로")
	pc.inventory.add("torch", 1)
	assert_true(s.use_item("torch", mate), "횃불")
	assert_true(pc.light.hours_left > 0.0, "빛은 플레이어에게(시야)")
