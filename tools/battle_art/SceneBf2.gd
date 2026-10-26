extends RefCounted
## 전투 뒷그림 — 핏빛성채 2장 도개교: 돌 둑길 끝에 검은 해자, 그 너머 성벽이 화면을 가로막는다.
## 성문 아치에 들어 올린 도개교(쇠사슬 둘), 양옆 둥근 탑, 성가퀴 위 횃불, 해자 가장자리에 걸친 손과 뼈.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const MOAT := Vector2(6.0, 14.5)  ## 해자 z 범위
const WALL_Z := 15.5
const CAUSE := 1.7  ## 둑길(해자로 뻗다 끊긴 다리 받침) 반 폭
const STONE := Color("#5e4e48")
const TORCH: Array[Vector3] = [Vector3(-2.6, 3.4, 15.2), Vector3(2.6, 3.4, 15.2)]


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.z_end = WALL_Z
	room.fog_k = 0.05
	room.fog_c = Color("#24100e")
	room.ambient = Color(0.14, 0.09, 0.08)
	room.shape(func(_z: float) -> float: return 40.0, func(_z: float) -> float: return 40.0, func(_z: float) -> float: return 80.0)
	room.lights = [{"p": Vector3(0.0, 30.0, 10.0), "c": Color("#b06050"), "s": 1.6, "r": 40.0}]
	for t in TORCH:
		room.lights.append({"p": t, "c": Color("#ff9040"), "s": 2.4, "r": 3.2})
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var causeway := absf(P.x) < CAUSE and P.z < MOAT.x + 3.0 + (m.nz("mid", P.x * 3.0, 9.0) - 0.5) * 1.2
				if P.z > MOAT.x + (m.nz("mid", P.x * 0.5, 4.0) - 0.5) * 0.4 and not causeway:
					return Kit2.water(m, P, Color("#0a0606"), Color("#d06a44"))
				var d := m.flags(P.x + 50.0, P.z, 0.9, Color("#4e443e"), Color("#1e1816"))
				var edge := smoothstep(MOAT.x - 1.2, MOAT.x, P.z)
				d["c"] = (d["c"] as Color).darkened(edge * 0.4).lerp(Color("#3a1210"), m.blood(P.x, P.z, 0.15) * 0.6)
				d["spec"] = edge * 0.4
				return d
			Room.END:
				return _wall(m, room, P)
			_:
				return Kit2.sky(m, room, P, Color("#2a1010"), Color("#9a4630"), Color("#4a1c16"))
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.28, Color("#120808"))
	Kit.hatch_dark(p, 8000, 60.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#1a0e0d"), Color("#e8c8b0"), 0.22, 0.6)
	for t in TORCH:
		Kit.flame(p, room, t, 0.6)
	return p


## 성벽(끝 벽): 큰 돌 + 성가퀴 + 아치 성문(올린 도개교 판), 그 위는 하늘.
static func _wall(m: Mats, room: Room, P: Vector3) -> Dictionary:
	var top := 4.4 + (0.6 if fposmod(P.x, 1.4) < 0.7 else 0.0)
	if absf(P.x) > 5.0 and absf(P.x) < 7.6:  # 탑
		top = 9.0 + (0.8 if fposmod(P.x, 1.0) < 0.5 else 0.0)
	if P.y > top:
		return Kit2.sky(m, room, P, Color("#2a1010"), Color("#9a4630"), Color("#4a1c16"))
	if absf(P.x) < 2.0 and P.y < 2.2 + sqrt(maxf(0.0, 4.0 - P.x * P.x)) * 0.8:  # 성문 아치 안 = 올린 도개교 판
		var pl := m.planks(P.x + 3.0, P.y, 0.3, Color("#4a3020"))
		if absf(fposmod(P.y, 1.4) - 0.7) < 0.06:
			pl["ink"] = 0.6
		return pl
	var d := m.courses(P.x + 30.0, P.y, 1.1, 0.55, STONE, Color("#1e1614"), 0.4, 0.03)
	d["c"] = (d["c"] as Color).darkened(0.35 * smoothstep(3.0, 0.0, P.y))  # 물 자국
	return d


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var stone := func(P: Vector3) -> Color: return m.courses(P.y, P.x + P.z, 0.9, 0.5, STONE.darkened(0.1), Color("#1e1614"), 0.3, 0.03)["c"]
	for s: float in [-1.0, 1.0]:  # 둥근 탑(성벽 앞으로 튀어나옴)
		Kit.pillar(p, room, s * 6.3, WALL_Z - 1.0, 1.3, 0.0, 9.0, stone)
		Kit.box(p, room, Vector3(s * 2.6, 0.0, WALL_Z - 0.4), Vector3(0.6, 4.4, 0.6), stone, 0.0, 1.0)
	for s: float in [-1.0, 1.0]:  # 도개교 쇠사슬(성벽 구멍 → 판 끝)
		var a := room.pt(s * 2.2, 4.3, WALL_Z - 0.1)
		var b := room.pt(s * 1.8, 1.4, WALL_Z - 0.3)
		var n := 18
		for k in n:
			var q := a.lerp(b, float(k) / n) + Vector2(sin(float(k) / n * PI) * 6.0 * s, 0)
			var r := room.px(0.07, WALL_Z)
			p.fill_rect(q.x - r * 0.5, q.y - r, r, r * 2.0, p.flat(Color("#1e1a18"), 0.1))
	# 해자 가장자리: 둑 끝 돌 턱 + 기어오르는 손
	for seg: Array in [[-40.0, -CAUSE], [CAUSE, 40.0]]:
		var lip := Kit.proj(room, [Vector3(float(seg[0]), 0.02, MOAT.x), Vector3(float(seg[1]), 0.02, MOAT.x)])
		Ink.line(p, lip[0], lip[1], room.px(0.06, MOAT.x), Color("#2a1e1a"), 1.0, 1.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = p.rng.seed + 9
	for k in 6:
		var hx := rng.randf_range(2.0, 5.0) * (1.0 if k % 2 == 0 else -1.0)
		var c := room.pt(hx, 0.0, MOAT.x + 0.05)
		var r := room.px(0.12, MOAT.x)
		for f in 4:  # 손가락
			var a := Vector2(c.x - r + f * r * 0.6, c.y + r * 0.4)
			Ink.line(p, a, a + Vector2(rng.randf_range(-1.0, 1.0), -r * rng.randf_range(0.6, 1.0)), clampf(r * 0.3, 1.2, 3.5), Color("#4e4038"), 1.0, 0.3)
	for c: Vector3 in [Vector3(-3.5, 0.0, 7.0), Vector3(4.0, 0.0, 10.0)]:
		Kit.skull(p, room, c, 0.1, Color("#9a8a72"))
