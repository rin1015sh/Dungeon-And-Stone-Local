extends RefCounted
## 거리 레이어(시설 건물과 같은 깊이, 시차 1): 건물 밑 인도 판석 · 연석 · 젖은 포석길(앞으로 올수록 큰 돌) · 웅덩이 ·
## 건물 사이 골목(낮은 돌담 + 쇠 난간, 가로등, 마른 나무·우물·수레·게시판) · 건물 발치 그늘 · 문 앞 불빛 웅덩이.
## 투명 배경(인도 위쪽은 건물 사이 소품만) — 뒤의 중경 레이어가 보인다. tools/paint_city.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Props := preload("res://tools/city_art/Props.gd")

const HEIGHT := 720
const CURB := 26  ## 인도 폭(건물 바닥 아래)


## spans = [[x0, x1] …] 건물이 차지하는 가로 구간, baseline = 건물이 서는 y.
static func paint(width: int, baseline: int, spans: Array, seed_value: int) -> Paint:
	var p := Paint.new(width, HEIGHT, seed_value)
	_gaps(p, baseline, spans)
	_ground(p, baseline)
	for s: Array in spans:
		var x0: float = s[0]
		var x1: float = s[1]
		Ink.shade(p, Paint.rect_poly(x0 - 10, baseline, x1 - x0 + 20, CURB), Vector2(0, baseline), Vector2(0, baseline + CURB), 0.6, 0.0)
		Ink.glow(p, (x0 + x1) / 2.0, baseline + 40, (x1 - x0) * 0.45, Color("#ffb45c"), 0.12, true, 0.35)
	Ink.grade(p, 0.3, 1.08)
	Ink.finish(p, 0.03)
	return p


static func _ground(p: Paint, baseline: int) -> void:
	var walk := Paint.rect_poly(0, baseline, p.w, CURB)
	p.fill_poly(walk, Mat.ashlar(p, Color("#4b4943"), 0, baseline, 58, CURB))
	var curb := Paint.rect_poly(0, baseline + CURB, p.w, 8)
	p.fill_poly(curb, p.flat(Color("#67645b"), 0.2))
	Ink.path(p, curb, 1.6, false)
	var y := float(baseline + CURB + 8)
	p.fill_rect(0, y, p.w, HEIGHT - y, p.flat(Color("#22211d"), 0.3))
	var row := 0
	var rh := 9.0
	while y < HEIGHT:  # 포석: 줄마다 높이가 커진다(가까울수록 크다)
		var x := -p.rng.randf() * rh * 2.0
		while x < p.w:
			var sw := rh * p.rng.randf_range(1.1, 2.4)
			_cobble(p, x, y, sw, rh)
			x += sw
		y += rh
		rh *= 1.12
		row += 1
	Ink.shade(p, Paint.rect_poly(0, baseline + CURB + 8, p.w, HEIGHT - baseline - CURB - 8), Vector2(0, baseline + CURB + 8), Vector2(0, HEIGHT), 0.25, 0.0)
	for i in int(p.w / 260.0):  # 웅덩이: 하늘·불빛 반사
		var cx := p.rng.randf() * p.w
		var cy := p.rng.randf_range(baseline + 60, HEIGHT - 20)
		var rw := p.rng.randf_range(40, 90)
		var pud: Array = []
		for k in 18:
			var a := TAU * k / 18.0
			pud.append(Vector2(cx + cos(a) * rw * p.rng.randf_range(0.8, 1.1), cy + sin(a) * rw * 0.18))
		var pp := Paint.poly(pud)
		p.fill_poly(pp, func(x2: int, y2: int) -> Color:
			return p.vary(Color("#1f2422").lerp(Color("#55593f"), clampf((cy - y2) / (rw * 0.2) * 0.5 + 0.5, 0.0, 1.0)), x2, y2, 0.2), 0.8)
		Ink.line(p, Vector2(cx - rw * 0.5, cy - 2), Vector2(cx + rw * 0.3, cy - 3), 1.6, Color("#b9b07a"), 0.35, 0.5)


static func _cobble(p: Paint, x: float, y: float, sw: float, sh: float) -> void:
	var pts: Array = []
	var cx := x + sw / 2.0
	var cy := y + sh / 2.0
	for k in 10:
		var a := TAU * k / 10.0
		var rr := 0.92 + p.rng.randf_range(-0.08, 0.06)
		pts.append(Vector2(cx + cos(a) * (sw / 2.0 - 1.0) * rr, cy + sin(a) * (sh / 2.0 - 0.8) * rr))
	var poly := Paint.poly(pts)
	var tone := Color("#3e3d37").lightened(p.rng.randf_range(-0.1, 0.1)).lerp(Color("#3d3528"), p.rng.randf() * 0.4)
	p.fill_poly(poly, func(x2: int, y2: int) -> Color:
		var t := (y2 - y) / sh
		var c := tone.lightened(0.1 * (1.0 - t)).darkened(0.18 * t * t)
		if p.nz("mid", x2, y2) > 0.68:
			c = c.lightened(0.12)  # 젖은 반들거림
		return p.vary(c, x2, y2, 0.22), 0.92)


## 건물 사이: 돌담 + 난간, 그리고 소품 하나씩(가로등은 늘).
static func _gaps(p: Paint, baseline: int, spans: Array) -> void:
	var gaps: Array = []
	var prev := 0.0
	for s: Array in spans:
		gaps.append([prev, float(s[0])])
		prev = float(s[1])
	gaps.append([prev, float(p.w)])
	var g := float(baseline)
	for i in gaps.size():
		var a: float = gaps[i][0]
		var b: float = gaps[i][1]
		if b - a < 60.0:
			continue
		var wall := Paint.rect_poly(a - 4, g - 58, b - a + 8, 58)
		p.fill_poly(wall, Mat.rubble(p, Color("#4a473f")))
		Ink.shade(p, wall, Vector2(0, g - 58), Vector2(0, g), 0.1, 0.5)
		Ink.path(p, wall, 2.0)
		var cap := Paint.rect_poly(a - 6, g - 64, b - a + 12, 8)
		p.fill_poly(cap, p.flat(Color("#5d5a50"), 0.2))
		Ink.path(p, cap, 1.6)
		var x := a + 6.0
		while x < b - 4.0:  # 쇠 난간
			Ink.line(p, Vector2(x, g - 64), Vector2(x, g - 100), 2.0, Color("#1c1a17"), 0.95, 0.2)
			Ink.line(p, Vector2(x - 2, g - 100), Vector2(x, g - 106), 1.6, Color("#1c1a17"), 0.95, 0.1)
			x += 12.0
		Ink.line(p, Vector2(a, g - 96), Vector2(b, g - 96), 2.4, Color("#1c1a17"), 0.95, 0.3)
		var mid := (a + b) / 2.0
		match i % 5:
			0:
				_dead_tree(p, mid, g - 60, 1.0)
			1:
				Props.well(p, mid + 10, g + 18)
			2:
				_notice_board(p, mid, g + 16)
			3:
				Props.cart(p, mid, g + 22)
			4:
				_dead_tree(p, mid - 20, g - 60, 0.85)
				Props.barrel(p, mid + 40, g + 16, 30, 40)
		Props.lamp_post(p, a + 22 if i > 0 else b - 30, g + 20, 190)


## 마른 나무: 뒤틀린 가지(잉크 획) — 잎 없음.
static func _dead_tree(p: Paint, cx: float, ground: float, s: float) -> void:
	_branch(p, Vector2(cx, ground + 60), -PI / 2.0 + p.rng.randf_range(-0.1, 0.1), 150.0 * s, 9.0 * s, 0)


static func _branch(p: Paint, from: Vector2, angle: float, length: float, width: float, depth: int) -> void:
	var to := from + Vector2.from_angle(angle) * length
	Ink.line(p, from, to, width, Color("#1d1814"), 1.0, 2.0)
	if depth >= 4 or length < 14.0:
		return
	for k in 2 + (p.rng.randi() % 2):
		_branch(p, to, angle + p.rng.randf_range(-0.75, 0.75), length * p.rng.randf_range(0.5, 0.7), width * 0.62, depth + 1)


static func _notice_board(p: Paint, cx: float, ground: float) -> void:
	for lx: float in [cx - 40, cx + 40]:
		Ink.line(p, Vector2(lx, ground), Vector2(lx, ground - 130), 6.0, Color("#3a2a1e"), 1.0, 0.3)
	var board := Paint.rect_poly(cx - 50, ground - 128, 100, 66)
	p.fill_poly(board, Mat.planks(p, Color("#4a3624"), int(cx), 0, false, 11))
	Ink.path(p, board, 2.0)
	for k in 5:
		var px := cx - 42 + p.rng.randf() * 64
		var py := ground - 122 + p.rng.randf() * 34
		var paper := Paint.rect_poly(px, py, p.rng.randf_range(16, 24), p.rng.randf_range(18, 26))
		p.fill_poly(paper, p.flat(Color("#b4aa8a"), 0.2))
		Ink.path(p, paper, 1.0, true, Ink.INK, 0.6)
		Ink.line(p, Vector2(px + 4, py + 7), Vector2(px + 14, py + 7), 1.0, Ink.INK, 0.5)
	var roof := Paint.poly([Vector2(cx - 58, ground - 126), Vector2(cx, ground - 150), Vector2(cx + 58, ground - 126)])
	p.fill_poly(roof, Mat.planks(p, Color("#3a2a1e"), 0, 0, false, 6))
	Ink.path(p, roof, 2.0)
