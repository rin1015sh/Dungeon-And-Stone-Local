extends TestCase
## 2층 균열 「꺼진 태양의 신전」(plans/expansion_f1_3_B §4): 모래 바다 한가운데 첨탑 끝 · 오후 모래 폭풍(13~16시)에만 ·
## 횃불이 있어야 · 불을 붙이면 균열(RiftGates) · 7일 차가 넘으면 늦음 · 자연 개방 없음 · 거상의 열기 게이지와 태양의 가슴.

const DESERT := "f2_rock_desert"
const RIFT := "rift_sun_temple"


func _session(seed_value: int = 2) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", DESERT)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = false
	s.start()
	return s


func _spire(s: ExploreSession) -> Dictionary:
	for e: Dictionary in s.features.list:
		if str(e["id"]) == "sun_spire":
			return e
	return {}


func _light(e: Dictionary) -> Dictionary:
	for a: Variant in JsonUtil.get_array(e["def"], "actions"):
		if str((a as Dictionary)["id"]) == "light":
			return a
	return {}


func _rift_portals(s: ExploreSession) -> Array:
	return s.map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("kind")) == "rift")


func _to_hour(s: ExploreSession, h: float) -> void:
	var now := s.clock.hour_of_day()
	s.clock.advance(fposmod(h - now, 24.0))


func test_spire_opens_only_in_the_storm_with_fire() -> void:
	var s := _session()
	assert_false(RiftWatch.rifts_for(s).has(RIFT), "natural false")
	var sp := _spire(s)
	assert_false(sp.is_empty(), "모래 바다에 첨탑 끝")
	var marks: Dictionary = s.map.anchors["marks"]
	assert_true(Vector2(sp["pos"] - (marks["sea_mid"] as Vector2i)).length() <= 10.0, "바다 한가운데 곁")
	_to_hour(s, 10.0)
	s.player.inventory.add("torch", 1)
	FieldFeatureAct.run(s, sp, _light(sp))
	assert_eq(_rift_portals(s).size(), 0, "폭풍 밖에서는 모래에 덮여 있다")
	s.player.inventory.remove("torch", s.player.inventory.count("torch"))
	_to_hour(s, 14.0)
	FieldFeatureAct.run(s, sp, _light(sp))
	assert_eq(_rift_portals(s).size(), 0, "불씨가 없으면 못 붙인다")
	s.player.inventory.add("torch", 1)
	FieldFeatureAct.run(s, sp, _light(sp))
	var rp := _rift_portals(s)
	assert_eq(rp.size(), 1, "폭풍 속에서 횃불로 불을 붙이면 균열")
	assert_eq(str(rp[0]["rift"]), RIFT)
	assert_eq(s.player.inventory.count("torch"), 0, "횃불은 화로에 들어갔다")
	var ch := s.rifts.enter(s, rp[0])
	assert_true(ch != null and ch.rift_run != null and ch.rift_run.chapters().size() == 3, "3챕터")


func test_too_late_after_day_seven() -> void:
	var s := _session(3)
	s.clock.advance(24.0 * 7.0)
	_to_hour(s, 14.0)
	s.player.inventory.add("torch", 1)
	var sp := _spire(s)
	FieldFeatureAct.run(s, sp, _light(sp))
	assert_eq(_rift_portals(s).size(), 0, "8일 차부터는 열리지 않는다")
	s.detach()


func test_colossus_heat_and_sun_heart() -> void:
	var party: Array[Actor] = [PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12})]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["sand_colossus"])
	var boss: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	var me: Actor = party[0]
	BossHooks.turn_end(b, boss, false)
	BossHooks.turn_end(b, boss, false)
	assert_eq(int(Meters.value(me, "sun_heat")), 24, "바퀴마다 열기 12")
	assert_eq(str(MonsterAi.choose(b, boss)["skill"]), "colossus_sun_heart", "1페이즈 — 태양의 가슴")
	BossHooks.use_skill(b, boss, "colossus_sun_heart")
	var hp := me.pool.get_current("hp")
	BattleDelayed.tick(b, boss)
	assert_eq(int(round(hp - me.pool.get_current("hp"))), 72, "게이지 ×3 피해")
	assert_eq(int(Meters.value(me, "sun_heat")), 0, "게이지는 0으로")
	assert_eq(Progression.first_kill_exp(db, (boss.actor as Monster).def), 4, "6등급 수호자 = 4")


func test_giant_sinks_then_rises() -> void:
	var party: Array[Actor] = [PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12})]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["ancient_stone_giant"])
	var g: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	assert_eq(Progression.first_kill_exp(db, (g.actor as Monster).def), 5, "6등급 + 상위 변이 = 5")
	g.actor.statuses.apply("half_buried")
	assert_eq(str(MonsterAi.choose(b, g)["skill"]), "giant_rise", "잠겼으면 다음 차례 솟구친다")
