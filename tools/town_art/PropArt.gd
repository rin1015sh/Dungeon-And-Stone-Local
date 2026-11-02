extends RefCounted
## 동네 거리 소품 그림(CT85 — 집과 같은 횡스크롤 붓): 가로등(Props.lamp_post) · 통(Props.barrel) · 상자(Props.crate) · 자루(Props.sack) ·
## 공시판 · 정산 천막 · 광장 세 단 돌 단과 선 돌 고리. 칸당 S px, 발 = 그림 아래 가운데 → assets/town/props/<kind>.webp(TownProp이 1/배율로 그린다).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Props := preload("res://tools/city_art/Props.gd")

const KINDS := ["lamp", "barrel", "crate", "sacks", "board", "tent", "dais"]


## kind → Paint(발 = 아래 가운데). size = 차지한 칸 수(가로·세로 — 천막·돌 단).
static func paint(kind: String, S: float, size: Vector2i, seed_value: int) -> Paint:
	match kind:
		"lamp":
			var p := Paint.new(int(S * 1.4), int(S * 3.0), seed_value)
			Props.lamp_post(p, p.w * 0.5, p.h - 4, S * 2.3)
			return _done(p)
		"barrel":
			var p := Paint.new(int(S * 0.9), int(S * 1.0), seed_value)
			Props.barrel(p, p.w * 0.5, p.h - 3, S * 0.55, S * 0.75)
			return _done(p)
		"crate":
			var p := Paint.new(int(S * 0.9), int(S * 0.9), seed_value)
			_box(p, p.w * 0.5, p.h - 3, S * 0.6)
			return _done(p)
		"sacks":
			var p := Paint.new(int(S * 1.0), int(S * 0.9), seed_value)
			Props.sack(p, p.w * 0.36, p.h - 3, S * 0.5)
			Props.sack(p, p.w * 0.64, p.h - 3, S * 0.46)
			Props.sack(p, p.w * 0.5, p.h - S * 0.3, S * 0.42)
			return _done(p)
		"board":
			var p := Paint.new(int(S * size.x + 8), int(S * 1.8), seed_value)
			_board(p, S)
			return _done(p)
		"tent":
			var p := Paint.new(int(S * size.x + 16), int(S * (size.y + 2.4)), seed_value)
			_tent(p, S, size)
			return _done(p)
		"dais":
			var p := Paint.new(int(S * size.x + 12), int(S * (size.y + 4.2)), seed_value)
			_dais(p, S, size)
			return _done(p)
	return Paint.new(2, 2, seed_value)


static func _done(p: Paint) -> Paint:
	Ink.silhouette(p, 2)
	Ink.grade(p, 0.22, 1.12)
	Ink.finish(p, 0.03)
	return p


## 3/4 상자: 앞면 + 윗면(판자 결) + 잉크.
static func _box(p: Paint, cx: float, ground: float, s: float) -> void:
	var front := Paint.rect_poly(cx - s * 0.5, ground - s * 0.8, s, s * 0.8)
	var top := Paint.poly([Vector2(cx - s * 0.5, ground - s * 0.8), Vector2(cx + s * 0.5, ground - s * 0.8), Vector2(cx + s * 0.4, ground - s * 1.2), Vector2(cx - s * 0.6, ground - s * 1.2)])
	p.fill_poly(front, Mat.planks(p, Props.WOOD.lightened(0.1), int(cx), 0, false, int(maxf(5.0, s / 4.0))))
	Ink.line(p, Vector2(cx - s * 0.5, ground - s * 0.8), Vector2(cx + s * 0.5, ground), 2.6, Color("#2c1f15"), 1.0, 0.2)
	Ink.shade(p, front, Vector2(0, ground - s * 0.8), Vector2(0, ground), 0.0, 0.35)
	Ink.path(p, front, 1.8)
	p.fill_poly(top, Mat.planks(p, Props.WOOD.lightened(0.25), int(cx), 0, false, int(maxf(5.0, s / 4.0))))
	Ink.path(p, top, 1.8)


static func _board(p: Paint, S: float) -> void:
	var g := float(p.h - 4)
	var w := float(p.w - 8)
	for x: float in [6.0, w - 2.0]:
		Ink.line(p, Vector2(x, g), Vector2(x, g - S * 1.5), 5.0, Color("#2e2118"), 1.0, 0.2)
	var b := Paint.rect_poly(4, g - S * 1.6, w, S * 0.95)
	p.fill_poly(b, Mat.planks(p, Color("#4a3424"), 0, 0, false, 8))
	Ink.path(p, b, Parts.LINE)
	for k in 5:
		var x := 10.0 + k * (w - 20.0) / 5.0 + p.rng.randf_range(-3, 3)
		var paper := Paint.rect_poly(x, g - S * 1.5 + p.rng.randf_range(0, S * 0.25), S * 0.32, S * 0.42)
		p.fill_poly(paper, p.flat(Color("#c9bea0").darkened(p.rng.randf_range(0.0, 0.25)), 0.12))
		Ink.path(p, paper, 1.2)
	p.fill_poly(Paint.poly([Vector2(0, g - S * 1.6), Vector2(w + 8, g - S * 1.6), Vector2(w + 2, g - S * 1.78), Vector2(6, g - S * 1.78)]), Mat.slate(p, Color("#3a4044"), 0, 0, 8, 5, 0.2))
	Ink.path(p, Paint.poly([Vector2(0, g - S * 1.6), Vector2(w + 8, g - S * 1.6), Vector2(w + 2, g - S * 1.78), Vector2(6, g - S * 1.78)]), 1.6)


## 정산 천막: 줄무늬 천 지붕 두 면 + 앞 박공(검은 입구) + 탁자와 저울.
static func _tent(p: Paint, S: float, size: Vector2i) -> void:
	var w := float(p.w - 16)
	var g := float(p.h - 4)
	var x0 := 8.0
	var top := g - S * (size.y + 1.6)
	var eave := g - S * 1.1
	var stripes := func(x: int, y: int) -> Color:
		return p.vary(Color("#7a2e28") if (x / int(S * 0.3)) % 2 == 0 else Color("#cdbf9c"), x, y, 0.15)
	var back := Paint.poly([Vector2(x0 + w * 0.5, top), Vector2(x0 + w, eave - S * size.y * 0.6), Vector2(x0 + w, eave), Vector2(x0 + w * 0.5, eave - S * 0.3)])
	p.fill_poly(back, stripes)
	Ink.shade(p, back, Vector2(x0 + w * 0.5, 0), Vector2(x0 + w, 0), 0.25, 0.5)
	Ink.path(p, back, 1.8)
	var tri := Paint.poly([Vector2(x0, eave), Vector2(x0 + w * 0.5, top), Vector2(x0 + w, eave)])
	p.fill_poly(tri, stripes)
	Ink.shade(p, tri, Vector2(0, top), Vector2(0, eave), 0.0, 0.3)
	Ink.path(p, tri, Parts.LINE)
	var body := Paint.rect_poly(x0 + 4, eave, w - 8, g - eave)
	p.fill_poly(body, p.flat(Color("#2a2420"), 0.1))
	Ink.path(p, body, 1.8)
	var table := Paint.rect_poly(x0 + w * 0.2, g - S * 0.55, w * 0.6, S * 0.5)
	p.fill_poly(table, Mat.planks(p, Color("#4d3726"), 0, 0, false, 7))
	Ink.path(p, table, 1.8)
	var sx := x0 + w * 0.65
	Ink.line(p, Vector2(sx, g - S * 0.55), Vector2(sx, g - S * 1.0), 2.0, Props.IRON, 1.0, 0.1)
	Ink.line(p, Vector2(sx - S * 0.25, g - S * 0.95), Vector2(sx + S * 0.25, g - S * 0.95), 2.0, Props.IRON, 1.0, 0.1)
	Ink.glow(p, x0 + w * 0.35, g - S * 0.8, S * 0.5, Color("#ffb45c"), 0.25)


## 광장 세 단 돌 단(둥근 마름돌 — 앞 옆면은 어둡게) + 단 위에 선 돌 고리(막돌 — 안은 어둡다, 포탈이 열리는 자리).
static func _dais(p: Paint, S: float, size: Vector2i) -> void:
	var r := S * size.x * 0.5
	var cx := p.w * 0.5
	var g := float(p.h - 4)
	for k in 3:
		var rr := r - k * S * 0.75
		var lift := k * S * 0.32
		var cy := g - r - lift - S * 0.32
		var side := _circle(Vector2(cx, cy + S * 0.32), rr)
		p.fill_poly(side, Mat.ashlar(p, Color("#4f4c45"), 0, 0, int(S * 0.6), int(S * 0.3)))
		Ink.path(p, side, 1.8)
		var top := _circle(Vector2(cx, cy), rr)
		p.fill_poly(top, Mat.ashlar(p, Color("#6e695e"), k * 13, 0, int(S * 0.55), int(S * 0.55)))
		Ink.shade(p, top, Vector2(cx - rr, cy - rr), Vector2(cx + rr, cy + rr), 0.0, 0.3)
		Ink.path(p, top, Parts.LINE)
	var base := g - r - S * 1.3
	var R := S * 1.7
	var th := S * 0.38
	var ctr := Vector2(cx, base - R)
	p.fill_poly(_circle(ctr, R - th), p.flat(Color("#141313"), 0.05), 0.75)
	for i in 28:
		var a0 := TAU * i / 28.0
		var a1 := TAU * (i + 1) / 28.0
		var q := Paint.poly([ctr + Vector2.from_angle(a0) * R, ctr + Vector2.from_angle(a1) * R, ctr + Vector2.from_angle(a1) * (R - th), ctr + Vector2.from_angle(a0) * (R - th)])
		p.fill_poly(q, Mat.rubble(p, Color("#77736a").darkened(0.25 * (0.5 + 0.5 * sin(a0 + 0.8)))))
	Ink.path(p, _circle(ctr, R), Parts.LINE)
	Ink.path(p, _circle(ctr, R - th), 1.8)
	for i in 8:
		var a := TAU * i / 8.0
		Ink.line(p, ctr + Vector2.from_angle(a) * (R - th), ctr + Vector2.from_angle(a) * R, 2.0, Ink.INK, 0.8, 0.2)
	var foot := Paint.rect_poly(cx - R * 0.8, base - 6, R * 1.6, 12)
	p.fill_poly(foot, Mat.ashlar(p, Color("#5f5b52"), 0, 0, 20, 10))
	Ink.path(p, foot, 1.8)


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 40:
		out.append(c + Vector2.from_angle(TAU * i / 40.0) * r)
	return out
