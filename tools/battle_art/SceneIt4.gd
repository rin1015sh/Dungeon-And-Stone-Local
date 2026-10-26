extends RefCounted
## 전투 뒷그림 — 강철의 묘 4장 강철의 분묘: 높은 천장의 넓은 강철 전당. 두 줄로 선 거대한 리벳 기둥, 천장 틈으로 떨어지는 차가운 빛,
## 바닥 한가운데 새겨진 큰 고리, 끝의 단 위에 뚜껑이 밀려난 거대한 강철 관(거인이 몸을 일으킨 자리)과 늘어진 사슬.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const HW := 10.0
const CH := 13.0
const END_Z := 30.0
const STEEL := Color("#5e626c")
const DAIS := Vector3(0.0, 0.0, 23.0)
const COLS: Array[float] = [6.0, 10.0, 14.0, 18.0, 22.0, 26.0]
const SHAFTS: Array[float] = [9.0, 17.0]


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "vault"
	room.spring = 0.7
	room.z_end = END_Z
	room.fog_k = 0.055
	room.fog_c = Color("#0a0a0d")
	room.ambient = Color(0.1, 0.1, 0.12)
	room.shape(func(_z: float) -> float: return HW, func(_z: float) -> float: return HW, func(_z: float) -> float: return CH)
	room.lights = [
		{"p": Vector3(0.0, 11.0, SHAFTS[0]), "c": Color("#c8d8f0"), "s": 2.2, "r": 8.0},
		{"p": Vector3(0.0, 11.0, SHAFTS[1]), "c": Color("#c8d8f0"), "s": 2.0, "r": 8.0},
		{"p": DAIS + Vector3(0.0, 3.0, -2.0), "c": Color("#8aa8ff"), "s": 1.6, "r": 4.0},
		{"p": DAIS + Vector3(-1.5, 2.5, -5.0), "c": Color("#b0c0e0"), "s": 2.0, "r": 4.5},
	]
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.plates(P.x + 30.0, P.z, 1.5, 1.5, STEEL.darkened(0.3))
				var r := Vector2(P.x, (P.z - 12.0)).length()
				for ring: float in [3.0, 3.4, 5.5]:
					if absf(r - ring) < 0.05:
						d["ink"] = 0.75
				var spoke := fposmod(Vector2(P.x, P.z - 12.0).angle() / TAU * 12.0, 1.0)
				if r > 3.4 and r < 5.5 and (spoke < 0.015 or spoke > 0.985):
					d["ink"] = 0.6
				return d
			Room.END:
				return m.plates(P.x + 7.0, P.y, 1.6, 1.2, STEEL.darkened(0.25))
			_:
				if N.y < -0.4:
					return m.plates(P.z, P.x * 1.3 + 9.0, 1.8, 1.4, STEEL.darkened(0.45))
				var d := m.plates(P.z, P.y, 1.6, 1.1, STEEL.darkened(0.1))
				return d
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.26, Color("#0a0a0c"))
	Kit.hatch_dark(p, 9000, 64.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 0.9)
	Kit.finish(p, Color("#101014"), Color("#e6e6e2"), 0.3, 0.6)
	_shafts(p, room)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var steel := func(P: Vector3) -> Color: return m.plates(P.y, P.x + P.z, 0.9, 0.7, STEEL)["c"]
	var dark := func(P: Vector3) -> Color: return m.vary(Color("#3a3c42"), P.y * 2.0, P.z * 2.0 + P.x, 0.2)
	# 단 + 거대한 관(뚜껑이 비스듬히 밀려났다)
	Kit.box(p, room, DAIS, Vector3(7.0, 0.6, 5.0), dark, 0.3, 1.0)
	Kit.box(p, room, DAIS + Vector3(0.0, 0.6, 0.0), Vector3(2.8, 1.6, 4.4), steel, 0.5, 1.0)
	var lid := Kit.proj(room, [DAIS + Vector3(-1.2, 2.2, -2.4), DAIS + Vector3(2.0, 2.2, -2.0), DAIS + Vector3(2.4, 2.6, -1.6), DAIS + Vector3(-0.8, 2.6, -2.0)])
	p.fill_poly(lid, p.flat(room.lit(DAIS + Vector3(0, 2.4, -2.0), Vector3(0, 0.6, -0.8).normalized(), STEEL.darkened(0.1), 0.2), 0.12))
	Ink.path(p, lid, 2.0, true, Ink.INK, 0.85, 0.3)
	var slab := Kit.proj(room, [DAIS + Vector3(2.4, 0.6, -1.0), DAIS + Vector3(3.4, 0.6, -1.4), DAIS + Vector3(3.0, 2.6, -1.8), DAIS + Vector3(2.0, 2.4, -1.4)])
	p.fill_poly(slab, p.flat(room.lit(DAIS + Vector3(2.8, 1.6, -1.4), Vector3(-0.3, 0.2, -1).normalized(), STEEL, 0.5), 0.12))
	Ink.path(p, slab, 2.0, true, Ink.INK, 0.85, 0.3)
	var hole := Kit.proj(room, [DAIS + Vector3(-1.2, 2.2, -2.0), DAIS + Vector3(1.2, 2.2, -2.0), DAIS + Vector3(1.2, 2.2, 2.0), DAIS + Vector3(-1.2, 2.2, 2.0)])
	p.fill_poly(hole, p.flat(Color("#06060a"), 0.05))
	for c: Vector3 in [DAIS + Vector3(-2.6, 13.0, 0.0), DAIS + Vector3(2.6, 13.0, 1.0), DAIS + Vector3(0.0, 13.0, -1.5)]:
		Kit.chain(p, room, c, 8.0 + absf(c.x) * 0.6, 0.2)
	# 두 줄 기둥(먼 것부터)
	var cols := COLS.duplicate()
	cols.reverse()
	for z: float in cols:
		for s: float in [-1.0, 1.0]:
			Kit.pillar(p, room, s * 6.5, z, 0.75, 0.0, CH * 0.7, steel, 0.5)
			Kit.box(p, room, Vector3(s * 6.5, 0.0, z), Vector3(2.0, 0.6, 2.0), dark, 0.3, 1.0)
			Kit.box(p, room, Vector3(s * 6.5, CH * 0.7, z), Vector3(2.0, 0.5, 2.0), dark, 0.3, 1.0)


## 천장 틈 빛줄기(색 보정 뒤).
static func _shafts(p: Paint, room: Room) -> void:
	for z in SHAFTS:
		var top := CH
		var poly := Kit.proj(room, [Vector3(-0.8, top, z), Vector3(0.8, top, z), Vector3(1.8, 0.0, z - 0.4), Vector3(-1.8, 0.0, z - 0.4)])
		var r := Paint.bounds(poly)
		p.fill_poly(poly, func(x: int, y: int) -> Color:
			var t := clampf((y - r.position.y) / maxf(1.0, r.size.y), 0.0, 1.0)
			p.add_light(x, y, Color("#d0e0f4"), 0.07 * (1.0 - t * 0.5) * (0.7 + 0.6 * p.nz("vs", x, y)))
			return Color(0, 0, 0, 0))
		Kit2.sparkle(p, r, 60, Color("#e8f0ff"), 1.0)
