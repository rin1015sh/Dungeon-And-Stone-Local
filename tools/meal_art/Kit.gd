extends RefCounted
## 음식 그림 부품 — 그릇·도구·탁자 위 소품(사용자 요청 2026-10-23 "식사하면 여관 테이블이 화면을 꽉 채우고 그 위에 음식이").
## 화면은 앉아서 내려다본 3/4 시점: 둥근 것은 세로로 눌린 타원(SQ), 화면 아래(앞)에 있을수록 앞(z — ZK).
## 좌표 = 캔버스 px(960×540). ctx = MealArt.paint가 만든 사전: cl · p · rng · mats(이름 → 재질 번호 캐시) · shadows · steam · dots · glows.

const Clay := preload("res://tools/monster_art/Clay.gd")

const SQ := 0.52  ## 원근 눌림(위에서 비스듬히 본 원 = 타원 세로/가로)
const ZK := 0.6  ## 화면 아래로 1px 갈 때 앞으로 나오는 깊이

## 재질 이름 → [색, Kinds 종류, 옵션]. 음식은 채도를 살려 둔다(먹음직스럽게 — 그릇·탁자는 탁하게).
const MATS := {
	"plate": [Color("#d8ccb4"), "bone", {"spec": 0.4, "tex": 0.08, "cav": 0.25}],
	"plate_blue": [Color("#8a98a4"), "bone", {"spec": 0.45, "tex": 0.08, "cav": 0.25}],
	"plate_dark": [Color("#3a3431"), "stone", {"spec": 0.4, "tex": 0.15, "cav": 0.25}],
	"earthen": [Color("#6a4028"), "stone", {"spec": 0.35, "tex": 0.2, "cav": 0.3}],
	"board": [Color("#8c6038"), "wood", {"cav": 0.25}],
	"wood_bowl": [Color("#6a4226"), "wood", {"spec": 0.12, "cav": 0.3}],
	"iron": [Color("#3a3836"), "metal", {"spec": 0.45}],
	"pewter": [Color("#8e908a"), "metal", {"spec": 0.6}],
	"brass": [Color("#b08a40"), "metal", {"spec": 0.75}],
	"silver": [Color("#b4b8b8"), "metal", {"spec": 0.8}],
	"stick": [Color("#a07a4a"), "wood"],
	"candle": [Color("#e4d6b0"), "bone", {"spec": 0.2, "tex": 0.05}],
	"flame": [Color("#ffd27a"), "glow"],
	"cloth": [Color("#9a3e32"), "cloth", {"cav": 0.4}],
	"linen": [Color("#c8bea4"), "cloth", {"cav": 0.4}],
	"ale": [Color("#a8641c"), "slime", {"spec": 0.8}],
	"foam": [Color("#f2e6cc"), "skin", {"spec": 0.15, "tex": 0.25, "cav": 0.5}],
	"tankard": [Color("#6a4a2e"), "wood", {"cav": 0.4}],
	"bread": [Color("#b8783a"), "skin", {"spec": 0.15, "tex": 0.3, "mottle": Color("#5a2c12"), "mottle_amt": 0.35}],
	"crumb": [Color("#e2c48a"), "bone", {"tex": 0.4}],
	"salt": [Color("#ece6da"), "bone", {"tex": 0.5}],
}


## 재질 번호(이름으로 한 번 만들고 다시 쓴다). 표에 없으면 col·kind·opts로 새로.
static func m(ctx: Dictionary, name: String, col: Color = Color.WHITE, kind: String = "skin", opts: Dictionary = {}) -> int:
	var cache: Dictionary = ctx["mats"]
	if cache.has(name):
		return cache[name]
	var cl: Clay = ctx["cl"]
	var d: Array = MATS.get(name, [col, kind, opts])
	var id := cl.mat(d[0], d[1], d[2] if d.size() > 2 else {})
	cache[name] = id
	return id


## 새 재질(이름 없이 그때그때).
static func food(ctx: Dictionary, col: Color, kind: String = "skin", opts: Dictionary = {}) -> int:
	var cl: Clay = ctx["cl"]
	return cl.mat(col, kind, opts)


## 탁자에 놓인 자리 y의 바닥 깊이.
static func z0(y: float) -> float:
	return y * ZK


## 눌린 타원 다각형(탁자 위 원).
static func oval(c: Vector2, rx: float, ry: float, n: int = 40) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


## 탁자에 지는 그림자(빛은 왼쪽 위 — 오른쪽 아래로 번진다). 칠하기 전에 MealArt가 탁자 위에 깐다.
static func shadow(ctx: Dictionary, c: Vector2, rx: float, ry: float, k: float = 0.6) -> void:
	ctx["shadows"].append([c + Vector2(rx * 0.12, ry * 0.25), rx * 1.08, ry * 1.15, k])


## 접시: 둥근 판(가장자리 둥글게) + 가운데를 얕게 파낸 우물 + 아래 굽 그늘. 돌려주는 값 = 음식 놓는 깊이.
static func plate(ctx: Dictionary, c: Vector2, r: float, mat_name: String = "plate", well: float = 0.72) -> float:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	var z := z0(c.y)
	var mm := m(ctx, mat_name)
	cl.slab(g, oval(c + Vector2(0, r * 0.05), r * 0.98, r * SQ * 0.98), z - 6.0, 4.0, mm, 2.0, r * 0.05)
	cl.slab(g, oval(c, r, r * SQ), z, 6.0, mm, 3.0, r * 0.12)
	cl.carve(g, c, r * well, r * well * SQ, r * 0.05)
	var ring: Array = []
	for i in 49:
		var a := TAU * i / 48
		ring.append(c + Vector2(cos(a) * r * 0.86, sin(a) * r * 0.86 * SQ))
	cl.ridge(g, ring, r * 0.07, r * 0.025, mm, 3.0)  # 둥근 테
	if mat_name == "plate":  # 테에 두른 푸른 유약 줄(칠한 뒤 MealArt가 그린다)
		ctx["rims"].append([c, r * 0.93, r * 0.93 * SQ, Color("#3e6488")])
		ctx["rims"].append([c, r * 0.8, r * 0.8 * SQ, Color("#3e6488")])
	shadow(ctx, c, r, r * SQ, 0.55)
	return z + 4.0


## 그릇(국·죽): 바깥 배(테 아래로 불룩 — 테보다 뒤) + 바닥 판 + 둥근 테(입술). 돌려주는 값 = [국물 깊이, 국물 반지름].
## lift = 받침(접시) 위에 놓을 때 올리는 깊이.
static func bowl(ctx: Dictionary, c: Vector2, r: float, mat_name: String = "earthen", tall: float = 0.55, lift: float = 0.0) -> Array:
	var cl: Clay = ctx["cl"]
	var z := z0(c.y) + lift
	var mm := m(ctx, mat_name)
	var gb := cl.group()
	var belly := r * tall
	cl.ell(gb, Vector3(c.x, c.y + belly * 0.55, z - r * 0.75), r * 0.97, r * SQ + belly * 0.55, r * 0.45, mm, 4.0)
	cl.slab(gb, oval(c + Vector2(0, belly * 0.95), r * 0.45, r * 0.45 * SQ), z - r * 0.5, 4.0, mm, 2.0, 4.0)  # 굽
	var gr := cl.group()
	cl.slab(gr, oval(c, r, r * SQ), z - 20.0, 5.0, mm, 3.0, r * 0.05)
	var ring: Array = []
	for i in 57:
		var a := TAU * i / 56
		ring.append(c + Vector2(cos(a) * r * 0.95, sin(a) * r * 0.95 * SQ))
	cl.ridge(gr, ring, r * 0.055, 18.0, mm, 3.0)
	shadow(ctx, c + Vector2(0, belly * 0.6), r, r * SQ + belly * 0.4, 0.6)
	return [z - 12.0, r * 0.89]


## 국물·죽 면(그릇 안): 평평한 판 + 가운데 살짝 볼록. 돌려주는 값 = 그룹(건더기를 얹는다).
static func surface(ctx: Dictionary, c: Vector2, r: float, z: float, mat_id: int, swell: float = 3.0) -> int:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	cl.slab(g, oval(c, r, r * SQ), z, swell, mat_id, 2.0, r * 0.4)
	return g


## 도마·나무 판(모서리 둥근 사각형, 눌림).
static func board(ctx: Dictionary, c: Vector2, hw: float, hh: float, rot: float = 0.0, mat_name: String = "board") -> float:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	var z := z0(c.y)
	var pts := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36
		var sx := signf(cos(a)) * pow(absf(cos(a)), 0.35)
		var sy := signf(sin(a)) * pow(absf(sin(a)), 0.35)
		pts.append(c + Vector2(sx * hw, sy * hh).rotated(rot) * Vector2(1, 1))
	cl.slab(g, pts, z, 8.0, m(ctx, mat_name), 2.0, 10.0)
	for k in 3:  # 나뭇결 골
		var y := c.y - hh * 0.5 + k * hh * 0.45
		cl.groove(g, Vector2(c.x - hw * 0.8, y), Vector2(c.x + hw * 0.8, y + 4), 2.5, 2.0)
	shadow(ctx, c, hw, hh, 0.55)
	return z + 8.0


## 잔(맥주·차): 화면 위로 선 나무 잔(쇠테 둘) + 손잡이 + 위에 거품 왕관(맥주) 또는 김 나는 차. 바닥 가운데 = base.
## mat_name = 잔 재질(tankard 나무 · pewter 쇠 · earthen 질그릇), drink = "ale" 또는 차 색(#rrggbb).
static func mug(ctx: Dictionary, base: Vector2, r: float, ht: float, mat_name: String = "tankard", drink: String = "ale") -> void:
	var cl: Clay = ctx["cl"]
	var z := z0(base.y) + r
	var g := cl.group()
	var mm := m(ctx, mat_name)
	cl.cap(g, Vector3(base.x, base.y - r * SQ * 0.4, z), Vector3(base.x, base.y - ht, z), r * 1.04, r * 0.92, mm, 3.0, 0.85)
	if mat_name == "tankard":
		for t: float in [0.16, 0.8]:  # 쇠테
			cl.ridge(g, [Vector2(base.x - r * 1.02, base.y - ht * t + 2), Vector2(base.x, base.y - ht * t + r * 0.12), Vector2(base.x + r * 1.02, base.y - ht * t + 2)], r * 0.09, r * 0.08, m(ctx, "iron"))
		for k in 3:  # 널 이음 골
			var x := base.x - r * 0.55 + k * r * 0.55
			cl.groove(g, Vector2(x, base.y - ht * 0.75), Vector2(x, base.y - ht * 0.2), 1.5, 2.0)
	var gh := cl.group()
	var hx := base.x + r * 0.9
	cl.chain(gh, [Vector3(hx, base.y - ht * 0.78, z - 2), Vector3(hx + r * 0.6, base.y - ht * 0.74, z - 2), Vector3(hx + r * 0.66, base.y - ht * 0.36, z - 2), Vector3(hx, base.y - ht * 0.28, z - 2)],
		[r * 0.16, r * 0.15, r * 0.15, r * 0.16], mm, 2.0)
	var top := Vector2(base.x, base.y - ht)
	var gt := cl.group()
	if drink == "ale":
		var foam := m(ctx, "foam")
		cl.ell(gt, Vector3(top.x, top.y - r * 0.12, z + r * 0.75), r * 1.02, r * 0.62, r * 0.5, foam, 4.0)
		var rng: RandomNumberGenerator = ctx["rng"]
		for k in 7:  # 몽글몽글한 거품
			var q := top + Vector2(rng.randf_range(-r * 0.75, r * 0.75), rng.randf_range(-r * 0.4, r * 0.15))
			cl.bump(gt, q, r * rng.randf_range(0.22, 0.34), r * rng.randf_range(0.18, 0.26), r * 0.14, foam, 4.0)
		cl.bump(gt, top + Vector2(-r * 0.9, r * 0.35), r * 0.18, r * 0.45, r * 0.12, foam, 3.0)  # 흘러내린 거품
	else:
		cl.slab(gt, oval(top, r * 0.88, r * 0.88 * SQ), z + r * 0.95, 1.0, food(ctx, Color(drink), "slime", {"spec": 1.0}), 2.0, 4.0)
		ctx["steam"].append([top, r * 1.2])
	shadow(ctx, base, r * 1.15, r * SQ * 1.1, 0.7)


## 촛대: 받침 접시 + 초 + 불꽃(빛 번짐).
static func candle(ctx: Dictionary, base: Vector2, ht: float) -> void:
	var cl: Clay = ctx["cl"]
	var z := z0(base.y)
	var g := cl.group()
	cl.slab(g, oval(base, ht * 0.32, ht * 0.32 * SQ), z, 4.0, m(ctx, "brass"), 2.0, 5.0)
	var gc := cl.group()
	var r := ht * 0.09
	cl.cap(gc, Vector3(base.x, base.y - 2, z + r), Vector3(base.x, base.y - ht, z + r), r, r * 0.95, m(ctx, "candle"), 2.0)
	cl.bump(gc, Vector2(base.x - r * 0.6, base.y - ht * 0.7), r * 0.35, r * 0.9, r * 0.3, m(ctx, "candle"))  # 흘러내린 촛농
	var fl := Vector2(base.x, base.y - ht - r * 1.6)
	cl.ell(cl.group(), Vector3(fl.x, fl.y, z + r * 3.0), r * 0.45, r * 1.3, r * 0.4, m(ctx, "flame"), 2.0)
	ctx["glows"].append([fl, ht * 2.2, Color("#ffb45c"), 0.55])
	ctx["glows"].append([fl, ht * 0.5, Color("#fff0c0"), 0.5])
	shadow(ctx, base, ht * 0.32, ht * 0.32 * SQ, 0.5)


## 빵 덩이(둥근 빵 + 칼집).
static func roll(ctx: Dictionary, c: Vector2, r: float, rot: float = 0.0) -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	cl.ell(g, Vector3(c.x, c.y, z0(c.y) + r * 0.2), r, r * 0.72, r * 0.6, m(ctx, "bread"), 3.0, rot)
	var d := Vector2.from_angle(rot + 0.6) * r * 0.55
	cl.groove(g, c - d, c + d, r * 0.1, r * 0.12)
	shadow(ctx, c, r, r * 0.6, 0.6)


## 숟가락·포크·칼(탁자·냅킨 위에 누운 것): 나무 자루 + 쇠 머리.
static func cutlery(ctx: Dictionary, c: Vector2, length: float, rot: float, kind: String = "spoon", mat_name: String = "pewter") -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	var z := z0(c.y) + 12.0
	var d := Vector2.from_angle(rot)
	var n := Vector2(-d.y, d.x)
	var a := c - d * length * 0.5
	var b := c + d * length * 0.5
	var mm := m(ctx, mat_name)
	var mid := a + d * length * 0.42
	cl.cap(g, Vector3(a.x, a.y, z), Vector3(mid.x, mid.y, z), length * 0.045, length * 0.038, m(ctx, "tankard"), 2.0, 0.7)
	cl.ridge(g, [mid - n * length * 0.04, mid + n * length * 0.04], length * 0.012, length * 0.01, m(ctx, "brass"))
	var head := b - d * length * 0.14
	match kind:
		"spoon":
			cl.cap(g, Vector3(mid.x, mid.y, z), Vector3(head.x, head.y, z), length * 0.018, length * 0.014, mm, 2.0, 0.6)
			cl.ell(g, Vector3(head.x, head.y, z), length * 0.14, length * 0.085, length * 0.035, mm, 3.0, rot)
			cl.carve(g, head, length * 0.1, length * 0.055, length * 0.025, rot)
		"knife":
			cl.slab(g, PackedVector2Array([mid + n * length * 0.035, b - d * length * 0.08 + n * length * 0.04, b, b - d * length * 0.06 - n * length * 0.02, mid - n * length * 0.03]), z, 3.0, mm, 2.0, 4.0)
		"fork":
			cl.cap(g, Vector3(mid.x, mid.y, z), Vector3(head.x, head.y, z), length * 0.018, length * 0.016, mm, 2.0, 0.6)
			cl.slab(g, PackedVector2Array([head - d * length * 0.05 + n * length * 0.05, head + d * length * 0.03 + n * length * 0.05, head + d * length * 0.03 - n * length * 0.05, head - d * length * 0.05 - n * length * 0.05]), z, 2.0, mm, 2.0, 3.0)
			for k in 4:
				var o := n * length * (-0.04 + k * 0.0267)
				cl.cap(g, Vector3(head.x + o.x, head.y + o.y, z + 1), Vector3(b.x + o.x, b.y + o.y, z + 1), length * 0.009, length * 0.007, mm, 1.0)
	ctx["shadows"].append([c + Vector2(4, 6), length * 0.5, length * 0.05, 0.45])


## 접은 천(냅킨): 비스듬히 놓인 천 + 접힌 모서리 + 주름 골.
static func napkin(ctx: Dictionary, c: Vector2, s: float, rot: float, mat_name: String = "linen") -> void:
	var cl: Clay = ctx["cl"]
	var g := cl.group()
	var mm := m(ctx, mat_name)
	var pts := PackedVector2Array()
	for q: Vector2 in [Vector2(-1, -0.55), Vector2(-0.2, -0.75), Vector2(1, -0.62), Vector2(1.08, 0.5), Vector2(0.1, 0.7), Vector2(-0.95, 0.62)]:
		pts.append(c + (q * Vector2(s, s * SQ * 1.4)).rotated(rot))
	cl.slab(g, pts, z0(c.y), 6.0, mm, 2.0, 12.0)
	var fold := PackedVector2Array()
	for q: Vector2 in [Vector2(0.35, -0.68), Vector2(1.0, -0.6), Vector2(1.04, 0.1)]:
		fold.append(c + (q * Vector2(s, s * SQ * 1.4)).rotated(rot))
	cl.slab(g, fold, z0(c.y) + 6.0, 4.0, mm, 2.0, 6.0)  # 접혀 올라온 모서리
	for k in 3:
		var y := -0.3 + k * 0.3
		cl.groove(g, c + Vector2(-s * 0.8, s * y * SQ).rotated(rot), c + Vector2(s * 0.6, s * (y + 0.12) * SQ).rotated(rot), 5.0, 3.0)
	shadow(ctx, c, s * 1.05, s * SQ * 1.1, 0.45)


## 소금 종지·작은 그릇(양념).
## lift = 도마·접시 위에 놓을 때.
static func dish(ctx: Dictionary, c: Vector2, r: float, fill: Color, kind: String = "bone", mat_name: String = "plate", lift: float = 0.0) -> void:
	var b := bowl(ctx, c, r, mat_name, 0.4, lift)
	surface(ctx, c, float(b[1]), float(b[0]) - 3.0, food(ctx, fill, kind, {"spec": 0.5 if kind == "slime" else 0.1, "tex": 0.4}), 4.0)
