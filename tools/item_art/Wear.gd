extends RefCounted
const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
## 방패·갑옷(칸을 채우는 물건 — 두 축 좌표 F.Q(u, v)): 소형 방패·방패·대형 방패, 누비 갑옷·로브·가죽 갑옷·사슬 갑옷·판금 갑옷.
## 방패 = 주 재질 판 + 쇠 테·징, 갑옷 = 주 재질(천·가죽·쇠) 몸판 + 끈·이음매.


static func buckler(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c := F.Q3(ctx, 0.5, 0.5, 0.05)
	var g := cl.group()
	cl.ell(g, c, 0.42 * W, 0.42 * W, 0.14 * W, ctx["m"], 2.0)
	cl.ridge(g, _ring(Vector2(c.x, c.y), 0.38 * W, 28), 0.035 * W, 0.02 * W, ctx["steel"] if str(ctx["kind"]) != "metal" else ctx["accent"])
	cl.bump(g, Vector2(c.x, c.y), 0.13 * W, 0.13 * W, 0.08 * W, ctx["accent"], 1.0)
	F.aura(ctx, Vector2(c.x, c.y), W * 0.5)


static func shield(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var poly := PackedVector2Array()
	for k in 32:  # 위가 평평하고 아래가 뾰족한 연 모양
		var a := TAU * k / 32.0
		var x := 0.5 + cos(a) * 0.42
		var y := 0.4 + sin(a) * (0.32 if sin(a) < 0.0 else 0.55)
		poly.append(F.Q(ctx, x, clampf(y, 0.08, 0.96)))
	cl.slab(g, poly, 0.03 * W, 0.12 * W, ctx["m"], 2.0, 0.3 * W)
	var rim: int = ctx["steel"] if str(ctx["kind"]) != "metal" else ctx["accent"]
	var ring: Array = []
	for q: Vector2 in poly:
		ring.append(F.Q(ctx, 0.5, 0.45) + (q - F.Q(ctx, 0.5, 0.45)) * 0.93)
	ring.append(ring[0])
	cl.ridge(g, ring, 0.03 * W, 0.02 * W, rim)
	if str(ctx["kind"]) == "wood":
		for k in 3:  # 판자 이음
			var x := 0.3 + k * 0.2
			cl.groove(g, F.Q(ctx, x, 0.12), F.Q(ctx, x, 0.85), 0.012 * W, 0.015 * W)
	cl.bump(g, F.Q(ctx, 0.5, 0.42), 0.1 * W, 0.1 * W, 0.07 * W, ctx["accent"], 1.0)
	F.aura(ctx, F.Q(ctx, 0.5, 0.45), W * 0.5)


static func tower(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var poly := F.poly(ctx, [Vector2(0.12, 0.08), Vector2(0.5, 0.04), Vector2(0.88, 0.08), Vector2(0.9, 0.86), Vector2(0.5, 0.97), Vector2(0.1, 0.86)])
	cl.slab(g, poly, 0.03 * W, 0.14 * W, ctx["m"], 2.0, 0.25 * W)
	var rim: int = ctx["steel"] if str(ctx["kind"]) != "metal" else ctx["accent"]
	cl.ridge(g, [F.Q(ctx, 0.5, 0.08), F.Q(ctx, 0.5, 0.93)], 0.03 * W, 0.02 * W, rim)
	cl.ridge(g, [F.Q(ctx, 0.14, 0.45), F.Q(ctx, 0.86, 0.45)], 0.03 * W, 0.02 * W, rim)
	for u: float in [0.2, 0.8]:
		for v: float in [0.14, 0.8]:
			cl.bump(g, F.Q(ctx, u, v), 0.035 * W, 0.035 * W, 0.025 * W, ctx["accent"], 1.0)
	F.aura(ctx, F.Q(ctx, 0.5, 0.45), W * 0.6)


## 몸판 윤곽(어깨·허리·아랫단): 소매 sleeve(0 = 없음), 아랫단 길이 hem.
static func _torso(ctx: Dictionary, sleeve: float, hem: float) -> PackedVector2Array:
	return F.poly(ctx, [Vector2(0.36, 0.06), Vector2(0.5, 0.12), Vector2(0.64, 0.06), Vector2(0.86, 0.14), Vector2(0.86 + sleeve * 0.1, 0.18 + sleeve),
		Vector2(0.74, 0.2 + sleeve * 0.7), Vector2(0.72, 0.5), Vector2(0.76, hem), Vector2(0.24, hem), Vector2(0.28, 0.5),
		Vector2(0.26, 0.2 + sleeve * 0.7), Vector2(0.14 - sleeve * 0.1, 0.18 + sleeve), Vector2(0.14, 0.14)])


static func padded(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.slab(g, _torso(ctx, 0.22, 0.9), 0.03 * W, 0.16 * W, ctx["m"], 2.0, 0.3 * W)
	for k in 6:  # 누빔 골(가로)
		var v := 0.22 + k * 0.11
		cl.groove(g, F.Q(ctx, 0.27, v), F.Q(ctx, 0.73, v), 0.012 * W, 0.022 * W)
	cl.groove(g, F.Q(ctx, 0.5, 0.14), F.Q(ctx, 0.5, 0.88), 0.014 * W, 0.03 * W)
	F.aura(ctx, F.Q(ctx, 0.5, 0.45), W * 0.6)


static func robe(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var poly := F.poly(ctx, [Vector2(0.34, 0.04), Vector2(0.66, 0.04), Vector2(0.9, 0.16), Vector2(0.95, 0.42), Vector2(0.8, 0.44),
		Vector2(0.78, 0.3), Vector2(0.82, 0.96), Vector2(0.18, 0.96), Vector2(0.22, 0.3), Vector2(0.2, 0.44), Vector2(0.05, 0.42), Vector2(0.1, 0.16)])
	cl.slab(g, poly, 0.03 * W, 0.14 * W, ctx["m"], 2.0, 0.28 * W)
	cl.carve(g, F.Q(ctx, 0.5, 0.08), 0.12 * W, 0.06 * W, 0.08 * W)  # 목둘레(두건 자리)
	for k in 4:  # 늘어진 주름
		var u := 0.3 + k * 0.13
		cl.groove(g, F.Q(ctx, u, 0.4), F.Q(ctx, u + 0.03, 0.94), 0.02 * W, 0.04 * W)
	cl.ridge(g, [F.Q(ctx, 0.22, 0.36), F.Q(ctx, 0.78, 0.36)], 0.025 * W, 0.015 * W, ctx["leather"])
	F.aura(ctx, F.Q(ctx, 0.5, 0.45), W * 0.6)


static func leather_armor(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.slab(g, _torso(ctx, 0.0, 0.86), 0.03 * W, 0.16 * W, ctx["m"], 2.0, 0.3 * W)
	for v: float in [0.32, 0.48, 0.64]:  # 가슴판 이음·끈
		cl.groove(g, F.Q(ctx, 0.28, v), F.Q(ctx, 0.72, v), 0.01 * W, 0.02 * W)
	cl.ridge(g, [F.Q(ctx, 0.3, 0.12), F.Q(ctx, 0.7, 0.62)], 0.022 * W, 0.016 * W, ctx["leather"] if str(ctx["kind"]) != "leather" else ctx["dark"])
	cl.bump(g, F.Q(ctx, 0.3, 0.14), 0.035 * W, 0.035 * W, 0.02 * W, ctx["steel"], 1.0)
	cl.ridge(g, [F.Q(ctx, 0.27, 0.74), F.Q(ctx, 0.73, 0.74)], 0.03 * W, 0.02 * W, ctx["leather"] if str(ctx["kind"]) != "leather" else ctx["dark"])
	cl.bump(g, F.Q(ctx, 0.5, 0.74), 0.04 * W, 0.035 * W, 0.025 * W, ctx["accent"], 1.0)
	F.aura(ctx, F.Q(ctx, 0.5, 0.45), W * 0.6)


static func chainmail(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.slab(g, _torso(ctx, 0.2, 0.9), 0.03 * W, 0.14 * W, ctx["m"], 2.0, 0.3 * W)
	var H: float = ctx["H"]
	var step := 0.035 * W
	var y := H * 0.08
	var row := 0
	while y < H * 0.92:  # 고리 무늬(엇갈린 작은 홈)
		var x := W * 0.12 + (step * 0.5 if row % 2 == 1 else 0.0)
		while x < W * 0.9:
			cl.carve(g, Vector2(x, y), step * 0.32, step * 0.22, 0.012 * W)
			x += step
		y += step * 0.7
		row += 1
	cl.ridge(g, [F.Q(ctx, 0.3, 0.1), F.Q(ctx, 0.5, 0.15), F.Q(ctx, 0.7, 0.1)], 0.025 * W, 0.015 * W, ctx["leather"])
	F.aura(ctx, F.Q(ctx, 0.5, 0.45), W * 0.6)


static func plate(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var breast := F.poly(ctx, [Vector2(0.3, 0.1), Vector2(0.5, 0.15), Vector2(0.7, 0.1), Vector2(0.74, 0.3), Vector2(0.7, 0.58), Vector2(0.3, 0.58), Vector2(0.26, 0.3)])
	cl.slab(g, breast, 0.05 * W, 0.2 * W, ctx["m"], 2.0, 0.3 * W)
	cl.ridge(g, [F.Q(ctx, 0.5, 0.16), F.Q(ctx, 0.5, 0.56)], 0.02 * W, 0.02 * W, ctx["m"])
	var gp := cl.group()
	for s: float in [-1.0, 1.0]:  # 어깨받이
		cl.ell(gp, F.Q3(ctx, 0.5 + s * 0.3, 0.16, 0.12), 0.18 * W, 0.11 * W, 0.08 * W, ctx["m"], 2.0, s * 0.3)
		cl.ridge(gp, [F.Q(ctx, 0.5 + s * 0.18, 0.2), F.Q(ctx, 0.5 + s * 0.42, 0.2)], 0.012 * W, 0.012 * W, ctx["accent"])
	var gf := cl.group()
	for k in 3:  # 허리 아래 겹판
		var v := 0.6 + k * 0.11
		var band := F.poly(ctx, [Vector2(0.28 - k * 0.02, v), Vector2(0.72 + k * 0.02, v), Vector2(0.74 + k * 0.02, v + 0.1), Vector2(0.26 - k * 0.02, v + 0.1)])
		cl.slab(gf, band, 0.04 * W - k * 0.01 * W, 0.08 * W, ctx["m"], 2.0, 0.1 * W)
	for u: float in [0.34, 0.66]:
		cl.bump(g, F.Q(ctx, u, 0.5), 0.025 * W, 0.025 * W, 0.015 * W, ctx["accent"], 1.0)
	F.aura(ctx, F.Q(ctx, 0.5, 0.4), W * 0.6)


static func _ring(c: Vector2, r: float, n: int) -> Array:
	var pts: Array = []
	for k in n + 1:
		var a := TAU * k / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts
