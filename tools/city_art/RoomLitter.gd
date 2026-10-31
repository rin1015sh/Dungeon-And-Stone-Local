extends RefCounted
## 시설 실내 바닥에 흩어진 것(RoomDecor 전용 — 밟고 지나가는 바닥 장식, CT68 "조금 어지럽혀도 되니 실제 같은 느낌으로"):
## papers 흩어진 종이 · rushes 깔아 둔 마른 풀 · spill 쏟은 술 · crumbs 빵부스러기·뼈 조각 · cobweb 구석 거미줄 · cracks 갈라진 바닥 ·
## chalk 분필 표시 · coins 흘린 동전 · ash 재·그을음 · puddle 물웅덩이 · petals 꽃잎 · wax 촛농 · sawdust 톱밥 · cloth 떨어진 천 ·
## stain 얼룩 · leaves 마른 잎 · shavings 쇳밥.
## 무리 칸마다 몇 개씩 흩뿌린다(Paint 시드 고정 — 같은 지도면 같은 그림).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")


static func draw(p: Paint, style: String, cells: Array, col: Color, t: int) -> bool:
	for c: Vector2i in cells:
		var o := Vector2(c * t)
		var at := func(m: float = 6.0) -> Vector2: return o + Vector2(p.rng.randf_range(m, t - m), p.rng.randf_range(m, t - m))
		match style:
			"papers":
				for k in 2:
					var a: Vector2 = at.call(10.0)
					var ang := p.rng.randf_range(-0.6, 0.6)
					var pts := PackedVector2Array()
					for v: Vector2 in [Vector2(-9, -6), Vector2(9, -6), Vector2(9, 6), Vector2(-9, 6)]:
						pts.append(a + v.rotated(ang))
					p.fill_poly(pts, p.flat(Color("#d8cca8"), 0.08))
					Ink.path(p, pts, 0.9, true, Ink.INK, 0.5)
					Ink.line(p, a + Vector2(-5, -1).rotated(ang), a + Vector2(5, -1).rotated(ang), 0.8, Ink.INK, 0.35)
			"rushes", "leaves":
				for k in (16 if style == "rushes" else 6):
					var a: Vector2 = at.call(2.0)
					if style == "rushes":
						Ink.line(p, a, a + Vector2.from_angle(p.rng.randf_range(-0.4, 0.4) + (PI if k % 2 == 0 else 0.0)) * 11.0, 1.6, col.lightened(p.rng.randf_range(-0.1, 0.1)), 0.75, 0.2)
					else:
						p.fill_poly(_ellipse(a, 4.0, 2.4, p.rng.randf() * PI), p.flat(col.lightened(p.rng.randf_range(-0.15, 0.1)), 0.1), 0.85)
			"spill", "puddle", "stain":
				var a: Vector2 = at.call(14.0)
				var cc := {"spill": Color("#4a1e1e"), "puddle": Color("#3a4a54"), "stain": Color("#2a241c")}[style] as Color
				p.fill_poly(_blob(p, a, t * 0.3), func(x: int, y: int) -> Color: return p.vary(cc, x, y, 0.06), 0.55 if style != "puddle" else 0.6)
				if style == "puddle":
					Ink.line(p, a + Vector2(-5, -3), a + Vector2(3, -4), 1.5, Color("#9ab0b8"), 0.5, 0.2)
			"crumbs", "shavings":
				for k in 8:
					var a: Vector2 = at.call(4.0)
					var cc: Color = col if style == "crumbs" else Color("#8a8a88")
					if style == "crumbs" and k % 4 == 0:
						Ink.line(p, a, a + Vector2(7, 2), 2.5, Color("#d8d0bc"), 0.9, 0.2)
					else:
						p.fill_rect(a.x, a.y, 2.5, 2.5, p.flat(cc.lightened(p.rng.randf_range(-0.2, 0.2)), 0.1))
			"cobweb":
				var corner := o + Vector2(2 if p.rng.randf() < 0.5 else t - 2, 2)
				var dirx := 1.0 if corner.x < o.x + t * 0.5 else -1.0
				for k in 5:
					Ink.line(p, corner, corner + Vector2.from_angle(PI * 0.5 * k / 4.0) * Vector2(dirx, 1) * t * 0.6, 0.8, Color("#d8d8d0"), 0.5, 0.1)
				for r in 3:
					var pts := PackedVector2Array()
					for k in 5:
						pts.append(corner + Vector2.from_angle(PI * 0.5 * k / 4.0) * Vector2(dirx, 1) * t * (0.18 + r * 0.15))
					Ink.path(p, pts, 0.7, false, Color("#d8d8d0"), 0.45, 0.1)
			"cracks":
				var a: Vector2 = at.call(8.0)
				for k in 3:
					var b := a + Vector2.from_angle(p.rng.randf() * TAU) * t * 0.35
					Ink.line(p, a, b, 1.2, Color("#1e1a16"), 0.6, 0.6)
			"chalk":
				var a: Vector2 = at.call(12.0)
				Ink.path(p, _ellipse(a, t * 0.25, t * 0.12, 0.0), 1.4, true, Color("#d8d4c8"), 0.55, 0.5)
				Ink.line(p, a + Vector2(-8, 0), a + Vector2(8, 0), 1.4, Color("#d8d4c8"), 0.55, 0.5)
			"coins":
				for k in 3:
					var a: Vector2 = at.call(6.0)
					p.fill_poly(_ellipse(a, 3.5, 2.2, 0.0), p.flat(Color("#c8a048"), 0.1))
					Ink.path(p, _ellipse(a, 3.5, 2.2, 0.0), 0.7, true, Ink.INK, 0.5)
			"ash":
				var a: Vector2 = at.call(12.0)
				p.fill_poly(_blob(p, a, t * 0.34), func(x: int, y: int) -> Color: return p.vary(Color("#2a2826"), x, y, 0.1), 0.4)
				for k in 5:
					var b: Vector2 = at.call(4.0)
					p.fill_rect(b.x, b.y, 3, 2, p.flat(Color("#1a1816"), 0.1), 0.7)
			"petals":
				for k in 6:
					var a: Vector2 = at.call(4.0)
					p.fill_poly(_ellipse(a, 3.0, 1.8, p.rng.randf() * PI), p.flat(col.lightened(p.rng.randf_range(-0.1, 0.15)), 0.1), 0.9)
			"wax":
				for k in 3:
					var a: Vector2 = at.call(6.0)
					p.fill_poly(_blob(p, a, 4.5), p.flat(Color("#e8dcc0"), 0.08), 0.85)
			"sawdust":
				for k in 22:
					var a: Vector2 = at.call(2.0)
					p.fill_rect(a.x, a.y, 2, 1.5, p.flat(Color("#c8a86a"), 0.15), 0.7)
			"cloth":
				var a: Vector2 = at.call(14.0)
				var cl := _blob(p, a, t * 0.28)
				p.fill_poly(cl, p.flat(col, 0.12))
				Ink.path(p, cl, 1.0, true, Ink.INK, 0.6)
			_:
				return false
	return true


static func _ellipse(c: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 14:
		pts.append(c + (Vector2.from_angle(TAU * i / 14.0) * Vector2(rx, ry)).rotated(rot))
	return pts


static func _blob(p: Paint, c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 14:
		pts.append(c + Vector2.from_angle(TAU * i / 14.0) * r * p.rng.randf_range(0.6, 1.05) * Vector2(1.0, 0.7))
	return pts
