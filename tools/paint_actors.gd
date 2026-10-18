extends SceneTree
## 탐험 맵 몸 그림(docs/PROMPT_ART_MAP.md A4): 전투 그림과 같은 도구로 그려 맵 크기로 줄인다.
##   godot --headless --path . --script res://tools/paint_actors.gd [-- --only=<종족|monsters|몬스터 id,…>]
## 탐험가: 아군 전투 그림의 3D 몸(Party·Back)을 앞(아래)·옆(오른쪽)·뒤(위)로 돌리고 걷기 세 장(왼발 앞·섬·오른발 앞)을 그려
##   한 장의 시트로 → assets/actors/<종족>.webp. 줄 = [아래, 왼쪽, 오른쪽, 위](오른쪽 = 왼쪽 좌우 반전), 칸 = [걸음 A, 섬, 걸음 B].
##   피어 앤 헝거 맵 그림처럼 곧게 선 약 3.3등신(큰 머리·마른 몸·붙인 다리)·움푹한 눈구멍 얼굴(입 없음)·대비를 키운 칠·진한 바깥선(장비는 몸에 그리지 않는다 — 사용자 결정 a+b, ASSUMPTIONS AM27).
## 몬스터: 전투 일러스트(assets/monsters/<id>.webp — 정면)를 몸 높이 색인으로 데이터 size에 맞춰 줄인다 → assets/actors/monsters/<id>.webp
##   (뒷모습 그림이 있으면 <id>_back.webp도). 걷기는 게임이 흔들어 보인다(MonsterView).
## 칸 크기·배율은 render.json view.actor_sheet. 줄인 뒤 1px 잉크 바깥선을 두른다(작은 그림에서 윤곽이 읽히게).

const Party := preload("res://tools/monster_art/Party.gd")
const MapMonster := preload("res://tools/monster_art/MapMonster.gd")
const Paint := preload("res://tools/city_art/Paint.gd")

## 정한 값(사용자 2026-10-17 — 피어 앤 헝거 맵 그림 참고 시트를 보고 여러 방법·템플릿을 비교해 고름: 방법 ⑤ + 머리 템플릿 5).
## 시험할 때는 --set=<상수 이름 소문자>=<값>으로 이번만 바꾸고 --out=<폴더>로 따로 그린다(게임 그림을 건드리지 않는다).
const RENDER_H := 168.0  ## 사람 키를 이 높이(맵 키의 2배)로 그려 반으로 줄인다 — 크게 그려 많이 줄이면 선·명암이 뭉개진다
const SIDE_TURN := 1.8   ## 옆모습 돌림 — 90°를 조금 넘겨 얼굴이 보는 사람 쪽으로 살짝(90° 안쪽은 뒤에서 본 옆모습이다)
const PITCH := 0.1       ## 3/4 시점 — 앞으로 내민 발이 조금 아래로(크게 하면 몸이 비틀려 보인다)
const PHASES := [1.0, 0.0, -1.0]  ## 칸 순서: 왼발 앞 · 섬 · 오른발 앞
const OUTLINE := Color("#120c0a")
## 몸 비율·자세(참고 시트): 머리 약 1/3, 굵고 짧은 팔다리, 살짝 숙인 몸, 늘어뜨린 팔, 큰 보폭·높이 드는 뒤꿈치
const HEAD := 2.5        ## 머리 크기 배율(전투 그림 = 1)
const LEGS := 0.68       ## 다리 길이 배율
const WIDE := 1.15       ## 어깨·엉덩이 폭 배율
const BULK := 1.35       ## 팔다리·몸통 굵기 배율
const HUNCH := 0.2       ## 숙임
const ARMS := 1.0        ## 팔 자세(ARM_POSES 번호 — 1 = 늘어뜨린 팔)
const STANCE := 0.065    ## 발 벌림(키 비율)
const KNEE := 0.08       ## 무릎 굽힘
const STEP := 0.17       ## 걸음 보폭(키 비율 — 다리 길이 배율이 곱해진다)
const HEEL := 0.13       ## 뒷발 뒤꿈치 드는 높이
const SWING := 0.15      ## 팔 흔들기
## 얼굴·머리
const MAP_FACE := 1.0    ## 1 = 맵 얼굴(깎은 얼굴형, 코·입·귀 없음), 0 = 전투 그림 얼굴
const SOCKETS := 1.0     ## 1 = 눈을 칠한 눈구멍으로
const EYE_STYLE := 1.0   ## 1 = 짙은 눈구멍 얼룩, 0 = 아몬드꼴 눈
const EYE_R := 0.06      ## 눈구멍 반지름(머리 높이 비율)
const SIDE_FACE_LIFT := 0.2  ## 옆모습 얼굴을 밝히는 정도(옆얼굴이 머리 그늘에 묻혀 어두웠다)
const HAIR_HIGH := 0.4   ## 얼굴 쪽 머리선을 올리는 정도(라디안)
const HAIR_GROW := 1.4   ## 머리숱 — 긴 머리(바바리안)
const FRINGE := 1.0      ## 1 = 긴 머리의 앞·옆머리 타래
const HAIR_FLARE := 0.04 ## 긴 머리 옆머리가 부푸는 정도
const SPIKY_GROW := 0.7  ## 짧은 머리(인간): 껍데기 숱 — 머리 모양은 아래 LOCKS 타래가 만든다
## 짧은 머리 타래(템플릿 5 — 턱선까지 내려오고 끝이 흩어진 머리, BackHair._spikes 스타일 값)
const LOCKS := {"n": 24, "w": 0.12, "wj": 0.35, "flick": 0.1, "jitter": 0.6, "front": 0.1, "temple": -0.15, "side": -0.55, "back": 0.3, "gap": 0, "light": 4}
const SIDE_LOCKS := {"temple": 0.12, "front": 0.16}  ## 옆모습에서만 덮어쓰는 타래 끝
## 마감(방법 ⑤): 전투 그림 빛 그대로, 줄인 뒤 밝기·대비·안쪽 선
const FRONT_LIGHT := 0.0
const LIGHT := Vector3(-0.2, -0.5, 0.85)
const CONTRAST := 1.12   ## 줄인 뒤 명암 대비
const GAMMA := 0.85      ## 줄인 뒤 밝기(1보다 작으면 중간 밝기를 올린다)
const LINE_STEP := 0.2   ## 이웃보다 이만큼 어두운 칸에 진한 선(겨드랑이·다리 사이·옷 경계)
const ARM_POSES := ["hang", "slump"]
const SEED := 4242

## 몬스터 맵 키(사람 키 × size 대비): 사람형은 몸 그대로, 나머지는 서 있는 앞모습 높이를 이만큼으로
const MONSTER_H := {"beast": 0.72, "crawler": 0.6, "mound": 0.7}
const MONSTER_RENDER := 2.0  ## 몬스터 그림을 맵 키의 이 배로 그려 줄인다(사람형은 RENDER_H)

var _cfg: Dictionary = {}
var _sheets: Dictionary = {}  ## 이번에 그린 몬스터 시트 {id: {cell, foot}}
var _out := "res://assets/actors"  ## --out=<폴더>: 시트를 다른 곳에 쓴다(게임 그림을 바꾸지 않고 시험해 볼 때)
var _set: Dictionary = {}  ## --set=head=2,legs=0.8: 맨 위 상수를 이번만 바꾼다(키 = 상수 이름 소문자)


func _init() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		elif a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
		elif a.begins_with("--set="):
			for kv in a.trim_prefix("--set=").split(","):
				var pair := kv.split("=")
				_set[pair[0]] = pair[1].to_float()
	var db := GameDatabase.new()
	db.load_all("res://data")
	_cfg = JsonUtil.get_dict(JsonUtil.get_dict(db.render, "view"), "actor_sheet")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/actors/monsters"))
	for race: String in Party.RACES:
		if only.is_empty() or only.has(race):
			_explorer(race)
	for id: String in db.get_collection("monsters"):
		if only.is_empty() or only.has("monsters") or only.has(id):
			if MapMonster.has(id):
				_monster_sheet(id)
			else:
				_monster(id, JsonUtil.get_float(db.get_entry("monsters", id), "size", 1.0))
	if not _sheets.is_empty():
		_save_sheet_index()
	quit(0)


## 탐험가 걷기 시트.
func _explorer(race: String) -> void:
	var t0 := Time.get_ticks_msec()
	var cell := _cell()
	var cols := PHASES.size()
	var sheet := Image.create_empty(cell.x * cols, cell.y * 4, false, Image.FORMAT_RGBA8)
	var turns := {0: PI, 1: -SIDE_TURN, 3: 0.0}  # 줄 → 돌림(2 = 오른쪽은 1을 뒤집는다 — 빛이 왼쪽 위에서 와서 왼쪽을 보게 그려야 얼굴이 밝다)
	for row: int in [0, 1, 3]:
		for c in cols:
			var img := _figure(Party.spec_of(race + "_back"), race, float(turns[row]), float(PHASES[c]))
			_put(sheet, img, Vector2i(c, row), cell)
			if row == 1:
				var flipped := img.duplicate() as Image
				flipped.flip_x()
				_put(sheet, flipped, Vector2i(c, 2), cell)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	var path := _out.path_join("%s.webp" % race)
	sheet.save_webp(path, false)
	print("그림: %s %dx%d (%d ms)" % [path, sheet.get_width(), sheet.get_height(), Time.get_ticks_msec() - t0])


## 한 장(사람형): 돌림·걸음으로 그려 사람 키 = actor_sheet.body_px × k(그림 배율 적용)로 줄이고 바깥선. 발 = 그림 아래 가운데.
## base = 3D 몸 설계(Party 형식), extra = 맨 위 상수 대신 쓸 맵 값(몬스터 — MapMonster.spec_of map), size = 사람 키 대비.
func _figure(base: Dictionary, name: String, turn: float, phase: float, extra: Dictionary = {}, size: float = -1.0) -> Image:
	var sp := base.duplicate(true)
	var k := size if size > 0.0 else float(sp.get("height", Party.REF_H)) / Party.REF_H  # 바바리안은 더 크다
	sp["height"] = _v("render_h", RENDER_H) * k
	sp["turn"] = turn
	sp["pitch"] = _v("pitch", PITCH)
	sp["pose"] = (sp.get("pose", {}) as Dictionary).merged({"arm_l": ARM_POSES[int(_v("arms", ARMS))], "arm_r": ARM_POSES[int(_v("arms", ARMS))], "stance": _v("stance", STANCE), "knee": _v("knee", KNEE), "hunch": _v("hunch", HUNCH)}, true)
	sp["step"] = _v("step", STEP)
	sp["swing"] = _v("swing", SWING)
	sp["heel"] = _v("heel", HEEL)
	sp["head"] = float(sp.get("head", 1.0)) * _v("head", HEAD)
	sp["legs"] = _v("legs", LEGS)
	sp["wide"] = _v("wide", WIDE)
	sp["bulk"] = float(sp.get("bulk", 1.0)) * _v("bulk", BULK)
	sp["map_face"] = _v("map_face", MAP_FACE) > 0.0  # 1 = 입·튀어나온 턱 없는 얼굴, 0 = 전투 그림 얼굴(코·입)
	sp["hair_high"] = _v("hair_high", HAIR_HIGH)
	sp["hair_grow"] = _v("hair_grow", HAIR_GROW)
	sp["fringe"] = _v("fringe", FRINGE) > 0.0  # 더벅머리 앞·옆머리
	if str(sp.get("hair", "")) == "short" and _v("spiky", 1.0) > 0.0:  # 짧은 머리: 삐친 타래로(매끈한 헬멧·항아리 얼굴이 되지 않게 — 피어 앤 헝거 주인공 머리)
		sp["spiky"] = true
		sp["fringe"] = false
		sp["hair_grow"] = _v("spiky_grow", SPIKY_GROW)
		sp["locks"] = LOCKS
	sp["socket_eyes"] = _v("sockets", SOCKETS) > 0.0
	sp["hair_flare"] = _v("hair_flare", HAIR_FLARE)
	sp["eye_r"] = _v("eye_r", EYE_R)
	sp["eye_style"] = int(_v("eye_style", EYE_STYLE))
	if absf(absf(turn) - PI * 0.5) < 0.6:  # 옆모습: 얼굴을 조금 밝게, 관자놀이 타래는 광대까지만(옆얼굴을 덮어 어두웠다)
		sp["face_lift"] = _v("side_face_lift", SIDE_FACE_LIFT)
		if sp.has("locks"):
			sp["locks"] = (sp["locks"] as Dictionary).merged(SIDE_LOCKS, true)
	sp["mottle_amt"] = 0.08  # 살갗 얼룩·때는 줄이면 점박이로 보인다
	sp["grime"] = 0.0
	if _v("front_light", FRONT_LIGHT) > 0.0:
		sp["light"] = LIGHT
	for key: String in extra:  # 몬스터 맵 값
		match key:
			"hunch", "knee", "stance":
				(sp["pose"] as Dictionary)[key] = extra[key]
			"head", "bulk":
				sp[key] = float(base.get(key, 1.0)) * float(extra[key])
			_:
				sp[key] = extra[key]
	if phase != 0.0:
		sp["walk"] = phase
	var p: Paint = Party.figure(sp, SEED + name.hash() % 997)
	var img := p.to_image()
	var H := float(sp["height"])
	var foot := Vector2(img.get_width() * 0.5, img.get_height() - H * 0.03)
	var out := _shrink(img, foot, JsonUtil.get_float(_cfg, "body_px", 84.0) / _v("render_h", RENDER_H))
	_contrast(out)
	_inner_lines(out)
	return out


## 몬스터 걷기 시트(MapMonster 설계가 있는 몬스터): 앞·왼쪽·오른쪽(뒤집기)·뒤 × 걸음 3장 → <out>/monsters/<id>.webp.
## 칸 크기는 몬스터마다(가장 큰 장에 맞춤) — <out>/monsters/sheets.json {id: {cell: [w, h], foot: 아래에서 발까지 px}}.
func _monster_sheet(id: String) -> void:
	var t0 := Time.get_ticks_msec()
	var m := MapMonster.spec_of(id)
	var kind := str(m["kind"])
	var size := float(m["size"])
	var body := JsonUtil.get_float(_cfg, "body_px", 84.0)
	var frames := {}  # [줄, 칸] → 그림(발 = 아래 가운데)
	var f := 0.0
	for row: int in [0, 1, 3]:
		var dir: String = ["down", "left", "", "up"][row]
		for c in PHASES.size():
			var img: Image
			if kind == "figure":
				var turn: float = {0: PI, 1: -SIDE_TURN, 3: 0.0}[row]
				img = _figure(m["spec"], id, turn, float(PHASES[c]), m.get("map", {}), size)
			else:
				var raw := MapMonster.paint(id, dir, float(PHASES[c]), body * size * MONSTER_RENDER, SEED + id.hash() % 997)
				var used := raw.get_used_rect()
				if f == 0.0:  # 서 있는 앞모습 높이로 배율을 정해 모든 장에 같이 쓴다
					f = body * size * float(MONSTER_H.get(kind, 0.7)) / maxf(1.0, used.size.y)
				img = _shrink(raw, Vector2(used.get_center().x, used.end.y), f)
				_contrast(img)
				_inner_lines(img)
			frames[Vector2i(c, row)] = img
			if row == 1:
				var fl := img.duplicate() as Image
				fl.flip_x()
				frames[Vector2i(c, 2)] = fl
	var cell := Vector2i(8, 8)
	for img: Image in frames.values():
		var u := img.get_used_rect()
		cell.x = maxi(cell.x, u.size.x + 4 + (u.size.x % 2))
		cell.y = maxi(cell.y, img.get_height() - u.position.y + 2)  # 위 빈칸은 버린다
	var sheet := Image.create_empty(cell.x * PHASES.size(), cell.y * 4, false, Image.FORMAT_RGBA8)
	for at: Vector2i in frames:
		var img: Image = frames[at]
		var u := img.get_used_rect()
		var dst := Vector2i(at.x * cell.x + (cell.x - u.size.x) / 2, at.y * cell.y + cell.y - 2 - (img.get_height() - u.position.y))
		sheet.blit_rect(img, u, dst)
	var dir_out := _out.path_join("monsters")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_out))
	sheet.save_webp(dir_out.path_join("%s.webp" % id), false)
	_sheets[id] = {"cell": [cell.x, cell.y], "foot": 4}  # _shrink가 발 아래 2px + 칸 아래 2px
	print("그림: 맵 몬스터 시트 %s %dx%d (%d ms)" % [id, sheet.get_width(), sheet.get_height(), Time.get_ticks_msec() - t0])


## 몬스터 시트 색인(있던 것에 이번 것을 더한다).
func _save_sheet_index() -> void:
	var path := _out.path_join("monsters/sheets.json")
	var cur: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	var all: Dictionary = cur if cur is Dictionary else {}
	all.merge(_sheets, true)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(all, "\t", true))


## 몬스터(시트 설계 없음): 전투 그림을 몸 높이 색인으로 맞춰 줄인다(사람 키 × size).
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


## 밝기·명암 대비(가운데 밝기 기준) — 줄이면 칠한 그늘이 뭉개져 흐릿해진다.
func _contrast(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var k := func(v: float) -> float: return clampf((pow(v, _v("gamma", GAMMA)) - 0.42) * _v("contrast", CONTRAST) + 0.44, 0.0, 1.0)
			img.set_pixel(x, y, Color(k.call(c.r), k.call(c.g), k.call(c.b), c.a))


## 몸 안 선: 맞닿은 이웃보다 LINE_STEP 넘게 어두운 칸을 더 어둡게(피어 앤 헝거 맵 그림의 진한 안쪽 윤곽).
func _inner_lines(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var marks: Array[Vector2i] = []
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a < 0.6:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var o := img.get_pixel(q.x, q.y)
				if o.a > 0.6 and o.get_luminance() - c.get_luminance() > _v("line_step", LINE_STEP):
					marks.append(Vector2i(x, y))
					break
	for m in marks:
		var c := img.get_pixel(m.x, m.y)
		img.set_pixel(m.x, m.y, Color(c.r * 0.5, c.g * 0.45, c.b * 0.45, c.a))


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
		img.set_pixel(m.x, m.y, OUTLINE.lerp(c, c.a * 0.2) if c.a > 0.0 else OUTLINE)


## 맨 위 상수(--set으로 이번만 바꿀 수 있다).
func _v(key: String, value: float) -> float:
	return float(_set.get(key, value))


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
