extends RefCounted
## 전투 뒷그림 — 빙하굴(glacier_cave): 푸르게 언 얼음 동굴. 겹겹이 줄진 얼음 벽, 천장의 고드름, 눈 덮인 바닥과 미끄러운 얼음판,
## 일정한 간격으로 선 얼음 길잡이 기둥(하나는 금이 갔다), 천장 틈으로 쏟아지는 차가운 빛줄기.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")

const ICE := Color("#86a6be")
const DEEP := Color("#2e4a66")
const SNOW := Color("#b8c6d0")
const SHAFT_Z := 12.5  ## 빛줄기가 떨어지는 거리


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "cave"
	room.z_end = 32.0
	room.fog_k = 0.07
	room.fog_c = Color("#0c1218")
	room.ambient = Color(0.14, 0.17, 0.22)
	room.bump = 0.9
	room.shape(func(z: float) -> float: return 5.0 + (m.nz("lo", z * 0.3, 4.0) - 0.5) * 2.4,
		func(z: float) -> float: return 5.2 + (m.nz("lo", z * 0.3, 21.0) - 0.5) * 2.4,
		func(z: float) -> float: return 7.0 + (m.nz("lo", z * 0.25, 40.0) - 0.5) * 2.0)
	room.lights = [
		{"p": Vector3(0.0, 8.5, SHAFT_Z), "c": Color("#d8ecff"), "s": 2.4, "r": 6.0},
		{"p": Vector3(0.5, 5.5, 23.0), "c": Color("#a8c8e8"), "s": 1.2, "r": 5.0},
		{"p": Vector3(0.0, 3.0, 4.0), "c": Color("#8aa0b8"), "s": 0.6, "r": 4.0},
		{"p": Vector3(0.0, 5.0, 0.5), "c": Color("#7a92aa"), "s": 1.0, "r": 6.0},
	]
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			return _floor(m, P)
		if kind == Room.END:
			return {"c": Color("#1a2a38")}
		var strata := m.nz("mid", P.z * 0.25, P.y * 1.6 + 3.0)
		var r := m.rock(P.z * 0.8, P.y * 0.9, ICE, 0.35)
		var c := (r["c"] as Color).lerp(DEEP, smoothstep(0.35, 0.7, strata) * 0.35)
		c = c.lerp(Color("#d8e8f0"), smoothstep(0.75, 0.9, m.nz("hi", P.z * 0.2, P.y * 3.0)) * 0.3)
		if N.y < -0.4:
			c = c.darkened(0.15)
		r["c"] = c
		r["emit"] = Color(0.03, 0.07, 0.11) * (1.0 - strata)  # 얼음 속에서 번지는 빛
		r["spec"] = 0.6
		return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.18, Color("#0c1620"))
	Kit.hatch_dark(p, 7000, 55.0, 0.03, 0.14, 0.32)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0e1620"), Color("#e8f0f4"), 0.2, 0.55)
	_shaft(p, room)
	return p


## 바닥: 눈(부드러운 둔덕) + 가운데 얼음판(광택, 금).
static func _floor(m: Mats, P: Vector3) -> Dictionary:
	var drift := m.nz("lo", P.x * 0.8, P.z * 0.6)
	var ice_k := smoothstep(0.6, 0.66, m.nz("lo", P.x * 0.5 + 9.0, P.z * 0.35) + (1.0 - smoothstep(0.0, 2.0, absf(P.x))) * 0.2)
	var c := m.vary(SNOW.lightened(0.08), P.x * 1.5, P.z * 1.5, 0.06).lerp(Color("#98aab8"), (1.0 - drift) * 0.25)
	var hgt := drift * 0.1 + m.nz("mid", P.x, P.z) * 0.02
	var ink := 0.0
	if ice_k > 0.0:
		var cr := m.nz("cell", P.x * 0.6, P.z * 0.6)
		var streak := m.nz("mid", P.x * 0.3, P.z * 1.2)
		c = c.lerp(Color("#506a80").lerp(Color("#9ab8cc"), streak * 0.6), ice_k)
		hgt = lerpf(hgt, 0.0, ice_k)
		ink = (1.0 - smoothstep(0.0, 0.02, cr)) * 0.4 * ice_k * smoothstep(0.45, 0.65, m.nz("mid", P.x * 0.3, P.z * 0.3))
	return {"c": c, "h": hgt, "ink": ink, "spec": ice_k * 0.5}


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 11
	var ice_tex := func(P: Vector3) -> Color:
		var c := m.vary(Color("#b8d0e0"), P.y * 2.0, P.z * 3.0 + P.x * 3.0, 0.3)
		return c.lerp(Color("#5a7a98"), smoothstep(0.4, 0.7, m.nz("mid", P.y * 1.5, P.x * 4.0)) * 0.5)
	var items: Array[Dictionary] = []
	for k in 30:  # 고드름
		var z := rng.randf_range(3.5, 26.0)
		var x := rng.randf_range(-0.75, 0.75) * room.left_at(z)
		items.append({"z": z, "kind": "icicle", "x": x, "len": rng.randf_range(0.5, 1.8)})
	for zz: float in [6.0, 13.0, 20.0]:  # 길잡이 기둥
		for s: float in [-1.0, 1.0]:
			items.append({"z": zz, "kind": "pillar", "x": s * (room.wall_x(zz, 1.0, int(s)) - 1.3), "crack": zz == 13.0 and s > 0.0})
	for k in 8:  # 바닥 얼음 결정
		var z := rng.randf_range(4.0, 22.0)
		var s := -1.0 if k % 2 == 0 else 1.0
		items.append({"z": z, "kind": "spike", "x": s * (room.wall_x(z, 0.3, int(s)) - rng.randf_range(0.2, 0.6)), "len": rng.randf_range(0.6, 1.5)})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["z"]) > float(b["z"]))
	for it in items:
		var z := float(it["z"])
		var x := float(it["x"])
		match str(it["kind"]):
			"icicle":
				var top := room.ceil_at(z) * (1.0 - absf(x) / maxf(1.0, room.left_at(z)) * 0.35)
				var ln := float(it["len"])
				Kit.shard(p, room, Vector3(x, top + 0.3, z), Vector3(x, top - ln, z), ln * 0.12, Color("#a8c4d8"), Color("#203040"), 0.8)
			"pillar":
				Kit.floor_shadow(p, room, x, z, 0.8, 0.35)
				Kit.pillar(p, room, x, z, 0.38, 0.0, room.ceil_at(z), ice_tex, 0.7)
				if it["crack"]:
					var a := room.pt(x - 0.1, 3.4, z - 0.35)
					var pts := PackedVector2Array([a])
					for i in 7:
						a += Vector2(rng.randf_range(-4.0, 4.0), room.px(0.25, z))
						pts.append(a)
					Ink.path(p, pts, clampf(room.px(0.03, z), 0.8, 2.5), false, Ink.INK, 0.8, 0.5)
			"spike":
				var ln2 := float(it["len"])
				Kit.cluster(p, room, Vector3(x, 0.0, z), Vector3(-signf(x) * 0.3, 1.0, 0.0), ln2, Color("#9ab8cc"), Color("#203848"), 4)


## 천장 틈에서 떨어지는 빛줄기(색 보정 뒤 — 더하기 빛).
static func _shaft(p: Paint, room: Room) -> void:
	var top := room.ceil_at(SHAFT_Z)
	var poly := Kit.proj(room, [Vector3(-0.6, top, SHAFT_Z), Vector3(0.9, top, SHAFT_Z), Vector3(2.0, 0.0, SHAFT_Z - 0.5), Vector3(-1.6, 0.0, SHAFT_Z - 0.5)])
	var y0 := Paint.bounds(poly).position.y
	var y1 := Paint.bounds(poly).end.y
	var col := Color("#d0e4f4")
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var t := clampf((y - y0) / maxf(1.0, y1 - y0), 0.0, 1.0)
		p.add_light(x, y, col, 0.09 * (1.0 - t * 0.6) * (0.7 + 0.6 * p.nz("vs", x, y)))
		return Color(0, 0, 0, 0))
	var c := room.pt(0.2, 0.0, SHAFT_Z - 0.5)
	Ink.glow(p, c.x, c.y, room.px(2.2, SHAFT_Z), col, 0.18)
