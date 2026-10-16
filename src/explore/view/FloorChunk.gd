class_name FloorChunk
extends Node2D
## 바닥 칸 묶음(청크) 그리기. 벽 칸은 WallRow가 그린다.
## 포탈처럼 표식 색(color_mark)이 있는 타일은 가운데에 마름모를 얹는다.

var view: FloorView
var cells: Rect2i

var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])


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
			var base := def.color_floor * view.cell_jitter(x, y)
			_pts[0] = Vector2(x * t, y * t)
			_pts[1] = Vector2((x + 1) * t, y * t)
			_pts[2] = Vector2((x + 1) * t, (y + 1) * t)
			_pts[3] = Vector2(x * t, (y + 1) * t)
			_cols[0] = view.vertex_color(x, y, base)
			_cols[1] = view.vertex_color(x + 1, y, base)
			_cols[2] = view.vertex_color(x + 1, y + 1, base)
			_cols[3] = view.vertex_color(x, y + 1, base)
			draw_polygon(_pts, _cols)
			if def.color_mark.a > 0.0:
				_draw_mark(x, y, t, view.vertex_color(x, y, def.color_mark))


func _draw_mark(x: int, y: int, t: int, color: Color) -> void:
	var c := Vector2((x + 0.5) * t, (y + 0.5) * t)
	var r := t * 0.32
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), color)
