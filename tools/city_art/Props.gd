extends RefCounted
## 소품(건물 앞·거리·실내 공용): 술통 · 상자 · 자루 · 긴 의자 · 촛불 · 담쟁이 · 가로등 · 허수아비 · 무기걸이 · 깃발 · 수레 · 우물 · 울타리.
## 모두 같은 잉크 굵기와 붓결. (x, ground) = 아래 가운데(또는 왼쪽 아래) 기준.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")

const WOOD := Color("#4d3726")
const IRON := Color("#24221f")


static func barrel(p: Paint, cx: float, ground: float, bw: float, bh: float) -> void:
	var pts: Array = []
	for i in 13:
		var t := float(i) / 12.0
		pts.append(Vector2(cx - bw / 2.0 - sin(t * PI) * bw * 0.08, ground - bh * t))
	for i in 13:
		var t := 1.0 - float(i) / 12.0
		pts.append(Vector2(cx + bw / 2.0 + sin(t * PI) * bw * 0.08, ground - bh * t))
	var poly := Paint.poly(pts)
	p.fill_poly(poly, Mat.planks(p, WOOD, int(cx - bw / 2.0), 0, true, int(maxf(5.0, bw / 5.0))))
	Ink.shade(p, poly, Vector2(cx - bw / 2.0, 0), Vector2(cx + bw / 2.0, 0), 0.0, 0.5)
	for t: float in [0.15, 0.5, 0.85]:
		var y := ground - bh * t
		Ink.line(p, Vector2(cx - bw / 2.0 - bw * 0.06, y), Vector2(cx + bw / 2.0 + bw * 0.06, y), 2.6, IRON, 0.95, 0.2)
	Ink.path(p, poly, 2.0)


static func crate(p: Paint, cx: float, ground: float, s: float) -> void:
	var poly := Paint.rect_poly(cx - s / 2.0, ground - s, s, s)
	p.fill_poly(poly, Mat.planks(p, WOOD.lightened(0.12), int(cx), 0, false, int(maxf(5.0, s / 4.0))))
	Ink.shade(p, poly, Vector2(cx - s / 2.0, 0), Vector2(cx + s / 2.0, 0), 0.0, 0.35)
	Ink.line(p, Vector2(cx - s / 2.0, ground - s), Vector2(cx + s / 2.0, ground), 3.0, Color("#2c1f15"), 1.0, 0.2)
	Ink.path(p, poly, 2.0)


static func sack(p: Paint, cx: float, ground: float, s: float = 30.0) -> void:
	var poly := Paint.poly([Vector2(cx - s * 0.2, ground - s), Vector2(cx + s * 0.2, ground - s), Vector2(cx + s * 0.55, ground - s * 0.3), Vector2(cx + s * 0.45, ground), Vector2(cx - s * 0.45, ground), Vector2(cx - s * 0.55, ground - s * 0.3)])
	p.fill_poly(poly, p.flat(Color("#7b6a4c"), 0.25))
	Ink.shade(p, poly, Vector2(cx - s * 0.5, 0), Vector2(cx + s * 0.5, 0), 0.0, 0.4)
	Ink.path(p, poly, 1.8)


static func bench(p: Paint, cx: float, ground: float, bw: float) -> void:
	var seat := Paint.rect_poly(cx - bw / 2.0, ground - 26, bw, 7)
	for lx: float in [cx - bw / 2.0 + 8, cx + bw / 2.0 - 14]:
		var leg := Paint.rect_poly(lx, ground - 22, 6, 22)
		p.fill_poly(leg, p.flat(WOOD.darkened(0.2), 0.2))
		Ink.path(p, leg, 1.6)
	p.fill_poly(seat, Mat.planks(p, WOOD, 0, 0, false, 7))
	Ink.path(p, seat, 1.8)


static func candle(p: Paint, cx: float, ground: float, ch: float = 14.0) -> void:
	var body := Paint.rect_poly(cx - 3, ground - ch, 6, ch)
	p.fill_poly(body, p.flat(Color("#d8cfb4"), 0.1))
	Ink.path(p, body, 1.2)
	var flame := Paint.poly([Vector2(cx, ground - ch - 10), Vector2(cx + 3, ground - ch - 3), Vector2(cx, ground - ch), Vector2(cx - 3, ground - ch - 3)])
	p.fill_poly(flame, p.flat(Color("#ffd58a"), 0.05))
	Ink.glow(p, cx, ground - ch - 5, 26.0, Color("#ffb45c"), 0.3, false)


## 담쟁이: 벽 위에 잎 덩이(짙은 녹갈색) + 늘어진 줄기.
static func ivy(p: Paint, x: float, y: float, iw: float, ih: float, c: Color = Color("#34402a")) -> void:
	for i in int(iw * ih / 420.0):
		var cx := x + p.rng.randf() * iw
		var cy := y + pow(p.rng.randf(), 1.6) * ih
		var r := p.rng.randf_range(3.0, 7.0)
		for yy in range(int(cy - r), int(cy + r) + 1):
			for xx in range(int(cx - r), int(cx + r) + 1):
				var d := Vector2(xx - cx, yy - cy).length() / r
				if d < 1.0 and p.nz("mid", xx * 3, yy * 3) > 0.35:
					var t := p.nz("hi", xx, yy)
					p.tint(xx, yy, c.lightened(0.25) if t > 0.75 else (c.darkened(0.4) if t < 0.3 else c), 0.92 * (1.0 - d * d * 0.5))
	for i in int(iw / 14.0):
		var vx := x + p.rng.randf() * iw
		Ink.line(p, Vector2(vx, y + p.rng.randf() * ih * 0.3), Vector2(vx + p.rng.randf_range(-8, 8), y + ih * p.rng.randf_range(0.5, 1.0)), 1.2, c.darkened(0.3), 0.7, 2.0)


## 쇠 가로등(길가 공용) — 기둥 + 등 + 빛 번짐.
static func lamp_post(p: Paint, cx: float, ground: float, ph: float = 150.0) -> void:
	Ink.line(p, Vector2(cx, ground), Vector2(cx, ground - ph), 5.0, IRON, 1.0, 0.3)
	Ink.line(p, Vector2(cx - 9, ground), Vector2(cx + 9, ground), 6.0, IRON, 1.0, 0.2)
	Ink.line(p, Vector2(cx, ground - ph + 20), Vector2(cx + 16, ground - ph + 4), 2.4, IRON, 1.0, 0.2)
	var lamp := Paint.poly([Vector2(cx - 10, ground - ph - 4), Vector2(cx + 10, ground - ph - 4), Vector2(cx + 7, ground - ph + 18), Vector2(cx - 7, ground - ph + 18)])
	p.fill_poly(lamp, p.flat(Color("#ffd08a"), 0.08))
	Ink.path(p, lamp, 2.2, true, IRON, 1.0, 0.2)
	Ink.line(p, Vector2(cx - 13, ground - ph - 6), Vector2(cx + 13, ground - ph - 6), 4.0, IRON, 1.0, 0.1)
	Ink.glow(p, cx, ground - ph + 7, 90.0, Color("#ffb45c"), 0.3)


## 훈련용 허수아비: 말뚝 + 가로대 팔(끝에 짚 뭉치) + 밧줄로 묶은 짚 몸통 + 둥근 자루 머리(꿰맨 자국) + 핏빛 천.
static func dummy(p: Paint, cx: float, ground: float, s: float = 1.0) -> void:
	Ink.line(p, Vector2(cx, ground), Vector2(cx, ground - 118 * s), 7.0 * s, WOOD.lightened(0.1), 1.0, 0.3)
	Ink.line(p, Vector2(cx - 44 * s, ground - 90 * s), Vector2(cx + 44 * s, ground - 94 * s), 6.0 * s, WOOD.lightened(0.1), 1.0, 0.3)
	for sgn: float in [-1.0, 1.0]:
		var hand := Paint.poly([Vector2(cx + sgn * 40 * s, ground - 100 * s), Vector2(cx + sgn * 52 * s, ground - 98 * s), Vector2(cx + sgn * 54 * s, ground - 84 * s), Vector2(cx + sgn * 40 * s, ground - 84 * s)])
		p.fill_poly(hand, Mat.thatch(p, Color("#8c7646")))
		Ink.path(p, hand, 1.6)
	var body := Paint.poly([Vector2(cx - 16 * s, ground - 102 * s), Vector2(cx + 16 * s, ground - 102 * s), Vector2(cx + 24 * s, ground - 74 * s), Vector2(cx + 20 * s, ground - 44 * s), Vector2(cx - 20 * s, ground - 44 * s), Vector2(cx - 24 * s, ground - 74 * s)])
	p.fill_poly(body, Mat.thatch(p, Color("#9a8150")))
	Ink.shade(p, body, Vector2(cx - 24 * s, 0), Vector2(cx + 24 * s, 0), 0.0, 0.5)
	for t: float in [0.3, 0.7]:
		var y := ground - (102.0 - 58.0 * t) * s
		Ink.line(p, Vector2(cx - 22 * s, y), Vector2(cx + 22 * s, y + 2 * s), 2.4 * s, Color("#3a2a1a"), 1.0, 0.3)
	Ink.path(p, body, 2.0)
	var head: Array = []
	for i in 18:
		head.append(Vector2(cx, ground - 118 * s) + Vector2.from_angle(TAU * i / 18.0) * Vector2(15 * s, 16 * s))
	var hp := Paint.poly(head)
	p.fill_poly(hp, p.flat(Color("#a8956c"), 0.25))
	Ink.shade(p, hp, Vector2(cx - 15 * s, 0), Vector2(cx + 15 * s, 0), 0.0, 0.5)
	Ink.path(p, hp, 2.0)
	Ink.line(p, Vector2(cx - 9 * s, ground - 122 * s), Vector2(cx + 7 * s, ground - 112 * s), 1.4, Ink.INK, 0.8, 0.3)
	Ink.line(p, Vector2(cx + 7 * s, ground - 122 * s), Vector2(cx - 9 * s, ground - 112 * s), 1.4, Ink.INK, 0.8, 0.3)
	Ink.line(p, Vector2(cx - 18 * s, ground - 80 * s), Vector2(cx + 14 * s, ground - 62 * s), 4.0 * s, Color("#7a2219"), 0.95, 0.6)


static func weapon_rack(p: Paint, cx: float, ground: float) -> void:
	for lx: float in [cx - 34, cx + 34]:
		Ink.line(p, Vector2(lx, ground), Vector2(lx, ground - 90), 5.0, WOOD, 1.0, 0.2)
	Ink.line(p, Vector2(cx - 40, ground - 80), Vector2(cx + 40, ground - 80), 5.0, WOOD, 1.0, 0.2)
	Ink.line(p, Vector2(cx - 40, ground - 30), Vector2(cx + 40, ground - 30), 4.0, WOOD, 1.0, 0.2)
	for i in 4:
		var x := cx - 24 + i * 16
		Ink.line(p, Vector2(x, ground - 26), Vector2(x + 4, ground - 112 + (i % 2) * 14), 3.0, Color("#8c8a84") if i % 2 == 0 else WOOD.lightened(0.15), 1.0, 0.1)


static func banner(p: Paint, cx: float, ground: float, c: Color, ph: float = 170.0) -> void:
	Ink.line(p, Vector2(cx, ground), Vector2(cx, ground - ph), 4.0, WOOD.darkened(0.2), 1.0, 0.2)
	var cloth := Paint.poly([Vector2(cx + 2, ground - ph + 6), Vector2(cx + 44, ground - ph + 4), Vector2(cx + 42, ground - ph + 84), Vector2(cx + 23, ground - ph + 70), Vector2(cx + 4, ground - ph + 86)])
	p.fill_poly(cloth, p.flat(c, 0.25))
	Ink.shade(p, cloth, Vector2(0, ground - ph), Vector2(0, ground - ph + 86), 0.0, 0.4)
	Ink.path(p, cloth, 1.8)


static func cart(p: Paint, cx: float, ground: float) -> void:
	var bed := Paint.rect_poly(cx - 50, ground - 52, 100, 24)
	p.fill_poly(bed, Mat.planks(p, WOOD, int(cx), 0, false, 8))
	Ink.path(p, bed, 2.0)
	Ink.line(p, Vector2(cx + 50, ground - 40), Vector2(cx + 96, ground - 24), 3.0, WOOD, 1.0, 0.3)
	var wheel: Array = []
	for i in 20:
		wheel.append(Vector2(cx - 14, ground - 22) + Vector2.from_angle(TAU * i / 20.0) * 22.0)
	var wp := Paint.poly(wheel)
	Ink.path(p, wp, 4.0, true, Color("#2a1e15"))
	for i in 4:
		var a := TAU * i / 8.0
		Ink.line(p, Vector2(cx - 14, ground - 22) - Vector2.from_angle(a) * 20.0, Vector2(cx - 14, ground - 22) + Vector2.from_angle(a) * 20.0, 2.0, Color("#2a1e15"), 1.0, 0.1)
	sack(p, cx + 10, ground - 52, 26)


static func well(p: Paint, cx: float, ground: float) -> void:
	var ring := Paint.rect_poly(cx - 40, ground - 46, 80, 46)
	p.fill_poly(ring, Mat.rubble(p, Color("#5e5a52")))
	Ink.shade(p, ring, Vector2(cx - 40, 0), Vector2(cx + 40, 0), 0.0, 0.4)
	Ink.path(p, ring, 2.2)
	for lx: float in [cx - 34, cx + 34]:
		Ink.line(p, Vector2(lx, ground - 46), Vector2(lx, ground - 120), 5.0, WOOD, 1.0, 0.2)
	var roof := Paint.poly([Vector2(cx - 52, ground - 112), Vector2(cx, ground - 146), Vector2(cx + 52, ground - 112)])
	p.fill_poly(roof, Mat.slate(p, Color("#3a4044"), 0, 0, 10, 7, 0.4))
	Ink.path(p, roof, 2.0)
	Ink.line(p, Vector2(cx, ground - 112), Vector2(cx, ground - 74), 1.4, IRON, 1.0, 0.1)
	crate(p, cx, ground - 64, 14)


static func fence(p: Paint, x0: float, x1: float, ground: float, fh: float = 54.0) -> void:
	var x := x0
	while x < x1:
		Ink.line(p, Vector2(x, ground), Vector2(x, ground - fh - p.rng.randf_range(-4, 4)), 4.0, WOOD.darkened(0.1), 1.0, 0.4)
		x += 18.0
	for yy: float in [ground - fh * 0.75, ground - fh * 0.35]:
		Ink.line(p, Vector2(x0 - 4, yy), Vector2(x1, yy + p.rng.randf_range(-3, 3)), 3.0, WOOD.darkened(0.1), 1.0, 0.8)
