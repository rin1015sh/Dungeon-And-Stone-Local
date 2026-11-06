extends RefCounted
## 고블린 숲 큰 구조물(FL21 — f2d_big.gd와 같은 틀: 한 그림 = 바닥 8 × 10칸, 발 = 아래 가운데, 발자리 칸은 막음 타일).
## 빈터의 거대한 나무(살아 있는 숲 — 넓은 잎 지붕 · 굵은 뿌리), 고블린 오두막(진흙 벽 + 짚 지붕), 가죽 천막, 망대(기둥 넷 위 판자).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Big := preload("res://tools/floor_art/rift/f2d_big.gd")

const BARK := Color("#352d26")
const BARK_L := Color("#5c5044")
const LEAF_D := Color("#1e281e")
const LEAF := Color("#34422e")
const LEAF_L := Color("#56664a")
const MUD := Color("#5a4e3e")
const THATCH := Color("#7a6a46")
const HIDE := Color("#6e5a44")
const SILVER := Color("#c4d0d8")
const INK := Color("#100c0a")
const LW := 1.4


static func paint(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var T := float(w) / 8.0
	var f := Vector2(w * 0.5, h - T * 0.5)
	match tile:
		"bigtree":
			_bigtree(p, f, T)
		"hut":
			_hut(p, f, T)
		"tent":
			_tent(p, f, T)
		"watch":
			_watch(p, f, T)
		_:
			pass
	return p


static func _leaves(p: Paint, c: Vector2, rx: float, ry: float, n: int, s: int) -> void:
	for k in n:
		var a := Paint.hash01(k, 1, s) * TAU
		var d := sqrt(Paint.hash01(k, 2, s))
		var q := c + Vector2(cos(a) * rx * d * 0.85, sin(a) * ry * d * 0.85)
		var rr := rx * (0.16 + Paint.hash01(k, 3, s) * 0.14)
		var t := clampf(0.55 - (q.y - c.y) / ry * 0.5 - (q.x - c.x) / rx * 0.25, 0.0, 1.0)
		p.fill_poly(Cave._ellipse(q, rr, rr * 0.82, 20), func(_x: int, _y: int) -> Color: return LEAF_D.lerp(LEAF_L, t))
		Ink.path(p, Cave._ellipse(q, rr, rr * 0.82, 20), LW * 0.7, true, INK, 0.35, 0.4)
	for k in 26:
		var a := PI + Paint.hash01(k, 4, s) * PI
		Cave._dot(p, c + Vector2(cos(a) * rx * 0.8, sin(a) * ry * 0.75), 1.6, SILVER, 0.55)


## 빈터의 거대한 나무: 갈라진 굵은 줄기 + 땅을 움켜쥔 뿌리 + 넓은 잎 지붕(그림판 위쪽 대부분).
static func _bigtree(p: Paint, f: Vector2, T: float) -> void:
	Big._shadow(p, f + Vector2(0, -T * 0.2), T * 3.4, T * 1.1)
	for k in 5:  # 뿌리
		var dx := (k - 2) * T * 0.9
		Ink.line(p, f + Vector2(dx * 0.3, -T * 1.2), f + Vector2(dx * 1.3, T * 0.1), T * 0.38, BARK, 1.0, 0.3)
	var trunk := PackedVector2Array([f + Vector2(-T * 1.1, 0), f + Vector2(-T * 0.7, -T * 4.0), f + Vector2(-T * 1.4, -T * 6.0),
		f + Vector2(T * 1.3, -T * 6.0), f + Vector2(T * 0.7, -T * 4.0), f + Vector2(T * 1.2, 0)])
	Big._face(p, trunk, BARK, 0.2)
	for k in 6:  # 껍질 결
		var x := f.x + (k - 2.5) * T * 0.35
		Ink.line(p, Vector2(x, f.y - T * 0.3), Vector2(x + (k - 2.5) * T * 0.1, f.y - T * 5.5), LW, BARK_L, 0.5, 0.7)
	Decals._blob(p, f + Vector2(-T * 0.6, -T * 1.2), T * 0.5, Color("#3e4c38"), 0.7, 0.4)
	_leaves(p, f + Vector2(0, -T * 6.9), T * 3.8, T * 2.1, 46, 7)


## 고블린 오두막: 둥근 진흙 벽(짚 섞임) + 원뿔 짚 지붕 + 낮은 문 구멍 + 지붕 위 해골.
static func _hut(p: Paint, f: Vector2, T: float) -> void:
	Big._shadow(p, f, T * 2.6, T * 0.9)
	var wall := Big._box(p, f, T * 4.2, T * 2.4, T * 2.2, MUD)
	var front: PackedVector2Array = wall["front"]
	p.fill_poly(PackedVector2Array([f + Vector2(-T * 0.45, 0), f + Vector2(-T * 0.45, -T * 1.3), f + Vector2(T * 0.45, -T * 1.3), f + Vector2(T * 0.45, 0)]),
		func(_x: int, _y: int) -> Color: return Color("#0a0806"))
	for k in 9:
		var q := front[3] + Vector2(Paint.hash01(k, 1, 4) * T * 4.2, -Paint.hash01(k, 2, 4) * T * 2.0)
		Ink.line(p, q, q + Vector2(T * 0.25, -T * 0.05), LW, THATCH, 0.6, 0.3)
	var apex := f + Vector2(T * 0.2, -T * 6.2)
	var roof := PackedVector2Array([f + Vector2(-T * 2.8, -T * 2.0), apex, f + Vector2(T * 3.1, -T * 2.3), f + Vector2(T * 0.3, -T * 1.6)])
	Big._face(p, roof, THATCH, 0.1)
	for k in 12:
		var t := float(k) / 12.0
		Ink.line(p, apex, roof[0].lerp(roof[2], t), LW * 0.8, THATCH.darkened(0.35), 0.5, 0.4)
	p.fill_poly(Cave._ellipse(apex + Vector2(0, T * 0.2), T * 0.35, T * 0.3, 14), func(_x: int, _y: int) -> Color: return Color("#cfc6ae"))


## 가죽 천막: 기운 막대 셋에 덮은 기운 가죽(꿰맨 줄) + 앞 자락 젖힘.
static func _tent(p: Paint, f: Vector2, T: float) -> void:
	Big._shadow(p, f, T * 2.4, T * 0.8)
	var apex := f + Vector2(0, -T * 4.6)
	var left := PackedVector2Array([f + Vector2(-T * 2.4, 0), apex, f + Vector2(-T * 0.2, T * 0.1)])
	var right := PackedVector2Array([f + Vector2(-T * 0.2, T * 0.1), apex, f + Vector2(T * 2.3, -T * 0.3)])
	Big._face(p, right, HIDE, -0.7)
	Big._face(p, left, HIDE, 0.4)
	p.fill_poly(PackedVector2Array([f + Vector2(-T * 0.6, T * 0.05), apex + Vector2(0, T * 1.6), f + Vector2(T * 0.4, 0)]), func(_x: int, _y: int) -> Color: return Color("#0c0a08"))
	for k in 3:
		Ink.line(p, apex, apex + Vector2((k - 1) * T * 0.4, -T * 0.8), LW * 1.6, BARK, 1.0, 0.2)
	for k in 4:
		var t := 0.25 + k * 0.18
		Ink.line(p, apex.lerp(left[0], t), apex.lerp(left[0], t) + Vector2(T * 0.6, T * 0.1), LW, HIDE.darkened(0.4), 0.7, 0.3)


## 망대: 기둥 넷 위 판자 바닥 + 난간, 사다리.
static func _watch(p: Paint, f: Vector2, T: float) -> void:
	Big._shadow(p, f, T * 2.2, T * 0.7)
	for x in [-1.6, 1.6]:
		Ink.line(p, f + Vector2(x * T, 0), f + Vector2(x * T * 0.85, -T * 5.0), T * 0.3, BARK, 1.0, 0.2)
		Ink.line(p, f + Vector2(x * T * 0.7, -T * 0.6), f + Vector2(x * T * 0.6, -T * 5.2), T * 0.24, BARK.darkened(0.3), 1.0, 0.2)
	Ink.line(p, f + Vector2(-T * 1.5, -T * 1.5), f + Vector2(T * 1.5, -T * 3.5), T * 0.12, BARK_L, 0.8, 0.2)
	Big._box(p, f + Vector2(0, -T * 5.0), T * 3.8, T * 2.0, T * 0.35, BARK_L)
	for k in 5:
		var x := -T * 1.8 + k * T * 0.9
		Ink.line(p, f + Vector2(x, -T * 5.3), f + Vector2(x, -T * 6.3), T * 0.12, BARK, 1.0, 0.2)
	Ink.line(p, f + Vector2(-T * 1.9, -T * 6.2), f + Vector2(T * 1.9, -T * 6.2), T * 0.14, BARK, 1.0, 0.2)
	for k in 6:  # 사다리
		var y := -T * 0.5 - k * T * 0.75
		Ink.line(p, f + Vector2(-T * 0.35, y), f + Vector2(T * 0.35, y), T * 0.1, BARK_L, 0.9, 0.2)
