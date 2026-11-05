extends TestCase
## 2층 첫 걷기 판(M6-0 — docs/plans/floor2.md): fields 생성기(marsh) · 층 사이 이동(FloorTravel) · 원정 시계 10일 · 큰 무리(예비대 BattleHorde).

const F2 := "f2_land_of_dead"


func _f2_map(seed_value: int = 3) -> FloorMap:
	var def := db.get_entry("floors", F2)
	return ContentRegistries.new().generator("fields").generate(db, def, Rng.new(seed_value))


func test_fields_route_map() -> void:
	var map := _f2_map()
	assert_true(map.is_walkable(map.entry), "시작 칸은 걸을 수 있다")
	var nodes: Dictionary = map.anchors["nodes"]
	assert_eq(map.entry, nodes["ferry"], "도착 = 진흙 나루터")
	var down: Dictionary = map.portals.filter(func(p: Dictionary) -> bool: return str(p.get("kind", "")) == "floor_down")[0]
	assert_eq(down["pos"], map.entry + Vector2i(0, 2), "도착 비석은 시작 두 칸 남쪽")
	var up: Dictionary = map.portals.filter(func(p: Dictionary) -> bool: return int(p.get("to_floor", 0)) == 3)[0]
	assert_eq(up["pos"], nodes["summit"], "위층 포탈 = 북쪽 고개 끝")
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
		if map.defs[map.tiles[i]].walkable and map.dark[i] == 0 and map.defs[map.tiles[i]].id != "f2d_flesh":
			walk += 1
	assert_eq(seen.size(), walk, "걸을 수 있는 칸은 모두 시작에서 닿는다(지하 묘실 — 어둠 — 은 계단으로만, 목구멍 방은 아귀 입으로만)")
	for id: String in nodes:
		assert_true(seen.has(nodes[id]) or not map.is_walkable(nodes[id]), "구간 %s까지 걸어 닿는다" % id)
	assert_true(seen.size() < map.width * map.height / 4, "열린 들판이 아니라 길(걸을 수 있는 칸이 지도의 4분의 1 미만): %d" % seen.size())
	assert_eq(map.tile_id_at(nodes["ferry"] + Vector2i(0, -40)) , map.tile_id_at(_f2_map(99).anchors["nodes"]["ferry"] + Vector2i(0, -40)), "고정 시드 — 원정마다 같은 지도")
	assert_eq(_f2_map(99).tiles, map.tiles, "다른 난수를 줘도 같은 지도(gen.seed)")


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
	var nodes: Dictionary = s.map.anchors["nodes"]
	assert_true(Vector2(s.grave.pos - (nodes["graveyard"] as Vector2i)).length() <= 17.0, "비석 터 구간 안")
	var n := s.monsters.groups.size()
	s.clock.advance(5.0 * 24.0)
	assert_false(s.grave.update(s), "아직은 깨어나지 않는다")
	s.clock.advance(1.0 * 24.0)
	assert_true(s.grave.update(s), "원정 7일 차에 깨어난다")
	assert_eq(s.monsters.groups.size(), n + 1)
	var dk: FieldMonsters.Group = s.monsters.groups[-1]
	assert_true(dk.monster_ids.has("death_knight") and dk.boss == "death_knight", "데스나이트 — 보스 무리")
	assert_true(Vector2(dk.pos - (nodes["tomb_gate"] as Vector2i)).length() <= 4.0, "묘역 문을 막고 선다")
	var s2 := _f2_session(9, false)
	var e: Dictionary = s2.features._by_cell[s2.grave.pos]
	var brk: Dictionary = JsonUtil.get_array(e["def"], "actions").filter(func(a: Dictionary) -> bool: return a["id"] == "break")[0]
	var b2 := brk.duplicate(true)
	b2["check"] = {"stat": "str", "dc": 1}
	var t0 := s2.clock.total_hours
	for tries in 10:  # 성공 확률은 상한이 있다(RiftHazards.success_chance) — 난수 하나에 기대지 않는다
		FieldFeatureAct.run(s2, e, b2)
		if s2.grave.broken(s2):
			break
	assert_true(s2.clock.total_hours > t0, "부수는 데 시간이 든다")
	assert_true(s2.grave.broken(s2), "비석을 부쉈다")
	s2.monsters_enabled = true
	s2.clock.advance(7.0 * 24.0)
	assert_false(s2.grave.update(s2), "부순 비석에서는 아무것도 깨어나지 않는다")


func test_route_guards_and_features() -> void:
	var s := _f2_session(4, true)
	var nodes: Dictionary = s.map.anchors["nodes"]
	var at_bridge := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return Vector2(g.pos - (nodes["bridge"] as Vector2i)).length() <= 4.0 and g.monster_ids.has("deathfiend"))
	assert_eq(at_bridge.size(), 1, "기사의 다리 관문 무리")
	assert_true(s.monsters.groups.any(func(g: FieldMonsters.Group) -> bool: return g.monster_ids.has("dullahan")), "듀라한의 폐허 엘리트")
	assert_true(s.features.list.any(func(e: Dictionary) -> bool: return e["id"] == "dead_campfire"), "예배당 쉼터 모닥불")


func test_levels_meet_only_at_ramps() -> void:
	var map := _f2_map()
	var lows := 0
	var bad := 0
	var ramps := 0
	for y in range(1, map.height - 1):
		for x in range(1, map.width - 1):
			var d := map.def_at(Vector2i(x, y))
			ramps += 1 if d.ramp else 0
			if not (d.walkable and d.sunk):
				continue
			lows += 1
			for dd in FloorMap.DIRS4:
				var n := map.def_at(Vector2i(x, y) + dd)
				if n.walkable and not n.sunk and not n.ramp:
					bad += 1
	assert_true(lows > 500, "낮은 땅이 있다(진창 지름길 · 분지 · 구덩이): %d" % lows)
	assert_true(ramps > 20, "비탈이 있다: %d" % ramps)
	assert_eq(bad, 0, "높은 땅과 낮은 땅은 비탈로만 맞닿는다(나머지는 절벽)")
	var nodes: Dictionary = map.anchors["nodes"]
	assert_true(map.def_at(nodes["crossroads"]).sunk, "갈림목은 낮은 분지")


func test_explore_finds_dig_epitaph_tomb_and_tower() -> void:
	var s := _f2_session(4, true)
	var ids := {}
	for e: Dictionary in s.features.list:
		ids[e["id"]] = int(ids.get(e["id"], 0)) + 1
	assert_true(int(ids.get("dig_grave", 0)) >= 8 and int(ids.get("epitaph", 0)) >= 4, "흙무덤 · 비문석이 흩어져 있다: %s" % ids)
	for k in ["sealed_tomb", "sacristy_chest", "watch_post", "journal_1", "journal_2", "journal_3"]:
		assert_true(ids.has(k), "%s가 놓였다" % k)
	var tomb: Dictionary = s.features.list.filter(func(e: Dictionary) -> bool: return e["id"] == "sealed_tomb")[0]
	var open_a: Dictionary = JsonUtil.get_array(tomb["def"], "actions").filter(func(a: Dictionary) -> bool: return a["id"] == "open")[0]
	var n := s.monsters.groups.size()
	FieldFeatureAct.run(s, tomb, open_a)
	assert_false(tomb["cleared"], "열쇠 없이는 열리지 않는다")
	s.player.inventory.add("crypt_key", 1)
	FieldFeatureAct.run(s, tomb, open_a)
	assert_true(tomb["cleared"] and s.map.is_walkable(tomb["pos"]), "열쇠로 열면 문 칸이 트인다")
	assert_eq(s.monsters.groups.size(), n + 1, "영묘를 지키던 스켈레톤이 일어난다")
	var tower: Dictionary = s.features.list.filter(func(e: Dictionary) -> bool: return e["id"] == "watch_post")[0]
	var climb: Dictionary = JsonUtil.get_array(tower["def"], "actions").filter(func(a: Dictionary) -> bool: return a["id"] == "climb")[0]
	var far: Vector2i = tower["pos"] + Vector2i(-40, 0)
	s.map.explored[s.map.idx(far)] = 0
	FieldFeatureAct.run(s, tower, climb)
	assert_eq(s.map.explored[s.map.idx(far)], 1, "망루에 오르면 둘레 지도가 밝혀진다")



func test_tide_floods_mire_and_cuts_isle() -> void:
	var s := _f2_session(4, false)
	var nodes: Dictionary = s.map.anchors["nodes"]
	var tide: Dictionary = s.map.anchors["tide"]
	var isle := Vector2i(-1, -1)
	var mire := Vector2i(-1, -1)
	for q: Vector2i in tide:
		if str(tide[q]) == "deep" and isle.x < 0 and Vector2(q - (nodes["bell_isle"] as Vector2i)).length() < 4.0:
			isle = q
		if str(tide[q]) == "flood" and mire.x < 0 and Vector2(q - (nodes["mire"] as Vector2i)).length() < 4.0:
			mire = q
	assert_true(isle.x >= 0 and mire.x >= 0, "종탑 섬 · 진창에 물때 칸")
	assert_true(s.map.is_walkable(isle), "첫날은 썰물 — 섬까지 걷는다")
	s.pass_time(24.0)
	assert_false(s.map.is_walkable(isle), "밀물 — 섬 갯길이 깊은 물에 잠긴다")
	assert_eq(s.map.tile_id_at(mire), "f2d_flood", "밀물 — 진창은 얕은 물(걸을 수 있고 느리다)")
	s.pass_time(24.0)
	assert_true(s.map.is_walkable(isle), "다시 썰물")


func test_night_fog_crumble_drop_and_crypt() -> void:
	var s := _f2_session(4, false)
	s.clock.total_hours = 22.0
	var nodes: Dictionary = s.map.anchors["nodes"]
	s.relocate(nodes["chapel"] + Vector2i(0, 6))
	assert_true(s.vision_m <= 3.51, "밤 안개 — 늪 · 잔해에서 시야가 줄어든다: %.1f" % s.vision_m)
	var cr: Dictionary = s.map.anchors["crumble"]
	var c: Vector2i = cr.keys()[0]
	s.relocate(c)
	var next := c + Vector2i.DOWN if s.map.is_walkable(c + Vector2i.DOWN) else c + Vector2i.UP
	s.enter_cell(next)
	assert_eq(s.map.tile_id_at(c), "f2d_hole", "무른 땅은 지나가면 꺼진다")
	var drops: Dictionary = s.map.anchors["drops"]
	var d: Vector2i = drops.keys()[0]
	s.relocate(d + Vector2i.LEFT)
	s.enter_cell(d)
	assert_true(s.map.is_dark(s.pos), "꺼진 땅으로 지하 묘실에 떨어진다")
	var up: Dictionary = s.features.list.filter(func(e: Dictionary) -> bool: return e["id"] == "crypt_exit")[0]
	FieldFeatureAct.run(s, up, JsonUtil.get_array(up["def"], "actions")[0])
	assert_false(s.map.is_dark(s.pos), "계단으로 납골당 마당에 나온다")
	assert_true(s.features.list.filter(func(e: Dictionary) -> bool: return e["id"] == "sarcophagus").size() >= 3, "묘실 석관")


func test_procession_walks_at_night() -> void:
	var s := _f2_session(4, true)
	assert_true(s.terrain._procession != null and s.monsters.groups.has(s.terrain._procession), "원정은 자정에 시작 — 밤이라 장례 행렬이 나와 있다")
	assert_true(s.terrain._procession.monster_ids.has("skeleton_mage"), "스켈레톤 행렬")
	s.clock.total_hours = 10.0
	s.terrain.update(s)
	assert_true(s.terrain._procession == null, "낮 — 멀리 있는 행렬은 사라진다")
	s.clock.total_hours = 21.0
	s.terrain.update(s)
	assert_true(s.terrain._procession != null, "다시 밤")



func test_maws_open_catch_and_swallow() -> void:
	var s := _f2_session(4, true)
	assert_true(s.maws != null and s.maws.cells.size() >= 6, "아귀 입이 곳곳에: %d" % (0 if s.maws == null else s.maws.cells.size()))
	var seen_open := false
	var seen_shut := false
	for k in 60:
		s.maws.t = k * 0.1
		seen_open = seen_open or s.maws.openness(0) >= 1.0
		seen_shut = seen_shut or s.maws.openness(0) <= 0.0
	assert_true(seen_open and seen_shut, "입은 벌어졌다 다문다")
	var c := s.maws.cells[0]
	s.maws._resolve(s, 0, true)
	assert_true(Vector2(s.pos - c).length() <= 3.5 and not s.map.is_dark(s.pos), "앞면 — 입 옆으로 빠져나온다")
	s.maws.swallow(s, 0)
	var marks: Dictionary = s.map.anchors["marks"]
	assert_eq(s.map.tile_id_at(s.pos), "f2d_flesh", "뒷면 — 목구멍 방에 떨어진다")
	assert_true(s.in_combat, "떨어지면 바로 무작위 무리와 싸운다")
	s.in_combat = false
	var wall: Dictionary = s.features.list.filter(func(e: Dictionary) -> bool: return e["id"] == "throat_wall")[0]
	var climb: Dictionary = JsonUtil.get_array(wall["def"], "actions").filter(func(a: Dictionary) -> bool: return a["id"] == "climb")[0]
	FieldFeatureAct.run(s, wall, climb)
	assert_eq(s.pos, marks["maw_return"], "힘줄을 타고 삼킨 입 옆으로 올라온다")
	assert_true(Vector2(s.pos - c).length() <= 3.5, "그 입 옆")
