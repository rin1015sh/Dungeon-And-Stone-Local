extends RefCounted
## 강철의 묘(rift_iron_tomb) 그림 — Common.gd 계약: 강철과 돌의 왕릉(회청 강철·짙은 점판암·해진 진홍 카펫과 깃발·바랜 금·촛불).
## 바닥 = it_floor(바탕)·it_fdetail(잔손질), 벽 = it_wall·it_wdetail, 소품 = it_stand·it_stand2, 뒷배경 = it_back. 부품은 it_lib.

const Paint := preload("res://tools/city_art/Paint.gd")
const Floor := preload("res://tools/floor_art/rift/it_floor.gd")
const FloorDetail := preload("res://tools/floor_art/rift/it_fdetail.gd")
const Wall := preload("res://tools/floor_art/rift/it_wall.gd")
const WallDetail := preload("res://tools/floor_art/rift/it_wdetail.gd")
const Stand := preload("res://tools/floor_art/rift/it_stand.gd")
const Back := preload("res://tools/floor_art/rift/it_back.gd")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if part == "floor":
		Floor.base(p, style, col, s)
	else:
		Wall.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	if part == "floor":
		FloorDetail.detail(p, style, v, col)
	else:
		WallDetail.detail(p, style, part, v, col)


static func stand(tile: String, w: int, h: int, seed_value: int) -> Paint:
	return Stand.paint(tile, w, h, seed_value)


static func backdrop(w: int, h: int, seed_value: int) -> Paint:
	return Back.paint(w, h, seed_value)
