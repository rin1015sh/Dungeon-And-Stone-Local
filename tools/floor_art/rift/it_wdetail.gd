extends RefCounted
## 강철의 묘 벽 잔손질(변형마다): 강철벽 부조 · 금 상감 벽화 · 깃발 찢김 · 감실 속 해골/유골함 · 기둥 금 · 문짝 새김 · 관 명판.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Common := preload("res://tools/floor_art/rift/Common.gd")
const L := preload("res://tools/floor_art/rift/it_lib.gd")

const BONE := Color("#b8ae98")
const GILD := Color("#e0c070")


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	var u := p.w / 64.0
	if part == "top":
		_top(p, style, v, u)
		return
	_grit(p, style, u)
	match style:
		"muralwall":
			L.relief(p, func(m: Paint) -> void: _scene(m, v, u, false), col.lightened(0.12), 0.25, true, 1.0)
			_grime(p, u, 2)
		"mural":
			L.relief(p, func(m: Paint) -> void: _scene(m, v + 3, u, true), GILD, 0.6, true, 1.2)
			for k in 3:
				L.glint(p, Vector2(p.rng.randf_range(14, 50), p.rng.randf_range(18, 32)) * u, 1.6 * u, 0.5)
		"bannerwall":
			_banner(p, v, u, col)
		"niche":
			_niche_item(p, v, u)
		"pillar":
			_pillar(p, v, u)
		"steeldoor":
			_door(p, v, u, col)
		"coffin":
			_coffin(p, v, u, col)


## 부조 장면(마스크에 흰색으로) — 강철벽 띠(y 15~35) 안. gold면 더 촘촘하게.
static func _scene(m: Paint, v: int, u: float, gold: bool) -> void:
	var wc := Color(1, 1, 1, 1)
	var cy := 25.0 * u
	match v % 6:
		0:  # 창을 든 행렬 둘
			for k in 2:
				_figure(m, Vector2((22 + k * 20) * u, 34 * u), 16.0 * u, wc, true)
		1:  # 해 원반과 빛살
			m.fill_poly(Cave._ellipse(Vector2(32 * u, cy), 5.5 * u, 5.5 * u, 20), func(_x: int, _y: int) -> Color: return wc)
			for k in 12:
				var a := TAU * k / 12.0
				Ink.line(m, Vector2(32 * u, cy) + Vector2.from_angle(a) * 7.5 * u, Vector2(32 * u, cy) + Vector2.from_angle(a) * 10.5 * u, 1.3 * u, wc, 1.0, 0.0)
		2:  # 물결 띠
			for row in 2:
				var pts := PackedVector2Array()
				for k in 25:
					var x := (12.0 + k * 1.7) * u
					pts.append(Vector2(x, (20.0 + row * 9.0) * u + sin(k * 0.75) * 2.5 * u))
				Ink.path(m, pts, 1.6 * u, false, wc, 1.0, 0.0)
		3:  # 큰 기사 하나(칼을 세운)
			_figure(m, Vector2(32 * u, 35 * u), 20.0 * u, wc, false)
		4:  # 겹 네모 미로
			for k in 3:
				var r := (4.0 + k * 4.0) * u
				Ink.path(m, Paint.rect_poly(32 * u - r * 1.6, cy - r * 0.8, r * 3.2, r * 1.6), 1.3 * u, true, wc, 1.0, 0.0)
		5:  # 원반에 절하는 사람
			m.fill_poly(Cave._ellipse(Vector2(40 * u, 21 * u), 4.5 * u, 4.5 * u, 18), func(_x: int, _y: int) -> Color: return wc)
			var q := Vector2(24 * u, 33 * u)
			m.fill_poly(PackedVector2Array([q + Vector2(-4, 0) * u, q + Vector2(-2, -8) * u, q + Vector2(6, -11) * u, q + Vector2(8, -8) * u, q + Vector2(2, -5) * u, q + Vector2(3, 0) * u]), func(_x: int, _y: int) -> Color: return wc)
			m.fill_poly(Cave._ellipse(q + Vector2(9, -10) * u, 2.2 * u, 2.2 * u, 10), func(_x: int, _y: int) -> Color: return wc)
			if gold:
				for k in 5:
					Ink.line(m, Vector2(40 * u, 21 * u), Vector2(40 * u, 21 * u) + Vector2.from_angle(PI * 0.6 + k * 0.25) * 12.0 * u, 0.9 * u, wc, 1.0, 0.0)
	if gold:  # 아래 띠에 새긴 글자 줄
		for k in 9:
			var x := (11.0 + k * 4.8) * u
			Ink.line(m, Vector2(x, 33 * u), Vector2(x + 2.0 * u, 33 * u), 0.9 * u, wc, 1.0, 0.0)
			Ink.line(m, Vector2(x + 1.0 * u, 32 * u), Vector2(x + 1.0 * u, 34.2 * u), 0.9 * u, wc, 1.0, 0.0)


## 서 있는 사람 모양(머리·몸·다리·창 또는 칼).
static func _figure(m: Paint, foot: Vector2, ht: float, wc: Color, spear: bool) -> void:
	var s := ht / 16.0
	m.fill_poly(Cave._ellipse(foot + Vector2(0, -14.2) * s, 1.8 * s, 1.9 * s, 12), func(_x: int, _y: int) -> Color: return wc)
	m.fill_poly(PackedVector2Array([foot + Vector2(-2.6, -12) * s, foot + Vector2(2.6, -12) * s, foot + Vector2(2.0, -5) * s, foot + Vector2(-2.0, -5) * s]), func(_x: int, _y: int) -> Color: return wc)
	m.fill_poly(PackedVector2Array([foot + Vector2(-2.0, -5) * s, foot + Vector2(2.0, -5) * s, foot + Vector2(2.6, 0) * s, foot + Vector2(0.4, 0) * s, foot + Vector2(0, -3) * s, foot + Vector2(-0.4, 0) * s, foot + Vector2(-2.6, 0) * s]), func(_x: int, _y: int) -> Color: return wc)
	if spear:
		Ink.line(m, foot + Vector2(4.0, 1) * s, foot + Vector2(4.0, -17) * s, 0.9 * s, wc, 1.0, 0.0)
		m.fill_poly(PackedVector2Array([foot + Vector2(4.0, -20) * s, foot + Vector2(5.2, -17) * s, foot + Vector2(2.8, -17) * s]), func(_x: int, _y: int) -> Color: return wc)
		Ink.line(m, foot + Vector2(2.4, -11) * s, foot + Vector2(4.0, -9) * s, 0.9 * s, wc, 1.0, 0.0)
	else:
		Ink.line(m, foot + Vector2(0, -4) * s, foot + Vector2(0, 1) * s, 1.0 * s, wc, 1.0, 0.0)
		Ink.line(m, foot + Vector2(-2.5, -5.5) * s, foot + Vector2(2.5, -5.5) * s, 0.9 * s, wc, 1.0, 0.0)
		m.fill_poly(PackedVector2Array([foot + Vector2(-4.2, -12) * s, foot + Vector2(-2.6, -12.6) * s, foot + Vector2(-2.6, -10) * s]), func(_x: int, _y: int) -> Color: return wc)
		m.fill_poly(PackedVector2Array([foot + Vector2(4.2, -12) * s, foot + Vector2(2.6, -12.6) * s, foot + Vector2(2.6, -10) * s]), func(_x: int, _y: int) -> Color: return wc)


## 리벳·턱 밑으로 흘러내린 때.
static func _grime(p: Paint, u: float, n: int) -> void:
	for k in n:
		var x := p.rng.randf_range(12, 48) * u
		Ink.grime(p, x, 10.0 * u, p.rng.randf_range(3, 7) * u, p.rng.randf_range(10, 26) * u, 0.35, Color("#14161a"))


static func _banner(p: Paint, v: int, u: float, col: Color) -> void:
	var wall := Color("#2e3036")
	match v % 6:
		1, 4:  # 찢어진 구멍(벽이 비친다)
			var q := Vector2(p.rng.randf_range(16, 48), p.rng.randf_range(30, 40)) * u
			var poly := Cave._ellipse(q, p.rng.randf_range(2.5, 4.5) * u, p.rng.randf_range(2.0, 3.5) * u, 9, p.rng)
			p.fill_poly(poly, func(x: int, y: int) -> Color: return p.vary(wall, x, y, 0.1))
			Ink.path(p, poly, 1.0 * u, true, Color("#2a0606"), 0.8, 0.8)
		2:  # 아래 끝이 갈가리
			for k in 5:
				var x := p.rng.randf_range(12, 52) * u
				var top := p.rng.randf_range(38, 42) * u
				var tri := PackedVector2Array([Vector2(x - 2.0 * u, 48 * u), Vector2(x, top), Vector2(x + 2.0 * u, 48 * u)])
				p.fill_poly(tri, func(xx: int, yy: int) -> Color: return p.vary(wall, xx, yy, 0.1))
		3:  # 바랜 얼룩
			Cave._dot(p, Vector2(p.rng.randf_range(20, 44), p.rng.randf_range(16, 36)) * u, 7.0 * u, Color("#8a6a5a"), 0.25)
		5:  # 핏자국
			Cave._dot(p, Vector2(p.rng.randf_range(20, 44), p.rng.randf_range(30, 40)) * u, 4.5 * u, Color("#240404"), 0.6)
	Ink.strokes(p, Paint.rect_poly(10 * u, 8 * u, 44 * u, 34 * u), 0.7, 9.0 * u, 2.5 * u, 85.0, 0.08, 0.3)


static func _niche_item(p: Paint, v: int, u: float) -> void:
	var sill := Vector2(32 * u, 38 * u)
	match v % 6:
		0, 3:
			_skull(p, sill + Vector2(0, -0.5) * u, 1.0 * u)
		1, 4:
			var prof: Array[Vector2] = [Vector2(0, 3), Vector2(2, 4), Vector2(7, 6.2), Vector2(11, 5.5), Vector2(14, 3.2), Vector2(15, 3.8), Vector2(16, 3.6), Vector2(18, 1.2)]
			for k in prof.size():
				prof[k] *= u
			L.lathe(p, sill, prof, Color("#7a6448"), false, 0.6)
			Ink.line(p, sill + Vector2(-5.5, -8) * u, sill + Vector2(5.5, -8) * u, 0.8 * u, Color("#2a1e14"), 0.6, 0.2)
		2:  # 뼈 무더기
			for k in 4:
				var a := sill + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-3, 0)) * u
				var d := Vector2.from_angle(p.rng.randf_range(-0.4, 0.4)) * p.rng.randf_range(4, 7) * u
				Ink.line(p, a - d, a + d, 1.8 * u, BONE.darkened(0.2), 0.95, 0.2)
				Cave._dot(p, a - d, 1.4 * u, BONE, 0.9)
				Cave._dot(p, a + d, 1.4 * u, BONE, 0.9)
			_skull(p, sill + Vector2(4, -3) * u, 0.75 * u)
		5:  # 녹은 초 + 희미한 불
			var q := sill + Vector2(-2, 0) * u
			Ink.glow(p, q.x, q.y - 9 * u, 12 * u, Color("#ff9a50"), 0.4)
			p.fill_rect(q.x - 1.6 * u, q.y - 6 * u, 3.2 * u, 6 * u, func(_x: int, _y: int) -> Color: return L.CANDLE)
			Cave._dot(p, q + Vector2(0, -8) * u, 1.5 * u, Color("#ffe0a0"), 1.0)
			_skull(p, sill + Vector2(7, 0) * u, 0.6 * u)


## 해골 하나(앞모습): 머리뼈 · 눈구멍 · 코 · 이빨.
static func _skull(p: Paint, base: Vector2, s: float) -> void:
	var c := base + Vector2(0, -6.5) * s
	p.fill_poly(Cave._ellipse(c + Vector2(1.2, 4.5) * s, 5.5 * s, 2.0 * s, 12), func(_x: int, _y: int) -> Color: return Color(0, 0, 0, 0.5))
	var head := Cave._ellipse(c, 4.6 * s, 4.2 * s, 18)
	p.fill_poly(head, func(x: int, y: int) -> Color:
		var d := (Vector2(x, y) - c) / (4.6 * s)
		return BONE.darkened(0.45).lerp(BONE.lightened(0.1), clampf(0.6 - d.x * 0.5 - d.y * 0.4, 0.0, 1.0)))
	var jaw := PackedVector2Array([c + Vector2(-2.8, 2.5) * s, c + Vector2(2.8, 2.5) * s, c + Vector2(2.2, 6.0) * s, c + Vector2(-2.2, 6.0) * s])
	p.fill_poly(jaw, func(_x: int, _y: int) -> Color: return BONE.darkened(0.3))
	Ink.path(p, head, 0.9 * s, true, Ink.INK, 0.7, 0.2)
	Ink.path(p, jaw, 0.8 * s, true, Ink.INK, 0.6, 0.2)
	for sx: float in [-1.8, 1.8]:
		p.fill_poly(Cave._ellipse(c + Vector2(sx, 0.6) * s, 1.4 * s, 1.3 * s, 10), func(_x: int, _y: int) -> Color: return Color("#0a0806"))
	p.fill_poly(PackedVector2Array([c + Vector2(0, 2.0) * s, c + Vector2(0.7, 3.4) * s, c + Vector2(-0.7, 3.4) * s]), func(_x: int, _y: int) -> Color: return Color("#140e0a"))
	for k in 4:
		Ink.line(p, c + Vector2(-1.8 + k * 1.2, 4.2) * s, c + Vector2(-1.8 + k * 1.2, 5.8) * s, 0.5 * s, Ink.INK, 0.6, 0.0)


static func _pillar(p: Paint, v: int, u: float) -> void:
	match v % 6:
		1, 4:
			Cave._crack(p, Vector2(p.rng.randf_range(20, 44) * u, p.rng.randf_range(24, 60) * u), 4, 7.0 * u, Vector2(0.2, 1))
		2:
			for k in 2:  # 떨어져 나간 자국
				var q := Vector2(p.rng.randf_range(18, 46), p.rng.randf_range(30, 80)) * u
				p.fill_poly(Cave._ellipse(q, 4 * u, 3 * u, 10, p.rng), func(_x: int, _y: int) -> Color: return Color(0.05, 0.05, 0.06, 0.45), 1.0, true)
				Ink.line(p, q + Vector2(-3, 3) * u, q + Vector2(3, 2) * u, 0.9 * u, L.LIT, 0.3, 0.6, true)
		5:
			Cave._dot(p, Vector2(p.rng.randf_range(26, 40), 76) * u, 6.0 * u, Color("#2a0505"), 0.5)
	Ink.grime(p, p.rng.randf_range(14, 40) * u, 18.0 * u, 10.0 * u, 26.0 * u, 0.3, Color("#2a2018"))
	Ink.grime(p, p.rng.randf_range(14, 40) * u, 93.0 * u, 8.0 * u, 12.0 * u, 0.3, Color("#2a2018"))


static func _door(p: Paint, v: int, u: float, col: Color) -> void:
	var c1 := Vector2(32, 31) * u
	var c2 := Vector2(32, 71) * u
	var wc := Color(1, 1, 1, 1)
	var draw := func(m: Paint) -> void:
		match v % 6:
			0, 4:  # 봉인 — 둥근 문장과 빛살
				Ink.path(m, Cave._ellipse(c1, 11 * u, 11 * u, 32), 1.6 * u, true, wc, 1.0, 0.0)
				Ink.path(m, Cave._ellipse(c1, 6 * u, 6 * u, 24), 1.4 * u, true, wc, 1.0, 0.0)
				for k in 8:
					var a := TAU * k / 8.0
					Ink.line(m, c1 + Vector2.from_angle(a) * 6.5 * u, c1 + Vector2.from_angle(a) * 10.5 * u, 1.2 * u, wc, 1.0, 0.0)
				m.fill_poly(Cave._ellipse(c1, 2.5 * u, 2.5 * u, 12), func(_x: int, _y: int) -> Color: return wc)
				_lozenge(m, c2, 12 * u, 13 * u, wc)
			1:
				_lozenge(m, c1, 14 * u, 14 * u, wc)
				_lozenge(m, c2, 14 * u, 14 * u, wc)
			2:  # 문고리 받침
				m.fill_poly(Cave._ellipse(c2 + Vector2(0, -4) * u, 4 * u, 4 * u, 14), func(_x: int, _y: int) -> Color: return wc)
				_lozenge(m, c1, 10 * u, 12 * u, wc)
			3:  # 격자
				for k in 5:
					Ink.line(m, Vector2((14 + k * 9) * u, 17 * u), Vector2((14 + k * 9) * u, 45 * u), 1.1 * u, wc, 1.0, 0.0)
					Ink.line(m, Vector2((14 + k * 9) * u, 57 * u), Vector2((14 + k * 9) * u, 85 * u), 1.1 * u, wc, 1.0, 0.0)
			5:  # 세로 글자 띠
				for k in 6:
					var y := (18.0 + k * 4.5) * u
					Ink.line(m, Vector2(26 * u, y), Vector2(38 * u, y), 1.0 * u, wc, 1.0, 0.0)
					Ink.line(m, Vector2((28 + (k % 3) * 4) * u, y - 1.5 * u), Vector2((28 + (k % 3) * 4) * u, y + 1.5 * u), 1.0 * u, wc, 1.0, 0.0)
				_lozenge(m, c2, 12 * u, 12 * u, wc)
	L.relief(p, draw, col.lightened(0.1), 0.15, true, 1.0)
	if v % 6 == 2:  # 쇠 문고리
		var q := c2 + Vector2(0, 3) * u
		Ink.path(p, Cave._ellipse(q, 5.5 * u, 6.5 * u, 22), 2.6 * u, true, Color("#1e1e22"), 0.95, 0.1)
		Ink.path(p, Cave._ellipse(q + Vector2(-0.6, -0.6) * u, 5.5 * u, 6.5 * u, 22), 1.0 * u, true, Color("#9a9aa2"), 0.5, 0.1)
	if v % 6 == 4:
		Cave._crack(p, c1 + Vector2(4, 6) * u, 4, 6.0 * u, Vector2(0.3, 1))
	Ink.grime(p, p.rng.randf_range(12, 44) * u, 54.0 * u, 12.0 * u, 30.0 * u, 0.3, Color("#2a2420"))
	Ink.strokes(p, Paint.rect_poly(6 * u, 14 * u, 52 * u, 74 * u), 0.5, 10.0 * u, 2.5 * u, 88.0, 0.06, 0.25)


static func _lozenge(m: Paint, c: Vector2, rx: float, ry: float, wc: Color) -> void:
	var poly := PackedVector2Array([c + Vector2(0, -ry), c + Vector2(rx, 0), c + Vector2(0, ry), c + Vector2(-rx, 0)])
	Ink.path(m, poly, 1.5 * m.w / 64.0, true, wc, 1.0, 0.0)
	m.fill_poly(Cave._ellipse(c, 2.2 * m.w / 64.0, 2.2 * m.w / 64.0, 12), func(_x: int, _y: int) -> Color: return wc)


static func _coffin(p: Paint, v: int, u: float, col: Color) -> void:
	var wc := Color(1, 1, 1, 1)
	var c := Vector2(32, 27.5) * u
	var draw := func(m: Paint) -> void:
		match v % 6:
			0, 3:  # 명판
				Ink.path(m, Paint.rect_poly(19 * u, 21 * u, 26 * u, 13 * u), 1.3 * u, true, wc, 1.0, 0.0)
				for k in 5:
					var x := (22.0 + k * 4.4) * u
					Ink.line(m, Vector2(x, 25 * u), Vector2(x + 2.4 * u, 30 * u), 0.9 * u, wc, 1.0, 0.0)
			1:  # 사슬 띠
				for k in 9:
					var q := Vector2((12 + k * 5) * u, c.y)
					var horiz := k % 2 == 0
					Ink.path(m, Cave._ellipse(q, (3.2 if horiz else 1.4) * u, (1.6 if horiz else 2.6) * u, 12), 1.0 * u, true, wc, 1.0, 0.0)
			2:  # 십자 칼
				Ink.line(m, c + Vector2(-14, 0) * u, c + Vector2(14, 0) * u, 1.6 * u, wc, 1.0, 0.0)
				Ink.line(m, c + Vector2(-8, -5) * u, c + Vector2(-8, 5) * u, 1.6 * u, wc, 1.0, 0.0)
				m.fill_poly(Cave._ellipse(c + Vector2(-12, 0) * u, 2 * u, 2 * u, 10), func(_x: int, _y: int) -> Color: return wc)
			4:  # 방패
				m.fill_poly(PackedVector2Array([c + Vector2(-6, -7) * u, c + Vector2(6, -7) * u, c + Vector2(6, 1) * u, c + Vector2(0, 7) * u, c + Vector2(-6, 1) * u]), func(_x: int, _y: int) -> Color: return wc)
			_:
				pass
	L.relief(p, draw, col.lightened(0.1), 0.15, true, 1.0)
	if v % 6 == 5:
		Cave._crack(p, c + Vector2(-6, -4) * u, 3, 6.0 * u, Vector2(1, 0.5))
		Cave._dot(p, c + Vector2(8, 4) * u, 6.0 * u, L.RUST, 0.4)
	_grime(p, u, 1)


static func _top(p: Paint, style: String, v: int, u: float) -> void:
	var c := Vector2(p.w, p.h) * 0.5
	match v % 3:
		0:
			Ink.strokes(p, Paint.rect_poly(10 * u, 12 * u, 44 * u, 40 * u), 0.6, 8.0 * u, 2.5 * u, 10.0, 0.06, 0.25)
		1:
			if style == "niche" or style == "pillar":
				Cave._crack(p, c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-8, 8)) * u, 3, 6.0 * u, Vector2.from_angle(p.rng.randf() * TAU))
			else:
				for k in 4:
					var q := c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-12, 12)) * u
					Ink.line(p, q, q + Vector2(p.rng.randf_range(5, 10), p.rng.randf_range(-2, 2)) * u, 0.7 * u, L.LIT, 0.25, 0.3, true)
		2:
			Cave._dot(p, c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-8, 8)) * u, 8.0 * u, Color("#121418"), 0.35)


## 공통 때: 붓결 · 턱 밑 흘러내린 얼룩 · 굽도리 쪽 먼지.
static func _grit(p: Paint, style: String, u: float) -> void:
	var main := float(p.h - Common.skirt)
	Ink.strokes(p, Paint.rect_poly(9 * u, 6 * u, 46 * u, main - 8 * u), 0.6, 10.0 * u, 3.0 * u, 85.0, 0.1, 0.3)
	if style != "bannerwall":
		for k in 3:
			Ink.grime(p, p.rng.randf_range(8, 48) * u, 6.0 * u, p.rng.randf_range(4, 10) * u, main * p.rng.randf_range(0.3, 0.8), 0.45, Color("#16181c"))
		Ink.grime(p, 8 * u, main - 10 * u, 48 * u, 10 * u, 0.35, Color("#1e1c1a"))
	for k in 4:
		Cave._dot(p, Vector2(p.rng.randf_range(12, 52) * u, main - p.rng.randf_range(1, 6) * u), p.rng.randf_range(2.0, 4.0) * u, Color("#2a2826"), 0.3)
