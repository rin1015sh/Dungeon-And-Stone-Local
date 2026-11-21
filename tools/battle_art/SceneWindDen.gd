extends RefCounted
## 전투 뒷그림 — 울부짖는 바람굴(rift_wind_den): 협곡 밑동의 둥근 굴이 어둠으로 빨려 들고, 천장 틈으로 잿빛 바깥빛이 떨어진다.
## 바람에 닳은 갈색 바위, 바닥의 흙먼지 결과 뼈 · 둥지, 굴 끝 어둠 속 두 눈, 바람에 날리는 먼지 줄.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const HW := 3.4
const CH := 4.6
const END_Z := 30.0
const ROCK := Color("#5c5246")
const SKY := Color("#e0d4bc")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 860.0
	room.hy = 245.0
	room.profile = "cave"
	room.z_end = END_Z
	room.fog_k = 0.075
	room.fog_c = Color("#1a140e")
	room.ambient = Color(0.15, 0.12, 0.09)
	room.shape(func(z: float) -> float: return HW + (m.nz("mid", z * 0.25, 2.0) - 0.5) * 0.9,
		func(z: float) -> float: return HW + (m.nz("mid", z * 0.25, 9.0) - 0.5) * 0.9,
		func(z: float) -> float: return CH + (m.nz("mid", z * 0.2, 5.0) - 0.5) * 0.8)
	room.lights = [{"p": Vector3(0.3, CH - 0.3, 6.0), "c": SKY, "s": 3.2, "r": 5.0}, {"p": Vector3(-0.4, CH - 0.3, 15.0), "c": SKY, "s": 2.0, "r": 4.0}]
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:  # 흙먼지 결(바람이 쓸고 간 줄) · 자갈
				var d := m.rock(P.x * 1.6, P.z * 1.6, Color("#4e443a"), 0.2)
				var streak := smoothstep(0.55, 0.8, m.nz("hi", P.x * 3.0, P.z * 0.25))
				d["c"] = (d["c"] as Color).lerp(Color("#7a6c58"), streak * 0.45)
				d["h"] = float(d["h"]) * 0.5
				return d
			Room.END:
				return {"c": Color("#0c0a08")}
			_:  # 벽 · 천장: 바람에 닳은 바위(가로 결) + 천장 틈 빛자리
				var r := m.rock(P.z * 1.1, P.y * 2.2, ROCK, 0.45)
				var band := smoothstep(0.45, 0.6, m.nz("lo", P.y * 1.8, P.z * 0.2))
				r["c"] = (r["c"] as Color).lerp(Color("#6e6250"), band * 0.35).darkened(0.3 * smoothstep(0.6, 0.0, P.y))
				return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.28, Color("#0e0c0a"))
	Kit.hatch_dark(p, 8000, 58.0, 0.03, 0.14, 0.33)
	Kit.brush(p, 1.0, 16.0, 4.0)
	Kit.finish(p, Color("#140f0a"), Color("#eee0c8"), 0.12, 0.58)
	for k in 2:  # 천장 틈 빛기둥(색 보정 뒤)
		Kit.glow(p, room, Vector3(0.3 - k * 0.7, CH - 0.5, 6.0 + k * 9.0), 1.2, SKY, 0.35)
	# 굴 끝 어둠 속 두 눈
	for s: float in [-1.0, 1.0]:
		var q := room.pt(s * 0.22, 1.2, END_Z - 1.0)
		Ink.glow(p, q.x, q.y, room.px(0.18, END_Z - 1.0), Color("#f0f4ff"), 0.6)
	Kit2.sparkle(p, Rect2(0, h * 0.25, w, h * 0.5), 180, Color("#c8b898"), 1.4)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var bone := func(P: Vector3) -> Color: return m.vary(Color("#c8bea2"), P.x * 5.0, P.z * 5.0, 0.15)
	var straw := func(P: Vector3) -> Color: return m.vary(Color("#6a5a3a"), P.x * 7.0, P.z * 7.0, 0.3)
	# 둥지(왼쪽) · 거대한 갈비뼈(오른쪽 벽에 기대)
	Kit.floor_shadow(p, room, -2.0, 7.0, 0.9, 0.5)
	Kit.box(p, room, Vector3(-2.0, 0.0, 7.0), Vector3(1.4, 0.25, 1.0), straw, 0.0, 0.8)
	for k in 5:  # 갈비뼈 아치
		var z := 10.0 + k * 0.6
		var a := room.pt(2.6, 0.0, z)
		var b := room.pt(1.6, 2.0 - k * 0.15, z)
		var c := room.pt(0.9, 0.3, z)
		var pts := PackedVector2Array([a, a.lerp(b, 0.5) + Vector2(room.px(0.2, z), 0), b, b.lerp(c, 0.5), c])
		Ink.path(p, pts, clampf(room.px(0.09, z), 1.2, 6.0), false, room.lit(Vector3(2.0, 1.0, z), Vector3.LEFT, Color("#c8bea2")), 1.0, 0.2)
		Ink.path(p, pts, clampf(room.px(0.02, z), 0.6, 1.5), false, Ink.INK, 0.6, 0.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 7
	for k in 10:  # 흩어진 뼈
		var z := rng.randf_range(3.0, 16.0)
		var x := rng.randf_range(-2.6, 2.6)
		var a := Vector3(x, 0.03, z)
		var b := a + Vector3(rng.randf_range(-0.4, 0.4), 0.0, rng.randf_range(-0.2, 0.2))
		var q := Kit.proj(room, [a, b])
		Ink.line(p, q[0], q[1], clampf(room.px(0.04, z), 1.0, 3.5), room.lit(a, Vector3.UP, Color("#cfc4a8")), 1.0, 0.2)
	Kit.skull(p, room, Vector3(1.4, 0.0, 5.0), 0.12, Color("#b8ae98"))
	Kit.box(p, room, Vector3(-2.4, 0.0, 14.0), Vector3(0.9, 1.4, 0.9), func(P: Vector3) -> Color: return m.rock(P.y * 2.0, P.z * 2.0 + P.x, ROCK.darkened(0.1), 0.4)["c"], 0.0, 1.0)
	Kit.box(p, room, Vector3(-1.9, 0.0, 6.6), Vector3(0.3, 0.05, 0.3), bone, 0.1, 0.6)
