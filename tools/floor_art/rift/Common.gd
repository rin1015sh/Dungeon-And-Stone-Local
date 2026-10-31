extends RefCounted
## 균열 그림(A5 — tools/floor_art/rift/specs.json) 공통: 장소 모듈(<place>.gd)이 칠한 바탕·잔손질을 이음매 없는 칸으로 묶고,
## 소품 시트를 만든다(낭떠러지 절벽 면은 장소 모듈이 아니라 공통 Cliff.gd — specs.json places.<장소>.cliff). paint_floor.gd가 부른다.
##
## 장소 모듈 계약(static func, 모두 Paint를 칠하거나 돌려준다 — 빛은 왼쪽 위, 피어 앤 헝거풍 손그림 + 잉크 선):
##   base(p: Paint, style: String, part: String, col: Color, seed: int) -> void
##        재질 바탕(part = "floor" | "top" | "face"). 같은 style·part·seed면 같은 그림(변형끼리 가장자리를 맞추는 데 쓴다).
##        벽 앞면(face)은 아래 skirt px(Common.skirt)가 투명하게 들쭉날쭉 끝나야 한다(바닥 위로 내려오는 밑동).
##   detail(p: Paint, style: String, part: String, v: int, col: Color) -> void
##        변형 v의 잔손질(금·자갈·얼룩·홈…) — 칸 가장자리는 Seam.mask가 바탕으로 되돌리므로 가운데 위주로.
##   stand(tile: String, w: int, h: int, seed: int) -> Paint
##        서 있는 소품 한 칸(투명 RGBA, w × h px = 바닥 2칸 × 3칸). 발(바닥에 닿는 아래 가운데) = (w / 2, h - w * 0.14).
##        한 칸짜리 물건은 바닥 1칸 폭(w / 2) 안팎 — 옆 칸 소품과 겹치지 않게. 줄로 늘어서는 것(탁자·울타리·창살·난간·의자)은
##        좌우 끝이 칸 가장자리(발 ± w / 4)에 닿아 이웃 칸과 이어지게.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")

static var skirt: int = 0


## 이음매 없는 칸 하나: 공통 바탕(seed) 위에 변형 v를 칠하고 가장자리 띠는 공통 바탕으로 되돌린다(Cave.cell과 같은 방식).
static func cell(mod: GDScript, style: String, part: String, v: int, w: int, h: int, col: Color, seed_value: int) -> Paint:
	var edge := Paint.new(w, h, seed_value)
	mod.call("base", edge, style, part, col, seed_value)
	var base := edge.buf
	var p := Paint.new(w, h, seed_value * 31 + v * 977 + 7)
	mod.call("base", p, style, part, col, seed_value + 1000 * (v + 1))
	mod.call("detail", p, style, part, v, col)
	var band := w * 0.14
	for y in h:
		for x in w:
			var m := Seam.mask(x, y, w, h, band, part == "face")
			var i := (y * w + x) * 4
			for j in 4:
				p.buf[i + j] = lerpf(base[i + j], p.buf[i + j], m)
	return p
