extends RefCounted
## 전투 뒷그림 — 녹색 탄광(green_mine): 갱목 틀이 줄지어 선 좁은 갱도가 어둠으로 빨려 들고, 바닥엔 철로가 소실점까지 뻗는다.
## 바위 벽의 초록 광맥과 광석 결정, 들보에 매달린 등불(하나는 꺼졌다), 철로 옆에 넘어진 광차.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")

const HW := 2.6
const CH := 3.4
const FRAME := 2.6   ## 갱목 틀 간격
const FRAME0 := 2.4
const ROCK := Color("#4c463e")
const WOOD := Color("#5a4630")
const VEIN := Color("#5ad65a")
const GAUGE := 0.55  ## 철로 반 폭
const LAMPS: Array[int] = [1, 3, 6]  ## 등불을 단 틀 번호(6 = 꺼진 등불)


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "box"
	room.z_end = 34.0
	room.fog_k = 0.09
	room.fog_c = Color("#0a0d09")
	room.ambient = Color(0.08, 0.1, 0.07)
	room.shape(func(z: float) -> float: return HW + (m.nz("mid", z * 0.2, 2.0) - 0.5) * 0.5,
		func(z: float) -> float: return HW + (m.nz("mid", z * 0.2, 9.0) - 0.5) * 0.5,
		func(_z: float) -> float: return CH)
	room.lights = [{"p": Vector3(0.0, 1.6, 30.0), "c": Color("#7aff7a"), "s": 0.8, "r": 4.0}]
	for i in LAMPS:
		if i < 6:
			room.lights.append({"p": Vector3(0.0, CH - 0.85, FRAME0 + FRAME * i - 0.1), "c": Color("#ffb060"), "s": 2.6, "r": 2.6})
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.rock(P.x * 2.0, P.z * 2.0, Color("#3e382e"), 0.15)
				var grav := smoothstep(0.55, 0.8, m.nz("hi", P.x * 0.8, P.z * 0.8))
				d["c"] = (d["c"] as Color).lerp(Color("#5a5446"), grav * 0.5).darkened(0.2 * (1.0 - smoothstep(0.0, 0.5, absf(absf(P.x) - GAUGE))))
				d["h"] = float(d["h"]) * 0.4
				return d
			Room.CEIL:  # 천장 널빤지(틀 사이를 덮는다)
				var pl := m.planks(P.z, P.x, 0.22, WOOD.darkened(0.35))
				return pl
			Room.END:
				return {"c": Color("#141a12")}
			_:
				var r := m.rock(P.z * 1.2, P.y * 1.4, ROCK, 0.55)
				var crack := m.nz("cell", P.z * 0.8 + 3.0, P.y * 1.3 + 1.0)
				var zone := smoothstep(0.5, 0.68, m.nz("lo", P.z * 0.6, P.y * 0.6 + 7.0))
				var vein := (1.0 - smoothstep(0.0, 0.05, crack)) * zone
				var halo := (1.0 - smoothstep(0.0, 0.2, crack)) * zone
				r["c"] = (r["c"] as Color).lerp(Color("#2e4a2a"), halo * 0.6)
				r["emit"] = Color(0.12, 0.42, 0.12) * vein + Color(0.02, 0.07, 0.02) * halo
				r["ink"] = float(r["ink"]) * (1.0 - vein)
				r["c"] = (r["c"] as Color).darkened(0.35 * smoothstep(0.6, 0.0, P.y))
				return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.35, Color("#0a0c08"))
	Kit.hatch_dark(p, 9000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0e130d"), Color("#e0e4c8"), 0.22, 0.6)
	for i in LAMPS:  # 등불 빛(색 보정 뒤)
		if i < 6:
			Kit.glow(p, room, Vector3(0.0, CH - 0.85, FRAME0 + FRAME * i - 0.1), 0.9, Color("#ffc070"), 0.55)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var wood := func(P: Vector3) -> Color: return m.planks(P.x + P.z, P.y * 0.3 + P.x, 0.3, WOOD)["c"]
	var iron := func(P: Vector3) -> Color: return m.vary(Color("#5a5a58"), P.z * 2.0, P.x * 9.0, 0.2)
	var rot := func(P: Vector3) -> Color: return m.vary(Color("#3a2a1e"), P.z * 2.0, P.x * 9.0, 0.25)
	# 철로: 침목(먼 것부터) → 레일
	var z := 32.0
	while z > 1.6:
		Kit.box(p, room, Vector3(0.0, 0.0, z), Vector3(GAUGE * 2.0 + 0.5, 0.07, 0.16), rot, 0.0, 0.6 if z < 12.0 else 0.0)
		z -= 0.62
	for s: float in [-1.0, 1.0]:
		Kit.face(p, room, [Vector3(s * GAUGE - 0.035, 0.12, 1.6), Vector3(s * GAUGE + 0.035, 0.12, 1.6), Vector3(s * GAUGE + 0.035, 0.12, 32.0), Vector3(s * GAUGE - 0.035, 0.12, 32.0)], Vector3.UP, iron, 0.8, 0.0)
		Kit.face(p, room, [Vector3(s * GAUGE - s * 0.035, 0.0, 1.6), Vector3(s * GAUGE - s * 0.035, 0.0, 32.0), Vector3(s * GAUGE - s * 0.035, 0.12, 32.0), Vector3(s * GAUGE - s * 0.035, 0.12, 1.6)], Vector3(-s, 0, 0), iron, 0.4, 0.0)
		var rail := Kit.proj(room, [Vector3(s * GAUGE, 0.12, 1.6), Vector3(s * GAUGE, 0.12, 32.0)])
		Ink.line(p, rail[0], rail[1], 1.2, Ink.INK, 0.5, 0.2)
	_cart(p, room, m, Vector3(1.55, 0.0, 17.0))
	# 갱목 틀(먼 것부터): 기둥 둘 + 위 들보 + 버팀목
	var frames: Array[float] = []
	var fz := FRAME0
	while fz < 32.0:
		frames.append(fz)
		fz += FRAME
	frames.reverse()
	for i in frames.size():
		var zz := frames[i]
		var idx := frames.size() - 1 - i
		for s: float in [-1.0, 1.0]:
			var x := s * (room.wall_x(zz, 1.0, int(s)) - 0.2)
			Kit.box(p, room, Vector3(x, 0.0, zz), Vector3(0.26, CH - 0.28, 0.26), wood, 0.0, 1.0)
		var xl := -(room.wall_x(zz, 1.0, -1) - 0.05)
		var xr := room.wall_x(zz, 1.0, 1) - 0.05
		Kit.box(p, room, Vector3((xl + xr) / 2.0, CH - 0.3, zz), Vector3(xr - xl, 0.3, 0.3), wood, 0.0, 1.0)
		if LAMPS.has(idx):
			_lamp(p, room, Vector3(0.0, CH - 0.3, zz - 0.1), idx < 6)
	for k in 7:  # 광석 결정(벽 밑)
		var cz := 4.0 + k * 3.7
		var s := -1.0 if k % 2 == 0 else 1.0
		var cy := 0.2 + float(k % 3) * 0.5
		Kit.cluster(p, room, Vector3(s * room.wall_x(cz, cy, int(s)), cy, cz), Vector3(-s, 0.4, -0.2), 0.45, Color("#4a8a44"), Color("#3aa03a"), 4)


## 매달린 등불(들보 밑 가운데) — 꺼진 등불은 유리만.
static func _lamp(p: Paint, room: Room, at: Vector3, lit: bool) -> void:
	var a := room.pt(at.x, at.y, at.z)
	var b := room.pt(at.x, at.y - 0.4, at.z)
	Ink.line(p, a, b, clampf(room.px(0.015, at.z), 0.7, 2.0), Ink.INK, 0.9, 0.2)
	var s := room.px(0.14, at.z)
	var body := Paint.poly([b + Vector2(-s * 0.6, 0), b + Vector2(s * 0.6, 0), b + Vector2(s * 0.7, s * 1.6), b + Vector2(-s * 0.7, s * 1.6)])
	p.fill_poly(body, p.flat(Color("#ffb860") if lit else Color("#2a2e26"), 0.15))
	Ink.path(p, body, clampf(s * 0.18, 0.8, 2.5), true, Color("#1a1612"), 0.95, 0.2)
	Ink.line(p, b + Vector2(-s * 0.8, 0), b + Vector2(s * 0.8, 0), clampf(s * 0.3, 1.0, 4.0), Color("#1a1612"), 1.0, 0.1)


## 넘어진 광차(철로 옆): 비스듬한 쇠 상자 + 바퀴 하나가 하늘을 본다.
static func _cart(p: Paint, room: Room, m: Mats, at: Vector3) -> void:
	Kit.floor_shadow(p, room, at.x, at.z, 0.9, 0.5)
	var iron := func(P: Vector3) -> Color: return m.plates(P.z * 3.0, P.y * 3.0, 0.5, 0.4, Color("#4a4640"))["c"]
	Kit.box(p, room, at, Vector3(0.9, 0.75, 1.3), iron, 0.4, 1.0)
	var c := room.pt(at.x - 0.45, 0.75, at.z - 0.3)
	var r := room.px(0.2, at.z)
	var wheel := PackedVector2Array()
	for i in 16:
		wheel.append(c + Vector2(cos(TAU * i / 16.0) * r * 0.5, sin(TAU * i / 16.0) * r))
	p.fill_poly(wheel, p.flat(Color("#24221e"), 0.1))
	Ink.path(p, wheel, 1.4, true, Ink.INK, 0.8, 0.3)
	for k in 6:  # 쏟아진 광석
		var q := room.pt(at.x - 0.7 - k * 0.12, 0.05, at.z - 0.5 + (k % 3) * 0.3)
		var rr := room.px(0.07, at.z)
		p.fill_rect(q.x - rr, q.y - rr * 0.7, rr * 2.0, rr * 1.4, p.flat(Color("#3a6a38") if k % 2 == 0 else Color("#3a3630"), 0.2))
