class_name WallRow
extends Node2D
## 벽 한 줄(청크 폭) 그리기. 노드 위치 = 그 줄의 바닥 아래 가장자리((row+1) × tile) → y 정렬 기준.
## 벽 칸 하나 = 윗면(바닥 칸 자리에서 앞면 높이만큼 위로 올림) + 앞면(남쪽을 향한 면).
## 남쪽에 다른 벽이 있으면 그 벽의 윗면이 이 앞면을 덮는다(나중에 그려지므로 자연스럽게 가려짐).
## 부드러운 암벽(타일 art.shape "smooth"·"round"·"bevel")은 WallShape로: 다듬은 윤곽, 윗면은 검게, 남쪽을 향한 윤곽만 앞면.
## 그 벽에 뚫린 좁은 북쪽 통로에는 문(아치 — WallDoors).

var view: FloorView
var row: int = 0
var x0: int = 0
var x1: int = 0

var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
var _uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _shape: WallShape = null  # 부드러운 암벽 모양(setup에서 한 번 — 벽 칸은 바뀌지 않는다)
var _pieces: Array[Node2D] = []  # 깎은 모서리·오목 메움 조각(WallShape.PIECE_*) — 자기 y로 캐릭터와 앞뒤를 가린다
var _batch := QuadBatch.new()   # 앞면 — 칸마다 draw_polygon을 부르지 않게
var _doors: Array[Dictionary] = []  # 이 줄의 문(WallDoors.find — 서쪽 문설주가 이 청크에 있는 것)


func setup(p_view: FloorView, p_row: int, p_x0: int, p_x1: int) -> void:
	view = p_view
	row = p_row
	x0 = p_x0
	x1 = p_x1
	position = Vector2(0, (row + 1) * view.tile)
	y_sort_enabled = true  # 조각 노드(자식)가 부모의 형제(캐릭터)와 함께 y로 정렬되게


## 부드러운 암벽 모양을 계산한다(줄당 0.1~0.2ms — 화면 밖 청크는 ChunkStream이 미뤄 부른다).
func build_shape() -> void:
	if view.smooth_any:
		_doors = WallDoors.find(view.map, row, x0, x1, view.smooth_by_def)
		_shape = WallShape.build(view.map, row, x0, x1, view.tile, view.tile * view.wall_round, view.smooth_by_def,
			view.wall_face_of, func(x: int, y: int, def: TileDef) -> int: return FloorArtLayer.variant(x, y, def.art_variants, def.art_salt + 1),
			view.tile * view.wall_bulge)
		for piece: int in [WallShape.PIECE_CUT, WallShape.PIECE_FILLET]:
			if not _shape.has_piece(piece):
				continue
			var n := Node2D.new()
			n.position = Vector2(0, WallShape.piece_sort(piece, view.tile, view.tile * view.wall_round) - view.tile)
			n.material = material
			n.use_parent_material = true
			n.draw.connect(_draw_piece.bind(n, piece))
			add_child(n)
			_pieces.append(n)
		queue_redraw()


func _draw_piece(n: Node2D, piece: int) -> void:
	if _shape != null:
		_draw_shape(n, view.tile, piece, n.position)


func _draw() -> void:
	var map := view.map
	var t := view.tile
	if _shape != null:
		_draw_shape(self, t, WallShape.PIECE_ROW, Vector2.ZERO)
		for n in _pieces:
			n.queue_redraw()
	for d in _doors:
		WallDoors.draw(view, self, row, d)
	for x in range(x0, x1):
		var i := row * map.width + x
		if map.explored[i] == 0:
			continue
		var def := map.defs[map.tiles[i]]
		if not def.is_wall() or view.smooth_by_def[def.index] != 0:
			continue
		var stand := view.stand_by_def[def.index]
		if stand != null:
			_draw_stand(x, t, def, stand)
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


## 부드러운 암벽: 윗면(검게 — 바위 속은 보이지 않는다) → 남쪽을 향한 윤곽의 앞면 띠(아틀라스 아랫줄, 밑동까지).
func _draw_shape(cv: CanvasItem, t: int, piece: int, at: Vector2) -> void:
	var map := view.map
	var lift := Vector2(0, (row + 1) * t) + at  # at = 그리는 노드의 위치(조각은 자기 y에 놓인다)
	var dark := view.art.unexplored
	var ftex := view.tile_tex[view.base_floor] if view.base_floor >= 0 else null
	for fl in _shape.floors:  # 깎은 모서리 아래 바닥(옆 바닥 칸 그림을 이어서 — 없으면 층 기본 바닥)
		if int(fl.get("piece", 0)) != piece or map.explored[row * map.width + int(fl["x"])] == 0:
			continue
		var fi := int(fl.get("def", -1))
		var tex := view.tile_tex[fi] if fi >= 0 else ftex
		if tex == null:
			continue
		var fdef := map.defs[fi if fi >= 0 else view.base_floor]
		var n := fdef.art_variants
		var poly: PackedVector2Array = fl["poly"]
		var x := int(fl["x"])
		var col := float(FloorArtLayer.variant(x, row, n, fdef.art_salt))
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		var cols := PackedColorArray()
		for q in poly:
			pts.append(q - lift)
			uvs.append(Vector2((col + clampf(q.x / t - x, 0.0, 1.0)) / n, clampf(q.y / t - row, 0.0, 1.0)))
			var v := Vector2i(clampi(roundi(q.x / t), 0, map.width), clampi(roundi(q.y / t), 0, map.height))
			cols.append(view.vertex_mul(v.x, v.y, fdef.color_floor))
		cv.draw_polygon(pts, cols, uvs, tex)
	for top in _shape.tops:
		if int(top.get("piece", 0)) != piece or map.explored[row * map.width + int(top["x"])] == 0:
			continue
		var poly: PackedVector2Array = (top["poly"] as PackedVector2Array).duplicate()
		var up := Vector2(0, float(top["h"])) + lift
		for k in poly.size():
			poly[k] -= up
		cv.draw_colored_polygon(poly, dark)
	for f in _shape.faces:
		if int(f.get("piece", 0)) != piece or map.explored[row * map.width + int(f["x"])] == 0:
			continue
		var def := map.defs[int(f["def"])]
		var tex := view.tile_tex[def.index]
		if tex == null:
			continue
		var a: Vector2 = f["a"]
		var b: Vector2 = f["b"]
		var h := float(f["h"])
		var sk := float(view.wall_skirt)
		_pts[0] = a - lift - Vector2(0, h)
		_pts[1] = b - lift - Vector2(0, h)
		_pts[2] = b - lift + Vector2(0, sk)
		_pts[3] = a - lift + Vector2(0, sk)
		var n := def.art_variants
		var split := clampf((float(tex.get_width()) / n) / tex.get_height(), 0.0, 1.0)
		var hx := 0.5 / tex.get_width()
		var col := float(int(f["v"]))
		var ua := (col + float(f["u0"])) / n
		var ub := (col + float(f["u1"])) / n
		ua = clampf(ua, col / n + hx, (col + 1.0) / n - hx)
		ub = clampf(ub, col / n + hx, (col + 1.0) / n - hx)
		var hy := 0.5 / tex.get_height()
		_uvs[0] = Vector2(ua, split + hy)
		_uvs[1] = Vector2(ub, split + hy)
		_uvs[2] = Vector2(ub, 1.0 - hy)
		_uvs[3] = Vector2(ua, 1.0 - hy)
		var la := _face_light(a, def)
		var lb := _face_light(b, def)
		_cols[0] = la
		_cols[1] = lb
		_cols[2] = lb
		_cols[3] = la
		_batch.add(_pts, _cols, _uvs, tex)
	_batch.flush(cv)  # 앞면은 윗면(위에서 먼저 flush)보다 나중에


## 바닥 평면 점 p(월드 px)에 가장 가까운 꼭짓점의 빛 × 면 그늘.
func _face_light(p: Vector2, def: TileDef) -> Color:
	var t := float(view.tile)
	var v := Vector2i(clampi(roundi(p.x / t), 0, view.map.width), clampi(roundi(p.y / t), 0, view.map.height))
	var c := view.vertex_mul(v.x, v.y, def.color_face)
	var k := view.face_shade
	return Color(c.r * k, c.g * k, c.b * k, c.a)


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
	if h <= 0 or split >= 1.0:
		_line_block(x, t, h)
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
	_line_block(x, t, h)


## 대현자 기념비처럼 살필 수 있는 벽 덩어리 = 윗면·앞면 둘레 검은 선(CT77).
func _line_block(x: int, t: int, h: int) -> void:
	if view.interactive_at(Vector2i(x, row)):
		draw_rect(Rect2(x * t, -t - h, t, t + maxi(h, 0)), Color.BLACK, false, view.outline_px * 1.5)


## 서 있는 소품(art.stand): 시트 칸 그림을 칸 아래쪽 가운데에 세운다(크기 = stand_size칸, 같은 줄 캐릭터와 y 정렬).
## 빛은 칸 아래 두 꼭짓점 배율의 평균(그림 전체에 같은 빛 — 작은 물건이라 꼭짓점마다 다르게 할 필요가 없다).
func _draw_stand(x: int, t: int, def: TileDef, tex: Texture2D) -> void:
	var cols := def.stand_cols
	var rows := def.stand_rows
	var w := def.stand_size.x * t
	var h := def.stand_size.y * t
	_quad(x * t + t * 0.5 - w * 0.5, -h, w, h)
	FloorChunk.set_uv_turned(_uvs, tex, def.stand_cell % cols, cols, def.stand_cell / cols, rows, 0, false)
	var c := view.vertex_mul(x, row + 1, def.color_face).lerp(view.vertex_mul(x + 1, row + 1, def.color_face), 0.5)
	c = c.lerp(view.vertex_mul(x, row, def.color_face).lerp(view.vertex_mul(x + 1, row, def.color_face), 0.5), 0.5)
	for k in 4:
		_cols[k] = c
	if view.interactive_at(Vector2i(x, row)):  # 뒤질 균열 장식 등 = 검은 테두리(CT77)
		Outline.polygon(self, _pts, _uvs, tex, view.outline_px)
	draw_polygon(_pts, _cols, _uvs, tex)


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
