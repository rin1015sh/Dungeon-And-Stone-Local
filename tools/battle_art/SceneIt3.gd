extends RefCounted
## 전투 뒷그림 — 강철의 묘 3장 수수께끼 문 앞: 묘실로 가는 마지막 복도. 양옆 벽감마다 창을 세운 강철 수호상,
## 끝을 막은 거대한 문에는 고리가 겹친 수수께끼 문양이 금빛으로 새겨져 있고, 문 양옆 화로에 푸른 불꽃.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")
const Kit2 := preload("res://tools/battle_art/Kit2.gd")
const Tomb := preload("res://tools/battle_art/SceneTomb.gd")

const HW := 3.2
const CH := 6.0
const DOOR_Z := 19.0
const NICHE := 3.4     ## 벽감 간격
const NICHE0 := 4.0
const STEEL := Color("#5e626c")
const GOLD := Color("#c8a050")
const FIRE: Array[Vector3] = [Vector3(-2.2, 1.3, 18.2), Vector3(2.2, 1.3, 18.2)]
const BLUE := Color("#6aa8ff")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var m := Mats.new(seed_value)
	var room := Room.new(w, h)
	room.f = 900.0
	room.hy = 250.0
	room.z_end = DOOR_Z
	room.fog_k = 0.07
	room.fog_c = Color("#09090c")
	room.ambient = Color(0.09, 0.09, 0.11)
	var side := func(z: float) -> float:
		var t := fposmod(z - NICHE0 + 0.7, NICHE) / NICHE
		return HW + (0.8 if t < 1.4 / NICHE else 0.0)
	room.shape(side, side, func(_z: float) -> float: return CH)
	room.lights = [{"p": Vector3(0.0, 4.5, 8.0), "c": Color("#a8b8d8"), "s": 1.0, "r": 6.0}]
	for f in FIRE:
		room.lights.append({"p": f + Vector3(0, 0.4, 0), "c": BLUE, "s": 2.6, "r": 3.2})
	room.material = func(kind: int, P: Vector3, _N: Vector3) -> Dictionary:
		match kind:
			Room.FLOOR:
				var d := m.plates(P.x + 20.0, P.z, 1.0, 1.0, STEEL.darkened(0.3))
				if absf(P.x) < 1.2:  # 가운데 길 = 닳은 판
					d["c"] = (d["c"] as Color).lightened(0.08)
					d["spec"] = 0.5
				return d
			Room.CEIL:
				return m.plates(P.x + 10.0, P.z, 1.2, 1.6, STEEL.darkened(0.5))
			Room.END:
				return _door(m, P)
			_:
				if P.y > 1.7 and P.y < 2.7 and absf(P.x) <= HW + 0.05:
					return Tomb._mural(m, P.z, P.y)
				var d := m.plates(P.z, P.y, 1.3, 0.85, STEEL)
				if absf(P.x) > HW + 0.05:  # 벽감 안 = 더 어둡게
					d["c"] = (d["c"] as Color).darkened(0.35)
				return d
	room.render(p)
	_props(p, room, m)
	Kit.grime(p, 0.28, Color("#0a0a0c"))
	Kit.hatch_dark(p, 9000, 64.0, 0.03, 0.14, 0.35)
	Kit.brush(p, 0.9)
	Kit.finish(p, Color("#101014"), Color("#e4e4e0"), 0.3, 0.62)
	for f in FIRE:
		_blue_fire(p, room, f)
	var seal := room.pt(0.0, 3.0, DOOR_Z)
	Ink.glow(p, seal.x, seal.y, room.px(1.8, DOOR_Z), GOLD, 0.16, false)
	return p


## 수수께끼 문: 두 짝 쇠문 + 겹친 고리 셋(칸마다 새긴 기호) — 금빛 홈.
static func _door(m: Mats, P: Vector3) -> Dictionary:
	var d := m.plates(P.x + 5.0, P.y, 0.8, 0.8, STEEL.darkened(0.15))
	if absf(P.x) > 2.6 or P.y > 5.6:
		d["c"] = (d["c"] as Color).darkened(0.45)
		return d
	var v := Vector2(P.x, P.y - 3.0)
	var r := v.length()
	var a := fposmod(v.angle(), TAU)
	for ring: float in [0.7, 1.3, 1.9]:
		if absf(r - ring) < 0.04:
			return {"c": GOLD, "emit": Color(0.25, 0.18, 0.06), "spec": 0.6}
	if r < 1.9:
		var seg := 8 if r > 1.3 else (6 if r > 0.7 else 4)
		var f := fposmod(a / TAU * seg, 1.0)
		if f < 0.02 or f > 0.98:
			return {"c": GOLD.darkened(0.2), "emit": Color(0.15, 0.1, 0.03), "spec": 0.5}
		var glyph := Paint.hash01(int(a / TAU * seg), int(r * 3.0), 5)
		if absf(f - 0.5) < 0.12 and absf(fposmod(r * 3.0, 1.0) - 0.5) < 0.15 * glyph + 0.05:
			return {"c": GOLD.darkened(0.1), "emit": Color(0.2, 0.14, 0.04), "spec": 0.5}
	if absf(P.x) < 0.03:
		d["ink"] = 0.8
	return d


static func _props(p: Paint, room: Room, m: Mats) -> void:
	var steel := func(P: Vector3) -> Color: return m.vary(STEEL.darkened(0.05), P.y * 3.0, P.z * 3.0 + P.x, 0.22)
	var dark := func(P: Vector3) -> Color: return m.vary(Color("#3a3c42"), P.y * 3.0, P.z * 3.0, 0.2)
	var zs: Array[float] = []
	var z := NICHE0
	while z < DOOR_Z - 1.0:
		zs.append(z)
		z += NICHE
	zs.reverse()
	for nz in zs:  # 벽감의 창 든 수호상
		for s: float in [-1.0, 1.0]:
			var x := s * (HW + 0.4)
			Kit.box(p, room, Vector3(x, 0.0, nz), Vector3(0.7, 0.4, 0.6), dark, 0.3, 1.0)
			Kit.box(p, room, Vector3(x, 0.4, nz), Vector3(0.55, 1.5, 0.4), steel, 0.5, 1.0)
			Kit.box(p, room, Vector3(x, 1.9, nz), Vector3(0.75, 0.45, 0.45), steel, 0.5, 1.0)
			Kit.box(p, room, Vector3(x, 2.35, nz), Vector3(0.36, 0.42, 0.36), steel, 0.5, 1.0)
			var spear := Kit.proj(room, [Vector3(x - s * 0.45, 0.4, nz - 0.25), Vector3(x - s * 0.45, 4.2, nz - 0.25)])
			Ink.line(p, spear[0], spear[1], clampf(room.px(0.05, nz), 1.0, 5.0), room.lit(Vector3(x, 2.0, nz), Vector3(-s, 0, -1).normalized(), Color("#6a6c70")), 1.0, 0.1)
			var tip := Kit.proj(room, [Vector3(x - s * 0.45, 4.2, nz - 0.25), Vector3(x - s * 0.45 - 0.1, 3.9, nz - 0.25), Vector3(x - s * 0.45, 4.6, nz - 0.25), Vector3(x - s * 0.45 + 0.1, 3.9, nz - 0.25)])
			p.fill_poly(tip, p.flat(room.lit(Vector3(x, 4.2, nz), Vector3(-s, 0, -1).normalized(), Color("#8a8c90"), 0.6), 0.1))
			var visor := room.pt(x, 2.55, nz - 0.19)
			var vr := room.px(0.12, nz)
			p.fill_rect(visor.x - vr, visor.y - vr * 0.15, vr * 2.0, vr * 0.3, p.flat(Color("#0a0a0c"), 0.05))
	for f in FIRE:  # 화로 받침
		Kit.box(p, room, Vector3(f.x, 0.0, f.z), Vector3(0.25, f.y - 0.2, 0.25), dark, 0.3, 1.0)
		Kit.box(p, room, Vector3(f.x, f.y - 0.25, f.z), Vector3(0.7, 0.3, 0.7), steel, 0.4, 1.0)


## 푸른 불꽃(색 보정 뒤).
static func _blue_fire(p: Paint, room: Room, at: Vector3) -> void:
	var c := room.pt(at.x, at.y + 0.05, at.z)
	var s := room.px(0.7, at.z)
	Ink.glow(p, c.x, c.y - s * 0.3, s * 4.0, BLUE, 0.5, false)
	for layer in 3:
		var col: Color = [Color("#2a4aa0"), Color("#5a9aff"), Color("#d8ecff")][layer]
		var fh := s * (1.0 - layer * 0.25)
		var fw := s * 0.34 * (1.0 - layer * 0.25)
		p.fill_poly(Paint.poly([c + Vector2(-fw, 0), c + Vector2(-fw * 0.5, -fh * 0.6), c + Vector2(0, -fh), c + Vector2(fw * 0.5, -fh * 0.55), c + Vector2(fw, 0)]), p.flat(col, 0.1))
