extends RefCounted
## 전투 뒷그림 — 2층 망자의 땅(f2_land_of_dead — docs/plans/floor2.md §3): 밤처럼 검은 하늘에 흩뿌린 빛, 웅덩이 진 검은 진창,
## 기울어진 묘비들 · 마른 나무 · 박힌 말뚝, 지평선에 무너진 석조 잔해 실루엣, 낮게 깔린 안개와 떠도는 넋불 둘.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const MUD := Color("#2a2622")
const STONE := Color("#4a4842")
const SKY_TOP := Color("#06080e")
const SKY_LOW := Color("#1a1e2a")
const CLOUD := Color("#10131c")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.z_end = 40.0
	room.fog_k = 0.07
	room.fog_c = Color("#141822")
	room.ambient = Color(0.13, 0.14, 0.18)
	room.shape(func(_z: float) -> float: return 30.0, func(_z: float) -> float: return 30.0, func(_z: float) -> float: return 80.0)
	room.lights = [
		{"p": Vector3(0.0, 30.0, 20.0), "c": Color("#7a86a8"), "s": 1.4, "r": 40.0},
		{"p": Vector3(-2.5, 1.2, 9.0), "c": Color("#7ab8ff"), "s": 0.8, "r": 3.0},
		{"p": Vector3(3.0, 1.5, 14.0), "c": Color("#7ab8ff"), "s": 0.7, "r": 3.0},
	]
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			var d := m.rock(P.x * 1.4, P.z * 1.4, MUD, 0.1)
			var puddle := smoothstep(0.62, 0.68, m.nz("lo", P.x * 0.7 + 3.0, P.z * 0.5))
			var prints := smoothstep(0.82, 0.86, m.nz("hi", P.x * 2.0, P.z * 2.0)) * (1.0 - puddle)
			d["c"] = (d["c"] as Color).darkened(prints * 0.3).lerp(Color("#121418"), puddle * 0.85)
			d["h"] = float(d["h"]) * 0.4
			d["spec"] = puddle * 0.95
			return d
		return Kit2.sky(m, room, P, SKY_TOP, SKY_LOW, CLOUD)
	room.render(p)
	_ruins(p, room)
	_props(p, room, m)
	Kit.grime(p, 0.25, Color("#08090c"))
	Kit.hatch_dark(p, 8000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0c0e14"), Color("#d8dce8"), 0.35, 0.6)
	Kit2.sparkle(p, Rect2(0, 0, w, room.hy - 40.0), 140, Color("#c8d4ff"), 1.2)  # 높은 천장에 흩뿌린 빛
	Kit2.wisp(p, room, Vector3(-2.5, 1.2, 9.0), 0.12, Color("#7ab8ff"))
	Kit2.wisp(p, room, Vector3(3.0, 1.5, 14.0), 0.1, Color("#7ab8ff"))
	return p


## 지평선의 무너진 석조 잔해(기둥 · 부서진 아치 · 벽 조각) — 검은 실루엣.
static func _ruins(p: Paint, room: Room) -> void:
	var z := 60.0
	var pts: Array = [Vector3(-40.0, 0.0, z)]
	var x := -40.0
	var i := 0
	while x < 40.0:
		var top := 1.5 + float((i * 7) % 4) * 0.8
		if i % 5 == 2:  # 부러진 기둥(가늘고 높게)
			pts.append(Vector3(x, 0.6, z))
			pts.append(Vector3(x, top + 4.0, z))
			pts.append(Vector3(x + 1.0, top + 3.2, z))
			pts.append(Vector3(x + 1.0, 0.6, z))
			x += 3.0
		else:  # 무너진 벽 조각(윗변이 깨진 낮은 덩어리)
			var wlen := 3.0 + float(i % 3)
			pts.append(Vector3(x, top, z))
			pts.append(Vector3(x + wlen * 0.4, top + 0.4, z))
			pts.append(Vector3(x + wlen * 0.55, top - 0.6, z))
			pts.append(Vector3(x + wlen, top - 0.2, z))
			pts.append(Vector3(x + wlen, 0.4, z))
			x += wlen + 2.0
			pts.append(Vector3(x - 2.0, 0.4, z))
		i += 1
	pts.append(Vector3(40.0, 0.0, z))
	Kit2.silhouette(p, Kit.proj(room, pts), Color("#161a22"), Color("#242a38"))


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var stone := func(P: Vector3) -> Color: return m.vary(STONE, P.y * 3.0, P.x * 3.0 + P.z, 0.25)
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 21
	var items: Array[Dictionary] = []
	for k in 16:  # 묘비
		var z := rng.randf_range(5.0, 30.0)
		var s := -1.0 if k % 2 == 0 else 1.0
		items.append({"z": z, "kind": "grave", "x": s * rng.randf_range(2.2, 9.0), "lean": rng.randf_range(-0.15, 0.15)})
	for k in 7:  # 마른 나무
		var z := rng.randf_range(8.0, 34.0)
		items.append({"z": z, "kind": "tree", "x": (-1.0 if k % 2 == 0 else 1.0) * rng.randf_range(4.0, 12.0)})
	for k in 6:  # 말뚝
		var z := rng.randf_range(4.0, 20.0)
		items.append({"z": z, "kind": "stake", "x": (-1.0 if k % 2 == 1 else 1.0) * rng.randf_range(2.5, 6.0)})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["z"]) > float(b["z"]))
	for it in items:
		var z := float(it["z"])
		var x := float(it["x"])
		match str(it["kind"]):
			"grave":
				Kit.floor_shadow(p, room, x, z, 0.5, 0.35)
				var hgt := rng.randf_range(0.7, 1.2)
				var lean := float(it["lean"])
				var poly := Kit.proj(room, [Vector3(x - 0.3, 0.0, z), Vector3(x + 0.3, 0.0, z), Vector3(x + 0.3 + lean, hgt, z), Vector3(x + lean, hgt + 0.18, z), Vector3(x - 0.3 + lean, hgt, z)])
				var y_top := Paint.bounds(poly).position.y
				var y_bot := Paint.bounds(poly).end.y
				p.fill_poly(poly, func(px: int, py: int) -> Color:
					var t := clampf((py - y_top) / maxf(1.0, y_bot - y_top), 0.0, 1.0)
					var lit := room.lit(Vector3(x, hgt * (1.0 - t), z), Vector3(0.2, 0.3, -1.0).normalized(), stone.call(Vector3(x + px * 0.01, py * 0.01, z)))
					return lit.darkened(t * 0.5))
				Ink.path(p, poly, clampf(room.px(0.03, z), 0.8, 2.0), true, Ink.INK, 0.8, 0.5)
			"tree":
				var base := room.pt(x, 0.0, z)
				var top := room.pt(x + rng.randf_range(-0.6, 0.6), rng.randf_range(3.5, 6.0), z)
				var wpx := clampf(room.px(0.22, z), 1.5, 8.0)
				Ink.line(p, base, top, wpx, Color("#1a1a1e"), 1.0, 0.4)
				for b in 5:
					var t := rng.randf_range(0.35, 0.9)
					var a := base.lerp(top, t)
					var end := a + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.9, -0.2)) * room.px(rng.randf_range(1.0, 2.0), z)
					Ink.line(p, a, end, wpx * 0.45, Color("#1a1a1e"), 1.0, 0.4)
			"stake":
				var q := Kit.proj(room, [Vector3(x, 0.0, z), Vector3(x + 0.1, rng.randf_range(1.0, 1.8), z)])
				Ink.line(p, q[0], q[1], clampf(room.px(0.1, z), 1.0, 5.0), room.lit(Vector3(x, 0.8, z), Vector3(0, 0.3, -1).normalized(), Color("#3a3028")), 1.0, 0.3)
				Ink.line(p, q[0], q[1], 1.0, Ink.INK, 0.5, 0.3)
	Kit.skull(p, room, Vector3(-1.4, 0.0, 6.5), 0.1, Color("#9a9488"))
	Kit.skull(p, room, Vector3(1.8, 0.0, 8.0), 0.09, Color("#9a9488"))
