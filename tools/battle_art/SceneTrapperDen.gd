extends RefCounted
## 전투 뒷그림 — 덫꾼의 굴(rift_trapper_den): 흙을 판 낮은 굴에 엉성한 버팀목이 줄지어 서고, 천장에서 숲 뿌리가 늘어진다.
## 버팀목마다 매달린 녹슨 곰덫 · 사슬, 바닥의 덫과 뼈, 굴 끝 고블린 모닥불의 붉은 빛.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")

const HW := 2.6
const CH := 3.2
const END_Z := 28.0
const DIRT := Color("#4a4030")
const WOOD := Color("#5a4630")
const FRAME := 2.8
const FRAME0 := 2.6
const FIRE := Color("#ff8a40")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "box"
	room.z_end = END_Z
	room.fog_k = 0.065
	room.fog_c = Color("#0c0a07")
	room.ambient = Color(0.14, 0.12, 0.09)
	room.shape(func(z: float) -> float: return HW + (m.nz("mid", z * 0.25, 3.0) - 0.5) * 0.6,
		func(z: float) -> float: return HW + (m.nz("mid", z * 0.25, 7.0) - 0.5) * 0.6,
		func(z: float) -> float: return CH + (m.nz("mid", z * 0.3, 1.0) - 0.5) * 0.4)
	room.lights = [{"p": Vector3(0.0, 0.6, END_Z - 2.0), "c": FIRE, "s": 3.0, "r": 5.0}, {"p": Vector3(0.0, 2.2, 5.0), "c": Color("#c89a60"), "s": 1.2, "r": 3.0}]
	for i in 4:  # 버팀목에 꽂은 횃불
		room.lights.append({"p": _torch_at(i), "c": FIRE, "s": 2.4, "r": 2.8})
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.rock(P.x * 2.4, P.z * 2.4, DIRT.darkened(0.15), 0.1)
				d["h"] = float(d["h"]) * 0.3
				d["c"] = (d["c"] as Color).lerp(Color("#2a2418"), smoothstep(0.5, 0.8, m.nz("lo", P.x, P.z * 0.7)) * 0.5)
				return d
			Room.CEIL:  # 흙 천장 + 늘어진 뿌리 결
				var r := m.rock(P.x * 2.0, P.z * 2.0, DIRT.darkened(0.4), 0.2)
				var root := 1.0 - smoothstep(0.0, 0.06, absf(m.nz("mid", P.x * 3.0, P.z * 0.8) - 0.5))
				r["c"] = (r["c"] as Color).lerp(Color("#3a2a1a"), root * 0.8)
				r["ink"] = maxf(float(r.get("ink", 0.0)), root * 0.4)
				return r
			Room.END:
				return {"c": Color("#140c08")}
			_:
				var r := m.rock(P.z * 1.6, P.y * 1.6, DIRT, 0.35)
				var root := 1.0 - smoothstep(0.0, 0.05, absf(m.nz("mid", P.z * 0.9, P.y * 2.0 + 4.0) - 0.5))
				r["c"] = (r["c"] as Color).lerp(Color("#3a2a18"), root * 0.7).darkened(0.3 * smoothstep(0.6, 0.0, P.y))
				return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.34, Color("#0c0a07"))
	Kit.hatch_dark(p, 9000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0e0b08"), Color("#e8dcc4"), 0.25, 0.62)
	Kit.glow(p, room, Vector3(0.0, 0.5, END_Z - 2.0), 1.4, FIRE, 0.55)  # 모닥불 빛(색 보정 뒤)
	for i in 4:
		Kit.flame(p, room, _torch_at(i), 0.1)
	Kit.flame(p, room, Vector3(0.0, 0.25, END_Z - 2.0), 0.3)
	return p


static func _torch_at(i: int) -> Vector3:
	return Vector3((-1.0 if i % 2 == 0 else 1.0) * (HW - 0.45), 1.9, FRAME0 + FRAME * i * 2.0 + 0.2)


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var wood := func(P: Vector3) -> Color: return m.planks(P.x + P.z, P.y * 0.3 + P.x, 0.3, WOOD)["c"]
	var rust := func(P: Vector3) -> Color: return m.vary(Color("#6a3a22"), P.x * 9.0, P.z * 9.0, 0.3)
	var frames: Array[float] = []
	var fz := FRAME0
	while fz < END_Z - 2.5:
		frames.append(fz)
		fz += FRAME
	frames.reverse()
	for i in frames.size():  # 엉성한 버팀목(먼 것부터 — 기둥 하나는 기울었다)
		var zz := frames[i]
		for s: float in [-1.0, 1.0]:
			var x := s * (room.wall_x(zz, 1.0, int(s)) - 0.2)
			Kit.box(p, room, Vector3(x, 0.0, zz), Vector3(0.22, CH - 0.3, 0.22), wood, 0.0, 1.0)
		var xl := -(room.wall_x(zz, 1.0, -1) - 0.05)
		var xr := room.wall_x(zz, 1.0, 1) - 0.05
		Kit.box(p, room, Vector3((xl + xr) / 2.0, CH - 0.32, zz), Vector3(xr - xl, 0.26, 0.26), wood, 0.0, 1.0)
		if i % 2 == 0:  # 매달린 곰덫 + 사슬
			var top := Vector3(xl * 0.4, CH - 0.32, zz - 0.1)
			Kit.chain(p, room, top, 0.8, 0.05)
			var c := room.pt(top.x, top.y - 0.95, top.z)
			var r := room.px(0.18, top.z)
			var jaw := PackedVector2Array()
			for k in 12:
				jaw.append(c + Vector2(cos(TAU * k / 12.0) * r, sin(TAU * k / 12.0) * r * 0.55))
			p.fill_poly(jaw, p.flat(Color("#5a3a26"), 0.2))
			Ink.path(p, jaw, clampf(r * 0.15, 0.8, 2.5), true, Ink.INK, 0.9, 0.2)
			for k in 6:  # 이빨
				var a := c + Vector2(-r + k * r * 0.4, 0)
				Ink.line(p, a, a + Vector2(0, -r * 0.4), clampf(r * 0.08, 0.6, 1.6), Color("#8a8a84"), 1.0, 0.1)
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 11
	for k in 5:  # 바닥 곰덫(벌린 것)
		var z := rng.randf_range(3.5, 16.0)
		var x := rng.randf_range(-1.8, 1.8)
		Kit.box(p, room, Vector3(x, 0.0, z), Vector3(0.45, 0.06, 0.3), rust, 0.3, 0.8)
	Kit.floor_shadow(p, room, -1.5, 6.0, 0.5, 0.4)
	Kit.skull(p, room, Vector3(-1.5, 0.0, 6.0), 0.1, Color("#b0a690"))
