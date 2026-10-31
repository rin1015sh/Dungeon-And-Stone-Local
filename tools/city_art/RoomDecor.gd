extends RefCounted
## 시설 실내 바닥 층 장식(RoomPaint 전용): 깔개 · 바닥 장식 무리(style — dais 제단 단 · steps 단 계단 · mosaic 원형 상감 · rosette 장미 원판 ·
## bones 뼈 · straw 짚 · footprints 발자국 · feathers 깃털·먼지 · scrap 버린 쇠 · rope 줄 · trap 쥐덫 · 그 밖은 RoomLitter 흩어진 것) · 계단 · 사다리 · 트인 곳 · 난간(문턱은 RoomWallForm).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const RoomLitter := preload("res://tools/city_art/RoomLitter.gd")


static func _hex(d: Dictionary, fallback: String) -> Color:
	return Color.from_string(JsonUtil.get_str(d, "color", fallback), Color(fallback))


## 깔개 무리: 바탕색 + 테두리 띠 + 마름모 무늬 + 닳은 자국.
static func rugs(p: Paint, rows: PackedStringArray, legend: Dictionary, t: int) -> void:
	for g: Dictionary in CityRoom.groups(rows, legend, ["rug"]):
		var rc: Rect2i = g["rect"]
		var base := _hex(JsonUtil.get_dict(legend, str(g["char"])), "#7a3a34")
		var r := Rect2(rc.position * t, rc.size * t).grow(-t * 0.08)
		var band := minf(r.size.x, r.size.y) * 0.14
		var cells := {}
		for c: Vector2i in g["cells"]:
			cells[c] = true
		p.fill_rect(r.position.x, r.position.y, r.size.x, r.size.y, func(x: int, y: int) -> Color:
			if not cells.has(Vector2i(floori(x / float(t)), floori(y / float(t)))):
				return Color(0, 0, 0, 0)
			var e := minf(minf(x - r.position.x, r.end.x - x), minf(y - r.position.y, r.end.y - y))
			var c := base
			if e < band * 0.4:
				c = base.darkened(0.4)
			elif e < band:
				c = Color("#86683c")
			else:
				var dd := absf(posmod(y - r.position.y, t) - t * 0.5) + absf(posmod(x - r.position.x, t) - t * 0.5)
				if absf(dd - t * 0.3) < 1.5:
					c = Color("#9a7a48")
			return p.vary(c.lerp(Color("#6a5a48"), clampf((p.nz("lo", x, y) - 0.55) * 1.4, 0.0, 0.45)), x, y, 0.16))


## 바닥 장식 무리(style).
static func decor(p: Paint, rows: PackedStringArray, legend: Dictionary, t: int) -> void:
	var gs := CityRoom.groups(rows, legend, ["decor"])
	var style_of := func(g: Dictionary) -> String: return JsonUtil.get_str(JsonUtil.get_dict(legend, str(g["char"])), "style")
	var mosaics := gs.filter(func(g: Dictionary) -> bool: return style_of.call(g) == "mosaic")
	gs = mosaics + gs.filter(func(g: Dictionary) -> bool: return style_of.call(g) != "mosaic")  # 상감 바닥을 먼저 — 장미 원판이 그 위에
	for g: Dictionary in gs:
		var d := JsonUtil.get_dict(legend, str(g["char"]))
		var rc: Rect2i = g["rect"]
		var col := _hex(d, "#8a8478")
		var cells: Array = g["cells"]
		match JsonUtil.get_str(d, "style"):
			"dais":
				for c: Vector2i in cells:
					p.fill_rect(c.x * t, c.y * t, t, t, Mat.ashlar(p, col, 0, 0, int(t * 0.9), int(t * 0.5)))
				Ink.path(p, Paint.rect_poly(rc.position.x * t, rc.position.y * t, rc.size.x * t, rc.size.y * t), 2.0, true, Ink.INK, 0.6)
				p.fill_rect(rc.position.x * t, rc.end.y * t - 4, rc.size.x * t, 4, p.flat(col.darkened(0.45), 0.05))
			"steps":
				for c: Vector2i in cells:
					p.fill_rect(c.x * t, c.y * t, t, t * 0.5, p.flat(col.lightened(0.08), 0.06))
					p.fill_rect(c.x * t, c.y * t + t * 0.5, t, t * 0.5, p.flat(col.darkened(0.25), 0.06))
			"mosaic":
				var ctr := (Vector2(rc.position) + Vector2(rc.size) * 0.5) * t
				var rad := minf(rc.size.x, rc.size.y) * 0.5 * t
				cells = []
				for yy in range(rc.position.y, rc.end.y):  # 상감 둘레 안의 장미 원판 칸도 바탕을 깐다(네모 이음매가 없게)
					for xx in range(rc.position.x, rc.end.x):
						if JsonUtil.get_str(JsonUtil.get_dict(legend, rows[yy][xx]), "kind") == "decor":
							cells.append(Vector2i(xx, yy))
				for c: Vector2i in cells:
					p.fill_rect(c.x * t, c.y * t, t, t, func(x: int, y: int) -> Color:
						var dd := Vector2(x, y).distance_to(ctr) / rad
						var cc := col
						if absf(dd - 0.95) < 0.04 or absf(dd - 0.62) < 0.03:
							cc = Color("#b8b0a0")
						elif dd > 0.62:
							cc = col.darkened(0.12) if posmod(int(atan2(y - ctr.y, x - ctr.x) * 12.0 / PI), 2) == 0 else col.lightened(0.05)
						return p.vary(cc, x, y, 0.1))
			"rosette":
				for c: Vector2i in cells:
					var cc := (Vector2(c) + Vector2(0.5, 0.5)) * t
					p.fill_rect(c.x * t, c.y * t, t, t, func(x: int, y: int) -> Color:
						var v := Vector2(x, y) - cc
						var dd := v.length() / (t * 0.48)
						if dd > 1.0:
							return Color(0, 0, 0, 0)
						var petal := 0.5 + 0.5 * cos(atan2(v.y, v.x) * 8.0)
						return p.vary(col.lightened(0.15 * petal) if dd > 0.3 else Color("#b8a87a"), x, y, 0.08))
					Ink.path(p, _circle(cc, t * 0.48), 1.4, true, Ink.INK, 0.6)
			"bones":
				for c: Vector2i in cells:
					for k in 3:
						var a := Vector2(c.x * t + p.rng.randf_range(6, t - 6), c.y * t + p.rng.randf_range(6, t - 6))
						Ink.line(p, a, a + Vector2.from_angle(p.rng.randf() * TAU) * t * 0.3, 3.0, col, 0.9, 0.2)
			"straw":
				for c: Vector2i in cells:
					for k in 14:
						var a := Vector2(c.x * t + p.rng.randf_range(0, t), c.y * t + p.rng.randf_range(0, t))
						Ink.line(p, a, a + Vector2.from_angle(p.rng.randf() * TAU) * 9.0, 1.4, col, 0.8, 0.2)
			"footprints":
				for c: Vector2i in cells:
					for k in 2:
						var a := Vector2(c.x * t + p.rng.randf_range(8, t - 8), c.y * t + p.rng.randf_range(8, t - 8))
						p.fill_poly(_circle(a, 4.0, 0.55), p.flat(col.darkened(0.3), 0.1), 0.6)
			"feathers", "scrap":
				for c: Vector2i in cells:
					for k in 6:
						var a := Vector2(c.x * t + p.rng.randf_range(0, t), c.y * t + p.rng.randf_range(0, t))
						Ink.line(p, a, a + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-3, 3)), 2.0, col, 0.7, 0.3)
			"rope":
				for c: Vector2i in cells:
					Ink.line(p, Vector2(c.x * t + t * 0.5, c.y * t), Vector2(c.x * t + t * 0.5, c.y * t + t), 3.0, col, 1.0, 0.6)
			"trap":
				for c: Vector2i in cells:
					p.fill_rect(c.x * t + t * 0.3, c.y * t + t * 0.4, t * 0.4, t * 0.25, p.flat(col, 0.1))
			var other:
				RoomLitter.draw(p, other, cells, col, t)


static func _circle(c: Vector2, r: float, squash: float = 1.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		pts.append(c + Vector2.from_angle(TAU * i / 20.0) * Vector2(r, r * squash))
	return pts


## 계단 칸: 위로 오를수록 좁아지는 디딤판 셋(맨 위·맨 아래 칸은 끝 그늘).
static func stairs(p: Paint, x: int, y: int, t: int, has_up: bool, has_down: bool) -> void:
	p.fill_rect(x * t, y * t, t, t, p.flat(Color("#1a1612"), 0.05))
	for k in 3:
		var yy := y * t + k * t / 3.0
		var step := Paint.rect_poly(x * t + 3, yy + 1, t - 6, t / 3.0 - 2)
		p.fill_poly(step, Mat.planks(p, Color("#5a4632").lightened(0.06 * (2 - k)), 0, 0, false, 9))
		Ink.line(p, Vector2(x * t + 3, yy + t / 3.0 - 1), Vector2(x * t + t - 3, yy + t / 3.0 - 1), 1.6, Ink.INK, 0.8, 0.2)
	for side: float in [x * t + 2.0, x * t + t - 2.0]:
		Ink.line(p, Vector2(side, y * t), Vector2(side, y * t + t), 2.0, Color("#2a1f17"), 0.9, 0.2)
	if not has_up:
		Ink.shade(p, Paint.rect_poly(x * t, y * t, t, t * 0.4), Vector2(0, y * t), Vector2(0, y * t + t * 0.4), 0.4, 0.0)


## 사다리 칸: 어두운 틈 위 두 기둥 + 가로대(벽·틈을 지나 위층·지하로 — CT66).
static func ladder(p: Paint, x: int, y: int, t: int, in_shaft: bool) -> void:
	p.fill_rect(x * t, y * t, t, t, p.flat(Color("#141210") if in_shaft else Color("#2a221a"), 0.05))
	var c := Color("#8a6a40")
	for side: float in [x * t + t * 0.24, x * t + t * 0.76]:
		Ink.line(p, Vector2(side, y * t), Vector2(side, y * t + t), 4.0, c, 1.0, 0.15)
	for k in 3:
		var yy := y * t + (k + 0.5) * t / 3.0
		Ink.line(p, Vector2(x * t + t * 0.24, yy), Vector2(x * t + t * 0.76, yy), 3.0, c.darkened(0.15), 1.0, 0.1)


## 트인 곳(아래층이 보인다): 어둠 + 아래 바닥의 흐린 결 + 가장자리 그늘.
static func open_drop(p: Paint, x: int, y: int, t: int, edge: bool) -> void:
	p.fill_rect(x * t, y * t, t, t, func(px: int, py: int) -> Color:
		return p.vary(Color("#16141a").lerp(Color("#2a2620"), p.nz("mid", px, py) * 0.5), px, py, 0.1))
	if edge:
		p.fill_rect(x * t, y * t, t, t * 0.35, p.flat(Color("#3a2c20"), 0.06))


## 난간: 바닥 + 나무 난간대 + 기둥.
static func rail(p: Paint, x: int, y: int, t: int, left_end: bool, right_end: bool) -> void:
	p.fill_rect(x * t, y * t + t * 0.42, t, t * 0.16, p.flat(Color("#6a4a2a"), 0.08))
	Ink.line(p, Vector2(x * t, y * t + t * 0.42), Vector2(x * t + t, y * t + t * 0.42), 1.6, Ink.INK, 0.7, 0.2)
	for k in 2:
		var px := x * t + t * (0.25 + k * 0.5)
		Ink.line(p, Vector2(px, y * t + t * 0.5), Vector2(px, y * t + t * 0.9), 3.0, Color("#4a3420"), 1.0, 0.1)
