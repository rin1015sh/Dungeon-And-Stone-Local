extends RefCounted
## 머리카락(Clay): 정수리에서 내려오는 가닥(가는 캡슐 줄)을 여러 개 — 가닥 사이 골이 잉크 결이 된다.
## hair: ragged(듬성듬성 엉킨 시체 머리) · long(등까지 늘어진 긴 머리) · slick(뒤로 넘긴 머리) · topknot(상투) · shaggy(덥수룩)
## hair_c = 색. 앞가닥은 머리보다 앞 그룹, 뒷머리는 머리 뒤(z 음수) 그룹.

const Clay := preload("res://tools/monster_art/Clay.gd")


static func grow(cl: Clay, f: Dictionary, kind: String, col: Color, rng: RandomNumberGenerator) -> void:
	if kind == "" or kind == "none":
		return
	var m := cl.mat(col, "hair")
	var hh: float = f["hh"]
	var c: Vector2 = f["c"]
	var tilt: float = f["tilt"]
	var hg: int = f["g"]
	var hw := hh * 0.42
	var R := func(u: float, v: float) -> Vector2: return c + Vector2(u * hh, v * hh).rotated(tilt)
	var front := cl.group()
	var back := cl.group()
	var hz := cl.surf(hg, c.x, c.y)
	if kind in ["long", "ragged", "shaggy"]:  # 뒷머리 판
		var ln := 1.6 if kind == "long" else (0.75 if kind == "ragged" else 1.0)
		var poly := PackedVector2Array()
		for k in 13:
			var a := PI + PI * k / 12.0
			poly.append(R.call(cos(a) * 0.5, -0.12 + sin(a) * 0.52))
		var w0 := 0.62 if kind != "ragged" else 0.5
		var bot := PackedVector2Array()
		for k in 9:
			var t := k / 8.0
			bot.append(R.call(lerpf(w0, -w0, t), ln - (0.15 if k % 2 == 0 else 0.0) * (1.0 if kind != "long" else 0.4) + rng.randf() * 0.1))
		poly.append_array(bot)
		cl.slab(back, poly, hz - hh * 0.75, hh * 0.15, m, 2.0, hh * 0.12)
		for k in 9:
			var x := lerpf(-w0, w0, (k + 0.5) / 9.0)
			cl.grooves(back, [R.call(x * 0.5, -0.4), R.call(x, ln * 0.5), R.call(x * 1.05, ln)], hh * 0.02, hh * 0.04)
	match kind:
		"slick", "topknot":
			var clip := PackedVector2Array()
			for k in 13:
				var a := PI + PI * k / 12.0
				clip.append(R.call(cos(a) * 0.62, -0.1 + sin(a) * 0.65))
			clip.append(R.call(0.48, -0.05))
			clip.append(R.call(0.38, -0.2))
			clip.append(R.call(0.12, -0.26))
			clip.append(R.call(0.0, -0.18))  # 이마 가운데 뾰족
			clip.append(R.call(-0.12, -0.26))
			clip.append(R.call(-0.38, -0.2))
			clip.append(R.call(-0.48, -0.05))
			cl.shell(["head"], hh * 0.035, m, front, clip, 4.0)
			for k in 8:
				var u := lerpf(-0.36, 0.36, (k + 0.5) / 8.0)
				cl.grooves(front, [R.call(u * 0.4, -0.22), R.call(u, -0.45), R.call(u * 1.2, -0.6)], hh * 0.014, hh * 0.025)
			if kind == "topknot":
				var top: Vector2 = R.call(0.0, -0.66)
				cl.ell(front, Vector3(top.x, top.y, hz - hh * 0.1), hh * 0.13, hh * 0.11, hh * 0.12, m, 2.0)
				var t1: Vector2 = R.call(0.12, -0.8)
				var t2: Vector2 = R.call(0.3, -0.7)
				cl.chain(back, [Vector3(top.x, top.y, hz - hh * 0.2), Vector3(t1.x, t1.y, hz - hh * 0.3), Vector3(t2.x, t2.y, hz - hh * 0.35)], [hh * 0.07, hh * 0.05, hh * 0.015], m, 2.0)
		_:
			var n := 18 if kind == "long" else (11 if kind == "ragged" else 16)
			for k in n:
				var a := lerpf(PI * 1.08, PI * 1.92, (k + rng.randf_range(0.0, 0.8)) / n)
				if kind == "ragged" and rng.randf() < 0.25:
					continue  # 빠진 자리
				var root: Vector2 = R.call(cos(a) * 0.4, -0.14 + sin(a) * 0.44)
				var side := cos(a)
				var ln := hh * rng.randf_range(0.25, 0.55) * (1.8 if kind == "long" and absf(side) > 0.55 else 1.0)
				if absf(side) < 0.5:
					ln *= 0.6  # 이마 위 가닥은 짧게
				var dir := Vector2(side * 0.55, 1.0).normalized().rotated(tilt + rng.randf_range(-0.25, 0.25))
				var p1 := root + dir * ln * 0.35 + Vector2(side * hh * 0.08, 0)
				var p2 := root + dir * ln * 0.7 + Vector2(side * hh * 0.1, 0)
				var p3 := root + dir * ln + Vector2(side * hh * 0.06, 0)
				var z0 := cl.surf(hg, root.x, root.y)
				if z0 <= Clay.EMPTY * 0.5:
					z0 = hz - hh * 0.2
				var r0 := hh * rng.randf_range(0.045, 0.07)
				cl.chain(front, [Vector3(root.x, root.y, z0 + hh * 0.01), Vector3(p1.x, p1.y, z0 - hh * 0.02), Vector3(p2.x, p2.y, z0 - hh * 0.06), Vector3(p3.x, p3.y, z0 - hh * 0.1)], [r0, r0 * 0.85, r0 * 0.55, r0 * 0.15], m, 1.5)
			var cap_clip := PackedVector2Array()
			for k in 13:
				var a := PI + PI * k / 12.0
				cap_clip.append(R.call(cos(a) * 0.62, -0.08 + sin(a) * 0.62))
			cap_clip.append(R.call(0.45, -0.12))
			cap_clip.append(R.call(0.0, -0.3))
			cap_clip.append(R.call(-0.45, -0.12))
			if kind != "ragged" or rng.randf() < 0.5:
				cl.shell(["head"], hh * 0.025, m, front, cap_clip, 3.0)
