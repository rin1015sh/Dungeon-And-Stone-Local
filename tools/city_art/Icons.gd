extends RefCounted
## 걸이 간판·문장에 그리는 시설 그림(놋쇠·뼈빛 물감 + 잉크): mug(여관) · book(도서관) · sun(신전) · bag(상점) · key(은행) · swords(훈련장) ·
## anvil(대장간) · crest(모험가 길드 — 방패 문장에 횃불).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

const BRASS := Color("#b08d4a")
const BONE := Color("#cfc4a6")
const RED := Color("#7d2620")


static func draw(p: Paint, icon: String, c: Vector2, s: float) -> void:
	match icon:
		"mug":
			var body := Paint.rect_poly(c.x - s * 0.55, c.y - s * 0.6, s * 0.95, s * 1.2)
			p.fill_poly(body, p.flat(BRASS, 0.2))
			Ink.path(p, body, 1.8)
			Ink.path(p, Paint.poly([Vector2(c.x + s * 0.4, c.y - s * 0.35), Vector2(c.x + s * 0.8, c.y - s * 0.3), Vector2(c.x + s * 0.8, c.y + s * 0.3), Vector2(c.x + s * 0.4, c.y + s * 0.35)]), 2.4, false, BRASS.darkened(0.3))
			p.fill_poly(Paint.rect_poly(c.x - s * 0.6, c.y - s * 0.8, s * 1.05, s * 0.3), p.flat(BONE, 0.15))
		"book":
			var l := Paint.poly([Vector2(c.x, c.y - s * 0.45), Vector2(c.x - s * 0.9, c.y - s * 0.65), Vector2(c.x - s * 0.9, c.y + s * 0.55), Vector2(c.x, c.y + s * 0.75)])
			var r := Paint.poly([Vector2(c.x, c.y - s * 0.45), Vector2(c.x + s * 0.9, c.y - s * 0.65), Vector2(c.x + s * 0.9, c.y + s * 0.55), Vector2(c.x, c.y + s * 0.75)])
			for q in [l, r]:
				p.fill_poly(q, p.flat(BONE, 0.15))
				Ink.path(p, q, 1.6)
			for i in 3:
				var yy := c.y - s * 0.25 + i * s * 0.25
				Ink.line(p, Vector2(c.x - s * 0.7, yy - s * 0.1), Vector2(c.x - s * 0.15, yy), 1.0, Ink.INK, 0.6)
				Ink.line(p, Vector2(c.x + s * 0.15, yy), Vector2(c.x + s * 0.7, yy - s * 0.1), 1.0, Ink.INK, 0.6)
		"sun":
			for i in 12:
				var a := TAU * i / 12.0
				Ink.line(p, c + Vector2.from_angle(a) * s * 0.55, c + Vector2.from_angle(a) * s * (1.0 if i % 2 == 0 else 0.8), 2.4, BRASS, 1.0, 0.1)
			var disc := _circle(c, s * 0.48)
			p.fill_poly(disc, p.flat(BRASS.lightened(0.1), 0.2))
			Ink.path(p, disc, 1.6)
		"bag":
			var bag := Paint.poly([Vector2(c.x - s * 0.25, c.y - s * 0.55), Vector2(c.x + s * 0.25, c.y - s * 0.55), Vector2(c.x + s * 0.8, c.y + s * 0.3), Vector2(c.x + s * 0.5, c.y + s * 0.75), Vector2(c.x - s * 0.5, c.y + s * 0.75), Vector2(c.x - s * 0.8, c.y + s * 0.3)])
			p.fill_poly(bag, p.flat(Color("#8a7350"), 0.2))
			Ink.path(p, bag, 1.8)
			Ink.line(p, Vector2(c.x - s * 0.35, c.y - s * 0.45), Vector2(c.x + s * 0.35, c.y - s * 0.45), 2.4, RED, 1.0, 0.2)
			p.fill_poly(_circle(c + Vector2(0, s * 0.2), s * 0.2), p.flat(BRASS, 0.1))
		"key":
			var ring := _circle(c + Vector2(-s * 0.45, 0), s * 0.35)
			p.fill_poly(ring, p.flat(BRASS, 0.15))
			p.fill_poly(_circle(c + Vector2(-s * 0.45, 0), s * 0.16), p.flat(Color("#2b1f16"), 0.1))
			Ink.path(p, ring, 1.6)
			Ink.line(p, c + Vector2(-s * 0.1, 0), c + Vector2(s * 0.85, 0), 3.4, BRASS, 1.0, 0.1)
			for k in 2:
				Ink.line(p, c + Vector2(s * (0.55 + k * 0.22), 0), c + Vector2(s * (0.55 + k * 0.22), s * 0.3), 3.0, BRASS, 1.0, 0.1)
		"anvil":
			var top := Paint.poly([Vector2(c.x - s * 0.95, c.y - s * 0.35), Vector2(c.x + s * 0.7, c.y - s * 0.35), Vector2(c.x + s * 0.95, c.y - s * 0.15),
				Vector2(c.x + s * 0.45, c.y), Vector2(c.x + s * 0.25, c.y + s * 0.15), Vector2(c.x + s * 0.4, c.y + s * 0.6), Vector2(c.x - s * 0.5, c.y + s * 0.6),
				Vector2(c.x - s * 0.35, c.y + s * 0.15), Vector2(c.x - s * 0.55, c.y - s * 0.05)])
			p.fill_poly(top, p.flat(Color("#5d5a55"), 0.2))
			Ink.path(p, top, 1.8)
			Ink.line(p, Vector2(c.x - s * 0.9, c.y - s * 0.33), Vector2(c.x + s * 0.65, c.y - s * 0.33), 1.6, BONE, 0.6, 0.1)
			Ink.line(p, c + Vector2(-s * 0.2, -s * 0.5), c + Vector2(s * 0.5, -s * 1.0), 3.0, BRASS.darkened(0.3), 1.0, 0.1)
			p.fill_poly(Paint.rect_poly(c.x + s * 0.35, c.y - s * 1.15, s * 0.4, s * 0.22), p.flat(Color("#4a4744"), 0.1))
		"crest":
			var sh := Paint.poly([Vector2(c.x - s * 0.75, c.y - s * 0.8), Vector2(c.x + s * 0.75, c.y - s * 0.8), Vector2(c.x + s * 0.75, c.y + s * 0.05),
				Vector2(c.x, c.y + s * 0.9), Vector2(c.x - s * 0.75, c.y + s * 0.05)])
			p.fill_poly(sh, func(x: int, y: int) -> Color:
				return p.vary(RED if x < int(c.x) else Color("#2c3444"), x, y, 0.2))
			Ink.path(p, sh, 2.0, true, BRASS.darkened(0.2))
			Ink.line(p, c + Vector2(0, s * 0.55), c + Vector2(0, -s * 0.15), 2.6, BONE, 1.0, 0.1)
			for layer in 2:
				var col: Color = [Color("#f08a2c"), Color("#ffd27a")][layer]
				var fh := s * (0.55 - layer * 0.18)
				var fl := Paint.poly([c + Vector2(-s * 0.18 + layer * 3, -s * 0.12), c + Vector2(0, -s * 0.12 - fh), c + Vector2(s * 0.18 - layer * 3, -s * 0.12)])
				p.fill_poly(fl, p.flat(col, 0.1))
		"swords":
			for sgn: float in [-1.0, 1.0]:
				var a := c + Vector2(-s * 0.75 * sgn, s * 0.75)
				var b := c + Vector2(s * 0.75 * sgn, -s * 0.75)
				Ink.line(p, a, b, 3.2, BONE, 1.0, 0.1)
				var g := a.lerp(b, 0.22)
				var n := (b - a).normalized().orthogonal() * s * 0.3
				Ink.line(p, g - n, g + n, 3.0, BRASS, 1.0, 0.1)


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 20:
		out.append(c + Vector2.from_angle(TAU * i / 20.0) * r)
	return out
