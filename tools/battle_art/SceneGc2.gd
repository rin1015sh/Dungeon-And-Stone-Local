extends RefCounted
## 전투 뒷그림 — 빙하굴 2장 얼음 계단과 토템: 넓은 얼음 공동 가운데 얼음 계단이 단으로 올라가고,
## 단 위에 뼈와 얼음으로 깎은 토템이 푸른 문양을 빛내며 서 있다(무리가 쏟아지는 곳). 둘레엔 금 간 길잡이 기둥과 고드름.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const ICE := Color("#86a6be")
const DEEP := Color("#2e4a66")
const SNOW := Color("#c0ccd6")
const STEP0 := 8.0     ## 계단 시작(그 앞은 평평한 얼음 바닥)
const TREAD := 0.8
const RISE := 0.2
const STEPS := 5
const TOTEM := Vector3(0.0, 0.0, 17.0)
const RUNE := Color("#7ac8ff")


static func _floor_h(z: float) -> float:
	if z < STEP0:
		return 0.0
	return minf(STEPS, floorf((z - STEP0) / TREAD) + 1.0) * RISE


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "cave"
	room.z_end = 32.0
	room.fog_k = 0.06
	room.fog_c = Color("#0c1218")
	room.ambient = Color(0.15, 0.18, 0.23)
	room.shape(func(z: float) -> float: return 7.0 + (m.nz("lo", z * 0.3, 4.0) - 0.5) * 1.6,
		func(z: float) -> float: return 7.4 + (m.nz("lo", z * 0.3, 21.0) - 0.5) * 1.6,
		func(z: float) -> float: return 10.0 + smoothstep(4.0, 12.0, z) * 2.0, func(z: float) -> float: return _floor_h(z))
	room.lights = [
		{"p": Vector3(0.0, 7.0, 14.0), "c": Color("#c8e0f8"), "s": 2.2, "r": 8.0},
		{"p": TOTEM + Vector3(0.0, 2.5, -0.8), "c": RUNE, "s": 1.8, "r": 3.0},
		{"p": Vector3(0.0, 4.0, 1.0), "c": Color("#8aa0b8"), "s": 0.8, "r": 5.0},
	]
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			var c := m.vary(SNOW, P.x * 1.5, P.z * 1.5, 0.08)
			var ink := 0.0
			var spec := 0.0
			if P.z >= STEP0 - 0.05 and P.z < STEP0 + STEPS * TREAD:
				if N.z < -0.5:  # 계단 앞면(챌판) = 푸른 얼음
					c = m.vary(Color("#6a8ca6"), P.x * 3.0, P.y * 6.0, 0.15)
					spec = 0.6
				var f := fposmod(P.z - STEP0, TREAD) / TREAD
				ink = (1.0 - smoothstep(0.0, 0.07, f)) * 0.5 if N.z > -0.5 else 0.0  # 계단 코
			var ice := smoothstep(0.62, 0.68, m.nz("lo", P.x * 0.4 + 9.0, P.z * 0.35)) * (1.0 - smoothstep(STEP0 - 1.5, STEP0, P.z))
			c = c.lerp(Color("#5a7890"), ice)
			return {"c": c, "h": m.nz("mid", P.x, P.z) * 0.02, "ink": ink, "spec": maxf(spec, ice * 0.5)}
		if kind == Room.END:
			return {"c": Color("#1a2a38")}
		var strata := m.nz("mid", P.z * 0.25, P.y * 1.6 + 3.0)
		var r := m.rock(P.z * 0.8, P.y * 0.9, ICE, 0.3)
		r["c"] = (r["c"] as Color).lerp(DEEP, smoothstep(0.35, 0.7, strata) * 0.35).darkened(0.15 if N.y < -0.4 else 0.0)
		r["emit"] = Color(0.03, 0.07, 0.11) * (1.0 - strata)
		r["spec"] = 0.6
		return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.16, Color("#0c1620"))
	Kit.hatch_dark(p, 7000, 55.0, 0.03, 0.14, 0.32)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0e1620"), Color("#e8f0f4"), 0.2, 0.55)
	_runes(p, room, true)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 4
	var ice_tex := func(P: Vector3) -> Color:
		return m.vary(Color("#b0c8da"), P.y * 2.0, P.z * 3.0 + P.x * 3.0, 0.3).lerp(Color("#5a7a98"), smoothstep(0.4, 0.7, m.nz("mid", P.y * 1.5, P.x * 4.0)) * 0.5)
	var bone := func(P: Vector3) -> Color: return m.vary(Color("#a89a84"), P.y * 4.0, P.x * 4.0, 0.25)
	for c: Vector3 in [Vector3(-5.5, 0.0, 9.0), Vector3(5.8, 0.0, 10.0), Vector3(-5.6, 0.0, 19.0), Vector3(5.8, 0.0, 20.0)]:  # 길잡이 기둥
		var fy := room.floor_at(c.z)
		Kit.pillar(p, room, c.x, c.z, 0.45, fy, room.ceil_at(c.z) * 0.9, ice_tex, 0.7)
	var crack := Kit.proj(room, [Vector3(5.7, 3.0, 9.55), Vector3(5.85, 2.2, 9.55), Vector3(5.65, 1.4, 9.55), Vector3(5.8, 0.4, 9.55)])
	Ink.path(p, crack, 1.6, false, Ink.INK, 0.8, 0.6)
	# 토템: 뼈 기둥에 얼굴 셋 + 뿔 + 가로 날개 뼈
	var fy0 := room.floor_at(TOTEM.z)
	Kit.pillar(p, room, TOTEM.x, TOTEM.z, 0.6, fy0, fy0 + 4.6, bone, 0.2)
	for k in 3:
		var y := fy0 + 0.7 + k * 1.15
		Kit.box(p, room, Vector3(TOTEM.x, y, TOTEM.z - 0.45), Vector3(1.4, 1.0, 0.35), bone, 0.1, 1.0)
		for e: float in [-0.3, 0.3]:  # 눈구멍(빛나는 문양이 들어간다)
			var q := room.pt(TOTEM.x + e, y + 0.6, TOTEM.z - 0.63)
			var r := room.px(0.08, TOTEM.z)
			p.fill_rect(q.x - r, q.y - r * 0.6, r * 2.0, r * 1.2, p.flat(Color("#0a1018"), 0.05))
	for s: float in [-1.0, 1.0]:  # 날개 뼈(갈비처럼 셋)
		for k in 3:
			var wing := Kit.proj(room, [Vector3(s * 0.5, fy0 + 4.0 - k * 0.3, TOTEM.z - 0.2), Vector3(s * (2.6 - k * 0.5), fy0 + 4.6 - k * 0.5, TOTEM.z - 0.2)])
			Ink.line(p, wing[0], wing[1], room.px(0.12, TOTEM.z), room.lit(TOTEM + Vector3(0, fy0 + 4.6, 0), Vector3(0, 0.3, -1).normalized(), Color("#a89a84")), 1.0, 0.6)
			Ink.line(p, wing[0], wing[1], 1.0, Ink.INK, 0.6, 0.6)
	for s: float in [-1.0, 1.0]:
		var horn := Kit.proj(room, [Vector3(s * 0.35, fy0 + 4.6, TOTEM.z), Vector3(s * 1.0, fy0 + 5.6, TOTEM.z), Vector3(s * 0.7, fy0 + 4.6, TOTEM.z)])
		p.fill_poly(horn, p.flat(room.lit(TOTEM + Vector3(0, fy0 + 5.6, 0), Vector3(0, 0.3, -1).normalized(), Color("#9a8a74")), 0.15))
		Ink.path(p, horn, 1.4, true, Ink.INK, 0.8, 0.4)
	_runes(p, room, false)
	for k in 26:  # 고드름
		var z := rng.randf_range(5.0, 26.0)
		var x := rng.randf_range(-0.8, 0.8) * room.left_at(z)
		var top := room.ceil_at(z) * (1.0 - absf(x) / maxf(1.0, room.left_at(z)) * 0.35)
		var ln := rng.randf_range(0.4, 1.6)
		Kit.shard(p, room, Vector3(x, top + 0.3, z), Vector3(x, top - ln, z), ln * 0.12, Color("#a8c4d8"), Color("#203040"), 0.8)


## 토템 문양(푸른 빛 줄): 바탕엔 칠, 색 보정 뒤엔 빛만(glow).
static func _runes(p: Paint, room: Room, glow: bool) -> void:
	var fy0 := room.floor_at(TOTEM.z)
	for k in 3:
		var y := fy0 + 0.7 + k * 1.15
		for e: float in [-0.3, 0.3]:
			var q := room.pt(TOTEM.x + e, y + 0.6, TOTEM.z - 0.63)
			if glow:
				Ink.glow(p, q.x, q.y, room.px(0.25, TOTEM.z), RUNE, 0.45, false)
			else:
				var r := room.px(0.04, TOTEM.z)
				p.fill_rect(q.x - r, q.y - r, r * 2.0, r * 2.0, p.flat(RUNE, 0.05))
		var a := room.pt(TOTEM.x - 0.45, y + 0.2, TOTEM.z - 0.63)
		var b := room.pt(TOTEM.x + 0.45, y + 0.2, TOTEM.z - 0.63)
		if glow:
			Ink.glow(p, (a.x + b.x) / 2.0, a.y, room.px(0.4, TOTEM.z), RUNE, 0.25, false)
		else:
			Ink.line(p, a, b, 1.6, RUNE, 0.9, 1.5)
