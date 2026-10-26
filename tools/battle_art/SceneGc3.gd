extends RefCounted
## 전투 뒷그림 — 빙하굴 3장 지하수맥: 오른쪽으로 검푸른 지하수가 이쪽으로 흘러오고, 끝에는 반쯤 얼어붙은 폭포가 김을 뿜는다.
## 왼쪽 얼음 둑에는 오크가 갇힌 얼음 기둥들, 벽 너머로 비치는 그림자.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const ICE := Color("#7e9cb4")
const DEEP := Color("#24405a")
const RIVER := 1.6    ## 이 x보다 오른쪽은 물
const FALLS_Z := 27.0
const PILLARS: Array[Vector3] = [Vector3(-3.6, 0.0, 9.0), Vector3(-4.4, 0.0, 15.5), Vector3(-3.2, 0.0, 21.0)]


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "cave"
	room.z_end = FALLS_Z
	room.fog_k = 0.07
	room.fog_c = Color("#0a1218")
	room.ambient = Color(0.12, 0.15, 0.2)
	room.shape(func(z: float) -> float: return 5.2 + (m.nz("lo", z * 0.3, 2.0) - 0.5) * 1.6,
		func(z: float) -> float: return 6.0 + (m.nz("lo", z * 0.3, 12.0) - 0.5) * 1.6,
		func(z: float) -> float: return 6.5 + (m.nz("lo", z * 0.25, 30.0) - 0.5) * 1.6)
	room.lights = [
		{"p": Vector3(3.0, 3.0, FALLS_Z - 1.5), "c": Color("#c0e0ff"), "s": 3.0, "r": 6.0},
		{"p": Vector3(0.0, 5.0, 8.0), "c": Color("#8aa4c0"), "s": 1.2, "r": 6.0},
	]
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		if kind == Room.FLOOR:
			var shore := RIVER + (m.nz("mid", P.z * 0.4, 1.0) - 0.5) * 0.8
			if P.x > shore:
				var wd := Kit2.water(m, P, Color("#0a1620"), Color("#8ab8d8"), 0.9)
				var foam := smoothstep(0.6, 0.8, m.nz("hi", P.x * 0.6, P.z * 1.5)) * (1.0 - smoothstep(0.0, 0.6, P.x - shore))
				wd["c"] = (wd["c"] as Color).lerp(Color("#c8dce8"), foam * 0.6)
				return wd
			var snow := m.vary(Color("#aebcc8"), P.x * 1.5, P.z * 1.5, 0.1)
			var ice := smoothstep(0.5, 0.6, m.nz("lo", P.x * 0.5, P.z * 0.4))
			snow = snow.lerp(Color("#5a7890"), ice * 0.7).darkened(0.3 * smoothstep(shore - 0.6, shore, P.x))
			return {"c": snow, "h": m.nz("mid", P.x, P.z) * 0.03 * (1.0 - ice), "spec": ice * 0.5 + smoothstep(shore - 0.6, shore, P.x) * 0.5}
		if kind == Room.END:  # 반쯤 언 폭포
			var falls := 1.0 - smoothstep(2.2, 3.2, absf(P.x - 2.4))
			var streak := m.nz("hi", P.x * 2.0, P.y * 0.1)
			var c := Color("#2a4058").lerp(Color("#cfe4f2"), falls * (0.4 + 0.6 * streak))
			return {"c": c, "emit": Color(0.08, 0.14, 0.2) * falls, "spec": 0.6}
		var strata := m.nz("mid", P.z * 0.3, P.y * 1.8)
		var r := m.rock(P.z * 0.8, P.y * 0.9, ICE, 0.35)
		r["c"] = (r["c"] as Color).lerp(DEEP, smoothstep(0.35, 0.7, strata) * 0.45).darkened(0.2 if N.y < -0.4 else 0.0)
		r["emit"] = Color(0.02, 0.05, 0.08) * (1.0 - strata)
		r["spec"] = 0.6
		if P.x < 0.0 and P.y > 1.0 and P.y < 3.2:  # 얼음벽 너머 그림자(무언가 움직인다)
			var sh := 1.0 - smoothstep(0.3, 0.9, Vector2((P.z - 17.0) * 0.8, (P.y - 2.0) * 0.6).length())
			r["c"] = (r["c"] as Color).darkened(sh * 0.6)
		return r
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.18, Color("#0a1620"))
	Kit.hatch_dark(p, 7000, 55.0, 0.03, 0.14, 0.32)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#0c141c"), Color("#e4eef4"), 0.2, 0.58)
	var mist := room.pt(2.6, 0.6, FALLS_Z - 0.5)
	Ink.glow(p, mist.x, mist.y, room.px(3.5, FALLS_Z), Color("#c8e0f0"), 0.3, false)
	Kit2.sparkle(p, Rect2(mist.x - 90, mist.y - 160, 180, 170), 70, Color("#e0f0ff"), 1.4)
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var ice_tex := func(P: Vector3) -> Color:
		return m.vary(Color("#a8c2d6"), P.y * 2.0, P.z * 3.0 + P.x * 3.0, 0.25).lerp(Color("#4a6a88"), smoothstep(0.4, 0.7, m.nz("mid", P.y * 1.5, P.x * 4.0)) * 0.5)
	for c in PILLARS:
		var top := room.ceil_at(c.z) * 0.92
		Kit.pillar(p, room, c.x, c.z, 0.65, 0.0, top, ice_tex, 0.8)
		_trapped(p, room, c)
	for k in 18:  # 고드름
		var z := p.rng.randf_range(4.0, 25.0)
		var x := p.rng.randf_range(-0.7, 0.7) * room.left_at(z)
		var top := room.ceil_at(z) * (1.0 - absf(x) / maxf(1.0, room.left_at(z)) * 0.35)
		var ln := p.rng.randf_range(0.4, 1.4)
		Kit.shard(p, room, Vector3(x, top + 0.3, z), Vector3(x, top - ln, z), ln * 0.12, Color("#a8c4d8"), Color("#203040"), 0.8)
	for k in 6:  # 물 위 얼음 조각
		var z := p.rng.randf_range(4.0, 18.0)
		var x := p.rng.randf_range(RIVER + 0.8, 5.0)
		var c := room.pt(x, 0.02, z)
		var r := room.px(p.rng.randf_range(0.2, 0.45), z)
		var floe := PackedVector2Array()
		for i in 7:
			var a := TAU * i / 7.0 + p.rng.randf() * 0.5
			floe.append(c + Vector2(cos(a) * r, sin(a) * r * 0.3))
		p.fill_poly(floe, p.flat(room.lit(Vector3(x, 0.05, z), Vector3.UP, Color("#b8ccd8")), 0.1))
		Ink.path(p, floe, 1.0, true, Ink.INK, 0.6, 0.3)


## 얼음 기둥 속에 갇힌 오크(어두운 몸 실루엣 — 기둥 앞면 안쪽).
static func _trapped(p: Paint, room: Room, c: Vector3) -> void:
	var z := c.z - 0.3
	var body := Kit.proj(room, [Vector3(c.x - 0.12, 2.25, z), Vector3(c.x + 0.12, 2.25, z), Vector3(c.x + 0.2, 2.05, z), Vector3(c.x + 0.42, 1.95, z),
		Vector3(c.x + 0.48, 1.2, z), Vector3(c.x + 0.36, 1.2, z), Vector3(c.x + 0.3, 1.75, z), Vector3(c.x + 0.24, 1.0, z),
		Vector3(c.x + 0.26, 0.15, z), Vector3(c.x + 0.06, 0.15, z), Vector3(c.x, 0.85, z), Vector3(c.x - 0.06, 0.15, z),
		Vector3(c.x - 0.26, 0.15, z), Vector3(c.x - 0.24, 1.0, z), Vector3(c.x - 0.3, 1.75, z), Vector3(c.x - 0.36, 1.2, z),
		Vector3(c.x - 0.48, 1.2, z), Vector3(c.x - 0.42, 1.95, z), Vector3(c.x - 0.2, 2.05, z)])
	p.fill_poly(body, func(x: int, y: int) -> Color: return Color(0.08, 0.12, 0.14, 0.55 * (0.7 + 0.3 * p.nz("mid", x, y))))
	var head := room.pt(c.x, 2.45, z)
	var hr := room.px(0.17, c.z)
	var hp := PackedVector2Array()
	for k in 12:
		hp.append(head + Vector2.from_angle(TAU * k / 12.0) * hr)
	p.fill_poly(hp, func(_x: int, _y: int) -> Color: return Color(0.08, 0.12, 0.14, 0.55))
	for s: float in [-1.0, 1.0]:  # 엄니
		var t := head + Vector2(s * hr * 0.4, hr * 0.5)
		Ink.line(p, t, t + Vector2(0, -hr * 0.5), clampf(hr * 0.12, 0.8, 2.0), Color("#c8c0a8"), 0.6, 0.1)
