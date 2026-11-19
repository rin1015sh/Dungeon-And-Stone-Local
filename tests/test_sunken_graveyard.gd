extends TestCase
## 2층 균열 「가라앉은 묘역」(plans/expansion_f1_3_B §3): 여는 문(RiftGates) · 넋불 끝 종자의 시신 · 시신을 지면 구울이 꼬임 ·
## 비석에 묻으면 균열이 열리고 기사가 깨지 않음 · 5일 차가 넘으면 늦음 · 자연 개방 없음 · 수호자의 장례 촛불.

const DEAD := "f2_land_of_dead"
const RIFT := "rift_sunken_graveyard"


func _session(seed_value: int = 4, monsters: bool = false) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", DEAD)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func _feature(s: ExploreSession, id: String) -> Dictionary:
	for e: Dictionary in s.features.list:
		if str(e["id"]) == id and not bool(e.get("cleared", false)):
			return e
	return {}


func _action(e: Dictionary, aid: String) -> Dictionary:
	for a: Variant in JsonUtil.get_array(e["def"], "actions"):
		if str((a as Dictionary)["id"]) == aid:
			return a
	return {}


func _rift_portals(s: ExploreSession) -> Array:
	return s.map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("kind")) == "rift")


func test_floor_two_rift_opens_only_by_its_gate() -> void:
	var s := _session()
	assert_true(db.has_entry("rifts", RIFT), "균열 데이터")
	assert_false(RiftWatch.rifts_for(s).has(RIFT), "natural false — 자연 개방 · 무작위 고르기에서 빠진다")
	assert_true(s.rift_gates != null, "망자의 땅에 여는 문")
	assert_eq(_rift_portals(s).size(), 0, "처음엔 균열 포탈이 없다")


func test_squire_corpse_at_wisp_end_and_scent() -> void:
	var s := _session()
	var sq := _feature(s, "squire_corpse")
	assert_false(sq.is_empty(), "넋불 한 줄 끝에 종자의 시신")
	assert_false(s.parties.carries_corpse(s), "아직 시신을 지지 않았다")
	FieldFeatureAct.run(s, sq, _action(sq, "take"))
	assert_eq(s.player.inventory.count("wrapped_corpse"), 1, "수습한 시신을 얻는다")
	assert_true(s.parties.carries_corpse(s), "지고 있으면 시체 냄새(구울이 꼬인다)")


func test_burying_opens_the_rift_and_stops_the_knight() -> void:
	var s := _session(4, true)
	var stone := _feature(s, "grave_stone")
	assert_false(stone.is_empty(), "비석")
	FieldFeatureAct.run(s, stone, _action(stone, "bury"))
	assert_eq(_rift_portals(s).size(), 0, "시신이 없으면 묻지 못한다")
	s.player.inventory.add("wrapped_corpse", 1)
	FieldFeatureAct.run(s, stone, _action(stone, "bury"))
	var rp := _rift_portals(s)
	assert_eq(rp.size(), 1, "비석이 가라앉고 균열 포탈 하나")
	assert_eq(str(rp[0]["rift"]), RIFT)
	assert_true(Vector2((rp[0]["pos"] as Vector2i) - (stone["pos"] as Vector2i)).length() <= 6.0, "비석 자리 곁")
	assert_eq(s.player.inventory.count("wrapped_corpse"), 0, "시신은 묻혔다")
	s.clock.advance(24.0 * 5.0)
	s.grave.update(s)
	assert_false(s.monsters.groups.any(func(g: FieldMonsters.Group) -> bool: return g.monster_ids.has("death_knight")), "기사는 깨지 않는다")
	var ch := s.rifts.enter(s, rp[0])
	assert_true(ch != null and ch.rift_run != null, "들어가면 첫 챕터")
	assert_eq(ch.rift_run.chapters().size(), 3, "3챕터")


func test_too_late_after_day_four() -> void:
	var s := _session(5)
	var stone := _feature(s, "grave_stone")
	s.clock.advance(24.0 * 4.0 + 1.0)
	s.player.inventory.add("wrapped_corpse", 1)
	FieldFeatureAct.run(s, stone, _action(stone, "bury"))
	assert_eq(_rift_portals(s).size(), 0, "5일 차(기사가 깨는 날)부터는 열리지 않는다")


func test_guardian_candles_harden_the_knight() -> void:
	var party: Array[Actor] = [PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12})]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["sleepless_knight"])
	var foes := b.side_units(Combatant.SIDE_ENEMY)
	var knight: Combatant = foes.filter(func(u: Combatant) -> bool: return (u.actor as Monster).monster_id == "sleepless_knight")[0]
	var candles := foes.filter(func(u: Combatant) -> bool: return (u.actor as Monster).monster_id == "funeral_candle")
	assert_eq(candles.size(), 3, "장례 촛불 셋이 함께 나온다")
	assert_eq(knight.actor.statuses.stacks("knight_vigil"), 3, "촛불만큼 단단하다")
	(candles[0] as Combatant).actor.pool.set_current("hp", 0)
	(candles[0] as Combatant).actor.dead = true
	BossHooks.turn_end(b, knight, false)
	assert_eq(knight.actor.statuses.stacks("knight_vigil"), 2, "하나를 끄면 하나 준다")
	var def := (knight.actor as Monster).def
	assert_eq(Progression.first_kill_exp(db, def), 5, "6등급 + 상위 변이 = 5")
	assert_eq(Progression.first_kill_exp(db, db.get_entry("monsters", "funeral_candle")), 0, "촛불은 토큰 — 경험치 없음")
