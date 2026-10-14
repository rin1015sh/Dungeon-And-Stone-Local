extends RefCounted
## 도시 시설 건물 그림(옆에서 본 정면, 투명 배경, 아래 가장자리 = 땅). tools/paint_city.gd 전용.
## 레퍼런스 톤: 어두운 돌 기단 · 낡은 나무 판자 · 이끼 낀 너와 지붕 · 담쟁이 · 따뜻한 창 불빛.

const Px := preload("res://tools/city_art/Px.gd")
const Props := preload("res://tools/city_art/Props.gd")

const WOOD := Color("#6a4d35")
const WOOD_DARK := Color("#4a3526")
const STONE_DARK := Color("#4a4f4c")
const MORTAR := Color("#262826")
const ROOF_WOOD := Color("#5e4a3a")
const PLASTER := Color("#b9ad95")
const BEAM := Color("#3b2a1d")
const IVY := Color("#3f6128")

## id → [폭, 높이]
const SIZES := {"inn": Vector2i(176, 150), "library": Vector2i(150, 160), "temple": Vector2i(136, 178),
	"shop": Vector2i(150, 136), "bank": Vector2i(140, 140), "training": Vector2i(184, 112)}


static func paint(id: String, seed_value: int) -> Px:
	var s: Vector2i = SIZES.get(id, Vector2i(140, 140))
	var p := Px.new(s.x, s.y, seed_value)
	match id:
		"inn":
			_inn(p)
		"library":
			_library(p)
		"temple":
			_temple(p)
		"shop":
			_shop(p)
		"bank":
			_bank(p)
		"training":
			_training(p)
	p.outline()
	return p


static func _poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in pts:
		out.append(v)
	return out


## 여관: 큰 너와 지붕 + 지붕창, 가운데 돌 아치(술 창고), 왼쪽 판자 날개(박공), 오른쪽 통나무 날개, 술통·포도주 통.
static func _inn(p: Px) -> void:
	var g := p.h - 1
	p.shingles(_poly([Vector2(14, 78), Vector2(44, 14), Vector2(132, 14), Vector2(164, 78)]), ROOF_WOOD, 4, 3, 7)
	p.rect(44, 12, 88, 2, ROOF_WOOD.darkened(0.4))
	for dx in [62, 104]:  # 지붕창
		p.planks_v(dx, 30, 14, 14, WOOD, 3)
		p.window(dx + 4, 34, 6, 7, true)
		p.shingles(_poly([Vector2(dx - 3, 31), Vector2(dx + 7, 21), Vector2(dx + 17, 31)]), ROOF_WOOD.darkened(0.1), 3, 2)
	p.stones(48, 70, 80, g - 70 + 1, STONE_DARK, MORTAR)
	p.rect(48, 70, 80, 2, Color("#5a5048"))
	p.door(76, 104, 24, g - 104 + 1, Color("#3a2a1e"), true)
	p.shade(76, 104, 24, 20, -0.25)
	p.window(56, 84, 9, 10, true)
	p.window(112, 84, 9, 10, false)
	p.ivy(48, 66, 80, 30, 9, IVY)
	p.planks_v(6, 90, 50, g - 90 + 1, WOOD, 4)
	p.shingles(_poly([Vector2(0, 94), Vector2(31, 50), Vector2(62, 94)]), ROOF_WOOD.lightened(0.05), 4, 3, 3)
	p.rect(26, 70, 10, 10, Color("#2c2119"))
	p.window(28, 72, 6, 7, true)
	p.door(22, 118, 14, g - 118 + 1, WOOD_DARK)
	p.window(10, 104, 8, 9, true)
	p.shade_grad(6, 94, 50, 6, -0.35, -0.05)
	p.planks_h(126, 88, 46, g - 88 + 1, WOOD.lightened(0.04), 4)
	p.shingles(_poly([Vector2(122, 92), Vector2(128, 74), Vector2(176, 74), Vector2(176, 92)]), ROOF_WOOD, 4, 3, 2)
	p.door(150, 116, 13, g - 116 + 1, WOOD_DARK)
	p.window(132, 102, 9, 9, false)
	p.shade_grad(126, 92, 46, 6, -0.35, -0.05)
	Props.sign(p, 56, 98, "mug", true)
	Props.barrel(p, 60, g, 9, 11)
	Props.barrel(p, 69, g, 9, 11)
	Props.barrel(p, 64, g - 11, 8, 9)
	Props.barrel(p, 114, g, 16, 18)
	Props.crate(p, 140, g, 9)
	Props.sack(p, 168, g)


## 도서관: 밝은 돌 + 점판암 지붕, 가운데 박공 + 둥근 창, 높은 아치 창, 쌍여닫이 아치 문, 돌계단.
static func _library(p: Px) -> void:
	var g := p.h - 1
	var slate := Color("#4b525c")
	p.shingles(_poly([Vector2(6, 64), Vector2(26, 28), Vector2(124, 28), Vector2(144, 64)]), slate, 4, 3, 4)
	p.noisy_rect(108, 12, 9, 18, Color("#6d6458"), 0.06)  # 굴뚝
	p.rect(107, 11, 11, 2, Color("#3e3a35"))
	p.stones(10, 62, 130, g - 62 + 1, Color("#9c9482"), Color("#5c564c"), 7, 11)
	p.shingles(_poly([Vector2(44, 66), Vector2(75, 26), Vector2(106, 66)]), slate.darkened(0.08), 4, 3, 2)
	p.stones(52, 62, 46, 20, Color("#a69e8b"), Color("#5c564c"), 6, 9)
	for yy in range(-6, 7):  # 둥근 창
		for xx in range(-6, 7):
			var d := Vector2(xx, yy).length()
			if d <= 6.5:
				p.px(75 + xx, 66 + yy, Color("#2c2119") if d > 5.0 or xx == 0 or yy == 0 else Color("#e8b864").lerp(Color("#a8682a"), (yy + 6) / 12.0))
	for wx in [22, 38, 104, 120]:
		p.window(wx, 86, 8, 24, wx == 38 or wx == 104, Color("#2c2119"), true)
	p.door(64, 104, 22, g - 108, Color("#4a3020"), true)
	p.rect(74, 104, 1, g - 108, Color("#1d140e"))
	for i in 3:
		p.noisy_rect(56 - i * 4, g - 3 + i - 2, 38 + i * 8, 2, Color("#7d776b"), 0.05)
	p.rect(10, 62, 130, 2, Color("#c8bfa8"))
	p.shade_grad(10, 64, 130, 8, -0.3, 0.0)
	p.ivy(10, 70, 26, 40, 5, IVY)
	p.ivy(118, 66, 22, 50, 4, IVY)
	Props.sign(p, 98, 96, "book", true)
	Props.lamp_post(p, 46, g)
	Props.crate(p, 132, g, 8)


## 신전: 밝은 돌 예배당 + 붉은 기와 박공, 왼쪽 종탑과 첨탑, 색유리 아치 창, 큰 아치 문, 촛불.
static func _temple(p: Px) -> void:
	var g := p.h - 1
	var tile := Color("#8a5a4e")
	var pale := Color("#b3a994")
	p.shingles(_poly([Vector2(36, 82), Vector2(86, 30), Vector2(136, 82)]), tile, 4, 3, 3)
	p.stones(44, 78, 86, g - 78 + 1, pale, Color("#6c6558"), 6, 10)
	p.stones(4, 44, 34, g - 44 + 1, pale.darkened(0.05), Color("#6c6558"), 5, 8)
	p.shingles(_poly([Vector2(0, 46), Vector2(21, 2), Vector2(42, 46)]), Color("#4b525c"), 3, 3, 1)
	p.rect(20, 0, 2, 4, Color("#c9a24a"))
	p.rect(17, 1, 8, 1, Color("#c9a24a"))
	p.window(13, 52, 16, 16, false, Color("#2c2119"), true)
	p.rect(19, 58, 4, 7, Color("#8a7a4a"))  # 종
	p.window(15, 92, 10, 20, true, Color("#2c2119"), true)
	for yy in 26:  # 색유리 창
		for xx in 16:
			var d := Vector2(xx - 7.5, yy - 8.0).length()
			if yy < 8 and d > 8.0:
				continue
			var cols := [Color("#a33a35"), Color("#3f5f9b"), Color("#c9a24a"), Color("#4f7a45")]
			var c: Color = cols[((xx / 4) + (yy / 5)) % 4]
			if xx % 4 == 0 or yy % 5 == 0:
				c = Color("#241a14")
			p.px(78 + xx, 88 + yy, p.jit(c, 0.06))
	p.door(72, 124, 28, g - 126, Color("#4a3020"), true)
	p.rect(85, 124, 1, g - 126, Color("#1d140e"))
	for i in 3:
		p.noisy_rect(66 - i * 3, g - 4 + i, 40 + i * 6, 2, Color("#8a8374"), 0.04)
	p.shade_grad(44, 80, 86, 8, -0.3, 0.0)
	p.ivy(110, 84, 20, 50, 4, IVY)
	for cx in [62, 66, 106, 110]:
		Props.candle(p, cx, g - 10 + (cx % 3))
	Props.sign(p, 44, 104, "sun", false)


## 상점: 반목조(흰 회벽 + 검은 들보), 1층 가게 진열창 + 천 차양, 너와 지붕, 상자·자루.
static func _shop(p: Px) -> void:
	var g := p.h - 1
	p.shingles(_poly([Vector2(4, 56), Vector2(30, 14), Vector2(120, 14), Vector2(146, 56)]), ROOF_WOOD.lightened(0.04), 4, 3, 5)
	p.noisy_rect(24, 52, 102, 38, PLASTER, 0.04)
	for bx in [24, 48, 75, 102, 124]:
		p.rect(bx, 52, 3, 38, BEAM)
	p.rect(24, 52, 103, 3, BEAM)
	p.rect(24, 88, 103, 3, BEAM)
	for seg in [[27, 48], [105, 124]]:
		p.line(Vector2i(seg[0], 55), Vector2i(seg[1], 87), BEAM)
		p.line(Vector2i(seg[1], 55), Vector2i(seg[0], 87), BEAM)
	p.window(54, 62, 16, 14, true)
	p.window(81, 62, 16, 14, false)
	p.planks_v(20, 90, 110, g - 90 + 1, WOOD, 4)
	p.rect(30, 98, 60, 22, Color("#21170f"))  # 진열창(안쪽 어둠)
	for i in 5:
		p.rect(33 + i * 11, 104, 8, 6, [Color("#8a6d3b"), Color("#6b4f36"), Color("#9b2a2a"), Color("#4f6b2e"), Color("#c9a24a")][i])
	p.rect(32, 112, 56, 2, WOOD.lightened(0.1))
	p.planks_h(30, 118, 60, 6, WOOD.lightened(0.08), 3)  # 판매대
	for xx in 72:  # 줄무늬 천 차양
		for yy in 9:
			var c := Color("#a8946c") if (xx / 6) % 2 == 0 else Color("#7f6a48")
			if yy == 8 and xx % 6 == 3:
				continue
			p.px(24 + xx, 89 + yy - (1 if yy > 6 and xx % 2 == 0 else 0), p.jit(c.darkened(0.12 * yy / 8.0), 0.04))
	p.door(102, 108, 15, g - 108 + 1, WOOD_DARK)
	p.shade_grad(20, 98, 110, 6, -0.35, 0.0)
	p.ivy(118, 50, 14, 36, 3, IVY)
	Props.sign(p, 126, 92, "bag", true)
	Props.crate(p, 36, g, 9)
	Props.crate(p, 46, g, 8)
	Props.crate(p, 41, g - 8, 7)
	Props.sack(p, 92, g)
	Props.sack(p, 98, g)
	Props.barrel(p, 140, g, 8, 10)


## 은행: 다듬은 회색 돌, 박공 페디먼트, 기둥 둘, 쇠띠 두른 무거운 문, 쇠창살 창.
static func _bank(p: Px) -> void:
	var g := p.h - 1
	var slate := Color("#3f454e")
	var stone := Color("#62666a")
	p.shingles(_poly([Vector2(6, 58), Vector2(22, 26), Vector2(118, 26), Vector2(134, 58)]), slate, 4, 3, 2)
	p.stones(10, 56, 120, g - 56 + 1, stone, Color("#2c2f31"), 10, 14)
	p.shingles(_poly([Vector2(36, 60), Vector2(70, 34), Vector2(104, 60)]), slate.darkened(0.1), 4, 3, 0)
	p.noisy_rect(44, 50, 52, 8, Color("#7a7d80"), 0.04)
	p.rect(68, 51, 4, 4, Color("#c9a24a"))
	p.rect(10, 56, 120, 3, Color("#8a8d90"))
	for cx in [44, 90]:  # 기둥
		p.noisy_rect(cx, 62, 6, g - 66, Color("#8e9194"), 0.04)
		p.rect(cx + 4, 62, 2, g - 66, Color("#5d6063"))
		p.rect(cx - 1, 60, 8, 3, Color("#a5a8ab"))
		p.rect(cx - 1, g - 5, 8, 3, Color("#a5a8ab"))
	p.door(56, 92, 28, g - 96, Color("#3a2a1e"), true)
	for by in [100, 112, 124]:
		p.rect(56, by, 28, 2, Color("#1f1f22"))
		for xx in range(57, 84, 4):
			p.px(xx, by, Color("#7a7a7e"))
	p.rect(68, 112, 4, 4, Color("#c9a24a"))
	for wx in [18, 108]:
		p.window(wx, 76, 14, 22, false)
		for xx in range(wx + 1, wx + 14, 3):
			p.rect(xx, 76, 1, 22, Color("#16161a"))
	for i in 2:
		p.noisy_rect(40 - i * 4, g - 3 + i, 60 + i * 8, 2, Color("#6f7275"), 0.04)
	p.shade_grad(10, 59, 120, 7, -0.3, 0.0)
	p.ivy(10, 60, 18, 20, 2, IVY)
	Props.sign(p, 100, 66, "key", true)
	Props.lamp_post(p, 32, g)


## 훈련장: 뾰족한 통나무 울타리, 오른쪽 초가 헛간, 허수아비·무기걸이·깃발.
static func _training(p: Px) -> void:
	var g := p.h - 1
	for x in range(0, 120, 5):  # 통나무 울타리
		var top := 50 + p.rng.randi_range(0, 4)
		p.planks_v(x, top, 5, g - top - 12, Color("#5e4632"), 5)
		p.px(x + 2, top - 1, Color("#5e4632"))
		p.px(x + 1, top, Color("#5e4632"))
		p.px(x + 3, top, Color("#5e4632"))
	p.rect(0, 66, 120, 2, Color("#3a2a1e"))
	p.rect(0, 84, 120, 2, Color("#3a2a1e"))
	p.planks_h(118, 52, 62, g - 52 - 12, WOOD.lightened(0.05), 4)
	for yy in 26:  # 초가 지붕
		for xx in range(-4, 70):
			var ty := 30 + yy
			var slope := xx * 0.18
			if yy < slope or 114 + xx > 183:
				continue
			var c := Color("#9a8550").darkened(0.25 if (xx + yy * 3) % 5 == 0 else 0.0)
			p.px(114 + xx, ty, p.jit(c.darkened(yy / 60.0), 0.06))
	p.door(140, 78, 16, g - 78 - 11, WOOD_DARK)
	p.window(124, 66, 9, 9, true)
	p.noisy_rect(0, g - 12, 184, 13, Color("#8a7656"), 0.06)  # 모래 마당
	for i in 30:
		p.px(p.rng.randi_range(0, 183), g - p.rng.randi_range(0, 11), Color("#6d5d44"))
	Props.dummy(p, 24, g - 2)
	Props.dummy(p, 52, g - 1)
	Props.weapon_rack(p, 88, g - 2)
	Props.banner(p, 108, g - 1, Color("#8a2f2a"))
	Props.barrel(p, 170, g - 1, 8, 10)
	Props.sign(p, 118, 60, "swords", false)
	p.ivy(0, 48, 30, 20, 2, IVY)
