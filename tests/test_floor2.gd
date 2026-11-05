extends TestCase
## 2층 첫 걷기 판(M6-0 — docs/plans/floor2.md): fields 생성기(marsh) · 층 사이 이동(FloorTravel) · 원정 시계 10일 · 큰 무리(예비대 BattleHorde).

const F2 := "f2_land_of_dead"


func _f2_map(seed_value: int = 3) -> FloorMap:
	var def := db.get_entry("floors", F2)
	return ContentRegistries.new().generator("fields").generate(db, def, Rng.new(seed_value))


func test_fields_marsh_map() -> void:
	var map := _f2_map()
	assert_true(map.is_walkable(map.entry), "시작 칸은 걸을 수 있다")
	var down: Dictionary = map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("kind", "")) == "floor_down")[0]
	assert_eq(down["pos"], map.entry + Vector2i(0, 2), "도착 비석은 시작 두 칸 남쪽")
	var up: Dictionary = map.portals.filter(func(p: Dictionary) -> bool: return int(p.get("to_floor", 0)) == 3)[0]
	assert_true(up["pos"].y < map.height / 4, "위층 포탈은 북쪽 끝")
	assert_eq(map.zone_at(map.entry), "f2d_marsh", "남쪽은 검은 늪")
	assert_eq(map.zone_at(up["pos"]), "f2d_hard", "북쪽은 굳은 땅")
	var seen := {map.entry: true}
	var queue: Array[Vector2i] = [map.entry]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in FloorMap.DIRS4:
			if map.in_bounds(p + d) and not seen.has(p + d) and map.is_walkable(p + d):
				seen[p + d] = true
				queue.append(p + d)
	var walk := 0
	for i in map.tiles.size():
		if map.defs[map.tiles[i]].walkable:
			walk += 1
	assert_eq(seen.size(), walk, "걸을 수 있는 칸은 모두 시작에서 닿는다")
	assert_true(seen.has(up["pos"]), "위층 포탈까지 걸어 닿는다")
	assert_eq(_f2_map(3).tiles, map.tiles, "같은 시드면 같은 지도")


func test_floor_travel_up_and_down() -> void:
	var reg := ContentRegistries.new()
	var def1 := db.get_entry("floors", "f1_crystal_cave")
	assert_eq(JsonUtil.get_float(def1, "close_hours"), 240.0, "원정은 모두 10일(사용자 2026-11-04)")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"agi": 8})
	var s1 := ExploreSession.new(db, def1, reg.generator("crystal_cave").generate(db, def1, Rng.new(5)), pc, GameClock.new(), Rng.new(6), reg.effects)
	s1.monsters_enabled = false
	s1.start()
	var south: Dictionary = s1.map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("dest", "")) == "floor2_south")[0]
	assert_eq(FloorTravel.floor_for(db, "floor2_south"), F2, "1층 남쪽 포탈 → 망자의 땅")
	assert_eq(FloorTravel.floor_for(db, "floor2_east"), "", "아직 없는 길은 잠김")
	s1.clock.advance(30.0)
	var s2 := FloorTravel.up(s1, south)
	assert_true(s2 != null and JsonUtil.get_int(s2.floor_def, "floor") == 2, "2층 세션")
	assert_true(s2.clock == s1.clock and s2.player == pc, "시계 · 플레이어는 이어진다")
	assert_true(s1.ended, "1층 세션은 떼어 둔다")
	s2.start()
	assert_near(s2.hours_until_close(), 210.0, 0.001, "남은 시간은 층과 무관하게 하나(240 − 30)")
	var east: Dictionary = s1.map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("dest", "")) == "floor2_east")[0]
	assert_true(FloorTravel.up(s1, east) == null, "만들지 않은 층은 오르지 못한다")
	var back := FloorTravel.down(s2)
	assert_true(back == s1 and not s1.ended, "도착 비석에서 내려가면 같은 1층 세션")
	assert_eq(s1.pos, south["pos"], "올라갔던 포탈 자리에 선다")
	assert_true(s2.ended and s2.below == null, "2층은 버린다(다시 오르면 새 지도)")


func test_horde_reserve_fills_in() -> void:
	var party: Array[Actor] = [PlayerCharacter.create(db, "human", "warrior", "시험", {"agi": 8})]
	var ids: Array = []
	for i in 10:
		ids.append("ghoul")
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(1), party, ids)
	var cap := int(db.bal("combat.max_side_units", 6))
	assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), cap, "앞의 6마리만 선다")
	assert_eq(b.horde.size(), 10 - cap, "나머지는 예비대")
	var first: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	first.actor.pool.set_current("hp", 0.0)
	first.actor.dead = true
	b._after_effects()
	assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), cap, "쓰러진 자리에 예비대가 들어온다")
	assert_eq(b.horde.size(), 10 - cap - 1)
	assert_true(b.result.is_empty(), "예비대가 남았으면 이긴 게 아니다")
	assert_eq(BattleReserve.plan(db, ["ghoul"], {}, ["elder_ghoul"]).has("elder_ghoul"), true, "무대는 예비대 자리도 미리 잡는다")


func test_horde_pack_size_by_day() -> void:
	var def := db.get_entry("floors", F2)
	var fm := FieldMonsters.new(db, _f2_map(), def, Rng.new(2))
	fm._now = 9.0 * 24.0
	var most := 0
	for i in 30:
		most = maxi(most, fm.pack_count("ghoul", true, true))
	assert_true(most > 6, "열댓 무리(구울 pack_size 최대를 넘는다): %d" % most)
	assert_true(fm.pack_count("ghoul", true, false) <= 6, "horde가 아니면 pack_size 최대까지")


func _f2_session(seed_value: int = 4, monsters: bool = false) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", F2)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(), Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func test_mud_slows_and_mounds_block_sight() -> void:
	var mud := db.get_entry("tiles", "f2d_mud")
	assert_true(JsonUtil.get_float(mud, "move_mult") < 1.0, "진창은 느리다")
	var mound := db.get_entry("tiles", "f2d_mound")
	assert_true(JsonUtil.get_bool(mound, "walkable") and JsonUtil.get_bool(mound, "blocks_sight"), "둔덕은 걸어 오르되 너머를 가린다")
	var s := _f2_session()
	assert_eq(s.map.tile_id_at(s.pos), "f2d_mud", "도착은 진창")
	var before := s.fpos
	s.move_dir(Vector2.UP, 0.1)
	var on_mud := before.distance_to(s.fpos)
	s.map.set_tile(s.pos, "f2d_hard")
	before = s.fpos
	s.move_dir(Vector2.UP, 0.1)
	assert_near(on_mud / before.distance_to(s.fpos), JsonUtil.get_float(mud, "move_mult"), 0.02, "진창에서는 그만큼 느리게 걷는다")
	assert_true(JsonUtil.get_bool(JsonUtil.get_dict(db.get_entry("monsters", "ghoul"), "behavior"), "mud_walker"), "구울은 진창에서 느려지지 않는다")


func test_grave_wakes_on_day_seven_unless_broken() -> void:
	var s := _f2_session(4, true)
	assert_true(s.grave != null and s.grave.pos.x >= 0, "비석이 섰다")
	assert_eq(s.map.zone_at(s.grave.pos), "f2d_ruins", "잔해 구역")
	var n := s.monsters.groups.size()
	s.clock.advance(5.0 * 24.0)
	assert_false(s.grave.update(s), "아직은 깨어나지 않는다")
	s.clock.advance(1.0 * 24.0)
	assert_true(s.grave.update(s), "원정 7일 차에 깨어난다")
	assert_eq(s.monsters.groups.size(), n + 1)
	var dk: FieldMonsters.Group = s.monsters.groups[-1]
	assert_true(dk.monster_ids.has("death_knight") and dk.boss == "death_knight", "데스나이트 — 보스 무리")
	var s2 := _f2_session(9, false)
	var e: Dictionary = s2.features._by_cell[s2.grave.pos]
	var brk: Dictionary = JsonUtil.get_array(e["def"], "actions").filter(func(a: Dictionary) -> bool: return a["id"] == "break")[0]
	var b2 := brk.duplicate(true)
	b2["check"] = {"stat": "str", "dc": 1}
	var t0 := s2.clock.total_hours
	FieldFeatureAct.run(s2, e, b2)
	assert_true(s2.clock.total_hours > t0, "부수는 데 시간이 든다")
	assert_true(s2.grave.broken(s2), "비석을 부쉈다")
	s2.monsters_enabled = true
	s2.clock.advance(7.0 * 24.0)
	assert_false(s2.grave.update(s2), "부순 비석에서는 아무것도 깨어나지 않는다")
