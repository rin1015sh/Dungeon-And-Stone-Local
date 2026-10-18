extends RefCounted
## 녹색 탄광 공통 부품(gm*.gd가 쓴다): 색 · 라임빛 결정 · 나무결 판자 · 못 · 녹 · 주기 잡음 표본.
## 바위는 차가운 청회·보라, 나무는 따뜻한 갈색, 쇠는 녹슨 갈회색 — 채도 높은 색은 결정·슬라임의 라임빛뿐.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")

const ROCK := Color("#4c5060")
const ROCK_VIOLET := Color("#4a4258")
const ROCK_DARK := Color("#22202a")
const WOOD := Color("#6a4c30")
const WOOD_DARK := Color("#3a2a1a")
const WOOD_PALE := Color("#8a7052")
const IRON := Color("#585654")
const STEEL := Color("#8a8c90")
const RUST := Color("#7a4826")
const VOID := Color("#07080b")
const LIME_LIGHT := Color("#eaffb0")
const LIME := Color("#9ee040")
const LIME_DARK := Color("#2c5a1c")
const LIME_GLOW := Color("#a6ff48")
const LAMP := Color("#ffb45a")
const QUARTZ := Color("#d4cdbc")


## 결정 기둥 하나(위로 솟거나 기운 육각 기둥): 왼쪽 면 밝은 라임, 오른쪽 면 짙은 녹, 가운데 모서리 빛, 짙은 녹 잉크.
static func shard(p: Paint, root: Vector2, ang: float, ln: float, wd: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := Vector2(-d.y, d.x)  # d가 위(−y)면 n은 왼쪽(−x)
	if n.x > 0.0:
		n = -n
	var tip := root + d * ln
	var sh := 0.74
	var lb := root + n * wd
	var rb := root - n * wd
	var ls := lb + d * ln * sh
	var rs := rb + d * ln * (sh + 0.06)
	var mb := root - n * wd * 0.25 + d * wd * 0.15
	var ms := mb + d * ln * (sh + 0.02)
	var left := PackedVector2Array([lb, ls, tip, ms, mb])
	var right := PackedVector2Array([mb, ms, tip, rs, rb])
	var len_t := func(x: int, y: int) -> float: return clampf((Vector2(x, y) - root).dot(d) / ln, 0.0, 1.0)
	p.fill_poly(left, func(x: int, y: int) -> Color:
		var t: float = len_t.call(x, y)
		var c := LIME_DARK.lerp(LIME, smoothstep(0.0, 0.35, t)).lerp(LIME_LIGHT, smoothstep(0.4, 1.0, t) * 0.7)
		return p.vary(c, x, y, 0.07))
	p.fill_poly(right, func(x: int, y: int) -> Color:
		var t: float = len_t.call(x, y)
		return p.vary(LIME_DARK.darkened(0.35).lerp(LIME.darkened(0.15), t * 0.7), x, y, 0.07))
	if ln > 14.0:  # 안쪽에 비치는 결(빛이 갇힌 줄)
		var a0 := root + d * ln * 0.25 + n * wd * 0.35
		Ink.line(p, a0, a0 + d * ln * 0.4 - n * wd * 0.2, maxf(0.6, wd * 0.12), LIME_LIGHT, 0.45, 0.3)
		Ink.line(p, mb + d * ln * 0.3, rb + d * ln * 0.55, maxf(0.6, wd * 0.1), LIME_DARK.darkened(0.4), 0.4, 0.3)
	Ink.line(p, mb + d * ln * 0.1, tip, maxf(0.6, wd * 0.2), LIME_LIGHT, 0.7, 0.2)  # 모서리 빛
	Ink.line(p, lb + d * ln * 0.15, ls, 0.7 + wd * 0.06, Color("#f6ffd8"), 0.35, 0.2)
	Ink.path(p, PackedVector2Array([lb, ls, tip, rs, rb]), 0.8 + wd * 0.12, false, Color("#0e2008"), 0.85, 0.3)


## 결정 무리: root에서 위로 솟는 기둥 n개(큰 것 뒤, 작은 것 앞) + 둘레 빛 번짐.
static func crystals(p: Paint, root: Vector2, size: float, n: int, glow: float = 0.5) -> void:
	halo(p, root + Vector2(0, -size * 0.45), size * 1.1, LIME_GLOW, glow)
	var list: Array[Array] = []
	for k in n:
		var side := (float(k) / maxf(1.0, n - 1) - 0.5) * 2.0 if n > 1 else 0.0
		var ang := -PI * 0.5 + side * 0.55 + p.rng.randf_range(-0.15, 0.15)
		var ln := size * (1.0 - absf(side) * 0.45) * p.rng.randf_range(0.75, 1.0)
		var wd := size * p.rng.randf_range(0.11, 0.16)
		var off := Vector2(side * size * 0.28, p.rng.randf_range(-0.03, 0.05) * size)
		list.append([ang, ln, wd, off])
	list.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))
	for e: Array in list:
		shard(p, root + (e[3] as Vector2), float(e[0]), float(e[1]), float(e[2]))
	Ink.glow(p, root.x, root.y - size * 0.3, size * 0.7, LIME_LIGHT, glow * 0.25, true)


## 바위에 박힌 작은 녹색 결정 조각(벽 앞면·바닥 부스러기): 파인 홈 + 짧은 기둥 2~3개 + 은은한 빛.
static func gem(p: Paint, q: Vector2, s: float, glow: float = 0.3) -> void:
	Ink.glow(p, q.x, q.y, 9.0 * s, LIME_GLOW, glow)
	p.fill_poly(Cave._ellipse(q + Vector2(0, 1.0 * s), 3.4 * s, 2.2 * s, 12), func(_x: int, _y: int) -> Color: return Color(0.04, 0.06, 0.04, 0.7))
	for k in p.rng.randi_range(2, 3):
		var ang := -PI * 0.5 + p.rng.randf_range(-0.8, 0.8)
		shard(p, q + Vector2(p.rng.randf_range(-1.4, 1.4) * s, 0.6 * s), ang, p.rng.randf_range(3.5, 6.5) * s, p.rng.randf_range(1.0, 1.6) * s)


## 나무 판(다각형): 결 방향(vertical = 세로결) 줄무늬 + 붓결. 판마다 tone으로 밝기를 바꾼다.
static func wood(p: Paint, poly: PackedVector2Array, col: Color, vertical: bool, tone: float = 0.0) -> void:
	var kind := "vs" if vertical else "hs"
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var g := p.nz(kind, x, y)
		var c := col.lightened(tone) if tone > 0.0 else col.darkened(-tone)
		c = c.darkened(0.18).lerp(c.lightened(0.14), g)
		if absf(g - 0.5) < 0.03:  # 결 사이 가는 골
			c = c.darkened(0.25)
		return p.vary(c, x, y, 0.07))


## 판자 하나(사각): 나무결 + 왼쪽 위 밝은 테 + 오른쪽 아래 잉크.
static func board(p: Paint, r: Rect2, col: Color, vertical: bool, tone: float = 0.0) -> void:
	var poly := Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y)
	wood(p, poly, col, vertical, tone)
	var u := p.w / 128.0
	Ink.line(p, r.position, Vector2(r.end.x, r.position.y), 0.8 * u, LIT_EDGE, 0.3, 0.2)
	Ink.line(p, r.position, Vector2(r.position.x, r.end.y), 0.8 * u, LIT_EDGE, 0.25, 0.2)
	Ink.path(p, poly, 1.1 * u, true, Ink.INK, 0.7, 0.3)

const LIT_EDGE := Color("#f0dcb8")


## 못 머리(작은 쇠 점 + 빛 점).
static func nail(p: Paint, q: Vector2, r: float) -> void:
	Cave._dot(p, q + Vector2(0.4, 0.5) * r, r * 1.2, Color("#120e0c"), 0.7)
	Cave._dot(p, q, r, Color("#4a4440"), 0.95)
	Cave._dot(p, q - Vector2(0.35, 0.35) * r, r * 0.45, Color("#c8c0b0"), 0.7)


## 녹 얼룩(칠한 곳에만): 갈색 반점 몇 개.
static func rust(p: Paint, c: Vector2, r: float, n: int) -> void:
	for k in n:
		var q := c + Vector2(p.rng.randf_range(-r, r), p.rng.randf_range(-r, r) * 0.6)
		Cave._dot(p, q, p.rng.randf_range(0.8, 2.2) * p.w / 128.0 * 2.0, RUST.lerp(Color("#a05a26"), p.rng.randf()), 0.6)


## 주기 잡음을 정수배로 눌러 표본(가로·세로 줄무늬 결 — 주기를 지킨다).
static func streak(f: PackedFloat32Array, w: int, h: int, x: int, y: int, kx: int, ky: int) -> float:
	return Seam.at(f, w, h, x * kx, y * ky)


## 나무 들보(두 점 사이 굵은 막대): 나무결 + 빛 쪽 밝은 테 + 잉크 + (선택) 떨어진 그림자.
static func beam(p: Paint, a: Vector2, b: Vector2, wd: float, col: Color, cast: bool = true) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * wd * 0.5
	var poly := PackedVector2Array([a + n, b + n, b - n, a - n])
	if cast:
		Ink.line(p, a + Vector2(2.0, 2.5), b + Vector2(2.0, 2.5), wd, Color(0.04, 0.03, 0.03), 0.3, 0.3)
	wood(p, poly, col, absf(d.y) > absf(d.x), 0.0)
	var lit := n if (n.x + n.y) < 0.0 else -n
	var dark := -lit
	Ink.line(p, a + lit * 0.75, b + lit * 0.75, maxf(0.8, wd * 0.14), LIT_EDGE, 0.3, 0.2)
	Ink.line(p, a + dark * 0.6, b + dark * 0.6, maxf(1.0, wd * 0.3), Color("#120c08"), 0.35, 0.2)
	Ink.path(p, poly, maxf(1.0, wd * 0.12) * 1.2, true, Ink.INK, 0.8, 0.3)


## 3/4 상자 앞면에 나무결을 입힌다(Kit.box가 돌려준 다각형 — 앞면 가로 판, 윗면 판, 옆면은 그늘).
static func wood_box(p: Paint, polys: Dictionary, col: Color, rows: int) -> void:
	var front: PackedVector2Array = polys["front"]
	var top: PackedVector2Array = polys["top"]
	wood(p, front, col.darkened(0.12), false, 0.0)
	wood(p, top, col.lightened(0.15), false, 0.0)
	var r := Paint.bounds(front)
	for k in range(1, rows):
		var y := r.position.y + r.size.y * k / rows
		Ink.line(p, Vector2(r.position.x + 1, y), Vector2(r.end.x - 1, y), 1.0 * p.w / 128.0, Ink.INK, 0.6, 0.4)
		Ink.line(p, Vector2(r.position.x + 1, y + 1.2), Vector2(r.end.x - 1, y + 1.2), 0.8, LIT_EDGE, 0.15, 0.4)
	Ink.path(p, front, 1.5 * p.w / 128.0, true, Ink.INK, 0.8, 0.3)
	Ink.path(p, top, 1.2 * p.w / 128.0, true, Ink.INK, 0.7, 0.3)


## 빛 번짐(투명한 배경에도 보이게): 빈 곳엔 반투명 빛 색을 깔고, 칠한 곳엔 빛을 더한다. 물건보다 먼저 부른다.
static func halo(p: Paint, c: Vector2, r: float, col: Color, strength: float) -> void:
	for y in range(maxi(0, int(c.y - r)), mini(p.h - 1, int(c.y + r)) + 1):
		for x in range(maxi(0, int(c.x - r)), mini(p.w - 1, int(c.x + r)) + 1):
			var d := Vector2(x - c.x, y - c.y).length() / r
			if d >= 1.0:
				continue
			var f := (1.0 - d) * (1.0 - d) * strength * (0.85 + 0.3 * p.nz("mid", x, y))
			if p.alpha_at(x, y) > 0.0:
				p.add_light(x, y, col, f * 0.6)
			else:
				p.blend(x, y, col, f * 0.55)


## 돌에 박힌 작은 녹색 반짝임(광석 알갱이): 짧은 결정 조각 하나 + 밝은 점 + 작은 빛.
static func glint(p: Paint, q: Vector2, r: float) -> void:
	Ink.glow(p, q.x, q.y, r * 4.0, LIME_GLOW, 0.3)
	shard(p, q + Vector2(0, r * 0.6), -PI * 0.5 + p.rng.randf_range(-0.6, 0.6), r * 2.4, r * 0.75)
	Cave._dot(p, q + Vector2(-0.3, -0.8) * r, r * 0.45, Color("#f6ffd8"), 0.9)
