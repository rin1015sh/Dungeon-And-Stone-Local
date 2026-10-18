extends RefCounted
## 녹색 탄광 바닥 잔손질(변형마다 — 칸 가운데 위주, 가장자리는 Common.cell이 바탕으로 되돌린다): 장화 자국·자갈·석탄 가루·금·결정 부스러기 ·
## 녹물·광석 · 덧댄 판·옹이 · 슬라임 거품·소용돌이 · 부서진 다리의 구멍. gm.gd가 부른다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const K := preload("res://tools/floor_art/rift/gm_kit.gd")
const F := preload("res://tools/floor_art/rift/gm_floor.gd")

const KINDS := {
	"minedirt": ["plain", "prints", "pebbles", "coal", "crack", "pebbles"],
	"bluestone": ["plain", "chips", "crack", "worn", "chips", "pebbles"],
	"rails": ["plain", "rust", "ore", "coal", "bolt", "rust"],
	"rubble": ["stones", "timber", "stones", "dust", "stones", "chips"],
	"woodstairs": ["plain", "worn", "nails", "plain", "crack", "dust"],
	"planks": ["plain", "nails", "knot", "stain", "nails", "patch"],
	"ooze": ["bubbles", "swirl", "bubbles", "bones", "swirl", "bubbles"],
	"brokenplanks": ["hole", "hole2", "split", "hole", "hole2", "split"],
	"rockstairs": ["plain", "chip", "crack", "pebbles", "chip", "plain"],
}

static func detail(p: Paint, style: String, v: int, col: Color) -> void:
	var kinds: Array = KINDS.get(style, ["plain"])
	var kind := str(kinds[v % kinds.size()])
	var s := float(p.w) / 64.0
	var c := Vector2(p.w, p.h) * 0.5
	match kind:
		"plain":
			if style != "ooze":
				Cave._brush(p, 0.07)
		"prints":  # 장화 자국
			var d := Vector2.from_angle(p.rng.randf() * TAU)
			var nrm := Vector2(-d.y, d.x)
			for k in 3:
				var q := c + d * (k - 1) * 11.0 * s + nrm * (3.0 if k % 2 == 0 else -3.0) * s
				_print(p, q, d, s)
		"pebbles":
			for k in p.rng.randi_range(2, 4):
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-15, 15)) * s
				var rx := p.rng.randf_range(2.0, 4.5) * s
				Cave._stone(p, q, rx, rx * 0.75, col.lightened(p.rng.randf_range(0.0, 0.25)) if style != "bluestone" else K.ROCK.lightened(0.1))
		"coal":
			Decals._blob(p, c + Vector2(p.rng.randf_range(-5, 5), p.rng.randf_range(-5, 5)) * s, 12.0 * s, Color("#1a1818"), 0.45, 0.35)
			for k in p.rng.randi_range(3, 5):
				var q := c + Vector2(p.rng.randf_range(-11, 11), p.rng.randf_range(-11, 11)) * s
				Cave._stone(p, q, 1.8 * s, 1.4 * s, Color("#2a2828"))
		"crack":
			Cave._crack(p, c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-10, 6)) * s, p.rng.randi_range(3, 5), 6.0 * s, Vector2.from_angle(p.rng.randf() * TAU))
		"chips":  # 바닥에 떨어진 녹색 결정 부스러기
			for k in p.rng.randi_range(2, 3):
				var q := c + Vector2(p.rng.randf_range(-13, 13), p.rng.randf_range(-13, 13)) * s
				K.gem(p, q, p.rng.randf_range(0.3, 0.45) * s, 0.25)
			for k in 3:
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-15, 15)) * s
				Cave._stone(p, q, 2.0 * s, 1.5 * s, K.ROCK)
		"worn":
			var q := c + Vector2(p.rng.randf_range(-4, 4), p.rng.randf_range(-4, 4)) * s
			p.fill_poly(Cave._ellipse(q, 15.0 * s, 10.0 * s, 20, p.rng), func(x: int, y: int) -> Color:
				var d := Vector2((x - q.x) / (15.0 * s), (y - q.y) / (10.0 * s)).length()
				return Color(0.8, 0.82, 0.9, 0.14 * clampf(1.0 - d, 0.0, 1.0)), 1.0, true)
		"rust":  # 레일·받침쇠의 녹물
			for ry: float in F.RAILS:
				K.rust(p, Vector2(c.x + p.rng.randf_range(-8, 8) * s, (ry + 3.0) * s), 12.0 * s, 4)
			Decals._blob(p, c + Vector2(p.rng.randf_range(-6, 6), 0) * s, 8.0 * s, Color("#5a3418"), 0.25, 0.4)
		"ore":  # 광차에서 떨어진 광석
			for k in p.rng.randi_range(3, 5):
				var q := c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-7, 7)) * s
				Cave._stone(p, q, p.rng.randf_range(2.0, 3.6) * s, 2.0 * s, Color("#3e3c44"))
			K.gem(p, c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-3, 3)) * s, 0.35 * s, 0.3)
		"bolt":  # 빠진 못·쪼개진 침목
			var x0 := (16.0 * p.rng.randi_range(1, 2) + 8.0) * s
			Ink.line(p, Vector2(x0, 24.0 * s), Vector2(x0 + p.rng.randf_range(-2, 2) * s, 38.0 * s), 1.2 * s, Ink.INK, 0.8, 1.0)
			Decals._stick(p, c + Vector2(-6, -2) * s, c + Vector2(2, 1) * s, 1.4 * s, K.IRON)
		"stones":
			for k in p.rng.randi_range(4, 7):
				var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-16, 16)) * s
				var rx := p.rng.randf_range(3.0, 6.5) * s
				Cave._stone(p, q, rx, rx * p.rng.randf_range(0.6, 0.85), col.lerp(K.ROCK, p.rng.randf()).lightened(p.rng.randf_range(0.0, 0.2)))
		"timber":  # 부러진 버팀목 조각
			var a := c + Vector2(-14, p.rng.randf_range(-6, 6)) * s
			Decals._stick(p, a, a + Vector2(26, p.rng.randf_range(-8, 8)) * s, 4.0 * s, K.WOOD)
			for k in 3:
				Cave._stone(p, c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-12, 12)) * s, 3.0 * s, 2.4 * s, K.ROCK)
		"dust":
			Decals._blob(p, c, 13.0 * s, Color("#a09888"), 0.25, 0.35)
		"nails":
			for k in p.rng.randi_range(2, 4):
				K.nail(p, c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-14, 14)) * s, 0.9 * s)
			if style == "woodstairs":
				Cave._brush(p, 0.06)
		"knot":
			var q := c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-10, 10)) * s
			p.fill_poly(Cave._ellipse(q, 2.2 * s, 3.8 * s, 14), func(_x: int, _y: int) -> Color: return Color(0.12, 0.07, 0.04, 0.75))
			Ink.path(p, Cave._ellipse(q, 3.6 * s, 6.0 * s, 16), 0.8 * s, true, Color("#2a1a10"), 0.45, 0.4)
		"stain":
			Decals._blob(p, c + Vector2(p.rng.randf_range(-5, 5), p.rng.randf_range(-5, 5)) * s, 11.0 * s, Color("#22180e"), 0.4, 0.4)
		"patch":  # 판 두 장을 가로지르는 덧댄 판
			var y0 := c.y + p.rng.randf_range(-8, 4) * s
			K.board(p, Rect2(c.x - 15.0 * s, y0, 30.0 * s, 7.0 * s), col.darkened(0.05), false, 0.04)
			for e: float in [-12.0, 12.0]:
				K.nail(p, Vector2(c.x + e * s, y0 + 3.5 * s), 0.9 * s)
		"bubbles":
			for k in p.rng.randi_range(3, 5):
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-15, 15)) * s
				_bubble(p, q, p.rng.randf_range(1.8, 4.2) * s, p.rng.randf() < 0.3)
		"swirl":
			for k in 2:
				var q := c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * s
				var pts := PackedVector2Array()
				var a0 := p.rng.randf() * TAU
				for j in 14:
					var a := a0 + j * 0.42
					pts.append(q + Vector2(cos(a), sin(a) * 0.7) * (3.0 + j * 1.1) * s)
				Ink.path(p, pts, 1.0 * s, false, K.LIME_LIGHT, 0.35, 0.4)
			_bubble(p, c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-10, 10)) * s, 2.5 * s, false)
		"bones":  # 반쯤 잠긴 뼈 — 위에 슬라임 막
			Decals._bones(p, c, s)
			p.fill_poly(Cave._ellipse(c, 18.0 * s, 16.0 * s, 20), func(_x: int, _y: int) -> Color: return Color(K.LIME.r, K.LIME.g, K.LIME.b, 0.28), 1.0, true)
			_bubble(p, c + Vector2(10, 8) * s, 2.2 * s, false)
		"hole", "hole2", "split":
			_hole(p, kind, col, s)
		"chip":  # 계단 코가 깨진 자리
			var j := p.rng.randi_range(1, 2)
			var q := Vector2(c.x + p.rng.randf_range(-10, 10) * s, (j * 16.0 + 10.0) * s)
			p.fill_poly(Cave._ellipse(q, 5.0 * s, 3.0 * s, 12, p.rng), func(_x: int, _y: int) -> Color: return Color(0.06, 0.05, 0.05, 0.8))
			for k in 2:
				Cave._stone(p, q + Vector2(p.rng.randf_range(-4, 6), p.rng.randf_range(5, 8)) * s, 1.8 * s, 1.4 * s, col.lightened(0.15))


## 장화 자국 하나(앞꿈치 + 뒤꿈치).
static func _print(p: Paint, q: Vector2, d: Vector2, s: float) -> void:
	for part: Array in [[0.0, 2.6, 4.0], [-6.0, 2.0, 2.4]]:
		var cq := q + d * float(part[0]) * s
		var rx := float(part[1]) * s
		var ry := float(part[2]) * s
		var poly := PackedVector2Array()
		for k in 14:
			var a := TAU * k / 14.0
			poly.append(cq + d * cos(a) * ry + Vector2(-d.y, d.x) * sin(a) * rx)
		p.fill_poly(poly, func(_x: int, _y: int) -> Color: return Color(0.08, 0.06, 0.05, 0.32), 1.0, true)


## 슬라임 거품: 어두운 테 + 밝은 안쪽 + 왼쪽 위 반짝임(터진 것은 고리만).
static func _bubble(p: Paint, q: Vector2, r: float, popped: bool) -> void:
	var ring := Cave._ellipse(q, r, r * 0.8, 16)
	if not popped:
		p.fill_poly(ring, func(x: int, y: int) -> Color:
			var d := Vector2(x - q.x, y - q.y) / r
			return K.LIME.lerp(K.LIME_LIGHT, clampf(0.5 - d.x * 0.4 - d.y * 0.4, 0.0, 1.0)).darkened(0.1))
		Cave._dot(p, q + Vector2(-0.35, -0.35) * r, r * 0.35, Color("#f8ffe8"), 0.9)
	Ink.path(p, ring, maxf(0.7, r * 0.25), true, Color("#10280c"), 0.7, 0.2)
	if popped:
		Ink.path(p, Cave._ellipse(q, r * 1.6, r * 1.2, 18), 0.7, true, K.LIME_LIGHT, 0.3, 0.3)


## 부서진 다리 판: 판이 끊겨 아래 어둠이 보이는 구멍(위 끝 = 부러진 판 두께, 아래 = 쪼개진 가시) + 저 아래 들보.
static func _hole(p: Paint, kind: String, col: Color, s: float) -> void:
	var boards: Array[int] = [p.rng.randi_range(1, 2)]
	if kind == "hole2":
		boards = [1, 2]
	var ya := p.rng.randf_range(13.0, 20.0) * s
	var yb := p.rng.randf_range(40.0, 50.0) * s
	if kind == "split":
		ya = p.rng.randf_range(22.0, 28.0) * s
		yb = ya + p.rng.randf_range(8.0, 12.0) * s
	for b in boards:
		var x0 := float(F.BOARDS[b]) * s
		var x1 := float(F.BOARDS[b + 1]) * s
		var tops := PackedFloat32Array()
		var bots := PackedFloat32Array()
		for x in range(int(x0), int(x1) + 1):
			tops.append(ya + p.rng.randf_range(-3.0, 3.0) * s + sin(x * 0.9) * 1.5 * s)
			bots.append(yb + p.rng.randf_range(-3.0, 3.0) * s + sin(x * 1.3 + 1.0) * 1.5 * s)
		for x in range(int(x0), int(x1) + 1):
			var k := x - int(x0)
			for y in range(int(tops[k]), int(bots[k]) + 1):
				var t := (y - tops[k]) / maxf(1.0, bots[k] - tops[k])
				var c := K.VOID.lerp(Color("#141a22"), 0.4 * (1.0 - t))
				var beam := absf(y - lerpf(ya, yb, 0.62)) < 2.5 * s  # 저 아래 어둠 속 들보
				if beam:
					c = K.WOOD_DARK.darkened(0.55)
				if y < tops[k] + 2.5 * s:
					c = col.darkened(0.55)  # 부러진 판 두께(남쪽 면)
				p.blend(x, y, c, 1.0)
		var top_line := PackedVector2Array()
		var bot_line := PackedVector2Array()
		for k in tops.size():
			top_line.append(Vector2(x0 + k, tops[k]))
			bot_line.append(Vector2(x0 + k, bots[k]))
		Ink.path(p, top_line, 1.1 * s, false, Ink.INK, 0.85, 0.3)
		Ink.path(p, bot_line, 1.0 * s, false, Ink.INK, 0.8, 0.3)
		for k in p.rng.randi_range(2, 3):  # 가시
			var sx := x0 + p.rng.randf_range(2.0, x1 - x0 - 2.0)
			var by := yb + p.rng.randf_range(-1.0, 1.0) * s
			Ink.line(p, Vector2(sx, by), Vector2(sx + p.rng.randf_range(-2, 2) * s, by - p.rng.randf_range(4, 8) * s), 1.2 * s, K.WOOD_PALE, 0.8, 0.3)
			var ty := ya + p.rng.randf_range(-1.0, 1.0) * s
			Ink.line(p, Vector2(sx, ty + 2.0 * s), Vector2(sx + p.rng.randf_range(-2, 2) * s, ty + p.rng.randf_range(4, 7) * s), 1.0 * s, col.lightened(0.1), 0.7, 0.3)
	if kind == "split":  # 옆 판이 쪼개져 내려앉음
		var b2 := 2 if boards[0] == 1 else 1
		var a := Vector2(float(F.BOARDS[b2]) * s + 3.0 * s, 16.0 * s)
		Cave._crack(p, a, 4, 7.0 * s, Vector2(0.3, 1.0))
		p.fill_poly(Paint.rect_poly(float(F.BOARDS[b2]) * s, 30.0 * s, (float(F.BOARDS[b2 + 1]) - float(F.BOARDS[b2])) * s, 14.0 * s),
			func(_x: int, _y: int) -> Color: return Color(0.04, 0.03, 0.03, 0.35), 1.0, true)
