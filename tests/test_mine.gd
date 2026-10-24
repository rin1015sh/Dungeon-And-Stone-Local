extends TestCase
## G7 녹색 탄광(docs/PROMPT_FLOOR1_V2.md §11): 분열·흡수·소환 만료·자폭·유도 폭발·독성부여·광부모·방어 무시·
## 킹 슬라임 패턴·지연 폭탄 예고·히든 피스·폭약 출구·소화력·분열 공유 중복 거부·경험치.

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


func _apply(src: Actor, tgt: Actor, fx: Array, seed_value: int = 1) -> EffectContext:
	var reg := ContentRegistries.new()
	var ctx := EffectContext.new(db, src, tgt, Rng.new(seed_value))
	ctx.registry = reg.effects
	reg.effects.apply_all(ctx, fx)
	return ctx


func _act(b: Battle, c: Combatant, action: Dictionary) -> bool:
	b.current = c
	b.phase = Battle.PHASE_AWAIT
	return b.act(c, action)


func test_slime_split_and_shared_essence() -> void:
	var b := _battle(["slime"])
	var s := b.side_units(Combatant.SIDE_ENEMY)[0]
	s.actor.pool.set_current("hp", 20.0)
	assert_eq(b.ai_action(s)["skill"], "slime_split", "생명력 50% 이하면 분열")
	assert_true(_act(b, s, {"kind": "skill", "skill": "slime_split", "target": null}))
	var slimes := b.side_units(Combatant.SIDE_ENEMY)
	assert_eq(slimes.size(), 2, "둘로 갈라진다")
	assert_near(slimes[0].actor.pool.get_current("hp"), 10.0, 0.001)
	assert_near(slimes[1].actor.pool.get_current("hp"), 10.0, 0.001, "남은 생명력을 반씩")
	assert_false(b.can_use(slimes[1], "slime_split").is_empty(), "새 슬라임은 다시 갈라지지 않는다")
	assert_false(b.can_use(slimes[0], "slime_split").is_empty(), "전투당 1회")
	var pc := _pc(6)
	assert_eq(pc.essences.absorb(pc, {"essence": "slime", "color": "blue", "stats": {}}), "")
	assert_eq(pc.essences.check_absorb(pc, {"essence": "mineral_slime", "color": "green", "stats": {}}), "essence.reason_duplicate", "슬라임↔광물 슬라임 분열 중복 거부")
	assert_eq(pc.essences.check_absorb(pc, {"essence": "mineral_slime", "color": "red", "stats": {}}), "")


func test_king_absorb_and_summon_expire() -> void:
	var b := _battle(["king_slime", "slime"])
	var king := b.side_units(Combatant.SIDE_ENEMY)[0]
	var max_hp := king.actor.pool.get_max("hp")
	king.actor.pool.set_current("hp", max_hp * 0.5)
	assert_eq(b.ai_action(king)["skill"], "king_absorb", "60% 이하이고 슬라임이 있으면 흡수 우선")
	BossHooks.apply_effects(b, king, king, JsonUtil.get_array(db.get_entry("skills", "king_absorb"), "effects"))
	assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), 1, "슬라임이 사라진다")
	assert_true(b.killed.is_empty(), "처치가 아니다")
	assert_near(king.actor.pool.get_current("hp"), max_hp * 0.6, 1.0, "10% 회복")
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	BossHooks.apply_effects(b, me, me, JsonUtil.get_array(db.get_entry("skills", "ess_slime_split"), "effects"))
	var mine := b.side_units(Combatant.SIDE_PARTY).filter(func(u: Combatant) -> bool: return u.actor is Monster)
	assert_eq(mine.size(), 1, "정수판 분열: 슬라임 소환수")
	assert_near(me.actor.pool.get_ratio("hp"), 0.7, 0.01, "생명력 30%를 들인다")
	BattlePassives.turn_end(b, mine[0])
	assert_true(mine[0].is_active())
	BattlePassives.turn_end(b, mine[0])
	assert_false(mine[0].is_active(), "자기 차례 2번 뒤 사라진다")


func test_bomber_blast_and_cookoff() -> void:
	var b := _battle(["goblin_bomber"], 2)
	var bomber := b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var fire := [{"type": "damage", "scaling": "magic", "base": 5, "power": 0.1, "damage_type": "fire", "accuracy": 1000}]
	var cooked := false
	for i in 20:
		var ctx := _apply(me.actor, bomber.actor, fire, i + 1)
		if ctx.messages.any(func(m: Dictionary) -> bool: return m["key"] == "combat.bomber_cookoff"):
			cooked = true
			break
	assert_true(cooked, "화염을 받으면 50%로 유도 폭발")
	var hp_before: Array[float] = []
	for u in b.side_units(Combatant.SIDE_PARTY):
		hp_before.append(u.actor.pool.get_current("hp"))
	bomber.actor.pool.set_current("hp", 0.0)
	assert_true(BattlePassives.on_down(b, bomber), "쓰러지면 자폭")
	var party := b.side_units(Combatant.SIDE_PARTY)
	for i in party.size():
		assert_true(party[i].actor.pool.get_current("hp") < hp_before[i], "적 전체 피해")
	var bomb := JsonUtil.get_array(db.get_entry("skills", "bomber_delayed_bomb"), "effects")
	BossHooks.apply_effects(b, bomber, me, bomb)
	assert_true(me.actor.statuses.has("telegraphed"), "지연 폭탄 1라운드 전 예고")


func test_venom_helmet_and_defense_ignore() -> void:
	var hob := Monster.create(db, "hobgoblin_miner")
	_apply(hob, hob, JsonUtil.get_array(db.get_entry("skills", "hobgoblin_venom"), "effects"))
	assert_true(hob.statuses.has("venom_weapon"))
	var poisoned := false
	for i in 20:
		var t := _pc()
		_apply(hob, t, [{"type": "damage", "power": 0.1, "damage_type": "weapon", "accuracy": 1000}], i + 1)
		poisoned = poisoned or t.statuses.has("poison")
	assert_true(poisoned, "독성부여: 무기 적중 시 [중독] 60%")
	var fx := {"scaling": "phys", "power": 1.0, "damage_type": "pierce", "accuracy": 1000}
	var tough := Actor.new(db, {"p_res": 20})
	var expect := DamageCalc.attack_power(db, hob, fx) * 100.0 / (100.0 + 20.0 * 0.75 * 4.0)
	assert_near(float(DamageCalc.resolve(db, hob, tough, fx, HIT)["amount"]), expect, 1.0, "광부의 근력: 방어 25% 무시")
	var b := _battle(["goblin_miner"])
	var miner := b.side_units(Combatant.SIDE_ENEMY)[0].actor
	assert_true(miner.statuses.has("miner_helmet"), "광부모")
	var me := b.side_units(Combatant.SIDE_PARTY)[0].actor
	var plain := Actor.new(db, {"p_res": 12})
	var normal := float(DamageCalc.resolve(db, me, plain, fx, HIT)["amount"])
	var c1 := _apply(me, miner, [fx.merged({"type": "damage"})])
	assert_near(float(c1.events[0]["amount"]), normal * 0.5, 1.0, "첫 피격 −50%")
	assert_false(miner.statuses.has("miner_helmet"), "한 번 맞으면 벗겨진다")


func test_king_slime_pattern_and_splits() -> void:
	var b := _battle(["king_slime"], 3)
	var king := b.side_units(Combatant.SIDE_ENEMY)[0]
	var seq: Array = []
	for i in 4:
		king.acted = i
		seq.append(b.ai_action(king)["skill"])
	assert_eq(seq, ["king_pounce", "king_acid_rain", "king_pounce", "king_jump_crush"], "덮치기 → 산성비 → 덮치기 → 압살")
	king.actor.pool.set_current("hp", king.actor.pool.get_max("hp") * 0.7)
	BossHooks.check_all(b)
	assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), 3, "25% 깎이면 슬라임 2체")
	king.actor.pool.set_current("hp", king.actor.pool.get_max("hp") * 0.45)
	BossHooks.check_all(b)
	assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), 5, "또 25%")
	BossHooks.apply_effects(b, king, b.side_units(Combatant.SIDE_PARTY)[0], JsonUtil.get_array(db.get_entry("skills", "king_jump_crush"), "effects"))
	assert_true(b.side_units(Combatant.SIDE_PARTY)[0].actor.statuses.has("telegraphed"), "점프 압살 예고")
	assert_true(king.actor.stats.apply_modifiers("dmg_taken:blunt", 1.0) < 1.0, "둔기 −40%")


func test_mine_chapters_hidden_and_explosive() -> void:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), _pc(), GameClock.new(), Rng.new(4), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, "rift_green_mine", s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	var run := cs.rift_run
	assert_eq(run.guardian_id(), "king_slime")
	assert_false(run.variant, "변종 없음")
	var at: Vector2i = run.hidden_at.keys()[0]
	assert_eq(cs.map.tile_id_at(at), "rail_wall_cracked")
	assert_true(run.take_hidden(cs, at))
	assert_eq(s.player.inventory.count("green_gem"), 1, "초록 보석")
	run.debug_clear()
	cs = run.use_exit(cs)
	assert_false(run.hazards.at.is_empty(), "무너진 다리")
	at = run.hidden_at.keys()[0]
	assert_eq(cs.map.tile_id_at(at), "ore_vein")
	assert_true(run.take_hidden(cs, at))
	assert_true(ItemUser.use(reg.effects, s.player, "gobl_quartz", Rng.new(1)).success)
	assert_near(s.player.stats.get_base("resist_poison"), 3.0, 0.001, "고블 쿼츠 독내성 +3")
	run.debug_clear()
	cs = run.use_exit(cs)
	run.debug_clear()
	assert_eq(run.use_exit(cs), null, "폭약 없이는 무너진 갱도를 못 지난다")
	at = run.hidden_at.keys()[0]
	assert_eq(cs.map.tile_id_at(at), "explosive_crate")
	assert_true(run.take_hidden(cs, at))
	cs = run.use_exit(cs)
	assert_true(cs != null and run.is_last_chapter(), "폭약으로 뚫는다")
	assert_eq(s.player.inventory.count("mine_explosive"), 1, "상자에 두 개 — 하나가 남는다(히든 피스 H)")
	assert_eq(s.player.inventory.count("green_gem"), 1)


func test_strong_bypass_digestion_and_exp() -> void:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var strong := _pc()
	strong.stats.set_base("str", 45.0)
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), strong, GameClock.new(), Rng.new(5), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, "rift_green_mine", s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	var run := cs.rift_run
	for i in 3:
		run.debug_clear()
		cs = run.use_exit(cs)
	assert_true(cs != null and run.is_last_chapter(), "근력 40 이상이면 폭약 없이 부순다")
	var plain := _pc()
	var eater := _pc()
	eater.stats.set_base("digestion", 50.0)
	assert_near(eater.pool.regen_per_unit("hunger", "time"), plain.pool.regen_per_unit("hunger", "time") * 0.5, 0.0001, "소화력 50 → 허기 감소 절반")
	var ex := {"slime": 1, "goblin_miner": 2, "mineral_slime": 2, "hobgoblin_miner": 3, "copper_golem": 3, "goblin_bomber": 4, "king_slime": 4}
	for id: String in ex:
		assert_eq(Progression.first_kill_exp(db, db.get_entry("monsters", id)), int(ex[id]), id)
	assert_near(EssenceDrop.drop_chance(db, db.get_entry("monsters", "goblin_bomber")), 0.1, 0.0001, "폭탄병 정수 10%")
	assert_false(db.get_entry("rifts", "rift_green_mine").has("stand_in"))
