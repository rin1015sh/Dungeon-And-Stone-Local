extends RefCounted
## 전투 뒷그림 — 핏빛성채 4장 내성벽 지하 감옥: 낮은 아치 천장 복도 양옆으로 창살 감방이 줄지어 있다.
## 젖은 판석과 가운데 배수 홈, 벽의 족쇄 사슬, 깜빡이는 횃불 하나, 감방 안에서 떠도는 푸른 영체 빛.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")

const HW := 3.0
const CH := 4.2
const CELL := 3.0       ## 감방 한 칸 길이(z)
const CELL0 := 2.0
const DEPTH := 2.2      ## 감방 깊이(창살 뒤로)
const STONE := Color("#4e4640")
const TORCH := Vector3(-2.7, 2.4, 8.0)
const WISP: Array[Vector3] = [Vector3(4.2, 1.6, 11.5), Vector3(-4.0, 2.0, 17.2), Vector3(0.6, 2.6, 22.0)]


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.profile = "vault"
	room.spring = 0.65
	room.z_end = 30.0
	room.fog_k = 0.11
	room.fog_c = Color("#0a0808")
	room.ambient = Color(0.11, 0.1, 0.11)
	var side := func(z: float) -> float:
		var t := fposmod(z - CELL0, CELL) / CELL
		return HW + DEPTH * (smoothstep(0.08, 0.1, t) * (1.0 - smoothstep(0.9, 0.92, t)))
	room.shape(side, side, func(_z: float) -> float: return CH)
	room.lights = [
		{"p": TORCH, "c": Color("#ff9a50"), "s": 3.0, "r": 3.0},
		{"p": Vector3(0.0, 3.5, 4.0), "c": Color("#8a7a70"), "s": 0.5, "r": 4.0},
	]
	for wp in WISP:
		room.lights.append({"p": wp, "c": Color("#7ab0ff"), "s": 1.2, "r": 1.8})
	room.material = func(kind: int, P: Vector3, N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				if absf(P.x) < 0.1:  # 배수 홈
					return Kit2.water(m, P, Color("#2a2420"), Color("#8a7a6a"), 0.6)
				var d := m.flags(P.x + 20.0, P.z, 0.7, STONE.darkened(0.15), Color("#141010"), 0.3)
				var wet := smoothstep(0.5, 0.7, m.nz("lo", P.x * 0.8, P.z * 0.5))
				d["c"] = (d["c"] as Color).darkened(wet * 0.3)
				d["spec"] = 0.2 + wet * 0.6
				if absf(P.x) > HW + 0.05:  # 감방 바닥 = 짚·흙
					d["c"] = m.vary(Color("#3a3024"), P.x * 3.0, P.z * 3.0, 0.3)
					d["spec"] = 0.0
				return d
			Room.END:
				return {"c": Color("#100c0c")}
			_:
				if N.y < -0.5:
					return m.courses(P.z, P.x * 1.4 + 9.0, 0.6, 0.28, STONE.darkened(0.3), Color("#141010"), 0.3, 0.025)
				var d := m.courses(P.z, P.y, 0.55, 0.3, STONE, Color("#1a1412"), 0.4, 0.028)
				var moss := smoothstep(0.55, 0.8, m.nz("lo", P.z * 1.2, P.y * 2.0)) * smoothstep(1.2, 0.0, P.y)
				d["c"] = (d["c"] as Color).lerp(Color("#2e3424"), moss * 0.7).darkened(0.25 * smoothstep(1.0, 0.0, P.y))
				d["spec"] = 0.15
				return d
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.35, Color("#0a0808"))
	Kit.hatch_dark(p, 9000, 62.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 1.0)
	Kit.finish(p, Color("#100e10"), Color("#dcd0c0"), 0.28, 0.65)
	Kit.flame(p, room, TORCH, 0.5)
	for wp in WISP:
		Kit2.wisp(p, room, wp, 0.12, Color("#8ab8ff"))
	return p


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var cells: Array[float] = []
	var z := CELL0
	while z < 28.0:
		cells.append(z)
		z += CELL
	cells.reverse()
	var iron := Color("#3a3634")
	for cz in cells:
		for s: float in [-1.0, 1.0]:  # 감방 창살(복도 쪽 면) + 문 경첩
			Kit2.bars(p, room, s * (HW + 0.02), cz + 0.25, cz + CELL - 0.25, 0.0, CH * 0.65, 0.22, iron)
		var rz := cz + CELL * 0.5
		if rz < 20.0:  # 감방 안 족쇄
			var sx := -1.0 if int(cz) % 2 == 0 else 1.0
			Kit.chain(p, room, Vector3(sx * (HW + DEPTH - 0.05), 2.4, rz - 0.4), 1.1, 0.05)
			Kit.chain(p, room, Vector3(sx * (HW + DEPTH - 0.05), 2.4, rz + 0.4), 1.0, 0.05)
	# 횃불 받침
	var arm := Kit.proj(room, [TORCH + Vector3(-0.3, -0.35, 0.0), TORCH + Vector3(0, -0.25, 0)])
	Ink.line(p, arm[0], arm[1], room.px(0.06, TORCH.z), Color("#1e1a16"), 1.0, 0.2)
	Kit.box(p, room, TORCH - Vector3(0, 0.45, 0), Vector3(0.14, 0.4, 0.14), func(_P: Vector3) -> Color: return Color("#3a2a1c"), 0.0, 0.8)
	for c: Vector3 in [Vector3(1.6, 0.0, 5.5), Vector3(-1.9, 0.0, 12.0)]:
		Kit.skull(p, room, c, 0.1, Color("#9a8a72"))
	for k in 5:  # 쥐 똥·짚 부스러기
		var q := room.pt(p.rng.randf_range(-2.5, 2.5), 0.01, p.rng.randf_range(3.0, 9.0))
		Ink.line(p, q, q + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-2, 2)), 1.6, Color("#6a5a3a"), 0.7, 0.4)
