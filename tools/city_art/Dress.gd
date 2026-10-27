extends RefCounted
## 거주 등급별 건물 꾸밈(사용자 2026-10-27, CT50 — tools/paint_city.gd 전용): 같은 시드로 그린 건물 위에 등급만큼 더 얹는다.
##   1 뒷골목 = 지금 그림 그대로(꾸밈 없음) · 2 장인 거리 = 벽 등 둘 + 문가 화분 ·
##   3 상인 거리 = + 처마에서 늘어뜨린 깃발 둘 + 덜 바랜 색(Buildings.finish) ·
##   4 고지대 = + 길가 쇠 가로등 둘 + 깃발 사이 꽃줄 + 금박 두른 지붕선 + 따뜻한 색 보정.
## 자리는 건물마다 모양이 달라 비율로 잡고, 벽이 칠해진 곳(알파)에만 벽 장식을 단다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")

const BANNER := [Color("#6e1f22"), Color("#23345a")]
const GOLD := Color("#c9a24a")
const LEAF := Color("#3f5a2c")
const POT := Color("#7a4a32")


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
	for fx: float in [0.1, 0.9]:
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
