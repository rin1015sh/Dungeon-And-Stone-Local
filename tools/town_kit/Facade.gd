extends RefCounted
## 집 짓기 도구의 면 그림(횡스크롤 건물 붓 그대로 — Paint · Mat · Parts · Ink · Buildings._timber · Dress._flower_box · Icons).
## 모두 Kit.face의 painter(p, poly_px, size_units)를 돌려준다. 칸당 P px, 한 층 = storey칸.
## 색(사용자 2026-11-02): 지붕은 어두운 갈색 한 계열(참고 그림 3·4번처럼 통일) · 벽은 크림 회벽 + 검은 들보 · 회색 돌 · 벽돌.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const Dress := preload("res://tools/city_art/Dress.gd")
const Buildings := preload("res://tools/city_art/Buildings.gd")
const Icons := preload("res://tools/city_art/Icons.gd")

## 회벽(사용자 2026-11-03 "전체적 색감이 예전이 나은 것 같은데" — CT99, 예전 바랜 크림 · 회갈색으로 되돌림).
const PLASTER := [Color("#bfb092"), Color("#b3a687"), Color("#c7b998"), Color("#a99c80"), Color("#b8ab92")]
const STONE := [Color("#7a756b"), Color("#6c675e"), Color("#837d71")]
const BRICK := Color("#6e4a3a")
const TIMBER := Color("#33251b")
## 지붕: 어두운 갈색 한 계열.
## 지붕: 어두운 갈색 한 계열(예전 색 — CT99). 집마다 굽는 쪽이 같은 계열 안에서 조금씩 다른 기운을 곱한다(HouseFit.ROOF_TINTS).
const ROOF := [Color("#4a3a2e"), Color("#3f342b"), Color("#54423a"), Color("#3a302a")]
const WOOD := Color("#3b2a1e")
static var P := 64.0
static var storey := 1.15
## 문(사용자 2026-11-02 "플레이어가 들어갈 수 있을 정도의 사이즈"): 폭 0.86칸(사람 몸 한 칸이 지나간다) · 높이 한 층의 0.88(사람 키보다 조금 높다).
const DOOR_W := 0.86
const DOOR_H := 0.88


## 벽 폭(칸)과 문 자리(0~1)로 문 가운데가 벽 왼쪽 끝에서 몇 칸인가(창 칸 나누기와 같은 규칙 — Designs가 문 앞 디딤돌을 놓는다).
static func door_x(width: float, frac: float) -> float:
	var n := maxi(1, int(width / 1.05))
	var k := clampi(int(frac * n), 0, n - 1)
	return width * (k + 0.5) / n


static func _door(p: Paint, cx: float, ground: float, arch: bool) -> void:
	var dw := P * DOOR_W
	var dh := storey * P * DOOR_H
	Parts.door(p, cx - dw * 0.5, ground - dh, dw, dh, arch, WOOD, true)


static func _box(poly: PackedVector2Array) -> Rect2:
	return Paint.bounds(poly)


static func _shader(p: Paint, style: String, ci: int) -> Callable:
	match style:
		"stone":
			return Mat.ashlar(p, STONE[ci % STONE.size()], 0, 0, int(P * 0.6), int(P * 0.27))
		"brick":
			return Mat.brick(p, BRICK.lightened((ci % 3) * 0.04), 0, 0, int(P * 0.3), int(P * 0.13))
		"rubble":
			return Mat.rubble(p, STONE[ci % STONE.size()].darkened(0.1))
	return Mat.plaster(p, PLASTER[ci % PLASTER.size()], 0.1 if ci % 3 == 0 else 0.0)


## 층이 있는 벽: o = {style(plaster·timber·stone·brick), floors, ci(색), door(0~1 자리, 없으면 -1), shop, arch, shutters, flowers, lit(0~1), win(square·arch·gothic), sign(아이콘), base(기단 칸)}.
static func wall(o: Dictionary) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := _box(poly)
		var W := r.size.x
		var g := r.end.y
		var style := str(o.get("style", "plaster"))
		var floors := int(o.get("floors", 1))
		var ci := int(o.get("ci", 0))
		var base := float(o.get("base", 0.0)) * P
		var fh := storey * P
		Parts.wall(p, poly, _shader(p, "plaster" if style == "timber" else style, ci))
		if style == "timber":
			Buildings._timber(p, r.position.x, maxf(r.position.y, g - base - floors * fh), W, minf(r.size.y, floors * fh), maxi(2, int(W / (P * 0.8))))
		if base > 0.0:
			Parts.plinth(p, r.position.x, g - base, W, base)
		var n := maxi(1, int(W / (P * 1.05)))
		var door := float(o.get("door", -1.0))
		var door_k := clampi(int(door * n), 0, n - 1) if door >= 0.0 else -1
		for fl in floors:
			var top := g - base - (fl + 1) * fh
			if style in ["stone", "brick"] and fl > 0:
				Parts.ledge(p, r.position.x - 2, top + fh - 3, W + 4, 5)
			for k in n:
				var cx := r.position.x + W * (k + 0.5) / n
				if fl == 0 and bool(o.get("arch", false)) and k == n / 2:
					var a := Paint.arch_poly(cx - P * 0.5, g - base - fh * 0.95, P * 1.0, fh * 0.95, false)
					p.fill_poly(a, p.flat(Color("#141110"), 0.05))
					Ink.path(p, a, Parts.LINE)
					continue
				if fl == 0 and k == door_k:
					_door(p, cx, g, int(o.get("ci", 0)) % 2 == 0)  # 문은 땅까지(기단을 끊는다)
					continue
				if fl == 0 and bool(o.get("shop", false)):
					var sw := Paint.rect_poly(cx - P * 0.38, g - base - fh * 0.78, P * 0.76, fh * 0.58)
					p.fill_poly(sw, Mat.glass(p, g - base - fh * 0.78, g - base - fh * 0.2, k % 2 == 0))
					Ink.path(p, sw, Parts.LINE)
					continue
				var lit := Paint.hash01(ci * 31 + k, fl, 7) < float(o.get("lit", 0.3))
				var ww := P * 0.32
				var wh := fh * 0.42
				Parts.window(p, cx - ww * 0.5, top + fh * 0.24, ww, wh, str(o.get("win", "square")), lit, bool(o.get("shutters", false)))
				if bool(o.get("flowers", false)) and fl == 1 and k % 2 == 0:
					Dress._flower_box(p, Rect2(cx - ww * 0.5, top + fh * 0.24, ww, wh), k)
		if not str(o.get("sign", "")).is_empty():
			Parts.sign(p, r.position.x + W * 0.78, g - base - fh * 0.98, str(o["sign"]), 1.0, P * 0.42)


## 박공 삼각·지붕창 앞벽: 회벽(또는 돌) + 가운데 작은 창, 반목조면 가운데 들보.
static func gable(style: String, ci: int, window: bool = true) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := _box(poly)
		Parts.wall(p, poly, _shader(p, "plaster" if style == "timber" else style, ci))
		if style == "timber":
			Ink.line(p, Vector2(r.get_center().x, r.position.y + r.size.y * 0.2), Vector2(r.get_center().x, r.end.y), 6.0, TIMBER, 1.0, 0.3)
			Ink.line(p, Vector2(r.position.x + r.size.x * 0.15, r.end.y - 4), Vector2(r.end.x - r.size.x * 0.15, r.end.y - 4), 6.0, TIMBER, 1.0, 0.3)
		if window and r.size.y > P * 0.6:
			Parts.window(p, r.get_center().x - P * 0.14, r.position.y + r.size.y * 0.42, P * 0.28, minf(P * 0.36, r.size.y * 0.4), "arch", ci % 2 == 0)


## 지붕(어두운 갈색 너와·점판암 한 계열). small = 지붕창·작은 지붕(잔 비늘).
static func roof(ci: int, small: bool = false) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var tw := int(P * (0.16 if small else 0.26))
		var th := int(P * (0.1 if small else 0.16))
		Parts.roof(p, poly, _tiles(ROOF[ci % ROOF.size()], tw, th))


## 차분한 기와 · 너와(줄 그늘 얕게, 장마다 밝기 차 작게 — 지붕이 탁하고 시끄럽지 않게, CT98).
static func _tiles(base: Color, tw: int, th: int) -> Callable:
	return func(x: int, y: int) -> Color:
		var row := floori(float(y) / th)
		var lx := x + (tw / 2 if row % 2 != 0 else 0)
		var col := floori(float(lx) / tw)
		var by := posmod(y, th)
		var bx := posmod(lx, tw)
		var tone := base.lightened((Paint.hash01(row, col, 5) - 0.5) * 0.16)
		if by >= th - 2:
			tone = tone.darkened(0.35)
		elif bx == 0:
			tone = tone.darkened(0.18)
		return tone


## 단색 재질(굴뚝 벽돌·돌기둥·나무·검은 입구 …).
static func plain(kind: String, ci: int = 0) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		match kind:
			"brick":
				p.fill_poly(poly, Mat.brick(p, Color("#5b3a2c"), 0, 0, int(P * 0.2), int(P * 0.1)))
			"stone":
				p.fill_poly(poly, Mat.ashlar(p, STONE[ci % STONE.size()], 0, 0, int(P * 0.5), int(P * 0.25)))
			"wood":
				p.fill_poly(poly, Mat.planks(p, Color("#4d3726"), 0, 0, false, int(P * 0.14)))
			"dark":
				p.fill_poly(poly, p.flat(Color("#1c1816"), 0.06))
			"cobble":
				p.fill_poly(poly, Mat.rubble(p, Color("#5f5a52")))
		Ink.path(p, poly, 1.6)


## 탑 벽: 돌 + 층마다 좁은 뾰족 창(맨 위는 종 창 — 어둡게, 종).
static func tower(ci: int, floors: int, belfry: bool, door: bool = false) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := _box(poly)
		Parts.wall(p, poly, _shader(p, "stone", ci))
		if door:
			_door(p, r.get_center().x, r.end.y, true)
		var fh := storey * P
		for fl in floors:
			var y := r.end.y - (fl + 1) * fh
			if fl == floors - 1 and belfry:
				var a := Paint.arch_poly(r.get_center().x - P * 0.3, y + fh * 0.12, P * 0.6, fh * 0.8, true)
				p.fill_poly(a, p.flat(Color("#120f0e"), 0.05))
				Ink.path(p, a, Parts.LINE)
				Ink.glow(p, r.get_center().x, y + fh * 0.6, P * 0.25, Color("#c9a24a"), 0.5, true)
			elif fl > 0 or not door:
				Parts.window(p, r.get_center().x - P * 0.12, y + fh * 0.22, P * 0.24, fh * 0.48, "gothic", fl % 2 == 1)
			Parts.ledge(p, r.position.x - 2, y + fh - 3, r.size.x + 4, 4)


## 줄무늬 천(차양).
static func awning() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var band := int(P * 0.22)
		p.fill_poly(poly, func(x: int, y: int) -> Color: return p.vary(Color("#7a2e28") if (x / band) % 2 == 0 else Color("#cdbf9c"), x, y, 0.12))
		Ink.path(p, poly, 1.8)


## 난간 회랑(나무 판 + 난간 살).
static func gallery() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := _box(poly)
		p.fill_poly(poly, Mat.planks(p, Color("#4d3726"), 0, 0, true, int(P * 0.12)))
		Ink.line(p, Vector2(r.position.x, r.position.y + 3), Vector2(r.end.x, r.position.y + 3), 5.0, TIMBER, 1.0, 0.2)
		Ink.path(p, poly, 1.6)


## 길드 깃발·현수막(검붉은 천 + 뼈빛 돌 고리 문장 — 차원광장의 돌 고리, 아래 술).
static func banner() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := _box(poly)
		p.fill_poly(poly, func(x: int, y: int) -> Color: return p.vary(Color("#5a2622"), x, y, 0.1))
		var c := Vector2(r.get_center().x, r.position.y + r.size.y * 0.42)
		var rad := minf(r.size.x, r.size.y) * 0.3
		p.fill_poly(Icons._circle(c, rad), p.flat(Color("#c9bc9a"), 0.08))
		p.fill_poly(Icons._circle(c, rad * 0.68), p.flat(Color("#5a2622"), 0.1))
		Ink.line(p, Vector2(r.position.x + 3, r.position.y + 4), Vector2(r.end.x - 3, r.position.y + 4), 4.0, Color("#8a7a52"), 1.0, 0.2)
		for i in int(r.size.x / 7.0):
			var x := r.position.x + 4 + i * 7.0
			Ink.line(p, Vector2(x, r.end.y - 9), Vector2(x, r.end.y - 2), 1.6, Color("#8a7a52"), 1.0, 0.3)
		Ink.path(p, poly, 1.6)
