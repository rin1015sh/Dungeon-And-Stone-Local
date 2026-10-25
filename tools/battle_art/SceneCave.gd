extends RefCounted
## 전투 뒷그림 — 1층 수정동굴(f1_crystal_cave): 구불구불 좁아졌다 넓어지는 굴이 어둠으로 빨려 든다.
## 보랏빛 도는 바위 벽, 벽과 바닥에 박혀 희미하게 빛나는 수정 무리, 천장의 종유석·바닥의 석순, 옆에 고인 검은 물웅덩이.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")

const ROCK := Color("#5c5664")
const FLOOR := Color("#4a4550")
const CRYSTAL := Color("#8a74c8")
const GLOW := Color("#b49cff")
const POOL := Vector3(2.4, 0.0, 9.5)  ## 물웅덩이 가운데(x, -, z)
const POOL_R := Vector2(1.5, 2.6)     ## 반지름(x, z)


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "cave"
	room.z_end = 30.0
	room.fog_k = 0.1
	room.fog_c = Color("#0c0a10")
	room.ambient = Color(0.1, 0.09, 0.13)
	room.bump = 1.0
	room.shape(func(z: float) -> float: return 4.2 + (m.nz("lo", z * 0.35, 3.0) - 0.5) * 3.2 - smoothstep(18.0, 26.0, z) * 1.2,
		func(z: float) -> float: return 4.6 + (m.nz("lo", z * 0.35, 17.0) - 0.5) * 3.4 - smoothstep(18.0, 26.0, z) * 1.4,
		func(z: float) -> float: return 5.2 + (m.nz("lo", z * 0.3, 31.0) - 0.5) * 2.0)
	var spots := _crystal_spots(room, p)
	room.lights = [
		{"p": Vector3(0.0, 5.0, 7.0), "c": Color("#9a92b0"), "s": 0.9, "r": 5.0},
		{"p": Vector3(0.0, 3.6, 13.0), "c": Color("#8a80b0"), "s": 0.6, "r": 3.5},
		{"p": Vector3(0.0, 2.0, 24.0), "c": Color("#7a6ac0"), "s": 0.8, "r": 4.0},
	]
	for sp: Dictionary in spots:
		if float(sp["size"]) > 0.7:
			room.lights.append({"p": (sp["at"] as Vector3) + (sp["up"] as Vector3) * 0.6, "c": GLOW, "s": 1.6 * float(sp["size"]), "r": 2.2})
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			return _floor(m, P)
		if kind == Room.END:
			return {"c": Color("#1a1620")}
		var r := m.rock(P.z * 1.1 + P.x * 0.3, P.y * 1.3, ROCK, 0.5)
		var band := smoothstep(0.62, 0.7, m.nz("mid", P.z * 0.4, P.y * 2.5 + 9.0))  # 보랏빛 광맥 줄
		r["c"] = (r["c"] as Color).lerp(Color("#6a5a8a"), band * 0.5)
		r["emit"] = Color(0.05, 0.03, 0.09) * band
		if N.y < -0.4:
			r["c"] = (r["c"] as Color).darkened(0.25)
		r["c"] = (r["c"] as Color).darkened(0.3 * (1.0 - smoothstep(0.0, 0.4, P.y)))  # 벽 밑동 젖음
		r["spec"] = 0.12
		return r
	room.render(p)
	_props(p, room, m, spots)
	Kit.grime(p, 0.3, Color("#0c0a10"))
	Kit.hatch_dark(p, 9000, 58.0, 0.03, 0.13, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#141018"), Color("#d8d0e8"), 0.25, 0.62)
	for sp: Dictionary in spots:  # 수정 빛은 색 보정 뒤에
		var s := float(sp["size"])
		Kit.glow(p, room, (sp["at"] as Vector3) + (sp["up"] as Vector3) * s * 0.5, s * 1.2, GLOW, 0.22 * minf(1.0, s))
	return p


## 바닥: 젖은 바위 + 자갈 + 물웅덩이(거울처럼 검고 수정 빛이 비친다).
static func _floor(m: Mats, P: Vector3) -> Dictionary:
	var d := Vector2((P.x - POOL.x) / POOL_R.x, (P.z - POOL.z) / POOL_R.y)
	var e := d.length() + (m.nz("mid", P.x, P.z) - 0.5) * 0.35
	if e < 1.0:
		var shine := smoothstep(0.5, 0.85, m.nz("mid", P.x * 0.4, P.z * 3.0)) * (0.5 + 0.5 * smoothstep(0.6, 1.0, e))
		var rim := smoothstep(0.8, 0.97, e)
		return {"c": Color("#1a1726").lerp(Color("#5a4c88"), shine * 0.7), "h": 0.002 * m.nz("hi", P.x, P.z * 4.0), "spec": 1.0,
			"emit": Color(0.1, 0.07, 0.2) * (shine + rim * 0.6), "ink": smoothstep(0.96, 1.0, e) * 0.6}
	var r := m.flags(P.x * 0.8 + 30.0, P.z * 0.8, 1.5, FLOOR, FLOOR.darkened(0.45), 0.35)
	r["ink"] = float(r["ink"]) * 0.45 * smoothstep(0.3, 0.6, m.nz("mid", P.x * 0.5, P.z * 0.5))
	var grav := smoothstep(0.6, 0.8, m.nz("hi", P.x * 0.6, P.z * 0.6))
	r["c"] = (r["c"] as Color).lerp(Color("#77708a"), grav * 0.4)
	r["h"] = float(r["h"]) * 0.6 + grav * 0.01
	var wet := 1.0 - smoothstep(1.0, 1.5, e)
	r["c"] = (r["c"] as Color).darkened(0.35 * wet)
	r["spec"] = 0.15 + 0.5 * wet
	return r


## 수정 무리 자리(벽·바닥) — 먼 것부터 칠하게 z 내림차순.
static func _crystal_spots(room: Room, p: Paint) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 77
	for k in 16:
		var z := rng.randf_range(3.5, 24.0)
		var side := -1 if k % 2 == 0 else 1
		var y := rng.randf_range(0.0, 2.6) if k % 3 != 0 else 0.0
		var x := room.wall_x(z, y, side) * float(side)
		var up := Vector3(-side * 0.8, 0.6, -0.1)
		if y == 0.0:  # 바닥 = 벽 밑에서 위로
			x = float(side) * (room.wall_x(z, 0.2, side) - rng.randf_range(0.2, 0.8))
			up = Vector3(-side * 0.25, 1.0, 0.0)
		out.append({"at": Vector3(x, y, z), "up": up, "size": rng.randf_range(0.4, 1.3) * (1.0 if z > 6.0 else 0.8)})
	out.append({"at": Vector3(-1.8, 0.0, 13.0), "up": Vector3(0.1, 1.0, 0.0), "size": 0.9})  # 바닥 가운데 쪽 하나
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["at"] as Vector3).z > (b["at"] as Vector3).z)
	return out


static func _props(p: Paint, room: Room, m: Mats, spots: Array[Dictionary]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 5
	var drips: Array[Vector3] = []
	for k in 26:  # 종유석(천장) · 석순(바닥 가장자리)
		var z := rng.randf_range(4.0, 24.0)
		var x := rng.randf_range(-0.7, 0.7) * room.left_at(z)
		drips.append(Vector3(x, 0.0 if k % 3 == 0 else 1.0, z))
	drips.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z > b.z)
	var rock := (ROCK.darkened(0.1))
	for d in drips:
		var ln := rng.randf_range(0.4, 1.4)
		if d.y > 0.5:
			var top := room.ceil_at(d.z) * (0.98 - absf(d.x) / maxf(1.0, room.left_at(d.z)) * 0.3)
			Kit.shard(p, room, Vector3(d.x, top + 0.2, d.z), Vector3(d.x + rng.randf_range(-0.05, 0.05), top - ln, d.z), ln * 0.18, rock, Color.BLACK, 0.2)
		else:
			var side := -1.0 if d.x < 0.0 else 1.0
			var x := side * (room.wall_x(d.z, 0.3, int(side)) - rng.randf_range(0.3, 0.9))
			Kit.shard(p, room, Vector3(x, -0.05, d.z), Vector3(x, ln * 0.6, d.z), ln * 0.22, rock, Color.BLACK, 0.2)
	for sp in spots:
		Kit.cluster(p, room, sp["at"], sp["up"], float(sp["size"]), CRYSTAL, GLOW * 0.5, 3 + int(float(sp["size"]) * 3.0))
	for k in 22:  # 자갈
		var z := rng.randf_range(2.5, 14.0)
		var x := rng.randf_range(-3.0, 3.0)
		if Vector2((x - POOL.x) / POOL_R.x, (z - POOL.z) / POOL_R.y).length() < 1.1:
			continue
		var c := room.pt(x, 0.0, z)
		var r := room.px(rng.randf_range(0.03, 0.09), z)
		var pebble := PackedVector2Array()
		for i in 8:
			var a := TAU * i / 8.0
			pebble.append(c + Vector2(cos(a) * r, sin(a) * r * 0.55 - r * 0.3))
		var col := room.lit(Vector3(x, 0.05, z), Vector3(-0.3, 0.9, -0.3).normalized(), Color("#5a5466"))
		p.fill_poly(pebble, p.flat(col, 0.15))
		Ink.path(p, pebble, clampf(r * 0.25, 0.6, 1.6), true, Ink.INK, 0.6, 0.3)
	Kit.skull(p, room, Vector3(-2.0, 0.0, 11.0), 0.1, Color("#8a7e6a"))
