extends RefCounted
## 상태이상 그림 기호 1(몸·자연): 핏방울 · 해골 · 불꽃 · 눈꽃 · 얼음 덩이 · 별(기절) · 소용돌이 · 유령(공포) · 눈 · 가린 눈 ·
## 번개 · 땀방울 · 돌 · 짓누르는 추 · 깨진 심장 · 송곳니 · 구더기 · 뼈 · 그릇 · 연기 · 그을음.
## 함수마다 (p, col) — col = 주 색. 좌표는 96×96(가운데 48, 48 — 기호는 반지름 약 32 안).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Sh := preload("res://tools/status_art/Shapes.gd")


static func drop(p: Paint, col: Color) -> void:
	var pts: Array = [Vector2(48, 14)]
	for i in 15:
		var a := -0.25 * PI + i * (1.5 * PI) / 14.0
		pts.append(Vector2(48, 56) + Vector2(cos(a), sin(a)) * 22.0)
	Sh.shape(p, Sh.poly(pts), col)


static func bubbles(p: Paint, col: Color) -> void:  # 독: 방울 + 거품
	drop(p, col)
	for q: Vector3 in [Vector3(70, 26, 7), Vector3(76, 42, 5), Vector3(24, 30, 5)]:
		Sh.shape(p, Sh.circle(Vector2(q.x, q.y), q.z, 14), col.lightened(0.2), 2.0, false)


static func skull(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.circle(Vector2(48, 42), 25, 30, 23), col)
	Sh.shape(p, Sh.poly([Vector2(34, 56), Vector2(62, 56), Vector2(60, 74), Vector2(36, 74)]), col.darkened(0.1), 3.0, false)
	for x: float in [38.0, 58.0]:
		p.fill_poly(Sh.circle(Vector2(x, 44), 7, 16, 8), p.flat(Sh.INK, 0.05))
	p.fill_poly(Sh.poly([Vector2(48, 52), Vector2(44, 59), Vector2(52, 59)]), p.flat(Sh.INK, 0.05))
	for x: float in [41.0, 48.0, 55.0]:
		Ink.line(p, Vector2(x, 64), Vector2(x, 74), 2.0, Sh.INK, 0.9, 0.2)


static func flame(p: Paint, col: Color) -> void:
	var outer := Sh.poly([Vector2(48, 10), Vector2(58, 28), Vector2(70, 24), Vector2(72, 48), Vector2(66, 70), Vector2(48, 80),
		Vector2(30, 70), Vector2(24, 50), Vector2(30, 34), Vector2(38, 40), Vector2(40, 22)])
	Sh.shape(p, outer, col)
	Sh.shape(p, Sh.poly([Vector2(48, 38), Vector2(56, 52), Vector2(58, 66), Vector2(48, 74), Vector2(38, 66), Vector2(40, 52)]), Color("#ffe08a"), 2.0, false)


static func snowflake(p: Paint, col: Color) -> void:
	for i in 3:
		var d := Vector2.from_angle(PI / 2.0 + i * PI / 3.0) * 30.0
		Sh.bar(p, Sh.C - d, Sh.C + d, 5.0, col)
		for s: float in [-1.0, 1.0]:
			for t: float in [0.55, -0.55]:
				var base := Sh.C + d * t
				var out := d.normalized() * signf(t)
				Sh.bar(p, base, base + out.rotated(s * 0.8) * 10.0, 3.0, col)
	Sh.shape(p, Sh.circle(Sh.C, 6, 12), col.lightened(0.3), 2.0, false)


static func ice_block(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(26, 28), Vector2(62, 20), Vector2(72, 34), Vector2(70, 70), Vector2(34, 78), Vector2(24, 64)]), col)
	Ink.line(p, Vector2(30, 32), Vector2(66, 26), 2.0, Color(1, 1, 1), 0.6, 0.3)
	Ink.line(p, Vector2(40, 40), Vector2(52, 62), 2.0, Sh.INK, 0.5, 0.5)
	Ink.line(p, Vector2(52, 62), Vector2(62, 56), 2.0, Sh.INK, 0.5, 0.5)


static func stars(p: Paint, col: Color) -> void:  # 기절: 머리 위를 도는 별
	Ink.path(p, Sh.circle(Vector2(48, 52), 32, 32, 13), 3.5, true, col.darkened(0.25), 0.85, 0.2)
	for q: Vector3 in [Vector3(22, 46, 15), Vector3(52, 34, 17), Vector3(74, 60, 14)]:
		Sh.shape(p, Sh.star(Vector2(q.x, q.y), q.z, q.z * 0.48), col, 3.0)


static func spiral(p: Paint, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 60:
		var t := i / 59.0
		pts.append(Sh.C + Vector2.from_angle(t * TAU * 2.4) * (3.0 + t * 28.0))
	for i in pts.size() - 1:
		Ink.line(p, pts[i], pts[i + 1], 9.0, Sh.INK, 0.95, 0.1)
	for i in pts.size() - 1:
		Ink.line(p, pts[i], pts[i + 1], 5.0, col, 1.0, 0.1)


static func ghost(p: Paint, col: Color) -> void:
	var pts: Array = []
	for i in 13:
		var a := PI + i * PI / 12.0
		pts.append(Vector2(48, 42) + Vector2(cos(a), sin(a)) * 24.0)
	pts.append_array([Vector2(72, 76), Vector2(64, 68), Vector2(56, 78), Vector2(48, 68), Vector2(40, 78), Vector2(32, 68), Vector2(24, 76)])
	Sh.shape(p, Sh.poly(pts), col)
	for x: float in [39.0, 57.0]:
		p.fill_poly(Sh.circle(Vector2(x, 42), 5, 12, 7), p.flat(Sh.INK, 0.05))
	p.fill_poly(Sh.circle(Vector2(48, 58), 6, 14, 8), p.flat(Sh.INK, 0.05))  # 비명


static func eye(p: Paint, col: Color) -> void:
	var lid := Sh.poly([Vector2(14, 48), Vector2(30, 32), Vector2(48, 27), Vector2(66, 32), Vector2(82, 48), Vector2(66, 64), Vector2(48, 69), Vector2(30, 64)])
	Sh.shape(p, lid, Color("#e8dcc8"), 3.0, false)
	Sh.shape(p, Sh.circle(Sh.C, 14, 20), col, 2.0, false)
	p.fill_poly(Sh.circle(Sh.C, 6, 14), p.flat(Sh.INK, 0.05))
	Ink.glow(p, 44, 44, 4, Color(1, 1, 1), 0.8)


static func eye_cross(p: Paint, col: Color) -> void:
	eye(p, col)
	Sh.bar(p, Vector2(20, 76), Vector2(76, 20), 6.0, Color("#b02020"))


static func lightning(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(56, 10), Vector2(26, 52), Vector2(46, 52), Vector2(36, 86), Vector2(72, 40), Vector2(52, 40), Vector2(64, 10)]), col)


static func sweat(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.circle(Vector2(44, 52), 24, 30), Color("#a08a70"), 3.0, false)  # 얼굴
	for x: float in [36.0, 52.0]:
		Ink.line(p, Vector2(x - 4, 50), Vector2(x + 4, 50), 2.5, Sh.INK, 0.9, 0.2)
	Ink.line(p, Vector2(38, 64), Vector2(50, 62), 2.5, Sh.INK, 0.9, 0.4)
	var pts: Array = [Vector2(72, 14)]
	for i in 11:
		var a := -0.25 * PI + i * (1.5 * PI) / 10.0
		pts.append(Vector2(72, 32) + Vector2(cos(a), sin(a)) * 10.0)
	Sh.shape(p, Sh.poly(pts), col, 2.5)


static func stone(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(20, 60), Vector2(26, 34), Vector2(44, 20), Vector2(66, 24), Vector2(78, 44), Vector2(74, 70), Vector2(50, 80), Vector2(28, 76)]), col)
	Ink.line(p, Vector2(40, 34), Vector2(50, 52), 2.0, Sh.INK, 0.7, 0.5)
	Ink.line(p, Vector2(50, 52), Vector2(64, 58), 2.0, Sh.INK, 0.7, 0.5)


static func weight(p: Paint, col: Color) -> void:  # 진압: 위에서 짓누르는 추
	Ink.path(p, Sh.circle(Vector2(48, 22), 10, 20, 8), 5.0, true, Sh.INK, 0.95, 0.2)
	Ink.path(p, Sh.circle(Vector2(48, 22), 10, 20, 8), 3.0, true, col.lightened(0.2), 1.0, 0.2)
	Sh.shape(p, Sh.poly([Vector2(32, 30), Vector2(64, 30), Vector2(76, 66), Vector2(20, 66)]), col)
	Sh.bar(p, Vector2(14, 78), Vector2(82, 78), 5.0, Color("#8a7a60"))
	for x: float in [26.0, 48.0, 70.0]:
		Ink.line(p, Vector2(x - 5, 70), Vector2(x + 5, 74), 2.5, Color("#e8d8b0"), 0.8, 0.2)


static func broken_heart(p: Paint, col: Color) -> void:
	var pts: Array = [Vector2(48, 80)]
	for i in 13:
		var a := PI * 0.85 - i * PI * 1.1 / 12.0
		pts.append(Vector2(34, 36) + Vector2(cos(a), -sin(a)) * 16.0)
	for i in 13:
		var a := PI * 1.05 - i * PI * 1.1 / 12.0
		pts.append(Vector2(62, 36) + Vector2(cos(a), -sin(a)) * 16.0)
	Sh.shape(p, Sh.poly(pts), col)
	for seg: Array in [[Vector2(48, 26), Vector2(42, 42)], [Vector2(42, 42), Vector2(54, 54)], [Vector2(54, 54), Vector2(46, 70)]]:
		Ink.line(p, seg[0], seg[1], 3.5, Sh.INK, 0.95, 0.2)


static func fang(p: Paint, col: Color) -> void:  # 흡혈: 벌린 윗입술 + 송곳니 + 피
	var lip: Array = []
	for i in 15:
		var a := PI + i * PI / 14.0
		lip.append(Vector2(48, 44) + Vector2(cos(a) * 34, sin(a) * 22))
	lip.append_array([Vector2(82, 44), Vector2(66, 50), Vector2(48, 46), Vector2(30, 50), Vector2(14, 44)])
	Sh.shape(p, Sh.poly(lip), col.darkened(0.2))
	for s: float in [-1.0, 1.0]:
		var x := 48 + s * 16
		Sh.shape(p, Sh.poly([Vector2(x - 7, 46), Vector2(x + 7, 46), Vector2(x + 2, 66), Vector2(x - s, 72), Vector2(x - 2, 66)]), Color("#f0e8d8"), 2.5)
	drop_small(p, Vector2(32, 84), col)
	drop_small(p, Vector2(64, 82), col)


static func drop_small(p: Paint, at: Vector2, col: Color) -> void:
	var pts: Array = [at + Vector2(0, -12)]
	for i in 11:
		var a := -0.25 * PI + i * (1.5 * PI) / 10.0
		pts.append(at + Vector2(cos(a), sin(a)) * 7.0)
	Sh.shape(p, Sh.poly(pts), col, 2.0, false)


static func maggot(p: Paint, col: Color) -> void:
	var pts: Array = []
	for i in 7:
		var t := i / 6.0
		pts.append(Vector2(22 + t * 52, 54 - sin(t * PI) * 22))
	for i in pts.size():
		Sh.shape(p, Sh.circle(pts[i], 11 - absf(i - 3) * 1.2, 16), col, 2.5, i == 3)
	p.fill_poly(Sh.circle(pts[6] + Vector2(2, -2), 2.5, 8), p.flat(Sh.INK, 0.05))


static func bone(p: Paint, col: Color) -> void:
	var a := Vector2(26, 70)
	var b := Vector2(70, 26)
	Sh.bar(p, a, b, 12.0, col)
	for e: Vector2 in [a, b]:
		var n := (b - a).normalized().orthogonal()
		for s: float in [-1.0, 1.0]:
			Sh.shape(p, Sh.circle(e + n * s * 8.0 - (b - a).normalized() * (4.0 if e == a else -4.0), 9, 16), col, 2.5, false)


static func bowl(p: Paint, col: Color, steam: bool = false) -> void:
	Sh.shape(p, Sh.poly([Vector2(14, 46), Vector2(82, 46), Vector2(74, 66), Vector2(60, 76), Vector2(36, 76), Vector2(22, 66)]), col)
	Sh.shape(p, Sh.circle(Vector2(48, 46), 34, 30, 8), col.darkened(0.45), 2.5, false)
	if steam:
		for x: float in [36.0, 50.0, 64.0]:
			Ink.line(p, Vector2(x, 36), Vector2(x - 4, 24), 3.0, Color("#e8e0d0"), 0.7, 1.2)
			Ink.line(p, Vector2(x - 4, 24), Vector2(x + 2, 14), 3.0, Color("#e8e0d0"), 0.6, 1.2)
	else:
		Ink.line(p, Vector2(40, 40), Vector2(56, 52), 2.5, Sh.INK, 0.8, 0.6)  # 금 간 빈 그릇


static func cloud(p: Paint, col: Color) -> void:
	for q: Vector3 in [Vector3(30, 56, 16), Vector3(48, 44, 20), Vector3(68, 54, 16), Vector3(50, 62, 16)]:
		Sh.shape(p, Sh.circle(Vector2(q.x, q.y), q.z, 22), col, 2.5, false)


static func puff(p: Paint, col: Color) -> void:  # 그을음
	cloud(p, col)
	for q: Vector2 in [Vector2(28, 30), Vector2(70, 30), Vector2(20, 74), Vector2(76, 72)]:
		p.fill_poly(Sh.circle(q, 3.5, 10), p.flat(Color("#e06020"), 0.1))
