extends RefCounted
## 동네 장식 소품(사용자 2026-11-03 "도시에 있을 법한 장식 요소 그려서 넣어 줘", CT101) — Props3D와 같은 붓 · 같은 3/4 굽기.
## 나무 · 덤불 · 장작더미 · 물구유 · 이정표 · 석상 · 돌말뚝 · 깃발 · 짐더미. tools/paint_town_props.gd가 Props3D.KINDS와 함께 굽는다.
## 잎 덩이는 면마다 먹선이 생기지 않게 한 덩이를 한 묶음(gid)으로 — paint_town_props._ids가 같은 면 번호를 준다.

const Kit := preload("res://tools/town_kit/Kit.gd")
const Props3D := preload("res://tools/town_kit/Props3D.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")

const KINDS := ["tree", "bush", "woodpile", "trough", "signpost", "statue", "bollard", "banner", "goods"]
const BARK := Color("#4a3628")
const LEAF := [Color("#3c4a2a"), Color("#46532e"), Color("#36422a"), Color("#4e5a32")]
const BRONZE := Color("#4c5a4a")
const STONE := Color("#77726a")

static var _gid := 0


static func build(kind: String, k: Kit) -> void:
	match kind:
		"tree": _tree(k)
		"bush": _bush(k)
		"woodpile": _woodpile(k)
		"trough": _trough(k)
		"signpost": _signpost(k)
		"statue": _statue(k)
		"bollard": _bollard(k)
		"banner": _banner(k)
		"goods": _goods(k)


## 잎 붓: 짙은 초록 잎 무늬(먹선 없이 — 덩이 둘레만 손그림 마감이 긋는다).
static func leaves(c: Color) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, Mat.rubble(p, c, c.darkened(0.35)))


## 둥근 덩이(잎 · 머리): 위도 띠 면. 바닥 쪽은 보이지 않아 생략. 한 덩이 = 한 묶음.
static func blob(k: Kit, c: Vector3, r: Vector3, painter: Callable, segs: int = 9, rings: int = 5) -> void:
	_gid += 1
	var n0 := k.root.get_child_count()
	for j in rings:
		var t0 := -0.35 * PI + (0.85 * PI) * j / rings
		var t1 := -0.35 * PI + (0.85 * PI) * (j + 1) / rings
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var q := PackedVector3Array()
			for ta: Vector2 in [Vector2(t0, a0), Vector2(t0, a1), Vector2(t1, a1), Vector2(t1, a0)]:
				q.append(c + Vector3(cos(ta.x) * cos(ta.y) * r.x, sin(ta.x) * r.y, cos(ta.x) * sin(ta.y) * r.z))
			var mid := (q[0] + q[2]) * 0.5 - c
			k.face(q, mid, painter)
	var cap := PackedVector3Array()  # 꼭대기
	var tt := -0.35 * PI + 0.85 * PI
	for i in segs:
		var a := TAU * i / segs
		cap.append(c + Vector3(cos(tt) * cos(a) * r.x, sin(tt) * r.y, cos(tt) * sin(a) * r.z))
	k.face(cap, Vector3.UP, painter)
	for i in range(n0, k.root.get_child_count()):
		k.root.get_child(i).set_meta("gid", _gid)


static func _tree(k: Kit) -> void:
	Props3D.cyl(k, 0.0, 0.0, 0.17, 0.0, 1.7, Props3D.paint(BARK, "vwood"), Props3D.paint(BARK), 8)
	k.box(-0.55, -0.04, 0.0, 0.04, 1.45, 1.53, {}, Props3D.paint(BARK))  # 가지
	k.box(0.0, -0.04, 0.5, 0.04, 1.6, 1.68, {}, Props3D.paint(BARK))
	var clumps := [[Vector3(0.0, 2.55, 0.0), Vector3(1.15, 0.9, 1.1), 0], [Vector3(-0.75, 2.2, 0.25), Vector3(0.75, 0.62, 0.7), 1],
		[Vector3(0.8, 2.25, 0.15), Vector3(0.75, 0.62, 0.7), 2], [Vector3(0.1, 3.15, -0.1), Vector3(0.8, 0.6, 0.75), 3], [Vector3(-0.15, 2.0, 0.65), Vector3(0.6, 0.5, 0.5), 1]]
	for cl: Array in clumps:
		blob(k, cl[0], cl[1], leaves(LEAF[int(cl[2])]))


static func _bush(k: Kit) -> void:
	for cl: Array in [[Vector3(-0.3, 0.38, 0.0), Vector3(0.5, 0.42, 0.45), 0], [Vector3(0.35, 0.35, 0.05), Vector3(0.45, 0.38, 0.42), 2], [Vector3(0.0, 0.62, -0.1), Vector3(0.45, 0.38, 0.4), 3]]:
		blob(k, cl[0], cl[1], leaves(LEAF[int(cl[2])]), 8, 4)


## 장작더미: 쌓은 통나무(앞면 = 나이테 동그라미) + 작은 판자 지붕.
static func _woodpile(k: Kit) -> void:
	k.box(-0.9, -0.3, 0.9, 0.3, 0.0, 0.85, {"top": Props3D.paint(BARK, "wood")}, Props3D.paint(Color("#5a4232"), "vwood"))
	var ends := func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, p.flat(Color("#a8865a"), 0.12))
		Ink.path(p, poly, 1.0)
	for row in 3:
		for i in 6 - (row % 2):
			var x := -0.75 + i * 0.3 + (row % 2) * 0.15
			var y := 0.15 + row * 0.27
			var ring := []
			for s in 9:
				var a := TAU * s / 9.0
				ring.append(Vector2(x + cos(a) * 0.13, y + sin(a) * 0.13))
			Props3D.plate(k, ring, 0.31, ends)
	k.shed_roof(-1.0, -0.4, 1.0, 0.45, 1.05, 1.25, 0.08, Props3D.paint(Color("#4a3a2e"), "wood"), Props3D.paint(Props3D.DARK_WOOD))
	for x: float in [-0.95, 0.95]:
		k.box(x - 0.04, 0.38, x + 0.04, 0.45, 0.0, 1.05, {}, Props3D.paint(Props3D.DARK_WOOD))


static func _trough(k: Kit) -> void:
	k.box(-0.85, -0.32, 0.85, 0.32, 0.0, 0.55, {"top": Props3D.paint(Color("#2c3a40"))}, Props3D.paint(STONE, "stone"))
	k.box(-0.85, -0.32, 0.85, -0.24, 0.55, 0.62, {}, Props3D.paint(STONE))  # 뒷전
	k.box(-0.85, 0.24, 0.85, 0.32, 0.55, 0.62, {}, Props3D.paint(STONE))  # 앞전
	k.box(0.7, -0.08, 0.86, 0.08, 0.55, 1.15, {"top": Props3D.paint(Props3D.IRON)}, Props3D.paint(Props3D.IRON))  # 물 꼭지


static func _signpost(k: Kit) -> void:
	k.box(-0.06, -0.06, 0.06, 0.06, 0.0, 2.15, {"top": Props3D.paint(Props3D.DARK_WOOD)}, Props3D.paint(Props3D.DARK_WOOD, "vwood"))
	var board := Props3D.paint(Color("#7a5a3a"), "wood")
	Props3D.plate(k, [Vector2(0.06, 1.62), Vector2(0.78, 1.62), Vector2(0.92, 1.73), Vector2(0.78, 1.84), Vector2(0.06, 1.84)], 0.07, board)
	Props3D.plate(k, [Vector2(-0.06, 1.3), Vector2(-0.74, 1.3), Vector2(-0.88, 1.41), Vector2(-0.74, 1.52), Vector2(-0.06, 1.52)], 0.07, board)
	Props3D.plate(k, [Vector2(0.06, 1.0), Vector2(0.6, 1.0), Vector2(0.72, 1.1), Vector2(0.6, 1.2), Vector2(0.06, 1.2)], 0.07, Props3D.paint(Color("#6a4a30"), "wood"))
	k.pyramid(-0.1, -0.1, 0.1, 0.1, 2.15, 0.14, 0.02, Props3D.paint(Props3D.DARK_WOOD))


## 석상: 두 단 받침 + 망토 두른 탐험가(청동 — 녹이 앉은 초록빛)가 칼을 짚고 선다.
static func _statue(k: Kit) -> void:
	k.box(-0.75, -0.75, 0.75, 0.75, 0.0, 0.35, {"top": Props3D.paint(STONE)}, Props3D.paint(STONE, "stone"))
	k.box(-0.55, -0.55, 0.55, 0.55, 0.35, 1.25, {"top": Props3D.paint(STONE.lightened(0.05))}, Props3D.paint(STONE.lightened(0.05), "stone"))
	var br := Props3D.paint(BRONZE, "", 1.0)
	k.cone(0.0, 0.0, 0.42, 1.25, 1.5, 10, br)  # 망토 자락
	Props3D.cyl(k, 0.0, 0.0, 0.24, 1.25, 2.3, br, br, 10)  # 몸
	k.box(-0.36, -0.14, 0.36, 0.14, 2.15, 2.4, {"top": br}, br)  # 어깨
	blob(k, Vector3(0.0, 2.58, 0.02), Vector3(0.17, 0.2, 0.17), Props3D.paint(BRONZE.lightened(0.06), "", 0.0), 8, 4)  # 머리
	k.box(0.3, 0.05, 0.42, 0.2, 1.55, 2.25, {}, br)  # 오른팔
	k.box(0.38, 0.12, 0.44, 0.2, 0.6 + 0.65, 2.05, {}, Props3D.paint(Color("#6a7468")))  # 칼(짚은)
	k.box(0.3, 0.08, 0.52, 0.24, 2.0, 2.06, {}, br)  # 칼자루 막대


static func _bollard(k: Kit) -> void:
	Props3D.cyl(k, 0.0, 0.0, 0.17, 0.0, 0.62, Props3D.paint(STONE, "stone"), Props3D.paint(STONE.lightened(0.08)), 10)
	k.cone(0.0, 0.0, 0.19, 0.62, 0.14, 10, Props3D.paint(STONE.lightened(0.08)))


static func _banner(k: Kit) -> void:
	k.box(-0.06, -0.06, 0.06, 0.06, 0.0, 3.1, {"top": Props3D.paint(Props3D.IRON)}, Props3D.paint(Props3D.DARK_WOOD, "vwood"))
	k.box(-0.5, -0.04, 0.5, 0.04, 2.86, 2.94, {}, Props3D.paint(Props3D.DARK_WOOD))
	var cloth := func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, p.flat(Color("#6e2e28"), 0.1))
		var r := Paint.bounds(poly)
		var c := r.position + r.size * Vector2(0.5, 0.42)
		var ring := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			ring.append(c + Vector2(cos(a), sin(a)) * r.size.x * 0.24)
		p.fill_poly(ring, p.flat(Color("#b08a40"), 0.08))
		Ink.path(p, ring, 1.0)
		Ink.path(p, poly, 1.2)
	Props3D.plate(k, [Vector2(-0.46, 2.86), Vector2(0.46, 2.86), Vector2(0.46, 1.5), Vector2(0.0, 1.3), Vector2(-0.46, 1.5)], 0.07, cloth)
	k.box(-0.08, -0.08, 0.08, 0.08, 3.1, 3.22, {}, Props3D.paint(Color("#b08a40")))


## 짐더미(둑길 · 창고 앞): 상자 둘 쌓고 · 통 · 자루.
static func _goods(k: Kit) -> void:
	Props3D._crate(k, -0.5, 0.0, 0.7)
	k.box(-0.74, -0.22, -0.28, 0.22, 0.6, 1.0, {"top": Props3D.paint(Color("#7a5a3a"), "wood")}, Props3D.paint(Color("#6e5034"), "wood"))
	Props3D._barrel(k, 0.45, 0.0, 0.9)
	Props3D.cyl(k, 0.1, 0.38, 0.2, 0.0, 0.4, Props3D.paint(Props3D.CLOTH, "rubble", 0.8), Props3D.paint(Props3D.CLOTH.lightened(0.1), "", 0.8), 9)
