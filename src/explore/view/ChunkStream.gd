class_name ChunkStream
extends RefCounted
## 플레이어 둘레 stream_chunks 청크만 노드로 둔다(큰 지도에서 노드 수·정렬 비용을 일정하게 — FloorView가 쓴다).
## 청크 하나 = FloorChunk(바닥) + DecorChunk(데칼·소품) + GlowChunk(맥동 빛) + WallRow(벽 줄, y 정렬이라 FloorView 바로 아래).
## 화면 밖으로 새로 들어온 청크의 거시 색조·데칼 자리·벽 모양은 한 프레임에 하나씩 미뤄 계산한다(process_one).

var view: FloorView
var radius: int = 3
var active: Rect2i = Rect2i()       ## 지금 노드가 있는 청크 사각형(청크 좌표)
var floor_chunks: Dictionary = {}   ## Vector2i(청크) -> FloorChunk
var wall_rows: Dictionary = {}      ## Vector2i(청크 x, 줄) -> WallRow
var glow_chunks: Dictionary = {}    ## Vector2i(청크) -> GlowChunk
var decor_chunks: Dictionary = {}   ## Vector2i(청크) -> DecorChunk
var _slow: Array[Vector2i] = []


func _init(p_view: FloorView, p_radius: int) -> void:
	view = p_view
	radius = p_radius


## 플레이어 칸 p 둘레로 맞춘다: 사각형을 벗어난 청크·벽 줄은 지우고, 새로 들어온 것은 만든다.
func around(p: Vector2i) -> void:
	var map := view.map
	var chunk := view.chunk
	var grid := Rect2i(0, 0, ceili(map.width / float(chunk)), ceili(map.height / float(chunk)))
	var c := Vector2i(p.x / chunk, p.y / chunk)
	var want := Rect2i(c - Vector2i(radius, radius), Vector2i(radius * 2 + 1, radius * 2 + 1)).intersection(grid)
	if want == active:
		return
	for key: Vector2i in floor_chunks.keys():
		if not want.has_point(key):
			for d: Dictionary in [floor_chunks, glow_chunks, decor_chunks]:
				if d.has(key):
					(d[key] as Node).queue_free()
					d.erase(key)
	for key: Vector2i in wall_rows.keys():
		if not want.has_point(Vector2i(key.x, key.y / chunk)):
			(wall_rows[key] as Node).queue_free()
			wall_rows.erase(key)
	for cy in range(want.position.y, want.end.y):
		for cx in range(want.position.x, want.end.x):
			if not active.has_point(Vector2i(cx, cy)):
				_build(Vector2i(cx, cy), c)
	active = want


## 미뤄 둔 청크 하나를 마무리한다(FloorView._process가 프레임마다).
func process_one() -> void:
	while not _slow.is_empty():
		var key: Vector2i = _slow.pop_front()
		if floor_chunks.has(key):  # 그새 스트리밍 범위를 벗어났으면 건너뛴다
			_finish(key, true)
			return


## 지금 노드가 있는 칸 사각형.
func active_cells() -> Rect2i:
	return Rect2i(active.position * view.chunk, active.size * view.chunk)


func redraw_all() -> void:
	for d: Dictionary in [floor_chunks, wall_rows, glow_chunks, decor_chunks]:
		for n: CanvasItem in d.values():
			n.queue_redraw()


## dirty(칸 사각형)에 걸친 청크·벽 줄만 다시 그린다(사전에서 바로 찾는다).
func redraw_rect(dirty: Rect2i) -> void:
	var map := view.map
	var chunk := view.chunk
	var r := dirty.intersection(Rect2i(0, 0, map.width, map.height))
	if not r.has_area():
		return
	var cx0 := r.position.x / chunk
	var cx1 := (r.end.x - 1) / chunk
	for cy in range(r.position.y / chunk, (r.end.y - 1) / chunk + 1):
		for cx in range(cx0, cx1 + 1):
			for d: Dictionary in [floor_chunks, decor_chunks, glow_chunks]:
				var n: CanvasItem = d.get(Vector2i(cx, cy))
				if n != null:
					n.queue_redraw()
	for row in range(r.position.y, r.end.y):
		for cx in range(cx0, cx1 + 1):
			var wr: WallRow = wall_rows.get(Vector2i(cx, row))
			if wr != null:
				wr.queue_redraw()


func recompute_decals() -> void:
	for dc: DecorChunk in decor_chunks.values():
		dc.compute_decals()


func _build(key: Vector2i, player_chunk: Vector2i) -> void:
	var map := view.map
	var chunk := view.chunk
	var cells := Rect2i(key * chunk, Vector2i(chunk, chunk)).intersection(Rect2i(0, 0, map.width, map.height))
	var fc := FloorChunk.new()
	fc.setup(view, cells)
	fc.material = view.tex_material
	view.floor_layer.add_child(fc)
	floor_chunks[key] = fc
	view.update_fog(cells)
	if view.decor_tex != null or not view.prop_tex.is_empty():
		var dc := DecorChunk.new()
		dc.setup(view, cells)
		dc.material = view.tex_material
		view.decor_layer.add_child(dc)
		decor_chunks[key] = dc
	var near := absi(key.x - player_chunk.x) <= 1 and absi(key.y - player_chunk.y) <= 1  # 화면에 보이는 청크는 바로
	if near:
		_finish(key, false)
	else:
		_slow.append(key)
	if view.glow_layer != null:
		var gc := GlowChunk.new()
		gc.setup(view, cells)
		view.glow_layer.add_child(gc)
		glow_chunks[key] = gc
	for row in range(cells.position.y, cells.end.y):
		if _row_has_wall(row, cells.position.x, cells.end.x):
			var wr := WallRow.new()
			wr.setup(view, row, cells.position.x, cells.end.x)
			wr.material = view.tex_material
			view.add_child(wr)
			wall_rows[Vector2i(key.x, row)] = wr
			if near:
				wr.build_shape()


## 청크의 거시 색조·데칼 자리를 계산한다. redraw면 그 청크 그림을 다시 그린다(미뤄 계산한 경우).
func _finish(key: Vector2i, redraw: bool) -> void:
	var cells := Rect2i(key * view.chunk, Vector2i(view.chunk, view.chunk)).intersection(Rect2i(0, 0, view.map.width, view.map.height))
	view.tint.fill(cells)
	var dc: DecorChunk = decor_chunks.get(key)
	if dc != null:
		dc.compute_decals()
	if redraw:  # 미뤄 둔 청크: 벽 모양도 지금 계산한다
		for row in range(cells.position.y, cells.end.y):
			var wr: WallRow = wall_rows.get(Vector2i(key.x, row))
			if wr != null:
				wr.build_shape()
		redraw_rect(cells)


func _row_has_wall(row: int, x0: int, x1: int) -> bool:
	for x in range(x0, x1):
		if view.map.def_at(Vector2i(x, row)).is_wall():
			return true
	return false
