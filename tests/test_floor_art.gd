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


## 1층 고정 지도에 지금 그림 층(아직 빈 것)을 얹어도 검사가 통과한다.
func test_floor1_art_layer() -> void:
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := ContentRegistries.new().generator("crystal_cave").generate(db, def, Rng.new(1))
	assert_eq(FloorArtCheck.problems(map, FloorArtCheck.empty_art()).size(), 0)
