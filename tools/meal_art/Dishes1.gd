extends RefCounted
## 여관 요리 그림(평소 차림 1): 먹물 튀김 · 멧돼지 갈비 · 꿀 메추리 · 치즈 수프 · 버섯 리소토 · 쑥 경단 · 장어 덮밥 · 생강꿀차와 호밀빵.
## 한 함수 = 한 장면(가운데 요리 + 둘레 소품). 부품 = Kit(그릇·소품) · Bits(음식 조각). 좌표는 960×540 캔버스 px.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Kit := preload("res://tools/meal_art/Kit.gd")
const Bits := preload("res://tools/meal_art/Bits.gd")

const C := Vector2(480, 305)
const PARSLEY := Color("#4f7a26")


## 둘레 소품 한 벌: 왼쪽 뒤 초 · 오른쪽 뒤 잔 · 앞 왼쪽 도구(+ 냅킨) — 요리마다 조금씩 바꿔 부른다.
## 둘레 소품 한 벌: 뒤쪽 초 · 잔, 앞쪽 냅킨 + 도구 · 빵. flip이면 좌우를 바꾼다(요리마다 조금씩 다르게).
## mug = "ale"(맥주) · 차 색("#rrggbb") · ""(없음), tool = spoon|fork|knife|"".
static func props(ctx: Dictionary, mug: String = "ale", tool: String = "fork", bread: bool = true, napkin: String = "linen", flip: bool = false) -> void:
	var fx := func(x: float) -> float: return 960.0 - x if flip else x
	Kit.candle(ctx, Vector2(fx.call(110), 200), 118.0)
	if not mug.is_empty():
		Kit.mug(ctx, Vector2(fx.call(850), 236), 44.0, 122.0, "tankard" if mug == "ale" else "earthen", mug)
	if not napkin.is_empty():
		Kit.napkin(ctx, Vector2(fx.call(130), 470), 96.0, -0.18 if not flip else 0.18, napkin)
	if not tool.is_empty():
		Kit.cutlery(ctx, Vector2(fx.call(140), 462), 180.0, -0.3 if not flip else PI + 0.3, tool)
	if bread:
		Kit.roll(ctx, Vector2(fx.call(840), 462), 50.0, 0.3)
		Kit.roll(ctx, Vector2(fx.call(900), 420), 40.0, -0.5)


static func squid_ink_fry(ctx: Dictionary) -> void:
	ctx["table"] = Color("#5e3c22")
	props(ctx, "ale", "fork", false, "cloth")
	var z := Kit.plate(ctx, C, 215.0, "plate")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var batter := Kit.food(ctx, Color("#3e322f"), "leather", {"spec": 0.85, "tex": 0.6, "mottle": Color("#a08868"), "mottle_amt": 0.45, "contrast": 1.3, "cav": 0.6})
	Kit.dish(ctx, C + Vector2(-125, -42), 40.0, Color("#f2dc96"), "slime")  # 마늘 마요 소스
	for k in 4:  # 고리 — 먹물 튀김옷을 입힌 오징어 몸통 고리(가운데가 뚫렸다)
		var g := cl.group()
		var o: Vector2 = C + [Vector2(-95, -18), Vector2(-15, 38), Vector2(55, -22), Vector2(125, 28)][k]
		var rr := rng.randf_range(30, 36)
		var ring: Array = []
		var rs: Array = []
		for i in 17:
			var a := TAU * i / 16.0
			ring.append(Vector3(o.x + cos(a) * rr, o.y + sin(a) * rr * 0.62, z + 16.0 + (k % 2) * 8.0))
			rs.append(9.0 + 1.5 * sin(a * 3.0 + k))
		cl.chain(g, ring, rs, batter, 2.0)
		_crisp(ctx, g, ring, batter)
	for k in 5:  # 끝이 말린 다리
		var g := cl.group()
		var o: Vector2 = C + [Vector2(-60, 20), Vector2(20, -30), Vector2(95, 5), Vector2(-120, 40), Vector2(40, 60)][k]
		var a0 := rng.randf() * TAU
		var turn := rng.randf_range(3.5, 5.0) * (1.0 if k % 2 == 0 else -1.0)
		var len := rng.randf_range(60, 90)
		var pts: Array = []
		var rs: Array = []
		for i in 12:
			var t := i / 11.0
			var a := a0 + turn * t * t
			var q := o + Vector2(cos(a0), sin(a0) * 0.6) * len * t + Vector2(cos(a), sin(a) * 0.6) * len * 0.18 * t * t
			pts.append(Vector3(q.x, q.y, z + 26.0 + (k % 3) * 6.0 - t * 4.0))
			rs.append(lerpf(10.0, 2.5, t))
		cl.chain(g, pts, rs, batter, 2.5)
		_crisp(ctx, g, pts.slice(0, 7), batter)
	Bits.lemon(ctx, C + Vector2(135, 72), z + 10.0, 54.0, -0.3)
	Bits.scatter(ctx, C + Vector2(0, 10), 150.0, 70.0, z + 48.0, 30, 5.0, Bits.veg(ctx, PARSLEY, 0.25))
	ctx["dots"].append([C + Vector2(0, 0), 150.0, 75.0, 45, Color("#d0301a"), 2.2])  # 고춧가루
	ctx["dots"].append([C + Vector2(0, 0), 150.0, 75.0, 60, Color("#f2ead6"), 1.3])  # 굵은 소금


## 튀김옷 알갱이: 줄을 따라 작은 혹.
static func _crisp(ctx: Dictionary, g: int, pts: Array, mat: int) -> void:
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	for q: Vector3 in pts:
		for i in 2:
			cl.bump(g, Vector2(q.x, q.y) + Vector2(rng.randf_range(-7, 7), rng.randf_range(-5, 5)), rng.randf_range(2.5, 4.5), rng.randf_range(2.0, 3.5), 2.5, mat, 2.0)


static func boar_rib_grill(ctx: Dictionary) -> void:
	ctx["table"] = Color("#563620")
	props(ctx, "ale", "knife", false, "")
	var z := Kit.board(ctx, C + Vector2(0, 8), 300.0, 130.0, -0.04)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var meat := Bits.roast(ctx, Color("#82300f"), 0.8)
	var bone := Kit.food(ctx, Color("#e8dcbc"), "bone", {"spec": 0.25})
	var g := cl.group()  # 통갈비 한 판: 뼈마다 불룩한 살이 녹아 붙은 덩어리 + 뼈 사이 칼집
	for k in 6:
		var x := C.x - 175 + k * 70
		var bow := sin((k + 0.5) / 6.0 * PI) * 12.0
		cl.ell(g, Vector3(x, C.y + 12 - bow, z + 8.0), 46.0, 58.0, 38.0, meat, 16.0, 0.08)
	for k in 6:
		var x := C.x - 175 + k * 70
		if k < 5:
			cl.groove(g, Vector2(x + 35, C.y - 38), Vector2(x + 33, C.y + 62), 6.0, 12.0)
		cl.groove(g, Vector2(x - 24, C.y + 2), Vector2(x + 18, C.y - 12), 3.0, 6.0)  # 그릴 자국
		cl.groove(g, Vector2(x - 26, C.y + 30), Vector2(x + 14, C.y + 16), 3.0, 6.0)
		var gb := cl.group()
		var root := Vector2(x - 4, C.y - 34 - sin((k + 0.5) / 6.0 * PI) * 12.0)
		var tip := root + Vector2(-8 + rng.randf_range(-4, 4), -30)
		cl.cap(gb, Vector3(root.x, root.y + 10, z + 38), Vector3(tip.x, tip.y, z + 40), 10.0, 9.0, bone, 2.0)
		cl.ell(gb, Vector3(tip.x, tip.y - 2, z + 41), 11.0, 8.0, 7.0, bone, 2.0)
		cl.ell(gb, Vector3(tip.x, tip.y - 2, z + 42), 6.0, 4.0, 3.0, Bits.roast(ctx, Color("#5a3a20")), 1.0)  # 그을린 끝
	var cut := cl.group()  # 앞에 잘라 놓은 한 대
	cl.ell(cut, Vector3(C.x + 150, C.y + 100, z + 20), 48.0, 22.0, 20.0, meat, 3.0, 0.25)
	cl.ell(cut, Vector3(C.x + 112, C.y + 92, z + 24), 15.0, 16.0, 16.0, Kit.food(ctx, Color("#c25a48"), "skin", {"spec": 0.5}), 2.0, 0.25)  # 잘린 면(분홍 속살)
	cl.cap(cl.group(), Vector3(C.x + 190, C.y + 112, z + 30), Vector3(C.x + 232, C.y + 122, z + 30), 8.0, 7.0, bone, 2.0)
	for k in 4:  # 흘러내린 양념
		cl.bump(cl.group(), Vector2(C.x - 150 + k * 90 + rng.randf_range(-15, 15), C.y + 70), 30.0, 10.0, 4.0, Bits.sauce(ctx, Color("#5e1a0a")), 3.0)
	Bits.sprig(ctx, C + Vector2(-230, 80), C + Vector2(-110, 110), z + 30.0, Bits.veg(ctx, Color("#3e5a2a"), 0.2))
	for k in 3:
		Bits.garlic(ctx, C + Vector2(-60 + k * 30, 100 + (k % 2) * 14), z + 16.0, 20.0, rng.randf() * TAU)
	Kit.dish(ctx, Vector2(650, 150), 34.0, Color("#c89a22"), "slime")  # 겨자
	ctx["dots"].append([C + Vector2(0, 10), 200.0, 60.0, 80, Color("#1c0e06"), 1.8])  # 후추
	ctx["dots"].append([C + Vector2(0, 10), 200.0, 60.0, 50, Color("#e8dcc0"), 1.3])  # 소금


static func honey_quail(ctx: Dictionary) -> void:
	props(ctx, "ale", "fork", true, "cloth", true)
	var z := Kit.plate(ctx, C, 240.0, "plate_blue")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var skin := Bits.roast(ctx, Color("#c0702a"), 0.95)
	var bone := Kit.food(ctx, Color("#eadcbc"), "bone", {"spec": 0.3})
	for k in 2:  # 꿀 바른 메추리 두 마리
		var c := C + Vector2(-80 + k * 160, -10 + k * 20)
		var g := cl.group()
		var zz := z + 20.0 + k * 6.0
		cl.ell(g, Vector3(c.x, c.y, zz), 78.0, 58.0, 54.0, skin, 6.0, 0.3 - k * 0.6)
		cl.ell(g, Vector3(c.x - 40, c.y - 18, zz + 10), 30.0, 22.0, 26.0, skin, 8.0)  # 가슴
		for s2: float in [-1.0, 1.0]:  # 다리
			var hip := c + Vector2(s2 * 30, 28)
			var knee := hip + Vector2(s2 * 34, 30)
			cl.cap(g, Vector3(hip.x, hip.y, zz + 20), Vector3(knee.x, knee.y, zz + 24), 24.0, 18.0, skin, 6.0)
			var gb := cl.group()
			var tip := knee + Vector2(s2 * 22, 18)
			cl.cap(gb, Vector3(knee.x, knee.y, zz + 26), Vector3(tip.x, tip.y, zz + 28), 7.0, 6.0, bone, 2.0)
			cl.ell(gb, Vector3(tip.x, tip.y, zz + 29), 8.0, 7.0, 6.0, bone, 2.0)
		cl.grooves(g, [c + Vector2(-50, -6), c + Vector2(0, 8), c + Vector2(46, -2)], 3.0, 5.0)
	var fig := Bits.veg(ctx, Color("#5a2448"), 0.5)
	for k in 2:  # 무화과 반쪽(붉은 속)
		var c := C + Vector2(150 - k * 300, 92 - k * 8)
		cl.ell(cl.group(), Vector3(c.x, c.y, z + 16), 36.0, 26.0, 22.0, fig, 3.0, 0.4)
		cl.slab(cl.group(), Kit.oval(c + Vector2(0, -4), 26.0, 17.0, 24), z + 30.0, 4.0, Bits.sauce(ctx, Color("#c8402e"), 0.7), 2.0, 8.0)
	Bits.balls(ctx, C + Vector2(0, 100), 70.0, 22.0, z + 16.0, 9, 13.0, Bits.veg(ctx, Color("#6a8a2e"), 0.9))  # 청포도
	Bits.sprig(ctx, C + Vector2(-60, -90), C + Vector2(40, -110), z + 60.0, Bits.veg(ctx, Color("#4a6a2a"), 0.2))


static func goat_cheese_soup(ctx: Dictionary) -> void:
	props(ctx, "", "spoon", true, "linen")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	Kit.plate(ctx, C + Vector2(0, 28), 250.0, "plate")
	var b := Kit.bowl(ctx, C, 190.0, "earthen", 0.5, 40.0)
	var g := Kit.surface(ctx, C, float(b[1]), float(b[0]) - 4.0, Bits.sauce(ctx, Color("#ecd284"), 0.6), 5.0)
	var cheese := Bits.sauce(ctx, Color("#fff0b8"), 0.9)
	for k in 5:  # 녹아 늘어진 치즈 줄
		var a := C + Vector2(rng.randf_range(-110, 110), rng.randf_range(-40, 40))
		cl.ridge(g, [a, a + Vector2(30, 6), a + Vector2(55, -4)], 7.0, 4.0, cheese, 3.0)
	var crust := Kit.m(ctx, "bread")
	for k in 3:  # 구운 빵 조각
		var c := C + Vector2(-70 + k * 70, -10 + (k % 2) * 30)
		Bits.lump(ctx, cl.group(), c, float(b[0]) + 2.0, 34.0, 22.0, 14.0, crust, rng.randf_range(-0.5, 0.5))
	Bits.scatter(ctx, C, 140.0, 60.0, float(b[0]) + 14.0, 26, 4.5, Bits.veg(ctx, Color("#5a8a2a"), 0.3))
	ctx["dots"].append([C, 140.0, 60.0, 70, Color("#24140a"), 1.6])
	ctx["steam"].append([C + Vector2(0, -20), 150.0])


static func black_mushroom_risotto(ctx: Dictionary) -> void:
	props(ctx, "ale", "spoon", false, "cloth", true)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var z := Kit.plate(ctx, C, 245.0, "plate")
	var g := cl.group()
	var rice := Kit.food(ctx, Color("#eadcae"), "bone", {"spec": 0.55, "tex": 0.2})
	cl.ell(g, Vector3(C.x, C.y, z + 2), 170.0, 82.0, 26.0, Bits.sauce(ctx, Color("#e0cc98"), 0.7), 6.0)
	Bits.grains(ctx, g, C, 160.0, 76.0, z + 14.0, 260, 5.0, rice)
	var cap := Bits.roast(ctx, Color("#4a2c18"), 0.8)
	var gill := Kit.food(ctx, Color("#c8a880"), "skin", {"spec": 0.3})
	for k in 7:  # 검은 버섯 저민 것
		var c := C + Vector2(rng.randf_range(-110, 110), rng.randf_range(-40, 40))
		var gm := cl.group()
		var rot := rng.randf_range(-0.8, 0.8)
		cl.ell(gm, Vector3(c.x, c.y, z + 34), 34.0, 20.0, 12.0, cap, 3.0, rot)
		cl.cap(gm, Vector3(c.x, c.y + 6, z + 40), Vector3(c.x + cos(rot + 1.6) * 22, c.y + 18, z + 40), 7.0, 6.0, gill, 2.0)
	ctx["dots"].append([C, 120.0, 50.0, 90, Color("#f6ecc8"), 2.0])  # 치즈 가루
	Bits.scatter(ctx, C, 150.0, 70.0, z + 52.0, 30, 4.5, Bits.veg(ctx, PARSLEY, 0.3))
	ctx["dots"].append([C, 150.0, 70.0, 60, Color("#20120a"), 1.5])
	ctx["steam"].append([C + Vector2(0, -30), 160.0])


static func mugwort_dumpling(ctx: Dictionary) -> void:
	props(ctx, "#6e7a2c", "", false, "linen")
	var cl: Clay = ctx["cl"]
	var z := Kit.board(ctx, C + Vector2(-20, 10), 250.0, 120.0, 0.05)
	var dough := Kit.food(ctx, Color("#6e8e3a"), "skin", {"spec": 0.35, "tex": 0.2, "mottle": Color("#9ab060"), "mottle_amt": 0.3})
	var spots := [Vector2(-130, 20), Vector2(-50, 40), Vector2(30, 30), Vector2(-90, -20), Vector2(-10, -14), Vector2(70, -18), Vector2(-50, -40)]
	for k in spots.size():
		var c: Vector2 = C + Vector2(-20, 10) + spots[k]
		var top := k >= 6
		cl.ell(cl.group(), Vector3(c.x, c.y - (26 if top else 0), z + 26 + (40 if top else 0) + c.y * 0.05), 40.0, 34.0, 32.0, dough, 3.0)
		ctx["dots"].append([c + Vector2(-6, -(30 if top else 4)), 30.0, 16.0, 70, Color("#e8c460"), 1.7])  # 콩고물
	ctx["dots"].append([C + Vector2(-20, 40), 190.0, 70.0, 120, Color("#d8b050"), 1.5])
	Kit.dish(ctx, C + Vector2(170, 20), 52.0, Color("#d89a28"), "slime", "plate", 40.0)  # 꿀
	Kit.cutlery(ctx, C + Vector2(150, 110), 150.0, 0.2, "spoon", "brass")


static func smoked_eel_rice(ctx: Dictionary) -> void:
	props(ctx, "#7a5a28", "spoon", false, "cloth", true)
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var b := Kit.bowl(ctx, C, 190.0, "earthen", 0.42)
	var g := Kit.surface(ctx, C, float(b[1]), float(b[0]) - 2.0, Kit.food(ctx, Color("#efe6d2"), "bone", {"spec": 0.4}), 10.0)
	Bits.grains(ctx, g, C, float(b[1]) * 0.95, float(b[1]) * 0.95 * Kit.SQ, float(b[0]) + 4.0, 320, 5.5, Kit.food(ctx, Color("#f4ecdc"), "bone", {"spec": 0.5}))
	var eel := Kit.food(ctx, Color("#a85a1e"), "slime", {"spec": 1.0, "mottle": Bits.SEAR, "mottle_amt": 0.45})
	for k in 3:  # 윤기 나는 장어 토막(납작한 살 + 껍질 쪽 짙은 테 + 숯불 자국)
		var c := C + Vector2(-100 + k * 98, -8 + (k % 2) * 14)
		var rot := rng.randf_range(-0.12, 0.12)
		var pts := PackedVector2Array()
		for q: Vector2 in [Vector2(-46, -26), Vector2(46, -30), Vector2(50, 24), Vector2(-44, 28)]:
			pts.append(c + q.rotated(rot))
		var ge := cl.group()
		cl.slab(ge, pts, float(b[0]) + 16.0 + k * 3.0, 12.0, eel, 3.0, 12.0)
		cl.ridge(ge, [c + Vector2(-44, -24).rotated(rot), c + Vector2(46, -28).rotated(rot)], 5.0, 3.0, Kit.food(ctx, Color("#2a1408"), "slime", {"spec": 0.9}))
		for t in 3:
			cl.groove(ge, c + Vector2(-30 + t * 30, -20).rotated(rot), c + Vector2(-38 + t * 30, 20).rotated(rot), 3.0, 4.0)
	cl.slab(cl.group(), Kit.oval(C + Vector2(130, 60), 36.0, 16.0, 16), float(b[0]) + 14.0, 6.0, Kit.food(ctx, Color("#e8908a"), "skin", {"spec": 0.5}), 2.0, 6.0)  # 초생강
	Bits.scatter(ctx, C, 140.0, 60.0, float(b[0]) + 44.0, 22, 6.0, Bits.veg(ctx, Color("#5e9a34"), 0.4), true)
	ctx["dots"].append([C, 150.0, 50.0, 60, Color("#f2ead0"), 1.6])  # 깨
	ctx["steam"].append([C + Vector2(0, -30), 160.0])


static func ginger_rye(ctx: Dictionary) -> void:
	props(ctx, "", "knife", false, "linen")
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var z := Kit.board(ctx, C + Vector2(-90, 30), 210.0, 110.0, -0.1)
	var rye := Kit.food(ctx, Color("#5a3220"), "skin", {"spec": 0.15, "tex": 0.6, "mottle": Color("#2a160c"), "mottle_amt": 0.5})
	var crust := Bits.roast(ctx, Color("#3a2010"), 0.3)
	for k in 3:  # 두툼한 호밀빵 조각 + 버터
		var c := C + Vector2(-180 + k * 80, 30 + (k % 2) * 16)
		var g := cl.group()
		cl.slab(g, Kit.oval(c, 54.0, 66.0, 24), z + 4.0 + k * 8.0, 10.0, crust, 2.0, 6.0)  # 겉껍질
		cl.slab(g, Kit.oval(c + Vector2(0, -2), 46.0, 57.0, 24), z + 10.0 + k * 8.0, 6.0, rye, 2.0, 8.0)  # 속살
		for i in 10:
			cl.carve(g, c + Vector2(rng.randf_range(-30, 30), rng.randf_range(-40, 40)), 3.0, 2.5, 3.0)  # 기공
		cl.slab(cl.group(), Kit.oval(c + Vector2(4, -6), 20.0, 13.0, 12), z + 30.0 + k * 8.0, 8.0, Kit.food(ctx, Color("#f6dc78"), "slime", {"spec": 0.8}), 2.0, 5.0)
	Kit.mug(ctx, C + Vector2(170, 60), 70.0, 120.0, "earthen", "#b8782a")  # 생강꿀차
	var gt := cl.group()
	for k in 3:  # 떠 있는 생강 조각
		var c := C + Vector2(150 + k * 22, -62 + (k % 2) * 6)
		cl.slab(gt, Kit.oval(c, 13.0, 7.0, 12), Kit.z0(C.y + 60) + 140.0, 2.0, Kit.food(ctx, Color("#e8d080"), "skin", {"spec": 0.4}), 2.0, 3.0)
	Kit.dish(ctx, C + Vector2(40, -120), 40.0, Color("#d89a28"), "slime")
	ctx["dots"].append([C + Vector2(-100, 30), 130.0, 50.0, 40, Color("#c8a070"), 1.4])  # 빵 부스러기
