class_name FloorFringe
extends RefCounted
## 바닥 재질 번짐(사용자 2026-11-11 "2층이 각지고 타일 같다", AM64): 재질이 다른 바닥 칸이 맞닿은 곳을 네모 경계 대신
## 순위(타일 art.fringe) 높은 재질이 낮은 칸 안으로 들쭉날쭉 스며든 띠로 덮는다.
## 띠 모양 = assets/floor/fringe_mask.webp(tools/f2_art/ground.py — 가로 변형 COLS칸 × 생김새마다 8줄: 북·동·남·서 변 띠,
## 북서·북동·남동·남서 모서리 부채꼴. R = 덮는 정도, G = 가장자리 그늘), 재질 그림은 셰이더가 세계 좌표로 이어 깐다(넓은 재질 art.span).
## 청크 모양을 만들 때만 계산한다(FloorChunk._build) — 다시 그릴 때는 꼭짓점 색만(ChunkMesh).

const SHADER := "res://assets/shaders/floor_fringe.gdshader"
const MASK := "res://assets/floor/fringe_mask.webp"
const COLS := 4
const ROWS := 8      ## 생김새 하나의 줄 수
const STYLES := 4    ## 생김새 수(TileDef.fringe_style)
const EDGE := 0.68   ## 변 띠가 칸 안으로 들어오는 가장 큰 깊이(칸 비율 — ground_extra.py EDGE): 그만큼만 그린다(겹쳐 그리는 넓이를 줄인다)
const CORNER := 0.5  ## 모서리 부채꼴의 가장 큰 폭
## 줄(북·동·남·서 변, 북서·북동·남동·남서 모서리)마다 칸 안에서 그리는 네모(칸 비율)
const RECTS: Array[Rect2] = [Rect2(0, 0, 1, EDGE), Rect2(1.0 - EDGE, 0, EDGE, 1), Rect2(0, 1.0 - EDGE, 1, EDGE), Rect2(0, 0, EDGE, 1),
	Rect2(0, 0, CORNER, CORNER), Rect2(1.0 - CORNER, 0, CORNER, CORNER), Rect2(1.0 - CORNER, 1.0 - CORNER, CORNER, CORNER), Rect2(0, 1.0 - CORNER, CORNER, CORNER)]
const SIDES: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const CORNERS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]


## 번짐 띠 층(FloorChunk의 자식 — 바닥 칸 위에 그린다). 재질 그림을 되풀이해 깔아야 해서 따로 둔다.
class Layer:
	extends Node2D
	var view: FloorView
	var mesh := ChunkMesh.new()

	func setup(p_view: FloorView) -> void:
		view = p_view
		material = view.fringe_material
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		if not mesh.is_empty():
			mesh.draw(self, view)


## 이 층이 번짐을 쓰면(번짐 순위가 있는 타일이 있고 띠 그림이 있으면) 번짐 셰이더, 아니면 null.
static func material(view: FloorView) -> ShaderMaterial:
	var span := 0
	for def in view.map.defs:
		if def.fringe > 0 and def.art_span > 0 and view.tile_tex[def.index] != null:
			span = def.art_span
	if span == 0 or not ResourceLoader.exists(MASK):
		return null
	var m := ShaderMaterial.new()
	m.shader = load(SHADER) as Shader
	m.set_shader_parameter("mask", load(MASK) as Texture2D)
	m.set_shader_parameter("span_px", float(span * view.tile))
	m.set_shader_parameter("memory_desat", view.memory_desat)
	return m


## 칸 p의 바닥 그림 타일. 서 있는 소품 칸 = 밑 바닥(stand.under), 그 밖은 자기 타일. 다만 둘레에서 빌리는 칸
## (art.ground "around" · 덧그림, 그리고 번짐을 쓰는 층에서는 소품 · 서 있는 소품 칸 모두)은 맞닿은 맨바닥 타일 —
## 같은 소품 타일이 여러 땅에 놓여도 네모나게 뜨지 않는다. 맞는 이웃이 없으면 원래 바닥(덧그림은 층 기본 바닥).
static func ground_def(view: FloorView, p: Vector2i) -> TileDef:
	var map := view.map
	var def := map.defs[map.tiles[p.y * map.width + p.x]]
	if def.is_wall():
		if view.stand_by_def[def.index] == null:
			return def
		var under := map.defs[view.under_by_def[def.index]]
		return under if under.is_wall() or view.fringe_material == null else _around(view, p, under)
	if def.art_overlay:
		return _around(view, p, map.defs[view.base_floor])
	if def.ground_around or (view.fringe_material != null and view.prop_by_def[def.index] != null):
		return _around(view, p, def)
	return def


## 칸 p에 맞닿은 맨바닥(그림 있는 바닥 — 소품 · 덧그림 칸 제외, 같은 높이) 타일. own과 같은 그림이 둘레에 있으면 own 그대로.
static func _around(view: FloorView, p: Vector2i, own: TileDef) -> TileDef:
	var map := view.map
	var pick: TileDef = null
	for d in SIDES:
		var q := p + d
		if not map.in_bounds(q):
			continue
		var o := map.defs[map.tiles[q.y * map.width + q.x]]
		if o.is_wall() or o.is_void or o.ground_around or o.sunk != own.sunk or view.tile_tex[o.index] == null or view.prop_by_def[o.index] != null:
			continue
		if o.art_atlas == own.art_atlas:
			return own
		if pick == null:
			pick = o
	return pick if pick != null else own


## 청크 칸들의 번짐 띠를 mesh에 넣는다(순위 낮은 것부터 — 높은 재질이 위에 덮인다).
static func build(view: FloorView, cells: Rect2i, mesh: ChunkMesh) -> void:
	var map := view.map
	var t := view.tile
	mesh.clear()
	var found: Array[Array] = []  # [순위, x, y, 줄, 타일]
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			if map.explored[y * map.width + x] == 0:
				continue
			var p := Vector2i(x, y)
			var me := ground_def(view, p)
			if me.fringe <= 0:
				continue
			var side: Array[TileDef] = [null, null, null, null]
			for k in 4:
				var o := _over(view, p + SIDES[k], me)
				side[k] = o
				if o != null:
					found.append([o.fringe, x, y, k, o])
			for k in 4:  # 모서리: 대각선 칸만 그 재질이고 맞닿은 두 변은 아닐 때(변 띠가 이미 덮으면 건너뛴다)
				var o := _over(view, p + CORNERS[k], me)
				if o == null:
					continue
				var a := side[(k + 3) % 4]  # 북서 = 서 · 북, 북동 = 북 · 동 …
				var b := side[k]
				if (a == null or a.art_atlas != o.art_atlas) and (b == null or b.art_atlas != o.art_atlas):
					found.append([o.fringe, x, y, 4 + k, o])
	if found.is_empty():
		return
	found.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	for f in found:
		var x := int(f[1])
		var y := int(f[2])
		var o: TileDef = f[4]
		var row := mini(o.fringe_style, STYLES - 1) * ROWS + int(f[3])
		var col := FloorArtLayer.variant(x, y + int(f[3]) * 7, COLS, o.art_salt)
		var r := RECTS[int(f[3])]
		pts[0] = Vector2(x + r.position.x, y + r.position.y) * t
		pts[1] = Vector2(x + r.end.x, y + r.position.y) * t
		pts[2] = Vector2(x + r.end.x, y + r.end.y) * t
		pts[3] = Vector2(x + r.position.x, y + r.end.y) * t
		var u0 := (col + r.position.x) / COLS
		var u1 := (col + r.end.x) / COLS
		var v0 := (row + r.position.y) / (ROWS * STYLES)
		var v1 := (row + r.end.y) / (ROWS * STYLES)
		uvs[0] = Vector2(u0, v0)
		uvs[1] = Vector2(u1, v0)
		uvs[2] = Vector2(u1, v1)
		uvs[3] = Vector2(u0, v1)
		mesh.add_tex(pts, uvs, view.tile_tex[o.index], x, y, o.color_floor, o.index)


## 칸 q의 재질이 me 칸으로 스며드는가 → 그 타일(아니면 null). 같은 높이(sunk)끼리, 순위가 더 높고 다른 재질일 때만.
static func _over(view: FloorView, q: Vector2i, me: TileDef) -> TileDef:
	if not view.map.in_bounds(q):
		return null
	var o := ground_def(view, q)
	if o.fringe <= me.fringe or o.art_span <= 0 or o.art_atlas == me.art_atlas or o.sunk != me.sunk:
		return null
	if o.is_wall() or o.is_void or view.tile_tex[o.index] == null:
		return null
	return o
