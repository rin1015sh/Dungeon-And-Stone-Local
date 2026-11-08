extends RefCounted
## 2층 새 몬스터의 몸(Clay — docs/plans/floor2_monsters.md): vine(가시넝쿨) · swarm(박쥐 · 까마귀 떼) · scorpion(사막 전갈) · bird(사막 독수리).
## 공통 spec 키: height · color · eyes · glow. swarm: count(마리 수) · beak(true면 까마귀 — 부리 · 깃 날개, 없으면 박쥐 막 날개) · insect(말벌 — 침).
## shroom(포자 버섯): cap(갓 색) · spots(점 색).
## 눈은 Things2.after가 eyes2 목록으로 찍는다(glow > 0이면 빛나는 눈).

const Clay := preload("res://tools/monster_art/Clay.gd")


## 가시넝쿨: 땅에서 솟은 굵은 덩굴 여럿이 가운데 봉오리를 감싸고, 줄기마다 가시 · 끝이 앞으로 휜다.
static func vine(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#4a6a3a"))
	var bark := cl.mat(col, "wood", {"mottle": col.darkened(0.35), "mottle_amt": 0.5})
	var thorn := cl.mat(Color("#c8b890"), "bone")
	var bud := cl.mat(sp.get("bud", Color("#7a2a3a")), "skin", {"mottle": Color("#3a1a20"), "mottle_amt": 0.5})
	var g_back := cl.group()
	var c := Vector3(foot.x, foot.y - 0.42 * H, 0.0)
	for k in 7:  # 덩굴: 뿌리 → 휘어 오르다 끝이 앞으로
		var a := lerpf(-1.1, 1.1, k / 6.0) + rng.randf_range(-0.12, 0.12)
		var root := Vector3(foot.x + sin(a) * 0.3 * H, foot.y - 0.02 * H, rng.randf_range(-0.06, 0.04) * H)
		var mid := Vector3(foot.x + sin(a) * 0.4 * H, foot.y - rng.randf_range(0.35, 0.6) * H, rng.randf_range(-0.04, 0.06) * H)
		var tip := Vector3(foot.x + sin(a) * rng.randf_range(0.18, 0.3) * H, foot.y - rng.randf_range(0.62, 0.86) * H, 0.12 * H)
		var g := g_back if absf(a) > 0.6 else cl.group()
		var pts: Array = [root, root.lerp(mid, 0.5) + Vector3(sin(a) * 0.04 * H, 0, 0), mid, mid.lerp(tip, 0.6), tip]
		cl.chain(g, pts, [0.05 * H, 0.045 * H, 0.038 * H, 0.025 * H, 0.008 * H], bark, 0.012 * H)
		for t in 6:  # 가시
			var q: Vector3 = (pts[t % 4] as Vector3).lerp(pts[t % 4 + 1], rng.randf())
			var out := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 0.3), rng.randf_range(0.2, 1)).normalized()
			cl.cap(g, q, q + out * 0.04 * H, 0.008 * H, 0.0015 * H, thorn, 0.002 * H)
	var gb := cl.group()  # 가운데 봉오리(입처럼 벌어진 틈)
	cl.ell(gb, c + Vector3(0, 0.06 * H, 0.05 * H), 0.13 * H, 0.15 * H, 0.11 * H, bud, 0.03 * H)
	cl.carve(gb, Vector2(c.x, c.y + 0.07 * H), 0.07 * H, 0.025 * H, 0.04 * H)
	for s: float in [-1.0, 1.0]:  # 봉오리를 감싼 잎
		cl.ell(gb, c + Vector3(s * 0.1 * H, 0.1 * H, 0.08 * H), 0.07 * H, 0.12 * H, 0.03 * H, bark, 0.02 * H)
	var gr := cl.group()  # 밑동 흙
	cl.ell(gr, Vector3(foot.x, foot.y - 0.02 * H, 0), 0.34 * H, 0.04 * H, 0.12 * H, cl.mat(Color("#3a3024"), "stone"), 0.02 * H)
	return {"eyes2": [Vector2(c.x - 0.04 * H, c.y + 0.03 * H), Vector2(c.x + 0.04 * H, c.y + 0.03 * H)], "mouth2": Vector2(c.x, c.y + 0.07 * H),
		"j": {"chest": c, "waist": c + Vector3(0, 0.2 * H, 0)}}


## 떼: 작은 몸 여럿(박쥐 막 날개 · 까마귀 깃 날개)이 엉켜 공중에 뭉쳐 있다.
static func swarm(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#3a3036"))
	var crow := bool(sp.get("beak", false))
	var body := cl.mat(col, "fur" if not crow else "leather", {"mottle": col.darkened(0.4), "mottle_amt": 0.3})
	var wing := cl.mat(col.darkened(0.15), "leather")
	var beak := cl.mat(Color("#2a2420"), "bone")
	var eyes: Array = []
	var n := int(sp.get("count", 7))
	var c := Vector2(foot.x, foot.y - 0.5 * H)
	for k in n:
		var a := TAU * k / n + rng.randf_range(-0.3, 0.3)
		var r := (0.12 + 0.18 * float(k % 3) / 2.0) * H
		var p := Vector3(c.x + cos(a) * r * 1.2, c.y + sin(a) * r * 0.8, rng.randf_range(-0.1, 0.12) * H)
		var s := rng.randf_range(0.75, 1.15)
		var g := cl.group()
		cl.ell(g, p, 0.04 * H * s, 0.05 * H * s, 0.04 * H * s, body, 0.01 * H)  # 몸
		var hd := p + Vector3(0, -0.05 * H * s, 0.02 * H)
		cl.ell(g, hd, 0.028 * H * s, 0.026 * H * s, 0.028 * H * s, body, 0.008 * H)
		if crow:
			cl.cap(g, hd + Vector3(0, 0.005 * H, 0.02 * H * s), hd + Vector3(rng.randf_range(-0.01, 0.01) * H, 0.02 * H, 0.06 * H * s), 0.01 * H * s, 0.002 * H, beak, 0.002 * H)
		elif bool(sp.get("insect", false)):  # 말벌: 귀 대신 배 끝 침
			cl.cap(g, p + Vector3(0, 0.04 * H * s, -0.01 * H), p + Vector3(0, 0.08 * H * s, 0.0), 0.012 * H * s, 0.002 * H, beak, 0.002 * H)
		else:
			for e: float in [-1.0, 1.0]:  # 박쥐 귀
				cl.cap(g, hd + Vector3(e * 0.015 * H * s, -0.015 * H * s, 0), hd + Vector3(e * 0.025 * H * s, -0.05 * H * s, 0), 0.01 * H * s, 0.002 * H, body, 0.002 * H)
		eyes.append(Vector2(hd.x - 0.01 * H * s, hd.y))
		eyes.append(Vector2(hd.x + 0.01 * H * s, hd.y))
		var flap := rng.randf_range(-0.5, 0.6)
		for e: float in [-1.0, 1.0]:  # 날개 — 펼친 판(두 마디)
			var w0 := p + Vector3(e * 0.03 * H * s, -0.01 * H, 0)
			var w1 := w0 + Vector3(e * 0.09 * H * s, (-0.05 + flap * 0.06) * H * s, -0.01 * H)
			var w2 := w1 + Vector3(e * 0.07 * H * s, (0.04 + flap * 0.03) * H * s, -0.01 * H)
			cl.chain(g, [w0, w1, w2], [0.02 * H * s, 0.028 * H * s, 0.006 * H * s], wing, 0.006 * H)
			cl.ell(g, w0.lerp(w2, 0.5) + Vector3(0, 0.02 * H * s, -0.005 * H), 0.07 * H * s, 0.03 * H * s, 0.006 * H, wing, 0.006 * H)
	return {"eyes2": eyes, "j": {"chest": Vector3(c.x, c.y, 0), "waist": Vector3(c.x, c.y + 0.2 * H, 0)}}


## 사막 전갈(정면 · 조금 위에서): 낮은 마디 몸, 앞으로 벌린 큰 집게, 다리 여덟, 등 위로 휘어 넘어온 꼬리와 독침.
static func scorpion(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#8a6a40"))
	var shell := cl.mat(col, "bone", {"mottle": col.darkened(0.35), "mottle_amt": 0.4, "spec": 0.4})
	var dark := cl.mat(col.darkened(0.45), "bone")
	var sting := cl.mat(Color("#2a1a12"), "bone")
	var c := Vector3(foot.x, foot.y - 0.16 * H, 0.0)
	var g_tail := cl.group()
	var tail: Array = []
	for k in 9:  # 꼬리: 몸 뒤에서 옆으로 둥글게 솟아 머리 위로 넘어온다(3/4에서 본 활 모양)
		var t := k / 8.0
		var a := t * PI * 1.05
		tail.append(Vector3(foot.x + 0.06 * H + sin(a) * 0.24 * H - t * 0.16 * H, c.y - 0.02 * H - (1.0 - cos(a)) * 0.27 * H, -0.18 * H + t * 0.26 * H))
	for k in tail.size() - 1:
		var r := lerpf(0.075, 0.04, k / 8.0) * H
		cl.cap(g_tail, tail[k], tail[k + 1], r, r * 0.92, shell, 0.006 * H)
		cl.ell(g_tail, (tail[k] as Vector3).lerp(tail[k + 1], 0.5), r * 1.12, r * 1.0, r * 0.8, shell, 0.008 * H)
	var tip: Vector3 = tail[8]
	cl.ell(g_tail, tip + Vector3(0, 0.03 * H, 0.02 * H), 0.055 * H, 0.05 * H, 0.05 * H, dark, 0.01 * H)
	cl.cap(g_tail, tip + Vector3(-0.01 * H, 0.06 * H, 0.04 * H), tip + Vector3(-0.04 * H, 0.14 * H, 0.08 * H), 0.022 * H, 0.002 * H, sting, 0.003 * H)
	var g_leg := cl.group()
	for s: float in [-1.0, 1.0]:  # 다리 넷씩
		for k in 4:
			var hip := c + Vector3(s * 0.16 * H, 0.02 * H, (0.06 - k * 0.06) * H)
			var knee := hip + Vector3(s * 0.15 * H, -0.07 * H, (0.02 - k * 0.02) * H)
			var toe := knee + Vector3(s * 0.08 * H, 0.15 * H, 0.0)
			cl.chain(g_leg, [hip, knee, toe], [0.022 * H, 0.016 * H, 0.006 * H], dark, 0.004 * H)
	var g := cl.group()
	for k in 4:  # 몸 마디(앞이 크다)
		cl.ell(g, c + Vector3(0, -0.02 * H - k * 0.012 * H, (0.05 - k * 0.07) * H), (0.22 - k * 0.025) * H, 0.09 * H, 0.08 * H, shell, 0.012 * H)
	var head := c + Vector3(0, 0.01 * H, 0.13 * H)
	cl.ell(g, head, 0.14 * H, 0.075 * H, 0.07 * H, shell, 0.012 * H)
	var g_claw := cl.group()
	for s: float in [-1.0, 1.0]:  # 집게팔
		var sh := head + Vector3(s * 0.1 * H, 0.01 * H, 0.0)
		var el := sh + Vector3(s * 0.17 * H, -0.06 * H, 0.08 * H)
		var wr := el + Vector3(-s * 0.04 * H, -0.05 * H, 0.1 * H)
		cl.chain(g_claw, [sh, el, wr], [0.035 * H, 0.04 * H, 0.05 * H], shell, 0.006 * H)
		cl.ell(g_claw, wr + Vector3(0, -0.01 * H, 0.04 * H), 0.08 * H, 0.06 * H, 0.08 * H, shell, 0.01 * H)
		cl.cap(g_claw, wr + Vector3(s * 0.02 * H, -0.02 * H, 0.09 * H), wr + Vector3(-s * 0.02 * H, -0.04 * H, 0.16 * H), 0.025 * H, 0.004 * H, dark, 0.004 * H)
		cl.cap(g_claw, wr + Vector3(s * 0.03 * H, 0.01 * H, 0.09 * H), wr + Vector3(-s * 0.01 * H, 0.0, 0.15 * H), 0.018 * H, 0.003 * H, dark, 0.004 * H)
	return {"eyes2": [Vector2(head.x - 0.025 * H, head.y - 0.02 * H), Vector2(head.x + 0.025 * H, head.y - 0.02 * H)],
		"j": {"chest": head, "waist": c}}


## 사막 독수리(앉은 정면): 접은 날개로 감싼 몸, 털 없는 긴 목, 굽은 부리, 깃털 목도리.
static func bird(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#5a4a3a"))
	var feather := cl.mat(col, "fur", {"mottle": col.darkened(0.35), "mottle_amt": 0.4})
	var ruff := cl.mat(sp.get("ruff", Color("#c8b8a0")), "fur")
	var skin := cl.mat(sp.get("skin", Color("#b07a6a")), "skin")
	var beak := cl.mat(Color("#d8c8a0"), "bone")
	var talon := cl.mat(Color("#3a3028"), "bone")
	var gl := cl.group()
	for s: float in [-1.0, 1.0]:  # 다리 · 발톱
		var hip := Vector3(foot.x + s * 0.07 * H, foot.y - 0.14 * H, 0.04 * H)
		var ft := Vector3(foot.x + s * 0.08 * H, foot.y - 0.01 * H, 0.06 * H)
		cl.cap(gl, hip, ft, 0.02 * H, 0.015 * H, skin, 0.004 * H)
		for f in 3:
			cl.cap(gl, ft, ft + Vector3((f - 1) * 0.03 * H, 0.01 * H, 0.04 * H), 0.008 * H, 0.002 * H, talon, 0.002 * H)
	var g := cl.group()
	var c := Vector3(foot.x, foot.y - 0.34 * H, 0.0)
	cl.ell(g, c, 0.17 * H, 0.22 * H, 0.14 * H, feather, 0.03 * H)  # 몸
	var gw := cl.group()
	for s: float in [-1.0, 1.0]:  # 접은 날개(몸 앞쪽으로 감싸 아래로 늘어진다)
		cl.ell(gw, c + Vector3(s * 0.15 * H, 0.03 * H, 0.04 * H), 0.08 * H, 0.24 * H, 0.06 * H, feather, 0.02 * H)
		for k in 4:  # 깃 끝
			var q := c + Vector3(s * (0.13 + k * 0.015) * H, (0.22 + k * 0.015) * H, 0.05 * H)
			cl.cap(gw, q, q + Vector3(s * 0.01 * H, 0.06 * H, 0.0), 0.02 * H, 0.006 * H, feather, 0.004 * H)
	var gr := cl.group()
	cl.ell(gr, c + Vector3(0, -0.17 * H, 0.04 * H), 0.12 * H, 0.06 * H, 0.1 * H, ruff, 0.02 * H)  # 깃털 목도리
	var gn := cl.group()
	var neck0 := c + Vector3(0, -0.18 * H, 0.06 * H)
	var hd := c + Vector3(0.0, -0.33 * H, 0.1 * H)
	cl.chain(gn, [neck0, neck0.lerp(hd, 0.5) + Vector3(0, 0, 0.02 * H), hd], [0.04 * H, 0.03 * H, 0.04 * H], skin, 0.008 * H)
	cl.ell(gn, hd, 0.05 * H, 0.045 * H, 0.05 * H, skin, 0.01 * H)
	cl.chain(gn, [hd + Vector3(0, 0.0, 0.04 * H), hd + Vector3(0, 0.01 * H, 0.09 * H), hd + Vector3(0, 0.05 * H, 0.1 * H)],
		[0.02 * H, 0.014 * H, 0.004 * H], beak, 0.003 * H)
	return {"eyes2": [Vector2(hd.x - 0.025 * H, hd.y - 0.008 * H), Vector2(hd.x + 0.025 * H, hd.y - 0.008 * H)],
		"j": {"chest": c + Vector3(0, -0.1 * H, 0), "waist": c}}


## 포자 버섯: 굵은 대 위 넓은 갓(점박이), 대에 파인 눈 · 입, 밑동 뿌리.
static func shroom(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var stalk := cl.mat(sp.get("color", Color("#c8b8a0")), "skin", {"mottle": Color("#8a7a68"), "mottle_amt": 0.4})
	var capc: Color = sp.get("cap", Color("#a04a5a"))
	var cap := cl.mat(capc, "skin", {"mottle": capc.darkened(0.4), "mottle_amt": 0.5, "spec": 0.3})
	var spot := cl.mat(sp.get("spots", Color("#e8dcc0")), "bone")
	var g := cl.group()
	var base := Vector3(foot.x, foot.y - 0.05 * H, 0.0)
	cl.cap(g, base, base + Vector3(0, -0.45 * H, 0.0), 0.13 * H, 0.1 * H, stalk, 0.03 * H)
	for k in 5:  # 밑동 뿌리
		var a := lerpf(-1.2, 1.2, k / 4.0)
		cl.cap(g, base + Vector3(sin(a) * 0.08 * H, 0, 0.02 * H), base + Vector3(sin(a) * 0.2 * H, 0.04 * H, 0.04 * H), 0.03 * H, 0.008 * H, stalk, 0.01 * H)
	var c := Vector3(foot.x, foot.y - 0.25 * H, 0.0)
	for s2: float in [-1.0, 1.0]:
		cl.carve(g, Vector2(c.x + s2 * 0.045 * H, c.y - 0.02 * H), 0.025 * H, 0.02 * H, 0.03 * H)
	cl.carve(g, Vector2(c.x, c.y + 0.06 * H), 0.05 * H, 0.016 * H, 0.03 * H)
	var gc := cl.group()
	var top := Vector3(foot.x, foot.y - 0.56 * H, 0.0)
	cl.ell(gc, top, 0.36 * H, 0.17 * H, 0.26 * H, cap, 0.04 * H)
	for k in 11:  # 갓 점
		var a := rng.randf_range(-PI, 0.0)
		var rr := rng.randf_range(0.2, 0.85)
		var q := Vector2(top.x + cos(a) * 0.3 * H * rr, top.y + sin(a) * 0.13 * H * rr)
		cl.bump(gc, q, rng.randf_range(0.02, 0.035) * H, rng.randf_range(0.015, 0.025) * H, 0.01 * H, spot, 0.004 * H, 0.0)
	return {"eyes2": [Vector2(c.x - 0.045 * H, c.y - 0.02 * H), Vector2(c.x + 0.045 * H, c.y - 0.02 * H)], "mouth2": Vector2(c.x, c.y + 0.06 * H),
		"j": {"chest": c, "waist": base}}
