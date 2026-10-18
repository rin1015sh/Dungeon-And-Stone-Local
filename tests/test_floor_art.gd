extends TestCase
## 탐험 맵 그림 층 검사(FloorArtCheck — docs/PROMPT_ART_MAP.md §5.4): 같은 변형 연속, 걷는 칸을 막는 장식, 동굴 요소와 겹침.
## 1층 고정 지도는 그림 층이 생겨도 지형이 그대로여야 한다(A2부터 실제 그림 층을 이 검사에 넘긴다).


## 5×3 바닥(가운데 줄만 걷는 칸) 시험 지도.
func _map() -> FloorMap:
	var map := FloorMap.new(db, 5, 3, "rock_wall")
	for x in 5:
		map.set_tile(Vector2i(x, 1), "cave_floor")
	return map


func _variants(map: FloorMap, row: Array) -> PackedInt32Array:
	var v := PackedInt32Array()
	v.resize(map.width * map.height)
	v.fill(-1)
	for x in row.size():
		v[map.width + x] = int(row[x])
	return v


func test_empty_art_has_no_problems() -> void:
	assert_eq(FloorArtCheck.problems(_map(), FloorArtCheck.empty_art()).size(), 0)


func test_variant_runs() -> void:
	var map := _map()
	assert_eq(FloorArtCheck.problems(map, {"variants": _variants(map, [0, 0, 1, 1, 0])}).size(), 0, "2칸까지는 괜찮다")
	assert_eq(FloorArtCheck.problems(map, {"variants": _variants(map, [2, 2, 2, 0, 1])}).size(), 1, "3칸 연속은 문제")
	assert_eq(FloorArtCheck.problems(map, {"variants": PackedInt32Array([0, 1])}).size(), 1, "칸 수가 다르면 문제")


func test_vertical_run() -> void:
	var map := FloorMap.new(db, 1, 4, "cave_floor")
	assert_eq(FloorArtCheck.problems(map, {"variants": PackedInt32Array([3, 3, 3, 1])}).size(), 1)


func test_decor_rules() -> void:
	var map := _map()
	map.features.append({"id": "explorer_corpse", "pos": Vector2i(3, 1)})
	assert_eq(FloorArtCheck.problems(map, {"decor": [{"pos": Vector2i(1, 1), "blocks": false}, {"pos": Vector2i(1, 0), "blocks": true}]}).size(), 0,
		"막지 않는 장식, 벽 위의 장식은 괜찮다")
	assert_eq(FloorArtCheck.problems(map, {"decor": [{"pos": Vector2i(2, 1), "blocks": true}]}).size(), 1, "걷는 칸을 막는 장식")
	assert_eq(FloorArtCheck.problems(map, {"decor": [{"pos": Vector2i(3, 1), "blocks": false}]}).size(), 1, "동굴 요소와 겹친 장식")


## 1층 고정 지도에 빈 그림 층을 얹어도 검사가 통과한다.
func test_floor1_art_layer() -> void:
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := ContentRegistries.new().generator("crystal_cave").generate(db, def, Rng.new(1))
	assert_eq(FloorArtCheck.problems(map, FloorArtCheck.empty_art()).size(), 0)


## 1층 고정 지도의 실제 그림 층(FloorArtLayer — 바닥 변형)이 검사를 통과한다: 같은 변형이 이어지지 않는다.
func test_floor1_variant_layer() -> void:
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := ContentRegistries.new().generator("crystal_cave").generate(db, def, Rng.new(1))
	var layer := FloorArtLayer.build(map)
	var v: PackedInt32Array = layer["variants"]
	assert_true(v.count(-1) < v.size(), "그림이 있는 바닥 칸이 있다")
	assert_eq(FloorArtCheck.problems(map, layer).size(), 0)


func test_variant_neighbors_differ() -> void:
	for y in 20:
		for x in 20:
			var a := FloorArtLayer.variant(x, y, 8, 7)
			assert_true(a >= 0 and a < 8)
			assert_true(a != FloorArtLayer.variant(x + 1, y, 8, 7) and a != FloorArtLayer.variant(x, y + 1, 8, 7))
	assert_eq(FloorArtLayer.variant(3, 4, 6, 9), FloorArtLayer.variant(3, 4, 6, 9), "같은 칸 = 같은 변형")


## 타일이 가리키는 재질 아틀라스(tools/paint_floor.gd)의 크기: 가로 = 변형 수 × 칸, 바닥은 한 줄, 벽은 윗면 줄 + 앞면 줄(docs/COMFYUI_PROMPTS.md §0-B).
func test_atlas_sizes() -> void:
	var view := JsonUtil.get_dict(db.render, "view")
	var k := JsonUtil.get_int(view, "art_scale", 2)
	var cell := int(JsonUtil.get_array(view, "floor_tile_px")[0]) * k
	var skirt := JsonUtil.get_int(view, "wall_skirt_px", 0) * k
	var face := (int(JsonUtil.get_array(view, "wall_tile_px")[1]) - int(JsonUtil.get_array(view, "floor_tile_px")[1])) * k
	var seen := 0
	for id: String in db.get_collection("tiles"):
		var t := db.get_entry("tiles", id)
		var art := JsonUtil.get_dict(t, "art")
		if not art.has("atlas"):  # 서 있는 소품(art.stand)만 있는 타일
			continue
		var tex := load(JsonUtil.get_str(art, "atlas")) as Texture2D
		assert_true(tex != null, "아틀라스: " + id)
		if tex == null:
			continue
		seen += 1
		assert_eq(tex.get_width(), JsonUtil.get_int(art, "variants") * cell, "아틀라스 가로: " + id)
		var wall := JsonUtil.get_str(t, "kind") == "wall"
		var fh := JsonUtil.get_int(t, "face_px", -1) * k + skirt if JsonUtil.get_int(t, "face_px", -1) >= 0 else face + skirt
		assert_eq(tex.get_height(), cell + fh if wall else cell, "아틀라스 세로: " + id)
	assert_true(seen >= 4, "1층 바닥·암벽·수정벽·물")


## 부드러운 암벽(WallShape): 북쪽이 열린 벽 칸만 윗면(검게), 남쪽이 열린 칸만 앞면, 볼록 모서리는 깎인다.
func test_wall_shape_smooth() -> void:
	var map := FloorMap.new(db, 4, 3, "cave_floor")
	map.set_tile(Vector2i(1, 1), "rock_wall")  # 홀로 선 벽 한 칸 — 네 모서리 모두 볼록
	var smooth := PackedByteArray()
	smooth.resize(map.defs.size())
	smooth[map.index_of("rock_wall")] = 1
	var face_h := func(_d: TileDef) -> int: return 24
	var variant := func(_x: int, _y: int, _d: TileDef) -> int: return 0
	var s := WallShape.build(map, 1, 0, 4, 32.0, 16.0, smooth, face_h, variant)
	assert_eq(s.tops.size(), 1, "북쪽이 열려 윗면 하나")
	var poly: PackedVector2Array = s.tops[0]["poly"]
	assert_false(poly.has(Vector2(32, 32)), "왼위 모서리는 깎였다")
	assert_true(s.faces.size() > 2, "아래 변 + 아래 두 모서리 사선이 앞면")
	for f in s.faces:
		assert_true((f["b"] as Vector2).x > (f["a"] as Vector2).x, "앞면 선분은 왼→오")
	assert_eq(s.floors.size(), 2, "깎은 아래쪽 두 모서리에 바닥을 채운다")
	var inner := WallShape.build(map, 0, 0, 4, 32.0, 16.0, smooth, face_h, variant)
	assert_eq(inner.tops.size() + inner.faces.size(), 0, "벽이 없는 줄(오목 모서리도 없음)")
