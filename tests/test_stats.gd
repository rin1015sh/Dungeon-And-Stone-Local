extends TestCase
## StatDef / StatBlock / Modifier: 계산 순서, 출처별 제거, 지속시간, 세부→상위 기여, 저장.


func _defs() -> Dictionary:
	var out := {}
	for d: Dictionary in [
			{"id": "a", "min": 0, "max": 100},
			{"id": "b"},
			{"id": "a_sub", "parent": "a", "coef": 0.5}]:
		out[d["id"]] = StatDef.from_dict(d)
	return out


func test_order_base_flat_percent_clamp() -> void:
	var sb := StatBlock.new(_defs())
	sb.set_base("a", 10)
	sb.add_modifier(Modifier.new("x", "a", 5.0, 0.5))
	assert_near(sb.get_value("a"), 22.5, 0.0001, "(10+5)×1.5")
	sb.add_modifier(Modifier.new("y", "a", 0.0, 0.5))
	assert_near(sb.get_value("a"), 30.0, 0.0001, "퍼센트는 합산 후 한 번 곱한다")
	sb.add_modifier(Modifier.new("z", "a", 1000.0))
	assert_near(sb.get_value("a"), 100.0, 0.0001, "상한 클램프")
	sb.add_modifier(Modifier.new("w", "a", -5000.0))
	assert_near(sb.get_value("a"), 0.0, 0.0001, "하한 클램프")


func test_percent_multiplier_never_negative() -> void:
	var sb := StatBlock.new(_defs())
	sb.set_base("b", 10)
	sb.add_modifier(Modifier.new("debuff", "b", 0.0, -1.5))
	assert_near(sb.get_value("b"), 0.0)


func test_remove_by_source() -> void:
	var sb := StatBlock.new(_defs())
	sb.set_base("b", 10)
	sb.add_modifier(Modifier.new("essence:1", "b", 3.0))
	sb.add_modifier(Modifier.new("essence:1", "b", 0.0, 0.1))
	sb.add_modifier(Modifier.new("gear:sword", "b", 2.0))
	assert_near(sb.get_value("b"), (10 + 3 + 2) * 1.1)
	assert_eq(sb.remove_source("essence:1"), 2)
	assert_near(sb.get_value("b"), 12.0)
	assert_false(sb.has_source("essence:1"))
	assert_true(sb.has_source("gear:sword"))


func test_child_stat_feeds_parent() -> void:
	var sb := StatBlock.new(_defs())
	sb.set_base("a", 10)
	sb.set_base("a_sub", 4)
	assert_near(sb.get_value("a"), 12.0, 0.0001, "세부 4 × coef 0.5")
	sb.add_modifier(Modifier.new("x", "a_sub", 2.0))
	assert_near(sb.get_value("a"), 13.0, 0.0001, "세부 스탯 수정자도 부모에 반영")


func test_unknown_stat_is_zero() -> void:
	var sb := StatBlock.new(_defs())
	assert_near(sb.get_value("nope"), 0.0)


func test_duration_units_and_expiry() -> void:
	var sb := StatBlock.new(_defs())
	sb.add_modifier(Modifier.new("elixir", "b", 10.0, 0.0, 3.0, "hour"))
	sb.add_modifier(Modifier.new("guard", "b", 5.0, 0.0, 1.0, "turn"))
	assert_near(sb.get_value("b"), 15.0)
	var expired := sb.tick("turn", 1.0)
	assert_true(expired.has("guard"), "턴 단위 만료")
	assert_near(sb.get_value("b"), 10.0)
	assert_eq(sb.tick("hour", 2.0).size(), 0)
	assert_near(sb.source_remaining("elixir"), 1.0)
	assert_true(sb.tick("hour", 1.0).has("elixir"))
	assert_near(sb.get_value("b"), 0.0)


func test_changed_signal_fires() -> void:
	var sb := StatBlock.new(_defs())
	var hits := [0]
	sb.changed.connect(func() -> void: hits[0] += 1)
	sb.set_base("a", 1)
	sb.add_modifier(Modifier.new("x", "a", 1.0))
	sb.remove_source("x")
	assert_eq(hits[0], 3)


func test_non_stat_targets() -> void:
	var sb := StatBlock.new(_defs())
	sb.add_modifier(Modifier.new("ach", "max:hp", 20.0))
	sb.add_modifier(Modifier.new("ring", "max:hp", 0.0, 0.5))
	assert_near(sb.apply_modifiers("max:hp", 100.0), 180.0)
	assert_near(sb.apply_modifiers("max:soul", 10.0), 10.0)


func test_data_modifier_list() -> void:
	var sb := StatBlock.new(_defs())
	sb.set_base("b", 10)
	sb.add_modifiers_from_data("status:starving", [{"target": "b", "percent": -0.3}])
	assert_near(sb.get_value("b"), 7.0)
	sb.remove_source("status:starving")
	assert_near(sb.get_value("b"), 10.0)


func test_save_roundtrip() -> void:
	var sb := StatBlock.new(_defs())
	sb.set_base("a", 7)
	sb.add_modifier(Modifier.new("elixir", "a", 10.0, 0.0, 2.0, "hour"))
	var copy := StatBlock.new(_defs())
	copy.load_dict(JSON.parse_string(JSON.stringify(sb.to_dict())))
	assert_near(copy.get_value("a"), 17.0)
	assert_near(copy.source_remaining("elixir"), 2.0)


func test_registry_from_data() -> void:
	var sb := StatBlock.new(db.stats)
	assert_eq(sb.ids("core").size(), 5, "핵심 스탯 5종")
	assert_true(sb.ids("sub").size() >= 10, "세부 스탯 정의 등록(주 스탯으로 대체할 수 없는 것만 — ASSUMPTIONS ST1)")
	for id in sb.ids("sub"):
		assert_true(sb.get_def(id).implemented, "남은 세부 스탯은 모두 규칙에 연결돼 있다: %s" % id)
	# 자식 스탯 → 부모 합산(parent·coef) 규칙 자체는 남아 있다(지금 데이터에는 없음)
	var defs := db.stats.duplicate()
	defs["test_child"] = StatDef.from_dict({"id": "test_child", "name_ko": "시험", "parent": "str", "coef": 0.5})
	var sc := StatBlock.new(defs)
	sc.set_base("str", 10)
	sc.set_base("test_child", 2)
	assert_near(sc.get_value("str"), 11.0, 0.0001, "자식 스탯 × coef가 부모에 더해진다")
