extends RefCounted
## 동네 장식 소품(사용자 2026-11-03 "도시에 있을 법한 장식 요소 그려서 넣어 줘", CT101) — Props3D와 같은 붓 · 같은 3/4 굽기.
## 나무 · 덤불 · 장작더미 · 물구유 · 이정표 · 석상 · 돌말뚝 · 깃발 · 짐더미. tools/paint_town_props.gd가 Props3D.KINDS와 함께 굽는다.
## 잎 덩이는 면마다 먹선이 생기지 않게 한 덩이를 한 묶음(gid)으로 — paint_town_props._ids가 같은 면 번호를 준다.

const Kit := preload("res://tools/town_kit/Kit.gd")
const Props3D := preload("res://tools/town_kit/Props3D.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")

const KINDS := ["tree", "bush", "woodpile", "trough", "signpost", "statue", "bollard", "banner", "goods",
	"sign", "walllamp", "wagon", "rail", "boat", "household", "anvil"]  # 3차 개선(CT103): 가게 간판 · 벽 등불 · 포장마차 · 부두 난간 · 거룻배 · 골목 살림
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
		"sign": _sign(k)
		"walllamp": _walllamp(k)
		"wagon": _wagon(k)
		"rail": _rail(k)
		"boat": _boat(k)
		"household": _household(k)
		"anvil": _anvil(k)


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


## 가게 간판: 벽에서 내민 쇠 팔 + 매단 나무 판(금 테 · 둥근 문장).
static func _sign(k: Kit) -> void:
	k.box(-0.05, -0.05, 0.05, 0.05, 0.0, 2.2, {"top": Props3D.paint(Props3D.IRON)}, Props3D.paint(Props3D.DARK_WOOD, "vwood"))
	k.box(-0.05, -0.04, 0.85, 0.04, 2.1, 2.17, {}, Props3D.paint(Props3D.IRON))
	var board := func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, Mat.planks(p, Color("#3e4a3a"), 0, 0, false, 8))
		var r := Paint.bounds(poly)
		var c := r.get_center()
		var ring := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			ring.append(c + Vector2(cos(a), sin(a)) * minf(r.size.x, r.size.y) * 0.28)
		p.fill_poly(ring, p.flat(Color("#b08a40"), 0.08))
		Ink.path(p, ring, 1.0)
		Ink.path(p, poly, 1.4)
	Props3D.plate(k, [Vector2(0.2, 1.4), Vector2(0.8, 1.4), Vector2(0.8, 2.02), Vector2(0.2, 2.02)], 0.06, board)
	for x: float in [0.28, 0.72]:
		k.box(x - 0.01, 0.0, x + 0.01, 0.02, 2.02, 2.1, {}, Props3D.paint(Props3D.IRON, "", 0.0))


## 벽 등불: 벽에 댄 판 + 쇠 팔 + 따뜻한 등불(집 앞면 바로 앞에 선다).
static func _walllamp(k: Kit) -> void:
	k.box(-0.12, -0.12, 0.12, -0.06, 0.0, 2.0, {"top": Props3D.paint(Props3D.DARK_WOOD)}, Props3D.paint(Props3D.DARK_WOOD, "vwood"))  # 벽에 댄 기둥(땅까지 — 발이 땅에 닿게)
	k.box(-0.03, -0.1, 0.03, 0.18, 1.86, 1.92, {}, Props3D.paint(Props3D.IRON))
	k.box(-0.12, 0.06, 0.12, 0.3, 1.44, 1.76, {"top": Props3D.paint(Props3D.IRON)}, Props3D.glow())
	k.pyramid(-0.14, 0.04, 0.14, 0.32, 1.76, 0.16, 0.02, Props3D.paint(Props3D.IRON))


## 포장마차(덮개 수레): 짐칸 · 둥근 천 덮개 · 바퀴 둘 · 끌채.
static func _wagon(k: Kit) -> void:
	k.box(-1.2, -0.45, 0.9, 0.45, 0.45, 0.8, {"top": Props3D.paint(Props3D.WOOD, "wood")}, Props3D.paint(Color("#6e5034"), "wood"))
	k.gable_roof(-1.2, -0.48, 0.9, 0.48, 0.8, 0.75, true, 0.04, Props3D.paint(Color("#c8bea0"), "", 1.0), Props3D.paint(Color("#b8ac8c"), "", 1.0))
	for x: float in [-0.85, 0.55]:
		var wheel := []
		for i in 12:
			var a := TAU * i / 12.0
			wheel.append(Vector2(x + cos(a) * 0.42, 0.42 + sin(a) * 0.42))
		Props3D.plate(k, wheel, 0.47, Props3D.paint(Color("#4a3424"), "vwood", 1.4))
	for z: float in [-0.2, 0.2]:
		k.box(0.9, z - 0.03, 1.8, z + 0.03, 0.5, 0.56, {}, Props3D.paint(Props3D.DARK_WOOD))


## 부두 난간(동서로 세 칸 — 판자 부두 끝): 기둥 넷 + 손잡이 · 가운데 가로대.
static func _rail(k: Kit) -> void:
	for x: float in [-1.45, -0.5, 0.5, 1.45]:
		k.box(x - 0.07, -0.07, x + 0.07, 0.07, 0.0, 0.95, {"top": Props3D.paint(Props3D.DARK_WOOD)}, Props3D.paint(Props3D.DARK_WOOD, "vwood"))
	k.box(-1.5, -0.05, 1.5, 0.05, 0.85, 0.95, {"top": Props3D.paint(Props3D.WOOD)}, Props3D.paint(Props3D.WOOD))
	k.box(-1.5, -0.04, 1.5, 0.04, 0.45, 0.52, {}, Props3D.paint(Props3D.WOOD))


## 거룻배(물 위): 뱃전 판 둘 · 안쪽 바닥 · 가로 앉을 판 · 노.
static func _boat(k: Kit) -> void:
	var hull := Props3D.paint(Color("#4e3a2a"), "wood", 1.4)
	var out := [Vector2(-1.25, 0.35), Vector2(1.25, 0.35), Vector2(1.0, 0.0), Vector2(-1.0, 0.0)]
	Props3D.plate(k, out, 0.42, hull)
	var top := PackedVector3Array([Vector3(-1.25, 0.33, 0.0), Vector3(-1.0, 0.33, -0.42), Vector3(1.0, 0.33, -0.42), Vector3(1.25, 0.33, 0.0), Vector3(1.0, 0.33, 0.42), Vector3(-1.0, 0.33, 0.42)])
	k.face(top, Vector3.UP, Props3D.paint(Color("#3a2a1e"), "wood", 1.4))
	k.box(-0.15, -0.4, 0.15, 0.4, 0.33, 0.42, {"top": Props3D.paint(Props3D.WOOD)}, Props3D.paint(Props3D.WOOD))
	k.box(0.2, 0.1, 1.5, 0.16, 0.42, 0.48, {}, Props3D.paint(Color("#6a4a30")))


## 골목 살림: 물동이 · 빗자루 · 바구니 · 작은 상자.
static func _household(k: Kit) -> void:
	Props3D.cyl(k, -0.4, 0.05, 0.2, 0.0, 0.38, Props3D.paint(Color("#5e4632"), "vwood"), Props3D.paint(Color("#2c3a40")), 10)
	k.box(-0.47, -0.02, -0.33, 0.12, 0.38, 0.4, {}, Props3D.paint(Props3D.IRON))
	k.box(0.05, -0.2, 0.09, -0.16, 0.0, 1.15, {}, Props3D.paint(Props3D.WOOD))  # 빗자루 자루
	k.box(-0.02, -0.24, 0.16, -0.12, 0.0, 0.35, {}, Props3D.paint(Color("#a08a5a"), "vwood", 0.8))  # 빗자루 솔
	Props3D.cyl(k, 0.45, 0.1, 0.22, 0.0, 0.3, Props3D.paint(Color("#8a7048"), "rubble", 0.8), Props3D.paint(Color("#6a5236")), 10)  # 바구니
	Props3D._crate(k, 0.1, 0.32, 0.4)



## 모루(대장간 앞 — CT105): 나무 그루터기 받침 + 쇠 모루(받침 · 허리 · 윗면 · 뿔) + 얹은 망치.
static func _anvil(k: Kit) -> void:
	Props3D.cyl(k, 0.0, 0.0, 0.3, 0.0, 0.45, Props3D.paint(Color("#5a4232"), "vwood"), Props3D.paint(Color("#7a5e40")), 12)
	var iron := Props3D.paint(Color("#2e2a28"), "", 1.2)
	k.box(-0.24, -0.15, 0.24, 0.15, 0.45, 0.55, {"top": iron}, iron)
	k.box(-0.13, -0.1, 0.13, 0.1, 0.55, 0.7, {}, iron)
	k.box(-0.36, -0.14, 0.3, 0.14, 0.7, 0.86, {"top": Props3D.paint(Color("#4a4642"), "", 1.2)}, iron)
	k.box(0.3, -0.07, 0.52, 0.07, 0.74, 0.84, {"top": iron}, iron)  # 뿔
	k.box(-0.3, 0.02, 0.05, 0.06, 0.86, 0.9, {}, Props3D.paint(Props3D.WOOD))  # 망치 자루
	k.box(-0.36, -0.03, -0.24, 0.11, 0.86, 0.98, {"top": iron}, iron)  # 망치 머리
