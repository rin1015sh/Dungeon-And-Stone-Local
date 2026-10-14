extends RefCounted
## 도시 뒷배경 레이어(상호작용 없는 실제 도시 풍경): 하늘(병든 달·구름) · 원경(언덕 위 성과 첨탑·지붕 물결·연기) ·
## 중경(뒷골목 집들 — 안개에 묻혀 흐리고 어둡다) · 안개 띠 · 화면 비네트.
## 앞의 시설 건물과 레이어가 구분되도록: 원경·중경은 반 해상도(흐림), 채도·대비를 낮추고 안개색으로 민다. 시차 스크롤은 게임이 한다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")

const FOG := Color("#5d6352")
const MOON := Color("#d9d6a4")


static func sky(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var horizon := h * 0.74
	p.fill_rect(0, 0, w, h, func(x: int, y: int) -> Color:
		var t := y / horizon
		var c := Color("#181d20").lerp(Color("#3a423d"), clampf(t * 1.3, 0.0, 1.0))
		if t > 0.6:
			c = c.lerp(Color("#867f55"), clampf((t - 0.6) / 0.4, 0.0, 1.0) * 0.8)
		return p.vary(c, x, y, 0.08))
	var moon := Vector2(w * 0.72, h * 0.2)
	Ink.glow(p, moon.x, moon.y, h * 0.5, Color("#6f7a52"), 0.35)
	Ink.glow(p, moon.x, moon.y, h * 0.16, Color("#b9c08a"), 0.4)
	var disc := _circle(moon, h * 0.065)
	p.fill_poly(disc, func(x: int, y: int) -> Color:
		var d := (Vector2(x, y) - moon) / (h * 0.065)
		var c := MOON.lerp(Color("#a9b47a"), clampf(d.x * 0.5 + d.y * 0.3 + 0.3, 0.0, 1.0))
		return c.darkened(p.nz("mid", x * 4, y * 4) * 0.2))
	for band in 7:  # 구름 띠: 가로로 늘인 붓질
		var cy := h * (0.12 + band * 0.1) + p.rng.randf_range(-8, 8)
		var c := Color("#2a302c").lerp(Color("#6b6a4c"), band / 7.0)
		for i in int(w / 6.0):
			var x := p.rng.randf() * w
			var yy := cy + p.rng.randf_range(-10, 10) + sin(x * 0.01 + band) * 8.0
			var lit := 1.0 - clampf(Vector2(x, yy).distance_to(moon) / (h * 0.6), 0.0, 1.0)
			Ink.line(p, Vector2(x - 24, yy), Vector2(x + 24, yy + p.rng.randf_range(-2, 2)), p.rng.randf_range(4, 9), c.lightened(lit * 0.35), 0.35, 1.0)
	for i in 9:  # 새 떼
		var b := Vector2(w * p.rng.randf_range(0.1, 0.6), h * p.rng.randf_range(0.15, 0.45))
		Ink.line(p, b, b + Vector2(5, 3), 1.2, Ink.INK, 0.8, 0.2)
		Ink.line(p, b + Vector2(5, 3), b + Vector2(10, 0), 1.2, Ink.INK, 0.8, 0.2)
	Ink.finish(p, 0.03)
	return p


## 원경: 오른쪽 언덕 위 성채와 대성당, 가운데 쌍첨탑 교회, 빽빽한 지붕 물결, 성벽 탑, 연기 기둥. 아래로 갈수록 안개.
static func far(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var base := Color("#232927")
	var hill := Paint.poly([Vector2(w * 0.55, h), Vector2(w * 0.62, h * 0.55), Vector2(w * 0.75, h * 0.42), Vector2(w * 0.92, h * 0.46), Vector2(w, h * 0.5), Vector2(w, h)])
	p.fill_poly(hill, p.flat(base.darkened(0.1), 0.2))
	var cx := w * 0.6
	while cx < w * 0.98:  # 성채 벽과 탑
		var tw := p.rng.randf_range(14, 30)
		var top := h * 0.42 - p.rng.randf_range(10, 40)
		_block(p, cx, top, tw, h * 0.5 - top, base.lightened(0.05), p.rng.randf() < 0.5)
		cx += tw + p.rng.randf_range(-4, 6)
	_spire_church(p, w * 0.8, h * 0.08, 46, base.lightened(0.02))
	_spire_church(p, w * 0.3, h * 0.05, 36, base)
	var x := -10.0
	while x < w:  # 지붕 물결
		var bw := p.rng.randf_range(14, 34)
		var top := h * p.rng.randf_range(0.5, 0.66)
		_block(p, x, top, bw, h - top, base.lightened(p.rng.randf_range(0.0, 0.12)), false)
		x += bw - p.rng.randf_range(0, 5)
	for i in int(w / 120.0):  # 성벽 둥근 탑
		var tx := p.rng.randf() * w
		_block(p, tx, h * 0.48, 20, h * 0.52, base.lightened(0.08), true)
	for i in int(w / 25.0):  # 불 켜진 창
		var q := Vector2(p.rng.randf() * w, h * p.rng.randf_range(0.5, 0.85))
		if p.alpha_at(int(q.x), int(q.y)) > 0.5:
			p.fill_rect(q.x, q.y, 2, 3, p.flat(Color("#c98b45"), 0.1))
	for i in 5:
		_smoke(p, Vector2(p.rng.randf() * w, h * 0.55), h * 0.5)
	Ink.shade(p, Paint.rect_poly(0, 0, w, h), Vector2(0, h * 0.4), Vector2(0, h), 0.0, 0.6, FOG)
	Ink.grade(p, 0.35, 0.95)
	Ink.finish(p, 0.03)
	return p


## 중경: 뒷골목 집들이 끊김 없이 이어진다(박공 모양·벽색·창 배치가 집마다 다르다). 아래는 안개에 잠긴다.
static func mid(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var x := -8.0
	var walls := [Color("#575142"), Color("#4b473b"), Color("#5e5341"), Color("#4f362c"), Color("#514e44"), Color("#5f584a")]
	while x < w:
		var bw := p.rng.randf_range(40, 90)
		var top := h * p.rng.randf_range(0.36, 0.6)
		_townhouse(p, x, top, bw, h - top, walls[p.rng.randi() % walls.size()])
		x += bw - 1.0
	Ink.shade(p, Paint.rect_poly(0, 0, w, h), Vector2(0, h * 0.2), Vector2(0, h), 0.1, 0.5, FOG)
	Ink.shade(p, Paint.rect_poly(0, h * 0.72, w, h * 0.28), Vector2(0, h * 0.72), Vector2(0, h), 0.0, 0.85, FOG.darkened(0.15))
	Ink.grade(p, 0.35, 1.0)
	Ink.finish(p, 0.03)
	return p


## 안개 띠: 부드러운 덩어리(앞 건물과 뒷배경 사이).
static func haze(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	p.fill_rect(0, 0, w, h, func(x: int, y: int) -> Color:
		var t := float(y) / h
		var a := sin(t * PI) * (0.25 + p.nz("lo", x, y) * 0.55) * smoothstep(0.0, 0.3, t)
		return Color(FOG.lightened(0.15).r, FOG.lightened(0.15).g, FOG.lightened(0.15).b, a))
	return p


## 화면 비네트(스크롤하지 않는 맨 앞 레이어): 가장자리와 위쪽을 어둡게.
static func vignette(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	p.fill_rect(0, 0, w, h, func(x: int, y: int) -> Color:
		var d := Vector2((x - w / 2.0) / (w / 2.0), (y - h * 0.55) / (h * 0.6)).length()
		var a := smoothstep(0.55, 1.35, d) * 0.75 + (1.0 - float(y) / h) * (1.0 - float(y) / h) * 0.25
		return Color(0.04, 0.04, 0.035, clampf(a, 0.0, 0.85)))
	return p


static func _townhouse(p: Paint, x: float, top: float, bw: float, bh: float, wall_c: Color) -> void:
	var kind := p.rng.randi() % 4
	var gable := bw * p.rng.randf_range(0.45, 0.8)
	var pts: Array = [Vector2(x, top + bh), Vector2(x, top)]
	match kind:
		0:
			pts.append(Vector2(x + bw / 2.0, top - gable))
		1:
			for k in 3:
				var s := bw * 0.16 * (k + 1)
				pts.append(Vector2(x + s - bw * 0.16, top - gable * k / 3.0))
				pts.append(Vector2(x + s, top - gable * k / 3.0))
			pts.append(Vector2(x + bw / 2.0 - bw * 0.1, top - gable))
			pts.append(Vector2(x + bw / 2.0 + bw * 0.1, top - gable))
			for k in range(2, -1, -1):
				var s := bw * 0.16 * (k + 1)
				pts.append(Vector2(x + bw - s, top - gable * k / 3.0))
				pts.append(Vector2(x + bw - s + bw * 0.16, top - gable * k / 3.0))
		2:
			for k in 9:
				var t := float(k) / 8.0
				pts.append(Vector2(x + bw * t, top - gable * (0.55 + 0.45 * sin(t * PI)) - absf(t - 0.5) * 6.0))
	pts.append(Vector2(x + bw, top))
	pts.append(Vector2(x + bw, top + bh))
	var poly := Paint.poly(pts)
	if kind == 3:
		var roof := Paint.poly([Vector2(x - 2, top), Vector2(x + bw * 0.2, top - gable * 0.6), Vector2(x + bw * 0.8, top - gable * 0.6), Vector2(x + bw + 2, top)])
		p.fill_poly(roof, Mat.slate(p, Color("#2c3134"), 0, 0, 8, 5, 0.4))
		Ink.path(p, roof, 1.2, true, Ink.INK, 0.7)
		poly = Paint.rect_poly(x, top, bw, bh)
	var brick := wall_c.r > wall_c.g * 1.25
	p.fill_poly(poly, Mat.brick(p, wall_c, int(x), 0, 11, 5) if brick else Mat.plaster(p, wall_c))
	Ink.shade(p, poly, Vector2(x, 0), Vector2(x + bw, 0), 0.0, 0.3)
	Ink.path(p, poly, 1.3, true, Ink.INK, 0.75)
	var cols := maxi(2, int(bw / 18.0))
	var rows := int(bh / 30.0)
	for r in rows:
		for c in cols:
			var wx := x + bw * (c + 0.5) / cols - 4.0
			var wy := top + 12.0 + r * 30.0
			if wy > top + bh * 0.8:
				continue
			var lit := p.rng.randf() < 0.12
			var win := Paint.rect_poly(wx, wy, 8, 13)
			p.fill_poly(win, p.flat(Color("#c98b45") if lit else Color("#1b1e1c"), 0.15))
			Ink.path(p, win, 1.0, true, Ink.INK, 0.7, 0.3)
			if lit:
				Ink.glow(p, wx + 4, wy + 6, 16, Color("#ffb45c"), 0.15)
	if p.rng.randf() < 0.6:
		var cx := x + p.rng.randf_range(bw * 0.2, bw * 0.7)
		var ch := Paint.rect_poly(cx, top - gable * 0.7 - 14, 7, 20)
		p.fill_poly(ch, Mat.brick(p, Color("#4a3027"), int(cx), 0, 6, 3))
		Ink.path(p, ch, 1.0, true, Ink.INK, 0.7)


static func _block(p: Paint, x: float, top: float, bw: float, bh: float, c: Color, cone: bool) -> void:
	var roof_h := bw * (1.4 if cone else 0.6)
	var poly := Paint.poly([Vector2(x, top + bh), Vector2(x, top), Vector2(x + bw / 2.0, top - roof_h), Vector2(x + bw, top), Vector2(x + bw, top + bh)])
	p.fill_poly(poly, p.flat(c, 0.12))
	Ink.shade(p, poly, Vector2(x, 0), Vector2(x + bw, 0), 0.0, 0.25)
	Ink.path(p, poly, 1.0, true, Ink.INK, 0.45, 0.3)


static func _spire_church(p: Paint, cx: float, top: float, s: float, c: Color) -> void:
	var g := p.h * 0.75
	for dx: float in [-s * 0.55, s * 0.55]:
		var tx := cx + dx
		var tower := Paint.poly([Vector2(tx - s * 0.25, g), Vector2(tx - s * 0.25, top + s * 1.6), Vector2(tx, top), Vector2(tx + s * 0.25, top + s * 1.6), Vector2(tx + s * 0.25, g)])
		p.fill_poly(tower, p.flat(c.darkened(0.08), 0.12))
		for k in 3:
			var q := Vector2(tx + (k - 1) * s * 0.18, top + s * 1.5)
			var mini_sp := Paint.poly([Vector2(q.x - 3, q.y + 6), Vector2(q.x, q.y - 12), Vector2(q.x + 3, q.y + 6)])
			p.fill_poly(mini_sp, p.flat(c, 0.1))
		Ink.path(p, tower, 1.0, true, Ink.INK, 0.5, 0.3)
	var nave := Paint.poly([Vector2(cx - s * 0.6, g), Vector2(cx - s * 0.6, top + s * 2.6), Vector2(cx, top + s * 2.0), Vector2(cx + s * 0.6, top + s * 2.6), Vector2(cx + s * 0.6, g)])
	p.fill_poly(nave, p.flat(c, 0.12))
	Ink.path(p, nave, 1.0, true, Ink.INK, 0.45, 0.3)


static func _smoke(p: Paint, base: Vector2, height: float) -> void:
	var q := base
	for i in 14:
		var r := 4.0 + i * 1.6
		q += Vector2(p.rng.randf_range(1.0, 4.0), -height / 14.0)
		for yy in range(int(q.y - r), int(q.y + r)):
			for xx in range(int(q.x - r), int(q.x + r)):
				var d := Vector2(xx - q.x, yy - q.y).length() / r
				if d < 1.0:
					p.blend(xx, yy, Color("#5e6356"), (1.0 - d) * 0.18 * (1.0 - i / 15.0))


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 32:
		out.append(c + Vector2.from_angle(TAU * i / 32.0) * r)
	return out
