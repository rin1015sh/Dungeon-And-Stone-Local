extends TestCase
## 전투 개선 2차(CB4 · CB5): 역할이 섞인 무리(지역 escort) · 정예 · 졸개 행동(웨어울프 변신 한 번 · 여왕 소환 상한 ·
## 코볼트 도주 · 곰 포효 · 불카르 숨기) · 데스나이트 맹세.


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	return pc


func _battle(monsters: Array, seed_value: int = 3) -> Battle:
	var party: Array[Actor] = [_pc()]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, monsters)


func _region(floor_id: String, rid: String) -> Dictionary:
	for r: Variant in JsonUtil.get_array(db.get_entry("floors", floor_id), "regions"):
		if r is Dictionary and JsonUtil.get_str(r, "id") == rid:
			return r
	return {}


## 2층 무리 조합: 대장에 졸개가 붙는다(앞에서 막는 쪽 + 뒤에서 쏘는 쪽 등).
func test_escorts_mix_roles() -> void:
	var want := {["f2_rock_desert", "f2r_cave", "kobold_shield"]: "kobold_slinger",
		["f2_land_of_dead", "f2d_ruins", "skeleton_warrior"]: "skeleton_archer",
		["f2_land_of_dead", "f2d_ruins", "skeleton_mage"]: "skeleton",
		["f2_goblin_forest", "f2g_village", "goblin_swordsman"]: "goblin_archer",
		["f2_beast_den", "f2b_outer", "giant_blade_wolf"]: "blade_wolf"}
	for k: Array in want:
		var esc := JsonUtil.get_dict(JsonUtil.get_dict(_region(k[0], k[1]), "escort"), k[2])
		assert_eq(JsonUtil.get_str(esc, "monster"), want[k], "%s %s 졸개" % [k[1], k[2]])
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f2_rock_desert")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(2)), pc, GameClock.new(), Rng.new(3), reg.effects)
	s.start()
	var g := s.monsters.spawn_group(_region("f2_rock_desert", "f2r_cave"), s.pos, s.pos + Vector2i(4, 0), "kobold_shield")
	assert_true(g != null and g.monster_ids.has("kobold_slinger"), "방패병 무리에 투석병이 섞인다: %s" % str(g.monster_ids if g != null else []))
	s.detach()


## 웨어울프 변신(회복 15%)은 한 판에 한 번 — 절반 아래에서 매 차례 회복하던 것.
func test_werewolf_changes_once() -> void:
	assert_true(JsonUtil.get_int(db.get_entry("skills", "werewolf_change"), "cooldown") >= 20, "몬스터판은 한 번")
	assert_true(JsonUtil.get_int(db.get_entry("skills", "ess_werewolf_change"), "cooldown") < 20, "정수판은 그대로")
	var b := _battle(["werewolf"])
	var w := b.side_units(Combatant.SIDE_ENEMY)[0]
	w.acted = 1
	w.actor.pool.set_current("hp", w.actor.pool.get_max("hp") * 0.4)
	assert_eq(b.ai_action(w)["skill"], "werewolf_change", "절반 아래면 변신")
	w.cooldowns["werewolf_change"] = JsonUtil.get_int(db.get_entry("skills", "werewolf_change"), "cooldown")
	assert_true(b.ai_action(w)["skill"] != "werewolf_change", "다시는 변신하지 않는다")


## 여왕은 두더지가 넉넉하면 더 부르지 않는다(무한 소환 방지).
func test_queen_stops_calling_with_many_moles() -> void:
	var b := _battle(["mole_queen", "wall_mole", "wall_mole", "wall_mole", "wall_mole"])
	var q := b.side_units(Combatant.SIDE_ENEMY)[0]
	q.acted = 1
	for i in 30:
		assert_true(b.ai_action(q)["skill"] != "mole_queen_call", "넷이 서 있으면 부르지 않는다")
	var b2 := _battle(["mole_queen"])
	var q2 := b2.side_units(Combatant.SIDE_ENEMY)[0]
	q2.acted = 1
	var called := false
	for i in 40:
		called = called or b2.ai_action(q2)["skill"] == "mole_queen_call"
	assert_true(called, "혼자면 부른다")


func test_cowards_and_cornered_beasts() -> void:
	for m: String in ["kobold", "kobold_slinger"]:
		var b := _battle([m])
		var k := b.side_units(Combatant.SIDE_ENEMY)[0]
		k.acted = 1
		k.actor.pool.set_current("hp", k.actor.pool.get_max("hp") * 0.2)
		assert_eq(b.ai_action(k)["skill"], "flee", "%s: 궁지에 몰리면 달아난다" % m)
	var bb := _battle(["moon_rock_bear"])
	var bear := bb.side_units(Combatant.SIDE_ENEMY)[0]
	bear.acted = 1
	bear.actor.pool.set_current("hp", bear.actor.pool.get_max("hp") * 0.3)
	var roared := false
	for i in 30:
		roared = roared or bb.ai_action(bear)["skill"] == "giant_menacing_roar"
	assert_true(roared, "곰은 궁지에 몰리면 포효한다")
	var bk := _battle(["bulkar"])
	var bul := bk.side_units(Combatant.SIDE_ENEMY)[0]
	bul.acted = 1
	bul.actor.pool.set_current("hp", bul.actor.pool.get_max("hp") * 0.3)
	var hid := false
	for i in 30:
		hid = hid or bk.ai_action(bul)["skill"] == "rat_hide"
	assert_true(hid, "불카르는 절반 아래면 바위 그늘로 숨는다")


## 데스나이트는 4라운드마다 망자의 맹세(가진 스킬 — 패턴이 없어 쓰지 않던 것).
func test_death_knight_oath_every_four_rounds() -> void:
	var b := _battle(["death_knight"])
	var dk := b.side_units(Combatant.SIDE_ENEMY)[0]
	assert_true(BossHooks.pattern(b, dk) != null, "범용 수호자 패턴")
	var n := b.side_units(Combatant.SIDE_ENEMY).size()
	for r in 4:
		dk.memo["round"] = int(dk.memo["round"]) + 1
		BossHooks.pattern(b, dk).on_round_end(b, dk, false)
	assert_true(b.side_units(Combatant.SIDE_ENEMY).size() > n, "4라운드째에 병사를 부른다")


## 1층 무리 섞기(CB9 — 사용자 "3일 차부터"): 1 · 2일 차엔 팔마다 한 종, 3일 차가 되면 있던 무리 절반쯤이 다른 종 졸개를 데려오고
## 그 뒤로 새로 생기는 무리에도 붙는다.
func test_floor1_mixes_from_day3() -> void:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8})
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), pc, GameClock.new(), Rng.new(4), reg.effects)
	s.start()
	var mixed := func() -> int:
		var n := 0
		for g in s.monsters.groups:
			if g.boss.is_empty() and g.region.begins_with("f1_") and g.monster_ids.size() > 1 and g.monster_ids.any(func(m: String) -> bool: return m != g.monster_ids[0]):
				n += 1
		return n
	assert_eq(mixed.call(), 0, "처음엔 한 종씩")
	s.monsters.update(Kinematics.center_of(s.pos), 0.0, 30.0, false)
	assert_eq(mixed.call(), 0, "2일 차도 한 종씩")
	var total := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.region.begins_with("f1_")).size()  # 약탈자 · 탐험가 무리 빼고
	s.monsters.update(Kinematics.center_of(s.pos), 0.0, 49.0, false)
	var m: int = mixed.call()
	assert_true(m > total * 0.25 and m < total * 0.75, "3일 차 — 있던 무리 절반쯤이 섞인다 %d / %d" % [m, total])
	s.monsters.update(Kinematics.center_of(s.pos), 0.0, 60.0, false)
	assert_eq(mixed.call(), m, "한 번만")
	var north := {}
	for r: Variant in JsonUtil.get_array(def, "regions"):
		if JsonUtil.get_str(r, "id") == "f1_north":
			north = r
	var g := s.monsters.spawn_group(north, s.pos, Vector2i(-1, -1), "goblin")
	assert_true(g != null and g.monster_ids.has("blade_wolf"), "3일 차 뒤 새 고블린 무리는 늑대를 데리고 다닌다")
	s.detach()


func _floor_session(floor_id: String) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", floor_id)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(2)), pc, GameClock.new(), Rng.new(3), reg.effects)
	s.monsters_enabled = false
	s.start()
	return s


func _at_hour(s: ExploreSession, hour: float) -> void:
	for i in 48:
		if absf(s.clock.hour_of_day() - hour) < 0.6:
			return
		s.clock.advance(0.5)


func _fight(s: ExploreSession, ids: Array) -> Battle:
	var party: Array[Actor] = [s.player]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(5), party, ids)


## 층별 전투 기믹(CB10): 망자의 밤 · 흥분 · 모래바람 · 좁은 협곡.
func test_floor_battle_gimmicks() -> void:
	var dead := _floor_session("f2_land_of_dead")
	_at_hour(dead, 21.0)
	var b := _fight(dead, ["skeleton", "banshee"])
	BattleFloor.apply(b, dead, null)
	for u in b.side_units(Combatant.SIDE_ENEMY):
		assert_true(u.actor.statuses.has("grave_night"), "밤엔 망자가 세다: %s" % u.label())
	assert_false(b.side_units(Combatant.SIDE_PARTY)[0].actor.statuses.has("grave_night"))
	_at_hour(dead, 12.0)
	var b2 := _fight(dead, ["skeleton"])
	BattleFloor.apply(b2, dead, null)
	assert_false(b2.side_units(Combatant.SIDE_ENEMY)[0].actor.statuses.has("grave_night"), "낮엔 없다")
	dead.detach()
	var forest := _floor_session("f2_goblin_forest")
	var g := FieldMonsters.Group.new()
	g.alert_until = forest.clock.total_hours + 1.0
	var b3 := _fight(forest, ["goblin"])
	BattleFloor.apply(b3, forest, g)
	assert_true(b3.side_units(Combatant.SIDE_ENEMY)[0].actor.statuses.has("roused"), "경보로 몰려온 무리는 흥분")
	g.alert_until = -1.0
	var b4 := _fight(forest, ["goblin"])
	BattleFloor.apply(b4, forest, g)
	assert_false(b4.side_units(Combatant.SIDE_ENEMY)[0].actor.statuses.has("roused"), "들키지 않았으면 없다")
	forest.detach()
	var desert := _floor_session("f2_rock_desert")
	_at_hour(desert, 14.0)
	var road := Vector2i(-1, -1)
	for i in desert.map.tiles.size():
		var p := desert.map.pos_of(i)
		if desert.map.zone_at(p) == "f2r_road" and desert.map.is_walkable(p):
			road = p
			break
	desert.relocate(road)
	var b5 := _fight(desert, ["kobold"])
	BattleFloor.apply(b5, desert, null)
	for u in b5.units:
		assert_true(u.actor.statuses.has("sandblown"), "모래 폭풍 속엔 양쪽 다: %s" % u.label())
	desert.detach()
	var den := _floor_session("f2_beast_den")
	assert_eq(BattleFloor.cap(den), 3, "좁은 협곡 — 적 셋까지")
	assert_eq(BattleFloor.merge_cap(2, 3), 2)
	assert_eq(BattleFloor.merge_cap(0, 3), 3)
	den.detach()
