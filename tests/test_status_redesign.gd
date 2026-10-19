extends TestCase
## 상태이상 재기획(2026-10-19, docs/plans/status_redesign.md): 행동 방해 뒤 면역 · 출혈(행동·회복) · 마비 확률 · 표식 · 끌어들이기 · 저항 스탯.


func _a(stats: Dictionary = {}) -> Actor:
	var base := {"str": 10, "agi": 20, "p_res": 0, "m_res": 0, "int": 0}
	base.merge(stats, true)
	return Monster.new(db, base, 1, ["hp"], {"hp": 200})


func test_control_gives_one_turn_immunity_after() -> void:
	var a := _a()
	assert_true(a.statuses.apply("stun", 1.0))
	a.statuses.tick_turns()  # 기절 차례가 지나 풀린다
	assert_false(a.statuses.has("stun"))
	assert_false(a.statuses.apply("stun"), "풀린 뒤 1차례는 같은 상태에 걸리지 않는다")
	a.statuses.tick_turns()
	assert_true(a.statuses.apply("stun"), "그다음 차례엔 다시 걸린다")


func test_bleeding_hurts_on_action_and_heal_stops_a_stack() -> void:
	var a := _a()
	a.statuses.apply("bleeding")
	a.statuses.apply("bleeding")
	var hp := a.pool.get_current("hp")
	a.statuses.on_acted()
	assert_near(a.pool.get_current("hp"), hp - 2.0, 0.001, "행동할 때마다 중첩당 1")
	a.statuses.on_healed()
	assert_eq(a.statuses.stacks("bleeding"), 1, "회복을 받으면 1중첩 멎는다")
	for i in 5:
		a.statuses.apply("bleeding")
	assert_eq(a.statuses.stacks("bleeding"), 3, "출혈 최대 3중첩")


func test_rot_halves_healing_and_burn_softens_armor() -> void:
	var a := _a({"p_res": 20})
	a.statuses.apply("rot")
	assert_near(a.statuses.heal_mult(), 0.5, 0.001, "부패: 받는 회복 절반")
	a.statuses.apply("burn")
	assert_near(a.stats.get_value("p_res"), 17.0, 0.001, "화상: 물리내성 −15%")


func test_mark_raises_hit_and_crit_against_target() -> void:
	var atk := _a()
	var tgt := _a()
	var before := DamageCalc.hit_chance(db, atk, tgt, false, 50.0)
	var crit0 := DamageCalc.crit_chance(db, atk)
	tgt.statuses.apply("marked")
	assert_near(DamageCalc.hit_chance(db, atk, tgt, false, 50.0), before + 0.15, 0.001, "표식: 명중 +15%p")
	assert_near(tgt.statuses.sum_key("crit_taken"), 0.1, 0.001, "표식: 치명 +10%p")
	assert_true(crit0 > 0.0)


func test_resist_stats_one_per_status() -> void:
	var want := {"stun": "p_res", "paralysis": "m_res", "snare": "str", "fear": "int", "bleeding": "p_res",
		"poison": "resist_poison", "frost": "resist_cold", "blind": "sight", "curse": "m_res", "daze": "int"}
	for id: String in want:
		var stats := JsonUtil.get_array(JsonUtil.get_dict(db.get_entry("statuses", id), "resist"), "stats")
		assert_eq(stats, [want[id]], "%s 저항 = %s" % [id, want[id]])


func test_merged_statuses_are_gone() -> void:
	for id in ["slow", "goblin_paralysis", "owl_hoot", "smoke_screen", "wolf_pack", "orc_war_cry", "ice_armor", "mud_merged"]:
		assert_false(db.has_entry("statuses", id), "%s는 공용 상태로 합쳤다" % id)
