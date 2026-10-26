extends RefCounted
## 전투 뒷그림 — 빙하굴 4장 얼음 가루가 쏟아지는 공동: 높은 둥근 천장의 넓은 얼음 공동, 가운데 천장 구멍에서
## 빛기둥과 함께 반짝이는 얼음 가루가 쏟아져 그 밑에 눈 더미가 쌓였다. 벽을 따라 거대한 고드름과 얼음 결정.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const ICE := Color("#8aa8c0")
const DEEP := Color("#2a4662")
const HOLE := Vector3(0.0, 0.0, 15.0)  ## 천장 구멍 아래(x, -, z)


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "cave"
	room.z_end = 32.0
	room.fog_k = 0.055
	room.fog_c = Color("#0e161e")
	room.ambient = Color(0.15, 0.18, 0.23)
	room.shape(func(z: float) -> float: return 5.5 + sin(clampf(z / 30.0, 0.0, 1.0) * PI) * 5.0,
		func(z: float) -> float: return 5.8 + sin(clampf(z / 30.0, 0.0, 1.0) * PI) * 5.0,
		func(z: float) -> float: return 7.0 + sin(clampf(z / 30.0, 0.0, 1.0) * PI) * 6.0)
	room.lights = [
		{"p": Vector3(0.0, 11.0, HOLE.z), "c": Color("#e0f0ff"), "s": 3.4, "r": 7.0},
		{"p": Vector3(0.0, 4.0, 3.0), "c": Color("#8aa0b8"), "s": 0.8, "r": 5.0},
	]
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			var d := Vector2(P.x - HOLE.x, (P.z - HOLE.z) * 0.8).length()
			var c := m.vary(Color("#c4d0da"), P.x * 1.2, P.z * 1.2, 0.07).lerp(Color("#e8f0f6"), (1.0 - smoothstep(0.0, 3.0, d)) * 0.5)
			var ice := smoothstep(0.66, 0.7, m.nz("lo", P.x * 0.4 + 9.0, P.z * 0.35)) * smoothstep(2.5, 4.0, d)
			c = c.lerp(Color("#8aa2b6"), ice * 0.6)
			return {"c": c, "h": m.nz("mid", P.x * 0.7, P.z * 0.7) * 0.06 + (1.0 - smoothstep(0.0, 3.0, d)) * 0.2, "spec": ice * 0.5}
		if kind == Room.END:
			return {"c": Color("#1c2c3a")}
		var r := m.rock(P.z * 0.6 + P.x * 0.2, P.y * 0.7, ICE, 0.3)
		var strata := m.nz("mid", P.z * 0.2, P.y * 1.2)
		var hole := 1.0 - smoothstep(1.2, 1.8, Vector2(P.x - HOLE.x, P.z - HOLE.z).length())
		if N.y < -0.5 and hole > 0.0:  # 천장 구멍 = 하얀 빛
			return {"c": Color("#f0f8ff").lerp(Color("#a8c0d4"), 1.0 - hole), "flat": true}
		r["c"] = (r["c"] as Color).lerp(DEEP, smoothstep(0.35, 0.7, strata) * 0.4).darkened(0.12 if N.y < -0.4 else 0.0)
		r["emit"] = Color(0.03, 0.07, 0.11) * (1.0 - strata)
		r["spec"] = 0.6
		return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.14, Color("#0c1620"))
	Kit.hatch_dark(p, 7000, 55.0, 0.03, 0.14, 0.3)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0e1620"), Color("#eef4f8"), 0.18, 0.55)
	_shaft(p, room)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 21
	var items: Array[Dictionary] = []
	for k in 34:
		var z := rng.randf_range(3.0, 28.0)
		var x := rng.randf_range(-0.85, 0.85) * room.left_at(z)
		if Vector2(x - HOLE.x, z - HOLE.z).length() < 2.2:
			continue
		items.append({"z": z, "x": x, "len": rng.randf_range(0.6, 2.6) * (1.0 if absf(x) > 2.0 else 0.6), "kind": "icicle"})
	for k in 10:
		var z := rng.randf_range(4.0, 26.0)
		var s := -1.0 if k % 2 == 0 else 1.0
		items.append({"z": z, "x": s * (room.wall_x(z, 0.3, int(s)) - rng.randf_range(0.2, 0.8)), "len": rng.randf_range(0.8, 2.2), "kind": "spike"})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["z"]) > float(b["z"]))
	for it in items:
		var z := float(it["z"])
		var x := float(it["x"])
		var ln := float(it["len"])
		if str(it["kind"]) == "icicle":
			var top := room.ceil_at(z) * (1.0 - absf(x) / maxf(1.0, room.left_at(z)) * 0.4)
			Kit.shard(p, room, Vector3(x, top + 0.4, z), Vector3(x, top - ln, z), ln * 0.13, Color("#aac6da"), Color("#203040"), 0.8)
		else:
			Kit.cluster(p, room, Vector3(x, 0.0, z), Vector3(-signf(x) * 0.3, 1.0, 0.0), ln, Color("#9ab8cc"), Color("#28485c"), 5)


## 천장 구멍의 빛기둥 + 쏟아지는 얼음 가루(색 보정 뒤).
static func _shaft(p: Paint, room: Room) -> void:
	var top := room.ceil_at(HOLE.z)
	var poly := Kit.proj(room, [Vector3(-1.4, top, HOLE.z), Vector3(1.4, top, HOLE.z), Vector3(2.4, 0.0, HOLE.z - 0.5), Vector3(-2.4, 0.0, HOLE.z - 0.5)])
	var r := Paint.bounds(poly)
	var col := Color("#dceaf8")
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var t := clampf((y - r.position.y) / maxf(1.0, r.size.y), 0.0, 1.0)
		p.add_light(x, y, col, 0.12 * (1.0 - t * 0.5) * (0.7 + 0.6 * p.nz("vs", x, y)))
		return Color(0, 0, 0, 0))
	Kit2.sparkle(p, r, 420, Color("#f0f8ff"), 1.3)
	var c := room.pt(0.0, 0.2, HOLE.z - 0.5)
	Ink.glow(p, c.x, c.y, room.px(2.6, HOLE.z), col, 0.22, false)
