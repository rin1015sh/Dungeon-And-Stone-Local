extends TestCase
## G2 1층 필드 10종(docs/PROMPT_FLOOR1_V2.md §1·§6): 공식 · 패시브 · 은신 · 증원 · 반격 · 흡혈 · AI 순환 · 변이종 출현 · 필드 은신 · 공유 이능 정수.

const HIT := {"hit": 0.0, "crit": 1.0, "var": 0.5, "lethal": 1.0}


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 12, "p_res": 8, "m_res": 5, "int": 8})
	pc.set_level(3)
	return pc


func _battle(monsters: Array, pc: PlayerCharacter = null, seed_value: int = 3, party_first: bool = true) -> Battle:
	var party: Array[Actor] = [pc if pc != null else _pc()]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, monsters, party_first)


## 공격자 src가 tgt를 effect로 한 번 친다(명중 보장 굴림이 아니라 실제 rng). 효과 문맥을 돌려준다.
func _hit(src: Actor, tgt: Actor, effect: Dictionary, seed_value: int) -> EffectContext:
	var reg := ContentRegistries.new()
	var ctx := EffectContext.new(db, src, tgt, Rng.new(seed_value))
	ctx.registry = reg.effects
	reg.effects.apply_all(ctx, [effect])
	return ctx


func test_formula_matches_spec() -> void:
	var a := Actor.new(db, {"str": 10, "agi": 10})
	var t := Actor.new(db, {"agi": 10})
	assert_near(DamageCalc.hit_chance(db, a, t, false), 0.95, 0.0001, "같은 민첩 → 기본 명중 95")
	var slow := Actor.new(db, {"agi": 0})
	assert_near(DamageCalc.hit_chance(db, slow, t, false), 0.95 * 0.95, 0.0001, "민첩 차 −10 → ×0.95")
	assert_near(DamageCalc.attack_power(db, a, {"scaling": "phys"}), 2.0 + 20.0, 0.0001, "근력×2 + 맨손")
	var gob := Monster.create(db, "goblin")
	assert_near(DamageCalc.attack_power(db, gob, {"scaling": "phys"}), 6.0 * 2.0 + 5.0, 0.0001, "몬스터 natural_weapon 5")
	t.statuses.apply("blind")
	assert_true(DamageCalc.hit_chance(db, t, a, false) < 0.7, "실명 → 명중률 −30")


func test_on_hit_passive_and_filter() -> void:
	var gob := Monster.create(db, "goblin")
	var got := false
	for s in 40:
		var t := Actor.new(db, {"p_res": 0, "agi": 0})
		_hit(gob, t, {"type": "damage", "power": 0.1, "damage_type": "weapon"}, s)
		got = got or t.statuses.has("goblin_paralysis")
	assert_true(got, "고블린 근접 적중 → 가끔 마비독")
	var archer := Monster.create(db, "goblin_archer")
	var melee_poison := false
	for s in 40:
		var t := Actor.new(db, {"agi": 0})
		_hit(archer, t, {"type": "damage", "power": 0.1, "damage_type": "pierce", "ranged": false}, s)
		melee_poison = melee_poison or t.statuses.has("poison")
	assert_false(melee_poison, "독화살 패시브는 원거리 공격에만")


func test_status_immune_reflect_counter_drain() -> void:
	var elder := Monster.create(db, "elder_ghoul")
	var ctx := _hit(Actor.new(db), elder, {"type": "apply_status", "status": "bleeding"}, 1)
	assert_false(elder.statuses.has("bleeding"), "썩은 거구: 출혈 면역")
	assert_true(ctx.messages.any(func(m: Dictionary) -> bool: return m["key"] == "effect.status_immune"))
	var giant := Monster.create(db, "giant_blade_wolf")
	var hero := Actor.new(db, {"str": 20, "agi": 30})
	var hp := hero.pool.get_current("hp")
	_hit(hero, giant, {"type": "damage", "power": 1.0, "damage_type": "slash", "accuracy": 200}, 2)
	assert_true(hero.pool.get_current("hp") < hp, "두꺼운 칼날털: 근접 공격자에게 반사")
	var sword := Monster.create(db, "goblin_swordsman")
	sword.statuses.apply("counter_stance")
	var hp2 := hero.pool.get_current("hp")
	var hit := false
	for s in 10:
		_hit(hero, sword, {"type": "damage", "power": 0.2, "damage_type": "slash", "accuracy": 200}, s)
		hit = hit or hero.pool.get_current("hp") < hp2
	assert_true(hit, "막고 찌르기: 근접 공격을 받으면 되찌른다")
	var blood := Monster.create(db, "blood_blade_wolf")
	blood.pool.set_current("hp", 10.0)
	var prey := Actor.new(db, {"agi": 0})
	prey.statuses.apply("bleeding")
	_hit(blood, prey, {"type": "damage", "power": 1.0, "damage_type": "pierce", "accuracy": 200,
		"drain_if_status": {"status": "bleeding", "ratio": 0.4}}, 3)
	assert_true(blood.pool.get_current("hp") > 10.0, "피 핥기: 출혈 대상이면 흡혈")


func test_hidden_target_rules() -> void:
	var b := _battle(["goblin_archer", "goblin"])
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var archer := b.side_units(Combatant.SIDE_ENEMY)[0]
	archer.actor.statuses.apply("hidden")
	assert_false(BattleRules.is_targetable(b, me, archer), "은신한 적은 고를 수 없다")
	assert_eq(ActionCheck.reason(b, me, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": archer}), "combat.reason_hidden")
	var b2 := _battle(["blade_wolf"])
	var wolf := b2.side_units(Combatant.SIDE_ENEMY)[0]
	var me2 := b2.side_units(Combatant.SIDE_PARTY)[0]
	me2.actor.statuses.apply("hidden")
	assert_true(BattleRules.is_targetable(b2, wolf, me2), "추적 후각: 은신도 노린다")


func test_howl_summons_and_snare_blocks_flee() -> void:
	var b := _battle(["goblin"], null, 4, false)
	var gob := b.side_units(Combatant.SIDE_ENEMY)[0]
	var before := b.units.size()
	for s in 20:
		BattleRules.summon(b, gob, {"monster": "goblin"})
	assert_true(b.units.size() > before, "증원")
	assert_true(b.side_units(Combatant.SIDE_ENEMY).size() <= int(db.bal("combat.max_side_units")), "한 진영 최대 수")
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	me.actor.statuses.apply("snare")
	assert_eq(b.flee_chance(me), 0.0, "속박이면 도주 불가")


func test_ghoul_cycle_and_first_strike() -> void:
	var b := _battle(["ghoul"], null, 5, false)
	var g := b.side_units(Combatant.SIDE_ENEMY)[0]
	var seq: Array = []
	for i in 3:
		g.acted = i
		seq.append(b.ai_action(g)["skill"])
	assert_eq(seq, ["ghoul_claw", "ghoul_claw", "ghoul_pounce"], "구울: 할퀴기 → 할퀴기 → 달려들기")
	assert_true(g.gauge >= 30.0, "네 발 짐승: 첫 차례 선공 게이지")


func test_wolf_pack_ai() -> void:
	var b := _battle(["blade_wolf", "blade_wolf"], null, 6, false)
	var w := b.side_units(Combatant.SIDE_ENEMY)[0]
	assert_eq(b.ai_action(w)["skill"], "wolf_pack_hunt", "늑대 둘 이상, 버프 없음 → 무리 사냥")
	w.actor.statuses.apply("wolf_pack")
	assert_eq(b.ai_action(w)["skill"], "wolf_blade_graze", "출혈 없는 대상 → 칼날 스치기")


func test_variants_spawn_outer_after_day3() -> void:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(9))
	# 1층 데이터엔 변이종이 없다(사용자 결정 2026-10-12) — 규칙(variants)은 그대로 살아 있는지 가짜 지역으로 확인한다.
	var region := {"id": "f1_north", "zone": "north", "monsters": ["goblin"],
		"variants": {"monsters": ["goblin_swordsman", "goblin_archer"], "min_day": 3, "outer_ratio": 0.5, "chance": 0.2}}
	var early := FieldMonsters.new(db, map, def, Rng.new(2))
	var late := FieldMonsters.new(db, map, def, Rng.new(2))
	late.update(Vector2(-50, -50), 0.0, 24.0 * 3, false)  # 4일 차
	var early_ids := {}
	var late_ids := {}
	for i in 200:
		var g1 := early.spawn_group(region, Vector2i(-99, -99))
		var g2 := late.spawn_group(region, Vector2i(-99, -99))
		for id in (g1.monster_ids if g1 != null else []):
			early_ids[id] = true
		for id in (g2.monster_ids if g2 != null else []):
			late_ids[id] = true
	assert_eq(early_ids.keys(), ["goblin"], "1일 차엔 원종만")
	assert_true(late_ids.has("goblin_swordsman") or late_ids.has("goblin_archer"), "3일 차 이후 외곽에 변이종")


func test_field_stealth_from_essence_skill() -> void:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(3))
	var pc := _pc()
	var s := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(4), reg.effects)
	s.monsters_enabled = false
	s.start()
	assert_eq(FieldStealth.of(s), 0.0)
	pc.essences.absorb(pc, {"essence": "goblin_archer", "color": "green", "stats": {}})
	assert_near(FieldStealth.of(s), 0.7, 0.0001, "도둑걸음: 서 있으면 −70%")
	s.last_move_hours = s.clock.total_hours
	assert_near(FieldStealth.of(s), 0.3, 0.0001, "움직이는 중 −30%")


func test_shared_skill_essences_conflict() -> void:
	var pairs := [[["ghoul", "red"], ["elder_ghoul", "gray"]], [["blade_wolf", "red"], ["giant_blade_wolf", "red"]],
		[["blade_wolf", "yellow"], ["blood_blade_wolf", "yellow"]], [["gnome", "green"], ["corrupted_gnome", "green"]]]
	for pair: Array in pairs:
		var pc := _pc()
		var a: Array = pair[0]
		var b: Array = pair[1]
		assert_eq(pc.essences.absorb(pc, {"essence": a[0], "color": a[1], "stats": {}}), "")
		assert_eq(pc.essences.absorb(pc, {"essence": b[0], "color": b[1], "stats": {}}), "essence.reason_duplicate",
			"%s %s ↔ %s %s 공유 이능" % [a[0], a[1], b[0], b[1]])
	var ok := _pc()
	assert_eq(ok.essences.absorb(ok, {"essence": "ghoul", "color": "red", "stats": {}}), "")
	assert_eq(ok.essences.absorb(ok, {"essence": "elder_ghoul", "color": "red", "stats": {}}), "", "다른 색(짓누르기)은 괜찮다")
	assert_true(Lineage.shared_skills(db, "ghoul").has("ghoul_claw"))


func test_essence_passive_works_for_player() -> void:
	var pc := _pc()
	pc.essences.absorb(pc, {"essence": "goblin", "color": "red", "stats": {}})
	assert_true(pc.passives.any(func(p: Dictionary) -> bool: return p["id"] == "goblin_paralytic_blade"), "정수 패시브가 붙는다")
	var got := false
	for s in 60:
		var t := Actor.new(db, {"agi": 0})
		_hit(pc, t, {"type": "damage", "power": 0.1, "damage_type": "weapon", "accuracy": 200}, s)
		got = got or t.statuses.has("goblin_paralysis")
	assert_true(got, "정수판 마비독 20%")
	pc.essences.remove(pc, 0)
	assert_true(pc.passives.is_empty(), "제거하면 패시브도 사라진다")


func test_flee_matches_spec() -> void:
	var b := _battle(["goblin"])
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var gob := b.side_units(Combatant.SIDE_ENEMY)[0]
	var diff := me.actor.stats.get_value("agi") - gob.actor.stats.get_value("agi")
	assert_near(b.flee_chance(me), 0.5 + diff * 0.02, 0.0001, "50% + 평균 민첩 차×2%p")
	me.actor.stats.set_base("agi", 200.0)
	assert_near(b.flee_chance(me), 0.9, 0.0001, "최대 90%")
	var guardian := Monster.create(db, "goblin")
	guardian.def = guardian.def.duplicate()
	guardian.def["rank"] = "guardian"
	var reg := ContentRegistries.new()
	var b2 := Battle.new(db, reg.effects, reg.ai_conditions, Rng.new(1))
	var me2 := b2.add(_pc(), Combatant.SIDE_PARTY)
	b2.add(guardian, Combatant.SIDE_ENEMY)
	assert_eq(b2.flee_chance(me2), 0.0, "수호자·계층군주전은 도주 불가")
	assert_eq(ActionCheck.reason(b2, me2, {"kind": "flee"}), "combat.reason_no_flee", "도주 불가면 차례를 쓰지 않는다")
