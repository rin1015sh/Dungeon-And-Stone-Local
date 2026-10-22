extends RefCounted
## 거리 사건 일러스트 셋째 묶음(CT45 — Events와 같은 문법): 술주정 · 심부름 · 화재 · 역병 소문.
## 장면 함수는 광원 목록을 돌려준다(Interiors.light).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Backdrop := preload("res://tools/city_art/Backdrop.gd")
const K := preload("res://tools/city_art/EventKit.gd")

const W := K.W
const H := K.H
const E2 := preload("res://tools/city_art/Events2.gd")


static func scene(p: Paint, id: String) -> Array:
	match id:
		"drunk":
			return drunk(p)
		"errand":
			return errand(p)
		"fire":
			return fire(p)
		"plague":
			return plague(p)
	return []


## 가까운 집 앞면(x, 처마 y, 폭, 바닥): 회벽·목조 뼈대 + 처마 지붕.
static func front(p: Paint, x: float, top: float, fw: float, base: float, wall: Color) -> void:
	var poly := Paint.rect_poly(x, top, fw, base - top)
	Parts.wall(p, poly, Mat.plaster(p, wall, 0.25), 0.25)
	for k in int(fw / 120.0) + 1:
		Ink.line(p, Vector2(x + k * 120.0, top), Vector2(x + k * 120.0, base), 10.0, Color("#2e2118"), 1.0, 0.4)
	Ink.line(p, Vector2(x, top + (base - top) * 0.48), Vector2(x + fw, top + (base - top) * 0.48), 10.0, Color("#2e2118"), 1.0, 0.4)
	var roof := Paint.poly([Vector2(x - 30, top), Vector2(x + fw + 30, top), Vector2(x + fw, top - 70), Vector2(x, top - 70)])
	Parts.roof(p, roof, Mat.slate(p, Color("#30363a"), int(x), int(top), 16, 10, 0.3))


## 불길(바닥 가운데 cx, base, 폭, 높이): 붉은 → 주황 → 노랑 혀 세 겹.
static func flames(p: Paint, cx: float, base: float, fw: float, fh: float) -> void:
	for layer in 3:
		var col: Color = [Color("#a8401a"), Color("#f08a2a"), Color("#ffe08a")][layer]
		var k := 1.0 - layer * 0.28
		for t in 7:
			var x := cx + (t / 6.0 - 0.5) * fw * k
			var hh := fh * k * p.rng.randf_range(0.5, 1.0)
			var tongue := Paint.poly([Vector2(x - fw * 0.09 * k, base), Vector2(x - fw * 0.04, base - hh * 0.55), Vector2(x + p.rng.randf_range(-8, 8), base - hh),
				Vector2(x + fw * 0.05, base - hh * 0.5), Vector2(x + fw * 0.09 * k, base)])
			p.fill_poly(tongue, p.flat(col, 0.08), 0.9)
	Ink.glow(p, cx, base - fh * 0.4, fw * 1.2, Color("#ff8a3a"), 0.5, false)


## 술주정: 밤, 불 켜진 선술집 문 앞에서 얼굴 붉은 사내가 술병을 들고 술통에 기댔다. 쏟아진 잔, 문간에 선 사람.
static func drunk(p: Paint) -> Array:
	K.sky(p, 120, Color("#121618"), Color("#262a2a"))
	front(p, -20, 110, 1000, 430, Color("#5e5341"))
	Parts.window(p, 90, 170, 110, 90, "square", true)
	Parts.window(p, 720, 170, 110, 90, "square", true)
	Parts.door(p, 420, 220, 120, 210, true, Color("#3b2a1e"), true)
	Parts.sign(p, 560, 150, "mug", 1.0, 60)
	Parts.lantern(p, 400, 210, 1.5)
	Parts.plinth(p, -20, 410, 1000, 24)
	K.ground(p, 432)
	var keeper := K.crowd_look(4)
	keeper["apron"] = Color("#6a5a40")
	keeper["arms"] = "crossed"
	keeper["light"] = 1.0
	K.person(p, 480, 430, 190, K.hazed(keeper, 0.25))
	Props.barrel(p, 700, 540, 110, 130)
	var o := Vector3(620, 560, 340)
	K.person(p, o.x, o.y, o.z, {"body": "stout", "top": Color("#6a3e30"), "bottom": Color("#3e3428"), "belt": Color("#2a1e14"), "arms": "counter",
		"hands_v": 0.62, "hair": "short", "hair_c": Color("#3a2a1e"), "beard": "stubble", "skin": Color("#c08068"), "light": -1.0})
	var hand := K.at(o, -0.09, 0.64)  # 술병
	var bottle := Paint.poly([hand + Vector2(-8, 4), hand + Vector2(-8, -30), hand + Vector2(-3, -40), hand + Vector2(-3, -52), hand + Vector2(3, -52), hand + Vector2(3, -40), hand + Vector2(8, -30), hand + Vector2(8, 4)])
	p.fill_poly(bottle, p.flat(Color("#2f4430"), 0.15))
	Ink.path(p, bottle, 1.6)
	Ink.line(p, hand + Vector2(-4, -26), hand + Vector2(-4, -4), 1.6, Color("#c8c0a0"), 0.4, 0.1)
	Bits.mug(p, 330, 520)
	var spill := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		spill.append(Vector2(300 + cos(a) * 46.0 * p.rng.randf_range(0.8, 1.1), 528 + sin(a) * 8.0))
	p.fill_poly(spill, p.flat(Color("#3a2e1a"), 0.1), 0.7)
	return [[Vector2(480, 330), 300.0, K.WARM, 0.8], [Vector2(145, 215), 230.0, K.WARM, 0.6], [Vector2(775, 215), 230.0, K.WARM, 0.6], [Vector2(400, 225), 200.0, K.WARM, 0.4]]


## 심부름: 흐린 낮 거리, 바퀴가 빠져 한쪽으로 주저앉은 짐수레(자루가 쏟아졌다), 빠진 바퀴가 바닥에 누웠고 늙은이가 허리를 짚고 서 있다.
static func errand(p: Paint) -> Array:
	K.sky(p, 260, Color("#30383a"), Color("#6a6a56"))
	K.houses(p, 330, 110, 190)
	K.ground(p, 330)
	var cx := 520.0
	var bed := Paint.poly([Vector2(cx - 150, 400), Vector2(cx + 150, 372), Vector2(cx + 156, 420), Vector2(cx - 146, 462)])  # 기운 짐칸
	p.fill_poly(bed, Mat.planks(p, Color("#4d3726"), int(cx), 0, false, 10))
	Ink.path(p, bed, 2.4)
	for k in 5:
		Props.sack(p, cx - 110 + k * 50, 392 - k * 5, 44)
	Props.sack(p, cx - 210, 500, 46)
	Props.sack(p, cx - 160, 520, 40)
	E2.wheel(p, Vector2(cx + 110, 432), 38)
	var lying := PackedVector2Array()  # 빠진 바퀴(바닥에 누운 타원)
	for i in 24:
		lying.append(Vector2(cx - 40, 500) + Vector2(cos(TAU * i / 24.0) * 46.0, sin(TAU * i / 24.0) * 14.0))
	Ink.path(p, lying, 6.0, true, Color("#2a1e15"))
	Ink.line(p, Vector2(cx - 84, 500), Vector2(cx + 4, 500), 3.0, Color("#2a1e15"), 1.0, 0.1)
	Ink.line(p, Vector2(cx + 150, 380), Vector2(cx + 230, 420), 6.0, Color("#3a2a1c"), 1.0, 0.3)
	K.person(p, 270, 520, 300, {"body": "male", "top": Color("#5a4a38"), "bottom": Color("#3a3228"), "belt": Color("#2a1e14"), "arms": "down",
		"hair": "bald", "hair_c": Color("#8a847a"), "beard": "full", "old": true, "skin": Color("#a88468"), "light": -1.0})
	return [[Vector2(480, 60), 860.0, K.SKY, 0.6]]


## 화재(다음 날): 밤사이 불탄 집 — 검게 그을린 벽, 뻥 뚫린 창, 내려앉은 지붕 들보, 아직 남은 불씨와 골목에 깔린 연기. 구경꾼의 등.
static func fire(p: Paint) -> Array:
	K.sky(p, 300, Color("#2a2826"), Color("#5e564a"))
	K.houses(p, 340, 120, 180, -10.0, 300.0, 0.3)
	K.houses(p, 340, 130, 190, 660.0, W + 10.0, 0.3)
	var wall := Paint.poly([Vector2(290, 360), Vector2(290, 160), Vector2(340, 150), Vector2(380, 190), Vector2(440, 140), Vector2(520, 176), Vector2(580, 130), Vector2(670, 160), Vector2(670, 360)])
	p.fill_poly(wall, Mat.plaster(p, Color("#3a342c"), 0.5))
	Ink.shade(p, wall, Vector2(0, 130), Vector2(0, 360), 0.65, 0.3, Color("#0c0a08"))  # 그을음(위가 더 검다)
	Ink.path(p, wall, 2.4)
	for x: float in [330.0, 450.0, 570.0]:
		var hole := Paint.poly([Vector2(x, 210), Vector2(x + 62, 206), Vector2(x + 58, 286), Vector2(x + 4, 290)])
		p.fill_poly(hole, p.flat(Color("#0a0806"), 0.05))
		Ink.path(p, hole, 2.0)
		Ink.glow(p, x + 30, 280, 30, Color("#ff6a2a"), 0.35, false)
		Ink.shade(p, Paint.rect_poly(x - 10, 150, 84, 60), Vector2(0, 210), Vector2(0, 150), 0.6, 0.0, Color("#0a0806"))  # 창 위 그을음 혀
	for k in 4:  # 내려앉은 들보
		var a := Vector2(300 + k * 95, 150 + (k % 2) * 30)
		Ink.line(p, a, a + Vector2(110, 40 - (k % 2) * 70), 12.0, Color("#1c140e"), 1.0, 0.8)
	Parts.door(p, 440, 290, 80, 70, false, Color("#1a120c"))
	for k in 3:
		Backdrop._smoke(p, Vector2(360 + k * 110, 160), 150)
	for k in 5:  # 골목에 깔린 연기
		var q := Vector2(p.rng.randf_range(80, 880), p.rng.randf_range(330, 420))
		Ink.glow(p, q.x, q.y, p.rng.randf_range(120, 200), Color("#6a665a"), 0.25, false, 0.35)
	K.ground(p, 360)
	for i in 12:  # 잿더미와 불씨
		var q := Vector2(p.rng.randf_range(300, 660), p.rng.randf_range(362, 392))
		p.fill_rect(q.x, q.y, p.rng.randf_range(8, 20), 5, p.flat(Color("#1a1612"), 0.2))
		if i % 3 == 0:
			Ink.glow(p, q.x + 6, q.y, 14, Color("#ff7a2a"), 0.4, false)
	for c: Array in [[90.0, 640.0, 380.0, 0], [250.0, 610.0, 330.0, 4], [700.0, 630.0, 360.0, 2], [870.0, 660.0, 400.0, 1]]:
		var look := K.crowd_look(int(c[3]))
		look["back"] = true
		K.person(p, float(c[0]), float(c[1]), float(c[2]), look)
	return [[Vector2(480, 60), 800.0, K.SKY, 0.4], [Vector2(480, 300), 300.0, K.FIRE, 0.35]]


## 역병 소문: 옅은 안개, 신전 아치 문 앞으로 길게 늘어선 줄 — 천으로 입을 가린 사람들, 한 사람은 등을 굽혀 기침한다. 문 옆 촛불.
static func plague(p: Paint) -> Array:
	K.sky(p, 200, Color("#252a26"), Color("#4e5644"))
	var nave := Paint.poly([Vector2(500, 380), Vector2(500, 120), Vector2(700, 40), Vector2(900, 120), Vector2(900, 380)])
	p.fill_poly(nave, Mat.ashlar(p, Color("#6a6458"), 0, 0, 50, 24))
	Ink.shade(p, nave, Vector2(500, 0), Vector2(900, 0), 0.0, 0.35)
	Ink.path(p, nave, 2.4)
	Parts.door(p, 640, 230, 120, 150, true, Color("#3b2a1e"), true)
	Parts.window(p, 670, 120, 60, 80, "gothic", true)
	K.houses(p, 380, 120, 190, -10.0, 500.0, 0.4)
	K.houses(p, 380, 140, 200, 900.0, W + 10.0, 0.4)
	K.ground(p, 380)
	Props.candle(p, 610, 380, 22)
	Props.candle(p, 790, 380, 22)
	var queue := [[600.0, 395.0, 150.0, 3], [540.0, 410.0, 168.0, 0], [470.0, 428.0, 190.0, 1], [390.0, 450.0, 216.0, 2], [300.0, 480.0, 250.0, 4], [190.0, 520.0, 300.0, 5]]
	for c: Array in queue:
		var look := K.hazed(K.crowd_look(int(c[3])), 0.35 if float(c[1]) < 440.0 else 0.0)
		look["back"] = true
		look["light"] = 1.0
		K.person(p, float(c[0]), float(c[1]), float(c[2]), look)
	var o := Vector3(760, 600, 380)  # 앞을 보고 선 사람 — 천으로 입을 가렸다
	K.person(p, o.x, o.y, o.z, {"body": "female", "top": Color("#4a4438"), "lower": "dress", "bottom": Color("#3a342c"), "arms": "crossed",
		"hair": "scarf", "hood_c": Color("#6a6250"), "light": -1.0})
	var mask := Paint.poly([K.at(o, -0.05, 0.912), K.at(o, 0.05, 0.912), K.at(o, 0.048, 0.86), K.at(o, 0.0, 0.84), K.at(o, -0.048, 0.86)])
	p.fill_poly(mask, p.flat(Color("#9a927c"), 0.15))
	Ink.path(p, mask, 1.4)
	Ink.shade(p, Paint.rect_poly(0, 0, W, K.H), Vector2(0, 0), Vector2(0, K.H), 0.25, 0.05, Color("#7a8070"))  # 안개
	return [[Vector2(700, 300), 260.0, K.WARM, 0.5], [Vector2(480, 60), 760.0, K.SKY, 0.4]]
