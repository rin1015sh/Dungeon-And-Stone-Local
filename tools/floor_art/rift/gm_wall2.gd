extends RefCounted
## 녹색 탄광 벽 잔손질(변형마다 — 칸 가운데 위주): 버팀목·널 막이·녹색 결정·금 · 부러진 들보 · 창문·연장 · 도르래·문살·사슬·랜턴 ·
## 숨은 틈(녹색 빛) · 광석 알갱이. gm.gd가 부른다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Common := preload("res://tools/floor_art/rift/Common.gd")
const K := preload("res://tools/floor_art/rift/gm_kit.gd")

const FACE := {
	"minewall": ["plain", "timber", "gems", "lagging", "timber", "crack"],
	"cavein": ["beam", "stones", "beams", "plain", "beam", "stones"],
	"shack": ["window", "plain", "patch", "window", "tools", "plain"],
	"lift": ["wheel", "gate", "chain", "wheel", "lantern", "gate"],
	"crackedwall": ["fissure", "buffer", "fissure", "buffer", "fissure", "buffer"],
	"orevein": ["veins", "nodes", "veins", "nodes", "veins", "nodes"],
}
const TOP := {
	"minewall": ["plain", "crack", "rubble", "plain", "gem", "rubble"],
	"cavein": ["beam", "stones", "plain", "beam", "stones", "plain"],
	"shack": ["plain", "patch", "plain", "moss", "patch", "plain"],
	"lift": ["plain", "rope", "plain", "hatch", "rope", "plain"],
	"crackedwall": ["plain", "crack", "plain", "crack", "plain", "crack"],
	"orevein": ["gem", "plain", "gem", "rubble", "gem", "plain"],
}


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	var table: Dictionary = FACE if part == "face" else TOP
	var kinds: Array = table.get(style, ["plain"])
	var kind := str(kinds[v % kinds.size()])
	if part == "top":
		_top(p, style, kind, col)
	else:
		_face(p, style, kind, col)


static func _top(p: Paint, style: String, kind: String, col: Color) -> void:
	var s := p.w / 64.0
	var c := Vector2(p.w, p.h) * 0.5
	match kind:
		"plain":
			Cave._brush(p, 0.07)
		"crack":
			Cave._crack(p, c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-10, 6)) * s, p.rng.randi_range(3, 5), 6.0 * s, Vector2.from_angle(p.rng.randf() * TAU))
		"rubble", "stones":
			for k in p.rng.randi_range(3, 6):
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-15, 15)) * s
				var rx := p.rng.randf_range(2.5, 5.0) * s
				Cave._stone(p, q, rx, rx * 0.75, K.ROCK.lerp(col, 0.4).lightened(0.05))
		"gem":
			K.gem(p, c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-8, 8)) * s, 0.55 * s, 0.35)
		"beam":
			var a := c + Vector2(-16, p.rng.randf_range(-8, 8)) * s
			Decals._stick(p, a, a + Vector2(30, p.rng.randf_range(-10, 10)) * s, 4.5 * s, K.WOOD)
			for k in 3:
				Cave._stone(p, c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-12, 12)) * s, 3.5 * s, 2.8 * s, K.ROCK)
		"patch":
			Decals._blob(p, c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * s, 10.0 * s, Color("#1e1a14"), 0.5, 0.4)
		"moss":
			Decals._blob(p, c, 13.0 * s, Color("#3a4428"), 0.45, 0.4)
		"rope":  # 감아 둔 밧줄
			var q := c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-12, 0)) * s
			for k in 4:
				Ink.path(p, Cave._ellipse(q, (9.0 - k * 1.8) * s, (6.0 - k * 1.2) * s, 20), 2.2 * s, true, Color("#8a7a5a"), 0.95, 0.3)
			Ink.path(p, Cave._ellipse(q, 9.6 * s, 6.5 * s, 20), 0.9 * s, true, Ink.INK, 0.6, 0.3)
		"hatch":
			var r := Rect2(c.x - 12.0 * s, c.y - 16.0 * s, 24.0 * s, 20.0 * s)
			Ink.path(p, Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y), 1.4 * s, true, Ink.INK, 0.8, 0.3)
			K.nail(p, r.position + Vector2(3, 3) * s, 1.0 * s)
			K.nail(p, r.end - Vector2(3, 3) * s, 1.0 * s)
			Ink.line(p, Vector2(r.end.x - 4.0 * s, r.get_center().y - 2.0 * s), Vector2(r.end.x - 4.0 * s, r.get_center().y + 2.0 * s), 2.0 * s, K.IRON, 0.9, 0.2)


static func _face(p: Paint, style: String, kind: String, col: Color) -> void:
	var s := p.w / 64.0
	var main := float(p.h - Common.skirt)
	var m := main / 48.0
	var cx := p.w * 0.5
	match kind:
		"plain":
			Cave._brush(p, 0.06)
			if style == "minewall" and p.rng.randf() < 0.6:
				K.gem(p, Vector2(p.rng.randf_range(0.3, 0.7) * p.w, main * p.rng.randf_range(0.45, 0.8)), 0.45 * s, 0.25)
		"timber", "lagging":
			if kind == "lagging":  # 버팀목 사이 널 막이
				for k in 3:
					var y0 := (13.0 + k * 9.5) * m
					K.board(p, Rect2(16.0 * s, y0, 32.0 * s, 7.5 * m), K.WOOD.darkened(0.2), false, p.rng.randf_range(-0.1, 0.05))
				Cave._crack(p, Vector2(30.0 * s, 26.0 * m), 2, 5.0 * s, Vector2(0.4, 1.0))
			_timber_set(p, s, m, main)
			if p.rng.randf() < 0.5:
				K.gem(p, Vector2(p.rng.randf_range(0.4, 0.6) * p.w, main * 0.86), 0.4 * s, 0.25)
		"gems":
			for k in p.rng.randi_range(2, 3):
				K.gem(p, Vector2(p.rng.randf_range(0.25, 0.75) * p.w, main * p.rng.randf_range(0.35, 0.85)), p.rng.randf_range(0.45, 0.65) * s, 0.35)
		"crack":
			Cave._crack(p, Vector2(p.rng.randf_range(0.35, 0.65) * p.w, 6.0 * m), p.rng.randi_range(4, 5), 8.0 * m, Vector2(0, 1))
		"beam", "beams":
			_broken_beam(p, Vector2(p.rng.randf_range(16, 26) * s, main * p.rng.randf_range(0.45, 0.6)), Vector2(1.0, -p.rng.randf_range(0.3, 0.7)).normalized(), 34.0 * s, 6.5 * s)
			if kind == "beams":
				_broken_beam(p, Vector2(p.rng.randf_range(38, 48) * s, main * p.rng.randf_range(0.6, 0.75)), Vector2(-1.0, -p.rng.randf_range(0.3, 0.6)).normalized(), 28.0 * s, 5.5 * s)
			for k in 3:
				var q := Vector2(p.rng.randf_range(0.25, 0.75) * p.w, main * p.rng.randf_range(0.6, 0.92))
				Cave._stone(p, q, p.rng.randf_range(4, 7) * s, p.rng.randf_range(3, 5) * s, K.ROCK.lerp(col, 0.3))
		"stones":
			for k in p.rng.randi_range(4, 6):
				var q := Vector2(p.rng.randf_range(0.22, 0.78) * p.w, main * p.rng.randf_range(0.25, 0.9))
				var rx := p.rng.randf_range(4.0, 8.0) * s
				Cave._stone(p, q, rx, rx * 0.72, K.ROCK.lerp(col, p.rng.randf_range(0.2, 0.5)).lightened(0.05))
		"window":
			_window(p, s, main)
		"patch":
			var a := Vector2(14.0 * s, main * 0.3)
			var b := Vector2(50.0 * s, main * 0.62)
			_plank_line(p, a, b, 6.0 * s)
			K.nail(p, a + (b - a) * 0.1, 1.0 * s)
			K.nail(p, a + (b - a) * 0.9, 1.0 * s)
		"tools":  # 못에 건 곡괭이·삽
			_hang_pick(p, Vector2(22.0 * s, main * 0.3), s)
			_hang_shovel(p, Vector2(42.0 * s, main * 0.28), s, main)
		"wheel":
			_pulley(p, Vector2(cx, 10.0 * main / 88.0), 12.0 * s)
		"gate":
			_lattice(p, Rect2(12.0 * s, 51.0 * main / 88.0, 40.0 * s, 20.0 * main / 88.0), s)
		"chain":
			_chain(p, Vector2(cx + p.rng.randf_range(-4, 4) * s, 9.0 * main / 88.0), 60.0 * main / 88.0, s)
		"lantern":
			_lantern(p, Vector2(cx, 26.0 * main / 88.0), s)
		"fissure", "buffer":
			_fissure(p, s, main)
			if kind == "buffer":
				_buffer(p, s, main)
		"veins", "nodes":
			for k in (2 if kind == "veins" else 1):
				var a := Vector2(p.rng.randf_range(12, 22) * s, main * p.rng.randf_range(0.2, 0.4))
				var b := Vector2(p.rng.randf_range(42, 52) * s, main * p.rng.randf_range(0.65, 0.85))
				_vein(p, a, b, s)
			for k in (2 if kind == "nodes" else 1):
				K.gem(p, Vector2(p.rng.randf_range(0.3, 0.7) * p.w, main * p.rng.randf_range(0.3, 0.85)), p.rng.randf_range(0.5, 0.7) * s, 0.4)


## 버팀목 한 벌: 기둥 2 + 위 받침 들보 + 모서리 까치발.
static func _timber_set(p: Paint, s: float, m: float, main: float) -> void:
	var bot := main + Common.skirt * 0.55
	for x0: float in [11.0, 46.0]:
		Ink.line(p, Vector2((x0 + 9.0) * s, 9.0 * m), Vector2((x0 + 9.0) * s, bot), 2.4 * s, Color(0.05, 0.04, 0.05), 0.45, 0.3)  # 기둥 그림자
		K.board(p, Rect2(x0 * s, 7.0 * m, 7.0 * s, bot - 7.0 * m), K.WOOD, true, p.rng.randf_range(-0.08, 0.06))
	K.board(p, Rect2(8.0 * s, 4.0 * m, 48.0 * s, 6.0 * m), K.WOOD.darkened(0.05), false, 0.04)
	for e: Array in [[18.0, 1.0], [46.0, -1.0]]:
		var a := Vector2(float(e[0]) * s, 10.0 * m)
		var b := a + Vector2(float(e[1]) * 7.0 * s, 8.0 * m)
		_plank_line(p, a + Vector2(float(e[1]) * 0.0, 0), b, 3.0 * s)
	for x0: float in [14.5, 49.5]:
		K.nail(p, Vector2(x0 * s, 7.0 * m), 0.9 * s)


## 굵은 나무 막대(두 점 사이 — 나무결, 왼쪽 위 밝게, 잉크).
static func _plank_line(p: Paint, a: Vector2, b: Vector2, wd: float) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * wd * 0.5
	var poly := PackedVector2Array([a + n, b + n, b - n, a - n])
	Ink.line(p, a + Vector2(1.5, 2.0), b + Vector2(1.5, 2.0), wd, Color(0.04, 0.03, 0.03), 0.35, 0.3)
	K.wood(p, poly, K.WOOD, absf(d.y) > absf(d.x), 0.0)
	var lit := n if n.y < 0.0 else -n
	Ink.line(p, a + lit * 0.8, b + lit * 0.8, 0.8, K.LIT_EDGE, 0.3, 0.2)
	Ink.path(p, poly, 1.1 * p.w / 64.0, true, Ink.INK, 0.75, 0.3)


## 부러진 들보: 흙더미에서 비스듬히 튀어나온 나무 — 바깥 끝은 쪼개진 가시, 밑동은 돌에 묻힘.
static func _broken_beam(p: Paint, root: Vector2, d: Vector2, ln: float, wd: float) -> void:
	var tip := root + d * ln
	_plank_line(p, root, tip, wd)
	var n := Vector2(-d.y, d.x) * wd * 0.5
	var spl := PackedVector2Array([tip + n, tip + d * wd * 0.9 + n * 0.4, tip + d * 0.2, tip + d * wd * 1.3 - n * 0.2, tip - n])
	p.fill_poly(spl, func(x: int, y: int) -> Color: return p.vary(K.WOOD_PALE, x, y, 0.08))
	Ink.path(p, spl, 0.9, false, Ink.INK, 0.7, 0.3)
	Cave._stone(p, root + Vector2(-1, 2) * (wd / 4.5), wd * 1.3, wd, K.ROCK.darkened(0.1))


## 작은 불 켜진 창: 나무틀 + 십자 창살 + 따뜻한 불빛(스스로 빛남).
static func _window(p: Paint, s: float, main: float) -> void:
	var m := main / 80.0
	var r := Rect2(21.0 * s, 26.0 * m, 22.0 * s, 20.0 * m)
	Ink.glow(p, r.get_center().x, r.get_center().y, 26.0 * s, K.LAMP, 0.22)
	p.fill_rect(r.position.x, r.position.y, r.size.x, r.size.y, func(x: int, y: int) -> Color:
		var d := Vector2((x - r.get_center().x) / r.size.x, (y - r.get_center().y) / r.size.y).length()
		return p.vary(Color("#ffd890").lerp(Color("#b8582a"), clampf(d * 1.6, 0.0, 1.0)), x, y, 0.1))
	p.fill_rect(r.position.x, r.end.y - 6.0 * m, r.size.x, 6.0 * m, func(_x: int, _y: int) -> Color: return Color(0.15, 0.08, 0.04, 0.55))  # 창 안 그늘
	var fc := K.WOOD.darkened(0.15)
	for bar: Rect2 in [Rect2(r.position.x - 2.5 * s, r.position.y - 2.5 * s, r.size.x + 5.0 * s, 3.0 * s),
			Rect2(r.position.x - 2.5 * s, r.end.y - 0.5 * s, r.size.x + 5.0 * s, 3.5 * s),
			Rect2(r.position.x - 2.5 * s, r.position.y, 3.0 * s, r.size.y),
			Rect2(r.end.x - 0.5 * s, r.position.y, 3.0 * s, r.size.y),
			Rect2(r.get_center().x - 1.2 * s, r.position.y, 2.4 * s, r.size.y),
			Rect2(r.position.x, r.get_center().y - 1.2 * s, r.size.x, 2.4 * s)]:
		K.board(p, bar, fc, bar.size.y > bar.size.x, 0.0)
	Ink.grime(p, r.position.x, r.end.y + 3.0 * s, r.size.x, 14.0 * s, 0.4)


static func _hang_pick(p: Paint, q: Vector2, s: float) -> void:
	K.nail(p, q, 1.1 * s)
	var a := q + Vector2(0, 1.5 * s)
	var b := a + Vector2(2.0 * s, 26.0 * s)
	Decals._stick(p, a, b, 2.6 * s, K.WOOD_PALE.darkened(0.15))
	var head := PackedVector2Array([a + Vector2(-11, 3) * s, a + Vector2(-2, -1) * s, a + Vector2(2, -1) * s, a + Vector2(12, 4) * s, a + Vector2(2, 2) * s, a + Vector2(-2, 2) * s])
	p.fill_poly(head, func(x: int, y: int) -> Color: return p.vary(K.IRON.lightened(0.1), x, y, 0.1))
	Ink.path(p, head, 1.0 * s, true, Ink.INK, 0.8, 0.3)


static func _hang_shovel(p: Paint, q: Vector2, s: float, main: float) -> void:
	K.nail(p, q, 1.1 * s)
	var b := Vector2(q.x + 3.0 * s, main * 0.82)
	Decals._stick(p, q + Vector2(0, 1) * s, b + Vector2(0, -12) * s, 2.4 * s, K.WOOD_PALE.darkened(0.2))
	var blade := PackedVector2Array([b + Vector2(-5, -13) * s, b + Vector2(5, -13) * s, b + Vector2(5, -2) * s, b + Vector2(0, 2) * s, b + Vector2(-5, -2) * s])
	p.fill_poly(blade, func(x: int, y: int) -> Color: return p.vary(K.IRON.lerp(K.RUST, 0.35), x, y, 0.12))
	Ink.path(p, blade, 1.0 * s, true, Ink.INK, 0.85, 0.3)


## 도르래: 바퀴 테 + 살 6개 + 축, 밧줄이 걸침.
static func _pulley(p: Paint, c: Vector2, r: float) -> void:
	var s := p.w / 64.0
	p.fill_poly(Cave._ellipse(c + Vector2(2, 2) * s, r, r, 28), func(_x: int, _y: int) -> Color: return Color(0.03, 0.02, 0.03, 0.45))
	for k in 6:
		var a := TAU * k / 6.0 + 0.3
		Ink.line(p, c, c + Vector2.from_angle(a) * r * 0.85, 2.0 * s, K.WOOD.darkened(0.1), 0.95, 0.2)
	var ring := Cave._ellipse(c, r, r, 32)
	var inner := Cave._ellipse(c, r * 0.78, r * 0.78, 32)
	Ink.path(p, ring, 1.0 * s, true, Ink.INK, 0.9, 0.2)
	for k in 32:
		Ink.line(p, ring[k].lerp(inner[k], 0.5), ring[(k + 1) % 32].lerp(inner[(k + 1) % 32], 0.5), r * 0.2,
			K.IRON.lerp(K.RUST, 0.3).lightened(0.25 if k > 14 and k < 26 else -0.0), 1.0, 0.1)
	Ink.path(p, inner, 0.8 * s, true, Ink.INK, 0.8, 0.2)
	Cave._stone(p, c, 2.6 * s, 2.6 * s, K.IRON)
	for rx: float in [c.x - r * 0.95, c.x + r * 0.95]:
		Ink.line(p, Vector2(rx, c.y), Vector2(rx, c.y + 60.0 * s), 2.4 * s, Color("#7a6a4a"), 0.9, 0.3)


## 쇠 문살(비스듬히 엇갈린 격자).
static func _lattice(p: Paint, r: Rect2, s: float) -> void:
	var col := K.IRON.lerp(K.RUST, 0.3)
	var step := 8.0 * s
	var k := -r.size.y
	while k < r.size.x:
		for dir: float in [1.0, -1.0]:
			var a := Vector2(r.position.x + k, r.position.y) if dir > 0.0 else Vector2(r.end.x - k, r.position.y)
			var b := a + Vector2(dir * r.size.y, r.size.y)
			var seg := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y))
			for sg: PackedVector2Array in seg:
				Ink.line(p, sg[0], sg[1], 2.6 * s, Ink.INK, 0.85, 0.2)
				Ink.line(p, sg[0], sg[1], 1.4 * s, col.lightened(0.2), 1.0, 0.2)
		k += step
	Ink.line(p, r.position, Vector2(r.end.x, r.position.y), 3.0 * s, col, 1.0, 0.2)
	Ink.line(p, Vector2(r.position.x, r.end.y), r.end, 3.0 * s, col.darkened(0.2), 1.0, 0.2)


## 늘어진 사슬(타원 고리를 번갈아).
static func _chain(p: Paint, top: Vector2, ln: float, s: float) -> void:
	var y := 0.0
	var k := 0
	while y < ln:
		var q := top + Vector2(sin(y * 0.05) * 1.5 * s, y)
		var rx := (1.6 if k % 2 == 0 else 0.7) * s
		var ring := Cave._ellipse(q, rx, 2.8 * s, 12)
		Ink.path(p, ring, 1.6 * s, true, Ink.INK, 0.8, 0.1)
		Ink.path(p, ring, 0.8 * s, true, K.IRON.lightened(0.25), 0.9, 0.1)
		y += 4.4 * s
		k += 1
	Cave._stone(p, top + Vector2(0, ln + 3.0 * s), 3.2 * s, 2.6 * s, K.IRON)  # 갈고리 추


## 걸린 광부 랜턴(따뜻한 불빛).
static func _lantern(p: Paint, c: Vector2, s: float) -> void:
	Ink.line(p, c + Vector2(0, -16) * s, c + Vector2(0, -6) * s, 1.0 * s, Ink.INK, 0.9, 0.2)
	Ink.glow(p, c.x, c.y, 22.0 * s, K.LAMP, 0.4, false)
	var body := Paint.rect_poly(c.x - 4.0 * s, c.y - 6.0 * s, 8.0 * s, 10.0 * s)
	p.fill_poly(body, func(x: int, y: int) -> Color: return Color("#ffe0a0").lerp(Color("#e08a30"), clampf((y - c.y + 6.0 * s) / (10.0 * s), 0.0, 1.0)))
	Ink.path(p, body, 1.2 * s, true, Ink.INK, 0.9, 0.2)
	Ink.line(p, c + Vector2(0, -6) * s, c + Vector2(0, 4) * s, 0.9 * s, Ink.INK, 0.8, 0.1)
	p.fill_poly(PackedVector2Array([c + Vector2(-5, -6) * s, c + Vector2(0, -9) * s, c + Vector2(5, -6) * s]), func(_x: int, _y: int) -> Color: return K.IRON)


## 숨은 틈: 턱에서 아래로 갈라진 검은 틈 + 안쪽 깊이 녹색 빛 + 오른쪽 벽에 빛 받은 가장자리 + 무너진 돌.
static func _fissure(p: Paint, s: float, main: float) -> void:
	var pts := PackedVector2Array()
	var x := p.rng.randf_range(26.0, 36.0) * s
	var n := 7
	for k in n + 1:
		var t := float(k) / n
		pts.append(Vector2(x + p.rng.randf_range(-4.0, 4.0) * s, lerpf(5.0, main * 0.88, t)))
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for k in pts.size():
		var t := float(k) / n
		var hw := lerpf(1.5, 4.5, sin(t * PI)) * s + (1.5 * s if k == 3 or k == 4 else 0.0)
		left.append(pts[k] + Vector2(-hw, 0))
		right.append(pts[k] + Vector2(hw, 0))
	var poly := left.duplicate()
	right.reverse()
	poly.append_array(right)
	var deep := pts[4]
	Ink.glow(p, deep.x, deep.y, 14.0 * s, K.LIME_GLOW, 0.22)
	p.fill_poly(poly, func(xx: int, yy: int) -> Color:
		var d := Vector2(xx, yy).distance_to(deep) / (12.0 * s)
		return K.VOID.lerp(K.LIME_DARK.darkened(0.3), clampf(1.0 - d, 0.0, 1.0) * 0.6))
	K.gem(p, deep + Vector2(0, 2) * s, 0.32 * s, 0.35)
	right.reverse()
	Ink.path(p, right, 0.8 * s, false, K.LIT_EDGE, 0.35, 0.3)
	Ink.path(p, poly, 1.3 * s, true, Ink.INK, 0.85, 0.3)
	for k in 2:  # 곁금
		Cave._crack(p, pts[2 + k * 2], 2, 5.0 * s, Vector2(1.0 if k == 0 else -1.0, 0.6))
	for k in 3:
		Cave._stone(p, Vector2(x + p.rng.randf_range(-10, 10) * s, main + p.rng.randf_range(-6, 1) * s), p.rng.randf_range(2.5, 4.0) * s, 2.4 * s, K.ROCK)


## 끊긴 철로 끝: 벽 밑동에 처박힌 휜 레일 토막 + 부서진 침목 + 돌.
static func _buffer(p: Paint, s: float, main: float) -> void:
	var a := Vector2(14.0 * s, main - 3.0 * s)
	var b := Vector2(30.0 * s, main - 6.0 * s)
	var c := Vector2(47.0 * s, main - 1.0 * s)
	K.board(p, Rect2(20.0 * s, main - 9.0 * s, 26.0 * s, 5.0 * s), K.WOOD.darkened(0.25), false, 0.0)  # 침목 조각
	for seg: Array in [[a, b], [b, c]]:
		var q0: Vector2 = seg[0]
		var q1: Vector2 = seg[1]
		Ink.line(p, q0 + Vector2(0, 2.2) * s, q1 + Vector2(0, 2.2) * s, 2.6 * s, Ink.INK, 0.7, 0.1)
		Ink.line(p, q0 + Vector2(0, 1.0) * s, q1 + Vector2(0, 1.0) * s, 2.0 * s, K.IRON.lerp(K.RUST, 0.4), 1.0, 0.1)
		Ink.line(p, q0, q1, 1.4 * s, K.STEEL, 1.0, 0.1)
	for k in 3:
		Cave._stone(p, Vector2(p.rng.randf_range(12, 52) * s, main - p.rng.randf_range(0, 4) * s), p.rng.randf_range(2.5, 4.0) * s, 2.4 * s, K.ROCK)


## 굵은 석영 줄(바위에 박힌 옅은 띠 + 녹색 광석 점).
static func _vein(p: Paint, a: Vector2, b: Vector2, s: float) -> void:
	var pts := PackedVector2Array()
	for k in 9:
		var t := k / 8.0
		pts.append(a.lerp(b, t) + Vector2(p.rng.randf_range(-1.5, 1.5), p.rng.randf_range(-2.5, 2.5)) * s)
	for k in pts.size() - 1:
		var wd := (1.0 + sin(float(k) / 8.0 * PI) * 1.4) * s
		Ink.line(p, pts[k], pts[k + 1], wd + 1.2 * s, Ink.INK, 0.55, 0.4)
		Ink.line(p, pts[k], pts[k + 1], wd, K.QUARTZ.darkened(0.3), 0.9, 0.4)
		Ink.line(p, pts[k] - Vector2(0, 0.6 * s), pts[k + 1] - Vector2(0, 0.6 * s), wd * 0.4, K.QUARTZ, 0.5, 0.4)
	for k in 3:
		var q := pts[p.rng.randi_range(1, 5)]
		Ink.glow(p, q.x, q.y, 6.0 * s, K.LIME_GLOW, 0.3)
		Cave._dot(p, q, 1.6 * s, K.LIME_LIGHT, 0.95)
