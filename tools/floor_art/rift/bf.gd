extends RefCounted
## 핏빛성채 그림(A5 — Common.gd 계약): 검은 요새·붉은 하늘·피 금 간 바닥(사용자 첨부 그림 — 붉은 고딕 대성당).
## 바닥 = bf_floor(바탕)·bf_floor_detail(잔손질), 벽 = bf_wall, 서 있는 소품 = bf_stand(0~15)·bf_stand2(16~30). 낭떠러지 절벽 면 = Cliff.gd(공통).
## 색: 검붉은 돌·소피·잿빛 갈색·녹슨 쇠·바랜 금 — 빛나는 붉은색은 피와 빛에만.

const Paint := preload("res://tools/city_art/Paint.gd")
const Floor := preload("res://tools/floor_art/rift/bf_floor.gd")
const FloorDetail := preload("res://tools/floor_art/rift/bf_floor_detail.gd")
const Wall := preload("res://tools/floor_art/rift/bf_wall.gd")
const Stand := preload("res://tools/floor_art/rift/bf_stand.gd")
const Stand2 := preload("res://tools/floor_art/rift/bf_stand2.gd")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if part == "floor":
		Floor.base(p, style, col, s)
	else:
		Wall.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	if part == "floor":
		FloorDetail.detail(p, style, v, col)
	else:
		Wall.detail(p, style, part, v, col)


static func stand(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	if not Stand.paint(p, tile):
		Stand2.paint(p, tile)
	return p

