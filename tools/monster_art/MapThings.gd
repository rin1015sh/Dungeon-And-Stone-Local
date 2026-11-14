extends RefCounted
## 탐험 맵 걷기 그림용 몸(사람형 · 네발짐승이 아닌 2층 몬스터): 전갈 · 독수리 · 포자 버섯 · 가시넝쿨 · 떼(박쥐 · 까마귀 · 말벌).
## 전투 그림(Things3 — 정면 한 장)과 같은 생김새를 몸 좌표로 다시 빚어 돌릴 수 있게 한다(Back.proj — 앞 · 옆 · 뒤 × 걸음). MapMonster.paint가 부른다.
## 몸 좌표: 키 비율, x 옆 · y 아래(+) — 발이 0, 위는 음수 · z 앞이 −(돌림 π면 보는 사람 쪽). walk = 걸음 +1 / 0 / −1.

const Paint := preload("res://tools/city_art/Paint.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const Things2 := preload("res://tools/monster_art/Things2.gd")

const KINDS := ["scorpion", "bird", "shroom", "vine", "swarm"]


static func paint(kind: String, sp: Dictionary, turn: float, walk: float, seed_value: int) -> Paint:
	var H := float(sp["height"])
	var w := int(H * 1.5)
	var h := int(H * 1.25)
	var p := Paint.new(w, h, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(w, h)
	var pr := Back.proj(Vector2(w * 0.5, h - H * 0.22), H, turn, float(sp.get("pitch", 0.3)))
	var post := {}
	match kind:
		"scorpion":
			post = _scorpion(cl, pr, sp, walk)
		"bird":
			post = _bird(cl, pr, sp, walk)
		"shroom":
			post = _shroom(cl, pr, sp, walk, rng)
		"vine":
			post = _vine(cl, pr, sp, walk, rng)
		"swarm":
			post = _swarm(cl, pr, sp, walk, rng)
	Render.render(cl, p, H)
	Things2.after(p, cl, post, sp, H, rng)
	Finish.done(p, sp, post.get("j", {}), H)
	return p


## 눈 자리(보는 사람 쪽을 향할 때만).
static func _eyes(pr: Dictionary, at: Vector3, gap: float, fwd: float = 0.0) -> Array:
	var out: Array = []
	for s: float in [-1.0, 1.0]:
		if Back.facing(pr, Vector3(s * 0.55, 0, -1)) > 0.2:
			out.append(Back.P2(pr, at + Vector3(s * gap, 0, fwd)))
	return out


## 사막 전갈: 낮은 마디 몸 · 앞으로 벌린 집게 · 다리 여덟(걸음마다 엇갈려 내딛는다) · 등 위로 휘어 넘어온 꼬리와 독침.
static func _scorpion(cl: Clay, pr: Dictionary, sp: Dictionary, walk: float) -> Dictionary:
	var col: Color = sp.get("color", Color("#8a6a40"))
	var shell := cl.mat(col, "bone", {"mottle": col.darkened(0.35), "mottle_amt": 0.4, "spec": 0.4})
	var dark := cl.mat(col.darkened(0.45), "bone")
	var sting := cl.mat(Color("#2a1a12"), "bone")
	var c := Vector3(0, -0.11, 0.0)
	var g_leg := cl.group()
	for s: float in [-1.0, 1.0]:
		for k in 4:
			var z := -0.08 + k * 0.075
			var step := walk * s * (1.0 if k % 2 == 0 else -1.0)
			var hip := c + Vector3(s * 0.12, 0.02, z)
			var knee := hip + Vector3(s * 0.15, -0.09, -step * 0.02)
			var toe := Vector3(s * 0.33, -maxf(0.0, step) * 0.035, z - step * 0.06)
			Back.chain(cl, pr, g_leg, [hip, knee, toe], [0.024, 0.018, 0.007], dark, 0.004)
	var g := cl.group()
	for k in 4:  # 몸 마디(앞이 크다)
		Back.ell(cl, pr, g, c + Vector3(0, -0.01 - k * 0.01, -0.06 + k * 0.085), 0.17 - k * 0.022, 0.085, 0.075, shell, 0.012)
	var head := c + Vector3(0, 0.0, -0.17)
	Back.ell(cl, pr, g, head, 0.13, 0.07, 0.08, shell, 0.012)
	var g_claw := cl.group()
	for s: float in [-1.0, 1.0]:
		var reach := walk * s * 0.025
		var sh := head + Vector3(s * 0.09, 0.0, -0.02)
		var el := sh + Vector3(s * 0.17, -0.05, -0.1 + reach)
		var wr := el + Vector3(-s * 0.05, -0.02, -0.14)
		Back.chain(cl, pr, g_claw, [sh, el, wr], [0.035, 0.04, 0.048], shell, 0.006)
		Back.ell(cl, pr, g_claw, wr + Vector3(0, -0.01, -0.05), 0.07, 0.055, 0.085, shell, 0.01)
		Back.cap(cl, pr, g_claw, wr + Vector3(s * 0.03, -0.01, -0.1), wr + Vector3(-s * 0.015, -0.02, -0.2), 0.026, 0.004, dark, 0.004)
		Back.cap(cl, pr, g_claw, wr + Vector3(-s * 0.035, 0.0, -0.1), wr + Vector3(-s * 0.02, -0.01, -0.19), 0.018, 0.003, dark, 0.004)
	var g_tail := cl.group()
	var tail: Array = []
	for k in 9:
		var t := k / 8.0
		var a := t * PI * 1.05
		tail.append(Vector3(walk * 0.035 * t, -0.13 - (1.0 - cos(a)) * 0.22, 0.24 + sin(a) * 0.17 - t * 0.34))
	for k in tail.size() - 1:
		var r := lerpf(0.07, 0.038, k / 8.0)
		Back.cap(cl, pr, g_tail, tail[k], tail[k + 1], r, r * 0.92, shell, 0.006)
		Back.ell(cl, pr, g_tail, (tail[k] as Vector3).lerp(tail[k + 1], 0.5), r * 1.12, r, r * 1.0, shell, 0.008)
	var tip: Vector3 = tail[8]
	Back.ell(cl, pr, g_tail, tip + Vector3(0, 0.02, -0.02), 0.05, 0.05, 0.055, dark, 0.01)
	Back.cap(cl, pr, g_tail, tip + Vector3(0, 0.05, -0.04), tip + Vector3(0, 0.13, -0.1), 0.022, 0.002, sting, 0.003)
	return {"eyes2": _eyes(pr, head + Vector3(0, -0.035, 0), 0.03, -0.06), "j": {"chest": Back.P(pr, head), "waist": Back.P(pr, c)}}


## 사막 독수리: 접은 날개 · 털 없는 긴 목 · 굽은 부리 · 깃털 목도리. 뒤뚱거리며 걷는다(다리를 번갈아, 머리를 앞뒤로).
static func _bird(cl: Clay, pr: Dictionary, sp: Dictionary, walk: float) -> Dictionary:
	var col: Color = sp.get("color", Color("#5a4a3a"))
	var feather := cl.mat(col, "fur", {"mottle": col.darkened(0.35), "mottle_amt": 0.4})
	var ruff := cl.mat(sp.get("ruff", Color("#c8b8a0")), "fur")
	var skin := cl.mat(sp.get("skin", Color("#b07a6a")), "skin")
	var beak := cl.mat(Color("#d8c8a0"), "bone")
	var talon := cl.mat(Color("#3a3028"), "bone")
	var sway := walk * 0.02
	var gl := cl.group()
	for s: float in [-1.0, 1.0]:
		var step := walk * s
		var hip := Vector3(s * 0.07 + sway, -0.17, 0.02)
		var ft := Vector3(s * 0.08, -maxf(0.0, step) * 0.04, 0.0 - step * 0.09)
		Back.cap(cl, pr, gl, hip, ft, 0.022, 0.016, skin, 0.004)
		for f in 3:
			Back.cap(cl, pr, gl, ft, ft + Vector3((f - 1) * 0.035, 0.008, -0.06), 0.009, 0.002, talon, 0.002)
	var g := cl.group()
	var c := Vector3(sway, -0.31 - absf(walk) * 0.012, 0.03)
	Back.ell(cl, pr, g, c, 0.17, 0.19, 0.21, feather, 0.03)
	for k in 5:  # 꽁지깃
		var q := c + Vector3((k - 2) * 0.035, 0.08, 0.18)
		Back.cap(cl, pr, g, q, q + Vector3((k - 2) * 0.015, 0.1, 0.1), 0.028, 0.008, feather, 0.006)
	var gw := cl.group()
	for s: float in [-1.0, 1.0]:  # 접은 날개
		Back.ell(cl, pr, gw, c + Vector3(s * 0.14, 0.0, 0.05), 0.07, 0.17, 0.2, feather, 0.03)
		Back.ell(cl, pr, gw, c + Vector3(s * 0.13, -0.13, -0.04), 0.07, 0.07, 0.09, feather, 0.03)  # 솟은 어깨
		for k in 4:
			var q := c + Vector3(s * 0.13, 0.17 + k * 0.012, 0.1 + k * 0.035)
			Back.cap(cl, pr, gw, q, q + Vector3(s * 0.005, 0.07, 0.03), 0.022, 0.006, feather, 0.004)
	var gr := cl.group()
	Back.ell(cl, pr, gr, c + Vector3(0, -0.16, -0.08), 0.13, 0.07, 0.12, ruff, 0.02)
	var gn := cl.group()
	var nod := -absf(walk) * 0.035
	var neck0 := c + Vector3(0, -0.18, -0.09)
	var hd := c + Vector3(0.0, -0.3, -0.2 + nod)
	Back.chain(cl, pr, gn, [neck0, neck0.lerp(hd, 0.5) + Vector3(0, 0, 0.03), hd], [0.045, 0.036, 0.045], skin, 0.008)
	Back.ell(cl, pr, gn, hd, 0.06, 0.055, 0.065, skin, 0.01)
	Back.chain(cl, pr, gn, [hd + Vector3(0, 0.005, -0.05), hd + Vector3(0, 0.02, -0.12), hd + Vector3(0, 0.08, -0.13)], [0.028, 0.02, 0.005], beak, 0.003)
	return {"eyes2": _eyes(pr, hd + Vector3(0, -0.008, 0), 0.03, -0.03), "j": {"chest": Back.P(pr, c + Vector3(0, -0.1, 0)), "waist": Back.P(pr, c)}}


## 포자 버섯: 굵은 대 · 넓은 점박이 갓 · 대에 파인 눈과 입. 뿌리 발을 번갈아 내딛고 갓이 걸음마다 기운다.
static func _shroom(cl: Clay, pr: Dictionary, sp: Dictionary, walk: float, rng: RandomNumberGenerator) -> Dictionary:
	var H: float = pr["H"]
	var stalk := cl.mat(sp.get("color", Color("#c8b8a0")), "skin", {"mottle": Color("#8a7a68"), "mottle_amt": 0.4})
	var capc: Color = sp.get("cap", Color("#a04a5a"))
	var cap := cl.mat(capc, "skin", {"mottle": capc.darkened(0.4), "mottle_amt": 0.5, "spec": 0.3})
	var spot := cl.mat(sp.get("spots", Color("#e8dcc0")), "bone")
	var lean := walk * 0.035
	var bob := absf(walk) * 0.015
	var g := cl.group()
	var base := Vector3(0, -0.05, 0.0)
	var neck := Vector3(lean, -0.45 - bob, 0.0)
	Back.cap(cl, pr, g, base, neck, 0.13, 0.1, stalk, 0.03)
	for k in 6:  # 뿌리 발 — 앞뒤 둘이 걸음을 딛는다
		var a := TAU * k / 6.0 + 0.5
		var step := walk * (1.0 if k % 2 == 0 else -1.0)
		var tip := Vector3(sin(a) * 0.21, -maxf(0.0, step) * 0.03, cos(a) * 0.19 - step * 0.05)
		Back.cap(cl, pr, g, base + Vector3(sin(a) * 0.07, 0.0, cos(a) * 0.07), tip, 0.034, 0.009, stalk, 0.01)
	var c := Vector3(lean * 0.5, -0.26 - bob * 0.5, 0.0)
	var eyes: Array = []
	for s: float in [-1.0, 1.0]:
		if Back.facing(pr, Vector3(s * 0.5, 0, -1)) > 0.25:
			var q := Back.P2(pr, c + Vector3(s * 0.045, -0.02, -0.115))
			cl.carve(g, q, 0.025 * H, 0.02 * H, 0.03 * H)
			eyes.append(q)
	if Back.facing(pr, Vector3(0, 0, -1)) > 0.3:
		cl.carve(g, Back.P2(pr, c + Vector3(0, 0.06, -0.12)), 0.05 * H * Back.facing(pr, Vector3(0, 0, -1)), 0.016 * H, 0.03 * H)
	var gc := cl.group()
	var top := Vector3(lean * 1.3, -0.56 - bob, 0.0)
	Back.ell(cl, pr, gc, top, 0.36, 0.17, 0.3, cap, 0.04, walk * 0.06)
	for k in 16:  # 갓 점(보이는 쪽 위 반구만)
		var a := rng.randf_range(0.0, TAU)
		var rr := rng.randf_range(0.2, 0.85)
		var n := Vector3(cos(a) * rr, -sqrt(1.0 - rr * rr), sin(a) * rr)
		if Back.facing(pr, Vector3(n.x, 0, n.z)) < -0.1 and rr > 0.45:
			continue
		var q := Back.P2(pr, top + Vector3(n.x * 0.33, n.y * 0.15, n.z * 0.27))
		cl.bump(gc, q, rng.randf_range(0.02, 0.035) * H, rng.randf_range(0.015, 0.025) * H, 0.01 * H, spot, 0.004 * H, 0.0)
	return {"eyes2": eyes, "j": {"chest": Back.P(pr, c), "waist": Back.P(pr, base)}}


## 가시넝쿨: 흙 밑동에서 솟은 굵은 덩굴 일곱이 가운데 봉오리를 감싼다. 덩굴 끝이 가는 쪽으로 휘고, 걸음마다 좌우로 꿈틀거리며 땅의 뿌리가 번갈아 뻗는다.
static func _vine(cl: Clay, pr: Dictionary, sp: Dictionary, walk: float, rng: RandomNumberGenerator) -> Dictionary:
	var H: float = pr["H"]
	var col: Color = sp.get("color", Color("#4a6a3a"))
	var bark := cl.mat(col, "wood", {"mottle": col.darkened(0.35), "mottle_amt": 0.5})
	var thorn := cl.mat(Color("#c8b890"), "bone")
	var bud := cl.mat(sp.get("bud", Color("#7a2a3a")), "skin", {"mottle": Color("#3a1a20"), "mottle_amt": 0.5})
	var gr := cl.group()
	Back.ell(cl, pr, gr, Vector3(0, -0.02, 0), 0.3, 0.04, 0.26, cl.mat(Color("#3a3024"), "stone"), 0.02)
	for k in 4:  # 땅을 기는 뿌리 — 앞의 둘이 번갈아 뻗는다
		var s := 1.0 if k % 2 == 0 else -1.0
		var fwd := -1.0 if k < 2 else 1.0
		var step := walk * s * (1.0 if k < 2 else -1.0)
		Back.chain(cl, pr, gr, [Vector3(s * 0.12, -0.03, fwd * 0.1), Vector3(s * 0.25, -0.05, fwd * 0.22 - step * 0.04), Vector3(s * 0.3, 0.0, fwd * 0.34 - step * 0.08)], [0.04, 0.03, 0.01], bark, 0.01)
	var c := Vector3(walk * 0.015, -0.42, 0.0)
	for k in 7:
		var a := TAU * k / 7.0 + 0.3 + rng.randf_range(-0.12, 0.12)
		var wig := walk * (0.05 if k % 2 == 0 else -0.05)
		var root := Vector3(sin(a) * 0.24, -0.02, cos(a) * 0.2)
		var mid := Vector3(sin(a) * 0.36 + wig * 0.5, -rng.randf_range(0.35, 0.58), cos(a) * 0.3)
		var tip := Vector3(sin(a) * rng.randf_range(0.16, 0.28) + wig, -rng.randf_range(0.64, 0.86), cos(a) * 0.2 - 0.12)
		var g := cl.group()
		var pts: Array = [root, root.lerp(mid, 0.5) + Vector3(sin(a) * 0.04, 0, cos(a) * 0.04), mid, mid.lerp(tip, 0.6), tip]
		Back.chain(cl, pr, g, pts, [0.05, 0.045, 0.038, 0.025, 0.008], bark, 0.012)
		for t in 6:  # 가시(바깥쪽으로)
			var q: Vector3 = (pts[t % 4] as Vector3).lerp(pts[t % 4 + 1], rng.randf())
			var out := Vector3(sin(a) + rng.randf_range(-0.6, 0.6), rng.randf_range(-0.8, 0.2), cos(a) + rng.randf_range(-0.6, 0.6)).normalized()
			Back.cap(cl, pr, g, q, q + out * 0.045, 0.008, 0.0015, thorn, 0.002)
	var gb := cl.group()
	Back.ell(cl, pr, gb, c + Vector3(0, 0.06, -0.02), 0.13, 0.15, 0.13, bud, 0.03)
	var eyes: Array = []
	var f := Back.facing(pr, Vector3(0, 0, -1))
	if f > 0.3:
		cl.carve(gb, Back.P2(pr, c + Vector3(0, 0.07, -0.15)), 0.07 * H * f, 0.025 * H, 0.04 * H)
	for s: float in [-1.0, 1.0]:
		Back.ell(cl, pr, gb, c + Vector3(s * 0.11, 0.1, -0.02), 0.045, 0.12, 0.09, bark, 0.02)
		if Back.facing(pr, Vector3(s * 0.5, 0, -1)) > 0.25:
			eyes.append(Back.P2(pr, c + Vector3(s * 0.04, 0.03, -0.14)))
	return {"eyes2": eyes, "j": {"chest": Back.P(pr, c), "waist": Back.P(pr, c + Vector3(0, 0.2, 0))}}


## 떼(박쥐 · 까마귀 · 말벌): 작은 몸 여럿이 공중에 뭉쳐 같은 쪽을 보고 난다. 걸음 칸마다 날갯짓이 바뀐다(마리마다 엇박자).
static func _swarm(cl: Clay, pr: Dictionary, sp: Dictionary, walk: float, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#3a3036"))
	var crow := bool(sp.get("beak", false))
	var insect := bool(sp.get("insect", false))
	var body := cl.mat(col, "fur" if not crow else "leather", {"mottle": col.darkened(0.4), "mottle_amt": 0.3})
	var wing := cl.mat(col.darkened(0.15) if not insect else Color("#b8b4a4"), "leather")
	var beak := cl.mat(Color("#2a2420"), "bone")
	var stripe := cl.mat(Color("#1e1a14"), "bone")
	var eyes: Array = []
	var n := int(sp.get("count", 7))
	var mid := Vector3(0, -0.5, 0)
	for k in n:
		var a := TAU * k / n + rng.randf_range(-0.3, 0.3)
		var r := 0.12 + 0.18 * float(k % 3) / 2.0
		var s := rng.randf_range(0.75, 1.15)
		var flap := sin(walk * PI * 0.5 + k * 2.1) * 0.9 + rng.randf_range(-0.15, 0.15)
		var q := mid + Vector3(cos(a) * r * 1.15, sin(a) * r * 0.75 - flap * 0.012, rng.randf_range(-0.22, 0.22))
		var g := cl.group()
		Back.ell(cl, pr, g, q, 0.04 * s, 0.045 * s, 0.06 * s, body, 0.01)
		var hd := q + Vector3(0, -0.02 * s, -0.065 * s)
		Back.ell(cl, pr, g, hd, 0.028 * s, 0.026 * s, 0.03 * s, body, 0.008)
		if crow:
			Back.cap(cl, pr, g, hd + Vector3(0, 0.004, -0.02 * s), hd + Vector3(0, 0.014, -0.07 * s), 0.011 * s, 0.002, beak, 0.002)
			Back.cap(cl, pr, g, q + Vector3(0, 0.0, 0.05 * s), q + Vector3(0, 0.01, 0.13 * s), 0.022 * s, 0.01 * s, wing, 0.004)  # 꽁지
		elif insect:
			Back.ell(cl, pr, g, q + Vector3(0, 0.01 * s, 0.07 * s), 0.034 * s, 0.036 * s, 0.05 * s, stripe, 0.006)
			Back.cap(cl, pr, g, q + Vector3(0, 0.015 * s, 0.11 * s), q + Vector3(0, 0.03 * s, 0.16 * s), 0.012 * s, 0.002, beak, 0.002)
		else:
			for e: float in [-1.0, 1.0]:
				Back.cap(cl, pr, g, hd + Vector3(e * 0.015 * s, -0.015 * s, 0), hd + Vector3(e * 0.025 * s, -0.05 * s, 0), 0.01 * s, 0.002, body, 0.002)
		for e: float in [-1.0, 1.0]:
			if Back.facing(pr, Vector3(e * 0.6, 0, -1)) > 0.3:
				eyes.append(Back.P2(pr, hd + Vector3(e * 0.011 * s, -0.004, -0.02 * s)))
			var w0 := q + Vector3(e * 0.03 * s, -0.01, 0)
			var w1 := w0 + Vector3(e * 0.09 * s, (-0.02 - flap * 0.07) * s, 0.01)
			var w2 := w1 + Vector3(e * 0.075 * s, (0.02 - flap * 0.05) * s, 0.02)
			Back.chain(cl, pr, g, [w0, w1, w2], [0.02 * s, 0.028 * s, 0.006 * s], wing, 0.006)
			Back.ell(cl, pr, g, w0.lerp(w2, 0.5) + Vector3(0, 0.012 * s, 0.02 * s), 0.07 * s, 0.012 * s, 0.045 * s, wing, 0.006)
	return {"eyes2": eyes, "j": {"chest": Back.P(pr, mid), "waist": Back.P(pr, mid + Vector3(0, 0.2, 0))}}
