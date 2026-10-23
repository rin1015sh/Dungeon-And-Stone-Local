extends TestCase
## G8 강철의 묘(docs/PROMPT_FLOOR1_V2.md §12): 함정(숨음·탐지·해제·밟아 부수기·감시자)·벽화 힌트·수수께끼 문지기·
## 배리드언 부활·정수판 버팀·자석 끌어당기기·일디움 패턴과 과열·임시 문지기 제거·경험치 108.

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


func _enter(pc: PlayerCharacter, seed_value: int = 4) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), pc, GameClock.new(), Rng.new(seed_value), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, "rift_iron_tomb", s.pos)
	return s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])


func test_hidden_traps_detect_disarm_and_watcher() -> void:
	var cs := _enter(_pc())
	var run := cs.rift_run
	assert_eq(run.guardian_id(), "ildium")
	var hz := run.hazards
	assert_false(hz.at.is_empty(), "함정이 깔린다")
	var cell: Vector2i = hz.at.keys()[0]
	var group: Dictionary = hz.at[cell]
	assert_true(JsonUtil.get_bool(group, "hidden"))
	assert_true(cs.map.tile_id_at(cell) != JsonUtil.get_str(group, "tile"), "숨은 함정은 원래 바닥처럼 보인다")
	assert_true(cs.map.is_walkable(cell))
	cs.player.stats.set_base("int", 60.0)
	var beside := Vector2i(-1, -1)  # 묶음 바로 옆(함정이 아닌 걸을 수 있는 칸)
	for q: Variant in group["cells"]:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var b: Vector2i = (q as Vector2i) + d
			if beside.x < 0 and cs.map.is_walkable(b) and not hz.at.has(b):
				beside = b
	assert_true(beside.x >= 0, "함정 옆 칸")
	hz.on_step(cs, beside)
	assert_true(bool(group.get("detected", false)), "정신력이 높으면 옆에서 알아챈다(옛 육감)")
	assert_eq(cs.map.tile_id_at(cell), JsonUtil.get_str(group, "tile"), "드러난다")
	var nimble := Actor.new(db, {"agi": 40})
	assert_near(RiftHazards.success_chance(db, nimble, JsonUtil.get_dict(group, "disarm")), float(db.bal("rift.hazard_max")), 0.001, "민첩으로 해제(옛 손재주)")
	assert_true(hz.watcher_bonus(cs) == 0.0, "1챕터엔 수호자의 눈이 없다")
	run.debug_clear()
	cs = run.use_exit(cs)
	assert_near(run.hazards.watcher_bonus(cs), 0.5, 0.001, "2챕터 수호자의 눈이 살아 있으면 함정 발동 +50%")
	var tank := _pc()
	tank.stats.set_base("p_res", 40.0)
	var cs2 := _enter(tank, 7)
	var c2: Vector2i = cs2.rift_run.hazards.at.keys()[0]
	var hp := tank.pool.get_current("hp")
	assert_eq(cs2.rift_run.hazards.on_step(cs2, c2), true, "물리내성이 높으면 밟아 부순다")
	assert_near(tank.pool.get_current("hp"), hp, 0.001)


## 함정은 판정이 끝나도(해제·발동 모두) 그 자리에 보이는 채로 남고, 칸이 바뀌면 화면에 다시 그리라고 알린다(사용자 요청 2026-10-23).
func test_traps_stay_visible_after_use() -> void:
	var cs := _enter(_pc())
	var hz := cs.rift_run.hazards
	var changed: Array[Rect2i] = []
	cs.tiles_changed.connect(func(r: Rect2i) -> void: changed.append(r))
	var cell: Vector2i = hz.at.keys()[0]
	var group: Dictionary = hz.at[cell]
	var tile := JsonUtil.get_str(group, "tile")
	cs.player.stats.set_base("int", 0.0)  # 알아채지 못한 채 밟는다
	cs.player.stats.set_base("agi", 0.0)
	hz.on_step(cs, cell)
	assert_false(hz.at.has(cell), "한 번 판정한 함정은 다시 발동하지 않는다")
	for c: Vector2i in group["cells"]:
		assert_eq(cs.map.tile_id_at(c), tile, "발동한 숨은 함정은 드러나 그 자리에 남는다 %s" % c)
		assert_true(cs.map.is_walkable(c))
	assert_false(changed.is_empty(), "드러난 칸을 다시 그린다")
	for c: Vector2i in group["cells"]:
		assert_true(changed.any(func(r: Rect2i) -> bool: return r.has_point(c)), "바뀐 칸이 다시 그릴 범위에 든다 %s" % c)
	var next: Vector2i = hz.at.keys()[0]  # 알아채고 해제한 함정도 남는다
	var g2: Dictionary = hz.at[next]
	g2["detected"] = true
	hz._show(cs, g2)
	cs.player.stats.set_base("agi", 80.0)
	assert_eq(hz.on_step(cs, next), true, "해제")
	for c: Vector2i in g2["cells"]:
		assert_eq(cs.map.tile_id_at(c), JsonUtil.get_str(g2, "tile"), "해제한 함정도 그 자리에 남는다")


func test_murals_and_riddle() -> void:
	var pc := _pc()
	var cs := _enter(pc)
	var run := cs.rift_run
	var rd := run.riddle
	assert_true(rd != null and rd.is_ready(), "입장 때 수수께끼 하나")
	assert_eq(rd.choices().size(), 5, "선택지 5개")
	var mural: Vector2i = run.hidden_at.keys()[0]
	assert_eq(cs.map.tile_id_at(mural), "tomb_mural")
	assert_true(run.take_hidden(cs, mural))
	assert_eq(rd.known(pc), 1, "벽화 하나 = 힌트 하나")
	assert_true(run.take_hidden(cs, mural), "다시 읽을 수 있다")
	assert_eq(rd.known(pc), 1, "같은 벽화는 같은 힌트")
	assert_eq(rd.known_hints(pc), [str(rd.hints()[0])], "대화창에 보일 벽화 장면")
	run.debug_clear()
	cs = run.use_exit(cs)
	assert_true(run.take_hidden(cs, run.hidden_at.keys()[0]))
	run.debug_clear()
	cs = run.use_exit(cs)
	assert_true(run.take_hidden(cs, run.hidden_at.keys()[0]))
	assert_eq(rd.known(pc), 3, "벽화 셋 = 힌트 셋")
	var left := rd.choices()
	assert_eq(left.size(), 5, "힌트를 다 알아도 선택지는 지워지지 않는다(벽화만 보고 저절로 풀리지 않게)")
	assert_true(left.has(JsonUtil.get_int(rd.data, "answer")))
	var gate: FieldMonsters.Group = run.remaining.filter(func(g: FieldMonsters.Group) -> bool: return g.tag == "riddle")[0]
	assert_true(rd.blocks(gate))
	var asked: Array = []
	cs.riddle_asked.connect(func(g: FieldMonsters.Group) -> void: asked.append(g))
	cs.engage(gate, false)
	assert_eq(asked.size(), 1, "마주치면 전투 대신 수수께끼")
	assert_false(cs.in_combat)
	var saved := pc.knowledge.to_dict()
	var pc2 := _pc()
	pc2.knowledge.load_dict(saved)
	assert_eq(rd.known(pc2), 3, "벽화 힌트는 캐릭터 지식으로 남는다")
	cs.answer_riddle(gate, RiftRiddle.PASS)
	assert_false(run.remaining.has(gate), "정답 → 전투 없이 통과")
	assert_false(cs.in_combat)


func test_riddle_weaken_and_wrong_rules() -> void:
	var cs := _enter(_pc())
	var run := cs.rift_run
	for i in 2:
		run.debug_clear()
		cs = run.use_exit(cs)
	var gate: FieldMonsters.Group = run.remaining.filter(func(g: FieldMonsters.Group) -> bool: return g.tag == "riddle")[0]
	var fought: Array = []
	cs.encounter.connect(func(g: FieldMonsters.Group, _pf: bool) -> void: fought.append(g))
	cs.answer_riddle(gate, RiftRiddle.WEAKEN)
	assert_eq(fought.size(), 1, "약화 → 바로 전투")
	assert_eq(JsonUtil.get_array(gate.battle_rules, "enemy_statuses"), ["riddle_weakened"])
	assert_near(JsonUtil.get_float(gate.battle_rules, "essence_mult"), 2.0, 0.001, "정수 드롭률 ×2")
	var b := _battle(["riddle_gatekeeper"])
	BattleRules.set_objective(b, gate.battle_rules)
	var gk := b.side_units(Combatant.SIDE_ENEMY)[0].actor
	assert_near(gk.stats.get_value("str"), 24.0 * 0.7, 0.01, "모든 스탯 −30%")
	var b2 := _battle(["riddle_gatekeeper"])
	BattleRules.set_objective(b2, {"enemy_statuses": ["riddle_empowered"]})
	assert_near(b2.side_units(Combatant.SIDE_ENEMY)[0].actor.stats.get_value("p_res"), 28.0 * 1.2, 0.01, "오답 → +20%")
	var hits := 0
	for i in 400:
		if not EssenceDrop.roll(db, "riddle_gatekeeper", Rng.new(i), true, 2.0).is_empty():
			hits += 1
	var base := EssenceDrop.drop_chance(db, db.get_entry("monsters", "riddle_gatekeeper"), true)
	assert_true(absf(float(hits) / 400.0 - base * 2.0) < 0.06, "정수 ×2 (%d/400, 기대 %.2f)" % [hits, base * 2.0])


func test_buried_revive_and_endure() -> void:
	var b := _battle(["buried_one"])
	var bo := b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var kill := [{"type": "damage", "power": 50.0, "damage_type": "holy", "scaling": "magic", "base": 100, "accuracy": 1000}]
	_apply(me.actor, bo.actor, kill)
	assert_false(bo.actor.dead, "관 속의 망자: 한 번 일어난다")
	assert_near(bo.actor.pool.get_current("hp"), roundf(150.0 * 0.3), 0.001, "생명력 30%")
	_apply(me.actor, bo.actor, kill)
	assert_true(bo.actor.dead, "두 번째는 쓰러진다")
	var pc := _pc(6)
	assert_eq(pc.essences.absorb(pc, {"essence": "buried_one", "color": "red", "stats": {}}), "")
	_apply(bo.actor, pc, kill)
	assert_near(pc.pool.get_current("hp"), 1.0, 0.001, "정수판: 생명력 1로 버틴다")
	BattleRules.cleanup(b)
	var b2 := _battle(["mummy"])
	b2.units.append(Combatant.new(pc, Combatant.SIDE_PARTY))
	BattleRules.cleanup(b2)
	assert_false(pc.has_meta(Passives.REVIVED_META), "전투가 끝나면 다시 쓸 수 있다")


func test_ildium_pattern_magnet_and_overheat() -> void:
	var b := _battle(["ildium"], 3)
	var il := b.side_units(Combatant.SIDE_ENEMY)[0]
	var seq: Array = []
	for i in 4:
		il.acted = i
		seq.append(b.ai_action(il)["skill"])
	assert_eq(seq, ["ild_steel_fist", "ild_magnet_pull", "ild_steel_fist", "ild_tomb_trap"], "주먹 → 자석 → 주먹 → 함정")
	var me := b.side_units(Combatant.SIDE_PARTY)[1]
	BossHooks.apply_effects(b, il, me, JsonUtil.get_array(db.get_entry("skills", "ild_magnet_pull"), "effects"))
	assert_true(me.actor.statuses.has("magnetized") and me.actor.statuses.has("snare"))
	il.acted = 1
	var act := b.ai_action(il)
	assert_eq(act["skill"], "ild_steel_fist", "끌려온 대상에게 주먹")
	assert_eq(act["target"], me)
	assert_near(DamageCalc.hit_chance(db, il.actor, me.actor, false, 1.0), 1.0, 0.001, "확정 명중")
	BossHooks.apply_effects(b, il, b.side_units(Combatant.SIDE_PARTY)[0], JsonUtil.get_array(db.get_entry("skills", "ild_tomb_trap"), "effects"))
	assert_true(b.side_units(Combatant.SIDE_PARTY)[0].actor.statuses.has("telegraphed"), "분묘의 함정 예고")
	il.actor.pool.set_current("hp", il.actor.pool.get_max("hp") * 0.45)
	BossHooks.check_all(b)
	assert_true(il.actor.statuses.has("ildium_overheat"), "50%에서 과열")
	assert_true(il.actor.damage_affinity("lightning", "magical") > 1.0, "전기 약점")
	var fx := {"scaling": "phys", "power": 1.0, "damage_type": "slash", "accuracy": 1000}
	assert_true(il.actor.stats.apply_modifiers("dmg_taken:slash", 1.0) < 0.7, "베기 −40%")
	assert_true(DamageCalc.resolve(db, me.actor, il.actor, fx, HIT)["amount"] > 0)


func test_tomb_data_and_exp() -> void:
	assert_false(db.has_entry("monsters", "rift_warden_standin"), "임시 문지기 제거")
	assert_false(db.has_entry("skills", "warden_mark_smash"))
	for id: Variant in db.get_collection("rifts").keys():
		assert_false(db.get_entry("rifts", str(id)).has("stand_in"), "%s: 임시 내용 없음" % id)
	var ex := {"mummy": 1, "buried_one": 2, "guardian_eye": 2, "riddle_gatekeeper": 3, "iron_cavalry": 3, "iron_lizardman": 3, "ildium": 4}
	for id: String in ex:
		assert_eq(Progression.first_kill_exp(db, db.get_entry("monsters", id)), int(ex[id]), id)
	assert_true(db.get_collection("riddles").size() >= 5, "수수께끼 5~10개")
	var murals := 0
	for ch: Variant in JsonUtil.get_array(db.get_entry("rifts", "rift_iron_tomb"), "chapters"):
		for h: Variant in JsonUtil.get_array(ch as Dictionary, "hidden"):
			murals += 1 if JsonUtil.get_bool(h as Dictionary, "mural") else 0
	for id: Variant in db.get_collection("riddles").keys():
		var r := db.get_entry("riddles", str(id))
		var choices := JsonUtil.get_array(r, "choices_ko")
		assert_eq(choices.size(), 5, "%s 선택지 5개" % id)
		assert_true(JsonUtil.get_int(r, "answer") >= 0 and JsonUtil.get_int(r, "answer") < choices.size())
		assert_eq(JsonUtil.get_array(r, "hints_ko").size(), murals, "%s 벽화마다 힌트 하나" % id)
		for hint: Variant in JsonUtil.get_array(r, "hints_ko"):
			assert_false(str(hint).contains(str(choices[JsonUtil.get_int(r, "answer")])), "%s 힌트가 정답을 그대로 말하지 않는다" % id)


## 선택지 순서는 입장마다 섞인다(자리로 답을 외우지 못하게) — 같은 시드면 같은 순서.
func test_riddle_choices_shuffled() -> void:
	var spec := JsonUtil.get_dict(db.get_entry("rifts", "rift_iron_tomb"), "riddle")
	var orders := {}
	for i in 12:
		var rd := RiftRiddle.new(db, spec, Rng.new(i + 1))
		var o := rd.choices()
		var sorted := o.duplicate()
		sorted.sort()
		assert_eq(sorted, [0, 1, 2, 3, 4], "선택지는 모두 보인다")
		orders[str(o)] = true
	assert_true(orders.size() > 1, "순서가 섞인다")
	assert_eq(RiftRiddle.new(db, spec, Rng.new(5)).choices(), RiftRiddle.new(db, spec, Rng.new(5)).choices(), "같은 시드면 같은 순서")
