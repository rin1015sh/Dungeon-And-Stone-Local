extends RefCounted
## 전투 뒷그림 — 가라앉은 묘역(rift_sunken_graveyard): 아치 천장의 납골 회랑이 검은 물에 반쯤 잠겼다. 이끼 낀 회녹색 석벽에
## 벽감 줄, 물 위로 솟은 묘비 끝, 끝 벽 아래 무릎 꿇은 갑주 그림자와 장례 촛불 셋, 물 위를 떠도는 푸른 넋불.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const HW := 3.2
const CH := 5.2
const END_Z := 24.0
const STONE := Color("#4a524c")
const WATER_Y := 0.0
const CANDLE := Color("#9ab4ff")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 880.0
	room.hy = 245.0
	room.profile = "vault"
	room.spring = 0.6
	room.z_end = END_Z
	room.fog_k = 0.06
	room.fog_c = Color("#0a100e")
	room.ambient = Color(0.13, 0.16, 0.15)
	room.shape(func(_z: float) -> float: return HW, func(_z: float) -> float: return HW, func(_z: float) -> float: return CH)
	room.lights = [{"p": Vector3(0.0, 1.0, END_Z - 1.2), "c": CANDLE, "s": 2.4, "r": 4.0}]
	for i in 3:
		room.lights.append({"p": Vector3(-1.6 + i * 1.6, 0.7, END_Z - 2.0), "c": CANDLE, "s": 1.0, "r": 2.2})
	for i in 5:  # 벽감 등잔(차가운 넋빛)
		room.lights.append({"p": _lamp_at(i), "c": CANDLE, "s": 2.2, "r": 3.0})
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:  # 검은 물(가운데) · 물가 진흙 포석(벽 쪽)
				var wet := smoothstep(HW - 0.9, HW - 1.6, absf(P.x)) * smoothstep(0.35, 0.55, m.nz("lo", P.x * 0.6, P.z * 0.4) + 0.2)
				if wet > 0.5:
					return Kit2.water(m, P, Color("#121a18"), Color("#5a7a78"), 0.0)
				var d := m.flags(P.x + 30.0, P.z, 0.7, STONE.darkened(0.35), Color("#1a201c"))
				d["c"] = (d["c"] as Color).lerp(Color("#24302a"), smoothstep(0.4, 0.8, m.nz("lo", P.x, P.z * 0.6)) * 0.6)
				return d
			Room.CEIL:
				var c := m.courses(P.z, P.x + 10.0, 0.9, 0.45, STONE.darkened(0.5), Color("#121614"))
				return c
			Room.END:  # 끝 벽: 큰 묘실 문 — 돌 두 짝, 가운데 금
				var d := m.courses(P.x + 4.0, P.y, 1.1, 0.5, STONE.darkened(0.2), Color("#141a16"))
				if absf(P.x) < 1.4 and P.y < 3.4:
					d = m.flags(P.x + 50.0, P.y, 1.4, STONE.darkened(0.45), Color("#0e1210"))
					if absf(P.x) < 0.03:
						d["ink"] = 0.8
				return d
			_:  # 벽: 마름돌 + 벽감 줄(어두운 네모) + 아래쪽 이끼
				var d := m.courses(P.z, P.y, 0.95, 0.42, STONE, Color("#1a201c"))
				var niche_u := fposmod(P.z, 2.2)
				if P.y > 1.4 and P.y < 2.3 and niche_u > 0.6 and niche_u < 1.6:
					d["c"] = Color("#0c100e")
					d["h"] = -0.05
				var moss := smoothstep(1.2, 0.0, P.y) * smoothstep(0.35, 0.7, m.nz("mid", P.z * 0.9, P.y * 1.4))
				d["c"] = (d["c"] as Color).lerp(Color("#2e3e26"), moss * 0.7).darkened(0.3 * smoothstep(0.5, 0.0, P.y))
				return d
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.3, Color("#0a0e0c"))
	Kit.hatch_dark(p, 9000, 62.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 0.9)
	Kit.finish(p, Color("#0c1210"), Color("#dfe6e0"), 0.32, 0.62)
	for i in 3:  # 촛불 빛(색 보정 뒤)
		Kit.glow(p, room, Vector3(-1.6 + i * 1.6, 0.75, END_Z - 2.0), 0.5, CANDLE, 0.45)
	for i in 5:
		Kit.glow(p, room, _lamp_at(i), 0.4, CANDLE, 0.4)
	for k in 5:  # 넋불
		Kit2.wisp(p, room, Vector3(-2.0 + k * 1.0, 1.2 + float(k % 2) * 0.6, 7.0 + k * 3.0), 0.18, Color("#8ac8ff"))
	return p


static func _lamp_at(i: int) -> Vector3:
	return Vector3((-1.0 if i % 2 == 0 else 1.0) * (HW - 0.3), 1.85, 2.8 + i * 4.0)


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var stone := func(P: Vector3) -> Color: return m.vary(STONE.darkened(0.15), P.y * 3.0, P.z * 3.0 + P.x, 0.22)
	var dark := func(P: Vector3) -> Color: return m.vary(Color("#2a2e2c"), P.y * 4.0, P.x * 4.0, 0.2)
	for k in 8:  # 물 위로 솟은 묘비 끝(먼 것부터)
		var i := 7 - k
		var s := -1.0 if i % 2 == 0 else 1.0
		var z := 3.5 + i * 2.4
		var x := s * (HW - 0.8 - float(i % 3) * 0.3)
		Kit.box(p, room, Vector3(x, 0.0, z), Vector3(0.55, 0.9 - float(i % 2) * 0.3, 0.16), stone, 0.2, 1.0)
	# 끝 벽 앞 무릎 꿇은 갑주(실루엣) · 장례 촛불 셋
	Kit.box(p, room, Vector3(0.0, 0.0, END_Z - 1.6), Vector3(0.8, 1.2, 0.5), dark, 0.5, 1.0)
	Kit.box(p, room, Vector3(0.0, 1.2, END_Z - 1.6), Vector3(0.36, 0.38, 0.36), dark, 0.5, 1.0)
	for i in 3:
		var cp := Vector3(-1.6 + i * 1.6, 0.0, END_Z - 2.0)
		Kit.box(p, room, cp, Vector3(0.14, 0.62, 0.14), func(_P: Vector3) -> Color: return Color("#d8d0b8"), 0.1, 1.0)
		Kit.flame(p, room, cp + Vector3(0, 0.7, 0), 0.08)
	Kit.floor_shadow(p, room, -1.8, 5.0, 0.6, 0.5)
	Kit.skull(p, room, Vector3(-1.8, 0.0, 5.0), 0.11, Color("#a8a090"))
