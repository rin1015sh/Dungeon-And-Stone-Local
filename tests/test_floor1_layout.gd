extends TestCase
## 1층 십자가 구조(CrossLayout + crystal_cave): 네 포탈 도달·나침반 경로·고정 장소·암흑지대 위치·시야·구역별 스폰·포탈 목적지,
## 고정 지도(data/maps — 굽기 시드로 새로 만든 지도와 같은지), 미로 동굴(중간 크기 공동·거대 공동 없음·지하 호수·수정 무리).

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


func test_baked_map_matches_its_seed() -> void:
	var def := _def()
	var fixed := JsonUtil.get_dict(def, "fixed_map")
	assert_true(FloorMapFile.exists(JsonUtil.get_str(fixed, "file")), "고정 지도 파일")
	var fresh := CrystalCaveGenerator.new().build(db, CrystalCaveGenerator.procedural(def), Rng.new(JsonUtil.get_int(fixed, "seed")))
	var baked := _gen(1)
	assert_true(fresh.tiles == baked.tiles, "고정 지도 = fixed_map.seed로 새로 만든 지도 (생성기·gen 값을 바꿨으면 tools/bake_floor.gd로 다시 굽기)")
	assert_eq(fresh.landmarks.size(), baked.landmarks.size())
	for i in fresh.landmarks.size():
		assert_eq(fresh.landmarks[i]["pos"], baked.landmarks[i]["pos"], "랜드마크 %s 자리" % fresh.landmarks[i]["id"])


func test_procedural_other_seed_passes_checks() -> void:
	# 다시 구울 때를 대비: 다른 시드로 만든 지도도 검사를 통과한다
	var map := CrystalCaveGenerator.new().build(db, CrystalCaveGenerator.procedural(_def()), Rng.new(2))
	var problems := CrossLayoutCheck.problems(map, _lay())
	assert_eq(problems.size(), 0, ", ".join(problems))


func test_maze_cave_has_medium_caverns_lakes_and_crystals() -> void:
	var map := _gen(1)
	var lay := _lay()
	# 중간 크기 공동: 9×9가 통째로 바닥인 자리가 구역마다 있다 / 너무 큰 공동은 없다(사용자 결정 2026-10-16 — 17×17이 통째로 트인 곳 없음)
	# 예외: 팔 끝 암흑지대는 벽을 걷어낸 트인 굴(사용자 결정 2026-11-01, CR26) — 암흑지대 둘레 8칸까지는 거대 공동을 세지 않는다
	var open_by_zone := {}
	var huge := 0
	for y in range(4, map.height - 4, 3):
		for x in range(4, map.width - 4, 3):
			if _open_square(map, Vector2i(x, y), 4):
				var z := map.zone_at(Vector2i(x, y))
				open_by_zone[z] = int(open_by_zone.get(z, 0)) + 1
				if _open_square(map, Vector2i(x, y), 8) and not _near_dark(map, Vector2i(x, y), 8):
					huge += 1
	for z: String in [CrossLayout.ZONE_CENTER] + Array(CrossLayout.ARMS):
		assert_true(int(open_by_zone.get(z, 0)) >= 10, "%s에 공동 (%d곳)" % [z, int(open_by_zone.get(z, 0))])
	assert_eq(huge, 0, "17×17이 통째로 트인 거대 공동은 없다")
	assert_true(map.count_tile("pond_water") > 50, "지하 호수(연못 물 %d칸)" % map.count_tile("pond_water"))
	assert_true(map.count_tile("crystal_wall") > 500, "수정벽·수정 무리")
	var walk := 0
	for i in map.tiles.size():
		if map.defs[map.tiles[i]].walkable:
			walk += 1
	var cross := lay.core_rect().get_area() + 4 * lay.arm_rect("east").get_area()
	assert_true(walk > cross * 0.25 and walk < cross * 0.6, "십자가 안 바닥 비율 %.2f — 바위 덩어리와 굴이 섞인다" % (float(walk) / cross))


func _near_dark(map: FloorMap, c: Vector2i, r: int) -> bool:
	for y in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			if map.is_dark(Vector2i(x, y)):
				return true
	return false


func test_dark_zone_is_open_cave() -> void:
	# 암흑지대 = 벽을 걷어낸 트인 굴(CR26): 팔 끝 암흑지대 사각형 가운데(가장자리 8칸 안쪽)에는 바위벽이 없다
	var map := _gen(1)
	var lay := _lay()
	var wall := map.index_of("rock_wall")
	for dir in CrossLayout.ARMS:
		var r := lay.dark_rect(dir).grow(-8)
		var walls := 0
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				if map.tiles[y * map.width + x] == wall:
					walls += 1
		assert_eq(walls, 0, "%s 암흑지대 안 바위벽" % dir)


func _open_square(map: FloorMap, c: Vector2i, r: int) -> bool:
	for y in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			if not map.is_walkable(Vector2i(x, y)):
				return false
	return true


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


func test_mixed_center_is_a_circle_and_corners_join_arms() -> void:
	var map := _gen(1)
	var lay := _lay()
	assert_true(lay.mixed_radius > 0.0 and lay.mixed_radius < lay.core_half, "중심부 원은 정사각형보다 작다")
	var r := int(lay.mixed_radius)
	assert_eq(map.zone_at(map.center + Vector2i(r - 1, 0)), "center", "원 안 = 중심부")
	assert_eq(map.zone_at(map.center + Vector2i(r + 2, 0)), "east", "원 밖 = 팔(한 종)")
	assert_eq(map.zone_at(map.center + Vector2i(0, -(r + 2))), "north")
	var c := lay.core_half - 1
	assert_eq(map.zone_at(map.center + Vector2i(c, c - 5)), "east", "정사각형 모서리는 가까운 팔로(대각선으로 나눔)")
	assert_eq(map.zone_at(map.center + Vector2i(-(c - 5), c)), "south")
	assert_eq(lay.zone_of(map.center + Vector2i(c, c)), "center", "지형 뼈대(zone_of)는 그대로 정사각형")


func test_fixed_places_same_every_entry() -> void:
	var a := _gen(1)
	var b := _gen(2)
	assert_true(a.tiles == b.tiles, "고정 지도 — 지형은 모든 게임·입장에서 같다")
	assert_false(a.entry == b.entry, "시작 위치는 입장마다 다르다")
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
		if not g.party.is_empty():  # 다른 탐험가 무리·약탈자(FieldParties)는 어디든 다닌다
			continue
		if g.region.is_empty():  # 동굴 요소를 지키는 무리(늑대 잠자리·고블린 모닥불 — FieldFeatures.spawn_guards)
			assert_true(map.features.any(func(f: Dictionary) -> bool: return Vector2(g.home - (f["pos"] as Vector2i)).length() <= 4.0),
				"지역 없는 무리 %d(%s)는 동굴 요소를 지킨다" % [g.id, g.leader()])
			continue
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
	var west: Dictionary = map.portals.filter(func(p: Dictionary) -> bool: return str(p["dest"]) == "floor2_west")[0]
	west["dest"] = "floor2_nowhere"  # 아직 없는 층으로 가는 포탈(1층 네 포탈은 모두 열렸다 — LD14)
	assert_true(ExploreDebug.teleport(s, west["pos"]))
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
