extends SceneTree
## 탐험 맵 몸 그림(docs/PROMPT_ART_MAP.md A4): 전투 그림과 같은 도구로 그려 맵 크기로 줄인다.
##   godot --headless --path . --script res://tools/paint_actors.gd [-- --only=<종족|monsters|몬스터 id,…>]
## 탐험가: 아군 전투 그림의 3D 몸(Party·Back)을 앞(아래)·옆(오른쪽)·뒤(위)로 돌리고 걷기 세 장(왼발 앞·섬·오른발 앞)을 그려
##   한 장의 시트로 → assets/actors/<종족>.webp. 줄 = [아래, 왼쪽, 오른쪽, 위](왼쪽 = 오른쪽 좌우 반전), 칸 = [걸음 A, 섬, 걸음 B].
##   피어 앤 헝거 맵 그림처럼 사람 키 1.3칸 안팎·약간 큰 머리와 짧고 굵은 몸(약 3.7등신 — HEAD·LEGS·WIDE·BULK)·진한 바깥선·칠한 그늘(장비는 몸에 그리지 않는다 — 사용자 결정 a+b, ASSUMPTIONS AM27).
## 몬스터: 전투 일러스트(assets/monsters/<id>.webp — 정면)를 몸 높이 색인으로 데이터 size에 맞춰 줄인다 → assets/actors/monsters/<id>.webp
##   (뒷모습 그림이 있으면 <id>_back.webp도). 걷기는 게임이 흔들어 보인다(MonsterView).
## 칸 크기·배율은 render.json view.actor_sheet. 줄인 뒤 1px 잉크 바깥선을 두른다(작은 그림에서 윤곽이 읽히게).

const Party := preload("res://tools/monster_art/Party.gd")
const Paint := preload("res://tools/city_art/Paint.gd")

const RENDER_H := 360.0  ## 사람 키를 이 높이로 그려 줄인다(작게 바로 그리면 붓결·눈이 뭉개진다)
const SIDE_TURN := 1.4   ## 옆모습(오른쪽을 본다) 돌림 — 거의 옆얼굴
const PITCH := 0.35      ## 3/4 시점 — 보는 사람 쪽으로 나온 발·팔이 화면 아래로(Back.proj)
const PHASES := [1.0, 0.0, -1.0]  ## 칸 순서: 왼발 앞 · 섬 · 오른발 앞
const OUTLINE := Color("#120c0a")
## 몸 비율(사용자 2026-10-17 "피어 앤 헝거 화면의 캐릭터 비율 그대로 — 약간 대두의 두꺼운 캐릭터"): 약 3.7등신
const HEAD := 2.0   ## 머리 크기 배율(전투 그림 = 1, 약 7.5등신)
const LEGS := 0.72  ## 다리 길이 배율
const WIDE := 1.2   ## 어깨·엉덩이 폭 배율
const BULK := 1.2   ## 팔다리·몸통 굵기 배율
const SEED := 4242

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
	var cols := PHASES.size()
	var sheet := Image.create_empty(cell.x * cols, cell.y * 4, false, Image.FORMAT_RGBA8)
	var turns := {0: PI, 2: SIDE_TURN, 3: 0.0}  # 줄 → 돌림(1 = 왼쪽은 2를 뒤집는다)
	for row: int in [0, 2, 3]:
		for c in cols:
			var img := _figure(race, float(turns[row]), float(PHASES[c]))
			_put(sheet, img, Vector2i(c, row), cell)
			if row == 2:
				var flipped := img.duplicate() as Image
				flipped.flip_x()
				_put(sheet, flipped, Vector2i(c, 1), cell)
	var path := "res://assets/actors/%s.webp" % race
	sheet.save_webp(path, false)
	print("그림: %s %dx%d (%d ms)" % [path, sheet.get_width(), sheet.get_height(), Time.get_ticks_msec() - t0])


## 한 장: 돌림·걸음으로 그려 사람 키 = actor_sheet.body_px(그림 배율 적용)로 줄이고 바깥선. 발 = 그림 아래 가운데.
func _figure(race: String, turn: float, phase: float) -> Image:
	var sp := Party.spec_of(race + "_back").duplicate(true)
	var k := float(sp.get("height", Party.REF_H)) / Party.REF_H  # 바바리안은 더 크다
	sp["height"] = RENDER_H * k
	sp["turn"] = turn
	sp["pitch"] = PITCH
	sp["pose"] = (sp.get("pose", {}) as Dictionary).merged({"arm_l": "hang", "arm_r": "hang"}, true)
	sp["head"] = float(sp.get("head", 1.0)) * HEAD  # 피어 앤 헝거 맵 비율: 약간 큰 머리·짧고 굵은 몸
	sp["legs"] = LEGS
	sp["wide"] = WIDE
	sp["bulk"] = float(sp.get("bulk", 1.0)) * BULK
	if phase != 0.0:
		sp["walk"] = phase
	var p: Paint = Party.figure(sp, SEED + race.hash() % 997)
	var img := p.to_image()
	var H := float(sp["height"])
	var foot := Vector2(img.get_width() * 0.5, img.get_height() - H * 0.03)
	return _shrink(img, foot, JsonUtil.get_float(_cfg, "body_px", 84.0) / RENDER_H)


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


## 시트 칸에 발이 아래 가운데(칸 아래에서 foot_px 위)에 오게 넣는다.
func _put(sheet: Image, img: Image, at: Vector2i, cell: Vector2i) -> void:
	var foot := JsonUtil.get_int(_cfg, "foot_px", 4)
	var dst := Vector2i(at.x * cell.x + (cell.x - img.get_width()) / 2, at.y * cell.y + cell.y - foot - img.get_height())
	var src := Rect2i(Vector2i.ZERO, img.get_size())
	if dst.y < at.y * cell.y:  # 칸보다 크면 위를 자른다
		src.position.y = at.y * cell.y - dst.y
		src.size.y -= src.position.y
		dst.y = at.y * cell.y
	if dst.x < at.x * cell.x:
		src.position.x = at.x * cell.x - dst.x
		src.size.x -= 2 * src.position.x
		dst.x = at.x * cell.x
	sheet.blend_rect(img, src, dst)
