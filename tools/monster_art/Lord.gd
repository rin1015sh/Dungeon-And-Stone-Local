extends RefCounted
## 계층군주 드레드피어(사용자 첨부 참고 2026-10-16 — "소환되면 끝장이다" 싶은 위압감): 화면을 꽉 채우는 거대한 상반신,
## 목을 두른 굵은 털 고리, 그 위 창백한 눈가린 얼굴과 솟아오른 뿔, 털 고리에서 돋아난 까마귀 머리들,
## 가슴·배에 박힌 이빨 드러낸 얼굴, 등 뒤로 펼친 붉은 박쥐 날개, 바닥까지 늘어진 굵은 팔 — 아래는 검은 연기로 사라진다.
## 오른손에 구더기가 들끓는 뼈 대검(사용자 결정 2026-10-21 "전투 화면에서도 드레드피어는 검 쓰는 걸로") — 연기 속 손에서 날개 앞으로 비스듬히 솟는다.
## spec 키: height · color(살) · shade(그늘) · wing(날개 막) · fur(털) · horn · eyes(빛나는 눈) · birds(까마귀 머리 수)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Face := preload("res://tools/monster_art/Face.gd")
const Fur := preload("res://tools/monster_art/Fur.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")


static func paint(sp: Dictionary, seed_value: int) -> Paint:
	var U := float(sp.get("height", 640))
	var W := U * 1.5  # 몸 기준 폭(날개는 이 바깥으로 더 뻗는다)
	var top := U * 0.24  # 뿔·날개 끝이 들어갈 위 여백
	var hb := U * 1.05  # 몸 기준 높이
	var cw := int(U * 2.1)
	var p := Paint.new(cw, int(top + hb), seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(cw, int(top + hb))
	var cx := cw * 0.5
	var h := hb
	var skin_c: Color = sp.get("color", Color("#d6a45e"))
	var skin := cl.mat(skin_c, "skin", {"shade": sp.get("shade", Color("#661646")), "mottle": Color("#7a2a3a"), "mottle_amt": 0.5})
	var bone := cl.mat(sp.get("horn", Color("#cdb892")), "bone")
	var dark := cl.mat(Color("#160807"), "glow")
	var glow_c: Color = sp.get("eyes", Color("#f4d27a"))
	var eye := cl.mat(glow_c, "glow")
	var mats := {"skin": skin, "bone": bone, "dark": dark, "eye": cl.mat(Color("#d8c8b0"), "eye"), "nail": cl.mat(Color("#2a1a18"), "bone")}
	var Y := func(t: float) -> float: return top + hb * t
	var X := func(t: float) -> float: return cx + W * t
	_wings(cl, X, Y, U, sp, rng)
	_greatsword(cl, X, Y, U, sp, rng)
	# 팔(어깨에서 바닥까지 늘어진 굵은 팔)
	for s: float in [-1.0, 1.0]:
		var g := cl.group()
		var sh := Vector3(X.call(s * 0.29), Y.call(0.47), -0.02 * U)
		var el := Vector3(X.call(s * 0.36), Y.call(0.68), 0.02 * U)
		var wr := Vector3(X.call(s * 0.345), Y.call(0.93), 0.07 * U)
		cl.chain(g, [sh, el, wr], [0.125 * U, 0.1 * U, 0.08 * U], skin, 0.04 * U)
		cl.bump(g, Vector2(sh.lerp(el, 0.5).x - s * 0.01 * U, sh.lerp(el, 0.5).y), 0.1 * U, 0.12 * U, 0.03 * U, skin, 0.03 * U)
		cl.bump(g, Vector2(el.lerp(wr, 0.3).x + s * 0.02 * U, el.lerp(wr, 0.3).y), 0.075 * U, 0.1 * U, 0.025 * U, skin, 0.03 * U)
		for f in 4:  # 바닥을 긁는 갈고리 손가락
			var b := wr + Vector3(s * (f - 1.5) * 0.03 * U, 0.03 * U, 0.03 * U)
			var t := b + Vector3(s * (f - 1.5) * 0.025 * U, 0.09 * U, 0.04 * U)
			cl.chain(g, [b, b.lerp(t, 0.55) + Vector3(0, 0, 0.02 * U), t], [0.022 * U, 0.018 * U, 0.008 * U], skin, 0.01 * U)
		for k in 3:  # 핏줄
			var a := sh.lerp(el, 0.2 + k * 0.25)
			cl.ridge(g, [Vector2(a.x, a.y), Vector2(a.x + s * 0.015 * U, a.y + 0.06 * U), Vector2(a.x - s * 0.01 * U, a.y + 0.12 * U)], 0.007 * U, 0.006 * U, skin)
	# 몸통(한 덩어리)
	var tg := cl.group()
	cl.tag = "torso"
	cl.cap(tg, Vector3(cx, Y.call(0.6), 0.0), Vector3(cx, Y.call(0.98), 0.02 * U), W * 0.25, W * 0.22, skin, 0.06 * U, 0.75)
	for s: float in [-1.0, 1.0]:
		cl.ell(tg, Vector3(X.call(s * 0.27), Y.call(0.46), -0.02 * U), 0.14 * U, 0.13 * U, 0.12 * U, skin, 0.06 * U)
		cl.cap(tg, Vector3(cx, Y.call(0.4), -0.06 * U), Vector3(X.call(s * 0.25), Y.call(0.44), -0.04 * U), 0.1 * U, 0.09 * U, skin, 0.05 * U)
	cl.tag = ""
	for s: float in [-1.0, 1.0]:
		cl.bump(tg, Vector2(X.call(s * 0.1), Y.call(0.58)), W * 0.1, h * 0.07, 0.03 * U, skin, 0.03 * U, s * 0.2)  # 가슴
		for row in 2:  # 복근
			cl.bump(tg, Vector2(X.call(s * 0.035), Y.call(0.86 + row * 0.06)), W * 0.03, h * 0.03, 0.015 * U, skin, 0.01 * U)
		for k in 4:  # 옆구리 갈비
			var yy: float = Y.call(0.55 + k * 0.05)
			cl.groove(tg, Vector2(X.call(s * 0.13), yy), Vector2(X.call(s * 0.21), yy + 0.03 * U), 0.008 * U, 0.01 * U)
	var face := _belly_face(cl, tg, cx, Y, W, U, skin, bone, dark, eye)
	_collar(cl, X, Y, W, U, sp, rng)
	var birds := _birds(cl, X, Y, U, int(sp.get("birds", 7)), eye)
	var hf := _head(cl, cx, Y, W, U, skin, bone, mats, rng)
	Render.render(cl, p, U)
	Fur.comb(cl, p, U, 1.3)
	for e: Vector2 in face + birds:
		Ink.glow(p, e.x, e.y, 0.03 * U, glow_c, 0.9, false)
	_blindfold_shadow(p, hf, U)
	_smoke(p, Y.call(0.66), U, rng)
	Finish.done(p, {"blood": 0.5, "grime": 0.25, "desat": 0.0}, {"chest": Vector3(cx, Y.call(0.5), 0), "waist": Vector3(cx, Y.call(0.72), 0), "shoulder_l": Vector3(X.call(-0.27), Y.call(0.4), 0), "shoulder_r": Vector3(X.call(0.27), Y.call(0.4), 0)}, U)
	return p


## 뼈 대검: 오른손(연기 속)에서 위·바깥으로 비스듬히 솟는 넓고 긴 뼈 날 — 등뼈 같은 마디 골, 이 빠진 날, 날에 붙은 구더기, 뼈 코등이·자루.
static func _greatsword(cl: Clay, X: Callable, Y: Callable, U: float, sp: Dictionary, rng: RandomNumberGenerator) -> void:
	var g := cl.group()
	var bone := cl.mat(sp.get("blade", Color("#c9bc9c")), "bone")
	var rot := cl.mat(Color("#6a5a48"), "bone")
	var grub := cl.mat(Color("#e6dcc0"), "skin", {"shade": Color("#8a7a5a")})
	var z := 0.13 * U
	var grip := Vector2(X.call(0.35), Y.call(0.86))
	var u := Vector2(0.3, -1.0).normalized()  # 날 방향(위·바깥)
	var n := Vector2(-u.y, u.x)  # 날 폭 방향
	var L := 1.02 * U
	var w0 := 0.085 * U
	var P := func(along: float, side: float) -> Vector2: return grip + u * along * L + n * side * w0
	# 자루·코등이(뼈 마디)
	cl.cap(g, Vector3(grip.x, grip.y, z) - Vector3(u.x, u.y, 0) * 0.12 * U, Vector3(grip.x, grip.y, z) + Vector3(u.x, u.y, 0) * 0.05 * U, 0.024 * U, 0.02 * U, rot, 0.01 * U)
	var gp: Vector2 = P.call(0.07, 0.0)
	cl.cap(g, Vector3(gp.x, gp.y, z) - Vector3(n.x, n.y, 0) * 0.12 * U, Vector3(gp.x, gp.y, z) + Vector3(n.x, n.y, 0) * 0.12 * U, 0.03 * U, 0.022 * U, bone, 0.01 * U)
	# 날: 밑동이 넓고 끝으로 갈수록 좁아지다 비스듬히 꺾인 끝
	var blade := PackedVector2Array([P.call(0.09, -1.0), P.call(0.09, 1.0), P.call(0.5, 1.05), P.call(0.86, 0.7), P.call(1.0, -0.15), P.call(0.9, -0.85), P.call(0.5, -1.0)])
	cl.slab(g, blade, z, 0.02 * U, bone, 1.6, 0.03 * U)
	for k in 9:  # 등뼈 같은 마디 골
		var t := 0.14 + k * 0.085
		cl.groove(g, P.call(t, -0.55), P.call(t + 0.02, 0.55), 0.006 * U, 0.006 * U)
	cl.ridge(g, [P.call(0.1, 0.0), P.call(0.5, 0.05), P.call(0.88, -0.05)], 0.008 * U, 0.008 * U, bone)
	for k in 6:  # 이 빠진 날
		var t := 0.2 + k * 0.12 + rng.randf() * 0.04
		var side := 1.0 if k % 2 == 0 else -1.0
		cl.erase(g, P.call(t, side * 1.02), rng.randf_range(0.012, 0.022) * U, rng.randf_range(0.018, 0.03) * U, 0.5)
	for k in 12:  # 날에 붙은 구더기
		var q: Vector2 = P.call(rng.randf_range(0.15, 0.8), rng.randf_range(-0.6, 0.6))
		cl.bump(g, q, 0.018 * U, 0.01 * U, 0.01 * U, grub, 0.005 * U, rng.randf_range(-1.0, 1.0))
	for k in 4:  # 썩은 얼룩
		var q: Vector2 = P.call(rng.randf_range(0.1, 0.7), rng.randf_range(-0.7, 0.7))
		cl.bump(g, q, rng.randf_range(0.02, 0.035) * U, rng.randf_range(0.012, 0.02) * U, 0.002 * U, rot, 0.01 * U)


## 등 뒤 박쥐 날개: 어깨 뒤에서 머리 위로 솟은 팔뼈 → 바깥 손목(엄지 갈고리) → 아래로 부채처럼 펼친 손가락뼈 넷.
## 막은 뼈 사이 칸마다 따로 부풀고(뼈 자리에 골이 진다), 손가락 끝 사이 가장자리는 손목 쪽으로 깊게 오목하다. 군데군데 찢어진 구멍.
static func _wings(cl: Clay, X: Callable, Y: Callable, U: float, sp: Dictionary, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(sp.get("wing", Color("#7e2a3e")), "leather", {"hatch": 0.9, "shade": Color("#2a0a18"), "mottle": Color("#c8703a"), "mottle_amt": 0.45})
	var bm := cl.mat(Color("#4a2a2a"), "bone")
	var claw := cl.mat(Color("#d8c8a8"), "bone")
	var z := -0.34 * U
	for s: float in [-1.0, 1.0]:
		var g := cl.group()
		var P := func(tx: float, ty: float) -> Vector3: return Vector3(X.call(s * tx), Y.call(ty), z)
		var root: Vector3 = P.call(0.16, 0.36)
		var el: Vector3 = P.call(0.36, 0.03)
		var wr: Vector3 = P.call(0.5, -0.08)
		var tips := [P.call(0.66, 0.22), P.call(0.64, 0.5), P.call(0.53, 0.72), P.call(0.37, 0.76)]
		var body: Vector3 = P.call(0.2, 0.6)
		var scallop := func(a: Vector3, b: Vector3, pull: float) -> PackedVector2Array:
			var ctl := a.lerp(b, 0.5).lerp(wr, pull)
			var out := PackedVector2Array()
			for k in range(1, 10):
				var u := k / 10.0
				var q := a.lerp(ctl, u).lerp(ctl.lerp(b, u), u)
				out.append(Vector2(q.x, q.y))
			return out
		var V := func(v: Vector3) -> Vector2: return Vector2(v.x, v.y)
		# 앞쪽 막(팔뼈와 첫 손가락 사이) · 손가락 사이 칸 셋 · 안쪽 막(마지막 손가락 → 옆구리)
		var panels: Array = []
		panels.append(PackedVector2Array([V.call(root), V.call(el), V.call(wr), V.call(tips[0])]) + PackedVector2Array([V.call(root)]))
		for i in 3:
			panels.append(PackedVector2Array([V.call(wr), V.call(tips[i])]) + scallop.call(tips[i], tips[i + 1], 0.42) + PackedVector2Array([V.call(tips[i + 1])]))
		panels.append(PackedVector2Array([V.call(root), V.call(wr), V.call(tips[3])]) + scallop.call(tips[3], body, 0.3) + PackedVector2Array([V.call(body)]))
		for pl: PackedVector2Array in panels:
			cl.slab(g, pl, z, 0.045 * U, m, 1.5, 0.06 * U)
		for k in 5:  # 찢어진 구멍
			var a: Vector3 = wr.lerp(tips[rng.randi_range(0, 3)], rng.randf_range(0.5, 0.85))
			cl.erase(g, Vector2(a.x, a.y), rng.randf_range(0.012, 0.03) * U, rng.randf_range(0.015, 0.04) * U, 0.5)
		var bz := z + 0.05 * U  # 뼈는 막 위로 도드라진다
		var lift := Vector3(0, 0, bz - z)
		cl.chain(g, [root + lift, el + lift, wr + lift], [0.036 * U, 0.026 * U, 0.022 * U], bm, 0.01 * U)
		cl.ell(g, el + lift, 0.032 * U, 0.032 * U, 0.03 * U, bm, 0.01 * U)
		cl.ell(g, wr + lift, 0.028 * U, 0.028 * U, 0.026 * U, bm, 0.01 * U)
		cl.cap(g, wr + lift, wr + lift + Vector3(s * 0.03 * U, -0.09 * U, 0.01 * U), 0.018 * U, 0.003 * U, claw, 0.005 * U)  # 엄지 갈고리
		for t: Vector3 in tips:
			var bend := wr.lerp(t, 0.5) + Vector3(s * 0.02 * U, -0.015 * U, 0)
			cl.chain(g, [wr + lift, bend + lift * 0.8, t + lift * 0.4], [0.017 * U, 0.011 * U, 0.004 * U], bm, 0.005 * U)
		for i in 3:  # 막의 핏줄(칸 가운데로 갈라져 나감)
			for k in 2:
				var a: Vector3 = wr.lerp(tips[i], 0.35 + k * 0.25)
				var b2: Vector3 = wr.lerp(tips[i + 1], 0.4 + k * 0.25)
				var mid := a.lerp(b2, 0.5)
				cl.ridge(g, [Vector2(a.x, a.y), Vector2(mid.x, mid.y + 0.02 * U), Vector2(b2.x, b2.y)], 0.004 * U, 0.004 * U, m)


## 가슴·배에 박힌 얼굴: 눈썹뼈 · 빛나는 두 눈 · 콧구멍 · 이빨 드러낸 입.
static func _belly_face(cl: Clay, g: int, cx: float, Y: Callable, W: float, U: float, skin: int, bone: int, dark: int, eye: int) -> Array:
	var ey: float = Y.call(0.665)
	var eyes: Array = []
	var bz := cl.surf(g, cx, ey)
	cl.cap(g, Vector3(cx - W * 0.06, ey - 0.03 * U, bz - 0.01 * U), Vector3(cx + W * 0.06, ey - 0.03 * U, bz - 0.01 * U), 0.022 * U, 0.022 * U, skin, 0.015 * U)
	for s: float in [-1.0, 1.0]:
		var e := Vector2(cx + s * W * 0.035, ey)
		cl.carve(g, e, 0.04 * U, 0.03 * U, 0.05 * U)
		cl.ell(g, Vector3(e.x, e.y, cl.surf(g, e.x, e.y) - 0.005 * U), 0.022 * U, 0.018 * U, 0.015 * U, eye, 0.002 * U)
		eyes.append(e)
		cl.carve(g, Vector2(cx + s * 0.018 * U, ey + 0.06 * U), 0.01 * U, 0.016 * U, 0.03 * U)
	var my: float = Y.call(0.75)
	var mw := W * 0.075
	cl.carve(g, Vector2(cx, my), mw, 0.038 * U, 0.06 * U)
	var mz := cl.surf(g, cx, my)
	cl.ell(g, Vector3(cx, my, mz - 0.01 * U), mw * 0.92, 0.034 * U, 0.004 * U, dark, 0.0)
	for row: float in [-1.0, 1.0]:
		for k in 9:
			var u := lerpf(-0.9, 0.9, (k + 0.5) / 9.0)
			var a := Vector2(cx + u * mw, my + row * 0.034 * U * sqrt(1.0 - u * u * 0.6))
			var z := cl.surf(g, a.x, a.y)
			var ln := 0.028 * U * (1.3 if k % 3 == 1 else 1.0)
			cl.cap(g, Vector3(a.x, a.y, z), Vector3(a.x, a.y - row * ln, z + 0.004 * U), 0.012 * U, 0.003 * U, bone, 0.001 * U)
	for row: float in [-1.0, 1.0]:  # 입술 주름
		cl.ridge(g, [Vector2(cx - mw * 1.05, my), Vector2(cx, my + row * 0.05 * U), Vector2(cx + mw * 1.05, my)], 0.012 * U, 0.008 * U, skin)
	return eyes


## 어깨를 두른 두꺼운 털 목도리: 목 둘레 타원을 따라 굵은 털 뭉치를 이어 붙인 고리(뒤쪽 반은 머리 뒤, 앞쪽 반은 가슴 위로 처짐).
static func _collar(cl: Clay, X: Callable, Y: Callable, W: float, U: float, sp: Dictionary, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(sp.get("fur", Color("#7a6a58")), "fur")
	var c := Vector2(cx_of(X), Y.call(0.41))
	var rx := W * 0.27
	var ry := U * 0.12
	for half in 2:  # 0 = 뒤(위쪽 호), 1 = 앞(아래쪽 호)
		var g := cl.group()
		var pts: Array = []
		var rs: Array = []
		for k in 15:
			var t := k / 14.0
			var a := PI + PI * t if half == 0 else PI - PI * t
			var sag := 0.0 if half == 0 else sin(t * PI) * 0.02 * U
			var z := -0.1 * U if half == 0 else 0.08 * U + sin(t * PI) * 0.08 * U
			pts.append(Vector3(c.x + cos(a) * rx, c.y + sin(a) * ry + sag, z))
			rs.append(U * (0.1 + 0.03 * sin(t * PI)) * rng.randf_range(0.9, 1.1))
		cl.chain(g, pts, rs, m, 0.04 * U)
		for k in 10:  # 털 뭉치 혹
			var q: Vector3 = pts[rng.randi_range(1, 13)]
			cl.bump(g, Vector2(q.x + rng.randf_range(-1, 1) * 0.04 * U, q.y + rng.randf_range(-1, 1) * 0.03 * U), 0.06 * U, 0.05 * U, 0.02 * U, m, 0.02 * U)


static func cx_of(X: Callable) -> float:
	return X.call(0.0)


## 털 목도리에서 돋아난 까마귀 머리들: 둥근 머리 + 길게 휜 부리(바깥·아래로) + 빛나는 눈 하나.
static func _birds(cl: Clay, X: Callable, Y: Callable, U: float, n: int, eye: int) -> Array:
	var m := cl.mat(Color("#3e3230"), "hair", {"hatch": 0.6})
	var beak := cl.mat(Color("#2a2420"), "bone")
	var g := cl.group()
	var eyes: Array = []
	for k in n:
		var t := (k + 0.5) / n  # 왼쪽 어깨 → 가슴 → 오른쪽 어깨(털 고리 앞쪽 호를 따라)
		var s := -1.0 if t < 0.5 else 1.0
		var a := PI - PI * t
		var px: float = X.call(cos(a) * 0.3)
		var py: float = Y.call(0.43) + sin(a) * U * 0.12 + sin(t * PI) * 0.02 * U
		var c := Vector3(px, py, 0.2 * U + sin(t * PI) * 0.1 * U)
		var dir := Vector3(s * (0.35 + absf(t - 0.5) * 1.3), 0.8, 0.45).normalized()
		cl.ell(g, c, 0.05 * U, 0.045 * U, 0.045 * U, m, 0.01 * U)
		var tip := c + dir * 0.15 * U + Vector3(0, 0.03 * U, 0)
		cl.chain(g, [c + dir * 0.03 * U, c + dir * 0.09 * U + Vector3(0, -0.005 * U, 0), tip], [0.022 * U, 0.013 * U, 0.002 * U], beak, 0.003 * U)  # 휜 부리
		var e := Vector3(c.x - dir.x * 0.008 * U, c.y - 0.012 * U, c.z + 0.04 * U)
		cl.ell(g, e, 0.01 * U, 0.01 * U, 0.007 * U, eye, 0.001 * U)
		eyes.append(Vector2(e.x, e.y))
	return eyes


## 작고 창백한 얼굴(눈은 천으로 가렸다) + 크게 말려 올라간 숫양 뿔.
static func _head(cl: Clay, cx: float, Y: Callable, W: float, U: float, skin: int, bone: int, mats: Dictionary, _rng: RandomNumberGenerator) -> Dictionary:
	var pale := cl.mat(Color("#e2cdb4"), "skin", {"shade": Color("#6a3a4a")})
	var j := {"head": Vector3(cx, Y.call(0.24), 0.22 * U), "head_h": 0.27 * U, "tilt": 0.0}
	var f := Face.head(cl, j, {"type": "human", "mouth": "shut", "jaw": 0.82, "width": 0.38, "ears": "none"}, pale, mats)
	var hh: float = f["hh"]
	var c: Vector2 = f["c"]
	var veil := cl.mat(Color("#cfc0a8"), "hair")  # 얼굴을 감싼 창백한 머리카락
	var vg := cl.group()
	var vp := PackedVector2Array()
	for k in 21:
		var a := PI + PI * k / 20.0
		vp.append(Vector2(c.x + cos(a) * hh * 0.62, c.y - hh * 0.1 + sin(a) * hh * 0.62))
	vp.append(Vector2(c.x + hh * 0.7, c.y + hh * 0.75))
	vp.append(Vector2(c.x + hh * 0.3, c.y + hh * 0.45))
	vp.append(Vector2(c.x - hh * 0.3, c.y + hh * 0.45))
	vp.append(Vector2(c.x - hh * 0.7, c.y + hh * 0.75))
	cl.slab(vg, vp, cl.surf(f["g"], c.x, c.y) - hh * 0.7, hh * 0.2, veil, 2.0, hh * 0.15)
	for k in 9:
		var u := lerpf(-0.6, 0.6, (k + 0.5) / 9.0)
		cl.groove(vg, Vector2(c.x + u * hh * 0.5, c.y - hh * 0.6), Vector2(c.x + u * hh * 1.1, c.y + hh * 0.7), hh * 0.02, hh * 0.04)
	var cloth := cl.mat(Color("#3a1418"), "cloth")
	var bg := cl.group()
	var band := PackedVector2Array([Vector2(c.x - hh, c.y - hh * 0.13), Vector2(c.x + hh, c.y - hh * 0.16), Vector2(c.x + hh, c.y + hh * 0.07), Vector2(c.x - hh, c.y + hh * 0.1)])
	cl.shell(["head"], hh * 0.035, cloth, bg, band, 3.0)
	var hg := cl.group()
	var hz := cl.surf(f["g"], c.x, c.y)
	for s: float in [-1.0, 1.0]:  # 뿔: 머리 양옆에서 바깥으로 크게 뻗었다가 위로 치솟는 황소 뿔
		var uv := [[0.3, -0.38], [0.62, -0.62], [0.92, -0.74], [1.18, -0.92], [1.3, -1.22], [1.24, -1.52]]
		var pts: Array = []
		var rs: Array = []
		for k in uv.size():
			var t := float(k) / (uv.size() - 1)
			pts.append(Vector3(c.x + s * uv[k][0] * hh, c.y + uv[k][1] * hh, hz - hh * 0.25 - t * hh * 0.15))
			rs.append(hh * (0.17 - t * 0.15))
		cl.chain(hg, pts, rs, bone, 2.0)
		for k in 4:  # 뿔의 마디 골
			var q: Vector3 = pts[k + 1]
			cl.groove(hg, Vector2(q.x - hh * 0.07, q.y + hh * 0.02), Vector2(q.x + hh * 0.07, q.y - hh * 0.02), hh * 0.014, hh * 0.022)
	f["band_y"] = c.y - hh * 0.03
	return f


## 눈가리개 주름 그늘 + 감은 얼굴의 입 선.
static func _blindfold_shadow(p: Paint, f: Dictionary, U: float) -> void:
	var hh: float = f["hh"]
	var c: Vector2 = f["c"]
	Ink.line(p, Vector2(c.x - hh * 0.38, f["band_y"] - hh * 0.07), Vector2(c.x + hh * 0.38, f["band_y"] - hh * 0.09), maxf(1.2, U / 400.0), Ink.INK, 0.7, 0.6)
	Ink.line(p, Vector2(c.x - hh * 0.12, c.y + hh * 0.3), Vector2(c.x + hh * 0.12, c.y + hh * 0.3), maxf(1.4, U / 360.0), Ink.INK, 0.9, 0.5)


## 아래쪽은 검은 연기로: 점점 어둡게 물들이고, 가장자리를 잡음으로 지우고, 둘레에 검은 연기 얼룩을 흘린다.
static func _smoke(p: Paint, y0: float, U: float, rng: RandomNumberGenerator) -> void:
	for y in range(int(y0), p.h):
		var t := (y - y0) / (p.h - y0)
		for x in p.w:
			var k := (y * p.w + x) * 4
			if p.buf[k + 3] <= 0.0:
				continue
			var n := p.nz("mid", x, y) * 0.6 + p.nz("lo", x, y) * 0.4
			var dk := clampf(t * 1.3 + (n - 0.5) * 0.6, 0.0, 1.0)
			for c in 3:
				p.buf[k + c] = lerpf(p.buf[k + c], 0.03, dk * 0.92)
			if t > 0.55:
				p.buf[k + 3] *= clampf(1.0 - (t - 0.55) * 2.4 + (n - 0.5) * 0.8, 0.0, 1.0)
	for i in 70:  # 둘레로 번지는 연기
		var x := p.w * 0.5 + rng.randf_range(-0.6, 0.6) * U
		var y := lerpf(y0 + (p.h - y0) * 0.2, p.h * 0.98, rng.randf())
		var r := rng.randf_range(0.04, 0.1) * U
		for yy in range(int(y - r), int(y + r) + 1):
			for xx in range(int(x - r), int(x + r) + 1):
				var d := Vector2(xx - x, yy - y).length() / r
				if d < 1.0:
					p.blend(xx, yy, Color(0.03, 0.02, 0.025), (1.0 - d) * (1.0 - d) * 0.22 * (0.6 + p.nz("mid", xx, yy) * 0.8))
