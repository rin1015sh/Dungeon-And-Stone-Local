extends RefCounted
## 얼굴 잉크(칠한 뒤 — Face.head가 돌려준 정보로): 눈꺼풀·흰자·홍채·동공, 찌푸린 미간, 콧방울, 팔자 주름, 입술 선.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")


## 얼굴 잉크(칠한 뒤): 눈꺼풀·흰자·홍채·동공, 찌푸린 미간, 콧방울, 팔자 주름, 입술 선 — 덩어리만으로는 흐린 얼굴을 펜으로 또렷하게.
## eye_style: human(흰자+홍채) · dead(탁한 흰자, 작은 동공) · beast(노란 눈, 세로 동공) · black(검은 구멍 + 반짝임) · glow(빛나는 눈) · none
static func ink(p: Paint, f: Dictionary, eye_c: Color, glow: float) -> void:
	var hh: float = f["hh"]
	var tilt: float = f["tilt"]
	var hd: Dictionary = f["hd"]
	var type: String = f["type"]
	var style := str(hd.get("eye_style", "skull" if type == "skull" else ("glow" if glow >= 0.5 else ("dead" if type in ["gaunt", "human"] else "beast"))))
	var lw := maxf(1.0, hh / 34.0)
	var er: float = f["eye_r"]
	var angry := float(hd.get("angry", 0.6))
	var k := 0
	for e: Vector2 in f["eyes"]:
		var s := -1.0 if k == 0 else 1.0
		k += 1
		var ew := er * float(hd.get("eye_w", 1.25))
		var eh := er * float(hd.get("eye_h", 0.62))
		var rot := tilt + s * angry * 0.18  # 바깥 눈꼬리가 올라간 매서운 눈
		var P := func(u: float, v: float) -> Vector2: return e + Vector2(u * ew, v * eh).rotated(rot)
		var up := PackedVector2Array()
		var lo := PackedVector2Array()
		for i in 9:
			var t := -1.0 + i * 0.25
			up.append(P.call(t, -sqrt(maxf(0.0, 1.0 - t * t)) * (1.0 - angry * 0.35 * (1.0 + s * t) * 0.5)))
			lo.append(P.call(t, sqrt(maxf(0.0, 1.0 - t * t)) * 0.8))
		var shape := PackedVector2Array(up)
		for i in range(lo.size() - 1, -1, -1):
			shape.append(lo[i])
		match style:
			"none":
				pass
			"skull":  # 빈 눈구멍 + 깊은 곳의 불씨
				var sock := PackedVector2Array()
				for i in 16:
					var a := TAU * i / 16.0
					sock.append(e + Vector2(cos(a) * er * 1.35, sin(a) * er * 1.15 + (er * 0.15 if sin(a) > 0.0 else 0.0)).rotated(tilt))
				p.fill_poly(sock, func(_x: int, _y: int) -> Color: return Color("#0c0705"), 0.92)
				if glow > 0.0:
					_dot(p, e + Vector2(0, er * 0.1), er * 0.32, eye_c.lightened(0.4), 0.95)
				k += 0
				continue
			"black":
				p.fill_poly(shape, func(_x: int, _y: int) -> Color: return Color("#0d0806"))
				_dot(p, e + Vector2(-er * 0.3, -er * 0.25), er * 0.18, Color(1, 0.95, 0.85), 0.9)
			_:
				var white := Color("#c9bf9f") if style != "dead" else Color("#b8b496")
				if style == "beast":
					white = eye_c
				if style == "glow":
					white = eye_c.lightened(0.3)
				p.fill_poly(shape, func(x: int, y: int) -> Color: return white.darkened(0.25 * clampf((float(y) - (e.y - eh)) / (eh * 2.0), 0.0, 1.0)))
				if style in ["human", "dead"]:
					var ir := eh * (0.95 if style == "human" else 0.55)
					_dot(p, e + Vector2(0, eh * 0.05), ir, eye_c.darkened(0.2) if style == "human" else Color("#8a8468"), 0.95)
					_dot(p, e + Vector2(0, eh * 0.05), ir * (0.45 if style == "human" else 0.4), Color("#100a08"), 0.95)
				elif style == "beast":
					for yy in range(int(e.y - eh), int(e.y + eh) + 1):  # 세로 동공
						for xx in range(int(e.x - eh * 0.25), int(e.x + eh * 0.25) + 1):
							if Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), shape):
								p.blend(xx, yy, Color("#120a06"), 0.9 * (1.0 - absf(xx + 0.5 - e.x) / (eh * 0.25)))
				elif style == "glow":
					_dot(p, e, eh * 0.5, Color(1, 0.98, 0.9), 0.9)
				_dot(p, e + Vector2(-ew * 0.25, -eh * 0.35), maxf(0.8, eh * 0.18), Color(1, 1, 0.95), 0.8)
				p.fill_poly(shape, func(_x: int, y: int) -> Color: return Color(0.05, 0.03, 0.02, 0.55 * clampf(1.0 - (float(y) - (e.y - eh)) / (eh * 0.7), 0.0, 1.0)))  # 윗눈꺼풀 그늘
		Ink.path(p, up, lw * 1.6, false, Ink.INK, 0.95, 0.4)
		Ink.path(p, lo, lw * 0.7, false, Ink.INK, 0.7, 0.4)
		# 찌푸린 눈썹 골 · 눈 밑 그늘
		var b0: Vector2 = P.call(-1.1 * s, -1.9)
		var b1: Vector2 = P.call(1.2 * s, -1.5 + angry * 0.9)
		Ink.line(p, b0 if s < 0 else b1, b1 if s < 0 else b0, lw * 1.4, Ink.INK, 0.8, 0.5)
		Ink.line(p, P.call(-0.8, 1.6), P.call(0.7, 1.5), lw * 0.7, Ink.INK, 0.45, 0.6)
	if type in ["human", "gaunt", "orc", "goblin", "demon", "ape"]:
		var c: Vector2 = f["c"]
		var R := func(u: float, v: float) -> Vector2: return c + Vector2(u * hh, v * hh).rotated(tilt)
		Ink.line(p, R.call(0.0, -0.05), R.call(0.0, -0.18), lw, Ink.INK, 0.6, 0.5)  # 미간 주름
		for s in [-1.0, 1.0]:
			Ink.line(p, R.call(s * 0.07, 0.15), R.call(s * 0.03, 0.18), lw * 1.2, Ink.INK, 0.85, 0.3)  # 콧방울
			Ink.line(p, R.call(s * 0.1, 0.14), R.call(s * 0.17, 0.3), lw, Ink.INK, 0.55, 0.8)  # 팔자 주름
	var mo: float = f.get("open", 0.0)
	var m: Vector2 = f["mouth"]
	var mw := float(f.get("mw", 0.15)) * hh
	if mo <= 0.0:
		Ink.line(p, m + Vector2(-mw, 0).rotated(tilt), m + Vector2(mw, 0).rotated(tilt), lw * 1.5, Ink.INK, 0.9, 0.8)
	else:
		var mp := PackedVector2Array()
		for i in 17:
			var a := TAU * i / 16.0
			mp.append(m + Vector2(cos(a) * mw * 0.95, sin(a) * mo * hh * 1.05).rotated(tilt))
		Ink.path(p, mp, lw * 1.3, true, Ink.INK, 0.9, 0.5)


static func _dot(p: Paint, c: Vector2, r: float, col: Color, a: float) -> void:
	for yy in range(int(c.y - r - 1), int(c.y + r + 1) + 1):
		for xx in range(int(c.x - r - 1), int(c.x + r + 1) + 1):
			var cov := clampf(r - Vector2(xx + 0.5 - c.x, yy + 0.5 - c.y).length() + 0.5, 0.0, 1.0)
			if cov > 0.0 and p.alpha_at(xx, yy) > 0.5:
				p.blend(xx, yy, col, cov * a)
