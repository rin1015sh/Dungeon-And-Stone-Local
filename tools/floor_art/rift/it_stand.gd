extends RefCounted
## 강철의 묘 서 있는 소품(칸 128×192, 발 = (w/2, h - w×0.14)): 쇠 난간 · 무너진 돌덩이 · 금 촛대 · 기사 석상 · 강철 석관.
## 나머지(갑옷 · 떨어진 샹들리에 · 화로 · 유골함 · 보물 더미)는 it_stand2.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const L := preload("res://tools/floor_art/rift/it_lib.gd")
const Stand2 := preload("res://tools/floor_art/rift/it_stand2.gd")

const BRONZE := Color("#7a6a48")
const STATUE := Color("#74767c")


static func paint(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var u := w / 128.0
	var foot := Vector2(w * 0.5, h - w * 0.14)
	match tile:
		"it_railing":
			_railing(p, foot, u)
		"it_debris":
			_debris(p, foot, u)
		"it_candelabra":
			_candelabra(p, foot, u)
		"it_statue":
			_statue(p, foot, u)
		"it_sarcophagus":
			_sarcophagus(p, foot, u)
		_:
			Stand2.paint(p, tile, foot, u)
	return p


## 쇠 난간: 돌 턱 + 돌림 난간동자 8개 + 가운데 띠 + 청동 손잡이(칸 좌우 끝까지 — 이웃 칸과 이어진다).
static func _railing(p: Paint, foot: Vector2, u: float) -> void:
	var half := 32.0 * u
	Kit.shadow(p, foot + Vector2(0, 2) * u, half + 2.0 * u, 4.0 * u, 0.35)
	Kit.box(p, foot + Vector2(0, 2) * u, half * 2.0, 8.0 * u, 5.0 * u, L.STONE.darkened(0.15))
	for k in 8:
		var x := foot.x - half + (4.0 + k * 8.0) * u
		var prof: Array[Vector2] = [Vector2(0, 2.2), Vector2(2, 2.6), Vector2(4, 1.4), Vector2(8, 1.3), Vector2(13, 3.0), Vector2(17, 2.6), Vector2(21, 1.2), Vector2(25, 1.3), Vector2(27, 2.4), Vector2(28.5, 2.4)]
		for j in prof.size():
			prof[j] *= u
		L.lathe(p, Vector2(x, foot.y - 3.0 * u), prof, L.IRON.lightened(0.15), true, 0.7)
	Kit.box(p, Vector2(foot.x, foot.y - 12.0 * u), half * 2.0, 3.0 * u, 2.0 * u, L.IRON.lightened(0.1), 0.8)
	Kit.box(p, Vector2(foot.x, foot.y - 31.0 * u), half * 2.0, 6.0 * u, 4.5 * u, BRONZE, 1.0)
	Ink.line(p, Vector2(foot.x - half + 2.0 * u, foot.y - 36.6 * u), Vector2(foot.x + half - 2.0 * u, foot.y - 36.6 * u), 1.0 * u, Color("#e8d8a8"), 0.35, 0.2)
	for k in 3:  # 녹 얼룩
		Cave._dot(p, Vector2(foot.x + p.rng.randf_range(-half, half), foot.y - p.rng.randf_range(10, 30) * u), 3.0 * u, L.RUST, 0.35)


## 무너진 돌덩이: 깨진 큰 덩이 둘 + 기둥 북돌 토막 + 부스러기·먼지.
static func _debris(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(0, -6) * u, 38 * u, 13 * u, 0.4)
	Kit.cyl(p, foot + Vector2(-22, -14) * u, 11 * u, 14 * u, L.STONE.darkened(0.05), 0)
	Ink.line(p, foot + Vector2(-30, -28) * u, foot + Vector2(-16, -26) * u, 1.2 * u, Ink.INK, 0.6, 0.8)
	var big := PackedVector2Array([foot + Vector2(-12, -40) * u, foot + Vector2(18, -44) * u, foot + Vector2(26, -36) * u, foot + Vector2(22, -26) * u, foot + Vector2(-6, -22) * u, foot + Vector2(-14, -30) * u])
	L.slab(p, big, 16 * u, L.STONE.lightened(0.05), 0.5, u)
	Cave._crack(p, foot + Vector2(4, -38) * u, 3, 6 * u, Vector2(0.5, 1))
	var small := PackedVector2Array([foot + Vector2(10, -14) * u, foot + Vector2(28, -18) * u, foot + Vector2(32, -8) * u, foot + Vector2(16, -2) * u, foot + Vector2(8, -6) * u])
	L.slab(p, small, 9 * u, Color("#5a5c62"), 0.45, u)
	var tiny := PackedVector2Array([foot + Vector2(-18, -6) * u, foot + Vector2(-6, -9) * u, foot + Vector2(-2, -2) * u, foot + Vector2(-14, 1) * u])
	L.slab(p, tiny, 5 * u, L.STONE.darkened(0.1), 0.4, u)
	for k in 9:
		var q := foot + Vector2(p.rng.randf_range(-34, 34), p.rng.randf_range(-12, 4)) * u
		var r := p.rng.randf_range(1.5, 3.5) * u
		Cave._stone(p, q, r, r * 0.7, L.STONE.lightened(p.rng.randf_range(-0.1, 0.15)))
	for k in 30:  # 먼지
		Cave._dot(p, foot + Vector2(p.rng.randf_range(-30, 30), p.rng.randf_range(-40, 2)) * u, 0.8 * u, Color("#b8b8b4"), 0.35)


## 금 촛대: 세발 받침 · 마디 있는 기둥 · 다섯 가지 · 촛농 흐른 초와 불꽃.
static func _candelabra(p: Paint, foot: Vector2, u: float) -> void:
	var gold := L.GOLD
	var base := foot + Vector2(0, -16) * u
	Kit.shadow(p, foot, 22 * u, 7 * u, 0.45)
	L.halo(p, foot + Vector2(0, -124) * u, 52 * u, Color("#ffb060"), 0.45)
	for k in 3:
		var tip := foot + Vector2([-18.0, 18.0, 4.0][k], [0.0, 0.0, -9.0][k]) * u
		var mid := base.lerp(tip, 0.55) + Vector2(0, -6) * u
		Kit.post(p, base, mid, 3.4 * u, gold.darkened(0.15))
		Kit.post(p, mid, tip, 3.0 * u, gold.darkened(0.15))
		p.fill_poly(Cave._ellipse(tip, 3.2 * u, 2.2 * u, 10), func(x: int, y: int) -> Color: return L.shade_round(gold, (x - tip.x) / (3.2 * u), true))
	var prof: Array[Vector2] = [Vector2(0, 7), Vector2(4, 5), Vector2(6, 2.4), Vector2(18, 2.2), Vector2(21, 5), Vector2(24, 2.2), Vector2(56, 2.0), Vector2(59, 4.6), Vector2(62, 2.0),
		Vector2(90, 1.8), Vector2(93, 4.2), Vector2(96, 1.8), Vector2(100, 2.4), Vector2(103, 3.4)]
	for j in prof.size():
		prof[j] *= u
	L.lathe(p, base, prof, gold, true, 0.9)
	var hub := base + Vector2(0, -101) * u
	var cups: Array[Vector2] = [Vector2(-24, -7), Vector2(-12, -14), Vector2(0, -20), Vector2(12, -14), Vector2(24, -7)]
	for k in cups.size():  # 가지
		var cup := hub + cups[k] * u
		if k == 2:
			Kit.post(p, hub, cup, 3.0 * u, gold)
			continue
		var bend := Vector2(cup.x, hub.y + 3.0 * u)
		Kit.post(p, hub, bend, 2.6 * u, gold)
		Kit.post(p, bend, cup, 2.4 * u, gold)
	for k in cups.size():
		var cup := hub + cups[k] * u
		var cp: Array[Vector2] = [Vector2(0, 1.0), Vector2(2, 3.6), Vector2(3.5, 4.0)]
		for j in cp.size():
			cp[j] *= u
		L.lathe(p, cup, cp, gold, true, 0.8)
		var ch := (11.0 - absf(k - 2) * 2.5 + (1.0 if k == 1 else 0.0)) * u
		var top := cup + Vector2(0, -3.5 * u - ch)
		var cand := PackedVector2Array([top + Vector2(-2.2, 0) * u, top + Vector2(2.2, 0) * u, cup + Vector2(2.2, -3.5) * u, cup + Vector2(-2.2, -3.5) * u])
		L.part(p, cand, L.CANDLE, 0.8, false, 0.7)
		Ink.line(p, top + Vector2(-1.6, 0.5) * u, top + Vector2(-1.8, 5) * u, 1.2 * u, Color("#f0e8d0"), 0.8, 0.3)
		Kit.flame(p, top + Vector2(0, -0.5) * u, 3.4 * u)
	L.glint(p, base + Vector2(-2, -58) * u, 3.0 * u, 0.7)
	L.glint(p, hub + Vector2(-20, -5) * u, 2.4 * u, 0.6)


## 기사 석상: 돌 받침 위, 칼끝을 바닥에 세우고 두 손을 칼자루에 얹은 판금 기사.
static func _statue(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(4, -6) * u, 36 * u, 13 * u, 0.45)
	var plinth := Color("#6a6c72")
	Kit.box(p, foot, 56 * u, 38 * u, 22 * u, plinth)
	Kit.box(p, foot + Vector2(0, -19) * u, 62 * u, 42 * u, 4 * u, plinth.lightened(0.08))
	Ink.line(p, foot + Vector2(-16, -9) * u, foot + Vector2(16, -9) * u, 1.0 * u, Ink.INK, 0.5, 0.3)
	var k := foot + Vector2(4, -34) * u
	var s := u
	var st := STATUE
	var pts := func(arr: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for v: Vector2 in arr:
			out.append(k + v * s)
		return out
	for sx: float in [-1.0, 1.0]:  # 다리·무릎·발
		L.part(p, pts.call([Vector2(sx * 2, 0), Vector2(sx * 10, 0), Vector2(sx * 10.5, -30), Vector2(sx * 3, -30)]), st, 0.7)
		p.fill_poly(Cave._ellipse(k + Vector2(sx * 6.5, -30) * s, 4.2 * s, 3.4 * s, 12), func(x: int, y: int) -> Color: return L.shade_round(st, (x - k.x - sx * 6.5 * s) / (4.2 * s), false))
		L.part(p, pts.call([Vector2(sx * 1.5, 1), Vector2(sx * 11, 1), Vector2(sx * 10, -5), Vector2(sx * 3, -5)]), st.darkened(0.05), 0.5)
	L.part(p, pts.call([Vector2(-14, -33), Vector2(14, -33), Vector2(11.5, -56), Vector2(-11.5, -56)]), st, 0.75)
	for j in 3:
		Ink.line(p, k + Vector2(-13 + j * 0.8, -40 - j * 6) * s, k + Vector2(13 - j * 0.8, -40 - j * 6) * s, 1.0 * s, Ink.INK, 0.55, 0.2)
	L.part(p, pts.call([Vector2(-5, -18), Vector2(5, -18), Vector2(6, -56), Vector2(-6, -56)]), st.darkened(0.08), 0.4)
	L.part(p, pts.call([Vector2(-11.5, -56), Vector2(11.5, -56), Vector2(15, -82), Vector2(8, -87), Vector2(-8, -87), Vector2(-15, -82)]), st, 0.85)
	Ink.line(p, k + Vector2(0, -60) * s, k + Vector2(0, -84) * s, 1.0 * s, Ink.INK, 0.4, 0.3)
	for sx: float in [-1.0, 1.0]:  # 팔
		Kit.post(p, k + Vector2(sx * 16, -80) * s, k + Vector2(sx * 15, -64) * s, 7.5 * s, st.darkened(0.05))
		Kit.post(p, k + Vector2(sx * 15, -64) * s, k + Vector2(sx * 4, -58) * s, 6.5 * s, st.darkened(0.05))
		p.fill_poly(Cave._ellipse(k + Vector2(sx * 17, -83) * s, 8.0 * s, 6.5 * s, 16), func(x: int, y: int) -> Color:
			var n := Vector2(x - k.x - sx * 17 * s, y - k.y + 83 * s) / (8.0 * s)
			return p.vary(st.darkened(0.4).lerp(st.lightened(0.2), clampf(0.55 - n.x * 0.45 - n.y * 0.5, 0.0, 1.0)), x, y, 0.06))
		Ink.path(p, Cave._ellipse(k + Vector2(sx * 17, -83) * s, 8.0 * s, 6.5 * s, 16), 1.1 * s, true, Ink.INK, 0.75, 0.3)
		Ink.line(p, k + Vector2(sx * 10, -82) * s, k + Vector2(sx * 23, -80) * s, 0.9 * s, Ink.INK, 0.45, 0.3)
	L.part(p, pts.call([Vector2(-6, -86), Vector2(6, -86), Vector2(5.5, -90), Vector2(-5.5, -90)]), st.darkened(0.1), 0.6)
	var helm: PackedVector2Array = pts.call([Vector2(-7.5, -89), Vector2(7.5, -89), Vector2(8, -104), Vector2(4, -109), Vector2(-4, -109), Vector2(-8, -104)])
	L.part(p, helm, st, 0.85)
	Ink.line(p, k + Vector2(-6.5, -99) * s, k + Vector2(6.5, -99) * s, 1.6 * s, Color("#0c0c0e"), 0.9, 0.1)
	Ink.line(p, k + Vector2(0, -92) * s, k + Vector2(0, -108) * s, 1.0 * s, Ink.INK, 0.5, 0.1)
	for j in 3:
		Cave._dot(p, k + Vector2(2.5, -94 + j * 1.6) * s, 0.6 * s, Ink.INK, 0.8)
	var blade: PackedVector2Array = pts.call([Vector2(-2.2, -54), Vector2(2.2, -54), Vector2(1.0, -6), Vector2(0, -2), Vector2(-1.0, -6)])
	L.part(p, blade, st.lightened(0.08), 0.6, false, 0.9)
	Ink.line(p, k + Vector2(0, -52) * s, k + Vector2(0, -8) * s, 0.7 * s, Ink.INK, 0.35, 0.1)
	L.part(p, pts.call([Vector2(-10, -56.5), Vector2(10, -56.5), Vector2(9, -53.5), Vector2(-9, -53.5)]), st, 0.5)
	p.fill_poly(Cave._ellipse(k + Vector2(0, -59) * s, 6.0 * s, 4.0 * s, 14), func(x: int, y: int) -> Color:
		var n := Vector2(x - k.x, y - k.y + 59 * s) / (6.0 * s)
		return p.vary(st.darkened(0.35).lerp(st.lightened(0.2), clampf(0.5 - n.x * 0.4 - n.y * 0.5, 0.0, 1.0)), x, y, 0.06))
	Ink.path(p, Cave._ellipse(k + Vector2(0, -59) * s, 6.0 * s, 4.0 * s, 14), 1.0 * s, true, Ink.INK, 0.75, 0.2)
	p.fill_poly(Cave._ellipse(k + Vector2(0, -64.5) * s, 2.4 * s, 2.0 * s, 10), func(_x: int, _y: int) -> Color: return st.lightened(0.1))
	Ink.path(p, Cave._ellipse(k + Vector2(0, -64.5) * s, 2.4 * s, 2.0 * s, 10), 0.8 * s, true, Ink.INK, 0.7, 0.1)
	Ink.hatch(p, pts.call([Vector2(4, -2), Vector2(14, -2), Vector2(16, -84), Vector2(6, -84)]), 3.2 * s, 65.0, 0.18, 0.8 * s)
	Ink.grime(p, k.x - 10 * s, k.y - 86 * s, 20 * s, 30 * s, 0.25, Color("#2a2a24"))
	Ink.grime(p, foot.x - 24 * u, foot.y - 22 * u, 48 * u, 14 * u, 0.3, Color("#2a2a24"))


## 강철 석관(남북으로 누운 관): 리벳 박은 몸 + 조금 큰 뚜껑 + 뚜껑에 새긴 누운 기사.
static func _sarcophagus(p: Paint, foot: Vector2, u: float) -> void:
	var body := Color("#5a5e66")
	var lid := Color("#6e7278")
	Kit.shadow(p, foot + Vector2(10, -22) * u, 36 * u, 30 * u, 0.42)
	Kit.box(p, foot, 46 * u, 88 * u, 22 * u, body)
	var lf := foot + Vector2(0, -22) * u
	var lw := 52.0 * u
	var ld := 92.0 * u
	Kit.box(p, lf + Vector2(0, 1) * u, lw, ld, 6 * u, lid)
	var top0 := lf + Vector2(-lw * 0.5, -5.0 * u)
	var dd := ld * Kit.DEPTH
	var at := func(a: float, b: float) -> Vector2:  # 뚜껑 윗면 좌표(가로 a, 깊이 b — 0~1)
		return top0 + Vector2(lw * a + dd * 0.35 * b, -dd * b)
	var wc := Color(1, 1, 1, 1)
	var draw := func(m: Paint) -> void:
		var hd: Vector2 = at.call(0.5, 0.84)
		m.fill_poly(Cave._ellipse(hd, 6.0 * u, 4.6 * u, 14), func(_x: int, _y: int) -> Color: return wc)
		var body_pts := PackedVector2Array([at.call(0.28, 0.74), at.call(0.72, 0.74), at.call(0.62, 0.22), at.call(0.5, 0.12), at.call(0.38, 0.22)])
		Ink.path(m, body_pts, 1.6 * u, true, wc, 1.0, 0.0)
		Ink.line(m, at.call(0.5, 0.7), at.call(0.5, 0.18), 1.8 * u, wc, 1.0, 0.0)
		Ink.line(m, at.call(0.36, 0.62), at.call(0.64, 0.62), 1.6 * u, wc, 1.0, 0.0)
		Ink.path(m, PackedVector2Array([at.call(0.08, 0.06), at.call(0.92, 0.06), at.call(0.92, 0.94), at.call(0.08, 0.94)]), 1.2 * u, true, wc, 1.0, 0.0)
	L.relief(p, draw, lid.lightened(0.1), 0.2, true, 1.0)
	for a: float in [0.1, 0.9]:
		for b: float in [0.1, 0.5, 0.9]:
			var q: Vector2 = at.call(a, b)
			p.fill_poly(Cave._ellipse(q, 1.6 * u, 1.3 * u, 8), func(_x: int, _y: int) -> Color: return lid.lightened(0.3))
			Cave._dot(p, q + Vector2(0.8, 0.8) * u, 1.2 * u, L.SHADE, 0.6)
	for k in 5:  # 앞면 리벳
		var q := foot + Vector2(-18 + k * 9, -17) * u
		p.fill_poly(Cave._ellipse(q, 1.5 * u, 1.5 * u, 8), func(_x: int, _y: int) -> Color: return body.lightened(0.3))
		Cave._dot(p, q + Vector2(0.8, 0.8) * u, 1.1 * u, L.SHADE, 0.6)
	var plate := Paint.rect_poly(foot.x - 12 * u, foot.y - 13 * u, 24 * u, 8 * u)
	Ink.path(p, plate, 1.0 * u, true, Ink.INK, 0.6, 0.2)
	for k in 4:
		Ink.line(p, foot + Vector2(-9 + k * 5, -11) * u, foot + Vector2(-7 + k * 5, -7) * u, 0.8 * u, Ink.INK, 0.5, 0.2)
	Ink.grime(p, foot.x - 22 * u, foot.y - 21 * u, 44 * u, 16 * u, 0.3, Color("#1a1c20"))
	Cave._dot(p, foot + Vector2(14, -30) * u, 5 * u, L.RUST, 0.4)
