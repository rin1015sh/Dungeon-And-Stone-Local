extends RefCounted
## 짐승 머리(Clay, 3/4 시점 — 주둥이가 FWD 쪽): wolf(늑대 — 으르렁 벌린 입) · cat(검치호 — 긴 송곳니) · owl(올빼미곰 — 둥근 얼굴판·부리) · rat(해골쥐 — 뼈 머리)
## 돌려주는 값: {"eyes": [Vector2…], "eye_r", "type"} — ink()가 눈을 그린다.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

static var FWD := Vector3(-0.3, 0.12, 0.95)  ## 머리는 몸보다 더 보는 사람 쪽(정면에 가깝게), 살짝 숙임 — Beast가 aim()으로 몸 방향에 맞춘다
static var SIDE := Vector3(0.95, 0.0, 0.3)


## 몸 앞쪽(Beast.FWD)에 맞춰 머리 방향을 정한다. 전투 그림 방향이면 원래 값(보는 사람 쪽으로 더 돌림).
static func aim(body_fwd: Vector3) -> void:
	if body_fwd.is_equal_approx(Vector3(-0.45, 0.0, 0.89)):
		FWD = Vector3(-0.3, 0.12, 0.95)
		SIDE = Vector3(0.95, 0.0, 0.3)
		return
	FWD = (body_fwd + Vector3(0, 0.12, 0)).normalized()
	SIDE = Vector3(body_fwd.z, 0.0, -body_fwd.x)
const UP := Vector3(0, -1, 0)


static func head(cl: Clay, g: int, c: Vector3, L: float, type: String, sp: Dictionary, skin: int, rng: RandomNumberGenerator) -> Dictionary:
	var bone := cl.mat(sp.get("bone", Color("#d8ccb0")), "bone")
	var dark := cl.mat(Color("#1a0c0a"), "glow")
	var nose := cl.mat(Color("#2a2220"), "leather")
	var eye_m := cl.mat(sp.get("eyes", Color("#d8b040")), "eye")
	var out := {"eyes": [], "eye_r": 0.012 * L, "type": type}
	var P := func(f: float, s: float, u: float) -> Vector3: return c + FWD * f * L + SIDE * s * L + UP * u * L
	match type:
		"owl":
			cl.ell(g, c, 0.11 * L, 0.1 * L, 0.1 * L, skin, 0.03 * L)
			var fc: Vector3 = P.call(0.07, 0.0, -0.005)
			cl.ell(g, fc, 0.085 * L, 0.075 * L, 0.04 * L, cl.mat(sp.get("belly", Color("#c8b898")), "fur"), 0.02 * L)
			for s: float in [-1.0, 1.0]:
				var e: Vector3 = P.call(0.1, s * 0.04, 0.012)
				cl.carve(g, Vector2(e.x, e.y), 0.032 * L, 0.03 * L, 0.03 * L)
				cl.ell(g, e + Vector3(0, 0, -0.005 * L), 0.022 * L, 0.022 * L, 0.012 * L, eye_m, 0.5)
				out["eyes"].append(Vector2(e.x, e.y))
				var t0: Vector3 = P.call(0.02, s * 0.06, 0.08)
				cl.cap(g, t0, t0 + UP * 0.07 * L + SIDE * s * 0.02 * L, 0.025 * L, 0.004 * L, skin, 0.01 * L)  # 귀깃
			var bk: Vector3 = P.call(0.15, 0.0, -0.025)
			cl.chain(g, [P.call(0.12, 0.0, 0.0), bk, bk + UP * -0.035 * L + FWD * 0.005 * L], [0.018 * L, 0.014 * L, 0.003 * L], cl.mat(Color("#3a3228"), "bone"), 0.005 * L)
			out["eye_r"] = 0.02 * L
		"rat":
			cl.ell(g, c, 0.06 * L, 0.05 * L, 0.06 * L, bone, 0.02 * L)
			cl.cap(g, P.call(0.03, 0.0, -0.005), P.call(0.16, 0.0, -0.03), 0.042 * L, 0.012 * L, bone, 0.02 * L)
			for s: float in [-1.0, 1.0]:
				var e: Vector3 = P.call(0.05, s * 0.028, 0.01)
				cl.carve(g, Vector2(e.x, e.y), 0.016 * L, 0.014 * L, 0.03 * L)
				out["eyes"].append(Vector2(e.x, e.y))
				var ear: Vector3 = P.call(-0.02, s * 0.045, 0.05)
				cl.ell(g, ear, 0.03 * L, 0.035 * L, 0.012 * L, cl.mat(Color("#b08880"), "skin"), 0.005 * L)
			var tip: Vector3 = P.call(0.16, 0.0, -0.035)
			cl.cap(g, tip, tip + UP * -0.03 * L, 0.008 * L, 0.006 * L, cl.mat(Color("#d8c890"), "bone"), 0.002 * L)  # 앞니
			cl.groove(g, Vector2(P.call(0.06, 0.0, -0.02).x, P.call(0.06, 0.0, -0.02).y), Vector2(tip.x, tip.y), 0.003 * L, 0.004 * L)
			out["eye_r"] = 0.01 * L
			out["sockets"] = true
		_:  # wolf · cat
			var cat := type == "cat"
			var base: Color = cl.mats[skin]["c"]
			var face := cl.mat(sp.get("muzzle", base.darkened(0.08)), "skin", {"hatch": 0.6})
			cl.ell(g, c, 0.075 * L, 0.066 * L, 0.075 * L, skin, 0.03 * L)
			var m0: Vector3 = P.call(0.05, 0.0, -0.015)
			var m1: Vector3 = P.call(0.1 if cat else 0.15, 0.0, -0.03 if cat else -0.035)
			cl.cap(g, m0, m1, 0.05 * L, 0.034 * L if cat else 0.03 * L, face, 0.02 * L)  # 주둥이
			cl.ell(g, m1 + FWD * 0.01 * L + UP * 0.006 * L, 0.018 * L, 0.014 * L, 0.016 * L, nose, 0.005 * L)  # 코
			var snarl := str(sp.get("mouth", "snarl")) == "snarl"
			var j0: Vector3 = P.call(0.03, 0.0, -0.05)
			var j1: Vector3 = m1 + UP * (-0.045 if snarl else -0.02) * L - FWD * 0.015 * L
			cl.cap(g, j0, j1, 0.032 * L, 0.02 * L, face, 0.01 * L)  # 아래턱
			if snarl:
				var mo := m0.lerp(m1, 0.6) + UP * -0.034 * L
				cl.ell(g, mo, 0.045 * L, 0.014 * L, 0.03 * L, dark, 0.0)  # 벌린 입속
				for k in 5:
					var t := 0.25 + k * 0.17
					var top := m0.lerp(m1, t) + UP * -0.024 * L + SIDE * 0.005 * L
					var ln := (0.035 if (k == 4 and not cat) else 0.016) * L
					cl.cap(g, top, top + UP * -ln, 0.006 * L, 0.0015 * L, bone, 0.002 * L)
					var bot := j0.lerp(j1, t + 0.05) + UP * 0.012 * L + SIDE * 0.005 * L
					cl.cap(g, bot, bot + UP * 0.014 * L, 0.005 * L, 0.0015 * L, bone, 0.002 * L)
				for k in 3:  # 콧등 주름
					var a := m0.lerp(m1, 0.2 + k * 0.18) + UP * 0.03 * L
					cl.groove(g, Vector2(a.x, a.y), Vector2(a.x + 0.006 * L, a.y + 0.012 * L), 0.004 * L, 0.006 * L)
			if cat:
				for s: float in [-1.0, 1.0]:  # 검치
					var b: Vector3 = P.call(0.095, s * 0.022, -0.04)
					cl.cap(g, b, b + UP * -float(sp.get("fangs", 0.14)) * L + FWD * 0.015 * L, 0.013 * L, 0.002 * L, bone, 0.002 * L)
			for s: float in [-1.0, 1.0]:
				var e: Vector3 = P.call(0.06, s * 0.032, 0.018)
				cl.carve(g, Vector2(e.x, e.y), 0.016 * L, 0.01 * L, 0.02 * L, -0.35 * s)
				cl.ell(g, e + FWD * -0.004 * L, 0.009 * L, 0.0065 * L, 0.01 * L, eye_m, 0.5, -0.35 * s)
				if (FWD + SIDE * s * 0.7).z > 0.05:  # 보는 사람 쪽 눈만(뒷모습·먼 쪽 눈은 머리에 가린다)
					out["eyes"].append(Vector2(e.x, e.y))
				var eb: Vector3 = P.call(0.035, s * 0.035, 0.035)
				cl.cap(g, eb + SIDE * -s * 0.01 * L, eb + SIDE * s * 0.02 * L + UP * -0.008 * L, 0.012 * L, 0.009 * L, skin, 0.008 * L)  # 찌푸린 눈썹뼈
				var ear: Vector3 = P.call(-0.025, s * 0.045, 0.06)
				var et := ear + UP * (0.045 if cat else 0.085) * L - FWD * 0.02 * L + SIDE * s * 0.01 * L
				var poly := PackedVector2Array([Vector2(ear.x - 0.03 * L, ear.y + 0.01 * L), Vector2(et.x, et.y), Vector2(ear.x + 0.03 * L, ear.y + 0.01 * L)])
				cl.slab(g, poly, ear.z - 0.01 * L, 0.012 * L, skin, 0.005 * L, 0.012 * L)
			if sp.has("horns"):
				var hm := cl.mat(sp["horns"], "bone")
				for s: float in [-1.0, 1.0]:
					var b: Vector3 = P.call(0.0, s * 0.035, 0.06)
					cl.chain(g, [b, b + UP * 0.06 * L - FWD * 0.04 * L, b + UP * 0.08 * L - FWD * 0.11 * L + UP * -0.02 * L], [0.016 * L, 0.01 * L, 0.002 * L], hm, 0.005 * L)
			out["eye_r"] = 0.0075 * L
	return out


## 눈: 노란 홍채 + 동공(고양이 눈은 세로) + 반짝임. 해골쥐는 빈 눈구멍에 작은 불씨.
static func ink(p: Paint, info: Dictionary, sp: Dictionary) -> void:
	var er: float = info["eye_r"]
	var ec: Color = sp.get("eyes", Color("#d8b040"))
	var glow := float(sp.get("glow", 0.0))
	for e: Vector2 in info["eyes"]:
		if info.get("sockets", false):
			Ink.glow(p, e.x, e.y, er * 2.5, ec, 0.9, false)
			_dot(p, e, er * 0.35, ec.lightened(0.4), 0.95)
			continue
		_dot(p, e, er * 0.95, ec, 0.95)
		if str(info["type"]) == "cat":
			for y in range(int(e.y - er * 0.9), int(e.y + er * 0.9) + 1):
				_dot(p, Vector2(e.x, y), er * 0.18, Color("#100806"), 0.9)
		else:
			_dot(p, e, er * 0.45, Color("#100806"), 0.95)
		_dot(p, e + Vector2(-er * 0.3, -er * 0.35), maxf(0.8, er * 0.2), Color(1, 1, 0.9), 0.8)
		var ring := PackedVector2Array()
		for k in 13:
			var a := TAU * k / 12.0
			ring.append(e + Vector2(cos(a), sin(a)) * er)
		Ink.path(p, ring, maxf(1.0, er * 0.25), false, Ink.INK, 0.85, 0.2)
		if glow > 0.0:
			Ink.glow(p, e.x, e.y, er * 3.5, ec, glow * 0.7, false)


static func _dot(p: Paint, c: Vector2, r: float, col: Color, a: float) -> void:
	for yy in range(int(c.y - r - 1), int(c.y + r + 1) + 1):
		for xx in range(int(c.x - r - 1), int(c.x + r + 1) + 1):
			var cov := clampf(r - Vector2(xx + 0.5 - c.x, yy + 0.5 - c.y).length() + 0.5, 0.0, 1.0)
			if cov > 0.0 and p.alpha_at(xx, yy) > 0.3:
				p.blend(xx, yy, col, cov * a)
