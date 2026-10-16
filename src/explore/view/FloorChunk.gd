class_name FloorChunk
extends Node2D
## 바닥 칸 묶음(청크) 그리기. 벽 칸은 WallRow가 그린다.
## 재질 아틀라스가 있는 타일(tiles.json art)은 그림 한 칸(FloorArtLayer 변형) × 꼭짓점 빛 배율(FloorView.vertex_mul)로,
## 없는 타일은 색칠한 칸(타일 색 × 꼭짓점 색)으로 그린다.
## 포탈처럼 표식 색(color_mark)이 있는 타일은 가운데에 마름모를 얹는다.

var view: FloorView
var cells: Rect2i

var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
var _uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])


func setup(p_view: FloorView, p_cells: Rect2i) -> void:
	view = p_view
	cells = p_cells


func _draw() -> void:
	var map := view.map
	var t := view.tile
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var i := y * map.width + x
			if map.explored[i] == 0:
				continue
			var def := map.defs[map.tiles[i]]
			if def.is_wall():
				continue
			_pts[0] = Vector2(x * t, y * t)
			_pts[1] = Vector2((x + 1) * t, y * t)
			_pts[2] = Vector2((x + 1) * t, (y + 1) * t)
			_pts[3] = Vector2(x * t, (y + 1) * t)
			var tex := view.tile_tex[def.index]
			if tex != null:
				var v := FloorArtLayer.variant(x, y, def.art_variants, def.art_salt)
				set_uv_cell(_uvs, tex, v, def.art_variants, 0.0, 1.0)
				_cols[0] = view.vertex_mul(x, y, def.color_floor)
				_cols[1] = view.vertex_mul(x + 1, y, def.color_floor)
				_cols[2] = view.vertex_mul(x + 1, y + 1, def.color_floor)
				_cols[3] = view.vertex_mul(x, y + 1, def.color_floor)
				draw_polygon(_pts, _cols, _uvs, tex)
			else:
				var base := def.color_floor * view.cell_jitter(x, y)
				_cols[0] = view.vertex_color(x, y, base)
				_cols[1] = view.vertex_color(x + 1, y, base)
				_cols[2] = view.vertex_color(x + 1, y + 1, base)
				_cols[3] = view.vertex_color(x, y + 1, base)
				draw_polygon(_pts, _cols)
			if def.color_mark.a > 0.0:
				_draw_mark(x, y, t, view.vertex_color(x, y, def.color_mark))


## 아틀라스 칸 v(가로 n칸)의 세로 구간 [v0, v1](0~1) UV를 사각형 네 꼭짓점(왼위·오위·오아래·왼아래)에 넣는다.
## 반 텍셀 안쪽으로 줄여 옆 칸이 번지지 않게 한다.
static func set_uv_cell(uvs: PackedVector2Array, tex: Texture2D, v: int, n: int, v0: float, v1: float) -> void:
	var hx := 0.5 / tex.get_width()
	var hy := 0.5 / tex.get_height()
	var u0 := float(v) / n + hx
	var u1 := float(v + 1) / n - hx
	uvs[0] = Vector2(u0, v0 + hy)
	uvs[1] = Vector2(u1, v0 + hy)
	uvs[2] = Vector2(u1, v1 - hy)
	uvs[3] = Vector2(u0, v1 - hy)


func _draw_mark(x: int, y: int, t: int, color: Color) -> void:
	var c := Vector2((x + 0.5) * t, (y + 0.5) * t)
	var r := t * 0.32
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), color)
