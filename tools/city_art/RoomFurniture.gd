extends RefCounted
## 시설 실내 가구 무리 그림(tools/paint_rooms.gd 전용 — CT66): 범례 shape → 투명 그림(가로 = 무리 폭 + 여백, 아래 끝 = 무리 아래 끝 — RoomWorld가 발을 맞춘다).
## 무리 모양: table(윗면 top) · desk · counter(variant) · altar · candles · pew · anvil · bench · block(top) · tall(top — books · jars · boxes) · bed · font · booth · bell · pile ·
##   forge · grille · fence. 칸마다 하나씩 세우는 것(barrel · crate · sack · seat · post · pillar · urn · dummy · stand · target · globe · pump · wheel ·
##   pot · lectern · rack)은 RoomFurniture2. 빛 나는 가구(light)는 불꽃 둘레 번짐. 칠한 뒤 빛 · Ink.grade · Ink.finish.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")
const RoomProps := preload("res://tools/city_art/RoomProps.gd")
const RoomProps2 := preload("res://tools/city_art/RoomProps2.gd")
const RoomFurniture2 := preload("res://tools/city_art/RoomFurniture2.gd")

const PAD := 10
const PER_CELL := ["barrel", "crate", "sack", "seat", "post", "pillar", "urn", "dummy", "stand", "target", "globe", "pump", "wheel", "pot", "lectern", "rack"]


static func paint(d: Dictionary, size: Vector2i, t: int, seed_value: int) -> Paint:
	var shape := JsonUtil.get_str(d, "shape", "block")
	var col := Color.from_string(JsonUtil.get_str(d, "color", "#5a3e28"), Color("#5a3e28"))
	var variant := JsonUtil.get_str(d, "variant", JsonUtil.get_str(d, "top"))
	if shape in PER_CELL:
		return RoomFurniture2.per_cell(shape, d, size, t, seed_value)
	match shape:
		"counter":
			if size.y == 1:
				return RoomProps2.counter(t, seed_value, size, variant)
		"altar":
			return RoomProps2.altar(t, seed_value, size, variant)
		"candles":
			if size.y == 1 and size.x > 1:
				return RoomProps2.candles(t, seed_value, size, variant)
			return RoomFurniture2.per_cell("post", d, size, t, seed_value)
		"pew":
			if size.y == 1:
				return RoomProps2.pew(t, seed_value, size, variant)
		"anvil":
			return RoomProps2.anvil(t, seed_value, size, variant)
		"bench":
			if size.y == 1:
				return RoomProps2.bench(t, seed_value, size, variant)
	if shape == "door":
		return _door(t, seed_value, col)
	var lift := {"table": 0.5, "desk": 0.6, "block": 0.6, "tall": 1.3, "bed": 0.35, "font": 0.55, "booth": 1.6, "bell": 1.2, "pile": 0.3,
		"forge": 0.7, "grille": 1.1, "fence": 0.7, "counter": 0.62, "pew": 0.42, "bench": 0.4}.get(shape, 0.6) as float
	var p := Paint.new(size.x * t + PAD * 2, size.y * t + int(lift * t) + 70, seed_value)
	var foot := Rect2(PAD, p.h - size.y * t, size.x * t, size.y * t)
	var lights: Array = []
	match shape:
		"table":
			var top := Rect2(foot.position.x + 4, foot.position.y - lift * t + 6, foot.size.x - 8, foot.size.y - 10)
			RoomProps._legs(p, top, lift * t, col.darkened(0.4))
			RoomProps._slab(p, top, 8, Mat.planks(p, col, 0, 0, false, 13), Mat.planks(p, col.darkened(0.25), 0, 0, false, 7))
			_items(p, top, variant, t)
			if JsonUtil.get_bool(d, "light"):
				lights.append(_candle_on(p, top))
		"desk", "block", "forge", "counter", "pew", "bench":
			var top := Rect2(foot.position.x + 2, foot.position.y - lift * t + 6, foot.size.x - 4, foot.size.y - 10)
			var front: Callable = Mat.brick(p, col.darkened(0.3), 0, 0, 16, 7) if shape == "forge" else (Mat.ashlar(p, col.darkened(0.2), 0, 0, 30, 14) if variant == "lid" else Mat.planks(p, col.darkened(0.25), 0, 0, true, 10))
			var top_sh: Callable = Mat.ashlar(p, col, 0, 0, 34, 18) if variant == "lid" or shape == "forge" else Mat.planks(p, col, 0, 0, false, 12)
			RoomProps._slab(p, top, lift * t - 6, top_sh, front)
			if shape == "forge":
				lights.append(_fire(p, top))
			else:
				_items(p, top, variant if shape != "desk" else "papers", t)
			if shape == "desk" or (JsonUtil.get_bool(d, "light") and shape != "forge"):
				var lamp := Vector2(top.position.x + 18, top.position.y + top.size.y * 0.4)
				RoomProps._oil_lamp(p, lamp)
				lights.append(lamp)
		"tall":
			var top := Rect2(foot.position.x + 3, foot.position.y - lift * t + 4, foot.size.x - 6, foot.size.y * 0.5)
			RoomProps._slab(p, top, lift * t - 4 + foot.size.y * 0.3, Mat.planks(p, col.lightened(0.05), 0, 0, false, 12), func(x: int, y: int) -> Color:
				var shelf := posmod(int(y - top.end.y), int(t * 0.42)) < 4
				return p.vary(col.darkened(0.45) if shelf else col.darkened(0.15), x, y, 0.15))
			_shelf_items(p, Rect2(top.position.x, top.end.y, top.size.x, lift * t - 4 + foot.size.y * 0.3), variant, t)
		"bed":
			var top := Rect2(foot.position.x + 3, foot.position.y - lift * t + 4, foot.size.x - 6, foot.size.y - 8)
			RoomProps._slab(p, top, lift * t - 2, Mat.planks(p, col, 0, 0, false, 10), Mat.planks(p, col.darkened(0.3), 0, 0, false, 8))
			var blanket := Paint.rect_poly(top.position.x + 4, top.position.y + top.size.y * 0.3, top.size.x - 8, top.size.y * 0.66)
			p.fill_poly(blanket, p.flat(Color("#6a2a24"), 0.15))
			Ink.path(p, blanket, 1.4)
			var pillow := Paint.rect_poly(top.position.x + top.size.x * 0.2, top.position.y + 4, top.size.x * 0.6, top.size.y * 0.2)
			p.fill_poly(pillow, p.flat(Color("#c8bca0"), 0.1))
			Ink.path(p, pillow, 1.2)
		"font":
			var c := Vector2(foot.get_center().x, foot.position.y - lift * t + foot.size.y * 0.4)
			var bowl := _ellipse(c, foot.size.x * 0.42, foot.size.y * 0.32)
			Ink.line(p, Vector2(c.x, c.y), Vector2(c.x, foot.end.y - 6), foot.size.x * 0.25, Color("#6a6458"), 1.0, 0.2)
			p.fill_poly(bowl, p.flat(Color("#8a8478"), 0.1))
			p.fill_poly(_ellipse(c, foot.size.x * 0.34, foot.size.y * 0.24), p.flat(col, 0.12))
			Ink.path(p, bowl, 1.8)
		"booth":
			var top := Rect2(foot.position.x + 2, foot.position.y - lift * t + 4, foot.size.x - 4, foot.size.y * 0.6)
			RoomProps._slab(p, top, lift * t, Mat.planks(p, col.lightened(0.1), 0, 0, false, 12), Mat.planks(p, col, 0, 0, true, 9))
			var cur := Paint.rect_poly(top.position.x + top.size.x * 0.25, top.end.y + 6, top.size.x * 0.5, lift * t - 10)
			p.fill_poly(cur, p.flat(Color("#4a1e22"), 0.15))
			Ink.path(p, cur, 1.4)
		"bell":
			var c := Vector2(foot.get_center().x, foot.position.y)
			Ink.line(p, Vector2(foot.position.x, c.y - t * 1.1), Vector2(foot.end.x, c.y - t * 1.1), 6.0, Color("#3a281b"), 1.0, 0.2)
			var bell := Paint.poly([c + Vector2(-t * 0.25, -t * 1.05), c + Vector2(t * 0.25, -t * 1.05), c + Vector2(t * 0.42, -t * 0.25), c + Vector2(t * 0.62, -t * 0.05), c + Vector2(-t * 0.62, -t * 0.05), c + Vector2(-t * 0.42, -t * 0.25)])
			p.fill_poly(bell, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.25 * clampf(1.0 - (x - c.x + t * 0.6) / (t * 1.2), 0.0, 1.0)), x, y, 0.1))
			Ink.path(p, bell, 2.0)
		"pile":
			for k in size.x * size.y * 6:
				var a := Vector2(foot.position.x + p.rng.randf_range(4, foot.size.x - 4), foot.position.y + p.rng.randf_range(4, foot.size.y - 2))
				var s := p.rng.randf_range(t * 0.12, t * 0.24)
				var chunk := Paint.poly([a + Vector2(-s, 0), a + Vector2(-s * 0.4, -s * 0.9), a + Vector2(s * 0.5, -s * 0.8), a + Vector2(s, 0)])
				p.fill_poly(chunk, p.flat(col.lightened(p.rng.randf_range(-0.15, 0.15)), 0.12))
				Ink.path(p, chunk, 1.0, true, Ink.INK, 0.7)
		"grille":
			Ink.line(p, Vector2(foot.position.x, foot.end.y - lift * t), Vector2(foot.end.x, foot.end.y - lift * t), 4.0, col.lightened(0.2), 1.0, 0.1)
			var x := foot.position.x + 4
			while x < foot.end.x:
				Ink.line(p, Vector2(x, foot.end.y - 4), Vector2(x, foot.end.y - lift * t), 2.5, col, 1.0, 0.05)
				x += 9
		"fence":
			for c in size.x * size.y:
				var cx := foot.position.x + (c % size.x + 0.5) * t
				var gy := foot.position.y + (c / size.x + 0.8) * t
				Ink.line(p, Vector2(cx, gy), Vector2(cx, gy - lift * t), 5.0, col, 1.0, 0.2)
			for yy: float in [0.35, 0.75]:
				Ink.line(p, Vector2(foot.position.x + 4, foot.position.y + t * 0.8 - lift * t * yy), Vector2(foot.end.x - 4, foot.end.y - t * 0.2 - lift * t * yy), 4.0, col.lightened(0.1), 1.0, 0.3)
	return done(p, lights, 0.86)


## 잠긴 문(1칸): 아치 나무 문 + 쇠띠 + 고리 — 벽 줄 높이로 세운다(RoomWorld가 지금 잠겨 있을 때만 세운다).
static func _door(t: int, seed_value: int, col: Color) -> Paint:
	var p := Paint.new(t + PAD * 2, int(t * 1.6), seed_value)
	var dr := Paint.arch_poly(PAD + 2, 4, t - 4, p.h - 6, false)
	p.fill_poly(dr, Mat.planks(p, col, 0, 0, true, 8))
	for k in 2:
		Ink.line(p, Vector2(PAD + 2, p.h * (0.35 + k * 0.35)), Vector2(PAD + t - 2, p.h * (0.35 + k * 0.35)), 3.0, Color("#3a3c40"), 1.0, 0.1)
	p.fill_poly(_ellipse(Vector2(PAD + t * 0.7, p.h * 0.55), 4, 4), p.flat(Color("#8a7448"), 0.1))
	Ink.path(p, dr, 2.0)
	return done(p, [], 0.86)


## 빛·색 보정·그레인. lights = 불꽃 자리들(둘레를 밝히고 번짐).
static func done(p: Paint, flames: Array, ambient: float) -> Paint:
	var ls: Array = []
	for f: Vector2 in flames:
		ls.append([f, 110.0, RoomArt.WARM, 0.8])
	RoomArt.light(p, ls, ambient)
	for f: Vector2 in flames:
		Ink.glow(p, f.x, f.y - 10, 20, RoomArt.WARM, 0.45)
	Ink.grade(p, 0.12, 1.05)
	Ink.finish(p, 0.04, 0.0)
	return p


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		pts.append(c + Vector2.from_angle(TAU * i / 20.0) * Vector2(rx, ry))
	return pts


## 윗면에 놓인 것(top·variant).
static func _items(p: Paint, top: Rect2, v: String, t: int) -> void:
	var at := func(fx: float, fy: float) -> Vector2: return Vector2(top.position.x + top.size.x * fx, top.position.y + top.size.y * fy)
	match v:
		"books", "":
			Bits.open_book(p, at.call(0.45, 0.3), minf(15.0, top.size.x * 0.18))
			RoomProps._book_stack(p, at.call(0.15, 0.7), 2)
		"inn", "mugs":
			for k in 3:
				Bits.mug(p, at.call(0.3 + k * 0.2, 0.5 + (k % 2) * 0.25).x, at.call(0.3 + k * 0.2, 0.5 + (k % 2) * 0.25).y)
		"guild", "papers", "map":
			var map := Paint.rect_poly(top.position.x + top.size.x * 0.2, top.position.y + 4, top.size.x * 0.55, top.size.y - 8)
			p.fill_poly(map, p.flat(Color("#b8a47c"), 0.15))
			Ink.path(p, map, 1.0)
			for k in 4:
				var a: Vector2 = at.call(0.25 + k * 0.12, 0.3 + (k % 2) * 0.3)
				Ink.line(p, a, a + Vector2(10, 5), 1.0, Color("#5a2a1a"), 0.6, 0.6)
		"potions":
			RoomProps2._bottles(p, at.call(0.2, 0.7), maxi(3, int(top.size.x / 12.0)))
		"food":
			p.fill_rect(top.position.x + top.size.x * 0.3, top.position.y + 6, 22, 9, p.flat(Color("#8a6a3a"), 0.15))
			p.fill_rect(top.position.x + top.size.x * 0.6, top.position.y + 8, 16, 7, p.flat(Color("#7a3a2a"), 0.15))
		"cloth":
			p.fill_rect(top.position.x + 4, top.position.y + 3, top.size.x - 8, top.size.y - 6, p.flat(Color("#a89878"), 0.1))
		"coins":
			Bits.coins(p, at.call(0.5, 0.6))
		"lid":
			Ink.line(p, at.call(0.5, 0.15), at.call(0.5, 0.85), 2.0, Color("#3a3630"), 0.8, 0.2)
			Ink.line(p, at.call(0.3, 0.4), at.call(0.7, 0.4), 2.0, Color("#3a3630"), 0.8, 0.2)
		"lute":
			p.fill_poly(_ellipse(at.call(0.5, 0.55), top.size.x * 0.18, top.size.y * 0.3), p.flat(Color("#9a6a30"), 0.12))
			Ink.line(p, at.call(0.5, 0.4), at.call(0.95, 0.1), 3.0, Color("#5a3a20"), 1.0, 0.1)
		"scrolls":
			for k in 3:
				var a: Vector2 = at.call(0.2, 0.3 + k * 0.2)
				Ink.line(p, a, a + Vector2(top.size.x * 0.6, -3), 6.0, Color("#b8a882"), 1.0, 0.2)
		"seal":
			p.fill_poly(_ellipse(at.call(0.5, 0.5), 7, 5), p.flat(Color("#8a2a24"), 0.1))
		"bellows":
			var b := Paint.poly([at.call(0.15, 0.3), at.call(0.85, 0.15), at.call(0.85, 0.85), at.call(0.15, 0.7)])
			p.fill_poly(b, p.flat(Color("#5a3a26"), 0.15))
			Ink.path(p, b, 1.4)


static func _shelf_items(p: Paint, front: Rect2, v: String, t: int) -> void:
	var rows := maxi(1, int(front.size.y / (t * 0.42)))
	for r in rows:
		var ground := front.position.y + (r + 1) * front.size.y / rows - 4
		var x := front.position.x + 6
		while x < front.end.x - 8:
			var hh := p.rng.randf_range(8, 14)
			var c: Color = [Color("#2f4430"), Color("#4e2a1c"), Color("#6a7a6a"), Color("#7a6a4a")][p.rng.randi() % 4]
			if v == "jars":
				p.fill_rect(x, ground - hh, 8, hh, p.flat(c.lightened(0.2), 0.15), 0.85)
			elif v == "boxes":  # 서랍·대여 금고 칸: 놋쇠 손잡이 단 네모
				var bw := 14.0
				p.fill_rect(x, ground - 13, bw, 12, p.flat(Color("#6a5a44").lerp(c, 0.2), 0.12))
				p.fill_rect(x + bw * 0.5 - 2, ground - 8, 4, 3, p.flat(Color("#c8a048"), 0.1))
				x += bw - 4
			else:
				p.fill_rect(x, ground - hh, 5, hh, p.flat(c, 0.2))
			x += 9


## 윗면의 초 하나(빛) — 불꽃 자리를 돌려준다.
static func _candle_on(p: Paint, top: Rect2) -> Vector2:
	var c := Vector2(top.position.x + top.size.x * 0.82, top.position.y + top.size.y * 0.45)
	RoomProps._candle(p, c, 14)
	return c + Vector2(0, -16)


## 화덕 불(윗면 가운데) — 불꽃 자리를 돌려준다.
static func _fire(p: Paint, top: Rect2) -> Vector2:
	var c := top.get_center()
	p.fill_poly(_ellipse(c, top.size.x * 0.32, top.size.y * 0.3), p.flat(Color("#2a1208"), 0.1))
	for layer in 3:
		var col: Color = [Color("#b8461c"), Color("#f08a2c"), Color("#ffd27a")][layer]
		for k in 5 - layer:
			var bx := c.x - top.size.x * 0.25 + k * top.size.x * 0.12 + layer * 6
			var fh := (34.0 - layer * 9.0) * p.rng.randf_range(0.7, 1.2)
			p.fill_poly(Paint.poly([Vector2(bx - 7, c.y), Vector2(bx, c.y - fh), Vector2(bx + 7, c.y)]), p.flat(col, 0.08))
	return c
