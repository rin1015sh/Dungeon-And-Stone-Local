extends RefCounted
## 시설 실내 그림 공통 조각(RoomPaint·RoomWalls·RoomFurniture·RoomProps 전용 — CT66): 판자 바닥 · 대리석 바둑판 · 창 · 불꽃 · 빛(작은 그림용 — 큰 지도는 RoomPaint._light_field).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")

const WARM := Color("#ffb060")
const COOL := Color("#9fb2c0")
const VOID := Color("#0b0a09")
const AMBIENT := 0.66  ## 빛이 닿지 않는 곳 배율(2026-10-31 도시를 밝은 구역 하나로 — 실내 방도 맞춰 밝게, CT63)


## 대리석 바둑판(칸 반 크기) — 칸마다 결·얼룩.
static func checker(p: Paint, a: Color, b: Color, t: int) -> Callable:
	var s := t / 2
	return func(x: int, y: int) -> Color:
		var odd := (floori(x / float(s)) + floori(y / float(s))) % 2 == 1
		var c := (b if odd else a).lerp(Color("#8a8070"), absf(p.nz("vs", x, y) - 0.5) * 0.2)
		if posmod(x, s) == 0 or posmod(y, s) == 0:
			c = c.darkened(0.35)
		return p.vary(c, x, y, 0.12)


## 판자 바닥(위에서 본 — 가로 판, 판마다 이음매가 엇갈린다).
static func floor_boards(p: Paint, base: Color, bh: int) -> Callable:
	return func(x: int, y: int) -> Color:
		var row := floori(y / float(bh))
		var ly := posmod(y, bh)
		var len := 150 + int(Paint.hash01(row, 3) * 120.0)
		var lx := posmod(x + int(Paint.hash01(row, 9) * 400.0), len)
		var idx := floori((x + int(Paint.hash01(row, 9) * 400.0)) / float(len))
		if ly == 0 or lx == 0:
			return p.vary(Color("#100b08"), x, y, 0.1)
		var tone := base.lightened((Paint.hash01(row, idx, 5) - 0.5) * 0.3)
		tone = tone.darkened(absf(p.nz("hs", x, y) - 0.5) * 0.45)
		if ly == 1:
			tone = tone.lightened(0.12)
		elif ly >= bh - 2:
			tone = tone.darkened(0.3)
		return p.vary(tone, x, y, 0.16)


## 가운데 높은 창(뾰족 아치): 흐린 하늘빛 유리 · 납 창살 · 돌 틀 · 창턱.
static func window(p: Paint, x: float, y: float, ww: float, wh: float) -> void:
	var outer := Paint.arch_poly(x - 8, y - 8, ww + 16, wh + 16, true)
	p.fill_poly(outer, Mat.ashlar(p, Color("#5a564c"), int(x), int(y), 30, 18))
	Ink.path(p, outer, 2.2)
	var glass := Paint.arch_poly(x, y, ww, wh, true)
	p.fill_poly(glass, func(px: int, py: int) -> Color:
		var v := clampf((py - y) / wh, 0.0, 1.0)
		var c := Color("#8a9aa4").lerp(Color("#4c5862"), v)
		if posmod(px - int(x), int(ww / 3.0)) < 2 or posmod(py - int(y), 22) < 2:
			c = Color("#1c1e1e")
		return p.vary(c, px, py, 0.12))
	Ink.path(p, glass, 2.0)
	var sill := Paint.rect_poly(x - 12, y + wh, ww + 24, 9)
	p.fill_poly(sill, p.flat(Color("#5e5a50"), 0.1))
	Ink.path(p, sill, 1.6)


static func _flame(p: Paint, base: Vector2, s: float) -> void:
	for layer in 3:
		var col: Color = [Color("#c2541e"), Color("#f39a3a"), Color("#ffe2a0")][layer]
		var fh := (12.0 - layer * 3.5) * s
		var fw := (4.0 - layer) * s
		p.fill_poly(Paint.poly([base + Vector2(-fw, 0), base + Vector2(0, -fh), base + Vector2(fw, 0), base + Vector2(0, fw * 0.6)]), p.flat(col, 0.08))


## 어둡게 내린 뒤 광원 둘레만 밝힌다(Interiors.light와 같은 식, 그림 크기 아무거나). lights = [[Vector2, 반지름, 색, 세기] …]
static func light(p: Paint, lights: Array, ambient: float) -> void:
	for y in p.h:
		for x in p.w:
			var k := (y * p.w + x) * 4
			if p.buf[k + 3] <= 0.0:
				continue
			var f := ambient
			for L: Array in lights:
				var d := Vector2(x, y).distance_to(L[0]) / float(L[1])
				if d < 1.0:
					f += (1.0 - d) * (1.0 - d) * float(L[3])
			f = minf(f, 1.25)
			for j in 3:
				p.buf[k + j] *= f
	for L: Array in lights:
		Ink.glow(p, L[0].x, L[0].y, float(L[1]) * 0.45, L[2], float(L[3]) * 0.3)
