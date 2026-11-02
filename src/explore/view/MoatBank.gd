class_name MoatBank
extends RefCounted
## 낮은 물(타일 art.sunk — 핏물 해자)의 물가 절벽(사용자 2026-11-01 "도개교 연결부 근처 지형도 절벽으로 입체감", AM62):
## 땅이 물보다 높게 보이도록 물가 윤곽(바닥이 이미 둥글게 섞인 모양 — FloorChunk 가장자리 사선과 같은 선)을 따라
##   남쪽을 향한 물가(땅 → 아래 물) = 절벽 면(균열 낭떠러지 절벽 그림 cliff를 세계 좌표로) + 그 아래 물 위 그림자 + 위 가장자리 밝은 턱
##   옆 물가(땅이 동·서) = 물 쪽에 비스듬히 보이는 좁은 절벽 벽(같은 절벽 그림) + 그늘 — 낭떠러지 셰이더의 옆벽과 같은 방식
##   북쪽을 향한 물가(땅이 물 남쪽 — 절벽 면은 보이지 않는다) = 물가 쪽 물 위에 얇은 그늘
## 청크마다 한 번 모양을 만들고(build) 그릴 때는 탐험·빛만 본다. VoidChunk의 받침 기둥 층(_under) 맨 앞에 그린다.
## 다리 발판(void_edge "beam")은 땅으로 치지 않는다(MoatDeck). 수치 = 균열 look.art.abyss.bank(없으면 기본값).

var _segs: Array[Dictionary] = []   ## [{a, b(월드, 왼→오), cell(탐험 확인 칸)}] 절벽 면이 매달리는 물가 선분
var _sides: Array[Dictionary] = []  ## [{x, y0, y1, dir(물 쪽 +1 동 / -1 서), cell}] 옆 물가
var _lows: Array[Dictionary] = []   ## [{x0, x1, y, cell}] 북쪽을 향한 물가(물 칸 아래 변 — 깎인 모서리 사이)


## cells 안의 물가 모양(없으면 null).
static func build(view: FloorView, cells: Rect2i) -> MoatBank:
	var map := view.map
	var any := false
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			if map.def_at(Vector2i(x, y)).sunk:
				any = true
				break
		if any:
			break
	if not any:
		return null
	var b := MoatBank.new()
	var t := float(view.tile)
	var r := view.wall_round * t
	var bulge := view.tile * view.wall_bulge
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var p := Vector2i(x, y)
			if map.def_at(p).sunk:
				b._water(view, p, t, r, bulge)
			elif _bank(map, p):
				b._fillets(view, p, t, r, bulge)
	return b if not (b._segs.is_empty() and b._sides.is_empty() and b._lows.is_empty()) else null


## 물보다 높은 땅(벽·낭떠러지·물·다리 발판이 아닌 칸).
static func _bank(map: FloorMap, q: Vector2i) -> bool:
	if not map.in_bounds(q):
		return false
	var d := map.def_at(q)
	return not d.is_wall() and not d.is_void and not d.sunk and d.void_edge != "beam"


## 물 칸 p의 볼록 모서리 c가 땅 그림으로 깎였는가(FloorChunk._find_blends와 같은 조건).
static func _cut(view: FloorView, p: Vector2i, c: Vector2i) -> bool:
	var map := view.map
	var a := p + Vector2i(c.x, 0)
	var b := p + Vector2i(0, c.y)
	if not (_bank(map, a) and _bank(map, b) and map.in_bounds(p + c)):
		return false
	var da := map.def_at(a)
	return da == map.def_at(b) and view.blend_by_def[map.def_at(p).index] != 0 and view.tile_tex[da.index] != null


func _water(view: FloorView, p: Vector2i, t: float, r: float, bulge: float) -> void:
	var map := view.map
	var o := Vector2(p) * t
	var nw := _cut(view, p, Vector2i(-1, -1))
	var ne := _cut(view, p, Vector2i(1, -1))
	if _bank(map, p + Vector2i(0, -1)):  # 북쪽이 땅: 물 칸 위 가장자리(깎인 모서리 사선 포함)에 절벽 면
		var line := PackedVector2Array()
		if nw:
			WallShape._cut(line, o + Vector2(0, r), o + Vector2(r, 0), o, bulge)
		else:
			line.append(o)
		if ne:
			WallShape._cut(line, o + Vector2(t - r, 0), o + Vector2(t, r), o + Vector2(t, 0), bulge)
		else:
			line.append(o + Vector2(t, 0))
		_add(line, p)
	if _bank(map, p + Vector2i(0, 1)):  # 남쪽이 땅(북쪽을 향한 물가)
		var x0 := o.x + (r if _cut(view, p, Vector2i(-1, 1)) else 0.0)
		var x1 := o.x + t - (r if _cut(view, p, Vector2i(1, 1)) else 0.0)
		_lows.append({"x0": x0, "x1": x1, "y": o.y + t, "cell": p})
	for side: int in [-1, 1]:  # 옆 물가
		if not _bank(map, p + Vector2i(side, 0)):
			continue
		var g := p + Vector2i(side, 0)  # 옆 땅 칸 — 그 오목 모서리가 물로 메워졌으면 그만큼 물가가 사선이다
		var top_cut := _cut(view, p, Vector2i(side, -1)) or _filled(view, g, Vector2i(-side, -1))
		var low_cut := _cut(view, p, Vector2i(side, 1)) or _filled(view, g, Vector2i(-side, 1))
		var x := o.x + (0.0 if side < 0 else t)
		_sides.append({"x": x, "y0": o.y + (r if top_cut else 0.0), "y1": o.y + (t - r if low_cut else t), "dir": -side, "cell": p})


## 땅 칸 g의 오목 모서리 c(바깥 대각선 방향)가 물로 메워졌는가(FloorChunk._find_blends와 같은 조건).
static func _filled(view: FloorView, g: Vector2i, c: Vector2i) -> bool:
	var map := view.map
	var a := g + Vector2i(c.x, 0)
	var b := g + Vector2i(0, c.y)
	if not (map.in_bounds(a) and map.in_bounds(b) and map.in_bounds(g + c)):
		return false
	var da := map.def_at(a)
	return da.sunk and da == map.def_at(b) and map.def_at(g + c) == da and view.blend_by_def[da.index] != 0


## 땅 칸 p의 아래쪽 오목 모서리가 물로 메워졌다(FloorChunk와 같은 조건) — 그 사선에도 절벽 면.
func _fillets(view: FloorView, p: Vector2i, t: float, r: float, bulge: float) -> void:
	var o := Vector2(p) * t
	for cx: int in [-1, 1]:
		if not _filled(view, p, Vector2i(cx, 1)):
			continue
		var corner := o + Vector2(t if cx > 0 else 0.0, t)
		var arc := PackedVector2Array()
		WallShape._cut(arc, corner + Vector2(0, -r), corner + Vector2(-cx * r, 0), corner, bulge)
		if arc[0].x > arc[arc.size() - 1].x:
			arc.reverse()
		_add(arc, p)


func _add(line: PackedVector2Array, cell: Vector2i) -> void:
	for i in line.size() - 1:
		if line[i + 1].x - line[i].x > 0.01:
			_segs.append({"a": line[i], "b": line[i + 1], "cell": cell})


## cv(VoidChunk._under)에 그린다 — 그림자 → 절벽 면 → 옆 그늘 → 위 턱 선.
func draw(view: FloorView, cv: CanvasItem) -> void:
	var map := view.map
	var t := float(view.tile)
	var cfg := JsonUtil.get_dict(view.art.abyss, "bank")
	var drop := JsonUtil.get_float(cfg, "depth_tiles", 0.45) * t
	var sh := JsonUtil.get_float(cfg, "shadow_tiles", 0.7) * t
	var sh_a := JsonUtil.get_float(cfg, "shadow_alpha", 0.55)
	var side_px := JsonUtil.get_float(cfg, "side_px", 9.0)
	var side_a := JsonUtil.get_float(cfg, "side_alpha", 0.5)
	var side_shade := JsonUtil.get_float(cfg, "side_shade", 0.6)
	var cliff_path := JsonUtil.get_str(view.art.abyss, "cliff")
	var cliff: Texture2D = load(cliff_path) as Texture2D if not cliff_path.is_empty() and ResourceLoader.exists(cliff_path) else null
	var cliff_w := JsonUtil.get_float(view.art.abyss, "cliff_tiles", 8.0) * t
	var cliff_h := JsonUtil.get_float(view.art.abyss, "cliff_depth", 2.0) * t
	var rim := Abyss.color(view.art, "rim_color", "#9a8e80")
	var batch := QuadBatch.new()
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
	var uvs := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var rims := PackedVector2Array()
	var rim_cols := PackedColorArray()
	var clear := Color(0, 0, 0, 0)
	for s in _segs:
		var c: Vector2i = s["cell"]
		if map.explored[c.y * map.width + c.x] == 0:
			continue
		var a: Vector2 = s["a"]
		var b: Vector2 = s["b"]
		var fa := Color(0, 0, 0, sh_a * view.fog_mul(roundi(a.x / t), roundi(a.y / t)))
		var fb := Color(0, 0, 0, sh_a * view.fog_mul(roundi(b.x / t), roundi(b.y / t)))
		_quad(pts, a + Vector2(0, drop), b + Vector2(0, drop), b + Vector2(0, drop + sh), a + Vector2(0, drop + sh))
		cols[0] = fa
		cols[1] = fb
		cols[2] = clear
		cols[3] = clear
		batch.add(pts, cols)
	for s in _lows:
		var c: Vector2i = s["cell"]
		if map.explored[c.y * map.width + c.x] == 0:
			continue
		var y := float(s["y"])
		var k := Color(0, 0, 0, side_a * view.fog_mul(c.x, c.y + 1))
		_quad(pts, Vector2(float(s["x0"]), y - side_px * 0.6), Vector2(float(s["x1"]), y - side_px * 0.6), Vector2(float(s["x1"]), y), Vector2(float(s["x0"]), y))
		cols[0] = clear
		cols[1] = clear
		cols[2] = k
		cols[3] = k
		batch.add(pts, cols)
	for s in _sides:  # 옆 절벽 너머 그늘
		var c: Vector2i = s["cell"]
		if map.explored[c.y * map.width + c.x] == 0:
			continue
		var x := float(s["x"]) + float(s["dir"]) * side_px
		var x2 := x + float(s["dir"]) * side_px
		var y0 := float(s["y0"])
		var y1 := float(s["y1"])
		var k := Color(0, 0, 0, side_a * view.fog_mul(c.x, c.y))
		_quad(pts, Vector2(x, y0), Vector2(x2, y0), Vector2(x2, y1), Vector2(x, y1))
		cols[0] = k
		cols[1] = clear
		cols[2] = clear
		cols[3] = k
		batch.add(pts, cols)
	batch.flush(cv)  # 그림자·옆 그늘이 절벽 면 아래로
	for s in _segs:
		var c: Vector2i = s["cell"]
		if map.explored[c.y * map.width + c.x] == 0:
			continue
		var a: Vector2 = s["a"]
		var b: Vector2 = s["b"]
		var la := _light(view, a, t)
		var lb := _light(view, b, t)
		_quad(pts, a, b, b + Vector2(0, drop), a + Vector2(0, drop))
		cols[0] = la
		cols[1] = lb
		cols[2] = Color(lb.r * 0.45, lb.g * 0.45, lb.b * 0.45, lb.a)
		cols[3] = Color(la.r * 0.45, la.g * 0.45, la.b * 0.45, la.a)
		if cliff != null:
			uvs[0] = Vector2(a.x / cliff_w, 0.0)
			uvs[1] = Vector2(b.x / cliff_w, 0.0)
			uvs[2] = Vector2(b.x / cliff_w, drop / cliff_h)
			uvs[3] = Vector2(a.x / cliff_w, drop / cliff_h)
			batch.add(pts, cols, uvs, cliff)
		else:
			batch.add(pts, cols)
		var rc := Color(rim.r * la.r, rim.g * la.g, rim.b * la.b, 0.7)
		rims.append_array([a, b])
		rim_cols.append(rc)
	for s in _sides:  # 옆 절벽 벽(비스듬히 보이는 좁은 면 — 절벽 그림을 세로로, 물 쪽으로 어둡게)
		var c: Vector2i = s["cell"]
		if map.explored[c.y * map.width + c.x] == 0:
			continue
		var x := float(s["x"])
		var x2 := x + float(s["dir"]) * side_px
		var y0 := float(s["y0"])
		var y1 := float(s["y1"])
		var l0 := _light(view, Vector2(x, y0), t)
		var l1 := _light(view, Vector2(x, y1), t)
		_quad(pts, Vector2(x, y0), Vector2(x2, y0), Vector2(x2, y1), Vector2(x, y1))
		cols[0] = Color(l0.r * side_shade, l0.g * side_shade, l0.b * side_shade, l0.a)
		cols[1] = Color(l0.r * side_shade * 0.4, l0.g * side_shade * 0.4, l0.b * side_shade * 0.4, l0.a)
		cols[2] = Color(l1.r * side_shade * 0.4, l1.g * side_shade * 0.4, l1.b * side_shade * 0.4, l1.a)
		cols[3] = Color(l1.r * side_shade, l1.g * side_shade, l1.b * side_shade, l1.a)
		if cliff != null:
			uvs[0] = Vector2(y0 / cliff_w + 0.37, 0.15)
			uvs[1] = Vector2(y0 / cliff_w + 0.37, 0.45)
			uvs[2] = Vector2(y1 / cliff_w + 0.37, 0.45)
			uvs[3] = Vector2(y1 / cliff_w + 0.37, 0.15)
			batch.add(pts, cols, uvs, cliff)
		else:
			batch.add(pts, cols)
		var rc := Color(rim.r * l0.r, rim.g * l0.g, rim.b * l0.b, 0.5)
		rims.append_array([Vector2(x, y0), Vector2(x, y1)])
		rim_cols.append(rc)
	batch.flush(cv)
	if not rims.is_empty():
		cv.draw_multiline_colors(rims, rim_cols, 1.2)


## 점 q(월드 px)에 가장 가까운 꼭짓점의 빛 배율(흰 바탕).
static func _light(view: FloorView, q: Vector2, t: float) -> Color:
	var m := view.map
	return view.vertex_mul(clampi(roundi(q.x / t), 0, m.width), clampi(roundi(q.y / t), 0, m.height), Color.WHITE)


static func _quad(pts: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> void:
	pts[0] = a
	pts[1] = b
	pts[2] = c
	pts[3] = d
