extends RefCounted
## 균열 그림 — 녹색 탄광(rift_green_mine): Common.gd 계약대로 바탕·잔손질·소품을 칠한다.
## 차가운 청회·보라 바위, 따뜻한 갈색 나무, 녹슨 쇠, 그리고 유일한 진한 색 = 라임빛 결정·슬라임의 빛.
## 바닥 gm_floor(바탕)·gm_floor2(잔손질) · 벽 gm_wall(바탕)·gm_wall2(잔손질) · 소품 gm_stand·gm_stand2 · 공통 부품 gm_kit.

const Paint := preload("res://tools/city_art/Paint.gd")
const Floor := preload("res://tools/floor_art/rift/gm_floor.gd")
const Floor2 := preload("res://tools/floor_art/rift/gm_floor2.gd")
const Wall := preload("res://tools/floor_art/rift/gm_wall.gd")
const Wall2 := preload("res://tools/floor_art/rift/gm_wall2.gd")
const Stand := preload("res://tools/floor_art/rift/gm_stand.gd")
const Stand2 := preload("res://tools/floor_art/rift/gm_stand2.gd")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if part == "floor":
		Floor.base(p, style, col, s)
	else:
		Wall.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	if part == "floor":
		Floor2.detail(p, style, v, col)
	else:
		Wall2.detail(p, style, part, v, col)


static func stand(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	if not Stand.paint(p, tile):
		Stand2.paint(p, tile)
	return p

