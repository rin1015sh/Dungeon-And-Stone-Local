extends RefCounted
## 균열 잡템 그림(RF19 — 장식을 뒤져 얻는 돈벌이 잡동사니): 동전 더미 · 썩은/언 고기 · 이끼 덩이 · 곡괭이 날 · 항아리 조각 · 버클 · 뼈 장신구.
## Goods.paint가 먼저 부른다(BY_ID에 있으면 그린다). 색 = 아이템 color.

const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Wear2 := preload("res://tools/item_art/Wear2.gd")

const BY_ID := {
	"old_silver_coin": "coins", "old_gold_coin": "coins", "rotten_meat": "spoiled_meat", "frozen_meat": "spoiled_meat",
	"glow_moss": "moss", "rusty_pick_head": "pick_head", "urn_shard": "potsherd", "rusty_buckle": "buckle",
	"frost_bone_charm": "bone_charm",
}


static func paint(id: String, ctx: Dictionary) -> bool:
	match str(BY_ID.get(id, "")):
		"coins":
			coins(ctx)
		"spoiled_meat":
			spoiled_meat(ctx, id == "frozen_meat")
		"moss":
			moss(ctx)
		"pick_head":
			pick_head(ctx)
		"potsherd":
			potsherd(ctx)
		"buckle":
			buckle(ctx)
		"bone_charm":
			var cl: Clay = ctx["cl"]
			ctx["kind"] = "bone"
			ctx["m"] = cl.mat(Color(ctx["c"]).darkened(0.15), "bone")
			Wear2.amulet(ctx)
		_:
			return false
	return true


## 납작한 옛 동전 몇 닢(아래 셋은 겹쳐 눕고 하나는 비스듬히) + 새긴 문양.
static func coins(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var m := cl.mat(c.darkened(0.25), "metal", {"spec": 0.9})
	for q: Vector3 in [Vector3(0.36, 0.66, 0.02), Vector3(0.6, 0.7, 0.04), Vector3(0.46, 0.56, 0.08)]:
		var g := cl.group()
		cl.ell(g, F.Q3(ctx, q.x, q.y, q.z), 0.2 * W, 0.13 * W, 0.035 * W, m, 2.0)
		cl.groove(g, F.Q(ctx, q.x - 0.08, q.y), F.Q(ctx, q.x + 0.08, q.y), 0.012 * W, 0.012 * W)
	var g2 := cl.group()
	cl.ell(g2, F.Q3(ctx, 0.62, 0.38, 0.14), 0.14 * W, 0.19 * W, 0.04 * W, m, 2.0, 0.3)
	cl.groove(g2, F.Q(ctx, 0.58, 0.3), F.Q(ctx, 0.66, 0.46), 0.014 * W, 0.012 * W)  # 새긴 옆얼굴 선
	ctx["glows"].append([F.Q(ctx, 0.5, 0.5), 0.3 * W, c.lightened(0.3), 0.35])


## 뼈에 붙은 고기 덩이 — 썩은 것은 거무죽죽한 반점, 언 것은 서리 빛.
static func spoiled_meat(ctx: Dictionary, frozen: bool) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var g := cl.group()
	cl.cap(g, F.Q3(ctx, 0.2, 0.8, 0.05), F.Q3(ctx, 0.8, 0.24, 0.05), 0.05 * W, 0.05 * W, ctx["bone"], 2.0)
	cl.ell(g, F.Q3(ctx, 0.2, 0.84, 0.05), 0.08 * W, 0.07 * W, 0.06 * W, ctx["bone"], 2.0)
	var flesh := cl.group()
	cl.ell(flesh, F.Q3(ctx, 0.56, 0.46, 0.08), 0.25 * W, 0.19 * W, 0.16 * W, cl.mat(c.darkened(0.35), "slime" if frozen else "skin", {"spec": 0.8} if frozen else {}), 3.0, -0.7)
	if frozen:
		ctx["glows"].append([F.Q(ctx, 0.5, 0.4), 0.35 * W, Color("#e8f6ff"), 0.45])
	else:
		for p: Vector2 in [Vector2(0.5, 0.4), Vector2(0.64, 0.52), Vector2(0.56, 0.58)]:
			cl.carve(flesh, F.Q(ctx, p.x, p.y), 0.04 * W, 0.03 * W, 0.03 * W)


## 빛나는 이끼 덩이: 둥근 뭉치 셋 + 속빛.
static func moss(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var m := cl.mat(c.darkened(0.45), "slime", {"spec": 0.4})
	var g := cl.group()
	for q: Vector3 in [Vector3(0.4, 0.6, 0.18), Vector3(0.62, 0.62, 0.15), Vector3(0.52, 0.44, 0.16)]:
		cl.ell(g, F.Q3(ctx, q.x, q.y, 0.05), q.z * W, q.z * 0.8 * W, q.z * 0.7 * W, m, 3.0)
	ctx["glows"].append([F.Q(ctx, 0.52, 0.52), 0.42 * W, c, 0.55])


## 자루가 빠진 곡괭이 날(초승달 쇳덩이 + 자루 구멍).
static func pick_head(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var pts: Array = []
	for i in 9:
		var t := float(i) / 8.0
		pts.append(Vector2(0.1 + t * 0.8, 0.5 - sin(t * PI) * 0.28))
	for i in 9:
		var t := 1.0 - float(i) / 8.0
		pts.append(Vector2(0.1 + t * 0.8, 0.6 - sin(t * PI) * 0.16))
	cl.slab(g, F.poly(ctx, pts), 0.04 * W, 0.07 * W, cl.mat(Color(ctx["c"]).darkened(0.2), "metal", {"spec": 0.3}), 1.0, 0.05 * W)
	cl.carve(g, F.Q(ctx, 0.5, 0.36), 0.05 * W, 0.06 * W, 0.08 * W)


## 항아리 조각: 휘어진 질그릇 조각 + 띠 무늬.
static func potsherd(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.18, 0.3), Vector2(0.62, 0.18), Vector2(0.84, 0.46), Vector2(0.66, 0.84), Vector2(0.3, 0.76), Vector2(0.22, 0.56)]),
		0.05 * W, 0.12 * W, cl.mat(Color(ctx["c"]).darkened(0.2), "stone"), 1.0, 0.04 * W)
	cl.groove(g, F.Q(ctx, 0.24, 0.42), F.Q(ctx, 0.78, 0.36), 0.025 * W, 0.02 * W)
	cl.groove(g, F.Q(ctx, 0.26, 0.5), F.Q(ctx, 0.8, 0.45), 0.012 * W, 0.015 * W)


## 녹슨 버클: 네모 고리 + 가로대·가시.
static func buckle(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m := cl.mat(Color(ctx["c"]).darkened(0.2), "metal", {"spec": 0.4})
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.2, 0.26), Vector2(0.8, 0.26), Vector2(0.8, 0.74), Vector2(0.2, 0.74)]), 0.04 * W, 0.06 * W, m, 1.0, 0.05 * W)
	cl.carve(g, F.Q(ctx, 0.5, 0.5), 0.2 * W, 0.15 * W, 0.12 * W)
	cl.cap(cl.group(), F.Q3(ctx, 0.5, 0.28, 0.09), F.Q3(ctx, 0.5, 0.74, 0.09), 0.035 * W, 0.03 * W, m, 2.0)
