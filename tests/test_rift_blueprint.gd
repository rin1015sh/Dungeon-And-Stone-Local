extends TestCase
## A5 균열 설계도 지도(docs/plans/rift_spaces.md, RiftBlueprintGenerator): 모든 챕터가 설계도를 쓰고,
## 시작에서 조우·출구·함정 자리에 걸어서 닿으며, 히든 피스는 옆 칸에서 살필 수 있고, 정해진 자리에 놓인다.


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14})
	pc.pool.fill_all()
	return pc


func _enter(rift: String) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), _pc(), GameClock.new(), Rng.new(5), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, rift, s.pos)
	return s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])


func test_every_chapter_uses_blueprint() -> void:
	for rid: String in db.get_collection("rifts"):
		for ch: Variant in JsonUtil.get_array(db.get_entry("rifts", rid), "chapters"):
			var path := JsonUtil.get_str(JsonUtil.get_dict(ch, "map"), "blueprint")
			assert_true(FloorMapFile.exists(path), "설계도: %s %s" % [rid, JsonUtil.get_str(ch, "id")])
			assert_eq(RiftBlueprintGenerator.problems(FloorMapFile.read(path), db).size(), 0, "설계도 형식: " + path)


func test_chapters_are_walkable_and_anchored() -> void:
	for rid: String in db.get_collection("rifts"):
		var cs := _enter(rid)
		var run := cs.rift_run
		for i in run.chapters().size():
			if i > 0:
				cs = run.build_chapter(i)
			var where := "%s %d" % [rid, i + 1]
			var m := cs.map
			assert_eq(cs.floor_def["generator"], "rift_blueprint", where)
			assert_true(m.width * m.height >= 2000, "챕터가 넓다(네모 방 이은 48×16이 아니다): " + where)
			var seen := m.reachable_from(m.entry)
			for p: Vector2i in m.slots:
				assert_eq(seen[m.idx(p)], 1, "조우 자리에 닿는다 %s %s" % [where, p])
			assert_eq(seen[m.idx(m.portals[0]["pos"])], 1, "출구에 닿는다: " + where)
			var spots: Array = m.anchors.get("hazards", [])
			for p: Vector2i in spots:
				assert_true(run.hazards.at.has(p), "함정은 정해진 자리에 %s %s" % [where, p])
			for p: Vector2i in run.hidden.at:
				var ok := false
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					ok = ok or (m.in_bounds(p + d) and seen[m.idx(p + d)] == 1)
				assert_true(ok, "히든 피스 옆 칸에 닿는다 %s %s" % [where, p])
			var listed := JsonUtil.get_array(run.chapters()[i], "hidden")
			assert_eq(run.hidden.at.size(), listed.filter(func(h: Variant) -> bool: return not (h as Dictionary).has("reveal")).size(),
				"히든 피스가 다 놓인다(나중에 드러나는 것 빼고): " + where)
			for p: Vector2i in m.anchors.get("hidden", []):  # 나중에 드러나는 자리도 옆 칸에 닿는다
				var near := false
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					near = near or (m.in_bounds(p + d) and seen[m.idx(p + d)] == 1)
				assert_true(near, "히든 피스 자리 옆 칸에 닿는다 %s %s" % [where, p])


## 함정·위험 묶음은 설계도 바닥 무늬에 맞물린다(사용자 2026-10-23): 묶음 칸은 모두 가운데 칸과 같은 설계도 바닥(카펫·홈·계단을 넘지 않는다),
## 한 칸짜리 묶음은 없다.
func test_hazards_fit_floor_pattern() -> void:
	for rid: String in db.get_collection("rifts"):
		var cs := _enter(rid)
		var run := cs.rift_run
		for i in run.chapters().size():
			if i > 0:
				cs = run.build_chapter(i)
			var bp := FloorMapFile.read(JsonUtil.get_str(JsonUtil.get_dict(run.chapters()[i], "map"), "blueprint"))
			var legend := JsonUtil.get_dict(bp, "legend")
			var rows := JsonUtil.get_array(bp, "rows")
			var tile_of := func(q: Vector2i) -> String:
				return str(legend.get(str(rows[q.y])[q.x], JsonUtil.get_str(bp, "floor")))
			for p: Vector2i in cs.map.anchors.get("hazards", []):
				var cells: Array = run.hazards.at[p]["cells"]
				var where := "%s %d챕터 %s" % [rid, i + 1, p]
				assert_true(cells.size() >= 2, "한 칸짜리 함정이 아니다 " + where)
				for q: Vector2i in cells:
					assert_eq(tile_of.call(q), tile_of.call(p), "묶음 칸 %s은 가운데와 같은 바닥 %s" % [q, where])


## 균열은 시야 제한 없음(사용자 2026-10-18) — 챕터 지도 전체가 보일 만큼 넓다.
func test_rift_vision_unlimited() -> void:
	for rid: String in db.get_collection("rifts"):
		var cs := _enter(rid)
		var fd := cs.rift_run.chapter_floor_def(0)
		assert_true(float(fd["visibility_cap_m"]) >= 100.0 and float(fd["ambient_light_m"]) >= 100.0, "시야 제한 없음: " + rid)


func test_void_tiles_block_walk_not_sight() -> void:
	for id: String in ["bf_void", "gc_void", "gm_void", "it_void"]:
		var t := TileDef.from_dict(db.get_entry("tiles", id), 0)
		assert_true(t.is_void and not t.walkable and not t.blocks_sight, "낭떠러지: " + id)


## 낭떠러지는 세계 좌표 절벽 셰이더(AM49): 칸 지도 그림 r = 허공, g = 나무 발판(다리 — 깎지 않는다), 화면 고정 뒷배경은 없다.
func test_abyss_mask_and_no_backdrop() -> void:
	var cs := _enter("rift_green_mine")
	cs.rift_run.debug_clear()
	var fd := cs.rift_run.chapter_floor_def(1)
	var art := FloorArt.resolve(db.render, fd)
	assert_false(art.abyss.is_empty(), "탄광 낭떠러지 설정")
	assert_false(JsonUtil.get_dict(fd, "art").has("backdrop"), "화면 고정 뒷배경 없음")
	var map := RiftBlueprintGenerator.new().generate(db, fd, Rng.new(1))
	var tex := Abyss.mask_texture(map)
	var img := tex.get_image()
	var wrong := 0
	var voids := 0
	var beams := 0
	for y in map.height:
		for x in map.width:
			var d := map.def_at(Vector2i(x, y))
			var c := img.get_pixel(x, y)
			if (c.r > 0.5) != d.is_void or (c.g > 0.5) != (d.void_edge == "beam"):
				wrong += 1
			voids += 1 if d.is_void else 0
			beams += 1 if d.void_edge == "beam" else 0
	assert_eq(wrong, 0, "칸 지도 그림 = 허공·발판")
	assert_true(voids > 0 and beams > 0, "무너진 다리 챕터에 허공(%d)과 다리 발판(%d)" % [voids, beams])


## 그림 계약(tools/floor_art/rift/specs.json): 균열 장소의 바닥·벽은 재질 아틀라스, 소품은 서 있는 그림(art.stand — 벽 종류),
## 설계도에 쓰인 걷지 못하는 물건(낭떠러지 제외)은 모두 그림이 있다. 균열마다 낭떠러지 절벽 면 그림이 있다.
func test_rift_tiles_have_art() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/floor_art/rift/specs.json"))
	for place: String in spec["places"]:
		var pd: Dictionary = spec["places"][place]
		for list: String in ["floors", "walls"]:
			for f: Dictionary in pd[list]:
				var def := TileDef.from_dict(db.get_entry("tiles", str(f["tile"])), 0)
				assert_true(ResourceLoader.exists(def.art_atlas), "재질 그림: %s %s" % [place, f["tile"]])
		for tid: Variant in pd["stands"]:
			var def := TileDef.from_dict(db.get_entry("tiles", str(tid)), 0)
			assert_true(def.is_wall() and ResourceLoader.exists(def.stand_sheet), "서 있는 소품 그림: " + str(tid))
	for rid: String in db.get_collection("rifts"):
		var ab := JsonUtil.get_dict(JsonUtil.get_dict(JsonUtil.get_dict(db.get_entry("rifts", rid), "look"), "art"), "abyss")
		assert_true(ResourceLoader.exists(JsonUtil.get_str(ab, "cliff")), "낭떠러지 절벽 면 그림: " + rid)
	for rid: String in db.get_collection("rifts"):
		for ch: Variant in JsonUtil.get_array(db.get_entry("rifts", rid), "chapters"):
			var data := FloorMapFile.read(JsonUtil.get_str(JsonUtil.get_dict(ch, "map"), "blueprint"))
			for c: String in JsonUtil.get_dict(data, "legend"):
				var def := TileDef.from_dict(db.get_entry("tiles", str(data["legend"][c])), 0)
				if def.is_void:
					continue
				assert_true(not def.art_atlas.is_empty() or not def.stand_sheet.is_empty(), "설계도 타일에 그림: %s %s" % [rid, def.id])
