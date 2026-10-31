extends SceneTree
## 옷차림 시안 미리보기(고르기 전 — 전투 동작 전체를 그리지 않는다, 사용자 2026-10-30 "여러 복장을 보여 주고 하나를 고르면 그것만"):
## 전투 그림 크기의 앞·옆·뒤 세 장을 한 줄로 → <out>/<id>_views.png. 맵 걷기 시트는 paint_actors --look, 비교 그림은 tools/looks_sheet.py.
##   godot --headless --path . --script res://tools/paint_look_preview.gd -- --look=<id,…> --out=<폴더>

const Party := preload("res://tools/monster_art/Party.gd")
const MapLooks := preload("res://tools/monster_art/MapLooks.gd")
const TURNS := [PI, -1.8, 0.0]  ## 앞 · 옆(얼굴이 보는 사람 쪽으로 살짝) · 뒤(전투 무대에서 보이는 쪽)
const SEED := 2026


func _init() -> void:
	var out := "res://tools/out"
	var looks := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--look="):
			looks = a.trim_prefix("--look=").split(",")
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for id: String in looks:
		if not MapLooks.has(id):
			print("없는 옷차림: ", id)
			continue
		var t0 := Time.get_ticks_msec()
		var base := MapLooks.apply(Party.spec_of(MapLooks.race_of(id) + "_back"), id)
		var imgs: Array[Image] = []
		for turn: float in TURNS:
			var sp := base.duplicate(true)
			sp["turn"] = turn
			if turn == PI:
				sp["light"] = Vector3(-0.2, -0.5, 0.85)  # 앞모습은 앞에서 비춘다(paint_actors FRONT_ROW_LIGHT와 같은 까닭 — 얼굴 반이 그늘에 묻힌다)
			imgs.append(Party.figure(sp, SEED + id.hash() % 9973).to_image())
		var row := _row(imgs)
		row.save_png(out.path_join(id + "_views.png"))
		print("시안: %s %dx%d (%d ms)" % [id, row.get_width(), row.get_height(), Time.get_ticks_msec() - t0])
	quit(0)


## 세 장을 발(그림 아래 끝)을 맞춰 나란히.
func _row(imgs: Array[Image]) -> Image:
	var rects: Array[Rect2i] = []
	var w := 0
	var h := 0
	for img in imgs:
		var u := img.get_used_rect().grow(8).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		rects.append(u)
		w += u.size.x
		h = maxi(h, u.size.y)
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var x := 0
	for i in imgs.size():
		var u := rects[i]
		out.blit_rect(imgs[i], u, Vector2i(x, h - u.size.y))
		x += u.size.x
	return out
