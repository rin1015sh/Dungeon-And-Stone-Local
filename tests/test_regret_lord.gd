extends TestCase
## 2층 계층군주 「후회의 군주」(plans/expansion_f1_3_B §6): 네 길 끝(3층 포탈 곁) 후회의 제단 · 수호자 넷을 모두 쓰러뜨린 적이 있어야 부름 ·
## 부른 길의 탈이 첫 페이즈(RegretMasks) · 탈이 깨질 때 그 길 몬스터 · 탈마다 다른 기술.

const ROADS := {"f2_beast_den": "beast", "f2_land_of_dead": "dead", "f2_rock_desert": "sand", "f2_goblin_forest": "goblin"}
const GUARDIANS := ["wolf_king", "sleepless_knight", "sand_colossus", "goblin_trap_king"]


func _session(fid: String, seed_value: int = 2) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", fid)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = true
	s.start()
	return s


func _altar(s: ExploreSession) -> Dictionary:
	for e: Dictionary in s.features.list:
		if str(e["id"]) == "regret_altar":
			return e
	return {}


func _summon(e: Dictionary) -> Dictionary:
	for a: Variant in JsonUtil.get_array(e["def"], "actions"):
		if str((a as Dictionary)["id"]) == "summon":
			return a
	return {}


func test_altar_at_every_road_end() -> void:
	for fid: String in ROADS:
		var s := _session(fid)
		var al := _altar(s)
		assert_false(al.is_empty(), "%s: 후회의 제단" % fid)
		var near := s.map.portals.any(func(p: Dictionary) -> bool:
			return str(p.get("dest", "")).begins_with("floor3_") and Vector2((p["pos"] as Vector2i) - (al["pos"] as Vector2i)).length() <= 8.0)
		assert_true(near, "%s: 3층 포탈 곁" % fid)
		assert_eq(JsonUtil.get_str(s.lord.def, "mask"), ROADS[fid], "%s: 이 길의 탈" % fid)
		s.detach()


func test_altar_needs_all_four_guardians() -> void:
	var s := _session("f2_rock_desert")
	var al := _altar(s)
	FieldFeatureAct.run(s, al, _summon(al))
	assert_false(s.lord.is_active(), "수호자 기록이 없으면 제단은 차갑다")
	for g in GUARDIANS.slice(0, 3):
		s.player.progression.record_kill(db, g)
	FieldFeatureAct.run(s, al, _summon(al))
	assert_false(s.lord.is_active(), "셋으로는 안 된다")
	s.player.progression.record_kill(db, GUARDIANS[3])
	FieldFeatureAct.run(s, al, _summon(al))
	assert_true(s.lord.is_active(), "넷을 모두 쓰러뜨린 적이 있으면 군주가 선다")
	assert_eq(s.lord.group.leader(), "regret_lord")
	var party: Array[Actor] = [s.player]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, s.lord.group.monster_ids)
	BattleFloor.apply(b, s, s.lord.group)
	var lord: Combatant = b.side_units(Combatant.SIDE_ENEMY).filter(func(u: Combatant) -> bool: return (u.actor as Monster).monster_id == "regret_lord")[0]
	assert_eq(RegretMasks.current(b, lord), "sand", "바위사막 제단에서 부르면 모래 탈부터")
	s.detach()


func test_lead_mask_and_breaks() -> void:
	var party: Array[Actor] = [PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12})]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["regret_lord"])
	var lord: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	lord.actor.set_meta(RegretMasks.LEAD, "sand")
	var ord := RegretMasks.order(b, lord)
	assert_eq(str(ord[0]), "sand", "부른 길의 탈이 맨 앞")
	assert_eq(str(ord[4]), RegretMasks.FACE, "마지막은 민낯")
	assert_eq(ord.slice(0, 4).duplicate().filter(func(m: Variant) -> bool: return m != "sand").size(), 3, "나머지 셋")
	assert_eq(str(MonsterAi.choose(b, lord)["skill"]), "regret_hourglass", "모래 탈 — 모래시계")
	var before := b.side_units(Combatant.SIDE_ENEMY).size()
	lord.actor.pool.set_current("hp", lord.actor.pool.get_max("hp") * 0.5)
	BossHooks.check_phase(b, lord)
	assert_eq(RegretMasks.phase_index(lord), 2, "생명력 50% — 세 번째 탈")
	assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), before + 2, "두 번째 탈이 깨질 때 그 길 몬스터 둘")
	assert_eq(RegretMasks.current(b, lord), str(ord[2]))
	assert_eq(int(db.prog("exp.lord_bonus")), 15, "군주 보너스 15")


## 2차(2026-11-21): 가장 많이 쓴 스킬 봉인 · 아군 순서 뒤집기 · 받은 피해 절반 되감기 · 계층석 2 · 정수.
func test_habits_reverse_and_rewind() -> void:
	var a := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12})
	var c2 := PlayerCharacter.create(db, "human", "warrior", "동료", {"str": 12})
	var party: Array[Actor] = [a, c2]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["regret_lord"])
	var lord: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	var me: Combatant = b.unit_of(a)
	a.skills.append_array(["ess_regret_claw", "ess_regret_mimic"])
	for i in 3:
		BattleHabits.record(b, me, "ess_regret_claw")
	BattleHabits.record(b, me, "ess_regret_mimic")
	assert_eq(BattleHabits.most_used(a, a.skills), "ess_regret_claw", "가장 많이 쓴 스킬")
	BossHooks.apply_effects(b, lord, me, [{"type": "seal_skill", "rounds": 3, "pick": "most_used"}])
	if a.statuses.has("seal"):
		assert_true(int(me.cooldowns.get("ess_regret_claw", 0)) >= 3, "흉내 — 가장 많이 쓴 스킬이 막힌다")
	var you: Combatant = b.unit_of(c2)
	me.gauge = 80.0
	you.gauge = 10.0
	BossHooks.apply_effects(b, lord, me, [{"type": "reverse_order"}])
	assert_eq(int(me.gauge), 10, "빠른 쪽이 늦게")
	assert_eq(int(you.gauge), 80, "늦은 쪽이 빠르게")
	var mx := lord.actor.pool.get_max("hp")
	lord.memo["hp_mark"] = mx
	lord.actor.pool.set_current("hp", mx - 1000.0)
	BossHooks.turn_end(b, lord, false)
	BossHooks.apply_effects(b, lord, lord, [{"type": "rewind", "ratio": 0.5}])
	assert_eq(int(lord.actor.pool.get_current("hp")), int(mx - 500.0), "직전 바퀴에 받은 1000의 절반을 되돌린다")


func test_floor_stone_two_opens_the_road_rift() -> void:
	var s := _session("f2_beast_den")
	var al := _altar(s)
	var offer := {}
	for x: Variant in JsonUtil.get_array(al["def"], "actions"):
		if str((x as Dictionary)["id"]) == "offer_stone":
			offer = x
	FieldFeatureAct.run(s, al, offer)
	assert_false(s.rift_gates.opened("rift_wind_den"), "돌이 없으면 아무 일도 없다")
	s.player.inventory.add("floor_stone_2", 1)
	FieldFeatureAct.run(s, al, offer)
	assert_true(s.rift_gates.opened("rift_wind_den"), "계층석을 바치면 그 길 균열이 조건 없이")
	assert_eq(s.player.inventory.count("floor_stone_2"), 0, "돌은 사라진다")
	assert_true(db.has_entry("essences", "regret_lord"), "계층정수")
	assert_true(JsonUtil.get_array(db.get_entry("monsters", "regret_lord"), "lord_drops").any(func(d: Variant) -> bool: return str((d as Dictionary)["item"]) == "floor_stone_2"), "군주가 계층석 2를 떨군다")
	s.detach()
