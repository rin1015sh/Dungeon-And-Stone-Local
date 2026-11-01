class_name VoidChunk
extends Node2D
## 청크 하나의 낭떠러지·구덩이(void 타일): 탐험한 허공 칸과 허공에 닿은 땅 칸에 절벽 셰이더(Abyss — abyss.gdshader)를 칠한다.
## 셰이더가 땅 가장자리를 들쭉날쭉 깎고 절벽 면·깊은 어둠을 세계 좌표로 그린다(화면 고정 그림 없음 — 칸 모양 경계가 보이지 않게).
## 허공 위 나무 발판(art.void_edge "beam")에는 들보 아래 받침 기둥(이 노드 — 셰이더 위)과 난간(북쪽 = 캐릭터 뒤, 남쪽 = 앞)을 얹는다.
## 낮은 물(타일 art.sunk — 핏물 해자) 위를 건너는 발판(도개교)도 같다: 셰이더가 없는 곳이라 남쪽 들보 면과 물 위 그림자를 직접 그린다.
## 바닥·데칼 위(void_layer z). 빛은 바닥과 같게 FloorView.vertex_mul.

const EDGE := 3  # 지도 끝에서 이 칸 수 안의 땅도 칠한다(abyss.gdshader edge_fade보다 크게)
const MARGIN := 16  # 지도 밖으로 이어 칠하는 칸 수(지도 끝의 허공 칸 너머 — 화면 반 폭보다 크게, 지도 끝 직선이 보이지 않게)

var view: FloorView
var cells: Rect2i
var _quads: Array[Vector2i] = []      # 셰이더로 칠할 칸(허공 + 허공에 닿은 땅)
var _outer: Array[Rect2i] = []        # 지도 밖 칸 묶음(가장 가까운 지도 끝 칸이 같은 칸끼리 — 띠·모서리 사각형 하나, 색이 한결같다)
var _outer_at: Array[Vector2i] = []   # 묶음마다 가장 가까운 지도 끝 칸(허공이나 길) — 셰이더가 그 칸 값을 이어 쓴다
var _beams_n: Array[Vector2i] = []    # 북쪽이 허공인 나무 발판 칸
var _beams_s: Array[Vector2i] = []    # 남쪽이 허공인 나무 발판 칸
var _decks: Array[Vector2i] = []      # 남쪽이 낮은 물인 나무 발판 칸(들보 면·그림자를 직접 — 허공은 셰이더가 그린다, MoatDeck)
var _decks_n: Array[Vector2i] = []    # 북쪽이 낮은 물인 나무 발판 칸(가장자리 먹선)
var _under: Node2D   # 받침 기둥(셰이더 위, 같은 z)
var _rail_back: Node2D   # 북쪽 난간(캐릭터 뒤)
var _rail_front: Node2D  # 남쪽 난간(캐릭터 앞)
var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
var _batch := QuadBatch.new()  # 칸들을 한 번에(draw_polygon 칸마다 부르면 느리다)
var _vmul := PackedColorArray()   # 그리는 동안 꼭짓점 빛 배율(청크 꼭짓점 격자 — 칸마다 네 번씩 다시 계산하지 않게)
var _vset := PackedByteArray()    # _vmul 칸을 이번에 계산했는가


func setup(p_view: FloorView, p_cells: Rect2i) -> void:
	view = p_view
	cells = p_cells
	var map := view.map
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var p := Vector2i(x, y)
			var d := map.def_at(p)
			if d.is_void:
				_quads.append(p)
			elif not d.is_wall() and (_near_void(map, p) or _near_border(map, p)):
				_quads.append(p)
				if d.void_edge == "beam":
					if _void_at(map, p + Vector2i(0, -1)):
						_beams_n.append(p)
					if _void_at(map, p + Vector2i(0, 1)):
						_beams_s.append(p)
			if d.void_edge == "beam" and not d.is_void:  # 낮은 물 위 다리(도개교)
				if _sunk_at(map, p + Vector2i(0, -1)):
					_beams_n.append(p)
					_decks_n.append(p)
				if _sunk_at(map, p + Vector2i(0, 1)):
					_beams_s.append(p)
					_decks.append(p)
	_find_outer(map)
	if not has_void():
		return
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_under = _layer(0, true, _draw_under)
	if not _beams_n.is_empty():
		_rail_back = _layer(JsonUtil.get_int(Abyss.rail(view.art), "z_back", -8), false, func() -> void: _draw_rails(_rail_back, _beams_n, 0.0))
	if not _beams_s.is_empty():
		_rail_front = _layer(JsonUtil.get_int(Abyss.rail(view.art), "z_front", 4), false, func() -> void: _draw_rails(_rail_front, _beams_s, 1.0))


func has_void() -> bool:
	return not _quads.is_empty() or not _outer.is_empty() or not _beams_n.is_empty() or not _beams_s.is_empty()


## 이 청크가 지도 끝에 닿아 있으면 그 바깥 MARGIN칸 중 가장 가까운 지도 칸이 벽이 아닌 칸.
func _find_outer(map: FloorMap) -> void:
	var ext := cells
	if cells.position.x == 0:
		ext = ext.grow_side(SIDE_LEFT, MARGIN)
	if cells.position.y == 0:
		ext = ext.grow_side(SIDE_TOP, MARGIN)
	if cells.end.x == map.width:
		ext = ext.grow_side(SIDE_RIGHT, MARGIN)
	if cells.end.y == map.height:
		ext = ext.grow_side(SIDE_BOTTOM, MARGIN)
	if ext == cells:
		return
	# 지도 밖 칸은 가장 가까운 지도 끝 칸(c)의 값을 그대로 쓰므로 c가 같은 칸끼리는 색이 같다 — 한 사각형으로 묶는다
	# (옆 = 한 줄 띠, 모서리 = 네모 하나). 지도가 작은 균열에서 끝 청크 하나가 칸 수백 개를 그려 걸음마다 끊겼다.
	var groups := {}  # c -> Rect2i
	for y in range(ext.position.y, ext.end.y):
		for x in range(ext.position.x, ext.end.x):
			var q := Vector2i(x, y)
			if map.in_bounds(q):
				continue
			var c := _clamp(map, q)
			if map.def_at(c).is_wall():  # 허공은 이어지고, 나가는 길은 어둠으로(벽 너머는 검은 바위 그대로)
				continue
			var cell := Rect2i(q, Vector2i.ONE)
			groups[c] = (groups[c] as Rect2i).merge(cell) if groups.has(c) else cell
	for c: Vector2i in groups:
		_outer_at.append(c)
		_outer.append(groups[c])


static func _clamp(map: FloorMap, q: Vector2i) -> Vector2i:
	return Vector2i(clampi(q.x, 0, map.width - 1), clampi(q.y, 0, map.height - 1))


func _layer(z: int, relative: bool, painter: Callable) -> Node2D:
	var n := Node2D.new()
	n.z_as_relative = relative
	n.z_index = z
	n.draw.connect(painter)
	add_child(n)
	return n


func _draw() -> void:
	var map := view.map
	var t := float(view.tile)
	var gw := cells.size.x + 1
	_vmul.resize(gw * (cells.size.y + 1))
	_vset.resize(_vmul.size())
	_vset.fill(0)
	for p in _quads:
		# 허공은 빛이 닿지 않아 탐험되지 않기도 한다(어두운 구덩이) — 이웃이 탐험됐으면 칠하고 꼭짓점 안개로 어둠에 녹인다
		if map.explored[p.y * map.width + p.x] == 0 and not (map.defs[map.tiles[p.y * map.width + p.x]].is_void and _near_explored(map, p)):
			continue
		_quad(p.x * t, p.y * t, t, t)
		_cols[0] = _mul(p.x, p.y, gw)
		_cols[1] = _mul(p.x + 1, p.y, gw)
		_cols[2] = _mul(p.x + 1, p.y + 1, gw)
		_cols[3] = _mul(p.x, p.y + 1, gw)
		_batch.add(_pts, _cols)
	for i in _outer.size():  # 지도 밖: 가장 가까운 지도 끝 칸·꼭짓점의 탐험·빛을 그대로(묶음 네 모서리도 지도 끝으로 당긴 꼭짓점)
		var c := _outer_at[i]
		if map.explored[c.y * map.width + c.x] == 0 and not _near_explored(map, c):
			continue
		var r := _outer[i]
		_quad(r.position.x * t, r.position.y * t, r.size.x * t, r.size.y * t)
		for k in 4:
			var vx := clampi(r.position.x + (r.size.x if k == 1 or k == 2 else 0), 0, map.width)
			var vy := clampi(r.position.y + (r.size.y if k >= 2 else 0), 0, map.height)
			_cols[k] = _mul(vx, vy, gw)
		_batch.add(_pts, _cols)
	_batch.flush(self)
	for n: Node2D in [_under, _rail_back, _rail_front]:
		if n != null:
			n.queue_redraw()


## 꼭짓점 (vx, vy)의 빛 배율(FloorView.vertex_mul, 흰 바탕) — 이번 그리기에서 처음이면 계산해 둔다. 이 청크의 꼭짓점(지도 끝으로 당긴 것 포함)만.
func _mul(vx: int, vy: int, gw: int) -> Color:
	var gi := (vy - cells.position.y) * gw + vx - cells.position.x
	if _vset[gi] == 0:
		_vset[gi] = 1
		_vmul[gi] = view.vertex_mul(vx, vy, Color.WHITE)
	return _vmul[gi]


func _quad(x: float, y: float, w: float, h: float) -> void:
	_pts[0] = Vector2(x, y)
	_pts[1] = Vector2(x + w, y)
	_pts[2] = Vector2(x + w, y + h)
	_pts[3] = Vector2(x, y + h)


## 발판 아래 받침 기둥: 남쪽이 허공인 발판 칸 every칸마다 들보 아래로 내려가며 어둠에 묻히는 기둥 + 사선 버팀대.
## 낮은 물 위 발판은 그 전에 물 위 그림자, 뒤에 들보 면(허공 위는 셰이더가 그린다)을 — 기둥이 들보 면 뒤로.
func _draw_under() -> void:
	var map := view.map
	var t := float(view.tile)
	var rail := Abyss.rail(view.art)
	var every := maxi(2, JsonUtil.get_int(rail, "support_every", 4))
	var wood := Abyss.color(view.art, "beam_color", "#4a3824")
	var depth := JsonUtil.get_float(rail, "support_depth", 2.6) * t
	MoatDeck.shadows(self, t, rail)
	for p in _beams_s:
		if map.explored[p.y * map.width + p.x] == 0 or posmod(p.x, every) != 0:
			continue
		var f := view.fog_mul(p.x, p.y + 1)
		var top := (p.y + 1) * t + t * 0.28
		var cx := (p.x + 0.5) * t
		var c0 := Color(wood.r * f * 0.8, wood.g * f * 0.8, wood.b * f * 0.8, 1.0)
		var c1 := Color(c0.r, c0.g, c0.b, 0.0)
		for side: float in [-1.0, 1.0]:  # 두 다리가 아래로 벌어진다
			var x0 := cx + side * t * 0.1
			var x1 := cx + side * t * 0.45
			_pts[0] = Vector2(x0 - 2.0, top)
			_pts[1] = Vector2(x0 + 2.0, top)
			_pts[2] = Vector2(x1 + 2.0, top + depth)
			_pts[3] = Vector2(x1 - 2.0, top + depth)
			_cols[0] = c0
			_cols[1] = c0.darkened(0.3)
			_cols[2] = c1
			_cols[3] = c1
			_batch.add(_pts, _cols)
		_quad(cx - t * 0.32, top + depth * 0.28, t * 0.64, 2.5)  # 가로 버팀대
		var cb := c0.lerp(c1, 0.35)
		_cols[0] = cb
		_cols[1] = cb
		_cols[2] = cb.darkened(0.4)
		_cols[3] = cb.darkened(0.4)
		_batch.add(_pts, _cols)
	MoatDeck.faces(self, t, rail, wood)
	_batch.flush(_under)
	MoatDeck.ink(self, _under, t, rail, wood)


## 난간: edge = 0(칸 북쪽 가장자리) / 1(남쪽). every칸마다 기둥, 그 사이에 위·가운데 줄(밧줄·가로대).
func _draw_rails(cv: CanvasItem, list: Array[Vector2i], edge: float) -> void:
	var map := view.map
	var t := float(view.tile)
	var rail := Abyss.rail(view.art)
	var every := maxi(1, JsonUtil.get_int(rail, "every", 2))
	var h := JsonUtil.get_float(rail, "height", 0.7) * t
	var post := Color.from_string(JsonUtil.get_str(rail, "post", "#5a4630"), Color.SADDLE_BROWN)
	var rope := Color.from_string(JsonUtil.get_str(rail, "rope", "#8a7656"), Color.TAN)
	var inset := t * (0.1 if edge < 0.5 else -0.08)
	var lines := PackedVector2Array()
	var line_cols := PackedColorArray()
	for p in list:
		if map.explored[p.y * map.width + p.x] == 0:
			continue
		var base := (p.y + edge) * t + inset
		var l0 := view.vertex_mul(p.x, p.y + int(edge), Color.WHITE)
		var l1 := view.vertex_mul(p.x + 1, p.y + int(edge), Color.WHITE)
		for k in 2:  # 위 줄 · 가운데 줄(칸 하나씩 이어 그려 이웃 칸과 이어진다)
			var yy := base - h * (0.92 if k == 0 else 0.5)
			var sag := t * 0.05
			lines.append_array([Vector2(p.x * t, yy), Vector2((p.x + 0.5) * t, yy + sag), Vector2((p.x + 0.5) * t, yy + sag), Vector2((p.x + 1) * t, yy)])
			for c: Color in [rope * l0, rope * l1]:  # 선분마다 한 색
				line_cols.append(Color(c.r, c.g, c.b, 1.0))
		if posmod(p.x, every) == 0:
			var cx := p.x * t + 1.5
			var pc := post * l0
			_pts[0] = Vector2(cx - 2.2, base - h)
			_pts[1] = Vector2(cx + 2.2, base - h)
			_pts[2] = Vector2(cx + 2.2, base + 2.0)
			_pts[3] = Vector2(cx - 2.2, base + 2.0)
			_cols[0] = Color(pc.r * 1.15, pc.g * 1.15, pc.b * 1.15, 1.0)
			_cols[1] = Color(pc.r * 0.6, pc.g * 0.6, pc.b * 0.6, 1.0)
			_cols[2] = _cols[1]
			_cols[3] = _cols[0]
			_batch.add(_pts, _cols)
	_batch.flush(cv)
	if not lines.is_empty():
		cv.draw_multiline_colors(lines, line_cols, 1.6)


static func _near_explored(map: FloorMap, p: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q := p + Vector2i(dx, dy)
			if map.in_bounds(q) and map.explored[q.y * map.width + q.x] != 0:
				return true
	return false


static func _void_at(map: FloorMap, q: Vector2i) -> bool:
	return map.in_bounds(q) and map.def_at(q).is_void


static func _sunk_at(map: FloorMap, q: Vector2i) -> bool:
	return map.in_bounds(q) and map.def_at(q).sunk


## 지도 끝 EDGE칸 안(나가는 길 — 셰이더가 어둠으로 녹인다).
static func _near_border(map: FloorMap, p: Vector2i) -> bool:
	return mini(mini(p.x, p.y), mini(map.width - 1 - p.x, map.height - 1 - p.y)) < EDGE


static func _near_void(map: FloorMap, p: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if (dx != 0 or dy != 0) and _void_at(map, p + Vector2i(dx, dy)):
				return true
	return false
