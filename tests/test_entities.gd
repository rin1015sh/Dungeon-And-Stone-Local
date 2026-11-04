extends TestCase
## Actor·StatusSet·Inventory·LightSource·GameClock·효과 레지스트리·아이템 사용.


func _actor(bases: Dictionary = {}) -> Actor:
	return Actor.new(db, bases)


func _b(path: String) -> float:
	return float(db.bal(path, 0.0))


func test_clock() -> void:
	var c := GameClock.new()
	var total := [0.0]
	c.advanced.connect(func(h: float, _t: float) -> void: total[0] += h)
	c.advance(25.5)
	assert_eq(c.day(), 2)
	assert_eq(c.hhmm(), "01:30")
	assert_near(total[0], 25.5)
	c.advance(-1.0)
	assert_near(c.total_hours, 25.5, 0.0001, "음수 시간은 무시")


func test_status_modifiers_follow_apply_and_remove() -> void:
	var a := _actor({"str": 10, "agi": 10})
	var events: Array = []
	a.status_changed.connect(func(id: String, on: bool) -> void: events.append("%s:%s" % [id, on]))
	assert_true(a.statuses.apply("starving"))
	assert_near(a.stats.get_value("str"), 7.0, 0.0001, "굶주림 근력 -30%")
	assert_true(a.statuses.remove("starving"))
	assert_near(a.stats.get_value("str"), 10.0)
	assert_eq(events, ["starving:true", "starving:false"])


func test_status_duration_periodic_and_stacking() -> void:
	var a := _actor()
	var bleed := _b("status.bleed_per_turn")
	var hp := a.pool.get_current("hp")
	a.statuses.apply("bleeding")
	a.statuses.apply("bleeding")
	assert_eq(a.statuses.stacks("bleeding"), 2)
	a.advance_turns(1.0)
	assert_near(a.pool.get_current("hp"), hp - 2.0 * bleed, 0.0001, "중첩 수만큼 주기 피해")
	a.advance_turns(2.0)
	assert_false(a.statuses.has("bleeding"), "3턴 지속 후 해제")
	assert_near(a.pool.get_current("hp"), hp - 6.0 * bleed)


func test_status_flags() -> void:
	var a := _actor()
	assert_false(a.statuses.has_flag("no_skills"))
	a.pool.set_current("soul", 0.0)
	assert_true(a.statuses.has("soul_exhaustion"), "영혼력 0 → 영혼탈진")
	assert_true(a.statuses.has_flag("no_skills"))
	a.advance_turns(1.0)
	assert_true(a.statuses.has("soul_exhaustion"), "조금 차올라서는 풀리지 않는다(R13 — 10%)")
	a.pool.set_current("soul", a.pool.get_max("soul") * 0.1)
	assert_false(a.statuses.has("soul_exhaustion"), "10%까지 차오르면 해제")


func test_hunger_thresholds_drive_statuses() -> void:
	var a := _actor()
	a.pool.set_context("dungeon", true)
	var decay := _b("hunger.decay_per_hour")
	a.advance_hours(71.0 / decay)
	assert_true(a.statuses.has("hungry"), "30% 이하 → 허기")
	a.advance_hours(20.0 / decay)
	assert_true(a.statuses.has("starving"), "10% 이하 → 굶주림")
	a.pool.modify("hunger", 60.0, "food")
	assert_false(a.statuses.has("hungry") or a.statuses.has("starving") or a.statuses.has("famished"), "먹으면 해제")


func test_starvation_kills_with_cause() -> void:
	var a := _actor()
	a.pool.set_context("dungeon", true)
	var cause := [""]
	a.died.connect(func(c: String) -> void: cause[0] = c)
	var hours := 0
	while not a.dead and hours < 1000:
		a.advance_hours(1.0)
		hours += 1
	assert_true(a.dead, "굶어 죽는다")
	assert_eq(cause[0], "status:starvation")
	assert_eq(a.death_cause, "status:starvation")
	a.advance_hours(10.0)
	assert_eq(a.pool.get_current("hp"), 0.0, "죽은 뒤에는 시간이 흐르지 않는다")


func test_min_value_keeps_alive() -> void:
	var a := _actor()
	a.pool.set_min_value("hp", 1.0)
	a.pool.modify("hp", -9999.0, "debug")
	assert_near(a.pool.get_current("hp"), 1.0)
	assert_false(a.dead)
	a.pool.set_min_value("hp", 0.0)
	a.pool.modify("hp", -9999.0, "debug")
	assert_true(a.dead)
	assert_eq(a.death_cause, "debug")


func test_inventory() -> void:
	var inv := Inventory.new()
	var changes := [0]
	inv.changed.connect(func(_id: String, _n: int) -> void: changes[0] += 1)
	inv.add("torch", 2)
	inv.add("ration")
	assert_eq(inv.count("torch"), 2)
	assert_false(inv.remove("torch", 3), "모자라면 실패")
	assert_true(inv.remove("torch", 2))
	assert_false(inv.has("torch"))
	assert_eq(inv.ids().size(), 1)
	assert_eq(inv.ids()[0], "ration")
	assert_eq(changes[0], 3)
	var copy := Inventory.new()
	copy.load_dict(inv.to_dict())
	assert_eq(copy.count("ration"), 1)


func test_effect_registry() -> void:
	var reg := EffectRegistry.new()
	for t: String in ["restore_resource", "light_source", "apply_status", "remove_status"]:
		assert_true(reg.has_type(t), t)
	assert_eq(reg.check_data({"type": "restore_resource", "resource": "nope", "amount": 1}, db).size(), 1)
	assert_eq(reg.check_data({"type": "no_such_effect"}, db).size(), 1)
	assert_eq(reg.check_data({"type": "light_source", "radius_m": 5, "hours": 1}, db).size(), 0)


## 포션: 특정값과 최대치 비율 중 더 큰 쪽으로 회복하고, 쓴 결과에 수치(res·delta)가 남는다.
func test_potions_heal_fixed_or_percent() -> void:
	var reg := EffectRegistry.new()
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {})
	pc.inventory.add("minor_potion", 1)
	pc.inventory.add("medium_potion", 1)
	var hp_max := pc.pool.get_max("hp")
	pc.pool.set_current("hp", 1.0)
	var ctx := ItemUser.use(reg, pc, "minor_potion", Rng.new(1))
	var low := maxf(40.0, floorf(hp_max * 0.15))
	assert_near(pc.pool.get_current("hp"), minf(1.0 + low, hp_max), 0.001, "하급 포션 = 40 또는 15% 중 큰 값")
	var num: Dictionary = {}
	for m: Dictionary in ctx.messages:
		if str(m["key"]) == "effect.restore":
			num = m["args"]
	assert_eq(str(num.get("res", "")), "hp", "쓴 결과에 자원")
	assert_eq(int(num.get("delta", 0)), int(minf(low, hp_max - 1.0)), "쓴 결과에 늘어난 수치")
	pc.pool.set_current("hp", 1.0)
	ItemUser.use(reg, pc, "medium_potion", Rng.new(1))
	assert_near(pc.pool.get_current("hp"), minf(1.0 + maxf(90.0, floorf(hp_max * 0.3)), hp_max), 0.001, "중급 포션 = 90 또는 30% 중 큰 값")


func test_player_create_and_item_use() -> void:
	var reg := EffectRegistry.new()
	var rng := Rng.new(1)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {})
	assert_eq(pc.inventory.count("torch"), 2, "시작 소지품")
	assert_eq(pc.inventory.count("ration"), 3)
	assert_eq(pc.race_name(), "인간")
	pc.pool.set_context("dungeon", true)
	pc.pool.set_current("hunger", 30.0)
	var ctx := ItemUser.use(reg, pc, "ration", rng)
	assert_true(ctx.success)
	assert_near(pc.pool.get_current("hunger"), 70.0)
	assert_eq(pc.inventory.count("ration"), 2)
	pc.pool.fill("hunger")
	assert_false(ItemUser.use(reg, pc, "ration", rng).success, "배부르면 먹지 않는다")
	assert_eq(pc.inventory.count("ration"), 2, "소모되지 않는다")
	assert_true(ItemUser.use(reg, pc, "torch", rng).success)
	assert_true(pc.light.is_lit())
	assert_eq(pc.inventory.count("torch"), 1)
	assert_false(ItemUser.use(reg, pc, "torch", rng).success, "이미 타고 있으면 켜지 않는다")
	assert_eq(pc.inventory.count("torch"), 1)
	var went_out := [false]
	pc.light.went_out.connect(func(_id: String) -> void: went_out[0] = true)
	pc.advance_hours(72.0)
	assert_false(pc.light.is_lit(), "사흘이면 꺼진다")
	assert_true(went_out[0])
	assert_true(ItemUser.use(reg, pc, "no_such_item", rng) == null)


## 허기·피로 단계 알림 신호(condition_notice) — 단계가 나빠질 때만, 문구 키가 모두 있다.
func test_condition_notices_on_worse_stages_only() -> void:
	var a := _actor()
	var got: Array[String] = []
	a.condition_notice.connect(func(id: String) -> void: got.append(id))
	a.pool.set_context("dungeon", true)
	var decay := _b("hunger.decay_per_hour")
	a.advance_hours(51.0 / decay)  # 100 → 49: 출출
	a.advance_hours(20.0 / decay)  # 29: 허기
	a.advance_hours(10.0 / decay)  # 19: 주림
	a.advance_hours(10.0 / decay)  # 9: 굶주림
	assert_eq(got, ["peckish", "hungry", "famished", "starving"], "허기 단계가 나빠질 때마다")
	a.pool.modify("hunger", 60.0, "food")
	assert_eq(got.size(), 4, "먹어서 나아질 땐 알리지 않는다")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10})
	var fat: Array[String] = []
	pc.condition_notice.connect(func(id: String) -> void: fat.append(id))
	pc.fatigue.set_value(35.0)
	pc.fatigue.set_value(40.0)
	pc.fatigue.set_value(55.0)
	pc.fatigue.set_value(90.0)
	pc.fatigue.set_value(20.0)
	assert_eq(fat, ["tired", "weary", "collapse"], "피로 단계가 오를 때만(같은 단계 안·내려갈 땐 없음)")
	for id: String in ["peckish", "hungry", "famished", "starving", "starvation", "tired", "weary", "spent", "collapse"]:
		assert_true(Strings.t("condition." + id, {"who": "가"}) != "condition." + id, "알림 문구: " + id)
