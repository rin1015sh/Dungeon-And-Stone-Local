extends RefCounted
## 균열에서 줍는 물건의 덧그림(2026-10-30 docs/plans/rift_rooms.md): 공식 장비 그림 위에 그 물건만의 표시를 더한다 —
## 상점의 같은 종류 × 소재 장비와 한눈에 갈리게. ItemArt가 부품을 칠한 뒤 extra(id, ctx)를 부른다.
## 그 밖의 새 모양(광부 도시락의 양철 통)은 Goods가 부른다.

const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")


static func extra(id: String, ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	match id:
		"mine_helmet":  # 이마의 초 받침 + 타는 초
			var g := cl.group()
			cl.cap(g, F.Q3(ctx, 0.5, 0.36, 0.3), F.Q3(ctx, 0.5, 0.24, 0.3), 0.07 * W, 0.07 * W, ctx["accent"], 3.0)
			cl.cap(g, F.Q3(ctx, 0.5, 0.24, 0.32), F.Q3(ctx, 0.5, 0.1, 0.32), 0.035 * W, 0.035 * W, cl.mat(Color("#d8ceb0"), "cloth"), 3.0)
			ctx["glows"].append([F.Q(ctx, 0.5, 0.07), 0.12 * W, Color("#ffc860"), 0.9])
		"mine_hammer":  # 머리에 박힌 녹색 광석 부스러기
			for k in 4:
				var at := F.Q(ctx, 0.62 + k * 0.05, 0.06 + (k % 2) * 0.04)
				ctx["glows"].append([at, 0.035 * W, Color("#7aff6a"), 0.6])
		"mine_goblin_boots":  # 바닥 쇠못
			for side: float in [-1.0, 1.0]:
				var g := cl.group()
				var cx := 0.5 + side * 0.2
				for k in 4:
					cl.bump(g, F.Q(ctx, cx - 0.06 + k * 0.05 + side * 0.04, 0.9), 0.018 * W, 0.018 * W, 0.02 * W, ctx["steel"])


## 양철 도시락 통: 납작한 상자 + 뚜껑 턱 + 걸쇠.
static func tin(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var m := cl.mat(Color(ctx["c"]).darkened(0.35), "metal", {"spec": 0.35})
	var body := F.poly(ctx, [Vector2(0.14, 0.4), Vector2(0.86, 0.4), Vector2(0.86, 0.82), Vector2(0.14, 0.82)])
	cl.slab(g, body, 0.03 * W, 0.12 * W, m, 2.0, 0.06 * W)
	var lid := F.poly(ctx, [Vector2(0.12, 0.26), Vector2(0.88, 0.26), Vector2(0.88, 0.44), Vector2(0.12, 0.44)])
	cl.slab(g, lid, 0.12 * W, 0.08 * W, m, 2.0, 0.05 * W)
	cl.groove(g, F.Q(ctx, 0.14, 0.44), F.Q(ctx, 0.86, 0.44), 0.015 * W, 0.03 * W)
	cl.ridge(g, [F.Q(ctx, 0.47, 0.38), F.Q(ctx, 0.53, 0.38), F.Q(ctx, 0.53, 0.52)], 0.018 * W, 0.03 * W, ctx["accent"])
	cl.ridge(g, [F.Q(ctx, 0.3, 0.2), F.Q(ctx, 0.5, 0.14), F.Q(ctx, 0.7, 0.2)], 0.015 * W, 0.03 * W, ctx["steel"])  # 손잡이


## 은 술잔: 잔 몸통 + 가는 목 + 받침.
static func cup(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var m := cl.mat(Color(ctx["c"]).darkened(0.3), "metal", {"spec": 0.7})
	cl.cap(g, F.Q3(ctx, 0.5, 0.26, 0.1), F.Q3(ctx, 0.5, 0.46, 0.08), 0.22 * W, 0.12 * W, m, 2.0)
	cl.cap(g, F.Q3(ctx, 0.5, 0.48, 0.06), F.Q3(ctx, 0.5, 0.74, 0.06), 0.04 * W, 0.04 * W, m, 3.0)
	cl.ell(g, F.Q3(ctx, 0.5, 0.8, 0.04), 0.18 * W, 0.06 * W, 0.05 * W, m, 2.0)
	ctx["lines"].append([F.Q(ctx, 0.36, 0.3), F.Q(ctx, 0.4, 0.42), maxf(1.2, W / 50.0), Color("#5a1a1e")])  # 술 얼룩


## 약초 다발: 잎 몇 장 + 묶은 끈.
static func herb(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	for k in 5:
		var g := cl.group()
		var a := -0.5 + k * 0.25
		var tip := F.Q3(ctx, 0.5 + a * 0.5, 0.12 + absf(a) * 0.12, 0.08)
		cl.cap(g, F.Q3(ctx, 0.5, 0.7, 0.06), tip, 0.035 * W, 0.08 * W, cl.mat(c.darkened(0.2 + k * 0.04), "cloth"), 3.0)
	cl.ridge(cl.group(), [F.Q(ctx, 0.42, 0.66), F.Q(ctx, 0.58, 0.68)], 0.025 * W, 0.04 * W, ctx["leather"])


## 향: 가는 막대 세 개 + 오르는 연기.
static func incense(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	for k in 3:
		var x := 0.4 + k * 0.1
		cl.cap(cl.group(), F.Q3(ctx, x, 0.9, 0.06), F.Q3(ctx, x + 0.03, 0.3, 0.06), 0.025 * W, 0.022 * W, cl.mat(Color(ctx["c"]).darkened(0.2), "wood"), 3.0)
		ctx["glows"].append([F.Q(ctx, x + 0.03, 0.29), 0.04 * W, Color("#ff9a50"), 0.8])
	ctx["lines"].append([F.Q(ctx, 0.53, 0.26), F.Q(ctx, 0.46, 0.06), maxf(1.0, W / 60.0), Color(0.85, 0.85, 0.8, 0.5)])
