extends TestCase
## G5 핏빛성채(docs/PROMPT_FLOOR1_V2.md §9): 약점·오라·재생·타입·영혼 베기·뼈대 형태·수호자 패턴·벤시·여신의 눈물·히든 피스.

const HIT := {"hit": 0.0, "crit": 1.0, "var": 0.5, "lethal": 1.0}


func _pc(level: int = 4) -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(level)
	pc.pool.fill_all()
	return pc


func _battle(monsters: Array, n_party: int = 1, seed_value: int = 3) -> Battle:
	var party: Array[Actor] = []
	for i in n_party:
		party.append(_pc())
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, monsters)


func _ctx_hit(src: Actor, tgt: Actor, fx: Array, seed_value: int = 1, aim_weak: bool = false) -> EffectContext:
	var reg := ContentRegistries.new()
	var ctx := EffectContext.new(db, src, tgt, Rng.new(seed_value))
	ctx.registry = reg.effects
	ctx.info = {"aim_weak": aim_weak}
	reg.effects.apply_all(ctx, fx)
	return ctx


func test_skeleton_core_weak_point() -> void:
	var atk := Actor.new(db, {"str": 10})
	var sk := Monster.create(db, "skeleton_archer")
	var plain := Actor.new(db, {"p_res": sk.stats.get_value("p_res")})  # 같은 방어의 보통 대상
	var fx := {"scaling": "phys", "power": 1.0, "damage_type": "slash", "accuracy": 1000}
	var base := float(DamageCalc.resolve(db, atk, plain, fx, HIT)["amount"])
	assert_near(float(DamageCalc.resolve(db, atk, sk, fx, HIT)["amount"]), base * 0.6, 1.0, "갈비뼈 속 핵: 베기 −40%")
	assert_near(float(DamageCalc.resolve(db, atk, sk, fx, HIT, true)["amount"]), base * 1.5, 1.0, "핵을 노려 맞히면 감소 무시 ×1.5")
	var blunt := fx.duplicate()
	blunt["damage_type"] = "blunt"
	assert_near(float(DamageCalc.resolve(db, atk, sk, blunt, HIT)["amount"]), base, 1.0, "둔기는 정상")
	assert_false(sk.def.has("magic_stone_chance"), "마석은 다른 몬스터처럼 늘 떨어진다(2026-10-21 — 처치 드롭 = 마석 100% + 정수)")


func test_banshee_immune_and_grudge_mark() -> void:
	var b := Monster.create(db, "banshee")
	var a1 := _pc()
	var a2 := _pc()
	var hp := b.pool.get_current("hp")
	_ctx_hit(a1, b, [{"type": "damage", "power": 1.0, "damage_type": "weapon", "accuracy": 1000}])
	assert_near(b.pool.get_current("hp"), hp, 0.001, "물리 면역")
	assert_true(a1.statuses.has("grudge_mark"), "먼저 공격한 탐험가에게 원한의 징표")
	_ctx_hit(a2, b, [{"type": "damage", "power": 1.0, "damage_type": "weapon", "accuracy": 1000}])
	assert_false(a2.statuses.has("grudge_mark"), "두 번째부터는 아니다")
	var holy := _ctx_hit(a2, b, [{"type": "damage", "scaling": "magic", "base": 20, "power": 1.0, "damage_type": "holy", "accuracy": 1000}])
	assert_true(b.pool.get_current("hp") < hp, "신성은 통한다")
	assert_false(holy.messages.is_empty())
	var map := ContentRegistries.new().generator("crystal_cave").generate(db, db.get_entry("floors", "f1_crystal_cave"), Rng.new(3))
	var steer := MonsterSteering.new(db, map, Rng.new(1), [])
	var g := FieldMonsters.Group.new()
	g.monster_ids.append("banshee")
	var near := map.entry
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if map.is_walkable(map.entry + d):
			near = map.entry + d
	g.place(near)
	g.facing = Vector2(map.entry - near)
	assert_false(steer.mind.can_see(g, Kinematics.center_of(map.entry)), "벤시는 먼저 덤비지 않는다")
	steer.mind.marks = ["grudge_mark"]
	assert_true(steer.mind.can_see(g, Kinematics.center_of(map.entry)), "원한의 징표가 있으면 알아채고 쫓는다")


func test_deathfiend_preservation_regen() -> void:
	var b := _battle(["deathfiend"])
	var df := b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	Passives.try_status(db, null, null, df.actor, "bleeding", 5.0)  # 저항 굴림 없이(육체보존의 지속 상한만 본다)
	assert_true(df.actor.statuses.has("bleeding"))
	assert_true(float((df.actor.statuses.to_dict()["bleeding"] as Dictionary)["remaining"]) <= 1.0, "육체보존: 출혈 1라운드")
	var half := roundf(df.actor.pool.get_max("hp") * 0.5)
	df.actor.pool.set_current("hp", half)
	BattlePassives.turn_end(b, df)
	assert_near(df.actor.pool.get_current("hp"), half + df.actor.pool.get_max("hp") * 0.04, 0.6, "라운드 끝 4% 재생")
	df.actor.statuses.apply("regen_stopped")
	var hp := df.actor.pool.get_current("hp")
	BattlePassives.turn_end(b, df)
	assert_near(df.actor.pool.get_current("hp"), hp, 0.001, "재생 정지")


func test_auras_and_start_summons() -> void:
	var b := _battle(["deadman_commander", "soldier_deadman"])
	var soldier := b.side_units(Combatant.SIDE_ENEMY)[1]
	var sol_str := JsonUtil.get_float(JsonUtil.get_dict(db.get_entry("monsters", "soldier_deadman"), "stats"), "str")
	assert_near(soldier.actor.stats.get_value("str"), sol_str * 1.15, 0.01, "썩은 지휘: 데드맨 계열 근력 +15%")
	var b2 := _battle(["ghoul_lord"])
	var foes := b2.side_units(Combatant.SIDE_ENEMY)
	assert_eq(foes.size(), 3, "구울로드: 엘더 구울 2체 동반")
	var eg_str := JsonUtil.get_float(JsonUtil.get_dict(db.get_entry("monsters", "elder_ghoul"), "stats"), "str")
	assert_near(foes[1].actor.stats.get_value("str"), eg_str * 1.15, 0.01, "아군 구울 계열 근력 +15%")
	foes[0].actor.pool.set_current("hp", 0.0)
	foes[0].actor.dead = true
	BattlePassives.refresh_auras(b2)
	assert_near(foes[1].actor.stats.get_value("str"), eg_str, 0.01, "주인이 쓰러지면 오라가 사라진다")


func test_chimera_volley_pushback_march() -> void:
	var b := _battle(["chimera_wolf"])
	var cw := b.side_units(Combatant.SIDE_ENEMY)[0]
	var fx := BattlePassives.skill_effects(b, cw, Battle.BASIC_ATTACK, db.get_entry("skills", Battle.BASIC_ATTACK))
	assert_eq(fx.size(), 2, "여러 개의 머리: 평타 2회")
	var b2 := _battle(["skeleton_archer", "skeleton_archer", "skeleton_archer"])
	var ar := b2.side_units(Combatant.SIDE_ENEMY)[0]
	assert_eq(BattlePassives.skill_effects(b2, ar, "skeleton_volley", db.get_entry("skills", "skeleton_volley")).size(), 3, "일제 사격: 아처 수만큼")
	var b3 := _battle(["soldier_deadman"])
	var me := b3.side_units(Combatant.SIDE_PARTY)[0]
	var sol := b3.side_units(Combatant.SIDE_ENEMY)[0]
	var g := me.gauge
	BossHooks.apply_effects(b3, sol, me, [{"type": "push_back", "amount": 60}])
	assert_near(me.gauge, g - 60.0, 0.001, "방패 밀치기: 다음 차례가 늦어진다")
	sol.actor.statuses.apply("march_order")
	_ctx_hit(sol.actor, me.actor, [{"type": "damage", "power": 1.0, "damage_type": "weapon"}])
	assert_false(sol.actor.statuses.has("march_order"), "진군 명령은 다음 공격 한 번")


func test_bone_knight_type_and_soul_slash() -> void:
	var types := {}
	for s in 30:
		var b := _battle(["bone_knight"], 1, s)
		var bk := b.side_units(Combatant.SIDE_ENEMY)[0].actor as Monster
		types[str(bk.get_meta("monster_type"))] = true
		assert_eq(bk.skills.size(), 2, "공통 뼈 베기 + 타입 스킬 하나")
	assert_eq(types.size(), 3, "갈망·슬픔·증오")
	var pc := _pc(4)
	pc.progression.exp_total = Progression.exp_for_level(db, 4) + 10
	for i in 4:
		pc.essences.absorb(pc, {"essence": ["goblin", "ghoul", "gnome", "blade_wolf"][i], "color": "red", "stats": {}})
	var bk2 := Monster.create(db, "bone_knight")
	_ctx_hit(bk2, pc, [{"type": "soul_slash", "base": 1.0, "per_level": 0.0}])
	assert_eq(pc.get_level(), 3, "영혼 베기: 레벨 하락")
	assert_eq(pc.progression.exp_total, Progression.exp_for_level(db, 3), "경험치는 이전 레벨 문턱으로")
	assert_eq(pc.essences.absorbed.size(), 3, "슬롯을 넘는 정수 하나가 소실")
	var bk3 := Monster.create(db, "bone_knight")
	bk3.pool.set_current("hp", 100.0)
	bk3.statuses.apply("poison")
	bk3.advance_turns(1.0)
	var lost := 100.0 - bk3.pool.get_current("hp")
	assert_near(lost, float(db.bal("status.poison_per_turn")) * 0.5, 0.01, "방부제: 지속 피해 절반")


func test_corpse_golem_skeleton_form() -> void:
	var b := _battle(["corpse_golem"], 2)
	var gol := b.side_units(Combatant.SIDE_ENEMY)[0]
	assert_true(gol.actor.weak_point().is_empty(), "마력핵은 처음엔 드러나지 않는다")
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	Meters.add(db, gol.actor, "golem_fire", 160.0)
	assert_true(gol.actor.statuses.has("golem_burned"), "화염 누적 150")
	var hp: float = me.actor.pool.get_current("hp")
	BossHooks.turn_end(b, gol, false)
	assert_eq(str(gol.memo["phase"]), "p2", "뼈대 형태")
	assert_true(gol.actor.statuses.has("golem_skeleton") and not gol.actor.weak_point().is_empty(), "마력핵 노출")
	assert_true(me.actor.pool.get_current("hp") < hp, "바뀔 때 살점폭발 자동 발동")
	var b2 := _battle(["corpse_golem"])
	var g2 := b2.side_units(Combatant.SIDE_ENEMY)[0]
	g2.actor.pool.set_current("hp", g2.actor.pool.get_max("hp") * 0.45)
	BossHooks.check_all(b2)
	assert_eq(str(g2.memo["phase"]), "p2", "생명력 50% 이하로도")


func test_blater_pattern() -> void:
	var b := _battle(["blater"], 2)
	var bl := b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	assert_true(me.actor.statuses.has("blater_grudge"), "원한: 적 전체 치유 절반")
	me.actor.pool.set_current("hp", 10.0)
	_ctx_hit(me.actor, me.actor, [{"type": "restore_resource", "resource": "hp", "amount": 40}])
	assert_near(me.actor.pool.get_current("hp"), 30.0, 0.001)
	assert_eq(b.flee_chance(me), 0.0, "수호자전 도주 불가")
	var seq: Array = []
	for i in 3:
		bl.acted = i
		seq.append(b.ai_action(bl)["skill"])
	assert_eq(seq, ["blater_cursed_slash", "blater_cursed_slash", "blater_death_sentence"], "검격 → 검격 → 사형 선고")
	for i in 3:
		BossHooks.turn_end(b, bl, false)
	assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), 3, "3라운드마다 망자의 맹세(병사 데드맨 2체)")
	var pat := BossHooks.pattern(b, bl)
	assert_false(pat.wants_extra_action(b, bl))
	bl.actor.pool.set_current("hp", bl.actor.pool.get_max("hp") * 0.4)
	BossHooks.check_all(b)
	assert_true(pat.wants_extra_action(b, bl), "생명력 50% 이하 라운드당 2회")
	BossHooks.apply_effects(b, bl, me, JsonUtil.get_array(db.get_entry("skills", "blater_death_sentence"), "effects"))
	assert_true(me.actor.statuses.has("telegraphed"), "사형 선고 예고")


func test_kambormir_feast_and_heart() -> void:
	var b := _battle(["kambormir"], 3)
	var k := b.side_units(Combatant.SIDE_ENEMY)[0]
	var party := b.side_units(Combatant.SIDE_PARTY)
	party[0].actor.statuses.apply("sacrifice_mark")
	party[1].actor.statuses.apply("sacrifice_mark")
	BossHooks.turn_end(b, k, false)
	assert_eq(k.actor.statuses.stacks("vamp_blood_feast"), 2, "제물 1명당 근력·민첩 +10%")
	assert_near(k.actor.stats.get_value("str"), JsonUtil.get_float(JsonUtil.get_dict((k.actor as Monster).def, "stats"), "str") * 1.2, 0.01)
	_ctx_hit(party[2].actor, k.actor, [{"type": "damage", "power": 1.0, "damage_type": "weapon", "accuracy": 1000}], 2, true)
	var ok := k.actor.statuses.has("regen_stopped")
	for s in 20:
		if ok:
			break
		_ctx_hit(party[2].actor, k.actor, [{"type": "damage", "power": 1.0, "damage_type": "weapon", "accuracy": 1000}], s + 3, true)
		ok = k.actor.statuses.has("regen_stopped")
	assert_true(ok, "심장을 맞히면 재생 정지")
	assert_eq(Progression.first_kill_exp(db, (k.actor as Monster).def), 6, "5등급 + 상위 변이종 = 6")


func test_goddess_tear_and_horn_and_hidden() -> void:
	var b := _battle(["deadman", "chimera_wolf"])
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	me.actor.inventory.add("goddess_tear", 1)
	var dm := b.side_units(Combatant.SIDE_ENEMY)[0]
	var cw := b.side_units(Combatant.SIDE_ENEMY)[1]
	var hp_cw := cw.actor.pool.get_current("hp")
	b.current = me
	b.phase = Battle.PHASE_AWAIT
	assert_true(b.act(me, {"kind": "item", "item": "goddess_tear"}))
	assert_true(dm.actor.dead or dm.actor.statuses.has("tear_sealed"), "언데드에게 봉인 + 큰 피해")
	assert_near(cw.actor.pool.get_current("hp"), hp_cw, 0.001, "짐승은 그대로")
	var drops := Loot.roll(db, "deadman_commander", Rng.new(1))
	assert_false(drops.any(func(d: Dictionary) -> bool: return not d["id"].begins_with("magic_stone")), "지휘관 데드맨: 마석 말고는 떨어뜨리지 않는다(RF17)")
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), _pc(), GameClock.new(), Rng.new(4), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, "rift_blood_fortress", s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	var run := cs.rift_run
	run.debug_clear()
	cs = run.use_exit(cs)
	run.debug_clear()
	cs = run.use_exit(cs)
	assert_eq(run.hidden_at.size(), 1, "3챕터 분수대 조각상")
	var at: Vector2i = run.hidden_at.keys()[0]
	assert_eq(cs.map.tile_id_at(at), "fountain_statue")
	assert_true(run.take_hidden(cs, at))
	assert_eq(s.player.inventory.count("goddess_tear"), 1, "여신의 눈물을 얻는다")
	run.finish()
	assert_eq(s.player.inventory.count("goddess_tear"), 0, "성채 밖으로는 가져갈 수 없다")


## 균열 전투 도구(성수 병 등)는 고른 적 하나만 친다(사용자 2026-10-30, RF27). 대상이 없거나 듣지 않으면 쓰지 않는다.
func test_holy_water_hits_one_target() -> void:
	var b := _battle(["deadman", "deadman", "chimera_wolf"])
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	me.actor.inventory.add("fortress_holy_water", 3)
	var foes := b.side_units(Combatant.SIDE_ENEMY)
	var a: Combatant = foes[0]
	var other: Combatant = foes[1]
	var cw: Combatant = foes[2]
	var hp_other := other.actor.pool.get_current("hp")
	b.current = me
	b.phase = Battle.PHASE_AWAIT
	assert_false(b.act(me, {"kind": "item", "item": "fortress_holy_water"}), "대상을 고르지 않으면 쓰지 않는다")
	assert_false(b.act(me, {"kind": "item", "item": "fortress_holy_water", "target": cw}), "짐승에게는 듣지 않는다")
	assert_eq(me.actor.inventory.count("fortress_holy_water"), 3, "쓰지 않았으면 그대로")
	var hp_a := a.actor.pool.get_current("hp")
	assert_true(b.act(me, {"kind": "item", "item": "fortress_holy_water", "target": a}))
	assert_true(a.actor.dead or a.actor.pool.get_current("hp") < hp_a, "고른 데드맨이 맞는다")
	assert_near(other.actor.pool.get_current("hp"), hp_other, 0.001, "다른 데드맨은 그대로")
	assert_eq(me.actor.inventory.count("fortress_holy_water"), 2)
	for id: String in ["fortress_holy_water", "glacier_ice_spike", "mine_powder_pouch", "tomb_seal_charm"]:
		assert_false(BattleRules.single_smite(db, id).is_empty(), id + ": 하나만")
	assert_true(BattleRules.single_smite(db, "goddess_tear").is_empty(), "여신의 눈물은 그대로 전원")


func test_telegraph_waits_through_extra_action() -> void:
	var b := _battle(["blater"], 2)
	var bl := b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	BossHooks.apply_effects(b, bl, me, JsonUtil.get_array(db.get_entry("skills", "blater_death_sentence"), "effects"))
	bl.memo["in_extra"] = true
	BattleDelayed.tick(b, bl)
	assert_true(me.actor.statuses.has("telegraphed"), "추가 행동 차례에는 예고가 터지지 않는다")
	bl.memo["in_extra"] = false
	BattleDelayed.tick(b, bl)
	assert_false(me.actor.statuses.has("telegraphed"), "다음 라운드에 터진다")
