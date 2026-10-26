extends RefCounted
## 전투 뒷그림 — 핏빛성채 1장 외곽 검문소: 붉게 흐린 하늘 아래 바퀴 자국 팬 진흙길이 검문소 문으로 이어진다.
## 왼쪽은 뾰족한 말뚝 울타리, 오른쪽은 낮은 돌담, 길가의 가시 바리케이드·쇠 우리 교수대, 문기둥의 화로 둘, 지평선의 성채 실루엣.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const MUD := Color("#4a3a30")
const WOOD := Color("#4e3a28")
const STONE := Color("#5a4c46")
const GATE_Z := 16.0
const FIRE: Array[Vector3] = [Vector3(-2.7, 2.1, 15.6), Vector3(2.7, 2.1, 15.6)]


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.z_end = 34.0
	room.fog_k = 0.06
	room.fog_c = Color("#2a1412")
	room.ambient = Color(0.16, 0.1, 0.09)
	room.shape(func(_z: float) -> float: return 4.6, func(_z: float) -> float: return 4.4, func(_z: float) -> float: return 60.0,
		Callable(), func(z: float) -> float: return 2.6 + 0.3 * sin(z * 3.1) if z < 20.0 else 0.0,
		func(z: float) -> float: return 1.5 + (m.nz("mid", z * 0.5, 3.0) - 0.5) * 0.4 if z < 26.0 else 0.0)
	room.lights = [
		{"p": Vector3(0.0, 25.0, 20.0), "c": Color("#c06a58"), "s": 2.0, "r": 40.0},
		{"p": FIRE[0], "c": Color("#ff9040"), "s": 2.6, "r": 3.0},
		{"p": FIRE[1], "c": Color("#ff9040"), "s": 2.6, "r": 3.0},
	]
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.rock(P.x * 1.6, P.z * 1.6, MUD, 0.12)
				var rut := 0.0
				for rx: float in [-0.75, 0.75]:
					rut = maxf(rut, 1.0 - smoothstep(0.0, 0.18, absf(P.x - rx + (m.nz("lo", P.z, rx) - 0.5) * 0.3)))
				var puddle := smoothstep(0.66, 0.7, m.nz("lo", P.x * 0.8 + 5.0, P.z * 0.6))
				d["c"] = (d["c"] as Color).darkened(rut * 0.35).lerp(Color("#2a1e1c"), puddle * 0.8)
				d["h"] = float(d["h"]) * 0.5 - rut * 0.03
				d["spec"] = puddle * 0.9 + rut * 0.2
				d["c"] = (d["c"] as Color).lerp(Color("#3a1210"), m.blood(P.x, P.z, 0.14) * 0.6)
				return d
			Room.WALL_L:  # 말뚝 울타리
				var d := m.planks(P.z, P.y, 0.22, WOOD)
				return d
			Room.WALL_R:  # 낮은 돌담
				return m.courses(P.z, P.y, 0.7, 0.32, STONE, Color("#241a18"), 0.4, 0.03)
			Room.END:
				if P.y < 0.4:
					return {"c": Color("#24140f"), "flat": true}
				return Kit2.sky(m, room, P, Color("#2a1010"), Color("#a04a32"), Color("#4a1c16"))
			_:
				return Kit2.sky(m, room, P, Color("#2a1010"), Color("#a04a32"), Color("#4a1c16"))
	room.render(p)
	_fortress(p, room)
	_props(p, room, m)
	Kit.grime(p, 0.3, Color("#120808"))
	Kit.hatch_dark(p, 8000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#1a0e0d"), Color("#e8c8b0"), 0.22, 0.6)
	for f in FIRE:
		Kit.flame(p, room, f, 0.7)
	return p


## 지평선의 성채(성벽 + 뾰족탑) — 붉은 하늘 앞 검은 실루엣.
static func _fortress(p: Paint, room: Room) -> void:
	var z := 80.0
	var pts: Array = [Vector3(-30.0, 0.0, z)]
	var x := -30.0
	var i := 0
	while x < 30.0:
		var tower := i % 3 == 1
		var top := (16.0 if i == 7 else 13.0) if tower else 8.0
		pts.append(Vector3(x, top, z))
		if tower:
			pts.append(Vector3(x + 1.8, top + 9.0 + (i % 2) * 5.0, z))
			pts.append(Vector3(x + 3.6, top, z))
			x += 3.6
		else:
			for k in 5:  # 성가퀴
				pts.append(Vector3(x + k * 1.2, top + (1.0 if k % 2 == 0 else 0.0), z))
				pts.append(Vector3(x + k * 1.2 + 1.2, top + (1.0 if k % 2 == 0 else 0.0), z))
			x += 6.0
		i += 1
	pts.append(Vector3(30.0, 0.0, z))
	Kit2.silhouette(p, Kit.proj(room, pts), Color("#1a0c0c"), Color("#4a2018"))
	for wx: float in [-12.0, 3.0, 14.0]:  # 창 불빛
		var q := room.pt(wx, 7.0, z)
		Ink.glow(p, q.x, q.y, 5.0, Color("#ff7030"), 0.5)


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var wood := func(P: Vector3) -> Color: return m.planks(P.x + P.z, P.y, 0.25, WOOD)["c"]
	var iron := func(P: Vector3) -> Color: return m.vary(Color("#3a3634"), P.y * 3.0, P.x * 3.0, 0.2)
	# 검문소 문: 기둥 둘 + 위 들보 + 반쯤 올린 차단봉, 기둥 위 화로
	Kit.box(p, room, Vector3(0.0, 3.3, GATE_Z), Vector3(6.4, 0.4, 0.45), wood, 0.0, 1.0)
	for s: float in [-1.0, 1.0]:
		Kit.box(p, room, Vector3(s * 3.0, 0.0, GATE_Z), Vector3(0.45, 3.3, 0.45), wood, 0.0, 1.0)
	var pole := Kit.proj(room, [Vector3(2.8, 1.3, GATE_Z - 0.3), Vector3(-0.8, 3.6, GATE_Z - 0.3)])
	Ink.line(p, pole[0], pole[1], room.px(0.14, GATE_Z), room.lit(Vector3(1.0, 2.4, GATE_Z - 0.3), Vector3(0, 0.3, -1).normalized(), Color("#6a4a30")), 1.0, 0.2)
	Ink.line(p, pole[0], pole[1], 1.2, Ink.INK, 0.6, 0.3)
	for f in FIRE:
		Kit.box(p, room, f - Vector3(0, 0.4, 0), Vector3(0.6, 0.35, 0.6), iron, 0.3, 1.0)
	# 경비 초소(문 오른쪽 뒤)
	Kit.box(p, room, Vector3(3.6, 0.0, GATE_Z + 3.0), Vector3(2.0, 2.6, 2.2), wood, 0.0, 1.0)
	Kit.box(p, room, Vector3(3.6, 2.6, GATE_Z + 3.0), Vector3(2.4, 0.25, 2.6), func(P: Vector3) -> Color: return m.vary(Color("#3a2a20"), P.x * 3.0, P.z * 3.0, 0.3), 0.0, 1.0)
	# 가시 바리케이드(길 양옆)
	for c: Vector3 in [Vector3(-3.4, 0.0, 6.5), Vector3(3.3, 0.0, 8.5), Vector3(-3.6, 0.0, 10.0)]:
		for k in 4:
			var a := c + Vector3(-0.9 + k * 0.6, 0.0, 0.0)
			for d: float in [-1.0, 1.0]:
				var q := Kit.proj(room, [a + Vector3(-0.4 * d, 0.0, -0.3), a + Vector3(0.4 * d, 1.3, 0.3)])
				Ink.line(p, q[0], q[1], room.px(0.09, c.z), room.lit(a + Vector3(0, 0.6, 0), Vector3(0, 0.3, -1).normalized(), Color("#5a4230")), 1.0, 0.3)
				Ink.line(p, q[0], q[1], 1.0, Ink.INK, 0.5, 0.3)
		var rail := Kit.proj(room, [c + Vector3(-1.2, 0.65, 0.0), c + Vector3(1.0, 0.65, 0.0)])
		Ink.line(p, rail[0], rail[1], room.px(0.1, c.z), room.lit(c + Vector3(0, 0.65, 0), Vector3(0, 0.3, -1).normalized(), Color("#4a3624")), 1.0, 0.2)
	# 교수대 쇠 우리(왼쪽)
	var gx := -3.9
	var gz := 8.0
	Kit.box(p, room, Vector3(gx, 0.0, gz), Vector3(0.25, 4.6, 0.25), wood, 0.0, 1.0)
	Kit.box(p, room, Vector3(gx + 0.8, 4.4, gz), Vector3(1.8, 0.22, 0.22), wood, 0.0, 1.0)
	Kit.chain(p, room, Vector3(gx + 1.5, 4.4, gz), 0.8, 0.0)
	var cage_top := 3.6
	for k in 7:
		var bx := gx + 1.15 + k * 0.12
		var q := Kit.proj(room, [Vector3(bx, cage_top, gz), Vector3(bx, cage_top - 1.5, gz)])
		Ink.line(p, q[0], q[1], room.px(0.03, gz), Color("#1e1a18"), 1.0, 0.1)
	for yy: float in [cage_top, cage_top - 1.5]:
		var q := Kit.proj(room, [Vector3(gx + 1.1, yy, gz), Vector3(gx + 1.9, yy, gz)])
		Ink.line(p, q[0], q[1], room.px(0.04, gz), Color("#1e1a18"), 1.0, 0.1)
	var body := Kit.proj(room, [Vector3(gx + 1.35, cage_top - 0.2, gz + 0.05), Vector3(gx + 1.65, cage_top - 0.25, gz + 0.05), Vector3(gx + 1.7, cage_top - 1.4, gz + 0.05), Vector3(gx + 1.3, cage_top - 1.35, gz + 0.05)])
	p.fill_poly(body, p.flat(Color("#2a1c18"), 0.1))
	Kit.skull(p, room, Vector3(1.9, 0.0, 6.0), 0.1, Color("#9a8a72"))
