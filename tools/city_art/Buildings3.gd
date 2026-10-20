extends RefCounted
## 시설 건물 그림 셋째 묶음(대장간·모험가 길드, 2026-10-20). tools/paint_city.gd 전용 — 통일 문법(Parts)은 다른 건물과 같다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Icons := preload("res://tools/city_art/Icons.gd")

const SLATE := Color("#3a4044")
const CLAY := Color("#6b3b2d")
const SOOT := Color("#4a4640")
const FIRE := Color("#ff8a30")


## 대장간: 낮은 돌 작업장 + 크고 검게 그을린 굴뚝(연기) · 앞이 트인 처마 아래 화덕 불빛 · 바깥 모루·물통·연장걸이 · 모루 간판.
static func smithy(p: Paint) -> void:
	var g := float(p.h)
	Parts.chimney(p, 70, 30, 64, 150)
	var house := Paint.rect_poly(18, 170, 250, g - 170)
	Parts.roof(p, Paint.poly([Vector2(6, 176), Vector2(60, 96), Vector2(232, 96), Vector2(286, 176)]), Mat.slate(p, SLATE.darkened(0.1), 0, 96, 16, 10, 0.2))
	Parts.wall(p, house, Mat.rubble(p, SOOT), 0.2)
	Parts.window(p, 60, 206, 44, 52, "square", true, true)
	Parts.window(p, 176, 206, 44, 52, "square", false, true)
	Parts.ledge(p, 10, 292, 266, 8)
	Parts.door(p, 104, 318, 68, g - 340, false, Color("#33261b"), true)
	Parts.plinth(p, 18, g - 22, 250, 22)
	# 앞이 트인 작업장: 기둥 둘 + 기울어진 처마(점토 기와) — 안쪽은 어둡고 화덕만 붉다
	var shed_back := Paint.rect_poly(268, 210, 236, g - 210)
	p.fill_poly(shed_back, func(x: int, y: int) -> Color:
		var t := clampf((y - 210.0) / (g - 210.0), 0.0, 1.0)
		return p.vary(Color("#15110d").lerp(Color("#2e241a"), t), x, y, 0.2))
	var forge := Paint.rect_poly(330, g - 120, 110, 98)
	p.fill_poly(forge, Mat.rubble(p, Color("#5b5249")))
	Ink.path(p, forge, Parts.LINE)
	var mouth := Paint.arch_poly(356, g - 96, 58, 44)
	p.fill_poly(mouth, func(x: int, y: int) -> Color:
		var t := clampf((y - (g - 96.0)) / 44.0, 0.0, 1.0)
		return p.vary(Color("#ffcf6a").lerp(Color("#d2461a"), t), x, y, 0.15))
	Ink.path(p, mouth, 2.0)
	var hood := Paint.poly([Vector2(320, g - 122), Vector2(450, g - 122), Vector2(410, g - 176), Vector2(360, g - 176)])
	p.fill_poly(hood, Mat.brick(p, Color("#4a3a30"), 0, 0, 18, 8))
	Ink.path(p, hood, Parts.LINE)
	Ink.line(p, Vector2(385, g - 176), Vector2(385, 210), 22.0, Color("#2a2622"), 1.0, 0.3)
	Ink.glow(p, 385, g - 76, 150, FIRE, 0.55)
	for tx: float in [290.0, 304.0, 470.0, 484.0]:  # 뒷벽에 걸린 집게·망치 실루엣
		Ink.line(p, Vector2(tx, 236), Vector2(tx + 3, 300), 3.0, Color("#6e6a64"), 0.9, 0.2)
	for px: float in [268.0, 494.0]:
		var post := Paint.rect_poly(px, 196, 12, g - 196)
		p.fill_poly(post, Mat.beam(p))
		Ink.path(p, post, 1.8)
	var eave := Paint.poly([Vector2(258, 214), Vector2(270, 166), Vector2(512, 186), Vector2(516, 222)])
	Parts.roof(p, eave, Mat.clay(p, CLAY.darkened(0.15), 0, 166))
	Ink.shade(p, Paint.rect_poly(280, 222, 214, 40), Vector2(0, 222), Vector2(0, 262), 0.55, 0.0)
	# 바깥: 모루(나무 받침) · 물통 · 연장걸이 · 쇳조각 더미
	var stump := Paint.rect_poly(214, g - 40, 36, 40)
	p.fill_poly(stump, Mat.planks(p, Color("#4a3624"), 214, 0, true, 12))
	Ink.path(p, stump, 1.8)
	Icons.draw(p, "anvil", Vector2(232, g - 54), 26)
	Props.barrel(p, 470, g, 38, 34)
	Ink.line(p, Vector2(456, g - 32), Vector2(484, g - 32), 2.0, Color("#6a8a8a"), 0.6, 0.3)
	Props.weapon_rack(p, 40, g)
	Props.crate(p, 300, g, 30)
	Parts.lantern(p, 96, 312)
	Parts.sign(p, 268, 292, "anvil", 1.0, 44)
	Ink.grime(p, 70, 30, 64, 120, 0.5)


## 모험가 길드: 넓은 2층 회관(돌 1층 + 목조 2층) · 가운데 큰 박공과 둥근 창 · 넓은 쌍여닫이 문과 돌계단 ·
## 양쪽 깃발 · 문 옆 의뢰 게시판(종이 쪽지) · 방패 문장 간판.
static func guild(p: Paint) -> void:
	var g := float(p.h)
	Parts.chimney(p, 470, 40, 34, 90)
	Parts.roof(p, Paint.poly([Vector2(6, 214), Vector2(80, 100), Vector2(500, 100), Vector2(574, 214)]), Mat.slate(p, SLATE, 0, 100, 18, 11, 0.4))
	var gab := Paint.poly([Vector2(196, 214), Vector2(196, 150), Vector2(290, 30), Vector2(384, 150), Vector2(384, 214)])
	Parts.wall(p, gab, Mat.plaster(p, Color("#84795f"), 0.1), 0.15)
	Parts.roof(p, Paint.poly([Vector2(182, 156), Vector2(290, 16), Vector2(398, 156), Vector2(384, 160), Vector2(290, 36), Vector2(196, 160)]), Mat.slate(p, SLATE.lightened(0.05), 0, 0, 12, 8, 0.25))
	_round(p, Vector2(290, 118), 30)
	var up := Paint.rect_poly(22, 210, 536, 140)
	Parts.wall(p, up, Mat.plaster(p, Color("#8b8068"), 0.15), 0.12)
	_timber(p, 22, 210, 536, 140, 8)
	for i in 6:
		var wx := 50.0 + i * 88.0
		Parts.window(p, wx, 238, 40, 58, "square", i == 1 or i == 3 or i == 4, i % 2 == 0)
	Parts.ledge(p, 12, 344, 556, 9, Color("#5a4636"))
	var low := Paint.rect_poly(30, 352, 520, g - 352)
	Parts.wall(p, low, Mat.ashlar(p, Color("#6a655a"), 30, 352, 44, 22), 0.1)
	Ink.shade(p, Paint.rect_poly(30, 354, 520, 30), Vector2(0, 354), Vector2(0, 384), 0.55, 0.0)
	Parts.door(p, 236, 392, 108, g - 414, true, Color("#3a281b"), true)
	Ink.line(p, Vector2(290, 400), Vector2(290, g - 24), 2.0, Ink.INK, 0.9)
	Parts.steps(p, 290, g, 160, 3, 7)
	Parts.window(p, 70, 400, 56, 64, "arch", true)
	Parts.window(p, 454, 400, 56, 64, "arch", false)
	Parts.plinth(p, 30, g - 22, 520, 22)
	Props.banner(p, 172, 390, Color("#2c3444"), 170)
	Props.banner(p, 380, 390, Color("#6e2420"), 170)
	Icons.draw(p, "crest", Vector2(290, 368), 18)
	_board(p, 140, 410)
	Parts.lantern(p, 222, 392)
	Parts.lantern(p, 358, 392)
	Parts.sign(p, 548, 330, "crest", -1.0, 44)
	Props.barrel(p, 520, g, 32, 40)
	Props.sack(p, 46, g, 34)
	Props.crate(p, 84, g, 30)


## 의뢰 게시판(나무 판 + 기둥 둘 + 쪽지 여럿).
static func _board(p: Paint, x: float, y: float) -> void:
	for lx: float in [x - 30.0, x + 30.0]:
		Ink.line(p, Vector2(lx, y), Vector2(lx, y + 128), 5.0, Color("#2e2118"), 1.0, 0.2)
	var board := Paint.rect_poly(x - 40, y, 80, 64)
	p.fill_poly(board, Mat.planks(p, Color("#4a3624"), int(x), int(y), false, 10))
	Ink.path(p, board, 2.0)
	for i in 6:
		var nx := x - 34 + (i % 3) * 24 + p.rng.randf_range(-3, 3)
		var ny := y + 6 + (i / 3) * 28 + p.rng.randf_range(-3, 3)
		var note := Paint.rect_poly(nx, ny, 18, 22)
		p.fill_poly(note, p.flat(Color("#cfc4a6").darkened(p.rng.randf_range(0.0, 0.3)), 0.2))
		Ink.path(p, note, 1.0)
		for k in 3:
			Ink.line(p, Vector2(nx + 3, ny + 6 + k * 5), Vector2(nx + 15, ny + 6 + k * 5), 0.8, Ink.INK, 0.5, 0.2)
		p.fill_rect(nx + 8, ny + 1, 3, 3, p.flat(Color("#7d2620"), 0.1))


## 둥근 창(살 여섯).
static func _round(p: Paint, c: Vector2, r: float) -> void:
	var ring := PackedVector2Array()
	for i in 24:
		ring.append(c + Vector2.from_angle(TAU * i / 24.0) * r)
	p.fill_poly(ring, Mat.glass(p, c.y - r, c.y + r, true))
	for i in 3:
		var a := TAU * i / 6.0
		Ink.line(p, c - Vector2.from_angle(a) * r, c + Vector2.from_angle(a) * r, 2.4, Color("#1d1713"), 1.0, 0.1)
	Ink.path(p, ring, Parts.LINE)
	Ink.glow(p, c.x, c.y, r * 2.4, Parts.GLOW, 0.2)


## 목조 뼈대(기둥·가로대·X 버팀대): n칸 — 여관과 같은 문법.
static func _timber(p: Paint, x: float, y: float, tw: float, th: float, n: int) -> void:
	var beam := Mat.beam(p)
	var bw := 9.0
	for i in n + 1:
		var bx := x + (tw - bw) * i / n
		p.fill_poly(Paint.rect_poly(bx, y, bw, th), beam)
		Ink.path(p, Paint.rect_poly(bx, y, bw, th), 1.4)
	for yy: float in [y, y + th - bw]:
		p.fill_poly(Paint.rect_poly(x, yy, tw, bw), beam)
		Ink.path(p, Paint.rect_poly(x, yy, tw, bw), 1.4)
	for i in n:
		if i % 2 == 1:
			continue
		var bx0 := x + (tw - bw) * i / n + bw
		var bx1 := x + (tw - bw) * (i + 1) / n
		Ink.line(p, Vector2(bx0, y + th - bw), Vector2(bx1, y + bw), 6.0, Color("#2a1e15"), 1.0, 0.3)
