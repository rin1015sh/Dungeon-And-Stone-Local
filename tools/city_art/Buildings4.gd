extends RefCounted
## 시설 건물 그림 넷째 묶음: 알미너스 중앙 거래소(2026-10-27, CT54 — 컴멜비 5구역부터 선다). tools/paint_city.gd 전용.
## 좌우 대칭의 큰 석조 회관: 가운데 원통 받침 위 청동 돔(금빛 갈비·꼭대기 등롱) · 앞 여섯 기둥 현관과 큰 박공(금빛 저울 문장) ·
## 금띠 두른 처마 · 난간동자 옥상 난간과 모서리 석상 · 좌우 날개의 높은 아치 창 2층 · 현관 안 문 셋 · 넓은 돌계단 · 양옆 깃발.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Deco := preload("res://tools/city_art/Buildings2.gd")

const STONE := Color("#8a8170")
const COPPER := Color("#4f7c74")
const GOLD := Color("#c9a24a")


static func exchange(p: Paint) -> void:
	var g := float(p.h)
	var cx := p.w / 2.0
	_dome(p, cx)
	var body := Paint.rect_poly(18, 236, p.w - 36, g - 236)
	Parts.wall(p, body, Mat.ashlar(p, STONE, 18, 236, 54, 22), 0.1)
	_balustrade(p, 14, 214, p.w - 28)
	Parts.ledge(p, 10, 232, p.w - 20, 12, STONE.lightened(0.1))
	Ink.line(p, Vector2(14, 246), Vector2(p.w - 14, 246), 2.4, GOLD, 0.95, 0.1)
	for side: float in [0.0, 1.0]:  # 좌우 날개: 아치 창 두 층
		for k in 2:
			var wx := (44.0 + k * 62.0) if side == 0.0 else (p.w - 44.0 - 36.0 - k * 62.0)
			Parts.window(p, wx, 278, 36, 92, "arch", k == 0)
			Parts.window(p, wx, 420, 36, 84, "arch", k == 1)
		var sx := 30.0 if side == 0.0 else p.w - 30.0
		_statue(p, sx, 214)
	Parts.ledge(p, 14, 396, p.w - 28, 8)
	var inner := Paint.rect_poly(156, 316, p.w - 312, g - 340)  # 현관 안쪽 벽(그늘)
	p.fill_poly(inner, Mat.ashlar(p, STONE.darkened(0.25), 156, 316, 40, 18))
	Ink.shade(p, inner, Vector2(0, 316), Vector2(0, 360), 0.6, 0.15)
	Parts.door(p, cx - 42, 400, 84, g - 430, true, Color("#3a2618"), true)
	for dx: float in [-112.0, 112.0]:
		Parts.door(p, cx + dx - 26, 436, 52, g - 466, true, Color("#3a2618"), false)
	for k in 6:  # 여섯 기둥
		Deco._column(p, 166.0 + k * (p.w - 332.0) / 5.0, 310, 26, g - 340)
	var beam := Paint.rect_poly(140, 290, p.w - 280, 22)
	p.fill_poly(beam, p.flat(STONE.lightened(0.12), 0.1))
	Ink.path(p, beam, Parts.LINE)
	for k in 9:
		Ink.glow(p, 170.0 + k * (p.w - 340.0) / 8.0, 301, 3.5, GOLD, 0.9, false)
	var ped := Paint.poly([Vector2(128, 292), Vector2(cx, 196), Vector2(p.w - 128, 292)])
	p.fill_poly(ped, Mat.ashlar(p, STONE.lightened(0.08), 0, 196, 40, 18))
	Ink.shade(p, ped, Vector2(0, 196), Vector2(0, 292), 0.0, 0.3)
	Ink.path(p, ped, 3.0)
	var tympan := Paint.poly([Vector2(160, 286), Vector2(cx, 210), Vector2(p.w - 160, 286)])
	Ink.path(p, tympan, 2.0, true, GOLD.darkened(0.15), 0.9, 0.1)
	_scale_crest(p, Vector2(cx, 270))
	Parts.steps(p, cx, g, p.w - 300, 4, 7)
	Parts.plinth(p, 18, g - 20, p.w - 36, 20)
	for bx: float in [128.0, p.w - 128.0]:
		Props.banner(p, bx, 300, Color("#23345a"), 120)
	Parts.lantern(p, 150, 330)
	Parts.lantern(p, p.w - 150, 330)


## 원통 받침(작은 둥근 창) + 청동 돔(금빛 갈비) + 꼭대기 등롱과 금구슬.
static func _dome(p: Paint, cx: float) -> void:
	var drum := Paint.rect_poly(cx - 92, 128, 184, 90)
	Parts.wall(p, drum, Mat.ashlar(p, STONE.lightened(0.05), int(cx - 92), 128, 30, 15), 0.15)
	for k in 5:
		var wx := cx - 72 + k * 36.0
		Parts.window(p, wx - 7, 150, 14, 34, "arch", k == 2)
	Parts.ledge(p, cx - 100, 122, 200, 8, STONE.lightened(0.12))
	var dome := PackedVector2Array()
	for i in 25:
		var a := PI + PI * i / 24.0
		dome.append(Vector2(cx + cos(a) * 98.0, 122 + sin(a) * 86.0))
	p.fill_poly(dome, func(x: int, y: int) -> Color:
		var t := (x - (cx - 98.0)) / 196.0
		var c := COPPER.lightened(0.22 * (1.0 - t)).darkened(0.4 * t * t)
		if p.nz("vs", x, y) > 0.7:
			c = c.lightened(0.08)  # 녹청 얼룩
		return p.vary(c, x, y, 0.12))
	for k in 7:  # 금빛 갈비(경선)
		var phi := -PI / 2.0 + PI * (k + 1) / 8.0
		var pts := PackedVector2Array()
		for i in 13:
			var lat := PI / 2.0 * i / 12.0
			pts.append(Vector2(cx + 98.0 * sin(phi) * cos(lat), 122.0 - 86.0 * sin(lat)))
		Ink.path(p, pts, 1.8, false, GOLD, 0.85, 0.1)
	Ink.shade(p, dome, Vector2(cx - 98, 0), Vector2(cx + 98, 0), 0.0, 0.3)
	Ink.path(p, dome, Parts.LINE)
	var lantern := Paint.rect_poly(cx - 14, 18, 28, 22)
	p.fill_poly(lantern, p.flat(STONE.lightened(0.1), 0.1))
	Ink.path(p, lantern, 1.8)
	var cap := Paint.poly([Vector2(cx - 18, 20), Vector2(cx, 4), Vector2(cx + 18, 20)])
	p.fill_poly(cap, p.flat(COPPER, 0.1))
	Ink.path(p, cap, 1.8)
	Ink.line(p, Vector2(cx - 12, 30), Vector2(cx + 12, 30), 2.0, GOLD, 0.9, 0.1)
	Ink.glow(p, cx, 3, 5.0, GOLD, 1.0, false)
	Ink.glow(p, cx, 30, 18.0, Color("#ffd08a"), 0.4)


## 옥상 난간(난간동자 줄).
static func _balustrade(p: Paint, x: float, y: float, bw: float) -> void:
	var rail := Paint.rect_poly(x, y, bw, 6)
	p.fill_poly(rail, p.flat(STONE.lightened(0.1), 0.1))
	Ink.path(p, rail, 1.6)
	var bx := x + 6.0
	while bx < x + bw - 10.0:
		var bal := Paint.poly([Vector2(bx, y + 18), Vector2(bx + 9, y + 18), Vector2(bx + 7, y + 13), Vector2(bx + 9, y + 9), Vector2(bx + 7, y + 6),
			Vector2(bx + 2, y + 6), Vector2(bx, y + 9), Vector2(bx + 2, y + 13)])
		p.fill_poly(bal, p.flat(STONE.lightened(0.06), 0.1))
		Ink.path(p, bal, 1.0)
		bx += 14.0


## 모서리 석상: 받침 + 서 있는 사람 윤곽.
static func _statue(p: Paint, cx: float, y: float) -> void:
	var base := Paint.rect_poly(cx - 12, y - 14, 24, 14)
	p.fill_poly(base, p.flat(STONE.lightened(0.08), 0.1))
	Ink.path(p, base, 1.6)
	var body := Paint.poly([Vector2(cx - 9, y - 14), Vector2(cx + 9, y - 14), Vector2(cx + 6, y - 48), Vector2(cx - 6, y - 48)])
	p.fill_poly(body, p.flat(STONE.lightened(0.12), 0.08))
	Ink.path(p, body, 1.4)
	var head := PackedVector2Array()
	for a in 10:
		head.append(Vector2(cx, y - 55) + Vector2.from_angle(TAU * a / 10.0) * 6.0)
	p.fill_poly(head, p.flat(STONE.lightened(0.12), 0.08))
	Ink.path(p, head, 1.2)


## 박공 문장: 금빛 저울(기둥 + 들보 + 접시 둘).
static func _scale_crest(p: Paint, c: Vector2) -> void:
	Ink.line(p, c, c + Vector2(0, -42), 3.4, GOLD, 1.0, 0.1)
	Ink.line(p, c + Vector2(-34, -38), c + Vector2(34, -38), 3.0, GOLD, 1.0, 0.1)
	for sgn: float in [-1.0, 1.0]:
		var top := c + Vector2(sgn * 34, -38)
		Ink.line(p, top, top + Vector2(-9, 20), 1.2, GOLD, 0.9)
		Ink.line(p, top, top + Vector2(9, 20), 1.2, GOLD, 0.9)
		var pan := Paint.poly([top + Vector2(-13, 20), top + Vector2(13, 20), top + Vector2(8, 26), top + Vector2(-8, 26)])
		p.fill_poly(pan, p.flat(GOLD, 0.1))
		Ink.path(p, pan, 1.2)
	Ink.line(p, c + Vector2(-16, 2), c + Vector2(16, 2), 4.0, GOLD, 1.0, 0.1)
	Ink.glow(p, c.x, c.y - 42, 5.0, GOLD, 1.0, false)
