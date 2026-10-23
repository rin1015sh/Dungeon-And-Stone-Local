extends RefCounted
## 음식 조각(Kit 위에 얹는다): 고기 덩이·갈비·잎·허브·레몬·쌀알·면·콩·열매·마늘·고추·꼬치.
## 색은 먹음직스럽게 — 구운 겉은 진한 갈색 + 탄 얼룩(mottle), 소스·꿀·국물은 번들(slime, spec), 채소는 맑은 색.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Kit := preload("res://tools/meal_art/Kit.gd")

const SEAR := Color("#3a1606")  ## 탄 자국


## 구운 고기 재질: 겉 색 c, 탄 얼룩, 기름 번들.
static func roast(ctx: Dictionary, c: Color, gloss: float = 0.45) -> int:
	return Kit.food(ctx, c, "leather", {"spec": gloss, "mottle": SEAR, "mottle_amt": 0.55, "tex": 0.3, "contrast": 1.1})


## 소스·꿀·국물(속이 비치는 번들).
static func sauce(ctx: Dictionary, c: Color, gloss: float = 1.0) -> int:
	return Kit.food(ctx, c, "slime", {"spec": gloss})


## 채소·잎(맑고 살짝 번들).
static func veg(ctx: Dictionary, c: Color, gloss: float = 0.3) -> int:
	return Kit.food(ctx, c, "skin", {"spec": gloss, "tex": 0.18})


## 덩이 하나(고기·감자·만두): 타원체 + 칼자국/그릴 자국(sear 줄 수).
static func lump(ctx: Dictionary, g: int, c: Vector2, z: float, rx: float, ry: float, rz: float, mat: int, rot: float = 0.0, sear: int = 0) -> void:
	var cl: Clay = ctx["cl"]
	cl.ell(g, Vector3(c.x, c.y, z), rx, ry, rz, mat, 3.0, rot)
	var d := Vector2.from_angle(rot + PI * 0.5)
	for k in sear:
		var o := Vector2.from_angle(rot) * rx * (-0.5 + k * (1.0 / maxf(1, sear - 1)) if sear > 1 else 0.0)
		cl.groove(g, c + o - d * ry * 0.6, c + o + d * ry * 0.6, rx * 0.05, rz * 0.18)


## 잎 하나(허브·상추·민트): 납작한 타원 + 가운데 잎맥.
static func leaf(ctx: Dictionary, c: Vector2, z: float, s: float, rot: float, mat: int) -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	cl.ell(g, Vector3(c.x, c.y, z), s, s * 0.42, s * 0.18, mat, 2.0, rot)
	var d := Vector2.from_angle(rot) * s * 0.8
	cl.groove(g, c - d, c + d, s * 0.06, s * 0.06)


## 허브 가지(로즈메리·딜): 줄기 + 잎 여럿.
static func sprig(ctx: Dictionary, a: Vector2, b: Vector2, z: float, mat: int, fine: bool = true) -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	var len := a.distance_to(b)
	cl.cap(g, Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), len * 0.02, len * 0.012, mat, 1.0)
	var d := (b - a) / maxf(1.0, len)
	var n := Vector2(-d.y, d.x)
	var count := 10 if fine else 5
	for k in count:
		var t := (k + 0.5) / count
		var q := a.lerp(b, t)
		for s: float in [-1.0, 1.0]:
			var tip := q + (n * s * 0.7 + d * 0.5) * len * (0.16 if fine else 0.22) * (1.0 - t * 0.4)
			cl.cap(g, Vector3(q.x, q.y, z + 1), Vector3(tip.x, tip.y, z + 1), len * (0.022 if fine else 0.04), len * 0.008, mat, 1.0)


## 흩뿌린 잎·파 조각(작은 고리·조각).
static func scatter(ctx: Dictionary, c: Vector2, rx: float, ry: float, z: float, n: int, s: float, mat: int, ring: bool = false) -> void:
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var g := cl.group()
	for k in n:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf())
		var q := c + Vector2(cos(a) * rx * r, sin(a) * ry * r)
		cl.ell(g, Vector3(q.x, q.y, z), s * rng.randf_range(0.7, 1.2), s * rng.randf_range(0.4, 0.8), s * 0.4, mat, 1.0, rng.randf() * PI)
		if ring:
			cl.carve(g, q, s * 0.4, s * 0.25, s * 0.5)


## 레몬 조각(반달 쐐기): 껍질 + 과육 면.
static func lemon(ctx: Dictionary, c: Vector2, z: float, s: float, rot: float) -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	cl.ell(g, Vector3(c.x, c.y, z), s, s * 0.55, s * 0.45, veg(ctx, Color("#e8c22c"), 0.5), 3.0, rot)
	var g2 := cl.group()
	var d := Vector2.from_angle(rot - PI * 0.5) * s * 0.12
	cl.slab(g2, Kit.oval(c + d, s * 0.82, s * 0.32, 24), z + s * 0.32, 3.0, Kit.food(ctx, Color("#f4e27a"), "slime", {"spec": 0.9}), 2.0, 4.0)
	for k in 4:
		var a := rot + PI + (k + 0.5) * PI / 4.0
		cl.groove(g2, c + d, c + d + Vector2.from_angle(a) * Vector2(s * 0.8, s * 0.3), s * 0.03, 2.0)


## 쌀·곡물 낟알(죽·밥): 영역 안에 작은 알 여럿.
static func grains(ctx: Dictionary, g: int, c: Vector2, rx: float, ry: float, z: float, n: int, s: float, mat: int) -> void:
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	for k in n:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf())
		var q := c + Vector2(cos(a) * rx * r, sin(a) * ry * r)
		cl.ell(g, Vector3(q.x, q.y, z + (1.0 - r) * s * 2.0), s, s * 0.55, s * 0.5, mat, 1.5, rng.randf() * PI)


## 둥근 알(콩·열매·완두): 영역 안에.
static func balls(ctx: Dictionary, c: Vector2, rx: float, ry: float, z: float, n: int, s: float, mat: int, own_group: bool = true) -> void:
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var g := cl.group()
	for k in n:
		if own_group and k % 6 == 0:
			g = cl.group()
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf())
		var q := c + Vector2(cos(a) * rx * r, sin(a) * ry * r)
		var ss := s * rng.randf_range(0.8, 1.15)
		cl.ell(g, Vector3(q.x, q.y, z + (1.0 - r) * s), ss, ss * 0.9, ss * 0.85, mat, 1.0)


## 면(국수): 국물 위로 굽이치는 가는 줄 여럿.
static func noodles(ctx: Dictionary, g: int, c: Vector2, rx: float, ry: float, z: float, n: int, w: float, mat: int) -> void:
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	for k in n:
		var pts: Array = []
		var y := c.y - ry * 0.8 + k * ry * 1.6 / n + rng.randf_range(-4, 4)
		var ph := rng.randf() * TAU
		var span := sqrt(maxf(0.0, 1.0 - pow((y - c.y) / ry, 2.0))) * rx * 0.95
		for i in 9:
			var t := i / 8.0
			pts.append(Vector2(c.x - span + span * 2.0 * t, y + sin(t * 7.0 + ph) * ry * 0.12))
		cl.ridge(g, pts, w, w * 0.9, mat, 1.5)
		z += 0.0


## 마늘 한 쪽(흰 통마늘 — 구워 갈색 끝).
static func garlic(ctx: Dictionary, c: Vector2, z: float, s: float, rot: float) -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	cl.ell(g, Vector3(c.x, c.y, z), s, s * 0.7, s * 0.6, veg(ctx, Color("#e6d4a6"), 0.35), 3.0, rot)
	var tip := c + Vector2.from_angle(rot) * s * 0.9
	cl.ell(g, Vector3(tip.x, tip.y, z + 1), s * 0.3, s * 0.25, s * 0.25, roast(ctx, Color("#8a5222")), 2.0)
	cl.groove(g, c - Vector2.from_angle(rot) * s * 0.7, tip, s * 0.06, s * 0.08)


## 고추(빨갛고 번들 — 말린 것·썬 것).
static func chili(ctx: Dictionary, a: Vector2, b: Vector2, z: float, r: float) -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	var mid := a.lerp(b, 0.5) + Vector2(0, -r * 0.6)
	cl.chain(g, [Vector3(a.x, a.y, z), Vector3(mid.x, mid.y, z + r * 0.3), Vector3(b.x, b.y, z)], [r, r * 0.8, r * 0.2], veg(ctx, Color("#b8261a"), 0.8), 2.0)
	cl.cap(g, Vector3(a.x, a.y, z + 1), Vector3(a.x - (b.x - a.x) * 0.12, a.y - 4, z + 1), r * 0.45, r * 0.3, veg(ctx, Color("#4a6a22")), 1.0)


## 꼬치(나무 막대 + 덩이들): ends = [시작, 끝], pieces = [[재질, 크기] …] 차례로 꿴다.
static func skewer(ctx: Dictionary, a: Vector2, b: Vector2, z: float, pieces: Array) -> void:
	var cl: Clay = ctx["cl"]
	var gs := cl.group()
	cl.cap(gs, Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), 3.0, 2.0, Kit.m(ctx, "stick"), 1.0)
	var g := cl.group()
	var n := pieces.size()
	var rng: RandomNumberGenerator = ctx["rng"]
	var rot := (b - a).angle()
	for k in n:
		var pc: Array = pieces[k]
		var q := a.lerp(b, 0.16 + 0.72 * (k + 0.5) / n)
		var s: float = pc[1]
		lump(ctx, g, q, z + s * 0.3, s, s * 0.82, s * 0.7, pc[0], rot + rng.randf_range(-0.3, 0.3), 2 if pc.size() > 2 and pc[2] else 0)
		if pc.size() > 2 and pc[2]:  # 고기는 모난 덩이(혹 하나 더)
			var o := Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)) * s
			cl.ell(g, Vector3(q.x + o.x, q.y + o.y - s * 0.2, z + s * 0.5), s * 0.7, s * 0.6, s * 0.6, pc[0], 2.0, rng.randf() * PI)
	Kit.shadow(ctx, a.lerp(b, 0.5), a.distance_to(b) * 0.5, 14.0, 0.45)


## 혼자 놓인 줄(꿀 줄기·양파 고리·사과 조각·실고추): 점들을 잇는 캡슐 줄(깊이 z). ridge는 이미 빚은 표면 위에만 붙으니 빈 자리엔 이것.
static func rope(ctx: Dictionary, pts: Array, z: float, r: float, mat: int) -> void:
	var cl: Clay = ctx["cl"]
	var p3: Array = []
	var rs: Array = []
	for q: Vector2 in pts:
		p3.append(Vector3(q.x, q.y, z))
		rs.append(r)
	cl.chain(cl.group(), p3, rs, mat, 2.0)
