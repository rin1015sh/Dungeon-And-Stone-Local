extends RefCounted
## 도서관 서적 그림(CT57): 어두운 책상 위에 펼친 낡은 책 한 권(960×540). 분야마다 쪽 위의 그림·글 배치가 다르다(Plates·Plates2).
## 글은 읽히지 않는 필사체 낙서(실제 내용은 아래 대화창 글) — 느낌만 살린다. 잉크는 갈색·적갈색, 종이는 바랜 양피지.
## 책은 화면 위쪽에(아래 대화창 128/720에 가리지 않게).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

const W := 960
const H := 540
const SPINE := 480.0
const TOP := 34.0       ## 쪽 위 끝
const BOTTOM := 432.0   ## 쪽 아래 끝
const OUTER := 92.0     ## 왼쪽 쪽 바깥 끝(오른쪽은 대칭)
const BOW := 10.0       ## 등 쪽으로 쪽 위·아래 끝이 휘어 내려가는 정도
const PAPER := Color("#d8c39a")
const INK := Color("#2c170c")    ## 갈색 잉크(글)
const RED := Color("#7a2a1a")    ## 적갈색 잉크(머리글자·표식)
const SEPIA := Color("#3e2214")  ## 그림 선


## 쪽 안쪽 칸(여백 뺀 곳). side = -1 왼쪽 쪽 · 1 오른쪽 쪽.
static func page_rect(side: int) -> Rect2:
	var x0 := OUTER + 34.0 if side < 0 else SPINE + 30.0
	var x1 := SPINE - 30.0 if side < 0 else W - OUTER - 34.0
	return Rect2(x0, TOP + 34.0, x1 - x0, BOTTOM - TOP - 64.0)


## plate = 쪽 배치 함수(Plates·Plates2의 static 함수 이름 fn을 script에서 부른다).
static func paint(script: Script, fn: String, seed_value: int) -> Paint:
	var p := Paint.new(W, H, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	desk(p, rng)
	book(p, rng)
	script.call(fn, p, rng)
	age(p, rng)
	Ink.glow(p, 300, 120, 560.0, Color("#ffb060"), 0.12, false, 0.7)  # 왼쪽 위 촛불 빛
	Ink.grade(p, 0.06, 1.05, Color("#120a06"), Color("#ffe8c0"), 0.08)
	Ink.finish(p, 0.026, 0.66)
	return p


## 책상: 어두운 호두나무 널판(가로 결) + 왼쪽 위 촛불 빛 웅덩이.
static func desk(p: Paint, rng: RandomNumberGenerator) -> void:
	var rows := 6
	for k in rows:
		var y0 := -10.0 + (H + 20.0) * k / rows
		var y1 := -10.0 + (H + 20.0) * (k + 1) / rows
		var c := Color("#2e1d12").lerp(Color("#3c2616") if k % 2 == 0 else Color("#24160c"), rng.randf_range(0.2, 0.8))
		p.fill_rect(0, y0, W, y1 - y0, func(x: int, y: int) -> Color:
			var g := p.nz("hs", x, int(y * 0.5)) * 0.6 + p.nz("hi", x, y) * 0.4
			return p.vary(c.lerp(Color("#140c06"), clampf((g - 0.5) * 0.8, 0.0, 0.45)), x, y, 0.12))
		Ink.line(p, Vector2(0, y1), Vector2(W, y1), 2.0, Color("#0c0703"), 0.8, 0.6)
	for k in 10:
		var a := Vector2(rng.randf_range(0, W), rng.randf_range(0, H))
		Ink.line(p, a, a + Vector2.from_angle(rng.randf_range(-0.2, 0.2)) * rng.randf_range(30, 90), 1.0, Color("#b08458"), 0.12, 0.4)
	Ink.glow(p, 260, 90, 620.0, Color("#ff9a48"), 0.2, true, 0.75)


## 펼친 책: 그림자 · 가죽 표지 테 · 쪽 묶음 두께 · 두 쪽(바랜 종이, 등 쪽 그늘, 가장자리 탐).
static func book(p: Paint, rng: RandomNumberGenerator) -> void:
	var cover := Paint.poly([Vector2(OUTER - 16, TOP - 6), Vector2(SPINE, TOP + BOW - 4), Vector2(W - OUTER + 16, TOP - 6),
		Vector2(W - OUTER + 18, BOTTOM + 22), Vector2(SPINE, BOTTOM + BOW + 24), Vector2(OUTER - 18, BOTTOM + 22)])
	p.fill_poly(_grow(cover, 18.0, Vector2(10, 16)), func(x: int, y: int) -> Color:  # 책 그림자
		return Color(0.02, 0.01, 0.0, 0.55), 1.0, true)
	p.fill_poly(cover, p.flat(Color("#3a1e12"), 0.18))  # 가죽 표지
	Ink.strokes(p, cover, 0.6, 18.0, 6.0, 10.0, 0.14, 0.3)
	Ink.path(p, cover, 2.4, true, Color("#0e0704"), 0.85, 0.6)
	for side: int in [-1, 1]:
		for layer in range(5, -1, -1):  # 쪽 묶음(아래·바깥으로 겹친 종이 끝)
			var d := layer * 2.6
			var stack := _page(side, d, d * 0.9)
			p.fill_poly(stack, p.flat(PAPER.darkened(0.25 + layer * 0.05), 0.1))
			Ink.path(p, stack, 1.0, true, Color("#3a2618"), 0.35, 0.3)
		var pg := _page(side, 0.0, 0.0)
		p.fill_poly(pg, func(x: int, y: int) -> Color:
			var c := PAPER.lerp(Color("#c8a874"), p.nz("lo", x, y) * 0.7)
			c = c.lerp(Color("#e8d8b0"), clampf(p.nz("mid", x, y) - 0.55, 0.0, 0.3))
			var to_spine := 1.0 - absf(x - SPINE) / (SPINE - OUTER)
			c = c.darkened(smoothstep(0.78, 1.0, to_spine) * 0.6)  # 등 쪽 골 그늘
			return p.vary(c, x, y, 0.08))
		_burn_edge(p, pg)
	Ink.line(p, Vector2(SPINE, TOP + BOW), Vector2(SPINE, BOTTOM + BOW), 3.0, Color("#2a1408"), 0.8, 0.4)


## 한 쪽의 다각형(위·아래 끝이 등 쪽으로 휜다). grow_out = 바깥으로, drop = 아래로 밀기(쪽 묶음 겹).
static func _page(side: int, grow_out: float, drop: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var outer := OUTER - grow_out if side < 0 else W - OUTER + grow_out
	var n := 16
	for i in n + 1:  # 위 끝: 바깥 → 등
		var t := float(i) / n
		pts.append(Vector2(lerpf(outer, SPINE, t), TOP + drop + BOW * t * t * t))
	for i in n + 1:  # 아래 끝: 등 → 바깥
		var t := 1.0 - float(i) / n
		pts.append(Vector2(lerpf(outer, SPINE, t), BOTTOM + drop + BOW * t * t * t))
	return pts


static func _grow(poly: PackedVector2Array, r: float, off: Vector2) -> PackedVector2Array:
	var out := Geometry2D.offset_polygon(poly, r)
	var pg: PackedVector2Array = out[0] if not out.is_empty() else poly
	for i in pg.size():
		pg[i] += off
	return pg


## 종이 가장자리가 그을린 듯 어두운 띠 + 얼룩.
static func _burn_edge(p: Paint, pg: PackedVector2Array) -> void:
	var r := Paint.bounds(pg)
	p.fill_poly(pg, func(x: int, y: int) -> Color:
		var e := minf(minf(x - r.position.x, r.end.x - x), minf(y - r.position.y, r.end.y - y))
		var k := smoothstep(26.0, 0.0, e + (p.nz("mid", x, y) - 0.5) * 18.0)
		return Color(0.25, 0.13, 0.05, k * 0.55), 1.0, true)


## 세월: 물 얼룩 테·여우 반점(점점이 갈색)·접힌 자국.
static func age(p: Paint, rng: RandomNumberGenerator) -> void:
	for k in 2:
		var side := -1 if k == 0 else 1
		var r := page_rect(side)
		var c := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		var rad := rng.randf_range(34, 60)
		p.fill_poly(oval(c, rad, rad * 0.9, 40), func(x: int, y: int) -> Color:
			var d := Vector2(x - c.x, (y - c.y) / 0.9).length() / rad
			return Color(0.45, 0.28, 0.12, 0.10 * smoothstep(0.6, 1.0, d) * smoothstep(1.05, 0.95, d) + 0.03), 1.0, true)
	for k in 70:
		var side := -1 if rng.randf() < 0.5 else 1
		var r := page_rect(side).grow(24.0)
		var q := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		var s := rng.randf_range(0.8, 2.8)
		p.fill_poly(oval(q, s, s * 0.8, 8), func(_x: int, _y: int) -> Color:
			return Color(0.42, 0.24, 0.1, rng.randf_range(0.15, 0.4)), 1.0, true)


# ── 글 ─────────────────────────────────────────────────

## 읽히지 않는 필사체 글 덩어리: rect 안에 줄마다 낱말(작은 획 묶음)을 늘어놓는다. 끝줄은 짧게, 첫 줄 머리글자는 적갈색.
static func script(p: Paint, rng: RandomNumberGenerator, rect: Rect2, line_h: float = 19.0, size: float = 7.0, c: Color = INK, initial: bool = false, last_short: bool = true) -> void:
	var y := rect.position.y + line_h * 0.8
	var first := true
	while y <= rect.end.y:
		var x := rect.position.x
		var end := rect.end.x - rng.randf_range(0.0, 14.0)
		if last_short and y + line_h > rect.end.y:
			end = rect.position.x + rect.size.x * rng.randf_range(0.35, 0.7)
		if first and initial:
			_initial(p, rng, Vector2(x + size * 1.3, y - size * 0.6), size * 2.6)
			x += size * 4.2
		first = false
		while x < end - size * 2.0:
			var n := rng.randi_range(2, 7)
			x = word(p, rng, Vector2(x, y), n, size, c, end)
			x += size * rng.randf_range(1.1, 1.8)
		y += line_h


## 낱말 하나(n 글자) — 다음 낱말을 쓸 x를 돌려준다.
static func word(p: Paint, rng: RandomNumberGenerator, at: Vector2, n: int, size: float, c: Color, limit: float = 1e9) -> float:
	var x := at.x
	var prev := Vector2(x, at.y)
	for i in n:
		if x + size > limit:
			break
		var gw := size * rng.randf_range(0.7, 1.15)
		var a := Vector2(x, at.y)
		Ink.line(p, prev, a, 1.3, c, 0.7, 0.3)  # 이음 획
		match rng.randi_range(0, 6):
			0:  # 세로 획(긴 것은 위로)
				var tall := size * (2.0 if rng.randf() < 0.25 else 1.0)
				Ink.line(p, a + Vector2(gw * 0.4, 0), a + Vector2(gw * 0.55, -tall), 1.9, c, 0.92, 0.3)
			1:  # 고리
				Ink.path(p, oval(a + Vector2(gw * 0.5, -size * 0.45), gw * 0.45, size * 0.45, 10), 1.7, true, c, 0.88, 0.2)
			2:  # 갈고리
				Ink.line(p, a, a + Vector2(gw * 0.4, -size), 1.9, c, 0.92, 0.3)
				Ink.line(p, a + Vector2(gw * 0.4, -size), a + Vector2(gw, -size * 0.3), 1.6, c, 0.88, 0.3)
			3:  # 물결
				Ink.line(p, a + Vector2(0, -size * 0.3), a + Vector2(gw * 0.5, -size * 0.8), 1.7, c, 0.9, 0.3)
				Ink.line(p, a + Vector2(gw * 0.5, -size * 0.8), a + Vector2(gw, -size * 0.2), 1.7, c, 0.9, 0.3)
			4:  # 아래로 내린 꼬리
				Ink.line(p, a + Vector2(gw * 0.2, -size * 0.8), a + Vector2(gw * 0.45, size * 0.9), 1.9, c, 0.92, 0.3)
			5:  # 짧은 둘
				Ink.line(p, a + Vector2(gw * 0.2, 0), a + Vector2(gw * 0.3, -size * 0.8), 1.7, c, 0.9, 0.3)
				Ink.line(p, a + Vector2(gw * 0.7, 0), a + Vector2(gw * 0.8, -size * 0.8), 1.7, c, 0.9, 0.3)
			_:  # 둥근 등
				Ink.line(p, a + Vector2(0, 0), a + Vector2(gw * 0.3, -size * 0.9), 1.7, c, 0.9, 0.3)
				Ink.line(p, a + Vector2(gw * 0.3, -size * 0.9), a + Vector2(gw * 0.9, -size * 0.5), 1.7, c, 0.9, 0.3)
		if rng.randf() < 0.08:  # 점·삐침
			Ink.line(p, a + Vector2(gw * 0.5, -size * 1.6), a + Vector2(gw * 0.6, -size * 1.4), 1.6, c, 0.8, 0.1)
		x += gw
		prev = Vector2(x, at.y)
	return x


## 장식 머리글자(적갈색 덩어리 + 둘레 테).
static func _initial(p: Paint, rng: RandomNumberGenerator, c: Vector2, s: float) -> void:
	Ink.path(p, Paint.rect_poly(c.x - s * 0.6, c.y - s * 0.7, s * 1.2, s * 1.4), 1.2, true, RED, 0.6, 0.4)
	Ink.line(p, c + Vector2(-s * 0.3, s * 0.5), c + Vector2(-s * 0.1, -s * 0.5), 2.4, RED, 0.9, 0.4)
	Ink.line(p, c + Vector2(-s * 0.1, -s * 0.5), c + Vector2(s * 0.35, s * 0.1), 2.2, RED, 0.9, 0.4)
	Ink.line(p, c + Vector2(-s * 0.2, 0), c + Vector2(s * 0.3, -s * 0.2), 1.6, RED, 0.8, 0.4)
	for k in 3:
		var q := c + Vector2(rng.randf_range(-s * 0.5, s * 0.5), rng.randf_range(-s * 0.6, s * 0.6))
		Ink.line(p, q, q + Vector2(2, -2), 1.2, RED, 0.6, 0.2)


## 그림 이름표: 짧은 낙서 한 낱말 + 밑줄(그림 옆 작은 주석).
static func label(p: Paint, rng: RandomNumberGenerator, at: Vector2, n: int = 4, c: Color = INK) -> void:
	var end := word(p, rng, at, n, 5.0, c)
	Ink.line(p, at + Vector2(0, 4), Vector2(end, at.y + 4), 0.9, c, 0.45, 0.6)


## 가는 지시선(그림 → 주석).
static func leader(p: Paint, a: Vector2, b: Vector2, c: Color = SEPIA) -> void:
	Ink.line(p, a, b, 0.9, c, 0.55, 0.5)
	p.fill_poly(oval(a, 1.8, 1.8, 8), func(_x: int, _y: int) -> Color: return Color(c, 0.8))


# ── 그림 부품 ───────────────────────────────────────────

static func oval(c: Vector2, rx: float, ry: float, n: int = 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## 펜 선 그림(윤곽) + 그늘 빗금 + 옅은 물감(선택).
static func sketch(p: Paint, poly: PackedVector2Array, wash: Color = Color(0, 0, 0, 0), hatch_spacing: float = 0.0, hatch_angle: float = 55.0, width: float = 1.6, c: Color = SEPIA) -> void:
	if wash.a > 0.0:
		p.fill_poly(poly, func(x: int, y: int) -> Color: return Color(wash, minf(1.0, wash.a * 1.6) * (0.75 + 0.5 * p.nz("mid", x, y))), 1.0, true)
	if hatch_spacing > 0.0:
		Ink.hatch(p, poly, hatch_spacing, hatch_angle, 0.55, 1.1, c)
	Ink.path(p, poly, width * 1.35, true, c, 0.92, 0.7)


## 깎인 다각형을 둥글린다(차이킨 — 해부도·얼굴 윤곽).
static func smooth(poly: PackedVector2Array, times: int = 2) -> PackedVector2Array:
	var pts := poly
	for t in times:
		var out := PackedVector2Array()
		var n := pts.size()
		for i in n:
			var a := pts[i]
			var b := pts[(i + 1) % n]
			out.append(a.lerp(b, 0.25))
			out.append(a.lerp(b, 0.75))
		pts = out
	return pts


## 겹 빗금(짙은 그늘): 두 방향.
static func cross(p: Paint, poly: PackedVector2Array, spacing: float, angle: float = 50.0, c: Color = SEPIA) -> void:
	Ink.hatch(p, poly, spacing, angle, 0.5, 1.0, c)
	Ink.hatch(p, poly, spacing * 1.2, angle + 75.0, 0.4, 0.9, c)


## 겹 원 + 둘레 눈금(마법진·도표).
static func circle_chart(p: Paint, rng: RandomNumberGenerator, c: Vector2, r: float, rings: int = 3, ticks: int = 24, col: Color = SEPIA) -> void:
	for i in rings:
		Ink.path(p, oval(c, r * (1.0 - i * 0.16), r * (1.0 - i * 0.16), 48), 1.4 if i == 0 else 1.0, true, col, 0.8, 0.3)
	for i in ticks:
		var a := TAU * i / ticks
		Ink.line(p, c + Vector2.from_angle(a) * r * 0.84, c + Vector2.from_angle(a) * r, 1.0, col, 0.7, 0.2)
	for i in ticks / 3:
		var a := TAU * (i + 0.5) / (ticks / 3.0)
		word(p, rng, c + Vector2.from_angle(a) * r * 0.91 - Vector2(5, -2), 1, 4.0, col)
