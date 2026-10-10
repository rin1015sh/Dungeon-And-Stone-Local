extends TestCase
## 수정동굴 생성기(결정성·연결성·랜드마크·포탈·암흑지대), FOV, 시야 규칙.

const FLOOR := "f1_crystal_cave"

var _cache: Dictionary = {}  # 시드 -> FloorMap (이 파일의 테스트끼리 공유, 생성은 한 번만)


func _gen(seed_value: int) -> FloorMap:
	if not _cache.has(seed_value):
		var gen := ContentRegistries.new().generator("crystal_cave")
		_cache[seed_value] = gen.generate(db, db.get_entry("floors", FLOOR), Rng.new(seed_value))
	return _cache[seed_value]


## 바닥만 있는 작은 방(가장자리는 벽).
func _room(size: int) -> FloorMap:
	var map := FloorMap.new(db, size, size, "rock_wall")
	for y in range(1, size - 1):
		for x in range(1, size - 1):
			map.set_tile(Vector2i(x, y), "cave_floor")
	return map


func test_registry_finds_generator() -> void:
	var reg := ContentRegistries.new()
	assert_true(reg.generators.has("crystal_cave"))
	assert_true(reg.generator("crystal_cave") is FloorGenerator)


func test_deterministic_with_seed() -> void:
	var gen := ContentRegistries.new().generator("crystal_cave")
	var def := db.get_entry("floors", FLOOR)
	var t := Time.get_ticks_usec()
	var a := gen.generate(db, def, Rng.new(42))
	print("    생성 시간 %.0fms" % ((Time.get_ticks_usec() - t) / 1000.0))
	var b := gen.generate(db, def, Rng.new(42))
	assert_true(a.tiles == b.tiles, "같은 시드 → 같은 지형")
	assert_eq(a.entry, b.entry)
	assert_true(a.dark == b.dark)
	var c := gen.generate(db, def, Rng.new(43))
	assert_false(a.tiles == c.tiles, "다른 시드 → 다른 지형")


func test_size_and_border() -> void:
	var map := _gen(1)
	var size: Array = JsonUtil.get_array(JsonUtil.get_dict(db.get_entry("floors", FLOOR), "gen"), "size")
	assert_eq(map.width, int(size[0]))
	assert_eq(map.height, int(size[1]))
	var bad := 0
	for x in map.width:
		for y: int in [0, map.height - 1]:
			if map.is_walkable(Vector2i(x, y)) or map.is_walkable(Vector2i(y, x)):
				bad += 1
	assert_eq(bad, 0, "가장자리는 막혀 있다")


func test_every_walkable_cell_is_connected() -> void:
	for seed_value in [1, 2, 3, 4, 5, 6]:
		var map := _gen(seed_value)
		assert_true(map.is_walkable(map.entry), "시작 위치는 걸을 수 있다 (시드 %d)" % seed_value)
		var reach := map.reachable_from(map.entry)
		var lost := 0
		for i in map.tiles.size():
			if map.defs[map.tiles[i]].walkable and reach[i] == 0:
				lost += 1
		assert_eq(lost, 0, "고립된 칸 없음 (시드 %d)" % seed_value)


func test_landmarks_and_safe_zone() -> void:
	var map := _gen(7)
	var ids := PackedStringArray()
	for rec: Dictionary in map.landmarks:
		ids.append(str(rec["id"]))
	for id: String in ["sage_monument", "square_crystal_junction", "boulder_pond"]:
		assert_true(ids.has(id), "랜드마크 " + id)
	assert_eq(map.tile_id_at(map.center), "monument", "중앙 기념비")
	assert_true(map.in_safe_zone(map.center + Vector2i(0, 2)))
	assert_false(map.in_safe_zone(map.entry))
	var min_entry := JsonUtil.get_float(JsonUtil.get_dict(db.get_entry("floors", FLOOR), "gen"), "entry_min_distance")
	assert_true(Vector2(map.entry - map.center).length() >= min_entry, "시작 위치는 기념비에서 멀다")
	assert_false(map.is_dark(map.entry))


func test_four_portals_in_their_directions() -> void:
	for seed_value in [11, 12, 13]:
		var map := _gen(seed_value)
		assert_eq(map.portals.size(), 4, "포탈 4개 (시드 %d)" % seed_value)
		for portal: Dictionary in map.portals:
			var p: Vector2i = portal["pos"]
			var d := p - map.center
			var ok := false
			match str(portal["dir"]):
				"east": ok = d.x > 0
				"west": ok = d.x < 0
				"south": ok = d.y > 0
				"north": ok = d.y < 0
			assert_true(ok, "%s 포탈 방향 (시드 %d)" % [portal["dir"], seed_value])
			assert_eq(map.tile_id_at(p), "portal")
			assert_false(map.is_dark(p), "포탈은 암흑지대 밖")


func test_crystals_and_dark_zones() -> void:
	var map := _gen(3)
	assert_true(map.count_tile("crystal_wall") > 0, "빛나는 수정벽")
	assert_true(map.dark.count(1) > 0, "암흑지대")
	var crystal := map.index_of("crystal_wall")
	var bad := 0
	for i in map.tiles.size():
		if map.tiles[i] == crystal and map.dark[i] != 0:
			bad += 1
	assert_eq(bad, 0, "암흑지대에는 빛나는 수정이 없다")


func test_fov_open_room() -> void:
	var map := _room(15)
	var vis := Fov.compute(map, Vector2i(7, 7), 3.0)
	assert_eq(vis[map.idx(Vector2i(7, 7))], 1, "자기 칸")
	assert_eq(vis[map.idx(Vector2i(10, 7))], 1, "반경 3")
	assert_eq(vis[map.idx(Vector2i(11, 7))], 0, "반경 밖")
	assert_eq(vis[map.idx(Vector2i(7, 4))], 1)
	assert_eq(vis[map.idx(Vector2i(10, 10))], 0, "대각 거리 4.2 > 3")


func test_fov_wall_blocks_sight() -> void:
	var map := _room(15)
	map.set_tile(Vector2i(9, 7), "rock_wall")
	var vis := Fov.compute(map, Vector2i(7, 7), 6.0)
	assert_eq(vis[map.idx(Vector2i(9, 7))], 1, "벽 자체는 보인다")
	assert_eq(vis[map.idx(Vector2i(11, 7))], 0, "벽 뒤는 안 보인다")
	assert_eq(vis[map.idx(Vector2i(7, 11))], 1, "다른 방향은 보인다")
	map.set_tile(Vector2i(9, 7), "pond_water")
	vis = Fov.compute(map, Vector2i(7, 7), 6.0)
	assert_eq(vis[map.idx(Vector2i(11, 7))], 1, "연못은 시야를 막지 않는다")


func test_vision_rules() -> void:
	var map := _room(9)
	var def := {"visibility_cap_m": 9.0, "ambient_light_m": 6.0}
	var p := Vector2i(4, 4)
	var a := Actor.new(db, {})
	assert_near(Vision.radius_m(db, def, map, a, p), 6.0, 0.0001, "수정 빛")
	assert_eq(Vision.light_kind(def, map, a, p), "ambient")
	map.dark[map.idx(p)] = 1
	assert_near(Vision.radius_m(db, def, map, a, p), float(db.bal("explore.min_vision_m")), 0.0001, "암흑지대 맨몸")
	assert_eq(Vision.light_kind(def, map, a, p), "dark")
	a.light.ignite("torch", 7.0, 10.0)
	assert_near(Vision.radius_m(db, def, map, a, p), 7.0, 0.0001, "횃불")
	assert_eq(Vision.light_kind(def, map, a, p), "torch")
	a.light.ignite("sun", 30.0, 10.0)
	assert_near(Vision.radius_m(db, def, map, a, p), 9.0, 0.0001, "아무리 밝아도 상한")
	a.light.ignite("torch", 7.0, 10.0)
	a.stats.set_base("field_of_view", 10)
	assert_true(Vision.radius_m(db, def, map, a, p) > 7.0, "시야 스탯 보정")
