extends RefCounted
## 2층 망자의 땅 그림(A5 — Common.gd 계약, docs/plans/floor2.md §3): 핏빛성채 그리는 법을 빌리고 색은 타일 색(검은 진창 · 잿빛 흙 · 회흑 돌)이 정한다.
## 서 있는 소품(묘비 · 죽은 나무 · 바위 · 석상 · 말뚝)은 핏빛성채 소품 시트를 그대로 쓴다(tiles.json f2d_* art.stand).

const Paint := preload("res://tools/city_art/Paint.gd")
const BF := preload("res://tools/floor_art/rift/bf.gd")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	BF.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	BF.detail(p, style, part, v, col)


static func stand(tile: String, w: int, h: int, seed_value: int) -> Paint:
	return BF.stand(tile, w, h, seed_value)
