extends RefCounted
## 바깥 장면 일러스트 공통 부품(귀환 정산 Settle — 옛 거리 사건 그림에서 남긴 것, CT45): 하늘 · 뒤 집 줄 · 젖은 포석 · 사람 · 군중 옷차림 · 종이(벽보) · 화로 · 마석 무더기.
## 960×540 화면 좌표. tools/paint_city.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Backdrop := preload("res://tools/city_art/Backdrop.gd")
const Street := preload("res://tools/city_art/Street.gd")
const Npc := preload("res://tools/city_art/Npcs.gd")
const NP := preload("res://tools/city_art/NpcParts.gd")

const W := 960
const H := 540
const SKY := Color("#b8b49a")   ## 흐린 낮빛(넓게 조금)
const WARM := Color("#ffb45c")
const FIRE := Color("#ff7a2a")
const WALLS := [Color("#575142"), Color("#4b473b"), Color("#5e5341"), Color("#4f362c"), Color("#514e44")]
const PAPER := Color("#cbbd98")
const STONE := Color("#6fc8b4")  ## 마석 빛(탁한 청록)
## 군중 옷차림(Plaza.LOOKS와 같은 결): 0 짐꾼 · 1 여자 · 2 뚱뚱한 대머리 · 3 두건 쓴 여자 · 4 상투 · 5 창 든 남자.
const CROWD := [
	{"body": "male", "top": Color("#5a4632"), "bottom": Color("#3e362c"), "hair": "short", "hair_c": Color("#2c2016")},
	{"body": "female", "top": Color("#4a5444"), "bottom": Color("#3a3a32"), "hair": "long", "hair_c": Color("#5a3a22")},
	{"body": "stout", "top": Color("#6a3e30"), "bottom": Color("#3e3428"), "hair": "bald"},
	{"body": "female", "top": Color("#3e3a48"), "lower": "robe", "hair": "hood", "hood_c": Color("#4a4458")},
	{"body": "male", "top": Color("#4e4a40"), "bottom": Color("#2e2a24"), "hair": "bun", "hair_c": Color("#1e1812")},
	{"body": "male", "top": Color("#5c5e60"), "bottom": Color("#34363a"), "belt": Color("#2a1e14"), "hair": "short", "hair_c": Color("#1e1812"), "beard": "stubble"},
]


static func crowd_look(i: int) -> Dictionary:
	return (CROWD[i % CROWD.size()] as Dictionary).duplicate()


## 사람 몸 위 점(u 가로, v 발에서 위로 — 키 비율).
static func at(o: Vector3, u: float, v: float) -> Vector2:
	return NP.q(o, u, v)


## 하늘: 위 → 지평선 그라디언트 + 가로 구름 붓질.
static func sky(p: Paint, horizon: float, top: Color = Color("#2c3438"), low: Color = Color("#6a6a52")) -> void:
	p.fill_rect(0, 0, W, horizon, func(x: int, y: int) -> Color:
		return p.vary(top.lerp(low, clampf(y / horizon, 0.0, 1.0)), x, y, 0.08))
	for band in 5:
		var cy := horizon * (0.12 + band * 0.16)
		for i in 40:
			var x := p.rng.randf() * W
			var yy := cy + p.rng.randf_range(-8, 8) + sin(x * 0.012 + band) * 6.0
			Ink.line(p, Vector2(x - 26, yy), Vector2(x + 26, yy + p.rng.randf_range(-2, 2)), p.rng.randf_range(4, 9), top.lerp(low, band / 5.0).lightened(0.12), 0.3, 1.0)


## 뒤 집 줄(x0..x1, 바닥 base, 지붕 높이 top_lo..top_hi) + 아래쪽 안개.
static func houses(p: Paint, base: float, top_lo: float, top_hi: float, x0: float = -10.0, x1: float = W + 10.0, fog: float = 0.35) -> void:
	var x := x0
	while x < x1:
		var bw := p.rng.randf_range(90, 150)
		var top := p.rng.randf_range(top_lo, top_hi)
		Backdrop._townhouse(p, x, top, bw, base - top, WALLS[p.rng.randi() % WALLS.size()])
		x += bw - 1.0
	Ink.shade(p, Paint.rect_poly(0, top_lo - 80, W, base - top_lo + 80), Vector2(0, top_lo), Vector2(0, base), 0.05, fog, Color("#3a3d36"))


## 젖은 포석(y0 아래 전부): 앞으로 올수록 큰 돌 + 웅덩이 한두 개.
static func ground(p: Paint, y0: float) -> void:
	p.fill_rect(0, y0, W, H - y0, p.flat(Color("#22211d"), 0.3))
	var y := y0
	var rh := 7.0
	while y < H:
		var x := -p.rng.randf() * rh * 2.0
		while x < W:
			var sw := rh * p.rng.randf_range(1.2, 2.4)
			Street._cobble(p, x, y, sw, rh)
			x += sw
		y += rh
		rh *= 1.13
	Ink.shade(p, Paint.rect_poly(0, y0, W, H - y0), Vector2(0, y0), Vector2(0, H), 0.35, 0.0)


## 사람 하나(발 = x, ground): 그림자 + Npcs 인물. 기본 피부·빛 왼쪽.
static func person(p: Paint, x: float, ground_y: float, h: float, look: Dictionary) -> void:
	var lk := look.duplicate()
	if not lk.has("skin"):
		lk["skin"] = Npc.SKIN
	Npc.figure(p, x, ground_y, h, lk)


## 먼 사람은 안개 색으로(색 값만).
static func hazed(look: Dictionary, k: float) -> Dictionary:
	var out := look.duplicate()
	for key: String in out.keys():
		if out[key] is Color:
			out[key] = (out[key] as Color).lerp(Color("#4a4c44"), k)
	return out


## 종이 한 장(벽보·포고문): 누런 종이 + 접힌 그늘 + 글 줄 + (seal) 붉은 밀랍. face = 서툰 얼굴 그림(현상수배).
static func paper(p: Paint, x: float, y: float, pw: float, ph: float, seal: bool = false, face: bool = false, torn: bool = false) -> void:
	var pts: Array = [Vector2(x, y), Vector2(x + pw, y + 2), Vector2(x + pw - 1, y + ph), Vector2(x + 2, y + ph - 2)]
	if torn:
		pts = [Vector2(x, y), Vector2(x + pw, y + 2), Vector2(x + pw - 2, y + ph * 0.55), Vector2(x + pw * 0.6, y + ph * 0.7), Vector2(x + pw * 0.3, y + ph * 0.52), Vector2(x + 2, y + ph * 0.6)]
	var poly := Paint.poly(pts)
	p.fill_poly(poly, p.flat(PAPER.darkened(p.rng.randf_range(0.0, 0.2)), 0.18))
	Ink.shade(p, poly, Vector2(x, y), Vector2(x + pw, y + ph), 0.0, 0.3)
	Ink.path(p, poly, 1.4, true, Ink.INK, 0.8)
	var ty := y + 8.0
	if face:
		var c := Vector2(x + pw / 2.0, y + ph * 0.32)
		var r := pw * 0.2
		var head := PackedVector2Array()
		for i in 14:
			head.append(c + Vector2(cos(TAU * i / 14.0) * r * 0.8, sin(TAU * i / 14.0) * r))
		Ink.path(p, head, 1.4, true, Ink.INK, 0.85, 1.0)
		for s: float in [-1.0, 1.0]:
			Ink.line(p, c + Vector2(s * r * 0.35 - 2, -r * 0.15), c + Vector2(s * r * 0.35 + 2, -r * 0.15), 2.0, Ink.INK, 0.9, 0.2)
		Ink.line(p, c + Vector2(-r * 0.3, r * 0.45), c + Vector2(r * 0.3, r * 0.4), 1.4, Ink.INK, 0.8, 0.5)
		ty = c.y + r * 1.4
	while ty < y + ph * (0.55 if torn else 0.82):
		Ink.line(p, Vector2(x + 6, ty), Vector2(x + pw - 6 - p.rng.randf_range(0, pw * 0.3), ty), 1.2, Color("#3a2e22"), 0.55, 0.6)
		ty += 7.0
	if seal:
		var sc := Vector2(x + pw * 0.75, y + ph - 12)
		var wax := PackedVector2Array()
		for i in 12:
			wax.append(sc + Vector2.from_angle(TAU * i / 12.0) * p.rng.randf_range(6.0, 8.0))
		p.fill_poly(wax, p.flat(Color("#7d2620"), 0.15))
		Ink.path(p, wax, 1.0, true, Ink.INK, 0.7)
	for nx: float in [x + 4, x + pw - 5]:  # 못
		p.fill_rect(nx - 1.5, y + 2, 3, 3, p.flat(Color("#1a1612"), 0.05))


## 횃대 위 화로(쇠 바구니 + 불).
static func brazier(p: Paint, cx: float, ground_y: float, s: float = 1.0) -> void:
	Ink.line(p, Vector2(cx, ground_y), Vector2(cx, ground_y - 70 * s), 5.0 * s, Color("#24221f"), 1.0, 0.2)
	var bowl := Paint.poly([Vector2(cx - 20 * s, ground_y - 86 * s), Vector2(cx + 20 * s, ground_y - 86 * s), Vector2(cx + 12 * s, ground_y - 68 * s), Vector2(cx - 12 * s, ground_y - 68 * s)])
	p.fill_poly(bowl, p.flat(Color("#2a2622"), 0.1))
	Ink.path(p, bowl, 2.0)
	Bits.torch(p, Vector2(cx, ground_y - 84 * s))


## 마석 한 무더기: 각진 작은 돌 n개(밑은 넓고 위로 좁게) + 빛.
static func stones(p: Paint, cx: float, base: float, wide: float, n: int) -> void:
	for i in n:
		var t := p.rng.randf()
		var q := Vector2(cx + p.rng.randf_range(-wide, wide) * (1.0 - t * 0.7), base - t * wide * 0.55 - p.rng.randf_range(0, 4))
		var r := p.rng.randf_range(4.0, 7.5)
		var pts := PackedVector2Array()
		for k in 6:
			pts.append(q + Vector2.from_angle(TAU * k / 6.0 + p.rng.randf()) * r * p.rng.randf_range(0.7, 1.1))
		p.fill_poly(pts, p.flat(STONE.darkened(p.rng.randf_range(0.2, 0.6)), 0.15))
		Ink.path(p, pts, 1.0, true, Ink.INK, 0.7, 0.2)
		Ink.line(p, q + Vector2(-2, -2), q + Vector2(1, -3), 1.2, STONE.lightened(0.4), 0.7, 0.1)
	Ink.glow(p, cx, base - wide * 0.2, wide * 1.6, STONE, 0.35, false)
