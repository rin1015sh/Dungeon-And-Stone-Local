extends RefCounted
## 시설 내부 둘째 묶음(대장간·탐험가 길드, 2026-10-20) — InteriorRooms와 같은 문법: 방을 칠하고 광원 목록을 돌려준다(Interiors.light).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Icons := preload("res://tools/city_art/Icons.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Npc := preload("res://tools/city_art/Npcs.gd")

const WARM := Color("#ffb45c")
const FIRE := Color("#ff7a2a")


## 대장간: 그을린 돌벽 · 뒷벽 가운데 큰 화덕(불)과 굴뚝 갓 · 벽에 걸린 집게·망치·편자 · 앞의 모루 · 물통 · 풀무 · 대장장이.
static func smithy(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.rubble(p, Color("#4a453e")), Mat.rubble(p, Color("#3e3a34")), Mat.ashlar(p, Color("#3a3631"), 0, 330, 70, 30), Mat.planks(p, Color("#1d1611"), 0, 0, false, 22))
	for s: float in [1.3, 1.9, 2.8]:
		Ink.line(p, I.pt(Vector2(170, 110), s), I.pt(Vector2(550, 110), s), 9.0 * s, Color("#1c140e"), 1.0, 0.5)
	var hood := Paint.poly([Vector2(268, 112), Vector2(452, 112), Vector2(486, 196), Vector2(234, 196)])
	p.fill_poly(hood, Mat.brick(p, Color("#3e322a"), 0, 0, 20, 9))
	Ink.path(p, hood, 2.4)
	Bits.hearth(p, 262, 196, 196, 134)
	for k in 5:  # 벽에 걸린 연장
		var tx := 192.0 + k * 14.0
		Ink.line(p, Vector2(tx, 150), Vector2(tx + 2, 214 - (k % 2) * 16), 3.0, Color("#77736c"), 1.0, 0.2)
	for k in 4:
		var hx := 486.0 + k * 16.0
		var shoe := PackedVector2Array()
		for i in 10:
			shoe.append(Vector2(hx, 170 + k % 2 * 18) + Vector2.from_angle(PI + PI * i / 9.0) * 7.0)
		Ink.path(p, shoe, 2.4, false, Color("#6a6660"), 1.0, 0.1)
	_bellows(p, 150, 330)
	Npc.figure(p, 548, 470, 196, {"body": "stout", "top": Color("#5a4a3a"), "bottom": Color("#3a3028"), "apron": Color("#3c2a1c"), "belt": Color("#2a1e14"),
		"arms": "crossed", "bare_arms": true, "hair": "bald", "hair_c": Color("#2a1e14"), "beard": "full", "skin": Color("#a87656"), "light": -1.0})
	var stump := Paint.rect_poly(300, 452, 92, 70)
	p.fill_poly(stump, Mat.planks(p, Color("#3e2c1d"), 300, 452, true, 16))
	Ink.shade(p, stump, Vector2(300, 0), Vector2(392, 0), 0.0, 0.5)
	Ink.path(p, stump, 2.2)
	Icons.draw(p, "anvil", Vector2(346, 432), 64)
	Props.barrel(p, 120, 528, 78, 70)
	Ink.line(p, Vector2(90, 466), Vector2(150, 466), 3.0, Color("#6a8a8a"), 0.6, 0.3)
	Props.crate(p, 700, 522, 64)
	Bits.torch(p, Vector2(70, 200))
	return [[Vector2(360, 290), 380.0, FIRE, 1.0], [Vector2(346, 420), 240.0, FIRE, 0.45], [Vector2(70, 190), 220.0, WARM, 0.5]]


## 탐험가 길드: 목조 회관 · 뒷벽 가득 의뢰 쪽지 게시판 · 양쪽 깃발 · 들보의 샹들리에 · 접수대(장부·종) · 접수원 · 앞쪽 긴 의자와 술잔.
static func guild(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.planks(p, Color("#3e2d20"), 0, 0, true, 16), Mat.plaster(p, Color("#6e624a"), 0.15), Mat.planks(p, Color("#45311f"), 0, 0, false, 14), Mat.planks(p, Color("#261c14"), 0, 0, false, 18))
	for s: float in [1.25, 1.7, 2.3, 3.2]:
		Ink.line(p, I.pt(Vector2(170, 110), s), I.pt(Vector2(550, 110), s), 9.0 * s, Color("#22180f"), 1.0, 0.5)
	var board := Paint.rect_poly(214, 132, 292, 150)
	p.fill_poly(board, Mat.planks(p, Color("#4a3624"), 214, 132, false, 12))
	Ink.path(p, board, 2.4)
	for i in 22:
		var nx := 222.0 + (i % 8) * 35.0 + p.rng.randf_range(-4, 4)
		var ny := 140.0 + (i / 8) * 46.0 + p.rng.randf_range(-4, 6)
		var note := Paint.rect_poly(nx, ny, 26, 34)
		p.fill_poly(note, p.flat(Color("#cfc4a6").darkened(p.rng.randf_range(0.05, 0.4)), 0.2))
		Ink.path(p, note, 1.2)
		for k in 4:
			Ink.line(p, Vector2(nx + 4, ny + 8 + k * 6), Vector2(nx + 22 - (k % 2) * 6, ny + 8 + k * 6), 0.9, Ink.INK, 0.5, 0.2)
		p.fill_rect(nx + 11, ny + 1, 4, 4, p.flat(Color("#7d2620"), 0.1))
	Icons.draw(p, "crest", Vector2(360, 120), 16)
	Props.banner(p, 186, 320, Color("#2c3444"), 200)
	Props.banner(p, 512, 320, Color("#6e2420"), 200)
	Bits.chandelier(p, Vector2(360, 96), 80)
	Npc.figure(p, 300, 446, 186, {"body": "female", "top": Color("#4a3a2c"), "lower": "dress", "collar": Color("#cfc4a6"), "arms": "counter", "hands_v": 0.5,
		"hair": "bun", "hair_c": Color("#3a2a1e"), "light": 1.0})
	I.box(p, 120, 378, 400, 104, 40, Mat.planks(p, Color("#4a3524"), 120, 378, true, 16), Mat.planks(p, Color("#5d432b"), 0, 0, false, 10))
	Bits.open_book(p, Vector2(420, 368), 34)
	Props.candle(p, 480, 372, 20)
	Bits.coins(p, Vector2(220, 372))
	I.box(p, 600, 470, 340, 30, 22, Mat.planks(p, Color("#3e2c1d"), 0, 0, false, 10), Mat.planks(p, Color("#4b3524"), 0, 0, false, 8))
	for mx: float in [650.0, 760.0, 880.0]:
		Bits.mug(p, mx, 464)
	Props.weapon_rack(p, 70, 520)
	Parts.lantern(p, 860, 170, 1.4)
	return [[Vector2(480, 350), 300.0, WARM, 0.7], [Vector2(360, 140), 320.0, WARM, 0.5], [Vector2(860, 190), 260.0, WARM, 0.55]]


## 풀무(가죽 주머니 + 손잡이).
static func _bellows(p: Paint, cx: float, y: float) -> void:
	var bag := Paint.poly([Vector2(cx - 50, y), Vector2(cx + 30, y - 22), Vector2(cx + 64, y - 6), Vector2(cx + 30, y + 26)])
	p.fill_poly(bag, p.flat(Color("#5a3a26"), 0.25))
	Ink.shade(p, bag, Vector2(0, y - 22), Vector2(0, y + 26), 0.0, 0.5)
	Ink.path(p, bag, 2.0)
	Ink.line(p, Vector2(cx + 64, y - 6), Vector2(cx + 110, y - 14), 5.0, Color("#2e2118"), 1.0, 0.2)
	Ink.line(p, Vector2(cx - 50, y), Vector2(cx - 90, y - 20), 4.0, Color("#2e2118"), 1.0, 0.2)


static func _I() -> GDScript:
	return load("res://tools/city_art/Interiors.gd")
