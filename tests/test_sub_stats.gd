extends TestCase
## 세부 스탯 정리(ASSUMPTIONS ST1~ST5): 주 스탯 5종으로 대체할 수 없는 세부 스탯 11종이 실제 규칙에 들어가는지 하나씩 본다.
## 시각(시야) · 식욕(허기) · 자연재생력·영혼 재생력(재생) · 명중률(명중·실명) · 감응도 2(화염·냉기) · 내성 4(화염·냉기·독·어둠)(속성 피해·상태 저항·지속 피해).
## 그리고 지운 세부 스탯이 주 스탯으로 옮겨졌는지(정수 굴림·종족·함정 판정).

const KEPT := ["sight", "appetite", "natural_regen", "soul_regen", "accuracy",
	"affinity_fire", "affinity_cold",
	"resist_fire", "resist_cold", "resist_poison", "resist_dark"]
const REMOVED := ["muscle_mass", "cutting_power", "bone_strength", "body_weight", "endurance", "flexibility", "leap", "stealth",
	"dexterity", "pain_tolerance", "fighting_spirit", "adaptability", "patience", "obsession", "smell", "hearing", "cognition",
	"control", "sixth_sense", "restoration", "luck", "fame", "support", "field_of_view",
	"affinity_lightning", "affinity_earth", "resist_lightning", "resist_earth", "resist_holy",
	"digestion"]  # 소화력: 허기 말고 쓰이는 데가 없어 지움(사용자 2026-10-26)


func _actor(stats: Dictionary = {}) -> Actor:
	var base := {"str": 10, "agi": 10, "p_res": 5, "m_res": 5, "int": 5}
	base.merge(stats, true)
	return Actor.new(db, base)


func test_sub_stat_list_is_exactly_the_kept_set() -> void:
	var sb := StatBlock.new(db.stats)
	var subs := sb.ids("sub")
	subs.sort()
	var want: Array[String] = []
	want.assign(KEPT)
	want.sort()
	assert_eq(subs, want, "남은 세부 스탯")
	for id: String in REMOVED:
		assert_false(db.stats.has(id), "지운 세부 스탯: %s" % id)


func test_sight_widens_vision() -> void:
	var map := FloorMap.new(db, 9, 9, "rock_wall")
	for y in range(1, 8):
		for x in range(1, 8):
			map.set_tile(Vector2i(x, y), "cave_floor")
	var def := {"visibility_cap_m": 20.0, "ambient_light_m": 6.0}
	var a := _actor()
	var p := Vector2i(4, 4)
	var r0 := Vision.radius_m(db, def, map, a, p)
	a.stats.set_base("sight", 10)
	assert_near(Vision.radius_m(db, def, map, a, p) - r0, 1.0, 0.0001, "시각 10 → 시야 +1m")
	def["visibility_cap_m"] = 6.0
	assert_near(Vision.radius_m(db, def, map, a, p), 6.0, 0.0001, "층 시야 상한은 넘지 않는다")


func test_appetite_changes_hunger() -> void:
	var base := _actor().pool.regen_per_unit("hunger", "time")
	assert_near(base, -float(db.bal("hunger.decay_per_hour")), 0.0001, "허기는 시간마다 준다")
	var hungry := _actor({"appetite": 20}).pool.regen_per_unit("hunger", "time")
	assert_true(hungry < base, "식욕이 높으면 더 빨리 배고프다 (%f < %f)" % [hungry, base])


func test_regen_stats() -> void:
	var a0 := _actor()
	var a1 := _actor({"natural_regen": 10})
	var hp0 := a0.pool.regen_per_unit("hp", "time")
	var hp1 := a1.pool.regen_per_unit("hp", "time")
	assert_near(hp1 - hp0, 10.0 * float(db.bal("hp.regen_ratio_per_natural_regen_per_hour")) * a1.pool.get_max("hp"), 0.0001, "자연재생력 → 시간당 생명력(최대 생명력 비율)")
	for trig: String in ["turn", "time"]:
		var s0 := _actor().pool.regen_per_unit("soul", trig)
		var s1 := _actor({"soul_regen": 10}).pool.regen_per_unit("soul", trig)
		assert_true(s1 > s0, "영혼 재생력 → 영혼력 재생(%s) %f > %f" % [trig, s1, s0])


func test_accuracy_and_blind() -> void:
	var foe := _actor()
	var plain := DamageCalc.hit_chance(db, _actor(), foe, 60.0)
	var sharp := DamageCalc.hit_chance(db, _actor({"accuracy": 20}), foe, 60.0)
	assert_true(sharp > plain, "명중률이 명중 확률을 올린다")
	var blind := _actor()
	blind.statuses.apply("blind")
	assert_true(DamageCalc.hit_chance(db, blind, foe, 60.0) < plain, "실명은 명중률을 깎는다")


func test_affinities_and_resistances_by_element() -> void:
	for t: String in ["fire", "cold"]:
		var mult := DamageCalc.element_mult(db, _actor({"affinity_" + t: 10}), _actor(), t)
		assert_near(mult, 1.0 + 10 * float(db.bal("combat.affinity_per_point")), 0.0001, "감응도: %s" % t)
	for t: String in ["fire", "cold", "poison", "dark"]:
		var mult := DamageCalc.element_mult(db, _actor(), _actor({"resist_" + t: 10}), t)
		assert_near(mult, 1.0 - 10 * float(db.bal("combat.element_resist_per_point")), 0.0001, "내성: %s" % t)
	assert_near(DamageCalc.element_mult(db, _actor(), _actor({"resist_fire": 10}), "slash"), 1.0, 0.0001, "다른 유형엔 무관")
	for t: String in ["lightning", "earth", "holy"]:  # 내성·감응도 스탯을 지운 속성: 몬스터 약점·면역만 남고 배율은 1
		assert_near(DamageCalc.element_mult(db, _actor(), _actor(), t), 1.0, 0.0001, "스탯 없는 속성: %s" % t)


func test_resistances_resist_statuses() -> void:
	assert_true(_actor({"resist_cold": 30}).statuses.resist_chance("frost") > 0.0, "냉기 내성 → 서리 저항")
	assert_true(_actor({"resist_poison": 30}).statuses.resist_chance("poison") > 0.0, "독 내성 → 중독 저항")


func test_removed_stats_moved_to_core() -> void:
	# 정수 굴림: 옛 세부 스탯은 주 스탯 ×0.5로 들어갔다(본 나이트 골강도 53~57 → 물리내성 27~29 + 지구력 → 물리내성).
	for id: Variant in db.get_collection("essences").keys():
		for k: Variant in JsonUtil.get_dict(db.get_entry("essences", str(id)), "stats"):
			assert_true(db.stats.has(str(k)), "%s 정수 스탯 %s가 있다" % [id, k])
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 10, "p_res": 5, "m_res": 5, "int": 5})
	pc.set_level(3)
	var p0 := pc.stats.get_value("p_res")
	assert_eq(pc.essences.absorb(pc, EssenceDrop.make(db, "bone_knight", "red", Rng.new(1))), "")
	assert_true(pc.stats.get_value("p_res") >= p0 + 34.0, "본 나이트 정수 → 물리내성 +34 이상")
	# 종족: 야만인 근질량 → 근력, 드워프 골강도 → 물리내성
	var barb := JsonUtil.get_dict(db.get_entry("races", "barbarian"), "stat_ranges")
	assert_false(barb.has("muscle_mass"))
	# 함정 판정: 탐지 = 정신력, 해제 = 민첩
	var tomb := db.get_entry("rifts", "rift_iron_tomb")
	for ch: Variant in JsonUtil.get_array(tomb, "chapters"):
		for hz: Variant in JsonUtil.get_array(ch as Dictionary, "hazards"):
			var h := hz as Dictionary
			if h.has("detect"):
				assert_eq(JsonUtil.get_str(JsonUtil.get_dict(h, "detect"), "stat"), "int")
			if h.has("disarm"):
				assert_eq(JsonUtil.get_str(JsonUtil.get_dict(h, "disarm"), "stat"), "agi")
	var avg := _actor({"int": 7, "agi": 10})
	var checked := 0
	for ch: Variant in JsonUtil.get_array(tomb, "chapters"):
		for hz: Variant in JsonUtil.get_array(ch as Dictionary, "hazards"):
			var h := hz as Dictionary
			if h.has("detect") and h.has("disarm"):
				for kv: Array in [["detect", 7.0], ["disarm", 10.0]]:  # 탐지 = 정신력, 해제 = 민첩(옛 육감·손재주 자리)
					var dc := JsonUtil.get_float(JsonUtil.get_dict(h, str(kv[0])), "dc")
					var want := clampf(0.5 + 0.5 * (float(kv[1]) - dc) / (float(kv[1]) + dc), float(db.bal("rift.hazard_min")), float(db.bal("rift.hazard_max")))
					assert_near(RiftHazards.success_chance(db, avg, JsonUtil.get_dict(h, str(kv[0]))), want, 0.001, "평균 캐릭터 %s 확률(비율 공식)" % kv[0])
				checked += 1
	assert_true(checked > 0, "강철의 묘 함정을 확인했다")
