class_name WallDoors
extends RefCounted
## 문(아치): 방 북쪽 벽에 뚫린 좁은 통로(1~max_cells칸)의 들머리에 벽 앞면이 아치로 이어지고, 그 위는 검은 벽 머리(사용자 레퍼런스 2026-11-01, AM62).
## 방과 방 사이를 넘어갈 때 "문을 지난다"가 보이게 한다 — 1층 수정동굴은 바위 아치, 균열 성채·묘는 돌 아치(벽 앞면 그림을 이어 쓴다).
## 문 칸 = 걸을 수 있는 칸들의 가로 줄(row r)로:
##   양옆이 다듬는 벽(art.shape — WallShape) · 적어도 한쪽은 남쪽이 열려 있다(방의 북쪽 벽 앞면 줄) · 문 칸 남쪽은 모두 열린 칸(방)
##   · 북쪽으로 depth칸 통로가 이어진다(줄마다 양옆이 벽이고 열린 칸이 있다 — 울퉁불퉁한 동굴 벽의 굴곡은 문이 아니다) · 포탈·동굴 요소 칸이 아니다.
## 그림(WallRow의 줄 조각 — 줄 아래 가장자리로 캐릭터와 y 정렬, 문을 지나는 캐릭터는 아치·벽 머리에 가려진다):
##   검은 벽 머리(문 칸 윗면 자리) → 아치(문설주 높이 spring부터 가운데 lintel까지, 벽 앞면 그림) → 아치 밑 그늘(통로 안 어둠) → 아치 먹선.
## 수치 = render.json view.door(FloorTextures가 읽어 둔다).

static var max_cells: int = 4
static var depth: int = 2          ## 문 북쪽으로 이어져야 하는 통로 길이(칸)
static var lintel: float = 0.3      ## 아치 가운데 두께(앞면 높이 비율)
static var spring: float = 0.7      ## 문설주 높이(앞면 위에서부터 앞면 높이 비율 — 아치가 시작되는 곳)
static var shade_tiles: float = 0.45  ## 아치 밑 그늘 길이(칸)
static var shade_alpha: float = 0.6
const STRIPS := 6  ## 칸마다 아치를 나누는 토막 수


## render.json view.door를 읽는다.
static func configure(cfg: Dictionary) -> void:
	max_cells = maxi(1, JsonUtil.get_int(cfg, "max_cells", 4))
	depth = maxi(1, JsonUtil.get_int(cfg, "depth", 2))
	lintel = JsonUtil.get_float(cfg, "lintel", 0.3)
	spring = JsonUtil.get_float(cfg, "spring", 0.7)
	shade_tiles = JsonUtil.get_float(cfg, "shade_tiles", 0.45)
	shade_alpha = JsonUtil.get_float(cfg, "shade_alpha", 0.6)


## 칸 p가 문 칸인가.
static func is_door(map: FloorMap, p: Vector2i, smooth: PackedByteArray) -> bool:
	return run_at(map, p, smooth).x >= 0


## 칸 p가 든 문의 가로 칸 범위 (서쪽 x, 동쪽 x — 끝 포함), 문이 아니면 (-1, -1).
static func run_at(map: FloorMap, p: Vector2i, smooth: PackedByteArray) -> Vector2i:
	var none := Vector2i(-1, -1)
	if not WallShape._open(map, p):
		return none
	var r := p.y
	var a := p.x
	while WallShape._open(map, Vector2i(a - 1, r)):
		a -= 1
		if p.x - a >= max_cells:
			return none
	var b := p.x
	while WallShape._open(map, Vector2i(b + 1, r)):
		b += 1
		if b - a + 1 > max_cells:
			return none
	var face := false
	for side: int in [a - 1, b + 1]:  # 문설주: 다듬는 벽 · 적어도 한쪽은 방의 북쪽 벽 앞면 줄(남쪽이 열림)
		if not WallShape._smooth_wall(map, Vector2i(side, r), smooth):
			return none
		face = face or WallShape._open(map, Vector2i(side, r + 1))
	if not face:
		return none
	for k in range(1, depth + 1):  # 북쪽으로 통로가 depth칸 이어진다(양옆이 벽 — 동굴 벽의 작은 굴곡은 문이 아니다)
		if not WallShape._wall(map, Vector2i(a - 1, r - k)) or not WallShape._wall(map, Vector2i(b + 1, r - k)):
			return none
		var open := false
		for x in range(a, b + 1):
			open = open or WallShape._open(map, Vector2i(x, r - k))
		if not open:
			return none
	for x in range(a, b + 1):
		var c := Vector2i(x, r)
		if not WallShape._open(map, c + Vector2i(0, 1)) or not map.portal_at(c).is_empty():
			return none
	for f in map.features:
		var fp: Vector2i = f["pos"]
		if fp.y == r and fp.x >= a and fp.x <= b:
			return none
	return Vector2i(a, b)


## 줄 row의 [x0, x1) 안에 서쪽 문설주가 있는 문들: [{x0, x1(끝 포함), flank(서쪽 문설주 타일 번호)}].
static func find(map: FloorMap, row: int, x0: int, x1: int, smooth: PackedByteArray) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for x in range(x0, x1):
		var p := Vector2i(x, row)
		if not WallShape._smooth_wall(map, p, smooth) or not WallShape._open(map, p + Vector2i(1, 0)):
			continue
		var run := run_at(map, p + Vector2i(1, 0), smooth)
		if run.x == x + 1:
			out.append({"x0": run.x, "x1": run.y, "flank": map.def_at(p).index})
	return out


## 문 하나를 cv(WallRow — 위치 = 줄 아래 가장자리)에 그린다.
static func draw(view: FloorView, cv: CanvasItem, row: int, door: Dictionary) -> void:
	var map := view.map
	var xa_cell := int(door["x0"])
	var xb_cell := int(door["x1"])
	if map.explored[row * map.width + xa_cell] == 0:
		return
	var def := map.defs[int(door["flank"])]
	var tex := view.tile_tex[def.index]
	var t := float(view.tile)
	var h := float(view.wall_face_of(def))
	var xa := xa_cell * t
	var xb := (xb_cell + 1) * t
	var top := -h  # 줄 아래 가장자리(바닥 선) 기준
	var spring_y := top + h * spring
	var crown := top + h * lintel
	var arch := func(x: float) -> float:
		var u := clampf((x - xa) / (xb - xa) * 2.0 - 1.0, -1.0, 1.0)
		return spring_y - (spring_y - crown) * sqrt(1.0 - u * u)
	var batch := QuadBatch.new()
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
	var uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var shade := shade_tiles * t
	var n := maxi(1, def.art_variants)
	var split := clampf((float(tex.get_width()) / n) / tex.get_height(), 0.0, 1.0) if tex != null else 0.0
	var span := h + float(view.wall_skirt)
	var ink := PackedVector2Array()
	for cell in range(xa_cell, xb_cell + 1):
		var col := float(FloorArtLayer.variant(cell, row, n, def.art_salt + 1))
		for k in STRIPS:
			var x0 := (cell + float(k) / STRIPS) * t
			var x1 := (cell + float(k + 1) / STRIPS) * t
			var y0: float = arch.call(x0)
			var y1: float = arch.call(x1)
			var l0 := _light(view, def, x0, row)
			var l1 := _light(view, def, x1, row)
			# 아치 밑 그늘(통로 안 어둠 — 아래로 투명)
			pts[0] = Vector2(x0, y0)
			pts[1] = Vector2(x1, y1)
			pts[2] = Vector2(x1, minf(y1 + shade, 0.0))
			pts[3] = Vector2(x0, minf(y0 + shade, 0.0))
			cols[0] = Color(0, 0, 0, shade_alpha)
			cols[1] = cols[0]
			cols[2] = Color(0, 0, 0, 0)
			cols[3] = cols[2]
			batch.add(pts, cols)
			# 아치(벽 앞면 그림을 이어서)
			pts[0] = Vector2(x0, top)
			pts[1] = Vector2(x1, top)
			pts[2] = Vector2(x1, y1)
			pts[3] = Vector2(x0, y0)
			cols[0] = l0
			cols[1] = l1
			cols[2] = l1
			cols[3] = l0
			if tex != null:
				var hx := 0.5 / tex.get_width()
				var u0 := clampf((col + float(k) / STRIPS) / n, col / n + hx, (col + 1.0) / n - hx)
				var u1 := clampf((col + float(k + 1) / STRIPS) / n, col / n + hx, (col + 1.0) / n - hx)
				uvs[0] = Vector2(u0, split)
				uvs[1] = Vector2(u1, split)
				uvs[2] = Vector2(u1, split + (y1 - top) / span * (1.0 - split))
				uvs[3] = Vector2(u0, split + (y0 - top) / span * (1.0 - split))
				batch.add(pts, cols, uvs, tex)
			else:
				batch.add(pts, cols)
			if ink.is_empty():
				ink.append(Vector2(x0, y0))
			ink.append(Vector2(x1, y1))
	batch.flush(cv)
	var dark := view.art.unexplored
	cv.draw_rect(Rect2(xa, top - t, xb - xa, t), dark)  # 문 위 벽 머리(문 칸 윗면 자리) — 검게
	var l := _light(view, def, (xa + xb) * 0.5, row)
	cv.draw_polyline(ink, Color(l.r * 0.25, l.g * 0.25, l.b * 0.25, l.a), 1.2)


## 바닥 선 위 x(월드 px)에 가장 가까운 꼭짓점의 빛 × 면 그늘(WallRow 앞면과 같은 빛).
static func _light(view: FloorView, def: TileDef, x: float, row: int) -> Color:
	var vx := clampi(roundi(x / view.tile), 0, view.map.width)
	var c := view.vertex_mul(vx, row + 1, def.color_face)
	var k := view.face_shade
	return Color(c.r * k, c.g * k, c.b * k, c.a)
