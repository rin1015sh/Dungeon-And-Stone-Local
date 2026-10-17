class_name DecorChunk
extends Node2D
## 청크 하나의 데칼(FloorDecor — 물가·자갈·이끼·구역 흔적)과 소품(타일 art.prop — 동굴 요소·포탈 그림)을 바닥 위, 벽·캐릭터 아래에 그린다.
## 빛은 바닥과 같은 꼭짓점 배율(FloorView.vertex_mul), 재질 셰이더(floor_tex)로 기억 칸은 탈색. 탐험한 칸만.
## 데칼 배치는 청크마다 한 번 계산(compute_decals — 화면 밖 청크는 FloorView가 몇 프레임에 나눠 부른다), 시야가 바뀌면 다시 그리기만 한다.

const QUARTER := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]

var view: FloorView
var cells: Rect2i
var _decals: Array[Dictionary] = []
var _prop_cells: Array[Vector2i] = []  # 소품이 있을 수 있는 칸(동굴 요소 자리·포탈·지금 소품 타일) — 칸 전체를 훑지 않게
var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
var _uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])


func setup(p_view: FloorView, p_cells: Rect2i) -> void:
	view = p_view
	cells = p_cells
	var seen := {}
	for f in view.map.features:
		if cells.has_point(f["pos"]):
			seen[f["pos"]] = true
	for pt in view.map.portals:
		if cells.has_point(pt["pos"]):
			seen[pt["pos"]] = true
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			if view.prop_by_def[view.map.tiles[y * view.map.width + x]] != null:
				seen[Vector2i(x, y)] = true
	for k: Vector2i in seen:
		_prop_cells.append(k)
	_prop_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))


## 데칼 자리를 계산한다(FloorDecor.cells — 청크 하나에 수 ms라 화면 밖 청크는 미뤄 부른다).
func compute_decals() -> void:
	_decals = view.decor.cells(cells) if view.decor != null and view.decor_tex != null else ([] as Array[Dictionary])
	queue_redraw()


func _draw() -> void:
	var map := view.map
	var t := float(view.tile)
	var tex := view.decor_tex
	if tex != null:
		var n := view.decor.variants
		var rows := view.decor.kinds.size()
		for e in _decals:
			var p: Vector2i = e["pos"]
			if map.explored[p.y * map.width + p.x] == 0:
				continue
			var mean := map.defs[map.tiles[p.y * map.width + p.x]].color_floor
			var size := float(e["size"]) * t
			var c := (Vector2(p) + Vector2(0.5, 0.5) + (e["off"] as Vector2)) * t
			_quad(c, size, size)
			FloorChunk.set_uv_turned(_uvs, tex, int(e["v"]), n, int(e["kind"]), rows, int(e["rot"]), bool(e["flip"]))
			_corner_light(p, mean, 1.0)
			draw_polygon(_pts, _cols, _uvs, tex)
	for q in _prop_cells:
		var x := q.x
		var y := q.y
		var i := y * map.width + x
		if map.explored[i] == 0:
			continue
		var def := map.defs[map.tiles[i]]
		var ptex := view.prop_by_def[def.index]
		if ptex == null:
			continue
		var cols := maxi(1, ptex.get_width() / ptex.get_height()) if def.prop_cols <= 0 else def.prop_cols
		var rows := maxi(1, ptex.get_height() / maxi(1, ptex.get_width() / cols))
		var size := def.prop_size * t
		_quad(Vector2((x + 0.5) * t, (y + 1.0) * t - size * 0.5 - t * 0.12), size, size)
		FloorChunk.set_uv_turned(_uvs, ptex, def.prop_cell % cols, cols, def.prop_cell / cols, rows, 0, false)
		_corner_light(Vector2i(x, y), def.color_floor, view.prop_highlight)
		draw_polygon(_pts, _cols, _uvs, ptex)


func _quad(c: Vector2, w: float, h: float) -> void:
	_pts[0] = c + Vector2(-w, -h) * 0.5
	_pts[1] = c + Vector2(w, -h) * 0.5
	_pts[2] = c + Vector2(w, h) * 0.5
	_pts[3] = c + Vector2(-w, h) * 0.5


## 칸 p 네 모서리의 빛 배율(그림 사각형 네 모서리에 그대로). k = 소품 강조(상호작용 대상은 한 단계 밝게).
func _corner_light(p: Vector2i, mean: Color, k: float) -> void:
	for j in 4:
		var q: Vector2i = p + QUARTER[j]
		var c := view.vertex_mul(q.x, q.y, mean)
		_cols[j] = Color(c.r * k, c.g * k, c.b * k, c.a)
