extends RefCounted
## 전투 뒷그림 — 강철의 묘(iron_tomb): 리벳 박은 쇠판으로 짠 좁고 어두운 복도. 벽 가운데 높이에 새겨진 벽화 띠,
## 일정한 간격의 쇠 기둥과 천장 들보, 기둥마다 차갑게 빛나는 등, 끝은 둥근 봉인이 박힌 거대한 강철 문. 바닥에 부러진 화살과 해골.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")

const HW := 3.0
const CH := 5.0
const RIB := 3.2     ## 쇠 기둥 간격
const RIB0 := 3.0
const STEEL := Color("#626670")
const MURAL := Vector2(1.7, 2.7)  ## 벽화 띠 높이(m)
const DOOR_Z := 25.0
const LAMP := Color("#bcd8ff")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "box"
	room.z_end = DOOR_Z
	room.fog_k = 0.08
	room.fog_c = Color("#0a0a0c")
	room.ambient = Color(0.08, 0.085, 0.1)
	room.shape(func(_z: float) -> float: return HW, func(_z: float) -> float: return HW, func(_z: float) -> float: return CH)
	room.lights = [{"p": Vector3(0.0, 2.2, DOOR_Z - 0.6), "c": Color("#7aa8ff"), "s": 1.6, "r": 3.0}]
	for i in 6:
		var s := -1.0 if i % 2 == 0 else 1.0
		room.lights.append({"p": _lamp_at(i, s), "c": LAMP, "s": 2.2 if i < 4 else 1.2, "r": 2.8})
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.plates(P.x + 20.0, P.z, 1.0, 1.0, STEEL.darkened(0.3))
				var grime := smoothstep(0.4, 0.8, m.nz("lo", P.x * 1.2, P.z * 0.8))
				d["c"] = (d["c"] as Color).lerp(Color("#24201c"), grime * 0.5).lerp(Color("#3a1210"), m.blood(P.x, P.z, 0.12) * 0.7)
				return d
			Room.CEIL:
				return m.plates(P.x + 10.0, P.z, 1.2, 1.6, STEEL.darkened(0.45))
			Room.END:
				return _door(m, P)
			_:
				if P.y > MURAL.x and P.y < MURAL.y:
					return _mural(m, P.z, P.y)
				var d := m.plates(P.z, P.y, 1.3, 0.85, STEEL)
				d["c"] = (d["c"] as Color).darkened(0.25 * smoothstep(0.6, 0.0, P.y))
				return d
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.3, Color("#0a0a0c"))
	Kit.hatch_dark(p, 9000, 64.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 0.9)
	Kit.finish(p, Color("#101014"), Color("#e4e4e0"), 0.3, 0.65)
	for i in 6:  # 등 빛(색 보정 뒤)
		var s := -1.0 if i % 2 == 0 else 1.0
		Kit.glow(p, room, _lamp_at(i, s), 0.5, LAMP, 0.5 if i < 4 else 0.3)
	var seal := room.pt(0.0, 2.3, DOOR_Z)
	Ink.glow(p, seal.x, seal.y, room.px(1.4, DOOR_Z), Color("#6a98ff"), 0.22)
	return p


static func _lamp_at(i: int, s: float) -> Vector3:
	return Vector3(s * (HW - 0.45), 3.2, RIB0 + RIB * i - 0.35)


## 벽화 띠: 위아래 테두리 + 칸마다 새긴 문양(사람·창·눈·톱니) — 패인 홈 = 잉크.
static func _mural(m: Mats, z: float, y: float) -> Dictionary:
	var base := m.vary(Color("#585a5e"), z * 2.0, y * 2.0, 0.2)
	var t := (y - MURAL.x) / (MURAL.y - MURAL.x)
	var ink := 0.0
	var hgt := 0.0
	if t < 0.08 or t > 0.92:  # 테두리
		return {"c": base.darkened(0.15), "h": 0.015, "ink": 0.35 if (t > 0.05 and t < 0.08) or (t > 0.92 and t < 0.95) else 0.0, "spec": 0.4}
	var cw := 0.9
	var cell := floori(z / cw)
	var u := z / cw - cell
	var v := (t - 0.08) / 0.84
	var kind := int(Paint.hash01(cell, 4, 91) * 4.0)
	var d := 1.0
	match kind:
		0:  # 창 든 사람
			d = minf(Vector2((u - 0.5) * 2.0, (v - 0.78) * 3.0).length() - 0.35, absf(u - 0.5) * 6.0 - 0.3 + maxf(0.0, 0.25 - v) * 9.0)
			d = minf(d, absf(u - 0.72) * 14.0 - 0.3)
		1:  # 눈
			d = absf(Vector2((u - 0.5) * 1.4, (v - 0.5) * 2.4).length() - 0.4) * 6.0 - 0.3
			d = minf(d, Vector2(u - 0.5, (v - 0.5) * 1.6).length() * 8.0 - 0.6)
		2:  # 톱니(칼날)
			d = absf(fposmod(u * 4.0, 1.0) - v) * 5.0 - 0.3
		_:  # 겹친 네모
			d = absf(maxf(absf(u - 0.5), absf(v - 0.5)) - 0.3) * 12.0 - 0.4
	if d < 0.0:
		ink = 0.6
		hgt = -0.01
	if u < 0.03 or u > 0.97:
		ink = maxf(ink, 0.3)
	return {"c": base, "h": hgt, "ink": ink, "spec": 0.35}


## 끝 문: 큰 쇠판 두 짝 + 가운데 둥근 봉인(희미한 푸른 빛).
static func _door(m: Mats, P: Vector3) -> Dictionary:
	var d := m.plates(P.x + 5.0, P.y, 0.9, 0.9, STEEL.darkened(0.2))
	var r := Vector2(P.x, P.y - 2.3).length()
	if absf(P.x) < 0.03 and P.y < 4.2:
		d["ink"] = 0.8
	if absf(r - 0.9) < 0.06 or absf(r - 0.6) < 0.03:
		d["ink"] = 0.7
		d["emit"] = Color(0.1, 0.18, 0.35)
	if P.y > 4.4 or absf(P.x) > 2.2:  # 문틀 밖 = 벽
		d["c"] = (d["c"] as Color).darkened(0.4)
	return d


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var steel := func(P: Vector3) -> Color: return m.vary(STEEL.darkened(0.15), P.y * 3.0, P.z * 3.0 + P.x, 0.2)
	var zs: Array[float] = []
	var z := RIB0
	while z < DOOR_Z - 0.5:
		zs.append(z)
		z += RIB
	zs.reverse()
	for zz in zs:
		Kit.box(p, room, Vector3(0.0, CH - 0.35, zz), Vector3(HW * 2.0, 0.35, 0.4), steel, 0.5, 1.0)
		for s: float in [-1.0, 1.0]:
			Kit.box(p, room, Vector3(s * (HW - 0.18), 0.0, zz), Vector3(0.36, CH - 0.35, 0.4), steel, 0.5, 1.0)
	for i in 6:  # 등: 쇠 받침 + 유리 구슬
		var s := -1.0 if i % 2 == 0 else 1.0
		var lp := _lamp_at(i, s)
		Kit.box(p, room, lp - Vector3(0, 0.3, 0), Vector3(0.18, 0.22, 0.18), steel, 0.5, 0.8)
		var c := room.pt(lp.x, lp.y, lp.z)
		var r := room.px(0.12, lp.z)
		var orb := PackedVector2Array()
		for k in 14:
			orb.append(c + Vector2.from_angle(TAU * k / 14.0) * r)
		p.fill_poly(orb, p.flat(LAMP if i < 4 else LAMP.darkened(0.4), 0.1))
		Ink.path(p, orb, clampf(r * 0.15, 0.7, 2.0), true, Ink.INK, 0.8, 0.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 3
	for k in 9:  # 부러진 화살
		var az := rng.randf_range(2.6, 12.0)
		var ax := rng.randf_range(-2.4, 2.4)
		var a := Vector3(ax, 0.03, az)
		var b := a + Vector3(rng.randf_range(-0.5, 0.5), 0.0, rng.randf_range(-0.3, 0.3))
		var q := Kit.proj(room, [a, b])
		Ink.line(p, q[0], q[1], clampf(room.px(0.025, az), 0.8, 2.5), room.lit(a, Vector3.UP, Color("#6a5236")), 1.0, 0.2)
		Ink.line(p, q[1], q[1] + (q[1] - q[0]).normalized() * room.px(0.06, az), clampf(room.px(0.03, az), 0.8, 3.0), Color("#2a2a2c"), 1.0, 0.1)
	for k in 6:  # 벽의 화살 구멍
		var s := -1.0 if k % 2 == 0 else 1.0
		var hz := 4.5 + k * 2.6
		var q := room.pt(s * HW, 1.2, hz)
		var r := room.px(0.06, hz)
		p.fill_rect(q.x - r * 0.4, q.y - r, r * 0.8, r * 2.0, p.flat(Color("#0a0a0a"), 0.05))
	Kit.floor_shadow(p, room, 2.1, 6.0, 0.6, 0.5)
	Kit.skull(p, room, Vector3(2.1, 0.0, 6.0), 0.11, Color("#9a9080"))
