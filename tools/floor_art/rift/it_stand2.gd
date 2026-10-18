extends RefCounted
## 강철의 묘 서 있는 소품(이어서): 갑옷 진열대 · 바닥에 떨어진 쇠고리 샹들리에 · 쇠 화로 · 유골함 · 보물 더미.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const L := preload("res://tools/floor_art/rift/it_lib.gd")

const ARMOR := Color("#8a9098")
const WOOD := Color("#4a3626")


static func paint(p: Paint, tile: String, foot: Vector2, u: float) -> void:
	match tile:
		"it_armor":
			_armor(p, foot, u)
		"it_chandelier":
			_chandelier(p, foot, u)
		"it_brazier":
			_brazier(p, foot, u)
		"it_urn":
			_urn(p, foot, u)
		"it_treasure":
			_treasure(p, foot, u)


## 갑옷 진열대: 나무 받침 위 판금 갑옷 한 벌(투구 · 어깨받이 · 진홍 겉옷) + 오른손에 세운 미늘창.
static func _armor(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(2, -4) * u, 26 * u, 9 * u, 0.45)
	Kit.box(p, foot, 40 * u, 30 * u, 6 * u, WOOD)
	var k := foot + Vector2(1, -10) * u
	var pole_x := k.x + 19 * u
	Kit.post(p, Vector2(pole_x, k.y + 2 * u), Vector2(pole_x, k.y - 132 * u), 2.6 * u, WOOD.lightened(0.1))
	var axe := PackedVector2Array([Vector2(pole_x, k.y - 120 * u), Vector2(pole_x + 12 * u, k.y - 126 * u), Vector2(pole_x + 14 * u, k.y - 112 * u), Vector2(pole_x + 9 * u, k.y - 104 * u), Vector2(pole_x, k.y - 108 * u)])
	L.part(p, axe, ARMOR, 0.3, true)
	var spike := PackedVector2Array([Vector2(pole_x - 1.6 * u, k.y - 130 * u), Vector2(pole_x, k.y - 144 * u), Vector2(pole_x + 1.6 * u, k.y - 130 * u)])
	L.part(p, spike, ARMOR, 0.3, true)
	L.part(p, PackedVector2Array([Vector2(pole_x, k.y - 116 * u), Vector2(pole_x - 7 * u, k.y - 118 * u), Vector2(pole_x - 4 * u, k.y - 112 * u)]), ARMOR.darkened(0.1), 0.3, true)
	var pts := func(arr: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for v: Vector2 in arr:
			out.append(k + v * u)
		return out
	for sx: float in [-1.0, 1.0]:
		L.part(p, pts.call([Vector2(sx * 2.5, 0), Vector2(sx * 10, 0), Vector2(sx * 9.5, -30), Vector2(sx * 3, -30)]), ARMOR, 0.85, true)
		L.part(p, pts.call([Vector2(sx * 1.5, 1), Vector2(sx * 11.5, 1), Vector2(sx * 10, -4), Vector2(sx * 3, -4)]), ARMOR.darkened(0.15), 0.6, true)
		p.fill_poly(Cave._ellipse(k + Vector2(sx * 6.5, -30) * u, 4.5 * u, 3.6 * u, 12), func(x: int, _y: int) -> Color: return L.shade_round(ARMOR, (x - k.x - sx * 6.5 * u) / (4.5 * u), true))
		L.part(p, pts.call([Vector2(sx * 3, -33), Vector2(sx * 11, -33), Vector2(sx * 11.5, -54), Vector2(sx * 2, -54)]), ARMOR, 0.85, true)
	L.part(p, pts.call([Vector2(-6, -20), Vector2(6, -20), Vector2(7, -58), Vector2(-7, -58)]), L.CRIMSON, 0.5)
	Ink.line(p, k + Vector2(-5, -24) * u, k + Vector2(5, -24) * u, 1.0 * u, Color("#8a7038"), 0.7, 0.3)
	L.part(p, pts.call([Vector2(-12, -54), Vector2(12, -54), Vector2(15, -80), Vector2(8, -86), Vector2(-8, -86), Vector2(-15, -80)]), ARMOR, 0.95, true)
	L.part(p, pts.call([Vector2(-7, -56), Vector2(7, -56), Vector2(7.5, -72), Vector2(-7.5, -72)]), L.CRIMSON.darkened(0.05), 0.5)
	for sx: float in [-1.0, 1.0]:  # 늘어뜨린 팔
		Kit.post(p, k + Vector2(sx * 17, -80) * u, k + Vector2(sx * 18, -62) * u, 7.0 * u, ARMOR.darkened(0.1))
		Kit.post(p, k + Vector2(sx * 18, -62) * u, k + Vector2(sx * 17, -46) * u, 6.0 * u, ARMOR.darkened(0.1))
		p.fill_poly(Cave._ellipse(k + Vector2(sx * 17, -43) * u, 3.8 * u, 4.6 * u, 12), func(x: int, _y: int) -> Color: return L.shade_round(ARMOR.darkened(0.2), (x - k.x - sx * 17 * u) / (3.8 * u), true))
		var pd := Cave._ellipse(k + Vector2(sx * 16.5, -82) * u, 8.5 * u, 6.0 * u, 16)
		p.fill_poly(pd, func(x: int, y: int) -> Color:
			var n := Vector2(x - k.x - sx * 16.5 * u, y - k.y + 82 * u) / (8.5 * u)
			return L.shade_round(ARMOR, clampf(n.x * 0.8 + n.y * 0.4, -1.0, 1.0), true))
		Ink.path(p, pd, 1.1 * u, true, Ink.INK, 0.75, 0.3)
		Ink.line(p, k + Vector2(sx * 9, -79) * u, k + Vector2(sx * 24, -78) * u, 0.9 * u, Ink.INK, 0.45, 0.3)
	var helm: PackedVector2Array = pts.call([Vector2(-7, -86), Vector2(7, -86), Vector2(8.5, -98), Vector2(5, -106), Vector2(-5, -106), Vector2(-8.5, -98)])
	L.part(p, helm, ARMOR, 0.95, true)
	Ink.line(p, k + Vector2(-6, -96) * u, k + Vector2(6, -96) * u, 1.6 * u, Color("#08080a"), 0.95, 0.1)
	Ink.line(p, k + Vector2(-7, -92) * u, k + Vector2(7, -91) * u, 0.8 * u, Ink.INK, 0.5, 0.2)
	Ink.line(p, k + Vector2(0, -98) * u, k + Vector2(0, -107) * u, 1.6 * u, ARMOR.lightened(0.2), 0.6, 0.1)
	var hand := k + Vector2(19, -56) * u  # 창 잡은 손
	p.fill_poly(Cave._ellipse(hand, 3.6 * u, 3.0 * u, 12), func(x: int, _y: int) -> Color: return L.shade_round(ARMOR.darkened(0.2), (x - hand.x) / (3.6 * u), true))
	Ink.path(p, Cave._ellipse(hand, 3.6 * u, 3.0 * u, 12), 0.9 * u, true, Ink.INK, 0.7, 0.2)
	Ink.hatch(p, pts.call([Vector2(5, -2), Vector2(13, -2), Vector2(16, -84), Vector2(7, -84)]), 3.4 * u, 65.0, 0.14, 0.8 * u)
	Cave._dot(p, k + Vector2(-6, -66) * u, 3.0 * u, L.RUST, 0.3)


## 떨어진 쇠고리 샹들리에: 바닥에 누운 고리 · 사슬 · 쓰러진 초 · 몇 개는 아직 타는 촛불.
static func _chandelier(p: Paint, foot: Vector2, u: float) -> void:
	var c := foot + Vector2(0, -14) * u
	var rx := 34.0 * u
	var ry := 14.5 * u
	var gold := Color("#8a7034")
	Kit.shadow(p, c + Vector2(2, 3) * u, rx + 4 * u, ry + 4 * u, 0.4)
	var hub := c + Vector2(-4, -28) * u
	for a: float in [-2.5, -1.6, -0.6]:  # 가운데 고리로 모이는 사슬(바닥에 누움)
		_chain(p, c + Vector2(cos(a) * rx, sin(a) * ry), hub, 2.2 * u)
	_chain(p, hub, hub + Vector2(-26, -14) * u, 2.2 * u)
	Ink.path(p, Cave._ellipse(hub, 4 * u, 2 * u, 12), 1.8 * u, true, Color("#2a2a2c"), 0.95, 0.2)
	var lit: Array[int] = [1, 4, 6]
	for half in 2:  # 뒤 반쪽 → 앞 반쪽
		var pts := PackedVector2Array()
		for j in 25:
			var a := PI + PI * j / 24.0 + (PI if half == 1 else 0.0)
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		if half == 1:
			Ink.path(p, pts, 8.0 * u, false, Color("#1a1612"), 0.95, 0.3)
			Ink.path(p, pts, 5.0 * u, false, gold.darkened(0.25), 0.95, 0.3)
			var hi := PackedVector2Array()
			for q in pts:
				hi.append(q + Vector2(0, -1.4) * u)
			Ink.path(p, hi, 1.2 * u, false, Color("#d8c080"), 0.55, 0.3)
		else:
			Ink.path(p, pts, 7.0 * u, false, Color("#1a1612"), 0.95, 0.3)
			Ink.path(p, pts, 4.0 * u, false, gold.darkened(0.35), 0.9, 0.3)
		for k in 8:
			var a := TAU * k / 8.0 + 0.2
			var back := sin(a) < 0.0
			if back != (half == 0):
				continue
			var q := c + Vector2(cos(a) * rx, sin(a) * ry)
			var cp: Array[Vector2] = [Vector2(0, 1.2), Vector2(2.4, 3.4), Vector2(3.6, 3.8)]
			for j in cp.size():
				cp[j] *= u
			L.lathe(p, q, cp, gold, true, 0.7)
			if k == 2 or k == 7:  # 쓰러진 초
				var d := Vector2.from_angle(a + 0.9) * 10 * u
				Ink.line(p, q + Vector2(0, -2) * u, q + Vector2(0, -2) * u + d, 3.6 * u, Color("#1a140e"), 0.9, 0.2)
				Ink.line(p, q + Vector2(0, -2) * u, q + Vector2(0, -2) * u + d, 2.2 * u, L.CANDLE, 0.95, 0.2)
				continue
			if k == 3:
				continue
			var hgt := (9.0 if lit.has(k) else 4.0 + k % 3 * 2.0) * u
			var top := q + Vector2(0, -3.6 * u - hgt)
			L.part(p, PackedVector2Array([top + Vector2(-2, 0) * u, top + Vector2(2, 0) * u, q + Vector2(2, -3.6) * u, q + Vector2(-2, -3.6) * u]), L.CANDLE, 0.8, false, 0.7)
			if lit.has(k):
				L.halo(p, top + Vector2(0, -3) * u, 22 * u, Color("#ffa050"), 0.4)
				Kit.flame(p, top + Vector2(0, -0.5) * u, 3.0 * u)


## 사슬: a → b 고리를 번갈아(가로·세로).
static func _chain(p: Paint, a: Vector2, b: Vector2, s: float) -> void:
	var n := int(a.distance_to(b) / (2.4 * s)) + 1
	var d := (b - a).normalized()
	for k in n:
		var q := a.lerp(b, float(k) / maxf(1, n - 1)) + Vector2(0, sin(k * 0.6) * 0.8 * s)
		var lng := k % 2 == 0
		var e := PackedVector2Array()
		for j in 12:
			var t := TAU * j / 12.0
			var v := d * cos(t) * 1.6 * s + Vector2(-d.y, d.x) * sin(t) * (0.9 if lng else 0.35) * s
			e.append(q + v)
		Ink.path(p, e, 1.1 * s * 0.6, true, Color("#1e1e20"), 0.95, 0.1)
		if lng:
			Ink.line(p, q - d * 1.0 * s + Vector2(-0.4, -0.5) * s, q + d * 0.4 * s + Vector2(-0.4, -0.5) * s, 0.5 * s, Color("#9a9aa0"), 0.6, 0.1)


## 쇠 화로: 짐승 발 세 다리 · 리벳 띠 두른 그릇 · 숯불과 불꽃 · 불똥.
static func _brazier(p: Paint, foot: Vector2, u: float) -> void:
	var iron := Color("#3e3c3a")
	Kit.shadow(p, foot + Vector2(0, -2) * u, 24 * u, 8 * u, 0.45)
	L.halo(p, foot + Vector2(0, -56) * u, 60 * u, Color("#ff8a3a"), 0.5)
	var bowl := foot + Vector2(0, -34) * u
	for k in 3:
		var tip := foot + Vector2([-17.0, 17.0, 3.0][k], [0.0, 0.0, -8.0][k]) * u
		var knee := bowl.lerp(tip, 0.5) + Vector2([-5.0, 5.0, 1.0][k], 0) * u
		Kit.post(p, bowl + Vector2([-8.0, 8.0, 1.0][k], 2) * u, knee, 3.4 * u, iron)
		Kit.post(p, knee, tip, 3.0 * u, iron)
		Cave._stone(p, tip, 3.2 * u, 2.2 * u, iron.lightened(0.1))
	var prof: Array[Vector2] = [Vector2(0, 5), Vector2(2, 9), Vector2(6, 15), Vector2(10, 19), Vector2(13, 21), Vector2(14, 21.5)]
	for j in prof.size():
		prof[j] *= u
	L.lathe(p, bowl, prof, iron.lightened(0.15), true, 1.0)
	for j in 7:  # 리벳 띠
		var a := PI * (0.15 + j / 8.0)
		var q := bowl + Vector2(cos(a) * 18.5, -8.0 + sin(a) * 2.5) * u
		Cave._dot(p, q, 1.4 * u, Color("#8a8a8e"), 0.9)
		Cave._dot(p, q + Vector2(0.6, 0.6) * u, 1.0 * u, L.SHADE, 0.5)
	var rim := bowl + Vector2(0, -14) * u
	var mouth := Cave._ellipse(rim, 21.5 * u, 6.5 * u, 28)
	p.fill_poly(mouth, func(x: int, y: int) -> Color:
		var hot := p.nz("mid", x, y)
		return Color("#1a0c06").lerp(Color("#c8501c"), clampf(hot * 1.4 - 0.3, 0.0, 1.0)))
	Ink.path(p, mouth, 1.6 * u, true, Ink.INK, 0.85, 0.2)
	for k in 14:
		Cave._dot(p, rim + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-4, 4)) * u, p.rng.randf_range(0.8, 1.8) * u, Color("#ffb050"), 0.9)
	for q: Vector3 in [Vector3(-9, -1, 7.0), Vector3(7, 0, 7.5), Vector3(0, -3, 10.5), Vector3(-2, 2, 6.0)]:
		Kit.flame(p, rim + Vector2(q.x, q.y) * u, q.z * u)
	for k in 7:
		var q := rim + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-48, -20)) * u
		L.halo(p, q, 2.4 * u, Color("#ffd080"), 1.0)


## 유골함: 큰 청동 항아리(뚜껑·띠 무늬·녹청) + 작은 항아리 하나.
static func _urn(p: Paint, foot: Vector2, u: float) -> void:
	var bronze := Color("#7a6448")
	Kit.shadow(p, foot + Vector2(2, -3) * u, 26 * u, 8 * u, 0.45)
	var big := foot + Vector2(-6, -4) * u
	var prof: Array[Vector2] = [Vector2(0, 8), Vector2(2, 8.5), Vector2(4, 6.5), Vector2(8, 10), Vector2(14, 14.5), Vector2(21, 16), Vector2(28, 14.5), Vector2(34, 11),
		Vector2(39, 7), Vector2(43, 6.5), Vector2(45, 9), Vector2(47, 9.5), Vector2(48, 8.5), Vector2(52, 7), Vector2(55, 4), Vector2(56, 2.2), Vector2(58, 2.6), Vector2(60, 1.6)]
	for j in prof.size():
		prof[j] *= u
	L.lathe(p, big, prof, bronze, true, 1.0)
	for hh: float in [14.0, 31.0]:
		var r := L.radius_at(prof, hh * u)
		var arc := PackedVector2Array()
		for j in 13:
			var a := PI * j / 12.0
			arc.append(big + Vector2(cos(a) * r, -hh * u + sin(a) * r * 0.22))
		Ink.path(p, arc, 1.3 * u, false, Color("#2a1e12"), 0.75, 0.2)
		var arc2 := PackedVector2Array()
		for q in arc:
			arc2.append(q + Vector2(0, 1.3) * u)
		Ink.path(p, arc2, 0.8 * u, false, Color("#c8b080"), 0.35, 0.2)
	for k in 6:  # 띠 사이 새김
		var a := PI * (0.2 + k * 0.12)
		var r := L.radius_at(prof, 22.0 * u)
		var q := big + Vector2(cos(a) * r * 0.92, -22 * u + sin(a) * r * 0.2)
		Ink.line(p, q + Vector2(0, -4) * u, q + Vector2(0, 4) * u, 1.0 * u, Color("#2a1e12"), 0.5, 0.2)
	for k in 4:
		Cave._dot(p, big + Vector2(p.rng.randf_range(-10, 12), -p.rng.randf_range(6, 40)) * u, p.rng.randf_range(2.5, 4.5) * u, Color("#4a6050"), 0.35)
	L.glint(p, big + Vector2(-7, -24) * u, 2.4 * u, 0.5)
	var small := foot + Vector2(17, 2) * u
	var sp: Array[Vector2] = [Vector2(0, 4.5), Vector2(2, 5), Vector2(8, 8.5), Vector2(15, 8), Vector2(20, 5), Vector2(23, 4), Vector2(25, 5), Vector2(26, 4.6)]
	for j in sp.size():
		sp[j] *= u
	L.lathe(p, small, sp, Color("#6a5a48"), false, 0.9)
	p.fill_poly(Cave._ellipse(small + Vector2(0, -26) * u, 4.4 * u, 1.6 * u, 12), func(_x: int, _y: int) -> Color: return Color("#120c08"))
	Cave._crack(p, small + Vector2(-3, -18) * u, 2, 4 * u, Vector2(0.4, 1))
	L.slab(p, PackedVector2Array([foot + Vector2(22, 8) * u, foot + Vector2(29, 6) * u, foot + Vector2(31, 10) * u, foot + Vector2(24, 12) * u]), 2 * u, Color("#6a5a48"), 0.4, u)


## 보물 더미: 바랜 금화 둔덕 · 잔 · 보석 박힌 관 · 흩어진 동전 · 반짝임.
static func _treasure(p: Paint, foot: Vector2, u: float) -> void:
	var gold := Color("#9a7a30")
	var c := foot + Vector2(0, -6) * u
	Kit.shadow(p, c + Vector2(2, 2) * u, 34 * u, 11 * u, 0.45)
	L.halo(p, c + Vector2(0, -14) * u, 44 * u, Color("#ffd070"), 0.12)
	var mound := PackedVector2Array()
	for j in 25:
		var a := PI * j / 24.0
		mound.append(c + Vector2(-cos(a) * 30, -sin(a) * 24 - pow(sin(a), 6.0) * 4.0) * u)
	for j in range(1, 24):
		var a := PI * j / 24.0
		mound.append(c + Vector2(cos(a) * 30, sin(a) * 8) * u)
	p.fill_poly(mound, func(x: int, y: int) -> Color:
		var n := Vector2(x - c.x, y - c.y + 8 * u) / Vector2(30 * u, 24 * u)
		var t := clampf(0.55 - n.x * 0.45 - n.y * 0.35, 0.0, 1.0)
		return p.vary(gold.darkened(0.55).lerp(gold.lightened(0.25), t), x, y, 0.12))
	var coins: Array[Vector2] = []
	for k in 70:
		var q := c + Vector2(p.rng.randf_range(-28, 28), p.rng.randf_range(-26, 6)) * u
		if Geometry2D.is_point_in_polygon(q, mound):
			coins.append(q)
	coins.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	for q in coins:
		_coin(p, q, u, gold)
	var gob := c + Vector2(-15, -10) * u  # 잔
	var gp: Array[Vector2] = [Vector2(0, 4.2), Vector2(1.4, 4.0), Vector2(2.4, 1.2), Vector2(8, 1.0), Vector2(9.5, 2.4), Vector2(13, 4.6), Vector2(16, 5.2)]
	for j in gp.size():
		gp[j] *= u
	L.lathe(p, gob, gp, Color("#b08a3a"), true, 0.9)
	p.fill_poly(Cave._ellipse(gob + Vector2(0, -16) * u, 5.2 * u, 1.6 * u, 12), func(_x: int, _y: int) -> Color: return Color("#2a1a08"))
	Cave._dot(p, gob + Vector2(0, -11) * u, 1.3 * u, Color("#8a2028"), 0.95)
	var cr := c + Vector2(8, -22) * u  # 관
	var band := PackedVector2Array([cr + Vector2(-9, 0) * u, cr + Vector2(9, 0) * u, cr + Vector2(9, -5) * u, cr + Vector2(-9, -5) * u])
	L.part(p, band, Color("#b89040"), 0.9, true, 0.9)
	for j in 5:
		var x := -8.0 + j * 4.0
		var spike := PackedVector2Array([cr + Vector2(x - 1.8, -5) * u, cr + Vector2(x, -11 + absf(j - 2) * 1.2) * u, cr + Vector2(x + 1.8, -5) * u])
		L.part(p, spike, Color("#b89040"), 0.5, true, 0.7)
		Cave._dot(p, cr + Vector2(x, -11.5 + absf(j - 2) * 1.2) * u, 1.2 * u, Color("#e8d8a0"), 0.9)
	for j in 3:
		var gc: Color = [Color("#7a1c24"), Color("#2a4a6a"), Color("#7a1c24")][j]
		Cave._dot(p, cr + Vector2(-5 + j * 5, -2.5) * u, 1.6 * u, gc, 1.0)
		Cave._dot(p, cr + Vector2(-5.5 + j * 5, -3.0) * u, 0.6 * u, Color("#ffffff"), 0.8)
	for k in 9:  # 흩어진 동전
		var q := c + Vector2(p.rng.randf_range(-34, 34), p.rng.randf_range(6, 14)) * u
		_coin(p, q, u, gold)
	for k in 6:
		var q: Vector2 = coins[p.rng.randi_range(0, coins.size() - 1)] if not coins.is_empty() else c
		L.glint(p, q + Vector2(-0.8, -0.6) * u, p.rng.randf_range(1.8, 3.2) * u, 0.75)


static func _coin(p: Paint, q: Vector2, u: float, gold: Color) -> void:
	var e := Cave._ellipse(q, 2.8 * u, 1.5 * u, 10)
	p.fill_poly(Cave._ellipse(q + Vector2(0.5, 0.9) * u, 2.8 * u, 1.5 * u, 10), func(_x: int, _y: int) -> Color: return Color(0.1, 0.06, 0.02, 0.6))
	var tone := gold.lightened(p.rng.randf_range(-0.1, 0.3))
	p.fill_poly(e, func(x: int, y: int) -> Color: return tone.lerp(Color("#f0dc98"), clampf(0.4 - (x - q.x) / (2.8 * u) * 0.4 - (y - q.y) / (1.5 * u) * 0.4, 0.0, 1.0)))
	Ink.path(p, e, 0.6 * u, true, Color("#3a2408"), 0.6, 0.1)
