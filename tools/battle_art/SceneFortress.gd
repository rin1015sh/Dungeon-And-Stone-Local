extends RefCounted
## 전투 뒷그림 — 핏빛성채(blood_fortress): 영주성 안 고딕 회랑. 붉게 그을린 벽돌 벽과 아치 천장이 소실점으로 빨려 들고,
## 벽 기둥마다 횃불, 찢긴 붉은 깃발, 천장에서 늘어진 사슬, 판석 바닥의 마른 피, 끝은 붉은 빛이 새는 큰 문.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")

const HW := 3.6
const CH := 6.6
const BAY := 4.0      ## 기둥 간격 m
const BAY0 := 3.2     ## 첫 기둥 거리
const STONE := Color("#6a4a42")
const FLAG := Color("#4e4640")
const BLOOD := Color("#3a0e0c")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "vault"
	room.spring = 0.6
	room.z_end = 30.0
	room.fog_k = 0.085
	room.fog_c = Color("#0c0606")
	room.ambient = Color(0.12, 0.08, 0.075)
	room.shape(func(z: float) -> float: return HW + _niche(z), func(z: float) -> float: return HW + _niche(z), func(_z: float) -> float: return CH)
	room.lights = [
		{"p": Vector3(-HW + 0.6, 2.5, BAY0 + BAY - 0.6), "c": Color("#ff9a50"), "s": 3.2, "r": 3.2},
		{"p": Vector3(HW - 0.6, 2.5, BAY0 + BAY * 2.0 - 0.6), "c": Color("#ff9a50"), "s": 3.2, "r": 3.2},
		{"p": Vector3(-HW + 0.6, 2.5, BAY0 + BAY * 4.0 - 0.6), "c": Color("#ff8a40"), "s": 2.4, "r": 2.8},
		{"p": Vector3(0.0, 6.0, 6.5), "c": Color("#b07a6a"), "s": 0.9, "r": 5.0},
		{"p": Vector3(0.0, 4.0, 13.0), "c": Color("#a06050"), "s": 0.7, "r": 4.0},
		{"p": Vector3(0.0, 2.0, 27.0), "c": Color("#ff3a20"), "s": 2.2, "r": 4.0},
	]
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.flags(P.x + 20.0, P.z, 0.75, FLAG, Color("#1e1816"))
				var b := m.blood(P.x, P.z, 0.4 if absf(P.x) < 2.5 else 0.25)
				d["c"] = (d["c"] as Color).lerp(BLOOD, b * 0.85)
				d["spec"] = 0.25 * b
				return d
			Room.END:
				return {"c": Color("#2a1a18")}
			_:
				if N.y < -0.5:  # 아치 천장 = 그을린 돌
					var r := m.courses(P.z, P.x * 1.3 + 30.0, 0.7, 0.32, Color("#3a2c28"), Color("#140e0c"), 0.2, 0.025)
					return r
				var dw := m.courses(P.z, P.y, 0.95, 0.42, STONE, Color("#241816"), 0.45, 0.026)
				var soot := smoothstep(3.0, 5.5, P.y) * 0.6 + smoothstep(0.55, 0.9, m.nz("lo", P.z * 3.0, P.y * 0.25)) * 0.35
				var drip := m.blood(P.z * 0.5, P.y * 2.2, 0.16) * (1.0 - smoothstep(0.0, 2.5, P.y))
				dw["c"] = (dw["c"] as Color).darkened(soot).lerp(BLOOD, drip * 0.7)
				return dw
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.35)
	Kit.hatch_dark(p, 9000, 62.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#1a0f10"), Color("#e2c8a8"), 0.22, 0.6)
	for L: Dictionary in room.lights:  # 불꽃은 색 보정 뒤에(빛이 탁해지지 않게)
		var lp: Vector3 = L["p"]
		if lp.y < 3.0 and absf(lp.x) > 1.0:
			Kit.flame(p, room, lp - Vector3(0, 0.05, 0), 0.5)
	return p


## 기둥 사이 벽은 조금 물러난다(벽감).
static func _niche(z: float) -> float:
	var t := fposmod(z - BAY0, BAY) / BAY
	return 0.25 * smoothstep(0.1, 0.2, t) * (1.0 - smoothstep(0.8, 0.9, t))


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var stone := func(P: Vector3) -> Color: return m.vary(STONE.darkened(0.1), P.y * 2.0, P.z * 2.0 + P.x, 0.25)
	# 끝의 큰 문(붉은 빛이 문틈으로)
	var dz := 29.6
	Kit.face(p, room, [Vector3(-1.8, 0, dz), Vector3(1.8, 0, dz), Vector3(1.8, 4.2, dz), Vector3(-1.8, 4.2, dz)], Vector3(0, 0, -1),
		func(P: Vector3) -> Color: return m.planks(P.x, P.y, 0.35, Color("#3a2418"))["c"], 0.0, 1.0)
	Kit.glow(p, room, Vector3(0, 0.3, dz - 0.2), 2.6, Color("#ff3018"), 0.35)
	var zs: Array[float] = []
	var z := BAY0
	while z < 28.0:
		zs.append(z)
		z += BAY
	zs.reverse()  # 먼 것부터
	for zz in zs:
		_rib(p, room, zz)
		for s: float in [-1.0, 1.0]:
			Kit.pillar(p, room, s * (HW - 0.15), zz, 0.42, 0.0, CH * 0.62, stone)
			Kit.pillar(p, room, s * (HW - 0.15), zz, 0.52, 0.0, 0.4, stone)
		var bi := int(zz / BAY)
		if bi % 2 == 0:  # 찢긴 깃발(기둥 사이 벽)
			_banner(p, room, -1.0 if bi % 4 == 0 else 1.0, zz + BAY * 0.5, m)
	# 횃불(빛과 같은 자리)
	for L: Dictionary in room.lights:
		var lp: Vector3 = L["p"]
		if lp.y < 3.0 and absf(lp.x) > 1.0:
			var s := signf(lp.x)
			var arm := Kit.proj(room, [lp + Vector3(s * 0.45, -0.35, 0.45), lp + Vector3(0, -0.25, 0)])
			Ink.line(p, arm[0], arm[1], room.px(0.06, lp.z), Color("#1e1a16"), 1.0, 0.2)
			Kit.box(p, room, lp - Vector3(0, 0.45, 0), Vector3(0.14, 0.4, 0.14), func(_P: Vector3) -> Color: return Color("#3a2a1c"), 0.0, 0.8)
	for c: Vector3 in [Vector3(-1.6, CH, 8.0), Vector3(1.2, CH, 13.0), Vector3(-0.4, CH, 18.0)]:
		Kit.chain(p, room, c, CH - 3.2 + c.z * 0.05, 0.05)
	_bones(p, room, m, Vector3(-3.0, 0, 5.2))
	_bones(p, room, m, Vector3(3.3, 0, 9.5))


## 천장을 가로지르는 아치 갈비(기둥 위에서 위로 휘어 만난다).
static func _rib(p: Paint, room: Room, z: float) -> void:
	var pts := PackedVector2Array()
	var cols: Array[Color] = []
	for i in 33:
		var a := PI * i / 32.0
		var x := -cos(a) * (HW - 0.15)
		var y := CH * 0.62 + sin(a) * (CH - CH * 0.62) * 1.05
		pts.append(room.pt(x, y, z - 0.2))
		cols.append(room.lit(Vector3(x, y, z - 0.2), Vector3(cos(a) * 0.4, -sin(a) * 0.5, -0.8).normalized(), STONE))
	for i in 32:
		Ink.line(p, pts[i], pts[i + 1], clampf(room.px(0.22, z), 1.5, 26.0), cols[i].lerp(cols[i + 1], 0.5), 0.95, 0.3)
	Ink.path(p, pts, clampf(room.px(0.04, z), 0.8, 3.0), false, Ink.INK, 0.6, 0.6)


## 찢긴 깃발(벽에 붙은 천 — 아래가 갈라진다).
static func _banner(p: Paint, room: Room, s: float, z: float, m: Mats) -> void:
	var x := s * (HW + 0.1)
	var top := 5.2
	var bot := 2.0
	var hw := 0.55
	var pts: Array = [Vector3(x, top, z - hw), Vector3(x, top, z + hw), Vector3(x, bot + 0.3, z + hw), Vector3(x, bot - 0.2, z + hw * 0.35), Vector3(x, bot + 0.5, z), Vector3(x, bot - 0.35, z - hw * 0.4), Vector3(x, bot + 0.2, z - hw)]
	Kit.face(p, room, pts, Vector3(-s, 0, 0), func(P: Vector3) -> Color:
		var c := m.vary(Color("#6a1a16"), P.z * 3.0, P.y * 3.0, 0.35)
		return c.darkened(0.4 * m.nz("mid", P.z * 2.0, P.y * 0.5)), 0.0, 1.0)
	var rod := Kit.proj(room, [Vector3(x, top + 0.05, z - hw - 0.15), Vector3(x, top + 0.05, z + hw + 0.15)])
	Ink.line(p, rod[0], rod[1], clampf(room.px(0.06, z), 1.0, 5.0), Color("#2a2018"), 0.95, 0.2)


## 뼈 무더기(해골 하나 + 뼈 몇 개).
static func _bones(p: Paint, room: Room, m: Mats, at: Vector3) -> void:
	Kit.floor_shadow(p, room, at.x, at.z, 0.5, 0.6)
	var bone := Color("#9a8a70")
	for k in 4:
		var a := at + Vector3(p.rng.randf_range(-0.35, 0.35), 0.0, p.rng.randf_range(-0.3, 0.3))
		var b := a + Vector3(p.rng.randf_range(-0.4, 0.4), 0.04, p.rng.randf_range(-0.2, 0.2))
		var q := Kit.proj(room, [a + Vector3(0, 0.04, 0), b])
		Ink.line(p, q[0], q[1], room.px(0.07, a.z), room.lit(a, Vector3.UP, bone), 1.0, 0.2)
		Ink.line(p, q[0], q[1], room.px(0.015, a.z), Ink.INK, 0.4, 0.3)
	Kit.skull(p, room, at + Vector3(0.1, 0, -0.1), 0.12, bone.lightened(0.3))
