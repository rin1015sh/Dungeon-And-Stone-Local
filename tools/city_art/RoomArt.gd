extends RefCounted
## 시설 실내 방 그림(탑뷰 3/4 — data/rooms, CT62; tools/paint_rooms.gd 전용). 칸 T px(= view.floor_tile_px × art_scale).
## 방 한 장 = 바닥(판자·깔개) + 뒷벽 앞면(벽 가구 B 칸 — 책장·창·촛대) + 옆벽·앞벽 윗면(문 틈) + 소품 그림자 + 빛.
## 칠하는 법은 도시 실내 일러스트(Interiors)와 같다: 어둡게 내린 뒤 촛불·창빛 둘레만 다시 밝힌다 → Ink.grade → Ink.finish.
## 소품(탁자·책상·독서대)은 RoomProps가 따로 그린다(화면이 발 높이로 앞뒤를 정한다).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")

const WARM := Color("#ffb060")
const COOL := Color("#9fb2c0")
const VOID := Color("#0b0a09")
const AMBIENT := 0.5


## 도서관 열람실: room = data/rooms/library.json. 돌려주는 값 = 그린 Paint.
static func library(room: Dictionary, t: int, seed_value: int) -> Paint:
	var rows: Array = room["rows"]
	var cols := str(rows[0]).length()
	var p := Paint.new(cols * t, rows.size() * t, seed_value)
	p.fill_rect(0, 0, p.w, p.h, p.flat(VOID, 0.05))
	var lights: Array = []  # [Vector2, 반지름, 색, 세기]
	var floor_r := Rect2(t, 3 * t, (cols - 2) * t, (rows.size() - 4) * t)
	p.fill_rect(floor_r.position.x, floor_r.position.y, floor_r.size.x, floor_r.size.y + t, floor_boards(p, Color("#4a3423"), 21))
	var door := _door_span(rows, t)
	_runner(p, door.x + t * 0.12, 3.25 * t, door.y - door.x - t * 0.24, p.h - 3.25 * t)
	_back_wall(p, cols, t)
	var window_x := door.x  # 창은 문 위 — 가운데 통로 끝
	_window(p, window_x + t * 0.12, 0.42 * t, door.y - door.x - t * 0.24, 2.18 * t)
	lights.append([Vector2((door.x + door.y) * 0.5, 2.0 * t), 3.2 * t, COOL, 0.55])
	_shaft(p, Vector2(door.x + t * 0.2, 3.0 * t), Vector2(door.y - t * 0.2, 3.0 * t), Vector2(door.x - t * 0.6, 7.6 * t), Vector2(door.y + t * 0.9, 7.6 * t), COOL, 0.14)
	var spots: Array = room.get("spots", [])
	for s: Variant in spots:
		var rc := _rect(s as Dictionary)
		if rc.position.y == 1:  # 뒷벽 책장
			_bookcase(p, rc.position.x * t + 5, 0.22 * t, rc.size.x * t - 10, 2.78 * t, t)
	for gx: int in _gaps(spots, cols, door, t):
		var c := Vector2((gx + 0.5) * t, 1.35 * t)
		_sconce(p, c, t)
		lights.append([c + Vector2(0, t * 0.6), 2.4 * t, WARM, 0.62])
	_ladder(p, 4.92 * t, 0.5 * t, 2.5 * t, t)
	_side_walls(p, cols, rows.size(), t)
	_front_wall(p, cols, rows.size(), t, door)
	Ink.shade(p, Paint.rect_poly(t, 3 * t, (cols - 2) * t, 0.7 * t), Vector2(0, 3 * t), Vector2(0, 3.7 * t), 0.55, 0.0)  # 뒷벽 밑 그늘
	for v: Variant in room.get("props", []):
		var d: Dictionary = v
		var rc := _rect(d)
		if not str(d.get("needs", "")).is_empty():
			continue  # 이번 순에만 서는 소품은 그림자도 없이(없을 때 빈 바닥)
		_prop_shadow(p, rc, t)
		match str(d.get("id", "")):
			"desk":
				lights.append([Vector2((rc.position.x + 0.4) * t, (rc.position.y + 0.1) * t), 2.6 * t, WARM, 0.7])
			_:
				if str(d.get("id", "")).begins_with("table"):
					lights.append([Vector2((rc.position.x + rc.size.x * 0.5) * t, (rc.position.y + 0.4) * t), 2.4 * t, WARM, 0.55])
	_grime(p, floor_r)
	light(p, lights, AMBIENT)
	Ink.grade(p, 0.24, 1.12)
	Ink.finish(p, 0.04, 0.45)
	return p


## 문 칸(D)의 x 범위(px): Vector2(왼쪽, 오른쪽).
static func _door_span(rows: Array, t: int) -> Vector2:
	var last := str(rows[rows.size() - 1])
	var a := last.find("D")
	var b := last.rfind("D")
	return Vector2(a * t, (b + 1) * t) if a >= 0 else Vector2(last.length() * t * 0.5 - t, last.length() * t * 0.5 + t)


static func _rect(d: Dictionary) -> Rect2i:
	var r: Array = d.get("rect", [0, 0, 0, 0])
	return Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))


## 책장 사이 빈 칸(창 자리 빼고) — 촛대를 단다.
static func _gaps(spots: Array, cols: int, door: Vector2, t: int) -> Array[int]:
	var used := {}
	for s: Variant in spots:
		var rc := _rect(s as Dictionary)
		if rc.position.y == 1:
			for x in range(rc.position.x, rc.end.x):
				used[x] = true
	var out: Array[int] = []
	for x in range(1, cols - 1):
		if not used.has(x) and (x * t < door.x or x * t >= door.y):
			out.append(x)
	return out


## 판자 바닥(위에서 본 — 가로 판, 판마다 이음매가 엇갈린다).
static func floor_boards(p: Paint, base: Color, bh: int) -> Callable:
	return func(x: int, y: int) -> Color:
		var row := floori(y / float(bh))
		var ly := posmod(y, bh)
		var len := 150 + int(Paint.hash01(row, 3) * 120.0)
		var lx := posmod(x + int(Paint.hash01(row, 9) * 400.0), len)
		var idx := floori((x + int(Paint.hash01(row, 9) * 400.0)) / float(len))
		if ly == 0 or lx == 0:
			return p.vary(Color("#100b08"), x, y, 0.1)
		var tone := base.lightened((Paint.hash01(row, idx, 5) - 0.5) * 0.3)
		tone = tone.darkened(absf(p.nz("hs", x, y) - 0.5) * 0.45)
		if ly == 1:
			tone = tone.lightened(0.12)
		elif ly >= bh - 2:
			tone = tone.darkened(0.3)
		return p.vary(tone, x, y, 0.16)


## 가운데 통로 깔개: 바랜 붉은 바탕 · 황토 테두리 · 마름모 무늬 · 닳은 자국 · 문 쪽 끝 올이 풀림.
static func _runner(p: Paint, x: float, y: float, rw: float, rh: float) -> void:
	var band := rw * 0.12
	var sh := func(px: int, py: int) -> Color:
		var u := (px - x) / rw
		var v := py - y
		var edge := minf(u, 1.0 - u) * rw
		var c := Color("#5a2622")
		if edge < band * 0.35:
			c = Color("#3a1a16")
		elif edge < band:
			c = Color("#86683c")
		else:
			var d := absf(posmod(v, rw * 0.9) - rw * 0.45) + absf(u - 0.5) * rw
			if absf(d - rw * 0.28) < 3.0:
				c = Color("#9a7a48")
		var wear := p.nz("lo", px, py)
		c = c.lerp(Color("#6a5a48"), clampf((wear - 0.55) * 1.6, 0.0, 0.5))
		return p.vary(c, px, py, 0.18)
	var poly := Paint.rect_poly(x, y, rw, rh)
	p.fill_poly(poly, sh)
	Ink.path(p, poly, 1.6, true, Ink.INK, 0.5)
	for k in int(rw / 5.0):  # 올 풀린 끝(문 쪽)
		var fx := x + 3 + k * 5
		Ink.line(p, Vector2(fx, y + rh - 4), Vector2(fx + p.rng.randf_range(-2, 2), y + rh + 3), 1.2, Color("#86683c"), 0.6, 0.4)


## 뒷벽: 위 처마(짙은 들보) + 돌벽 앞면 + 밑 굽도리.
static func _back_wall(p: Paint, cols: int, t: int) -> void:
	p.fill_rect(t, 0.18 * t, (cols - 2) * t, 2.82 * t, Mat.ashlar(p, Color("#4a463e"), 0, 0, 58, 26))
	Ink.shade(p, Paint.rect_poly(t, 0.18 * t, (cols - 2) * t, 2.82 * t), Vector2(0, 0.2 * t), Vector2(0, 3 * t), 0.55, 0.15)
	var beam := Paint.rect_poly(t * 0.6, 0, (cols - 1.2) * t, 0.3 * t)
	p.fill_poly(beam, Mat.beam(p, Color("#2a1e15")))
	Ink.path(p, beam, 2.0)
	var skirt := Paint.rect_poly(t, 2.86 * t, (cols - 2) * t, 0.14 * t)
	p.fill_poly(skirt, Mat.planks(p, Color("#2e2117"), 0, 0, false, 9))
	Ink.line(p, Vector2(t, 3 * t), Vector2((cols - 1) * t, 3 * t), 2.2, Ink.INK, 0.85, 0.6)


## 벽에 붙은 책장(앞면): 짙은 틀 · 책 칸(Bits.books_shader) · 위 갓 · 아래 서랍 받침.
static func _bookcase(p: Paint, x: float, y: float, bw: float, bh: float, t: int) -> void:
	var frame := Paint.rect_poly(x, y, bw, bh)
	p.fill_poly(frame, Mat.planks(p, Color("#3a281b"), int(x), 0, true, 11))
	var inner := Paint.rect_poly(x + 7, y + 0.18 * t, bw - 14, bh - 0.62 * t)
	p.fill_poly(inner, Bits.books_shader(p))
	Ink.shade(p, inner, Vector2(0, y), Vector2(0, y + bh), 0.35, 0.05)
	Ink.path(p, inner, 1.6)
	var crown := Paint.rect_poly(x - 4, y - 4, bw + 8, 0.16 * t)
	p.fill_poly(crown, Mat.beam(p, Color("#30221a")))
	Ink.path(p, crown, 1.8)
	var base := Paint.rect_poly(x + 4, y + bh - 0.42 * t, bw - 8, 0.38 * t)
	p.fill_poly(base, Mat.planks(p, Color("#33241a"), 0, 0, false, 12))
	Ink.path(p, base, 1.6)
	for k in 2:  # 서랍 손잡이
		p.fill_rect(x + bw * (0.3 + k * 0.4) - 3, y + bh - 0.24 * t, 6, 3, p.flat(Color("#8a7448"), 0.1))
	Ink.path(p, frame, 2.4)


## 가운데 높은 창(뾰족 아치): 흐린 하늘빛 유리 · 납 창살 · 돌 틀 · 창턱.
static func _window(p: Paint, x: float, y: float, ww: float, wh: float) -> void:
	var outer := Paint.arch_poly(x - 8, y - 8, ww + 16, wh + 16, true)
	p.fill_poly(outer, Mat.ashlar(p, Color("#5a564c"), int(x), int(y), 30, 18))
	Ink.path(p, outer, 2.2)
	var glass := Paint.arch_poly(x, y, ww, wh, true)
	p.fill_poly(glass, func(px: int, py: int) -> Color:
		var v := clampf((py - y) / wh, 0.0, 1.0)
		var c := Color("#8a9aa4").lerp(Color("#4c5862"), v)
		if posmod(px - int(x), int(ww / 3.0)) < 2 or posmod(py - int(y), 22) < 2:
			c = Color("#1c1e1e")
		return p.vary(c, px, py, 0.12))
	Ink.path(p, glass, 2.0)
	var sill := Paint.rect_poly(x - 12, y + wh, ww + 24, 9)
	p.fill_poly(sill, p.flat(Color("#5e5a50"), 0.1))
	Ink.path(p, sill, 1.6)


## 창빛 줄기(바닥 위 사다리꼴, 더하기 빛 — 멀수록 옅게).
static func _shaft(p: Paint, a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2, c: Color, strength: float) -> void:
	var poly := Paint.poly([a0, a1, b1, b0])
	var r := Paint.bounds(poly)
	for y in range(int(r.position.y), int(r.end.y)):
		var tt := clampf((y - a0.y) / maxf(1.0, b0.y - a0.y), 0.0, 1.0)
		for x in range(int(r.position.x), int(r.end.x)):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), poly):
				p.add_light(x, y, c, strength * (1.0 - tt * 0.8) * (0.6 + 0.6 * p.nz("vs", x, y)))


## 벽 촛대: 쇠 받침 + 초 + 불꽃.
static func _sconce(p: Paint, c: Vector2, t: int) -> void:
	var plate := Paint.rect_poly(c.x - 5, c.y - 4, 10, 18)
	p.fill_poly(plate, p.flat(Color("#2a2622"), 0.1))
	Ink.path(p, plate, 1.4)
	Ink.line(p, c + Vector2(0, 10), c + Vector2(0, 22), 3.0, Color("#26221e"), 1.0, 0.2)
	var dish := Paint.rect_poly(c.x - 9, c.y + 20, 18, 5)
	p.fill_poly(dish, p.flat(Color("#3a342c"), 0.1))
	var candle := Paint.rect_poly(c.x - 3, c.y + 4, 6, 16)
	p.fill_poly(candle, p.flat(Color("#d8cfb4"), 0.1))
	Ink.path(p, candle, 1.0)
	_flame(p, Vector2(c.x, c.y + 3), 1.0)
	Ink.glow(p, c.x, c.y, t * 0.9, WARM, 0.45)


static func _flame(p: Paint, base: Vector2, s: float) -> void:
	for layer in 3:
		var col: Color = [Color("#c2541e"), Color("#f39a3a"), Color("#ffe2a0")][layer]
		var fh := (12.0 - layer * 3.5) * s
		var fw := (4.0 - layer) * s
		p.fill_poly(Paint.poly([base + Vector2(-fw, 0), base + Vector2(0, -fh), base + Vector2(fw, 0), base + Vector2(0, fw * 0.6)]), p.flat(col, 0.08))


## 책장에 기대 세운 사다리(앞면).
static func _ladder(p: Paint, x: float, top: float, lh: float, t: int) -> void:
	var c := Color("#4a3424")
	Ink.line(p, Vector2(x, top), Vector2(x - 0.18 * t, top + lh), 5.0, c, 1.0, 0.3)
	Ink.line(p, Vector2(x + 0.42 * t, top), Vector2(x + 0.24 * t, top + lh), 5.0, c, 1.0, 0.3)
	for k in 8:
		var f := (k + 0.6) / 8.6
		Ink.line(p, Vector2(x - 0.18 * t * f, top + lh * f), Vector2(x + 0.42 * t - 0.18 * t * f, top + lh * f), 3.0, c.darkened(0.15), 1.0, 0.2)


## 옆벽 윗면(위에서 본 돌 머리) + 안쪽 테 + 바닥에 지는 그늘.
static func _side_walls(p: Paint, cols: int, rows_n: int, t: int) -> void:
	for side in 2:
		var x: float = 0.0 if side == 0 else float((cols - 1) * t)
		var cap := Paint.rect_poly(x, 0, t, rows_n * t)
		p.fill_poly(cap, Mat.ashlar(p, Color("#3c3a34"), int(x), 0, 30, 46))
		Ink.shade(p, cap, Vector2(x + (t if side == 0 else 0), 0), Vector2(x + (0 if side == 0 else t), 0), 0.0, 0.5)
		var edge: float = x + (float(t) if side == 0 else 0.0)
		Ink.line(p, Vector2(edge, 0), Vector2(edge, rows_n * t), 2.4, Ink.INK, 0.9, 0.6)
		var fall := Paint.rect_poly(edge if side == 0 else edge - 0.6 * t, 3 * t, 0.6 * t, (rows_n - 4) * t)
		Ink.shade(p, fall, Vector2(edge, 0), Vector2(edge + (0.6 * t if side == 0 else -0.6 * t), 0), 0.5, 0.0)


## 앞벽 윗면(아래 끝 줄) + 문 틈(닳은 문턱 · 바깥 어둠 · 돌 문설주).
static func _front_wall(p: Paint, cols: int, rows_n: int, t: int, door: Vector2) -> void:
	var y := (rows_n - 1) * t
	for seg: Vector2 in [Vector2(0, door.x), Vector2(door.y, cols * t)]:
		var cap := Paint.rect_poly(seg.x, y + 0.2 * t, seg.y - seg.x, 0.8 * t)
		p.fill_poly(cap, Mat.ashlar(p, Color("#3c3a34"), 0, int(y), 46, 30))
		Ink.shade(p, cap, Vector2(0, y), Vector2(0, y + t), 0.0, 0.45)
		Ink.line(p, Vector2(seg.x, y + 0.2 * t), Vector2(seg.y, y + 0.2 * t), 2.4, Ink.INK, 0.9, 0.6)
	var sill := Paint.rect_poly(door.x, y + 0.25 * t, door.y - door.x, 0.3 * t)
	p.fill_poly(sill, Mat.ashlar(p, Color("#625c50"), int(door.x), int(y), 40, 14))
	var out := Paint.rect_poly(door.x, y + 0.55 * t, door.y - door.x, 0.45 * t)
	p.fill_poly(out, func(px: int, py: int) -> Color: return p.vary(Color("#1a1d20").lerp(VOID, clampf((py - y - 0.55 * t) / (0.45 * t), 0.0, 1.0)), px, py, 0.1))
	for jx: float in [door.x - 0.12 * t, door.y - 0.06 * t]:
		var jamb := Paint.rect_poly(jx, y - 0.1 * t, 0.18 * t, 1.1 * t)
		p.fill_poly(jamb, Mat.ashlar(p, Color("#55514a"), int(jx), int(y), 14, 22))
		Ink.path(p, jamb, 1.8)


## 소품 발밑 그림자(바닥에 번진 타원).
static func _prop_shadow(p: Paint, rc: Rect2i, t: int) -> void:
	var c := (Vector2(rc.position) + Vector2(rc.size) * Vector2(0.5, 0.62)) * t
	var r := Vector2(rc.size) * t * Vector2(0.62, 0.62)
	for y in range(int(c.y - r.y), int(c.y + r.y)):
		for x in range(int(c.x - r.x), int(c.x + r.x)):
			var d := Vector2((x - c.x) / r.x, (y - c.y) / r.y).length()
			if d < 1.0:
				p.tint(x, y, Color("#080605"), (1.0 - d) * 0.55)


## 바닥 때·얼룩·긁힌 자국.
static func _grime(p: Paint, r: Rect2) -> void:
	for k in 60:
		var x := p.rng.randf_range(r.position.x, r.end.x)
		var y := p.rng.randf_range(r.position.y, r.end.y)
		Ink.grime(p, x, y, p.rng.randf_range(6, 26), p.rng.randf_range(4, 14), 0.22)
	for k in 30:
		var a := Vector2(p.rng.randf_range(r.position.x, r.end.x), p.rng.randf_range(r.position.y, r.end.y))
		Ink.line(p, a, a + Vector2(p.rng.randf_range(-30, 30), p.rng.randf_range(-3, 3)), 0.8, Color("#0e0a08"), 0.35, 0.3)


## 어둡게 내린 뒤 광원 둘레만 밝힌다(Interiors.light와 같은 식, 그림 크기 아무거나). lights = [[Vector2, 반지름, 색, 세기] …]
static func light(p: Paint, lights: Array, ambient: float) -> void:
	for y in p.h:
		for x in p.w:
			var k := (y * p.w + x) * 4
			if p.buf[k + 3] <= 0.0:
				continue
			var f := ambient
			for L: Array in lights:
				var d := Vector2(x, y).distance_to(L[0]) / float(L[1])
				if d < 1.0:
					f += (1.0 - d) * (1.0 - d) * float(L[3])
			f = minf(f, 1.25)
			for j in 3:
				p.buf[k + j] *= f
	for L: Array in lights:
		Ink.glow(p, L[0].x, L[0].y, float(L[1]) * 0.45, L[2], float(L[3]) * 0.3)
