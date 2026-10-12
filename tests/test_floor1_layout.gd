extends TestCase
## 1층 십자가 구조(CrossLayout + crystal_cave): 네 포탈 도달·나침반 경로·고정 장소·암흑지대 위치·시야·구역별 스폰·포탈 목적지.

const FLOOR := "f1_crystal_cave"

var _cache: Dictionary = {}  # 시드 -> FloorMap


func _def() -> Dictionary:
	return db.get_entry("floors", FLOOR)


func _lay() -> CrossLayout:
	return CrossLayout.new(JsonUtil.get_dict(_def(), "gen"))


func _gen(seed_value: int) -> FloorMap:
	if not _cache.has(seed_value):
		_cache[seed_value] = ContentRegistries.new().generator("crystal_cave").generate(db, _def(), Rng.new(seed_value))
	return _cache[seed_value]


func test_layout_checks_pass_for_many_seeds() -> void:
	for seed_value in [1, 2, 3, 4, 5, 6, 7, 8]:
		var problems := CrossLayoutCheck.problems(_gen(seed_value), _lay())
		assert_eq(problems.size(), 0, "시드 %d: %s" % [seed_value, ", ".join(problems)])


func test_corridors_two_wide_and_no_dead_ends() -> void:
	for seed_value in [1, 2, 3]:
		var map := _gen(seed_value)
		assert_eq(GridWiden.count_narrow(GridWiden.walk_cells(map), map.width, map.height), 0, "한 칸 폭 목 없음 (시드 %d)" % seed_value)
		assert_eq(CrossLayoutCheck.max_dead_end(map), 0, "막다른 길 없음 — 모든 길이 다른 길로 이어진다 (시드 %d)" % seed_value)


func test_spur_detector() -> void:
	# 2칸 폭 고리 + 고리에서 뻗은 2칸 폭 막다른 길 6칸 → 막다른 길만 잡힌다
	var w := 20
	var cells := PackedByteArray()
	cells.resize(w * w)
	cells.fill(1)
	for y in range(2, 10):
		for x in range(2, 10):
			if x < 4 or x > 7 or y < 4 or y > 7:
				cells[y * w + x] = 0
	for x in range(10, 16):
		for y in range(2, 4):
			cells[y * w + x] = 0
	var hubs: Array[Vector2i] = []
	var spurs := GridSpurs.spur_cells(cells, w, w, hubs)
	assert_eq(spurs[3 * w + 15], 1, "막다른 끝")
	assert_eq(spurs[3 * w + 5], 0, "고리는 막다른 길이 아니다")
	assert_eq(GridSpurs.max_spur(cells, w, w, hubs), 12)
	assert_eq(GridWiden.count_narrow(cells, w, w), 0)


func test_cross_shape_and_compass_directions() -> void:
	var map := _gen(1)
	var lay := _lay()
	assert_eq(map.zone_at(map.center), "center")
	assert_eq(map.zone_at(map.center + Vector2i(lay.core_half + 5, 0)), "east", "동쪽 팔 = 지도 오른쪽")
	assert_eq(map.zone_at(map.center - Vector2i(lay.core_half + 5, 0)), "west")
	assert_eq(map.zone_at(map.center + Vector2i(0, lay.core_half + 5)), "south", "남쪽 팔 = 지도 아래")
	assert_eq(map.zone_at(map.center - Vector2i(0, lay.core_half + 5)), "north", "북쪽 팔 = 지도 위")
	var corner := map.center + Vector2i(lay.core_half + 5, lay.core_half + 5)
	assert_eq(map.zone_at(corner), "", "십자가 바깥 모서리는 암반")
	assert_false(map.is_walkable(corner))


func test_fixed_places_same_every_entry() -> void:
	var a := _gen(1)
	var b := _gen(2)
	assert_false(a.tiles == b.tiles, "지형은 입장마다 다르다")
	assert_eq(a.center, b.center, "기념비 자리")
	assert_eq(a.tile_id_at(a.center), "monument")
	assert_eq(b.tile_id_at(b.center), "monument")
	assert_true(a.dark == b.dark, "암흑지대 네 곳은 늘 같은 자리")
	assert_true(a.zones == b.zones, "구역은 늘 같다")
	for i in a.portals.size():
		assert_eq(a.portals[i]["pos"], b.portals[i]["pos"], "포탈 %s 자리" % a.portals[i]["dir"])


func test_dark_only_at_arm_tips_and_vision_not_reduced_elsewhere() -> void:
	var map := _gen(3)
	var lay := _lay()
	var def := _def()
	var actor := Actor.new(db, {})
	var ambient := minf(JsonUtil.get_float(def, "ambient_light_m"), JsonUtil.get_float(def, "visibility_cap_m"))
	var reduced := 0
	var dark_cells := 0
	for i in map.tiles.size():
		var p := map.pos_of(i)
		if not map.is_walkable(p):
			continue
		if lay.arm_depth(p) <= lay.dark_start():
			if Vision.radius_m(db, def, map, actor, p) < ambient - 0.001:
				reduced += 1
		else:
			dark_cells += 1
			assert_eq(Vision.light_kind(def, map, actor, p), "dark")
	assert_eq(reduced, 0, "중심부·팔 통로에서는 시야가 줄지 않는다")
	assert_true(dark_cells > 0, "팔 끝 암흑지대엔 걷는 칸이 있다")
	for dir in CrossLayout.ARMS:
		var r := lay.dark_rect(dir)
		assert_eq(r.size.x * r.size.y, lay.dark_depth * (lay.arm_half * 2 + 1), "%s 암흑지대 깊이 = dark_depth" % dir)


func test_monument_and_portals_connected() -> void:
	for seed_value in [4, 5, 6]:
		var map := _gen(seed_value)
		var reach := map.reachable_from(CrystalCaveGenerator.monument_side(map, "north"))
		for portal: Dictionary in map.portals:
			assert_eq(reach[map.idx(portal["pos"])], 1, "기념비 → %s 포탈 (시드 %d)" % [portal["dir"], seed_value])
			assert_true(CrossLayout.compass_path(map, CrystalCaveGenerator.monument_side(map, str(portal["dir"])), str(portal["dir"]), portal["pos"]),
				"%s 쪽으로만 걸어도 닿는다 (시드 %d)" % [portal["dir"], seed_value])


func test_arms_are_winding() -> void:
	for seed_value in [1, 2, 3]:
		var map := _gen(seed_value)
		for portal: Dictionary in map.portals:
			var p: Vector2i = portal["pos"]
			var straight := absi(p.x - map.center.x) + absi(p.y - map.center.y)
			var path := _path_len(map, CrystalCaveGenerator.monument_side(map, str(portal["dir"])), p)
			assert_true(path >= int(straight * 1.1), "%s: 최단 %d걸음 ≥ 직선 %d × 1.1 (시드 %d)" % [portal["dir"], path, straight, seed_value])


func test_spawn_tables_by_zone() -> void:
	var map := _gen(5)
	var fm := FieldMonsters.new(db, map, _def(), Rng.new(9))
	var problems := CrossLayoutCheck.spawn_problems(fm, map, _def(), 80)
	assert_eq(problems.size(), 0, ", ".join(problems))
	var center: Dictionary = JsonUtil.get_array(_def(), "regions").filter(func(r: Variant) -> bool: return JsonUtil.get_str(r, "zone") == "center")[0]
	var seen := {}
	for i in 200:
		seen[fm.pick_monster(center)] = true
	for id: String in ["blade_wolf", "gnome", "ghoul", "goblin"]:
		assert_true(seen.has(id), "중심부에 " + id)
	for r: Variant in JsonUtil.get_array(_def(), "regions"):
		assert_true(JsonUtil.get_dict(r, "variants").is_empty(), "1층엔 변이종 없음 (%s)" % JsonUtil.get_str(r, "id"))


func test_spawn_weights() -> void:
	var fm := FieldMonsters.new(db, _gen(5), _def(), Rng.new(3))
	var region := {"id": "w", "zone": "center", "monsters": ["gnome", "goblin"], "weights": {"gnome": 9, "goblin": 1}}
	var gnomes := 0
	for i in 1000:
		if fm.pick_monster(region) == "gnome":
			gnomes += 1
	assert_true(gnomes > 850 and gnomes < 950, "가중치 9:1 → 노움 %d/1000" % gnomes)


func test_session_spawns_stay_in_their_zone() -> void:
	var reg := ContentRegistries.new()
	var map := reg.generator("crystal_cave").generate(db, _def(), Rng.new(6))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {})
	var s := ExploreSession.new(db, _def(), map, pc, GameClock.new(), Rng.new(7), reg.effects)
	s.start()
	s.monsters._process_respawns(s.pos, 24.0 * 3)  # 시간에 따른 추가 무리
	var zone_of_region := {}
	for r: Variant in JsonUtil.get_array(_def(), "regions"):
		zone_of_region[JsonUtil.get_str(r, "id")] = JsonUtil.get_str(r, "zone")
	assert_true(s.monsters.groups.size() >= 10)
	for g in s.monsters.groups:
		assert_eq(map.zone_at(g.home), zone_of_region[g.region], "무리 %d(%s)는 제 구역에서 생긴다" % [g.id, g.leader()])


func test_portal_has_destination_and_placeholder_message() -> void:
	var reg := ContentRegistries.new()
	var map := reg.generator("crystal_cave").generate(db, _def(), Rng.new(8))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {})
	var s := ExploreSession.new(db, _def(), map, pc, GameClock.new(), Rng.new(9), reg.effects)
	s.monsters_enabled = false
	s.start()
	var dests := {}
	for portal: Dictionary in map.portals:
		dests[portal["dir"]] = portal["dest"]
	assert_eq(dests, {"east": "floor2_east", "west": "floor2_west", "south": "floor2_south", "north": "floor2_north"})
	var keys: Array[String] = []
	s.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	assert_true(ExploreDebug.teleport(s, map.portals[0]["pos"]))
	assert_true(keys.has("explore.dark_enter"), "포탈 주변은 암흑지대")
	s.interact()
	assert_true(keys.has("explore.portal_locked"), "2층이 없으면 안내 메시지")


func _path_len(map: FloorMap, a: Vector2i, b: Vector2i) -> int:
	var dist := {a: 0}
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		if p == b:
			return dist[p]
		for d in FloorMap.DIRS4:
			if map.is_walkable(p + d) and not dist.has(p + d):
				dist[p + d] = int(dist[p]) + 1
				queue.append(p + d)
	return -1
