extends RefCounted
## 거주 구역마다 다른 거리(사용자 2026-10-27 「밝고 고급지게」, CT54 — Street.gd가 부른다, tools/paint_city.gd 전용).
##   2 라비기온 7구역 = 젖지 않은 포석 · 막돌담 위 쇠 난간 · 마른 나무 대신 어린 잎나무 · 화분.
##   3 컴멜비 5구역 = 반듯한 사암 판석길 · 다듬은 돌담 위 다듬은 산울타리 · 잎 무성한 가로수 · 긴 의자 · 꽃밭.
##   4 컴멜비 3구역 = 흰 대리석 판석(금빛 줄눈 띠) · 흰 난간동자 난간 · 분수 · 석상 · 둥근 정원수 · 금장 가로등.
## 색은 마지막에 Refine(구역 색)이 한 번 더 민다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Props := preload("res://tools/city_art/Props.gd")

const LEAF := Color("#4a6a34")
const MARBLE := Color("#e6dfcf")
const GOLD := Color("#d4ac52")
const WATER := Color("#9fd0dc")
const FLOWER := [Color("#d8473a"), Color("#e8c04a"), Color("#e07a9a"), Color("#f2efe0")]
const CURB := 26


## 건물 사이 한 틈(a~b). g = 땅 높이(건물 바닥).
static func gap(p: Paint, a: float, b: float, g: float, i: int, tier: int) -> void:
	_wall(p, a, b, g, tier)
	var mid := (a + b) / 2.0
	var narrow := b - a < 150.0
	match tier:
		2:
			if narrow:
				_pot(p, mid, g + 16, 1.0)
			else:
				match i % 3:
					0:
						tree(p, mid, g + 14, 0.75, 0.55)
					1:
						Props.well(p, mid + 10, g + 18)
					2:
						Props.cart(p, mid, g + 22)
						_pot(p, mid - 60, g + 16, 1.0)
		3:
			if narrow:
				tree(p, mid, g + 14, 0.7, 0.9)
			else:
				match i % 3:
					0:
						tree(p, mid - 30, g + 14, 0.95, 1.0)
						Props.bench(p, mid + 40, g + 18, 80)
					1:
						_flower_bed(p, mid, g + 18, minf(b - a - 60.0, 160.0))
						tree(p, mid, g + 4, 0.8, 1.0)
					2:
						tree(p, mid, g + 14, 1.0, 1.0)
		_:
			if narrow:
				_topiary(p, mid, g + 16, 1.0)
			else:
				match i % 3:
					0:
						fountain(p, mid, g + 22)
					1:
						statue(p, mid, g + 18)
						_topiary(p, mid - 70, g + 16, 0.9)
						_topiary(p, mid + 70, g + 16, 0.9)
					2:
						tree(p, mid, g + 14, 1.0, 1.0)
						_flower_bed(p, mid, g + 20, minf(b - a - 60.0, 180.0))
	var lx := a + 22 if i > 0 else b - 30
	Props.lamp_post(p, lx, g + 20, 190)
	if tier >= 4:  # 금장 가로등: 기둥 금띠·꼭대기 금구슬
		for yy: float in [g + 14, g - 40, g - 150]:
			Ink.line(p, Vector2(lx - 5, yy), Vector2(lx + 5, yy), 3.0, GOLD, 1.0, 0.1)
		Ink.glow(p, lx, g + 20 - 190 - 12, 4.0, GOLD, 1.0, false)


## 담: 2 = 막돌담 + 쇠 난간 · 3 = 다듬은 돌담 + 산울타리 · 4 = 흰 대리석 난간(난간동자).
static func _wall(p: Paint, a: float, b: float, g: float, tier: int) -> void:
	var wh := 58.0 if tier < 4 else 46.0
	var wall := Paint.rect_poly(a - 4, g - wh, b - a + 8, wh)
	match tier:
		2:
			p.fill_poly(wall, Mat.rubble(p, Color("#5a564b")))
		3:
			p.fill_poly(wall, Mat.ashlar(p, Color("#8a7a5e"), int(a), int(g - wh), 40, 18))
		_:
			p.fill_poly(wall, Mat.ashlar(p, MARBLE, int(a), int(g - wh), 54, 23, Color("#8c8576")))
	Ink.shade(p, wall, Vector2(0, g - wh), Vector2(0, g), 0.05, 0.35)
	Ink.path(p, wall, 2.0)
	var cap := Paint.rect_poly(a - 6, g - wh - 6, b - a + 12, 8)
	p.fill_poly(cap, p.flat(Color("#6d695e") if tier == 2 else (Color("#a0906e") if tier == 3 else MARBLE), 0.12))
	Ink.path(p, cap, 1.6)
	var top := g - wh - 6
	match tier:
		2:
			var x := a + 6.0
			while x < b - 4.0:
				Ink.line(p, Vector2(x, top), Vector2(x, top - 36), 2.0, Color("#1c1a17"), 0.95, 0.2)
				x += 12.0
			Ink.line(p, Vector2(a, top - 32), Vector2(b, top - 32), 2.4, Color("#1c1a17"), 0.95, 0.3)
		3:
			var hedge := PackedVector2Array()
			hedge.append(Vector2(a - 2, top))
			var x := a
			while x <= b:
				hedge.append(Vector2(x, top - 30 - sin(x * 0.07) * 2.0 - p.rng.randf() * 3.0))
				x += 8.0
			hedge.append(Vector2(b + 2, top))
			p.fill_poly(hedge, p.flat(LEAF.darkened(0.1), 0.3))
			Ink.shade(p, hedge, Vector2(0, top - 34), Vector2(0, top), 0.0, 0.45)
			Ink.path(p, hedge, 1.6)
		_:
			var x := a + 4.0
			while x < b - 12.0:  # 난간동자(위아래가 굵은 기둥)
				var bal := Paint.poly([Vector2(x, top), Vector2(x + 12, top), Vector2(x + 10, top - 8), Vector2(x + 12, top - 18), Vector2(x + 9, top - 28),
					Vector2(x + 12, top - 32), Vector2(x, top - 32), Vector2(x + 3, top - 28), Vector2(x, top - 18), Vector2(x + 2, top - 8)])
				p.fill_poly(bal, p.flat(MARBLE, 0.06))
				Ink.shade(p, bal, Vector2(x, 0), Vector2(x + 12, 0), 0.0, 0.35)
				Ink.path(p, bal, 1.2)
				x += 17.0
			var rail := Paint.rect_poly(a - 6, top - 40, b - a + 12, 9)
			p.fill_poly(rail, p.flat(MARBLE, 0.06))
			Ink.path(p, rail, 1.6)
			Ink.line(p, Vector2(a - 4, top - 31), Vector2(b + 4, top - 31), 1.6, GOLD, 0.8, 0.1)


## 길바닥(인도·연석·차도). 2 = 마른 포석(Street._ground가 웅덩이 수를 줄인다) · 3 = 사암 판석 · 4 = 대리석 판석 + 놋쇠빛 띠.
static func ground(p: Paint, baseline: int, tier: int, height: int) -> void:
	var walk := Paint.rect_poly(0, baseline, p.w, CURB)
	var walk_c := Color("#8a7c62") if tier == 3 else MARBLE.darkened(0.08)
	p.fill_poly(walk, Mat.ashlar(p, walk_c, 0, baseline, 62, CURB, Color("#5a5040")))
	var curb := Paint.rect_poly(0, baseline + CURB, p.w, 8)
	p.fill_poly(curb, p.flat(walk_c.lightened(0.12), 0.15))
	Ink.path(p, curb, 1.6, false)
	var y := float(baseline + CURB + 8)
	var rh := 12.0
	var row := 0
	while y < height:  # 판석: 줄마다 높이가 커진다(가까울수록 크다), 줄마다 반 칸씩 엇갈린다
		var sw := rh * (3.2 if tier == 3 else 4.2)
		var x := -sw * (0.5 if row % 2 == 1 else 0.0)
		var band := tier >= 4 and row % 4 == 2
		while x < p.w:
			_slab(p, x, y, sw, rh, tier, band)
			x += sw
		if band:
			Ink.line(p, Vector2(0, y + 1), Vector2(p.w, y + 1), 1.6, GOLD, 0.55, 0.1)
		y += rh
		rh *= 1.14
		row += 1
	Ink.shade(p, Paint.rect_poly(0, baseline + CURB + 8, p.w, height - baseline - CURB - 8), Vector2(0, baseline + CURB + 8), Vector2(0, height), 0.18, 0.0)


static func _slab(p: Paint, x: float, y: float, sw: float, sh: float, tier: int, band: bool) -> void:
	var poly := Paint.rect_poly(x + 1, y + 1, sw - 2, sh - 1.5)
	var base := Color("#a08c68") if tier == 3 else (Color("#a8823e") if band else MARBLE.darkened(0.16))
	var tone := base.lightened(p.rng.randf_range(-0.06, 0.08))
	p.fill_poly(poly, func(x2: int, y2: int) -> Color:
		var t := (y2 - y) / sh
		var c := tone.lightened(0.08 * (1.0 - t)).darkened(0.12 * t * t)
		if tier >= 4 and p.nz("vs", x2, y2) > 0.72:
			c = c.darkened(0.1)  # 대리석 결
		return p.vary(c, x2, y2, 0.12), 0.96)
	Ink.path(p, poly, 1.1, true, Color("#3a342a"), 0.55, 0.2)


## 잎나무: 줄기 + 겹친 잎 덩이(위는 밝고 아래는 그늘). leaf = 잎 양(0.5 어린 나무 ~ 1 무성).
static func tree(p: Paint, cx: float, ground: float, s: float, leaf: float) -> void:
	var trunk_h := 120.0 * s
	Ink.line(p, Vector2(cx, ground), Vector2(cx + 4, ground - trunk_h), 10.0 * s, Color("#3a2a1e"), 1.0, 0.8)
	for k in 3:
		Ink.line(p, Vector2(cx + 3, ground - trunk_h * 0.8), Vector2(cx + (k - 1) * 40.0 * s, ground - trunk_h - 30.0 * s), 4.0 * s, Color("#3a2a1e"), 1.0, 1.0)
	var top := Vector2(cx + 4, ground - trunk_h - 40.0 * s)
	var n := int(7 + 9 * leaf)
	for k in n:
		var o := Vector2(p.rng.randf_range(-62, 62), p.rng.randf_range(-48, 34)) * s * (0.6 + 0.4 * leaf)
		var r := p.rng.randf_range(22.0, 36.0) * s * (0.7 + 0.3 * leaf)
		var blob: Array = []
		for a in 14:
			blob.append(top + o + Vector2.from_angle(TAU * a / 14.0) * r * (0.85 + 0.15 * p.rng.randf()))
		var bp := Paint.poly(blob)
		var c := LEAF.lightened(clampf(-o.y / (80.0 * s), -0.2, 0.25) + p.rng.randf_range(-0.05, 0.05))
		p.fill_poly(bp, p.flat(c, 0.22))
		Ink.shade(p, bp, top + o - Vector2(0, r), top + o + Vector2(0, r), 0.0, 0.4)
		Ink.path(p, bp, 1.2, true, Ink.INK, 0.45, 0.6)


## 분수: 둥근 돌 수반 + 가운데 기둥 위 작은 접시 + 솟는 물줄기.
static func fountain(p: Paint, cx: float, ground: float) -> void:
	var basin := Paint.poly([Vector2(cx - 74, ground - 34), Vector2(cx + 74, ground - 34), Vector2(cx + 66, ground), Vector2(cx - 66, ground)])
	var pool := Paint.poly([Vector2(cx - 70, ground - 34), Vector2(cx + 70, ground - 34), Vector2(cx + 60, ground - 42), Vector2(cx - 60, ground - 42)])
	p.fill_poly(pool, p.flat(WATER, 0.12))
	p.fill_poly(basin, p.flat(MARBLE, 0.06))
	Ink.shade(p, basin, Vector2(cx - 74, 0), Vector2(cx + 74, 0), 0.0, 0.4)
	Ink.line(p, Vector2(cx - 72, ground - 30), Vector2(cx + 72, ground - 30), 2.0, GOLD, 0.9, 0.1)
	Ink.path(p, basin, 2.0)
	var post := Paint.rect_poly(cx - 8, ground - 100, 16, 62)
	p.fill_poly(post, p.flat(MARBLE.darkened(0.05), 0.06))
	Ink.path(p, post, 1.6)
	var dish := Paint.poly([Vector2(cx - 36, ground - 104), Vector2(cx + 36, ground - 104), Vector2(cx + 20, ground - 92), Vector2(cx - 20, ground - 92)])
	p.fill_poly(dish, p.flat(MARBLE, 0.06))
	Ink.path(p, dish, 1.6)
	for k in 7:
		var dx := (k - 3) * 9.0
		var pts := PackedVector2Array()
		for t in 13:
			var u := t / 12.0
			pts.append(Vector2(cx + dx * u * 3.4, ground - 108 - sin(u * PI) * 34.0 + u * u * 62.0))
		Ink.path(p, pts, 1.6, false, WATER.lightened(0.2), 0.8, 0.2)
	Ink.glow(p, cx, ground - 110, 26.0, Color("#dff4ff"), 0.35, false)


## 석상: 계단식 받침 + 망토 두른 사람(팔 하나 든) — 흰 돌.
static func statue(p: Paint, cx: float, ground: float) -> void:
	var base := Paint.rect_poly(cx - 30, ground - 52, 60, 52)
	p.fill_poly(base, Mat.ashlar(p, MARBLE.darkened(0.05), int(cx), int(ground), 30, 26, Color("#8c8576")))
	Ink.path(p, base, 2.0)
	Ink.line(p, Vector2(cx - 26, ground - 44), Vector2(cx + 26, ground - 44), 1.6, GOLD, 0.9, 0.1)
	var body := Paint.poly([Vector2(cx - 18, ground - 54), Vector2(cx + 18, ground - 54), Vector2(cx + 12, ground - 120), Vector2(cx + 6, ground - 132),
		Vector2(cx - 6, ground - 132), Vector2(cx - 14, ground - 118)])
	p.fill_poly(body, p.flat(MARBLE, 0.07))
	Ink.shade(p, body, Vector2(cx - 18, 0), Vector2(cx + 18, 0), 0.0, 0.45)
	Ink.path(p, body, 1.8)
	Ink.line(p, Vector2(cx + 8, ground - 124), Vector2(cx + 26, ground - 156), 6.0, MARBLE.darkened(0.1), 1.0, 0.2)
	var head: Array = []
	for a in 12:
		head.append(Vector2(cx, ground - 142) + Vector2.from_angle(TAU * a / 12.0) * 9.0)
	p.fill_poly(Paint.poly(head), p.flat(MARBLE, 0.06))
	Ink.path(p, Paint.poly(head), 1.6)


static func _topiary(p: Paint, cx: float, ground: float, s: float) -> void:
	var urn := Paint.poly([Vector2(cx - 16 * s, ground - 34 * s), Vector2(cx + 16 * s, ground - 34 * s), Vector2(cx + 11 * s, ground - 8 * s), Vector2(cx + 14 * s, ground), Vector2(cx - 14 * s, ground), Vector2(cx - 11 * s, ground - 8 * s)])
	p.fill_poly(urn, p.flat(MARBLE, 0.06))
	Ink.shade(p, urn, Vector2(cx - 16 * s, 0), Vector2(cx + 16 * s, 0), 0.0, 0.4)
	Ink.line(p, Vector2(cx - 16 * s, ground - 32 * s), Vector2(cx + 16 * s, ground - 32 * s), 2.0, GOLD, 0.95, 0.1)
	Ink.path(p, urn, 1.8)
	for k in 2:
		var c := Vector2(cx, ground - (60.0 + 34.0 * k) * s)
		var ball: Array = []
		for a in 18:
			ball.append(c + Vector2.from_angle(TAU * a / 18.0) * (22.0 - 6.0 * k) * s)
		var bp := Paint.poly(ball)
		p.fill_poly(bp, p.flat(LEAF.lightened(0.1 * k), 0.25))
		Ink.shade(p, bp, c - Vector2(0, 22 * s), c + Vector2(0, 22 * s), 0.0, 0.45)
		Ink.path(p, bp, 1.4)


static func _pot(p: Paint, cx: float, ground: float, s: float) -> void:
	var pot := Paint.poly([Vector2(cx - 15 * s, ground - 26 * s), Vector2(cx + 15 * s, ground - 26 * s), Vector2(cx + 11 * s, ground), Vector2(cx - 11 * s, ground)])
	p.fill_poly(pot, p.flat(Color("#7a4a32"), 0.12))
	Ink.path(p, pot, 1.6)
	for k in 6:
		_dot(p, cx + p.rng.randf_range(-12, 12) * s, ground - (32.0 + p.rng.randf() * 16.0) * s, 7.0 * s, LEAF.lightened(0.1))
	for k in 3:
		_dot(p, cx + p.rng.randf_range(-10, 10) * s, ground - (34.0 + p.rng.randf() * 12.0) * s, 3.5 * s, FLOWER[k % FLOWER.size()])


## 꽃밭: 낮은 돌테 + 잎 + 색색 꽃.
static func _flower_bed(p: Paint, cx: float, ground: float, bw: float) -> void:
	for k in int(bw / 9.0):
		var x := cx - bw / 2.0 + p.rng.randf() * bw
		_dot(p, x, ground - 20 - p.rng.randf() * 10.0, 9.0, LEAF.lightened(p.rng.randf_range(0.0, 0.2)))
	for k in int(bw / 6.0):
		_dot(p, cx - bw / 2.0 + p.rng.randf() * bw, ground - 22 - p.rng.randf() * 12.0, 3.4, FLOWER[k % FLOWER.size()])
	var rim := Paint.rect_poly(cx - bw / 2.0 - 6, ground - 14, bw + 12, 14)
	p.fill_poly(rim, Mat.ashlar(p, MARBLE.darkened(0.15), int(cx), int(ground), 26, 14, Color("#6a6458")))
	Ink.path(p, rim, 1.8)


## 꽃·잎 한 점(꽉 찬 작은 원 — 빈 바탕 위에도 보인다).
static func _dot(p: Paint, x: float, y: float, r: float, c: Color) -> void:
	var pts: Array = []
	for a in 8:
		pts.append(Vector2(x, y) + Vector2.from_angle(TAU * a / 8.0) * r)
	p.fill_poly(Paint.poly(pts), p.flat(c, 0.15))
