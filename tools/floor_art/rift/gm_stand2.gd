extends RefCounted
## 녹색 탄광 소품 2(화약통·작업대·연장 걸이·광석 더미·바위·천막·모닥불·기중기·폭약 궤짝). 칸·발·빛 규칙은 gm_stand와 같다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const K := preload("res://tools/floor_art/rift/gm_kit.gd")

const CANVAS := Color("#6a5e48")
const POWDER_RED := Color("#8a2a1e")


static func paint(p: Paint, tile: String) -> bool:
	var u := p.w / 128.0
	var foot := Vector2(p.w * 0.5, p.h - p.w * 0.14)
	match tile:
		"gm_powder":
			_powder(p, foot, u)
		"gm_bench":
			_bench(p, foot, u)
		"gm_toolrack":
			_toolrack(p, foot, u)
		"gm_ore":
			_ore(p, foot, u)
		"gm_rock":
			_rock(p, foot, u)
		"gm_tent":
			_tent(p, foot, u)
		"gm_fire":
			_fire(p, foot, u)
		"gm_crane":
			_crane(p, foot, u)
		"explosive_crate":
			_explosive(p, foot, u)
		_:
			return false
	return true


## 화약통: 검은 나무통 + 쇠테 3줄 + 흰 해골 표식 + 위로 솟은 심지 + 쏟아진 화약.
static func _powder(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 26 * u, 8 * u)
	Decals._blob(p, foot + Vector2(18, 2) * u, 10 * u, Color("#141212"), 0.6, 0.4)
	Kit.cyl(p, foot, 19 * u, 40 * u, Color("#3e2e22"), 3, Color("#1e1a18"))
	var ry := 19 * u * Kit.DEPTH * 0.6
	for k in range(1, 6):
		var a := PI * k / 6.0
		var x := foot.x - 19 * u * cos(a)
		Ink.line(p, Vector2(x, foot.y - 40 * u + sin(a) * ry), Vector2(x, foot.y + sin(a) * ry * 0.9), 0.8 * u, Ink.INK, 0.4, 0.4)
	_skull(p, foot + Vector2(-2, -19) * u, u)
	var top := foot + Vector2(3, -40) * u
	var pts := PackedVector2Array([top, top + Vector2(2, -6) * u, top + Vector2(-2, -12) * u, top + Vector2(3, -17) * u, top + Vector2(8, -18) * u])
	Ink.path(p, pts, 2.2 * u, false, Ink.INK, 0.9, 0.3)
	Ink.path(p, pts, 1.2 * u, false, Color("#b8a888"), 0.9, 0.3)
	Cave._dot(p, top, 2.2 * u, Color("#1a1412"), 0.9)


## 칠한 해골 표식(바랜 흰색).
static func _skull(p: Paint, c: Vector2, u: float) -> void:
	var bone := Color("#d8d0bc")
	p.fill_poly(Cave._ellipse(c, 7 * u, 6 * u, 16), func(x: int, y: int) -> Color: return Color(bone.r, bone.g, bone.b, 0.8 * (0.7 + 0.3 * p.nz("mid", x, y))))
	p.fill_poly(Paint.rect_poly(c.x - 4 * u, c.y + 4 * u, 8 * u, 4 * u), func(_x: int, _y: int) -> Color: return Color(bone.r, bone.g, bone.b, 0.75))
	Cave._dot(p, c + Vector2(-2.6, 0.5) * u, 2.0 * u, Color("#141010"), 0.95)
	Cave._dot(p, c + Vector2(2.6, 0.5) * u, 2.0 * u, Color("#141010"), 0.95)
	for e: float in [-2.0, 0.0, 2.0]:
		Ink.line(p, c + Vector2(e, 5) * u, c + Vector2(e, 8) * u, 0.7 * u, Ink.INK, 0.7, 0.1)
	for d: float in [-1.0, 1.0]:
		Ink.line(p, c + Vector2(-10 * d, -8) * u, c + Vector2(10 * d, 10) * u, 1.6 * u, bone, 0.55, 0.4)


## 작업대: 두꺼운 상판 + 다리 4개 + 아래 선반 + 바이스·망치·톱·광석 조각.
static func _bench(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(0, -6) * u, 36 * u, 9 * u)
	var dd := Vector2(6, -14) * u
	var top_y := 36.0 * u
	for e: float in [-27.0, 27.0]:  # 뒷다리
		K.beam(p, foot + Vector2(e, 0) * u + dd, foot + Vector2(e, 0) * u + dd + Vector2(0, -top_y), 5 * u, K.WOOD.darkened(0.35), false)
	K.beam(p, foot + Vector2(-27, -10) * u, foot + Vector2(27, -10) * u, 4 * u, K.WOOD.darkened(0.2))  # 아래 가로대
	var shelf := PackedVector2Array([foot + Vector2(-27, -12) * u, foot + Vector2(27, -12) * u, foot + Vector2(27, -12) * u + dd, foot + Vector2(-27, -12) * u + dd])
	K.wood(p, shelf, K.WOOD.darkened(0.25), false, 0.0)
	Cave._stone(p, foot + Vector2(-6, -16) * u + dd * 0.5, 5 * u, 3.5 * u, Color("#3e3c46"))
	for e: float in [-27.0, 27.0]:  # 앞다리
		K.beam(p, foot + Vector2(e, 1) * u, foot + Vector2(e, -top_y / u) * u, 6 * u, K.WOOD)
	var tb := Kit.box(p, foot + Vector2(0, -top_y / u) * u, 66 * u, 26 * u, 7 * u, K.WOOD)
	K.wood_box(p, tb, K.WOOD, 1)
	var surf := foot + Vector2(0, -top_y / u - 7) * u + dd * 0.5
	# 바이스(왼쪽 끝)
	Kit.box(p, surf + Vector2(-24, 2) * u, 10 * u, 8 * u, 9 * u, K.IRON)
	Ink.line(p, surf + Vector2(-31, -4) * u, surf + Vector2(-17, -4) * u, 1.6 * u, K.STEEL, 0.9, 0.1)
	# 망치
	Decals._stick(p, surf + Vector2(-8, 3) * u, surf + Vector2(8, -2) * u, 2.2 * u, K.WOOD_PALE)
	Cave._stone(p, surf + Vector2(9, -2.5) * u, 4 * u, 2.4 * u, K.IRON)
	# 톱(날 + 이)
	var saw := PackedVector2Array([surf + Vector2(12, 4) * u, surf + Vector2(30, 1) * u, surf + Vector2(30, 5) * u, surf + Vector2(13, 8) * u])
	p.fill_poly(saw, func(x: int, y: int) -> Color: return p.vary(K.STEEL.darkened(0.1), x, y, 0.08))
	Ink.path(p, saw, 1.0 * u, true, Ink.INK, 0.8, 0.2)
	Decals._stick(p, surf + Vector2(8, 5) * u, surf + Vector2(13, 6) * u, 3.2 * u, K.WOOD)
	K.glint(p, surf + Vector2(-2, 6) * u, 1.8 * u)
	for k in 4:
		K.nail(p, surf + Vector2(p.rng.randf_range(-14, 20), p.rng.randf_range(4, 9)) * u, 0.9 * u)


## 연장 걸이: 기둥 둘 + 가로대 둘 + 곡괭이 둘·삽 하나를 기대 놓음.
static func _toolrack(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 32 * u, 8 * u)
	for e: float in [-26.0, 26.0]:
		K.beam(p, foot + Vector2(e, 0) * u, foot + Vector2(e, -82) * u, 6 * u, K.WOOD.darkened(0.15))
	K.beam(p, foot + Vector2(-30, -76) * u, foot + Vector2(30, -76) * u, 5 * u, K.WOOD)
	_pick(p, foot + Vector2(-16, 0) * u, foot + Vector2(-12, -80) * u, u)
	_shovel(p, foot + Vector2(2, -2) * u, foot + Vector2(4, -86) * u, u)
	_pick(p, foot + Vector2(16, 0) * u, foot + Vector2(20, -78) * u, u)
	K.beam(p, foot + Vector2(-30, -36) * u, foot + Vector2(30, -36) * u, 5 * u, K.WOOD)  # 앞 가로대(연장을 붙잡음)
	for e: float in [-26.0, 26.0]:
		K.nail(p, foot + Vector2(e, -36) * u, 1.1 * u)
		K.nail(p, foot + Vector2(e, -76) * u, 1.1 * u)


static func _pick(p: Paint, a: Vector2, b: Vector2, u: float) -> void:
	Decals._stick(p, a, b, 3.0 * u, K.WOOD_PALE.darkened(0.1))
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	var head := PackedVector2Array([b - n * 18 * u - d * 6 * u, b + d * 2 * u - n * 4 * u, b + d * 2 * u + n * 4 * u, b + n * 18 * u - d * 4 * u, b + n * 4 * u - d * 4 * u, b - n * 4 * u - d * 4 * u])
	p.fill_poly(head, func(x: int, y: int) -> Color: return p.vary(K.IRON.lerp(K.RUST, 0.25).lightened(0.1), x, y, 0.12))
	Ink.line(p, head[0], head[3], 0.9 * u, Color("#c8c0b0"), 0.35, 0.3)
	Ink.path(p, head, 1.2 * u, true, Ink.INK, 0.9, 0.2)


static func _shovel(p: Paint, blade_end: Vector2, grip: Vector2, u: float) -> void:
	var d := (grip - blade_end).normalized()
	var n := Vector2(-d.y, d.x)
	var neck := blade_end + d * 22 * u
	Decals._stick(p, neck, grip, 2.8 * u, K.WOOD_PALE.darkened(0.15))
	Decals._stick(p, grip - n * 5 * u, grip + n * 5 * u, 2.6 * u, K.WOOD_PALE.darkened(0.15))
	var blade := PackedVector2Array([neck - n * 3 * u, neck + n * 3 * u, blade_end + d * 18 * u + n * 8 * u, blade_end + n * 7 * u, blade_end, blade_end - n * 7 * u, blade_end + d * 18 * u - n * 8 * u])
	p.fill_poly(blade, func(x: int, y: int) -> Color: return p.vary(K.IRON.lerp(K.RUST, 0.45), x, y, 0.14))
	Ink.path(p, blade, 1.2 * u, true, Ink.INK, 0.9, 0.2)


## 광석 더미: 어두운 청회 돌덩이 무더기(아래 넓게) + 녹색으로 반짝이는 결정 알갱이.
static func _ore(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 32 * u, 9 * u)
	K.halo(p, foot + Vector2(0, -16) * u, 40 * u, K.LIME_GLOW, 0.12)
	for k in 34:
		var t := float(k) / 34.0
		var spread := 32.0 * (1.0 - t * 0.75)
		var q := foot + Vector2(p.rng.randf_range(-spread, spread), -t * 38.0 + p.rng.randf_range(-2, 3)) * u
		var r := p.rng.randf_range(4.5, 8.5) * u * (1.0 - t * 0.3)
		Cave._stone(p, q, r, r * 0.72, Color("#3e3c48").lerp(K.ROCK_VIOLET, p.rng.randf()).lightened(p.rng.randf_range(0.0, 0.15)))
		if p.rng.randf() < 0.18:
			K.glint(p, q + Vector2(p.rng.randf_range(-2, 2), -2) * u, p.rng.randf_range(1.6, 2.4) * u)
	K.glint(p, foot + Vector2(-3, -38) * u, 2.6 * u)


## 바위: 금 간 큰 청회 덩어리 + 작은 돌.
static func _rock(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 34 * u, 10 * u, 0.5)
	var c := foot + Vector2(-2, -28) * u
	Kit.blob(p, c, 35 * u, 30 * u, K.ROCK.lerp(K.ROCK_VIOLET, 0.4))
	Kit.blob(p, c + Vector2(-11, -14) * u, 18 * u, 12 * u, K.ROCK.lightened(0.05))
	Cave._crack(p, c + Vector2(4, -16) * u, 4, 9 * u, Vector2(0.2, 1.0))
	Cave._crack(p, c + Vector2(-14, 4) * u, 2, 7 * u, Vector2(1.0, 0.3))
	Ink.shade(p, Cave._ellipse(c + Vector2(6, 6) * u, 32 * u, 26 * u, 24), c + Vector2(-10, -10) * u, c + Vector2(24, 22) * u, 0.0, 0.45)
	Cave._stone(p, foot + Vector2(28, 2) * u, 6 * u, 4.5 * u, K.ROCK)
	Cave._stone(p, foot + Vector2(-30, 3) * u, 4 * u, 3 * u, K.ROCK)
	K.glint(p, c + Vector2(12, 4) * u, 1.8 * u)


## 낡은 천막(A자): 앞 세모(어두운 입구 + 젖힌 자락) + 오른쪽 지붕 면 + 엇갈린 장대 + 말뚝 밧줄 + 기운 자국.
static func _tent(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(6, -6) * u, 42 * u, 11 * u, 0.4)
	var apex := foot + Vector2(-8, -74) * u
	var bl := foot + Vector2(-38, 0) * u
	var br := foot + Vector2(24, 0) * u
	var dd := Vector2(16, -24) * u
	var roof := PackedVector2Array([apex, apex + dd, br + dd, br])
	p.fill_poly(roof, func(x: int, y: int) -> Color: return p.vary(CANVAS.darkened(0.35), x, y, 0.12))
	Ink.hatch(p, roof, 4.0 * u, 50.0, 0.22, 0.9 * u)
	var patch := PackedVector2Array([apex.lerp(br, 0.45) + dd * 0.3, apex.lerp(br, 0.45) + dd * 0.6, apex.lerp(br, 0.7) + dd * 0.6, apex.lerp(br, 0.7) + dd * 0.3])
	p.fill_poly(patch, func(x: int, y: int) -> Color: return p.vary(Color("#4e4434"), x, y, 0.1))
	Ink.path(p, patch, 0.9 * u, true, Ink.INK, 0.6, 0.5)
	var front := PackedVector2Array([apex, br, bl])
	p.fill_poly(front, func(x: int, y: int) -> Color:
		var t := clampf((y - apex.y) / (foot.y - apex.y), 0.0, 1.0)
		return p.vary(CANVAS.darkened(0.05 + t * 0.2), x, y, 0.12))
	var door := PackedVector2Array([apex + Vector2(2, 14) * u, foot + Vector2(10, 0) * u, foot + Vector2(-20, 0) * u])
	p.fill_poly(door, func(x: int, y: int) -> Color: return p.vary(Color("#120e0c"), x, y, 0.05))
	var flap := PackedVector2Array([apex + Vector2(2, 14) * u, foot + Vector2(-20, 0) * u, foot + Vector2(-30, -2) * u])
	p.fill_poly(flap, func(x: int, y: int) -> Color: return p.vary(CANVAS.lightened(0.08), x, y, 0.1))
	Ink.path(p, flap, 1.1 * u, true, Ink.INK, 0.75, 0.4)
	Ink.grime(p, bl.x + 6 * u, foot.y - 26 * u, 56 * u, 22 * u, 0.4)
	Ink.path(p, front, 1.6 * u, true, Ink.INK, 0.85, 0.5)
	Ink.path(p, roof, 1.4 * u, true, Ink.INK, 0.8, 0.5)
	for q: Vector2 in [apex, apex + dd]:  # 엇갈린 장대
		Decals._stick(p, q + Vector2(-5, 6) * u, q + Vector2(6, -10) * u, 2.4 * u, K.WOOD_DARK)
		Decals._stick(p, q + Vector2(6, 6) * u, q + Vector2(-5, -10) * u, 2.4 * u, K.WOOD_DARK)
	for st: Vector2 in [foot + Vector2(-50, 4) * u, foot + Vector2(44, -4) * u]:  # 말뚝 밧줄
		Ink.line(p, apex if st.x < foot.x else apex + dd, st, 0.9 * u, Color("#8a7a5a"), 0.7, 0.4)
		Decals._stick(p, st, st + Vector2(0, -6) * u, 2.2 * u, K.WOOD_DARK)


## 모닥불: 돌 둘레 + 엇갈린 장작 + 불꽃 + 큰 빛 번짐 + 삼발이에 매단 냄비.
static func _fire(p: Paint, foot: Vector2, u: float) -> void:
	var c := foot + Vector2(0, -8) * u
	K.halo(p, c + Vector2(0, -14) * u, 58 * u, Color("#ff8a3a"), 0.42)
	Decals._blob(p, c, 16 * u, Color("#1e1a18"), 0.9, 0.15)
	for k in 10:
		var a := PI + TAU * k / 10.0
		var q := c + Vector2(cos(a) * 21, sin(a) * 9) * u
		if sin(a) < 0.0:
			Cave._stone(p, q, 5 * u, 3.6 * u, K.ROCK)
	for k in 3:
		var d := Vector2.from_angle(PI * (0.1 + k * 0.33)) * Vector2(14, 6) * u
		Decals._stick(p, c - d, c + d, 4.0 * u, Color("#2a1e14"))
	for k in 6:
		Cave._dot(p, c + Vector2(p.rng.randf_range(-9, 9), p.rng.randf_range(-3, 3)) * u, 1.6 * u, Color("#ff8a30"), 0.9)
	Kit.flame(p, c + Vector2(-3, -1) * u, 11 * u)
	Kit.flame(p, c + Vector2(5, 0) * u, 8 * u)
	for k in 10:
		var a := TAU * k / 10.0
		var q := c + Vector2(cos(a) * 21, sin(a) * 9) * u
		if sin(a) >= 0.0:
			Cave._stone(p, q, 5.5 * u, 3.8 * u, K.ROCK)
	var top := c + Vector2(0, -52) * u
	for b: Vector2 in [c + Vector2(-26, 4) * u, c + Vector2(24, 6) * u, c + Vector2(4, -12) * u]:  # 삼발이
		Decals._stick(p, b, top, 2.4 * u, K.WOOD_DARK)
	Ink.line(p, top, top + Vector2(0, 18) * u, 1.0 * u, K.IRON, 0.9, 0.1)
	var pot := top + Vector2(0, 24) * u
	Kit.cyl(p, pot + Vector2(0, 6) * u, 8 * u, 10 * u, Color("#2a2624"), 0)
	Ink.glow(p, pot.x, pot.y + 10 * u, 12 * u, Color("#ff9040"), 0.3, true)


## 나무 기중기: 받침 상자 + 곧은 돛대 + 비스듬한 팔 + 버팀줄 + 감는 북 + 팔 끝에서 내려온 밧줄과 갈고리(칸 높이를 다 씀).
static func _crane(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(4, -4) * u, 30 * u, 9 * u)
	var base := Kit.box(p, foot + Vector2(-8, 0) * u, 36 * u, 28 * u, 12 * u, K.WOOD.darkened(0.1))
	K.wood_box(p, base, K.WOOD.darkened(0.1), 2)
	var mast_b := foot + Vector2(-12, -12) * u
	var mast_t := foot + Vector2(-12, -168) * u
	var tip := foot + Vector2(50, -150) * u
	var pivot := foot + Vector2(-12, -64) * u
	Ink.line(p, mast_t, tip, 1.4 * u, Color("#8a7a5a"), 0.9, 0.3)  # 버팀줄
	K.beam(p, mast_b, mast_t, 9 * u, K.WOOD)
	K.beam(p, foot + Vector2(-28, -12) * u, foot + Vector2(-14, -60) * u, 5 * u, K.WOOD.darkened(0.15))  # 까치발
	K.beam(p, pivot, tip, 7 * u, K.WOOD.darkened(0.05))
	K.beam(p, pivot + Vector2(0, -2) * u, pivot.lerp(tip, 0.5) + Vector2(0, 6) * u, 4 * u, K.WOOD.darkened(0.2))
	# 감는 북 + 손잡이
	var drum := foot + Vector2(4, -24) * u
	Kit.cyl(p, drum + Vector2(0, 7) * u, 7 * u, 14 * u, K.WOOD.darkened(0.2), 2, K.IRON)
	Decals._stick(p, drum + Vector2(8, 0) * u, drum + Vector2(14, -6) * u, 2.0 * u, K.IRON)
	Ink.line(p, drum + Vector2(0, -6) * u, pivot.lerp(tip, 0.15), 1.2 * u, Color("#8a7a5a"), 0.85, 0.2)
	Ink.line(p, pivot.lerp(tip, 0.15), tip, 1.0 * u, Color("#8a7a5a"), 0.7, 0.2)
	# 도르래 + 늘어진 밧줄 + 갈고리
	Ink.path(p, Cave._ellipse(tip + Vector2(0, 4) * u, 4 * u, 4 * u, 12), 1.8 * u, true, K.IRON, 0.95, 0.1)
	var hook := tip + Vector2(0, 76) * u
	Ink.line(p, tip + Vector2(0, 8) * u, hook, 1.6 * u, Ink.INK, 0.7, 0.2)
	Ink.line(p, tip + Vector2(0, 8) * u, hook, 1.0 * u, Color("#9a8a6a"), 0.9, 0.2)
	var hk := PackedVector2Array([hook, hook + Vector2(0, 7) * u, hook + Vector2(4, 11) * u, hook + Vector2(8, 8) * u, hook + Vector2(8, 4) * u])
	Ink.path(p, hk, 3.0 * u, false, Ink.INK, 0.9, 0.1)
	Ink.path(p, hk, 1.8 * u, false, K.STEEL, 1.0, 0.1)
	for k in 3:
		K.nail(p, mast_b.lerp(mast_t, 0.3 + k * 0.25), 1.2 * u)


## 폭약 궤짝: 궤짝 + 붉은 경고 띠·세모 표식 + 열린 틈으로 보이는 붉은 폭약 다발과 감긴 심지.
static func _explosive(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 32 * u, 9 * u)
	var box := Kit.box(p, foot, 50 * u, 38 * u, 32 * u, K.WOOD.darkened(0.05))
	K.wood_box(p, box, K.WOOD.darkened(0.05), 3)
	var top: PackedVector2Array = box["top"]
	# 반쯤 밀린 뚜껑: 앞쪽 절반만 열려 붉은 막대가 보인다
	var gap := PackedVector2Array([top[0].lerp(top[3], 0.1) + Vector2(3, 0) * u, top[1].lerp(top[2], 0.1) - Vector2(8, 0) * u, top[1].lerp(top[2], 0.55) - Vector2(8, 0) * u, top[0].lerp(top[3], 0.55) + Vector2(3, 0) * u])
	p.fill_poly(gap, func(_x: int, _y: int) -> Color: return Color("#140e0a"))
	var g0 := gap[0]
	var g1 := gap[1]
	for k in 6:
		var a := g0.lerp(g1, (k + 0.6) / 6.6) + Vector2(0, -2) * u
		var b := a + (gap[3] - gap[0]) * 0.85
		Ink.line(p, a, b, 4.6 * u, Ink.INK, 0.9, 0.1)
		Ink.line(p, a, b, 3.4 * u, POWDER_RED, 1.0, 0.1)
		Ink.line(p, a + Vector2(-0.8, 0) * u, b + Vector2(-0.8, 0) * u, 1.0 * u, Color("#d87a5a"), 0.6, 0.1)
	var lid := PackedVector2Array([top[0].lerp(top[3], 0.5), top[1].lerp(top[2], 0.5), top[2], top[3]])
	K.wood(p, lid, K.WOOD_PALE.darkened(0.1), false, 0.0)
	Ink.path(p, lid, 1.2 * u, true, Ink.INK, 0.8, 0.3)
	var coil := (lid[0] + lid[2]) * 0.5
	for k in 3:
		Ink.path(p, Cave._ellipse(coil, (6 - k * 1.6) * u, (3 - k * 0.7) * u, 14), 1.2 * u, true, Color("#a8987a"), 0.9, 0.3)
	var f: PackedVector2Array = box["front"]
	var r := Paint.bounds(f)
	p.fill_rect(r.position.x, r.position.y + 3 * u, r.size.x, 5 * u, func(x: int, y: int) -> Color: return Color(0.6, 0.18, 0.1, 0.55 * (0.7 + 0.3 * p.nz("mid", x, y))))
	var c := r.get_center() + Vector2(0, 4) * u
	var tri := PackedVector2Array([c + Vector2(0, -10) * u, c + Vector2(10, 7) * u, c + Vector2(-10, 7) * u])
	Ink.path(p, tri, 2.2 * u, true, Color("#a83a22"), 0.75, 0.6)
	Ink.line(p, c + Vector2(0, -4) * u, c + Vector2(0, 1) * u, 2.0 * u, Color("#a83a22"), 0.75, 0.3)
	Cave._dot(p, c + Vector2(0, 4) * u, 1.3 * u, Color("#a83a22"), 0.8)
	for q: Vector2 in [r.position + Vector2(3, 3) * u, Vector2(r.end.x - 3 * u, r.position.y + 3 * u), Vector2(r.position.x + 3 * u, r.end.y - 3 * u), r.end - Vector2(3, 3) * u]:
		K.nail(p, q, 1.0 * u)
