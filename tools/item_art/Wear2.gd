extends RefCounted
const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
## 머리·손·발·허리·망토·장신구(두 축 좌표 F.Q): 두건·투구·통투구, 장갑·건틀릿, 장화·쇠 장화, 허리띠, 망토, 반지·목걸이.


static func hood(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var poly := F.poly(ctx, [Vector2(0.5, 0.06), Vector2(0.78, 0.2), Vector2(0.86, 0.6), Vector2(0.94, 0.94), Vector2(0.06, 0.94), Vector2(0.14, 0.6), Vector2(0.22, 0.2)])
	cl.slab(g, poly, 0.03 * W, 0.2 * W, ctx["m"], 2.0, 0.3 * W)
	cl.carve(g, F.Q(ctx, 0.5, 0.52), 0.2 * W, 0.26 * W, 0.18 * W)  # 얼굴 구멍
	cl.groove(g, F.Q(ctx, 0.3, 0.3), F.Q(ctx, 0.22, 0.88), 0.02 * W, 0.03 * W)
	cl.groove(g, F.Q(ctx, 0.7, 0.3), F.Q(ctx, 0.78, 0.88), 0.02 * W, 0.03 * W)


static func helm(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.ell(g, F.Q3(ctx, 0.5, 0.48, 0.05), 0.38 * W, 0.38 * W, 0.22 * W, ctx["m"], 2.0)
	cl.erase(g, F.Q(ctx, 0.5, 0.86), 0.5 * W, 0.2 * W, 0.0)
	cl.ridge(g, [F.Q(ctx, 0.13, 0.62), F.Q(ctx, 0.5, 0.66), F.Q(ctx, 0.87, 0.62)], 0.035 * W, 0.025 * W, ctx["accent"])
	cl.ridge(g, [F.Q(ctx, 0.5, 0.12), F.Q(ctx, 0.5, 0.82)], 0.035 * W, 0.03 * W, ctx["m"])  # 콧대
	F.aura(ctx, F.Q(ctx, 0.5, 0.45), W * 0.5)


static func greathelm(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var poly := F.poly(ctx, [Vector2(0.24, 0.1), Vector2(0.5, 0.05), Vector2(0.76, 0.1), Vector2(0.8, 0.9), Vector2(0.5, 0.95), Vector2(0.2, 0.9)])
	cl.slab(g, poly, 0.03 * W, 0.22 * W, ctx["m"], 2.0, 0.3 * W)
	cl.groove(g, F.Q(ctx, 0.27, 0.4), F.Q(ctx, 0.73, 0.4), 0.03 * W, 0.12 * W)  # 눈 틈
	for k in 5:  # 숨구멍
		cl.carve(g, F.Q(ctx, 0.6 + (k % 2) * 0.06, 0.6 + k * 0.05), 0.012 * W, 0.012 * W, 0.04 * W)
	cl.ridge(g, [F.Q(ctx, 0.5, 0.08), F.Q(ctx, 0.5, 0.36)], 0.03 * W, 0.03 * W, ctx["accent"])
	F.aura(ctx, F.Q(ctx, 0.5, 0.45), W * 0.5)


## 장갑 한 쌍: 손바닥 덩어리 + 손가락 넷 + 엄지 + 손목 단.
static func gloves(ctx: Dictionary) -> void:
	_pair_hands(ctx, ctx["m"], false)


static func gauntlets(ctx: Dictionary) -> void:
	_pair_hands(ctx, ctx["m"], true)


static func _pair_hands(ctx: Dictionary, m: int, plated: bool) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	for side: float in [-1.0, 1.0]:
		var g := cl.group()
		var cx := 0.5 + side * 0.22
		cl.ell(g, F.Q3(ctx, cx, 0.58, 0.05), 0.17 * W, 0.2 * W, 0.08 * W, m, 3.0)
		for f in 4:
			var fx := cx - 0.1 + f * 0.065
			cl.cap(g, F.Q3(ctx, fx, 0.45, 0.07), F.Q3(ctx, fx + side * 0.01, 0.16 + absf(f - 1.5) * 0.04, 0.06), 0.035 * W, 0.028 * W, m, 2.0)
		cl.cap(g, F.Q3(ctx, cx - side * 0.12, 0.6, 0.06), F.Q3(ctx, cx - side * 0.2, 0.44, 0.07), 0.04 * W, 0.03 * W, m, 2.0)
		cl.cap(g, F.Q3(ctx, cx, 0.78, 0.05), F.Q3(ctx, cx, 0.94, 0.05), 0.15 * W, 0.17 * W, ctx["leather"] if not plated else m, 2.0)
		if plated:
			for v: float in [0.5, 0.62, 0.74]:
				cl.groove(g, F.Q(ctx, cx - 0.14, v), F.Q(ctx, cx + 0.14, v), 0.012 * W, 0.02 * W)
	F.aura(ctx, F.Q(ctx, 0.5, 0.5), W * 0.5)


static func boots(ctx: Dictionary) -> void:
	_pair_feet(ctx, false)


static func sabatons(ctx: Dictionary) -> void:
	_pair_feet(ctx, true)


static func _pair_feet(ctx: Dictionary, plated: bool) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m: int = ctx["m"]
	for side: float in [-1.0, 1.0]:
		var g := cl.group()
		var cx := 0.5 + side * 0.2
		cl.cap(g, F.Q3(ctx, cx, 0.08, 0.05), F.Q3(ctx, cx, 0.72, 0.05), 0.13 * W, 0.14 * W, m, 3.0)
		cl.cap(g, F.Q3(ctx, cx, 0.8, 0.06), F.Q3(ctx, cx + side * 0.17, 0.86, 0.07), 0.13 * W, 0.09 * W, m, 3.0)
		cl.ridge(g, [F.Q(ctx, cx - 0.13, 0.15), F.Q(ctx, cx + 0.13, 0.15)], 0.02 * W, 0.015 * W, ctx["dark"] if not plated else ctx["accent"])
		if plated:
			for v: float in [0.32, 0.5, 0.68]:
				cl.groove(g, F.Q(ctx, cx - 0.13, v), F.Q(ctx, cx + 0.13, v), 0.012 * W, 0.02 * W)
		else:
			cl.groove(g, F.Q(ctx, cx, 0.2), F.Q(ctx, cx, 0.6), 0.012 * W, 0.015 * W)
	F.aura(ctx, F.Q(ctx, 0.5, 0.5), W * 0.5)


static func belt(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var band := F.poly(ctx, [Vector2(0.04, 0.3), Vector2(0.96, 0.24), Vector2(0.96, 0.7), Vector2(0.04, 0.76)])
	cl.slab(g, band, 0.03 * W, 0.06 * W, ctx["m"], 2.0, 0.08 * W)
	for k in 4:
		cl.carve(g, F.Q(ctx, 0.66 + k * 0.07, 0.48), 0.012 * W, 0.02 * W, 0.03 * W)
	var gb := cl.group()
	var buckle := F.poly(ctx, [Vector2(0.3, 0.12), Vector2(0.46, 0.12), Vector2(0.46, 0.88), Vector2(0.3, 0.88)])
	cl.slab(gb, buckle, 0.08 * W, 0.04 * W, ctx["accent"], 1.0, 0.03 * W)
	cl.carve(gb, F.Q(ctx, 0.38, 0.5), 0.04 * W, 0.12 * W, 0.06 * W)
	F.aura(ctx, F.Q(ctx, 0.5, 0.5), W * 0.4)


static func cloak(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var poly := F.poly(ctx, [Vector2(0.38, 0.04), Vector2(0.62, 0.04), Vector2(0.8, 0.3), Vector2(0.94, 0.96), Vector2(0.06, 0.96), Vector2(0.2, 0.3)])
	cl.slab(g, poly, 0.03 * W, 0.14 * W, ctx["m"], 2.0, 0.3 * W)
	var rng: RandomNumberGenerator = ctx["rng"]
	for k in 5:  # 늘어진 주름
		var u := 0.24 + k * 0.13 + (rng.randf() - 0.5) * 0.04
		cl.groove(g, F.Q(ctx, 0.5 + (u - 0.5) * 0.4, 0.14), F.Q(ctx, u, 0.94), 0.022 * W, 0.05 * W)
	cl.bump(g, F.Q(ctx, 0.5, 0.09), 0.06 * W, 0.05 * W, 0.04 * W, ctx["accent"], 1.0)
	F.aura(ctx, F.Q(ctx, 0.5, 0.5), W * 0.6)


## 반지: 고리(띠 = 금속) + 위에 보석(보석 소재면 그 색, 금속 소재면 수정).
static func ring(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var c := F.Q(ctx, 0.5, 0.56)
	var band: int = ctx["m"] if str(ctx["kind"]) == "metal" else ctx["accent"]
	var pts: Array = []
	var rs: Array = []
	for k in 25:
		var a := TAU * k / 24.0
		pts.append(Vector3(c.x + cos(a) * 0.28 * W, c.y + sin(a) * 0.24 * W, (0.06 - sin(a) * 0.04) * W))
		rs.append(0.06 * W)
	cl.chain(g, pts, rs, band, 2.0)
	var gem_c: Color = ctx["c"] if str(ctx["kind"]) == "gem" else Color("#d8e4f0")
	var top := F.Q3(ctx, 0.5, 0.3, 0.16)
	cl.ell(cl.group(), top, 0.13 * W, 0.12 * W, 0.1 * W, cl.mat(gem_c, "eye"), 2.0)
	if int(ctx["tier"]) >= 3:
		ctx["glows"].append([Vector2(top.x, top.y), 0.3 * W, gem_c.lightened(0.2), 0.5])


## 목걸이: 줄(잉크 선) + 아래 매단 장식(보석 또는 뼈).
static func amulet(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var H: float = ctx["H"]
	var pend := F.Q3(ctx, 0.5, 0.74, 0.08)
	var cord := Color("#5a4a36")
	var pts: Array[Vector2] = []
	for k in 13:
		var a := PI * k / 12.0
		pts.append(Vector2(W * 0.5 + cos(a) * W * 0.36, H * 0.12 + sin(a) * H * 0.5))
	for k in 12:
		ctx["lines"].append([pts[k], pts[k + 1], maxf(1.2, W / 50.0), cord])
	var g := cl.group()
	if str(ctx["kind"]) == "bone":
		cl.cap(g, Vector3(pend.x, pend.y - 0.14 * W, pend.z), Vector3(pend.x, pend.y + 0.2 * W, pend.z), 0.08 * W, 0.04 * W, ctx["m"], 2.0)
	else:
		var gem_c: Color = ctx["c"]
		cl.ell(g, pend, 0.17 * W, 0.2 * W, 0.12 * W, cl.mat(gem_c, "eye"), 2.0)
		cl.ridge(g, [Vector2(pend.x - 0.18 * W, pend.y - 0.2 * W), Vector2(pend.x + 0.18 * W, pend.y - 0.2 * W)], 0.02 * W, 0.02 * W, ctx["accent"])
		if int(ctx["tier"]) >= 3:
			ctx["glows"].append([Vector2(pend.x, pend.y), 0.4 * W, gem_c.lightened(0.2), 0.5])
