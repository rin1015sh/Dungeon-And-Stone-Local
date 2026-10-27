extends RefCounted
## 거주 등급별 건물 꾸밈(사용자 2026-10-27, CT50·CT54 — tools/paint_city.gd 전용): 같은 시드로 그린 건물 위에 등급만큼 더 얹는다.
##   1 라비기온 13구역 = 지금 그림 그대로(꾸밈 없음) · 2 7구역 = 벽 등 둘 + 문가 화분 + 아래층 창 꽃상자 ·
##   3 컴멜비 5구역 = + 모든 창 꽃상자 + 처마에서 늘어뜨린 깃발 둘 · 4 3구역 = + 문 앞 흰 기둥 현관(금빛 박공) + 창 금테 +
##   돌림띠 금선 + 금박 두른 지붕선 + 길가 가로등 둘 + 깃발 사이 꽃줄 + 화분 대신 둥근 정원수 항아리.
## 벽 색·밝기는 Refine(구역 색), 자리는 Parts가 남긴 부품 자리(Paint.marks — 창·문·돌림띠)와 비율로 잡는다. 벽이 칠해진 곳(알파)에만 벽 장식.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")

const BANNER := [Color("#6e1f22"), Color("#23345a")]
const GOLD := Color("#c9a24a")
const LEAF := Color("#3f5a2c")
const POT := Color("#7a4a32")
const MARBLE := Color("#e9e2d2")
## 문 앞 현관을 달지 않는 건물(차양 밑 문 · 이미 기둥 현관이 있다).
const NO_PORTICO := ["shop", "exchange"]
const BOX := [Color("#3e5a44"), Color("#5a3a2c"), Color("#34486a")]
const FLOWER := [Color("#d8473a"), Color("#e8c04a"), Color("#e07a9a"), Color("#f2efe0")]


static func dress(p: Paint, id: String, tier: int) -> void:
	if tier < 2:
		return
	var ground := float(p.h - 1)
	var top := _top(p)
	for fx: float in [0.2, 0.8]:
		var x := p.w * fx
		var y := ground - p.h * 0.42
		if _wall(p, x, y):
			Parts.lantern(p, x, y, 1.1)
	var wins: Array = p.marks.get("window", [])
	for i in wins.size():
		var r: Rect2 = wins[i][0]
		if tier >= 3 or (r.position.y > p.h * 0.45 and i % 2 == 0):
			_flower_box(p, r, i)
	if tier >= 4:
		for w: Array in wins:
			_gold_frame(p, w[0], str(w[1]))
		for L: Array in (p.marks.get("ledge", []) if not id in NO_PORTICO else []):  # 거래소는 제 금띠가 있다
			var lr: Rect2 = L[0]
			Ink.line(p, lr.position + Vector2(2, 1), Vector2(lr.end.x - 2, lr.position.y + 1), 2.2, GOLD, 0.9, 0.2)
		if not id in NO_PORTICO:
			_portico(p, _main_door(p), ground)
	for fx: float in [0.1, 0.9]:
		if tier >= 4:
			_topiary(p, p.w * fx, ground)
		else:
			_planter(p, p.w * fx, ground)
	if tier < 3:
		return
	var tops: Array[Vector2] = []
	for i in 2:
		var x := p.w * (0.33 if i == 0 else 0.67)
		var y0 := top + (ground - top) * 0.3
		if _wall(p, x, y0) and _wall(p, x, y0 + p.h * 0.24):
			_hang(p, x, y0, p.h * 0.24, BANNER[(i + id.length()) % BANNER.size()])
			tops.append(Vector2(x, y0))
	if tier < 4:
		return
	_gilt(p)
	for fx: float in [0.035, 0.965]:
		Props.lamp_post(p, p.w * fx, ground, p.h * 0.4)
	if tops.size() == 2:
		_garland(p, tops[0] + Vector2(13, 2), tops[1] + Vector2(-13, 2))


## 꽃상자: 창 밑 칠한 나무 상자 + 넘쳐 나온 잎과 붉은·노란 꽃.
static func _flower_box(p: Paint, r: Rect2, i: int) -> void:
	var y := r.end.y + 6.0
	var box := Paint.rect_poly(r.position.x - 7, y, r.size.x + 14, 10)
	for k in 9:
		var bx := r.position.x - 4 + (r.size.x + 8) * k / 8.0
		var poly: Array = []
		for a in 10:
			poly.append(Vector2(bx, y - 1) + Vector2.from_angle(TAU * a / 10.0) * Vector2(6.5, 5.0) * (0.85 + 0.15 * p.rng.randf()))
		p.fill_poly(Paint.poly(poly), p.flat(LEAF.lightened(p.rng.randf_range(0.0, 0.2)), 0.2))
	p.fill_poly(box, p.flat(BOX[i % BOX.size()], 0.15))
	Ink.shade(p, box, Vector2(0, y), Vector2(0, y + 10), 0.0, 0.4)
	Ink.path(p, box, 1.5)
	for k in int(r.size.x / 7.0) + 2:
		var fx := r.position.x - 3 + p.rng.randf() * (r.size.x + 6)
		Ink.glow(p, fx, y - 3 - p.rng.randf() * 5.0, 3.2, FLOWER[(k + i) % FLOWER.size()], 0.95, false)


## 창 금테: 창틀 바깥으로 금빛 선 한 줄.
static func _gold_frame(p: Paint, r: Rect2, style: String) -> void:
	var f := 8.0
	Ink.path(p, Parts._shape(r.position.x - f, r.position.y - f, r.size.x + f * 2.0, r.size.y + f * 2.0, style if not style.is_empty() else "square"), 1.8, true, GOLD, 0.9, 0.2)


## 가장 큰 문(정문).
static func _main_door(p: Paint) -> Rect2:
	var best := Rect2()
	for d: Array in p.marks.get("door", []):
		var r: Rect2 = d[0]
		if r.get_area() > best.get_area():
			best = r
	return best


## 현관: 정문 양옆 흰 기둥 둘 + 위 들보 + 금빛 테 두른 낮은 박공.
static func _portico(p: Paint, door: Rect2, ground: float) -> void:
	if door.size.x <= 0.0:
		return
	var cw := clampf(door.size.x * 0.22, 12.0, 20.0)
	var x0 := door.position.x - 10.0 - cw
	var x1 := door.end.x + 10.0
	var top := door.position.y - 22.0
	for cx: float in [x0, x1]:
		var shaft := Paint.rect_poly(cx, top + 10, cw, ground - top - 10)
		p.fill_poly(shaft, func(x: int, y: int) -> Color:
			var t := (x - cx) / cw
			return p.vary(MARBLE.darkened(0.35 * t * t).lightened(0.1 * (1.0 - t)), x, y, 0.06))
		for k in 2:
			Ink.line(p, Vector2(cx + cw * (k + 1) / 3.0, top + 14), Vector2(cx + cw * (k + 1) / 3.0, ground - 10), 1.0, Ink.INK, 0.3, 0.2)
		Ink.path(p, shaft, 1.8)
		for yy: float in [top + 4, ground - 8]:
			var cap := Paint.rect_poly(cx - 4, yy, cw + 8, 8)
			p.fill_poly(cap, p.flat(MARBLE, 0.08))
			Ink.path(p, cap, 1.5)
	var beam := Paint.rect_poly(x0 - 8, top - 6, x1 + cw + 8 - (x0 - 8), 12)
	p.fill_poly(beam, p.flat(MARBLE, 0.08))
	Ink.path(p, beam, 1.8)
	Ink.line(p, Vector2(x0 - 6, top + 4), Vector2(x1 + cw + 6, top + 4), 2.0, GOLD, 0.95, 0.1)
	var mid := (x0 + x1 + cw) / 2.0
	var ped := Paint.poly([Vector2(x0 - 10, top - 6), Vector2(mid, top - 6 - (x1 - x0) * 0.22), Vector2(x1 + cw + 10, top - 6)])
	p.fill_poly(ped, p.flat(MARBLE.darkened(0.05), 0.08))
	Ink.path(p, ped, 2.0, true, GOLD.darkened(0.2), 1.0, 0.1)
	Ink.glow(p, mid, top - 6 - (x1 - x0) * 0.09, 5.0, GOLD, 0.95, false)


## 둥근 정원수 항아리: 금테 두른 흰 항아리 + 둥글게 다듬은 나무.
static func _topiary(p: Paint, cx: float, ground: float) -> void:
	var urn := Paint.poly([Vector2(cx - 14, ground - 30), Vector2(cx + 14, ground - 30), Vector2(cx + 10, ground - 8), Vector2(cx + 13, ground), Vector2(cx - 13, ground), Vector2(cx - 10, ground - 8)])
	p.fill_poly(urn, p.flat(MARBLE, 0.08))
	Ink.shade(p, urn, Vector2(cx - 14, 0), Vector2(cx + 14, 0), 0.0, 0.35)
	Ink.line(p, Vector2(cx - 14, ground - 28), Vector2(cx + 14, ground - 28), 2.0, GOLD, 0.95, 0.1)
	Ink.path(p, urn, 1.8)
	Ink.line(p, Vector2(cx, ground - 30), Vector2(cx, ground - 44), 3.0, Color("#3a2a1e"), 1.0, 0.1)
	var ball: Array = []
	for k in 20:
		ball.append(Vector2(cx, ground - 62) + Vector2.from_angle(TAU * k / 20.0) * 20.0 * (0.93 + 0.07 * p.rng.randf()))
	var bp := Paint.poly(ball)
	p.fill_poly(bp, p.flat(LEAF.lightened(0.12), 0.25))
	Ink.shade(p, bp, Vector2(cx - 20, ground - 82), Vector2(cx + 20, ground - 42), 0.0, 0.45)
	Ink.path(p, bp, 1.6)


## 금박 지붕선: 세로줄마다 칠해진 맨 위 몇 픽셀을 금빛으로(굴뚝·첨탑 끝까지 테가 돈다).
static func _gilt(p: Paint) -> void:
	for x in p.w:
		for y in p.h:
			if p.alpha_at(x, y) > 0.9:
				for k in 3:
					p.tint(x, y + k, GOLD.lightened(0.15 * (2 - k)), 0.75 - k * 0.2)
				break


## 칠해진 가장 위 줄(지붕 끝).
static func _top(p: Paint) -> float:
	for y in p.h:
		for x in range(0, p.w, 4):
			if p.alpha_at(x, y) > 0.9:
				return float(y)
	return 0.0


static func _wall(p: Paint, x: float, y: float) -> bool:
	return p.alpha_at(int(x), int(y)) > 0.9


## 문가 화분: 붉은 흙 화분 + 둥근 덤불(잎 덩이 몇 개).
static func _planter(p: Paint, cx: float, ground: float) -> void:
	var pot := Paint.poly([Vector2(cx - 15, ground - 26), Vector2(cx + 15, ground - 26), Vector2(cx + 11, ground), Vector2(cx - 11, ground)])
	p.fill_poly(pot, p.flat(POT, 0.12))
	Ink.shade(p, pot, Vector2(cx - 15, 0), Vector2(cx + 15, 0), 0.0, 0.45)
	Ink.path(p, pot, 1.8)
	for i in 7:
		var bx := cx + p.rng.randf_range(-14.0, 14.0)
		var by := ground - 30.0 - p.rng.randf_range(0.0, 20.0)
		var r := p.rng.randf_range(7.0, 11.0)
		var blob: Array = []
		for k in 12:
			blob.append(Vector2(bx, by) + Vector2.from_angle(TAU * k / 12.0) * r * (0.85 + 0.15 * p.rng.randf()))
		var poly := Paint.poly(blob)
		p.fill_poly(poly, p.flat(LEAF.lightened(p.rng.randf_range(-0.1, 0.15)), 0.18))
	for i in 3:
		var fx := cx + p.rng.randf_range(-10.0, 10.0)
		var fy := ground - 34.0 - p.rng.randf_range(0.0, 14.0)
		Ink.glow(p, fx, fy, 4.0, Color("#d8b04a") if i % 2 == 0 else Color("#b8473a"), 0.9, false)


## 처마 깃발: 가로대 + 아래가 제비꼬리로 갈라진 천 + 금빛 테.
static func _hang(p: Paint, x: float, y: float, len: float, c: Color) -> void:
	var hw := 17.0
	Ink.line(p, Vector2(x - hw - 4, y), Vector2(x + hw + 4, y), 3.0, Color("#2a2620"), 1.0, 0.2)
	var cloth := Paint.poly([Vector2(x - hw, y + 2), Vector2(x + hw, y + 2), Vector2(x + hw, y + len), Vector2(x, y + len - 14), Vector2(x - hw, y + len)])
	p.fill_poly(cloth, p.flat(c, 0.2))
	Ink.shade(p, cloth, Vector2(x - hw, 0), Vector2(x + hw, 0), 0.0, 0.35)
	for side: float in [-1.0, 1.0]:
		Ink.line(p, Vector2(x + side * (hw - 3), y + 4), Vector2(x + side * (hw - 3), y + len - 4), 1.6, GOLD, 0.9, 0.3)
	Ink.glow(p, x, y + len * 0.4, 5.0, GOLD, 0.8, false)
	Ink.path(p, cloth, 1.6)


## 꽃줄: 두 깃발 사이로 늘어진 초록 줄 + 띄엄띄엄 꽃.
static func _garland(p: Paint, a: Vector2, b: Vector2) -> void:
	var pts := PackedVector2Array()
	var sag := absf(b.x - a.x) * 0.12
	for i in 25:
		var t := i / 24.0
		pts.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * sag))
	Ink.path(p, pts, 3.4, false, LEAF.darkened(0.2), 1.0, 0.4)
	for i in range(2, 23, 3):
		Ink.glow(p, pts[i].x, pts[i].y + 2, 4.5, Color("#d8b04a") if i % 2 == 0 else Color("#c24a3c"), 0.9, false)
