extends TestCase
## G4 신규 상태이상 12종 · 저항 · 저체온증 · 예고 공격(찍힌 대상) — docs/PROMPT_FLOOR1_V2.md §4.


func _a(stats: Dictionary = {}) -> Actor:
	var a := Actor.new(db, stats)
	a.pool.fill_all()
	return a


func _apply(src: Actor, tgt: Actor, status_id: String, seed_value: int) -> bool:
	var ctx := EffectContext.new(db, src, tgt, Rng.new(seed_value))
	return ContentRegistries.new().effects.apply_all(ctx, [{"type": "apply_status", "status": status_id}]) and tgt.statuses.has(status_id)


func _battle(n_party: int = 1) -> Battle:
	var reg := ContentRegistries.new()
	var party: Array[Actor] = []
	for i in n_party:
		party.append(PlayerCharacter.create(db, "human", "warrior", "시험%d" % i, {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10}))
	return Battle.from_encounter(db, reg, Rng.new(4), party, ["blater"])


func test_skip_turn_family() -> void:
	for id in ["stun", "petrify", "suppress", "frozen"]:
		var a := _a()
		a.statuses.apply(id)
		assert_true(a.statuses.has_flag("skip_turn"), "%s → 행동 불가" % id)
	var par := _a()
	par.statuses.apply("paralysis")
	assert_true(par.statuses.has_flag("may_skip_turn") and not par.statuses.has_flag("skip_turn"), "마비 = 확률로 행동 실패(기절과 다름)")
	var p := _a({"p_res": 10})
	p.statuses.apply("petrify")
	assert_near(p.stats.get_value("p_res"), 20.0, 0.001, "석화: 물리내성 +100%")
	var strong := _a({"m_res": 25})
	assert_false(strong.statuses.apply("suppress"), "항마력 25 이상 진압 면역")


func test_resist_by_stats() -> void:
	var weak := 0
	var tough := 0
	for i in 200:
		if _apply(_a(), _a({"p_res": 0}), "stun", i):
			weak += 1
		if _apply(_a(), _a({"p_res": 60}), "stun", i):
			tough += 1
	assert_eq(weak, 200, "저항 스탯 0이면 항상 걸린다")
	assert_true(tough < 120 and tough > 50, "기절 저항 = 물리내성 60 → 최대 저항 60%% (%d/200 걸림)" % tough)
	var self_ok := _a({"int": 30, "m_res": 30})
	var ctx := EffectContext.new(db, self_ok, self_ok, Rng.new(1))
	ContentRegistries.new().effects.apply_all(ctx, [{"type": "apply_status", "status": "stun"}])
	assert_true(self_ok.statuses.has("stun"), "자기가 건 상태는 저항하지 않는다")


func test_suppress_breaks_on_damage_frozen_on_fire() -> void:
	var a := _a()
	a.statuses.apply("suppress")
	a.statuses.on_damaged("slash")
	assert_false(a.statuses.has("suppress"), "진압: 피해를 받으면 풀림")
	a.statuses.apply("frozen")
	a.statuses.on_damaged("slash")
	assert_true(a.statuses.has("frozen"), "빙결은 베기로 안 풀림")
	a.statuses.on_damaged("fire")
	assert_false(a.statuses.has("frozen"), "화염에 녹는다")


func test_frost_stacks_into_frozen_and_slow() -> void:
	var a := _a({"agi": 20})
	a.statuses.apply("frost")
	a.statuses.apply("frost")
	assert_near(a.stats.get_value("agi"), 20.0 * 0.8, 0.001, "서리 2중첩 민첩 −20%")
	a.statuses.apply("frost")
	assert_false(a.statuses.has("frost"), "3중첩이면 서리는 사라지고")
	assert_true(a.statuses.has("frozen"), "빙결로 바뀐다")
	assert_near(a.stats.get_value("agi"), 20.0, 0.001)


func test_heal_block_and_seal_and_confusion() -> void:
	var a := _a()
	a.pool.set_current("hp", 10.0)
	a.statuses.apply("heal_block")
	var ctx := EffectContext.new(db, a, a, Rng.new(1))
	ContentRegistries.new().effects.apply_all(ctx, [{"type": "restore_resource", "resource": "hp", "amount": 40}])
	assert_near(a.pool.get_current("hp"), 30.0, 0.001, "원한: 치유 절반")
	var b := _battle(2)
	var boss := b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var bm := boss.actor as Monster
	bm.def = bm.def.duplicate()
	bm.def["status_immune_all"] = false  # 봉인 규칙만 본다(보스 등급 면역 UI25는 test_status_immunity)
	BossHooks.apply_effects(b, me, boss, [{"type": "seal_skill", "rounds": 2}])
	assert_true(boss.actor.statuses.has("seal"))
	var sealed := boss.cooldowns.keys().filter(func(k: String) -> bool: return k in ["blater_cursed_slash", "blater_oath", "blater_death_sentence"])
	assert_eq(sealed.size(), 1, "봉인: 액티브 하나가 쿨타임으로 막힌다")
	me.actor.statuses.apply("confusion")
	var sides := {}
	for i in 80:
		var m := BattleTargets.misdirect(b, me, "enemy_single")
		if not m.is_empty():
			sides[(m["target"] as Combatant).side] = true
			assert_true(m["target"] != me)
	assert_eq(sides.size(), 2, "혼란: 아군·적 아무나")


func test_hypothermia_formula_and_marks() -> void:
	var cold := _a({"agi": 40, "resist_cold": 0})
	cold.statuses.apply("hypothermia")
	assert_near(cold.stats.get_value("agi"), 28.0, 0.001, "냉기 내성 0 → 민첩 −30%(CTB, GC2)")
	var warm := _a({"agi": 40, "resist_cold": 25})
	warm.statuses.apply("hypothermia")
	assert_near(warm.stats.get_value("agi"), 38.0, 0.001, "냉기 내성 25 → −5%")
	var hit := {"hit": 0.0, "crit": 1.0, "var": 0.5, "lethal": 1.0}
	var atk := _a({"int": 10})
	var fx := {"scaling": "magic", "base": 20, "power": 1.0, "damage_type": "cold", "accuracy": 1000}
	var plain := _a({"m_res": 0})
	var base_dmg := float(DamageCalc.resolve(db, atk, plain, fx, hit)["amount"])
	var c0 := _a({"m_res": 0, "resist_cold": 0})
	c0.statuses.apply("hypothermia")
	var c20 := _a({"m_res": 0, "resist_cold": 20})
	c20.statuses.apply("hypothermia")
	assert_near(float(DamageCalc.resolve(db, atk, c0, fx, hit)["amount"]), base_dmg * 2.0, 1.0, "받는 냉기 피해 ×2")
	assert_near(float(DamageCalc.resolve(db, atk, c20, fx, hit)["amount"]), base_dmg * 1.5 * 0.8, 1.0, "냉기 내성 20 이상 ×1.5, 내성 20 → −20%(GC1)")
	var g := _a()
	assert_true(g.statuses.apply("grudge_mark") and g.statuses.apply("sacrifice_mark"), "원한의 징표·제물")


func test_telegraph_hits_marked_target() -> void:
	var b := _battle(3)
	var boss := b.side_units(Combatant.SIDE_ENEMY)[0]
	var party := b.side_units(Combatant.SIDE_PARTY)
	var mark := party[2]
	BossHooks.apply_effects(b, boss, mark, JsonUtil.get_array(db.get_entry("skills", "blater_death_sentence"), "effects"))
	assert_true(mark.actor.statuses.has("telegraphed"), "찍힌 대상에 [예고]")
	var hp := []
	for u in party:
		hp.append(u.actor.pool.get_current("hp"))
	BattleDelayed.tick(b, boss)
	BattleDelayed.tick(b, boss)
	assert_false(mark.actor.statuses.has("telegraphed"))
	assert_true(mark.actor.pool.get_current("hp") < float(hp[2]), "찍힌 대상이 맞는다")
	assert_near(party[0].actor.pool.get_current("hp"), float(hp[0]), 0.001, "다른 사람은 무사")
