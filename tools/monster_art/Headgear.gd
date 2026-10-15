extends RefCounted
## 머리 장구(Face.head 뒤에 빚는다): 두건 · 투구(얼굴 판·눈 틈·깃) · 광부 모자(등잔) · 왕관.

const Clay := preload("res://tools/monster_art/Clay.gd")


## 머리 장구(머리를 빚은 뒤): hood(두건 — 얼굴 둘레를 감싸고 어깨로 흘러내림) · helm(투구 — 눈 틈) · crown(왕관) · plume(투구 깃).
## hd 키: hood(색) · helm(색) · crown(색) · plume(색) · visor(true면 얼굴 전체를 덮는 투구)
static func gear(cl: Clay, f: Dictionary, hd: Dictionary, j: Dictionary, H: float) -> void:
	var hh: float = f["hh"]
	var c: Vector2 = f["c"]
	var tilt: float = f["tilt"]
	var R := func(u: float, v: float) -> Vector2: return c + Vector2(u * hh, v * hh).rotated(tilt)
	if hd.has("hood"):
		var m := cl.mat(hd["hood"], "cloth")
		var g := cl.group()
		var outer := PackedVector2Array()
		for k in 21:
			var a := PI + PI * k / 20.0
			outer.append(R.call(cos(a) * 0.56, 0.06 + sin(a) * 0.62))
		var sl: Vector3 = j["shoulder_l"]
		var sr: Vector3 = j["shoulder_r"]
		outer.append(Vector2(sr.x + 0.02 * H, sr.y + 0.06 * H))
		outer.append(Vector2(c.x, j["chest"].y - 0.01 * H))
		outer.append(Vector2(sl.x - 0.02 * H, sl.y + 0.06 * H))
		var z := cl.surf(f["g"], c.x, c.y)
		cl.slab(g, outer, z - hh * 0.5, hh * 0.58, m, 4.0, hh * 0.3)
		cl.erase(g, R.call(0.0, 0.08), hh * 0.34, hh * 0.42, 0.05)
		for k in 6:  # 두건 주름
			var u := lerpf(-0.55, 0.55, (k + 0.5) / 6.0)
			cl.groove(g, R.call(u * 0.7, -0.45), R.call(u * 1.3, 0.9), hh * 0.025, hh * 0.05)
		f["hood"] = true
	if hd.has("helm"):
		var m := cl.mat(hd["helm"], "metal")
		var g := cl.group()
		var hz := cl.surf(f["g"], c.x, c.y)
		var dome: Vector2 = R.call(0.0, -0.12)
		var hw2 := hh * 0.52
		cl.ell(g, Vector3(dome.x, dome.y, hz - hh * 0.55), hw2, hh * 0.56, hh * 0.62, m, 6.0, tilt)  # 투구 통
		f["visor"] = bool(hd.get("visor", true))
		if hd.get("visor", true):
			var fp: Vector2 = R.call(0.0, 0.14)
			cl.ell(g, Vector3(fp.x, fp.y, hz - hh * 0.38), hw2 * 0.86, hh * 0.46, hh * 0.5, m, 8.0, tilt)  # 얼굴 판
			cl.ridge(g, [R.call(0.0, -0.62), R.call(0.0, 0.5)], hh * 0.035, hh * 0.025, m)
			cl.groove(g, R.call(-0.4, -0.03), R.call(0.4, -0.03), hh * 0.035, hh * 0.05)  # 눈 틈 골
			for k in 5:
				cl.carve(g, R.call(-0.16 + k * 0.08, 0.3), hh * 0.014, hh * 0.045, hh * 0.04)  # 숨구멍
		else:
			cl.groove(g, R.call(-0.45, 0.02), R.call(0.45, 0.02), hh * 0.03, hh * 0.04)
		if hd.has("plume"):
			var pm := cl.mat(hd["plume"], "hair")
			var top: Vector2 = R.call(0.0, -0.62)
			var z := cl.surf(g, top.x, top.y + hh * 0.1)
			for k in 7:
				var a := -0.9 + k * 0.3
				var tip := top + Vector2(sin(a) * hh * 0.5, -cos(a) * hh * 0.6 - hh * 0.2)
				cl.chain(g, [Vector3(top.x, top.y, z), Vector3(lerpf(top.x, tip.x, 0.5), lerpf(top.y, tip.y, 0.6), z - hh * 0.1), Vector3(tip.x, tip.y, z - hh * 0.2)], [hh * 0.07, hh * 0.06, hh * 0.015], pm, 2.0)
			f["top"] = top.y - hh * 0.8
	if hd.has("cap"):  # 광부 모자 + 등잔
		var m := cl.mat(hd["cap"], "leather")
		var g := cl.group()
		var hz := cl.surf(f["g"], c.x, c.y)
		var dome: Vector2 = R.call(0.0, -0.28)
		cl.ell(g, Vector3(dome.x, dome.y, hz - hh * 0.5), hh * 0.5, hh * 0.36, hh * 0.55, m, 4.0, tilt)
		cl.cap(g, _v3(R.call(-0.56, -0.12), hz - hh * 0.2), _v3(R.call(0.56, -0.12), hz - hh * 0.2), hh * 0.06, hh * 0.06, m, 3.0)
		var lamp: Vector2 = R.call(0.0, -0.36)
		cl.ell(g, Vector3(lamp.x, lamp.y, cl.surf(g, lamp.x, lamp.y) + hh * 0.02), hh * 0.07, hh * 0.06, hh * 0.05, cl.mat(Color("#f0c070"), "glow"), 0.5)
		f["glows"] = [[lamp, hh * 0.22, Color("#ffc060")]]
	if hd.has("crown"):
		var m := cl.mat(hd["crown"], "metal")
		var g := cl.group()
		var z := cl.surf(f["g"], c.x, c.y - hh * 0.3)
		for k in 7:
			var u := lerpf(-0.36, 0.36, k / 6.0)
			var b: Vector2 = R.call(u, -0.42)
			var t: Vector2 = R.call(u * 1.1, -0.72 if k % 2 == 0 else -0.6)
			var bz := z - absf(u) * hh * 0.5
			cl.cap(g, Vector3(b.x, b.y, bz), Vector3(t.x, t.y, bz), hh * 0.045, hh * 0.01, m, 2.0)
		cl.cap(g, Vector3(R.call(-0.4, -0.42).x, R.call(-0.4, -0.42).y, z - hh * 0.2), Vector3(R.call(0.4, -0.42).x, R.call(0.4, -0.42).y, z - hh * 0.2), hh * 0.06, hh * 0.06, m, 3.0)
		f["top"] = c.y - hh * 0.75


static func _v3(v: Vector2, z: float) -> Vector3:
	return Vector3(v.x, v.y, z)
