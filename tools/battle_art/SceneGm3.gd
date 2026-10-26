extends RefCounted
## 전투 뒷그림 — 녹색 탄광 3장 절벽의 원형 계단: 왼쪽 깎아지른 절벽을 따라 좁은 바위 턱이 나 있고, 오른쪽은 끝없는 낭떠러지.
## 건너편 절벽에는 아래로 빙빙 내려가는 계단 턱들과 매달린 등불, 까마득한 아래에는 무너져 막힌 갱도 입구의 초록 빛.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const ROCK := Color("#4a423a")
const LEDGE := 1.4     ## 바위 턱 오른쪽 끝 x(그 너머 낭떠러지)
const FAR_X := 9.0     ## 건너편 절벽
const LAMPS: Array[Vector3] = [Vector3(-3.0, 2.4, 9.0), Vector3(-3.2, 2.4, 19.0), Vector3(8.7, -1.5, 18.0), Vector3(8.7, -6.5, 12.0), Vector3(8.7, -11.5, 20.0)]


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.z_end = 34.0
	room.fog_k = 0.045
	room.fog_c = Color("#090c08")
	room.ambient = Color(0.16, 0.18, 0.14)
	room.shape(func(z: float) -> float: return 3.3 + (m.nz("lo", z * 0.4, 2.0) - 0.5) * 1.0,
		func(_z: float) -> float: return FAR_X, func(_z: float) -> float: return 30.0, func(_z: float) -> float: return -40.0)
	room.lights = [{"p": Vector3(4.0, -25.0, 22.0), "c": Color("#5aff5a"), "s": 2.0, "r": 18.0}, {"p": Vector3(6.0, 3.0, 14.0), "c": Color("#b0a888"), "s": 1.6, "r": 10.0}]
	for l in LAMPS:
		room.lights.append({"p": l, "c": Color("#ffb060"), "s": 2.0, "r": 3.0})
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:  # 까마득한 아래
				return Kit2.chasm(m, P, Color("#040604"), Color("#1a3418"))
			Room.WALL_R, Room.END:
				return _far(m, P)
			Room.CEIL:
				return {"c": Color("#040504"), "flat": true}
			_:
				var r := m.rock(P.z * 1.0, P.y * 1.1, ROCK, 0.55)
				var crack := m.nz("cell", P.z * 0.8 + 3.0, P.y * 1.3 + 1.0)
				r["emit"] = Color(0.12, 0.42, 0.12) * (1.0 - smoothstep(0.0, 0.05, crack)) * smoothstep(0.55, 0.7, m.nz("lo", P.z * 0.6, P.y * 0.6))
				return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.3, Color("#0a0c08"))
	Kit.hatch_dark(p, 9000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0e130d"), Color("#e0e4c8"), 0.22, 0.6)
	for l in LAMPS:
		Kit.glow(p, room, l, 0.8, Color("#ffc070"), 0.5)
	var abyss := room.pt(5.0, -20.0, 22.0)
	Ink.glow(p, abyss.x, abyss.y, 300.0, Color("#3aa03a"), 0.14, false)
	return p


## 건너편 절벽: 바위 + 아래로 빙빙 내려가는 계단 턱(밝은 띠) + 깊을수록 어둡게.
static func _far(m: Mats, P: Vector3) -> Dictionary:
	var r := m.rock(P.z * 0.6 + P.x * 0.3, P.y * 0.7, ROCK, 0.45)
	var band := fposmod(P.y + P.z * 0.35, 5.0)
	if band < 0.35:  # 턱 윗면
		r["c"] = Color("#5a5246").lerp(Color("#3a342c"), band / 0.35)
		r["ink"] = 0.0
	elif band < 0.5:
		r["ink"] = 0.6
	r["c"] = (r["c"] as Color).darkened(clampf(-P.y / 22.0, 0.0, 0.85))
	return r


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var wood := func(P: Vector3) -> Color: return m.planks(P.x + P.z, P.y, 0.25, Color("#4e3a28"))["c"]
	# 바위 턱(낭떠러지 위에 뜬 면 — 오른쪽 끝은 들쭉날쭉)
	var ledge: Array = [Vector3(-4.5, 0.0, 1.0)]
	for k in 15:
		var z := 1.0 + k * 2.1
		ledge.append(Vector3(LEDGE + (m.nz("mid", z * 0.5, 3.0) - 0.5) * 0.8, 0.0, z))
	ledge.append(Vector3(-4.5, 0.0, 31.0))
	Kit.face(p, room, ledge, Vector3.UP, func(P: Vector3) -> Color:
		var d := m.rock(P.x * 1.5, P.z * 1.5, Color("#4a4238"), 0.3)
		return (d["c"] as Color).darkened(float(d["ink"]) * 0.6), 0.0, 0.0)
	for k in 14:  # 턱 끝 잉크 + 깎은 계단 자국
		var a: Vector3 = ledge[k + 1]
		var b: Vector3 = ledge[k + 2] if k + 2 < ledge.size() - 1 else a
		var q := Kit.proj(room, [a, b])
		Ink.line(p, q[0], q[1], clampf(room.px(0.04, a.z), 0.8, 3.0), Ink.INK, 0.8, 0.6)
	var sz := 2.0
	while sz < 28.0:
		var q := Kit.proj(room, [Vector3(-3.4, 0.0, sz), Vector3(LEDGE - 0.3, 0.0, sz)])
		Ink.line(p, q[0], q[1], clampf(room.px(0.02, sz), 0.6, 2.0), Ink.INK, clampf(0.6 - sz * 0.015, 0.15, 0.5), 0.6)
		sz += 1.1
	# 낭떠러지 쪽 말뚝 + 밧줄 울타리
	var posts: Array[float] = [3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0, 24.0]
	var tops: Array[Vector2] = []
	for zz in posts:
		var x := LEDGE + (m.nz("mid", zz * 0.5, 3.0) - 0.5) * 0.8 - 0.15
		Kit.box(p, room, Vector3(x, 0.0, zz), Vector3(0.14, 1.0, 0.14), wood, 0.0, 0.8)
		tops.append(room.pt(x, 0.95, zz))
	for i in tops.size() - 1:
		var rope := PackedVector2Array()
		for k in 9:
			var t := float(k) / 8.0
			rope.append(tops[i].lerp(tops[i + 1], t) + Vector2(0, sin(t * PI) * room.px(0.18, posts[i])))
		Ink.path(p, rope, clampf(room.px(0.025, posts[i]), 0.8, 2.5), false, Color("#3a2e20"), 0.95, 0.2)
	for l in LAMPS:  # 벽에 박은 등불 걸이
		var s := -1.0 if l.x < 0.0 else 1.0
		var arm := Kit.proj(room, [l + Vector3(-s * 0.5, 0.4, 0.0), l + Vector3(0, 0.4, 0)])
		Ink.line(p, arm[0], arm[1], room.px(0.05, l.z), Color("#1e1a16"), 1.0, 0.2)
		var c := room.pt(l.x, l.y, l.z)
		var r := room.px(0.12, l.z)
		p.fill_poly(Paint.poly([c + Vector2(-r * 0.6, -r), c + Vector2(r * 0.6, -r), c + Vector2(r * 0.7, r), c + Vector2(-r * 0.7, r)]), p.flat(Color("#ffb860"), 0.15))
	# 아래 막힌 갱도 입구(희미한 갱목 틀)
	var base := Vector3(4.0, -24.0, 26.0)
	for s: float in [-1.0, 1.0]:
		var a := room.pt(base.x + s * 2.0, base.y, base.z)
		var b := room.pt(base.x + s * 2.0, base.y + 3.5, base.z)
		Ink.line(p, a, b, room.px(0.3, base.z), Color("#1e2a1a"), 0.9, 0.3)
	var beam := Kit.proj(room, [Vector3(base.x - 2.3, base.y + 3.5, base.z), Vector3(base.x + 2.3, base.y + 3.5, base.z)])
	Ink.line(p, beam[0], beam[1], room.px(0.3, base.z), Color("#1e2a1a"), 0.9, 0.3)
	for k in 8:  # 무너진 돌
		var q := room.pt(base.x + p.rng.randf_range(-2.0, 2.0), base.y + p.rng.randf_range(0.0, 2.5), base.z)
		var r := room.px(p.rng.randf_range(0.3, 0.7), base.z)
		p.fill_rect(q.x - r, q.y - r * 0.7, r * 2.0, r * 1.4, p.flat(Color("#1a2016"), 0.2))
