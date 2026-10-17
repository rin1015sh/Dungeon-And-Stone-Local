class_name WallRow
extends Node2D
## 벽 한 줄(청크 폭) 그리기. 노드 위치 = 그 줄의 바닥 아래 가장자리((row+1) × tile) → y 정렬 기준.
## 벽 칸 하나 = 윗면(바닥 칸 자리에서 앞면 높이만큼 위로 올림) + 앞면(남쪽을 향한 면).
## 남쪽에 다른 벽이 있으면 그 벽의 윗면이 이 앞면을 덮는다(나중에 그려지므로 자연스럽게 가려짐).

var view: FloorView
var row: int = 0
var x0: int = 0
var x1: int = 0

var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
var _uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])


func setup(p_view: FloorView, p_row: int, p_x0: int, p_x1: int) -> void:
	view = p_view
	row = p_row
	x0 = p_x0
	x1 = p_x1
	position = Vector2(0, (row + 1) * view.tile)


func _draw() -> void:
	var map := view.map
	var t := view.tile
	for x in range(x0, x1):
		var i := row * map.width + x
		if map.explored[i] == 0:
			continue
		var def := map.defs[map.tiles[i]]
		if not def.is_wall():
			continue
		var h := view.wall_face_of(def)
		var tex := view.tile_tex[def.index]
		if tex != null:
			_draw_textured(x, t, h, def, tex)
			continue
		# 윗면 (로컬 y: -t-h ~ -h)
		_quad(x * t, -t - h, t, t)
		_cols[0] = view.vertex_color(x, row, def.color_top)
		_cols[1] = view.vertex_color(x + 1, row, def.color_top)
		_cols[2] = view.vertex_color(x + 1, row + 1, def.color_top)
		_cols[3] = view.vertex_color(x, row + 1, def.color_top)
		draw_polygon(_pts, _cols)
		_draw_rims(map, x, t, h, _cols[0].lerp(_cols[2], 0.5))
		# 앞면 (로컬 y: -h ~ 0), 남쪽 가장자리 빛에 면 그늘을 곱한다
		if h <= 0:
			continue
		_quad(x * t, -h, t, h)
		var left := view.vertex_color(x, row + 1, def.color_face) * view.face_shade
		var right := view.vertex_color(x + 1, row + 1, def.color_face) * view.face_shade
		left.a = 1.0
		right.a = 1.0
		_cols[0] = left
		_cols[1] = right
		_cols[2] = right
		_cols[3] = left
		draw_polygon(_pts, _cols)
		# 윗면과 앞면이 만나는 모서리 선 + 앞면 돌 줄눈(바닥과 구분되는 높이감)
		var edge := left.lerp(right, 0.5) * view.edge_shade
		edge.a = 1.0
		draw_line(Vector2(x * t, -h), Vector2((x + 1) * t, -h), edge, 1.0)
		_draw_courses(x, t, h, edge.lerp(left.lerp(right, 0.5), 0.5))


## 재질 아틀라스로 그린 벽: 윗면 = 아틀라스 윗줄의 변형, 앞면 = 아랫줄의 변형(FloorArtLayer — 줄을 따라 이웃이 늘 다름).
## 빛은 꼭짓점 배율(윗면 네 모서리, 앞면은 바닥 접점 두 모서리 × face_shade).
func _draw_textured(x: int, t: int, h: int, def: TileDef, tex: Texture2D) -> void:
	var n := def.art_variants
	var cell := float(tex.get_width()) / n
	var split := clampf(cell / tex.get_height(), 0.0, 1.0)
	_quad(x * t, -t - h, t, t)
	FloorChunk.set_uv_cell(_uvs, tex, FloorArtLayer.variant(x, row, n, def.art_salt), n, 0.0, split)
	_cols[0] = view.vertex_mul(x, row, def.color_top)
	_cols[1] = view.vertex_mul(x + 1, row, def.color_top)
	_cols[2] = view.vertex_mul(x + 1, row + 1, def.color_top)
	_cols[3] = view.vertex_mul(x, row + 1, def.color_top)
	draw_polygon(_pts, _cols, _uvs, tex)
	_draw_rim_edges(x, t, h, def)
	if h <= 0 or split >= 1.0:
		return
	_quad(x * t, -h, t, h + view.wall_skirt)  # 밑동만큼 바닥 쪽으로 내려온다(그림 아래 끝이 들쭉날쭉 — 투명)
	FloorChunk.set_uv_cell(_uvs, tex, FloorArtLayer.variant(x, row, n, def.art_salt + 1), n, split, 1.0)
	var left := view.vertex_mul(x, row + 1, def.color_face)
	var right := view.vertex_mul(x + 1, row + 1, def.color_face)
	left = Color(left.r * view.face_shade, left.g * view.face_shade, left.b * view.face_shade, left.a)
	right = Color(right.r * view.face_shade, right.g * view.face_shade, right.b * view.face_shade, right.a)
	_cols[0] = left
	_cols[1] = right
	_cols[2] = right
	_cols[3] = left
	draw_polygon(_pts, _cols, _uvs, tex)


## 바닥 쪽으로 열린 윗면 가장자리(북·서·동)에 턱 그림(art.rim)을 그림 위쪽이 바깥을 보게 덧그린다.
## 바깥으로 rim_out만큼 튀어나와 칸 직선 테두리를 울퉁불퉁하게 깬다. 그림은 중간 회색으로 칠해 윗면 색 × 2를 곱한다.
func _draw_rim_edges(x: int, t: int, h: int, def: TileDef) -> void:
	var rtex := view.rim_by_def[def.index]
	if rtex == null:
		return
	var map := view.map
	var y0 := float(-t - h)
	var o := view.rim_out * t
	var d := view.rim_in * t
	var tint := def.color_top * 2.0
	for side in [0, 3, 1]:  # 북 · 서 · 동
		var nb := Vector2i(x, row) + FloorDecor.DIRS[side]
		if map.is_wall(nb) or not map.in_bounds(nb):
			continue
		match side:
			0:
				_quad(x * t, y0 - o, t, o + d)
			3:
				_quad(x * t - o, y0, o + d, t)
			1:
				_quad((x + 1) * t - d, y0, o + d, t)
		var v := absi(hash(Vector3i(x, row, side))) % maxi(1, def.rim_variants)
		FloorChunk.set_uv_turned(_uvs, rtex, v, def.rim_variants, 0, 1, side, false)
		var a := view.vertex_mul(x, row, def.color_top)
		var b := view.vertex_mul(x + 1, row + 1, def.color_top)
		var c := a.lerp(b, 0.5)
		c = Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a)
		for j in 4:
			_cols[j] = c
		draw_polygon(_pts, _cols, _uvs, rtex)


## 앞면에 돌 쌓은 줄(가로 2줄)과 엇갈린 이음매(세로)를 그린다.
func _draw_courses(x: int, t: int, h: int, color: Color) -> void:
	if h < 9:
		return
	var y1 := -h + h / 3.0
	var y2 := -h + h * 2.0 / 3.0
	draw_line(Vector2(x * t, y1), Vector2((x + 1) * t, y1), color, 1.0)
	draw_line(Vector2(x * t, y2), Vector2((x + 1) * t, y2), color, 1.0)
	var shift := t * (0.25 if (x + row) % 2 == 0 else 0.75)
	draw_line(Vector2(x * t + shift, -h), Vector2(x * t + shift, y1), color, 1.0)
	draw_line(Vector2(x * t + t - shift, y1), Vector2(x * t + t - shift, y2), color, 1.0)
	draw_line(Vector2(x * t + shift, y2), Vector2(x * t + shift, 0), color, 1.0)


## 윗면 테두리: 벽이 아닌 칸과 맞닿은 북·서·동쪽 가장자리를 밝게 그어 덩어리 윤곽을 살린다.
func _draw_rims(map: FloorMap, x: int, t: int, h: int, top_color: Color) -> void:
	var rim := top_color * view.rim_shade
	rim.a = 1.0
	var y0 := -t - h
	if not map.is_wall(Vector2i(x, row - 1)):
		draw_line(Vector2(x * t, y0), Vector2((x + 1) * t, y0), rim, 1.0)
	if not map.is_wall(Vector2i(x - 1, row)):
		draw_line(Vector2(x * t, y0), Vector2(x * t, 0), rim, 1.0)
	if not map.is_wall(Vector2i(x + 1, row)):
		draw_line(Vector2((x + 1) * t, y0), Vector2((x + 1) * t, 0), rim, 1.0)


func _quad(x: float, y: float, w: float, h: float) -> void:
	_pts[0] = Vector2(x, y)
	_pts[1] = Vector2(x + w, y)
	_pts[2] = Vector2(x + w, y + h)
	_pts[3] = Vector2(x, y + h)
