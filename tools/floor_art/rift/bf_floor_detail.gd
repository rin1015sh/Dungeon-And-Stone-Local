extends RefCounted
## 핏빛성채 바닥 잔손질(bf.gd가 부른다): 변형마다 다른 금·얼룩·뼈·짚·웅덩이·팔다리 — 칸 가운데 위주(가장자리는 Common.cell이 바탕으로 되돌린다).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const K := preload("res://tools/floor_art/rift/bf_kit.gd")
const Floor := preload("res://tools/floor_art/rift/bf_floor.gd")


# ── 잔손질 ───────────────────────────────────────────

static func detail(p: Paint, style: String, v: int, col: Color) -> void:
	var kinds: Array = Floor.KINDS.get(style, ["plain"])
	var kind := str(kinds[v % kinds.size()])
	var s := p.w / 64.0
	var c := Vector2(p.w, p.h) * 0.5
	var j := func(r: float) -> Vector2: return c + Vector2(p.rng.randf_range(-r, r), p.rng.randf_range(-r, r)) * s
	if style == "corpsepit":
		for k in p.rng.randi_range(2, 3):
			var a: Vector2 = j.call(14.0)
			_limb(p, a, a + Vector2.from_angle(p.rng.randf() * TAU) * p.rng.randf_range(12.0, 18.0) * s, s)
		if p.rng.randf() < 0.6:
			Cave._stone(p, j.call(10.0), 8.0 * s, 5.5 * s, K.SKIN.darkened(0.3))  # 웅크린 몸통
	match style + ":" + kind:
		"cobble:plain", "stairs:plain", "dirt:plain", "mudroad:plain", "ash:plain":
			Cave._brush(p, 0.07)
		"carpet:plain":
			for k in 3:
				var q: Vector2 = j.call(16.0)
				Ink.line(p, q, q + Vector2(p.rng.randf_range(4, 9), p.rng.randf_range(-2, 2)) * s, 0.8 * s, K.GOLD, 0.5, 0.6)
		"cobble:crack", "stairs:crack":
			Cave._crack(p, j.call(8.0), p.rng.randi_range(3, 4), 6.0 * s, Vector2.from_angle(p.rng.randf() * TAU))
		"cobble:chip", "stairs:chip":
			for k in p.rng.randi_range(2, 3):
				var q: Vector2 = j.call(16.0)
				Cave._pit(p, q, p.rng.randf_range(2.0, 3.5) * s)
				Cave._stone(p, q + Vector2(p.rng.randf_range(3, 7), p.rng.randf_range(2, 5)) * s, 1.6 * s, 1.2 * s, col.lightened(0.2))
		"cobble:stain", "stairs:blood":
			K.stain(p, j.call(8.0), p.rng.randf_range(7.0, 11.0) * s, 0.6)
		"cobble:split":
			var y0 := c.y + p.rng.randf_range(-12, -4) * s
			Ink.line(p, Vector2(c.x - 14 * s, y0), Vector2(c.x + 12 * s, y0 + 3 * s), 1.4 * s, Color("#1c120e"), 0.8, 0.8)
			Ink.line(p, Vector2(c.x - 14 * s, y0 + 1.2 * s), Vector2(c.x + 12 * s, y0 + 4.2 * s), 0.7 * s, K.LIT, 0.15, 0.8, true)
		"cobble:grime", "stairs:grime":
			Decals._blob(p, j.call(6.0), 13.0 * s, Color("#1e1a14"), 0.4, 0.4)
			for k in 3:
				Cave._dot(p, j.call(14.0), 1.2 * s, Color("#3a4a2a"), 0.5)
		"mudroad:puddle", "dirt:puddle":
			K.puddle(p, j.call(5.0), p.rng.randf_range(10.0, 14.0) * s)
		"mudroad:rut":
			var ox := p.rng.randf_range(-4, 4)
			for o: float in [-8.0, 8.0]:
				var a := Vector2(c.x + (o + ox) * s - 2.0 * s, 4.0 * s)
				var b := Vector2(c.x + (o + ox) * s + 2.0 * s, p.h - 4.0 * s)
				Ink.line(p, a, b, 4.2 * s, Color("#20160f"), 0.5, 1.4)
				Ink.line(p, a + Vector2(2.0, 0) * s, b + Vector2(2.0, 0) * s, 1.2 * s, Color("#b09478"), 0.3, 1.4, true)
		"mudroad:prints", "ash:prints":
			for k in 4:
				var q := c + Vector2(-12.0 + k * 8.0, (k % 2) * 7.0 - 3.5) * s
				Cave._pit(p, q, 2.8 * s)
				Cave._pit(p, q + Vector2(0.6, -3.8) * s, 1.8 * s)
		"mudroad:stones", "ash:stones":
			for k in p.rng.randi_range(4, 6):
				var rx := p.rng.randf_range(2.0, 4.2) * s
				Cave._stone(p, j.call(17.0), rx, rx * 0.75, Color("#6a605a"))
		"ash:tuft":
			for k in p.rng.randi_range(2, 3):
				_tuft(p, j.call(15.0), s)
		"ash:char":
			Decals._blob(p, j.call(6.0), 10.0 * s, Color("#141010"), 0.6, 0.4)
			for k in 4:
				Decals._stick(p, j.call(9.0), j.call(9.0), 1.6 * s, Color("#1c1614"))
			K.bone(p, j.call(10.0), j.call(10.0), s * 0.8, K.BONE.darkened(0.3))
		"carpet:stain":
			Decals._blob(p, j.call(8.0), p.rng.randf_range(8.0, 12.0) * s, Color("#2a060a"), 0.55, 0.4)
			for k in 4:
				Cave._dot(p, j.call(16.0), p.rng.randf_range(0.8, 1.6) * s, Color("#2a060a"), 0.55)
		"carpet:worn":
			Decals._blob(p, j.call(6.0), 12.0 * s, Color("#704a40"), 0.4, 0.35)
		"carpet:wax":
			for k in p.rng.randi_range(4, 6):
				Cave._dot(p, j.call(15.0), p.rng.randf_range(1.0, 2.0) * s, Color("#c8b890"), 0.75)
		"carpet:fray":
			var q: Vector2 = j.call(6.0)
			Decals._blob(p, q, 9.0 * s, Color("#7a5a4a"), 0.45, 0.3)
			for k in 7:
				var a := q + Vector2(p.rng.randf_range(-7, 7), p.rng.randf_range(-5, 5)) * s
				Ink.line(p, a, a + Vector2(p.rng.randf_range(-1, 1), p.rng.randf_range(3, 6)) * s, 0.7 * s, Color("#c09070"), 0.5, 0.3)
		"rubble:heap", "rubble:chunks":
			var n := p.rng.randi_range(8, 11) if kind == "heap" else p.rng.randi_range(5, 7)
			var r0 := 11.0 if kind == "heap" else 17.0
			for k in n:
				var rx := p.rng.randf_range(2.2, 6.0) * s
				Cave._stone(p, j.call(r0), rx, rx * p.rng.randf_range(0.6, 0.8), Color("#7a706c").lerp(col, 0.4).lightened(p.rng.randf_range(-0.15, 0.15)))
		"rubble:block":
			_block(p, c + Vector2(p.rng.randf_range(-4, 4), 0) * s, s, col.darkened(0.1))
			for k in 3:
				Cave._stone(p, j.call(16.0), 2.5 * s, 2.0 * s, col)
		"rubble:dust":
			Decals._blob(p, c, 14.0 * s, Color("#8a807a"), 0.3, 0.4)
			for k in 10:
				Cave._dot(p, j.call(16.0), 1.0 * s, Color("#a09890"), 0.6)
		"bloodcrack:fissure":
			K.blood_crack(p, c + Vector2(p.rng.randf_range(-14, -6), p.rng.randf_range(-10, 10)) * s, Vector2.from_angle(p.rng.randf_range(-0.6, 0.6)), 4, 7.0 * s, 2.0 * s)
		"bloodcrack:pool":
			K.pool(p, j.call(4.0), p.rng.randf_range(10.0, 13.0) * s, 1.0, 0.25)
		"bloodcrack:spatter":
			for k in p.rng.randi_range(5, 8):
				Cave._dot(p, j.call(16.0), p.rng.randf_range(0.8, 2.0) * s, K.BLOOD_LIT, 0.8)
		"bloodpool:ring":
			var q: Vector2 = j.call(6.0)
			for r: float in [4.0, 8.0, 12.0]:
				Ink.path(p, Cave._ellipse(q, r * s, r * 0.6 * s, 26), 0.9 * s, true, Color("#c86a60"), 0.2, 0.5)
		"bloodpool:clot":
			for k in p.rng.randi_range(2, 4):
				var rx := p.rng.randf_range(2.0, 4.0) * s
				Cave._stone(p, j.call(12.0), rx, rx * 0.7, Color("#3a0608"))
		"bloodpool:bone":
			K.bone(p, j.call(6.0), j.call(14.0), s, K.BONE.darkened(0.3))
			Cave._dot(p, j.call(12.0), 1.4 * s, Color("#d8a090"), 0.5)
		"bones:skull", "corpsepit:skull":
			K.skull(p, j.call(14.0), s * 1.2, K.BONE.darkened(0.2) if style == "bones" else K.BONE.darkened(0.3))
			K.bone(p, j.call(17.0), j.call(17.0), s, K.BONE.darkened(0.2))
			if style == "bones":
				K.bone(p, j.call(17.0), j.call(17.0), s, K.BONE.darkened(0.3))
		"bones:ribs", "corpsepit:ribs":
			K.ribs(p, j.call(12.0), p.rng.randf() * TAU, s * 1.1)
			if style == "bones":
				K.bone(p, j.call(17.0), j.call(17.0), s, K.BONE.darkened(0.25))
		"bones:pile":
			for k in 4:
				K.bone(p, j.call(17.0), j.call(17.0), s, K.BONE.darkened(p.rng.randf_range(0.1, 0.35)))
			K.skull(p, j.call(14.0), s, K.BONE.darkened(0.25))
		"bones:long":
			for k in 4:
				K.bone(p, j.call(18.0), j.call(18.0), s * 1.1, K.BONE.darkened(p.rng.randf_range(0.1, 0.35)))
		"dirt:straw":
			for k in p.rng.randi_range(12, 18):
				var q: Vector2 = j.call(14.0)
				var e := q + Vector2.from_angle(p.rng.randf() * TAU) * p.rng.randf_range(6, 12) * s
				Ink.line(p, q + Vector2(0.6, 0.8), e + Vector2(0.6, 0.8), 1.4 * s, K.INK, 0.35, 0.5)
				Ink.line(p, q, e, 1.1 * s, Color("#b09a60"), 0.85, 0.5)
		"dirt:bone":
			K.bone(p, j.call(12.0), j.call(12.0), s)
			K.skull(p, j.call(10.0), s * 0.9, K.BONE.darkened(0.2))
		"dirt:chain":
			var q: Vector2 = c + Vector2(-16, -4) * s
			for k in 7:
				Ink.path(p, Cave._ellipse(q, 2.6 * s, 1.7 * s, 10), 1.6 * s, true, K.INK, 0.6, 0.2)
				Ink.path(p, Cave._ellipse(q, 2.6 * s, 1.7 * s, 10), 1.0 * s, true, Color("#6a6468"), 0.95, 0.2)
				q += Vector2(4.4, 1.0) * s
		"grate:rust":
			Decals._blob(p, j.call(6.0), 10.0 * s, Color("#7a4020"), 0.35, 0.4)
		"grate:debris":
			K.bone(p, j.call(8.0), j.call(8.0), s * 0.9)
		"grate:slime":
			Decals._blob(p, j.call(6.0), 8.0 * s, Color("#3a4a2a"), 0.45, 0.4)
		"grate:rag":
			p.fill_poly(Cave._ellipse(j.call(6.0), 8.0 * s, 4.0 * s, 14, p.rng), func(x: int, y: int) -> Color: return p.vary(Color("#4a3c30"), x, y, 0.15))
		"corpsepit:hand":
			_hand(p, j.call(8.0), p.rng.randf_range(-PI, 0.0), s * 1.2)
		"corpsepit:arm":
			var a: Vector2 = j.call(10.0)
			var b := a + Vector2.from_angle(p.rng.randf() * TAU) * 14.0 * s
			Decals._stick(p, a, b, 3.4 * s, K.SKIN.darkened(0.15))
			_hand(p, b, (b - a).angle(), s)
			K.stain(p, a, 4.0 * s, 0.5)
		_:
			pass


## 마른 풀 한 포기(가는 잎 몇 가닥).
static func _tuft(p: Paint, q: Vector2, s: float) -> void:
	Cave._dot(p, q + Vector2(1, 1) * s, 3.0 * s, K.INK, 0.35)
	for k in p.rng.randi_range(7, 10):
		var d := Vector2.from_angle(-PI * 0.5 + p.rng.randf_range(-1.0, 1.0)) * p.rng.randf_range(5.0, 10.0) * s
		Ink.line(p, q, q + d, 1.4 * s, Color("#1e1812"), 0.6, 0.5)
		Ink.line(p, q, q + d, 0.8 * s, Color("#9a8a60").lerp(Color("#6a6040"), p.rng.randf()), 0.9, 0.5)


## 무너진 돌덩이(위에서 본 모난 벽돌 조각).
static func _block(p: Paint, q: Vector2, s: float, col: Color) -> void:
	var top := PackedVector2Array([q + Vector2(-11, -8) * s, q + Vector2(9, -10) * s, q + Vector2(12, -2) * s, q + Vector2(-9, 1) * s])
	var front := PackedVector2Array([q + Vector2(-9, 1) * s, q + Vector2(12, -2) * s, q + Vector2(12, 5) * s, q + Vector2(-9, 8) * s])
	p.fill_poly(PackedVector2Array([q + Vector2(-8, 3) * s, q + Vector2(15, 0) * s, q + Vector2(15, 9) * s, q + Vector2(-6, 11) * s]), func(_x: int, _y: int) -> Color: return Color(0.04, 0.03, 0.03, 0.45))
	p.fill_poly(front, func(x: int, y: int) -> Color: return p.vary(col.darkened(0.3), x, y, 0.1))
	p.fill_poly(top, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.1), x, y, 0.1))
	Ink.path(p, PackedVector2Array([top[0], top[1], top[2], front[2], front[3], top[3]]), 1.3 * s, true, K.INK, 0.8, 0.4)
	Ink.line(p, top[3], top[2], 0.9 * s, K.INK, 0.6, 0.3)
	Cave._crack(p, q + Vector2(-2, -6) * s, 2, 4.0 * s, Vector2(1, 0.4))


## 창백한 손(손바닥 + 손가락 넷).
static func _hand(p: Paint, q: Vector2, ang: float, s: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := Vector2(-d.y, d.x)
	Cave._stone(p, q, 3.2 * s, 2.8 * s, K.SKIN)
	for k in 4:
		var b := q + d * 2.2 * s + n * (k - 1.5) * 1.4 * s
		var e := b + d.rotated((k - 1.5) * 0.15) * p.rng.randf_range(3.5, 5.0) * s
		Ink.line(p, b, e, 1.6 * s, K.INK, 0.7, 0.2)
		Ink.line(p, b, e, 1.0 * s, K.SKIN.lightened(0.1), 0.95, 0.2)


## 팔·다리 하나(굵은 살빛 막대 + 마디 그늘 + 끝에 손).
static func _limb(p: Paint, a: Vector2, b: Vector2, s: float) -> void:
	var m := a.lerp(b, 0.5) + (b - a).orthogonal().normalized() * p.rng.randf_range(-3.0, 3.0) * s
	var tone := K.SKIN.darkened(p.rng.randf_range(0.1, 0.35))
	for seg: Array in [[a, m], [m, b]]:
		var u: Vector2 = seg[0]
		var v: Vector2 = seg[1]
		Ink.line(p, u + Vector2(1.0, 1.4) * s, v + Vector2(1.0, 1.4) * s, 4.4 * s, Color(0.03, 0.02, 0.02), 0.5, 0.3)
		Ink.line(p, u, v, 4.4 * s, K.INK, 0.85, 0.3)
		Ink.line(p, u, v, 3.2 * s, tone, 1.0, 0.3)
		Ink.line(p, u - Vector2(0.6, 0.6) * s, v - Vector2(0.6, 0.6) * s, 1.0 * s, tone.lightened(0.3), 0.7, 0.3)
	_hand(p, b, (b - m).angle(), s * 0.85)
