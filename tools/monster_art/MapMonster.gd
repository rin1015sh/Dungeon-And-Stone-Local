extends RefCounted
## 탐험 맵 몬스터 걷기 그림(앞·옆·뒤 × 걸음): 전투 그림과 같은 3D 덩어리 도구로 몸을 돌려 그린다(tools/paint_actors.gd가 줄여 시트로).
## 여기 설계가 있는 몬스터만 시트를 그리고, 없는 몬스터는 예전처럼 전투 그림을 줄인 한 장(MonsterView가 흔든다).
## dir: "down"(앞) · "left"(왼쪽을 본 옆 — 오른쪽은 뒤집는다) · "up"(뒤). phase: 걸음 +1 / 0(섬) / -1.
## 종류(kind): figure = 사람형(탐험가와 같은 3D 몸 Back·Party — 큰 머리 맵 비율) · beast = 네발짐승(Beast — 앞 방향 face)
##            crawler = 기는 것(Party._crawler — 돌림 turn) · mound = 흙더미(여기서 — 얼굴·뿌리 팔이 돌림을 따른다)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const Beast := preload("res://tools/monster_art/Beast.gd")
const Party := preload("res://tools/monster_art/Party.gd")
const Specs := preload("res://tools/monster_art/Specs.gd")

const PITCH := 0.3  ## 짐승·기는 것·흙더미를 위에서 내려다보는 정도
const SIDE_FACE := 0.25  ## 옆모습을 보는 사람 쪽으로 살짝 돌리는 정도(라디안 — 완전한 옆보다 3/4에 가깝게)


static func C(hex: String) -> Color:
	return Color(hex)


## 몬스터 맵 설계. kind · size(사람 키 대비 — 데이터 size와 같게) · spec(그리는 도구 설계) · map(figure: 탐험가 맵 값을 덮어쓴다).
static func spec_of(id: String) -> Dictionary:
	match id:
		"goblin":  # 전투 그림: 초록 살갗·굽은 등·긴 귀·노란 눈·허리 천·단검
			return {"kind": "figure", "size": 0.75, "spec": {"height": Party.REF_H, "build": "thin", "sh": 0.1, "skin": C("#7a9258"), "mottle": C("#4a5a30"),
				"hair": "none", "ears": "long", "eye_glow": C("#e8d060"),
				"kit": {"loin": C("#4a3a2a"), "belt": C("#3a2a1e"), "weapon": "dagger", "weapon_c": C("#7a7468")}},
				"map": {"hunch": 0.38, "knee": 0.16, "head": 2.3, "legs": 0.72, "wide": 1.0, "bulk": 1.05, "stance": 0.07}}
		"blade_wolf":
			return {"kind": "beast", "size": 1.0, "spec": Specs.More.spec_of("blade_wolf")}
		"ghoul":
			return {"kind": "crawler", "size": 1.0, "spec": {"height": 420, "color": C("#8a947c"), "blood": 0.5, "eyes": C("#e0d8a0"), "elbow_h": 0.32, "elbow_w": 0.2, "reach": 0.3}}
		"gnome":
			return {"kind": "mound", "size": 0.8, "spec": Specs.More.spec_of("gnome")}
	return {}


static func has(id: String) -> bool:
	return not spec_of(id).is_empty()


## 짐승·기는 것·흙더미 한 장(크게 — 줄이는 것은 paint_actors). height = 그릴 크기(px). 돌려주는 그림의 아래 가운데 근처가 발.
static func paint(id: String, dir: String, phase: float, height: float, seed_value: int) -> Image:
	var m := spec_of(id)
	var sp: Dictionary = (m["spec"] as Dictionary).duplicate(true)
	sp["height"] = height
	sp["pitch"] = PITCH
	sp["walk"] = phase
	match str(m["kind"]):
		"beast":
			sp["face"] = {"down": 0.0, "left": -PI * 0.5 + SIDE_FACE, "up": PI}[dir]
			sp["canvas_h"] = 1.1
			return Beast.paint(sp, seed_value).to_image()
		"crawler":
			sp["turn"] = {"down": PI, "left": -PI * 0.5 - SIDE_FACE, "up": 0.0}[dir]
			sp["canvas_h"] = 1.0
			return Party._crawler(sp, seed_value).to_image()
		"mound":
			return _mound(sp, {"down": PI, "left": -PI * 0.5 - SIDE_FACE, "up": 0.0}[dir], phase, seed_value).to_image()
	return Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)


## 흙더미(노움): 이끼 덮인 흙·돌 둔덕 + 앞쪽의 눈구멍 둘(빛) + 양옆 뿌리 팔. 걸으면 좌우로 기우뚱하며 뿌리 팔을 번갈아 내딛는다.
static func _mound(sp: Dictionary, turn: float, walk: float, seed_value: int) -> Paint:
	var H := float(sp["height"])
	var w := int(H * 1.1)
	var h := int(H * 0.9)
	var p := Paint.new(w, h, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(w, h)
	var pr := Back.proj(Vector2(w * 0.5, h - H * 0.06), H, turn, PITCH)
	var col: Color = sp.get("color", C("#7a6a52"))
	var earth := cl.mat(col, "stone", {"mottle": col.darkened(0.3), "mottle_amt": 0.5})
	var g := cl.group()
	cl.tag = "mound"
	var bob := absf(walk) * 0.012
	var c := Vector3(walk * 0.015, -0.2 - bob, 0.0)
	Back.ell(cl, pr, g, c, 0.3, 0.22, 0.27, earth, 0.04)
	for k in 16:  # 돌·흙 덩이(위·옆을 덮는다)
		var a := rng.randf_range(0.0, TAU)
		var la := rng.randf_range(0.15, 1.2)
		var q := c + Vector3(cos(a) * cos(la) * 0.27, -sin(la) * 0.2, sin(a) * cos(la) * 0.24)
		Back.ell(cl, pr, g, q, rng.randf_range(0.03, 0.06), rng.randf_range(0.025, 0.05), rng.randf_range(0.03, 0.05), earth, 0.01)
	if sp.has("moss"):  # 이끼(위쪽 반)
		var mm := cl.mat(sp["moss"], "fur")
		for k in 22:
			var a := rng.randf_range(0.0, TAU)
			var la := rng.randf_range(0.55, 1.4)
			var q := c + Vector3(cos(a) * cos(la) * 0.28, -sin(la) * 0.21 - 0.01, sin(a) * cos(la) * 0.25)
			Back.ell(cl, pr, g, q, 0.05, 0.025, 0.05, mm, 0.01)
	var F := Vector3(0, 0, -1)  # 노움의 앞(몸 좌표 — 돌림 π면 보는 사람 쪽)
	var eyes: Array = []
	for s: float in [-1.0, 1.0]:  # 눈구멍
		var e := c + Vector3(s * 0.065, 0.0, -0.24)
		if Back.facing(pr, Vector3(s * 0.4, 0, -1)) > 0.15:
			var q := Back.P2(pr, e)
			cl.carve(g, q, 0.026 * H, 0.02 * H, 0.03 * H)
			eyes.append(q)
	for s: float in [-1.0, 1.0]:  # 뿌리 팔(몸 옆에서 땅으로) — 걸음마다 번갈아 앞으로
		var ga := cl.group()
		var k := walk * s
		var a := c + Vector3(s * 0.22, 0.1, -0.06)  # 몸 아래쪽 옆에서 짧게 — 땅을 짚는 굵은 뿌리
		var tip := a + Vector3(s * 0.07, 0.09 - maxf(0.0, k) * 0.03, -0.04 - k * 0.06)
		Back.chain(cl, pr, ga, [a, a.lerp(tip, 0.5) + Vector3(s * 0.02, 0.0, 0.0), tip], [0.045, 0.035, 0.02], earth, 0.01)
		for f in 3:
			Back.cap(cl, pr, ga, tip, tip + Vector3(s * (f - 1) * 0.025, 0.04, -0.02 + (f - 1) * 0.015), 0.008, 0.002, earth, 0.004)
	Render.render(cl, p, H)
	var ec: Color = sp.get("eyes", C("#ffcc60"))
	for e: Vector2 in eyes:
		Ink.glow(p, e.x, e.y, H * 0.06, ec, float(sp.get("glow", 1.0)) * 0.7, false)
		for yy in range(int(e.y - H * 0.008), int(e.y + H * 0.008) + 1):
			for xx in range(int(e.x - H * 0.01), int(e.x + H * 0.01) + 1):
				p.blend(xx, yy, ec.lightened(0.35), 0.95)
	Finish.done(p, sp, {"chest": Back.P(pr, c), "waist": Back.P(pr, c)}, H)
	return p
