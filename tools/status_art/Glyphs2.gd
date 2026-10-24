extends RefCounted
## 상태이상 그림 기호 2(물건·표식): 사슬 · 자물쇠 · 방패 · 투구 · 칼 · 단검 · 독 묻은 단검 · 날개 장화 · 깨진 방패 · 위/아래 화살 ·
## 조준 · 문양 · 느낌표 · 자석 · 모래시계 · 덫 · 가면 · 엇갈린 칼 · 주먹 · 울림 · 터짐 · 사람 · 장막 · 룬 · 관.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Sh := preload("res://tools/status_art/Shapes.gd")
const G1 := preload("res://tools/status_art/Glyphs.gd")

const STEEL := Color("#9aa0a8")


static func chain(p: Paint, col: Color) -> void:
	for i in 3:
		var c := Vector2(26 + i * 22, 64 - i * 16)
		var ring := Sh.circle(c, 13, 24, 8)
		var rot := PackedVector2Array()
		for q in ring:
			rot.append(c + (q - c).rotated(-0.6))
		Ink.path(p, rot, 9.0, true, Sh.INK, 0.95, 0.1)
		Ink.path(p, rot, 5.0, true, col, 1.0, 0.1)


static func lock(p: Paint, col: Color) -> void:
	var arc := PackedVector2Array()
	for i in 13:
		arc.append(Vector2(48, 40) + Vector2.from_angle(PI + i * PI / 12.0) * 16.0)
	for i in arc.size() - 1:
		Ink.line(p, arc[i], arc[i + 1], 11.0, Sh.INK, 0.95, 0.1)
	for i in arc.size() - 1:
		Ink.line(p, arc[i], arc[i + 1], 6.0, STEEL, 1.0, 0.1)
	Sh.shape(p, Sh.poly([Vector2(24, 40), Vector2(72, 40), Vector2(72, 78), Vector2(24, 78)]), col)
	p.fill_poly(Sh.circle(Vector2(48, 54), 5, 12), p.flat(Sh.INK, 0.05))
	p.fill_poly(Sh.poly([Vector2(46, 56), Vector2(50, 56), Vector2(51, 68), Vector2(45, 68)]), p.flat(Sh.INK, 0.05))


static func shield(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(20, 18), Vector2(48, 12), Vector2(76, 18), Vector2(74, 48), Vector2(64, 68), Vector2(48, 82), Vector2(32, 68), Vector2(22, 48)]), col)
	Ink.line(p, Vector2(48, 16), Vector2(48, 78), 2.5, Sh.INK, 0.6, 0.2)
	Ink.line(p, Vector2(24, 40), Vector2(72, 40), 2.5, Sh.INK, 0.6, 0.2)


static func broken_shield(p: Paint, col: Color) -> void:
	shield(p, col)
	for seg: Array in [[Vector2(52, 12), Vector2(44, 34)], [Vector2(44, 34), Vector2(56, 50)], [Vector2(56, 50), Vector2(46, 80)]]:
		Ink.line(p, seg[0], seg[1], 5.0, Sh.INK, 1.0, 0.2)
	arrow(p, Color("#c84a3a"), false, Vector2(70, 66), 0.55)


static func helmet(p: Paint, col: Color) -> void:
	var pts: Array = []
	for i in 13:
		pts.append(Vector2(48, 54) + Vector2.from_angle(PI + i * PI / 12.0) * 28.0)
	pts.append_array([Vector2(80, 62), Vector2(16, 62)])
	Sh.shape(p, Sh.poly(pts), col)
	Sh.shape(p, Sh.circle(Vector2(48, 40), 7, 14), Color("#ffe8a0"), 2.0, false)  # 광부 등


static func sword(p: Paint, col: Color) -> void:
	_blade(p, Vector2(28, 74), Vector2(72, 18), 15.0, col)
	_hilt(p, Vector2(28, 74), Vector2(72, 18), 26.0)


static func dagger(p: Paint, col: Color) -> void:
	_blade(p, Vector2(32, 70), Vector2(66, 26), 14.0, col)
	_hilt(p, Vector2(32, 70), Vector2(66, 26), 22.0)


## 칼날(손잡이 쪽 a → 끝 b, 너비 w): 가운데 등줄 + 밝은 날.
static func _blade(p: Paint, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var d := (b - a).normalized()
	var n := d.orthogonal() * (w * 0.5)
	var tip := b + d * w * 0.4
	Sh.shape(p, Sh.poly([a + n, b + n, tip, b - n, a - n]), col.lerp(Color.WHITE, 0.25), 3.0, false)
	Ink.line(p, a.lerp(b, 0.05), b, 1.6, col.darkened(0.5), 0.7, 0.2)
	Ink.line(p, a + n * 0.5, b + n * 0.5, 1.6, Color(1, 1, 1), 0.55, 0.2)


## 칼자루(코등이 + 손잡이 + 끝 구슬).
static func _hilt(p: Paint, a: Vector2, b: Vector2, guard: float) -> void:
	var d := (b - a).normalized()
	var n := d.orthogonal()
	Sh.bar(p, a - n * guard * 0.5, a + n * guard * 0.5, 6.0, Color("#c09848"))
	Sh.bar(p, a - d * 3.0, a - d * 15.0, 7.0, Color("#6a4428"))
	Sh.shape(p, Sh.circle(a - d * 19.0, 5.0, 12), Color("#c09848"), 2.0, false)


static func dagger_drop(p: Paint, col: Color) -> void:
	_blade(p, Vector2(28, 66), Vector2(62, 22), 14.0, Color("#c8ccd0"))
	_hilt(p, Vector2(28, 66), Vector2(62, 22), 22.0)
	Ink.line(p, Vector2(40, 52), Vector2(60, 26), 6.0, col, 0.8, 0.3)
	G1.drop_small(p, Vector2(64, 66), col)
	G1.drop_small(p, Vector2(76, 50), col)


static func boot_wing(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(34, 24), Vector2(52, 24), Vector2(52, 60), Vector2(74, 66), Vector2(74, 76), Vector2(30, 76)]), Color("#6a4a30"))
	for i in 3:
		Sh.shape(p, Sh.poly([Vector2(34, 30 + i * 9), Vector2(12, 22 + i * 12), Vector2(16, 30 + i * 12), Vector2(34, 38 + i * 9)]), col, 2.0, false)


## 화살표(위 = 오름, 아래 = 내림). at·scale로 작게 겹쳐 그릴 수 있다.
static func arrow(p: Paint, col: Color, up: bool = true, at: Vector2 = Vector2(48, 48), scale: float = 1.0) -> void:
	var out := PackedVector2Array()
	for q: Vector2 in [Vector2(0, -30), Vector2(22, -6), Vector2(9, -6), Vector2(9, 28), Vector2(-9, 28), Vector2(-9, -6), Vector2(-22, -6)]:
		out.append(at + q * scale)
	Sh.shape(p, out if up else _flip(out, at), col, 3.0 * scale + 0.5)


static func _flip(pts: PackedVector2Array, at: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(Vector2(q.x, 2.0 * at.y - q.y))
	return out


static func crosshair(p: Paint, col: Color) -> void:
	for r: float in [28.0, 14.0]:
		var ring := Sh.circle(Sh.C, r, 32)
		Ink.path(p, ring, 8.0, true, Sh.INK, 0.95, 0.1)
		Ink.path(p, ring, 4.0, true, col, 1.0, 0.1)
	for d: Vector2 in [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]:
		Sh.bar(p, Sh.C + d * 18.0, Sh.C + d * 38.0, 4.0, col)


static func sigil(p: Paint, col: Color) -> void:
	var shapes: Array[PackedVector2Array] = [Sh.circle(Sh.C, 32, 36)]
	for rot: float in [-PI / 2.0, PI / 2.0]:  # 두 삼각형(육각별)
		var tri := PackedVector2Array()
		for k in 3:
			tri.append(Sh.C + Vector2.from_angle(rot + k * TAU / 3.0) * 30.0)
		shapes.append(tri)
	for pts in shapes:
		Ink.path(p, pts, 8.0, true, Sh.INK, 0.95, 0.2)
		Ink.path(p, pts, 4.0, true, col, 1.0, 0.2)
	Ink.glow(p, 48, 48, 30, col, 0.25)


static func exclamation(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(40, 12), Vector2(56, 12), Vector2(52, 60), Vector2(44, 60)]), col)
	Sh.shape(p, Sh.circle(Vector2(48, 74), 8, 16), col)


static func magnet(p: Paint, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		pts.append(Vector2(48, 46) + Vector2.from_angle(PI + i * PI / 16.0) * 22.0)
	for i in pts.size() - 1:
		Ink.line(p, pts[i], pts[i + 1], 18.0, Sh.INK, 0.95, 0.1)
	for i in pts.size() - 1:
		Ink.line(p, pts[i], pts[i + 1], 12.0, col, 1.0, 0.1)
	for x: float in [26.0, 70.0]:
		Sh.bar(p, Vector2(x, 46), Vector2(x, 66), 12.0, col)
		Sh.bar(p, Vector2(x, 66), Vector2(x, 76), 12.0, STEEL)


static func hourglass(p: Paint, col: Color) -> void:
	Sh.bar(p, Vector2(26, 16), Vector2(70, 16), 5.0, Color("#6a4a30"))
	Sh.bar(p, Vector2(26, 80), Vector2(70, 80), 5.0, Color("#6a4a30"))
	Sh.shape(p, Sh.poly([Vector2(30, 20), Vector2(66, 20), Vector2(50, 48), Vector2(66, 76), Vector2(30, 76), Vector2(46, 48)]), Color("#c8d0d8").darkened(0.2), 3.0, false)
	Sh.shape(p, Sh.poly([Vector2(34, 74), Vector2(62, 74), Vector2(48, 58)]), col, 2.0, false)


static func bear_trap(p: Paint, col: Color) -> void:  # 덫: 벌린 쇠 이빨
	var top: Array = []
	var low: Array = []
	for i in 13:
		var a := PI + i * PI / 12.0
		top.append(Vector2(48, 46) + Vector2(cos(a) * 32, sin(a) * 24))
		low.append(Vector2(48, 58) + Vector2(cos(a) * 32, -sin(a) * 24))
	for i in 7:  # 위 이빨(아래로) — 오른쪽 → 왼쪽
		var x := 80.0 - i * (64.0 / 6.0)
		top.append(Vector2(x, 46))
		if i < 6:
			top.append(Vector2(x - 64.0 / 12.0, 56))
	for i in 7:
		var x := 80.0 - i * (64.0 / 6.0)
		low.append(Vector2(x, 58))
		if i < 6:
			low.append(Vector2(x - 64.0 / 12.0, 48))
	Sh.shape(p, Sh.poly(low), col.darkened(0.15), 3.0, false)
	Sh.shape(p, Sh.poly(top), col, 3.0)
	Sh.bar(p, Vector2(14, 52), Vector2(24, 52), 5.0, STEEL)
	Sh.bar(p, Vector2(72, 52), Vector2(82, 52), 5.0, STEEL)


static func mask(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(16, 34), Vector2(48, 28), Vector2(80, 34), Vector2(76, 56), Vector2(56, 62), Vector2(48, 54), Vector2(40, 62), Vector2(20, 56)]), col)
	for x: float in [34.0, 62.0]:
		p.fill_poly(Sh.circle(Vector2(x, 44), 7, 14, 5), p.flat(Sh.INK, 0.05))


static func crossed_swords(p: Paint, col: Color) -> void:
	for s: float in [-1.0, 1.0]:
		var a := Vector2(48 - 26 * s, 76)
		var b := Vector2(48 + 24 * s, 16)
		Sh.bar(p, a.lerp(b, 0.25), b, 6.0, col)
		var n := (b - a).normalized().orthogonal()
		var g := a.lerp(b, 0.25)
		Sh.bar(p, g - n * 9.0, g + n * 9.0, 4.0, Color("#a08040"))
		Sh.bar(p, a, g, 5.0, Color("#5a3a22"))


static func fist(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(26, 34), Vector2(68, 30), Vector2(74, 44), Vector2(72, 62), Vector2(60, 76), Vector2(34, 76), Vector2(24, 60)]), col)
	for i in 3:
		Ink.line(p, Vector2(38 + i * 11, 32), Vector2(38 + i * 11, 48), 2.5, Sh.INK, 0.8, 0.2)
	Ink.line(p, Vector2(26, 52), Vector2(54, 52), 2.5, Sh.INK, 0.8, 0.2)


static func waves(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.circle(Vector2(30, 48), 9, 16), col, 2.5)
	for r: float in [18.0, 30.0, 42.0]:
		var arc := PackedVector2Array()
		for i in 9:
			arc.append(Vector2(30, 48) + Vector2.from_angle(-0.7 + i * 1.4 / 8.0) * r)
		for i in arc.size() - 1:
			Ink.line(p, arc[i], arc[i + 1], 7.0, Sh.INK, 0.9, 0.1)
		for i in arc.size() - 1:
			Ink.line(p, arc[i], arc[i + 1], 3.5, col, 1.0, 0.1)


static func burst(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.star(Sh.C, 38, 18, 9, 0.2), col)
	Sh.shape(p, Sh.star(Sh.C, 18, 9, 7, 0.0), Color("#ffe0a0"), 2.0, false)


static func figure(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.circle(Vector2(48, 28), 12, 18), col)
	Sh.shape(p, Sh.poly([Vector2(32, 46), Vector2(64, 46), Vector2(70, 68), Vector2(61, 68), Vector2(58, 84), Vector2(38, 84), Vector2(35, 68), Vector2(26, 68)]), col)


static func veil(p: Paint, col: Color) -> void:
	var pts: Array = [Vector2(20, 18), Vector2(76, 18)]
	for i in 7:
		pts.append(Vector2(76 - i * 9.3, 74 + (8 if i % 2 == 0 else 0)))
	Sh.shape(p, Sh.poly(pts), col)
	for x: float in [34.0, 48.0, 62.0]:
		Ink.line(p, Vector2(x, 22), Vector2(x - 2, 72), 2.0, Sh.INK, 0.5, 0.6)


static func rune(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(30, 14), Vector2(66, 14), Vector2(74, 48), Vector2(66, 82), Vector2(30, 82), Vector2(22, 48)]), Color("#5a5650"))
	for seg: Array in [[Vector2(48, 24), Vector2(48, 72)], [Vector2(48, 36), Vector2(62, 26)], [Vector2(48, 50), Vector2(34, 40)], [Vector2(48, 60), Vector2(62, 70)]]:
		Ink.line(p, seg[0], seg[1], 6.0, col, 1.0, 0.2)
	Ink.glow(p, 48, 48, 26, col, 0.3)


static func coffin(p: Paint, col: Color) -> void:
	Sh.shape(p, Sh.poly([Vector2(38, 10), Vector2(58, 10), Vector2(70, 30), Vector2(62, 86), Vector2(34, 86), Vector2(26, 30)]), col)
	Sh.bar(p, Vector2(48, 30), Vector2(48, 62), 4.0, Color("#c8b070"))
	Sh.bar(p, Vector2(38, 40), Vector2(58, 40), 4.0, Color("#c8b070"))
