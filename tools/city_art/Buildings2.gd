extends RefCounted
## 시설 건물 그림 둘째 묶음(상점·은행·훈련장)과 장식(장미창·시계·종·색유리·버팀벽). tools/paint_city.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Icons := preload("res://tools/city_art/Icons.gd")

const SLATE := Color("#3a4044")
const CLAY := Color("#6b3b2d")
const SHOP_PLASTER := Color("#8c7a55")
const BANK_STONE := Color("#575a54")


## 상점: 좁고 높은 상인 집 — 계단식 박공(돌 갓돌) · 꼭대기 도르래 들보 · 1층 넓은 진열창(물건) · 줄무늬 차양 · 자루 간판.
static func shop(p: Paint) -> void:
	var g := float(p.h)
	var pts: Array = [Vector2(28, g), Vector2(28, 150)]
	var steps := [[28.0, 128.0], [64.0, 100.0], [100.0, 72.0], [136.0, 44.0], [168.0, 20.0]]
	for i in steps.size():
		var sx: float = steps[i][0]
		var sy: float = steps[i][1]
		var prev_y: float = 150.0 if i == 0 else steps[i - 1][1]
		pts.append(Vector2(sx, prev_y))
		pts.append(Vector2(sx, sy))
	var mirrored: Array = []
	for i in range(pts.size() - 1, 0, -1):
		var v: Vector2 = pts[i]
		mirrored.append(Vector2(400.0 - v.x, v.y))
	var body := Paint.poly(pts + mirrored)
	Parts.wall(p, body, Mat.plaster(p, SHOP_PLASTER, 0.12), 0.15)
	for st: Array in steps:
		for sgn: float in [1.0, -1.0]:
			var sx: float = st[0] if sgn > 0.0 else 400.0 - st[0] - 38.0
			var cap := Paint.rect_poly(sx - 4, st[1] - 7, 42, 8)
			p.fill_poly(cap, p.flat(Color("#6f685b"), 0.2))
			Ink.path(p, cap, 1.6)
	Parts.window(p, 186, 46, 28, 34, "arch", false)
	Ink.line(p, Vector2(200, 92), Vector2(200, 112), 6.0, Color("#2a1e15"), 1.0, 0.1)
	Ink.line(p, Vector2(200, 100), Vector2(232, 100), 6.0, Color("#2a1e15"), 1.0, 0.1)
	Ink.line(p, Vector2(228, 104), Vector2(228, 190), 1.4, Color("#8a7a5a"), 0.9, 0.6)
	Parts.ledge(p, 22, 246, 356, 7)
	for wx: float in [62.0, 175.0, 288.0]:
		Parts.window(p, wx, 166, 50, 62, "square", wx == 175.0, true)
		Parts.window(p, wx, 266, 50, 58, "square", wx == 62.0, false)
	Parts.ledge(p, 22, 340, 356, 9, Color("#4e3a29"))
	var front := Paint.rect_poly(36, 349, 328, g - 371)
	p.fill_poly(front, Mat.planks(p, Color("#3b2c20"), 36, 349, true, 14))
	Ink.path(p, front, Parts.LINE)
	var disp := Paint.rect_poly(54, 386, 196, 80)
	p.fill_poly(disp, Mat.glass(p, 386, 466, true))
	for i in 7:
		var gx := 64.0 + i * 26.0
		var jar := Paint.poly([Vector2(gx, 462), Vector2(gx + 16, 462), Vector2(gx + 16, 440 - (i % 3) * 8), Vector2(gx + 8, 432 - (i % 3) * 8), Vector2(gx, 440 - (i % 3) * 8)])
		p.fill_poly(jar, p.flat([Color("#3d2a1c"), Color("#4a5a3c"), Color("#6e2a22")][i % 3], 0.2))
		Ink.path(p, jar, 1.2)
	Ink.line(p, Vector2(54, 426), Vector2(250, 426), 3.0, Color("#2a1e15"), 1.0, 0.2)
	for i in 4:
		Ink.line(p, Vector2(54 + i * 65.0, 386), Vector2(54 + i * 65.0, 466), 2.6, Color("#1d1713"), 1.0, 0.2)
	Ink.path(p, disp, Parts.LINE)
	Ink.glow(p, 152, 430, 140, Parts.GLOW, 0.22)
	Parts.door(p, 272, 382, 68, g - 404, false, Color("#33261b"), true)
	var aw: Array = [Vector2(30, 350), Vector2(370, 350), Vector2(384, 384)]
	for i in 12:
		var t := float(12 - i) / 12.0
		aw.append(Vector2(16 + 368 * t, 384 + (6 if i % 2 == 0 else 0)))
	aw.append(Vector2(16, 384))
	var awning := Paint.poly(aw)
	p.fill_poly(awning, func(x: int, y: int) -> Color:
		return p.vary(Color("#7a2c24") if (x / 28) % 2 == 0 else Color("#a89a78"), x, y, 0.2))
	Ink.shade(p, awning, Vector2(0, 350), Vector2(0, 390), 0.0, 0.45)
	Ink.path(p, awning, Parts.LINE)
	Ink.shade(p, Paint.rect_poly(36, 390, 328, 30), Vector2(0, 390), Vector2(0, 420), 0.45, 0.0)
	Parts.plinth(p, 28, g - 22, 344, 22)
	Parts.sign(p, 117, 254, "bag", 1.0, 36)
	Props.crate(p, 46, g, 36)
	Props.crate(p, 82, g, 30)
	Props.crate(p, 62, g - 34, 28)
	Props.sack(p, 252, g, 32)
	Props.sack(p, 356, g, 30)


## 은행: 거친 다듬은 돌 · 좌우 대칭 · 박공 머리(열쇠 문장) · 기둥 둘 사이 깊은 아치 문(쇠 격자) · 쇠창살 창 · 돌 난간과 항아리.
static func bank(p: Paint) -> void:
	var g := float(p.h)
	var body := Paint.rect_poly(20, 126, 430, g - 126)
	Parts.wall(p, body, Mat.ashlar(p, BANK_STONE, 20, 126, 60, 26), 0.12)
	var ped := Paint.poly([Vector2(120, 122), Vector2(235, 38), Vector2(350, 122)])
	Parts.wall(p, ped, Mat.ashlar(p, BANK_STONE.lightened(0.06), 120, 38, 40, 18), 0.1)
	Ink.path(p, Paint.poly([Vector2(108, 126), Vector2(235, 28), Vector2(362, 126)]), 6.0, false, Color("#4c4e49"), 1.0, 0.3)
	Icons.draw(p, "key", Vector2(235, 92), 26)
	Parts.ledge(p, 10, 118, 450, 12, Color("#787a72"))
	for ux: float in [34.0, 418.0]:
		var urn := Paint.poly([Vector2(ux - 12, 118), Vector2(ux + 12, 118), Vector2(ux + 16, 96), Vector2(ux + 8, 84), Vector2(ux - 8, 84), Vector2(ux - 16, 96)])
		p.fill_poly(urn, p.flat(Color("#6e7069"), 0.2))
		Ink.path(p, urn, 1.8)
	for wx: float in [50.0, 376.0]:
		Parts.window(p, wx, 160, 44, 58, "square", false)
		Parts.window(p, wx, 284, 44, 84, "arch", wx < 100.0)
		for k in 4:
			Ink.line(p, Vector2(wx + 6 + k * 11.0, 286), Vector2(wx + 6 + k * 11.0, 368), 3.0, Parts.BAR, 1.0, 0.1)
	_round_window(p, Vector2(235, 176), 22)
	Parts.ledge(p, 14, 236, 442, 8)
	Parts.door(p, 186, 262, 98, g - 290, true, Color("#2f2419"), false)
	for k in 6:
		Ink.line(p, Vector2(192 + k * 17.0, 272), Vector2(192 + k * 17.0, g - 30), 3.4, Parts.BAR, 1.0, 0.1)
	for k in 3:
		Ink.line(p, Vector2(188, 300 + k * 44.0), Vector2(282, 300 + k * 44.0), 3.0, Parts.BAR, 1.0, 0.1)
	for cx: float in [146.0, 298.0]:
		_column(p, cx, 246, 26, g - 274)
	Parts.steps(p, 235, g, 150, 3, 6)
	Parts.plinth(p, 20, g - 24, 430, 24)
	Parts.lantern(p, 132, 254)
	Parts.lantern(p, 338, 254)


static func rose_window(p: Paint, c: Vector2, r: float, lit: bool) -> void:
	var ring := _circle(c, r + 6)
	p.fill_poly(ring, p.flat(Parts.FRAME, 0.2))
	Ink.path(p, ring, Parts.LINE)
	var inner := _circle(c, r)
	var cols := [Color("#6e2a24"), Color("#2f4560"), Color("#8a6a2c"), Color("#3c5634")]
	p.fill_poly(inner, func(x: int, y: int) -> Color:
		var a := (Vector2(x, y) - c).angle()
		var k := int(floor((a + PI) / TAU * 12.0)) % 4
		var col: Color = cols[k].darkened(0.0 if lit else 0.35).lerp(Color("#3a3328"), 0.35)
		return p.vary(col, x, y, 0.25))
	for i in 8:
		var a := TAU * i / 8.0
		Ink.line(p, c, c + Vector2.from_angle(a) * r, 2.2, Parts.BAR, 1.0, 0.1)
	Ink.path(p, _circle(c, r * 0.45), 2.0, true, Parts.BAR)
	Ink.path(p, inner, 2.0)


static func clock(p: Paint, c: Vector2, r: float) -> void:
	var face := _circle(c, r)
	p.fill_poly(face, p.flat(Color("#bdb293"), 0.15))
	Ink.path(p, _circle(c, r + 4), 5.0, true, Color("#4b463c"), 1.0, 0.2)
	for i in 12:
		var a := TAU * i / 12.0
		Ink.line(p, c + Vector2.from_angle(a) * r * 0.75, c + Vector2.from_angle(a) * r * 0.92, 1.6, Ink.INK, 1.0, 0.1)
	Ink.line(p, c, c + Vector2.from_angle(-PI * 0.6) * r * 0.55, 2.6, Ink.INK, 1.0, 0.1)
	Ink.line(p, c, c + Vector2.from_angle(-PI * 0.05) * r * 0.8, 1.8, Ink.INK, 1.0, 0.1)


static func bell(p: Paint, c: Vector2) -> void:
	var b := Paint.poly([Vector2(c.x - 8, c.y - 18), Vector2(c.x + 8, c.y - 18), Vector2(c.x + 12, c.y), Vector2(c.x + 18, c.y + 12), Vector2(c.x - 18, c.y + 12), Vector2(c.x - 12, c.y)])
	p.fill_poly(b, p.flat(Color("#7c6638"), 0.2))
	Ink.shade(p, b, Vector2(c.x - 18, 0), Vector2(c.x + 18, 0), 0.0, 0.5)
	Ink.path(p, b, 2.0)


## 색유리 창(고딕): 납선 격자 + 탁한 보석색 + 안쪽 불빛.
static func stained_glass(p: Paint, x: float, y: float, sw: float, sh: float) -> void:
	var outer := Paint.arch_poly(x - 8, y - 8, sw + 16, sh + 16, true)
	p.fill_poly(outer, p.flat(Parts.FRAME, 0.2))
	Ink.path(p, outer, Parts.LINE)
	var inner := Paint.arch_poly(x, y, sw, sh, true)
	var cols := [Color("#7a2a22"), Color("#2c4a6e"), Color("#a07a30"), Color("#3e6038"), Color("#5a3060")]
	p.fill_poly(inner, func(x2: int, y2: int) -> Color:
		var k := int(Paint.hash01(int((x2 - x) / 11.0 + p.nz("mid", x2, y2) * 2.5), int((y2 - y) / 15.0 + p.nz("lo", x2, y2) * 3.0)) * cols.size())
		return p.vary(cols[k].darkened(0.3).lerp(Color("#3a3328"), 0.3), x2, y2, 0.3))
	var yy := y + 16.0
	while yy < y + sh:
		Ink.line(p, Vector2(x, yy), Vector2(x + sw, yy), 1.6, Parts.BAR, 1.0, 0.4)
		yy += 18.0
	var xx := x + 14.0
	while xx < x + sw:
		Ink.line(p, Vector2(xx, y + 10), Vector2(xx, y + sh), 1.6, Parts.BAR, 1.0, 0.4)
		xx += 14.0
	Ink.line(p, Vector2(x + sw / 2.0, y), Vector2(x + sw / 2.0, y + sh), 4.0, Parts.FRAME, 1.0, 0.2)
	Ink.path(p, inner, 2.0)
	Ink.glow(p, x + sw / 2.0, y + sh * 0.6, sw * 1.3, Color("#e0a050"), 0.16)


static func buttress(p: Paint, x: float, y: float, bw: float, bh: float) -> void:
	var poly := Paint.poly([Vector2(x, y + bh), Vector2(x, y + 20), Vector2(x + bw * 0.3, y), Vector2(x + bw, y), Vector2(x + bw, y + bh)])
	p.fill_poly(poly, Mat.ashlar(p, Color("#8c836f"), int(x), int(y), 24, 16))
	Ink.shade(p, poly, Vector2(x, 0), Vector2(x + bw, 0), 0.0, 0.45)
	Ink.path(p, poly, Parts.LINE)


static func _column(p: Paint, cx: float, y: float, cw: float, ch: float) -> void:
	var shaft := Paint.rect_poly(cx - cw / 2.0, y + 12, cw, ch - 24)
	p.fill_poly(shaft, func(x: int, y2: int) -> Color:
		var t := (x - (cx - cw / 2.0)) / cw
		return p.vary(Color("#7d7f78").darkened(0.45 * t * t).lightened(0.12 * (1.0 - t)), x, y2, 0.12))
	for k in 3:
		Ink.line(p, Vector2(cx - cw / 2.0 + cw * (k + 1) / 4.0, y + 14), Vector2(cx - cw / 2.0 + cw * (k + 1) / 4.0, y + ch - 14), 1.0, Ink.INK, 0.4, 0.3)
	Ink.path(p, shaft, 2.0)
	for yy: float in [y, y + ch - 12]:
		var cap := Paint.rect_poly(cx - cw / 2.0 - 6, yy, cw + 12, 12)
		p.fill_poly(cap, p.flat(Color("#82847c"), 0.2))
		Ink.path(p, cap, 1.8)


static func _round_window(p: Paint, c: Vector2, r: float) -> void:
	var ring := _circle(c, r + 5)
	p.fill_poly(ring, p.flat(Parts.FRAME, 0.2))
	p.fill_poly(_circle(c, r), Mat.glass(p, c.y - r, c.y + r, false))
	Ink.line(p, c - Vector2(r, 0), c + Vector2(r, 0), 2.0, Parts.BAR)
	Ink.line(p, c - Vector2(0, r), c + Vector2(0, r), 2.0, Parts.BAR)
	Ink.path(p, ring, Parts.LINE)


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 28:
		out.append(c + Vector2.from_angle(TAU * i / 28.0) * r)
	return out
