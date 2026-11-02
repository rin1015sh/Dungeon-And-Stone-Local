class_name TownLandmark
extends RefCounted
## 도시 동네 지도의 시설 건물(CT82 — TownSolid로 입체):
##   신전 = 고딕(가파른 박공 본당 · 앞 모서리 탑 둘과 뾰족 첨탑 · 장미창 · 뾰족 아치 문과 창 · 부벽) ·
##   도서관 = 원형 열람당(사용자 2026-11-02 "원형이 예쁠듯" — 둥근 벽 · 아치 창 · 처마 띠 · 유리 돔과 갈빗대 · 꼭대기 등 · 기둥 현관) ·
##   나머지 시설은 상자 집(TownHouse.build_house) 앞벽에 큰 문과 꾸밈(길드 깃발 · 은행 기둥과 박공 · 여관 간판과 등 · 잡화점 아치와 차양 · 대장간 화덕 불빛).


## 앞벽 위 사각(문 칸 기준 가로 d0~d1칸 — 동쪽이 +, 높이 z0~z1).
static func _front_quad(h: TownHouse, d0: float, d1: float, z0: float, z1: float) -> PackedVector3Array:
	var door: Vector2i = h.house["door"]
	var y := float((h.house["rect"] as Rect2i).end.y)
	var x := door.x + 0.5
	return PackedVector3Array([Vector3(x + d0, y, z0), Vector3(x + d1, y, z0), Vector3(x + d1, y, z1), Vector3(x + d0, y, z1)])


## 뾰족(또는 둥근) 아치 꼴 — 앞벽 위(가운데 dx, 아래 z0, 폭 w, 높이 ht).
static func _arch(h: TownHouse, dx: float, z0: float, w: float, ht: float, pointed: bool) -> PackedVector3Array:
	var door: Vector2i = h.house["door"]
	var y := float((h.house["rect"] as Rect2i).end.y)
	var x := door.x + 0.5 + dx
	var r := w * 0.5
	var spring := z0 + ht - r * (1.4 if pointed else 1.0)
	var pts := PackedVector3Array([Vector3(x - r, y, z0), Vector3(x + r, y, z0)])
	for i in 9:
		var a := float(i) / 8.0 * PI
		var p := Vector2(cos(a) * r, sin(a) * r * (1.4 if pointed else 1.0))
		if pointed and i == 4:
			p.y += r * 0.2
		pts.append(Vector3(x + p.x, y, spring + p.y))
	return pts


static func dress(s: TownSolid, h: TownHouse) -> void:
	var fac := str(h.house.get("facility", ""))
	if fac.is_empty() or h.front.is_empty():
		return
	var f: Dictionary = h.front["face"]
	var storey := h.num("storey", 1.0)
	var base := h.num("base", 0.2)
	var door: Vector2i = h.house["door"]
	var y := float((h.house["rect"] as Rect2i).end.y)
	var dx := door.x + 0.5
	match str(h.house.get("style", "")):
		"stone":
			for k in [-2.2, -1.1, 1.1, 2.2]:  # 기둥
				var cx: float = dx + k
				s.box(PackedVector2Array([Vector2(cx - 0.18, y), Vector2(cx + 0.18, y), Vector2(cx + 0.18, y + 0.3), Vector2(cx - 0.18, y + 0.3)]),
					0.0, base + storey * 1.6, TownBrush.shade(h.col("stone"), 1.2), "ashlar")
			s.face(PackedVector3Array([Vector3(dx - 2.6, y + 0.32, base + storey * 1.6), Vector3(dx + 2.6, y + 0.32, base + storey * 1.6),
				Vector3(dx, y + 0.32, base + storey * 2.3)]), TownBrush.shade(h.col("stone"), 1.2), "ashlar", Vector3(0, 1, 0))
			s.decal(f, _front_quad(h, -0.45, 0.45, base, base + 1.2), h.col("door"), "wood")
		"hall":
			s.decal(f, _arch(h, 0.0, base, 1.1, 1.3, false), h.col("plinth"), "ashlar")
			s.decal(f, _arch(h, 0.0, base, 0.9, 1.2, false), h.col("door"), "wood")
			for k in [-1.6, 1.6]:  # 깃발
				s.decal(f, _front_quad(h, k - 0.22, k + 0.22, base + storey * 1.2, base + storey * 2.4), h.col("banner", 0), "wood", true)
		"inn":
			s.decal(f, _arch(h, 0.0, base, 0.9, 1.1, false), h.col("plinth"), "ashlar")
			s.decal(f, _arch(h, 0.0, base, 0.72, 1.0, false), h.col("door"), "wood")
			s.decal(f, _front_quad(h, 0.7, 1.3, base + storey + 0.05, base + storey + 0.45), h.col("cloth"), "wood")  # 간판
			s.decal(f, _front_quad(h, -0.8, -0.62, base + storey * 0.7, base + storey * 0.9), h.col("glass_lit"), "", false)  # 문 옆 등
		"arcade":
			s.decal(f, _front_quad(h, -dx + float((h.house["rect"] as Rect2i).position.x), float((h.house["rect"] as Rect2i).end.x) - dx, base + storey - 0.15, base + storey + 0.05), h.col("awning"), "wood")
			for k in [-3.6, -1.8, 0.0, 1.8, 3.6]:
				s.decal(f, _arch(h, k, base, 1.0, storey - 0.25, false), h.col("plinth"), "ashlar")
				s.decal(f, _arch(h, k, base, 0.82, storey - 0.32, false), h.col("glass_lit") if k == 0.0 else Color(0.08, 0.07, 0.06), "", false)
		"workshop":
			s.decal(f, _front_quad(h, -0.9, 0.9, base, base + 1.3), h.col("plinth"), "ashlar")
			s.decal(f, _front_quad(h, -0.75, 0.75, base, base + 1.2), Color(0.42, 0.2, 0.08), "", false)
			s.decal(f, _front_quad(h, -0.75, 0.75, base + 0.6, base + 1.2), Color(0.08, 0.06, 0.05), "", false)
			var c: Vector2 = h.house["center"]
			for k in [-0.3, 0.3]:  # 큰 굴뚝 둘
				var at := c + Vector2((h.house["size"] as Vector2).x * k, 0)
				s.box(PackedVector2Array([at + Vector2(-0.35, -0.35), at + Vector2(0.35, -0.35), at + Vector2(0.35, 0.35), at + Vector2(-0.35, 0.35)]),
					h.wall_height(), h.wall_height() + 4.2, h.col("brick"), "ashlar", Color(0.08, 0.07, 0.06), "")
		_:
			s.decal(f, _front_quad(h, -0.35, 0.35, base, base + 0.9), h.col("door"), "wood")


## 신전 — 고딕.
static func gothic(s: TownSolid, h: TownHouse) -> void:
	var rc: Rect2i = h.house["rect"]
	var x0 := float(rc.position.x)
	var x1 := float(rc.end.x)
	var y0 := float(rc.position.y)
	var y1 := float(rc.end.y)
	var tw := 4.0
	var storey := h.num("storey", 1.0)
	var hgt := h.wall_height()
	var stone := h.col("stone_dark")
	var slate := h.col("slate", 1)
	var nx0 := x0 + tw - 0.6
	var nx1 := x1 - tw + 0.6
	var xm := (x0 + x1) * 0.5
	var rise := minf((nx1 - nx0) * 0.5 * 1.25, 9.0)
	for p: Array in [[Vector2(nx0, y0), Vector2(nx1, y0), Vector3(0, -1, 0)], [Vector2(nx1, y0), Vector2(nx1, y1), Vector3(1, 0, 0)], [Vector2(nx0, y1), Vector2(nx0, y0), Vector3(-1, 0, 0)]]:
		var a: Vector2 = p[0]
		var b: Vector2 = p[1]
		s.face(TownHouse._quad_v(a, b, 0.0, hgt), stone, "ashlar", p[2])
	s.face(PackedVector3Array([Vector3(nx0 - 0.3, y1 + 0.2, hgt - 0.05), Vector3(xm, y1 + 0.2, hgt + rise), Vector3(xm, y0 - 0.3, hgt + rise), Vector3(nx0 - 0.3, y0 - 0.3, hgt - 0.05)]),
		slate, "slate", Vector3(-1, 0, 1))
	s.face(PackedVector3Array([Vector3(xm, y1 + 0.2, hgt + rise), Vector3(nx1 + 0.3, y1 + 0.2, hgt - 0.05), Vector3(nx1 + 0.3, y0 - 0.3, hgt - 0.05), Vector3(xm, y0 - 0.3, hgt + rise)]),
		slate, "slate", Vector3(1, 0, 1))
	var f := s.face(PackedVector3Array([Vector3(nx0, y1, 0), Vector3(nx1, y1, 0), Vector3(nx1, y1, hgt), Vector3(xm, y1, hgt + rise - 0.1), Vector3(nx0, y1, hgt)]),
		stone, "ashlar", Vector3(0, 1, 0))
	var dx := 0.0
	s.decal(f, _arch(h, dx, 0.0, 2.2, storey * 2.6, true), TownBrush.shade(stone, 1.25), "ashlar")
	s.decal(f, _arch(h, dx, 0.0, 1.6, storey * 2.4, true), h.col("door"), "wood")
	var rose := PackedVector3Array()
	var rz := hgt + 0.6
	for i in 16:
		var a := TAU * i / 16.0
		rose.append(Vector3(xm + cos(a) * 1.25, y1, rz + sin(a) * 1.25))
	s.decal(f, rose, TownBrush.shade(stone, 1.25), "ashlar")
	var inner := PackedVector3Array()
	for i in 16:
		var a := TAU * i / 16.0
		inner.append(Vector3(xm + cos(a) * 0.95, y1, rz + sin(a) * 0.95))
	s.decal(f, inner, h.col("glass_lit").lerp(h.col("banner", 1), 0.45).lerp(stone, 0.3), "", true)
	for k in [-3.4, 3.4]:
		s.decal(f, _arch(h, k, 0.9, 0.9, storey * 2.6, true), TownBrush.shade(stone, 1.2), "ashlar")
		s.decal(f, _arch(h, k, 0.95, 0.66, storey * 2.45, true), h.col("glass"), "", true)
	for tx: float in [x0, x1 - tw]:  # 탑 둘 + 첨탑
		var th := hgt + storey * 3.5
		var base := PackedVector2Array([Vector2(tx, y1 - tw), Vector2(tx + tw, y1 - tw), Vector2(tx + tw, y1), Vector2(tx, y1)])
		var faces := s.box(base, 0.0, th, TownBrush.shade(stone, 1.08), "ashlar", stone, "ashlar")
		var tf: Dictionary = faces[2]
		var tc := tx + tw * 0.5
		for fl in 3:
			var z := 1.2 + fl * 1.9
			s.decal(tf, _tower_arch(tc, y1, z, 0.75, 1.3), TownBrush.shade(stone, 1.25), "ashlar")
			s.decal(tf, _tower_arch(tc, y1, z + 0.05, 0.5, 1.15), h.col("glass") if fl < 2 else Color(0.05, 0.05, 0.05), "", fl < 2)
		var apex := Vector3(tc, y1 - tw * 0.5, th + tw * 1.9)
		var corners := [Vector3(tx - 0.15, y1 - tw - 0.15, th), Vector3(tx + tw + 0.15, y1 - tw - 0.15, th), Vector3(tx + tw + 0.15, y1 + 0.15, th), Vector3(tx - 0.15, y1 + 0.15, th)]
		for i in 4:
			var a: Vector3 = corners[i]
			var b: Vector3 = corners[(i + 1) % 4]
			var mid := (a + b) * 0.5 - Vector3(tc, y1 - tw * 0.5, th)
			s.face(PackedVector3Array([a, b, apex]), h.col("lead"), "lead", Vector3(mid.x, mid.y, 0.6))


static func _tower_arch(cx: float, y: float, z0: float, w: float, ht: float) -> PackedVector3Array:
	var r := w * 0.5
	var spring := z0 + ht - r * 1.4
	var pts := PackedVector3Array([Vector3(cx - r, y, z0), Vector3(cx + r, y, z0)])
	for i in 7:
		var a := float(i) / 6.0 * PI
		pts.append(Vector3(cx + cos(a) * r, y, spring + sin(a) * r * 1.4))
	return pts


## 도서관 — 원형 열람당.
static func rotunda(s: TownSolid, h: TownHouse) -> void:
	var c: Array = h.house["circle"]
	var cx := float(c[0]) + 0.5
	var cy := float(c[1]) + 0.5
	var R := float(c[2]) - 0.3
	var hgt := h.wall_height()
	var storey := h.num("storey", 1.0)
	var stone := h.col("stone", 0)
	var n := 28
	for i in n:  # 둥근 벽 + 아치 창
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector2(cx + cos(a0) * R, cy + sin(a0) * R)
		var p1 := Vector2(cx + cos(a1) * R, cy + sin(a1) * R)
		var am := (a0 + a1) * 0.5
		var f := s.face(TownHouse._quad_v(p0, p1, 0.0, hgt), stone, "ashlar", Vector3(cos(am), sin(am), 0), false)
		if f.is_empty():
			continue
		s.decal(f, TownHouse._quad_v(p0, p1, 0.0, 0.25), h.col("plinth"), "ashlar")
		if i % 2 == 0:
			for fl in 2:
				var z := 0.6 + fl * (storey + 0.3)
				var q0 := p0.lerp(p1, 0.22)
				var q1 := p0.lerp(p1, 0.78)
				s.decal(f, TownHouse._quad_v(q0, q1, z - 0.06, z + 0.9), TownBrush.shade(stone, 1.25), "ashlar")
				s.decal(f, TownHouse._quad_v(p0.lerp(p1, 0.3), p0.lerp(p1, 0.7), z, z + 0.82), h.col("glass_lit") if (i / 2 + fl) % 3 == 0 else h.col("glass"), "", (i / 2 + fl) % 3 != 0)
		s.decal(f, TownHouse._quad_v(p0, p1, hgt - 0.3, hgt), TownBrush.shade(stone, 1.2), "ashlar")
	var lead := h.col("lead")
	var rings := 6
	var dome_h := R * 0.75
	for k in rings:  # 돔(위도 띠 × 경도 조각)
		var t0 := float(k) / rings
		var t1 := float(k + 1) / rings
		var r0 := R * cos(t0 * PI * 0.5) + 0.15 * (1.0 - t0)
		var r1 := R * cos(t1 * PI * 0.5)
		var z0 := hgt + 0.2 + dome_h * sin(t0 * PI * 0.5)
		var z1 := hgt + 0.2 + dome_h * sin(t1 * PI * 0.5)
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
			var tm := (t0 + t1) * 0.5 * PI * 0.5
			var pane := lead.lerp(h.col("glass"), 0.35) if (i + k) % 2 == 0 else lead
			s.face(pts, pane, "lead", Vector3(cos(am) * cos(tm), sin(am) * cos(tm), sin(tm)), true)
	var top := hgt + 0.2 + dome_h
	var lb := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		lb.append(Vector2(cx + cos(a) * 0.5, cy + sin(a) * 0.5))
	var lf := s.box(lb, top - 0.1, top + 0.7, TownBrush.shade(stone, 1.1), "ashlar", lead, "lead")
	for lfi in lf:
		if not lfi.is_empty() and (lfi["n"] as Vector3).z < 0.5:
			s.decal(lfi, lfi["pts"], h.col("glass_lit").lerp(stone, 0.4), "", false)
	var door: Vector2i = h.house["door"]
	var dx := door.x + 0.5
	var fy := cy + R + 0.1
	for k in [-1.1, 1.1]:  # 현관 기둥 + 박공
		s.box(PackedVector2Array([Vector2(dx + k - 0.16, fy), Vector2(dx + k + 0.16, fy), Vector2(dx + k + 0.16, fy + 0.32), Vector2(dx + k - 0.16, fy + 0.32)]),
			0.0, storey * 1.5, TownBrush.shade(stone, 1.3), "ashlar")
	s.face(PackedVector3Array([Vector3(dx - 1.5, fy + 0.34, storey * 1.5), Vector3(dx + 1.5, fy + 0.34, storey * 1.5), Vector3(dx, fy + 0.34, storey * 2.1)]),
		TownBrush.shade(stone, 1.2), "ashlar", Vector3(0, 1, 0))
	var front := PackedVector3Array([Vector3(dx - 0.45, fy + 0.05, 0), Vector3(dx + 0.45, fy + 0.05, 0), Vector3(dx + 0.45, fy + 0.05, 1.1), Vector3(dx - 0.45, fy + 0.05, 1.1)])
	s.face(front, h.col("door"), "wood", Vector3(0, 1, 0))
