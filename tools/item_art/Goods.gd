extends RefCounted
## 장비가 아닌 아이템(포션·음식·마석·도구·잡동사니)과 공식 밖 장비(구리 반지·뼈 목걸이·뼈 대검).
## 아이템 id(BY_ID) → 그림, 없으면 icon 종류(BY_ICON). 색 = 아이템 color(마석 등급색·포션 물약색).
## 유리병 = 물약(slime — 번들)을 담은 몸 + 밝은 테두리 + 코르크, 마석·결정 = 각진 판 + 속빛.

const F := preload("res://tools/item_art/Frame.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Blades := preload("res://tools/item_art/Blades.gd")
const Wear2 := preload("res://tools/item_art/Wear2.gd")
const Junk := preload("res://tools/item_art/Junk.gd")
const RiftGear := preload("res://tools/item_art/RiftGear.gd")

const BY_ID := {
	"minor_potion": "vial", "medium_potion": "flask", "greater_potion": "big_flask", "soul_potion": "flask", "antidote": "vial",
	"spring_water": "waterskin", "goddess_tear": "tear", "ice_crystal": "orb", "mana_ice_shard": "shard", "gobl_quartz": "cluster",
	"green_gem": "gem", "gnome_trinket": "pebble", "whetstone": "whetstone", "explorer_tag": "tag", "rift_stone": "tablet",
	"floor_stone_1": "tablet", "mine_explosive": "dynamite", "smoke_bomb": "pot_bomb", "ration": "bundle", "stone_bread": "bread",
	"leftovers": "meat", "crystal_mushroom": "mushroom", "bandage": "bandage", "torch": "torch", "torch_stub": "stub",
	"lantern": "lantern", "necronomicon": "book", "copper_ring": "ring", "bone_amulet": "amulet",
	"dread_bone_greatsword": "bone_greatsword",
	"tomb_oil": "vial", "steel_relic": "orb", "death_mask": "tablet", "tomb_gold": "gem", "fortress_key": "tag", "silver_chest": "tablet",
	"blood_chalice": "flask", "snow_lotus": "mushroom", "eternal_ice": "shard", "mine_heart": "cluster", "green_vein": "crystal",
	"ice_chips": "shard", "copper_ore": "pebble", "shroud_rag": "bandage",
	"mine_bitter_tea": "flask", "mine_moss_salve": "vial", "mine_lunchbox": "tin", "mine_green_tonic": "flask",
	"mine_powder_pouch": "pot_bomb", "mine_rough_gem": "gem",
}
const BY_ICON := {"potion": "flask", "stone": "crystal", "gem": "gem", "bomb": "pot_bomb", "food": "bundle", "bread": "bread",
	"torch": "torch", "lantern": "lantern", "book": "book", "horn": "horn", "ring": "ring", "amulet": "amulet", "pouch": "bundle"}


static func paint(id: String, it: Dictionary, ctx: Dictionary) -> bool:
	if Junk.paint(id, ctx):  # 균열 잡템(RF19)
		return true
	var how := str(BY_ID.get(id, BY_ICON.get(JsonUtil.get_str(it, "icon"), "")))
	if how.is_empty() and JsonUtil.get_str(it, "category") == "magic_stone":
		how = "crystal"
	if how.is_empty():
		return false
	if id.begins_with("magic_stone"):
		how = "crystal"
	match how:
		"ring", "amulet":
			var cl: Clay = ctx["cl"]
			ctx["kind"] = "bone" if id == "bone_amulet" else "metal"
			ctx["m"] = cl.mat(Color(ctx["c"]).darkened(0.25), "bone" if id == "bone_amulet" else "metal", {"spec": 0.5})
			if how == "ring":
				Wear2.ring(ctx)
			else:
				Wear2.amulet(ctx)
		"bone_greatsword":
			var cl: Clay = ctx["cl"]
			ctx["m"] = cl.mat(Color("#cbbd9f"), "bone")
			ctx["accent"] = cl.mat(Color("#5a3e30"), "leather")
			Blades.greatsword(ctx)
		_:
			_by_name(how, ctx)
	return true


## 그림 이름 → 이 파일의 함수.
static func _by_name(how: String, ctx: Dictionary) -> void:
	match how:
		"tin":
			RiftGear.tin(ctx)
		"bandage":
			bandage(ctx)
		"big_flask":
			big_flask(ctx)
		"book":
			book(ctx)
		"bread":
			bread(ctx)
		"bundle":
			bundle(ctx)
		"cluster":
			cluster(ctx)
		"crystal":
			crystal(ctx)
		"dynamite":
			dynamite(ctx)
		"flask":
			flask(ctx)
		"gem":
			gem(ctx)
		"horn":
			horn(ctx)
		"lantern":
			lantern(ctx)
		"meat":
			meat(ctx)
		"mushroom":
			mushroom(ctx)
		"orb":
			orb(ctx)
		"pebble":
			pebble(ctx)
		"pot_bomb":
			pot_bomb(ctx)
		"shard":
			shard(ctx)
		"stub":
			stub(ctx)
		"tablet":
			tablet(ctx)
		"tag":
			tag(ctx)
		"tear":
			tear(ctx)
		"torch":
			torch(ctx)
		"vial":
			vial(ctx)
		"waterskin":
			waterskin(ctx)
		"whetstone":
			whetstone(ctx)


# ── 유리병 ─────────────────────────────────────────────

## 병: 몸 (cx, cy, rx, ry) + 목 + 코르크. 물약 색 = ctx.c.
static func _bottle(ctx: Dictionary, body: Vector2, rx: float, ry: float, neck_h: float) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var glass := cl.mat(Color("#9aa8a8"), "slime", {"spec": 1.0})
	var liquid := cl.mat(c.darkened(0.2), "slime", {"spec": 0.9})
	var g := cl.group()
	cl.ell(g, F.Q3(ctx, body.x, body.y, 0.05), rx * W, ry * W, rx * W * 0.8, glass, 2.0)
	var gl := cl.group()
	cl.ell(gl, F.Q3(ctx, body.x, body.y + ry * 0.25, 0.1), rx * W * 0.86, ry * W * 0.72, rx * W * 0.7, liquid, 2.0)
	var top := body.y - ry * float(ctx["W"]) / float(ctx["H"])
	cl.cap(g, F.Q3(ctx, body.x, top + 0.02, 0.06), F.Q3(ctx, body.x, top - neck_h, 0.06), 0.09 * W, 0.08 * W, glass, 2.0)
	var gc := cl.group()
	cl.cap(gc, F.Q3(ctx, body.x, top - neck_h + 0.02, 0.08), F.Q3(ctx, body.x, top - neck_h - 0.1, 0.08), 0.1 * W, 0.11 * W, ctx["wood"], 1.0)
	ctx["glows"].append([F.Q(ctx, body.x - rx * 0.35, body.y - ry * 0.2), rx * W * 0.5, Color(1, 1, 1), 0.35])


static func vial(ctx: Dictionary) -> void:
	_bottle(ctx, Vector2(0.5, 0.62), 0.22, 0.28, 0.12)


static func flask(ctx: Dictionary) -> void:
	_bottle(ctx, Vector2(0.5, 0.64), 0.32, 0.3, 0.1)


static func big_flask(ctx: Dictionary) -> void:
	_bottle(ctx, Vector2(0.5, 0.64), 0.36, 0.32, 0.08)
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	cl.ridge(cl.group(), [F.Q(ctx, 0.2, 0.62), F.Q(ctx, 0.8, 0.62)], 0.025 * W, 0.04 * W, cl.mat(Color("#a88a48"), "metal"))


static func waterskin(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.ell(g, F.Q3(ctx, 0.5, 0.6, 0.05), 0.34 * W, 0.32 * W, 0.22 * W, ctx["leather"], 3.0)
	cl.cap(g, F.Q3(ctx, 0.5, 0.32, 0.08), F.Q3(ctx, 0.56, 0.12, 0.08), 0.1 * W, 0.07 * W, ctx["leather"], 3.0)
	cl.groove(g, F.Q(ctx, 0.25, 0.6), F.Q(ctx, 0.75, 0.62), 0.015 * W, 0.02 * W)
	cl.ell(cl.group(), F.Q3(ctx, 0.57, 0.1, 0.12), 0.06 * W, 0.05 * W, 0.04 * W, ctx["wood"], 1.0)


static func tear(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var g := cl.group()
	var poly := PackedVector2Array()
	for k in 32:
		var a := TAU * k / 32.0
		var r := 0.28 * (1.0 + 0.7 * maxf(0.0, -sin(a)) * 0.0)
		var y := 0.6 + sin(a) * 0.28
		var x := 0.5 + cos(a) * r * (1.0 - maxf(0.0, -sin(a)) * 0.85)
		poly.append(F.Q(ctx, x, y - maxf(0.0, -sin(a)) * 0.3))
	cl.slab(g, poly, 0.05 * W, 0.2 * W, cl.mat(c, "slime", {"spec": 1.0}), 2.0, 0.25 * W)
	ctx["glows"].append([F.Q(ctx, 0.5, 0.58), 0.6 * W, c.lightened(0.3), 0.7])


static func orb(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	cl.ell(cl.group(), F.Q3(ctx, 0.5, 0.52, 0.05), 0.3 * W, 0.3 * W, 0.28 * W, cl.mat(c.darkened(0.15), "slime", {"spec": 1.0}), 2.0)
	ctx["glows"].append([F.Q(ctx, 0.5, 0.52), 0.55 * W, c.lightened(0.2), 0.6])


# ── 돌·결정 ────────────────────────────────────────────

## 마석·결정 조각: 각진 판 두어 개 + 속빛(아이템 색).
static func crystal(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var m := cl.mat(c.darkened(0.25), "metal", {"spec": 0.8})
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.5, 0.08), Vector2(0.74, 0.34), Vector2(0.68, 0.86), Vector2(0.34, 0.9), Vector2(0.26, 0.4)]), 0.05 * W, 0.22 * W, m, 1.0, 0.28 * W)
	cl.groove(g, F.Q(ctx, 0.5, 0.1), F.Q(ctx, 0.5, 0.86), 0.015 * W, 0.03 * W)
	cl.groove(g, F.Q(ctx, 0.28, 0.42), F.Q(ctx, 0.72, 0.36), 0.012 * W, 0.02 * W)
	ctx["glows"].append([F.Q(ctx, 0.5, 0.5), 0.45 * W, c.lightened(0.2), 0.55])


static func shard(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.58, 0.04), Vector2(0.7, 0.5), Vector2(0.52, 0.96), Vector2(0.36, 0.52)]), 0.05 * W, 0.18 * W, cl.mat(c.darkened(0.15), "slime", {"spec": 1.0}), 1.0, 0.2 * W)
	ctx["glows"].append([F.Q(ctx, 0.52, 0.5), 0.45 * W, c.lightened(0.25), 0.55])


static func cluster(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var m := cl.mat(c.darkened(0.35), "metal", {"spec": 0.6})
	var rock := cl.mat(Color("#5a524a"), "stone")
	cl.ell(cl.group(), F.Q3(ctx, 0.5, 0.82, 0.02), 0.36 * W, 0.12 * W, 0.1 * W, rock, 2.0)
	for k in 4:
		var x := 0.32 + k * 0.12
		var top := 0.18 + absf(k - 1.5) * 0.12
		cl.slab(cl.group(), F.poly(ctx, [Vector2(x - 0.07, 0.8), Vector2(x - 0.05, top + 0.08), Vector2(x, top), Vector2(x + 0.05, top + 0.08), Vector2(x + 0.07, 0.8)]),
			0.05 * W + k * 0.01 * W, 0.08 * W, m, 1.0, 0.06 * W)


static func gem(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.24, 0.36), Vector2(0.36, 0.2), Vector2(0.64, 0.2), Vector2(0.76, 0.36), Vector2(0.5, 0.86)]), 0.05 * W, 0.2 * W, cl.mat(c.darkened(0.2), "metal", {"spec": 1.0}), 1.0, 0.18 * W)
	cl.groove(g, F.Q(ctx, 0.25, 0.37), F.Q(ctx, 0.75, 0.37), 0.012 * W, 0.03 * W)
	cl.groove(g, F.Q(ctx, 0.42, 0.22), F.Q(ctx, 0.5, 0.84), 0.01 * W, 0.02 * W)
	ctx["glows"].append([F.Q(ctx, 0.46, 0.4), 0.4 * W, c.lightened(0.3), 0.5])


static func pebble(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	cl.ell(cl.group(), F.Q3(ctx, 0.5, 0.56, 0.05), 0.3 * W, 0.24 * W, 0.18 * W, cl.mat(c.darkened(0.3), "metal", {"spec": 0.9}), 2.0)
	ctx["glows"].append([F.Q(ctx, 0.42, 0.48), 0.25 * W, c.lightened(0.3), 0.5])


static func whetstone(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.14, 0.36), Vector2(0.86, 0.3), Vector2(0.88, 0.62), Vector2(0.16, 0.7)]), 0.04 * W, 0.12 * W, cl.mat(Color(ctx["c"]).darkened(0.25), "stone"), 1.0, 0.1 * W)


static func tag(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.3, 0.3), Vector2(0.7, 0.3), Vector2(0.74, 0.84), Vector2(0.26, 0.84)]), 0.04 * W, 0.06 * W, cl.mat(Color(ctx["c"]).darkened(0.3), "metal", {"spec": 0.5}), 1.0, 0.06 * W)
	cl.carve(g, F.Q(ctx, 0.5, 0.38), 0.05 * W, 0.05 * W, 0.06 * W)
	for k in 3:  # 새긴 이름
		cl.groove(g, F.Q(ctx, 0.36, 0.52 + k * 0.08), F.Q(ctx, 0.64 - k * 0.05, 0.52 + k * 0.08), 0.01 * W, 0.015 * W)
	ctx["lines"].append([F.Q(ctx, 0.5, 0.36), F.Q(ctx, 0.3, 0.06), maxf(1.2, W / 50.0), Color("#5a4a36")])
	ctx["lines"].append([F.Q(ctx, 0.5, 0.36), F.Q(ctx, 0.7, 0.06), maxf(1.2, W / 50.0), Color("#5a4a36")])


## 석판(균열석·계층석): 깨진 돌판 + 갈라진 틈의 빛.
static func tablet(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.22, 0.16), Vector2(0.7, 0.12), Vector2(0.82, 0.5), Vector2(0.7, 0.88), Vector2(0.26, 0.86), Vector2(0.16, 0.5)]), 0.04 * W, 0.12 * W, cl.mat(Color("#5e5650"), "stone"), 1.0, 0.12 * W)
	var crack := [F.Q(ctx, 0.4, 0.18), F.Q(ctx, 0.5, 0.42), F.Q(ctx, 0.44, 0.6), F.Q(ctx, 0.56, 0.84)]
	cl.grooves(g, crack, 0.025 * W, 0.04 * W)
	for k in crack.size() - 1:
		ctx["lines"].append([crack[k], crack[k + 1], maxf(1.5, W / 40.0), c])
	ctx["glows"].append([F.Q(ctx, 0.48, 0.5), 0.5 * W, c, 0.6])


# ── 폭약 ───────────────────────────────────────────────

static func dynamite(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m := cl.mat(Color(ctx["c"]).darkened(0.2), "cloth")
	for k in 3:
		var x := 0.34 + k * 0.16
		cl.cap(cl.group(), F.Q3(ctx, x, 0.86, 0.04 + k * 0.01), F.Q3(ctx, x, 0.3, 0.04 + k * 0.01), 0.09 * W, 0.09 * W, m, 1.0)
	cl.ridge(cl.group(), [F.Q(ctx, 0.22, 0.6), F.Q(ctx, 0.78, 0.6)], 0.025 * W, 0.08 * W, ctx["leather"])
	ctx["lines"].append([F.Q(ctx, 0.5, 0.28), F.Q(ctx, 0.62, 0.08), maxf(1.4, W / 45.0), Color("#8a7a5a")])
	ctx["glows"].append([F.Q(ctx, 0.62, 0.08), 0.15 * W, Color("#ffb040"), 0.7])


static func pot_bomb(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.ell(g, F.Q3(ctx, 0.5, 0.6, 0.05), 0.32 * W, 0.3 * W, 0.26 * W, cl.mat(Color(ctx["c"]).darkened(0.35), "stone"), 2.0)
	cl.cap(g, F.Q3(ctx, 0.5, 0.32, 0.08), F.Q3(ctx, 0.5, 0.24, 0.08), 0.1 * W, 0.1 * W, ctx["cloth"], 1.0)
	ctx["lines"].append([F.Q(ctx, 0.5, 0.24), F.Q(ctx, 0.6, 0.08), maxf(1.4, W / 45.0), Color("#8a7a5a")])


# ── 음식·천 ────────────────────────────────────────────

static func bundle(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.ell(g, F.Q3(ctx, 0.5, 0.6, 0.05), 0.36 * W, 0.28 * W, 0.2 * W, cl.mat(Color(ctx["c"]).darkened(0.3), "cloth"), 3.0)
	cl.cap(g, F.Q3(ctx, 0.5, 0.36, 0.1), F.Q3(ctx, 0.44, 0.18, 0.1), 0.08 * W, 0.05 * W, cl.mat(Color(ctx["c"]).darkened(0.3), "cloth"), 3.0)
	cl.ridge(g, [F.Q(ctx, 0.2, 0.56), F.Q(ctx, 0.8, 0.6)], 0.02 * W, 0.03 * W, ctx["leather"])
	cl.ridge(g, [F.Q(ctx, 0.5, 0.34), F.Q(ctx, 0.52, 0.86)], 0.02 * W, 0.03 * W, ctx["leather"])


static func bread(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.ell(g, F.Q3(ctx, 0.5, 0.58, 0.05), 0.38 * W, 0.24 * W, 0.2 * W, cl.mat(Color(ctx["c"]).darkened(0.2), "wood"), 3.0, -0.2)
	for k in 3:
		cl.groove(g, F.Q(ctx, 0.3 + k * 0.16, 0.44), F.Q(ctx, 0.38 + k * 0.16, 0.7), 0.025 * W, 0.04 * W)


static func meat(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	cl.cap(g, F.Q3(ctx, 0.2, 0.8, 0.05), F.Q3(ctx, 0.8, 0.24, 0.05), 0.05 * W, 0.05 * W, ctx["bone"], 2.0)
	cl.ell(g, F.Q3(ctx, 0.2, 0.84, 0.05), 0.08 * W, 0.07 * W, 0.06 * W, ctx["bone"], 2.0)
	cl.ell(cl.group(), F.Q3(ctx, 0.56, 0.46, 0.08), 0.24 * W, 0.18 * W, 0.16 * W, cl.mat(Color("#6a3a2a"), "skin"), 3.0, -0.7)


static func mushroom(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	cl.cap(cl.group(), F.Q3(ctx, 0.5, 0.88, 0.05), F.Q3(ctx, 0.52, 0.48, 0.05), 0.08 * W, 0.06 * W, cl.mat(Color("#b8b0a0"), "skin"), 2.0)
	var top := F.Q3(ctx, 0.52, 0.4, 0.08)
	cl.ell(cl.group(), top, 0.32 * W, 0.17 * W, 0.14 * W, cl.mat(c.darkened(0.3), "slime", {"spec": 0.8}), 2.0)
	ctx["glows"].append([Vector2(top.x, top.y), 0.45 * W, c, 0.6])


static func bandage(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var m := cl.mat(Color(ctx["c"]).darkened(0.25), "cloth")
	var g := cl.group()
	cl.cap(g, F.Q3(ctx, 0.3, 0.5, 0.05), F.Q3(ctx, 0.7, 0.5, 0.05), 0.24 * W, 0.24 * W, m, 2.0, 0.6)
	cl.carve(g, F.Q(ctx, 0.74, 0.5), 0.05 * W, 0.12 * W, 0.08 * W)
	for k in 3:
		cl.groove(g, F.Q(ctx, 0.36 + k * 0.12, 0.28), F.Q(ctx, 0.36 + k * 0.12, 0.72), 0.01 * W, 0.015 * W)
	var tail := F.poly(ctx, [Vector2(0.22, 0.62), Vector2(0.4, 0.66), Vector2(0.34, 0.92), Vector2(0.16, 0.86)])
	cl.slab(cl.group(), tail, 0.1 * W, 0.03 * W, m, 1.0, 0.04 * W)


# ── 빛·책·뿔 ───────────────────────────────────────────

static func torch(ctx: Dictionary) -> void:
	_torch(ctx, 0.0)


static func stub(ctx: Dictionary) -> void:
	_torch(ctx, 0.4)


static func _torch(ctx: Dictionary, cut: float) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var g := cl.group()
	var top := 0.72 - cut
	cl.cap(g, F.V(ctx, 0.0), F.V(ctx, top), 0.09 * W, 0.11 * W, ctx["wood"], 1.0)
	var head := cl.mat(Color("#4a3a2a") if cut == 0.0 else Color("#1e1610"), "cloth")
	cl.cap(cl.group(), F.V(ctx, top - 0.04, 0.0, 0.03), F.V(ctx, top + 0.18, 0.0, 0.03), 0.17 * W, 0.15 * W, head, 2.0)
	for k in 3:
		var t := top + k * 0.05
		cl.groove(g, F.P(ctx, t, -0.18), F.P(ctx, t + 0.03, 0.18), 0.012 * W, 0.02 * W)
	if cut > 0.0:
		ctx["glows"].append([F.P(ctx, top + 0.12), 0.2 * W, Color("#ff7a30"), 0.4])


static func lantern(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var iron := cl.mat(Color("#3a3634"), "metal", {"spec": 0.3})
	var glass := cl.mat(Color("#e8b060"), "glow")
	cl.cap(cl.group(), F.V(ctx, 0.2, 0.0, 0.02), F.V(ctx, 0.62, 0.0, 0.02), 0.26 * W, 0.26 * W, glass, 1.0)
	var g := cl.group()
	for s: float in [-0.3, 0.3]:  # 세로 살
		cl.cap(g, F.V(ctx, 0.16, s, 0.1), F.V(ctx, 0.66, s, 0.1), 0.04 * W, 0.04 * W, iron, 1.0)
	cl.cap(g, F.V(ctx, 0.13, -0.36, 0.08), F.V(ctx, 0.13, 0.36, 0.08), 0.06 * W, 0.06 * W, iron, 1.0)
	cl.cap(g, F.V(ctx, 0.66, -0.34, 0.08), F.V(ctx, 0.66, 0.34, 0.08), 0.05 * W, 0.05 * W, iron, 1.0)
	cl.ell(g, F.V(ctx, 0.74, 0.0, 0.06), 0.24 * W, 0.08 * W * 2.0, 0.08 * W, iron, 2.0)
	var ring: Array = []
	for k in 9:
		var a := PI * k / 8.0
		ring.append(F.P(ctx, 0.84 + sin(a) * 0.1, cos(a) * 0.2))
	for k in 8:
		ctx["lines"].append([ring[k], ring[k + 1], maxf(1.5, W / 30.0), Color("#3a3634")])
	ctx["glows"].append([F.P(ctx, 0.42), 0.7 * W, Color("#ffb050"), 0.7])


static func book(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var c: Color = ctx["c"]
	var g := cl.group()
	cl.slab(g, F.poly(ctx, [Vector2(0.2, 0.12), Vector2(0.8, 0.14), Vector2(0.82, 0.9), Vector2(0.2, 0.88)]), 0.06 * W, 0.08 * W, cl.mat(c, "leather"), 1.0, 0.06 * W)
	cl.cap(g, F.Q3(ctx, 0.2, 0.14, 0.12), F.Q3(ctx, 0.2, 0.88, 0.12), 0.05 * W, 0.05 * W, cl.mat(c.darkened(0.3), "leather"), 1.0)
	var face := F.Q(ctx, 0.52, 0.48)  # 표지의 꿰맨 얼굴
	cl.bump(g, face, 0.16 * W, 0.2 * W, 0.04 * W, cl.mat(Color("#8a6a5a"), "skin"), 2.0)
	for s: float in [-1.0, 1.0]:
		cl.carve(g, face + Vector2(s * 0.06 * W, -0.04 * W), 0.03 * W, 0.02 * W, 0.04 * W)
	cl.groove(g, face + Vector2(-0.06 * W, 0.08 * W), face + Vector2(0.06 * W, 0.08 * W), 0.012 * W, 0.03 * W)
	ctx["glows"].append([face, 0.3 * W, Color("#c03030"), 0.25])


static func horn(ctx: Dictionary) -> void:
	var cl: Clay = ctx["cl"]
	var W: float = ctx["W"]
	var pts: Array = []
	var rs: Array = []
	for k in 9:
		var t := k / 8.0
		pts.append(F.Q3(ctx, 0.14 + t * 0.62 + sin(t * PI) * 0.06, 0.82 - (1.0 - cos(t * PI * 0.5)) * 0.62 - t * 0.04, 0.05))
		rs.append((0.025 + t * t * 0.14) * W)
	var g := cl.group()
	cl.chain(g, pts, rs, cl.mat(Color(ctx["c"]).darkened(0.1), "bone"), 3.0)
	var mouth: Vector3 = pts[8]
	cl.carve(g, Vector2(mouth.x, mouth.y), 0.1 * W, 0.08 * W, 0.08 * W)
	for k: int in [3, 6]:
		var p: Vector3 = pts[k]
		cl.ridge(g, [Vector2(p.x - rs[k], p.y + 0.02 * W), Vector2(p.x + rs[k], p.y - 0.02 * W)], 0.025 * W, 0.03 * W, ctx["accent"])
