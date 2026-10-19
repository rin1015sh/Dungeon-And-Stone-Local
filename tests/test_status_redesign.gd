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


func _battle(party: int = 2, foes: Array = ["goblin"]) -> Battle:
	var reg := ContentRegistries.new()
	var b := Battle.new(db, reg.effects, reg.ai_conditions, Rng.new(7))
	for i in party:
		var pc := PlayerCharacter.create(db, "human", "warrior", "시험%d" % i, {"str": 10, "agi": 10, "p_res": 5})
		b.add(pc, Combatant.SIDE_PARTY, "front")
	for id: Variant in foes:
		b.add(Monster.create(db, str(id)), Combatant.SIDE_ENEMY, "front")
	return b


func test_consume_status_heals_by_stacks() -> void:
	var reg := ContentRegistries.new()
	var me := _a()
	var foe := _a()
	me.pool.modify("hp", -100.0, "test")
	for i in 3:
		foe.statuses.apply("bleeding")
	var ctx := EffectContext.new(db, me, foe, Rng.new(1))
	ctx.registry = reg.effects
	reg.effects.apply_all(ctx, [{"type": "consume_status", "status": "bleeding", "heal_ratio_per_stack": 0.05}])
	assert_false(foe.statuses.has("bleeding"), "출혈을 터뜨려 없앴다")
	assert_near(me.pool.get_current("hp"), 100.0 + 200.0 * 0.05 * 3.0, 0.5, "중첩 3 × 5% 회복")


func test_execute_power_below_hp_ratio() -> void:
	var atk := _a()
	var low := _a()
	low.pool.modify("hp", -150.0, "test")
	var fx := {"scaling": "phys", "power": 1.0, "power_if_hp_below": {"ratio": 0.3, "mult": 2.0}}
	var rolls := {"hit": 0.0, "crit": 1.0, "var": 0.5, "lethal": 1.0}
	var full := DamageCalc.resolve(db, atk, _a(), fx, rolls)
	var hurt := DamageCalc.resolve(db, atk, low, fx, rolls)
	assert_near(float(hurt["raw"]), float(full["raw"]) * 2.0, 0.01, "생명력 30% 이하면 위력 ×2")


func test_cover_redirects_single_attack() -> void:
	var b := _battle(2)
	var p := b.side_units(Combatant.SIDE_PARTY)
	var foe := b.side_units(Combatant.SIDE_ENEMY)[0]
	var ctx := EffectContext.new(db, p[0].actor, p[1].actor, Rng.new(1))
	ContentRegistries.new().effects.apply_all(ctx, [{"type": "cover", "duration": 2}])
	var targets: Array[Combatant] = [p[1]]
	BattleRules.apply_cover(b, foe, "enemy_single", targets)
	assert_eq(targets[0], p[0], "지키는 사람이 대신 맞는다")


func test_on_kill_passive_and_gauge_event() -> void:
	var killer := _a()
	killer.add_passive({"id": "t_kill", "on_kill": [{"type": "restore_resource", "resource": "hp", "amount": 30}]})
	killer.pool.modify("hp", -50.0, "test")
	var victim := _a()
	victim.pool.modify("hp", -199.0, "test")
	var reg := ContentRegistries.new()
	var ctx := EffectContext.new(db, killer, victim, Rng.new(1))
	ctx.registry = reg.effects
	reg.effects.apply_all(ctx, [{"type": "damage", "scaling": "phys", "power": 1.0, "accuracy": 1000}])
	assert_true(victim.dead)
	assert_near(killer.pool.get_current("hp"), 180.0, 0.5, "쓰러뜨리면 on_kill 회복")
	var g := EffectContext.new(db, killer, victim, Rng.new(1))
	reg.effects.apply_all(g, [{"type": "gauge", "amount": 30, "to": "self"}])
	assert_eq(g.events[0]["target"], killer, "gauge to self")
