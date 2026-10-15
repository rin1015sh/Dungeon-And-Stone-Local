extends RefCounted
## 차원광장(미궁 입구) 앞 그림 1280×720 — 하늘·원경은 거리 레이어를 그대로 쓰고(날씨 따라 바뀜) 이 그림은 그 위에 얹는다(위쪽은 투명).
## 양옆 높은 집 · 뒤쪽 아치 회랑 · 가운데 3단 단상 위 돌 고리(포탈이 열리는 자리, 고리 안은 회랑이 비친다) · 화로 · 가로등 · 줄 선 탐험가 뒷모습.
## 고리 위치·크기는 render.json city.plaza.portal_rect와 맞춘다(고리 안쪽 타원 = 포탈).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Npc := preload("res://tools/city_art/Npcs.gd")

const W := 1280
const H := 720
const HORIZON := 455.0  ## 회랑 발치 = 광장 바닥이 시작하는 높이
const VP := Vector2(640, 300)
const RING_C := Vector2(640, 300)  ## 고리 중심
const RING_OUT := Vector2(188, 192)
const RING_IN := Vector2(142, 148)
const FIRE := Color("#ffb45c")


static func paint(seed_value: int) -> Paint:
	var p := Paint.new(W, H, seed_value)
	_arcade(p)
	_ground(p)
	_house(p, -20.0, 300.0, 60.0, Mat.plaster(p, Color("#7a6c55"), 0.2), 1.0)
	_house(p, 980.0, 1300.0, 40.0, Mat.brick(p, Color("#6a4434"), 980, 40), -1.0)
	_dais(p)
	_ring(p)
	for bx: float in [430.0, 850.0]:
		_brazier(p, Vector2(bx, 520))
	Props.lamp_post(p, 345, 600, 190)
	Props.lamp_post(p, 935, 600, 190)
	_crowd(p)
	Ink.grade(p, 0.28, 1.06)
	Ink.finish(p, 0.035)
	return p


## 뒤쪽 아치 회랑(고리 뒤로 지나간다): 마름돌 벽 + 어두운 아치 + 처마 띠.
static func _arcade(p: Paint) -> void:
	var wall := Paint.rect_poly(240, 330, 800, HORIZON - 330 + 4)
	p.fill_poly(wall, Mat.ashlar(p, Color("#625d51"), 240, 330, 44, 20))
	var x := 262.0
	while x < 1010.0:
		var arch := Paint.arch_poly(x, 362, 50, HORIZON - 362)
		p.fill_poly(arch, p.flat(Color("#16140f"), 0.1))
		Ink.path(p, arch, 2.0)
		x += 74.0
	Parts.ledge(p, 236, 322, 808, 12)
	Ink.shade(p, wall, Vector2(0, 330), Vector2(0, HORIZON), 0.1, 0.45)
	Ink.path(p, wall, 2.2)


## 광장 바닥: 판석(먼 곳일수록 촘촘한 가로줄 + 소실점으로 모이는 세로줄) + 단상을 두른 둥근 무늬 띠.
static func _ground(p: Paint) -> void:
	var g := Paint.rect_poly(0, HORIZON, W, H - HORIZON)
	p.fill_poly(g, p.flat(Color("#6a655a"), 0.22))
	var y := HORIZON
	var k := 0
	while y < H:
		Ink.line(p, Vector2(0, y), Vector2(W, y), 1.4 + k * 0.15, Color("#2a2620"), 0.55, 0.6)
		k += 1
		y += 6.0 + k * k * 1.6
	for i in range(-14, 15):
		var bottom := Vector2(640 + i * 120.0, H + 40)
		var top := VP + (bottom - VP) * ((HORIZON - VP.y) / (bottom.y - VP.y))
		Ink.line(p, top, bottom, 1.4, Color("#2a2620"), 0.45, 0.6)
	for r: Vector2 in [Vector2(470, 120), Vector2(520, 140)]:
		Ink.path(p, _ellipse(Vector2(640, 560), r, 64), 3.0, true, Color("#9a927e"), 0.5, 0.6)
	Ink.shade(p, g, Vector2(0, HORIZON), Vector2(0, H), 0.55, 0.0)
	Ink.strokes(p, g, 0.6, 18.0, 6.0, 5.0, 0.1, 0.3)


## 양옆의 높은 집(앞면 + 소실점 쪽 옆면). side 1 = 왼쪽 집(옆면이 오른쪽).
static func _house(p: Paint, x0: float, x1: float, top: float, wall_sh: Callable, side: float) -> void:
	var front := Paint.rect_poly(x0, top + 60, x1 - x0, 470 - top - 60 + 30)
	var edge := x1 if side > 0.0 else x0
	var depth := 46.0 * side
	var side_poly := Paint.poly([Vector2(edge, top + 60), Vector2(edge + depth, top + 110), Vector2(edge + depth, 470), Vector2(edge, 500)])
	p.fill_poly(side_poly, wall_sh)
	Ink.shade(p, side_poly, Vector2(edge, 0), Vector2(edge + depth, 0), 0.35, 0.6)
	Ink.path(p, side_poly, 2.2)
	p.fill_poly(front, wall_sh)
	var roof := Paint.poly([Vector2(x0 - 12, top + 64), Vector2(x1 + 12, top + 64), Vector2((x0 + x1) / 2.0 + side * 40.0, top - 40)])
	Parts.roof(p, roof, Mat.slate(p, Color("#3c3f3c"), 0, 0))
	Parts.plinth(p, x0, 470, x1 - x0, 30)
	var cols := 3
	var cw := (x1 - x0) / cols
	for r in 3:
		for c in cols:
			var wx := x0 + c * cw + cw * 0.3
			var wy := top + 100 + r * 105
			Parts.window(p, wx, wy, cw * 0.4, 62, "arch" if r == 0 else "square", (r + c) % 3 == 1, r > 0)
	Ink.shade(p, front, Vector2(0, top), Vector2(0, 500), 0.1, 0.45)
	Ink.path(p, front, 2.4)


## 3단 단상(앞면 + 윗면 띠).
static func _dais(p: Paint) -> void:
	var steps := [[380.0, 900.0, 528.0, 30.0], [420.0, 860.0, 502.0, 26.0], [460.0, 820.0, 480.0, 22.0]]
	for st: Array in steps:
		var x0: float = st[0]
		var x1: float = st[1]
		var y: float = st[2]
		var hgt: float = st[3]
		var top := Paint.poly([Vector2(x0, y), Vector2(x1, y), Vector2(x1 - 14, y - 10), Vector2(x0 + 14, y - 10)])
		p.fill_poly(top, p.flat(Color("#8e8878"), 0.15))
		Ink.path(p, top, 1.8)
		var front := Paint.rect_poly(x0, y, x1 - x0, hgt)
		p.fill_poly(front, Mat.ashlar(p, Color("#6e6a5e"), int(x0), int(y), 52, int(hgt)))
		Ink.shade(p, front, Vector2(0, y), Vector2(0, y + hgt), 0.1, 0.5)
		Ink.path(p, front, 2.2)


## 돌 고리: 두꺼운 고리(이음매 16개 + 머릿돌) + 아래 받침 둘 + 희미하게 새긴 문양.
static func _ring(p: Paint) -> void:
	for sx: float in [-1.0, 1.0]:
		var bx := RING_C.x + sx * 150.0
		var foot := Paint.rect_poly(bx - 36, 418, 72, 62)
		p.fill_poly(foot, Mat.ashlar(p, Color("#6a665a"), int(bx - 36), 418, 36, 20))
		Ink.shade(p, foot, Vector2(bx - 36, 0), Vector2(bx + 36, 0), 0.0 if sx < 0.0 else 0.4, 0.4 if sx < 0.0 else 0.0)
		Ink.path(p, foot, 2.2)
	var outer := _ellipse(RING_C, RING_OUT, 72)
	var inner := _ellipse(RING_C, RING_IN, 72)
	var band := PackedVector2Array(outer)
	band.append(outer[0])
	for i in range(inner.size() - 1, -1, -1):
		band.append(inner[i])
	band.append(inner[inner.size() - 1])
	p.fill_poly(band, p.flat(Color("#6c685b"), 0.3))
	Ink.shade(p, band, RING_C + Vector2(-RING_OUT.x, -RING_OUT.y), RING_C + RING_OUT, 0.0, 0.5)
	Ink.strokes(p, band, 0.8, 12.0, 4.0, 30.0, 0.12, 0.35)
	for i in 16:
		var a := TAU * i / 16.0 + PI / 16.0
		var d := Vector2(cos(a), sin(a))
		Ink.line(p, RING_C + d * RING_IN, RING_C + d * RING_OUT, 2.0, Ink.INK, 0.85, 0.4)
		var mid := RING_C + d * (RING_IN + RING_OUT) / 2.0
		var t := Vector2(-d.y, d.x) * 7.0
		Ink.line(p, mid - t, mid + t * 0.4 + d * 5.0, 1.6, Color("#4f8f86"), 0.55, 0.6)
		Ink.line(p, mid + d * -4.0, mid + t, 1.4, Color("#4f8f86"), 0.45, 0.6)
	var key := Paint.poly([RING_C + Vector2(-26, -RING_OUT.y - 14), RING_C + Vector2(26, -RING_OUT.y - 14), RING_C + Vector2(18, -RING_IN.y + 6), RING_C + Vector2(-18, -RING_IN.y + 6)])
	p.fill_poly(key, Mat.ashlar(p, Color("#8a8574"), 0, 0, 30, 18))
	Ink.path(p, key, 2.4)
	Ink.path(p, outer, 2.8)
	Ink.path(p, inner, 2.8)
	Ink.shade(p, _ellipse(RING_C, RING_IN, 48), RING_C, RING_C + Vector2(0, RING_IN.y), 0.25, 0.45)


static func _brazier(p: Paint, base: Vector2) -> void:
	for sx: float in [-1.0, 0.0, 1.0]:
		Ink.line(p, base + Vector2(sx * 16, 0), base + Vector2(sx * 6, -44), 4.0, Color("#26221d"), 1.0, 0.3)
	var bowl := Paint.poly([base + Vector2(-26, -58), base + Vector2(26, -58), base + Vector2(18, -42), base + Vector2(-18, -42)])
	p.fill_poly(bowl, p.flat(Color("#3a342c"), 0.15))
	Ink.path(p, bowl, 2.0)
	for k in 5:
		var fx := base.x - 18 + k * 9.0
		var fh := 26.0 + 14.0 * sin(k * 1.7)
		var flame := Paint.poly([Vector2(fx - 7, base.y - 58), Vector2(fx + 7, base.y - 58), Vector2(fx + 2, base.y - 58 - fh)])
		p.fill_poly(flame, p.flat(Color("#ffcf7a") if k % 2 == 0 else Color("#ff8a3a"), 0.1))
	Ink.glow(p, base.x, base.y - 70, 160.0, FIRE, 0.55, true)
	Ink.glow(p, base.x, base.y - 70, 40.0, Color("#fff0c0"), 0.6, true)


## 포탈을 기다리는 탐험가들(뒷모습) — 과하지 않게 다섯, 남녀 섞어서.
static func _crowd(p: Paint) -> void:
	Npc.figure(p, 190, 668, 168, {"back": true, "body": "male", "top": Color("#5a4632"), "bottom": Color("#3e362c"), "pack": Color("#6a5236"), "hair": "short", "hair_c": Color("#2c2016"), "spear": true, "light": 1.0})
	Npc.figure(p, 262, 640, 150, {"back": true, "body": "female", "top": Color("#4a5444"), "bottom": Color("#3a3a32"), "hair": "long", "hair_c": Color("#5a3a22"), "light": 1.0})
	Npc.figure(p, 1040, 662, 172, {"back": true, "body": "stout", "top": Color("#6a3e30"), "bottom": Color("#3e3428"), "pack": Color("#5a4630"), "hair": "bald", "light": -1.0})
	Npc.figure(p, 1112, 636, 148, {"back": true, "body": "female", "top": Color("#3e3a48"), "lower": "robe", "hair": "hood", "hood_c": Color("#4a4458"), "light": -1.0})
	Npc.figure(p, 980, 700, 186, {"back": true, "body": "male", "top": Color("#4e4a40"), "bottom": Color("#2e2a24"), "hair": "bun", "hair_c": Color("#1e1812"), "spear": true, "light": -1.0})


static func _ellipse(c: Vector2, r: Vector2, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return out
