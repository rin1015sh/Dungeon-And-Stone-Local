extends RefCounted
## 전투 뒷그림 — 녹색 탄광 2장 무너진 다리: 철로가 놓인 나무 다리가 깊은 협곡 위로 뻗다가 가운데가 무너져 끊기고,
## 건너편에 남은 다리 끝과 갱도 입구(갱목 틀)가 보인다. 끊긴 자리에 늘어진 판자, 다리 밑으로 내려가는 받침대, 협곡 바닥의 초록 빛.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const BW := 2.0                    ## 다리 반 폭
const GAP := Vector2(9.5, 17.0)    ## 무너진 구간 z
const FAR_Z := 27.0                ## 건너편 절벽
const WOOD := Color("#5a4630")
const ROCK := Color("#463f38")
const GAUGE := 0.55
const LAMP := Vector3(0.0, 2.6, FAR_Z - 0.4)


## 무너진 끝의 들쭉날쭉한 z(x마다).
static func _jag(m: Mats, x: float) -> float:
	return (m.nz("mid", x * 3.0, 5.0) - 0.5) * 1.6


## 다리 바닥 판(앞 토막 · 건너편 토막) — 협곡 위에 뜬 면, 가로 판자 줄 + 건너편 토막의 두께.
static func _deck(p: Paint, room: Room, m: Mats) -> void:
	var plank := func(P: Vector3) -> Color:
		var d := m.planks(P.z, P.x, 0.35, WOOD)
		return (d["c"] as Color).darkened(0.3 * smoothstep(0.55, 0.8, m.nz("lo", P.x * 1.5, P.z * 0.8)))
	var near: Array = [Vector3(-BW, 0.0, 1.0), Vector3(BW, 0.0, 1.0)]
	var far: Array = []
	for k in 9:
		var x := BW - k * BW * 2.0 / 8.0
		near.append(Vector3(x, 0.0, GAP.x + _jag(m, x)))
		far.append(Vector3(-x, 0.0, GAP.y + _jag(m, -x) * 0.6))
	far.append(Vector3(BW, 0.0, FAR_Z))
	far.append(Vector3(-BW, 0.0, FAR_Z))
	Kit.face(p, room, far, Vector3.UP, plank, 0.0, 0.0)
	var lip: Array = []
	for v: Vector3 in far.slice(0, 9):
		lip.append(v)
	for k in range(8, -1, -1):
		lip.append((far[k] as Vector3) + Vector3(0, -0.35, 0))
	Kit.face(p, room, lip, Vector3(0, 0, -1), func(P: Vector3) -> Color: return m.vary(WOOD.darkened(0.35), P.x * 4.0, P.y * 8.0, 0.2), 0.0, 0.6)
	Kit.face(p, room, near, Vector3.UP, plank, 0.0, 0.0)
	var z := 1.2
	while z < FAR_Z:  # 판자 이음매
		if z < GAP.x - 0.8 or z > GAP.y + 0.8:
			var q := Kit.proj(room, [Vector3(-BW, 0.0, z), Vector3(BW, 0.0, z)])
			Ink.line(p, q[0], q[1], clampf(room.px(0.02, z), 0.6, 2.0), Ink.INK, clampf(0.7 - z * 0.02, 0.15, 0.6), 0.5)
		z += 0.35
	for s: float in [-1.0, 1.0]:
		var e := Kit.proj(room, [Vector3(s * BW, 0.0, 1.0), Vector3(s * BW, 0.0, GAP.x + _jag(m, s * BW))])
		Ink.line(p, e[0], e[1], 1.6, Ink.INK, 0.8, 0.4)


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "cave"
	room.z_end = FAR_Z
	room.fog_k = 0.05
	room.fog_c = Color("#0a0d09")
	room.ambient = Color(0.16, 0.19, 0.14)
	room.shape(func(z: float) -> float: return 9.0 + (m.nz("lo", z * 0.3, 2.0) - 0.5) * 3.0,
		func(z: float) -> float: return 9.5 + (m.nz("lo", z * 0.3, 8.0) - 0.5) * 3.0,
		func(z: float) -> float: return 9.0 + (m.nz("lo", z * 0.25, 30.0) - 0.5) * 2.0, func(_z: float) -> float: return -40.0)
	room.lights = [
		{"p": LAMP, "c": Color("#ffb060"), "s": 2.4, "r": 3.0},
		{"p": Vector3(0.0, 2.6, 4.0), "c": Color("#ffb060"), "s": 1.8, "r": 3.0},
		{"p": Vector3(0.0, -12.0, 16.0), "c": Color("#5aff5a"), "s": 1.4, "r": 12.0},
		{"p": Vector3(0.0, 4.0, 22.0), "c": Color("#c0a880"), "s": 1.4, "r": 7.0},
		{"p": Vector3(-6.0, 3.0, 10.0), "c": Color("#7aa070"), "s": 1.0, "r": 6.0},
	]
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:  # 협곡 바닥(까마득히 아래)
				return Kit2.chasm(m, P, Color("#050705"), Color("#1a3418"))
			Room.END:  # 건너편 절벽 + 갱도 입구
				if absf(P.x) < 1.8 and P.y < 3.0:
					return {"c": Color("#060806")}
				return m.rock(P.x * 1.2 + 9.0, P.y * 1.2, ROCK, 0.5)
			_:
				var r := m.rock(P.z * 1.0, P.y * 1.1, ROCK, 0.5)
				var crack := m.nz("cell", P.z * 0.8 + 3.0, P.y * 1.3 + 1.0)
				var vein := (1.0 - smoothstep(0.0, 0.05, crack)) * smoothstep(0.5, 0.68, m.nz("lo", P.z * 0.6, P.y * 0.6 + 7.0))
				r["emit"] = Color(0.12, 0.42, 0.12) * vein
				r["c"] = (r["c"] as Color).darkened(0.85 * smoothstep(0.0, -14.0, P.y))
				return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.3, Color("#0a0c08"))
	Kit.hatch_dark(p, 9000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0e130d"), Color("#e0e4c8"), 0.22, 0.6)
	Kit.glow(p, room, LAMP, 0.9, Color("#ffc070"), 0.5)
	Kit.glow(p, room, Vector3(0.0, 2.6, 4.0), 0.9, Color("#ffc070"), 0.45)
	var abyss := room.pt(0.0, -6.0, 16.0)
	Ink.glow(p, abyss.x, abyss.y, 260.0, Color("#3aa03a"), 0.12, false)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var wood := func(P: Vector3) -> Color: return m.planks(P.x + P.z, P.y * 0.3 + P.x, 0.3, WOOD)["c"]
	var iron := func(P: Vector3) -> Color: return m.vary(Color("#5a5a58"), P.z * 2.0, P.x * 9.0, 0.2)
	# 갱도 입구 갱목 틀(건너편)
	for s: float in [-1.0, 1.0]:
		Kit.box(p, room, Vector3(s * 1.9, 0.0, FAR_Z - 0.3), Vector3(0.3, 3.2, 0.3), wood, 0.0, 1.0)
	Kit.box(p, room, Vector3(0.0, 3.0, FAR_Z - 0.3), Vector3(4.2, 0.3, 0.3), wood, 0.0, 1.0)
	Kit.chain(p, room, LAMP + Vector3(0, 0.4, 0), 0.3, 0.0)
	# 다리 받침대(판자 밑으로 협곡에 박힌 기둥 — 무너진 구간 양 끝)
	for zz: float in [GAP.y + 1.5, GAP.y + 5.0, GAP.x - 2.0, 6.0]:
		for s: float in [-1.0, 1.0]:
			var a := room.pt(s * (BW - 0.2), 0.0, zz)
			var b := room.pt(s * (BW + 0.6), -9.0, zz)
			Ink.line(p, a, b, room.px(0.22, zz), room.lit(Vector3(s * BW, -1.0, zz), Vector3(0, 0.2, -1).normalized(), WOOD.darkened(0.3)), 1.0, 0.4)
			Ink.line(p, a, b, 1.0, Ink.INK, 0.6, 0.4)
	_deck(p, room, m)  # 받침대 위에 판
	# 철로(무너진 데서 끊긴다)
	for seg: Vector2 in [Vector2(1.6, GAP.x - 0.6), Vector2(GAP.y + 0.6, FAR_Z - 0.5)]:
		var z := seg.y
		while z > seg.x:
			Kit.box(p, room, Vector3(0.0, 0.0, z), Vector3(GAUGE * 2.0 + 0.5, 0.07, 0.16), func(P: Vector3) -> Color: return m.vary(Color("#3a2a1e"), P.z * 2.0, P.x * 9.0, 0.25), 0.0, 0.5 if z < 10.0 else 0.0)
			z -= 0.62
		for s: float in [-1.0, 1.0]:
			Kit.face(p, room, [Vector3(s * GAUGE - 0.035, 0.12, seg.x), Vector3(s * GAUGE + 0.035, 0.12, seg.x), Vector3(s * GAUGE + 0.035, 0.12, seg.y), Vector3(s * GAUGE - 0.035, 0.12, seg.y)], Vector3.UP, iron, 0.8, 0.0)
	var bent := Kit.proj(room, [Vector3(GAUGE, 0.12, GAP.x - 0.6), Vector3(GAUGE + 0.3, -0.8, GAP.x + 0.4), Vector3(GAUGE + 0.2, -2.0, GAP.x + 0.6)])
	Ink.path(p, bent, room.px(0.06, GAP.x), false, Color("#4a4a48"), 1.0, 0.3)
	# 끊긴 자리에 늘어진 판자
	for k in 5:
		var x := -BW + 0.3 + k * 0.85
		var top := Vector3(x, 0.0, GAP.x + (m.nz("mid", x * 3.0, 5.0) - 0.5) * 1.6)
		var q := Kit.proj(room, [top, top + Vector3(0.1 * (k % 2), -1.2 - (k % 3) * 0.5, 0.2)])
		Ink.line(p, q[0], q[1], room.px(0.28, top.z), room.lit(top, Vector3(0, 0.2, -1).normalized(), WOOD), 1.0, 0.3)
		Ink.line(p, q[0], q[1], 1.0, Ink.INK, 0.5, 0.3)
	# 난간: 기둥 + 늘어진 밧줄
	for side: float in [-1.0, 1.0]:
		var posts: Array[float] = [2.5, 5.5, 8.5, 11.5, 20.0, 23.0, 26.0]
		var tops: Array[Vector2] = []
		for zz in posts:
			Kit.box(p, room, Vector3(side * (BW - 0.1), 0.0, zz), Vector3(0.14, 1.1, 0.14), wood, 0.0, 0.8)
			tops.append(room.pt(side * (BW - 0.1), 1.05, zz))
		for i in tops.size() - 1:
			if posts[i] < GAP.x and posts[i + 1] > GAP.y:
				continue
			var a := tops[i]
			var b := tops[i + 1]
			var rope := PackedVector2Array()
			for k in 9:
				var t := float(k) / 8.0
				rope.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * room.px(0.2, (posts[i] + posts[i + 1]) / 2.0)))
			Ink.path(p, rope, clampf(room.px(0.025, posts[i]), 0.8, 2.5), false, Color("#3a2e20"), 0.95, 0.2)
