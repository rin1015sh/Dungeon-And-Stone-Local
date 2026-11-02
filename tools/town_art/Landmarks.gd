extends RefCounted
## 동네 집 굽기의 큰 건물 두 채: 신전(고딕 — 본당 · 앞 탑 둘과 첨탑 · 장미창 · 색유리 창 · 부벽 · 종) ·
## 도서관(원형 열람당 — 둥근 벽 조각마다 아치 창과 붙임기둥 · 유리 돔 · 꼭대기 등 · 기둥 현관). 모양은 Geo에, 면 그림은 횡스크롤 신전·도서관 부품(Buildings2)으로.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const B2 := preload("res://tools/city_art/Buildings2.gd")
const Geo := preload("res://tools/town_art/Geo.gd")

const KINDS := ["temple_front", "nave", "tower", "tower_top", "spire", "drum", "dome", "lantern", "lantern_top", "column", "column_top", "pediment", "portal"]
const TEMPLE_STONE := Color("#5f5b52")
const LIB_STONE := Color("#7a7468")
const LEAD := Color("#4a5056")


static func handles(kind: String) -> bool:
	return kind in KINDS


static func gothic(g: Geo, h: Dictionary) -> void:
	var rc: Rect2i = h["rect"]
	var x0 := float(rc.position.x)
	var x1 := float(rc.end.x)
	var y0 := float(rc.position.y)
	var y1 := float(rc.end.y)
	var tw := 4.0
	var hgt := g.wall_height(h)
	var nx0 := x0 + tw - 0.6
	var nx1 := x1 - tw + 0.6
	var xm := (x0 + x1) * 0.5
	var rise := minf((nx1 - nx0) * 0.5 * 0.95, 6.0)
	g.add("nave", Geo.quad_v(Vector2(nx1, y0), Vector2(nx1, y1), 0.0, hgt), Vector3(1, 0, 0))
	g.add("nave", Geo.quad_v(Vector2(nx0, y1), Vector2(nx0, y0), 0.0, hgt), Vector3(-1, 0, 0))
	g.add("spire", PackedVector3Array([Vector3(nx0 - 0.3, y1 + 0.2, hgt - 0.05), Vector3(xm, y1 + 0.2, hgt + rise), Vector3(xm, y0 - 0.3, hgt + rise), Vector3(nx0 - 0.3, y0 - 0.3, hgt - 0.05)]), Vector3(-1, 0, 1))
	g.add("spire", PackedVector3Array([Vector3(xm, y1 + 0.2, hgt + rise), Vector3(nx1 + 0.3, y1 + 0.2, hgt - 0.05), Vector3(nx1 + 0.3, y0 - 0.3, hgt - 0.05), Vector3(xm, y0 - 0.3, hgt + rise)]), Vector3(1, 0, 1))
	g.add("temple_front", PackedVector3Array([Vector3(nx0, y1, 0), Vector3(nx1, y1, 0), Vector3(nx1, y1, hgt), Vector3(xm, y1, hgt + rise - 0.1), Vector3(nx0, y1, hgt)]), Vector3(0, 1, 0), {"hgt": hgt})
	for tx: float in [x0, x1 - tw]:
		var th := hgt + 3.5
		g.box("tower", PackedVector2Array([Vector2(tx, y1 - tw), Vector2(tx + tw, y1 - tw), Vector2(tx + tw, y1), Vector2(tx, y1)]), 0.0, th)
		var apex := Vector3(tx + tw * 0.5, y1 - tw * 0.5, th + tw * 1.9)
		var cs := [Vector3(tx - 0.15, y1 - tw - 0.15, th), Vector3(tx + tw + 0.15, y1 - tw - 0.15, th), Vector3(tx + tw + 0.15, y1 + 0.15, th), Vector3(tx - 0.15, y1 + 0.15, th)]
		for i in 4:
			var a: Vector3 = cs[i]
			var b: Vector3 = cs[(i + 1) % 4]
			var m := (a + b) * 0.5 - Vector3(apex.x, apex.y, th)
			g.add("spire", PackedVector3Array([a, b, apex]), Vector3(m.x, m.y, 0.6))


static func rotunda(g: Geo, h: Dictionary) -> void:
	var c: Array = h["circle"]
	var cx := float(c[0]) + 0.5
	var cy := float(c[1]) + 0.5
	var R := float(c[2]) - 0.3
	var hgt := g.wall_height(h)
	var n := 24
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var am := (a0 + a1) * 0.5
		g.add("drum", Geo.quad_v(Vector2(cx + cos(a0) * R, cy + sin(a0) * R), Vector2(cx + cos(a1) * R, cy + sin(a1) * R), 0.0, hgt), Vector3(cos(am), sin(am), 0), {"i": i})
	var rings := 6
	var dh := R * 0.5
	for k in rings:
		var t0 := float(k) / rings
		var t1 := float(k + 1) / rings
		var r0 := R * cos(t0 * PI * 0.5) + 0.15 * (1.0 - t0)
		var r1 := R * cos(t1 * PI * 0.5)
		var z0 := hgt + 0.2 + dh * sin(t0 * PI * 0.5)
		var z1 := hgt + 0.2 + dh * sin(t1 * PI * 0.5)
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var am := (a0 + a1) * 0.5
			var pts := PackedVector3Array([Vector3(cx + cos(a0) * r0, cy + sin(a0) * r0, z0), Vector3(cx + cos(a1) * r0, cy + sin(a1) * r0, z0)])
			if r1 > 0.05:
				pts.append(Vector3(cx + cos(a1) * r1, cy + sin(a1) * r1, z1))
				pts.append(Vector3(cx + cos(a0) * r1, cy + sin(a0) * r1, z1))
			else:
				pts.append(Vector3(cx, cy, z1))
			var tm := (t0 + t1) * 0.25 * PI
			g.add("dome", pts, Vector3(cos(am) * cos(tm), sin(am) * cos(tm), sin(tm)), {"glass": (i + k) % 2 == 0})
	var top := hgt + 0.2 + dh
	var lb := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		lb.append(Vector2(cx + cos(a) * 0.55, cy + sin(a) * 0.55))
	g.box("lantern", lb, top - 0.1, top + 0.8)
	var door: Vector2i = h["door"]
	var dx := door.x + 0.5
	var fy := cy + R + 0.1
	for k: float in [-1.1, 1.1]:
		g.box("column", PackedVector2Array([Vector2(dx + k - 0.17, fy), Vector2(dx + k + 0.17, fy), Vector2(dx + k + 0.17, fy + 0.34), Vector2(dx + k - 0.17, fy + 0.34)]), 0.0, 1.5)
	g.add("pediment", PackedVector3Array([Vector3(dx - 1.5, fy + 0.36, 1.5), Vector3(dx + 1.5, fy + 0.36, 1.5), Vector3(dx, fy + 0.36, 2.15)]), Vector3(0, 1, 0))
	g.add("portal", PackedVector3Array([Vector3(dx - 0.5, fy + 0.05, 0), Vector3(dx + 0.5, fy + 0.05, 0), Vector3(dx + 0.5, fy + 0.05, 1.2), Vector3(dx - 0.5, fy + 0.05, 1.2)]), Vector3(0, 1, 0))


static func face(f: Dictionary, h: Dictionary, P: float, seed_value: int) -> Paint:
	var size: Vector2 = f["size"]
	var p := Paint.new(maxi(2, int(ceil(size.x * P)) + 1), maxi(2, int(ceil(size.y * P)) + 1), seed_value)
	var poly := PackedVector2Array()
	for l: Vector2 in f["local"]:
		poly.append(l * P)
	var W := float(p.w - 1)
	var H := float(p.h - 1)
	var info: Dictionary = f["info"]
	match str(f["kind"]):
		"temple_front":
			Parts.wall(p, poly, Mat.ashlar(p, TEMPLE_STONE, 0, 0, int(P * 0.62), int(P * 0.28)))
			var wall_top := H - float(info.get("hgt", 4.0)) * P
			for k: float in [-0.36, 0.36]:
				B2.buttress(p, W * (0.5 + k) - P * 0.2, wall_top + P * 0.4, P * 0.4, H - wall_top - P * 0.4)
				B2.stained_glass(p, W * (0.5 + k * 0.6) - P * 0.4, wall_top + P * 0.9, P * 0.8, P * 2.4)
			B2.rose_window(p, Vector2(W * 0.5, wall_top + P * 0.2), P * 1.35, true)
			var door := Paint.arch_poly(W * 0.5 - P * 0.75, H - P * 2.3, P * 1.5, P * 2.3, true)
			p.fill_poly(Paint.arch_poly(W * 0.5 - P * 0.95, H - P * 2.55, P * 1.9, P * 2.55, true), Mat.ashlar(p, TEMPLE_STONE.lightened(0.15), 0, 0, int(P * 0.4), int(P * 0.2)))
			Ink.path(p, Paint.arch_poly(W * 0.5 - P * 0.95, H - P * 2.55, P * 1.9, P * 2.55, true), Parts.LINE)
			p.fill_poly(door, Mat.planks(p, Color("#3b2a1e"), 0, 0, true, int(P * 0.18)))
			Ink.path(p, door, Parts.LINE)
			Parts.plinth(p, 0, H - P * 0.25, W, P * 0.25)
		"nave":
			Parts.wall(p, poly, Mat.ashlar(p, TEMPLE_STONE, 0, 0, int(P * 0.62), int(P * 0.28)))
			var n := maxi(1, int(W / (P * 2.2)))
			for k in n:
				var cx := W * (k + 0.5) / n
				B2.stained_glass(p, cx - P * 0.3, P * 0.8, P * 0.6, P * 2.0)
				B2.buttress(p, W * float(k) / n - P * 0.15, P * 0.6, P * 0.3, H - P * 0.6)
		"tower":
			Parts.wall(p, poly, Mat.ashlar(p, TEMPLE_STONE.lightened(0.05), 0, 0, int(P * 0.62), int(P * 0.28)))
			for fl in 3:
				var y := P * 0.6 + fl * P * 1.9
				var win := Paint.arch_poly(W * 0.5 - P * 0.3, y, P * 0.6, P * 1.3, true)
				p.fill_poly(win, Mat.glass(p, y, y + P * 1.3, fl == 1) if fl > 0 else p.flat(Color("#0e0c0b"), 0.05))
				Ink.path(p, win, Parts.LINE)
				if fl == 0:
					B2.bell(p, Vector2(W * 0.5, y + P * 0.75))
			Parts.ledge(p, -2, P * 0.25, W + 4, 6)
		"spire":
			Parts.roof(p, poly, Mat.slate(p, LEAD, 0, 0, int(P * 0.34), int(P * 0.2), 0.35))
		"tower_top", "column_top", "lantern_top":
			p.fill_poly(poly, p.flat(Color("#3a3832"), 0.1))
			Ink.path(p, poly, 1.4)
		"drum":
			Parts.wall(p, poly, Mat.ashlar(p, LIB_STONE, int(info.get("i", 0)) * 37, 0, int(P * 0.62), int(P * 0.28)))
			Parts.ledge(p, -2, P * 0.1, W + 4, 7)
			if int(info.get("i", 0)) % 2 == 0:
				for fl in 2:
					Parts.window(p, W * 0.5 - P * 0.22, P * 0.55 + fl * P * 1.25, P * 0.44, P * 0.8, "arch", (int(info.get("i", 0)) / 2 + fl) % 3 == 0)
			else:
				Ink.line(p, Vector2(W * 0.5, P * 0.3), Vector2(W * 0.5, H - P * 0.3), 5.0, Color("#3e3a33"), 0.8, 0.2)
			Parts.plinth(p, -1, H - P * 0.25, W + 2, P * 0.25)
		"dome":
			p.fill_poly(poly, Mat.slate(p, LEAD.lightened(0.08), 0, 0, int(P * 0.22), int(P * 0.14), 0.15))
			Ink.shade(p, poly, Vector2(0, 0), Vector2(0, H), 0.0, 0.25)
			Ink.path(p, poly, 1.6)
		"lantern":
			p.fill_poly(poly, Mat.glass(p, 0, H, true))
			Ink.path(p, poly, 1.8)
		"column":
			p.fill_poly(poly, p.flat(Color("#9a9384"), 0.15))
			Ink.shade(p, poly, Vector2(0, 0), Vector2(W, 0), 0.0, 0.35)
			Ink.path(p, poly, 1.6)
		"pediment":
			p.fill_poly(poly, Mat.ashlar(p, Color("#8d877a"), 0, 0, int(P * 0.5), int(P * 0.22)))
			Ink.path(p, poly, Parts.LINE)
		"portal":
			Parts.door(p, P * 0.12, P * 0.12, W - P * 0.24, H - P * 0.12, true, Color("#3b2a1e"), true)
	return p
