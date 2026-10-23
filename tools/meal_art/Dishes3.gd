extends RefCounted
## 여관 요리 그림(평소 차림 3 · 특식): 보리 귀리죽 · 콩죽 · 드레이크 꼬리 스테이크 · 연어 통구이 · 월광 산딸기 타르트 · 통돼지 바비큐 ·
## 왕실 약초 전골 · 동굴 송로 수프. 특식은 접시가 크고 곁들임이 많다(놋쇠 쟁반·은 접시).

const Clay := preload("res://tools/monster_art/Clay.gd")
const Kit := preload("res://tools/meal_art/Kit.gd")
const Bits := preload("res://tools/meal_art/Bits.gd")
const D1 := preload("res://tools/meal_art/Dishes1.gd")

const C := Vector2(480, 305)


static func barley_porridge(ctx: Dictionary) -> void:
	D1.props(ctx, "#8a5a2a", "", true, "linen", true)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var b := Kit.bowl(ctx, C, 200.0, "wood_bowl", 0.55)
	var g := Kit.surface(ctx, C, float(b[1]), float(b[0]) - 2.0, Kit.food(ctx, Color("#cca86c"), "skin", {"spec": 0.45, "tex": 0.3}), 10.0)
	Bits.grains(ctx, g, C, float(b[1]) * 0.9, float(b[1]) * 0.9 * Kit.SQ, float(b[0]) + 4.0, 220, 6.0, Kit.food(ctx, Color("#d8b880"), "skin", {"spec": 0.5}))
	Bits.balls(ctx, C + Vector2(-50, -10), 70.0, 26.0, float(b[0]) + 16.0, 9, 11.0, Bits.veg(ctx, Color("#c8203a"), 1.0))  # 산딸기
	Bits.balls(ctx, C + Vector2(60, 10), 60.0, 22.0, float(b[0]) + 16.0, 8, 10.0, Bits.veg(ctx, Color("#3a3a8a"), 1.0))  # 블루베리
	var nut := Bits.roast(ctx, Color("#a8743a"), 0.4)
	for k in 5:  # 호두
		var c := C + Vector2(rng.randf_range(-100, 100), rng.randf_range(-30, 30))
		Bits.lump(ctx, cl.group(), c, float(b[0]) + 18.0, 14.0, 10.0, 8.0, nut, rng.randf() * PI, 2)
	cl.slab(g, Kit.oval(C + Vector2(20, 4), 46.0, 20.0, 24), float(b[0]) + 12.0, 3.0, Bits.sauce(ctx, Color("#d89020")), 2.0, 10.0)  # 고인 꿀
	Kit.cutlery(ctx, C + Vector2(200, 60), 190.0, -0.5, "spoon", "board")
	ctx["steam"].append([C + Vector2(0, -20), 150.0])


static func bean_porridge(ctx: Dictionary) -> void:
	D1.props(ctx, "ale", "spoon", false, "cloth")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	Kit.plate(ctx, C + Vector2(0, 26), 255.0, "plate")
	var b := Kit.bowl(ctx, C, 195.0, "plate", 0.45, 40.0)
	var g := Kit.surface(ctx, C, float(b[1]), float(b[0]) - 2.0, Bits.sauce(ctx, Color("#e6c886"), 0.55), 6.0)
	var spiral: Array = []
	for i in 40:  # 크림 한 바퀴
		var t := i / 39.0
		var a := t * TAU * 1.6
		spiral.append(C + Vector2(cos(a) * (20 + t * 90), sin(a) * (10 + t * 46)))
	cl.ridge(g, spiral, 5.0, 4.0, Kit.food(ctx, Color("#fff4dc"), "slime", {"spec": 0.8}), 2.0)
	Bits.balls(ctx, C + Vector2(10, -6), 40.0, 16.0, float(b[0]) + 8.0, 10, 8.0, Bits.veg(ctx, Color("#7a1e1e"), 0.9))  # 팥
	for k in 8:  # 잣
		var c := C + Vector2(rng.randf_range(-60, 60), rng.randf_range(-20, 20))
		cl.ell(cl.group(), Vector3(c.x, c.y, float(b[0]) + 14.0), 6.0, 4.0, 4.0, Kit.food(ctx, Color("#f2e2b4"), "bone", {"spec": 0.5}), 1.0, rng.randf() * PI)
	ctx["dots"].append([C, 110.0, 44.0, 30, Color("#3a2a10"), 1.4])  # 계피 가루
	ctx["steam"].append([C + Vector2(0, -26), 150.0])


static func drake_tail_steak(ctx: Dictionary) -> void:
	ctx["table"] = Color("#4e301c")
	D1.props(ctx, "#6a1a20", "knife", false, "cloth")
	var cl: Clay = ctx["cl"]
	var z := Kit.board(ctx, C + Vector2(0, 10), 310.0, 130.0, -0.06)
	var crust := Bits.roast(ctx, Color("#6a2a10"), 0.75)
	var pink := Kit.food(ctx, Color("#d0605a"), "skin", {"spec": 0.55, "mottle": Color("#e89080"), "mottle_amt": 0.4})
	var scale := Kit.food(ctx, Color("#3a4a2e"), "leather", {"spec": 0.8, "mottle": Bits.SEAR, "mottle_amt": 0.4})
	var g := cl.group()  # 두툼한 꼬리 토막(겉은 바싹, 비늘 껍질 띠)
	cl.ell(g, Vector3(C.x - 90, C.y + 10, z + 30), 130.0, 74.0, 56.0, crust, 6.0, -0.1)
	for k in 7:
		var a := PI * 0.9 + k * 0.2
		cl.bump(g, C + Vector2(-90 + cos(a) * 120, 10 + sin(a) * 66), 18.0, 12.0, 6.0, scale, 3.0, a)
	for k in 3:
		cl.groove(g, C + Vector2(-170 + k * 50, -10), C + Vector2(-130 + k * 50, 40), 4.0, 6.0)
	for k in 3:  # 저며 펼친 조각(분홍 속살 + 탄 테두리)
		var c := C + Vector2(70 + k * 56, 20 + k * 6)
		var gs := cl.group()
		cl.ell(gs, Vector3(c.x, c.y, z + 20 + k * 6), 44.0, 64.0, 18.0, crust, 3.0, 0.25)
		cl.slab(gs, Kit.oval(c + Vector2(-4, -2), 36.0, 54.0, 24), z + 34.0 + k * 6, 4.0, pink, 2.0, 10.0)
	Bits.balls(ctx, C + Vector2(-60, 100), 60.0, 16.0, z + 10.0, 5, 16.0, Bits.veg(ctx, Color("#c8281a"), 1.0))  # 구운 방울토마토
	Bits.sprig(ctx, C + Vector2(-230, -60), C + Vector2(-120, -100), z + 70.0, Bits.veg(ctx, Color("#3e5a2a"), 0.2))
	Bits.sprig(ctx, C + Vector2(160, -80), C + Vector2(250, -40), z + 30.0, Bits.veg(ctx, Color("#3e5a2a"), 0.2))
	Kit.dish(ctx, C + Vector2(240, 80), 40.0, Color("#7a2018"), "slime", "plate", 40.0)  # 붉은 포도주 소스
	ctx["dots"].append([C + Vector2(-60, 10), 200.0, 70.0, 90, Color("#f4eee0"), 1.8])  # 굵은 소금
	ctx["dots"].append([C + Vector2(-60, 10), 200.0, 70.0, 70, Color("#140a04"), 1.8])  # 후추


static func butter_salmon(ctx: Dictionary) -> void:
	D1.props(ctx, "ale", "fork", false, "linen", true)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var z := Kit.plate(ctx, C, 260.0, "plate")
	var salmon := Kit.food(ctx, Color("#e8784a"), "skin", {"spec": 0.75, "mottle": Color("#f8c0a0"), "mottle_amt": 0.35, "contrast": 1.1})
	var g := cl.group()  # 통 연어 살(결 + 그릴 자국)
	cl.slab(g, PackedVector2Array([C + Vector2(-170, -30), C + Vector2(120, -60), C + Vector2(170, -20), C + Vector2(140, 40), C + Vector2(-150, 50), C + Vector2(-190, 20)]), z + 10.0, 34.0, salmon, 3.0, 30.0)
	for k in 7:
		var x := -140 + k * 42
		cl.grooves(g, [C + Vector2(x, -40), C + Vector2(x + 14, 0), C + Vector2(x + 4, 40)], 2.5, 5.0)
	for k in 3:
		cl.groove(g, C + Vector2(-150 + k * 100, -10), C + Vector2(-90 + k * 100, -30), 4.0, 6.0)
	cl.slab(cl.group(), Kit.oval(C + Vector2(-20, -24), 34.0, 20.0, 20), z + 50.0, 10.0, Kit.food(ctx, Color("#fae47c"), "slime", {"spec": 1.0}), 2.0, 8.0)  # 녹는 버터
	Bits.rope(ctx, [C + Vector2(10, -16), C + Vector2(30, 6), C + Vector2(24, 34)], z + 46.0, 5.0, Bits.sauce(ctx, Color("#f2d060")))
	var potato := Kit.food(ctx, Color("#e0b048"), "skin", {"spec": 0.6, "mottle": Color("#9a6420"), "mottle_amt": 0.45})
	for k in 5:  # 버터 감자
		var c := C + Vector2(-150 + k * 70, 80 + (k % 2) * 12)
		Bits.lump(ctx, cl.group(), c, z + 12.0, 30.0, 22.0, 22.0, potato, rng.randf() * PI)
	Bits.scatter(ctx, C + Vector2(-20, 70), 170.0, 30.0, z + 40.0, 26, 4.0, Bits.veg(ctx, Color("#5a8a2a"), 0.4))
	for k in 3:
		Bits.sprig(ctx, C + Vector2(80 + k * 20, -80), C + Vector2(150 + k * 20, -60), z + 50.0, Bits.veg(ctx, Color("#6a9a3a"), 0.3))
	Bits.lemon(ctx, C + Vector2(200, 40), z + 10.0, 50.0, -0.6)


static func moonberry_tart(ctx: Dictionary) -> void:
	ctx["table"] = Color("#4a3020")
	D1.props(ctx, "#e8d8b0", "fork", false, "cloth")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var z := Kit.plate(ctx, C + Vector2(0, 10), 255.0, "silver")
	var crust := Kit.food(ctx, Color("#cc8c40"), "skin", {"spec": 0.35, "tex": 0.35, "mottle": Color("#8a5420"), "mottle_amt": 0.4})
	var g := cl.group()  # 타르트 틀: 바깥 테(주름 진 가장자리) + 크림
	cl.slab(g, Kit.oval(C, 190.0, 190.0 * Kit.SQ, 48), z + 14.0, 20.0, crust, 3.0, 14.0)
	for i in 36:
		var a := TAU * i / 36.0
		cl.bump(g, C + Vector2(cos(a) * 182, sin(a) * 182 * Kit.SQ), 12.0, 9.0, 8.0, crust, 3.0)
	var ring: Array = []
	for i in 49:
		ring.append(C + Vector2(cos(TAU * i / 48.0) * 165, sin(TAU * i / 48.0) * 165 * Kit.SQ))
	cl.ridge(g, ring, 16.0, 14.0, crust, 3.0)  # 두툼한 테
	cl.slab(cl.group(), Kit.oval(C, 150.0, 150.0 * Kit.SQ, 48), z + 30.0, 4.0, Kit.food(ctx, Color("#f2d488"), "slime", {"spec": 0.6}), 2.0, 10.0)  # 커스터드
	var berry := Kit.food(ctx, Color("#7484d8"), "slime", {"spec": 1.0})
	var berry2 := Kit.food(ctx, Color("#b8bcf0"), "slime", {"spec": 1.0})
	for k in 44:  # 소복이 얹은 월광 산딸기
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf())
		var c := C + Vector2(cos(a) * 125 * r, sin(a) * 58 * r)
		var s := rng.randf_range(15, 21)
		cl.ell(cl.group(), Vector3(c.x, c.y, z + 40 + (1.0 - r) * 34 + k * 0.3), s, s * 0.9, s * 0.9, berry if k % 3 else berry2, 1.0)
		if k % 4 == 0:
			ctx["glows"].append([c, 40.0, Color("#c8d4ff"), 0.12])
	for k in 3:
		Bits.leaf(ctx, C + Vector2(-20 + k * 20, -30 + k * 4), z + 90.0, 24.0, -0.6 + k * 0.7, Bits.veg(ctx, Color("#3e8a3a"), 0.6))
	ctx["dots"].append([C, 160.0, 70.0, 160, Color("#fbf8f0"), 1.5])  # 슈가 파우더
	var pot := C + Vector2(250, -90)  # 크림 단지
	Kit.dish(ctx, pot, 44.0, Color("#fff4e0"), "slime", "silver")


static func whole_pig_roast(ctx: Dictionary) -> void:
	ctx["table"] = Color("#4e301c")
	D1.props(ctx, "ale", "knife", true, "", false)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var z := Kit.plate(ctx, C + Vector2(0, 15), 330.0, "brass", 0.8)
	var skin := Bits.roast(ctx, Color("#b05a1c"), 0.95)
	var g := cl.group()  # 통돼지: 몸통 · 머리 · 귀 · 주둥이 · 다리
	cl.ell(g, Vector3(C.x - 30, C.y + 10, z + 40), 200.0, 92.0, 88.0, skin, 8.0)
	var head := C + Vector2(170, 0)
	cl.ell(g, Vector3(head.x, head.y, z + 50), 78.0, 66.0, 70.0, skin, 14.0)
	cl.cap(g, Vector3(head.x + 50, head.y + 14, z + 70), Vector3(head.x + 92, head.y + 18, z + 76), 34.0, 28.0, skin, 8.0)
	cl.carve(g, head + Vector2(96, 16), 6.0, 5.0, 6.0)
	cl.carve(g, head + Vector2(96, 28), 6.0, 5.0, 6.0)
	cl.groove(g, head + Vector2(20, -16), head + Vector2(40, -20), 4.0, 6.0)  # 감은 눈
	for s: float in [-1.0, 1.0]:
		cl.slab(cl.group(), PackedVector2Array([head + Vector2(-14, -36 + s * 14), head + Vector2(46, -42 + s * 30), head + Vector2(30, -16 + s * 14)]), z + 100.0, 6.0, skin, 2.0, 8.0)  # 앞으로 처진 귀
	for k in 4:  # 다리
		var hip := C + Vector2(-150 + k * 90, 70)
		cl.cap(g, Vector3(hip.x, hip.y, z + 50), Vector3(hip.x + 20, hip.y + 40, z + 56), 26.0, 16.0, skin, 8.0)
	for k in 9:  # 칼집(바삭한 껍질 결)
		cl.groove(g, C + Vector2(-200 + k * 40, -60), C + Vector2(-180 + k * 40, 60), 3.0, 6.0)
	var apple := Bits.veg(ctx, Color("#c8281e"), 0.9)
	cl.ell(cl.group(), Vector3(head.x + 116, head.y + 26, z + 90), 30.0, 28.0, 26.0, apple, 2.0)  # 입에 문 사과
	for k in 5:  # 둘레 사과 · 잎
		var a := PI * 0.55 + k * 0.5
		var c := C + Vector2(cos(a) * 270, sin(a) * 120 + 20)
		cl.ell(cl.group(), Vector3(c.x, c.y, z + 20), 30.0, 27.0, 26.0, apple if k % 2 == 0 else Bits.veg(ctx, Color("#9ab030"), 0.8), 2.0)
		Bits.leaf(ctx, c + Vector2(30, -10), z + 30.0, 30.0, rng.randf() * TAU, Bits.veg(ctx, Color("#3e6a2a"), 0.5))
	for k in 2:
		Bits.sprig(ctx, C + Vector2(-240 + k * 60, -60), C + Vector2(-160 + k * 60, -100), z + 110.0, Bits.veg(ctx, Color("#3e5a2a"), 0.2))
	ctx["dots"].append([C + Vector2(-30, 0), 200.0, 80.0, 90, Color("#f2ead6"), 1.6])


static func royal_herb_hotpot(ctx: Dictionary) -> void:
	ctx["table"] = Color("#4a2e1c")
	D1.props(ctx, "#8a7a2a", "spoon", false, "cloth", true)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var b := Kit.bowl(ctx, C, 225.0, "brass", 0.5)  # 놋 전골냄비
	for s: float in [-1.0, 1.0]:
		cl.chain(cl.group(), [Vector3(C.x + s * 215, C.y - 6, Kit.z0(C.y) - 4), Vector3(C.x + s * 250, C.y - 14, Kit.z0(C.y) - 4), Vector3(C.x + s * 252, C.y + 16, Kit.z0(C.y) - 4)], [10.0, 10.0, 10.0], Kit.m(ctx, "brass"), 2.0)
	var zb := float(b[0])
	Kit.surface(ctx, C, float(b[1]), zb - 4.0, Bits.sauce(ctx, Color("#a89a3a"), 0.9), 3.0)
	var shroom := Bits.roast(ctx, Color("#8a5a30"), 0.6)
	var meatball := Bits.roast(ctx, Color("#7a4020"), 0.6)
	for k in 6:  # 표고 · 완자
		var c := C + Vector2(rng.randf_range(-150, 150), rng.randf_range(-50, 50))
		if k % 2 == 0:
			Bits.lump(ctx, cl.group(), c, zb + 2.0, 28.0, 18.0, 14.0, shroom, rng.randf() * PI, 0)
		else:
			cl.ell(cl.group(), Vector3(c.x, c.y, zb + 4.0), 22.0, 19.0, 18.0, meatball, 2.0)
	var ginseng := Kit.food(ctx, Color("#e8d4a0"), "skin", {"spec": 0.4})  # 인삼 뿌리
	Bits.rope(ctx, [C + Vector2(-40, 0), C + Vector2(10, -16), C + Vector2(60, -6), C + Vector2(90, 16)], zb + 14.0, 9.0, ginseng)
	Bits.rope(ctx, [C + Vector2(60, -6), C + Vector2(80, -28)], zb + 12.0, 4.0, ginseng)
	for k in 10:  # 약초 잎
		var c := C + Vector2(rng.randf_range(-160, 160), rng.randf_range(-55, 55))
		Bits.leaf(ctx, c, zb + 10.0, rng.randf_range(16, 26), rng.randf() * TAU, Bits.veg(ctx, Color("#3e7a2a").lerp(Color("#8ab040"), rng.randf()), 0.6))
	Bits.balls(ctx, C + Vector2(-60, 30), 80.0, 30.0, zb + 6.0, 12, 6.0, Bits.veg(ctx, Color("#c82a1a"), 1.0))  # 구기자
	Bits.balls(ctx, C + Vector2(80, 20), 30.0, 12.0, zb + 6.0, 3, 14.0, Bits.veg(ctx, Color("#9a2a1a"), 0.9))  # 대추
	ctx["steam"].append([C + Vector2(-60, -20), 170.0])
	ctx["steam"].append([C + Vector2(60, -10), 170.0])


static func cave_truffle_soup(ctx: Dictionary) -> void:
	ctx["table"] = Color("#4a3020")
	D1.props(ctx, "ale", "spoon", true, "linen")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	Kit.plate(ctx, C + Vector2(0, 26), 255.0, "plate_dark")
	var b := Kit.bowl(ctx, C, 195.0, "plate_dark", 0.45, 40.0)
	var zb := float(b[0])
	var g := Kit.surface(ctx, C, float(b[1]), zb - 2.0, Bits.sauce(ctx, Color("#b08a5a"), 0.6), 5.0)
	var spiral: Array = []
	for i in 30:
		var t := i / 29.0
		var a := t * TAU * 1.3 + 1.0
		spiral.append(C + Vector2(cos(a) * (14 + t * 80), sin(a) * (7 + t * 40)))
	cl.ridge(g, spiral, 4.0, 3.0, Kit.food(ctx, Color("#f8f0dc"), "slime", {"spec": 0.8}), 2.0)
	var truffle := Kit.food(ctx, Color("#3a2a20"), "skin", {"spec": 0.4, "mottle": Color("#c8b098"), "mottle_amt": 0.5, "tex": 0.4})
	for k in 7:  # 얇게 저민 송로
		var c := C + Vector2(rng.randf_range(-90, 90), rng.randf_range(-30, 30))
		cl.slab(cl.group(), Kit.oval(c, 22.0, 14.0, 14), zb + 8.0 + k, 3.0, truffle, 2.0, 4.0)
	var glow := Kit.food(ctx, Color("#9ad8e0"), "slime", {"spec": 0.8})
	for k in 3:  # 동굴 빛버섯(작은 갓)
		var c := C + Vector2(-110 + k * 30, -20 + k * 10)
		cl.cap(cl.group(), Vector3(c.x, c.y + 10, zb + 14), Vector3(c.x, c.y - 6, zb + 18), 3.0, 2.5, Kit.food(ctx, Color("#e0e8e0"), "skin"), 1.0)
		cl.ell(cl.group(), Vector3(c.x, c.y - 10, zb + 22), 11.0, 7.0, 6.0, glow, 2.0)
		ctx["glows"].append([c + Vector2(0, -10), 34.0, Color("#9adce8"), 0.25])
	Bits.scatter(ctx, C, 110.0, 40.0, zb + 18.0, 18, 4.0, Bits.veg(ctx, Color("#5a8a2a"), 0.3))
	ctx["dots"].append([C, 110.0, 44.0, 40, Color("#140c06"), 1.4])
	ctx["steam"].append([C + Vector2(0, -26), 150.0])
