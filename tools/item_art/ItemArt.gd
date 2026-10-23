extends RefCounted
## 아이템 그림 한 장(사용자 요청 2026-10-23 "아이템 이미지를 우리 그림체로 전면 교체"): 몬스터 그림과 같은 순서로 칠한다 —
## 3D 덩어리로 빚기(Clay) → 붓 칠·적갈색 그늘·잉크·펜 빗금(Render) → 빛·활시위 → 때·색 보정·그레인(Finish).
## 캔버스 = 가방 칸 크기(size [가로, 세로]) × CELL px — 게임은 칸 사각형에 그대로 맞춰 그린다(ItemIconPainter).
## 무엇을 그릴지: 공식 장비는 forged.type(종류)·material(소재 — 색·종류·등급), 그 밖은 아이템 id(GOODS) → 그림 종류(icon).
## 그리는 부품: Blades(날붙이·자루 무기) · Hafts(둔기·활·지팡이) · Wear(갑옷·방패) · Wear2(머리·손·발·허리·망토·장신구) · Goods(소모품·잡동사니).
## ctx(부품이 받는 사전): cl · W · H · rng · tier · m(주 재질) · steel · wood · leather · cloth · accent(장식 금속) · c(주 색) · kind(소재 종류)
##   · glows [[Vector2, 반지름, 색, 세기]] · lines [[a, b, 굵기, 색]](칠한 뒤 그린다)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")
const Blades := preload("res://tools/item_art/Blades.gd")
const Hafts := preload("res://tools/item_art/Hafts.gd")
const Wear := preload("res://tools/item_art/Wear.gd")
const Wear2 := preload("res://tools/item_art/Wear2.gd")
const Goods := preload("res://tools/item_art/Goods.gd")

const CELL := 80  ## 칸 하나의 그림 px(가방 칸 38px의 약 2배 — 줄여 쓴다)
const KIND_OF := {"metal": "metal", "leather": "leather", "wood": "wood", "cloth": "cloth", "bone": "bone", "gem": "metal"}

## 종류(item_types id) → 부품 함수
const TYPE_PAINTER := {
	"dagger": [Blades, "dagger"], "sword": [Blades, "sword"], "greatsword": [Blades, "greatsword"], "axe": [Blades, "axe"],
	"spear": [Blades, "spear"], "halberd": [Blades, "halberd"],
	"mace": [Hafts, "mace"], "warhammer": [Hafts, "warhammer"], "club": [Hafts, "club"], "bow": [Hafts, "bow"],
	"crossbow": [Hafts, "crossbow"], "staff": [Hafts, "staff"],
	"buckler": [Wear, "buckler"], "shield": [Wear, "shield"], "tower_shield": [Wear, "tower"],
	"padded": [Wear, "padded"], "robe": [Wear, "robe"], "leather_armor": [Wear, "leather_armor"], "chainmail": [Wear, "chainmail"],
	"plate": [Wear, "plate"],
	"hood": [Wear2, "hood"], "helm": [Wear2, "helm"], "greathelm": [Wear2, "greathelm"], "gloves": [Wear2, "gloves"],
	"gauntlets": [Wear2, "gauntlets"], "boots": [Wear2, "boots"], "sabatons": [Wear2, "sabatons"], "belt": [Wear2, "belt"],
	"cloak": [Wear2, "cloak"], "ring": [Wear2, "ring"], "amulet": [Wear2, "amulet"],
}


## 아이템 하나를 그린다. 그릴 수 없으면 null.
static func paint(db: GameDatabase, id: String, seed_value: int) -> Paint:
	var it := db.get_entry("items", id)
	if it.is_empty():
		return null
	var size := JsonUtil.get_array(it, "size")
	var W := CELL * (int(size[0]) if size.size() == 2 else 1)
	var H := CELL * (int(size[1]) if size.size() == 2 else 1)
	var p := Paint.new(W, H, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(W, H)
	var forged := JsonUtil.get_dict(it, "forged")
	var mat := db.get_entry("materials", JsonUtil.get_str(forged, "material"))
	var ctx := _ctx(cl, W, H, rng, it, mat)
	var done := false
	var pt: Array = TYPE_PAINTER.get(JsonUtil.get_str(forged, "type"), [])
	if not pt.is_empty():
		(pt[0] as Script).call(str(pt[1]), ctx)
		done = true
	else:
		done = Goods.paint(id, it, ctx)
	if not done:
		return null
	Render.render(cl, p, float(maxi(W, H)) * 1.6)
	for ln: Array in ctx["lines"]:
		Ink.line(p, ln[0], ln[1], ln[2], ln[3], 0.9, 0.3)
	for gl: Array in ctx["glows"]:
		var gp: Vector2 = gl[0]
		Ink.glow(p, gp.x, gp.y, gl[1], gl[2], float(gl[3]) if gl.size() > 3 else 0.8, false)
	Finish.done(p, {"grime": float(ctx.get("grime", 0.25))}, {}, float(H))
	return p


## 부품이 쓰는 재질·색. 공식 장비는 소재 색·종류로, 그 밖은 아이템 color로.
static func _ctx(cl: Clay, W: int, H: int, rng: RandomNumberGenerator, it: Dictionary, mat: Dictionary) -> Dictionary:
	var kind := JsonUtil.get_str(mat, "kind", "metal")
	var c := Color.from_string(JsonUtil.get_str(mat, "color", JsonUtil.get_str(it, "color", "#8a8a86")), Color("#8a8a86"))
	var tier := JsonUtil.get_int(mat, "tier", 1)
	var steel_c := c if kind == "metal" else Color("#7a7c80")
	var ctx := {"cl": cl, "W": float(W), "H": float(H), "rng": rng, "tier": tier, "kind": kind, "c": c, "glows": [], "lines": [],
		"mat_id": JsonUtil.get_str(mat, "id")}
	ctx["m"] = cl.mat(_tone(c, kind), str(KIND_OF.get(kind, "metal")), _shine(c, kind))
	ctx["steel"] = cl.mat(_tone(steel_c, "metal"), "metal", _shine(steel_c, "metal"))
	ctx["wood"] = cl.mat(_tone(c, "wood") if kind == "wood" else Color("#4e3626"), "wood")
	ctx["leather"] = cl.mat(_tone(c, "leather") if kind == "leather" else Color("#4a3222"), "leather")
	ctx["cloth"] = cl.mat(_tone(c, "cloth") if kind == "cloth" else Color("#4a4236"), "cloth")
	ctx["bone"] = cl.mat(_tone(c, "bone") if kind == "bone" else Color("#cbbd9f"), "bone")
	ctx["accent"] = cl.mat(Color("#a88a48") if tier >= 3 else Color("#6e6a64"), "metal")
	ctx["dark"] = cl.mat(Color("#1a1210"), "cloth")
	if tier >= 5:  # 5~6단계 소재는 은은한 빛(마력이 깃든 금속·가죽)
		ctx["aura"] = c.lightened(0.3)
	return ctx


## 쇠 광택: 밝은 금속일수록 번들(어두운 아다만티움은 반사가 적어 어둡게 남는다 — Render의 쇠 반사는 흰빛을 섞는다).
static func _shine(c: Color, kind: String) -> Dictionary:
	if kind != "metal" and kind != "gem":
		return {}
	return {"spec": 0.15 + 0.55 * c.get_luminance()}


## 소재 색을 그림 색으로: 채도를 낮추고(그림체 규칙) 재질마다 조금씩 어둡게.
static func _tone(c: Color, kind: String) -> Color:
	var lum := c.get_luminance()
	var d := c.lerp(Color(lum, lum, lum), 0.2)
	match kind:
		"metal":
			return d.darkened(0.48)
		"leather", "wood":
			return d.darkened(0.12)
		"cloth":
			return d.darkened(0.18)
	return d
