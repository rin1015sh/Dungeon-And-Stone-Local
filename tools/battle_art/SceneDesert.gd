extends RefCounted
## 전투 뒷그림 — 2층 바위사막(f2_rock_desert — floor2.md §4, LD14): 뜨거운 모래 평원. 멀리 양옆으로 검은 바위산이 물러나 있고,
## 하얗게 바랜 하늘, 바닥은 바람 결이 진 모래 · 자갈 · 짐승 뼈, 멀리 검은 바위산 실루엣과 아지랑이 같은 모래먼지(SceneCanyon을 넓힌 것).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const DIRT := Color("#c8a874")
const ROCK := Color("#4a423c")
const ROCK_DARK := Color("#221e1a")
const SKY_TOP := Color("#a89880")
const SKY_LOW := Color("#f0e0c0")
const CLOUD := Color("#e0ccaa")
const BONE := Color("#d8ccb0")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 860.0
	room.hy = 240.0
	room.z_end = 160.0
	room.fog_k = 0.045
	room.fog_c = Color("#e0c8a0")
	room.ambient = Color(0.32, 0.28, 0.24)
	room.shape(func(_z: float) -> float: return 400.0, func(_z: float) -> float: return 400.0, func(_z: float) -> float: return 60.0)
	room.lights = [
		{"p": Vector3(1.0, 24.0, 18.0), "c": Color("#ffe0b0"), "s": 2.2, "r": 46.0},
	]
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			var d := m.rock(P.x * 1.6, P.z * 1.6, DIRT, 0.12)
			var gravel := smoothstep(0.7, 0.76, m.nz("hi", P.x * 3.0, P.z * 3.0))
			d["c"] = (d["c"] as Color).lerp(Color("#6a5240"), gravel * 0.6)
			d["h"] = float(d["h"]) * 0.5
			return d
		if kind == Room.WALL_L or kind == Room.WALL_R:
			var band := sin(P.y * 2.6 + m.nz("lo", P.z * 0.3, P.y * 0.5) * 3.0) * 0.5 + 0.5  # 가로 사암 결
			var d := m.rock(P.z * 1.2, P.y * 1.5, ROCK.lerp(ROCK_DARK, band * 0.45), 0.2)
			d["c"] = (d["c"] as Color).darkened(clampf(1.0 - P.y / 6.0, 0.0, 1.0) * 0.25)  # 밑동은 그늘
			return d
		return Kit2.sky(m, room, P, SKY_TOP, SKY_LOW, CLOUD)
	room.render(p)
	_mesas(p, room)
	_props(p, room)
	Kit.grime(p, 0.14, Color("#2a1e16"))
	Kit.hatch_dark(p, 7000, 60.0, 0.03, 0.14, 0.32)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#2a1e16"), Color("#f0e0c8"), 0.35, 0.45)
	Kit2.sparkle(p, Rect2(0, room.hy - 30.0, w, 120.0), 90, Color("#f0d8b0"), 1.4)  # 바람에 떠도는 흙먼지
	return p


## 협곡 끝 너머 멀리 메사들(평평한 꼭대기 · 가파른 옆면) — 흐린 실루엣.
static func _mesas(p: Paint, room: Room) -> void:
	var z := 58.0
	var pts: Array = [Vector3(-12.0, 0.0, z)]
	var x := -12.0
	var i := 0
	while x < 12.0:
		var top := 5.0 + float((i * 5) % 4) * 1.6
		var wid := 3.0 + float(i % 3) * 1.5
		pts.append(Vector3(x + 0.6, top, z))
		pts.append(Vector3(x + wid - 0.6, top, z))
		pts.append(Vector3(x + wid, top * 0.55, z))
		x += wid + 0.8
		pts.append(Vector3(x, 2.0, z))
		i += 1
	pts.append(Vector3(12.0, 0.0, z))
	Kit2.silhouette(p, Kit.proj(room, pts), Color("#3a342e"), Color("#a89880"))


static func _props(p: Paint, room: Room) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 31
	var items: Array[Dictionary] = []
	for k in 10:  # 바위
		items.append({"z": rng.randf_range(4.0, 34.0), "kind": "rock", "x": (-1.0 if k % 2 == 0 else 1.0) * rng.randf_range(1.6, 3.4)})
	for k in 8:  # 짐승 뼈
		items.append({"z": rng.randf_range(3.0, 22.0), "kind": "bone", "x": rng.randf_range(-2.6, 2.6)})
	for k in 0:  # (사막엔 절벽 굴이 없다 — SceneCanyon에서 가져온 틀)
		items.append({"z": rng.randf_range(5.0, 30.0), "kind": "hole", "x": (-1.0 if k % 2 == 1 else 1.0)})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["z"]) > float(b["z"]))
	for it in items:
		var z := float(it["z"])
		var x := float(it["x"])
		match str(it["kind"]):
			"rock":
				Kit.floor_shadow(p, room, x, z, 0.6, 0.4)
				var r := rng.randf_range(0.3, 0.7)
				var poly := Kit.proj(room, [Vector3(x - r, 0.0, z), Vector3(x - r * 0.7, r * 0.8, z), Vector3(x + r * 0.2, r * 1.1, z), Vector3(x + r, r * 0.5, z), Vector3(x + r * 0.9, 0.0, z)])
				p.fill_poly(poly, func(_px: int, py: int) -> Color:
					var lit := room.lit(Vector3(x, r * 0.5, z), Vector3(-0.3, 0.6, -1.0).normalized(), ROCK.darkened(0.15))
					return lit.darkened(clampf((py - Paint.bounds(poly).position.y) / maxf(1.0, Paint.bounds(poly).size.y), 0.0, 1.0) * 0.45))
				Ink.path(p, poly, clampf(room.px(0.03, z), 0.8, 2.0), true, Ink.INK, 0.75, 0.5)
			"bone":
				var a := room.pt(x, 0.02, z)
				var b := room.pt(x + rng.randf_range(-0.5, 0.5), 0.02, z + rng.randf_range(-0.4, 0.4))
				Ink.line(p, a, b, clampf(room.px(0.06, z), 1.0, 4.0), room.lit(Vector3(x, 0.1, z), Vector3(0, 1, 0), BONE), 0.95, 0.3)
			"hole":
				var wx := (4.0 + z * 0.3) * (-1.0 if x < 0.0 else 1.0) * 0.98
				var c := room.pt(wx, rng.randf_range(0.3, 1.2), z)
				var rr := clampf(room.px(rng.randf_range(0.18, 0.32), z), 2.0, 22.0)
				p.fill_poly(_ellipse(c, rr * 0.7, rr), func(_px: int, _py: int) -> Color: return Color("#1a120c"), 0.95)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 14:
		var a := TAU * k / 14.0
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out
