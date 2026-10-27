extends RefCounted
## 도서관 서적 그림의 쪽 배치(1): 미궁 · 소재와 무기 · 상태이상. 함수 하나 = 분야 하나(p, rng).

const B := preload("res://tools/book_art/BookArt.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")


## 미궁에 관하여: 왼쪽 = 둥근 미궁 도면, 오른쪽 = 글 + 층층이 쌓인 층 도표 + 작은 차원문 원.
static func dungeon(p: Paint, rng: RandomNumberGenerator) -> void:
	var l := B.page_rect(-1)
	var r := B.page_rect(1)
	B.script(p, rng, Rect2(l.position, Vector2(l.size.x, 48)), 19.0, 7.0, B.INK, true)
	var c := Vector2(l.get_center().x, l.position.y + 196)
	_labyrinth(p, rng, c, 118.0)
	B.label(p, rng, Vector2(c.x - 30, l.end.y - 4), 5)
	B.script(p, rng, Rect2(r.position, Vector2(r.size.x, 120)), 19.0, 7.0)
	var top := r.position.y + 140
	for i in 7:  # 위로 갈수록 좁아지는 층 띠(아래가 1층)
		var y := top + i * 22.0
		var half := 46.0 + i * 9.0
		var cx := r.position.x + 90
		var band := Paint.poly([Vector2(cx - half, y), Vector2(cx + half, y), Vector2(cx + half + 8, y + 18), Vector2(cx - half - 8, y + 18)])
		B.sketch(p, band, Color(B.RED, 0.10 if i == 6 else 0.0), 5.0 if i % 2 == 0 else 0.0, 30.0, 1.2)
		B.word(p, rng, Vector2(cx + half + 16, y + 13), rng.randi_range(2, 4), 5.4, B.INK)
	B.leader(p, Vector2(r.position.x + 90, top + 6 * 22 + 9), Vector2(r.position.x + 230, top + 40))
	B.circle_chart(p, rng, Vector2(r.position.x + 262, top + 46), 40.0, 2, 16, B.RED)
	_spiral(p, Vector2(r.position.x + 262, top + 46), 22.0, B.SEPIA)
	B.script(p, rng, Rect2(r.position.x, top + 170, r.size.x, r.end.y - top - 170), 19.0, 7.0)


## 소재와 무기에 관하여: 왼쪽 = 글 + 비스듬한 장검(치수선), 오른쪽 = 도끼날·광석 덩어리 + 등급 표 + 글.
static func arms(p: Paint, rng: RandomNumberGenerator) -> void:
	var l := B.page_rect(-1)
	var r := B.page_rect(1)
	B.script(p, rng, Rect2(l.position, Vector2(l.size.x, 64)), 19.0, 7.0, B.INK, true)
	_sword(p, rng, Vector2(l.position.x + 30, l.end.y - 18), Vector2(l.end.x - 20, l.position.y + 96))
	B.label(p, rng, Vector2(l.position.x + 10, l.position.y + 110), 4)
	B.label(p, rng, Vector2(l.end.x - 110, l.end.y - 30), 5)
	_axe(p, Vector2(r.position.x + 78, r.position.y + 62))
	_ore(p, rng, Vector2(r.position.x + 236, r.position.y + 70))
	B.label(p, rng, Vector2(r.position.x + 40, r.position.y + 128), 3)
	B.label(p, rng, Vector2(r.position.x + 205, r.position.y + 128), 4)
	var t := Rect2(r.position.x + 10, r.position.y + 146, r.size.x - 20, 96)  # 등급 표
	Ink.path(p, Paint.rect_poly(t.position.x, t.position.y, t.size.x, t.size.y), 1.2, true, B.SEPIA, 0.75, 0.4)
	for i in range(1, 4):
		var y := t.position.y + t.size.y * i / 4.0
		Ink.line(p, Vector2(t.position.x, y), Vector2(t.end.x, y), 0.9, B.SEPIA, 0.6, 0.4)
	Ink.line(p, Vector2(t.position.x + 92, t.position.y), Vector2(t.position.x + 92, t.end.y), 0.9, B.SEPIA, 0.6, 0.4)
	for i in 4:
		var y := t.position.y + t.size.y * (i + 0.7) / 4.0
		B.word(p, rng, Vector2(t.position.x + 10, y), rng.randi_range(3, 5), 5.4, B.RED if i == 0 else B.INK)
		B.word(p, rng, Vector2(t.position.x + 104, y), rng.randi_range(6, 12), 5.4, B.INK, t.end.x - 8)
	B.script(p, rng, Rect2(r.position.x, t.end.y + 14, r.size.x, r.end.y - t.end.y - 14), 19.0, 7.0)


## 상태이상에 관하여: 왼쪽 = 사람 몸 앞모습(붉은 표식 + 지시선 주석), 오른쪽 = 글 + 둥근 약병·물방울·약초 줄기 + 글.
static func ailments(p: Paint, rng: RandomNumberGenerator) -> void:
	var l := B.page_rect(-1)
	var r := B.page_rect(1)
	var c := Vector2(l.get_center().x, l.position.y + 20)
	_figure(p, c, 300.0)
	for spot: Array in [[Vector2(-16, 92), -1], [Vector2(24, 128), 1], [Vector2(-52, 150), -1], [Vector2(20, 236), 1], [Vector2(0, 26), 1]]:
		var q: Vector2 = c + (spot[0] as Vector2)
		p.fill_poly(B.oval(q, 7, 6, 14), func(_x: int, _y: int) -> Color: return Color(B.RED, 0.45), 1.0, true)
		Ink.path(p, B.oval(q, 8, 7, 14), 1.0, true, B.RED, 0.8, 0.4)
		var side: int = spot[1]
		var to := Vector2(l.position.x + 8 if side < 0 else l.end.x - 60, q.y - 10)
		B.leader(p, q, to + Vector2(0 if side < 0 else -4, 6))
		B.word(p, rng, to + Vector2(-2 if side < 0 else 0, 2), rng.randi_range(3, 5), 5.4, B.INK)
	B.script(p, rng, Rect2(r.position, Vector2(r.size.x, 102)), 19.0, 7.0, B.INK, true)
	var fy := r.position.y + 200
	_flask(p, Vector2(r.position.x + 70, fy))
	for k in 3:
		_drop(p, Vector2(r.position.x + 140 + k * 18, fy + 20 - k * 6), 6.0)
	_herb(p, rng, Vector2(r.position.x + 236, fy + 52), 110.0)
	B.label(p, rng, Vector2(r.position.x + 40, fy + 64), 4)
	B.label(p, rng, Vector2(r.position.x + 214, fy + 64), 3)
	B.script(p, rng, Rect2(r.position.x, fy + 82, r.size.x, r.end.y - fy - 82), 19.0, 7.0)


# ── 그림 부품 ───────────────────────────────────────────

## 둥근 미궁: 겹 고리마다 틈(입구)을 두고 고리 사이를 짧은 벽으로 잇는다. 가운데 붉은 점.
static func _labyrinth(p: Paint, rng: RandomNumberGenerator, c: Vector2, r: float) -> void:
	var rings := 6
	for i in rings:
		var rr := r * (1.0 - float(i) / rings)
		var gap := rng.randf_range(0.0, TAU)
		var n := 64
		var pts := PackedVector2Array()
		for k in n + 1:
			var a := gap + 0.35 + (TAU - 0.7) * k / n
			pts.append(c + Vector2.from_angle(a) * rr)
		Ink.path(p, pts, 2.0 if i == 0 else 1.6, false, B.SEPIA, 0.85, 0.5)
		if i < rings - 1:
			for w in 3:  # 고리 사이 벽
				var a := rng.randf_range(0.0, TAU)
				Ink.line(p, c + Vector2.from_angle(a) * rr, c + Vector2.from_angle(a) * (rr - r / rings), 1.6, B.SEPIA, 0.85, 0.4)
	Ink.hatch(p, B.oval(c, r * 1.08, r * 1.08, 48), 9.0, 35.0, 0.12, 0.8, B.SEPIA)
	p.fill_poly(B.oval(c, 6, 6, 12), func(_x: int, _y: int) -> Color: return Color(B.RED, 0.85))
	for k in 4:  # 바깥 네 방향 표식(십자가 팔)
		var a := PI * 0.5 * k - PI * 0.5
		Ink.line(p, c + Vector2.from_angle(a) * (r + 6), c + Vector2.from_angle(a) * (r + 22), 1.8, B.RED, 0.85, 0.3)


static func _spiral(p: Paint, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 60:
		var t := k / 59.0
		pts.append(c + Vector2.from_angle(t * TAU * 2.5) * r * t)
	Ink.path(p, pts, 1.3, false, col, 0.8, 0.3)


## 장검: 날(가운데 홈) · 날밑 · 감은 손잡이 · 둥근 머리 + 날 옆 치수선.
static func _sword(p: Paint, rng: RandomNumberGenerator, hilt: Vector2, tip: Vector2) -> void:
	var d := (tip - hilt).normalized()
	var n := Vector2(-d.y, d.x)
	var guard := hilt + d * 56.0
	var bw := 11.0
	var blade := Paint.poly([guard + n * bw, tip - d * 26 + n * bw * 0.8, tip, tip - d * 26 - n * bw * 0.8, guard - n * bw])
	B.sketch(p, blade, Color("#8a8070", 0.12), 0.0)
	Ink.hatch(p, Paint.poly([guard - n * bw, tip - d * 26 - n * bw * 0.8, tip, guard]), 4.0, rad_to_deg(-d.angle()) + 70.0, 0.35, 0.8, B.SEPIA)
	Ink.line(p, guard + d * 10, tip - d * 50, 1.0, B.SEPIA, 0.7, 0.3)  # 홈
	B.sketch(p, Paint.poly([guard + n * 34 - d * 5, guard + n * 34 + d * 5, guard - n * 34 + d * 5, guard - n * 34 - d * 5]), Color(0, 0, 0, 0), 3.0, 20.0)
	var grip := Paint.poly([hilt + n * 6 + d * 12, guard + n * 6 - d * 5, guard - n * 6 - d * 5, hilt - n * 6 + d * 12])
	B.sketch(p, grip, Color("#5a3220", 0.15), 0.0)
	for k in 6:
		var q := hilt + d * (16.0 + k * 6.0)
		Ink.line(p, q + n * 6, q - n * 6 + d * 4, 1.0, B.SEPIA, 0.75, 0.2)
	Ink.path(p, B.oval(hilt + d * 4, 9, 9, 14), 1.5, true, B.SEPIA, 0.85, 0.3)
	var off := n * 30.0  # 치수선
	Ink.line(p, guard + off, tip + off, 0.9, B.RED, 0.7, 0.3)
	for e: Vector2 in [guard, tip]:
		Ink.line(p, e + off - n * 6, e + off + n * 6, 0.9, B.RED, 0.7, 0.2)
	B.word(p, rng, guard.lerp(tip, 0.5) + off + n * 10, 3, 5.4, B.RED)


static func _axe(p: Paint, c: Vector2) -> void:
	B.sketch(p, Paint.rect_poly(c.x - 4, c.y - 46, 8, 104), Color("#5a3220", 0.12), 0.0, 0.0, 1.3)
	var head := Paint.poly([c + Vector2(4, -36), c + Vector2(46, -54), c + Vector2(58, -20), c + Vector2(50, 10), c + Vector2(4, -8)])
	B.sketch(p, head, Color("#8a8070", 0.14), 4.0, 110.0)
	Ink.line(p, c + Vector2(46, -54), c + Vector2(50, 10), 1.8, B.SEPIA, 0.85, 0.6)


## 광석 덩어리: 깎인 결정 몇 개(빗금 + 적갈색 옅은 물감).
static func _ore(p: Paint, rng: RandomNumberGenerator, c: Vector2) -> void:
	for k in 5:
		var a := -PI * 0.5 + rng.randf_range(-0.8, 0.8)
		var long := rng.randf_range(34, 58)
		var base := c + Vector2(rng.randf_range(-26, 26), 20)
		var tip := base + Vector2.from_angle(a) * long
		var n := Vector2.from_angle(a + PI * 0.5) * rng.randf_range(8, 13)
		var poly := Paint.poly([base + n, tip + n * 0.4, tip, tip - n * 0.4, base - n])
		B.sketch(p, poly, Color(B.RED, 0.08), 4.5, 60.0 + k * 20.0, 1.3)
	Ink.path(p, B.oval(c + Vector2(0, 24), 46, 10, 24), 1.2, true, B.SEPIA, 0.6, 0.6)


## 사람 몸 앞모습(해부도처럼): 둥근 윤곽 · 가슴·배·무릎 근육 선 · 손·발 · 오른쪽 겹 빗금 그늘.
static func _figure(p: Paint, top: Vector2, h: float) -> void:
	var u := h / 300.0
	var q := func(x: float, y: float) -> Vector2: return top + Vector2(x, y) * u
	var head := B.smooth(Paint.poly([q.call(0, 0), q.call(16, 6), q.call(20, 26), q.call(14, 44), q.call(0, 50), q.call(-14, 44), q.call(-20, 26), q.call(-16, 6)]), 2)
	B.sketch(p, head, Color("#c08a60", 0.12), 0.0, 0.0, 1.4)
	Ink.hatch(p, B.smooth(Paint.poly([q.call(6, 4), q.call(20, 26), q.call(14, 44), q.call(4, 48), q.call(10, 26)]), 1), 3.0, 70.0, 0.45, 0.9, B.SEPIA)
	var body := B.smooth(Paint.poly([q.call(-8, 48), q.call(-12, 58), q.call(-44, 66), q.call(-48, 96), q.call(-38, 132), q.call(-36, 160), q.call(-30, 176),
		q.call(0, 182), q.call(30, 176), q.call(36, 160), q.call(38, 132), q.call(48, 96), q.call(44, 66), q.call(12, 58), q.call(8, 48)]), 2)
	for s: float in [-1.0, 1.0]:
		var arm := B.smooth(Paint.poly([q.call(42 * s, 64), q.call(56 * s, 72), q.call(64 * s, 104), q.call(66 * s, 128), q.call(72 * s, 176),
			q.call(66 * s, 180), q.call(56 * s, 132), q.call(48 * s, 108), q.call(42 * s, 92)]), 2)
		B.sketch(p, arm, Color("#c08a60", 0.10), 0.0, 0.0, 1.3)
		B.sketch(p, B.smooth(Paint.poly([q.call(64 * s, 176), q.call(76 * s, 180), q.call(78 * s, 196), q.call(70 * s, 202), q.call(64 * s, 192)]), 1), Color(0, 0, 0, 0), 0.0, 0.0, 1.1)
		var leg := B.smooth(Paint.poly([q.call(32 * s, 172), q.call(36 * s, 206), q.call(32 * s, 240), q.call(30 * s, 280), q.call(26 * s, 296),
			q.call(12 * s, 296), q.call(12 * s, 278), q.call(10 * s, 240), q.call(6 * s, 206), q.call(2 * s, 182)]), 2)
		B.sketch(p, leg, Color("#c08a60", 0.10), 0.0, 0.0, 1.3)
		B.sketch(p, B.smooth(Paint.poly([q.call(12 * s, 294), q.call(28 * s, 294), q.call(36 * s, 302), q.call(14 * s, 304)]), 1), Color(0, 0, 0, 0), 0.0, 0.0, 1.1)
		Ink.path(p, PackedVector2Array([q.call(14 * s, 236), q.call(22 * s, 232), q.call(30 * s, 238)]), 1.0, false, B.SEPIA, 0.6, 0.3)  # 무릎
		Ink.path(p, PackedVector2Array([q.call(4 * s, 74), q.call(20 * s, 92), q.call(40 * s, 86)]), 1.1, false, B.SEPIA, 0.65, 0.4)  # 가슴
		Ink.path(p, PackedVector2Array([q.call(50 * s, 74), q.call(54 * s, 100)]), 0.9, false, B.SEPIA, 0.5, 0.4)  # 어깨 근육
	B.sketch(p, body, Color("#c08a60", 0.12), 0.0, 0.0, 1.5)
	B.cross(p, B.smooth(Paint.poly([q.call(22, 60), q.call(44, 66), q.call(48, 96), q.call(38, 132), q.call(36, 160), q.call(30, 176), q.call(16, 180), q.call(24, 130), q.call(28, 92)]), 1), 3.6, 70.0)
	Ink.hatch(p, B.smooth(Paint.poly([q.call(56, 72), q.call(64, 104), q.call(66, 128), q.call(72, 176), q.call(66, 180), q.call(60, 120)]), 1), 3.0, 75.0, 0.5, 0.9, B.SEPIA)
	Ink.hatch(p, B.smooth(Paint.poly([q.call(20, 182), q.call(32, 172), q.call(36, 206), q.call(30, 280), q.call(24, 290), q.call(24, 220)]), 1), 3.0, 80.0, 0.5, 0.9, B.SEPIA)
	Ink.line(p, q.call(0, 96), q.call(0, 160), 1.0, B.SEPIA, 0.55, 0.3)  # 배 가운데 선
	for k in 3:  # 배 근육
		var y := 112.0 + k * 16.0
		Ink.line(p, q.call(-14, y), q.call(-2, y + 2), 0.9, B.SEPIA, 0.5, 0.3)
		Ink.line(p, q.call(2, y + 2), q.call(14, y), 0.9, B.SEPIA, 0.5, 0.3)
	Ink.path(p, PackedVector2Array([q.call(-22, 168), q.call(0, 186), q.call(22, 168)]), 1.0, false, B.SEPIA, 0.6, 0.4)  # 골반


## 둥근 약병(목·마개·탁한 초록 약).
static func _flask(p: Paint, c: Vector2) -> void:
	var body := B.oval(c + Vector2(0, 14), 34, 34, 36)
	p.fill_poly(Paint.poly([c + Vector2(-33, 22), c + Vector2(33, 22), c + Vector2(26, 40), c + Vector2(0, 48), c + Vector2(-26, 40)]),
		func(_x: int, _y: int) -> Color: return Color("#5a6a30", 0.22), 1.0, true)
	B.sketch(p, body, Color(0, 0, 0, 0), 0.0, 55.0, 1.6)
	Ink.line(p, c + Vector2(-33, 22), c + Vector2(33, 22), 1.0, B.SEPIA, 0.6, 0.8)
	B.sketch(p, Paint.rect_poly(c.x - 9, c.y - 46, 18, 28), Color(0, 0, 0, 0), 0.0, 55.0, 1.4)
	B.sketch(p, Paint.rect_poly(c.x - 12, c.y - 58, 24, 13), Color("#5a3220", 0.2), 3.0, 30.0, 1.3)
	Ink.line(p, c + Vector2(-18, -2), c + Vector2(-24, 18), 2.0, Color("#f0e2c0"), 0.5, 0.3)  # 유리 빛


static func _drop(p: Paint, c: Vector2, s: float) -> void:
	var poly := Paint.poly([c + Vector2(0, -s * 1.8), c + Vector2(s * 0.8, 0), c + Vector2(0, s), c + Vector2(-s * 0.8, 0)])
	B.sketch(p, poly, Color("#5a6a30", 0.3), 0.0, 55.0, 1.1)


## 약초 줄기: 휘는 줄기 + 어긋나는 잎(잎맥 하나).
static func _herb(p: Paint, rng: RandomNumberGenerator, base: Vector2, h: float) -> void:
	var prev := base
	var pts: Array[Vector2] = []
	for k in 12:
		var t := (k + 1) / 12.0
		var q := base + Vector2(sin(t * 2.2) * 18.0, -h * t)
		Ink.line(p, prev, q, 1.6 * (1.0 - t * 0.5), B.SEPIA, 0.85, 0.3)
		pts.append(q)
		prev = q
	for k in range(1, 11, 2):
		var at := pts[k]
		var side := -1.0 if k % 4 == 1 else 1.0
		var tip := at + Vector2(side * rng.randf_range(26, 36), rng.randf_range(-14, -4))
		var mid := at.lerp(tip, 0.5)
		var n := (tip - at).normalized().orthogonal() * 7.0
		var leaf := Paint.poly([at, mid + n, tip, mid - n])
		B.sketch(p, leaf, Color("#5a6a30", 0.18), 0.0, 55.0, 1.1)
		Ink.line(p, at, tip, 0.8, B.SEPIA, 0.5, 0.2)
