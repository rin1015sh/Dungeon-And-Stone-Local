extends RefCounted
## 동네 집 굽기의 면 그림(입면도): 면(Geo) 하나를 횡스크롤 건물과 같은 붓 — Paint 캔버스 · Mat 재질(회벽·마름돌·점판암·기와·벽돌·들보) ·
## Parts 부품(벽 그늘·창·문·돌림띠·기단·지붕·간판·등) · Ink(잉크 윤곽·빗금·빛 번짐) · Dress(꽃상자) — 로 평평하게 그린다.
## 그린 그림은 Warp가 기운 3/4 면에 옮겨 붙인다. P = 칸당 px(입면도 해상도). 색은 횡스크롤 도시 그림의 색(Buildings·Buildings2 상수).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Dress := preload("res://tools/city_art/Dress.gd")
const Buildings := preload("res://tools/city_art/Buildings.gd")
const B2 := preload("res://tools/city_art/Buildings2.gd")
const Icons := preload("res://tools/city_art/Icons.gd")

## 횡스크롤 도시 그림의 색(Buildings.PLASTER·SLATE·CLAY, Buildings2.SHOP_PLASTER·BANK_STONE, 여관 아래층 돌 …) + 비슷한 이웃 색.
const PLASTER := [Color("#8b8068"), Color("#8c7a55"), Color("#857d6c"), Color("#7d7768"), Color("#90856c")]
const STONE := [Color("#6e695e"), Color("#575a54"), Color("#66625a"), Color("#5f5b52")]
const SLATE := [Color("#3a4044"), Color("#353b42"), Color("#40464a")]
const CLAY := [Color("#6b3b2d"), Color("#5e3a2e")]
const WOOD := Color("#3b2a1e")
const BANNER := [Color("#6e1f22"), Color("#23345a")]
const DARK_STONE := Color("#4f4c45")


static func pick(h: Dictionary, k: int, n: int) -> int:
	return int(absi(int(h.get("look", 0)) * (k * 7 + 3) + k * 131) / 7) % maxi(1, n)


static func style_of(h: Dictionary) -> String:
	var s := str(h.get("style", "plaster"))
	match s:
		"stone", "workshop":
			return "stone"
		"timber", "inn", "hall":
			return "timber"
	return "plaster"


static func roof_slate(h: Dictionary) -> bool:
	return str(h.get("style", "")) in ["stone", "workshop", "hall"] or pick(h, 2, 5) < 3


## 면 하나를 평평하게 그린 캔버스(크기 = 면 크기 × P, 면 밖은 투명).
static func face(f: Dictionary, h: Dictionary, P: float, seed_value: int) -> Paint:
	var size: Vector2 = f["size"]
	var p := Paint.new(maxi(2, int(ceil(size.x * P)) + 1), maxi(2, int(ceil(size.y * P)) + 1), seed_value)
	var poly := PackedVector2Array()
	for l: Vector2 in f["local"]:
		poly.append(l * P)
	match str(f["kind"]):
		"wall":
			_wall(p, poly, f, h, P)
		"gable":
			_gable(p, poly, h, P)
		"roof":
			_roof(p, poly, h, P, bool((f["info"] as Dictionary).get("small", false)))
		"dormer":
			_dormer(p, poly, h, P)
		"chimney":
			p.fill_poly(poly, Mat.brick(p, Color("#5b3a2c"), 0, 0, int(P * 0.2), int(P * 0.1)))
			Ink.path(p, poly, 1.6)
		"chimney_top":
			p.fill_poly(poly, p.flat(Color("#2a2622"), 0.1))
			Ink.path(p, poly, 1.4)
		_:
			p.fill_poly(poly, p.flat(Color("#6e695e"), 0.1))
	return p


static func _wall_shader(p: Paint, h: Dictionary, P: float, style: String) -> Callable:
	if style == "stone":
		return Mat.ashlar(p, STONE[pick(h, 1, STONE.size())], 0, 0, int(P * 0.62), int(P * 0.28))
	return Mat.plaster(p, PLASTER[pick(h, 1, PLASTER.size())], 0.14 if pick(h, 12, 3) == 0 else 0.0)


static func _wall(p: Paint, poly: PackedVector2Array, f: Dictionary, h: Dictionary, P: float) -> void:
	var W := float(p.w - 1)
	var H := float(p.h - 1)
	var style := style_of(h)
	var floors := int(h.get("floors", 2))
	var base := H - floors * P  # 기단 높이(px)
	Parts.wall(p, poly, _wall_shader(p, h, P, style))
	if style == "timber":
		var low := Paint.rect_poly(0, H - P - base, W, P + base)
		p.fill_poly(low, Mat.ashlar(p, STONE[pick(h, 3, STONE.size())], 0, 0, int(P * 0.62), int(P * 0.28)))
		Ink.shade(p, low, Vector2(0, H - P - base), Vector2(0, H - P - base + P * 0.3), 0.5, 0.0)
		if floors >= 2:
			Buildings._timber(p, 0, 0, W, H - P - base, maxi(2, int(W / (P * 0.75))))
		Parts.ledge(p, -2, H - P - base - 4, W + 4, 6, Color("#5a4636"))
	elif style == "stone":
		for fl in range(1, floors):
			Parts.ledge(p, -2, H - base - fl * P - 3, W + 4, 5)
	var n := maxi(1, int(W / (P * 1.1)))
	var front := bool((f["info"] as Dictionary).get("front", false))
	var fac := str(h.get("facility", ""))
	var door_k := pick(h, 8, n) if front and fac.is_empty() else -1
	var shutters := style == "plaster" and pick(h, 9, 2) == 0
	var arch := style == "stone" and pick(h, 10, 2) == 0
	var flowers := pick(h, 11, 3) == 0
	var ww := P * 0.34
	var wh := P * 0.46
	for fl in floors:
		var top := H - base - (fl + 1) * P
		for k in n:
			var cx := W * (k + 0.5) / n
			if fl == 0 and k == door_k:
				Parts.door(p, cx - P * 0.22, H - base - P * 0.74, P * 0.44, P * 0.74, pick(h, 13, 2) == 0, WOOD, pick(h, 14, 3) == 0)
				continue
			if fl == 0 and front and not fac.is_empty():
				continue
			var lit := Paint.hash01(int(h.get("look", 0)), k * 7 + fl, 5) < 0.3
			Parts.window(p, cx - ww * 0.5, top + P * 0.24, ww, wh, "arch" if arch else "square", lit, shutters and fl > 0)
			if flowers and fl > 0 and (k + fl) % 2 == 0:
				Dress._flower_box(p, Rect2(cx - ww * 0.5, top + P * 0.24, ww, wh), k + fl)
	Parts.plinth(p, 0, H - base, W, base)
	if front and not fac.is_empty():
		_facility_front(p, h, P, W, H, base)


static func _gable(p: Paint, poly: PackedVector2Array, h: Dictionary, P: float) -> void:
	var style := style_of(h)
	Parts.wall(p, poly, _wall_shader(p, h, P, "plaster" if style == "timber" else style))
	var W := float(p.w - 1)
	var H := float(p.h - 1)
	if style == "timber":
		Ink.line(p, Vector2(W * 0.5, H * 0.15), Vector2(W * 0.5, H), 6.0, Color("#2a1e15"), 1.0, 0.3)
	if H > P * 0.7:
		Parts.window(p, W * 0.5 - P * 0.13, H * 0.45, P * 0.26, P * 0.3, "arch", pick(h, 15, 3) == 0)


static func _roof(p: Paint, poly: PackedVector2Array, h: Dictionary, P: float, small: bool) -> void:
	var big := p.w > P * 4.5 or p.h > P * 4.5
	var tw := int(P * (0.16 if small else (0.32 if big else 0.24)))
	var th := int(P * (0.1 if small else (0.2 if big else 0.15)))
	if roof_slate(h):
		Parts.roof(p, poly, Mat.slate(p, SLATE[pick(h, 3, SLATE.size())], 0, 0, tw, th, 0.3))
	else:
		Parts.roof(p, poly, Mat.clay(p, CLAY[pick(h, 3, CLAY.size())], 0, 0, tw, th))


static func _dormer(p: Paint, poly: PackedVector2Array, h: Dictionary, P: float) -> void:
	Parts.wall(p, poly, Mat.plaster(p, PLASTER[pick(h, 1, PLASTER.size())]))
	var W := float(p.w - 1)
	var H := float(p.h - 1)
	Parts.window(p, W * 0.5 - P * 0.14, H * 0.32, P * 0.28, P * 0.34, "square", pick(h, 16, 3) == 0)


## 시설 앞벽 꾸밈(횡스크롤 시설 그림의 부품 그대로): 큰 문 · 간판 · 등 · 기둥 · 깃발 · 아치 · 차양 · 화덕.
static func _facility_front(p: Paint, h: Dictionary, P: float, W: float, H: float, base: float) -> void:
	var door: Vector2i = h["door"]
	var rc: Rect2i = h["rect"]
	var cx := (door.x + 0.5 - rc.position.x) * P
	var g := H - base
	match str(h.get("style", "")):
		"stone":  # 은행: 기둥 넷 · 박공 · 큰 문 · 열쇠 간판
			for k in [-2.2, -1.1, 1.1, 2.2]:
				B2._column(p, cx + float(k) * P - P * 0.14, g - P * 1.6, P * 0.28, P * 1.6)
			var ped := Paint.poly([Vector2(cx - 2.6 * P, g - P * 1.6), Vector2(cx, g - P * 2.25), Vector2(cx + 2.6 * P, g - P * 1.6)])
			p.fill_poly(ped, Mat.ashlar(p, Color("#77736a"), 0, 0, int(P * 0.5), int(P * 0.22)))
			Ink.path(p, ped, Parts.LINE)
			Parts.door(p, cx - P * 0.4, g - P * 1.15, P * 0.8, P * 1.15, true, WOOD, true)
			Parts.sign(p, cx + P * 0.6, g - P * 1.35, "key", 1.0, P * 0.55)
		"hall":  # 길드: 큰 아치 문 · 깃발 둘 · 문장 간판
			Parts.door(p, cx - P * 0.5, g - P * 1.2, P * 1.0, P * 1.2, true, WOOD, true)
			for k in [-1.7, 1.7]:
				var bx := cx + float(k) * P - P * 0.2
				var ban := Paint.poly([Vector2(bx, g - P * 2.6), Vector2(bx + P * 0.4, g - P * 2.6), Vector2(bx + P * 0.4, g - P * 1.4), Vector2(bx + P * 0.2, g - P * 1.25), Vector2(bx, g - P * 1.4)])
				p.fill_poly(ban, Mat.planks(p, BANNER[0], int(bx), 0, true, 6))
				Ink.path(p, ban, 1.8)
				Icons.draw(p, "crest", Vector2(bx + P * 0.2, g - P * 2.1), P * 0.14)
			Parts.lantern(p, cx - P * 0.75, g - P * 0.9, 0.7)
			Parts.lantern(p, cx + P * 0.75, g - P * 0.9, 0.7)
		"inn":  # 여관: 문틈 불빛 · 술잔 간판 · 등 둘
			Parts.door(p, cx - P * 0.36, g - P * 0.9, P * 0.72, P * 0.9, true, WOOD, true)
			Parts.lantern(p, cx - P * 0.6, g - P * 0.75, 0.7)
			Parts.lantern(p, cx + P * 0.6, g - P * 0.75, 0.7)
			Parts.sign(p, cx + P * 0.9, g - P * 1.05, "mug", 1.0, P * 0.55)
		"arcade":  # 잡화점: 1층 아치 가게창 · 줄무늬 차양 · 자루 간판
			var n := maxi(3, int(W / (P * 1.6)))
			for k in n:
				var ax := W * (k + 0.5) / n
				var arch := Paint.arch_poly(ax - P * 0.42, g - P * 0.85, P * 0.84, P * 0.85, false)
				p.fill_poly(arch, Mat.glass(p, g - P * 0.85, g, absf(ax - cx) < P * 0.6 or k % 2 == 0))
				Ink.path(p, arch, Parts.LINE)
			var aw := Paint.poly([Vector2(0, g - P * 1.0), Vector2(W, g - P * 1.0), Vector2(W, g - P * 0.88), Vector2(0, g - P * 0.88)])
			p.fill_poly(aw, func(x: int, y: int) -> Color: return p.vary(Color("#7a2e28") if (x / int(P * 0.25)) % 2 == 0 else Color("#cdbf9c"), x, y, 0.12))
			Ink.path(p, aw, 1.8)
			Parts.sign(p, cx + P * 0.4, g - P * 1.35, "bag", 1.0, P * 0.5)
		"workshop":  # 대장간: 넓은 화덕 입구 · 불빛 · 모루 간판
			var mouth := Paint.arch_poly(cx - P * 0.7, g - P * 1.1, P * 1.4, P * 1.1, false)
			p.fill_poly(mouth, p.flat(Color("#120d0a"), 0.1))
			Ink.glow(p, cx, g - P * 0.25, P * 0.9, Color("#ff8a3a"), 0.75, false, 0.6)
			Ink.path(p, mouth, Parts.LINE)
			Parts.sign(p, cx + P * 0.8, g - P * 1.35, "anvil", 1.0, P * 0.55)
