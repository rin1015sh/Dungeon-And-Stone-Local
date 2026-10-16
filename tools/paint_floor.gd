extends SceneTree
## 탐험 맵 재질 아틀라스 생성기(docs/PROMPT_ART_MAP.md A2 · docs/ART.md §6): 1층 수정동굴의 바닥·벽·물·진흙을
## 손으로 칠한 듯한 칸 그림(변형 여럿, 이어 붙여도 이음매 없음)으로 그려 assets/floor/에 저장한다.
##   godot --headless --path . --script res://tools/paint_floor.gd [-- --only=<장소|style>]
## 칸 크기 = render.json view.floor_tile_px × art_scale, 벽 앞면 = (wall_tile_px 높이 − 바닥 칸) × art_scale.
## 아틀라스: 바닥 = 한 줄에 변형 칸, 벽 = 윗면 줄 + 앞면 줄(앞면 아래 끝 = 바닥 접점). 설계는 tools/floor_art/Specs.gd.
## 그림 평균 색은 그 타일의 data 색에 맞춘다(빛·근흑색·안개는 게임이 곱한다 — FloorView.vertex_mul).

const Cave := preload("res://tools/floor_art/Cave.gd")
const Specs := preload("res://tools/floor_art/Specs.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Paint := preload("res://tools/city_art/Paint.gd")


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
	var face := (int(wt[1]) - int(ft[1])) * scale
	for spec: Dictionary in Specs.ATLASES:
		if not only.is_empty() and only != spec["place"] and only != spec["style"]:
			continue
		var t := db.get_entry("tiles", str(spec["tile"]))
		var colors := JsonUtil.get_dict(t, "colors")
		var n := int(spec["variants"])
		var img: Image
		if spec["kind"] == "wall":
			var top := _row(spec, "top", n, cell, cell, Color.from_string(JsonUtil.get_str(colors, "top"), Color.GRAY))
			var fr := _row(spec, "face", n, cell, face, Color.from_string(JsonUtil.get_str(colors, "face"), Color.GRAY))
			img = Image.create_empty(n * cell, cell + face, false, Image.FORMAT_RGBA8)
			img.blit_rect(top, Rect2i(0, 0, n * cell, cell), Vector2i.ZERO)
			img.blit_rect(fr, Rect2i(0, 0, n * cell, face), Vector2i(0, cell))
		else:
			img = _row(spec, "floor", n, cell, cell, Color.from_string(JsonUtil.get_str(colors, "floor"), Color.GRAY))
		var path := str(spec["path"])
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
		img.save_webp(path, false)
		print("그림: %s %dx%d (변형 %d)" % [path, img.get_width(), img.get_height(), n])
	quit(0)


## 한 줄(변형 n칸)을 칠해 색 보정하고 평균 색을 target에 맞춘 이미지.
func _row(spec: Dictionary, part: String, n: int, w: int, h: int, target: Color) -> Image:
	var cells: Array = []
	var sum := Vector3.ZERO
	var count := 0
	for v in n:
		var p: Paint = Cave.cell(str(spec["style"]), part, v, w, h, target, int(spec["seed"]) + (0 if part != "face" else 50))
		Ink.grade(p, 0.18, 1.08, Color("#1a1412"), Color("#e0d2b0"), 0.12)
		cells.append(p)
		for i in w * h:
			var c := Color(p.buf[i * 4], p.buf[i * 4 + 1], p.buf[i * 4 + 2])
			if c.get_luminance() < 0.6:  # 스스로 빛나는 수정은 평균에서 뺀다
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
				img.set_pixel(v * w + x, y, Color(adj.lerp(c, glow), 1.0))
	return img
