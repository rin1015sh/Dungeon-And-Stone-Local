extends RefCounted
## 전투 뒷그림 — 강철의 묘 2장 회전 칼날의 방: 쇠판으로 짠 네모난 방, 바닥의 둥근 홈에서 톱날이 반쯤 솟아 돌고,
## 공중에는 붉게 빛나는 눈알들이 떠서 지켜본다. 벽엔 벽화 띠와 통풍구, 끝에 다음 복도로 가는 쇠문.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")
const Tomb := preload("res://tools/battle_art/SceneTomb.gd")

const HW := 5.0
const CH := 5.5
const END_Z := 18.0
const STEEL := Color("#626670")
const SAWS: Array[Vector3] = [Vector3(-2.8, 0.0, 8.5), Vector3(3.0, 0.0, 11.5), Vector3(-0.6, 0.0, 15.0)]  ## 홈 가운데(x, -, z)
const EYES: Array[Vector3] = [Vector3(-3.0, 3.6, 12.0), Vector3(3.4, 4.0, 15.5), Vector3(0.8, 4.4, 9.5)]
const IRIS := Color("#ff4a3a")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.z_end = END_Z
	room.fog_k = 0.07
	room.fog_c = Color("#0a0a0c")
	room.ambient = Color(0.1, 0.1, 0.12)
	room.shape(func(_z: float) -> float: return HW, func(_z: float) -> float: return HW, func(_z: float) -> float: return CH)
	room.lights = [
		{"p": Vector3(0.0, 5.0, 9.0), "c": Color("#bcd0f0"), "s": 1.8, "r": 6.0},
		{"p": Vector3(-4.5, 3.2, 6.0), "c": Color("#bcd8ff"), "s": 1.4, "r": 3.0},
		{"p": Vector3(4.5, 3.2, 13.0), "c": Color("#bcd8ff"), "s": 1.4, "r": 3.0},
	]
	for e in EYES:
		room.lights.append({"p": e, "c": IRIS, "s": 0.9, "r": 2.0})
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.plates(P.x + 20.0, P.z, 1.2, 1.2, STEEL.darkened(0.3))
				for s in SAWS:  # 톱날 홈(둥근 고리)
					var r := Vector2(P.x - s.x, (P.z - s.z)).length()
					if absf(r - 1.4) < 0.07:
						return {"c": Color("#0a0a0a"), "ink": 0.5}
					if absf(r - 1.4) < 0.14:
						d["c"] = (d["c"] as Color).darkened(0.4)
				d["c"] = (d["c"] as Color).lerp(Color("#3a1210"), m.blood(P.x, P.z, 0.14) * 0.7)
				return d
			Room.CEIL:
				return m.plates(P.x + 10.0, P.z, 1.2, 1.6, STEEL.darkened(0.45))
			Room.END:
				if absf(P.x) < 1.2 and P.y < 3.0:
					var d := m.plates(P.x + 3.0, P.y, 1.2, 1.0, STEEL.darkened(0.15))
					if absf(P.x) < 0.03:
						d["ink"] = 0.8
					return d
				return m.plates(P.x + 7.0, P.y, 1.3, 0.85, STEEL.darkened(0.1))
			_:
				if P.y > 1.7 and P.y < 2.7:
					return Tomb._mural(m, P.z, P.y)
				var d := m.plates(P.z, P.y, 1.3, 0.85, STEEL)
				if P.y > 3.6 and P.y < 4.2 and fposmod(P.z, 2.6) < 1.0:  # 통풍구 창살
					d["c"] = Color("#0c0c0e")
					d["ink"] = 0.4 if fposmod(P.z * 12.0, 1.0) < 0.3 else 0.0
				return d
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.28, Color("#0a0a0c"))
	Kit.hatch_dark(p, 9000, 64.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 0.9)
	Kit.finish(p, Color("#101014"), Color("#e4e4e0"), 0.3, 0.62)
	for e in EYES:
		Kit2.eye_orb(p, room, e, 0.32, IRIS, true)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var steel := func(P: Vector3) -> Color: return m.vary(STEEL.darkened(0.15), P.y * 3.0, P.z * 3.0 + P.x, 0.2)
	for s: float in [-1.0, 1.0]:  # 모서리 기둥
		for zz: float in [END_Z - 0.3, 4.0]:
			Kit.box(p, room, Vector3(s * (HW - 0.2), 0.0, zz), Vector3(0.4, CH, 0.4), steel, 0.5, 1.0)
	var saws := SAWS.duplicate()
	saws.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z > b.z)
	for s: Vector3 in saws:
		Kit2.saw(p, room, Vector3(s.x, 0.55, s.z - 1.4), 1.1, Color("#6a7078"))  # 고리 앞쪽에서 솟은 날
	var eyes := EYES.duplicate()
	eyes.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z > b.z)
	for e: Vector3 in eyes:
		Kit2.eye_orb(p, room, e, 0.32, IRIS)
		var trail := Kit.proj(room, [e + Vector3(0.0, 0.3, 0.0), e + Vector3(0.1, 0.9, 0.2)])  # 시신경 같은 꼬리
		Ink.line(p, trail[0], trail[1], clampf(room.px(0.04, e.z), 0.8, 3.0), Color("#5a2a26"), 0.8, 1.2)
	for k in 7:  # 잘린 화살·쇳조각
		var a := Vector3(p.rng.randf_range(-3.5, 3.5), 0.02, p.rng.randf_range(2.6, 8.0))
		var q := Kit.proj(room, [a, a + Vector3(p.rng.randf_range(-0.3, 0.3), 0.0, p.rng.randf_range(-0.2, 0.2))])
		Ink.line(p, q[0], q[1], clampf(room.px(0.03, a.z), 0.8, 3.0), room.lit(a, Vector3.UP, Color("#7a7c80")), 1.0, 0.2)
	Kit.skull(p, room, Vector3(-3.6, 0.0, 6.0), 0.11, Color("#9a9080"))
