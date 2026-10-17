extends TestCase
## 탐험 맵 그림 층 A3(docs/PROMPT_ART_MAP.md §5.2~5.4): 데칼 배치(FloorDecor)·거시 색조(FloorTint)·소품·랜드마크 그림.
## 데칼은 그림만 — 동굴 요소 칸에 놓이지 않고, 같은 칸은 늘 같은 데칼, 물가는 물 쪽을 본다.

const DecalSpecs := preload("res://tools/floor_art/Specs.gd")
const Props := preload("res://tools/floor_art/Props.gd")


func _f1() -> Array:
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := ContentRegistries.new().generator("crystal_cave").generate(db, def, Rng.new(1))
	return [map, def]


func test_decor_rules_follow_map() -> void:
	var f := _f1()
	var map: FloorMap = f[0]
	var decor := FloorDecor.compile(map, f[1])
	assert_false(decor.is_empty())
	var rect := Rect2i(300, 380, 32, 24)  # 이끼 물웅덩이 둘레
	var a := decor.cells(rect)
	var b := decor.cells(rect)
	assert_eq(a.size(), b.size(), "같은 칸 = 같은 데칼")
	assert_true(a.size() > 0)
	var feats := {}
	for fe in map.features:
		feats[fe["pos"]] = true
	var shore := decor.kinds.find("shore")
	var seen_shore := false
	for e in a:
		var p: Vector2i = e["pos"]
		assert_false(feats.has(p), "동굴 요소 칸에는 데칼 없음")
		assert_eq(map.tile_id_at(p), "cave_floor", "on_tiles 바닥에만")
		if int(e["kind"]) == shore:
			seen_shore = true
			var q: Vector2i = p + FloorDecor.DIRS[int(e["rot"])]
			assert_eq(map.tile_id_at(q), "pond_water", "물가 데칼은 물 쪽을 본다")
	assert_true(seen_shore, "물웅덩이 둘레에 물가")
	assert_eq(FloorArtCheck.problems(map, {"decor": decor.cells(Rect2i(0, 0, map.width, map.height).intersection(Rect2i(256, 256, 224, 224)))}).size(), 0)


## 데이터의 데칼 종류 순서 = 그림 도구의 시트 줄 순서, 시트 크기도 맞다.
func test_decal_sheet_matches_data() -> void:
	var decor := JsonUtil.get_dict(JsonUtil.get_dict(db.get_entry("floors", "f1_crystal_cave"), "art"), "decor")
	var spec: Dictionary = DecalSpecs.DECALS[0]
	assert_eq(JsonUtil.get_array(decor, "kinds"), spec["kinds"])
	var view := JsonUtil.get_dict(db.render, "view")
	var cell := int(JsonUtil.get_array(view, "floor_tile_px")[0]) * JsonUtil.get_int(view, "art_scale", 2)
	var tex := load(JsonUtil.get_str(decor, "sheet")) as Texture2D
	assert_eq(tex.get_width(), JsonUtil.get_int(decor, "variants") * cell)
	assert_eq(tex.get_height(), (spec["kinds"] as Array).size() * cell)


## 소품: 동굴 요소 타일마다 마름모 대신 그림 칸이 있고, 칸 번호가 시트 안에 있다.
func test_props_cover_feature_tiles() -> void:
	var missing := PackedStringArray()
	for id: String in db.get_collection("events"):
		var tile := JsonUtil.get_str(db.get_entry("events", id), "tile", JsonUtil.get_str(JsonUtil.get_dict(db.get_entry("events", id), "hazard"), "tile"))
		if tile.is_empty() or tile == "feat_mud":
			continue
		var prop := JsonUtil.get_dict(JsonUtil.get_dict(db.get_entry("tiles", tile), "art"), "prop")
		if prop.is_empty():
			missing.append(tile)
		else:
			assert_true(JsonUtil.get_int(prop, "cell") < Props.ORDER.size(), "소품 칸 번호: " + tile)
	assert_eq(missing.size(), 0, "소품 그림 없는 동굴 요소: " + ", ".join(missing))
	for t in ["portal", "monument", "square_crystal", "boulder"]:
		assert_false(JsonUtil.get_dict(db.get_entry("tiles", t), "art").is_empty(), "랜드마크 그림: " + t)


## 거시 색조: 기념비 안전지대 둘레는 한 단계 어둡고, 구역마다 색조가 다르다.
func test_macro_tint() -> void:
	var f := _f1()
	var map: FloorMap = f[0]
	var tint := FloorTint.new()
	tint.setup(map, f[1])
	assert_true(tint.enabled)
	var c: Vector2i = map.safe_zones[0]["center"]
	assert_true(tint.at(c.x, c.y).get_luminance() < tint.at(c.x + 40, c.y).get_luminance() * 0.9, "안전지대 둘레가 어둡다")
	var east := tint.at(600, 366)
	var west := tint.at(130, 366)
	assert_true(east.b > east.r and west.r > west.b, "동 = 차가운 색, 서 = 따뜻한 색")
