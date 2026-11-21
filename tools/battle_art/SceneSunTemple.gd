extends RefCounted
## 전투 뒷그림 — 꺼진 태양의 신전(rift_sun_temple): 사암 마름돌 회랑, 벽 가운데 높이에 해 · 물결 · 눈 문양을 새긴 띠,
## 천장 틈으로 떨어지는 금빛 빛줄기와 그 아래 쌓인 모래, 줄지어 선 사암 기둥과 타는 화로, 끝 벽에 큰 해 원반 돋을새김.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const HW := 3.4
const CH := 5.6
const END_Z := 26.0
const SAND := Color("#a88a62")
const SUN := Color("#ffd890")
const COL := 3.4
const COL0 := 3.0


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "box"
	room.z_end = END_Z
	room.fog_k = 0.06
	room.fog_c = Color("#1a140c")
	room.ambient = Color(0.12, 0.1, 0.07)
	room.shape(func(_z: float) -> float: return HW, func(_z: float) -> float: return HW, func(_z: float) -> float: return CH)
	room.lights = [{"p": Vector3(0.0, CH - 0.2, 9.0), "c": SUN, "s": 4.5, "r": 4.5}, {"p": Vector3(0.0, 2.6, END_Z - 0.6), "c": Color("#ffb060"), "s": 1.6, "r": 3.5}]
	for i in 3:
		room.lights.append({"p": Vector3(-2.6 if i % 2 == 0 else 2.6, 1.3, COL0 + COL * i + 1.2), "c": Color("#ff9a40"), "s": 1.4, "r": 2.4})
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:  # 사암 판석 + 빛줄기 아래 쌓인 모래
				var d := m.courses(P.x + 20.0, P.z, 1.1, 0.75, SAND.darkened(0.15), Color("#4a3a26"))
				var drift := smoothstep(2.6, 0.4, Vector2(P.x, (P.z - 9.0) * 0.5).length()) + smoothstep(0.62, 0.85, m.nz("lo", P.x * 0.7, P.z * 0.5)) * 0.6
				d["c"] = (d["c"] as Color).lerp(Color("#c8a874"), clampf(drift, 0.0, 1.0) * 0.85)
				d["ink"] = float(d.get("ink", 0.0)) * (1.0 - clampf(drift, 0.0, 1.0))
				return d
			Room.CEIL:
				var c := m.courses(P.z, P.x, 1.2, 0.6, SAND.darkened(0.55), Color("#2a2014"))
				if Vector2(P.x, (P.z - 9.0) * 0.6).length() < 0.6:
					c["c"] = SUN
					c["flat"] = true
				return c
			Room.END:  # 끝 벽 해 원반 돋을새김
				var d := m.courses(P.x + 3.0, P.y, 1.2, 0.6, SAND.darkened(0.1), Color("#4a3a26"))
				var r := Vector2(P.x, P.y - 3.0).length()
				if r < 1.5:
					d["c"] = (d["c"] as Color).lightened(0.1)
					d["h"] = 0.03
					if absf(r - 1.5) < 0.05 or absf(r - 0.9) < 0.04 or (r > 0.9 and fposmod(atan2(P.y - 3.0, P.x) * 6.0 / PI, 1.0) < 0.08):
						d["ink"] = 0.7
				return d
			_:
				if P.y > 2.0 and P.y < 2.8:  # 문양 띠
					var d := m.courses(P.z, P.y, 0.8, 0.8, SAND.lightened(0.05), Color("#5a4630"))
					var u := fposmod(P.z, 0.8) / 0.8
					var v := (P.y - 2.0) / 0.8
					var kind_i := int(Paint.hash01(floori(P.z / 0.8), 3, 17) * 3.0)
					var dd := 1.0
					match kind_i:
						0:
							dd = absf(Vector2(u - 0.5, v - 0.5).length() - 0.22) * 14.0 - 0.4
						1:
							dd = absf(v - 0.5 - sin(u * TAU * 2.0) * 0.12) * 14.0 - 0.4
						_:
							dd = absf(Vector2((u - 0.5) * 1.3, (v - 0.5) * 2.2).length() - 0.35) * 10.0 - 0.4
					if dd < 0.0:
						d["ink"] = 0.6
						d["h"] = -0.01
					return d
				var d := m.courses(P.z, P.y, 1.0, 0.5, SAND, Color("#5a4630"))
				d["c"] = (d["c"] as Color).darkened(0.25 * smoothstep(0.6, 0.0, P.y))
				return d
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.22, Color("#1a140c"))
	Kit.hatch_dark(p, 7000, 60.0, 0.03, 0.14, 0.3)
	Kit.brush(p, 0.9)
	Kit.finish(p, Color("#16100a"), Color("#f4ead4"), 0.22, 0.58)
	Kit.glow(p, room, Vector3(0.0, 2.6, 9.0), 1.8, SUN, 0.35)  # 빛줄기(색 보정 뒤)
	for i in 3:
		Kit.glow(p, room, Vector3(-2.6 if i % 2 == 0 else 2.6, 1.3, COL0 + COL * i + 1.2), 0.6, Color("#ffb060"), 0.5)
	Kit2.sparkle(p, Rect2(w * 0.38, h * 0.1, w * 0.24, h * 0.55), 160, Color("#ffe8b0"), 1.6)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var stone := func(P: Vector3) -> Color: return m.courses(P.y * 2.0 + P.x, P.z * 2.0, 0.5, 0.5, SAND.darkened(0.05), Color("#5a4630"))["c"]
	var zs: Array[float] = []
	var z := COL0
	while z < END_Z - 1.0:
		zs.append(z)
		z += COL
	zs.reverse()
	for zz in zs:  # 사암 기둥(먼 것부터)
		for s: float in [-1.0, 1.0]:
			Kit.pillar(p, room, s * (HW - 0.55), zz, 0.32, 0.0, CH, stone, 0.1)
	for i in 3:  # 화로: 받침 + 불
		var bp := Vector3(-2.6 if i % 2 == 0 else 2.6, 0.0, COL0 + COL * i + 1.2)
		Kit.box(p, room, bp, Vector3(0.4, 1.0, 0.4), func(P: Vector3) -> Color: return m.vary(Color("#4a3a2a"), P.y * 6.0, P.z * 6.0, 0.2), 0.3, 1.0)
		Kit.flame(p, room, bp + Vector3(0, 1.1, 0), 0.16)
