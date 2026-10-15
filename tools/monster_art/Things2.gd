extends RefCounted
## Things의 나머지 몸(Clay): worm · slime · mound · eye · maggot + 칠한 뒤 손질(after — 슬라임 속 뼈·광택, 눈 핏줄, 빛).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")


## 바위 벌레: 땅에서 S자로 솟은 돌 마디 + 이빨이 둘러난 둥근 아가리(보는 사람 쪽).
static func worm(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#8a8a90"))
	var st := cl.mat(col, "stone", {"mottle": col.darkened(0.3), "mottle_amt": 0.4})
	var flesh := cl.mat(Color("#6a2a2a"), "skin")
	var bone := cl.mat(Color("#d8ccb0"), "bone")
	var dark := cl.mat(Color("#160807"), "glow")
	var g_rub := cl.group()
	for k in 9:  # 땅을 뚫고 나온 돌무더기
		var x := foot.x + rng.randf_range(-0.28, 0.28) * H
		cl.ell(g_rub, Vector3(x, foot.y - rng.randf_range(0.0, 0.03) * H, rng.randf_range(-0.05, 0.08) * H), rng.randf_range(0.04, 0.08) * H, rng.randf_range(0.025, 0.05) * H, 0.05 * H, st, 0.01 * H)
	var pts: Array = []
	for k in 9:
		var t := k / 8.0
		pts.append(Vector3(foot.x + sin(t * PI * 1.3) * 0.12 * H - 0.02 * H, foot.y - 0.02 * H - t * 0.72 * H, t * 0.12 * H))
	var g := cl.group()
	for k in pts.size() - 1:  # 마디마다 따로 부풀려 골이 진다
		var r := lerpf(0.11, 0.085, k / 8.0) * H
		cl.cap(g, pts[k], pts[k + 1], r, r * 0.96, st, 0.008 * H)
		var m: Vector3 = (pts[k] as Vector3).lerp(pts[k + 1], 0.5)
		cl.ell(g, m, r * 1.06, r * 0.5, r * 0.9, st, 0.012 * H)
	var top: Vector3 = pts[8]
	var g2 := cl.group()
	cl.ell(g2, top + Vector3(0, -0.01 * H, 0.06 * H), 0.11 * H, 0.1 * H, 0.08 * H, st, 0.01 * H)
	cl.carve(g2, Vector2(top.x, top.y - 0.01 * H), 0.08 * H, 0.072 * H, 0.06 * H)
	var mz := cl.surf(g2, top.x, top.y - 0.01 * H)
	cl.ell(g2, Vector3(top.x, top.y - 0.01 * H, mz - 0.01 * H), 0.075 * H, 0.068 * H, 0.01 * H, flesh, 0.0)
	cl.ell(g2, Vector3(top.x, top.y - 0.01 * H, mz + 0.002 * H), 0.035 * H, 0.032 * H, 0.004 * H, dark, 0.0)
	for k in 16:  # 안쪽을 향한 이빨 고리
		var a := TAU * k / 16.0
		var b := Vector2(top.x, top.y - 0.01 * H) + Vector2(cos(a), sin(a)) * Vector2(0.074 * H, 0.066 * H)
		var tip := Vector2(top.x, top.y - 0.01 * H) + Vector2(cos(a), sin(a)) * Vector2(0.042 * H, 0.038 * H)
		var bz := cl.surf(g2, b.x, b.y)
		cl.cap(g2, Vector3(b.x, b.y, bz), Vector3(tip.x, tip.y, bz + 0.004 * H), 0.009 * H, 0.0015 * H, bone, 0.001 * H)
	return {"j": {"chest": top, "waist": pts[4]}}


## 점액 덩어리: 둥근 언덕 + 흘러내린 자락 + (속에 비친) 뼈·결정 + 왕관.
static func slime(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#5ac05a"))
	var sl := cl.mat(col, "slime", {"shade": col.darkened(0.55)})
	var g := cl.group()
	var r := 0.4 * H
	var c := Vector3(foot.x, foot.y - r * 0.55, 0.0)
	cl.ell(g, c, r * 1.05, r * 0.62, r * 0.75, sl, 0.05 * H)
	cl.ell(g, c + Vector3(0, -r * 0.3, 0.02 * H), r * 0.7, r * 0.5, r * 0.6, sl, 0.08 * H)
	cl.ell(g, Vector3(foot.x, foot.y - 0.03 * H, 0.04 * H), r * 1.25, 0.045 * H, 0.08 * H, sl, 0.06 * H)  # 바닥에 퍼진 웅덩이
	var post := {"slime_c": c, "slime_r": r, "j": {"chest": c, "waist": c}}
	if sp.has("crystals"):
		var cm := cl.mat(sp["crystals"], "slime", {"spec": 1.3})
		var g2 := cl.group()
		for k in 9:
			var a := rng.randf_range(-2.9, -0.25)
			var b := c + Vector3(cos(a) * r * 0.85, sin(a) * r * 0.5, 0.05 * H)
			var t := b + Vector3(cos(a) * 0.07 * H, sin(a) * 0.12 * H - 0.04 * H, 0.02 * H)
			cl.cap(g2, b, t, rng.randf_range(0.02, 0.035) * H, 0.002 * H, cm, 0.002 * H)
	if sp.has("crown"):
		var cm := cl.mat(sp["crown"], "metal")
		var g3 := cl.group()
		var top := c + Vector3(0, -r * 0.78, 0.02 * H)
		for k in 7:
			var u := lerpf(-0.11, 0.11, k / 6.0) * H
			cl.cap(g3, top + Vector3(u, 0, -absf(u) * 0.3), top + Vector3(u * 1.15, -(0.08 if k % 2 == 0 else 0.05) * H, -absf(u) * 0.3), 0.014 * H, 0.004 * H, cm, 0.004 * H)
		cl.cap(g3, top + Vector3(-0.12 * H, 0.0, -0.03 * H), top + Vector3(0.12 * H, 0.0, -0.03 * H), 0.02 * H, 0.02 * H, cm, 0.01 * H)
	post["eyes2"] = [Vector2(c.x - r * 0.25, c.y - r * 0.12), Vector2(c.x + r * 0.22, c.y - r * 0.1)]
	return post


## 흙더미 노움: 울퉁불퉁 흙·돌 무더기 + 이끼 + 작은 얼굴 + 뿌리 같은 팔.
static func mound(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#7a6a52"))
	var earth := cl.mat(col, "stone", {"mottle": col.darkened(0.3), "mottle_amt": 0.5})
	var g := cl.group()
	cl.tag = "mound"
	var c := Vector3(foot.x, foot.y - 0.2 * H, 0.0)
	cl.ell(g, c, 0.3 * H, 0.22 * H, 0.2 * H, earth, 0.04 * H)
	for k in 14:  # 돌·흙 덩이
		var a := rng.randf_range(-PI, 0.2)
		var rr := rng.randf_range(0.5, 0.95)
		cl.bump(g, Vector2(c.x + cos(a) * 0.27 * H * rr, c.y + sin(a) * 0.19 * H * rr), rng.randf_range(0.03, 0.06) * H, rng.randf_range(0.025, 0.05) * H, 0.02 * H, earth, 0.01 * H, rng.randf() * PI)
	if sp.has("moss"):
		var mm := cl.mat(sp["moss"], "fur")
		var gm := cl.group()
		var clip := PackedVector2Array()
		for k in 13:
			var a := PI + PI * k / 12.0
			clip.append(Vector2(c.x + cos(a) * 0.32 * H, c.y - 0.06 * H + sin(a) * 0.2 * H + (0.03 * H if k % 2 == 0 else 0.0)))
		cl.shell(["mound"], 0.012 * H, mm, gm, clip, 3.0, 0.0, true)
	var post := {"j": {"chest": c, "waist": c}}
	# 얼굴: 눈 두 구멍 + 입 틈
	for s: float in [-1.0, 1.0]:
		cl.carve(g, Vector2(c.x + s * 0.06 * H, c.y - 0.02 * H), 0.025 * H, 0.02 * H, 0.03 * H)
	cl.carve(g, Vector2(c.x, c.y + 0.06 * H), 0.06 * H, 0.018 * H, 0.03 * H)
	post["eyes2"] = [Vector2(c.x - 0.06 * H, c.y - 0.02 * H), Vector2(c.x + 0.06 * H, c.y - 0.02 * H)]
	post["mouth2"] = Vector2(c.x, c.y + 0.06 * H)
	for s: float in [-1.0, 1.0]:  # 뿌리 팔
		var ga := cl.group()
		var a := Vector3(c.x + s * 0.24 * H, c.y + 0.02 * H, 0.05 * H)
		cl.chain(ga, [a, a + Vector3(s * 0.08 * H, 0.06 * H, 0.04 * H), a + Vector3(s * 0.1 * H, 0.15 * H, 0.06 * H)], [0.035 * H, 0.025 * H, 0.012 * H], earth, 0.01 * H)
		for f in 3:
			var b := a + Vector3(s * 0.1 * H, 0.15 * H, 0.06 * H)
			cl.cap(ga, b, b + Vector3(s * (f - 1) * 0.025 * H, 0.04 * H, 0.02 * H), 0.008 * H, 0.002 * H, earth, 0.004 * H)
	if sp.has("veins"):
		var vm := cl.mat(sp["veins"], "skin")
		for k in 6:
			var a := rng.randf_range(-PI, 0.0)
			var p0 := Vector2(c.x + cos(a) * 0.08 * H, c.y + sin(a) * 0.06 * H)
			var p1 := Vector2(c.x + cos(a) * 0.25 * H, c.y + sin(a) * 0.18 * H)
			cl.ridge(g, [p0, p0.lerp(p1, 0.5) + Vector2(rng.randf_range(-1, 1) * 0.02 * H, 0), p1], 0.008 * H, 0.006 * H, vm)
	return post


## 수호자의 눈: 살덩이 받침 위 큰 눈알 + 늘어진 촉수.
static func eye(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#b89070"))
	var flesh := cl.mat(col, "skin", {"mottle": Color("#7a3a3a"), "mottle_amt": 0.6})
	var white := cl.mat(Color("#e0d8c0"), "eye")
	var c := Vector3(foot.x, foot.y - 0.5 * H, 0.0)
	var gt := cl.group()
	for k in 7:  # 촉수
		var a := lerpf(-0.9, 0.9, k / 6.0)
		var pts: Array = [c + Vector3(sin(a) * 0.15 * H, 0.12 * H, -0.05 * H)]
		var rs: Array = [0.045 * H]
		var cur: Vector3 = pts[0]
		for s in 5:
			cur += Vector3(sin(a) * 0.06 * H + rng.randf_range(-0.03, 0.03) * H, 0.07 * H, rng.randf_range(-0.02, 0.03) * H)
			pts.append(cur)
			rs.append(0.045 * H * (1.0 - (s + 1) / 6.0) + 0.004 * H)
		cl.chain(gt, pts, rs, flesh, 0.01 * H)
	var gf := cl.group()
	cl.ell(gf, c + Vector3(0, 0.02 * H, -0.04 * H), 0.3 * H, 0.27 * H, 0.22 * H, flesh, 0.04 * H)  # 눈두덩
	var g := cl.group()
	cl.ell(g, c + Vector3(0, 0, 0.08 * H), 0.22 * H, 0.22 * H, 0.2 * H, white, 0.0)
	var lids := cl.group()
	cl.cap(lids, c + Vector3(-0.25 * H, -0.12 * H, 0.1 * H), c + Vector3(0.25 * H, -0.12 * H, 0.1 * H), 0.07 * H, 0.07 * H, flesh, 0.03 * H)  # 윗눈꺼풀
	cl.cap(lids, c + Vector3(-0.24 * H, 0.17 * H, 0.08 * H), c + Vector3(0.24 * H, 0.17 * H, 0.08 * H), 0.05 * H, 0.05 * H, flesh, 0.03 * H)
	return {"iris": Vector2(c.x - 0.02 * H, c.y + 0.02 * H), "iris_r": 0.1 * H, "eyeball": c, "j": {"chest": c, "waist": c + Vector3(0, 0.2 * H, 0)}}


## 구더기: 둥글게 몸을 만 하얀 마디 몸 + 작은 머리·턱.
static func maggot(cl: Clay, foot: Vector2, H: float, sp: Dictionary, _rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#d9cfa8"))
	var m := cl.mat(col, "skin", {"mottle": Color("#9a8a60"), "mottle_amt": 0.4, "spec": 0.4})
	var g := cl.group()
	for k in 10:
		var t := k / 9.0
		var a := PI * 0.9 - t * PI * 1.3
		var c := Vector3(foot.x + cos(a) * 0.3 * H, foot.y - 0.22 * H - sin(a) * 0.16 * H, t * 0.12 * H)
		var r := (0.13 - absf(t - 0.4) * 0.12) * H
		cl.ell(g, c, r, r * 0.92, r, m, 0.008 * H)
	var hd := Vector3(foot.x + cos(PI * 0.9 - PI * 1.3) * 0.3 * H, foot.y - 0.22 * H - sin(PI * 0.9 - PI * 1.3) * 0.16 * H, 0.16 * H)
	var dark := cl.mat(Color("#3a2a1a"), "bone")
	for s: float in [-1.0, 1.0]:
		cl.cap(g, hd + Vector3(s * 0.02 * H, 0.03 * H, 0.03 * H), hd + Vector3(s * 0.035 * H, 0.08 * H, 0.04 * H), 0.012 * H, 0.002 * H, dark, 0.002 * H)
	return {"j": {"chest": hd, "waist": hd}}


## 칠한 뒤: 슬라임 속 뼈 그림자·광택 점, 흙더미 눈빛, 수호자 눈의 홍채·핏줄.
static func after(p: Paint, _cl: Clay, post: Dictionary, sp: Dictionary, H: float, rng: RandomNumberGenerator) -> void:
	var ec: Color = sp.get("eyes", Color("#ffcc60"))
	if post.has("slime_c"):
		var c: Vector3 = post["slime_c"]
		var r: float = post["slime_r"]
		for k in int(sp.get("inside", 2)):  # 속에 비친 뼈
			var b := Vector2(c.x + rng.randf_range(-0.5, 0.5) * r, c.y + rng.randf_range(-0.1, 0.35) * r)
			var d := Vector2.from_angle(rng.randf() * TAU) * r * rng.randf_range(0.15, 0.3)
			Ink.line(p, b - d, b + d, r * 0.06, Color(0.1, 0.12, 0.08), 0.35, 0.5)
		for k in 14:  # 기포
			var b := Vector2(c.x + rng.randf_range(-0.7, 0.7) * r, c.y + rng.randf_range(-0.4, 0.3) * r)
			var rr := rng.randf_range(0.01, 0.025) * H
			var ring := PackedVector2Array()
			for i in 11:
				ring.append(b + Vector2.from_angle(TAU * i / 10.0) * rr)
			Ink.path(p, ring, 1.0, false, Color(1, 1, 0.95), 0.35, 0.2)
	for e: Vector2 in post.get("eyes2", []):
		if float(sp.get("glow", 0.0)) > 0.0:
			Ink.glow(p, e.x, e.y, 0.05 * H, ec, 0.9, false)
			for yy in range(int(e.y - 0.008 * H), int(e.y + 0.008 * H) + 1):
				for xx in range(int(e.x - 0.008 * H), int(e.x + 0.008 * H) + 1):
					if Vector2(xx - e.x, yy - e.y).length() < 0.008 * H:
						p.blend(xx, yy, ec.lightened(0.5), 0.9)
		else:
			for yy in range(int(e.y - 0.014 * H), int(e.y + 0.014 * H) + 1):
				for xx in range(int(e.x - 0.012 * H), int(e.x + 0.012 * H) + 1):
					if Vector2((xx - e.x) / 1.0, (yy - e.y) * 0.85).length() < 0.012 * H:
						p.blend(xx, yy, Color("#0e0806"), 0.85)
	if post.has("iris"):
		var ic: Vector2 = post["iris"]
		var ir: float = post["iris_r"]
		var eb: Vector3 = post["eyeball"]
		for k in 22:  # 핏줄
			var a := rng.randf() * TAU
			var p0 := Vector2(eb.x, eb.y) + Vector2.from_angle(a) * 0.21 * H
			var p1 := p0.lerp(ic, rng.randf_range(0.3, 0.6)) + Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.02 * H
			Ink.line(p, p0, p1, maxf(1.0, H / 400.0), Color("#8a1a14"), 0.55, 1.5)
		var iris_c: Color = sp.get("iris", Color("#c8a030"))
		for yy in range(int(ic.y - ir), int(ic.y + ir) + 1):
			for xx in range(int(ic.x - ir), int(ic.x + ir) + 1):
				var d := Vector2(xx - ic.x, yy - ic.y).length() / ir
				if d < 1.0 and p.alpha_at(xx, yy) > 0.5:
					var col := iris_c.darkened(0.35 * d + 0.15 * p.nz("hi", xx, yy))
					if d < 0.42:
						col = Color("#0a0606")
					p.blend(xx, yy, col, 0.95)
		Ink.glow(p, ic.x, ic.y, ir * 1.4, iris_c, 0.45, false)
		var ring := PackedVector2Array()
		for i in 25:
			ring.append(ic + Vector2.from_angle(TAU * i / 24.0) * ir)
		Ink.path(p, ring, maxf(1.5, H / 250.0), false, Ink.INK, 0.9, 0.3)
		for yy in range(int(ic.y - ir * 0.6), int(ic.y - ir * 0.3)):
			for xx in range(int(ic.x - ir * 0.55), int(ic.x - ir * 0.25)):
				p.blend(xx, yy, Color(1, 1, 0.95), 0.5 * clampf(1.0 - Vector2(xx - (ic.x - ir * 0.4), yy - (ic.y - ir * 0.45)).length() / (ir * 0.15), 0.0, 1.0))
	if post.has("mouth2") and float(sp.get("glow", 0.0)) > 0.0:
		var m: Vector2 = post["mouth2"]
		Ink.glow(p, m.x, m.y, 0.05 * H, ec, 0.4, false)
