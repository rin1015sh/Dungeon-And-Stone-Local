extends RefCounted
## 시설 실내 가구 — 칸마다 하나씩 세우는 것(RoomFurniture 전용): barrel 통(variant water) · crate 궤짝 · sack 자루 · seat 의자·걸상 · post 촛대·등 ·
## pillar 기둥 · urn 항아리 · dummy 허수아비 · stand 갑옷 받침대 · target 과녁 · globe 지구본 · pump 펌프 · wheel 숫돌 바퀴 · pot 솥 · lectern 독서대 · rack 걸이.
## 무리 칸마다 그 칸 아래쪽(발)에 세운다 — 위 줄부터 그려 아래 줄이 앞을 가린다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Props := preload("res://tools/city_art/Props.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")
const RoomProps := preload("res://tools/city_art/RoomProps.gd")

const PAD := 10


static func per_cell(shape: String, d: Dictionary, size: Vector2i, t: int, seed_value: int) -> Paint:
	var col := Color.from_string(JsonUtil.get_str(d, "color", "#5a3e28"), Color("#5a3e28"))
	var tall := {"pillar": 1.9, "post": 1.4, "dummy": 1.6, "stand": 1.3, "target": 1.2, "rack": 1.6, "lectern": 1.3, "urn": 0.9, "globe": 1.0, "pump": 1.1}.get(shape, 0.8) as float
	var p := Paint.new(size.x * t + PAD * 2 + 20, size.y * t + int(tall * t) + 30, seed_value)
	var flames: Array = []
	for cy in size.y:
		for cx in size.x:
			var gx := PAD + 10 + (cx + 0.5) * t
			var gy := p.h - (size.y - cy - 1) * t - t * 0.28
			var f := _one(p, shape, d, col, gx, gy, t)
			if f != Vector2.ZERO:
				flames.append(f)
	var ls: Array = []
	for f: Vector2 in flames:
		ls.append([f, 90.0, RoomArt.WARM, 0.8])
	RoomArt.light(p, ls, 0.86)
	for f: Vector2 in flames:
		Ink.glow(p, f.x, f.y, 18, RoomArt.WARM, 0.5)
	Ink.grade(p, 0.12, 1.05)
	Ink.finish(p, 0.04, 0.0)
	return p


## 한 칸에 하나. 불꽃이 있으면 그 자리(없으면 Vector2.ZERO).
static func _one(p: Paint, shape: String, d: Dictionary, col: Color, cx: float, g: float, t: int) -> Vector2:
	match shape:
		"barrel":
			Props.barrel(p, cx, g, t * 0.62, t * 0.78)
			var lid := _ellipse(Vector2(cx, g - t * 0.8), t * 0.3, t * 0.1)
			p.fill_poly(lid, p.flat(Color("#26343a") if JsonUtil.get_str(d, "variant") == "water" else col.darkened(0.1), 0.15))
			Ink.path(p, lid, 1.4)
		"crate":
			Props.crate(p, cx, g, t * 0.7)
		"sack":
			Props.sack(p, cx, g, t * 0.6)
		"seat":
			var seat := Paint.rect_poly(cx - t * 0.26, g - t * 0.42, t * 0.52, t * 0.14)
			for lx: float in [cx - t * 0.22, cx + t * 0.16]:
				p.fill_rect(lx, g - t * 0.3, 5, t * 0.3, p.flat(col.darkened(0.3), 0.1))
			p.fill_poly(seat, p.flat(col, 0.15))
			Ink.path(p, seat, 1.4)
			var back := Paint.rect_poly(cx - t * 0.26, g - t * 0.85, t * 0.52, t * 0.42)
			p.fill_poly(back, Mat.planks(p, col.darkened(0.1), 0, 0, true, 7))
			Ink.path(p, back, 1.4)
		"post":
			Ink.line(p, Vector2(cx - t * 0.2, g), Vector2(cx + t * 0.2, g), 5.0, Color("#2a2622"), 1.0, 0.2)
			Ink.line(p, Vector2(cx, g), Vector2(cx, g - t * 1.15), 4.0, col.darkened(0.35), 1.0, 0.15)
			Ink.line(p, Vector2(cx - t * 0.2, g - t * 1.15), Vector2(cx + t * 0.2, g - t * 1.15), 3.0, col.darkened(0.2), 1.0, 0.1)
			for k in 3:
				Props.candle(p, cx - t * 0.16 + k * t * 0.16, g - t * 1.17, 10.0 + (k % 2) * 4.0)
			return Vector2(cx, g - t * 1.35)
		"pillar":
			Bits.column(p, Vector2(cx, g - t * 1.85), Vector2(cx, g), t * 0.62)
			p.fill_rect(cx - t * 0.4, g - t * 1.9, t * 0.8, t * 0.14, p.flat(col.lightened(0.1), 0.08))
			p.fill_rect(cx - t * 0.4, g - t * 0.12, t * 0.8, t * 0.12, p.flat(col.darkened(0.1), 0.08))
		"urn":
			var u := Paint.poly([Vector2(cx - t * 0.12, g - t * 0.85), Vector2(cx + t * 0.12, g - t * 0.85), Vector2(cx + t * 0.32, g - t * 0.45), Vector2(cx + t * 0.18, g), Vector2(cx - t * 0.18, g), Vector2(cx - t * 0.32, g - t * 0.45)])
			p.fill_poly(u, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.2 * clampf((cx - x) / (t * 0.3), -1.0, 1.0)), x, y, 0.1))
			Ink.path(p, u, 1.6)
		"dummy":
			Props.dummy(p, cx, g, 0.55)
		"stand":
			Ink.line(p, Vector2(cx, g), Vector2(cx, g - t * 1.2), 4.0, Color("#4a3424"), 1.0, 0.1)
			var torso := Paint.poly([Vector2(cx - t * 0.3, g - t * 1.15), Vector2(cx + t * 0.3, g - t * 1.15), Vector2(cx + t * 0.22, g - t * 0.55), Vector2(cx - t * 0.22, g - t * 0.55)])
			p.fill_poly(torso, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.25 * clampf((cx - x) / (t * 0.3), -1.0, 1.0)), x, y, 0.1))
			Ink.path(p, torso, 1.6)
			p.fill_poly(_ellipse(Vector2(cx, g - t * 1.25), t * 0.12, t * 0.12), p.flat(col.darkened(0.2), 0.1))
		"target":
			for lx: float in [cx - t * 0.25, cx + t * 0.25]:
				Ink.line(p, Vector2(lx, g), Vector2(cx, g - t * 0.9), 3.0, Color("#4a3424"), 1.0, 0.2)
			for k in 4:
				var rr := t * (0.42 - k * 0.1)
				p.fill_poly(_ellipse(Vector2(cx, g - t * 0.75), rr, rr), p.flat(col if k % 2 == 0 else Color("#c8bca0"), 0.1))
			Ink.path(p, _ellipse(Vector2(cx, g - t * 0.75), t * 0.42, t * 0.42), 1.6)
		"globe":
			Ink.line(p, Vector2(cx, g), Vector2(cx, g - t * 0.5), 4.0, Color("#4a3424"), 1.0, 0.1)
			p.fill_poly(_ellipse(Vector2(cx, g - t * 0.75), t * 0.3, t * 0.3), func(x: int, y: int) -> Color: return p.vary(col.lerp(Color("#8a7a4a"), p.nz("mid", x, y)), x, y, 0.15))
			Ink.path(p, _ellipse(Vector2(cx, g - t * 0.75), t * 0.3, t * 0.3), 1.6)
			Ink.path(p, _ellipse(Vector2(cx, g - t * 0.75), t * 0.34, t * 0.08), 1.4, true, Color("#a88a3a"))
		"pump":
			var body := Paint.rect_poly(cx - t * 0.12, g - t * 0.95, t * 0.24, t * 0.95)
			p.fill_poly(body, p.flat(col, 0.12))
			Ink.path(p, body, 1.4)
			Ink.line(p, Vector2(cx, g - t * 0.95), Vector2(cx + t * 0.4, g - t * 1.1), 3.0, col.darkened(0.2), 1.0, 0.1)
			Ink.line(p, Vector2(cx - t * 0.12, g - t * 0.6), Vector2(cx - t * 0.35, g - t * 0.55), 4.0, col.darkened(0.2), 1.0, 0.1)
		"wheel":
			var c := Vector2(cx, g - t * 0.45)
			p.fill_poly(_ellipse(c, t * 0.34, t * 0.34), p.flat(col, 0.15))
			Ink.path(p, _ellipse(c, t * 0.34, t * 0.34), 2.0)
			Ink.line(p, c + Vector2(-t * 0.35, t * 0.4), c + Vector2(t * 0.35, t * 0.4), 5.0, Color("#4a3424"), 1.0, 0.2)
		"pot":
			var c := Vector2(cx, g - t * 0.3)
			p.fill_poly(_ellipse(c, t * 0.36, t * 0.28), p.flat(col, 0.12))
			Ink.path(p, _ellipse(c, t * 0.36, t * 0.28), 1.8)
			p.fill_poly(_ellipse(c + Vector2(0, -t * 0.18), t * 0.3, t * 0.08), p.flat(Color("#4a3a24"), 0.15))
		"lectern":
			Ink.line(p, Vector2(cx, g), Vector2(cx, g - t * 0.9), 6.0, col.darkened(0.2), 1.0, 0.1)
			var board := Paint.poly([Vector2(cx - t * 0.35, g - t * 0.9), Vector2(cx + t * 0.35, g - t * 0.9), Vector2(cx + t * 0.3, g - t * 1.2), Vector2(cx - t * 0.3, g - t * 1.2)])
			p.fill_poly(board, Mat.planks(p, col, 0, 0, false, 8))
			Ink.path(p, board, 1.6)
			Bits.open_book(p, Vector2(cx, g - t * 1.16), t * 0.3)
		"rack":
			Props.weapon_rack(p, cx, g)
	return Vector2.ZERO


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		pts.append(c + Vector2.from_angle(TAU * i / 20.0) * Vector2(rx, ry))
	return pts
