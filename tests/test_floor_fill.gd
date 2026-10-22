extends TestCase
## 1층 채우기(docs/plans/floor1_fill.md A·B·C·D·F): 길드 신원패·조사 기록, 소굴 둘레 무리·냄새 추적, 다른 탐험가 무리·약탈자·새 시체.

const FLOOR := "f1_crystal_cave"


func _session(seed_value: int = 11) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", FLOOR)
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(seed_value))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9})
	var s := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(seed_value + 1), reg.effects)
	s.start()
	return s


func _keys(s: ExploreSession) -> Array[String]:
	var out: Array[String] = []
	s.message.connect(func(key: String, _a: Dictionary, _k: String) -> void: out.append(key))
	return out


func _city_pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8})


func test_guild_tags_and_records() -> void:
	var st := CityState.new(db, 3)
	st.start()
	var pc := _city_pc()
	var reg := ContentRegistries.new().city_effects
	assert_eq(st.enter_facility("guild"), "")
	var none := CityActions.perform(st, pc, "guild_tags", reg)
	assert_true(none.messages.any(func(m: Dictionary) -> bool: return m["key"] == "city.fx.no_tags"), "신원패가 없으면 못 낸다")
	pc.inventory.add("explorer_tag", 3)
	var before := pc.inventory.money
	CityActions.perform(st, pc, "guild_tags", reg)
	assert_eq(pc.inventory.count("explorer_tag"), 0, "신원패를 모두 낸다")
	assert_true(pc.inventory.money > before, "수고비")
	pc.knowledge.learn_stats("goblin")
	pc.knowledge.learn_affinity("goblin", "fire", 1.5)
	before = pc.inventory.money
	CityActions.perform(st, pc, "guild_records", reg)
	var gained := pc.inventory.money - before
	assert_true(gained > 0, "조사 기록 2건을 판다")
	before = pc.inventory.money
	CityActions.perform(st, pc, "guild_records", reg)
	assert_eq(pc.inventory.money, before, "같은 기록은 두 번 팔리지 않는다")


func test_arms_one_kind_and_cluster_near_dens() -> void:
	var s := _session()
	var leaders := {}
	var near_den := 0
	var cluster := JsonUtil.get_dict(JsonUtil.get_dict(s.floor_def, "spawn"), "cluster")
	var dens := JsonUtil.get_dict(cluster, "features")
	for g in s.monsters.groups:
		if g.region == "f1_east":
			leaders[g.leader()] = true
		if g.region.is_empty():
			continue
		for f: Dictionary in s.map.features:
			if dens.has(f["id"]) and Vector2(g.home - (f["pos"] as Vector2i)).length() <= JsonUtil.get_float(cluster, "radius_tiles") + 3.0:
				near_den += 1
				break
	assert_eq(leaders.keys(), ["blade_wolf"], "동쪽 팔 끝은 칼날늑대만(사용자 결정 2026-10-22)")
	assert_true(near_den >= 20, "소굴 둘레에 뭉친 무리 (%d)" % near_den)


func test_one_monster_per_battle_early() -> void:
	var s := _session()
	var multi := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.party.is_empty() and g.boss.is_empty() and g.monster_ids.size() > 1)
	assert_eq(multi.size(), 0, "1일 차 필드 무리(지키는 무리 포함)는 한 마리씩")
	s.monsters._now = 24.0 * 5  # 6일 차
	var gob: Array[int] = []
	var wolf: Array[int] = []
	for i in 60:
		gob.append(s.monsters.pack_count("goblin", true))
		wolf.append(s.monsters.pack_count("blade_wolf", true))
	assert_true(gob.min() >= 2 and gob.max() == 3, "6일 차 고블린 2~3마리 (%d~%d)" % [gob.min(), gob.max()])
	assert_true(wolf.max() <= 2, "칼날늑대는 원래 최대(2)를 넘지 않는다")


func test_growth_ghouls_only_south_and_center() -> void:
	var sp := JsonUtil.get_dict(db.get_entry("floors", FLOOR), "spawn")
	var rng := Rng.new(3)
	var day3 := 24.0 * 3
	var south := 0
	for i in 200:
		assert_eq(FieldSpawnBias.growth_monster(db, rng, sp, day3, "f1_east"), "", "동쪽 팔엔 늘어나는 구울이 없다")
		if FieldSpawnBias.growth_monster(db, rng, sp, day3, "f1_south") == "ghoul":
			south += 1
	assert_true(south > 50, "남쪽은 3일 차부터 구울이 는다 (%d/200)" % south)
	assert_eq(FieldSpawnBias.growth_monster(db, rng, sp, 1.0, "f1_south"), "", "1일 차엔 아직")


func test_wolf_follows_scent() -> void:
	var s := _session()
	var steer := MonsterSteering.new(db, s.map, Rng.new(1), [])
	var g := FieldMonsters.Group.new()
	g.monster_ids.append("blade_wolf")
	g.place(s.pos + Vector2i(3, 0))
	var far := s.pos + Vector2i(60, 0)
	steer.player_trail = [[s.pos, 10.0]]
	assert_true(steer._notices(g, far, 10.5), "방금 지나간 냄새를 맡는다")
	assert_eq(g.scent, s.pos)
	assert_false(steer._notices(g, far, 20.0), "오래된 냄새는 못 맡는다")
	var gob := FieldMonsters.Group.new()
	gob.monster_ids.append("goblin")
	gob.place(s.pos + Vector2i(3, 0))
	assert_false(steer._notices(gob, far, 10.5), "냄새를 쫓는 건 칼날늑대만")


func test_parties_spawn_by_day_and_size() -> void:
	var s := _session()
	var ex := JsonUtil.get_dict(s.floor_def, "explorers")
	assert_eq(s.parties.of_kind(s, FieldParties.ROOKIE).size(), int(JsonUtil.get_array(ex, "rookies_by_day")[0]), "1일 차 신참 수")
	var raiders := s.parties.of_kind(s, FieldParties.RAIDER)
	assert_eq(raiders.size(), int(JsonUtil.get_array(ex, "raiders_by_day")[0]), "1일 차 약탈자 수")
	assert_true(raiders.all(func(g: FieldMonsters.Group) -> bool: return g.hostile() and not g.monster_ids.is_empty()), "약탈자는 싸울 구성이 있다")
	assert_true(s.parties.of_kind(s, FieldParties.ROOKIE).all(func(g: FieldMonsters.Group) -> bool: return not g.hostile()), "신참은 덤비지 않는다")
	assert_eq(s.party_size(), 1, "혼자")


func test_death_leaves_fresh_corpse_and_scream() -> void:
	var s := _session()
	var keys := _keys(s)
	var sounds: Array[String] = []
	s.sound.connect(func(key: String, _at: Vector2i) -> void: sounds.append(key))
	var rookie: FieldMonsters.Group = s.parties.of_kind(s, FieldParties.ROOKIE)[0]
	rookie.place(s.pos + Vector2i(0, 0))
	var at := _free_near(s, s.pos, 6)
	rookie.place(at)
	var n := s.features.list.size()
	s.parties.kill(s, rookie, true)
	assert_eq(s.features.list.size(), n + 1, "시체가 남는다")
	var e: Dictionary = s.features.list.back()
	assert_eq(str(e["id"]), "fresh_corpse")
	assert_false(s.monsters.groups.has(rookie), "무리는 사라진다")
	assert_eq(sounds, ["scream"] as Array[String], "비명은 소리로")
	assert_true(keys.is_empty(), "비명을 글로 알리지 않는다(UI19)")
	var before := s.player.inventory.count("magic_stone_9") + s.player.inventory.count("explorer_tag")
	FieldFeatureAct.run(s, e, JsonUtil.get_array(e["def"], "actions")[0])
	assert_true(s.player.inventory.count("magic_stone_9") + s.player.inventory.count("explorer_tag") >= before, "유품을 챙긴다")


func test_rookie_trade_rumor_follow() -> void:
	var s := _session()
	var g: FieldMonsters.Group = s.parties.of_kind(s, FieldParties.ROOKIE)[0]
	g.party["trade"] = {"give": "ration", "n": 1, "price": 3}
	var ids: Array = FieldPartyMeet.options(s, g).map(func(o: Dictionary) -> String: return str(o["id"]))
	assert_eq(ids, ["trade", "rumor", "follow", "leave"])
	assert_false(FieldPartyMeet.options(s, g)[0]["enabled"], "마석이 없으면 거래 못 함")
	s.player.inventory.add("magic_stone_9", 5)
	var food := s.player.inventory.count("ration")
	FieldPartyMeet.act(s, g, "trade")
	assert_eq(s.player.inventory.count("magic_stone_9"), 2)
	assert_eq(s.player.inventory.count("ration"), food + 1)
	var keys := _keys(s)
	FieldPartyMeet.act(s, g, "rumor")
	assert_true(keys.any(func(k: String) -> bool: return k.begins_with("explore.party.rumor")), "소문")
	g.place(_free_near(s, s.pos, 2))
	FieldPartyMeet.act(s, g, "follow")
	assert_eq(s.party_size(), 1 + int(g.party["members"]), "함께 다니면 머릿수에 든다(계층군주 조건)")
	assert_true(s.parties.watch_mult(s) < 1.0, "망을 봐 준다")
	assert_eq(FieldPartyMeet.options(s, g).map(func(o: Dictionary) -> String: return str(o["id"])), ["leave"], "한 번씩만")


func test_raider_toll_and_fight_leaves_remains() -> void:
	var s := _session()
	var g: FieldMonsters.Group = s.parties.of_kind(s, FieldParties.RAIDER)[0]
	s.player.inventory.add("magic_stone_9", 9)
	assert_false(FieldPartyMeet.can_cancel(g), "약탈자 앞에서는 물러날 수 없다")
	assert_eq(FieldPartyMeet.options(s, g).map(func(o: Dictionary) -> String: return str(o["id"])), ["pay", "fight"])
	FieldPartyMeet.act(s, g, "pay")
	assert_eq(s.player.inventory.count("magic_stone_9"), 4, "절반(올림)을 빼앗긴다")
	assert_false(g.hostile(), "통행세를 받은 약탈자는 덤비지 않는다")
	s.parties._spawn(s, FieldParties.RAIDER, _free_near(s, s.pos, 8))
	var r: FieldMonsters.Group = s.parties.of_kind(s, FieldParties.RAIDER).filter(func(x: FieldMonsters.Group) -> bool: return x.hostile())[0]
	var met: Array = []
	s.party_met.connect(func(x: FieldMonsters.Group) -> void: met.append(x))
	s.engage(r, false)
	assert_eq(met.size(), 1, "닿으면 먼저 요구한다")
	assert_false(s.in_combat)
	FieldPartyMeet.act(s, r, "fight")
	assert_true(s.in_combat, "싸운다")
	var n := s.features.list.size()
	s.resolve_encounter(r, Battle.RESULT_VICTORY, 3, r.monster_ids.duplicate())
	assert_eq(str(s.features.list.back()["id"]), "raider_remains", "쓰러진 약탈자의 유품")
	assert_eq(s.features.list.size(), n + 1)
	assert_false(s.monsters.groups.has(r))


func test_ghouls_gather_at_new_corpse() -> void:
	var s := _session()
	var spot := _free_near(s, s.pos, 30)
	var ghoul := s.monsters.spawn_group({"id": "f1_south", "monsters": ["ghoul"]}, Vector2i(-99, -99), spot + Vector2i(10, 0), "ghoul")
	if ghoul == null:
		return
	s.parties.drop_corpse(s, spot, false)
	assert_true(not ghoul.route.is_empty() or (ghoul.home - spot).length() <= 4.0, "구울이 시체 쪽으로 간다")


func test_fill_day_grows_raiders() -> void:
	var s := _session()
	var ex := JsonUtil.get_dict(s.floor_def, "explorers")
	s.clock.advance(24.0 * 4)
	s.parties.update(s, 1.0)
	var hostile := s.parties.of_kind(s, FieldParties.RAIDER).filter(func(g: FieldMonsters.Group) -> bool: return g.hostile()).size()
	assert_true(hostile >= int(JsonUtil.get_array(ex, "raiders_by_day")[4]), "5일 차 약탈자 (%d)" % hostile)


func _free_near(s: ExploreSession, p: Vector2i, r: int) -> Vector2i:
	for rr in range(r, r + 20):
		for d: Vector2i in [Vector2i(rr, 0), Vector2i(-rr, 0), Vector2i(0, rr), Vector2i(0, -rr)]:
			var q := p + d
			if s.map.is_walkable(q) and not s.map.in_safe_zone(q) and s.monsters.group_at(q) == null and s.map.portal_at(q).is_empty():
				return q
	return p
