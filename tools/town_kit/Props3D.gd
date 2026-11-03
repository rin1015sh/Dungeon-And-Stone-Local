extends RefCounted
## 동네 거리 소품을 3D로 짓는다(사용자 2026-11-03 "소품 전체적으로 교체 · 3d 느낌 나게", CT99) — 집 키트(Kit)와 같은 면 그림 붓으로.
## tools/paint_town_props.gd가 3/4로 찍어 손그림 마감 → assets/town/props/<kind>.webp(TownProp이 발 = 아래 가운데로 그린다).
## 좌표: 칸(X 동, Y 위, Z 남), 발자리 가운데가 원점. KINDS = 굽는 소품.

const Kit := preload("res://tools/town_kit/Kit.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")

const KINDS := ["lamp", "tent", "board", "barrel", "crate", "sacks", "well", "grave", "stall", "cart", "bench", "planter", "fountain", "laundry", "dais"]
const WOOD := Color("#5a4030")
const DARK_WOOD := Color("#3b2a1e")
const IRON := Color("#26221f")
const STONE := Color("#7a756b")
const CLOTH := Color("#8a7a62")
const RED := Color("#7a3028")
const BLUE := Color("#3a4a66")


static func build(kind: String, k: Kit) -> void:
	match kind:
		"lamp": _lamp(k)
		"tent": _tent(k)
		"board": _board(k)
		"barrel": _barrel(k, 0.0, 0.0, 1.0)
		"crate": _crate(k, 0.0, 0.0, 0.72)
		"sacks": _sacks(k)
		"well": _well(k)
		"grave": _grave(k)
		"stall": _stall(k)
		"cart": _cart(k)
		"bench": _bench(k)
		"planter": _planter(k)
		"fountain": _fountain(k)
		"laundry": _laundry(k)
		"dais": _dais(k)


# ---------- 붓 ----------

static func paint(c: Color, mat: String = "", ink: float = 1.2) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		match mat:
			"wood":
				p.fill_poly(poly, Mat.planks(p, c, 0, 0, false, 9))
			"vwood":
				p.fill_poly(poly, Mat.planks(p, c, 0, 0, true, 9))
			"stone":
				p.fill_poly(poly, Mat.ashlar(p, c, 0, 0, 30, 15))
			"rubble":
				p.fill_poly(poly, Mat.rubble(p, c))
			_:
				p.fill_poly(poly, p.flat(c, 0.08))
		if ink > 0.0:
			Ink.path(p, poly, ink)


static func stripes(a: Color, b: Color) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, func(x: int, _y: int) -> Color: return (a if posmod(x, 22) < 11 else b).darkened(0.04 * float(posmod(x, 11)) / 11.0))
		Ink.path(p, poly, 1.2)


static func glow() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, p.flat(Color("#f0b860"), 0.12))
		Ink.path(p, poly, 1.2)


static func papers() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, size: Vector2) -> void:
		p.fill_poly(poly, Mat.planks(p, WOOD, 0, 0, false, 9))
		var r := Paint.bounds(poly)
		for i in 5:  # 붙은 쪽지
			var w := r.size.x * 0.16
			var x := r.position.x + r.size.x * (0.08 + i * 0.18)
			var y := r.position.y + r.size.y * (0.15 + 0.12 * (i % 2))
			var q := Paint.rect_poly(x, y, w, r.size.y * 0.5)
			p.fill_poly(q, p.flat(Color("#d8cfb8").darkened(0.08 * (i % 3)), 0.05))
			Ink.path(p, q, 0.8)
		Ink.path(p, poly, 1.2)


# ---------- 조각 ----------

## 둥근 기둥(통 · 우물 · 분수): 옆 + 윗면(낮은 원뿔).
static func cyl(k: Kit, cx: float, cz: float, r: float, y0: float, y1: float, side: Callable, top: Callable, segs: int = 14) -> void:
	k.cylinder(cx, cz, r, y0, y1, segs, func(_i: int) -> Callable: return side)
	var cap := PackedVector3Array()  # 윗면은 한 장(조각마다 먹선이 바퀴살처럼 보이지 않게)
	for i in segs:
		var a := TAU * i / segs
		cap.append(Vector3(cx + cos(a) * r, y1, cz + sin(a) * r))
	k.face(cap, Vector3.UP, top)


## 앞(남)을 보는 납작한 판(바퀴 · 고리) — 꼭짓점 (x, y) 목록, 깊이 z.
static func plate(k: Kit, pts2: Array, z: float, painter: Callable) -> void:
	var pts := PackedVector3Array()
	for q: Vector2 in pts2:
		pts.append(Vector3(q.x, q.y, z))
	k.face(pts, Vector3.BACK, painter)


static func _lamp(k: Kit) -> void:
	k.box(-0.18, -0.18, 0.18, 0.18, 0.0, 0.18, {"top": paint(STONE)}, paint(STONE, "stone"))
	k.box(-0.06, -0.06, 0.06, 0.06, 0.18, 2.3, {}, paint(IRON))
	k.box(-0.06, -0.06, 0.32, 0.06, 2.2, 2.28, {}, paint(IRON))  # 팔
	k.box(0.14, -0.14, 0.44, 0.14, 1.78, 2.16, {"top": paint(IRON)}, glow())
	k.pyramid(0.12, -0.16, 0.46, 0.16, 2.16, 0.22, 0.03, paint(IRON))


static func _tent(k: Kit) -> void:
	for x: float in [-1.6, 1.6]:
		for z: float in [-0.8, 0.8]:
			k.box(x - 0.05, z - 0.05, x + 0.05, z + 0.05, 0.0, 1.6, {}, paint(DARK_WOOD))
	k.gable_roof(-1.6, -0.8, 1.6, 0.8, 1.6, 0.7, true, 0.15, stripes(RED, Color("#c8b890")), stripes(RED, Color("#c8b890")))
	k.box(-1.1, 0.0, 1.1, 0.6, 0.0, 0.8, {"top": paint(WOOD, "wood")}, paint(DARK_WOOD, "vwood"))
	k.box(-0.3, 0.15, 0.3, 0.45, 0.8, 0.95, {"top": paint(Color("#b08a40"))}, paint(Color("#8a6a30")))  # 저울


static func _board(k: Kit) -> void:
	for x: float in [-0.85, 0.85]:
		k.box(x - 0.07, -0.07, x + 0.07, 0.07, 0.0, 1.9, {}, paint(DARK_WOOD))
	k.box(-0.95, -0.06, 0.95, 0.06, 0.7, 1.75, {"s": papers()}, paint(WOOD, "wood"))
	k.gable_roof(-1.05, -0.2, 1.05, 0.2, 1.85, 0.22, true, 0.05, paint(DARK_WOOD, "wood"), paint(DARK_WOOD))


static func _barrel(k: Kit, cx: float, cz: float, s: float) -> void:
	var hoop := func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, Mat.planks(p, Color("#6a4a32"), 0, 0, true, 7))
		var r := Paint.bounds(poly)
		for t: float in [0.18, 0.8]:
			var q := Paint.rect_poly(r.position.x, r.position.y + r.size.y * t, r.size.x, 3)
			p.fill_poly(q, p.flat(IRON, 0.05))
		Ink.path(p, poly, 1.0)
	cyl(k, cx, cz, 0.34 * s, 0.0, 0.85 * s, hoop, paint(Color("#5e4230"), "wood"), 12)


static func _crate(k: Kit, cx: float, cz: float, s: float) -> void:
	var h := s * 0.5
	k.box(cx - h, cz - h, cx + h, cz + h, 0.0, s * 0.85, {"top": paint(Color("#7a5a3a"), "wood")}, paint(Color("#6e5034"), "wood"))


static func _sacks(k: Kit) -> void:
	for q: Vector3 in [Vector3(-0.25, 0.0, 0.1), Vector3(0.25, 0.0, 0.05), Vector3(0.0, 0.5, -0.05)]:
		cyl(k, q.x, q.z, 0.26, q.y, q.y + 0.5, paint(CLOTH, "rubble", 0.8), paint(CLOTH.lightened(0.1), "", 0.8), 9)


static func _well(k: Kit) -> void:
	cyl(k, 0.0, 0.0, 0.72, 0.0, 0.75, paint(STONE, "stone"), paint(Color("#1c2226")), 16)
	for x: float in [-0.62, 0.62]:
		k.box(x - 0.06, -0.06, x + 0.06, 0.06, 0.75, 1.9, {}, paint(DARK_WOOD))
	k.box(-0.62, -0.03, 0.62, 0.03, 1.55, 1.6, {}, paint(DARK_WOOD))  # 도르래 축
	k.gable_roof(-0.85, -0.45, 0.85, 0.45, 1.9, 0.45, true, 0.1, paint(Color("#4a3a2e"), "wood"), paint(DARK_WOOD))
	_barrel(k, 0.5, 0.55, 0.5)  # 두레박


static func _grave(k: Kit) -> void:
	k.box(-0.25, -0.08, 0.25, 0.08, 0.0, 0.62, {"top": paint(STONE)}, paint(STONE, "stone"))
	k.pyramid(-0.25, -0.08, 0.25, 0.08, 0.62, 0.15, 0.0, paint(STONE))


static func _stall(k: Kit) -> void:
	k.box(-0.95, -0.2, 0.95, 0.35, 0.0, 0.7, {"top": paint(WOOD, "wood")}, paint(DARK_WOOD, "vwood"))
	for i in 5:  # 물건(과일 바구니 · 천 · 단지)
		var x := -0.75 + i * 0.37
		var c: Color = [Color("#8a3a2a"), Color("#b08a40"), Color("#4a6a3a"), Color("#c8b890"), Color("#6a4a7a")][i]
		k.box(x - 0.13, -0.05, x + 0.13, 0.2, 0.7, 0.86, {"top": paint(c.lightened(0.12), "", 0.8)}, paint(c, "", 0.8))
	for x: float in [-1.0, 1.0]:
		for z: float in [-0.3, 0.45]:
			k.box(x - 0.04, z - 0.04, x + 0.04, z + 0.04, 0.0, 1.6 if z < 0 else 1.35, {}, paint(DARK_WOOD))
	k.shed_roof(-1.0, -0.3, 1.0, 0.45, 1.35, 1.6, 0.15, stripes(Color("#6e3a32"), Color("#c8b890")), paint(Color("#6e3a32")))


static func _cart(k: Kit) -> void:
	k.box(-0.8, -0.32, 0.6, 0.32, 0.38, 0.62, {"top": paint(WOOD, "wood")}, paint(Color("#6e5034"), "wood"))
	for x: float in [-0.8, 0.6]:  # 옆판
		k.box(x - 0.03, -0.32, x + 0.03, 0.32, 0.62, 0.85, {}, paint(DARK_WOOD, "wood"))
	k.box(-0.8, 0.29, 0.6, 0.32, 0.62, 0.85, {}, paint(DARK_WOOD, "wood"))
	_sacks_on(k, -0.3, 0.62)
	k.box(0.6, -0.04, 1.2, 0.04, 0.42, 0.5, {}, paint(DARK_WOOD))  # 손잡이
	var wheel := []
	for i in 12:
		var a := TAU * i / 12.0
		wheel.append(Vector2(-0.1 + cos(a) * 0.38, 0.38 + sin(a) * 0.38))
	plate(k, wheel, 0.34, paint(Color("#4a3424"), "vwood", 1.4))


static func _sacks_on(k: Kit, x: float, y: float) -> void:
	cyl(k, x, 0.0, 0.2, y, y + 0.38, paint(CLOTH, "rubble", 0.8), paint(CLOTH.lightened(0.1), "", 0.8), 9)
	cyl(k, x + 0.4, 0.05, 0.18, y, y + 0.34, paint(CLOTH.darkened(0.1), "rubble", 0.8), paint(CLOTH, "", 0.8), 9)


static func _bench(k: Kit) -> void:
	k.box(-0.9, -0.15, 0.9, 0.2, 0.42, 0.5, {"top": paint(WOOD, "wood")}, paint(DARK_WOOD, "wood"))
	k.box(-0.9, -0.2, 0.9, -0.12, 0.5, 0.95, {}, paint(WOOD, "wood"))  # 등받이
	for x: float in [-0.75, 0.75]:
		k.box(x - 0.05, -0.15, x + 0.05, 0.2, 0.0, 0.42, {}, paint(IRON))


static func _planter(k: Kit) -> void:
	k.box(-0.42, -0.3, 0.42, 0.3, 0.0, 0.45, {"top": paint(Color("#3a2c22"))}, paint(Color("#6e5034"), "wood"))
	for q: Vector3 in [Vector3(-0.2, 0.0, 0.0), Vector3(0.2, 0.0, 0.05), Vector3(0.0, 0.0, -0.1)]:
		k.cone(q.x, q.z, 0.24, 0.45, 0.45, 8, paint(Color("#4e6a3a"), "rubble", 0.8))
	for q: Vector2 in [Vector2(-0.22, 0.12), Vector2(0.18, 0.15), Vector2(0.02, -0.05)]:
		k.box(q.x - 0.05, q.y - 0.05, q.x + 0.05, q.y + 0.05, 0.62, 0.72, {"top": paint(Color("#b04a3a"), "", 0.6)}, paint(Color("#9a3a2e"), "", 0.6))


static func _fountain(k: Kit) -> void:
	cyl(k, 0.0, 0.0, 0.95, 0.0, 0.5, paint(STONE, "stone"), paint(Color("#3e5a62")), 20)
	cyl(k, 0.0, 0.0, 0.16, 0.5, 1.25, paint(STONE.lightened(0.1), "stone"), paint(STONE), 10)
	cyl(k, 0.0, 0.0, 0.45, 1.25, 1.4, paint(STONE.lightened(0.1), "stone"), paint(Color("#4a6a72")), 14)
	cyl(k, 0.0, 0.0, 0.08, 1.4, 1.75, paint(STONE.lightened(0.15)), paint(STONE), 8)


static func _laundry(k: Kit) -> void:
	for x: float in [-1.1, 1.1]:
		k.box(x - 0.05, -0.05, x + 0.05, 0.05, 0.0, 1.8, {}, paint(DARK_WOOD))
	k.box(-1.1, -0.01, 1.1, 0.01, 1.7, 1.73, {}, paint(IRON, "", 0.0))
	var cols := [Color("#c8bea8"), Color("#8a7a62"), Color("#6e3a32"), Color("#a9a08c"), Color("#4a5a6e")]
	for i in 5:
		var x := -0.85 + i * 0.42
		var h := 0.5 + 0.15 * (i % 2)
		k.box(x - 0.16, -0.01, x + 0.16, 0.01, 1.7 - h, 1.7, {}, paint(cols[i], "", 0.8))


static func _dais(k: Kit) -> void:
	for i in 3:  # 세 단 돌 단
		cyl(k, 0.0, 0.0, 3.4 - 0.65 * i, 0.3 * i, 0.3 * (i + 1), paint(STONE.darkened(0.12 + 0.05 * i), "stone"), paint(Color("#857d6c").darkened(0.05 * i), "rubble"), 32)  # 어두운 바닥에 맞춰(CT101)
	var y0 := 0.9
	var r1 := 1.95
	var r0 := 1.5
	for i in 24:  # 선 돌 고리(앞에서 본 고리 조각 — 꺼진 포탈)
		var a0 := TAU * i / 24.0
		var a1 := TAU * (i + 1) / 24.0
		var c := Vector2(0, y0 + r1)
		plate(k, [c + Vector2(cos(a0), sin(a0)) * r1, c + Vector2(cos(a1), sin(a1)) * r1, c + Vector2(cos(a1), sin(a1)) * r0, c + Vector2(cos(a0), sin(a0)) * r0],
			0.15, paint(Color("#8a8476"), "stone", 0.8))
		plate(k, [c + Vector2(cos(a0), sin(a0)) * r1, c + Vector2(cos(a1), sin(a1)) * r1, c + Vector2(cos(a1), sin(a1)) * r0, c + Vector2(cos(a0), sin(a0)) * r0],
			-0.15, paint(Color("#6e695e"), "stone", 0.8))
	k.box(-0.9, -0.3, 0.9, 0.3, y0 - 0.05, y0 + 0.12, {"top": paint(STONE)}, paint(STONE, "stone"))  # 고리 받침
