extends RefCounted
## 날붙이·자루 무기(세로, 손잡이 아래 · 끝 위): 단검·장검·대검·도끼·창·미늘창.
## 날 = 주 재질(ctx.m — 소재), 손잡이 = 가죽 감개, 자루 = 나무, 날밑·자루 고리 = 쇠(3단계 이상은 장식 금속), 4단계 이상 자루 끝에 보석.

const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")


static func dagger(ctx: Dictionary) -> void:
	_blade_weapon(ctx, 0.28, 0.12, 0.26, 0.14)


static func sword(ctx: Dictionary) -> void:
	_blade_weapon(ctx, 0.17, 0.1, 0.32, 0.12)


static func greatsword(ctx: Dictionary) -> void:
	_blade_weapon(ctx, 0.2, 0.11, 0.42, 0.17)


## 손잡이 길이 grip, 자루 끝 반지름 pommel, 날밑 반폭 guard, 날 반폭 bw(모두 캔버스 비율 — 세로는 t, 가로는 폭).
static func _blade_weapon(ctx: Dictionary, grip: float, pommel: float, guard: float, bw: float) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.02), F.V(ctx, grip), 0.065 * W, 0.06 * W, ctx["leather"], 1.0)
	for k in 4:  # 감개 줄
		var t := 0.04 + (grip - 0.06) * k / 3.0
		cl.groove(g, F.P(ctx, t, -0.08), F.P(ctx, t + 0.02, 0.08), 0.012 * W, 0.01 * W)
	var gp := cl.group()
	var fit: int = ctx["accent"] if int(ctx["tier"]) >= 3 else ctx["steel"]
	cl.ell(gp, F.V(ctx, 0.01, 0.0, 0.04), pommel * W, pommel * W, pommel * W * 0.8, fit, 1.0)
	if int(ctx["tier"]) >= 4:
		var gem := F.V(ctx, 0.01, 0.0, 0.12)
		cl.ell(gp, gem, pommel * W * 0.45, pommel * W * 0.45, pommel * W * 0.3, cl.mat(Color(ctx["c"]).lightened(0.2), "glow"), 0.5)
		ctx["glows"].append([Vector2(gem.x, gem.y), pommel * W * 1.6, Color(ctx["c"]).lightened(0.3), 0.5])
	var gt := grip + 0.015
	cl.cap(gp, F.V(ctx, gt, -guard, 0.06), F.V(ctx, gt, guard, 0.06), 0.05 * W, 0.05 * W, fit, 1.0)
	cl.ell(gp, F.V(ctx, gt, 0.0, 0.08), 0.07 * W, 0.05 * W, 0.05 * W, fit, 1.0)
	var gb := cl.group()
	var b0 := gt + 0.025
	var blade := PackedVector2Array([F.P(ctx, b0, -bw), F.P(ctx, b0, bw), F.P(ctx, 0.84, bw * 0.92), F.P(ctx, 0.995, 0.0), F.P(ctx, 0.84, -bw * 0.92)])
	cl.slab(gb, blade, 0.03 * W, 0.11 * W, ctx["m"], 1.0, bw * W)  # 가운데 등이 솟은 날 — 한쪽이 그늘
	cl.groove(gb, F.P(ctx, b0 + 0.04, 0.0), F.P(ctx, 0.72, 0.0), bw * W * 0.22, 0.02 * W)
	_nicks(ctx, gb, b0, bw)
	F.aura(ctx, F.P(ctx, 0.6), W * 0.6)


## 날 이 빠진 자국(1단계 소재만 — 싸구려 쇠).
static func _nicks(ctx: Dictionary, g: int, b0: float, bw: float) -> void:
	if int(ctx["tier"]) > 1:
		return
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var rng: RandomNumberGenerator = ctx["rng"]
	for k in 2:
		var t := lerpf(b0 + 0.1, 0.8, rng.randf())
		var side := bw * (1.0 if rng.randf() < 0.5 else -1.0)
		cl.erase(g, F.P(ctx, t, side), 0.03 * W, 0.025 * W, 0.4)


static func axe(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, 0.95), 0.055 * W, 0.05 * W, ctx["wood"], 1.0)
	cl.cap(g, F.V(ctx, 0.04, 0.0, 0.02), F.V(ctx, 0.2, 0.0, 0.02), 0.065 * W, 0.065 * W, ctx["leather"], 1.0)
	var gh := cl.group()
	var head := PackedVector2Array([F.P(ctx, 0.9, 0.0), F.P(ctx, 0.97, 0.18), F.P(ctx, 1.0, 0.42), F.P(ctx, 0.84, 0.46),
		F.P(ctx, 0.68, 0.42), F.P(ctx, 0.71, 0.18), F.P(ctx, 0.77, 0.0), F.P(ctx, 0.8, -0.2), F.P(ctx, 0.86, -0.2)])
	cl.slab(gh, head, 0.04 * W, 0.1 * W, ctx["m"], 1.0, 0.2 * W)
	cl.groove(gh, F.P(ctx, 0.95, 0.36), F.P(ctx, 0.73, 0.36), 0.02 * W, 0.015 * W)
	cl.cap(gh, F.V(ctx, 0.74, 0.0, 0.07), F.V(ctx, 0.93, 0.0, 0.07), 0.075 * W, 0.075 * W, ctx["accent"] if int(ctx["tier"]) >= 3 else ctx["steel"], 1.0)
	F.aura(ctx, F.P(ctx, 0.84, 0.2), W * 0.5)


static func spear(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, 0.8), 0.05 * W, 0.045 * W, ctx["wood"], 1.0)
	cl.cap(g, F.V(ctx, 0.3, 0.0, 0.02), F.V(ctx, 0.42, 0.0, 0.02), 0.06 * W, 0.06 * W, ctx["leather"], 1.0)
	var gh := cl.group()
	cl.cap(gh, F.V(ctx, 0.76, 0.0, 0.03), F.V(ctx, 0.83, 0.0, 0.03), 0.075 * W, 0.06 * W, ctx["accent"] if int(ctx["tier"]) >= 3 else ctx["steel"], 1.0)
	var head := PackedVector2Array([F.P(ctx, 0.82, -0.06), F.P(ctx, 0.88, -0.16), F.P(ctx, 0.995, 0.0), F.P(ctx, 0.88, 0.16), F.P(ctx, 0.82, 0.06)])
	cl.slab(gh, head, 0.04 * W, 0.09 * W, ctx["m"], 1.0, 0.16 * W)
	cl.groove(gh, F.P(ctx, 0.85, 0.0), F.P(ctx, 0.96, 0.0), 0.025 * W, 0.015 * W)
	F.aura(ctx, F.P(ctx, 0.9), W * 0.5)


static func halberd(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, 0.88), 0.05 * W, 0.045 * W, ctx["wood"], 1.0)
	var gh := cl.group()
	var fit: int = ctx["accent"] if int(ctx["tier"]) >= 3 else ctx["steel"]
	cl.cap(gh, F.V(ctx, 0.72, 0.0, 0.03), F.V(ctx, 0.9, 0.0, 0.03), 0.07 * W, 0.06 * W, fit, 1.0)
	var blade := PackedVector2Array([F.P(ctx, 0.88, 0.04), F.P(ctx, 0.92, 0.3), F.P(ctx, 0.85, 0.44), F.P(ctx, 0.74, 0.44), F.P(ctx, 0.7, 0.3), F.P(ctx, 0.74, 0.04)])
	cl.slab(gh, blade, 0.04 * W, 0.1 * W, ctx["m"], 1.0, 0.2 * W)
	var hook := PackedVector2Array([F.P(ctx, 0.82, -0.04), F.P(ctx, 0.84, -0.38), F.P(ctx, 0.8, -0.3), F.P(ctx, 0.77, -0.04)])
	cl.slab(gh, hook, 0.04 * W, 0.04 * W, ctx["m"], 1.0, 0.06 * W)
	var tip := PackedVector2Array([F.P(ctx, 0.89, -0.05), F.P(ctx, 0.995, 0.0), F.P(ctx, 0.89, 0.05)])
	cl.slab(gh, tip, 0.04 * W, 0.04 * W, ctx["m"], 1.0, 0.05 * W)
	F.aura(ctx, F.P(ctx, 0.82, 0.1), W * 0.6)
