extends RefCounted
## 거리 사건 일러스트 둘째 묶음(CT45 — Events와 같은 문법): 마석 넘침 · 마석 매집 · 포션 품귀 · 수상한 약장수 · 구걸.
## 장면 함수는 광원 목록을 돌려준다(Interiors.light).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Npc := preload("res://tools/city_art/Npcs.gd")
const K := preload("res://tools/city_art/EventKit.gd")

const W := K.W
const H := K.H

const STONE := Color("#6fc8b4")  ## 마석 빛(탁한 청록)


static func scene(p: Paint, id: String) -> Array:
	match id:
		"stone_glut":
			return stone_glut(p)
		"stone_demand":
			return stone_demand(p)
		"potion_shortage":
			return potion_shortage(p)
		"dubious_peddler":
			return dubious_peddler(p)
		"beggar":
			return beggar(p)
	return []


## 마석 한 무더기: 각진 작은 돌 n개(밑은 넓고 위로 좁게) + 빛.
static func stones(p: Paint, cx: float, base: float, wide: float, n: int) -> void:
	for i in n:
		var t := p.rng.randf()
		var q := Vector2(cx + p.rng.randf_range(-wide, wide) * (1.0 - t * 0.7), base - t * wide * 0.55 - p.rng.randf_range(0, 4))
		var r := p.rng.randf_range(4.0, 7.5)
		var pts := PackedVector2Array()
		for k in 6:
			pts.append(q + Vector2.from_angle(TAU * k / 6.0 + p.rng.randf()) * r * p.rng.randf_range(0.7, 1.1))
		p.fill_poly(pts, p.flat(STONE.darkened(p.rng.randf_range(0.2, 0.6)), 0.15))
		Ink.path(p, pts, 1.0, true, Ink.INK, 0.7, 0.2)
		Ink.line(p, q + Vector2(-2, -2), q + Vector2(1, -3), 1.2, STONE.lightened(0.4), 0.7, 0.1)
	Ink.glow(p, cx, base - wide * 0.2, wide * 1.6, STONE, 0.35, false)


## 차양 친 노점 탁자(x0..x1, 탁자 윗면 y): 줄무늬 차양 + 기둥 + 판자 탁자.
static func stall(p: Paint, x0: float, x1: float, top: float, cloth: Color) -> void:
	for x: float in [x0 + 8, x1 - 8]:
		Ink.line(p, Vector2(x, top + 70), Vector2(x, top - 150), 7.0, Color("#3a2a1c"), 1.0, 0.2)
	var awn := Paint.poly([Vector2(x0 - 20, top - 120), Vector2(x1 + 20, top - 120), Vector2(x1 + 36, top - 82), Vector2(x0 - 36, top - 82)])
	p.fill_poly(awn, func(x: int, y: int) -> Color:
		var c := cloth if int((x - x0) / 34.0) % 2 == 0 else Color("#bdb08a").darkened(0.25)
		return p.vary(c, x, y, 0.12))
	Ink.shade(p, awn, Vector2(0, top - 120), Vector2(0, top - 82), 0.0, 0.35)
	Ink.path(p, awn, 2.2)
	var front := Paint.rect_poly(x0, top, x1 - x0, 74)
	p.fill_poly(front, Mat.planks(p, Color("#4a3624"), int(x0), int(top), true, 18))
	Ink.shade(p, front, Vector2(0, top), Vector2(0, top + 74), 0.1, 0.5)
	Ink.path(p, front, 2.2)
	var board := Paint.rect_poly(x0 - 6, top - 10, x1 - x0 + 12, 12)
	p.fill_poly(board, Mat.planks(p, Color("#5a4430"), 0, 0, false, 9))
	Ink.path(p, board, 2.0)


## 원정대 귀환: 마석 자루를 가득 실은 짐수레, 시장 노점에 마석이 수북이 쌓이고(값판의 값에 줄을 긋는다), 짐을 진 탐험가들.
static func stone_glut(p: Paint) -> Array:
	K.sky(p, 260, Color("#262c2e"), Color("#5e6150"))
	K.houses(p, 330, 110, 190)
	K.ground(p, 330)
	K.person(p, 450, 420, 200, {"body": "stout", "top": Color("#5a4a3a"), "bottom": Color("#3a3028"), "apron": Color("#5a4630"),
		"arms": "counter", "hair": "bald", "beard": "mustache", "light": -1.0})
	stall(p, 270, 640, 380, Color("#6a3a2a"))
	stones(p, 360, 372, 60, 70)
	stones(p, 520, 372, 54, 60)
	var sign := Paint.rect_poly(680, 250, 90, 70)
	Ink.line(p, Vector2(725, 320), Vector2(725, 450), 6.0, Color("#3a2a1c"), 1.0, 0.2)
	p.fill_poly(sign, Mat.planks(p, Color("#4a3624"), 680, 250, false, 10))
	Ink.path(p, sign, 2.0)
	for k in 3:
		Ink.line(p, Vector2(692, 268 + k * 16), Vector2(752, 268 + k * 16), 2.0, K.PAPER, 0.7, 0.6)
	Ink.line(p, Vector2(688, 300), Vector2(760, 262), 3.0, Color("#7d2620"), 0.9, 0.5)
	cart(p, 150, 470)
	Props.sack(p, 840, 525, 64)
	for c: Array in [[90.0, 660.0, 380.0], [760.0, 650.0, 372.0], [900.0, 680.0, 400.0]]:
		K.person(p, float(c[0]), float(c[1]), float(c[2]), {"body": "male", "top": Color("#4e4434"), "bottom": Color("#34302a"), "back": true,
			"pack": Color("#6a5236"), "hair": "short", "hair_c": Color("#2a2018"), "spear": c[0] > 800.0, "light": -1.0})
	return [[Vector2(440, 360), 300.0, STONE, 0.6], [Vector2(480, 60), 800.0, K.SKY, 0.4]]


## 마석 매집: 천막 아래 탁자에 놋쇠 저울·동전 더미·장부, 법의에 영대를 두른 마도 공방 매입인과 돈궤, 기둥에 붙은 쪽지, 앞에 자루를 든 사람들.
static func stone_demand(p: Paint) -> Array:
	K.sky(p, 240, Color("#22282a"), Color("#56584a"))
	K.houses(p, 330, 100, 170)
	K.ground(p, 330)
	K.person(p, 520, 420, 210, {"body": "male", "top": Color("#3e3a48"), "lower": "robe", "bottom": Color("#2a2830"), "stole": Color("#4a6a8a"), "glasses": true,
		"arms": "counter", "hair": "short", "hair_c": Color("#4a4a44"), "old": true, "light": -1.0})
	K.paper(p, 270, 240, 46, 56, true)
	stall(p, 300, 700, 380, Color("#2e3a44"))
	Bits.scale(p, Vector2(420, 370))
	Bits.coins(p, Vector2(600, 372))
	stones(p, 390, 340, 14, 8)
	Bits.open_book(p, Vector2(520, 362), 24)
	var chest := Paint.rect_poly(724, 400, 90, 60)
	p.fill_poly(chest, Mat.planks(p, Color("#4a3020"), 724, 400, false, 12))
	Ink.path(p, chest, 2.2)
	Ink.line(p, Vector2(724, 418), Vector2(814, 418), 3.0, Color("#24221f"), 1.0, 0.1)
	Bits.coins(p, Vector2(770, 400))
	Parts.lantern(p, 300, 210, 1.3)
	for c: Array in [[110.0, 640.0, 370.0, 0], [260.0, 690.0, 410.0, 2], [880.0, 660.0, 380.0, 5]]:
		var look := K.crowd_look(int(c[3]))
		look["back"] = true
		K.person(p, float(c[0]), float(c[1]), float(c[2]), look)
	Props.sack(p, 330, 530, 56)
	return [[Vector2(560, 340), 300.0, K.WARM, 0.55], [Vector2(300, 225), 220.0, K.WARM, 0.5], [Vector2(480, 60), 800.0, K.SKY, 0.35]]


## 포션 품귀: 상점 진열창 안 선반에 붉은 포션이 몇 병 남았고, 그 앞에 새로 붙인 큰 가격표(옛 값에 줄). 사람들이 팔짱을 끼고 들여다본다.
static func potion_shortage(p: Paint) -> Array:
	var wall := Paint.rect_poly(0, 0, W, 420)
	p.fill_poly(wall, Mat.plaster(p, Color("#5e5341"), 0.3))
	Ink.shade(p, wall, Vector2(0, 0), Vector2(W, 0), 0.0, 0.35)
	var win := Paint.rect_poly(150, 100, 420, 240)
	p.fill_poly(win, p.flat(Color("#2a2420"), 0.1))
	for y: float in [190.0, 290.0]:
		var shelf := Paint.rect_poly(162, y, 396, 8)
		p.fill_poly(shelf, Mat.planks(p, Color("#3a2a1c"), 0, 0, false, 7))
		Ink.path(p, shelf, 1.6)
	for x: float in [200.0, 236.0, 410.0]:  # 남은 붉은 포션
		vial(p, x, 290, Color("#8a2a24"))
	for x: float in [300.0, 480.0]:
		vial(p, x, 190, Color("#8a2a24"))
	var tag := Paint.poly([Vector2(330, 214), Vector2(420, 210), Vector2(424, 272), Vector2(334, 276)])  # 새 가격표
	p.fill_poly(tag, p.flat(Color("#e0d4b0"), 0.12))
	Ink.path(p, tag, 1.8)
	Ink.line(p, Vector2(345, 232), Vector2(400, 230), 3.0, Color("#3a2e22"), 0.8, 0.4)
	Ink.line(p, Vector2(340, 236), Vector2(404, 226), 2.4, Color("#7d2620"), 0.9, 0.3)
	Ink.line(p, Vector2(345, 256), Vector2(410, 254), 4.0, Color("#3a2e22"), 0.9, 0.4)
	Ink.line(p, Vector2(376, 196), Vector2(376, 212), 1.4, Color("#24221f"), 1.0, 0.1)
	for k in 6:  # 창살
		Ink.line(p, Vector2(150 + k * 84, 100), Vector2(150 + k * 84, 340), 3.0, Color("#1d1713"), 0.9, 0.1)
	Ink.path(p, win, 3.0)
	Parts.door(p, 660, 160, 120, 230, true, Color("#3b2a1e"), true)
	Parts.sign(p, 790, 120, "bag", 1.0, 56)
	Parts.plinth(p, 0, 390, W, 30)
	K.ground(p, 420)
	Parts.steps(p, 720, 420, 150, 2, 7)
	var a := K.crowd_look(1)
	a["back"] = true
	a["light"] = -1.0
	K.person(p, 270, 600, 330, a)
	var b2 := K.crowd_look(2)
	b2["arms"] = "crossed"
	b2["light"] = -1.0
	K.person(p, 560, 600, 320, b2)
	var c3 := K.crowd_look(3)
	c3["back"] = true
	K.person(p, 860, 680, 400, c3)
	Parts.lantern(p, 640, 180, 1.3)
	return [[Vector2(360, 220), 320.0, K.WARM, 0.45], [Vector2(480, 80), 760.0, K.SKY, 0.4], [Vector2(640, 195), 200.0, K.WARM, 0.4]]


## 작은 물약 병(바닥 가운데 x, base).
static func vial(p: Paint, x: float, base: float, c: Color) -> void:
	var b := Paint.poly([Vector2(x - 7, base), Vector2(x - 7, base - 18), Vector2(x - 3, base - 26), Vector2(x - 3, base - 32), Vector2(x + 3, base - 32), Vector2(x + 3, base - 26), Vector2(x + 7, base - 18), Vector2(x + 7, base)])
	p.fill_poly(b, p.flat(c, 0.12))
	Ink.path(p, b, 1.2)
	Ink.line(p, Vector2(x - 3, base - 16), Vector2(x - 3, base - 4), 1.2, c.lightened(0.5), 0.6, 0.1)
	p.fill_rect(x - 3, base - 36, 6, 5, p.flat(Color("#5a4430"), 0.1))


## 짐수레(앞 가운데 cx, 바퀴 아래 ground): 판자 짐칸 + 바퀴 둘 + 손잡이 + 마석 자루 무더기.
static func cart(p: Paint, cx: float, ground: float) -> void:
	var bed := Paint.rect_poly(cx - 110, ground - 90, 220, 44)
	p.fill_poly(bed, Mat.planks(p, Color("#4d3726"), int(cx), 0, false, 10))
	Ink.path(p, bed, 2.2)
	for k in 7:
		Props.sack(p, cx - 90 + k * 30 + (k % 2) * 6, ground - 88 - (k % 2) * 16, 40)
	for wx: float in [cx - 70, cx + 70]:
		wheel(p, Vector2(wx, ground - 32), 32)
	Ink.line(p, Vector2(cx + 110, ground - 70), Vector2(cx + 180, ground - 40), 6.0, Color("#3a2a1c"), 1.0, 0.3)
	Ink.glow(p, cx, ground - 110, 120, STONE, 0.2, false)


static func wheel(p: Paint, c: Vector2, r: float) -> void:
	var rim := PackedVector2Array()
	for i in 24:
		rim.append(c + Vector2.from_angle(TAU * i / 24.0) * r)
	Ink.path(p, rim, maxf(4.0, r * 0.16), true, Color("#2a1e15"))
	for i in 4:
		var a := TAU * i / 8.0
		Ink.line(p, c - Vector2.from_angle(a) * r * 0.92, c + Vector2.from_angle(a) * r * 0.92, maxf(2.0, r * 0.08), Color("#2a1e15"), 1.0, 0.1)


## 수상한 약장수: 해 진 뒤 좁은 골목 그늘, 외투를 걸친 사내가 한 손으로 손짓하고 품에서 꺼낸 붉은 물약 병을 내민다. 골목 끝 등롱 하나.
static func dubious_peddler(p: Paint) -> Array:
	K.sky(p, 160, Color("#141818"), Color("#2e2c26"))
	var left := Paint.poly([Vector2(0, 0), Vector2(380, 120), Vector2(380, 380), Vector2(0, H)])  # 골목 양쪽 벽(한 점 투시)
	var right := Paint.poly([Vector2(W, 0), Vector2(580, 120), Vector2(580, 380), Vector2(W, H)])
	p.fill_poly(left, Mat.brick(p, Color("#4f362c"), 0, 0, 30, 12))
	p.fill_poly(right, Mat.plaster(p, Color("#4b473b"), 0.4))
	Ink.shade(p, left, Vector2(0, 0), Vector2(380, 0), 0.5, 0.2)
	Ink.shade(p, right, Vector2(W, 0), Vector2(580, 0), 0.5, 0.2)
	var far := Paint.rect_poly(380, 120, 200, 260)
	p.fill_poly(far, Mat.plaster(p, Color("#575142"), 0.2))
	Parts.window(p, 440, 170, 80, 90, "square", true)
	var flo := Paint.poly([Vector2(0, H), Vector2(380, 380), Vector2(580, 380), Vector2(W, H)])
	p.fill_poly(flo, p.flat(Color("#22211d"), 0.3))
	Ink.hatch(p, flo, 14.0, 10.0, 0.18)
	for poly in [left, right, far]:
		Ink.path(p, poly, 2.0, true, Ink.INK, 0.7)
	Parts.lantern(p, 600, 150, 1.2)
	var o := Vector3(420, 600, 400)
	K.person(p, o.x, o.y, o.z, {"body": "male", "top": Color("#2e2a26"), "lower": "robe", "bottom": Color("#24221e"), "arms": "counter", "hands_v": 0.62,
		"hair": "hood", "hood_c": Color("#2a2622"), "beard": "stubble", "scar": true, "light": 1.0})
	var hand := K.at(o, 0.09, 0.62)
	vial(p, hand.x + 4, hand.y + 6, Color("#a02a2a"))
	Ink.glow(p, hand.x + 4, hand.y - 10, 60, Color("#e05a4a"), 0.45, false)
	return [[Vector2(600, 165), 300.0, K.WARM, 0.55], [Vector2(hand.x, hand.y - 10), 160.0, Color("#e05a4a"), 0.5], [Vector2(480, 220), 220.0, K.WARM, 0.3]]


## 외팔이 탐험가: 비 젖은 담 모퉁이에 한쪽 팔이 없는 사내가 담요를 덮고 기대 앉았고, 옆에 찌그러진 투구가 엎어져 있다. 오른쪽으로 지나가는 사람.
static func beggar(p: Paint) -> Array:
	var wall := Paint.rect_poly(0, 0, 620, 420)
	p.fill_poly(wall, Mat.brick(p, Color("#5a3e30"), 0, 0, 30, 12))
	Ink.shade(p, wall, Vector2(0, 0), Vector2(620, 0), 0.05, 0.4)
	var side := Paint.poly([Vector2(620, 0), Vector2(W, 0), Vector2(W, 420), Vector2(620, 420)])
	p.fill_poly(side, Mat.plaster(p, Color("#4b473b"), 0.4))
	Ink.shade(p, side, Vector2(620, 0), Vector2(W, 0), 0.3, 0.6)
	Ink.line(p, Vector2(620, 0), Vector2(620, 420), 3.0, Ink.INK, 0.8, 0.5)
	Ink.grime(p, 40, 30, 560, 300, 0.4)
	K.ground(p, 420)
	var o := Vector3(400, 700, 520)  # 앉은 사람 — 발을 바닥 아래에 두고 다리는 담요가 덮는다
	K.person(p, o.x, o.y, o.z, {"body": "male", "top": Color("#5a4c38"), "bottom": Color("#34302a"), "arms": "down", "one_arm": true,
		"hair": "long", "hair_c": Color("#4a4238"), "beard": "full", "scar": true, "skin": Color("#b08a68"), "light": -1.0, "keep": 0.5})
	var rug := Paint.poly([Vector2(230, 540), Vector2(250, 490), Vector2(310, 468), Vector2(400, 462), Vector2(490, 470), Vector2(550, 496), Vector2(580, 540)])
	p.fill_poly(rug, p.flat(Color("#4a4030"), 0.3))
	Ink.hatch(p, rug, 9.0, 60.0, 0.3)
	Ink.strokes(p, rug, 1.2, 18.0, 6.0, 20.0, 0.18)
	Ink.path(p, rug, 2.4)
	var hc := Vector2(150, 488)  # 엎어진(구멍이 위로) 찌그러진 투구: 둥근 쇠 몸 + 위의 어두운 구멍 + 찌그러진 자국
	var dome := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		dome.append(hc + Vector2(cos(a) * 46.0, sin(a) * 40.0 - (6.0 if i == 8 else 0.0)))
	p.fill_poly(dome, p.flat(Color("#7a7e7c"), 0.18))
	Ink.shade(p, dome, hc + Vector2(-46, 0), hc + Vector2(46, 30), 0.0, 0.6)
	Ink.line(p, hc + Vector2(-30, 12), hc + Vector2(-6, 26), 1.8, Color("#c8c8c0"), 0.5, 0.4)
	Ink.line(p, hc + Vector2(12, 20), hc + Vector2(22, 30), 3.0, Ink.INK, 0.7, 0.6)  # 찌그러진 자국
	Ink.path(p, dome, 2.2)
	var mouth := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		mouth.append(hc + Vector2(cos(a) * 46.0, sin(a) * 9.0))
	p.fill_poly(mouth, p.flat(Color("#141210"), 0.05))
	Ink.path(p, mouth, 2.4, true, Color("#5a5e5c"), 1.0, 0.2)
	p.fill_rect(hc.x - 8, hc.y - 3, 10, 4, p.flat(Color("#b8954a"), 0.1))  # 동전 한 닢
	var walker := K.crowd_look(5)
	walker["back"] = true
	walker["light"] = -1.0
	K.person(p, 930, 760, 560, walker)
	Parts.lantern(p, 670, 120, 1.4)
	return [[Vector2(670, 140), 420.0, K.WARM, 0.6], [Vector2(300, 60), 700.0, K.SKY, 0.45], [Vector2(220, 460), 260.0, K.WARM, 0.4]]
