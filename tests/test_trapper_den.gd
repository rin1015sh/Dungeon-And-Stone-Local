extends TestCase
## 2층 균열 「덫꾼의 굴」(plans/expansion_f1_3_B §5): 덫 밭 셋 한가운데 덫에 걸린 사냥꾼 · 매듭 끈 셋을 다 풀면 균열(RiftGates) ·
## 7일 차가 넘으면 늦음 · 자연 개방 없음 · 1장 숨은 곰덫 · 덫왕의 덫 줄(방어로 받는다) · 증원 넷까지.

const FOREST := "f2_goblin_forest"
const RIFT := "rift_trapper_den"


func _session(seed_value: int = 2) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", FOREST)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = false
	s.start()
	return s


func _knots(s: ExploreSession) -> Array:
	return s.features.list.filter(func(e: Dictionary) -> bool: return str(e["id"]) == "trapper_knot")


func _untie(e: Dictionary) -> Dictionary:
	for a: Variant in JsonUtil.get_array(e["def"], "actions"):
		if str((a as Dictionary)["id"]) == "untie":
			return a
	return {}


func _rift_portals(s: ExploreSession) -> Array:
	return s.map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("kind")) == "rift")


func test_three_knots_open_the_den() -> void:
	var s := _session()
	assert_false(RiftWatch.rifts_for(s).has(RIFT), "natural false")
	var knots := _knots(s)
	assert_eq(knots.size(), 3, "덫 밭마다 매듭 하나")
	var marks: Dictionary = s.map.anchors["marks"]
	for k: Dictionary in knots:
		assert_true(["trap1", "trap2", "trap3"].any(func(m: String) -> bool: return Vector2(k["pos"] - (marks[m] as Vector2i)).length() <= 6.0), "덫 밭 한가운데")
	for i in 2:
		FieldFeatureAct.run(s, knots[i], _untie(knots[i]))
	assert_eq(_rift_portals(s).size(), 0, "둘로는 열리지 않는다")
	FieldFeatureAct.run(s, knots[2], _untie(knots[2]))
	var rp := _rift_portals(s)
	assert_eq(rp.size(), 1, "셋을 다 풀면 덮은 구덩이")
	assert_eq(str(rp[0]["rift"]), RIFT)
	var ch := s.rifts.enter(s, rp[0])
	assert_true(ch != null and ch.rift_run != null and ch.rift_run.chapters().size() == 3, "3챕터")
	assert_eq((ch.map.anchors.get("hazards", []) as Array).size(), 5, "1장 숨은 곰덫 묶음 다섯")
	assert_true(ch.rift_run.hazards.at.size() >= 10, "묶음마다 여러 칸")


func test_too_late_after_day_seven() -> void:
	var s := _session(3)
	s.clock.advance(24.0 * 7.0 + 1.0)
	for k: Dictionary in _knots(s):
		FieldFeatureAct.run(s, k, _untie(k))
	assert_eq(_rift_portals(s).size(), 0, "8일 차부터는 열리지 않는다")
	s.detach()


func test_trap_king_lines_and_calls() -> void:
	var party: Array[Actor] = [PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12})]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["goblin_trap_king"])
	var king: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	assert_eq(str(MonsterAi.choose(b, king)["skill"]), "trap_line", "1페이즈 — 덫 줄")
	BossHooks.use_skill(b, king, "trap_line")
	var me: Actor = party[0]
	var hp := me.pool.get_current("hp")
	BattleDelayed.tick(b, king)
	assert_true(me.pool.get_current("hp") < hp, "다음 차례 그 줄이 덫에 걸린다")
	for i in 12:
		BossHooks.turn_end(b, king, false)
	assert_eq(int(king.memo.get("every_0", 0)), 2, "고블린 부르기는 두 번(넷)까지")
	assert_eq(Progression.first_kill_exp(db, (king.actor as Monster).def), 4, "6등급 수호자 = 4")
	assert_eq(Progression.first_kill_exp(db, db.get_entry("monsters", "hobgoblin_chief")), 5, "6등급 + 상위 변이 = 5")
