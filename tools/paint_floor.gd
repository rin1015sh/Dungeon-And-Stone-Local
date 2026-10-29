extends SceneTree
## 탐험 맵 재질 아틀라스 생성기(docs/PROMPT_ART_MAP.md A2 · docs/ART.md §6): 1층 수정동굴의 바닥·벽·물·진흙을
## 손으로 칠한 듯한 칸 그림(변형 여럿, 이어 붙여도 이음매 없음)으로 그려 assets/floor/에 저장한다.
##   godot --headless --path . --script res://tools/paint_floor.gd [-- --only=<장소|style>]
## 칸 크기 = render.json view.floor_tile_px × art_scale, 벽 앞면 = (wall_tile_px 높이 − 바닥 칸) × art_scale.
## 아틀라스: 바닥 = 한 줄에 변형 칸, 벽 = 윗면 줄 + 앞면 줄(앞면 = 앞면 높이 + 밑동 view.wall_skirt_px — 밑동은 바닥 칸 위로 내려와 들쭉날쭉 끝난다). 설계는 tools/floor_art/Specs.gd.
## 그림 평균 색은 그 타일의 data 색에 맞춘다(빛·근흑색·안개는 게임이 곱한다 — FloorView.vertex_mul).

const Cave := preload("res://tools/floor_art/Cave.gd")
const Specs := preload("res://tools/floor_art/Specs.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Marks := preload("res://tools/floor_art/Marks.gd")
const Props := preload("res://tools/floor_art/Props.gd")
const RiftCommon := preload("res://tools/floor_art/rift/Common.gd")
const RiftCliff := preload("res://tools/floor_art/rift/Cliff.gd")
const RIFT_SPECS := "res://tools/floor_art/rift/specs.json"


func _init() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	var db := GameDatabase.new()
	db.load_all("res://data")
	var view := JsonUtil.get_dict(db.render, "view")
	var scale := JsonUtil.get_int(view, "art_scale", 2)
	var ft := JsonUtil.get_array(view, "floor_tile_px")
	var wt := JsonUtil.get_array(view, "wall_tile_px")
	var cell := int(ft[0]) * scale
	var skirt := JsonUtil.get_int(view, "wall_skirt_px", 0) * scale
	Cave.skirt = skirt
	var face := (int(wt[1]) - int(ft[1])) * scale + skirt
	for spec: Dictionary in Specs.ATLASES:
		if not only.is_empty() and only != spec["place"] and only != spec["style"]:
			continue
		var t := db.get_entry("tiles", str(spec["tile"]))
		var colors := JsonUtil.get_dict(t, "colors")
		var n := int(spec["variants"])
		var img: Image
		if spec["kind"] == "wall":
			var fh := face if not spec.has("face_px") else int(spec["face_px"]) * scale + skirt
			var top := _row(spec, "top", n, cell, cell, Color.from_string(JsonUtil.get_str(colors, "top"), Color.GRAY))
			var fr := _row(spec, "face", n, cell, fh, Color.from_string(JsonUtil.get_str(colors, "face"), Color.GRAY))

			img = Image.create_empty(n * cell, cell + fh, false, Image.FORMAT_RGBA8)
			img.blit_rect(top, Rect2i(0, 0, n * cell, cell), Vector2i.ZERO)
			img.blit_rect(fr, Rect2i(0, 0, n * cell, fh), Vector2i(0, cell))
		else:
			img = _row(spec, "floor", n, cell, cell, Color.from_string(JsonUtil.get_str(colors, "floor"), Color.GRAY))
		var path := str(spec["path"])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
		img.save_webp(path, false)
		print("그림: %s %dx%d (변형 %d)" % [path, img.get_width(), img.get_height(), n])
	for spec: Dictionary in Specs.DECALS:
		if not only.is_empty() and only != spec["place"] and only != spec["style"]:
			continue
		_decal_sheet(spec, cell)
	for spec: Dictionary in Specs.PROPS:
		if not only.is_empty() and only != spec["place"] and only != spec["style"]:
			continue
		var pc := int(round(cell * float(spec["size"])))
		var cols := int(spec["cols"])
		var rows := ceili(Props.ORDER.size() / float(cols))
		var img := Image.create_empty(cols * pc, rows * pc, false, Image.FORMAT_RGBA8)
		for k in Props.ORDER.size():
			var p: Paint = Props.paint(str(Props.ORDER[k]), pc, int(spec["seed"]))
			Ink.grade(p, 0.18, 1.08, Color("#1a1412"), Color("#e0d2b0"), 0.12)
			img.blit_rect(p.to_image(), Rect2i(0, 0, pc, pc), Vector2i((k % cols) * pc, (k / cols) * pc))
		img.save_webp(str(spec["path"]), false)
		print("그림: %s %dx%d (소품 %d)" % [spec["path"], img.get_width(), img.get_height(), Props.ORDER.size()])
	_rift(db, only, cell, face, skirt, scale)
	quit(0)


## 균열 장소 그림(A5 — tools/floor_art/rift/specs.json · <place>.gd): 바닥·벽 아틀라스, 서 있는 소품 시트, 뒷배경.
## --only=<place>(bf·gc·gm·it) 또는 --only=<place>:stand|cliff|atlas 로 일부만.
func _rift(db: GameDatabase, only: String, cell: int, face: int, skirt: int, scale: int) -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RIFT_SPECS))
	RiftCommon.skirt = skirt
	var n := int(spec["variants"])
	for place: String in spec["places"]:
		var part_only := ""
		if not only.is_empty():
			if only.split(":")[0] != place:
				continue
			part_only = only.split(":")[1] if only.contains(":") else ""
		var mod := load("res://tools/floor_art/rift/%s.gd" % place) as GDScript
		var pd: Dictionary = spec["places"][place]
		var dir := "res://assets/floor/%s" % place
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		if part_only.is_empty() or part_only == "atlas":
			for f: Dictionary in pd["floors"]:
				var colors := JsonUtil.get_dict(db.get_entry("tiles", str(f["tile"])), "colors")
				var sd := 3000 + str(f["style"]).hash() % 1000
				var row := _row({"seed": sd}, "floor", n, cell, cell, Color.from_string(JsonUtil.get_str(colors, "floor"), Color.GRAY),
					func(part: String, v: int, w: int, h: int, col: Color, s: int) -> Paint: return RiftCommon.cell(mod, str(f["style"]), part, v, w, h, col, s))
				row.save_webp("%s/%s.webp" % [dir, f["style"]], false)
				print("그림: %s/%s.webp" % [dir, f["style"]])
			for wd: Dictionary in pd["walls"]:
				var colors := JsonUtil.get_dict(db.get_entry("tiles", str(wd["tile"])), "colors")
				var sd := 5000 + str(wd["style"]).hash() % 1000
				var fh := int(wd["face_px"]) * scale + skirt
				var painter := func(part: String, v: int, w: int, h: int, col: Color, s: int) -> Paint: return RiftCommon.cell(mod, str(wd["style"]), part, v, w, h, col, s)
				var top := _row({"seed": sd}, "top", n, cell, cell, Color.from_string(JsonUtil.get_str(colors, "top"), Color.GRAY), painter)
				var fr := _row({"seed": sd}, "face", n, cell, fh, Color.from_string(JsonUtil.get_str(colors, "face"), Color.GRAY), painter)
				var img := Image.create_empty(n * cell, cell + fh, false, Image.FORMAT_RGBA8)
				img.blit_rect(top, Rect2i(0, 0, n * cell, cell), Vector2i.ZERO)
				img.blit_rect(fr, Rect2i(0, 0, n * cell, fh), Vector2i(0, cell))
				img.save_webp("%s/%s.webp" % [dir, wd["style"]], false)
				print("그림: %s/%s.webp" % [dir, wd["style"]])
		if part_only.is_empty() or part_only == "stand":
			var sc: Array = spec["stand_cell"]
			var cw := int(sc[0]) * cell
			var ch := int(sc[1]) * cell
			var cols := int(spec["stand_cols"])
			var stands: Array = pd["stands"]
			var img := Image.create_empty(cols * cw, ceili(stands.size() / float(cols)) * ch, false, Image.FORMAT_RGBA8)
			for k in stands.size():
				var p: Paint = mod.call("stand", str(stands[k]), cw, ch, 7000 + k * 31)
				Ink.grade(p, 0.18, 1.08, Color("#1a1412"), Color("#e0d2b0"), 0.12)
				img.blit_rect(p.to_image(), Rect2i(0, 0, cw, ch), Vector2i((k % cols) * cw, (k / cols) * ch))
			img.save_webp(dir + "/stand.webp", false)
			print("그림: %s/stand.webp %dx%d (소품 %d)" % [dir, img.get_width(), img.get_height(), stands.size()])
		if (part_only.is_empty() or part_only == "cliff") and pd.has("cliff"):
			var cs: Array = spec["cliff_size"]
			var cp: Paint = RiftCliff.paint(int(cs[0]), int(cs[1]), 9000, pd["cliff"])
			Ink.grade(cp, 0.18, 1.08, Color("#1a1412"), Color("#e0d2b0"), 0.12)
			cp.save(dir + "/chasm.webp")
			print("그림: %s/chasm.webp" % dir)


## 데칼 시트: 줄 = 종류, 칸 = 변형(투명 RGBA, 색 보정만 — 평균 맞추기 없음).
func _decal_sheet(spec: Dictionary, cell: int) -> void:
	var kinds: Array = spec["kinds"]
	var n := int(spec["variants"])
	var img := Image.create_empty(n * cell, kinds.size() * cell, false, Image.FORMAT_RGBA8)
	for row in kinds.size():
		for v in n:
			var p: Paint = Decals.paint(str(kinds[row]), v, cell, int(spec["seed"]) + row * 37)
			Ink.grade(p, 0.18, 1.08, Color("#1a1412"), Color("#e0d2b0"), 0.12)
			img.blit_rect(p.to_image(), Rect2i(0, 0, cell, cell), Vector2i(v * cell, row * cell))
	var path := str(spec["path"])
	img.save_webp(path, false)
	print("그림: %s %dx%d (데칼 %d종 × %d)" % [path, img.get_width(), img.get_height(), kinds.size(), n])


## 한 줄(변형 n칸)을 칠해 색 보정하고 평균 색을 target에 맞춘 이미지. painter(part, v, w, h, col, seed)가 있으면 그것으로(균열 장소).
func _row(spec: Dictionary, part: String, n: int, w: int, h: int, target: Color, painter: Callable = Callable()) -> Image:
	var cells: Array = []
	var sum := Vector3.ZERO
	var count := 0
	for v in n:
		var sd := int(spec["seed"]) + (0 if part != "face" else 50)
		var p: Paint
		if painter.is_valid():
			p = painter.call(part, v, w, h, target, sd)
		elif spec.get("painter", "") == "marks":
			p = Marks.cell(str(spec["style"]), part, v, w, h, target, sd)
		else:
			p = Cave.cell(str(spec["style"]), part, v, w, h, target, sd)
		Ink.grade(p, 0.18, 1.08, Color("#1a1412"), Color("#e0d2b0"), 0.12)
		cells.append(p)
		for i in w * h:
			var c := Color(p.buf[i * 4], p.buf[i * 4 + 1], p.buf[i * 4 + 2])
			if c.get_luminance() < 0.6 and p.buf[i * 4 + 3] > 0.5:  # 스스로 빛나는 수정·투명한 밑동은 평균에서 뺀다
				sum += Vector3(c.r, c.g, c.b)
				count += 1
	var mean := sum / maxf(1.0, count)
	var k := Vector3(clampf(target.r / maxf(mean.x, 0.01), 0.4, 3.0), clampf(target.g / maxf(mean.y, 0.01), 0.4, 3.0),
		clampf(target.b / maxf(mean.z, 0.01), 0.4, 3.0))
	var img := Image.create_empty(n * w, h, false, Image.FORMAT_RGBA8)
	for v in n:
		var p: Paint = cells[v]
		for y in h:
			for x in w:
				var i := (y * w + x) * 4
				var c := Color(p.buf[i], p.buf[i + 1], p.buf[i + 2])
				var glow := clampf((c.get_luminance() - 0.6) * 2.5, 0.0, 1.0)  # 빛나는 곳은 덜 맞춘다
				var adj := Color(minf(1.0, c.r * k.x), minf(1.0, c.g * k.y), minf(1.0, c.b * k.z))
				img.set_pixel(v * w + x, y, Color(adj.lerp(c, glow), p.buf[i + 3]))
	return img
