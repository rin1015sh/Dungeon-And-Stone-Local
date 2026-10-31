extends RefCounted
## 시설 실내 벽 장식 — 작은 것(RoomWalls 전용, CT68 "단순 장식 요소를 더"): painting 액자 그림 · sconce 벽 촛대(빛) · tapestry 걸개 ·
## pegs 옷걸이 못(망토·모자·가방) · pots 걸어 둔 냄비·국자 · map 벽 지도 · herbs 말린 약초 다발 · cobweb 거미줄 · damp 얼룩·금 ·
## plates 장식 접시 · keys 열쇠 판 · notice 붙은 종이 몇 장 · rack_small 작은 선반(병·단지) · icon 성화 · garland 마른 꽃 줄.
## r = 벽 장식 무리(벽 앞면 칸) 사각형.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")


static func draw(p: Paint, style: String, r: Rect2, col: Color, t: int) -> bool:
	var c := r.get_center()
	match style:
		"painting", "icon":
			var fr := Rect2(c.x - r.size.x * 0.36, r.position.y + t * 0.25, r.size.x * 0.72, minf(r.size.y - t * 0.5, r.size.x * 0.6))
			var frame := Paint.rect_poly(fr.position.x, fr.position.y, fr.size.x, fr.size.y)
			p.fill_poly(frame, p.flat(Color("#a8843a") if style == "icon" else Color("#4a3020"), 0.1))
			var inner := fr.grow(-5)
			p.fill_rect(inner.position.x, inner.position.y, inner.size.x, inner.size.y, func(x: int, y: int) -> Color:
				var f := (y - inner.position.y) / inner.size.y
				var cc: Color = col.lerp(Color("#2e3a2a"), 0.4).lerp(col.lightened(0.2), 1.0 - f) if style == "painting" else Color("#6a2a24")
				if style == "painting" and f > 0.62:
					cc = Color("#4a5a34").darkened(p.nz("lo", x, y) * 0.3)
				return p.vary(cc, x, y, 0.1))
			if style == "icon":
				p.fill_poly(_circle(Vector2(inner.get_center().x, inner.position.y + inner.size.y * 0.32), inner.size.x * 0.18), p.flat(Color("#e8d080"), 0.1))
				p.fill_rect(inner.get_center().x - inner.size.x * 0.15, inner.position.y + inner.size.y * 0.48, inner.size.x * 0.3, inner.size.y * 0.45, p.flat(Color("#2c4a6a"), 0.1))
			Ink.path(p, frame, 1.8)
		"sconce":
			p.fill_rect(c.x - 4, c.y - 2, 8, 12, p.flat(Color("#3a3226"), 0.1))
			Ink.line(p, Vector2(c.x, c.y + 4), Vector2(c.x + 8, c.y - 6), 3.0, Color("#3a3226"), 1.0, 0.1)
			RoomArt._flame(p, Vector2(c.x + 8, c.y - 6), 1.0)
		"tapestry":
			var tp := Paint.poly([Vector2(r.position.x + 6, r.position.y + 6), Vector2(r.end.x - 6, r.position.y + 6), Vector2(r.end.x - 6, r.end.y - 14), Vector2(c.x, r.end.y - 4), Vector2(r.position.x + 6, r.end.y - 14)])
			p.fill_poly(tp, func(x: int, y: int) -> Color:
				var band := posmod(int(y - r.position.y), 22) < 4
				return p.vary(Color("#c8a048") if band else col, x, y, 0.12))
			Ink.path(p, tp, 1.6)
			Ink.line(p, Vector2(r.position.x + 2, r.position.y + 6), Vector2(r.end.x - 2, r.position.y + 6), 4.0, Color("#3a281b"), 1.0, 0.1)
		"pegs":
			Ink.line(p, Vector2(r.position.x + 4, r.position.y + t * 0.5), Vector2(r.end.x - 4, r.position.y + t * 0.5), 5.0, Color("#4a3424"), 1.0, 0.1)
			var n := maxi(1, int(r.size.x / (t * 0.7)))
			for k in n:
				var x := r.position.x + (k + 0.5) * r.size.x / n
				var cc: Color = [col, Color("#4a4034"), Color("#6a2a24"), Color("#2e3a4a")][k % 4]
				var cl := Paint.poly([Vector2(x - 5, r.position.y + t * 0.5), Vector2(x + 5, r.position.y + t * 0.5), Vector2(x + 12, r.position.y + t * 1.4), Vector2(x - 12, r.position.y + t * 1.45)])
				p.fill_poly(cl, p.flat(cc, 0.15))
				Ink.path(p, cl, 1.2)
		"pots", "keys":
			Ink.line(p, Vector2(r.position.x + 4, r.position.y + t * 0.4), Vector2(r.end.x - 4, r.position.y + t * 0.4), 4.0, Color("#3a3226"), 1.0, 0.1)
			var n := maxi(2, int(r.size.x / (t * 0.4)))
			for k in n:
				var x := r.position.x + (k + 0.5) * r.size.x / n
				var y := r.position.y + t * 0.4
				Ink.line(p, Vector2(x, y), Vector2(x, y + t * 0.25), 1.5, Ink.INK, 0.8)
				if style == "keys":
					Ink.path(p, _circle(Vector2(x, y + t * 0.3), 4.0), 1.6, true, Color("#a8843a"), 1.0)
					Ink.line(p, Vector2(x, y + t * 0.36), Vector2(x, y + t * 0.6), 2.0, Color("#a8843a"), 1.0, 0.1)
				elif k % 2 == 0:
					p.fill_poly(_circle(Vector2(x, y + t * 0.5), t * 0.2), p.flat(Color("#3a3a3c"), 0.1))
					Ink.path(p, _circle(Vector2(x, y + t * 0.5), t * 0.2), 1.4)
				else:
					Ink.line(p, Vector2(x, y + t * 0.25), Vector2(x, y + t * 0.7), 2.5, Color("#6a6a68"), 1.0, 0.1)
					p.fill_poly(_circle(Vector2(x, y + t * 0.74), 5.0), p.flat(Color("#6a6a68"), 0.1))
		"map", "notice":
			var n := 1 if style == "map" else maxi(2, int(r.size.x / (t * 0.5)))
			for k in n:
				var w := r.size.x * 0.7 if style == "map" else p.rng.randf_range(16, 24)
				var h := r.size.y * 0.55 if style == "map" else p.rng.randf_range(20, 28)
				var x := c.x - w * 0.5 if style == "map" else r.position.x + 6 + k * (r.size.x - 12 - w) / maxf(1.0, n - 1)
				var y := r.position.y + t * 0.3 + (k % 2) * 8
				p.fill_rect(x, y, w, h, func(px: int, py: int) -> Color: return p.vary(Color("#c8b890").darkened(p.nz("lo", px, py) * 0.25), px, py, 0.08))
				Ink.path(p, Paint.rect_poly(x, y, w, h), 1.0)
				if style == "map":
					for l in 6:
						var a := Vector2(x + p.rng.randf_range(6, w - 6), y + p.rng.randf_range(6, h - 6))
						Ink.line(p, a, a + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-8, 8)), 1.2, Color("#6a3a24"), 0.7, 0.8)
				else:
					p.fill_rect(x + w * 0.5 - 2, y - 2, 4, 4, p.flat(Color("#3a3226"), 0.1))
		"herbs", "garland":
			Ink.line(p, Vector2(r.position.x + 4, r.position.y + t * 0.3), Vector2(r.end.x - 4, r.position.y + t * 0.3), 2.0, Color("#6a5a3a"), 1.0, 0.3)
			var n := maxi(2, int(r.size.x / (t * 0.35)))
			for k in n:
				var x := r.position.x + (k + 0.5) * r.size.x / n
				for l in 5:
					var a := Vector2(x, r.position.y + t * 0.3)
					var cc: Color = col.lightened(p.rng.randf_range(-0.12, 0.12)) if style == "herbs" else [Color("#9a4a5a"), Color("#c8a048"), Color("#7a8a4a")][l % 3]
					Ink.line(p, a, a + Vector2(p.rng.randf_range(-7, 7), t * p.rng.randf_range(0.4, 0.7)), 2.5, cc, 1.0, 0.3)
		"cobweb":
			for corner: Vector2 in [r.position + Vector2(2, 2), Vector2(r.end.x - 2, r.position.y + 2)]:
				var dx := 1.0 if corner.x < c.x else -1.0
				for k in 5:
					Ink.line(p, corner, corner + Vector2.from_angle(PI * 0.5 * k / 4.0) * Vector2(dx, 1) * t * 0.55, 0.8, Color("#d8d8d0"), 0.45, 0.1)
		"damp":
			p.fill_poly(_blob(p, Vector2(c.x, r.end.y - t * 0.4), r.size.x * 0.3), func(x: int, y: int) -> Color: return p.vary(Color("#2a3026"), x, y, 0.1), 0.35)
			Ink.line(p, Vector2(c.x - 4, r.position.y + 6), Vector2(c.x + 6, r.position.y + r.size.y * 0.5), 1.2, Color("#1a1612"), 0.6, 0.9)
		"plates":
			var n := maxi(1, int(r.size.x / (t * 0.6)))
			Ink.line(p, Vector2(r.position.x + 4, r.position.y + t * 0.95), Vector2(r.end.x - 4, r.position.y + t * 0.95), 4.0, Color("#4a3424"), 1.0, 0.1)
			for k in n:
				var pc := Vector2(r.position.x + (k + 0.5) * r.size.x / n, r.position.y + t * 0.62)
				p.fill_poly(_circle(pc, t * 0.24), p.flat(Color("#d8d0bc"), 0.06))
				Ink.path(p, _circle(pc, t * 0.24), 1.4)
				Ink.path(p, _circle(pc, t * 0.15), 1.4, true, col, 0.8)
		"rack_small":
			Bits.shelf_row(p, r.position.x + 4, r.position.y + t * 0.2, r.size.x - 8, "jars" if p.rng.randf() < 0.5 else "bottles")
		_:
			return false
	return true


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 18:
		pts.append(c + Vector2.from_angle(TAU * i / 18.0) * r)
	return pts


static func _blob(p: Paint, c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 14:
		pts.append(c + Vector2.from_angle(TAU * i / 14.0) * r * p.rng.randf_range(0.6, 1.05))
	return pts
