extends RefCounted
## 무기·방패(Clay): 쥔 손(hand_<l|r>) 자리에서 무기 축을 따라 자루·날·머리를 빚는다.
## kit 키: weapon(sword|greatsword|dagger|axe|cleaver|club|spear|lance|pick|staff|bow|bomb|torch) · weapon_c(쇠 색) · wood(자루 색)
##         weapon_hand(l|r, 기본 l) · weapon_angle(도, 0 = 아래로 · 180 = 위로, 바깥쪽이 +) · glow(지팡이 구슬 빛) · shield(색) · shield_kind(round|kite)
## 돌려주는 값: {"glows": [[위치, 반지름, 색]…], "lines": [[a, b, 굵기, 색]…]} — 칠한 뒤 Figure가 빛·활시위를 그린다.

const Clay := preload("res://tools/monster_art/Clay.gd")


static func arm(cl: Clay, j: Dictionary, H: float, kit: Dictionary, pose: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var out := {"glows": [], "lines": []}
	var wpn := str(kit.get("weapon", ""))
	if wpn != "":
		var tag := str(kit.get("weapon_hand", "l"))
		var s := -1.0 if tag == "l" else 1.0
		var grip: Vector3 = j["hand_" + tag]
		var raised := str(pose.get("arm_" + tag, "hang")) == "raise"
		var def_ang := 160.0 if raised else 28.0
		if wpn in ["spear", "lance", "staff"]:
			def_ang = 172.0
		var ang := deg_to_rad(float(kit.get("weapon_angle", def_ang)))
		var u := Vector3(sin(ang) * s, cos(ang), 0.08 if not raised else -0.1).normalized()
		_weapon(cl, wpn, grip, u, s, H, kit, out, rng)
	if kit.has("shield"):
		_shield(cl, j, H, kit)
	return out


static func _weapon(cl: Clay, wpn: String, grip: Vector3, u: Vector3, s: float, H: float, kit: Dictionary, out: Dictionary, rng: RandomNumberGenerator) -> void:
	var g := cl.group()
	var steel := cl.mat(kit.get("weapon_c", Color("#8a8a86")), "metal")
	var wood := cl.mat(kit.get("wood", Color("#5a4030")), "wood")
	var u2 := Vector2(u.x, u.y).normalized()
	var n2 := Vector2(-u2.y, u2.x)
	if n2.x * s < 0.0:
		n2 = -n2  # n2 = 바깥쪽
	var z := grip.z - 0.004 * H
	var P := func(along: float, side: float) -> Vector2: return Vector2(grip.x, grip.y) + u2 * along * H + n2 * side * H
	var V := func(along: float, side: float, dz: float = 0.0) -> Vector3:
		var q: Vector2 = P.call(along, side)
		return Vector3(q.x, q.y, z + dz * H + u.z * along * H)
	match wpn:
		"sword", "greatsword", "dagger":
			var big := wpn == "greatsword"
			var ln := 0.56 if big else (0.15 if wpn == "dagger" else 0.38)
			var bw := 0.024 if big else (0.013 if wpn == "dagger" else 0.017)
			cl.cap(g, V.call(-0.05, 0.0), V.call(0.035, 0.0), 0.009 * H, 0.009 * H, wood, 1.0)
			cl.ell(g, V.call(-0.055, 0.0), 0.012 * H, 0.012 * H, 0.012 * H, steel, 1.0)
			cl.cap(g, V.call(0.04, -0.045 if big else -0.035), V.call(0.04, 0.045 if big else 0.035), 0.008 * H, 0.008 * H, steel, 1.0)
			var blade := PackedVector2Array([P.call(0.05, -bw), P.call(0.05, bw), P.call(ln * 0.85, bw * 0.9), P.call(ln + 0.04, 0.0), P.call(ln * 0.85, -bw * 0.9)])
			var bz: Vector3 = V.call(0.05, 0.0)
			cl.slab(g, blade, bz.z, 0.006 * H, steel, 1.0, bw * H * 0.7, Vector2(u.z * u2.x, u.z * u2.y) * 0.0)
			cl.groove(g, P.call(0.07, 0.0), P.call(ln * 0.7, 0.0), bw * H * 0.25, 0.003 * H)
		"axe", "cleaver":
			var cleaver := wpn == "cleaver"
			var hl := 0.1 if cleaver else 0.3
			cl.cap(g, V.call(-0.05, 0.0), V.call(hl, 0.0), 0.011 * H, 0.01 * H, wood, 1.0)
			var blade: PackedVector2Array
			if cleaver:
				blade = PackedVector2Array([P.call(0.06, -0.02), P.call(0.06, 0.08), P.call(0.33, 0.1), P.call(0.36, 0.02), P.call(0.34, -0.02)])
			else:
				blade = PackedVector2Array([P.call(hl - 0.07, 0.0), P.call(hl - 0.1, 0.07), P.call(hl - 0.04, 0.12), P.call(hl + 0.05, 0.12), P.call(hl + 0.06, 0.06), P.call(hl + 0.01, 0.0)])
			var bz: Vector3 = V.call(hl, 0.0)
			cl.slab(g, blade, bz.z, 0.007 * H, steel, 1.0, 0.025 * H)
			if cleaver:
				for k in 3:  # 이 빠진 날
					cl.erase(g, P.call(0.12 + k * 0.08 + rng.randf() * 0.03, 0.1), 0.008 * H, 0.012 * H, 0.4)
				cl.carve(g, P.call(0.09, 0.0), 0.009 * H, 0.009 * H, 0.01 * H)
		"club":
			cl.cap(g, V.call(-0.05, 0.0), V.call(0.36, 0.0), 0.012 * H, 0.032 * H, wood, 1.0)
			var spk := cl.mat(Color("#6e6660"), "metal")
			for k in 14:
				var along := 0.14 + k * 0.016
				var side := (1.0 if k % 2 == 0 else -1.0) * (0.024 + along * 0.02)
				var base: Vector3 = V.call(along, side * 0.7)
				var tip: Vector3 = V.call(along + 0.012, side * 1.6, 0.01 * (1 if k % 3 == 0 else -1))
				cl.cap(g, base, tip, 0.006 * H, 0.0015 * H, spk, 0.5)
		"spear", "lance":
			cl.cap(g, V.call(-0.3, 0.0), V.call(0.5, 0.0), 0.009 * H, 0.008 * H, wood, 1.0)
			if wpn == "lance":
				cl.cap(g, V.call(0.42, 0.0), V.call(0.64, 0.0), 0.03 * H, 0.002 * H, steel, 1.0)
				cl.ell(g, V.call(0.08, 0.0), 0.04 * H, 0.03 * H, 0.03 * H, steel, 1.0)
			else:
				var head := PackedVector2Array([P.call(0.48, -0.012), P.call(0.53, -0.022), P.call(0.64, 0.0), P.call(0.53, 0.022), P.call(0.48, 0.012)])
				var hz: Vector3 = V.call(0.5, 0.0)
				cl.slab(g, head, hz.z, 0.006 * H, steel, 1.0, 0.012 * H)
		"pick":
			cl.cap(g, V.call(-0.05, 0.0), V.call(0.27, 0.0), 0.01 * H, 0.009 * H, wood, 1.0)
			var a: Vector3 = V.call(0.27, -0.12)
			var m: Vector3 = V.call(0.29, 0.0, 0.01)
			var b: Vector3 = V.call(0.24, 0.13)
			cl.chain(g, [a, V.call(0.285, -0.06), m, V.call(0.28, 0.07), b], [0.003 * H, 0.012 * H, 0.016 * H, 0.012 * H, 0.003 * H], steel, 2.0)
		"staff":
			var sc := cl.mat(kit.get("staff_c", kit.get("wood", Color("#4a3426"))), "wood")
			cl.chain(g, [V.call(-0.32, 0.0), V.call(0.1, 0.004), V.call(0.42, -0.004)], [0.009 * H, 0.009 * H, 0.011 * H], sc, 2.0)
			var orb_c: Color = kit.get("glow", Color("#9ab8e8"))
			var top: Vector3 = V.call(0.47, 0.0, 0.01)
			for k: int in [-1, 1]:  # 구슬을 쥔 갈퀴
				cl.chain(g, [V.call(0.42, 0.0), V.call(0.45, k * 0.03), V.call(0.5, k * 0.02)], [0.006 * H, 0.005 * H, 0.002 * H], sc, 1.0)
			cl.ell(g, top, 0.022 * H, 0.022 * H, 0.022 * H, cl.mat(orb_c, "glow"), 0.5)
			out["glows"].append([Vector2(top.x, top.y), 0.09 * H, orb_c])
		"bow":
			var bw := cl.mat(kit.get("wood", Color("#5a4030")), "wood")
			var pts: Array = []
			var rs: Array = []
			for k in 9:
				var t := k / 8.0
				pts.append(Vector3(grip.x + s * sin(t * PI) * 0.06 * H * -1.0, grip.y + (t - 0.5) * 0.5 * H, grip.z + 0.01 * H))
				rs.append((0.01 - absf(t - 0.5) * 0.012) * H)
			cl.chain(g, pts, rs, bw, 1.0)
			var a: Vector3 = pts[0]
			var b: Vector3 = pts[8]
			out["lines"].append([Vector2(a.x, a.y), Vector2(b.x, b.y), maxf(1.0, H / 400.0), Color("#c8bea0")])
		"bomb":
			cl.ell(g, grip + Vector3(0, 0.01 * H, 0.03 * H), 0.04 * H, 0.04 * H, 0.04 * H, cl.mat(Color("#2e2a28"), "metal"), 1.0)
			var f0 := grip + Vector3(0, -0.028 * H, 0.04 * H)
			cl.cap(g, f0, f0 + Vector3(0.015 * H, -0.03 * H, 0.0), 0.004 * H, 0.003 * H, cl.mat(Color("#8a7a5a"), "cloth"), 0.5)
			out["glows"].append([Vector2(f0.x + 0.015 * H, f0.y - 0.03 * H), 0.04 * H, Color("#ffb040")])
		"torch":
			cl.cap(g, V.call(-0.03, 0.0), V.call(0.14, 0.0), 0.01 * H, 0.013 * H, wood, 1.0)
			var tp: Vector2 = P.call(0.17, 0.0)
			out["glows"].append([tp, 0.12 * H, Color("#ffa040")])


static func _shield(cl: Clay, j: Dictionary, H: float, kit: Dictionary) -> void:
	var tag := "r" if str(kit.get("weapon_hand", "l")) == "l" else "l"
	var hand: Vector3 = j["hand_" + tag]
	var el: Vector3 = j["elbow_" + tag]
	var c := hand.lerp(el, 0.45) + Vector3(0, 0, 0.05 * H)
	var g := cl.group()
	var col: Color = kit["shield"]
	var m := cl.mat(col, str(kit.get("shield_mat", "wood")))
	var rim := cl.mat(col.darkened(0.3), "metal")
	if str(kit.get("shield_kind", "round")) == "kite":
		var poly := PackedVector2Array()
		for k in 24:
			var t := TAU * k / 24.0
			var r := 1.0 if sin(t) < 0.0 else 1.0 + sin(t) * 0.8
			poly.append(Vector2(c.x + cos(t) * 0.085 * H, c.y + sin(t) * 0.085 * H * r - 0.02 * H))
		cl.slab(g, poly, c.z, 0.02 * H, m, 2.0, 0.03 * H)
		cl.ridge(g, [Vector2(c.x, c.y - 0.1 * H), Vector2(c.x, c.y + 0.12 * H)], 0.008 * H, 0.004 * H, rim)
		cl.ridge(g, [Vector2(c.x - 0.075 * H, c.y - 0.03 * H), Vector2(c.x + 0.075 * H, c.y - 0.03 * H)], 0.008 * H, 0.004 * H, rim)
	else:
		cl.ell(g, c, 0.1 * H, 0.1 * H, 0.025 * H, m, 1.0)
		cl.ridge(g, _ring(Vector2(c.x, c.y), 0.093 * H, 24), 0.008 * H, 0.004 * H, rim)
		cl.bump(g, Vector2(c.x, c.y), 0.024 * H, 0.024 * H, 0.012 * H, rim, 1.0)
		for k in 4:  # 판자 이음
			var x := c.x + (k - 1.5) * 0.045 * H
			cl.groove(g, Vector2(x, c.y - 0.085 * H), Vector2(x, c.y + 0.085 * H), 0.003 * H, 0.004 * H)


static func _ring(c: Vector2, r: float, n: int) -> Array:
	var pts: Array = []
	for k in n + 1:
		var a := TAU * k / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts
