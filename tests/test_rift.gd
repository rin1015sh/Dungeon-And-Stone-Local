extends TestCase
## G4 균열 공통(docs/PROMPT_FLOOR1_V2.md §8): 달력 · 자연/강제 개방 · 입장 · 챕터(연전·생존·수호자) · 탈출 · 드롭 · 변종.


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	return pc


func _session(seed_value: int = 3) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(seed_value))
	var s := ExploreSession.new(db, def, map, _pc(), GameClock.new(), Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = false
	s.start()
	return s


func test_calendar_chances() -> void:
	assert_eq(RiftCalendar.chance(db, 0), 0.0)
	assert_eq(RiftCalendar.chance(db, 1), 0.0, "직전 개방 후 2달 미만은 안 열린다")
	assert_true(RiftCalendar.chance(db, 4) > RiftCalendar.chance(db, 2))
	assert_eq(RiftCalendar.chance(db, 8), 1.0, "8달이면 확정")
	assert_eq(RiftCalendar.chance(db, 20), 1.0)
	var cal := RiftCalendar.new(db)
	cal.months_since_open = 8
	var at := cal.roll_month(db, Rng.new(1), 168.0)
	assert_true(at >= 48.0 and at <= 144.0, "3일 차 이후 ~ 폐쇄 하루 전 (%.1f)" % at)
	assert_eq(cal.months_since_open, 0)
	var opened_at := []
	for i in 400:
		var c := RiftCalendar.new(db)
		c.months_since_open = 0
		var m := 0
		while c.roll_month(db, Rng.new(i * 31 + m), 168.0) < 0.0:
			m += 1
		opened_at.append(m + 1)
	var four_five := opened_at.filter(func(x: int) -> bool: return x >= 3 and x <= 5).size()
	assert_true(four_five > 200, "대부분 4~5주기 사이(%d/400)" % four_five)
	assert_true(opened_at.all(func(x: int) -> bool: return x >= 3 and x <= 9), "최소 2달 쉬고 8달 안에")


func test_natural_open_after_day3() -> void:
	var s := _session()
	s.rifts.open_at = 60.0
	s.rifts.update(s, 1.0)
	assert_false(s.rifts.opened)
	s.clock.advance(61.0)
	s.rifts.update(s, 1.0)
	var rifts := s.map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("kind", "")) == "rift")
	assert_true(rifts.size() >= 3 and rifts.size() <= 5, "균열 포탈 3~5개 (%d)" % rifts.size())
	for p: Dictionary in rifts:
		assert_eq(s.map.tile_id_at(p["pos"]), "rift_portal")
	var picks := {}
	for i in 200:
		picks[s.rifts.pick_rift(s)] = true
	assert_eq(picks.size(), 4, "입장 때 4종 중 가중 무작위")


func test_force_open_with_stone_at_monument() -> void:
	var s := _session()
	var mon := s.map.landmarks[0]["pos"] as Vector2i
	for lm: Dictionary in s.map.landmarks:
		if str(lm["id"]) == "sage_monument":
			mon = lm["pos"]
	assert_false(s.rifts.try_offer(s, mon), "마석이 없으면 아무 일도 없다")
	s.player.inventory.add("magic_stone_beast_den", 1)
	assert_true(s.rifts.try_offer(s, mon))
	assert_eq(s.player.inventory.count("magic_stone_beast_den"), 0, "마석을 쓴다")
	var p: Dictionary = s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]
	assert_eq(str(p["rift"]), "rift_glacier_cave", "짐승의 소굴 마석 → 빙하굴")
	var before := s.map.portals.size()
	s.player.inventory.add("floor_stone_1", 1)
	assert_true(s.rifts.try_offer(s, mon), "계층석을 바친다")
	assert_eq(s.player.inventory.count("floor_stone_1"), 0, "계층석은 한 번 쓰면 사라진다")
	assert_eq(s.map.portals.size(), before + 1, "그 층 균열 하나가 열린다")


## 균열에 들어가 첫 챕터 세션을 돌려준다(세션이 RiftRun을 붙잡고, 균열은 세션을 약하게 가리킨다).
func _enter(s: ExploreSession, rift_id: String) -> ExploreSession:
	assert_true(s.rifts.force_open(s, rift_id, s.pos))
	var p: Dictionary = s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]
	var cs := s.rifts.enter(s, p)
	assert_true(s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift").is_empty(), "들어가면 포탈이 닫힌다")
	return cs


## 세션의 남은 조우를 차례로 이긴 것으로 처리한다(연전은 끝까지).
func _win_all(run: RiftRun) -> void:
	var s := run.session
	for g: FieldMonsters.Group in run.remaining.duplicate():
		var guard := 0
		while run.remaining.has(g) and guard < 20:
			guard += 1
			run.on_battle_end(s, g, Battle.RESULT_VICTORY)


func test_chapters_chain_guardian_and_escape() -> void:
	var s := _session()
	var outer_pos := s.pos
	var cs := _enter(s, "rift_blood_fortress")
	var run := cs.rift_run
	assert_eq(run.chapter, 0)
	assert_eq(run.session, cs)
	assert_eq(run.remaining.size(), 2, "1챕터 조우 2개")
	assert_eq(run.use_exit(cs), null, "조우를 남기면 출구가 잠겨 있다")
	_win_all(run)
	assert_eq(run.use_exit(cs), null, "뿔피리가 없으면 1챕터 출구가 막혀 있다")
	s.player.inventory.add("rift_horn", 1)
	cs = run.use_exit(cs)
	assert_eq(s.player.inventory.count("rift_horn"), 0, "뿔피리를 쓴다")
	assert_true(cs != null and run.chapter == 1)
	var waves: FieldMonsters.Group = run.remaining[0]
	assert_eq(int(waves.battle_rules["survive_rounds"]), 6, "도개교 6라운드 생존")
	_win_all(run)
	cs = run.use_exit(cs)
	var chain: FieldMonsters.Group = run.remaining[0]
	assert_eq(chain.waves.size(), 2, "외성벽 시가지 3연전(남은 2)")
	run.on_battle_end(cs, chain, Battle.RESULT_VICTORY)
	assert_true(run.remaining.has(chain) and chain.waves.size() == 1, "이기면 바로 다음 무리")
	_win_all(run)
	cs = run.use_exit(cs)
	_win_all(run)
	cs = run.use_exit(cs)
	assert_true(run.is_last_chapter())
	var guardian: FieldMonsters.Group = run.remaining.filter(func(g: FieldMonsters.Group) -> bool: return g.tag == "guardian")[0]
	assert_true(guardian.monster_ids.has(run.guardian_id()))
	_win_all(run)
	assert_true(run.guardian_down)
	var back := run.use_exit(cs)
	assert_eq(back, s, "탈출하면 바깥 층 세션")
	assert_eq(s.pos, outer_pos, "원래 자리")
	assert_true(run.finished)


func test_survival_objective_and_reinforce() -> void:
	var reg := ContentRegistries.new()
	var party: Array[Actor] = [_pc()]
	var b := Battle.from_encounter(db, reg, Rng.new(2), party, ["ghoul"])
	b.objective = {"survive_rounds": 3, "reinforce": {"monsters": ["ghoul"], "count": [1, 1]}}
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	(me.actor as Actor).stats.add_modifiers_from_data("test", [{"target": "dmg_taken:all", "percent": -1.0}])
	var enemies_before := b.side_units(Combatant.SIDE_ENEMY).size()
	var grew := false
	for t in 60:
		var c := b.next_turn()
		if c == null:
			break
		if c.side == Combatant.SIDE_PARTY:
			b.act(c, {"kind": "guard"})
			grew = grew or b.side_units(Combatant.SIDE_ENEMY).size() > enemies_before
		else:
			b.act(c, b.ai_action(c))
	assert_eq(b.result, Battle.RESULT_VICTORY, "3라운드 버티면 승리")
	assert_true(grew, "라운드마다 증원")
	assert_true(b.side_units(Combatant.SIDE_ENEMY).size() > 0, "적이 남아 있어도 끝난다")


func test_guardian_drops_variant_and_rift_essence() -> void:
	var stones := 0
	var s := _session()
	for i in 200:
		s.rng = Rng.new(i + 7)
		var run := RiftRun.new(s, "rift_iron_tomb")
		run._guardian_drops(s)
	stones = s.player.inventory.count("rift_stone")
	assert_true(stones > 100 and stones < 165, "균열석 66%% 근처 (%d/200)" % stones)
	var v := 0
	for i in 2000:
		s.rng = Rng.new(i + 100)
		if RiftRun.new(s, "rift_glacier_cave").variant:
			v += 1
	assert_true(v > 25 and v < 100, "변종 수호자 3%% 근처 (%d/2000)" % v)
	assert_false(RiftRun.new(s, "rift_green_mine").variant, "녹색 탄광은 변종 없음")
	var g := db.get_entry("monsters", "goblin")
	assert_near(EssenceDrop.drop_chance(db, g, true), EssenceDrop.drop_chance(db, g) * float(db.bal("essence.rift_mult")), 0.0001, "균열 안 정수 × rift_mult")
	var w := db.get_entry("monsters", "blater")
	assert_near(EssenceDrop.drop_chance(db, w, true), 0.33, 0.0001, "수호자 정수 33%")
	var p := Progression.new()
	p.record_kill(db, "blater")
	assert_eq(p.record_kill(db, "blater"), int(db.prog("exp.guardian_bonus")), "수호자 +3 반복")


func test_field_effect_and_on_enter() -> void:
	var s := _session()
	var cs := _enter(s, "rift_glacier_cave")
	var run := cs.rift_run
	_win_all(run)
	cs = run.use_exit(cs)
	_win_all(run)
	var hp := s.player.pool.get_current("hp")
	cs = run.use_exit(cs)
	assert_true(s.player.statuses.has("hypothermia"), "3챕터 저체온증")
	assert_true(s.player.pool.get_current("hp") < hp, "폭포·낙하 피해")
	_win_all(run)
	cs = run.use_exit(cs)
	assert_true(s.player.statuses.has("hypothermia"), "4챕터도 저체온증")
	_win_all(run)
	cs = run.use_exit(cs)
	assert_eq(cs, s)
	assert_false(s.player.statuses.has("hypothermia"), "나오면 풀린다")
