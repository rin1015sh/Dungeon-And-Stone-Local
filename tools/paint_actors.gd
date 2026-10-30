extends SceneTree
## 탐험 맵 몸 그림(docs/PROMPT_ART_MAP.md A4): 전투 그림과 같은 도구로 그려 맵 크기로 줄인다.
##   godot --headless --path . --script res://tools/paint_actors.gd [-- --only=<종족|monsters|몬스터 id,…>]
## 탐험가: 아군 전투 그림의 3D 몸(Party·Back)을 앞(아래)·옆(오른쪽)·뒤(위)로 돌리고 걷기 다섯 장(왼발 앞·반걸음·섬·반걸음·오른발 앞)을 그려
##   한 장의 시트로 → assets/actors/<종족>.webp. 줄 = [아래, 왼쪽, 오른쪽, 위](오른쪽 = 왼쪽 좌우 반전), 칸 = [걸음 A, 반걸음 A, 섬, 반걸음 B, 걸음 B].
##   피어 앤 헝거 맵 그림처럼 곧게 선 약 3.3등신(큰 머리·마른 몸·붙인 다리)·움푹한 눈구멍 얼굴(입 없음)·대비를 키운 칠·진한 바깥선(장비는 몸에 그리지 않는다 — 사용자 결정 a+b, ASSUMPTIONS AM27).
## 몬스터: 전투 일러스트(assets/monsters/<id>.webp — 정면)를 몸 높이 색인으로 데이터 size에 맞춰 줄인다 → assets/actors/monsters/<id>.webp
##   (뒷모습 그림이 있으면 <id>_back.webp도). 걷기는 게임이 흔들어 보인다(MonsterView).
## 칸 크기·배율은 render.json view.actor_sheet. 줄인 뒤 1px 잉크 바깥선을 두른다(작은 그림에서 윤곽이 읽히게).

const Party := preload("res://tools/monster_art/Party.gd")
const MapMonster := preload("res://tools/monster_art/MapMonster.gd")
const MapLooks := preload("res://tools/monster_art/MapLooks.gd")
const Paint := preload("res://tools/city_art/Paint.gd")

## 정한 값(사용자 2026-10-17 — 피어 앤 헝거 맵 그림 참고 시트를 보고 여러 방법·템플릿을 비교해 고름: 방법 ⑤ + 머리 템플릿 5).
## 시험할 때는 --set=<상수 이름 소문자>=<값>으로 이번만 바꾸고 --out=<폴더>로 따로 그린다(게임 그림을 건드리지 않는다).
const RENDER_H := 168.0  ## 사람 키를 이 높이(맵 키의 2배)로 그려 반으로 줄인다 — 크게 그려 많이 줄이면 선·명암이 뭉개진다
const SIDE_TURN := 1.8   ## 옆모습 돌림 — 90°를 조금 넘겨 얼굴이 보는 사람 쪽으로 살짝(90° 안쪽은 뒤에서 본 옆모습이다)
const PITCH := 0.1       ## 3/4 시점 — 앞으로 내민 발이 조금 아래로(크게 하면 몸이 비틀려 보인다)
const PHASES := [1.0, 0.5, 0.0, -0.5, -1.0]  ## 칸 순서: 왼발 앞 · 반걸음 · 섬 · 반걸음 · 오른발 앞(재생 순서는 render.json actor_sheet.walk_cycle)
const OUTLINE := Color("#120c0a")
## 몸 비율·자세(참고 시트): 머리 약 1/3, 굵고 짧은 팔다리, 살짝 숙인 몸, 늘어뜨린 팔, 큰 보폭·높이 드는 뒤꿈치
const HEAD := 2.2        ## 머리 크기 배율(전투 그림 = 1) — 2026-10-17 사용자 "머리 크기 줄이고"로 2.5 → 2.2
const LEGS := 0.75       ## 다리 길이 배율 — 2026-10-17 사용자 "다리 조금만 늘려"로 0.68 → 0.75
## 종족마다 HEAD·LEGS를 덮어쓴다(2026-10-17 사용자 "바바리안은 예전 머리 2.5·다리 0.68로" — 인간만 줄이고 늘림). --set=head/legs가 있으면 그것이 이긴다.
const RACE_BODY := {"barbarian": {"head": 2.5, "legs": 0.68}}
## 게임 그림의 옷차림 = MapLooks.CHOSEN(종족 → id — 전투 뒷모습도 같이), 남겨 두는 옷차림 MapLooks.KEEP → <out>/looks/<id>.webp.
## 후보 비교: --look=<id,id> --out=<폴더>.
const WIDE := 1.15       ## 어깨·엉덩이 폭 배율
const BULK := 1.35       ## 팔다리·몸통 굵기 배율
const HUNCH := 0.2       ## 숙임
const ARMS := 1.0        ## 팔 자세(ARM_POSES 번호 — 1 = 늘어뜨린 팔)
const STANCE := 0.065    ## 발 벌림(키 비율)
const KNEE := 0.08       ## 무릎 굽힘
## 걸음(2026-10-17 사용자 첨부 피어 앤 헝거 걷기 프레임을 격자로 재서 맞춤 — ASSUMPTIONS AM29). 각도(도) = 옆에서 본 수직(아래)에서 앞(+)·뒤(−),
## "걸음 칸" 값이고 반걸음 칸은 선 자세와의 중간. 몸 높이는 앞발이 땅에 닿게 저절로 내려간다(Back.stride).
## 예전 값(보폭 0.17·뒤꿈치 0.13·팔 0.15 — 발 자리를 옮기는 방식)은 뒷다리 허벅지가 +18°로 앞을 향한 채 정강이만 −65°로 꺾였고, 팔은 아래팔만 뻗었다.
const THIGH_F := 24.0    ## 앞다리 허벅지(참고 +21~25°)
const SHIN_F := 18.0     ## 앞다리 정강이(무릎을 살짝 굽혀 디딤)
const THIGH_B := -20.0   ## 뒷다리 허벅지(참고 약 −25°)
const SHIN_B := -32.0    ## 뒷다리 정강이(뒤꿈치를 들고 발끝은 땅에)
const LIFT := 25.0       ## 반걸음 칸에서 지나가는 뒷다리의 무릎 굽힘(정강이 −, 허벅지는 절반만큼 +)
const TWIST := 0.012     ## 앞으로 간 팔 쪽 어깨가 나오는 양(키 비율 — 어깨·골반 반대 돌림)
## 팔(2026-10-17 사용자 "팔을 앞으로만 흔들어 좀비 같다"): 참고 그림의 앞팔(아래팔 +43°)을 그대로 따르면 늘 손이 몸 앞에 있다 →
## 앞은 줄이고 뒤를 크게 — 걸음 칸마다 한 손은 등 뒤로 확실히 빠진다. 예전 값 15 / 14 / −14 / −4.
const ARM_F := 24.0      ## 앞으로 간 팔: 위팔을 더 돌리는 각(선 자세 −4° → +8°)
const FORE_F := -6.0    ## 앞으로 간 팔: 아래팔(선 자세 +13° → +13° 그대로 — 뻗지 않는다)
const ARM_B := -18.0     ## 뒤로 간 팔: 위팔 — 2026-10-26 사용자 "옆에서 볼 때 너무 뒤로 흔든다, 앞 흔드는 각도 정도로"로 −34 → −18(지금 반걸음 칸이 최대)
const FORE_B := -4.0     ## 뒤로 간 팔: 아래팔(−10 → −4 — 다 펴면 손이 위팔보다 조금 더 뒤)
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
const LOCKS := {"n": 24, "w": 0.12, "wj": 0.35, "flick": 0.1, "jitter": 0.6, "front": 0.1, "temple": -0.15, "side": -0.55, "back": -0.15, "gap": 0, "light": 4}
const SIDE_LOCKS := {"temple": 0.12, "front": 0.16}  ## 옆모습에서만 덮어쓰는 타래 끝
## 옆모습 머리: 2026-10-17 "헬멧 같다"로 휨·삐친 뭉치를 넣어 봤다가 사용자가 되돌림("바로 전으로, 뒷머리만 깎아") — 템플릿 5 그대로, 뒷머리만 짧게(LOCKS back 0.3 → −0.15).
## --set=sl_<키>=값으로 시험(아래 SIDE_HAIR 키 — BackHair._spikes swirl·tufts도 받는다).
const SIDE_HAIR := {"side": -0.55, "back": -0.15, "flick": 0.1, "jitter": 0.6, "swirl": 0.0, "tufts": 0.0, "gap": 0.0}
const SIDE_SHELL := 0.7  ## 옆모습 껍데기 숱(SPIKY_GROW와 같게)
## 마감(방법 ⑤): 전투 그림 빛 그대로, 줄인 뒤 밝기·대비·안쪽 선
const FRONT_LIGHT := 0.0
## 탐험가 앞모습만 앞에서 비춘다(사용자 2026-10-29 "다 안대를 쓰고 있다" — 왼쪽 위 빛이면 얼굴 오른쪽 반이 그늘에 묻혀 오른 눈구멍이 안 보이고
## 왼 눈만 짙어 안대처럼 보였다). 옆·뒤와 몬스터는 그대로.
const FRONT_ROW_LIGHT := 1.0
const LIGHT := Vector3(-0.2, -0.5, 0.85)
const CONTRAST := 1.12   ## 줄인 뒤 명암 대비
const GAMMA := 0.85      ## 줄인 뒤 밝기(1보다 작으면 중간 밝기를 올린다)
const LINE_STEP := 0.2   ## 이웃보다 이만큼 어두운 칸에 진한 선(겨드랑이·다리 사이·옷 경계)
const ARM_POSES := ["hang", "slump", "down"]
const EXPLORER_ARMS := 2.0  ## 탐험가만 팔 자세(2 = 몸 옆으로 곧게 내림 — 사용자 2026-10-26 "선 자세에서 팔이 살짝 앞에 있어 좀비 같다", AM42). 몬스터 사람형은 ARMS
const SEED := 4242

## 몬스터 맵 키(사람 키 × size 대비): 사람형은 몸 그대로, 나머지는 서 있는 앞모습 높이를 이만큼으로
const MONSTER_H := {"beast": 0.72, "crawler": 0.6, "mound": 0.7}
const MONSTER_RENDER := 2.0  ## 몬스터 그림을 맵 키의 이 배로 그려 줄인다(사람형은 RENDER_H)

var _cfg: Dictionary = {}
var _sheets: Dictionary = {}  ## 이번에 그린 몬스터 시트 {id: {cell, foot}}
var _out := "res://assets/actors"  ## --out=<폴더>: 시트를 다른 곳에 쓴다(게임 그림을 바꾸지 않고 시험해 볼 때)
const IDLE_TURN := 0.65  ## 보스 기다리는 자세는 3/4 앞모습(정면으로는 앉음·무릎 꿇음이 읽히지 않았다)
const BOSS_MIN := 1.8  ## 보스 맵 크기 = max(데이터 size, BOSS_MIN) × BOSS_SCALE(사람 키 대비 — "보스라는 느낌이 확 들게", 사용자 2026-10-18)
const BOSS_SCALE := 1.4
var _idle_ids := PackedStringArray()  ## --idle=<id,...>: 보스가 방에서 기다리는 자세 한 장만 그린다(MapMonster.BOSSES)
var _set: Dictionary = {}  ## --set=head=2,legs=0.8: 맨 위 상수를 이번만 바꾼다(키 = 상수 이름 소문자)
var _look := ""  ## 지금 그리는 옷차림(MapLooks id — 빈 값 = 전투 그림 옷)


func _init() -> void:
	var only := PackedStringArray()
	var looks := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		elif a.begins_with("--idle="):
			_idle_ids = a.trim_prefix("--idle=").split(",")
		elif a.begins_with("--look="):
			looks = a.trim_prefix("--look=").split(",")
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
	if not looks.is_empty():  # 옷차림 후보만: <out>/<id>.webp
		for id: String in looks:
			if MapLooks.has(id):
				_look = id
				_explorer(MapLooks.race_of(id), id)
		quit(0)
		return
	if not _idle_ids.is_empty():
		for id: String in _idle_ids:
			_idle(id, JsonUtil.get_float(db.get_entry("monsters", id), "size", 1.0))
		quit(0)
		return
	for race: String in Party.RACES:
		if only.is_empty() or only.has(race):
			_look = str(MapLooks.CHOSEN.get(race, ""))
			_explorer(race)
			for id: String in MapLooks.KEEP:  # 남겨 두는 옷차림(NPC용)
				if MapLooks.race_of(id) == race:
					_look = id
					_explorer(race, "looks/" + id)
			_look = ""
	for id: String in db.get_collection("monsters"):
		if only.is_empty() or only.has("monsters") or only.has(id):
			if not MapMonster.idle_of(id).is_empty():
				_idle(id, JsonUtil.get_float(db.get_entry("monsters", id), "size", 1.0))
			else:  # 전투 그림을 줄인 한 장(시트가 없거나 못 읽을 때 쓴다) + 설계가 있으면 걷기 시트
				_monster(id, JsonUtil.get_float(db.get_entry("monsters", id), "size", 1.0))
				if MapMonster.has(id):
					_monster_sheet(id, JsonUtil.get_float(db.get_entry("monsters", id), "size", 1.0))
	if not _sheets.is_empty():
		_save_sheet_index()
	quit(0)


## 탐험가 걷기 시트(file = 저장 이름 — 옷차림 후보는 그 id).
func _explorer(race: String, file: String = "") -> void:
	var t0 := Time.get_ticks_msec()
	var cell := _cell()
	var cols := PHASES.size()
	var sheet := Image.create_empty(cell.x * cols, cell.y * 4, false, Image.FORMAT_RGBA8)
	var turns := {0: PI, 1: -SIDE_TURN, 3: 0.0}  # 줄 → 돌림(2 = 오른쪽은 1을 뒤집는다 — 빛이 왼쪽 위에서 와서 왼쪽을 보게 그려야 얼굴이 밝다)
	for row: int in [0, 1, 3]:
		for c in cols:
			var base := Party.spec_of(race + "_back")
			if not _look.is_empty():
				base = MapLooks.apply(base, _look)
			var img := _figure(base, race, float(turns[row]), float(PHASES[c]))
			_put(sheet, img, Vector2i(c, row), cell)
			if row == 1:
				var flipped := img.duplicate() as Image
				flipped.flip_x()
				_put(sheet, flipped, Vector2i(c, 2), cell)
	var path := _out.path_join("%s.webp" % (file if not file.is_empty() else race))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
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
	var arms: String = ARM_POSES[int(_v("arms", EXPLORER_ARMS if size < 0.0 else ARMS))]
	sp["pose"] = (sp.get("pose", {}) as Dictionary).merged({"arm_l": arms, "arm_r": arms, "stance": _v("stance", STANCE), "knee": _v("knee", KNEE), "hunch": _v("hunch", HUNCH)}, true)
	sp["gait"] = {"thigh_f": _v("thigh_f", THIGH_F), "shin_f": _v("shin_f", SHIN_F), "thigh_b": _v("thigh_b", THIGH_B), "shin_b": _v("shin_b", SHIN_B),
		"lift": _v("lift", LIFT), "twist": _v("twist", TWIST), "arm_f": _v("arm_f", ARM_F), "fore_f": _v("fore_f", FORE_F), "arm_b": _v("arm_b", ARM_B), "fore_b": _v("fore_b", FORE_B)}
	var rb: Dictionary = RACE_BODY.get(name, {})
	if not _look.is_empty() and MapLooks.race_of(_look) == name:  # 옷차림이 정한 머리·다리 비율
		var lb := MapLooks.body(_look)
		rb = {"head": lb["head"] if float(lb["head"]) > 0.0 else rb.get("head", HEAD), "legs": lb["legs"] if float(lb["legs"]) > 0.0 else rb.get("legs", LEGS)}
	sp["head"] = float(sp.get("head", 1.0)) * _v("head", float(rb.get("head", HEAD)))
	sp["legs"] = _v("legs", float(rb.get("legs", LEGS)))
	sp["wide"] = _v("wide", WIDE) * (0.9 if sp.get("female", false) else 1.0)  # 여성(새 종족 후보): 덜 넓고 덜 굵게 — 맵 배율에서 뻣뻣한 통짜 몸이 됐다
	sp["bulk"] = float(sp.get("bulk", 1.0)) * _v("bulk", BULK) * (0.88 if sp.get("female", false) else 1.0)
	sp["map_face"] = _v("map_face", MAP_FACE) > 0.0  # 1 = 입·튀어나온 턱 없는 얼굴, 0 = 전투 그림 얼굴(코·입)
	sp["hair_high"] = _v("hair_high", HAIR_HIGH)
	sp["hair_grow"] = _v("hair_grow", HAIR_GROW)
	sp["fringe"] = _v("fringe", FRINGE) > 0.0  # 더벅머리 앞·옆머리
	if str(sp.get("hair", "")) == "short" and _v("spiky", 1.0) > 0.0:  # 짧은 머리: 삐친 타래로(매끈한 헬멧·항아리 얼굴이 되지 않게 — 피어 앤 헝거 주인공 머리)
		sp["spiky"] = true
		sp["fringe"] = false
		sp["hair_grow"] = _v("spiky_grow", SPIKY_GROW)
		sp["locks"] = LOCKS.merged(sp.get("map_locks", {}) as Dictionary, true).merged({"back": _v("lock_back", float(LOCKS["back"]))}, true)  # map_locks = 종족 머리 타래(드워프는 짧게 — RaceParts)
	sp["socket_eyes"] = _v("sockets", SOCKETS) > 0.0
	sp["hair_flare"] = _v("hair_flare", HAIR_FLARE)
	sp["eye_r"] = _v("eye_r", EYE_R)
	sp["eye_style"] = int(_v("eye_style", EYE_STYLE))
	if absf(absf(turn) - PI * 0.5) < 0.6:  # 옆모습: 얼굴을 조금 밝게, 관자놀이 타래는 광대까지만(옆얼굴을 덮어 어두웠다)
		sp["face_lift"] = _v("side_face_lift", SIDE_FACE_LIFT)
		if sp.has("locks"):
			var side_hair := {}
			for key: String in SIDE_HAIR:
				side_hair[key] = _v("sl_" + key, float(SIDE_HAIR[key]))
			sp["locks"] = (sp["locks"] as Dictionary).merged(SIDE_LOCKS, true).merged(side_hair, true)
			sp["hair_grow"] = _v("side_shell", SIDE_SHELL)
	sp["mottle_amt"] = 0.08  # 살갗 얼룩·때는 줄이면 점박이로 보인다
	sp["grime"] = 0.0
	if _v("front_light", FRONT_LIGHT) > 0.0 or (size < 0.0 and absf(absf(turn) - PI) < 0.3 and _v("front_row_light", FRONT_ROW_LIGHT) > 0.0):
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


## 몬스터 걷기 시트(MapMonster 설계가 있는 몬스터): 앞·왼쪽·오른쪽(뒤집기)·뒤 × 걸음 cols장 → <out>/monsters/<id>_walk.webp.
## 칸 크기는 몬스터마다(가장 큰 장에 맞춤) — <out>/monsters/sheets.json {id: {cell: [w, h], foot: 아래에서 발까지 px}}.
func _monster_sheet(id: String, data_size: float) -> void:
	var t0 := Time.get_ticks_msec()
	var m := MapMonster.spec_of(id)
	var kind := str(m["kind"])
	var size := float(m.get("size", data_size))
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
	sheet.save_webp(dir_out.path_join("%s_walk.webp" % id), false)
	_sheets[id] = {"cell": [cell.x, cell.y], "foot": 4}  # _shrink가 발 아래 2px + 칸 아래 2px
	print("그림: 맵 몬스터 시트 %s %dx%d (%d ms)" % [id, sheet.get_width(), sheet.get_height(), Time.get_ticks_msec() - t0])


## 보스 기다리는 자세(3/4 앞모습 한 장, 크게) → <out>/monsters/<id>.webp(MonsterView가 보스 방에 그린다).
func _idle(id: String, data_size: float) -> void:
	var t0 := Time.get_ticks_msec()
	var m := MapMonster.idle_of(id)
	if m.is_empty():
		return
	var size := maxf(float(m.get("size", data_size)), _v("boss_min", BOSS_MIN)) * _v("boss_scale", BOSS_SCALE)
	var img: Image
	if str(m["kind"]) == "figure":
		img = _figure(m["spec"], id, PI + IDLE_TURN, 0.0, m.get("map", {}), size)
	else:
		var body := JsonUtil.get_float(_cfg, "body_px", 84.0)
		var raw := MapMonster.paint(id, "down", 0.0, body * size * MONSTER_RENDER, SEED + id.hash() % 997)
		var used := raw.get_used_rect()
		img = _shrink(raw, Vector2(used.get_center().x, used.end.y), body * size * float(MONSTER_H.get("blob", 0.5)) / maxf(1.0, used.size.y))
		_contrast(img)
		_inner_lines(img)
	var u := img.get_used_rect()
	var out := Image.create_empty(u.size.x + 4, img.get_height() - u.position.y + 2, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, u, Vector2i(2, 0))
	var dir_out := _out.path_join("monsters")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_out))
	out.save_webp(dir_out.path_join("%s.webp" % id), false)
	print("그림: 보스 기다리는 자세 %s %dx%d (%d ms)" % [id, out.get_width(), out.get_height(), Time.get_ticks_msec() - t0])


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
