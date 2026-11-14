extends TestCase
## 던전 에셋 키트(assets/dungeon_kit — docs/DUNGEON_KIT.md): kit.json이 가리키는 그림 조각 · 세트가 온전하고, DungeonKit이 노드 · TileSet을 만든다.


func test_manifest_regions_fit_their_sheets() -> void:
	var kit := DungeonKit.open()
	assert_true(kit.ids().size() >= 150, "에셋 수: %d" % kit.ids().size())
	var bad: Array[String] = []
	for id in kit.ids():
		var a := kit.info(id)
		var sheet: Dictionary = kit.data["sheets"].get(a.get("sheet", ""), {})
		if sheet.is_empty() or not FileAccess.file_exists(String(sheet.get("path", ""))):
			bad.append(id + ": 묶음 그림 없음")
			continue
		for v: String in a["variants"]:
			for f: Array in a["variants"][v]["frames"]:
				if f[0] < 0 or f[1] < 0 or f[0] + f[2] > sheet["size"][0] or f[1] + f[3] > sheet["size"][1] or f[2] < 2 or f[3] < 2:
					bad.append("%s.%s" % [id, v])
	assert_true(bad.is_empty(), "묶음 그림 밖을 가리킴: %s" % [", ".join(bad.slice(0, 5))])


func test_every_category_and_layer_is_present() -> void:
	var kit := DungeonKit.open()
	for cat: String in ["floor", "wall", "structure", "furniture", "light", "trace", "nature", "special", "trap", "terrain", "flora"]:
		assert_true(kit.ids(cat).size() >= 10, "%s 분류: %d종" % [cat, kit.ids(cat).size()])
	for layer: String in ["floor", "wall", "decal", "wall_decal", "stand", "over"]:
		assert_true(kit.ids("", layer).size() > 0, "%s 층" % layer)


func test_make_builds_sprite_animation_and_collision() -> void:
	var kit := DungeonKit.open()
	var pillar := kit.make("pillar", "broken")
	assert_true(pillar.get_child(0) is Sprite2D, "기둥 = Sprite2D")
	assert_true(pillar.get_node_or_null("Body") is StaticBody2D, "기둥에 충돌")
	var torch := kit.make("torch_wall", "lit")
	assert_true(torch.get_child(0) is AnimatedSprite2D, "횃불 = AnimatedSprite2D")
	assert_eq(kit.frame_count("torch_wall", "lit"), 4)
	assert_true(not kit.light_of("torch_wall", "lit").is_empty() and kit.light_of("torch_wall", "unlit").is_empty(), "켜진 변형만 빛을 낸다")
	var splat := kit.make("blood_splat")
	assert_true(splat.get_node_or_null("Body") == null, "자국은 충돌 없음")
	assert_true(kit.variants("pillar").has(kit.pick("pillar", 7)), "변형 고르기")
	for n: Node2D in [pillar, torch, splat]:
		n.free()


func test_tileset_and_sets_build() -> void:
	var kit := DungeonKit.open()
	var ts := kit.tileset()
	assert_eq(ts.get_source_count(), 3)
	assert_true((ts.get_source(DungeonKit.SRC_FLOOR) as TileSetAtlasSource).get_tiles_count() >= 14 * 16, "바닥 타일")
	assert_true((ts.get_source(DungeonKit.SRC_TOP) as TileSetAtlasSource).get_tiles_count() >= 16, "벽 윗면 16가지")
	assert_true(kit.set_names().size() >= 6, "테마 세트")
	for set_name in kit.set_names():
		var room := kit.build_set(set_name)
		var s: Dictionary = kit.data["sets"][set_name]
		assert_eq(room.get_child_count(), 3 + (s["items"] as Array).size(), set_name)
		var floor_layer := room.get_child(0) as TileMapLayer
		assert_eq(floor_layer.get_used_cells().size(), int(s["size"][0]) * int(s["size"][1]), set_name + " 바닥 칸")
		room.free()


func test_regions_point_at_real_assets() -> void:
	## 에셋 라이브러리(docs/asset_library): 지역 표가 가리키는 바닥 · 벽 · 에셋 · 변형이 모두 있고, 지역 확장형은 틀이 되는 공용 에셋을 가리킨다.
	var kit := DungeonKit.open()
	assert_true(kit.region_names().size() >= 40, "지역 수: %d" % kit.region_names().size())
	var bad: Array[String] = []
	for rid in kit.region_names():
		var r := kit.region(rid)
		if not ["specific", "partial", "none"].has(str(r.get("lore", ""))) or not kit.has("wall_" + str(r.get("wall", ""))) or kit.region_assets(rid, "floor").is_empty():
			bad.append(rid)
		for ref in kit.region_assets(rid):
			var id := ref.get_slice(".", 0)
			if not kit.has(id) or (ref.contains(".") and not kit.variants(id).has(ref.get_slice(".", 1))):
				bad.append("%s: %s" % [rid, ref])
	assert_true(bad.is_empty(), "지역 표 오류: %s" % [", ".join(bad.slice(0, 5))])
	var n_ext := 0
	for id in kit.ids():
		var reuse := kit.reuse_of(id)
		assert_true(["common", "ext", "region"].has(reuse), "%s reuse" % id)
		if reuse == "ext":
			n_ext += 1
			assert_true(kit.has(str(kit.info(id).get("base", ""))), "%s: 틀이 되는 공용 에셋" % id)
	assert_true(n_ext >= 8, "지역 확장형 에셋: %d" % n_ext)
	var node := kit.make_ref("rock_ice.pillar_frozen")
	assert_true(node.get_child(0) is Sprite2D, "참조로 만들기")
	node.free()
	assert_eq(kit.frame_count("ground_lava", "flow"), 4, "용암 4프레임")
	assert_true(not kit.light_of("crystal_wall", "a").is_empty() and kit.light_of("crystal_wall", "dim").is_empty(), "수정 광원")


func test_game_prop_tiles_point_at_kit_sheet() -> void:
	## 게임 소품 시트(AM66 — tools/dungeon_kit/game_props.py): 소품 타일이 가리키는 칸이 시트 안에 있다.
	var tex := load("res://assets/floor/kit/props.webp") as Texture2D
	assert_true(tex != null, "assets/floor/kit/props.webp")
	if tex == null:
		return
	var bad: Array[String] = []
	var n := 0
	for t: Dictionary in db.get_collection("tiles").values():
		var prop: Dictionary = JsonUtil.get_dict(JsonUtil.get_dict(t, "art"), "prop")
		if prop.is_empty() or not str(prop.get("sheet", "")).ends_with("kit/props.webp"):
			continue
		n += 1
		var cols := int(prop.get("cols", 8))
		if int(prop.get("cell", 0)) >= cols * (tex.get_height() / (tex.get_width() / cols)):
			bad.append(str(t.get("id", "")))
	assert_true(n >= 50, "키트 시트를 쓰는 소품 타일: %d" % n)
	assert_true(bad.is_empty(), "시트 밖 칸: %s" % [", ".join(bad)])
