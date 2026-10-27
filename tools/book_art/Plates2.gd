extends RefCounted
## 도서관 서적 그림의 쪽 배치(2): 몬스터와 정수 · 생존과 야영 · 도시와 탐험가. 함수 하나 = 분야 하나(p, rng).

const B := preload("res://tools/book_art/BookArt.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")


## 몬스터와 정수에 관하여: 왼쪽 = 고블린 머리 습작 + 주석, 오른쪽 = 빛나는 정수 구슬 + 일곱 빛깔 고리 도표 + 글.
static func monsters(p: Paint, rng: RandomNumberGenerator) -> void:
	var l := B.page_rect(-1)
	var r := B.page_rect(1)
	B.script(p, rng, Rect2(l.position, Vector2(l.size.x, 32)), 19.0, 7.0, B.INK, true, false)
	var hc := Vector2(l.get_center().x, l.position.y + 150)
	_goblin_head(p, hc, 1.0)
	B.leader(p, hc + Vector2(-70, -40), Vector2(l.position.x + 6, l.position.y + 80))
	B.leader(p, hc + Vector2(30, 46), Vector2(l.end.x - 50, l.position.y + 262))
	B.word(p, rng, Vector2(l.position.x + 4, l.position.y + 76), 4, 5.4, B.INK)
	B.word(p, rng, Vector2(l.end.x - 60, l.position.y + 276), 4, 5.4, B.INK)
	B.script(p, rng, Rect2(l.position.x, l.position.y + 286, l.size.x, l.end.y - l.position.y - 286), 19.0, 7.0)
	var oc := Vector2(r.position.x + 92, r.position.y + 92)
	_essence(p, rng, oc, 44.0)
	var wc := Vector2(r.end.x - 72, r.position.y + 84)
	B.circle_chart(p, rng, wc, 64.0, 3, 28)
	var cols := ["#9a2a1a", "#c07a20", "#b8a030", "#4a7a3a", "#2a5a8a", "#5a3a7a", "#e8e0d0"]  # 정수 빛깔
	for i in cols.size():
		var q := wc + Vector2.from_angle(TAU * i / cols.size() - PI * 0.5) * 42.0
		var col := Color(cols[i])
		p.fill_poly(B.oval(q, 7, 7, 14), func(_x: int, _y: int) -> Color: return Color(col, 0.6), 1.0, true)
		Ink.path(p, B.oval(q, 7.5, 7.5, 14), 1.0, true, B.SEPIA, 0.8, 0.2)
	B.leader(p, oc + Vector2(48, 0), wc + Vector2(-66, 4))
	B.script(p, rng, Rect2(r.position.x, r.position.y + 176, r.size.x, r.end.y - r.position.y - 176), 19.0, 7.0, B.INK, true)


## 생존과 야영에 관하여: 왼쪽 = 천막 + 돌 두른 모닥불 + 글, 오른쪽 = 글 + 버섯 셋(하나는 붉은 ×) · 횃불 + 글.
static func survival(p: Paint, rng: RandomNumberGenerator) -> void:
	var l := B.page_rect(-1)
	var r := B.page_rect(1)
	var base := Vector2(l.get_center().x + 30, l.position.y + 210)
	_tent(p, Vector2(l.position.x + 70, l.position.y + 140))
	_campfire(p, rng, base)
	B.label(p, rng, Vector2(base.x - 30, base.y + 46), 4)
	B.script(p, rng, Rect2(l.position.x, l.position.y + 270, l.size.x, l.end.y - l.position.y - 270), 19.0, 7.0)
	B.script(p, rng, Rect2(r.position, Vector2(r.size.x, 100)), 19.0, 7.0, B.INK, true)
	var my := r.position.y + 196
	for i in 3:
		var at := Vector2(r.position.x + 40 + i * 74, my)
		_mushroom(p, rng, at, 1.0 - i * 0.12, i == 1)
		B.word(p, rng, at + Vector2(-16, 26), rng.randi_range(3, 4), 5.4, B.RED if i == 1 else B.INK)
	_torch(p, Vector2(r.end.x - 30, my + 20))
	B.script(p, rng, Rect2(r.position.x, my + 44, r.size.x, r.end.y - my - 44), 19.0, 7.0)


## 도시와 탐험가에 관하여: 글이 많은 기록부 — 왼쪽 = 글만(두 단락), 오른쪽 = 방패 문장 + 장부 칸 + 서명 + 붉은 밀랍 봉인.
static func society(p: Paint, rng: RandomNumberGenerator) -> void:
	var l := B.page_rect(-1)
	var r := B.page_rect(1)
	B.script(p, rng, Rect2(l.position, Vector2(l.size.x, 150)), 19.0, 7.0, B.INK, true)
	B.script(p, rng, Rect2(l.position.x, l.position.y + 168, l.size.x, l.size.y - 168), 19.0, 7.0, B.INK, true)
	var sc := Vector2(r.get_center().x, r.position.y + 54)
	_shield(p, sc)
	var t := Rect2(r.position.x, r.position.y + 124, r.size.x, 132)  # 장부: 이름 · 날짜 · 금액
	for i in 7:
		var y := t.position.y + i * 19.0
		Ink.line(p, Vector2(t.position.x, y + 4), Vector2(t.end.x, y + 4), 0.8, B.SEPIA, 0.4, 0.5)
		B.word(p, rng, Vector2(t.position.x + 4, y), rng.randi_range(4, 7), 5.4, B.INK, t.position.x + 160)
		B.word(p, rng, Vector2(t.position.x + 176, y), 3, 5.4, B.INK)
		B.word(p, rng, Vector2(t.end.x - 50, y), rng.randi_range(2, 4), 5.4, B.RED)
	for x: float in [t.position.x + 168, t.end.x - 58]:
		Ink.line(p, Vector2(x, t.position.y - 14), Vector2(x, t.end.y - 6), 0.8, B.SEPIA, 0.45, 0.4)
	B.script(p, rng, Rect2(r.position.x, t.end.y + 6, r.size.x, 52), 19.0, 7.0)
	var sg := Vector2(r.position.x + 30, r.end.y - 6)  # 서명
	var prev := sg
	for k in 14:
		var q := sg + Vector2(k * 9.0, sin(k * 1.7) * 7.0 - k * 0.6)
		Ink.line(p, prev, q, 1.5, B.INK, 0.85, 0.3)
		prev = q
	_seal(p, rng, Vector2(r.end.x - 52, r.end.y - 18))


# ── 그림 부품 ───────────────────────────────────────────

## 고블린 머리(앞모습 습작): 아래로 처진 긴 귀 · 무거운 눈두덩 · 매부리코 · 들쭉날쭉한 이빨 · 주름 · 목 + 오른쪽 겹 빗금 그늘.
static func _goblin_head(p: Paint, c: Vector2, s: float) -> void:
	var q := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	Ink.line(p, q.call(-20, 50), q.call(-24, 96), 1.8, B.SEPIA, 0.9, 0.5)  # 목
	Ink.line(p, q.call(20, 50), q.call(26, 96), 1.8, B.SEPIA, 0.9, 0.5)
	Ink.hatch(p, Paint.poly([q.call(6, 54), q.call(20, 50), q.call(26, 96), q.call(6, 96)]), 3.5, 70.0, 0.5, 1.0, B.SEPIA)
	Ink.path(p, Paint.poly([q.call(-64, 104), q.call(-24, 92), q.call(0, 98), q.call(26, 92), q.call(70, 106)]), 1.6, false, B.SEPIA, 0.8, 0.8)
	for side: float in [-1.0, 1.0]:
		var ear := B.smooth(Paint.poly([q.call(42 * side, -30), q.call(92 * side, -46), q.call(132 * side, -40), q.call(98 * side, -22), q.call(70 * side, 0), q.call(46 * side, 10)]), 2)
		B.sketch(p, ear, Color("#6a7a40", 0.16), 0.0, 0.0, 1.5)
		Ink.path(p, B.smooth(Paint.poly([q.call(52 * side, -20), q.call(90 * side, -36), q.call(112 * side, -36), q.call(80 * side, -16), q.call(56 * side, -2)]), 2), 1.0, true, B.SEPIA, 0.6, 0.5)
		B.cross(p, B.smooth(Paint.poly([q.call(46 * side, -6), q.call(74 * side, -14), q.call(100 * side, -22), q.call(70 * side, 0), q.call(46 * side, 10)]), 1), 3.5, 40.0 if side > 0 else 120.0)
		Ink.line(p, q.call(104 * side, -40), q.call(112 * side, -33), 1.6, B.SEPIA, 0.9, 0.2)  # 귀 끝 홈
	var head := B.smooth(Paint.poly([q.call(0, -66), q.call(30, -62), q.call(46, -36), q.call(52, -8), q.call(42, 20), q.call(26, 46), q.call(6, 64),
		q.call(-6, 64), q.call(-26, 46), q.call(-42, 20), q.call(-52, -8), q.call(-46, -36), q.call(-30, -62)]), 2)
	B.sketch(p, head, Color("#6a7a40", 0.14), 0.0, 0.0, 1.8)
	B.cross(p, B.smooth(Paint.poly([q.call(22, -62), q.call(46, -36), q.call(52, -8), q.call(42, 20), q.call(26, 46), q.call(10, 62), q.call(24, 20), q.call(30, -20)]), 1), 3.2, 60.0)
	Ink.hatch(p, B.smooth(Paint.poly([q.call(-24, 48), q.call(-4, 60), q.call(10, 58), q.call(-8, 52)]), 1), 2.8, 20.0, 0.5, 0.9, B.SEPIA)
	for k in 3:  # 이마 주름
		var y := -50.0 + k * 8.0
		Ink.path(p, PackedVector2Array([q.call(-18 + k * 3, y + 3), q.call(0, y), q.call(18 - k * 3, y + 3)]), 1.1, false, B.SEPIA, 0.6, 0.4)
	for side: float in [-1.0, 1.0]:
		var brow := Paint.poly([q.call(4 * side, -18), q.call(20 * side, -30), q.call(40 * side, -28), q.call(38 * side, -22), q.call(20 * side, -22), q.call(6 * side, -12)])
		B.sketch(p, brow, Color(B.SEPIA, 0.5), 2.5, 30.0, 1.2)
		Ink.hatch(p, Paint.poly([q.call(8 * side, -14), q.call(36 * side, -22), q.call(34 * side, -10), q.call(10 * side, -6)]), 2.6, 80.0, 0.45, 0.9, B.SEPIA)  # 눈구멍 그늘
		var eye := Paint.poly([q.call(10 * side, -9), q.call(20 * side, -14), q.call(32 * side, -11), q.call(22 * side, -5)])
		p.fill_poly(eye, func(_x: int, _y: int) -> Color: return Color("#e8d8a0", 0.85))
		Ink.path(p, eye, 1.3, true, B.SEPIA, 0.9, 0.2)
		p.fill_poly(B.oval(q.call(21 * side, -9.5), 3.2 * s, 3.2 * s, 10), func(_x: int, _y: int) -> Color: return Color(B.INK, 0.95))
		Ink.path(p, PackedVector2Array([q.call(10 * side, 6), q.call(22 * side, 16), q.call(30 * side, 30)]), 1.2, false, B.SEPIA, 0.7, 0.5)  # 볼 주름
	Ink.path(p, PackedVector2Array([q.call(-3, -12), q.call(2, 2), q.call(10, 14), q.call(6, 20), q.call(-4, 19), q.call(-10, 14)]), 1.8, false, B.SEPIA, 0.9, 0.4)  # 매부리코
	Ink.hatch(p, Paint.poly([q.call(2, -6), q.call(10, 14), q.call(6, 20), q.call(0, 12)]), 2.4, 60.0, 0.5, 0.9, B.SEPIA)
	for side: float in [-1.0, 1.0]:
		p.fill_poly(B.oval(q.call(5 * side - 1, 17), 2.0 * s, 1.4 * s, 8), func(_x: int, _y: int) -> Color: return Color(B.INK, 0.9))
	var mouth := B.smooth(Paint.poly([q.call(-34, 28), q.call(0, 33), q.call(34, 28), q.call(20, 42), q.call(0, 46), q.call(-20, 42)]), 1)
	p.fill_poly(mouth, func(_x: int, _y: int) -> Color: return Color("#2a120a", 0.8))
	Ink.path(p, mouth, 1.6, true, B.SEPIA, 0.9, 0.3)
	var tx := -28.0
	var k := 0
	while tx < 26.0:  # 들쭉날쭉한 윗니 · 아랫니 두 개
		var tw := 4.0 + float((k * 7) % 4)
		var tooth := Paint.poly([q.call(tx, 29 + absf(tx) * 0.1), q.call(tx + tw, 29 + absf(tx + tw) * 0.1), q.call(tx + tw * 0.5, 37 - float(k % 2) * 2.0)])
		p.fill_poly(tooth, func(_x: int, _y: int) -> Color: return Color("#ecdcb4", 0.95))
		Ink.path(p, tooth, 0.9, true, B.SEPIA, 0.8, 0.1)
		tx += tw + 1.0
		k += 1
	for side: float in [-1.0, 1.0]:
		var fang := Paint.poly([q.call(14 * side, 42), q.call(20 * side, 41), q.call(18 * side, 30)])
		p.fill_poly(fang, func(_x: int, _y: int) -> Color: return Color("#ecdcb4", 0.95))
		Ink.path(p, fang, 1.0, true, B.SEPIA, 0.85, 0.1)


## 정수 구슬: 둥근 테 + 퍼지는 빛살 + 가운데 붉은 빛 물감.
static func _essence(p: Paint, rng: RandomNumberGenerator, c: Vector2, r: float) -> void:
	p.fill_poly(B.oval(c, r, r, 40), func(x: int, y: int) -> Color:
		var d := Vector2(x - c.x, y - c.y).length() / r
		return Color(B.RED.lerp(Color("#c06030"), 1.0 - d), 0.7 * (1.0 - d * d) + 0.1), 1.0, true)
	B.sketch(p, B.oval(c, r, r, 40), Color(0, 0, 0, 0), 0.0, 55.0, 1.8)
	Ink.hatch(p, Paint.poly([c + Vector2(r * 0.2, -r * 0.98), c + Vector2(r, 0), c + Vector2(r * 0.2, r * 0.98), c + Vector2(r * 0.55, 0)]), 3.0, 60.0, 0.45, 0.9, B.SEPIA)
	var arc := PackedVector2Array()
	for k in 9:  # 왼쪽 위 빛 받은 곡선
		arc.append(c + Vector2.from_angle(PI * 1.05 + k * 0.08) * r * 0.7)
	Ink.path(p, arc, 2.2, false, Color("#f4e8cc"), 0.8, 0.2)
	for k in 20:
		var a := TAU * k / 20 + rng.randf_range(-0.05, 0.05)
		var long := r * (1.25 + (0.45 if k % 2 == 0 else 0.15))
		Ink.line(p, c + Vector2.from_angle(a) * r * 1.1, c + Vector2.from_angle(a) * long, 1.0, B.RED, 0.6, 0.3)


static func _tent(p: Paint, c: Vector2) -> void:
	var tent := Paint.poly([c + Vector2(0, -56), c + Vector2(62, 30), c + Vector2(-62, 30)])
	B.sketch(p, tent, Color("#8a7050", 0.1), 0.0, 55.0, 1.6)
	Ink.hatch(p, Paint.poly([c + Vector2(0, -56), c + Vector2(62, 30), c + Vector2(10, 30)]), 4.5, 75.0, 0.35, 0.8, B.SEPIA)
	B.sketch(p, Paint.poly([c + Vector2(0, -10), c + Vector2(16, 30), c + Vector2(-16, 30)]), Color(B.INK, 0.4), 0.0, 55.0, 1.2)
	Ink.line(p, c + Vector2(0, -56), c + Vector2(0, -70), 1.4, B.SEPIA, 0.8, 0.2)
	for s: float in [-1.0, 1.0]:
		Ink.line(p, c + Vector2(30 * s, -12), c + Vector2(86 * s, 34), 0.9, B.SEPIA, 0.5, 0.3)  # 줄
	Ink.line(p, c + Vector2(-90, 32), c + Vector2(90, 32), 1.0, B.SEPIA, 0.5, 1.0)


## 모닥불: 돌 고리 · 엇갈린 장작 · 적갈색 불꽃 혀 + 연기 몇 줄.
static func _campfire(p: Paint, rng: RandomNumberGenerator, c: Vector2) -> void:
	for k in 9:
		var a := TAU * k / 9
		var q := c + Vector2(cos(a) * 58, sin(a) * 20 + 14)
		B.sketch(p, B.oval(q, 12, 8, 12), Color("#6a6050", 0.12), 3.5 if sin(a) > 0 else 0.0, 50.0, 1.3)
	for s: float in [-1.0, 1.0]:
		var wood := Paint.poly([c + Vector2(-44 * s, 20), c + Vector2(30 * s, -4), c + Vector2(34 * s, 6), c + Vector2(-40 * s, 30)])
		B.sketch(p, wood, Color("#5a3220", 0.15), 4.0, 80.0, 1.4)
	for k in 5:
		var x := c.x + (k - 2) * 12.0
		var h := 70.0 - absf(k - 2) * 16.0
		var flame := B.smooth(Paint.poly([Vector2(x - 11, c.y + 6), Vector2(x - 9, c.y - h * 0.4), Vector2(x - 2, c.y - h * 0.7), Vector2(x + rng.randf_range(-6, 6), c.y - h), Vector2(x + 6, c.y - h * 0.6), Vector2(x + 10, c.y - h * 0.3), Vector2(x + 11, c.y + 6)]), 1)
		B.sketch(p, flame, Color(B.RED, 0.16), 0.0, 55.0, 1.2, B.RED)
	for k in 3:
		var prev := c + Vector2(k * 10 - 10, -76)
		for i in 8:
			var q := prev + Vector2(sin(i * 0.9 + k) * 5.0, -9)
			Ink.line(p, prev, q, 1.0, B.SEPIA, 0.35, 0.3)
			prev = q


## 버섯: 갓 · 대 · 갓 밑 주름. bad = 먹지 말 것(붉은 ×).
static func _mushroom(p: Paint, rng: RandomNumberGenerator, at: Vector2, s: float, bad: bool) -> void:
	var stem := Paint.poly([at + Vector2(-6, 0) * s, at + Vector2(-5, -34) * s, at + Vector2(5, -34) * s, at + Vector2(7, 0) * s])
	B.sketch(p, stem, Color(0, 0, 0, 0), 0.0, 55.0, 1.3)
	var cap := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		cap.append(at + Vector2(cos(a) * 26, sin(a) * 22 - 32) * s)
	B.sketch(p, cap, Color(B.RED if bad else Color("#8a6a40"), 0.16), 4.0, 120.0, 1.4)
	for k in 5:
		var x := (-18.0 + k * 9.0) * s
		Ink.line(p, at + Vector2(x, -32 * s), at + Vector2(x * 0.4, -36 * s), 0.8, B.SEPIA, 0.5, 0.2)
	if bad:
		for k in 4:
			var q := at + Vector2(rng.randf_range(-14, 14), rng.randf_range(-48, -40)) * s
			Ink.path(p, B.oval(q, 2.5, 2.5, 8), 1.0, true, B.SEPIA, 0.7, 0.1)
		Ink.line(p, at + Vector2(22, -70) * s, at + Vector2(40, -52) * s, 2.0, B.RED, 0.9, 0.3)
		Ink.line(p, at + Vector2(40, -70) * s, at + Vector2(22, -52) * s, 2.0, B.RED, 0.9, 0.3)


static func _torch(p: Paint, base: Vector2) -> void:
	B.sketch(p, Paint.poly([base + Vector2(-4, 0), base + Vector2(-6, -76), base + Vector2(6, -76), base + Vector2(4, 0)]), Color("#5a3220", 0.15), 0.0, 55.0, 1.3)
	B.sketch(p, Paint.rect_poly(base.x - 9, base.y - 90, 18, 16), Color("#5a3220", 0.2), 3.0, 30.0, 1.3)
	B.sketch(p, Paint.poly([base + Vector2(-10, -92), base + Vector2(-4, -116), base + Vector2(2, -132), base + Vector2(8, -112), base + Vector2(10, -92)]), Color(B.RED, 0.18), 0.0, 55.0, 1.2, B.RED)


## 방패 문장: 방패꼴 + 가운데 세로띠 + 탑(도시) 표.
static func _shield(p: Paint, c: Vector2) -> void:
	var sh := Paint.poly([c + Vector2(-40, -44), c + Vector2(40, -44), c + Vector2(40, 0), c + Vector2(24, 30), c + Vector2(0, 46), c + Vector2(-24, 30), c + Vector2(-40, 0)])
	B.sketch(p, sh, Color(B.RED, 0.08), 0.0, 55.0, 2.0)
	Ink.hatch(p, Paint.poly([c + Vector2(0, -44), c + Vector2(40, -44), c + Vector2(40, 0), c + Vector2(24, 30), c + Vector2(0, 46)]), 4.0, 90.0, 0.3, 0.8, B.SEPIA)
	var tower := Paint.poly([c + Vector2(-14, 24), c + Vector2(-12, -14), c + Vector2(-16, -14), c + Vector2(-16, -28), c + Vector2(-8, -28), c + Vector2(-8, -22),
		c + Vector2(-3, -22), c + Vector2(-3, -28), c + Vector2(3, -28), c + Vector2(3, -22), c + Vector2(8, -22), c + Vector2(8, -28), c + Vector2(16, -28),
		c + Vector2(16, -14), c + Vector2(12, -14), c + Vector2(14, 24)])
	B.sketch(p, tower, Color("#d8c39a", 0.8), 0.0, 55.0, 1.4)
	B.sketch(p, Paint.arch_poly(c.x - 5, c.y + 6, 10, 18), Color(B.INK, 0.5), 0.0, 55.0, 1.0)
	for s: float in [-1.0, 1.0]:  # 양옆 잎 장식
		var prev := c + Vector2(44 * s, 20)
		for k in 6:
			var q := c + Vector2((48 + k * 2) * s, 14 - k * 10)
			Ink.line(p, prev, q, 1.2, B.SEPIA, 0.75, 0.3)
			Ink.line(p, q, q + Vector2(9 * s, -4), 1.0, B.SEPIA, 0.6, 0.2)
			prev = q


## 붉은 밀랍 봉인: 울퉁불퉁한 덩어리 + 찍힌 고리 + 늘어진 끈.
static func _seal(p: Paint, rng: RandomNumberGenerator, c: Vector2) -> void:
	for s: float in [-1.0, 1.0]:
		var ribbon := Paint.poly([c + Vector2(6 * s, 10), c + Vector2(20 * s, 44), c + Vector2(12 * s, 40), c + Vector2(6 * s, 48), c + Vector2(-2 * s, 14)])
		B.sketch(p, ribbon, Color("#7a6a40", 0.35), 0.0, 55.0, 1.1)
	var blob := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24
		blob.append(c + Vector2.from_angle(a) * (26.0 + rng.randf_range(-3.0, 4.0)))
	p.fill_poly(blob, func(x: int, y: int) -> Color:
		var d := Vector2(x - c.x, y - c.y)
		var lit := clampf(0.5 - (d.x + d.y) / 60.0, 0.0, 1.0)
		return p.vary(Color("#6a1a10").lerp(Color("#b04030"), lit * 0.6), x, y, 0.1))
	Ink.path(p, blob, 1.4, true, Color("#2a0806"), 0.8, 0.4)
	Ink.path(p, B.oval(c, 15, 15, 24), 1.6, true, Color("#3a0c08"), 0.7, 0.3)
	Ink.path(p, B.oval(c, 9, 9, 18), 1.2, true, Color("#3a0c08"), 0.6, 0.3)
	Ink.line(p, c + Vector2(-12, -14), c + Vector2(-4, -20), 2.0, Color("#e09080"), 0.5, 0.2)
