extends RefCounted
## 차원광장(미궁 입구) 앞 그림 1280×720 — 하늘·원경은 거리 레이어를 그대로 쓰고(날씨 따라 바뀜) 이 그림은 그 위에 얹는다(위쪽은 투명).
## 입체감(2026-10-15 사용자 요청 "더 입체적으로, 옆 건물은 치우되 텅 비지 않게"): 모든 것을 3D 좌표(미터)로 놓고 한 점 투시로 옮긴다.
##   뒤 = 단상을 둘러싼 반원 열주 회랑(가까운 양끝은 크고 먼 가운데는 작고 뿌옇다) · 바닥 = 단상을 중심으로 한 동심원·방사 판석
##   가운데 = 3단 둥근 단상 + 두께가 보이는 돌 고리(안쪽 면 = 포탈 자리) · 양옆 화로 · 깊이마다 크기가 다른 탐험가·경비병
##   앞 = 화면 양끝을 가르는 깃발 기둥(가까운 물체로 깊이를 준다) · 짐 상자.
## 포탈 자리(고리 안쪽 뒷면 원의 상자)는 render.json city.plaza.portal_rect와 맞춘다 — portal_rect()가 계산한다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Npc := preload("res://tools/city_art/Npcs.gd")

const W := 1280
const H := 720
const HOR := 330.0  ## 지평선(눈높이)
const F := 700.0  ## 초점 거리(px) — 1m가 깊이 z에서 F/z px
const EYE := 1.7  ## 눈높이(m)
const CZ := 12.0  ## 단상·고리 중심 깊이
const RING_Y := 3.8  ## 고리 중심 높이
const RING_OUT := 3.1
const RING_IN := 2.45
const RING_T := 0.45  ## 고리 두께의 반
const EXEDRA_R := 20.0  ## 회랑 반지름
const STONE := Color("#6f6b62")
const FOG := Color("#8d948e")
const FIRE := Color("#ffb45c")


static func paint(seed_value: int) -> Paint:
	var p := Paint.new(W, H, seed_value)
	_ground(p)
	_exedra(p)
	_dais(p)
	_ring(p)
	for sx: float in [-1.0, 1.0]:
		_brazier(p, sx * 6.4, 9.6)
	_people(p)
	Props.barrel(p, _P(-5.6, 0, 6.6).x, _P(-5.6, 0, 6.6).y, 0.7 * _s(6.6), 0.95 * _s(6.6))
	Props.crate(p, _P(-4.8, 0, 6.0).x, _P(-4.8, 0, 6.0).y, 0.6 * _s(6.0))
	Props.barrel(p, _P(5.4, 0, 6.8).x, _P(5.4, 0, 6.8).y, 0.7 * _s(6.8), 0.95 * _s(6.8))
	Props.crate(p, _P(4.7, 0, 6.2).x, _P(4.7, 0, 6.2).y, 0.55 * _s(6.2))
	for sx: float in [-1.0, 1.0]:
		_banner(p, sx * 3.7, 4.4)
	Ink.grade(p, 0.28, 1.06)
	Ink.finish(p, 0.035)
	return p


## 고리 안쪽 뒷면 원의 상자(포탈 셰이더 자리) — render.json city.plaza.portal_rect.
static func portal_rect() -> Rect2:
	var c := _P(0, RING_Y, CZ + RING_T)
	var r := RING_IN * _s(CZ + RING_T)
	return Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)


static func _P(x: float, y: float, z: float) -> Vector2:
	return Vector2(W / 2.0 + F * x / z, HOR - F * (y - EYE) / z)


static func _s(z: float) -> float:
	return F / z


## 멀수록 안개 색으로.
static func _hz(c: Color, z: float, k: float = 1.0) -> Color:
	return c.lerp(FOG, clampf((z - 10.0) / 40.0, 0.0, 0.55) * k)


## 바닥(수평 원) 위 점: 각 a(0 = 오른쪽, π/2 = 안쪽 깊이).
static func _circ(r: float, y: float, a: float, cz: float = CZ) -> Vector2:
	return _P(r * cos(a), y, cz + r * sin(a))


## 판석 바닥: 단상 둘레 동심원 + 방사 이음매(가까울수록 굵다) + 먼 쪽 안개.
static func _ground(p: Paint) -> void:
	var g := Paint.rect_poly(0, HOR - 4, W, H - HOR + 4)
	p.fill_poly(g, p.flat(Color("#615d53"), 0.22))
	Ink.strokes(p, g, 0.5, 20.0, 6.0, 3.0, 0.1, 0.3)
	for r: float in [6.0, 7.5, 9.5, 12.0, 15.0, 18.5]:
		var pts := PackedVector2Array()
		for i in 121:
			var a := TAU * i / 120.0
			var z := CZ + r * sin(a)
			if z < 1.6:
				if pts.size() > 1:
					_ground_line(p, pts, z)
				pts = PackedVector2Array()
				continue
			pts.append(_circ(r, 0, a))
		if pts.size() > 1:
			_ground_line(p, pts, CZ)
	for i in 24:
		var a := TAU * i / 24.0 + PI / 24.0
		var r1 := 18.5
		while CZ + r1 * sin(a) < 1.6:
			r1 -= 0.5
		var segs := 6
		for k in segs:  # 가까운 쪽일수록 굵게
			var ra := lerpf(5.5, r1, float(k) / segs)
			var rb := lerpf(5.5, r1, float(k + 1) / segs)
			var z := CZ + (ra + rb) / 2.0 * sin(a)
			Ink.line(p, _circ(ra, 0, a), _circ(rb, 0, a), clampf(_s(z) / 45.0, 1.0, 4.0), Color("#2a2620"), 0.5, 0.5)
	Ink.shade(p, g, Vector2(0, HOR), Vector2(0, H), 0.0, 0.5)
	Ink.shade(p, Paint.rect_poly(0, HOR - 4, W, 60), Vector2(0, HOR + 60), Vector2(0, HOR), 0.0, 0.35, FOG)


static func _ground_line(p: Paint, pts: PackedVector2Array, _z: float) -> void:
	for i in pts.size() - 1:  # 아래(가까운 쪽)일수록 굵게
		var w := clampf((pts[i].y - HOR) / 45.0, 1.0, 4.5)
		Ink.line(p, pts[i], pts[i + 1], w, Color("#2a2620"), 0.55, 0.6)
		Ink.line(p, pts[i] + Vector2(0, w), pts[i + 1] + Vector2(0, w), w * 1.6, Color("#948c78"), 0.16, 0.6)


## 반원 열주 회랑: 뒷벽(어두운 출입구) → 기단 → 기둥(먼 것부터) → 처마. 멀수록 작고 뿌옇다.
static func _exedra(p: Paint) -> void:
	var a0 := deg_to_rad(18.0)
	var a1 := deg_to_rad(162.0)
	var n := 48
	var wall_r := EXEDRA_R + 1.6
	for i in n:  # 뒷벽 + 출입구
		var aa := lerpf(a0, a1, float(i) / n)
		var ab := lerpf(a0, a1, float(i + 1) / n)
		var z := CZ + wall_r * sin((aa + ab) / 2.0)
		var quad := Paint.poly([_circ(wall_r, 0, aa), _circ(wall_r, 0, ab), _circ(wall_r, 6.2, ab), _circ(wall_r, 6.2, aa)])
		p.fill_poly(quad, p.flat(_hz(Color("#38342e"), z, 0.35), 0.18))
		Ink.shade(p, quad, _circ(wall_r, 6.2, aa), _circ(wall_r, 0, aa), 0.45, 0.1)
		var ceil := Paint.poly([_circ(EXEDRA_R, 6.2, aa), _circ(EXEDRA_R, 6.2, ab), _circ(wall_r, 6.2, ab), _circ(wall_r, 6.2, aa)])
		p.fill_poly(ceil, p.flat(_hz(Color("#211e1a"), z, 0.3), 0.1))
		if i % 3 == 1:
			var door := Paint.poly([_circ(wall_r, 0.6, aa), _circ(wall_r, 0.6, ab), _circ(wall_r, 3.6, ab), _circ(wall_r, 4.3, (aa + ab) / 2.0), _circ(wall_r, 3.6, aa)])
			p.fill_poly(door, p.flat(_hz(Color("#110f0c"), z, 0.25), 0.1))
			Ink.path(p, door, maxf(1.0, _s(z) / 40.0), true, Ink.INK, 0.6, 0.4)
	for i in n:  # 기단 앞면 + 윗면
		var aa := lerpf(a0, a1, float(i) / n)
		var ab := lerpf(a0, a1, float(i + 1) / n)
		var z := CZ + EXEDRA_R * sin((aa + ab) / 2.0)
		var top := Paint.poly([_circ(EXEDRA_R - 1.0, 0.6, aa), _circ(EXEDRA_R - 1.0, 0.6, ab), _circ(wall_r, 0.6, ab), _circ(wall_r, 0.6, aa)])
		p.fill_poly(top, p.flat(_hz(STONE.lightened(0.12), z), 0.12))
		var front := Paint.poly([_circ(EXEDRA_R - 1.0, 0, aa), _circ(EXEDRA_R - 1.0, 0, ab), _circ(EXEDRA_R - 1.0, 0.6, ab), _circ(EXEDRA_R - 1.0, 0.6, aa)])
		p.fill_poly(front, p.flat(_hz(STONE.darkened(0.15), z), 0.12))
	var cols: Array = []
	for k in 17:
		cols.append(lerpf(a0 + 0.04, a1 - 0.04, float(k) / 16.0))
	cols.sort_custom(func(x: float, y: float) -> bool: return sin(x) > sin(y))  # 먼 것부터
	for a: float in cols:
		_column(p, EXEDRA_R * cos(a), CZ + EXEDRA_R * sin(a))
	for i in n:  # 처마(기둥 위 들보)
		var aa := lerpf(a0, a1, float(i) / n)
		var ab := lerpf(a0, a1, float(i + 1) / n)
		var z := CZ + EXEDRA_R * sin((aa + ab) / 2.0)
		var beam := Paint.poly([_circ(EXEDRA_R, 6.2, aa), _circ(EXEDRA_R, 6.2, ab), _circ(EXEDRA_R, 7.4, ab), _circ(EXEDRA_R, 7.4, aa)])
		p.fill_poly(beam, p.flat(_hz(STONE, z), 0.14))
		Ink.line(p, _circ(EXEDRA_R, 6.2, aa), _circ(EXEDRA_R, 6.2, ab), maxf(1.0, _s(z) / 30.0), Ink.INK, 0.7, 0.3)
		Ink.line(p, _circ(EXEDRA_R, 7.4, aa), _circ(EXEDRA_R, 7.4, ab), maxf(1.2, _s(z) / 24.0), Ink.INK, 0.8, 0.3)
	for f: Array in [[-6.0, 27.0, 0], [5.0, 28.5, 1], [-11.0, 26.0, 2], [9.5, 25.5, 3]]:  # 회랑 아래 오가는 사람(작다)
		_person(p, float(f[0]), float(f[1]), int(f[2]), true)


static func _column(p: Paint, x: float, z: float) -> void:
	var s := _s(z)
	var hw := 0.36 * s
	var base := _P(x, 0.6, z)
	var top := _P(x, 6.2, z)
	var shaft := Paint.rect_poly(base.x - hw, top.y, hw * 2.0, base.y - top.y)
	p.fill_poly(shaft, p.flat(_hz(STONE.lightened(0.08), z), 0.15))
	Ink.shade(p, shaft, Vector2(base.x - hw, 0), Vector2(base.x + hw, 0), 0.0, 0.55)
	for k in 3:  # 세로 홈
		var fx := base.x - hw * 0.5 + hw * 0.5 * k
		Ink.line(p, Vector2(fx, top.y + 2), Vector2(fx, base.y - 2), maxf(0.6, s / 60.0), Ink.INK, 0.25, 0.3)
	for b: Array in [[base.y - 0.25 * s, 0.25 * s], [top.y, 0.3 * s]]:
		var cap := Paint.rect_poly(base.x - hw * 1.35, float(b[0]), hw * 2.7, float(b[1]))
		p.fill_poly(cap, p.flat(_hz(STONE.lightened(0.15), z), 0.1))
		Ink.path(p, cap, maxf(1.0, s / 35.0))
	Ink.path(p, shaft, maxf(1.0, s / 30.0))


## 3단 둥근 단상: 단마다 앞쪽 옆면(돌 이음매) + 윗면.
static func _dais(p: Paint) -> void:
	var tiers := [[5.4, 0.0, 0.28], [4.6, 0.28, 0.56], [3.8, 0.56, 0.84]]
	for t: Array in tiers:
		var r: float = t[0]
		var side := PackedVector2Array()
		for i in 41:
			side.append(_circ(r, float(t[2]), PI + PI * i / 40.0))
		for i in 41:
			side.append(_circ(r, float(t[1]), TAU - PI * i / 40.0))
		p.fill_poly(side, p.flat(STONE.darkened(0.1), 0.18))
		Ink.shade(p, side, _circ(r, 0, PI * 1.5), _circ(r, 0, PI), 0.05, 0.55)
		for i in 16:
			var a := PI + PI * (i + 0.5) / 16.0
			Ink.line(p, _circ(r, float(t[1]), a), _circ(r, float(t[2]), a), 1.4, Ink.INK, 0.6, 0.3)
		Ink.path(p, side, 2.0)
		var top := PackedVector2Array()
		for i in 64:
			top.append(_circ(r, float(t[2]), TAU * i / 64.0))
		p.fill_poly(top, p.flat(STONE.lightened(0.14), 0.16))
		Ink.shade(p, top, _circ(r, 0, PI * 0.5), _circ(r, 0, PI * 1.5), 0.25, 0.0)
		Ink.path(p, top, 1.8)


## 돌 고리: 받침 둘 → 안쪽 면(두께 — 위쪽은 아랫면이 보인다) → 앞면(이음매 16·문양·머릿돌).
static func _ring(p: Paint) -> void:
	for sx: float in [-1.0, 1.0]:
		_block(p, sx * 2.35, 0.84, 0.95, 0.42, 0.55)
	var zf := CZ - RING_T
	var zb := CZ + RING_T
	var n := 64
	for i in n:
		var a := TAU * i / n
		var b := TAU * (i + 1) / n
		var quad := Paint.poly([_ringp(RING_IN, a, zf), _ringp(RING_IN, b, zf), _ringp(RING_IN, b, zb), _ringp(RING_IN, a, zb)])
		var under := sin((a + b) / 2.0)  # 위쪽(아랫면)일수록 어둡다
		p.fill_poly(quad, p.flat(STONE.darkened(0.3 + 0.25 * maxf(0.0, under)), 0.12))
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in n:
		outer.append(_ringp(RING_OUT, TAU * i / n, zf))
		inner.append(_ringp(RING_IN, TAU * i / n, zf))
	var band := PackedVector2Array(outer)
	band.append(outer[0])
	for i in range(n - 1, -1, -1):
		band.append(inner[i])
	band.append(inner[n - 1])
	p.fill_poly(band, p.flat(Color("#6e6a5d"), 0.3))
	var c := _P(0, RING_Y, zf)
	var ro := RING_OUT * _s(zf)
	Ink.shade(p, band, c + Vector2(-ro, -ro), c + Vector2(ro, ro), 0.0, 0.5)
	Ink.strokes(p, band, 0.8, 12.0, 4.0, 30.0, 0.12, 0.35)
	for i in 16:
		var a := TAU * i / 16.0 + PI / 16.0
		var pi_ := _ringp(RING_IN, a, zf)
		var po := _ringp(RING_OUT, a, zf)
		Ink.line(p, pi_, po, 2.0, Ink.INK, 0.85, 0.4)
		var mid := (pi_ + po) / 2.0
		var d := (po - pi_).normalized()
		var t := Vector2(-d.y, d.x) * 7.0
		Ink.line(p, mid - t, mid + t * 0.4 + d * 5.0, 1.6, Color("#4f8f86"), 0.55, 0.6)
		Ink.line(p, mid - d * 4.0, mid + t, 1.4, Color("#4f8f86"), 0.45, 0.6)
	var key := Paint.poly([_P(-0.45, RING_Y + RING_OUT + 0.25, zf - 0.1), _P(0.45, RING_Y + RING_OUT + 0.25, zf - 0.1), _P(0.32, RING_Y + RING_IN - 0.05, zf - 0.1), _P(-0.32, RING_Y + RING_IN - 0.05, zf - 0.1)])
	p.fill_poly(key, p.flat(STONE.lightened(0.12), 0.2))
	Ink.path(p, key, 2.4)
	Ink.path(p, outer, 2.8)
	Ink.path(p, inner, 2.8)


static func _ringp(r: float, a: float, z: float) -> Vector2:
	return _P(r * cos(a), RING_Y + r * sin(a), z)


## 앞을 보는 돌덩이(x 가운데, 바닥 y0, 높이 h, 폭 w, 깊이 d) — 앞면 + 윗면 + 가운데 쪽 옆면.
static func _block(p: Paint, x: float, y0: float, h: float, w: float, d: float) -> void:
	var z0 := CZ - d
	var x0 := x - w
	var x1 := x + w
	var front := Paint.poly([_P(x0, y0, z0), _P(x1, y0, z0), _P(x1, y0 + h, z0), _P(x0, y0 + h, z0)])
	var sx := x0 if x > 0.0 else x1
	var side := Paint.poly([_P(sx, y0, z0), _P(sx, y0, CZ + d), _P(sx, y0 + h, CZ + d), _P(sx, y0 + h, z0)])
	p.fill_poly(side, p.flat(STONE.darkened(0.35), 0.15))
	Ink.path(p, side, 1.8)
	p.fill_poly(front, Mat.ashlar(p, STONE, 0, 0, 34, 18))
	Ink.shade(p, front, _P(x0, 0, z0), _P(x1, 0, z0), 0.0 if x < 0.0 else 0.4, 0.4 if x < 0.0 else 0.0)
	Ink.path(p, front, 2.2)


static func _brazier(p: Paint, x: float, z: float) -> void:
	var s := _s(z)
	var base := _P(x, 0, z)
	_shadow(p, base, s * 0.9)
	for sx: float in [-1.0, 0.0, 1.0]:
		Ink.line(p, base + Vector2(sx * 0.3 * s, 0), base + Vector2(sx * 0.1 * s, -0.95 * s), maxf(2.0, s / 18.0), Color("#26221d"), 1.0, 0.3)
	var top := base.y - 1.1 * s
	var bowl := Paint.poly([Vector2(base.x - 0.5 * s, top), Vector2(base.x + 0.5 * s, top), Vector2(base.x + 0.34 * s, top + 0.22 * s), Vector2(base.x - 0.34 * s, top + 0.22 * s)])
	p.fill_poly(bowl, p.flat(Color("#3a342c"), 0.15))
	Ink.path(p, bowl, 2.0)
	for k in 6:
		var fx := base.x - 0.4 * s + k * 0.16 * s
		var fh := (0.5 + 0.3 * sin(k * 1.7)) * s
		var flame := Paint.poly([Vector2(fx - 0.12 * s, top), Vector2(fx + 0.12 * s, top), Vector2(fx + 0.03 * s, top - fh)])
		p.fill_poly(flame, p.flat(Color("#ffcf7a") if k % 2 == 0 else Color("#ff8a3a"), 0.1))
	Ink.glow(p, base.x, top - 0.3 * s, 3.2 * s, FIRE, 0.5, true)
	Ink.glow(p, base.x, top - 0.3 * s, 0.8 * s, Color("#fff0c0"), 0.6, true)


## 깊이마다 크기가 다른 사람들(먼 것부터 그린다).
static func _people(p: Paint) -> void:
	var crowd := [[-3.4, 8.6, 0], [-2.2, 9.4, 1], [2.6, 9.0, 2], [3.6, 8.2, 3], [-6.8, 14.5, 4], [7.4, 15.5, 1], [4.6, 11.6, 5], [-1.2, 7.2, 3], [-2.1, 5.3, 0]]
	crowd.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))
	for c: Array in crowd:
		_person(p, float(c[0]), float(c[1]), int(c[2]), int(c[2]) != 5)


const LOOKS := [
	{"body": "male", "top": Color("#5a4632"), "bottom": Color("#3e362c"), "pack": Color("#6a5236"), "hair": "short", "hair_c": Color("#2c2016"), "spear": true},
	{"body": "female", "top": Color("#4a5444"), "bottom": Color("#3a3a32"), "hair": "long", "hair_c": Color("#5a3a22")},
	{"body": "stout", "top": Color("#6a3e30"), "bottom": Color("#3e3428"), "pack": Color("#5a4630"), "hair": "bald"},
	{"body": "female", "top": Color("#3e3a48"), "lower": "robe", "hair": "hood", "hood_c": Color("#4a4458")},
	{"body": "male", "top": Color("#4e4a40"), "bottom": Color("#2e2a24"), "hair": "bun", "hair_c": Color("#1e1812")},
	{"body": "male", "top": Color("#5c5e60"), "bottom": Color("#34363a"), "belt": Color("#2a1e14"), "hair": "short", "hair_c": Color("#1e1812"), "beard": "stubble", "spear": true, "arms": "down"},
]


static func _person(p: Paint, x: float, z: float, look_i: int, back: bool) -> void:
	var foot := _P(x, 0, z)
	var h := (1.62 + 0.06 * (look_i % 3)) * _s(z)
	_shadow(p, foot, h * 0.3)
	var look: Dictionary = (LOOKS[look_i] as Dictionary).duplicate()
	look["skin"] = Npc.SKIN
	for k: String in look.keys():
		if look[k] is Color:
			look[k] = _hz(look[k], z)  # 먼 사람은 안개에 묻힌다
	look["back"] = back
	look["light"] = 1.0 if x < 0.0 else -1.0
	Npc.figure(p, foot.x, foot.y, h, look)


static func _shadow(p: Paint, foot: Vector2, rx: float) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(foot + Vector2(cos(a) * rx, sin(a) * rx * 0.22))
	p.fill_poly(pts, p.flat(Color("#0c0907"), 0.05), 0.4)


## 앞쪽 깃발 기둥(화면 양끝): 쇠 기둥 + 위에서 늘어진 천(주름·고리 문장). 가까워서 크다.
static func _banner(p: Paint, x: float, z: float) -> void:
	var s := _s(z)
	var foot := _P(x, 0, z)
	_shadow(p, foot, 0.5 * s)
	Ink.line(p, foot, _P(x, 9.0, z), 0.14 * s, Color("#2a2622"), 1.0, 0.2)
	var inward := -signf(x)
	var top := _P(x, 6.6, z)
	var cloth_x0 := top.x + inward * 0.12 * s
	var cloth_x1 := cloth_x0 + inward * 1.1 * s
	var bottom := _P(x, 2.6, z).y
	var cloth := Paint.poly([Vector2(cloth_x0, top.y), Vector2(cloth_x1, top.y), Vector2(cloth_x1, bottom - 0.25 * s), Vector2((cloth_x0 + cloth_x1) / 2.0, bottom), Vector2(cloth_x0, bottom - 0.25 * s)])
	p.fill_poly(cloth, p.flat(Color("#5e1f1b"), 0.2))
	Ink.shade(p, cloth, Vector2(cloth_x0, 0), Vector2(cloth_x1, 0), 0.4, 0.05)
	for k in 3:
		var fx := lerpf(cloth_x0, cloth_x1, 0.25 + 0.25 * k)
		Ink.line(p, Vector2(fx, top.y + 4), Vector2(fx + inward * 4.0, bottom - 0.3 * s), maxf(1.0, s / 70.0), Ink.INK, 0.3, 1.2)
	var emblem := Vector2((cloth_x0 + cloth_x1) / 2.0, lerpf(top.y, bottom, 0.38))
	var ring := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		ring.append(emblem + Vector2(cos(a), sin(a)) * 0.3 * s)
	Ink.path(p, ring, maxf(2.0, s / 25.0), true, Color("#c9a86a"), 0.85, 0.4)
	Ink.line(p, Vector2(cloth_x0 - inward * 0.2 * s, top.y), Vector2(cloth_x1 + inward * 0.1 * s, top.y), 0.08 * s, Color("#2a2622"), 1.0, 0.2)
	Ink.path(p, cloth, 2.4)
