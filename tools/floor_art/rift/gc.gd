extends RefCounted
## 빙하굴 균열 그림(A5 — Common.gd 계약): 눈 덮인 비탈·언 호수 → 고드름 아치 안 얼음 동굴 · 얼음 계단과 토템 · 지하수맥 · 얼음 가루 공동.
## 눈은 푸른 그늘이 진 밝은 흰색, 얼음은 비치는 청록, 깊은 곳은 남빛 — 따뜻한 색은 토템·모닥불에만. 피어 앤 헝거풍 잉크·붓결·때.
## 바닥 gc_floor(_detail) · 벽 gc_wall · 소품 gc_stand(2) · 공통 부품 gc_mat.

const Paint := preload("res://tools/city_art/Paint.gd")
const Floor := preload("res://tools/floor_art/rift/gc_floor.gd")
const FloorDetail := preload("res://tools/floor_art/rift/gc_floor_detail.gd")
const Wall := preload("res://tools/floor_art/rift/gc_wall.gd")
const Stand := preload("res://tools/floor_art/rift/gc_stand.gd")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if part == "floor":
		Floor.base(p, style, col, s)
	else:
		Wall.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	if part == "floor":
		FloorDetail.paint(p, style, v, col)
	else:
		Wall.detail(p, style, part, v, col)


static func stand(tile: String, w: int, h: int, seed_value: int) -> Paint:
	return Stand.paint(tile, w, h, seed_value)

