class_name FloorChunk
extends Node2D
## 바닥 칸 묶음(청크) 그리기. 벽 칸은 WallRow가 그린다.
## 재질 아틀라스가 있는 타일(tiles.json art)은 그림 한 칸(FloorArtLayer 변형) × 꼭짓점 빛 배율(FloorView.vertex_mul)로,
## 없는 타일은 색칠한 칸(타일 색 × 꼭짓점 색)으로 그린다.
## 포탈처럼 표식 색(color_mark)이 있는 타일은 가운데에 마름모를 얹는다.
## 서 있는 소품(art.stand) 칸엔 밑 바닥(stand.under — 없으면 층 기본 바닥)을, 낭떠러지(void) 칸은 뒷배경이 있으면 비워 둔다.
## 칸 모양·UV는 그리는 칸(탐험·타일)이 바뀔 때만 다시 만들고(ChunkMesh), 시야만 바뀌면 꼭짓점 색만 다시 채운다.

var view: FloorView
var cells: Rect2i

var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _mesh := ChunkMesh.new()  # 칸들을 그림마다 한 번에(draw_polygon 칸마다 부르면 느리다) — 모양은 두고 색만 다시
var _shape := PackedInt32Array()  # 모양을 만들 때 칸마다(탐험했으면 타일 번호, 아니면 -1) — 달라지면 모양을 다시 만든다
var _marks: Array[Array] = []  # [x, y, 표식 색] — 표식 마름모는 바닥을 다 그린 뒤 위에
var _blends: Array[Array] = []  # [x, y, 모서리 방향, 칠할 타일] — 물 가장자리 사선(setup에서 한 번, 물·바닥 타일은 바뀌지 않는다)


func setup(p_view: FloorView, p_cells: Rect2i) -> void:
	view = p_view
	cells = p_cells
	if view.blend_any:
		_find_blends()


func _draw() -> void:
	var map := view.map
	var t := view.tile
	var now := _cell_state()
	if now != _shape:
		_shape = now
		_build()
	_mesh.draw(self, view)
	for m in _marks:
		_draw_mark(m[0], m[1], t, view.vertex_color(m[0], m[1], m[2]))
	var r := view.wall_round * t
	for b in _blends:
		if map.explored[int(b[1]) * map.width + int(b[0])] != 0:
			_corner_tri(int(b[0]), int(b[1]), t, r, b[2], b[3])


## 칸마다 탐험했으면 타일 번호, 아니면 -1(그리는 칸이 바뀌었는지 — 원정 중 새 시체 타일 등).
func _cell_state() -> PackedInt32Array:
	var map := view.map
	var out := PackedInt32Array()
	out.resize(cells.size.x * cells.size.y)
	var k := 0
	for y in range(cells.position.y, cells.end.y):
		var i := y * map.width + cells.position.x
		for x in cells.size.x:
			out[k] = map.tiles[i + x] if map.explored[i + x] != 0 else -1
			k += 1
	return out


## 칸 모양·UV·표식을 다시 만든다(그리는 칸이 바뀌었을 때만).
func _build() -> void:
	var map := view.map
	var t := view.tile
	_mesh.clear()
	_marks.clear()
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var i := y * map.width + x
			if map.explored[i] == 0:
				continue
			var def := map.defs[map.tiles[i]]
			if def.is_wall():
				if view.stand_by_def[def.index] == null:
					continue
				def = map.defs[view.under_by_def[def.index]]  # 서 있는 소품 밑 바닥(WallRow가 위에 그림을 세운다)
			elif def.is_void and view.void_layer != null:
				continue  # 낭떠러지: 아래 층(VoidChunk)의 뒷배경이 비친다
			_pts[0] = Vector2(x * t, y * t)
			_pts[1] = Vector2((x + 1) * t, y * t)
			_pts[2] = Vector2((x + 1) * t, (y + 1) * t)
			_pts[3] = Vector2(x * t, (y + 1) * t)
			var tex := view.tile_tex[def.index]
			if tex != null:
				var v := FloorArtLayer.variant(x, y, def.art_variants, def.art_salt)
				set_uv_cell(_uvs, tex, v, def.art_variants, 0.0, 1.0)
				if def.art_directional and _vertical(map, x, y, def):  # 세로 철로: 그림의 가로 방향을 화면 세로로
					var tr := _uvs[1]
					_uvs[1] = _uvs[3]
					_uvs[3] = tr
				_mesh.add_tex(_pts, _uvs, tex, x, y, def.color_floor, def.index)
			else:
				_mesh.add_plain(_pts, x, y, def.color_floor * view.cell_jitter(x, y))
			if def.color_mark.a > 0.0 and view.prop_by_def[def.index] == null and tex == null:  # 그림이 있으면 표식 마름모는 그리지 않는다
				_marks.append([x, y, def.color_mark])


## 칸 (x, y)의 같은 타일이 가로보다 세로로 더 길게 이어지는가(한 방향 무늬 — 철로).
static func _vertical(map: FloorMap, x: int, y: int, def: TileDef) -> bool:
	var h := 1
	var v := 1
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q := Vector2i(x, y) + d
		while map.in_bounds(q) and map.def_at(q) == def:
			if d.y == 0:
				h += 1
			else:
				v += 1
			q += d
	return v > h


## 가장자리를 다듬는 바닥(물 — art.shape "smooth")의 칸 모서리를 사선으로: 물 칸의 볼록 모서리(맞닿은 두 이웃이 다른 바닥)는
## 그 이웃 바닥 그림으로 깎고, 다른 바닥 칸의 오목 모서리(맞닿은 두 이웃과 대각선이 물)는 물 그림으로 메운다(벽과 같은 0.5칸 사선).
func _find_blends() -> void:
	var map := view.map
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var me := map.defs[map.tiles[y * map.width + x]]
			if me.is_wall() or view.tile_tex[me.index] == null:
				continue
			var mine := view.blend_by_def[me.index] != 0
			for c: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
				var a := Vector2i(x + c.x, y)
				var b := Vector2i(x, y + c.y)
				if not map.in_bounds(a) or not map.in_bounds(b) or not map.in_bounds(Vector2i(x + c.x, y + c.y)):
					continue
				var da := map.def_at(a)
				var db := map.def_at(b)
				var paint: TileDef = null
				if mine and da == db and da != me and not da.is_wall() and view.tile_tex[da.index] != null:
					paint = da  # 물의 볼록 모서리 → 옆 바닥으로 깎는다
				elif not mine and da == db and view.blend_by_def[da.index] != 0 and map.def_at(Vector2i(x + c.x, y + c.y)) == da:
					paint = da  # 바닥의 오목 모서리 → 물로 메운다
				if paint != null:
					_blends.append([x, y, c, paint])


func _corner_tri(x: int, y: int, t: int, r: float, c: Vector2i, def: TileDef) -> void:
	var o := Vector2(x * t, y * t)
	var corner := o + Vector2(t if c.x > 0 else 0, t if c.y > 0 else 0)
	var pts := PackedVector2Array([corner])
	WallShape._cut(pts, corner + Vector2(0, -c.y * r), corner + Vector2(-c.x * r, 0), corner, view.tile * view.wall_bulge)
	var tex := view.tile_tex[def.index]
	var n := def.art_variants
	var col := float(FloorArtLayer.variant(x, y, n, def.art_salt))
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var c00 := view.vertex_mul(x, y, def.color_floor)
	var c10 := view.vertex_mul(x + 1, y, def.color_floor)
	var c01 := view.vertex_mul(x, y + 1, def.color_floor)
	var c11 := view.vertex_mul(x + 1, y + 1, def.color_floor)
	for q in pts:
		var f := (q - o) / t
		uvs.append(Vector2((col + clampf(f.x, 0.0, 1.0)) / n, clampf(f.y, 0.0, 1.0)))
		cols.append(c00.lerp(c10, f.x).lerp(c01.lerp(c11, f.x), f.y))
	draw_polygon(pts, cols, uvs, tex)


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


## 시트 칸 (col, row)의 UV(반 텍셀 안쪽, 왼위·오위·오아래·왼아래)를 그림 위쪽이 rot(0 북·1 동·2 남·3 서)을 보게 돌리고
## flip이면 좌우를 뒤집어 uvs에 넣는다(데칼·소품·벽 턱).
static func set_uv_turned(uvs: PackedVector2Array, tex: Texture2D, col: int, cols: int, row: int, rows: int, rot: int, flip: bool) -> void:
	var hx := 0.5 / tex.get_width()
	var hy := 0.5 / tex.get_height()
	var u0 := float(col) / cols + hx
	var u1 := float(col + 1) / cols - hx
	var v0 := float(row) / rows + hy
	var v1 := float(row + 1) / rows - hy
	var base := [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]
	if flip:
		base = [base[1], base[0], base[3], base[2]]
	for j in 4:
		uvs[j] = base[posmod(j - rot, 4)]


func _draw_mark(x: int, y: int, t: int, color: Color) -> void:
	var c := Vector2((x + 0.5) * t, (y + 0.5) * t)
	var r := t * 0.32
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), color)
