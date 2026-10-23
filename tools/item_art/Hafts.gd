extends RefCounted
const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Hilt := preload("res://tools/item_art/Hilt.gd")
const Surface := preload("res://tools/item_art/Surface.gd")
## 둔기·활·지팡이(세로): 철퇴·전투 망치·곤봉·활·석궁·지팡이. 머리·날개 = 주 재질(ctx.m), 자루 = 나무(목재 소재면 그 나무).
## 생김새는 소재(ctx.style): 철퇴·망치 머리(mace — flanged·spiked·block·ornate), 손잡이(Hilt.grip), 표면 무늬·둘레 장식(Surface).


static func mace(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, 0.74), 0.05 * W, 0.05 * W, ctx["wood"] if str(ctx["kind"]) != "bone" else ctx["m"], 1.0)
	Hilt.grip(ctx, 0.03, 0.22, 0.062)
	var gh := cl.group()
	var c := F.V(ctx, 0.84, 0.0, 0.04)
	var m: int = ctx["m"]
	match str(st["mace"]):
		"spiked":  # 가시 철퇴
			cl.ell(gh, c, 0.22 * W, 0.22 * W, 0.18 * W, m, 2.0)
			for k in 9:
				var a := TAU * k / 9.0
				var tip := Vector3(c.x + cos(a) * 0.4 * W, c.y + sin(a) * 0.36 * W, c.z + 0.04 * W)
				cl.cap(gh, Vector3(c.x + cos(a) * 0.15 * W, c.y + sin(a) * 0.15 * W, c.z + 0.08 * W), tip, 0.05 * W, 0.006 * W, m, 1.0)
		"block":  # 각진 쇳덩이
			var r := 0.24 * W
			cl.slab(gh, PackedVector2Array([Vector2(c.x - r, c.y - r * 0.9), Vector2(c.x + r, c.y - r * 0.9), Vector2(c.x + r, c.y + r * 0.9), Vector2(c.x - r, c.y + r * 0.9)]),
				c.z, 0.16 * W, m, 1.0, 0.1 * W)
			for s: float in [-1.0, 1.0]:
				for v: float in [-1.0, 1.0]:
					cl.bump(gh, Vector2(c.x + s * r * 0.6, c.y + v * r * 0.55), 0.05 * W, 0.05 * W, 0.05 * W, ctx["steel"], 1.0)
		"ornate":  # 금테 두른 머리 + 위 보석
			cl.ell(gh, c, 0.2 * W, 0.22 * W, 0.16 * W, m, 2.0)
			for k in 6:
				var a := TAU * k / 6.0 + 0.3
				cl.chain(gh, [Vector3(c.x, c.y, c.z + 0.04 * W), Vector3(c.x + cos(a) * 0.26 * W, c.y + sin(a) * 0.24 * W, c.z + 0.04 * W),
					Vector3(c.x + cos(a + 0.3) * 0.3 * W, c.y + sin(a + 0.3) * 0.28 * W, c.z + 0.03 * W)], [0.06 * W, 0.04 * W, 0.015 * W], m, 2.0)
			cl.ridge(gh, [Vector2(c.x - 0.2 * W, c.y + 0.06 * W), Vector2(c.x + 0.2 * W, c.y + 0.06 * W)], 0.03 * W, 0.03 * W, ctx["accent"])
			Hilt._gem(ctx, gh, Vector3(c.x, c.y - 0.2 * W, c.z + 0.1 * W), 0.07 * W)
		_:  # 날개 철퇴
			cl.ell(gh, c, 0.2 * W, 0.2 * W, 0.16 * W, m, 2.0)
			for k in 6:
				var a := TAU * k / 6.0 + 0.3
				var tip := Vector3(c.x + cos(a) * 0.33 * W, c.y + sin(a) * 0.3 * W, c.z + 0.02 * W)
				cl.cap(gh, Vector3(c.x, c.y, c.z + 0.04 * W), tip, 0.07 * W, 0.025 * W, m, 2.0)
	cl.ell(gh, Vector3(c.x, c.y, c.z + 0.12 * W), 0.08 * W, 0.08 * W, 0.06 * W, Hilt._fit(ctx), 1.0)
	Surface.apply(ctx, gh, Surface.circle(Vector2(c.x, c.y), 0.2 * W, 0.2 * W), st)
	F.aura(ctx, Vector2(c.x, c.y), W * 0.6)


static func warhammer(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, 0.9), 0.05 * W, 0.048 * W, ctx["wood"], 1.0)
	Hilt.grip(ctx, 0.03, 0.2, 0.062)
	var gh := cl.group()
	var kind := str(st["mace"])
	var bw := float(st["blade_w"])
	var half := 0.07 * (1.4 if kind == "block" else 1.0) * bw
	var head := PackedVector2Array([F.P(ctx, 0.865 + half, -0.42), F.P(ctx, 0.865 + half, 0.24), F.P(ctx, 0.865 - half, 0.24), F.P(ctx, 0.865 - half, -0.42)])
	cl.slab(gh, head, 0.05 * W, 0.16 * W, ctx["m"], 1.0, 0.14 * W)
	var reach := 0.62 if kind == "spiked" else 0.47
	var spike := PackedVector2Array([F.P(ctx, 0.9, 0.24), F.P(ctx, 0.865, reach), F.P(ctx, 0.83, 0.24)])
	if kind == "spiked":  # 독수리 부리처럼 휜 뒤쪽 날
		spike = PackedVector2Array([F.P(ctx, 0.9, 0.24), F.P(ctx, 0.84, 0.48), F.P(ctx, 0.76, reach), F.P(ctx, 0.83, 0.24)])
	cl.slab(gh, spike, 0.06 * W, 0.04 * W, ctx["m"], 1.0, 0.05 * W)
	if kind == "ornate":
		for v: float in [-0.3, -0.05]:
			cl.ridge(gh, [F.P(ctx, 0.865 - half, v), F.P(ctx, 0.865 + half, v)], 0.03 * W, 0.03 * W, ctx["accent"])
	for s: float in [-0.4, -0.25]:  # 망치 얼굴의 쐐기 무늬
		cl.groove(gh, F.P(ctx, 0.865 - half * 0.8, s), F.P(ctx, 0.865 + half * 0.8, s), 0.012 * W, 0.02 * W)
	cl.cap(gh, F.V(ctx, 0.78, 0.0, 0.09), F.V(ctx, 0.95, 0.0, 0.09), 0.06 * W, 0.06 * W, Hilt._fit(ctx), 1.0)
	Surface.apply(ctx, gh, head, st)
	F.aura(ctx, F.P(ctx, 0.86), W * 0.6)


static func club(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var g := cl.group()
	var m: int = ctx["m"]
	var pts := [F.V(ctx, 0.0), F.V(ctx, 0.4, 0.02), F.V(ctx, 0.75, -0.02), F.V(ctx, 0.97, 0.0)]
	var rs := [0.05 * W, 0.08 * W, 0.15 * W, 0.17 * W]
	cl.chain(g, pts, rs, m, 4.0)
	for k in 5:  # 옹이·마디
		var t := 0.45 + k * 0.1 + rng.randf() * 0.04
		cl.bump(g, F.P(ctx, t, (rng.randf() - 0.5) * 0.18), 0.05 * W, 0.04 * W, 0.03 * W, m, 2.0)
	Surface.apply(ctx, g, F.tube(pts.slice(1), rs.slice(1)), ctx["style"])
	Hilt.grip(ctx, 0.02, 0.2, 0.062)
	F.aura(ctx, F.P(ctx, 0.8), W * 0.6)


static func staff(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var m: int = ctx["m"]
	var pts := [F.V(ctx, 0.0), F.V(ctx, 0.3, 0.03), F.V(ctx, 0.6, -0.03), F.V(ctx, 0.86, 0.0)]
	var rs := [0.045 * W, 0.05 * W, 0.05 * W, 0.06 * W]
	cl.chain(g, pts, rs, m, 3.0)
	Surface.apply(ctx, g, F.tube(pts, rs), ctx["style"])
	for side: float in [-1.0, 1.0]:  # 구슬을 쥔 갈퀴
		cl.chain(g, [F.V(ctx, 0.85, 0.0), F.V(ctx, 0.9, side * 0.16), F.V(ctx, 0.99, side * 0.08)], [0.04 * W, 0.035 * W, 0.015 * W], m, 2.0)
	var orb := F.V(ctx, 0.93, 0.0, 0.05)
	var glow_c := Color.from_string(str(ctx["style"]["glow"]), Color(ctx["c"]).lightened(0.35) if int(ctx["tier"]) >= 2 else Color("#9ab8e8"))
	cl.ell(cl.group(), orb, 0.13 * W, 0.13 * W, 0.12 * W, cl.mat(glow_c, "glow"), 1.0)
	ctx["glows"].append([Vector2(orb.x, orb.y), 0.5 * W, glow_c, 0.7])
	Hilt.grip(ctx, 0.36, 0.5, 0.06)


## 활(2×3): 가운데 손잡이, 위아래로 휜 활대, 시위(잉크 줄).
static func bow(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var H: float = ctx["H"]
	var g := cl.group()
	var pts: Array = []
	var rs: Array = []
	for k in 13:
		var t := k / 12.0
		pts.append(Vector3(W * (0.3 + 0.32 * sin(t * PI)), H * (0.05 + 0.9 * t), 0.02 * W))
		rs.append((0.035 - absf(t - 0.5) * 0.04) * W + 0.008 * W)
	cl.chain(g, pts, rs, ctx["m"], 2.0)
	Surface.apply(ctx, g, F.tube(pts, rs), ctx["style"])
	cl.cap(cl.group(), Vector3(W * 0.62, H * 0.42, 0.05 * W), Vector3(W * 0.62, H * 0.58, 0.05 * W), 0.05 * W, 0.05 * W, ctx["leather"], 1.0)
	var a: Vector3 = pts[0]
	var b: Vector3 = pts[12]
	ctx["lines"].append([Vector2(a.x, a.y), Vector2(b.x, b.y), maxf(1.2, W / 90.0), Color("#c8bea0")])
	F.aura(ctx, Vector2(W * 0.5, H * 0.5), W * 0.5)


## 석궁(2×3): 세로 개머리 + 위쪽 가로 활대 + 시위 + 방아쇠.
static func crossbow(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var H: float = ctx["H"]
	var g := cl.group()
	var stock: int = ctx["wood"] if str(ctx["kind"]) != "wood" else ctx["m"]
	var stock_poly := PackedVector2Array([Vector2(W * 0.44, H * 0.12), Vector2(W * 0.56, H * 0.12), Vector2(W * 0.58, H * 0.7),
		Vector2(W * 0.64, H * 0.95), Vector2(W * 0.38, H * 0.95), Vector2(W * 0.43, H * 0.7)])
	cl.slab(g, stock_poly, 0.02 * W, 0.06 * W, stock, 1.0, 0.08 * W)
	cl.groove(g, Vector2(W * 0.5, H * 0.14), Vector2(W * 0.5, H * 0.55), 0.02 * W, 0.02 * W)
	Surface.apply(ctx, g, stock_poly, ctx["style"])
	var gl := cl.group()
	var limb: Array = []
	var rs: Array = []
	for k in 11:
		var t := k / 10.0
		limb.append(Vector3(W * (0.06 + 0.88 * t), H * (0.3 - 0.1 * sin(t * PI)), 0.07 * W))
		rs.append((0.03 - absf(t - 0.5) * 0.025) * W + 0.006 * W)
	cl.chain(gl, limb, rs, ctx["steel"] if str(ctx["kind"]) == "wood" else ctx["m"], 2.0)
	cl.ell(gl, Vector3(W * 0.5, H * 0.22, 0.1 * W), 0.08 * W, 0.05 * W, 0.04 * W, ctx["accent"], 1.0)
	cl.cap(gl, Vector3(W * 0.5, H * 0.62, 0.06 * W), Vector3(W * 0.48, H * 0.7, 0.06 * W), 0.02 * W, 0.015 * W, ctx["steel"], 1.0)
	var a: Vector3 = limb[0]
	var b: Vector3 = limb[10]
	ctx["lines"].append([Vector2(a.x, a.y), Vector2(W * 0.5, H * 0.42), maxf(1.2, W / 90.0), Color("#c8bea0")])
	ctx["lines"].append([Vector2(W * 0.5, H * 0.42), Vector2(b.x, b.y), maxf(1.2, W / 90.0), Color("#c8bea0")])
	F.aura(ctx, Vector2(W * 0.5, H * 0.4), W * 0.5)
