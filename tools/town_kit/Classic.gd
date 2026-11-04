extends RefCounted
## 신고전풍 석조 면 그림(은행 — CT109, 사용자 2026-11-04 "세부적인 요소들을 넣어서 건물을 다시 그려").
##   facade = 정면(거친 돌 1층 · 창살 아치창 · 2층 박공 얹은 창 · 모서리 돌 · 이빨 장식 처마)
##   side = 옆 · 뒤(같은 문법 · 창 적게) · frieze = 현관 위 띠(이빨 장식 · 둥근 무늬) · pediment = 삼각 박공(동전 · 저울 문장 부조)
##   column = 기둥 조각(세로 홈 줄 — Kit.cylinder painter_i)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const F := preload("res://tools/town_kit/Facade.gd")
const G := preload("res://tools/town_kit/Gothic.gd")

const STONE := Color("#a8a294")
const STONE_L := Color("#bdb7a8")
const STONE_D := Color("#77736a")
const IRON := Color("#22201d")


## 거친 돌(1층 — 줄눈이 깊은 큰 돌, 위아래 그늘이 짙다).
static func _rustic(p: Paint) -> Callable:
	var bh := int(F.P * 0.22)
	var bw := int(F.P * 0.5)
	return func(x: int, y: int) -> Color:
		var row := floori(float(y) / bh)
		var lx := x + (bw / 2 if row % 2 != 0 else 0)
		var by := posmod(y, bh)
		var bx := posmod(lx, bw)
		if by < 3:
			return Color("#3a3630")
		var c := STONE.lightened((Paint.hash01(row, floori(float(lx) / bw), 3) - 0.5) * 0.12)
		if by < 7:
			c = c.lightened(0.1)
		elif by > bh - 6:
			c = c.darkened(0.25)
		if bx < 2:
			c = c.darkened(0.2)
		return p.vary(c, x, y, 0.1)


static func _smooth(p: Paint) -> Callable:
	return Mat.ashlar(p, STONE_L, 0, 0, int(F.P * 0.42), int(F.P * 0.16))


## 처마 띠(돌림 + 이빨 장식).
static func cornice(p: Paint, x: float, y: float, w: float) -> void:
	var band := Paint.rect_poly(x - 4, y, w + 8, 10)
	p.fill_poly(band, p.flat(STONE_L, 0.05))
	Ink.path(p, band, 1.4)
	var d := x
	while d < x + w - 6:
		var dent := Paint.rect_poly(d + 2, y + 10, 7, 8)
		p.fill_poly(dent, p.flat(STONE_L.darkened(0.05), 0.04))
		Ink.path(p, dent, 0.9)
		d += 12.0
	Ink.shade(p, Paint.rect_poly(x, y + 18, w, 12), Vector2(0, y + 18), Vector2(0, y + 30), 0.4, 0.0)


## 쇠창살 아치창(1층).
static func barred(p: Paint, cx: float, base: float, w: float, h: float, lit: bool) -> void:
	var arch := Paint.arch_poly(cx - w * 0.5, base - h, w, h, false)
	var frame := Paint.arch_poly(cx - w * 0.5 - 7, base - h - 7, w + 14, h + 7, false)
	p.fill_poly(frame, p.flat(STONE_L, 0.05))
	Ink.path(p, frame, 1.6)
	p.fill_poly(arch, Mat.glass(p, base - h, base, lit))
	var bx := cx - w * 0.5 + w / 6.0
	while bx < cx + w * 0.5 - 2:
		Ink.line(p, Vector2(bx, base - h + 6), Vector2(bx, base), 2.4, IRON, 1.0, 0.1)
		bx += w / 6.0
	for t: float in [0.4, 0.75]:
		Ink.line(p, Vector2(cx - w * 0.5, base - h * t), Vector2(cx + w * 0.5, base - h * t), 2.0, IRON, 1.0, 0.1)
	Ink.path(p, arch, 1.4)
	var key := Paint.poly([Vector2(cx - 7, base - h - 10), Vector2(cx + 7, base - h - 10), Vector2(cx + 5, base - h + 6), Vector2(cx - 5, base - h + 6)])
	p.fill_poly(key, p.flat(STONE_L.lightened(0.08), 0.05))
	Ink.path(p, key, 1.2)
	if lit:
		Ink.glow(p, cx, base - h * 0.5, w, Color("#ffb45c"), 0.2)


## 박공 얹은 창(2층 — 네모 창 + 작은 삼각 지붕 + 창 아래 받침).
static func pedimented(p: Paint, cx: float, top: float, w: float, h: float, lit: bool) -> void:
	Parts.window(p, cx - w * 0.5, top, w, h, "square", lit, false)
	var tri := Paint.poly([Vector2(cx - w * 0.5 - 12, top - 18), Vector2(cx + w * 0.5 + 12, top - 18), Vector2(cx, top - 38)])
	p.fill_poly(tri, p.flat(STONE_L, 0.05))
	Ink.shade(p, tri, Vector2(0, top - 38), Vector2(0, top - 18), 0.0, 0.25)
	Ink.path(p, tri, 1.4)
	for s: float in [-1.0, 1.0]:
		var br := Paint.rect_poly(cx + s * (w * 0.5 + 6) - 4, top + h + 6, 8, 12)
		p.fill_poly(br, p.flat(STONE_L, 0.05))
		Ink.path(p, br, 1.0)


static func facade(windows: bool = true) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := Paint.bounds(poly)
		var P := F.P
		var fh := F.storey * P
		var g := r.end.y
		var split := g - fh * 1.1
		Parts.wall(p, poly, _smooth(p))
		var low := Geometry2D.intersect_polygons(poly, Paint.rect_poly(r.position.x, split, r.size.x, g - split))
		if not low.is_empty():
			p.fill_poly(low[0], _rustic(p))
			Ink.path(p, low[0], 1.4)
		G.quoins(p, Rect2(r.position.x, r.position.y, r.size.x, split - r.position.y))
		var string := Paint.rect_poly(r.position.x - 3, split - 8, r.size.x + 6, 10)
		p.fill_poly(string, p.flat(STONE_L, 0.05))
		Ink.path(p, string, 1.4)
		if windows:
			var n := maxi(2, int(r.size.x / (P * 1.1)))
			for k in n:
				var cx := r.position.x + r.size.x * (k + 0.5) / n
				if absf(cx - r.get_center().x) > P * 0.9 or n <= 2:
					barred(p, cx, g - P * 0.18, P * 0.42, fh * 0.72, k % 2 == 1)
				pedimented(p, cx, split - fh * 0.78, P * 0.34, fh * 0.46, k % 3 == 0)
		cornice(p, r.position.x, r.position.y + 4, r.size.x)


static func side() -> Callable:
	return facade(true)


## 현관 위 띠(돌림 · 둥근 무늬 · 이빨).
static func frieze() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := Paint.bounds(poly)
		p.fill_poly(poly, _smooth(p))
		cornice(p, r.position.x, r.position.y + 2, r.size.x)
		var x := r.position.x + 20.0
		while x < r.end.x - 12:
			Ink.path(p, G.circle(Vector2(x, r.end.y - r.size.y * 0.32), 6.0, 12), 1.2, true, STONE_D)
			x += 34.0
		Ink.path(p, poly, 1.4)


## 삼각 박공(테두리 · 가운데 문장 — 동전 둘레 월계 잎 · 위에 저울).
static func pediment() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := Paint.bounds(poly)
		p.fill_poly(poly, _smooth(p))
		Ink.shade(p, poly, Vector2(0, r.position.y), Vector2(0, r.end.y), 0.0, 0.2)
		var c := Vector2(r.get_center().x, r.end.y - r.size.y * 0.36)
		var rr := minf(r.size.y * 0.26, 34.0)
		var coin := G.circle(c, rr, 28)
		p.fill_poly(coin, p.flat(Color("#b8a46a"), 0.05))
		Ink.path(p, coin, 1.6)
		Ink.path(p, G.circle(c, rr * 0.7, 22), 1.0, true, Color("#6a5a30"))
		for s: float in [-1.0, 1.0]:
			for k in 6:
				var a := PI * 0.5 + s * (0.5 + k * 0.32)
				var q := c + Vector2.from_angle(a) * rr * 1.35
				var leaf := Paint.poly([q + Vector2(-5, 0), q + Vector2(0, -4), q + Vector2(5, 0), q + Vector2(0, 4)])
				p.fill_poly(leaf, p.flat(STONE_L, 0.05))
				Ink.path(p, leaf, 0.8)
		Ink.line(p, c + Vector2(-rr * 0.5, -rr * 0.2), c + Vector2(rr * 0.5, -rr * 0.2), 2.0, Color("#4a3a1a"), 1.0, 0.1)
		Ink.line(p, c + Vector2(0, -rr * 0.5), c + Vector2(0, rr * 0.4), 2.0, Color("#4a3a1a"), 1.0, 0.1)
		Ink.path(p, poly, 1.6)


## 기둥 조각 i(세로 홈 — 밝은 면 · 어두운 홈 번갈아).
static func column(i: int) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := Paint.bounds(poly)
		p.fill_poly(poly, p.flat(STONE_L.lightened(0.04) if i % 2 == 0 else STONE_L.darkened(0.1), 0.04))
		Ink.line(p, Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), 1.0, STONE_D, 0.6, 0.0)
