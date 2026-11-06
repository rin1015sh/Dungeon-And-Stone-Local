extends RefCounted
## 전투 뒷그림 — 2층 고블린 숲(f2_goblin_forest — docs/plans/floor2.md §5, FL21): 밤 숲 오솔길. 양옆으로 깊이 따라 늘어선 굵은 줄기,
## 머리 위를 덮은 잎 지붕 실루엣(틈으로 별빛 은색), 낙엽 깔린 흙바닥 가운데 다져진 길, 고블린 토템 · 걸린 올가미, 멀리 고블린 화톳불 붉은 빛 둘.
## 망자의 땅 전투 그림과 같은 결(채도를 누른 잿빛 초록 · 은빛).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const SOIL := Color("#3e4034")
const PATH := Color("#5a5444")
const LITTER := Color("#5a4c36")
const BARK := Color("#3a332c")
const LEAF := Color("#26302a")
const SKY_TOP := Color("#0e1214")
const SKY_LOW := Color("#2e3a3a")
const CLOUD := Color("#1e2626")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 270.0
	room.z_end = 40.0
	room.fog_k = 0.08
	room.fog_c = Color("#2e3a36")
	room.ambient = Color(0.28, 0.31, 0.3)
	room.shape(func(_z: float) -> float: return 30.0, func(_z: float) -> float: return 30.0, func(_z: float) -> float: return 80.0)
	room.lights = [
		{"p": Vector3(0.0, 25.0, 18.0), "c": Color("#a8b8c0"), "s": 1.8, "r": 40.0},
		{"p": Vector3(-6.0, 1.0, 26.0), "c": Color("#ff8a4a"), "s": 0.9, "r": 5.0},
		{"p": Vector3(7.0, 1.0, 30.0), "c": Color("#ff8a4a"), "s": 0.8, "r": 5.0},
	]
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			var d := m.rock(P.x * 1.6, P.z * 1.6, SOIL, 0.12)
			var lane := 1.0 - smoothstep(1.2, 2.4, absf(P.x + sin(P.z * 0.25) * 0.8))  # 가운데 다져진 길
			var leaf := smoothstep(0.55, 0.75, m.nz("hi", P.x * 3.0, P.z * 3.0)) * (1.0 - lane)
			var c := (d["c"] as Color).lerp(PATH, lane * 0.8).lerp(LITTER, leaf * 0.6)
			d["c"] = c
			d["h"] = float(d["h"]) * 0.5
			return d
		return Kit2.sky(m, room, P, SKY_TOP, SKY_LOW, CLOUD)
	room.render(p)
	_far_trees(p, room)
	_trees(p, room, m)
	_canopy(p, w, room)
	_props(p, room)
	Kit.grime(p, 0.16, Color("#141814"))
	Kit.hatch_dark(p, 8000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#141814"), Color("#dce4dc"), 0.5, 0.5)
	Kit2.sparkle(p, Rect2(0, 0, w, room.hy), 90, Color("#d0dcff"), 1.2)  # 잎 틈의 별빛
	Kit.glow(p, room, Vector3(-6.0, 0.6, 26.0), 2.5, Color("#ff7a3a"), 0.5)
	Kit.glow(p, room, Vector3(7.0, 0.6, 30.0), 2.2, Color("#ff7a3a"), 0.45)
	return p


## 지평선 숲(먼 줄기 · 잎 덩어리) — 안개 낀 검은 실루엣.
static func _far_trees(p: Paint, room: Room) -> void:
	var z := 55.0
	var pts: Array = [Vector3(-45.0, 0.0, z)]
	var x := -45.0
	var i := 0
	while x < 45.0:
		var top := 7.0 + float((i * 7) % 5) * 1.4
		pts.append(Vector3(x, top - 2.0, z))
		pts.append(Vector3(x + 1.2, top, z))
		pts.append(Vector3(x + 2.6, top - 1.2, z))
		x += 3.0 + float(i % 3)
		i += 1
	pts.append(Vector3(45.0, 0.0, z))
	Kit2.silhouette(p, Kit.proj(room, pts), Color("#141a18"), Color("#2e3a36"))


## 길 양옆 굵은 줄기(멀리서 가까이로 그린다 — 가까운 줄기가 위에).
static func _trees(p: Paint, room: Room, m: Mats) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 31
	var items: Array[Dictionary] = []
	for k in 22:
		var z := rng.randf_range(4.0, 36.0)
		var s := -1.0 if k % 2 == 0 else 1.0
		items.append({"z": z, "x": s * rng.randf_range(3.2, 12.0), "r": rng.randf_range(0.25, 0.6)})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["z"]) > float(b["z"]))
	var bark := func(P: Vector3) -> Color: return m.vary(BARK, P.y * 2.0, P.x * 5.0 + P.z * 3.0, 0.3)
	for it in items:
		var x := float(it["x"])
		var z := float(it["z"])
		var r := float(it["r"])
		Kit.floor_shadow(p, room, x, z, r * 2.2, 0.4)
		Kit.pillar(p, room, x, z, r, 0.0, 14.0, bark)
		for b in 2:  # 뿌리
			var q := Kit.proj(room, [Vector3(x, 0.4, z), Vector3(x + (b * 2 - 1) * r * 2.4, 0.0, z - 0.2)])
			Ink.line(p, q[0], q[1], clampf(room.px(r * 0.5, z), 1.0, 10.0), BARK.darkened(0.2), 1.0, 0.3)


## 머리 위 잎 지붕: 위쪽을 덮는 겹친 잎 덩어리(아래 가장자리만 은빛).
static func _canopy(p: Paint, w: int, room: Room) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 7
	for k in 260:  # 잎 뭉치(작게 · 많이 — 큰 원판이면 만화처럼 보인다), 위로 갈수록 빽빽하게
		var y := room.hy * 0.5 * pow(rng.randf(), 1.6) - 30.0
		var c := Vector2(rng.randf() * w, y)
		var r := rng.randf_range(14.0, 46.0)
		var t := rng.randf() * (1.0 - clampf(y / (room.hy * 0.5), 0.0, 1.0) * 0.5)
		var col := LEAF.darkened(0.55 - t * 0.35)
		var poly := PackedVector2Array()
		for j in 18:
			var a := TAU * j / 18.0
			var rr := r * (0.8 + 0.25 * sin(a * 3.0 + k))
			poly.append(c + Vector2(cos(a) * rr, sin(a) * rr * 0.7))
		p.fill_poly(poly, func(_x: int, _y: int) -> Color: return col, 0.92)
		if t > 0.75:
			Ink.path(p, _arc(c, r, r * 0.7), 1.0, false, Color("#8a9a98"), 0.3, 0.5)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _arc(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 9:
		var a := PI * 0.15 + PI * 0.7 * k / 8.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## 고블린 토템(왼쪽 앞) · 나뭇가지에 걸린 올가미(오른쪽).
static func _props(p: Paint, room: Room) -> void:
	var q := Kit.proj(room, [Vector3(-3.2, 0.0, 7.0), Vector3(-3.1, 1.7, 7.0)])
	Ink.line(p, q[0], q[1], room.px(0.1, 7.0), BARK.darkened(0.3), 1.0, 0.3)
	Kit.skull(p, room, Vector3(-3.1, 1.6, 7.0), 0.2, Color("#bfb6a0"))
	var top := room.pt(3.6, 3.4, 9.0)
	var loop := room.pt(3.7, 1.2, 9.0)
	Ink.line(p, top, loop, 1.6, Color("#8a7a58"), 0.9, 0.4)
	var ring := PackedVector2Array()
	for k in 13:
		var a := TAU * k / 12.0
		ring.append(loop + Vector2(cos(a) * room.px(0.22, 9.0), sin(a) * room.px(0.16, 9.0) + room.px(0.2, 9.0)))
	Ink.path(p, ring, 1.6, true, Color("#8a7a58"), 0.9, 0.3)
