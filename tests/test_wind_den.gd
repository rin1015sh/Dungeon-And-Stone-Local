extends TestCase
## 2층 균열 「울부짖는 바람굴」(plans/expansion_f1_3_B §2): 갈림길 바른 갈래 끝 막힌 바람 틈 셋(RouteForks right_feature) ·
## 뚫으면 가장 가까운 짐승 무리 하나가 쫓아온다 · 셋 다 뚫으면 균열(RiftGates) · 7일 차가 넘으면 늦음 · 자연 개방 없음 ·
## 늑대왕(표식 · 부르는 울음 여섯까지 · 달을 향한 고개 — 끊지 못하면 두 번 행동).

const DEN := "f2_beast_den"
const RIFT := "rift_wind_den"


func _session(seed_value: int = 3, monsters: bool = false) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", DEN)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func _gaps(s: ExploreSession) -> Array:
	return s.features.list.filter(func(e: Dictionary) -> bool: return str(e["id"]) == "wind_gap" and not bool(e.get("cleared", false)))


func _action(e: Dictionary, aid: String) -> Dictionary:
	for a: Variant in JsonUtil.get_array(e["def"], "actions"):
		if str((a as Dictionary)["id"]) == aid:
			return a
	return {}


func _rift_portals(s: ExploreSession) -> Array:
	return s.map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("kind")) == "rift")


func test_gaps_sit_on_the_right_branches() -> void:
	var s := _session()
	assert_true(db.has_entry("rifts", RIFT), "균열 데이터")
	assert_false(RiftWatch.rifts_for(s).has(RIFT), "natural false")
	assert_true(s.rift_gates != null, "짐승의 소굴에 여는 문")
	assert_eq(_rift_portals(s).size(), 0)
	var gaps := _gaps(s)
	assert_eq(gaps.size(), 3, "갈림길마다 바람 틈 하나")
	var marks: Dictionary = s.map.anchors["marks"]
	var forks := JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "forks")
	for i in forks.size():
		var br := JsonUtil.get_array(forks[i], "branches")
		var right: Vector2i = marks[JsonUtil.get_str(br[s.forks.right[i]], "block")]
		assert_true(gaps.any(func(e: Dictionary) -> bool: return Vector2(e["pos"] - right).length() <= 3.0), "갈림길 %d: 바른 갈래 끝" % i)
		assert_true(s.map.is_walkable(right), "틈이 길을 막지 않는다")
	s.detach()


func test_three_gaps_open_the_rift_and_wake_one_pack() -> void:
	var s := _session(3, true)
	var gaps := _gaps(s)
	var g0: Dictionary = gaps[0]
	for g: FieldMonsters.Group in s.monsters.groups:
		g.alert_until = 0.0
	FieldFeatureAct.run(s, g0, _action(g0, "clear"))
	var chasing := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.alert_until > s.clock.total_hours)
	assert_true(chasing.size() <= 1, "가장 가까운 무리 하나만 냄새를 맡는다")
	assert_eq(s.rift_gates.count("wind_den"), 1)
	assert_eq(_rift_portals(s).size(), 0, "하나로는 열리지 않는다")
	for i in [1, 2]:
		var g: Dictionary = gaps[i]
		FieldFeatureAct.run(s, g, _action(g, "clear"))
	var rp := _rift_portals(s)
	assert_eq(rp.size(), 1, "셋을 다 뚫으면 균열 포탈")
	assert_eq(str(rp[0]["rift"]), RIFT)
	var ch := s.rifts.enter(s, rp[0])
	assert_true(ch != null and ch.rift_run != null and ch.rift_run.chapters().size() == 3, "3챕터")
	assert_eq(ch.rift_run.hidden.at.size(), 1, "1장 히든 피스")


func test_too_late_after_day_seven() -> void:
	var s := _session(4)
	s.clock.advance(24.0 * 7.0 + 1.0)
	for g: Dictionary in _gaps(s):
		FieldFeatureAct.run(s, g, _action(g, "clear"))
	assert_eq(_rift_portals(s).size(), 0, "8일 차부터는 열리지 않는다")
	s.detach()


func test_wolf_king_howls_marks_and_moon() -> void:
	var party: Array[Actor] = [PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12})]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["wolf_king"])
	var king: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	for i in 15:
		BossHooks.turn_end(b, king, false)
	var wolves := b.side_units(Combatant.SIDE_ENEMY).size() - 1
	assert_eq(int(king.memo.get("every_0", 0)), 3, "부르는 울음은 세 번까지")
	assert_true(wolves >= 4 and wolves <= 6, "늑대 여섯까지(적 자리 수만큼): %d" % wolves)
	var act := MonsterAi.choose(b, king)
	assert_eq(str(act["skill"]), "wolf_king_mark", "먼저 표식")
	(act["target"] as Combatant).actor.statuses.apply("marked")
	king.cooldowns["wolf_king_mark"] = 3
	var next := MonsterAi.choose(b, king)
	assert_eq(str(next["skill"]), "wolf_king_maul", "표식이 서면 목덜미 물기")
	assert_true((next["target"] as Combatant).actor.statuses.has("marked"), "표식 대상을")
	BossHooks.use_skill(b, king, "wolf_king_moon")
	assert_false(king.actor.statuses.has("moon_frenzy"), "한 차례 뒤에")
	BattleDelayed.tick(b, king)
	assert_true(king.actor.statuses.has("moon_frenzy"), "끊지 못하면 달빛 광분")
	assert_true(BossHooks.pattern(b, king).wants_extra_action(b, king), "두 번 움직인다")
	assert_eq(Progression.first_kill_exp(db, (king.actor as Monster).def), 4, "6등급 수호자 = 4")
	assert_eq(Progression.first_kill_exp(db, db.get_entry("monsters", "alpha_werewolf")), 5, "6등급 + 상위 변이 = 5")


## 2차(2026-11-20): 균열 몬스터 셋 · 정수 다섯.
func test_second_pass_monsters_and_essences() -> void:
	var exp := {"gale_wolf": 3, "silvermane_wolf": 3, "bone_gnawer": 2, "alpha_werewolf": 5, "wolf_king": 4}
	for id: String in exp:
		assert_eq(Progression.first_kill_exp(db, db.get_entry("monsters", id)), int(exp[id]), "%s 첫 처치" % id)
		assert_true(db.has_entry("essences", id), "%s 정수" % id)
	var party: Array[Actor] = [PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12})]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(5), party, ["gale_wolf", "silvermane_wolf"])
	var foes := b.side_units(Combatant.SIDE_ENEMY)
	var gale: Combatant = foes.filter(func(u: Combatant) -> bool: return (u.actor as Monster).monster_id == "gale_wolf")[0]
	var mane: Combatant = foes.filter(func(u: Combatant) -> bool: return (u.actor as Monster).monster_id == "silvermane_wolf")[0]
	assert_eq(str(MonsterAi.choose(b, gale)["skill"]), "gale_ride", "질풍 늑대는 첫 차례에 바람을 탄다")
	gale.actor.pool.set_current("hp", gale.actor.pool.get_max("hp") * 0.3)
	var act := MonsterAi.choose(b, mane)
	assert_eq(str(act["skill"]), "silvermane_guard", "다친 늑대를 감싼다")
	assert_eq(act["target"], gale)
