extends RefCounted
## 시설 내부 6곳의 가구·장식·사람(시설마다 한 명, Npcs). 각 함수는 방을 칠하고 광원 목록 [[위치, 반지름, 색, 세기] …]을 돌려준다(Interiors.light가 쓴다).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Icons := preload("res://tools/city_art/Icons.gd")
const Deco := preload("res://tools/city_art/Buildings2.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Npc := preload("res://tools/city_art/Npcs.gd")

const WARM := Color("#ffb45c")
const COOL := Color("#a9bfa0")


## 여관: 목조 들보 천장 · 회벽 뒷벽의 돌 난로(불) · 술통 선반 · 긴 탁자와 의자 · 촛대 샹들리에.
static func inn(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.plaster(p, Color("#77694f"), 0.15), Mat.planks(p, Color("#3e2d20"), 0, 0, true, 16), Mat.planks(p, Color("#4a3523"), 0, 0, false, 14), Mat.planks(p, Color("#2c2017"), 0, 0, false, 18))
	for s: float in [1.25, 1.7, 2.3, 3.2]:
		Ink.line(p, I.pt(Vector2(170, 110), s), I.pt(Vector2(550, 110), s), 9.0 * s, Color("#22180f"), 1.0, 0.5)
	Bits.hearth(p, 196, 150, 140, 180)
	for i in 3:
		for k in 3 - i:
			Props.barrel(p, 400 + k * 46 + i * 23, 330 - i * 38, 40, 40)
	Bits.shelf_row(p, 380, 150, 160, "bottles")
	Bits.chandelier(p, Vector2(360, 128), 70)
	Npc.figure(p, 262, 434, 182, {"body": "female", "top": Color("#7a4634"), "bottom": Color("#5e3a2c"), "lower": "dress", "apron": Color("#b4a688"), "arms": "down", "hair": "scarf", "hood_c": Color("#5f6a52"), "hair_c": Color("#4a3020"), "light": 1.0})
	I.box(p, 150, 410, 420, 64, 46, Mat.planks(p, Color("#4b3524"), 150, 410, false, 12), Mat.planks(p, Color("#5a4029"), 0, 0, false, 9))
	for mx: float in [200.0, 300.0, 430.0, 520.0]:
		Bits.mug(p, mx, 404)
	Props.candle(p, 360, 404, 18)
	I.box(p, 120, 488, 480, 26, 20, Mat.planks(p, Color("#3e2c1d"), 0, 0, false, 10), Mat.planks(p, Color("#4b3524"), 0, 0, false, 8))
	Parts.lantern(p, 70, 180, 1.4)
	I.box(p, 640, 372, 330, 110, 34, Mat.planks(p, Color("#3a2a1c"), 640, 372, true, 18), Mat.planks(p, Color("#5a4029"), 0, 0, false, 9))
	for mx: float in [680.0, 720.0, 800.0]:
		Bits.mug(p, mx, 366)
	Bits.shelf_row(p, 640, 230, 300, "bottles")
	Parts.lantern(p, 860, 170, 1.4)
	return [[Vector2(860, 190), 260.0, WARM, 0.55], [Vector2(266, 300), 420.0, WARM, 0.95], [Vector2(360, 395), 260.0, WARM, 0.55], [Vector2(360, 150), 300.0, WARM, 0.45], [Vector2(70, 200), 200.0, WARM, 0.5]]


## 도서관: 벽을 덮은 책장 · 가운데 높은 고딕 창(병든 달빛 줄기) · 사다리 · 초 켠 독서대(펼친 책·해골) · 바닥의 책 더미.
static func library(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.planks(p, Color("#33261b"), 0, 0, true, 18), Bits.books_shader(p), Mat.ashlar(p, Color("#4d4a42"), 0, 330, 70, 30), Mat.planks(p, Color("#221a13"), 0, 0, false, 20))
	Bits.bookcase(p, 176, 116, 112, 214)
	Bits.bookcase(p, 432, 116, 112, 214)
	Parts.window(p, 314, 130, 92, 176, "gothic", false)
	I.shaft(p, Vector2(318, 230), Vector2(402, 230), Vector2(330, 540), Vector2(600, 540), COOL, 0.18)
	Ink.line(p, Vector2(150, 520), Vector2(206, 140), 6.0, Color("#3a2a1e"), 1.0, 0.4)
	Ink.line(p, Vector2(196, 530), Vector2(250, 150), 6.0, Color("#3a2a1e"), 1.0, 0.4)
	for k in 9:
		var t := (k + 1) / 10.0
		Ink.line(p, Vector2(150, 520).lerp(Vector2(206, 140), t), Vector2(196, 530).lerp(Vector2(250, 150), t), 4.0, Color("#3a2a1e"), 1.0, 0.2)
	Npc.figure(p, 404, 442, 180, {"old": true, "body": "male", "top": Color("#3e4a3e"), "lower": "robe", "arms": "book", "hair": "bald", "hair_c": Color("#c8c2b0"), "beard": "full", "glasses": true, "skin": Color("#bc9a80"), "light": -1.0})
	I.box(p, 250, 404, 230, 70, 44, Mat.planks(p, Color("#3c2a1c"), 250, 404, true, 14), Mat.planks(p, Color("#4b3524"), 0, 0, false, 9))
	Bits.open_book(p, Vector2(330, 392), 40)
	Bits.skull(p, Vector2(430, 388), 13)
	Props.candle(p, 280, 398, 22)
	Bits.book_pile(p, 70, 520, 6)
	Bits.book_pile(p, 620, 520, 4)
	return [[Vector2(280, 370), 300.0, WARM, 0.75], [Vector2(360, 230), 300.0, COOL, 0.45], [Vector2(470, 520), 260.0, COOL, 0.25]]


## 신전: 둥근 천장의 갈빗대 · 줄 선 기둥 · 제단과 촛불 · 큰 색유리 창의 빛줄기 · 해 문장 · 긴 의자.
static func temple(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.ashlar(p, Color("#7a7262"), 170, 110, 40, 20), Mat.ashlar(p, Color("#625b4f"), 0, 0, 50, 24), Mat.ashlar(p, Color("#55514a"), 0, 330, 80, 34), Bits.vault_shader(p))
	for s: float in [1.3, 1.9, 2.8]:
		for bx: float in [170.0, 550.0]:
			Bits.column(p, I.pt(Vector2(bx, 110), s), I.pt(Vector2(bx, 330), s), 18.0 * s)
	Deco.stained_glass(p, 314, 124, 92, 150)
	Icons.draw(p, "sun", Vector2(360, 118), 12)
	I.shaft(p, Vector2(318, 200), Vector2(402, 200), Vector2(270, 540), Vector2(520, 540), Color("#e0b070"), 0.15)
	Npc.figure(p, 360, 312, 122, {"body": "female", "top": Color("#bcb49c"), "lower": "robe", "arms": "down", "hair": "hood", "hood_c": Color("#c8c0a6"), "stole": Color("#8a2a22"), "light": 1.0})
	I.box(p, 296, 290, 128, 40, 18, Mat.ashlar(p, Color("#8a8170"), 296, 290, 30, 14), p.flat(Color("#9c9482"), 0.1))
	Bits.altar_cloth(p, 300, 290, 120)
	for cx: float in [306.0, 322.0, 398.0, 414.0]:
		Props.candle(p, cx, 286, 14)
	for s: float in [1.5, 2.1]:
		for side: float in [-1.0, 1.0]:
			var a: Vector2 = I.pt(Vector2(360 + side * 30, 330), s)
			var b: Vector2 = I.pt(Vector2(360 + side * 170, 330), s)
			I.box(p, minf(a.x, b.x), a.y - 22 * s, absf(b.x - a.x), 22 * s, 10 * s, Mat.planks(p, Color("#3a2a1d"), 0, 0, false, int(8 * s)), Mat.planks(p, Color("#4a3624"), 0, 0, false, 6))
	Bits.candle_stand(p, 110, 470)
	Bits.candle_stand(p, 600, 470)
	return [[Vector2(360, 210), 320.0, Color("#e8c890"), 0.55], [Vector2(360, 285), 220.0, WARM, 0.6], [Vector2(110, 380), 200.0, WARM, 0.5], [Vector2(600, 380), 200.0, WARM, 0.45]]


## 상점: 판자 벽 가득 선반(병·단지·상자) · 들보에 매단 약초·자루 · 저울과 장부가 놓인 계산대 · 궤짝.
static func shop(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.planks(p, Color("#3d2c1f"), 0, 0, true, 15), Mat.plaster(p, Color("#6a5f4a"), 0.2), Mat.planks(p, Color("#45311f"), 0, 0, false, 13), Mat.planks(p, Color("#261c14"), 0, 0, false, 18))
	for y: float in [146.0, 206.0, 266.0]:
		Bits.shelf_row(p, 180, y, 360, "jars" if y < 200.0 else ("boxes" if y > 250.0 else "bottles"))
	Ink.line(p, I.pt(Vector2(170, 112), 1.5), I.pt(Vector2(550, 112), 1.5), 12.0, Color("#22180f"), 1.0, 0.4)
	for k in 9:
		var hx := 140.0 + k * 52.0
		Bits.hanging(p, Vector2(hx, 64), 40.0 + (k % 3) * 18.0, k % 3)
	Npc.figure(p, 342, 452, 192, {"body": "stout", "top": Color("#9a8a68"), "bottom": Color("#4a3a2a"), "apron": Color("#6a4a32"), "arms": "counter", "hands_v": 0.5, "hair": "bald", "hair_c": Color("#3a2a1e"), "beard": "mustache", "light": 1.0})
	I.box(p, 110, 380, 470, 100, 42, Mat.planks(p, Color("#4a3524"), 110, 380, true, 16), Mat.planks(p, Color("#5d432b"), 0, 0, false, 10))
	Bits.scale(p, Vector2(250, 372))
	Bits.open_book(p, Vector2(420, 368), 34)
	Props.candle(p, 500, 372, 20)
	Bits.coins(p, Vector2(330, 372))
	Props.crate(p, 660, 520, 70)
	Props.crate(p, 720, 450, 56)
	Props.sack(p, 60, 530, 70)
	Parts.lantern(p, 90, 170, 1.4)
	return [[Vector2(90, 190), 260.0, WARM, 0.6], [Vector2(500, 350), 280.0, WARM, 0.65], [Vector2(330, 220), 260.0, WARM, 0.3]]


## 은행: 어두운 다듬은 돌 · 뒷벽의 둥근 금고 문 · 앞을 가로지르는 쇠창살 창구 · 놋쇠 등 · 동전 궤짝 · 기둥.
static func bank(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.ashlar(p, Color("#4b4d48"), 170, 110, 48, 22), Mat.ashlar(p, Color("#41433f"), 0, 0, 56, 26), Bits.checker_shader(p), p.flat(Color("#1c1d1b"), 0.2))
	Bits.vault(p, Vector2(360, 222), 92)
	for s: float in [1.45]:
		for bx: float in [190.0, 530.0]:
			Bits.column(p, I.pt(Vector2(bx, 110), s), I.pt(Vector2(bx, 330), s), 20.0 * s)
	Npc.figure(p, 356, 446, 188, {"body": "female", "top": Color("#34343e"), "lower": "dress", "collar": Color("#d0c8b4"), "arms": "counter", "hands_v": 0.5, "hair": "bun", "hair_c": Color("#5a4636"), "glasses": true, "light": 1.0})
	I.box(p, 40, 372, 660, 120, 30, Mat.planks(p, Color("#2e2219"), 40, 372, true, 22), p.flat(Color("#4a3a2c"), 0.15))
	for k in 23:
		Ink.line(p, Vector2(52 + k * 28.0, 250), Vector2(52 + k * 28.0, 362), 3.0, Color("#1b1a18"), 1.0, 0.2)
	Ink.line(p, Vector2(40, 250), Vector2(700, 250), 6.0, Color("#1b1a18"), 1.0, 0.3)
	Bits.brass_lamp(p, Vector2(560, 360))
	Bits.brass_lamp(p, Vector2(190, 360))
	Bits.coins(p, Vector2(420, 364))
	Bits.open_book(p, Vector2(300, 362), 30)
	I.box(p, 760, 470, 120, 60, 26, Mat.planks(p, Color("#3a2a1c"), 760, 470, false, 12), Mat.planks(p, Color("#4a3624"), 0, 0, false, 8))
	return [[Vector2(560, 340), 280.0, WARM, 0.7], [Vector2(190, 340), 240.0, WARM, 0.55], [Vector2(360, 222), 220.0, COOL, 0.3]]


## 훈련장(실내 훈련실): 거친 돌 뒷벽의 무기걸이·방패 · 깃발 · 모래 바닥 · 허수아비 · 횃불 · 앞쪽 나무 울타리.
static func training(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.rubble(p, Color("#55514a")), Mat.planks(p, Color("#3a2b1f"), 0, 0, true, 18), Bits.sand_shader(p), Mat.planks(p, Color("#241a12"), 0, 0, false, 22))
	for s: float in [1.3, 1.9, 2.8]:
		Ink.line(p, I.pt(Vector2(170, 110), s), I.pt(Vector2(550, 110), s), 9.0 * s, Color("#22180f"), 1.0, 0.5)
	Props.weapon_rack(p, 230, 330)
	Props.weapon_rack(p, 490, 330)
	for sx: float in [300.0, 360.0, 420.0]:
		Bits.shield(p, Vector2(sx, 190), 24)
	Props.banner(p, 360, 300, Color("#6e2420"), 180)
	Props.dummy(p, 250, 470, 1.5)
	Props.dummy(p, 470, 420, 1.15)
	Npc.figure(p, 378, 474, 204, {"body": "male", "top": Color("#6a4a30"), "bottom": Color("#4a4034"), "belt": Color("#2a1e14"), "arms": "crossed", "bare_arms": true, "hair": "short", "hair_c": Color("#241a14"), "beard": "stubble", "scar": true, "skin": Color("#b48462"), "light": -1.0})
	for side: float in [1.0, 0.0]:
		var tx := 70.0 if side > 0.0 else 650.0
		Bits.torch(p, Vector2(tx, 230))
	Props.barrel(p, 640, 520, 60, 76)
	Props.fence(p, 560, 960, 535, 70)
	return [[Vector2(70, 220), 300.0, WARM, 0.75], [Vector2(650, 220), 300.0, WARM, 0.7], [Vector2(360, 400), 320.0, WARM, 0.4]]


static func _I() -> GDScript:
	return load("res://tools/city_art/Interiors.gd")
