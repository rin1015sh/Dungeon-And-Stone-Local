extends SceneTree
## 탐험 맵 몸 그림(docs/PROMPT_ART_MAP.md A4).
##   godot --headless --path . --script res://tools/paint_actors.gd [-- --only=<종족|monsters|몬스터 id,…>]
## 탐험가: 피어 앤 헝거 맵 그림처럼 2D 픽셀로 바로 찍는다(tools/actor_art/ — 곧게 선 약 3.3등신·큰 머리카락·눈 점만 있는 얼굴·
##   붙어 선 다리·진한 바깥선·4단 명암, 옷은 전투 그림 설계 Party.spec_of의 색·구성 — 사용자 2026-10-17, ASSUMPTIONS AM27).
##   한 장의 시트 → assets/actors/<종족>.webp. 줄 = [아래, 왼쪽, 오른쪽, 위](오른쪽 = 왼쪽 좌우 반전), 칸 = [걸음 A, 섬, 걸음 B].
## 몬스터: 전투 일러스트(assets/monsters/<id>.webp — 정면)를 몸 높이 색인으로 데이터 size에 맞춰 줄인다 → assets/actors/monsters/<id>.webp
##   (뒷모습 그림이 있으면 <id>_back.webp도). 걷기는 게임이 흔들어 보인다(MonsterView). 줄인 뒤 1px 잉크 바깥선.
## 칸 크기·배율은 render.json view.actor_sheet.

const Party := preload("res://tools/monster_art/Party.gd")
const Explorer := preload("res://tools/actor_art/Explorer.gd")

const PHASES := [1.0, 0.0, -1.0]  ## 칸 순서: 걸음 A · 섬 · 걸음 B
const OUTLINE := Color("#120c0a")

var _cfg: Dictionary = {}


func _init() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	var db := GameDatabase.new()
	db.load_all("res://data")
	_cfg = JsonUtil.get_dict(JsonUtil.get_dict(db.render, "view"), "actor_sheet")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/actors/monsters"))
	for race: String in Party.RACES:
		if only.is_empty() or only.has(race):
			_explorer(race)
	for id: String in db.get_collection("monsters"):
		if only.is_empty() or only.has("monsters") or only.has(id):
			_monster(id, JsonUtil.get_float(db.get_entry("monsters", id), "size", 1.0))
	quit(0)


## 탐험가 걷기 시트.
func _explorer(race: String) -> void:
	var t0 := Time.get_ticks_msec()
	var cell := _cell()
	var foot := JsonUtil.get_int(_cfg, "foot_px", 4)
	var sheet := Image.create_empty(cell.x * PHASES.size(), cell.y * 4, false, Image.FORMAT_RGBA8)
	var ex := Explorer.new()
	for c in PHASES.size():
		for row: int in [0, 1, 3]:
			var img := ex.paint(race, ["down", "left", "", "up"][row], float(PHASES[c]), cell, foot)
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i(c * cell.x, row * cell.y))
			if row == 1:
				img.flip_x()
				sheet.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i(c * cell.x, 2 * cell.y))
	var path := "res://assets/actors/%s.webp" % race
	sheet.save_webp(path, false)
	print("그림: %s %dx%d (%d ms)" % [path, sheet.get_width(), sheet.get_height(), Time.get_ticks_msec() - t0])


## 몬스터: 전투 그림을 몸 높이 색인으로 맞춰 줄인다(사람 키 × size).
func _monster(id: String, size: float) -> void:
	var idx_path := "res://assets/monsters/index.json"
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(idx_path)) if FileAccess.file_exists(idx_path) else {}
	for suffix: String in ["", "_back"]:
		var src := "res://assets/monsters/%s%s.webp" % [id, suffix]
		if not FileAccess.file_exists(src):
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(src))
		img.convert(Image.FORMAT_RGBA8)
		var body := float((index as Dictionary).get(id + suffix, (index as Dictionary).get(id, img.get_height())))
		var want := JsonUtil.get_float(_cfg, "body_px", 84.0) * size
		var out := _shrink(img, Vector2(img.get_width() * 0.5, img.get_height()), want / maxf(1.0, body))
		var used := out.get_used_rect()
		var w := maxi(2, used.size.x + 4)
		var canvas := Image.create_empty(w + (w % 2), used.end.y + 2, false, Image.FORMAT_RGBA8)  # 아래 끝 = 발, 가로 가운데 = 몸 가운데
		canvas.blit_rect(out, Rect2i(used.position.x, 0, used.size.x, used.end.y), Vector2i((canvas.get_width() - used.size.x) / 2, 0))
		canvas.save_webp("res://assets/actors/monsters/%s%s.webp" % [id, suffix], false)
	print("그림: 맵 몬스터 %s" % id)


## 그림을 f배로 줄여(발 = foot) 바깥선을 두른다. 결과의 아래 가운데가 발.
func _shrink(img: Image, foot: Vector2, f: float) -> Image:
	var w := maxi(1, roundi(img.get_width() * f))
	var h := maxi(1, roundi(img.get_height() * f))
	var small := img.duplicate() as Image
	small.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var fx := roundi(foot.x * f)
	var fy := roundi(foot.y * f)
	var half := maxi(fx, w - fx) + 2
	var out := Image.create_empty(half * 2, fy + 2, false, Image.FORMAT_RGBA8)  # 발을 아래 가운데로
	out.blit_rect(small, Rect2i(0, 0, w, mini(h, fy + 2)), Vector2i(half - fx, 0))
	_outline(out)
	return out


## 1px 잉크 바깥선(불투명 칸 둘레의 투명 칸).
func _outline(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var marks: Array[Vector2i] = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.35:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and img.get_pixel(q.x, q.y).a > 0.6:
					marks.append(Vector2i(x, y))
					break
	for m in marks:
		var c := img.get_pixel(m.x, m.y)
		img.set_pixel(m.x, m.y, OUTLINE.lerp(c, c.a * 0.3) if c.a > 0.0 else Color(OUTLINE, 0.85))


func _cell() -> Vector2i:
	var c := JsonUtil.get_array(_cfg, "cell")
	return Vector2i(int(c[0]), int(c[1])) if c.size() == 2 else Vector2i(72, 100)
