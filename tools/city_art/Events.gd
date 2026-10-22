extends RefCounted
## 거리 사건 일러스트(2026-10-22 사용자 "도시 이벤트당 일러스트 1장 — 이벤트가 나오면 일러스트, 뒤 도시 조작은 막고", CT45):
## 사건마다 960×540 한 장(data/street_events art). 바깥 장면 = 하늘 · 뒤 집들(박공·작은 창) · 젖은 포석 · 사람(Npcs — 앞일수록 크다).
## 칠은 실내 그림과 같다: 장면을 다 칠한 뒤 Interiors.light로 어둡게 내리고 광원만 밝힌 다음 색 보정·그레인.
## 장면 함수는 광원 목록 [[위치, 반지름, 색, 세기] …]을 돌려준다. 이 파일 = 공통 틀 + 교수형·포고·소매치기·검문·현상수배(나머지 Events2·Events3).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Interiors := preload("res://tools/city_art/Interiors.gd")
const Npc := preload("res://tools/city_art/Npcs.gd")
const K := preload("res://tools/city_art/EventKit.gd")
const E2 := preload("res://tools/city_art/Events2.gd")
const E3 := preload("res://tools/city_art/Events3.gd")

const W := 960
const H := 540
const SKY := K.SKY
const WARM := K.WARM
const FIRE := K.FIRE


static func paint(id: String, seed_value: int) -> Paint:
	var p := Paint.new(W, H, seed_value)
	var lights: Array = []
	match id:
		"hanging":
			lights = hanging(p)
		"tax_notice":
			lights = tax_notice(p)
		"pickpocket":
			lights = pickpocket(p)
		"checkpoint":
			lights = checkpoint(p)
		"wanted":
			lights = wanted(p)
		"stone_glut", "stone_demand", "potion_shortage", "dubious_peddler", "beggar":
			lights = E2.scene(p, id)
		_:
			lights = E3.scene(p, id)
	Interiors.light(p, lights)
	Ink.grade(p, 0.25, 1.12)
	Ink.finish(p, 0.04, 0.6)
	return p


# ── 장면 ──────────────────────────────────────────────────────────────

## 교수형: 흐린 광장, 높은 단 위 긴 들보에 밧줄 셋 — 두건을 쓴 죄수 셋(사람·덩치 큰 수인·작은 드워프)이 목에 올가미를 걸고 한 줄로 섰다.
## 옆에 복면 집행인·창 든 경비, 단 모서리 화로. 앞에는 등을 보인 군중(가까워서 크고 아래가 잘린다).
static func hanging(p: Paint) -> Array:
	K.sky(p, 330, Color("#262c2e"), Color("#5e6150"))
	K.houses(p, 330, 150, 230)
	K.ground(p, 330)
	var wood := Color("#3a2a1c")
	for x: float in [306.0, 654.0]:  # 기둥
		var post := Paint.rect_poly(x - 10, 62, 20, 240)
		p.fill_poly(post, Mat.beam(p, wood))
		Ink.shade(p, post, Vector2(x - 10, 0), Vector2(x + 10, 0), 0.0, 0.5)
		Ink.path(p, post, 2.2)
	var beam := Paint.rect_poly(286, 54, 388, 20)
	p.fill_poly(beam, Mat.beam(p, wood))
	Ink.path(p, beam, 2.2)
	for s: float in [-1.0, 1.0]:  # 버팀대
		Ink.line(p, Vector2(480 + s * 174, 124), Vector2(480 + s * 120, 74), 7.0, wood.darkened(0.2), 1.0, 0.3)
	var deck := Paint.rect_poly(250, 300, 460, 18)  # 단
	p.fill_poly(deck, Mat.planks(p, Color("#4a3624"), 250, 300, false, 12))
	Ink.path(p, deck, 2.2)
	var face := Paint.rect_poly(256, 318, 448, 56)
	p.fill_poly(face, Mat.planks(p, Color("#3a2a1c"), 256, 318, true, 14))
	Ink.shade(p, face, Vector2(0, 318), Vector2(0, 374), 0.1, 0.55)
	Ink.path(p, face, 2.2)
	var rope := Color("#8a7a58")
	var condemned := [[400.0, 150.0, {"body": "male", "top": Color("#5a5040"), "bottom": Color("#3a342a")}],
		[488.0, 172.0, {"body": "stout", "top": Color("#4a4034"), "bottom": Color("#34302a")}],
		[568.0, 118.0, {"body": "stout", "top": Color("#5e4a36"), "bottom": Color("#3a3028")}]]  # 사람 · 수인(크다) · 드워프(작다)
	for c: Array in condemned:
		var x := float(c[0])
		var h := float(c[1])
		var look: Dictionary = (c[2] as Dictionary).duplicate()
		look.merge({"hair": "hood", "hood_c": Color("#7a6a4c"), "arms": "down", "light": -1.0, "keep": 0.15})
		K.person(p, x, 300, h, look)
		var neck := K.at(Vector3(x, 300, h), 0.0, 0.86)
		Ink.line(p, Vector2(x, 74), neck, 2.6, rope, 1.0, 0.4)  # 밧줄
		Ink.line(p, neck + Vector2(-9, 0), neck + Vector2(9, 0), 3.4, rope, 1.0, 0.2)  # 올가미
	K.person(p, 666, 300, 160, {"body": "stout", "top": Color("#2a2420"), "bottom": Color("#221e1a"), "hair": "hood", "hood_c": Color("#1c1816"),
		"arms": "crossed", "bare_arms": true, "skin": Color("#a87656"), "light": -1.0})
	K.person(p, 282, 300, 156, {"body": "male", "top": Color("#5c5e60"), "bottom": Color("#34363a"), "belt": Color("#2a1e14"), "hair": "scarf",
		"hood_c": Color("#5a5a58"), "beard": "stubble", "spear": true, "light": -1.0})
	K.brazier(p, 236, 330, 0.8)
	K.brazier(p, 724, 330, 0.8)
	var crowd := [[130.0, 420.0, 150.0, 0], [220.0, 410.0, 140.0, 1], [740.0, 415.0, 146.0, 2], [830.0, 425.0, 156.0, 3],
		[60.0, 640.0, 360.0, 4], [300.0, 660.0, 380.0, 1], [640.0, 650.0, 370.0, 2], [900.0, 640.0, 350.0, 0]]
	for c: Array in crowd:
		var look := K.hazed(K.crowd_look(int(c[3])), 0.3 if float(c[1]) < 500.0 else 0.0)
		look["back"] = true
		K.person(p, float(c[0]), float(c[1]), float(c[2]), look)
	return [[Vector2(480, 40), 900.0, SKY, 0.5], [Vector2(236, 240), 160.0, FIRE, 0.6], [Vector2(724, 240), 160.0, FIRE, 0.6]]


## 납세 포고: 관청 돌벽 앞 궤짝 위에서 포고관이 포고문을 펼쳐 읽는다. 벽에는 붉은 밀랍을 찍은 포고문, 옆에 창 든 경비, 앞에 군중의 등.
static func tax_notice(p: Paint) -> Array:
	var wall := Paint.rect_poly(0, 0, W, 400)
	p.fill_poly(wall, Mat.ashlar(p, Color("#55524a"), 0, 0, 64, 30))
	Ink.shade(p, wall, Vector2(0, 0), Vector2(0, 400), 0.35, 0.1)
	Parts.window(p, 90, 70, 70, 110, "arch", false, true)
	Parts.window(p, 800, 70, 70, 110, "arch", false, true)
	Parts.door(p, 650, 200, 110, 200, true, Color("#3b2a1e"))
	K.paper(p, 520, 130, 92, 124, true)
	K.paper(p, 486, 160, 40, 56)
	Parts.plinth(p, 0, 380, W, 22)
	K.ground(p, 400)
	Props.crate(p, 380, 470, 74)
	K.person(p, 380, 400, 230, {"body": "male", "top": Color("#5a2a24"), "bottom": Color("#2e2620"), "stole": Color("#a88a4a"), "collar": Color("#cfc4a6"),
		"arms": "book", "hair": "short", "hair_c": Color("#2a2018"), "beard": "mustache", "light": -1.0})
	var sc := K.at(Vector3(380, 400, 230), -0.07, 0.76)  # 펼친 포고문(책 위에 덮는다)
	K.paper(p, sc.x, sc.y, 0.17 * 230, 0.2 * 230, true)
	K.person(p, 240, 410, 228, {"body": "male", "top": Color("#5c5e60"), "bottom": Color("#34363a"), "belt": Color("#2a1e14"), "hair": "scarf",
		"hood_c": Color("#5a5a58"), "beard": "stubble", "spear": true, "light": -1.0})
	Parts.lantern(p, 610, 190, 1.4)
	for c: Array in [[120.0, 650.0, 360.0, 3], [560.0, 640.0, 350.0, 0], [800.0, 660.0, 380.0, 2]]:
		var look := K.crowd_look(int(c[3]))
		look["back"] = true
		K.person(p, float(c[0]), float(c[1]), float(c[2]), look)
	return [[Vector2(380, 120), 640.0, SKY, 0.55], [Vector2(610, 205), 200.0, WARM, 0.55]]


## 소매치기: 해 질 녘 붐비는 골목, 불룩한 돈주머니를 찬 상인 뒤로 두건 쓴 자가 손을 뻗는다. 등롱 둘.
static func pickpocket(p: Paint) -> Array:
	K.sky(p, 200, Color("#1e2226"), Color("#4a4438"))
	K.houses(p, 380, 70, 130, -10.0, W + 10.0, 0.45)
	Parts.lantern(p, 230, 170, 1.4)
	Parts.lantern(p, 760, 150, 1.4)
	K.ground(p, 380)
	for c: Array in [[120.0, 470.0, 210.0, 0], [300.0, 480.0, 220.0, 1], [780.0, 470.0, 214.0, 5], [880.0, 490.0, 226.0, 3]]:
		K.person(p, float(c[0]), float(c[1]), float(c[2]), K.hazed(K.crowd_look(int(c[3])), 0.25))
	var mark := Vector3(560, 520, 300)  # 상인(앞모습) — 허리 오른쪽 돈주머니
	K.person(p, mark.x, mark.y, mark.z, {"body": "stout", "top": Color("#6a4a2c"), "bottom": Color("#3a2e22"), "belt": Color("#2a1e14"),
		"collar": Color("#8a7a52"), "arms": "down", "hair": "bald", "hair_c": Color("#3a2c22"), "beard": "full", "light": -1.0})
	var pouch := K.at(mark, 0.1, 0.56)
	var bag := Paint.poly([pouch + Vector2(-12, -6), pouch + Vector2(12, -6), pouch + Vector2(16, 18), pouch + Vector2(0, 26), pouch + Vector2(-16, 18)])
	p.fill_poly(bag, p.flat(Color("#6a4a2a"), 0.2))
	Ink.path(p, bag, 1.8)
	K.person(p, 420, 530, 290, {"body": "male", "top": Color("#26241f"), "bottom": Color("#1e1c18"), "hair": "hood", "hood_c": Color("#2a2824"),
		"back": true, "light": 1.0})
	var sh := K.at(Vector3(420, 530, 290), 0.11, 0.8)  # 뻗은 팔(소매 → 손이 주머니 끈에)
	var hand := pouch + Vector2(-6, -2)
	Ink.line(p, sh, sh.lerp(hand, 0.55) + Vector2(0, 8), 20.0, Color("#26241f"), 1.0, 0.4)
	Ink.line(p, sh.lerp(hand, 0.55) + Vector2(0, 8), hand + Vector2(-10, 0), 16.0, Color("#26241f"), 1.0, 0.4)
	var fist := PackedVector2Array()
	for i in 10:
		fist.append(hand + Vector2(cos(TAU * i / 10.0) * 9.0, sin(TAU * i / 10.0) * 7.0))
	p.fill_poly(fist, p.flat(Npc.SKIN.darkened(0.25), 0.1))
	Ink.path(p, fist, 1.6)
	Ink.glow(p, pouch.x, pouch.y + 8, 40, WARM, 0.12)
	return [[Vector2(230, 185), 260.0, WARM, 0.6], [Vector2(760, 165), 260.0, WARM, 0.55], [Vector2(560, 340), 360.0, WARM, 0.25]]


## 검문: 거리를 가로막은 목책·궤짝·술통, 그 앞에 쇠사슬 두건을 쓴 경비 둘(창), 가운데 화로. 앞에 짐을 진 사람들이 줄을 섰다.
static func checkpoint(p: Paint) -> Array:
	K.sky(p, 300, Color("#22282a"), Color("#56584a"))
	K.houses(p, 340, 120, 200)
	K.ground(p, 340)
	Props.fence(p, 120, 840, 440, 74)
	Props.crate(p, 170, 446, 58)
	Props.barrel(p, 780, 448, 50, 64)
	Props.crate(p, 830, 446, 46)
	K.brazier(p, 480, 446, 1.2)
	var guard := {"body": "male", "top": Color("#5c5e60"), "bottom": Color("#34363a"), "belt": Color("#2a1e14"), "hair": "scarf",
		"hood_c": Color("#6a6c68"), "beard": "stubble", "spear": true}
	var g1 := guard.duplicate()
	g1["light"] = 1.0
	K.person(p, 350, 470, 250, g1)
	var g2 := guard.duplicate()
	g2["light"] = -1.0
	g2["arms"] = "crossed"
	K.person(p, 620, 470, 254, g2)
	for c: Array in [[90.0, 650.0, 370.0, 0], [260.0, 680.0, 400.0, 2], [760.0, 660.0, 380.0, 5]]:
		var look := K.crowd_look(int(c[3]))
		look["back"] = true
		look["pack"] = Color("#6a5236")
		K.person(p, float(c[0]), float(c[1]), float(c[2]), look)
	return [[Vector2(480, 340), 340.0, FIRE, 0.75], [Vector2(480, 60), 800.0, SKY, 0.35]]


## 현상수배: 돌담에 박은 판자 게시판, 서툰 얼굴을 그린 수배지 넷(하나는 찢겼다)과 쪽지, 등롱 아래에서 두건 쓴 자가 올려다본다.
static func wanted(p: Paint) -> Array:
	var wall := Paint.rect_poly(0, 0, W, 440)
	p.fill_poly(wall, Mat.plaster(p, Color("#5a5446"), 0.35))
	Ink.shade(p, wall, Vector2(0, 0), Vector2(W, 0), 0.1, 0.4)
	var board := Paint.rect_poly(200, 70, 540, 290)
	p.fill_poly(board, Mat.planks(p, Color("#4a3624"), 200, 70, false, 18))
	Ink.shade(p, board, Vector2(200, 0), Vector2(740, 0), 0.0, 0.35)
	Ink.path(p, board, 2.6)
	for x: float in [220.0, 704.0]:
		var leg := Paint.rect_poly(x, 360, 16, 90)
		p.fill_poly(leg, Mat.beam(p))
		Ink.path(p, leg, 2.0)
	K.paper(p, 226, 92, 110, 150, false, true)
	K.paper(p, 352, 86, 116, 156, true, true)
	K.paper(p, 486, 96, 104, 146, false, true, true)
	K.paper(p, 606, 90, 112, 152, true, true)
	K.paper(p, 268, 262, 70, 80)
	K.paper(p, 548, 258, 90, 86)
	Parts.lantern(p, 120, 110, 1.5)
	K.ground(p, 440)
	K.person(p, 640, 640, 380, {"body": "male", "top": Color("#2e2c26"), "bottom": Color("#24221e"), "hair": "hood", "hood_c": Color("#34322c"),
		"back": true, "pack": Color("#4a3a28"), "light": -1.0})
	return [[Vector2(120, 130), 420.0, WARM, 0.75], [Vector2(480, 200), 520.0, SKY, 0.2]]
