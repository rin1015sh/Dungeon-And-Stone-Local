extends RefCounted
## 전투 뒷그림 — 녹색 탄광 4장 무너진 공동: 폭약으로 뚫은 갱도 끝의 거대한 공동(반경 50m). 천장에서 무너진 바위 더미,
## 바닥 곳곳에 초록으로 빛나는 끈적한 슬라임 웅덩이와 끌린 자국, 부러진 갱목, 벽의 광석 결정과 광맥.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const ROCK := Color("#4a443c")
const SLIME := Color("#6ad65a")
const POOLS: Array[Vector3] = [Vector3(-3.5, 0.0, 9.0), Vector3(4.5, 0.0, 13.0), Vector3(-1.0, 0.0, 20.0), Vector3(6.5, 0.0, 22.0)]  ## 웅덩이 가운데(x, -, z)


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "cave"
	room.z_end = 34.0
	room.fog_k = 0.06
	room.fog_c = Color("#090c08")
	room.ambient = Color(0.14, 0.16, 0.12)
	room.shape(func(z: float) -> float: return 4.0 + smoothstep(0.0, 9.0, z) * 9.0,
		func(z: float) -> float: return 4.2 + smoothstep(0.0, 9.0, z) * 9.5,
		func(z: float) -> float: return 6.0 + smoothstep(0.0, 10.0, z) * 9.0)
	room.lights = [
		{"p": Vector3(0.0, 9.0, 14.0), "c": Color("#9aa890"), "s": 1.8, "r": 12.0},
		{"p": Vector3(-1.5, 2.6, 5.0), "c": Color("#ffb060"), "s": 1.6, "r": 3.0},
	]
	for pl in POOLS:
		room.lights.append({"p": Vector3(pl.x, 0.5, pl.z), "c": SLIME, "s": 1.4, "r": 2.6})
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			var d := m.rock(P.x * 1.4, P.z * 1.4, Color("#3e3a32"), 0.25)
			var grav := smoothstep(0.55, 0.8, m.nz("hi", P.x * 0.6, P.z * 0.6))
			d["c"] = (d["c"] as Color).lerp(Color("#5a5446"), grav * 0.4)
			var trail := 1.0 - smoothstep(0.0, 0.35, absf(P.x - sin(P.z * 0.35) * 2.0 - 1.0))
			for pl in POOLS:
				var e := Vector2((P.x - pl.x) / 1.6, (P.z - pl.z) / 2.2).length() + (m.nz("mid", P.x, P.z) - 0.5) * 0.4
				if e < 1.0:
					var gw := smoothstep(0.55, 0.85, m.nz("mid", P.x * 2.0, P.z * 2.0))
					return {"c": Color("#2a5a24").lerp(Color("#9aff7a"), gw * 0.4), "spec": 1.0, "emit": Color(0.08, 0.3, 0.06) * (0.5 + gw), "h": gw * 0.02,
						"ink": smoothstep(0.9, 1.0, e) * 0.4}
			d["c"] = (d["c"] as Color).lerp(Color("#3a5a30"), trail * 0.5)
			d["spec"] = trail * 0.6
			return d
		if kind == Room.END:
			return {"c": Color("#141a12")}
		var r := m.rock(P.z * 0.7 + P.x * 0.2, P.y * 0.8, ROCK, 0.5)
		var crack := m.nz("cell", P.z * 0.6 + 3.0, P.y * 0.9 + 1.0)
		r["emit"] = Color(0.12, 0.42, 0.12) * (1.0 - smoothstep(0.0, 0.045, crack)) * smoothstep(0.5, 0.68, m.nz("lo", P.z * 0.5, P.y * 0.5 + 7.0))
		r["c"] = (r["c"] as Color).darkened(0.2 if N.y < -0.4 else 0.0)
		return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.3, Color("#0a0c08"))
	Kit.hatch_dark(p, 9000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0e130d"), Color("#e0e4c8"), 0.22, 0.6)
	for pl in POOLS:
		Kit.glow(p, room, Vector3(pl.x, 0.1, pl.z), 1.8, Color("#7aff6a"), 0.18)
	Kit.glow(p, room, Vector3(-1.5, 2.6, 5.0), 0.8, Color("#ffc070"), 0.45)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 17
	var rock := Color("#5a5248")
	var wood := func(P: Vector3) -> Color: return m.planks(P.x + P.z, P.y, 0.3, Color("#4e3a28"))["c"]
	# 무너진 바위 더미(먼 것부터)
	var piles: Array[Vector3] = [Vector3(-7.0, 0.0, 24.0), Vector3(8.0, 0.0, 18.0), Vector3(-6.0, 0.0, 12.0), Vector3(2.0, 0.0, 27.0)]
	piles.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z > b.z)
	for c in piles:
		for k in 9:
			var at := c + Vector3(rng.randf_range(-1.6, 1.6), 0.0, rng.randf_range(-1.0, 1.0))
			var ln := rng.randf_range(0.6, 1.8) * (1.0 - absf(at.x - c.x) / 2.5)
			Kit.shard(p, room, at, at + Vector3(rng.randf_range(-0.4, 0.4), ln, rng.randf_range(-0.2, 0.2)), ln * 0.55, rock, Color.BLACK, 0.1)
	# 부러진 갱목(비스듬히 쓰러진 기둥)
	for b: Array in [[Vector3(-4.5, 0.0, 7.0), Vector3(-2.8, 2.6, 7.6)], [Vector3(5.5, 0.0, 10.0), Vector3(3.8, 1.6, 9.0)]]:
		var q := Kit.proj(room, b)
		var z := ((b[0] as Vector3).z + (b[1] as Vector3).z) / 2.0
		Ink.line(p, q[0], q[1], room.px(0.25, z), room.lit((b[0] as Vector3).lerp(b[1], 0.5), Vector3(0, 0.4, -1).normalized(), Color("#5a4630")), 1.0, 0.3)
		Ink.line(p, q[0], q[1], 1.2, Ink.INK, 0.6, 0.3)
	Kit.box(p, room, Vector3(-1.5, 0.0, 5.3), Vector3(0.25, 2.3, 0.25), wood, 0.0, 1.0)  # 등불 기둥
	for k in 8:  # 광석 결정
		var z := 6.0 + k * 3.0
		var s := -1.0 if k % 2 == 0 else 1.0
		var y := 0.3 + float(k % 3) * 0.6
		Kit.cluster(p, room, Vector3(s * room.wall_x(z, y, int(s)), y, z), Vector3(-s, 0.4, -0.2), 0.6, Color("#4a8a44"), Color("#3aa03a"), 4)
	for k in 14:  # 천장에서 늘어진 슬라임 방울
		var z := rng.randf_range(6.0, 24.0)
		var x := rng.randf_range(-0.6, 0.6) * room.left_at(z)
		var top := room.ceil_at(z) * (1.0 - absf(x) / maxf(1.0, room.left_at(z)) * 0.4)
		var a := room.pt(x, top, z)
		var b := room.pt(x, top - rng.randf_range(0.5, 2.0), z)
		Ink.line(p, a, b, clampf(room.px(0.05, z), 0.8, 3.0), Color("#4a8a3a"), 0.8, 0.4)
		Ink.glow(p, b.x, b.y, room.px(0.12, z), SLIME, 0.4)
