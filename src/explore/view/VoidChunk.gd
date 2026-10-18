class_name VoidChunk
extends Node2D
## 청크 하나의 낭떠러지 칸(void 타일 — 균열 경계): 탐험한 칸에 뒷배경(Backdrop 셰이더 — 화면 고정 + 시차)을 비추고,
## 위(북쪽)가 땅인 칸에는 가장자리에서 아래로 떨어지는 절벽 면(색 → 투명)을, 옆이 땅이면 가는 그늘을 얹는다.
## 바닥 층보다 아래(void_layer). 안개 밝기는 FloorView.fog_mul(횃불 빛은 곱하지 않는다).

var view: FloorView
var cells: Rect2i
var _void: Array[Vector2i] = []
var _cliffs: Node2D  # 절벽 면을 그리는 자식(뒷배경 셰이더를 쓰지 않는다)
var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])


func setup(p_view: FloorView, p_cells: Rect2i) -> void:
	view = p_view
	cells = p_cells
	var map := view.map
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			if map.defs[map.tiles[y * map.width + x]].is_void:
				_void.append(Vector2i(x, y))
	if has_void():
		_cliffs = Node2D.new()
		_cliffs.draw.connect(func() -> void: draw_cliffs(_cliffs))
		add_child(_cliffs)


func has_void() -> bool:
	return not _void.is_empty()


func _draw() -> void:
	var map := view.map
	var t := float(view.tile)
	for p in _void:
		if map.explored[p.y * map.width + p.x] == 0:
			continue
		_quad(p.x * t, p.y * t, t, t)
		for k in 4:
			var f := view.fog_mul(p.x + (1 if k == 1 or k == 2 else 0), p.y + (1 if k >= 2 else 0))
			_cols[k] = Color(f, f, f, 1.0)
		draw_polygon(_pts, _cols)
	if _cliffs != null:
		_cliffs.queue_redraw()


func _quad(x: float, y: float, w: float, h: float) -> void:
	_pts[0] = Vector2(x, y)
	_pts[1] = Vector2(x + w, y)
	_pts[2] = Vector2(x + w, y + h)
	_pts[3] = Vector2(x, y + h)


## 절벽 면(뒷배경 위): 북쪽이 땅이면 위 가장자리에서 아래로 cliff_depth칸 띠, 서·동쪽이 땅이면 옆 그늘.
func draw_cliffs(cv: CanvasItem) -> void:
	var map := view.map
	var t := float(view.tile)
	var col := Backdrop.cliff_color(view.art)
	var depth := Backdrop.cliff_depth(view.art) * t
	for p in _void:
		if map.explored[p.y * map.width + p.x] == 0:
			continue
		var fl := view.fog_mul(p.x, p.y)
		var fr := view.fog_mul(p.x + 1, p.y)
		var top := Color(col.r * fl, col.g * fl, col.b * fl, 1.0)
		var top_r := Color(col.r * fr, col.g * fr, col.b * fr, 1.0)
		if _ground(map, p + Vector2i(0, -1)):
			_quad(p.x * t, p.y * t, t, depth)
			_cols[0] = top
			_cols[1] = top_r
			_cols[2] = Color(top_r.r, top_r.g, top_r.b, 0.0)
			_cols[3] = Color(top.r, top.g, top.b, 0.0)
			cv.draw_polygon(_pts, _cols)
			cv.draw_line(Vector2(p.x * t, p.y * t), Vector2((p.x + 1) * t, p.y * t), top.darkened(0.6), 1.5)
		for side: int in [-1, 1]:
			if _ground(map, p + Vector2i(side, 0)):
				var x0 := (p.x + (0 if side < 0 else 1)) * t
				var x1 := x0 - side * t * 0.28
				_pts[0] = Vector2(x0, p.y * t)
				_pts[1] = Vector2(x1, p.y * t)
				_pts[2] = Vector2(x1, (p.y + 1) * t)
				_pts[3] = Vector2(x0, (p.y + 1) * t)
				var a := Color(top.r, top.g, top.b, 0.85)
				var b := Color(top.r, top.g, top.b, 0.0)
				_cols[0] = a
				_cols[1] = b
				_cols[2] = b
				_cols[3] = a
				cv.draw_polygon(_pts, _cols)


static func _ground(map: FloorMap, q: Vector2i) -> bool:
	return map.in_bounds(q) and not map.def_at(q).is_void
