extends RefCounted
## 여관 요리 그림(평소 차림 2): 은어구이 · 청어구이 · 선지 소시지 · 쓴나물 국밥 · 양꼬치 · 고추기름 국수 · 박하 얼음과자 · 당근 스튜.
## 한 함수 = 한 장면. 소품 한 벌은 Dishes1.props. 부품 = Kit · Bits.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Kit := preload("res://tools/meal_art/Kit.gd")
const Bits := preload("res://tools/meal_art/Bits.gd")
const D1 := preload("res://tools/meal_art/Dishes1.gd")

const C := Vector2(480, 305)


## 생선 한 마리(옆으로 누운): 몸통 · 머리 · 눈 · 꼬리 지느러미 · 비늘 결. dir = 머리 쪽 방향(라디안).
static func fish(ctx: Dictionary, c: Vector2, z: float, len: float, dir: float, skin: int, belly: int) -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	var d := Vector2.from_angle(dir)
	var n := Vector2(-d.y, d.x)
	cl.ell(g, Vector3(c.x, c.y, z), len * 0.5, len * 0.13, len * 0.12, skin, 4.0, dir)
	var belly_c := c + n * len * 0.06
	cl.ell(g, Vector3(belly_c.x, belly_c.y, z - 2), len * 0.42, len * 0.08, len * 0.1, belly, 4.0, dir)
	var head := c + d * len * 0.38
	cl.ell(g, Vector3(head.x, head.y, z + 3), len * 0.15, len * 0.12, len * 0.11, skin, 6.0, dir)
	cl.groove(g, head - d * len * 0.06 + n * len * 0.1, head - d * len * 0.06 - n * len * 0.1, 2.5, 4.0)  # 아가미
	var eye := head + d * len * 0.04 - n * len * 0.04
	cl.ell(cl.group(), Vector3(eye.x, eye.y, z + len * 0.12), len * 0.025, len * 0.025, len * 0.02, Kit.food(ctx, Color("#e8e0c8"), "eye"), 1.0)
	var tail := c - d * len * 0.5
	cl.slab(cl.group(), PackedVector2Array([tail + d * len * 0.06, tail - d * len * 0.14 + n * len * 0.12, tail - d * len * 0.1, tail - d * len * 0.14 - n * len * 0.12]), z - 4.0, 4.0, skin, 2.0, 5.0)
	for k in 5:  # 비늘·칼집 결
		var q := c + d * len * (-0.3 + k * 0.13)
		cl.groove(g, q + n * len * 0.1, q - d * len * 0.04 - n * len * 0.06, 2.0, 3.0)


static func grilled_sweetfish(ctx: Dictionary) -> void:
	D1.props(ctx, "#6a7a30", "", false, "linen", true)
	var cl: Clay = ctx["cl"]
	var z := Kit.board(ctx, C + Vector2(0, 10), 300.0, 105.0, -0.08, "plate")
	var skin := Kit.food(ctx, Color("#9a8a62"), "skin", {"spec": 0.7, "mottle": Bits.SEAR, "mottle_amt": 0.55, "contrast": 1.2})
	var belly := Kit.food(ctx, Color("#e8dcc0"), "skin", {"spec": 0.6})
	for k in 2:  # 꼬치에 꿴 은어 두 마리(소금 뿌려 숯불에)
		var c := C + Vector2(-20 + k * 40, -30 + k * 70)
		Bits.skewer(ctx, c + Vector2(-230, 30), c + Vector2(220, -26), z + 12.0, [])
		fish(ctx, c, z + 30.0 + k * 10.0, 330.0, -0.12, skin, belly)
		ctx["dots"].append([c, 140.0, 22.0, 90, Color("#f6f2e8"), 1.8])  # 소금
	var radish := Kit.food(ctx, Color("#f2eee4"), "bone", {"tex": 0.6, "spec": 0.3})
	cl.ell(cl.group(), Vector3(C.x + 200, C.y + 50, z + 20), 40.0, 26.0, 26.0, radish, 3.0)  # 간 무
	Bits.lemon(ctx, C + Vector2(-210, 60), z + 12.0, 46.0, 0.4)
	for k in 3:  # 잎 깔개
		Bits.leaf(ctx, C + Vector2(150 + k * 30, -70 + k * 6), z + 6.0, 50.0, 0.3 + k * 0.4, Bits.veg(ctx, Color("#3e6a2a"), 0.5))


static func salted_herring(ctx: Dictionary) -> void:
	D1.props(ctx, "ale", "fork", true, "cloth")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var z := Kit.plate(ctx, C, 245.0, "plate")
	var skin := Kit.food(ctx, Color("#8c9cac"), "metal", {"spec": 0.95, "mottle": Color("#2a3446"), "mottle_amt": 0.6})
	var flesh := Kit.food(ctx, Color("#e8b8a0"), "skin", {"spec": 0.6})
	for k in 3:  # 청어 살(은빛 껍질이 위 · 등 쪽 짙은 푸른 줄 · 끝에 분홍 살 단면)
		var c := C + Vector2(-120 + k * 100, -18 + (k % 2) * 34)
		var rot := -0.25 + k * 0.15
		var leaf := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			leaf.append(c + Vector2(cos(a) * 82, sin(a) * 26 * (1.0 if sin(a) > 0 else 0.8)).rotated(rot))
		var g := cl.group()
		cl.slab(g, leaf, z + 14.0 + k * 4.0, 14.0, skin, 3.0, 14.0)
		cl.ridge(g, [c + Vector2(-70, -12).rotated(rot), c + Vector2(0, -18).rotated(rot), c + Vector2(70, -10).rotated(rot)], 6.0, 3.0, Kit.food(ctx, Color("#2e3c58"), "metal", {"spec": 0.9}))
		cl.slab(cl.group(), Kit.oval(c + Vector2(78, 0).rotated(rot), 10.0, 20.0, 14), z + 22.0 + k * 4.0, 5.0, flesh, 2.0, 5.0)
	var onion := Bits.veg(ctx, Color("#9a3a6a"), 0.6)
	for k in 6:  # 붉은 양파 고리
		var c := C + Vector2(rng.randf_range(-130, 130), rng.randf_range(-50, 50))
		var ring: Array = []
		for i in 13:
			ring.append(c + Vector2(cos(TAU * i / 12.0) * 16, sin(TAU * i / 12.0) * 9))
		Bits.rope(ctx, ring, z + 40.0, 3.5, onion)
	Bits.balls(ctx, C + Vector2(120, 80), 50.0, 20.0, z + 10.0, 4, 24.0, Kit.food(ctx, Color("#e0b850"), "skin", {"spec": 0.4, "mottle": Color("#a07a28"), "mottle_amt": 0.4}))  # 삶은 감자
	Bits.lemon(ctx, C + Vector2(-150, 70), z + 10.0, 48.0, 0.2)
	for k in 3:
		Bits.sprig(ctx, C + Vector2(-60 + k * 50, -70), C + Vector2(-20 + k * 50, -40), z + 50.0, Bits.veg(ctx, Color("#5a8a3a"), 0.2))
	ctx["dots"].append([C, 140.0, 60.0, 50, Color("#1a1008"), 1.5])


static func blood_sausage(ctx: Dictionary) -> void:
	D1.props(ctx, "ale", "knife", false, "linen", true)
	var cl: Clay = ctx["cl"]
	var z := Kit.plate(ctx, C, 245.0, "plate")
	var casing := Bits.roast(ctx, Color("#3e1414"), 0.8)
	var inside := Kit.food(ctx, Color("#4a1a1c"), "skin", {"spec": 0.3, "tex": 0.6, "mottle": Color("#d8b090"), "mottle_amt": 0.35})
	var g := cl.group()  # 통 소시지(굽은)
	cl.chain(g, [Vector3(C.x - 170, C.y - 30, z + 20), Vector3(C.x - 80, C.y - 60, z + 22), Vector3(C.x + 20, C.y - 50, z + 22)], [26.0, 27.0, 25.0], casing, 4.0)
	for k in 4:  # 썬 소시지(동그란 단면)
		var c := C + Vector2(40 + k * 34, -10 + k * 14)
		var gs := cl.group()
		cl.ell(gs, Vector3(c.x, c.y + 6, z + 14), 26.0, 20.0, 12.0, casing, 2.0)
		cl.slab(gs, Kit.oval(c, 23.0, 17.0, 20), z + 24.0 + k * 3.0, 3.0, inside, 2.0, 4.0)
	var apple := Kit.food(ctx, Color("#e0a040"), "slime", {"spec": 0.9})
	for k in 5:  # 버터에 지진 사과
		var c := C + Vector2(-150 + k * 34, 50 + (k % 2) * 10)
		var arc: Array = []
		for i in 7:
			var a := PI * 1.1 + i * 0.16
			arc.append(c + Vector2(cos(a) * 34, sin(a) * 20 + 20))
		Bits.rope(ctx, arc, z + 14.0, 9.0, apple)
	var mash := Kit.food(ctx, Color("#f0dca0"), "skin", {"spec": 0.35, "tex": 0.35})
	var gm := cl.group()
	cl.ell(gm, Vector3(C.x + 100, C.y + 70, z + 10), 70.0, 40.0, 36.0, mash, 6.0)
	cl.grooves(gm, [C + Vector2(60, 60), C + Vector2(100, 50), C + Vector2(140, 66)], 4.0, 5.0)
	cl.slab(cl.group(), Kit.oval(C + Vector2(100, 56), 16.0, 9.0, 12), z + 48.0, 6.0, Kit.food(ctx, Color("#fae080"), "slime", {"spec": 1.0}), 2.0, 4.0)  # 버터
	cl.ell(cl.group(), Vector3(C.x + 170, C.y - 50, z + 10), 26.0, 16.0, 14.0, Bits.sauce(ctx, Color("#c8961c"), 0.8), 3.0)  # 겨자
	Bits.scatter(ctx, C + Vector2(80, 60), 60.0, 30.0, z + 50.0, 12, 4.0, Bits.veg(ctx, Color("#4f7a26"), 0.3))


static func bitter_herb_gukbap(ctx: Dictionary) -> void:
	D1.props(ctx, "", "spoon", false, "linen")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	Kit.board(ctx, C + Vector2(0, 20), 320.0, 140.0, 0.0, "tankard")  # 나무 쟁반
	var b := Kit.bowl(ctx, C + Vector2(-30, 0), 170.0, "plate_dark", 0.55, 55.0)
	var bc := C + Vector2(-30, 0)
	Kit.surface(ctx, bc, float(b[1]), float(b[0]) - 3.0, Bits.sauce(ctx, Color("#b08048"), 0.7), 4.0)
	var meat := Kit.food(ctx, Color("#c8a080"), "skin", {"spec": 0.4})
	for k in 4:  # 고기 편육
		var c := bc + Vector2(rng.randf_range(-90, 90), rng.randf_range(-30, 30))
		cl.slab(cl.group(), Kit.oval(c, 26.0, 13.0, 16), float(b[0]) + 2.0, 4.0, meat, 2.0, 5.0)
	for k in 9:  # 쓴나물
		var c := bc + Vector2(rng.randf_range(-100, 100), rng.randf_range(-35, 35))
		Bits.leaf(ctx, c, float(b[0]) + 8.0, rng.randf_range(16, 24), rng.randf() * TAU, Bits.veg(ctx, Color("#4a7a2a").lerp(Color("#7aa040"), rng.randf()), 0.5))
	for k in 6:  # 실고추
		var a := bc + Vector2(rng.randf_range(-60, 60), rng.randf_range(-20, 20))
		Bits.rope(ctx, [a, a + Vector2(14, -4), a + Vector2(26, 2)], float(b[0]) + 16.0, 1.6, Bits.veg(ctx, Color("#c02a14"), 0.6))
	Bits.scatter(ctx, bc, 100.0, 36.0, float(b[0]) + 14.0, 18, 5.0, Bits.veg(ctx, Color("#6aaa3a"), 0.4), true)
	ctx["steam"].append([bc + Vector2(0, -20), 150.0])
	ctx["steam"].append([bc + Vector2(40, -10), 120.0])
	var side := [[Vector2(220, -50), Color("#b83a1e")], [Vector2(230, 60), Color("#7a9a3a")], [Vector2(-250, 70), Color("#e0c87a")]]
	for sd: Array in side:  # 반찬 그릇 셋(붉은 절임 · 나물 · 무)
		Kit.dish(ctx, C + (sd[0] as Vector2), 44.0, sd[1] as Color, "skin", "plate")
		ctx["dots"].append([C + (sd[0] as Vector2), 24.0, 10.0, 25, (sd[1] as Color).lightened(0.3), 2.5])


static func garlic_lamb_skewer(ctx: Dictionary) -> void:
	D1.props(ctx, "ale", "", true, "cloth")
	var cl: Clay = ctx["cl"]
	var z := Kit.board(ctx, C + Vector2(0, 10), 300.0, 110.0, 0.05, "plate_dark")
	var lamb := Bits.roast(ctx, Color("#94461c"), 0.7)
	var pepper := Bits.veg(ctx, Color("#4a8a2a"), 0.7)
	var onion := Bits.veg(ctx, Color("#e8d8b8"), 0.4)
	for k in 3:  # 꼬치 셋: 양고기 · 통마늘 · 풋고추 · 양파
		var y := C.y - 60 + k * 58
		var a := Vector2(C.x - 250, y + 18)
		var b := Vector2(C.x + 240, y - 18)
		Bits.skewer(ctx, a, b, z + 12.0 + k * 8.0, [[lamb, 30.0, true], [onion, 20.0], [lamb, 32.0, true], [pepper, 22.0], [lamb, 30.0, true], [lamb, 28.0, true]])
		Bits.garlic(ctx, a.lerp(b, 0.48) + Vector2(0, 26), z + 40.0 + k * 8.0, 15.0, 0.4 * k)
	ctx["dots"].append([C + Vector2(0, 0), 230.0, 90.0, 160, Color("#c0301a"), 2.0])  # 고춧가루
	ctx["dots"].append([C + Vector2(0, 0), 230.0, 90.0, 80, Color("#c8a060"), 1.5])  # 쯔란
	Bits.chili(ctx, C + Vector2(200, 90), C + Vector2(260, 70), z + 10.0, 9.0)


static func chili_oil_noodle(ctx: Dictionary) -> void:
	D1.props(ctx, "ale", "spoon", false, "linen", true)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var b := Kit.bowl(ctx, C, 205.0, "plate", 0.5)
	var g := Kit.surface(ctx, C, float(b[1]), float(b[0]) - 6.0, Bits.sauce(ctx, Color("#c8341a"), 1.0), 3.0)
	Bits.noodles(ctx, g, C + Vector2(-20, 0), float(b[1]) * 0.8, float(b[1]) * 0.8 * Kit.SQ, float(b[0]), 12, 5.0, Kit.food(ctx, Color("#f0dcaa"), "skin", {"spec": 0.6}))
	var choy := Bits.veg(ctx, Color("#4a8a2a"), 0.6)
	for k in 3:  # 청경채
		Bits.leaf(ctx, C + Vector2(100 + k * 12, -30 + k * 18), float(b[0]) + 14.0, 40.0, -0.6 + k * 0.5, choy)
	var white := Kit.food(ctx, Color("#f4f0e4"), "skin", {"spec": 0.6})
	var e := C + Vector2(-90, -10)  # 반숙 달걀 반쪽
	cl.ell(cl.group(), Vector3(e.x, e.y, float(b[0]) + 14.0), 36.0, 26.0, 18.0, white, 3.0)
	cl.ell(cl.group(), Vector3(e.x + 2, e.y - 2, float(b[0]) + 26.0), 17.0, 13.0, 9.0, Bits.sauce(ctx, Color("#f09a1c"), 1.0), 2.0)
	for k in 5:
		Bits.chili(ctx, C + Vector2(rng.randf_range(-60, 60), rng.randf_range(10, 40)), C + Vector2(rng.randf_range(-60, 60), rng.randf_range(10, 40)) + Vector2(24, -4), float(b[0]) + 16.0, 5.0)
	Bits.scatter(ctx, C, 130.0, 50.0, float(b[0]) + 22.0, 24, 5.0, Bits.veg(ctx, Color("#6aaa3a"), 0.4), true)
	ctx["dots"].append([C, 140.0, 55.0, 70, Color("#f2e6c4"), 1.5])  # 깨
	ctx["steam"].append([C + Vector2(0, -24), 170.0])


static func mint_sherbet(ctx: Dictionary) -> void:
	D1.props(ctx, "", "spoon", false, "linen")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var base := C + Vector2(-20, 170)  # 은 굽잔: 받침 · 대 · 잔
	var silver := Kit.m(ctx, "silver")
	var zb := Kit.z0(base.y)
	cl.slab(cl.group(), Kit.oval(base, 90.0, 90.0 * Kit.SQ, 30), zb, 6.0, silver, 2.0, 10.0)
	cl.cap(cl.group(), Vector3(base.x, base.y - 6, zb + 20), Vector3(base.x, base.y - 90, zb + 20), 16.0, 11.0, silver, 4.0)
	var cup := base + Vector2(0, -130)
	var gc := cl.group()
	cl.ell(gc, Vector3(cup.x, cup.y + 26, zb + 30), 140.0, 62.0, 44.0, silver, 4.0)
	cl.slab(gc, Kit.oval(cup, 142.0, 142.0 * Kit.SQ, 40), zb + 60.0, 4.0, silver, 2.0, 8.0)
	Kit.shadow(ctx, base, 70.0, 70.0 * Kit.SQ, 0.6)
	var mint := Kit.food(ctx, Color("#b4e0b0"), "skin", {"spec": 0.35, "tex": 0.45, "mottle": Color("#e8f6e0"), "mottle_amt": 0.5})
	for k in 3:  # 동그란 셔벗 세 덩이
		var c: Vector2 = cup + [Vector2(-56, -12), Vector2(54, -8), Vector2(0, -56)][k]
		cl.ell(cl.group(), Vector3(c.x, c.y, zb + 80.0 + k * 10.0), 62.0, 54.0, 50.0, mint, 3.0)
	for k in 2:
		Bits.leaf(ctx, cup + Vector2(10 + k * 18, -86 + k * 6), zb + 140.0, 26.0, -0.8 + k * 1.2, Bits.veg(ctx, Color("#3e8a3a"), 0.6))
	Bits.balls(ctx, cup + Vector2(-20, -40), 20.0, 8.0, zb + 130.0, 3, 9.0, Bits.veg(ctx, Color("#c82838"), 1.0))  # 붉은 열매
	ctx["dots"].append([cup + Vector2(0, -30), 90.0, 40.0, 70, Color("#f4fff4"), 1.4])  # 서리
	var cookie := Kit.m(ctx, "bread")
	for k in 3:  # 곁들인 과자
		cl.slab(cl.group(), Kit.oval(C + Vector2(170 + k * 20, 60 + k * 14), 36.0, 18.0, 20), Kit.z0(C.y + 60) + 6.0 + k * 6.0, 6.0, cookie, 2.0, 6.0)
	for k in 6:
		var a := rng.randf() * TAU
		ctx["glows"].append([cup + Vector2(cos(a) * 60, -30 + sin(a) * 20), 30.0, Color("#e0fff0"), 0.15])


static func roast_carrot_stew(ctx: Dictionary) -> void:
	D1.props(ctx, "ale", "", true, "cloth", true)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var b := Kit.bowl(ctx, C, 200.0, "iron", 0.62)  # 무쇠 냄비
	for s: float in [-1.0, 1.0]:  # 냄비 손잡이
		cl.chain(cl.group(), [Vector3(C.x + s * 190, C.y - 4, Kit.z0(C.y) + 10), Vector3(C.x + s * 228, C.y - 10, Kit.z0(C.y) + 10), Vector3(C.x + s * 230, C.y + 20, Kit.z0(C.y) + 10)], [9.0, 9.0, 9.0], Kit.m(ctx, "iron"), 2.0)
	Kit.surface(ctx, C, float(b[1]), float(b[0]) - 5.0, Bits.sauce(ctx, Color("#c0601e"), 0.8), 4.0)
	var carrot := Bits.veg(ctx, Color("#e8781e"), 0.7)
	var potato := Kit.food(ctx, Color("#e8c878"), "skin", {"spec": 0.4})
	for k in 9:  # 구운 당근 · 감자 덩이
		var c := C + Vector2(rng.randf_range(-130, 130), rng.randf_range(-45, 45))
		Bits.lump(ctx, cl.group(), c, float(b[0]) - 2.0, rng.randf_range(20, 30), rng.randf_range(14, 18), 14.0, carrot if k % 3 != 2 else potato, rng.randf() * PI, 0)
	Bits.sprig(ctx, C + Vector2(-40, -40), C + Vector2(60, -60), float(b[0]) + 26.0, Bits.veg(ctx, Color("#3e6a2a"), 0.2))
	Bits.scatter(ctx, C, 120.0, 45.0, float(b[0]) + 24.0, 20, 4.5, Bits.veg(ctx, Color("#5a8a2a"), 0.3))
	ctx["dots"].append([C, 120.0, 50.0, 50, Color("#1a0e06"), 1.5])
	ctx["steam"].append([C + Vector2(-20, -20), 170.0])
	ctx["steam"].append([C + Vector2(50, -10), 120.0])
