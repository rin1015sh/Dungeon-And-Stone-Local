extends RefCounted
## 날붙이·자루 무기(세로, 손잡이 아래 · 끝 위): 단검·장검·대검·도끼·창·미늘창.
## 생김새는 소재(ctx.style — Style.gd)를 따른다: 날 폭·날끝(tip)·날(edge)·날밑·자루 끝·손잡이·표면 무늬·빛.
## 날 = 주 재질(ctx.m), 자루 = 나무, 칼자루 = Hilt.gd, 무늬 = Surface.gd.

const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Hilt := preload("res://tools/item_art/Hilt.gd")
const Surface := preload("res://tools/item_art/Surface.gd")


static func dagger(ctx: Dictionary) -> void:
	_blade_weapon(ctx, 0.28, 0.12, 0.26, 0.14)


static func sword(ctx: Dictionary) -> void:
	_blade_weapon(ctx, 0.17, 0.1, 0.32, 0.12)


static func greatsword(ctx: Dictionary) -> void:
	_blade_weapon(ctx, 0.2, 0.11, 0.42, 0.17)


## 손잡이 길이 grip, 자루 끝 반지름 pommel, 날밑 반폭 guard, 날 반폭 bw(세로는 t, 가로는 폭 비율).
static func _blade_weapon(ctx: Dictionary, grip: float, pommel: float, guard: float, bw: float) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	bw *= float(st["blade_w"])
	Hilt.grip(ctx, 0.02, grip, 0.065)
	Hilt.pommel(ctx, 0.01, pommel)
	var gt := grip + 0.015
	Hilt.guard(ctx, gt, guard)
	var gb := cl.group()
	var b0 := gt + 0.025
	var blade := blade_poly(ctx, b0, bw)
	cl.slab(gb, blade, 0.03 * W, 0.11 * W, ctx["m"], 1.0, bw * W)  # 가운데 등이 솟은 날 — 한쪽이 그늘
	if str(st["surface"]) != "holes":
		cl.groove(gb, F.P(ctx, b0 + 0.04, 0.0), F.P(ctx, 0.7, 0.0), bw * W * 0.22, 0.02 * W)
	Surface.apply(ctx, gb, blade, st, true)
	_nicks(ctx, gb, b0, bw)
	F.aura(ctx, F.P(ctx, 0.6), W * 0.6)


## 날 윤곽: b0(날밑 위)부터 끝까지, 반폭 bw를 날끝(tip)·날(edge) 모양대로.
static func blade_poly(ctx: Dictionary, b0: float, bw: float) -> PackedVector2Array:
	var st: Dictionary = ctx["style"]
	var tip := str(st["tip"])
	var edge := str(st["edge"])
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := 18
	for k in n + 1:
		var u := float(k) / n
		var t := lerpf(b0, 0.995, u)
		var hw := bw
		match tip:
			"long":
				hw = bw * (1.0 - 0.3 * u) * clampf((1.0 - u) / 0.45, 0.0, 1.0)
			"leaf":
				hw = bw * (0.8 + 0.35 * sin(minf(u / 0.75, 1.0) * PI * 0.85)) * clampf((1.0 - u) / 0.3, 0.0, 1.0)
			"chisel":
				hw = bw * clampf((1.0 - u) / 0.1, 0.0, 1.0)
			_:
				hw = bw * clampf((1.0 - u) / 0.2, 0.0, 1.0)
		var wl := hw
		var wr := hw
		match edge:
			"wavy":
				wl *= 1.0 + 0.14 * sin(u * PI * 8.0)
				wr *= 1.0 + 0.14 * sin(u * PI * 8.0 + PI)
			"serrated":
				if u < 0.7 and k % 2 == 1:
					wr *= 0.72
		if tip == "chisel":
			wl = bw * clampf((1.0 - u) / 0.25, 0.0, 1.0)  # 한쪽만 비스듬히 잘린 끝
		left.append(F.P(ctx, t, -wl))
		right.append(F.P(ctx, t, wr))
	var out := PackedVector2Array()
	for k in right.size():
		out.append(right[k])
	for k in range(left.size() - 1, -1, -1):
		out.append(left[k])
	return out


## 날 이 빠진 자국(edge notched — 1단계 강철·아다만티움).
static func _nicks(ctx: Dictionary, g: int, b0: float, bw: float) -> void:
	if str(ctx["style"]["edge"]) != "notched":
		return
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var rng: RandomNumberGenerator = ctx["rng"]
	for k in 3:
		var t := lerpf(b0 + 0.1, 0.8, rng.randf())
		var side := bw * (1.0 if rng.randf() < 0.5 else -1.0)
		cl.erase(g, F.P(ctx, t, side), 0.035 * W, 0.03 * W, 0.4)


## 도끼날 윤곽(Style.head): t0~t1 높이에서 자루 오른쪽(dir 1)·왼쪽(-1)으로 뻗는다. reach = 날 끝까지의 폭 비율.
static func axe_head(ctx: Dictionary, t0: float, t1: float, reach: float, dir: float) -> PackedVector2Array:
	var st: Dictionary = ctx["style"]
	var w := reach * float(st["blade_w"]) * dir
	var mid := (t0 + t1) * 0.5
	var span := t1 - t0
	var pts: Array = []
	match str(st["head"]):
		"bearded":  # 아래로 길게 늘어진 턱
			pts = [Vector2(t1, 0.0), Vector2(t1 + span * 0.1, w * 0.45), Vector2(t1 + span * 0.15, w), Vector2(mid - span * 0.2, w * 1.05),
				Vector2(t0 - span * 0.55, w * 0.8), Vector2(t0 - span * 0.35, w * 0.35), Vector2(t0, 0.0)]
		"crescent":  # 큰 반달
			pts = [Vector2(t1 - span * 0.1, 0.0)]
			for k in 9:
				var a := -PI * 0.5 + k * PI / 8.0
				pts.append(Vector2(mid + sin(a) * span * 0.95, w * (0.35 + 0.65 * cos(a))))
			pts.append(Vector2(t0 + span * 0.1, 0.0))
		_:
			pts = [Vector2(t1, 0.0), Vector2(t1 + span * 0.25, w * 0.4), Vector2(t1 + span * 0.35, w), Vector2(t0 - span * 0.1, w * 1.05),
				Vector2(t0 + span * 0.05, w * 0.4), Vector2(t0, 0.0)]
	var out := PackedVector2Array()
	for q: Vector2 in pts:
		out.append(F.P(ctx, q.x, q.y))
	return out


static func axe(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, 0.95), 0.055 * W, 0.05 * W, ctx["wood"], 1.0)
	Hilt.grip(ctx, 0.04, 0.2, 0.065)
	var gh := cl.group()
	var heads: Array = [axe_head(ctx, 0.74, 0.9, 0.44, 1.0)]
	if str(st["head"]) == "double":
		heads.append(axe_head(ctx, 0.74, 0.9, 0.44, -1.0))
	else:
		cl.slab(gh, PackedVector2Array([F.P(ctx, 0.84, 0.0), F.P(ctx, 0.83, -0.22), F.P(ctx, 0.79, -0.22), F.P(ctx, 0.78, 0.0)]), 0.04 * W, 0.06 * W, ctx["m"], 1.0, 0.06 * W)
	for head: PackedVector2Array in heads:
		cl.slab(gh, head, 0.04 * W, 0.1 * W, ctx["m"], 1.0, 0.2 * W)
		Surface.apply(ctx, gh, head, st, true)
		_edge_teeth(ctx, gh, head)
	cl.cap(gh, F.V(ctx, 0.72, 0.0, 0.07), F.V(ctx, 0.93, 0.0, 0.07), 0.075 * W, 0.075 * W, Hilt._fit(ctx), 1.0)
	F.aura(ctx, F.P(ctx, 0.82, 0.2), W * 0.5)


## 톱니 날(edge serrated): 날 바깥 끝을 따라 이를 판다.
static func _edge_teeth(ctx: Dictionary, g: int, head: PackedVector2Array) -> void:
	if str(ctx["style"]["edge"]) != "serrated":
		return
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var far := 0.0
	var c := Vector2.ZERO
	for p in head:
		c += p
	c /= head.size()
	for p in head:
		far = maxf(far, p.distance_to(c))
	for p in head:
		if p.distance_to(c) > far * 0.8:
			cl.erase(g, p.lerp(c, 0.05), 0.04 * W, 0.04 * W, 0.2)


static func spear(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, 0.8), 0.05 * W, 0.045 * W, ctx["wood"], 1.0)
	Hilt.grip(ctx, 0.3, 0.42, 0.06)
	var gh := cl.group()
	cl.cap(gh, F.V(ctx, 0.76, 0.0, 0.03), F.V(ctx, 0.83, 0.0, 0.03), 0.075 * W, 0.06 * W, Hilt._fit(ctx), 1.0)
	if str(st["guard"]) in ["wings", "claw", "crescent"]:  # 창날 밑 날개(멈춤쇠)
		for s: float in [-1.0, 1.0]:
			cl.chain(gh, [F.V(ctx, 0.81, 0.0, 0.05), F.V(ctx, 0.8, s * 0.2, 0.05), F.V(ctx, 0.84, s * 0.26, 0.05)], [0.03 * W, 0.022 * W, 0.008 * W], Hilt._fit(ctx), 2.0)
	var head := blade_poly(ctx, 0.82, 0.13)
	cl.slab(gh, head, 0.04 * W, 0.09 * W, ctx["m"], 1.0, 0.16 * W)
	cl.groove(gh, F.P(ctx, 0.85, 0.0), F.P(ctx, 0.95, 0.0), 0.02 * W, 0.015 * W)
	Surface.apply(ctx, gh, head, st, true)
	F.aura(ctx, F.P(ctx, 0.9), W * 0.5)


static func halberd(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var st: Dictionary = ctx["style"]
	var g := cl.group()
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, 0.88), 0.05 * W, 0.045 * W, ctx["wood"], 1.0)
	Hilt.grip(ctx, 0.36, 0.5, 0.06)
	var gh := cl.group()
	cl.cap(gh, F.V(ctx, 0.7, 0.0, 0.03), F.V(ctx, 0.9, 0.0, 0.03), 0.07 * W, 0.06 * W, Hilt._fit(ctx), 1.0)
	var blade := axe_head(ctx, 0.73, 0.87, 0.44, 1.0)
	cl.slab(gh, blade, 0.04 * W, 0.1 * W, ctx["m"], 1.0, 0.2 * W)
	Surface.apply(ctx, gh, blade, st, true)
	_edge_teeth(ctx, gh, blade)
	var hook := PackedVector2Array([F.P(ctx, 0.82, -0.04), F.P(ctx, 0.85, -0.38), F.P(ctx, 0.8, -0.3), F.P(ctx, 0.77, -0.04)])
	cl.slab(gh, hook, 0.04 * W, 0.04 * W, ctx["m"], 1.0, 0.06 * W)
	var tip := blade_poly(ctx, 0.89, 0.06)
	cl.slab(gh, tip, 0.04 * W, 0.04 * W, ctx["m"], 1.0, 0.05 * W)
	F.aura(ctx, F.P(ctx, 0.8, 0.1), W * 0.6)
