class_name FloorView
extends Node2D
## 3/4 시점(오블리크 탑다운) 층 그리기. 논리는 바닥 평면 그리드(FloorMap), 높이는 여기서만 다룬다.
##   바닥: FloorChunk(청크 단위, 항상 벽·캐릭터 아래)
##   벽:   WallRow(한 줄 × 청크 폭) — y_sort로 캐릭터와 앞뒤 가림. 윗면은 앞면 높이만큼 위로 올라간다.
##   캐릭터: ActorView — 발 위치가 정렬 기준. 남쪽 벽에 가려지면 실루엣을 겹친다.
## 밝기: 칸 꼭짓점마다 (정적 광원 + 시야 빛)을 계산해 draw_polygon 꼭짓점 색으로 섞는다(셰이더 없이).
## 안개: 탐험했지만 지금 안 보이는 칸은 어둡고 차갑게, 미탐험 칸은 그리지 않는다.

var session: ExploreSession
var map: FloorMap
var tile: int = 32
var wall_face: int = 24
var chunk: int = 16
var face_shade: float = 0.9
var edge_shade: float = 0.45
var rim_shade: float = 2.2
var player_view: ActorView

var _monster_views: Dictionary = {}  # 무리 id -> MonsterView
var _floor_chunks: Dictionary = {}  # Vector2i(청크 x, 청크 y) -> FloorChunk
var _wall_rows: Dictionary = {}     # Vector2i(청크 x, 줄) -> WallRow
var _last_rect: Rect2i = Rect2i()
var _vlight: PackedColorArray       # 꼭짓점 빛(시야 사각형 안만 갱신)
var _light_color: Color = Color.WHITE
var _light_center: Vector2 = Vector2.ZERO
var _vision: float = 1.0
var _cfg: Dictionary = {}
var _memory_tint: Color = Color.GRAY
var _memory_brightness: float = 0.2


func setup(p_session: ExploreSession) -> void:
	session = p_session
	map = session.map


func _ready() -> void:
	_cfg = JsonUtil.get_dict(session.db.render, "view")
	var ft := JsonUtil.get_array(_cfg, "floor_tile_px")
	var wt := JsonUtil.get_array(_cfg, "wall_tile_px")
	tile = int(ft[0]) if ft.size() == 2 else 32
	wall_face = (int(wt[1]) - tile) if wt.size() == 2 else 24
	chunk = maxi(4, JsonUtil.get_int(_cfg, "chunk_size", 16))
	face_shade = JsonUtil.get_float(_cfg, "face_shade", 0.9)
	edge_shade = JsonUtil.get_float(_cfg, "edge_shade", 0.45)
	rim_shade = JsonUtil.get_float(_cfg, "rim_shade", 2.2)
	_memory_tint = Color.from_string(JsonUtil.get_str(_cfg, "memory_tint"), Color.GRAY)
	_memory_brightness = JsonUtil.get_float(_cfg, "memory_brightness", 0.2)
	_vlight = PackedColorArray()
	_vlight.resize((map.width + 1) * (map.height + 1))
	y_sort_enabled = true
	var floor_layer := Node2D.new()
	floor_layer.z_index = -10
	add_child(floor_layer)
	for cy in ceili(map.height / float(chunk)):
		for cx in ceili(map.width / float(chunk)):
			var fc := FloorChunk.new()
			fc.setup(self, Rect2i(cx * chunk, cy * chunk, chunk, chunk).intersection(Rect2i(0, 0, map.width, map.height)))
			floor_layer.add_child(fc)
			_floor_chunks[Vector2i(cx, cy)] = fc
	for row in map.height:
		for cx in ceili(map.width / float(chunk)):
			var x0 := cx * chunk
			var x1 := mini(x0 + chunk, map.width)
			if _row_has_wall(row, x0, x1):
				var wr := WallRow.new()
				wr.setup(self, row, x0, x1)
				add_child(wr)
				_wall_rows[Vector2i(cx, row)] = wr
	player_view = ActorView.new()
	player_view.setup_for(session.player, session.db.render)
	add_child(player_view)
	player_view.position = feet_of(session.fpos)
	session.body_moved.connect(_on_body_moved)
	session.monsters.changed.connect(sync_monsters)
	refresh(true)


## 칸 p 중심에 선 캐릭터의 발 위치(월드 좌표).
func feet_position(p: Vector2i) -> Vector2:
	return feet_of(Kinematics.center_of(p))


## 몸 중심 연속 좌표 c(칸 단위)에 선 캐릭터의 발 위치. 칸 중심이면 칸 아래쪽에서 inset만큼 올린 자리.
## 몸 반폭(0.3칸) 덕분에 발은 늘 (북쪽 벽 줄, 남쪽 벽 줄) 사이에 있어 벽과의 y 정렬이 뒤집히지 않는다.
func feet_of(c: Vector2) -> Vector2:
	var inset := JsonUtil.get_int(_cfg, "actor_feet_inset_px", 4)
	return Vector2(c.x * tile, (c.y + 0.5) * tile - inset)


## 칸이 바뀌었다(시야 갱신은 refresh가 한다).
func move_player(_to: Vector2i) -> void:
	player_view.face(session.facing)


func _on_body_moved(at: Vector2) -> void:
	player_view.position = feet_of(at)
	player_view.face(session.facing)


## 시야가 바뀌면 부른다. full이면 전부 다시 그린다.
func refresh(full: bool = false) -> void:
	_vision = maxf(0.5, session.vision_tiles())
	_light_center = Vector2(session.pos) + Vector2(0.5, 0.5)
	var kind := session.light_kind()
	if kind == "torch":
		_light_color = Color.from_string(JsonUtil.get_str(JsonUtil.get_dict(session.db.render, "lighting"), "torch_color"), Color.WHITE)
	else:
		_light_color = Color.from_string(JsonUtil.get_str(session.floor_def, "ambient_color"), Color.WHITE)
	var r := ceili(_vision) + 2
	var rect := Rect2i(session.pos - Vector2i(r, r), Vector2i(r * 2 + 1, r * 2 + 1)).intersection(Rect2i(0, 0, map.width, map.height))
	_update_vertex_light(rect)
	var dirty := Rect2i(0, 0, map.width, map.height) if full or not _last_rect.has_area() else rect.merge(_last_rect)
	_last_rect = rect
	for key: Vector2i in _floor_chunks:
		var fc: FloorChunk = _floor_chunks[key]
		if fc.cells.intersects(dirty):
			fc.queue_redraw()
	for key: Vector2i in _wall_rows:
		var wr: WallRow = _wall_rows[key]
		if key.y >= dirty.position.y and key.y < dirty.end.y and wr.x0 < dirty.end.x and wr.x1 > dirty.position.x:
			wr.queue_redraw()
	player_view.face(session.facing)
	player_view.set_occluded(_occludes(session.pos + Vector2i(0, 1)))
	sync_monsters()
	player_view.set_light(_light_color, kind == "torch", _vision * tile)
	var tint_k := JsonUtil.get_float(_cfg, "actor_light_tint", 0.5)
	player_view.self_modulate = Color.WHITE.lerp(_light_color, tint_k)


## 몬스터 무리 그림을 세션 상태에 맞춘다: 새 무리는 만들고, 사라진 무리는 지우고, 보이는 것만 표시.
func sync_monsters() -> void:
	var alive := {}
	for g in session.monsters.groups:
		alive[g.id] = true
		var mv: MonsterView = _monster_views.get(g.id)
		if mv == null:
			mv = MonsterView.new()
			mv.setup(g, session.db)
			add_child(mv)
			_monster_views[g.id] = mv
		mv.position = feet_of(g.fpos)
		mv.face_toward(feet_of(session.fpos))
		mv.visible = session.monsters.is_visible(g, session.pos)
	for id: int in _monster_views.keys():
		if not alive.has(id):
			(_monster_views[id] as Node).queue_free()
			_monster_views.erase(id)


## 꼭짓점 (vx, vy)의 최종 색: 보이면 빛을 곱하고, 기억만 있으면 어둡고 차갑게.
func vertex_color(vx: int, vy: int, base: Color, seen_now: bool) -> Color:
	if not seen_now:
		var l := base.get_luminance()
		var d := Color(l, l, l).lerp(base, 0.35)
		return Color(d.r * _memory_tint.r * _memory_brightness, d.g * _memory_tint.g * _memory_brightness,
			d.b * _memory_tint.b * _memory_brightness, 1.0)
	var lit := _vlight[vy * (map.width + 1) + vx]
	return Color(base.r * lit.r, base.g * lit.g, base.b * lit.b, 1.0)


## 칸마다 약간 다른 밝기(동굴 바닥 질감). 같은 칸은 항상 같은 값.
func cell_jitter(x: int, y: int) -> float:
	var h := hash(Vector2i(x, y) + Vector2i(map.seed_value % 9973, 0))
	return 0.9 + 0.1 * float(absi(h) % 1000) / 1000.0


func wall_face_of(def: TileDef) -> int:
	return def.face_px if def.face_px >= 0 else wall_face


## 시야 사각형 안 꼭짓점의 빛 = 시야 빛(가운데 light_peak → 가장자리 light_min) + 정적 광원.
func _update_vertex_light(rect: Rect2i) -> void:
	var light_min := JsonUtil.get_float(_cfg, "light_min", 0.1)
	var peak := JsonUtil.get_float(_cfg, "light_peak", 1.5)
	var inner := _vision * JsonUtil.get_float(_cfg, "light_inner_ratio", 0.45)
	var span := maxf(0.001, _vision + 0.75 - inner)
	var static_k := JsonUtil.get_float(_cfg, "static_light_strength", 0.9)
	var w := map.width + 1
	for vy in range(rect.position.y, rect.end.y + 1):
		for vx in range(rect.position.x, rect.end.x + 1):
			var d := Vector2(vx, vy).distance_to(_light_center)
			var k := 1.0 if d <= inner else clampf(1.0 - (d - inner) / span, 0.0, 1.0)
			var dyn := lerpf(light_min, peak, k * k * (3.0 - 2.0 * k))
			var s := session.lights.at(vx, vy)
			_vlight[vy * w + vx] = Color(minf(_light_color.r * dyn + s.r * static_k, peak),
				minf(_light_color.g * dyn + s.g * static_k, peak), minf(_light_color.b * dyn + s.b * static_k, peak), 1.0)


func _row_has_wall(row: int, x0: int, x1: int) -> bool:
	for x in range(x0, x1):
		if map.def_at(Vector2i(x, row)).is_wall():
			return true
	return false


## 칸 p의 벽이 바로 북쪽 칸에 선 캐릭터를 가리는가.
func _occludes(p: Vector2i) -> bool:
	return map.in_bounds(p) and map.def_at(p).is_wall() and map.explored[map.idx(p)] != 0
