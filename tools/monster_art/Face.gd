extends RefCounted
## 머리 빚기(Clay): 두개골 + 턱 + 광대 + 눈썹뼈 + 코 → 눈구멍·입을 파내고 눈알·이빨을 넣는다.
## hd 키: type(gaunt|human|goblin|orc|skull|ape|lizard|demon|block|bird|hood) · size(배율) · mouth(shut|open|scream|grin|fangs)
##         eyes(눈 색) · glow(눈 빛 세기) · ears(none|human|pointed|long) · horns(Color) · horn_len · jaw(턱 폭 배율)
## 돌려주는 값: {"g": 그룹, "eyes": [눈 위치 Vector2…], "eye_r": 반지름, "top": 머리 꼭대기 y, "mouth": 입 위치}

const Clay := preload("res://tools/monster_art/Clay.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")


static func head(cl: Clay, j: Dictionary, hd: Dictionary, skin: int, mats: Dictionary) -> Dictionary:
	var g := cl.group()
	cl.tag = "head"
	var c: Vector3 = j["head"]
	var hh: float = float(j["head_h"]) * float(hd.get("size", 1.0))
	var tilt := float(j.get("tilt", 0.0))
	var type := str(hd.get("type", "human"))
	var bone: int = mats["bone"]
	var dark: int = mats["dark"]
	var eye_m: int = mats["eye"]
	var hw := hh * float(hd.get("width", 0.42))  # 머리 반폭
	var jaw := float(hd.get("jaw", 1.0))
	var out := {"g": g, "eyes": [], "top": c.y - hh * 0.55, "mouth": Vector2(c.x, c.y + hh * 0.3), "hh": hh, "c": Vector2(c.x, c.y), "tilt": tilt, "type": type, "hd": hd}
	var R := func(u: float, v: float) -> Vector2:  # 머리 기울기 적용한 화면 좌표(u·v = 머리 높이 비율)
		return Vector2(c.x, c.y) + Vector2(u * hh, v * hh).rotated(tilt)
	if type == "block":
		return _block(cl, g, R, hh, c.z, skin, mats, out, tilt)
	# 두개골 · 턱 · 광대
	var crown := 0.0 if type in ["ape", "orc", "block"] else 0.04
	var cr: Vector2 = R.call(0.0, -0.12 - crown)
	cl.ell(g, Vector3(cr.x, cr.y, c.z), hw, hh * (0.44 + crown), hh * 0.5, skin, 6.0, tilt)
	var jw: Vector2 = R.call(0.0, 0.2)
	var jaw_w := hw * 0.78 * jaw
	if type == "goblin":
		jaw_w = hw * 0.62 * jaw
	cl.ell(g, Vector3(jw.x, jw.y, c.z + hh * 0.06), jaw_w, hh * 0.28, hh * 0.42, skin, 8.0, tilt)
	var chin: Vector2 = R.call(0.0, 0.4 if type != "goblin" else 0.44)
	cl.ell(g, Vector3(chin.x, chin.y, c.z + hh * 0.2), jaw_w * 0.5, hh * 0.1, hh * 0.25, skin, 6.0, tilt)
	for s: int in [-1, 1]:
		var cb: Vector2 = R.call(s * 0.27, 0.02)
		cl.ell(g, Vector3(cb.x, cb.y, c.z + hh * 0.3), hh * 0.12, hh * 0.08, hh * 0.18, skin, 4.0, tilt)
	if type in ["gaunt", "skull"]:  # 꺼진 볼
		for s: int in [-1, 1]:
			cl.carve(g, R.call(s * 0.24, 0.17), hh * 0.09, hh * 0.12, hh * 0.08)
	# 눈썹뼈
	var brow := 0.05 if type in ["orc", "ape", "demon", "block"] else 0.025
	cl.cap(g, _v3(R.call(-0.3, -0.1), c.z + hh * 0.42), _v3(R.call(0.3, -0.1), c.z + hh * 0.42), hh * brow + hh * 0.03, hh * brow + hh * 0.03, skin, 5.0)
	# 눈구멍 + 눈알
	var ey := -0.03
	var er := hh * (0.085 if type != "goblin" else 0.1)
	for s: int in [-1, 1]:
		var e: Vector2 = R.call(s * 0.17, ey)
		cl.carve(g, e, er * 1.5, er * 1.25, hh * (0.14 if type in ["gaunt", "skull"] else 0.09), tilt)
		if type != "skull":
			var ez := cl.surf(g, e.x, e.y)
			cl.ell(g, Vector3(e.x, e.y, ez - er * 0.35), er * 0.9, er * 0.8, er * 0.8, eye_m, 0.5)
		out["eyes"].append(e)
	out["eye_r"] = er
	# 코
	match type:
		"skull":
			cl.carve(g, R.call(0.0, 0.12), hh * 0.05, hh * 0.08, hh * 0.15)
		"ape", "orc":
			var nb: Vector2 = R.call(0.0, 0.12)
			cl.ell(g, Vector3(nb.x, nb.y, c.z + hh * 0.48), hh * 0.12, hh * 0.08, hh * 0.1, skin, 3.0, tilt)
			for s: int in [-1, 1]:
				cl.carve(g, R.call(s * 0.05, 0.15), hh * 0.028, hh * 0.022, hh * 0.05)
		"goblin":
			var n0: Vector2 = R.call(0.0, -0.02)
			var n1: Vector2 = R.call(0.0, 0.2)
			cl.cap(g, _v3(n0, c.z + hh * 0.45), _v3(n1, c.z + hh * 0.62), hh * 0.05, hh * 0.08, skin, 3.0)
		"lizard", "bird":
			pass
		_:
			var n0: Vector2 = R.call(0.0, -0.02)
			var n1: Vector2 = R.call(0.0, 0.13)
			cl.cap(g, _v3(n0, c.z + hh * 0.42), _v3(n1, c.z + hh * 0.5), hh * 0.035, hh * 0.055, skin, 3.0)
			for s: int in [-1, 1]:
				cl.carve(g, R.call(s * 0.04, 0.16), hh * 0.02, hh * 0.015, hh * 0.04)
	match type:
		"lizard":  # 앞으로 길게 나온 주둥이 + 비늘 골
			var s0: Vector2 = R.call(0.0, 0.05)
			var s1: Vector2 = R.call(0.0, 0.52)
			cl.cap(g, _v3(s0, c.z + hh * 0.35), _v3(s1, c.z + hh * 0.75), hh * 0.24, hh * 0.15, skin, 6.0)
			for s: float in [-1.0, 1.0]:
				cl.carve(g, R.call(s * 0.06, 0.58), hh * 0.025, hh * 0.018, hh * 0.04)
			for k in 5:
				cl.groove(g, R.call(-0.3, -0.35 + k * 0.1), R.call(0.3, -0.33 + k * 0.1), hh * 0.015, hh * 0.02)
			hd = hd.duplicate()
			hd["mouth"] = hd.get("mouth", "fangs")
		"ape":  # 앞으로 튀어나온 입 · 넓적한 코
			var mz: Vector2 = R.call(0.0, 0.24)
			cl.ell(g, Vector3(mz.x, mz.y, c.z + hh * 0.32), hh * 0.3, hh * 0.2, hh * 0.3, skin, 6.0, tilt)
		"demon":
			for s: float in [-1.0, 1.0]:  # 광대 가시
				var b: Vector2 = R.call(s * 0.36, 0.1)
				cl.cap(g, _v3(b, c.z + hh * 0.1), _v3(b + Vector2(s * hh * 0.18, hh * 0.05), c.z + hh * 0.05), hh * 0.05, hh * 0.008, bone, 2.0)
	_mouth(cl, g, R, hh, c.z, str(hd.get("mouth", "shut")), type, bone, dark, skin, out)
	_ears(cl, g, R, hh, c.z, str(hd.get("ears", "human" if type in ["human", "gaunt"] else ("pointed" if type in ["goblin", "orc"] else "none"))), skin, tilt)
	if hd.has("horns"):
		var hm: int = mats.get("horn", bone)
		var hl := float(hd.get("horn_len", 0.6))
		for s: int in [-1, 1]:
			var b0: Vector2 = R.call(s * 0.28, -0.42)
			var b1: Vector2 = R.call(s * (0.42 + hl * 0.2), -0.42 - hl * 0.45)
			var b2: Vector2 = R.call(s * (0.36 + hl * 0.1), -0.42 - hl * 0.9)
			cl.chain(g, [_v3(b0, c.z), _v3(b1, c.z + hh * 0.05), _v3(b2, c.z + hh * 0.08)], [hh * 0.09, hh * 0.055, hh * 0.012], hm, 3.0)
		out["top"] = c.y - hh * (0.5 + hl * 0.9)
	if type in ["gaunt", "skull", "demon", "orc"]:  # 주름·힘줄
		for k in 3:
			cl.groove(g, R.call(-0.18, -0.25 - k * 0.05), R.call(0.18, -0.25 - k * 0.05), hh * 0.012, hh * 0.015)
	return out


static func _mouth(cl: Clay, g: int, R: Callable, hh: float, z: float, mouth: String, type: String, bone: int, dark: int, skin: int, out: Dictionary) -> void:
	var my := 0.3 if type != "goblin" else 0.3
	var mw := 0.16 if type != "goblin" else 0.24
	var open := 0.0
	match mouth:
		"open":
			open = 0.06
		"scream":
			open = 0.12
			mw *= 0.85
		"grin", "fangs":
			open = 0.035
			mw *= 1.35
	var m: Vector2 = R.call(0.0, my)
	out["mouth"] = m
	out["mw"] = mw
	out["open"] = open
	if open <= 0.0:
		cl.groove(g, R.call(-mw, my), R.call(mw, my), hh * 0.015, hh * 0.04)
		return
	cl.carve(g, m, hh * mw, hh * open, hh * 0.3)
	var mz := cl.surf(g, m.x, m.y)
	cl.ell(g, Vector3(m.x, m.y, mz - hh * 0.02), hh * mw * 0.9, hh * open * 0.85, hh * 0.02, dark, 0.0)  # 입속 어둠
	var n := 8 if mouth != "fangs" else 6
	for row: int in [-1, 1]:
		for k in n:
			var u := lerpf(-mw * 0.85, mw * 0.85, (k + 0.5) / n)
			var a: Vector2 = R.call(u, my + row * open * 0.95)
			var len := hh * (0.035 if mouth != "fangs" or k % 2 == 0 else 0.07)
			if mouth == "fangs" and (k == 1 or k == n - 2):
				len = hh * 0.11
			var b: Vector2 = a + Vector2(0, -row * len)
			var zz := cl.surf(g, a.x, a.y)
			cl.cap(g, Vector3(a.x, a.y, zz + hh * 0.005), Vector3(b.x, b.y, zz + hh * 0.01), hh * 0.016, hh * 0.007, bone, 0.5)
	for row: int in [-1, 1]:  # 입술
		cl.ridge(g, [R.call(-mw * 1.05, my + row * open * 1.15), R.call(0.0, my + row * open * 1.3), R.call(mw * 1.05, my + row * open * 1.15)], hh * 0.02, hh * 0.012, skin)


static func _ears(cl: Clay, g: int, R: Callable, hh: float, z: float, ears: String, skin: int, tilt: float) -> void:
	for s: int in [-1, 1]:
		match ears:
			"human":
				var e: Vector2 = R.call(s * 0.4, 0.05)
				cl.ell(g, Vector3(e.x, e.y, z - hh * 0.16), hh * 0.035, hh * 0.085, hh * 0.08, skin, 3.0, tilt)
			"pointed", "long":
				var ln := 0.55 if ears == "long" else 0.3
				var b0: Vector2 = R.call(s * 0.38, -0.05)
				var b1: Vector2 = R.call(s * (0.38 + ln * 0.6), -0.05 - ln * 0.35)
				var b2: Vector2 = R.call(s * (0.38 + ln), -0.1 - ln * 0.55)
				cl.slab(g, PackedVector2Array([R.call(s * 0.36, -0.15), b1 + Vector2(0, -hh * 0.06), b2, b1 + Vector2(0, hh * 0.06), R.call(s * 0.36, 0.1)]), z - hh * 0.06, hh * 0.06, skin, 2.0, hh * 0.06)
				cl.groove(g, b0, b2.lerp(b0, 0.25), hh * 0.025, hh * 0.04)


static func _v3(v: Vector2, z: float) -> Vector3:
	return Vector3(v.x, v.y, z)


## 네모 머리(골렘): 모서리가 둥근 돌·쇠 덩어리 + 가로 눈 틈 + 이마 골.
static func _block(cl: Clay, g: int, R: Callable, hh: float, z: float, skin: int, mats: Dictionary, out: Dictionary, tilt: float) -> Dictionary:
	var sq := PackedVector2Array([R.call(-0.42, -0.5), R.call(0.42, -0.5), R.call(0.46, 0.38), R.call(-0.46, 0.38)])
	cl.slab(g, sq, z, hh * 0.45, skin, 4.0, hh * 0.18)
	var jaw := PackedVector2Array([R.call(-0.36, 0.2), R.call(0.36, 0.2), R.call(0.3, 0.5), R.call(-0.3, 0.5)])
	cl.slab(g, jaw, z + hh * 0.05, hh * 0.35, skin, 3.0, hh * 0.12)
	cl.groove(g, R.call(-0.38, 0.22), R.call(0.38, 0.22), hh * 0.025, hh * 0.05)
	cl.cap(g, _v3(R.call(-0.38, -0.12), z + hh * 0.42), _v3(R.call(0.38, -0.12), z + hh * 0.42), hh * 0.07, hh * 0.07, skin, 3.0)
	for s: float in [-1.0, 1.0]:
		var e: Vector2 = R.call(s * 0.18, 0.0)
		cl.carve(g, e, hh * 0.12, hh * 0.045, hh * 0.08, tilt)
		cl.ell(g, Vector3(e.x, e.y, cl.surf(g, e.x, e.y) - hh * 0.01), hh * 0.08, hh * 0.025, hh * 0.02, mats["eye"], 0.3, tilt)
		out["eyes"].append(e)
	out["eye_r"] = hh * 0.06
	out["mouth"] = R.call(0.0, 0.32)
	out["hd"] = {"eye_style": "none"}
	out["type"] = "block"
	return out
