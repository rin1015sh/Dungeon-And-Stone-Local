extends RefCounted
## 도시 건물 잡템 그림(CT74 — 건물 안 가구를 뒤져 얻는 것): 쇳조각 · 녹슨 못 · 부러진 칼날 · 낱장 종이 · 양초 토막 · 노끈 타래 · 부러진 화살촉.
## Junk.paint가 BY_ID에 없으면 부른다. 색 = 아이템 color. Clay(3D 덩어리) → ItemArt가 칠한다.

const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")

const BY_ID := {"iron_scrap": "scrap", "rusty_nails": "nails", "broken_blade": "broken_blade", "loose_pages": "pages", "torn_bounty": "pages",
	"candle_stub": "candle", "twine": "twine", "broken_arrowhead": "arrowheads"}


static func paint(id: String, ctx: Dictionary) -> bool:
	match str(BY_ID.get(id, "")):
		"scrap":
			scrap(ctx)
		"nails":
			nails(ctx)
		"broken_blade":
			broken_blade(ctx)
		"pages":
			pages(ctx, id == "torn_bounty")
		"candle":
			candle(ctx)
		"twine":
			twine(ctx)
		"arrowheads":
			arrowheads(ctx)
		_:
			return false
	return true


## 쇳조각: 모가 난 쇳덩이 둘(하나는 비스듬히) — 자른 면은 밝게.
static func scrap(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m := cl.mat(Color(ctx["c"]).darkened(0.15), "metal", {"spec": 0.5})
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.14, 0.52), Vector2(0.46, 0.3), Vector2(0.6, 0.42), Vector2(0.52, 0.7), Vector2(0.22, 0.78)]), 0.04 * W, 0.06 * W, m, 1.0, 0.04 * W)
	var g2 := cl.group()
	cl.slab(g2, F.poly(ctx, [Vector2(0.5, 0.22), Vector2(0.86, 0.3), Vector2(0.8, 0.56), Vector2(0.58, 0.5)]), 0.08 * W, 0.05 * W, m, 1.0, 0.03 * W)
	cl.groove(g2, F.Q(ctx, 0.56, 0.3), F.Q(ctx, 0.8, 0.38), 0.012 * W, 0.012 * W)


## 녹슨 못 한 줌: 머리 달린 가는 못 다섯이 흩어져 눕는다.
static func nails(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m := cl.mat(Color(ctx["c"]).darkened(0.2), "metal", {"spec": 0.3})
	for q: Array in [[0.2, 0.3, 0.7, 0.42], [0.18, 0.58, 0.66, 0.5], [0.3, 0.8, 0.8, 0.68], [0.5, 0.2, 0.82, 0.6], [0.26, 0.44, 0.5, 0.86]]:
		var g := cl.group()
		var a := F.Q3(ctx, q[0], q[1], 0.06)
		var b := F.Q3(ctx, q[2], q[3], 0.06)
		cl.cap(g, a, b, 0.022 * W, 0.008 * W, m, 2.0)
		cl.ell(g, a, 0.04 * W, 0.04 * W, 0.015 * W, m, 2.0)


## 부러진 칼날: 끝이 날카롭고 반대쪽은 들쭉날쭉 부러진 날 조각 + 가운데 홈.
static func broken_blade(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m := cl.mat(Color(ctx["c"]), "metal", {"spec": 0.8})
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.12, 0.86), Vector2(0.18, 0.7), Vector2(0.76, 0.16), Vector2(0.86, 0.12), Vector2(0.84, 0.24), Vector2(0.3, 0.84), Vector2(0.24, 0.8)]),
		0.03 * W, 0.04 * W, m, 1.0, 0.02 * W)
	cl.groove(g, F.Q(ctx, 0.26, 0.76), F.Q(ctx, 0.76, 0.22), 0.014 * W, 0.01 * W)


## 낱장 종이(겹친 두세 장 — 수배서면 붉은 밀랍 자국): 귀가 접힌 종이 + 글 줄.
static func pages(ctx: Dictionary, bounty: bool) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var paper := cl.mat(Color(ctx["c"]), "cloth")
	for k in 2:
		var g := cl.group()
		var o := k * 0.1
		cl.slab(g, F.poly(ctx, [Vector2(0.18 + o, 0.2 + o * 0.5), Vector2(0.72 + o, 0.16 + o * 0.5), Vector2(0.78 + o, 0.78), Vector2(0.24 + o, 0.84)]),
			0.02 * W + k * 0.02 * W, 0.02 * W, paper, 1.0, 0.01 * W)
		for l in 4:
			var y := 0.32 + l * 0.12
			cl.groove(g, F.Q(ctx, 0.3 + o, y), F.Q(ctx, 0.66 + o, y - 0.02), 0.01 * W, 0.006 * W)
	if bounty:
		cl.ell(cl.group(), F.Q3(ctx, 0.62, 0.3, 0.07), 0.06 * W, 0.05 * W, 0.02 * W, cl.mat(Color("#8a2a24"), "skin"), 2.0)


## 양초 토막: 흘러내린 밀랍이 붙은 짧은 초 + 그을린 심지.
static func candle(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var wax := cl.mat(Color(ctx["c"]), "skin", {"spec": 0.3})
	var g := cl.group()
	cl.cap(g, F.Q3(ctx, 0.5, 0.82, 0.08), F.Q3(ctx, 0.5, 0.36, 0.08), 0.12 * W, 0.11 * W, wax, 3.0)
	cl.ell(g, F.Q3(ctx, 0.5, 0.84, 0.08), 0.2 * W, 0.06 * W, 0.12 * W, wax, 3.0)
	cl.ell(g, F.Q3(ctx, 0.62, 0.5, 0.12), 0.04 * W, 0.09 * W, 0.04 * W, wax, 2.0)  # 흘러내린 밀랍
	cl.cap(cl.group(), F.Q3(ctx, 0.5, 0.36, 0.1), F.Q3(ctx, 0.52, 0.24, 0.1), 0.012 * W, 0.008 * W, cl.mat(Color("#1e1a16"), "cloth"), 2.0)


## 노끈 타래: 감은 고리 셋 + 풀린 끝.
static func twine(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m := cl.mat(Color(ctx["c"]), "cloth")
	var g := cl.group()
	for k in 3:
		var pts: Array = []
		var radii: Array = []
		for i in 17:
			var a := TAU * i / 16.0
			pts.append(F.Q3(ctx, 0.5 + cos(a) * (0.26 - k * 0.04), 0.52 + sin(a) * (0.18 - k * 0.03), 0.06 + k * 0.02))
			radii.append(0.028 * W)
		cl.chain(g, pts, radii, m, 2.0)
	cl.cap(g, F.Q3(ctx, 0.74, 0.56, 0.08), F.Q3(ctx, 0.9, 0.82, 0.04), 0.024 * W, 0.02 * W, m, 2.0)


## 부러진 화살촉 셋: 세모 쇠촉 + 짧게 부러진 화살대.
static func arrowheads(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m := cl.mat(Color(ctx["c"]).darkened(0.1), "metal", {"spec": 0.5})
	var wood := cl.mat(Color("#6a4a2e"), "wood")
	for q: Array in [[0.3, 0.7, 0.2, 0.28], [0.58, 0.8, 0.62, 0.36], [0.78, 0.62, 0.86, 0.22]]:
		var tip := Vector2(q[2], q[3])
		var base := Vector2(q[0], q[1])
		var d := (tip - base).normalized()
		var side := Vector2(-d.y, d.x) * 0.07
		var head := base + (tip - base) * 0.55
		var g := cl.group()
		cl.cap(g, F.Q3(ctx, base.x, base.y, 0.05), F.Q3(ctx, head.x, head.y, 0.05), 0.022 * W, 0.022 * W, wood, 2.0)
		cl.slab(g, F.poly(ctx, [tip, head + side, head - side]), 0.06 * W, 0.03 * W, m, 1.0, 0.02 * W)
