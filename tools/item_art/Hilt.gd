extends RefCounted
## 칼자루(Style.grip · guard · pommel): 손잡이 감개 · 날밑 · 자루 끝을 소재마다 다르게.
## 날밑·자루 끝 재질 = 날과 같은 소재(1단계는 쇠), 소용돌이·보석 장식은 장식 금속(금빛).

const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")


## 손잡이: t0~t1, 반지름 r(폭 비율).
static func grip(ctx: Dictionary, t0: float, t1: float, r: float) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	var g := cl.group()
	var gc := str(st["grip_c"])
	var kind := str(st["grip"])
	var m: int = ctx["leather"]
	match kind:
		"cloth":
			m = cl.mat(Color.from_string(gc, Color("#cfc8b8")).darkened(0.15), "cloth")
		"wire":
			m = ctx["m"] if str(ctx["kind"]) == "metal" else ctx["steel"]
		"scale":
			m = cl.mat(Color.from_string(gc, Color("#3a3a40")), "leather", {"spec": 0.4})
		"bone":
			m = ctx["bone"] if str(ctx["kind"]) != "bone" else ctx["m"]
		"dark":
			m = cl.mat(Color("#1e1814"), "leather")
	cl.cap(g, F.V(ctx, t0), F.V(ctx, t1), r * W, r * W * 0.92, m, 1.0)
	var len := t1 - t0
	match kind:
		"leather", "dark":
			for k in 4:  # 비스듬히 감은 가죽
				var t := t0 + 0.02 + (len - 0.05) * k / 3.0
				cl.groove(g, F.P(ctx, t, -r * 1.2), F.P(ctx, t + 0.02, r * 1.2), 0.012 * W, 0.01 * W)
		"cloth":
			for k in 6:  # 엇갈려 감은 천
				var t := t0 + 0.01 + len * k / 6.0
				var sgn := 1.0 if k % 2 == 0 else -1.0
				cl.groove(g, F.P(ctx, t, -r * sgn * 1.2), F.P(ctx, t + len / 6.0, r * sgn * 1.2), 0.01 * W, 0.012 * W)
		"wire":
			var n := int(len * float(ctx["H"]) / maxf(2.5, W * 0.035))
			for k in n:  # 촘촘히 감은 쇠줄
				var t := t0 + len * (k + 0.5) / n
				cl.groove(g, F.P(ctx, t, -r * 1.2), F.P(ctx, t, r * 1.2), 0.006 * W, 0.008 * W)
		"scale":
			for k in 5:
				var t := t0 + len * (k + 0.5) / 5.0
				for s: float in [-0.5, 0.5]:
					cl.bump(g, F.P(ctx, t, s * r), r * W * 0.5, r * W * 0.4, r * W * 0.2, m, 2.0)
		"bone":
			for k in 3:
				var t := t0 + len * (k + 0.5) / 3.0
				cl.ridge(g, [F.P(ctx, t, -r * 1.1), F.P(ctx, t, r * 1.1)], 0.018 * W, 0.015 * W, m)


## 날밑: 높이 t, 반폭 half.
static func guard(ctx: Dictionary, t: float, half: float) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	var g := cl.group()
	var fit := _fit(ctx)
	match str(st["guard"]):
		"slim":
			cl.cap(g, F.V(ctx, t, -half * 0.7, 0.06), F.V(ctx, t, half * 0.7, 0.06), 0.028 * W, 0.028 * W, fit, 1.0)
		"crescent":  # 끝이 날 쪽으로 휜 초승달
			var pts: Array = []
			var rs: Array = []
			for k in 9:
				var u := (k / 8.0) * 2.0 - 1.0
				pts.append(F.V(ctx, t + u * u * 0.06, u * half * 1.05, 0.06))
				rs.append((0.05 - absf(u) * 0.035) * W)
			cl.chain(g, pts, rs, fit, 2.0)
		"block":
			cl.slab(g, PackedVector2Array([F.P(ctx, t - 0.025, -half * 0.8), F.P(ctx, t - 0.025, half * 0.8), F.P(ctx, t + 0.03, half * 0.8), F.P(ctx, t + 0.03, -half * 0.8)]),
				0.05 * W, 0.08 * W, fit, 1.0, 0.06 * W)
		"ornate":
			var gold: int = ctx["accent"]
			cl.cap(g, F.V(ctx, t, -half, 0.06), F.V(ctx, t, half, 0.06), 0.04 * W, 0.04 * W, gold, 1.0)
			for s: float in [-1.0, 1.0]:  # 끝을 말아 올린 소용돌이
				var c := F.V(ctx, t + 0.025, s * half, 0.07)
				var curl: Array = []
				for k in 7:
					var a := k * 0.9
					curl.append(Vector3(c.x + s * cos(a) * 0.06 * W, c.y - sin(a) * 0.06 * W, c.z))
				cl.chain(g, curl, [0.03 * W, 0.028 * W, 0.025 * W, 0.022 * W, 0.02 * W, 0.017 * W, 0.014 * W], gold, 1.0)
			_gem(ctx, g, F.V(ctx, t, 0.0, 0.12), 0.07 * W)
		"claw":  # 날 밑동을 움켜쥔 발톱 셋
			for s: float in [-1.0, 0.0, 1.0]:
				cl.chain(g, [F.V(ctx, t - 0.01, s * half * 0.6, 0.06), F.V(ctx, t + 0.03, s * half * 0.75, 0.08), F.V(ctx, t + 0.075, s * half * 0.35, 0.09)],
					[0.045 * W, 0.035 * W, 0.012 * W], fit, 2.0)
		"wings":  # 뒤(손잡이 쪽)로 젖힌 날개
			for s: float in [-1.0, 1.0]:
				cl.chain(g, [F.V(ctx, t, 0.0, 0.06), F.V(ctx, t - 0.015, s * half * 0.6, 0.06), F.V(ctx, t - 0.06, s * half * 1.05, 0.06)],
					[0.05 * W, 0.035 * W, 0.01 * W], fit, 2.0)
		_:
			cl.cap(g, F.V(ctx, t, -half, 0.06), F.V(ctx, t, half, 0.06), 0.05 * W, 0.05 * W, fit, 1.0)
	cl.ell(g, F.V(ctx, t, 0.0, 0.08), 0.07 * W, 0.05 * W, 0.05 * W, fit, 1.0)


## 자루 끝: 높이 t, 크기 r(폭 비율).
static func pommel(ctx: Dictionary, t: float, r: float) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	var g := cl.group()
	var fit := _fit(ctx)
	var c := F.V(ctx, t, 0.0, 0.04)
	match str(st["pommel"]):
		"disc":
			cl.ell(g, c, r * W * 1.35, r * W * 0.6, r * W * 0.5, fit, 1.0)
		"crescent":
			for s: float in [-1.0, 1.0]:
				cl.chain(g, [c, Vector3(c.x + s * r * W, c.y + r * W * 0.2, c.z), Vector3(c.x + s * r * W * 1.4, c.y - r * W * 0.7, c.z)],
					[r * W * 0.7, r * W * 0.45, r * W * 0.1], fit, 2.0)
		"block":
			cl.slab(g, PackedVector2Array([Vector2(c.x - r * W, c.y - r * W * 0.8), Vector2(c.x + r * W, c.y - r * W * 0.8),
				Vector2(c.x + r * W, c.y + r * W * 0.8), Vector2(c.x - r * W, c.y + r * W * 0.8)]), c.z, r * W * 0.6, fit, 1.0, r * W * 0.5)
		"gem":
			cl.ell(g, c, r * W, r * W, r * W * 0.8, ctx["accent"], 1.0)
			_gem(ctx, g, Vector3(c.x, c.y, c.z + r * W * 0.6), r * W * 0.55)
		"claw":
			_gem(ctx, g, c, r * W * 0.8)
			for s: float in [-1.0, 0.0, 1.0]:
				cl.cap(g, Vector3(c.x + s * r * W * 0.8, c.y - r * W * 0.9, c.z), Vector3(c.x + s * r * W * 0.5, c.y + r * W * 0.5, c.z + r * W * 0.5), r * W * 0.3, r * W * 0.1, fit, 1.0)
		"ring":
			var pts: Array = []
			var rs: Array = []
			for k in 13:
				var a := TAU * k / 12.0
				pts.append(Vector3(c.x + cos(a) * r * W * 0.9, c.y + sin(a) * r * W * 0.9, c.z))
				rs.append(r * W * 0.32)
			cl.chain(g, pts, rs, fit, 1.0)
		_:
			cl.ell(g, c, r * W, r * W, r * W * 0.8, fit, 1.0)


## 날밑·자루 끝 재질: 1단계는 쇠, 그 위는 날과 같은 소재(금속이 아니면 쇠).
static func _fit(ctx: Dictionary) -> int:
	if int(ctx["tier"]) <= 1 or str(ctx["kind"]) != "metal":
		return ctx["steel"]
	return ctx["m"]


## 빛나는 보석(소재 빛 색, 없으면 소재 색).
static func _gem(ctx: Dictionary, g: int, at: Vector3, r: float) -> void:
	var cl: Clay = ctx["cl"]
	var st: Dictionary = ctx["style"]
	var col := Color.from_string(str(st["glow"]), Color(ctx["c"]).lightened(0.3))
	cl.ell(g, at, r, r, r * 0.7, cl.mat(col, "glow"), 0.5)
	ctx["glows"].append([Vector2(at.x, at.y), r * 3.0, col, 0.5])
