extends TestCase
## ResourceDef / ResourcePool: 생명력·영혼력·허기의 최대치 수식, 코스트, 임계값, 범위, 재생, 저장.


func _stats(bases: Dictionary = {}) -> StatBlock:
	var sb := StatBlock.new(db.stats)
	sb.set_bases(bases)
	return sb


func _b(path: String) -> float:
	return float(db.bal(path, 0.0))


func _expected_soul(level: int) -> float:
	var cap := int(_b("soul.early_level_cap"))
	return _b("soul.base") + mini(level - 1, cap - 1) * _b("soul.per_level_early") \
		+ maxi(level - cap, 0) * _b("soul.per_level_late")


func test_core_resources_present() -> void:
	var pool := ResourcePool.new(db, _stats())
	var ids := pool.ids()
	assert_true(ids.has("hp") and ids.has("soul") and ids.has("hunger"), "생명력·영혼력·허기")
	assert_false(ids.has("stamina"), "예약 자원은 기본으로 빠진다")


func test_hp_max_formula_uses_stats_and_level() -> void:
	var sb := _stats({"str": 10, "p_res": 8})
	var pool := ResourcePool.new(db, sb, [], {}, 2)
	var expected := floorf(_b("hp.base") + 2 * _b("hp.per_level") + 8 * _b("hp.per_p_res"))
	assert_near(pool.get_max("hp"), expected)
	assert_near(pool.get_current("hp"), expected, 0.0001, "시작은 가득")
	sb.set_base("str", 15)
	assert_near(pool.get_max("hp"), expected, 0.0001, "근력은 생명력에 안 들어간다(J12)")
	sb.set_base("m_res", 4)
	assert_near(pool.get_max("hp"), floorf(expected + 4 * _b("hp.per_m_res")), 0.0001, "항마력도 물리내성처럼 생명력을 준다(BL2)")
	sb.set_base("m_res", 0)
	sb.set_base("p_res", 10)
	assert_near(pool.get_max("hp"), floorf(expected + 2 * _b("hp.per_p_res")), 0.0001, "스탯 변화 → 최대치 재계산(내림)")
	assert_near(pool.get_current("hp"), expected, 0.0001, "현재값은 유지")


func test_soul_max_follows_level_table() -> void:
	var pool := ResourcePool.new(db, _stats())
	for lv in range(1, 9):
		pool.set_level(lv)
		assert_near(pool.get_max("soul"), _expected_soul(lv), 0.0001, "Lv%d" % lv)
	# 원작 규칙: 5레벨까지 +10씩, 이후 +30씩
	assert_near(_expected_soul(5) - _expected_soul(4), 10.0)
	assert_near(_expected_soul(6) - _expected_soul(5), 30.0)


func test_max_modifier_and_removal() -> void:
	var sb := _stats()
	var pool := ResourcePool.new(db, sb)
	var base := pool.get_max("soul")
	sb.add_modifier(Modifier.new("achievement:floor5", "max:soul", 20.0))
	assert_near(pool.get_max("soul"), base + 20.0)
	pool.fill("soul")
	sb.remove_source("achievement:floor5")
	assert_near(pool.get_max("soul"), base)
	assert_near(pool.get_current("soul"), base, 0.0001, "최대치가 줄면 현재값 클램프")


func test_spend_is_atomic() -> void:
	var pool := ResourcePool.new(db, _stats())
	var soul := pool.get_current("soul")
	assert_true(pool.can_afford({"soul": 5}))
	assert_true(pool.spend({"soul": 5}))
	assert_near(pool.get_current("soul"), soul - 5)
	assert_false(pool.spend({"soul": 1, "hp": 99999}), "하나라도 모자라면 실패")
	assert_near(pool.get_current("soul"), soul - 5, 0.0001, "실패하면 아무것도 깎지 않는다")
	assert_false(pool.can_afford({"nothing": 1}), "없는 자원")


func test_hp_cost_cannot_kill() -> void:
	var pool := ResourcePool.new(db, _stats())
	pool.set_current("hp", 10)
	assert_false(pool.can_afford({"hp": 10}), "생명력 코스트로 0이 될 수 없다")
	assert_true(pool.can_afford({"hp": 9}))


func test_depleted_and_recovered_signals() -> void:
	var pool := ResourcePool.new(db, _stats())
	var events: Array = []
	pool.depleted.connect(func(id: String) -> void: events.append("down:" + id))
	pool.recovered.connect(func(id: String) -> void: events.append("up:" + id))
	pool.modify("soul", -9999)
	pool.modify("soul", -1)
	pool.modify("soul", 3)
	assert_eq(events, ["down:soul", "up:soul"])
	assert_false(pool.is_depleted("soul"))


func test_hunger_scope_thresholds() -> void:
	var pool := ResourcePool.new(db, _stats())
	var seen: Array = []
	pool.threshold_crossed.connect(func(_id: String, t: Dictionary, entered: bool) -> void:
		seen.append("%s:%s" % [t.get("apply_status"), "on" if entered else "off"]))
	pool.tick("time", 10.0)
	assert_near(pool.get_current("hunger"), 100.0, 0.0001, "도시에서는 허기가 줄지 않는다")
	assert_false(pool.is_active("hunger"))
	pool.set_context("dungeon", true)
	pool.tick("time", 10.0)
	assert_near(pool.get_current("hunger"), 100.0 - 10.0 * _b("hunger.decay_per_hour"), 0.0001, "미궁에서는 감소")
	pool.set_current("hunger", 31)
	pool.modify("hunger", -2)
	pool.modify("hunger", -20)
	pool.modify("hunger", 80)
	assert_eq(seen, ["hungry:on", "starving:on", "hungry:off", "starving:off"])


func test_appetite_scales_hunger_decay() -> void:
	var pool := ResourcePool.new(db, _stats({"appetite": 50}))
	pool.set_context("dungeon", true)
	var expected := -_b("hunger.decay_per_hour") * (1.0 + 50.0 * _b("hunger.appetite_coef"))
	assert_near(pool.regen_per_unit("hunger", "time"), expected)


func test_soul_regen_per_turn_and_modifier() -> void:
	var sb := _stats()
	var pool := ResourcePool.new(db, sb)
	pool.set_current("soul", 0)
	pool.tick("turn")
	var per_turn := pool.get_max("soul") * _b("soul.regen_ratio_per_turn")
	assert_near(pool.get_current("soul"), per_turn)
	sb.add_modifier(Modifier.new("charm", "regen:soul", 0.0, 1.0))
	assert_near(pool.regen_per_unit("soul", "turn"), per_turn * 2.0, 0.0001, "regen 수정자")


func test_overrides_for_monsters() -> void:
	var pool := ResourcePool.new(db, _stats(), ["hp"], {"hp": 40})
	assert_eq(pool.ids().size(), 1)
	assert_eq(pool.ids()[0], "hp")
	assert_near(pool.get_max("hp"), 40.0)


func test_save_roundtrip() -> void:
	var sb := _stats({"str": 9})
	var pool := ResourcePool.new(db, sb, [], {}, 3)
	pool.set_context("dungeon", true)
	pool.modify("hp", -12)
	pool.modify("hunger", -40)
	var data: Dictionary = JSON.parse_string(JSON.stringify(pool.to_dict()))
	var copy := ResourcePool.new(db, sb)
	copy.load_dict(data)
	assert_eq(copy.get_level(), 3)
	assert_near(copy.get_current("hp"), pool.get_current("hp"))
	assert_near(copy.get_current("hunger"), 60.0)
	assert_true(copy.is_active("hunger"))
	assert_eq(copy.active_thresholds("hunger").size(), 0)


## 허기 표시(사용자 2026-10-27, UI35): 속값은 포만도, 화면은 허기 = 최대 − 포만도(0 = 배부름, 100 = 굶주림). 음식은 "허기 -n".
func test_hunger_shown_inverted() -> void:
	var rd: ResourceDef = db.resources["hunger"]
	assert_true(rd.display_inverted)
	assert_near(rd.shown(100.0, 100.0), 0.0, 0.001, "배부르면 허기 0")
	assert_near(rd.shown(25.0, 100.0), 75.0, 0.001, "포만도 25 = 허기 75")
	var hp: ResourceDef = db.resources["hp"]
	assert_near(hp.shown(40.0, 100.0), 40.0, 0.001, "다른 자원은 그대로")
	var food := {"type": "restore_resource", "resource": "hunger", "amount": 40}
	assert_eq(ItemTooltip._effect_line(db, food), Strings.t("inventory.eff_lower", {"res": rd.name_ko, "amount": 40}), "먹으면 허기 -40")
	assert_eq(ItemTooltip._effect_line(db, {"type": "restore_resource", "resource": "hp", "amount": 30}),
		Strings.t("inventory.eff_restore", {"res": hp.name_ko, "amount": 30}), "생명력은 +30")
