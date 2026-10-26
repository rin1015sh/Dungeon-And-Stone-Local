extends RefCounted
## 전투 뒷그림 — 핏빛성채 3장 외성벽 시가지: 무너져 가는 집들 사이 좁은 돌길이 광장으로 열리고, 가운데에 마른 분수대.
## 깨진 창에서 새는 불빛, 늘어진 빨랫줄, 길에 엎어진 수레, 붉은 하늘에 그을음.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const PLAZA_Z := 15.0     ## 여기서부터 광장(집이 물러난다)
const FOUNTAIN_Z := 21.0
const HOUSE := 3.2        ## 집 한 채 폭(m, z 방향)
const WALLS: Array[Color] = [Color("#5a4a40"), Color("#4e423c"), Color("#5e4a3a"), Color("#4a3a34")]


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.z_end = 34.0
	room.fog_k = 0.06
	room.fog_c = Color("#2a1412")
	room.ambient = Color(0.19, 0.13, 0.12)
	var side := func(z: float) -> float: return 3.6 if z < PLAZA_Z else 3.6 + smoothstep(PLAZA_Z, PLAZA_Z + 1.5, z) * 7.0
	var top := func(z: float) -> float: return 6.5 + Paint.hash01(floori(z / HOUSE), 3, 7) * 3.5
	room.shape(side, side, func(_z: float) -> float: return 80.0, Callable(), top,
		func(z: float) -> float: return 6.0 + Paint.hash01(floori(z / HOUSE), 5, 7) * 4.0)
	room.lights = [
		{"p": Vector3(0.0, 30.0, 18.0), "c": Color("#b06050"), "s": 1.6, "r": 40.0},
		{"p": Vector3(-3.3, 2.8, 7.4), "c": Color("#ff9a50"), "s": 1.6, "r": 2.4},
		{"p": Vector3(3.3, 3.6, 12.2), "c": Color("#ff9a50"), "s": 1.4, "r": 2.4},
	]
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.flags(P.x + 40.0, P.z, 0.45, Color("#4a423c"), Color("#1a1412"), 0.35)
				d["c"] = (d["c"] as Color).lerp(Color("#3a1210"), m.blood(P.x, P.z, 0.12) * 0.6)
				return d
			Room.WALL_L, Room.WALL_R:
				return _facade(m, P)
			Room.END:
				if P.y < 9.0 + Paint.hash01(floori(P.x / 4.0), 1, 3) * 5.0:
					return _facade(m, Vector3(P.z, P.y, P.x))
				return Kit2.sky(m, room, P, Color("#241010"), Color("#9a4630"), Color("#4a1c16"))
			_:
				return Kit2.sky(m, room, P, Color("#241010"), Color("#9a4630"), Color("#4a1c16"))
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.3, Color("#120808"))
	Kit.hatch_dark(p, 9000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#1a0e0d"), Color("#e8c8b0"), 0.22, 0.6)
	_windows(p, room, m)
	return p


## 집 앞면: 회벽·벽돌 드러남 + 나무 기둥틀 + 창(어둡거나 불빛) + 문. P.z = 길 방향, P.y = 높이.
static func _facade(m: Mats, P: Vector3) -> Dictionary:
	var hi := floori(P.z / HOUSE)
	var u := P.z - hi * HOUSE
	var base: Color = WALLS[hi % WALLS.size()]
	var d := m.courses(P.z, P.y, 0.32, 0.14, Color("#5a3428"), Color("#241a16"), 0.3, 0.012)
	var plaster := smoothstep(0.35, 0.5, m.nz("lo", P.z * 1.3, P.y * 0.9))
	d["c"] = (d["c"] as Color).lerp(m.vary(base, P.z, P.y, 0.25), plaster)
	d["ink"] = float(d["ink"]) * (1.0 - plaster)
	for b: float in [0.0, HOUSE - 0.25]:  # 기둥틀
		if u > b and u < b + 0.25:
			d = m.planks(P.y, P.z, 0.25, Color("#3a2a1c"))
	if absf(P.y - 3.0) < 0.12 or absf(P.y - 6.0) < 0.12:
		d = m.planks(P.z, P.y, 2.0, Color("#3a2a1c"))
	for wy: float in [1.4, 4.2]:  # 창(층마다 둘)
		for wu: float in [0.7, 2.0]:
			if (wy < 2.0 and hi % 2 == 0 and wu > 1.5):
				continue
			if absf(u - wu - 0.25) < 0.32 and absf(P.y - wy - 0.55) < 0.6:
				var lit := Paint.hash01(hi, int(wu * 10 + wy), 11) > 0.75
				return {"c": Color("#ffa050") if lit else Color("#120c0a"), "emit": Color(0.5, 0.25, 0.08) if lit else Color.BLACK,
					"ink": 0.6 if absf(u - wu - 0.25) > 0.27 or absf(P.y - wy - 0.55) > 0.55 else 0.0}
	if hi % 2 == 0 and absf(u - 2.1) < 0.45 and P.y < 2.2:  # 문
		return m.planks(P.z, P.y, 0.18, Color("#2e2016"))
	d["c"] = (d["c"] as Color).darkened(0.3 * smoothstep(1.0, 0.0, P.y))
	return d


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var stone := func(P: Vector3) -> Color: return m.vary(Color("#6a5a50"), P.y * 3.0, P.x * 2.0 + P.z, 0.25)
	# 마른 분수대: 둥근 수반 + 가운데 기둥 + 깨진 조각상
	Kit.floor_shadow(p, room, 0.0, FOUNTAIN_Z, 2.6, 0.5)
	Kit.pillar(p, room, 0.0, FOUNTAIN_Z, 2.4, 0.0, 0.8, stone, 0.1)
	var rim := PackedVector2Array()
	for k in 40:
		var a := PI + PI * k / 39.0
		rim.append(room.pt(cos(a) * 2.4, 0.8, FOUNTAIN_Z + sin(a) * 2.4 * 0.5))
	Ink.path(p, rim, 2.0, false, Ink.INK, 0.6, 0.5)
	Kit.pillar(p, room, 0.0, FOUNTAIN_Z, 0.35, 0.8, 3.0, stone, 0.1)
	Kit.box(p, room, Vector3(0.0, 3.0, FOUNTAIN_Z), Vector3(0.9, 0.25, 0.9), stone, 0.0, 1.0)
	var statue := Kit.proj(room, [Vector3(-0.3, 3.25, FOUNTAIN_Z), Vector3(0.3, 3.25, FOUNTAIN_Z), Vector3(0.25, 4.4, FOUNTAIN_Z), Vector3(0.05, 4.6, FOUNTAIN_Z), Vector3(-0.2, 4.2, FOUNTAIN_Z)])
	p.fill_poly(statue, p.flat(room.lit(Vector3(0, 3.8, FOUNTAIN_Z), Vector3(0, 0.3, -1).normalized(), Color("#7a6a60")), 0.15))
	Ink.path(p, statue, 1.6, true, Ink.INK, 0.8, 0.5)
	# 엎어진 수레(왼쪽)
	var wood := func(P: Vector3) -> Color: return m.planks(P.x + P.z, P.y, 0.22, Color("#4e3a28"))["c"]
	Kit.box(p, room, Vector3(-2.4, 0.0, 9.5), Vector3(1.0, 0.8, 1.8), wood, 0.0, 1.0)
	var wc := room.pt(-1.85, 0.6, 9.1)
	var wr := room.px(0.5, 9.1)
	var wheel := PackedVector2Array()
	for k in 20:
		wheel.append(wc + Vector2(cos(TAU * k / 20.0) * wr * 0.35, sin(TAU * k / 20.0) * wr))
	Ink.path(p, wheel, room.px(0.06, 9.1), true, Color("#2a1e14"), 1.0, 0.3)
	for k in 4:
		var a := TAU * k / 8.0
		Ink.line(p, wc - Vector2(cos(a) * wr * 0.35, sin(a) * wr), wc + Vector2(cos(a) * wr * 0.35, sin(a) * wr), room.px(0.03, 9.1), Color("#2a1e14"), 1.0, 0.2)
	# 빨랫줄(집과 집 사이)
	for c: Vector2 in [Vector2(5.0, 5.8), Vector2(10.5, 6.2)]:
		var pts := PackedVector2Array()
		for k in 17:
			var t := float(k) / 16.0
			pts.append(room.pt(-3.6 + 7.2 * t, c.y - sin(t * PI) * 0.7, c.x))
		Ink.path(p, pts, 1.2, false, Color("#1a1210"), 0.9, 0.3)
		for k in [4, 7, 11]:
			var q := pts[k]
			var cw := room.px(0.4, c.x)
			p.fill_poly(Paint.poly([q, q + Vector2(cw, 2), q + Vector2(cw * 0.9, cw * 1.3), q + Vector2(0.1 * cw, cw * 1.2)]), p.flat(Color("#6a5a4a").darkened(0.3 * (k % 3)), 0.2))
	Kit.skull(p, room, Vector3(2.4, 0.0, 6.5), 0.1, Color("#9a8a72"))


## 창 불빛 번짐(색 보정 뒤).
static func _windows(p: Paint, room: Room, m: Mats) -> void:
	for L: Dictionary in room.lights:
		var lp: Vector3 = L["p"]
		if lp.y < 5.0:
			Kit.glow(p, room, lp, 0.9, Color("#ff9040"), 0.35)
