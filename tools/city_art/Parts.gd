extends RefCounted
## 건물 부품(모든 시설이 같은 문법을 쓴다 — 통일감): 벽 · 돌 기단 · 처마 그늘 · 창 · 문 · 지붕 · 굴뚝 · 걸이 간판 · 등.
## 공통 규칙: 잉크 윤곽 굵기 LINE, 창틀은 같은 마름돌 · 같은 짙은 창살, 걸이 간판은 같은 쇠 받침 + 그 시설의 그림.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Icons := preload("res://tools/city_art/Icons.gd")

const LINE := 2.4
const FRAME := Color("#6c6457")
const BAR := Color("#1d1713")
const IRON := Color("#24221f")
const GLOW := Color("#ffb45c")


## 벽 한 면: 재질 + 처마 밑 그늘 + 밑동 습기 + 왼쪽 빛/오른쪽 그늘 + 윤곽.
static func wall(p: Paint, poly: PackedVector2Array, shader: Callable, side_shade: float = 0.0) -> void:
	p.fill_poly(poly, shader)
	var r := Paint.bounds(poly)
	Ink.strokes(p, poly, 1.2, 16.0, 6.0, 78.0, 0.2, 0.35)
	Ink.grime(p, r.position.x, r.position.y, r.size.x, minf(90.0, r.size.y * 0.6), 0.3)
	Ink.shade(p, poly, r.position, r.position + Vector2(0, minf(40.0, r.size.y * 0.25)), 0.5, 0.0)
	Ink.shade(p, poly, Vector2(0, r.end.y - 30.0), Vector2(0, r.end.y), 0.0, 0.35, Color("#1c1a12"))
	var band := Geometry2D.intersect_polygons(poly, Paint.rect_poly(r.position.x, r.position.y, r.size.x, minf(34.0, r.size.y * 0.2)))
	if not band.is_empty():
		Ink.hatch(p, band[0], 5.0, 62.0, 0.22, 1.0)
	if side_shade > 0.0:
		Ink.shade(p, poly, r.position, Vector2(r.end.x, r.position.y), 0.0, side_shade)
	Ink.path(p, poly, LINE)


## 돌 기단(모든 건물 공통): 짙은 마름돌 띠.
static func plinth(p: Paint, x: float, y: float, pw: float, ph: float) -> void:
	var poly := Paint.rect_poly(x, y, pw, ph)
	p.fill_poly(poly, Mat.ashlar(p, Color("#4f4c45"), int(x), int(y), 38, 15))
	Ink.shade(p, poly, Vector2(0, y), Vector2(0, y + ph), 0.0, 0.3)
	Ink.path(p, poly, LINE)


## 돌출 띠(층 사이 돌림띠·처마 돌림).
static func ledge(p: Paint, x: float, y: float, lw: float, lh: float = 7.0, c: Color = Color("#8c8473")) -> void:
	p.mark("ledge", Rect2(x, y, lw, lh))
	var poly := Paint.rect_poly(x, y, lw, lh)
	p.fill_poly(poly, p.flat(c, 0.15))
	Ink.shade(p, poly, Vector2(0, y), Vector2(0, y + lh), -0.0, 0.35)
	Ink.path(p, poly, 1.8)
	Ink.shade(p, Paint.rect_poly(x, y + lh, lw, 10), Vector2(0, y + lh), Vector2(0, y + lh + 10), 0.45, 0.0)


## 창: style = "square" · "arch" · "gothic". lit = 따뜻한 불빛(번짐 포함). shutters = 덧문.
static func window(p: Paint, x: float, y: float, ww: float, wh: float, style: String = "square", lit: bool = false, shutters: bool = false) -> void:
	p.mark("window", Rect2(x, y, ww, wh), style)
	var f := 5.0
	var outer := _shape(x - f, y - f, ww + f * 2.0, wh + f * 2.0, style)
	p.fill_poly(outer, p.flat(FRAME, 0.2))
	Ink.shade(p, outer, Vector2(x - f, 0), Vector2(x + ww + f, 0), 0.0, 0.3)
	var inner := _shape(x, y, ww, wh, style)
	p.fill_poly(inner, Mat.glass(p, y, y + wh, lit))
	Ink.shade(p, inner, Vector2(0, y), Vector2(0, y + 10), 0.55, 0.0)
	var mx := x + ww / 2.0
	Ink.line(p, Vector2(mx, y + 2), Vector2(mx, y + wh), 2.2, BAR, 0.95, 0.3)
	var rows := 1 if wh < 40 else 2
	for i in rows:
		var yy := y + wh * (i + 1) / (rows + 1.0)
		Ink.line(p, Vector2(x, yy), Vector2(x + ww, yy), 2.0, BAR, 0.95, 0.3)
	if lit:  # 커튼(안쪽 양옆 천 — 따뜻한 창에 사는 느낌, CT109)
		for s: float in [0.0, 1.0]:
			var cw := ww * 0.26
			var cx0 := x + (0.0 if s == 0.0 else ww - cw)
			var cur := Paint.poly([Vector2(cx0, y + 2), Vector2(cx0 + cw, y + 2), Vector2(cx0 + cw * (0.55 if s == 0.0 else 0.45), y + wh), Vector2(cx0 + (0.0 if s == 0.0 else cw), y + wh)])
			p.fill_poly(cur, p.flat(Color("#7a3a28"), 0.12), 0.85)
			Ink.line(p, Vector2(cx0 + cw * 0.5, y + 4), Vector2(cx0 + cw * 0.5, y + wh - 4), 0.8, Color("#4a2018"), 0.5, 0.3)
	Ink.path(p, inner, 1.6)
	Ink.path(p, outer, LINE)
	if style == "square":  # 돌 인방 + 가운데 쐐기돌(CT109)
		var lin := Paint.rect_poly(x - f - 4, y - f - 9, ww + f * 2.0 + 8, 9)
		p.fill_poly(lin, p.flat(FRAME.lightened(0.12), 0.12))
		Ink.shade(p, lin, Vector2(0, y - f - 9), Vector2(0, y - f), 0.0, 0.3)
		Ink.path(p, lin, 1.4)
		var key := Paint.poly([Vector2(x + ww * 0.5 - 6, y - f - 11), Vector2(x + ww * 0.5 + 6, y - f - 11), Vector2(x + ww * 0.5 + 4, y - f + 1), Vector2(x + ww * 0.5 - 4, y - f + 1)])
		p.fill_poly(key, p.flat(FRAME.lightened(0.2), 0.1))
		Ink.path(p, key, 1.2)
	Ink.grime(p, x - f, y + wh + f + 5, ww + f * 2.0, 70.0, 0.45)
	var sill := Paint.rect_poly(x - f - 3, y + wh + f, ww + f * 2.0 + 6, 5)
	p.fill_poly(sill, p.flat(FRAME.lightened(0.08), 0.15))
	Ink.path(p, sill, 1.6)
	Ink.shade(p, Paint.rect_poly(x - f, y + wh + f + 5, ww + f * 2.0, 14), Vector2(0, y + wh + f + 5), Vector2(0, y + wh + f + 19), 0.35, 0.0)
	if shutters:
		for sx: float in [x - f - ww / 2.0 - 2.0, x + ww + f + 2.0]:
			var sp := Paint.rect_poly(sx, y - 2, ww / 2.0, wh + 4)
			p.fill_poly(sp, Mat.planks(p, Color("#3d4a3f"), int(sx), 0, true, 7))
			Ink.path(p, sp, 1.8)
	if lit:
		Ink.glow(p, mx, y + wh * 0.55, maxf(ww, wh) * 1.1, GLOW, 0.28)


## 문: 아치 돌 테두리 + 판자 문 + 쇠띠 + 고리. lit_gap = 문틈 불빛.
static func door(p: Paint, x: float, y: float, dw: float, dh: float, arch: bool = true, wood: Color = Color("#3b2a1e"), lit_gap: bool = false) -> void:
	p.mark("door", Rect2(x, y, dw, dh), "arch" if arch else "square")
	var f := 7.0
	var outer := _shape(x - f, y - f, dw + f * 2.0, dh + f, "arch" if arch else "square")
	p.fill_poly(outer, p.flat(FRAME.darkened(0.08), 0.2))
	Ink.path(p, outer, LINE)
	var inner := _shape(x, y, dw, dh, "arch" if arch else "square")
	p.fill_poly(inner, Mat.planks(p, wood, int(x), int(y), true, int(maxf(8.0, dw / 4.0))))
	Ink.shade(p, inner, Vector2(0, y), Vector2(0, y + 26), 0.6, 0.05)
	for by: float in [y + dh * 0.38, y + dh * 0.78]:
		Ink.line(p, Vector2(x + 2, by), Vector2(x + dw * 0.72, by), 4.0, IRON, 0.95, 0.2)
		for k in 2:  # 소용돌이 경첩 끝(CT109)
			var cc := Vector2(x + dw * (0.74 + k * 0.08), by + (-5.0 if k == 0 else 5.0))
			var curl := PackedVector2Array()
			for i in 10:
				curl.append(cc + Vector2.from_angle(TAU * i / 12.0 + (0.0 if k == 0 else PI)) * (6.0 - i * 0.4))
			Ink.path(p, curl, 1.6, false, IRON, 0.95, 0.1)
		for k in 3:  # 못 머리
			Ink.glow(p, x + 6 + k * dw * 0.25, by, 1.6, Color("#5a564e"), 0.9)
	var ring := PackedVector2Array()  # 문고리
	for i in 14:
		ring.append(Vector2(x + dw * 0.5, y + dh * 0.52) + Vector2.from_angle(TAU * i / 14.0) * 5.0)
	Ink.path(p, ring, 1.8, true, Color("#6a5a3a"), 1.0, 0.1)
	Ink.glow(p, x + dw * 0.75, y + dh * 0.58, 3.0, Color("#c9a24a"), 0.8)
	Ink.path(p, inner, 1.8)
	if lit_gap:
		Ink.line(p, Vector2(x + dw / 2.0, y + 6), Vector2(x + dw / 2.0, y + dh - 2), 1.6, GLOW, 0.9, 0.2)
		Ink.glow(p, x + dw / 2.0, y + dh, dw * 1.2, GLOW, 0.22)


## 계단(문 앞): n단, 아래로 넓어진다.
static func steps(p: Paint, cx: float, ground: float, sw: float, n: int = 2, sh: float = 6.0) -> void:
	for i in n:
		var ww := sw + i * 12.0
		var poly := Paint.rect_poly(cx - ww / 2.0, ground - (n - i) * sh, ww, sh)
		p.fill_poly(poly, p.flat(Color("#6a655a"), 0.2))
		Ink.path(p, poly, 1.6)


## 앞에서 본 지붕 면(처마가 거리와 나란한 지붕): 사다리꼴 + 처마 그늘 + 윤곽.
static func roof(p: Paint, poly: PackedVector2Array, shader: Callable) -> void:
	p.fill_poly(poly, shader)
	var r := Paint.bounds(poly)
	Ink.strokes(p, poly, 0.7, 20.0, 5.0, 20.0, 0.12, 0.28)
	Ink.shade(p, poly, r.position, Vector2(r.position.x, r.end.y), 0.25, 0.0)
	Ink.shade(p, poly, r.position, Vector2(r.end.x, r.position.y), 0.0, 0.25)
	Ink.path(p, poly, LINE)
	Ink.hatch(p, poly, 9.0, 58.0, 0.12, 1.0)


## 굴뚝(벽돌 + 갓돌) + 연기.
static func chimney(p: Paint, x: float, y: float, cw: float, ch: float, smoke: bool = true) -> void:
	var poly := Paint.rect_poly(x, y, cw, ch)
	p.fill_poly(poly, Mat.brick(p, Color("#5b3a2c"), int(x), int(y), 12, 6))
	Ink.shade(p, poly, Vector2(x, 0), Vector2(x + cw, 0), 0.0, 0.4)
	Ink.path(p, poly, LINE)
	var cap := Paint.rect_poly(x - 4, y - 6, cw + 8, 7)
	p.fill_poly(cap, p.flat(Color("#5c5850"), 0.2))
	Ink.path(p, cap, 1.8)
	if smoke:
		var sx := x + cw / 2.0
		var sy := y - 10.0
		for i in 9:
			var r := 7.0 + i * 3.2
			sx += p.rng.randf_range(2.0, 7.0)
			sy -= r * 0.7
			var col := Color("#8d9187").darkened(i * 0.03)
			for yy in range(int(sy - r), int(sy + r)):
				for xx in range(int(sx - r), int(sx + r)):
					var d := Vector2(xx - sx, yy - sy).length() / r
					if d < 1.0:
						p.blend(xx, yy, col, (1.0 - d) * 0.22 * (1.0 - i / 10.0) * p.nz("mid", xx, yy) * 1.6)


## 걸이 간판(쇠 받침 + 나무 판 + 시설 그림). side = 1이면 오른쪽으로 뻗는다.
static func sign(p: Paint, wx: float, y: float, icon: String, side: float = 1.0, sw: float = 46.0) -> void:
	var tip := wx + side * (sw + 14.0)
	Ink.line(p, Vector2(wx, y), Vector2(tip, y), 3.6, IRON, 1.0, 0.3)
	Ink.line(p, Vector2(wx, y + 18), Vector2(wx + side * (sw * 0.6), y), 2.4, IRON, 1.0, 0.3)
	var bx := wx + side * 10.0 + (0.0 if side > 0.0 else -sw)
	for cx: float in [bx + 6.0, bx + sw - 6.0]:
		Ink.line(p, Vector2(cx, y), Vector2(cx, y + 9), 1.6, IRON, 1.0, 0.1)
	var board := Paint.rect_poly(bx, y + 9, sw, sw * 0.8)
	p.fill_poly(board, Mat.planks(p, Color("#4a3424"), int(bx), int(y), false, 9))
	Ink.path(p, board, LINE)
	Icons.draw(p, icon, Vector2(bx + sw / 2.0, y + 9 + sw * 0.4), sw * 0.32)


## 벽 등(쇠 등롱) + 빛 번짐.
static func lantern(p: Paint, x: float, y: float, s: float = 1.0) -> void:
	Ink.line(p, Vector2(x, y - 14 * s), Vector2(x, y - 4 * s), 2.0, IRON, 1.0, 0.1)
	var body := Paint.poly([Vector2(x - 6 * s, y - 4 * s), Vector2(x + 6 * s, y - 4 * s), Vector2(x + 4 * s, y + 10 * s), Vector2(x - 4 * s, y + 10 * s)])
	p.fill_poly(body, p.flat(Color("#ffd28a"), 0.1))
	Ink.path(p, body, 1.8, true, IRON, 1.0, 0.2)
	Ink.glow(p, x, y + 3 * s, 60.0 * s, GLOW, 0.32, false)


static func _shape(x: float, y: float, ww: float, wh: float, style: String) -> PackedVector2Array:
	match style:
		"arch":
			return Paint.arch_poly(x, y, ww, wh, false)
		"gothic":
			return Paint.arch_poly(x, y, ww, wh, true)
	return Paint.rect_poly(x, y, ww, wh)

