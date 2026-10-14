extends RefCounted
## 실내 소품 조각(InteriorRooms 전용): 난로 · 선반 · 책장 · 책 · 해골 · 기둥 · 제단 · 촛대 · 매단 약초 · 저울 · 동전 · 금고 문 · 놋쇠 등 · 방패 · 횃불,
## 그리고 실내 바닥·천장 셰이더(책 벽·둥근 천장·체크 바닥·모래).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Props := preload("res://tools/city_art/Props.gd")

const BOOK_COLORS := [Color("#5a2420"), Color("#3d4a30"), Color("#2c3444"), Color("#5c4a2c"), Color("#7a6d52"), Color("#3a2618")]


static func hearth(p: Paint, x: float, y: float, hw: float, hh: float) -> void:
	var surround := Paint.rect_poly(x, y, hw, hh)
	p.fill_poly(surround, Mat.rubble(p, Color("#57524a")))
	Ink.path(p, surround, 2.4)
	var mantle := Paint.rect_poly(x - 12, y - 4, hw + 24, 14)
	p.fill_poly(mantle, Mat.planks(p, Color("#3b2a1c"), 0, 0, false, 14))
	Ink.path(p, mantle, 2.0)
	var mouth := Paint.arch_poly(x + 22, y + 60, hw - 44, hh - 60)
	p.fill_poly(mouth, p.flat(Color("#0d0907"), 0.1))
	Ink.path(p, mouth, 2.4)
	var fx := x + hw / 2.0
	var fy := y + hh - 6.0
	for k in 3:  # 장작
		Ink.line(p, Vector2(fx - 34 + k * 8, fy), Vector2(fx + 24 - k * 6, fy - 8), 7.0, Color("#2b1a10"), 1.0, 0.3)
	for layer in 3:
		var col: Color = [Color("#b8461c"), Color("#f08a2c"), Color("#ffd27a")][layer]
		for k in 5 - layer:
			var bx := fx - 30 + k * 14 + layer * 8 + p.rng.randf_range(-3, 3)
			var fh := (50.0 - layer * 12.0) * p.rng.randf_range(0.7, 1.2)
			var fl := Paint.poly([Vector2(bx - 9, fy - 4), Vector2(bx - 3, fy - fh * 0.6), Vector2(bx + 2, fy - fh), Vector2(bx + 5, fy - fh * 0.5), Vector2(bx + 10, fy - 4)])
			p.fill_poly(fl, p.flat(col, 0.1))
	Ink.glow(p, fx, fy - 20, 120, Color("#ff9a40"), 0.5)


static func shelf_row(p: Paint, x: float, y: float, sw: float, kind: String) -> void:
	var board := Paint.rect_poly(x, y + 44, sw, 7)
	var cx := x + 6.0
	while cx < x + sw - 12.0:
		var iw := 14.0
		match kind:
			"bottles":
				iw = p.rng.randf_range(10, 16)
				var bh := p.rng.randf_range(26, 40)
				var b := Paint.poly([Vector2(cx, y + 44), Vector2(cx, y + 44 - bh * 0.6), Vector2(cx + iw * 0.35, y + 44 - bh), Vector2(cx + iw * 0.65, y + 44 - bh), Vector2(cx + iw, y + 44 - bh * 0.6), Vector2(cx + iw, y + 44)])
				p.fill_poly(b, p.flat([Color("#2f4430"), Color("#4e2a1c"), Color("#2b3138"), Color("#6a5a2c")][p.rng.randi() % 4], 0.2))
				Ink.path(p, b, 1.4)
				Ink.line(p, Vector2(cx + 3, y + 44 - bh * 0.5), Vector2(cx + 3, y + 40), 1.2, Color("#c8c0a0"), 0.35, 0.1)
			"jars":
				iw = p.rng.randf_range(18, 26)
				var jh := p.rng.randf_range(22, 32)
				var j := Paint.rect_poly(cx, y + 44 - jh, iw, jh)
				p.fill_poly(j, p.flat([Color("#7a6a4a"), Color("#5c4632"), Color("#8a7c5e")][p.rng.randi() % 3], 0.2))
				Ink.shade(p, j, Vector2(cx, 0), Vector2(cx + iw, 0), 0.0, 0.4)
				Ink.path(p, j, 1.4)
				p.fill_rect(cx - 2, y + 44 - jh - 5, iw + 4, 6, p.flat(Color("#3b2a1c"), 0.1))
			"boxes":
				iw = p.rng.randf_range(26, 40)
				var bx := Paint.rect_poly(cx, y + 44 - iw * 0.7, iw, iw * 0.7)
				p.fill_poly(bx, Mat.planks(p, Color("#5a432c"), int(cx), 0, false, 7))
				Ink.path(p, bx, 1.6)
		cx += iw + p.rng.randf_range(2, 6)
	p.fill_poly(board, Mat.planks(p, Color("#3a2a1c"), 0, 0, false, 7))
	Ink.path(p, board, 1.8)


static func bookcase(p: Paint, x: float, y: float, bw: float, bh: float) -> void:
	var frame := Paint.rect_poly(x, y, bw, bh)
	p.fill_poly(frame, books_shader(p))
	Ink.path(p, frame, 2.6)
	Ink.shade(p, frame, Vector2(0, y), Vector2(0, y + bh), 0.1, 0.4)


## 책 벽: 칸마다 책등(색·높이·폭이 다르다) + 짙은 선반 판.
static func books_shader(p: Paint) -> Callable:
	return func(x: int, y: int) -> Color:
		var row := floori(y / 42.0)
		var ly := posmod(y, 42)
		if ly < 6:
			return p.vary(Color("#2a1d13"), x, y, 0.2)
		var col := floori((x + row * 7) / 9.0)
		var hgt := 12 + int(Paint.hash01(row, col, 4) * 22.0)
		if ly < 42 - hgt or posmod(x + row * 7, 9) == 0:
			return p.vary(Color("#120d09"), x, y, 0.2)
		var c: Color = BOOK_COLORS[int(Paint.hash01(row, col, 8) * BOOK_COLORS.size())]
		if posmod(ly, 42) == 42 - hgt + 4:
			c = Color("#a88a4a")
		return p.vary(c, x, y, 0.25)


static func open_book(p: Paint, c: Vector2, s: float) -> void:
	for sgn: float in [-1.0, 1.0]:
		var page := Paint.poly([c, c + Vector2(sgn * s, -s * 0.12), c + Vector2(sgn * s * 1.02, s * 0.42), c + Vector2(0, s * 0.5)])
		p.fill_poly(page, p.flat(Color("#bfb391"), 0.12))
		Ink.path(p, page, 1.4)
		for k in 4:
			var yy := s * (0.02 + k * 0.1)
			Ink.line(p, c + Vector2(sgn * s * 0.15, yy), c + Vector2(sgn * s * 0.85, yy - s * 0.05), 0.9, Ink.INK, 0.45)


static func skull(p: Paint, c: Vector2, r: float) -> void:
	var head: Array = []
	for i in 16:
		head.append(c + Vector2.from_angle(TAU * i / 16.0) * Vector2(r, r * 0.9))
	var hp := Paint.poly(head)
	p.fill_poly(hp, p.flat(Color("#c4b896"), 0.15))
	var jaw := Paint.rect_poly(c.x - r * 0.5, c.y + r * 0.6, r, r * 0.55)
	p.fill_poly(jaw, p.flat(Color("#b4a886"), 0.15))
	Ink.path(p, hp, 1.6)
	Ink.path(p, jaw, 1.4)
	for sgn: float in [-1.0, 1.0]:
		p.fill_poly(_circle(c + Vector2(sgn * r * 0.38, r * 0.15), r * 0.24), p.flat(Color("#1a120c"), 0.1))


static func book_pile(p: Paint, x: float, ground: float, n: int) -> void:
	var y := ground
	for i in n:
		var bw := p.rng.randf_range(60, 90)
		var bh := p.rng.randf_range(12, 18)
		var bx := x + p.rng.randf_range(-10, 10)
		var b := Paint.rect_poly(bx, y - bh, bw, bh)
		p.fill_poly(b, p.flat(BOOK_COLORS[p.rng.randi() % BOOK_COLORS.size()], 0.2))
		Ink.line(p, Vector2(bx + 4, y - bh + 3), Vector2(bx + 4, y - 3), 1.0, Color("#a88a4a"), 0.6)
		Ink.path(p, b, 1.6)
		y -= bh


## 둥근 천장: 어둠 + 갈빗대 줄.
static func vault_shader(p: Paint) -> Callable:
	return func(x: int, y: int) -> Color:
		var c := Color("#1b1a17").lerp(Color("#36332c"), clampf(y / 110.0, 0.0, 1.0))
		if posmod(x + int(y * 1.6), 90) < 6:
			c = c.lightened(0.15)
		return p.vary(c, x, y, 0.2)


static func checker_shader(p: Paint) -> Callable:
	return func(x: int, y: int) -> Color:
		var s := 14.0 + (y - 330.0) * 0.35
		var ix := floori((x - 360.0) / maxf(4.0, s * 1.6))
		var iy := floori(sqrt(maxf(0.0, y - 330.0)) * 1.2)
		var c := Color("#3d3b36") if (ix + iy) % 2 == 0 else Color("#24231f")
		if p.nz("mid", x, y) > 0.7:
			c = c.lightened(0.1)
		return p.vary(c, x, y, 0.15)


static func sand_shader(p: Paint) -> Callable:
	return func(x: int, y: int) -> Color:
		var c := Color("#6b5a40").darkened(absf(p.nz("hs", x, y) - 0.5) * 0.5)
		return p.vary(c, x, y, 0.25)


## 기둥: 위 a → 아래 b, 폭 cw. 왼쪽 밝고 오른쪽 어둡다.
static func column(p: Paint, a: Vector2, b: Vector2, cw: float) -> void:
	var shaft := Paint.rect_poly(a.x - cw / 2.0, a.y, cw, b.y - a.y)
	p.fill_poly(shaft, func(x: int, y: int) -> Color:
		var t := (x - (a.x - cw / 2.0)) / cw
		return p.vary(Color("#6d675a").lightened(0.15 * (1.0 - t)).darkened(0.55 * t * t), x, y, 0.15))
	Ink.path(p, shaft, 2.2)
	for yy: float in [a.y, b.y - cw * 0.5]:
		var cap := Paint.rect_poly(a.x - cw * 0.7, yy, cw * 1.4, cw * 0.5)
		p.fill_poly(cap, p.flat(Color("#5d584c"), 0.15))
		Ink.path(p, cap, 1.8)


static func altar_cloth(p: Paint, x: float, y: float, cw: float) -> void:
	var cloth := Paint.poly([Vector2(x, y), Vector2(x + cw, y), Vector2(x + cw - 10, y + 34), Vector2(x + cw / 2.0, y + 40), Vector2(x + 10, y + 34)])
	p.fill_poly(cloth, p.flat(Color("#6a2420"), 0.2))
	Ink.path(p, cloth, 1.6)
	Ink.line(p, Vector2(x + cw / 2.0, y + 4), Vector2(x + cw / 2.0, y + 34), 3.0, Color("#a88a4a"), 0.9, 0.1)


static func candle_stand(p: Paint, cx: float, ground: float) -> void:
	Ink.line(p, Vector2(cx, ground), Vector2(cx, ground - 110), 5.0, Color("#2a2622"), 1.0, 0.2)
	Ink.line(p, Vector2(cx - 30, ground - 110), Vector2(cx + 30, ground - 110), 4.0, Color("#2a2622"), 1.0, 0.2)
	Ink.line(p, Vector2(cx - 20, ground), Vector2(cx + 20, ground), 6.0, Color("#2a2622"), 1.0, 0.2)
	for k in 5:
		Props.candle(p, cx - 26 + k * 13, ground - 112, 12 + (k % 2) * 6)


static func hanging(p: Paint, top: Vector2, length: float, kind: int) -> void:
	Ink.line(p, top, top + Vector2(0, length), 1.2, Color("#2a2018"), 0.9, 0.3)
	var b := top + Vector2(0, length)
	if kind == 0:
		for k in 7:
			Ink.line(p, b, b + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(10, 26)), 2.0, Color("#4f5a34"), 0.9, 1.0)
	else:
		var s := Paint.poly([b + Vector2(-6, 0), b + Vector2(6, 0), b + Vector2(10, 26), b + Vector2(0, 32), b + Vector2(-10, 26)])
		p.fill_poly(s, p.flat(Color("#6b4a32") if kind == 1 else Color("#7a6a4c"), 0.2))
		Ink.path(p, s, 1.4)


static func scale(p: Paint, c: Vector2) -> void:
	var brass := Color("#a88a4a")
	Ink.line(p, c, c + Vector2(0, -50), 3.0, brass.darkened(0.3), 1.0, 0.1)
	Ink.line(p, c + Vector2(-40, -46), c + Vector2(40, -50), 3.0, brass, 1.0, 0.1)
	for sgn: float in [-1.0, 1.0]:
		var top := c + Vector2(sgn * 40, -48)
		Ink.line(p, top, top + Vector2(-12, 26), 1.0, brass, 0.9)
		Ink.line(p, top, top + Vector2(12, 26), 1.0, brass, 0.9)
		var pan := Paint.poly([top + Vector2(-16, 26), top + Vector2(16, 26), top + Vector2(10, 32), top + Vector2(-10, 32)])
		p.fill_poly(pan, p.flat(brass, 0.15))
		Ink.path(p, pan, 1.4)
	p.fill_rect(c.x - 16, c.y - 4, 32, 6, p.flat(brass.darkened(0.3), 0.1))


static func coins(p: Paint, c: Vector2) -> void:
	for i in 14:
		var q := c + Vector2(p.rng.randf_range(-24, 24), -float(i % 5) * 3.0 - p.rng.randf_range(0, 3))
		var coin := Paint.poly([q + Vector2(-6, 0), q + Vector2(0, -2.5), q + Vector2(6, 0), q + Vector2(0, 2.5)])
		p.fill_poly(coin, p.flat(Color("#b8954a"), 0.2))
		Ink.path(p, coin, 0.9, true, Ink.INK, 0.7)
	Ink.glow(p, c.x, c.y - 6, 30, Color("#ffd27a"), 0.25)


static func vault(p: Paint, c: Vector2, r: float) -> void:
	var ring := _circle(c, r)
	p.fill_poly(ring, func(x: int, y: int) -> Color:
		var d := (Vector2(x, y) - c).length() / r
		return p.vary(Color("#55554f").darkened(0.3 * d).lightened(0.1 if d > 0.86 else 0.0), x, y, 0.15))
	Ink.path(p, ring, 3.0)
	Ink.path(p, _circle(c, r * 0.86), 2.0)
	for i in 16:
		var q := c + Vector2.from_angle(TAU * i / 16.0) * r * 0.93
		p.fill_poly(_circle(q, 2.6), p.flat(Color("#8a8a80"), 0.1))
	for i in 3:
		var a := TAU * i / 6.0
		Ink.line(p, c - Vector2.from_angle(a) * r * 0.45, c + Vector2.from_angle(a) * r * 0.45, 6.0, Color("#2a2a26"), 1.0, 0.1)
	p.fill_poly(_circle(c, r * 0.14), p.flat(Color("#7a6a3c"), 0.15))


static func brass_lamp(p: Paint, base: Vector2) -> void:
	Ink.line(p, base, base + Vector2(0, -36), 3.0, Color("#6a5630"), 1.0, 0.1)
	var shade := Paint.poly([base + Vector2(-16, -36), base + Vector2(16, -36), base + Vector2(8, -52), base + Vector2(-8, -52)])
	p.fill_poly(shade, p.flat(Color("#3e5a3a"), 0.15))
	Ink.path(p, shade, 1.6)
	Ink.glow(p, base.x, base.y - 30, 70, Color("#ffcf80"), 0.4)


static func shield(p: Paint, c: Vector2, r: float) -> void:
	var s := _circle(c, r)
	p.fill_poly(s, func(x: int, y: int) -> Color:
		return p.vary(Color("#6e2420") if (x - int(c.x)) * (y - int(c.y)) > 0 else Color("#a99a78"), x, y, 0.25))
	Ink.path(p, s, 2.4)
	p.fill_poly(_circle(c, r * 0.25), p.flat(Color("#5a5650"), 0.1))


static func torch(p: Paint, c: Vector2) -> void:
	Ink.line(p, c + Vector2(0, 40), c, 6.0, Color("#3a2a1c"), 1.0, 0.2)
	Ink.line(p, c + Vector2(-8, 34), c + Vector2(8, 34), 4.0, Color("#24221f"), 1.0, 0.1)
	for layer in 3:
		var col: Color = [Color("#c0501e"), Color("#f39030"), Color("#ffe08a")][layer]
		var fh := 34.0 - layer * 9.0
		var fl := Paint.poly([c + Vector2(-9 + layer * 2, 0), c + Vector2(-3, -fh * 0.6), c + Vector2(0, -fh), c + Vector2(4, -fh * 0.5), c + Vector2(9 - layer * 2, 0)])
		p.fill_poly(fl, p.flat(col, 0.1))
	Ink.glow(p, c.x, c.y - 10, 90, Color("#ff9a40"), 0.45)


static func chandelier(p: Paint, c: Vector2, r: float) -> void:
	Ink.line(p, Vector2(c.x, 0), c, 2.0, Color("#1f1c19"), 1.0, 0.2)
	Ink.path(p, Paint.poly([c + Vector2(-r, 14), c + Vector2(r, 14)]), 4.0, false, Color("#1f1c19"))
	for sgn: float in [-1.0, 1.0]:
		Ink.line(p, c, c + Vector2(sgn * r, 14), 1.6, Color("#1f1c19"), 1.0, 0.2)
	for k in 5:
		Props.candle(p, c.x - r + k * r / 2.0, c.y + 12, 12)


static func mug(p: Paint, cx: float, ground: float) -> void:
	var m := Paint.rect_poly(cx - 8, ground - 18, 16, 18)
	p.fill_poly(m, p.flat(Color("#6a5236"), 0.2))
	Ink.path(p, m, 1.4)
	Ink.line(p, Vector2(cx + 8, ground - 14), Vector2(cx + 13, ground - 6), 2.0, Color("#3a2a1c"), 1.0, 0.1)


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 24:
		out.append(c + Vector2.from_angle(TAU * i / 24.0) * r)
	return out
