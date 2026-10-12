extends TestCase
## G3 드레드피어(docs/PROMPT_FLOOR1_V2.md §7): 게이지 · 페이즈 · 라운드 규칙 · 예고 공격 · 오인 · 보상 · 맵 소환.


func _pc(level: int = 4) -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(level)
	pc.pool.fill_all()
	return pc


## 드레드피어 한 마리 + 탐험가 n명. [전투, 보스, 탐험가들]
func _fight(n: int = 1) -> Array:
	var reg := ContentRegistries.new()
	var b := Battle.new(db, reg.effects, reg.ai_conditions, Rng.new(7))
	var party: Array[Combatant] = []
	for i in n:
		party.append(b.add(_pc(), Combatant.SIDE_PARTY))
	var boss := b.add(Monster.create(db, "dreadfear"), Combatant.SIDE_ENEMY)
	b.start(true)
	return [b, boss, party]


func _set_hp_ratio(c: Combatant, r: float) -> void:
	c.actor.pool.set_current("hp", c.actor.pool.get_max("hp") * r)


func test_meter_full_applies_status_and_resets() -> void:
	var pc := _pc()
	assert_false(Meters.add(db, pc, "dread_fear", 60.0))
	assert_near(Meters.value(pc, "dread_fear"), 60.0, 0.001)
	assert_true(Meters.add(db, pc, "dread_fear", 50.0), "가득 참")
	assert_true(pc.statuses.has("fear"), "공포 게이지 → [공포]")
	assert_near(Meters.value(pc, "dread_fear"), 0.0, 0.001, "가득 차면 초기화")
	Meters.add(db, pc, "dread_plague", 100.0)
	assert_true(pc.statuses.has("lethargy") and pc.statuses.has_flag("no_skills"), "역병 → 무기력증(이능 불가)")
	Meters.add(db, pc, "dread_resentment", 100.0)
	assert_true(pc.statuses.has("exhaustion"), "원망 → 탈진")


func test_gnawing_fear_and_rage() -> void:
	var f := _fight()
	var b: Battle = f[0]
	var boss: Combatant = f[1]
	var me: Combatant = (f[2] as Array)[0]
	assert_eq(str(boss.memo["phase"]), "p1")
	BossHooks.turn_end(b, boss, false)
	assert_near(Meters.value(me.actor, "dread_fear"), 10.0 - 10.0 / 10.0, 0.001, "갉아먹는 공포: 10 − 정신력/10")
	var ctx := EffectContext.new(db, me.actor, boss.actor, Rng.new(1))
	ctx.registry = b.effects
	b.effects.apply_all(ctx, [{"type": "damage", "scaling": "phys", "power": 3.0, "damage_type": "slash", "accuracy": 1000}])
	var dealt := boss.actor.pool.get_max("hp") - boss.actor.pool.get_current("hp")
	assert_near(Meters.value(boss.actor, "dread_rage"), dealt / boss.actor.pool.get_max("hp") * 100.0, 0.01, "받은 피해 1%당 분노 +1")


func test_phases_follow_hp() -> void:
	var f := _fight(2)
	var b: Battle = f[0]
	var boss: Combatant = f[1]
	var me: Combatant = (f[2] as Array)[0]
	_set_hp_ratio(boss, 0.6)
	BossHooks.check_all(b)
	assert_eq(str(boss.memo["phase"]), "p2")
	assert_true(me.actor.statuses.has("dread_seeping"), "P2 스며드는 공포")
	assert_eq(str(boss.memo.get("target_rule", "")), "guard_front")
	BossHooks.turn_end(b, boss, false)
	assert_near(Meters.value(me.actor, "dread_plague"), 8.0, 0.001, "P2 역병 확산 +8")
	_set_hp_ratio(boss, 0.3)
	BossHooks.check_all(b)
	assert_eq(str(boss.memo["phase"]), "p3")
	assert_true(me.actor.statuses.has("dread_veil"), "P3 배신의 장막")
	_set_hp_ratio(boss, 0.1)
	BossHooks.check_all(b)
	assert_eq(str(boss.memo["phase"]), "p4")
	assert_false(me.actor.statuses.has("dread_veil"), "P4에서 장막이 걷힌다")
	assert_true(boss.actor.statuses.has("dread_human_form"))
	assert_true(bool((boss.memo["flags"] as Dictionary).get("old_memory", false)), "아군 5인 이하 → old_memory")
	_set_hp_ratio(boss, 0.9)
	BossHooks.check_all(b)
	assert_eq(str(boss.memo["phase"]), "p4", "페이즈는 앞으로만")


func test_p1_maggots_and_proliferation() -> void:
	var f := _fight()
	var b: Battle = f[0]
	var boss: Combatant = f[1]
	for i in 12:
		BossHooks.turn_end(b, boss, false)
		if i == 2:
			assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), 3, "3라운드에 구더기 2체")
	assert_eq(boss.actor.statuses.stacks("dread_proliferating"), 3, "4라운드마다 공포의 증식")
	assert_true(b.side_units(Combatant.SIDE_ENEMY).size() <= int(db.bal("combat.max_side_units")))
	var pat := BossHooks.pattern(b, boss)
	assert_false(pat.wants_extra_action(b, boss))
	boss.actor.statuses.apply("dread_proliferating")
	assert_true(pat.wants_extra_action(b, boss), "4중첩부터 라운드당 2회 행동")
	var r := int(boss.memo["round"])
	BossHooks.turn_end(b, boss, false)
	assert_eq(int(boss.memo["round"]), r, "추가 행동은 같은 라운드")
	BossHooks.turn_end(b, boss, false)
	assert_eq(int(boss.memo["round"]), r + 1)


func test_p3_cycle_veil_groggy_buff() -> void:
	var f := _fight()
	var b: Battle = f[0]
	var boss: Combatant = f[1]
	var me: Combatant = (f[2] as Array)[0]
	_set_hp_ratio(boss, 0.3)
	BossHooks.check_all(b)
	for i in 3:
		BossHooks.turn_end(b, boss, false)
	assert_false(me.actor.statuses.has("dread_veil"), "장막 3라운드 뒤 걷힘")
	assert_true(boss.actor.statuses.has("dread_groggy") and boss.actor.statuses.has_flag("skip_turn"), "보호기제(그로기)")
	for i in 2:
		BossHooks.turn_end(b, boss, true)
	assert_eq((boss.memo["buffs"] as Array).size(), 1, "그로기 뒤 버프 하나")
	assert_true(me.actor.statuses.has("dread_veil"), "다시 장막")
	assert_true(Meters.value(boss.actor, "dread_hatred") > 0.0, "P3부터 증오가 쌓인다")


func test_inner_mirror_and_delayed_memory() -> void:
	var f := _fight()
	var b: Battle = f[0]
	var boss: Combatant = f[1]
	var me: Combatant = (f[2] as Array)[0]
	me.actor.meters["dread_fear"] = 30.0
	var hp := me.actor.pool.get_current("hp")
	BossHooks.apply_effects(b, boss, me, JsonUtil.get_array(db.get_entry("skills", "dread_inner_mirror"), "effects"))
	assert_near(me.actor.pool.get_current("hp"), hp - 60.0, 0.001, "공포 × 2 고정 피해")
	hp = me.actor.pool.get_current("hp")
	BossHooks.apply_effects(b, boss, boss, JsonUtil.get_array(db.get_entry("skills", "dread_dead_memory"), "effects"))
	assert_eq((boss.memo["delayed"] as Array).size(), 1)
	BattleDelayed.tick(b, boss)
	assert_near(me.actor.pool.get_current("hp"), hp, 0.001, "1라운드 뒤엔 아직")
	BattleDelayed.tick(b, boss)
	assert_true(me.actor.pool.get_current("hp") < hp or me.actor.dead, "2라운드 뒤 쏟아진다")
	assert_true((boss.memo["delayed"] as Array).is_empty())


func test_misdirect_and_veil_rules() -> void:
	var f := _fight(2)
	var b: Battle = f[0]
	var party: Array = f[2]
	var a: Combatant = party[0]
	var c2: Combatant = party[1]
	a.actor.statuses.apply("dread_veil")
	var hits := 0
	for i in 50:
		var m := BattleTargets.misdirect(b, a, "enemy_single")
		if not m.is_empty():
			hits += 1
			assert_true(m["target"] == c2, "오인은 다른 아군에게")
			assert_near(float(m["power_mult"]), 5.0, 0.001)
	assert_true(hits > 5 and hits < 40, "배신의 장막 오인 40%% 근처 (%d/50)" % hits)
	var boosted := BattleTargets.boosted([{"type": "damage", "power": 1.0}], {"power_mult": 5.0, "ignore_defense": true})
	assert_near(float(boosted[0]["power"]), 5.0, 0.001)
	assert_true(bool(boosted[0]["ignore_defense"]))
	var solo := _fight()
	var lone: Combatant = (solo[2] as Array)[0]
	lone.actor.statuses.apply("dread_veil")
	for i in 20:
		assert_eq(BattleTargets.misdirect(solo[0] as Battle, lone, "enemy_single"), {}, "혼자면 오인 없음")
	assert_eq(b.flee_chance(a), 0.0, "계층군주전 도주 불가")


func test_hatred_burst_ai_and_cleanup() -> void:
	var f := _fight()
	var b: Battle = f[0]
	var boss: Combatant = f[1]
	var me: Combatant = (f[2] as Array)[0]
	Meters.add(db, boss.actor, "dread_hatred", 100.0)
	assert_true(boss.actor.statuses.has("dread_hatred_burst"))
	assert_eq(b.ai_action(boss)["skill"], "dread_hate_explosion", "증오 폭발")
	me.actor.statuses.apply("dread_seeping")
	me.actor.meters["dread_fear"] = 20.0
	BattleRules.cleanup(b)
	assert_false(me.actor.statuses.has("dread_seeping"), "전투 한정 상태 해제")
	assert_true(me.actor.meters.is_empty(), "게이지 초기화")


func test_lord_rewards() -> void:
	var p := Progression.new()
	assert_eq(p.record_kill(db, "dreadfear"), int(db.prog("exp.lord_bonus")), "군주 +15(첫 처치 경험치 없음)")
	assert_eq(p.record_kill(db, "dreadfear"), 0, "군주 보너스는 1회")
	assert_eq(p.record_kill(db, "dreadfear_maggot"), 0, "토큰 0")
	assert_eq(EssenceDrop.drop_chance(db, db.get_entry("monsters", "dreadfear")), 0.0, "정수 없음")
	assert_true(Loot.roll(db, "dreadfear", Rng.new(1)).is_empty(), "전리품 없음")


func _session(min_party: int) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave").duplicate(true)
	(def["lord"] as Dictionary)["min_party"] = min_party
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(3))
	var s := ExploreSession.new(db, def, map, _pc(), GameClock.new(), Rng.new(4), reg.effects)
	s.start()
	return s


func test_summon_conditions() -> void:
	var s := _session(1)
	var w := s.lord
	for i in 40:
		w.update(s, 1.0)  # 1~2일 차: 아무리 머물러도 안 나온다
	assert_eq(w.state, LordWatch.IDLE, "3일 차 전")
	s.clock.advance(48.0)
	var crowd := _session(5)
	crowd.clock.advance(48.0)
	for i in 48:
		crowd.lord.update(crowd, 1.0)
	assert_eq(crowd.lord.state, LordWatch.IDLE, "인원 부족(혼자, 최소 5)")
	assert_true(w.chance_for(24.0, 1.0) > w.chance_for(2.0, 1.0) * 10.0, "머문 시간에 따라 지수적으로")
	var survive := 1.0
	for h in 24:
		survive *= 1.0 - w.chance_for(float(h), 1.0)
	assert_true(survive < 0.05, "하루면 사실상 확정 (남을 확률 %.3f)" % survive)
	var summoned := false
	for i in 30:
		summoned = summoned or w.update(s, 1.0)
	assert_true(summoned and w.is_active(), "3일 차 이후 머물면 소환")
	s.refresh_view()
	assert_near(s.vision_m, w.vision_cap_m(), 0.001, "소환 중 시야 2m")
	assert_true(s.monsters.groups.has(w.group))
	assert_true(w.on_battle_end(s, w.group, Battle.RESULT_VICTORY))
	assert_eq(w.state, LordWatch.COOLDOWN, "6시간 재소환 대기")
	assert_false(w.update(s, 1.0), "대기 중엔 소환되지 않는다")


func test_moving_resets_stay() -> void:
	var s := _session(1)
	s.clock.advance(48.0)
	var w := s.lord
	w.update(s, 2.0)
	assert_near(w.stay_hours, 2.0, 0.001)
	var far := s.pos
	for c in s.map.tiles.size():
		var p := s.map.pos_of(c)
		if s.map.is_walkable(p) and Vector2(p - s.pos).length() > 10.0 and s.monsters.group_at(p) == null:
			far = p
			break
	s.relocate(far)
	w.update(s, 0.5)
	assert_near(w.stay_hours, 0.5, 0.001, "자리를 옮기면 처음부터")
