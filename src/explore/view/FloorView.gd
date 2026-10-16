class_name FloorView
extends Node2D
## 3/4 시점(오블리크 탑다운) 층 그리기. 논리는 바닥 평면 그리드(FloorMap), 높이는 여기서만 다룬다.
##   바닥: FloorChunk(청크 단위, 항상 벽·캐릭터 아래)
##   벽:   WallRow(한 줄 × 청크 폭) — y_sort로 캐릭터와 앞뒤 가림. 윗면은 앞면 높이만큼 위로 올라간다.
##   청크·벽 줄 노드는 플레이어 둘레 stream_chunks 청크 안에만 둔다(큰 지도에서 노드 수·정렬 비용을 일정하게).
##   캐릭터: ActorView — 발 위치가 정렬 기준. 남쪽 벽에 가려지면 실루엣을 겹친다.
## 밝기: 칸 꼭짓점마다 (정적 광원 + 시야 빛)을 계산해 draw_polygon 꼭짓점 색으로 섞는다(셰이더 없이).
## 안개(시야 3상태): 미탐험 = 그리지 않음(순흑 배경), 기억 = 탈색·저명도, 보임 = 빛. 경계는 꼭짓점마다
##   둘레 네 칸 중 탐험한 수·보이는 수(_vfog)로 섞어 칸 계단 없이 부드럽게 감쇠한다. 보이는 곳의 최저 명도 = 층 근흑색.
## 층 그림 설정(색조·근흑색·맥동·입자)은 FloorArt(층 JSON art).

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
var _floor_chunks: Dictionary = {}  # Vector2i(청크 x, 청크 y) -> FloorChunk (플레이어 둘레만 — _stream_around)
var _wall_rows: Dictionary = {}     # Vector2i(청크 x, 줄) -> WallRow
var _floor_layer: Node2D
var _stream: int = 3                # 플레이어 청크에서 몇 청크까지 그릴 노드를 두는가(render.json view.stream_chunks)
var _active: Rect2i = Rect2i()      # 지금 노드가 있는 청크 사각형(청크 좌표)
var _last_rect: Rect2i = Rect2i()
var _vlight: PackedColorArray       # 꼭짓점 빛(시야 사각형 안만 갱신)
var _light_color: Color = Color.WHITE
var _light_center: Vector2 = Vector2.ZERO
var _vision: float = 1.0
var _cfg: Dictionary = {}
const FOG_ALL_SEEN := 4 | (4 << 3)
var _vfog: PackedByteArray          # 꼭짓점 둘레 네 칸: 탐험한 수(아래 3비트) | 보이는 수 << 3
var art: FloorArt
var _nb: Color = Color.BLACK          # art 값 사본(vertex_color는 아주 자주 불린다)
var _unexplored: Color = Color.BLACK
var _mem: Color = Color.GRAY         # 기억 색조 × 밝기
var _glow_layer: Node2D
var glow_texture: GradientTexture2D   # GlowChunk들이 같이 쓴다
var glow_material: ShaderMaterial
var _glow_chunks: Dictionary = {}   # Vector2i(청크) -> GlowChunk (맥동하는 타일이 있는 층만)
var _particles: AmbientParticles


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
	_set_art(FloorArt.resolve(session.db.render, session.floor_def, GraphicsSettings.quality()))
	_vlight = PackedColorArray()
	_vlight.resize((map.width + 1) * (map.height + 1))
	_vfog = PackedByteArray()
	_vfog.resize((map.width + 1) * (map.height + 1))
	_stream = maxi(1, JsonUtil.get_int(_cfg, "stream_chunks", 3))
	y_sort_enabled = true
	_floor_layer = Node2D.new()
	_floor_layer.z_index = -10
	add_child(_floor_layer)
	if art.has_pulse():
		_glow_layer = Node2D.new()
		_glow_layer.z_index = JsonUtil.get_int(_cfg, "glow_z", 5)
		glow_texture = GlowChunk.make_texture()
		glow_material = GlowChunk.make_material(art.pulse_period, art.pulse_depth)
		add_child(_glow_layer)
	player_view = ActorView.new()
	player_view.setup_for(session.player, session.db.render)
	player_view.calm = art.low_quality
	add_child(player_view)
	player_view.position = feet_of(session.fpos)
	_build_particles()
	session.body_moved.connect(_on_body_moved)
	session.monsters.changed.connect(sync_monsters)
	refresh(true)


## 그래픽 품질이 바뀌었다: 그림 설정을 다시 읽어 맥동 깊이·입자·횃불 흔들림만 바꾼다(지형 그림은 그대로).
func set_quality(quality: String) -> void:
	_set_art(FloorArt.resolve(session.db.render, session.floor_def, quality))
	player_view.calm = art.low_quality
	if glow_material != null:
		glow_material.set_shader_parameter("depth", art.pulse_depth)
	if _particles != null:
		_particles.queue_free()
		_particles = null
	_build_particles()
	if _particles != null:
		_particles.set_radius(_vision * tile)


func _set_art(a: FloorArt) -> void:
	art = a
	_nb = a.near_black
	_unexplored = a.unexplored
	_mem = a.memory_tint * a.memory_brightness


func _build_particles() -> void:
	if art.particles.is_empty():
		return
	_particles = AmbientParticles.new()
	_particles.z_index = JsonUtil.get_int(_cfg, "particles_z", 6)
	add_child(_particles)
	_particles.setup(art.particles)
	_particles.position = player_view.position


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
	if _particles != null:
		_particles.position = player_view.position
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
	var whole := full or not _last_rect.has_area()
	var dirty := rect.merge(_last_rect) if not whole else Rect2i()
	_last_rect = rect
	_stream_around(session.pos)  # 새로 만든 노드는 처음 그려질 때 이미 최신이다
	if whole:
		_update_fog(Rect2i(_active.position * chunk, _active.size * chunk))
		for fc: FloorChunk in _floor_chunks.values():
			fc.queue_redraw()
		for wr: WallRow in _wall_rows.values():
			wr.queue_redraw()
		for gc: GlowChunk in _glow_chunks.values():
			gc.queue_redraw()
	else:
		_update_fog(dirty)
		_redraw_rect(dirty)
	player_view.face(session.facing)
	player_view.set_occluded(_occludes(session.pos + Vector2i(0, 1)))
	sync_monsters()
	player_view.set_light(_light_color, kind == "torch", _vision * tile)
	if _particles != null:
		_particles.set_radius(_vision * tile)
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


## 꼭짓점 (vx, vy)의 최종 색: 둘레 네 칸 중 보이는 비율만큼 빛(base × 빛)을, 나머지는 기억 색(탈색·저명도)을 섞고,
## 층 근흑색 아래로 내려가지 않게 한 뒤, 둘레에 미탐험 칸이 있으면 그만큼 순흑으로 감쇠한다.
func vertex_color(vx: int, vy: int, base: Color) -> Color:
	var i := vy * (map.width + 1) + vx
	var f := _vfog[i]
	var lit := _vlight[i]
	if f == FOG_ALL_SEEN:  # 가장 흔한 경우(시야 한가운데)
		return Color(maxf(base.r * lit.r, _nb.r), maxf(base.g * lit.g, _nb.g), maxf(base.b * lit.b, _nb.b), 1.0)
	var e := f & 7
	if e == 0:
		return _unexplored
	var s := f >> 3
	var l := base.get_luminance()
	var d := Color(l, l, l).lerp(base, 0.35)
	var c := Color(d.r * _mem.r, d.g * _mem.g, d.b * _mem.b, 1.0)
	if s > 0:
		c = c.lerp(Color(base.r * lit.r, base.g * lit.g, base.b * lit.b, 1.0), float(s) / float(e))
	c = Color(maxf(c.r, _nb.r), maxf(c.g, _nb.g), maxf(c.b, _nb.b), 1.0)
	return c if e >= 4 else _unexplored.lerp(c, float(e) * 0.25)


## 꼭짓점 (vx, vy) 둘레 네 칸(지도 밖은 미탐험)의 탐험한 수 | 보이는 수 << 3.
static func fog_counts(m: FloorMap, vx: int, vy: int) -> int:
	var e := 0
	var s := 0
	for dy in 2:
		var y := vy - 1 + dy
		if y < 0 or y >= m.height:
			continue
		for dx in 2:
			var x := vx - 1 + dx
			if x < 0 or x >= m.width:
				continue
			var j := y * m.width + x
			if m.explored[j] != 0:
				e += 1
				if m.visible_now[j] != 0:
					s += 1
	return e | (s << 3)


## 칸 사각형 cells를 둘러싼 꼭짓점들의 안개 값을 다시 센다(칸 값 = 탐험 1 + 보임 8을 한 번 모아 네 칸씩 더한다).
func _update_fog(cells: Rect2i) -> void:
	var r := cells.intersection(Rect2i(0, 0, map.width, map.height))
	if not r.has_area():
		return
	var ext := r.grow(1)  # 꼭짓점 둘레 칸까지
	var cw := ext.size.x
	var cv := PackedByteArray()
	cv.resize(cw * ext.size.y)
	for y in range(maxi(0, ext.position.y), mini(map.height, ext.end.y)):
		var row := (y - ext.position.y) * cw - ext.position.x
		for x in range(maxi(0, ext.position.x), mini(map.width, ext.end.x)):
			var j := y * map.width + x
			if map.explored[j] != 0:
				cv[row + x] = 9 if map.visible_now[j] != 0 else 1
	var w := map.width + 1
	for vy in range(r.position.y, r.end.y + 1):
		var up := (vy - 1 - ext.position.y) * cw - ext.position.x
		var dn := up + cw
		for vx in range(r.position.x, r.end.x + 1):
			_vfog[vy * w + vx] = cv[up + vx - 1] + cv[up + vx] + cv[dn + vx - 1] + cv[dn + vx]


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


## 플레이어 칸 p 둘레 청크만 노드로 둔다: 사각형을 벗어난 청크·벽 줄은 지우고, 새로 들어온 것은 만든다.
func _stream_around(p: Vector2i) -> void:
	var grid := Rect2i(0, 0, ceili(map.width / float(chunk)), ceili(map.height / float(chunk)))
	var c := Vector2i(p.x / chunk, p.y / chunk)
	var want := Rect2i(c - Vector2i(_stream, _stream), Vector2i(_stream * 2 + 1, _stream * 2 + 1)).intersection(grid)
	if want == _active:
		return
	for key: Vector2i in _floor_chunks.keys():
		if not want.has_point(key):
			(_floor_chunks[key] as Node).queue_free()
			_floor_chunks.erase(key)
			if _glow_chunks.has(key):
				(_glow_chunks[key] as Node).queue_free()
				_glow_chunks.erase(key)
	for key: Vector2i in _wall_rows.keys():
		if not want.has_point(Vector2i(key.x, key.y / chunk)):
			(_wall_rows[key] as Node).queue_free()
			_wall_rows.erase(key)
	for cy in range(want.position.y, want.end.y):
		for cx in range(want.position.x, want.end.x):
			if not _active.has_point(Vector2i(cx, cy)):
				_build_chunk(cx, cy)
	_active = want


func _build_chunk(cx: int, cy: int) -> void:
	var cells := Rect2i(cx * chunk, cy * chunk, chunk, chunk).intersection(Rect2i(0, 0, map.width, map.height))
	var fc := FloorChunk.new()
	fc.setup(self, cells)
	_floor_layer.add_child(fc)
	_floor_chunks[Vector2i(cx, cy)] = fc
	_update_fog(cells)
	if _glow_layer != null:
		var gc := GlowChunk.new()
		gc.setup(self, cells)
		_glow_layer.add_child(gc)
		_glow_chunks[Vector2i(cx, cy)] = gc
	for row in range(cells.position.y, cells.end.y):
		if _row_has_wall(row, cells.position.x, cells.end.x):
			var wr := WallRow.new()
			wr.setup(self, row, cells.position.x, cells.end.x)
			add_child(wr)
			_wall_rows[Vector2i(cx, row)] = wr


## dirty(칸 사각형)에 걸친 청크·벽 줄만 다시 그린다(사전에서 바로 찾는다).
func _redraw_rect(dirty: Rect2i) -> void:
	var r := dirty.intersection(Rect2i(0, 0, map.width, map.height))
	if not r.has_area():
		return
	var cx0 := r.position.x / chunk
	var cx1 := (r.end.x - 1) / chunk
	for cy in range(r.position.y / chunk, (r.end.y - 1) / chunk + 1):
		for cx in range(cx0, cx1 + 1):
			var fc: FloorChunk = _floor_chunks.get(Vector2i(cx, cy))
			if fc != null:
				fc.queue_redraw()
			var gc: GlowChunk = _glow_chunks.get(Vector2i(cx, cy))
			if gc != null:
				gc.queue_redraw()
	for row in range(r.position.y, r.end.y):
		for cx in range(cx0, cx1 + 1):
			var wr: WallRow = _wall_rows.get(Vector2i(cx, row))
			if wr != null:
				wr.queue_redraw()


func _row_has_wall(row: int, x0: int, x1: int) -> bool:
	for x in range(x0, x1):
		if map.def_at(Vector2i(x, row)).is_wall():
			return true
	return false


## 칸 p의 벽이 바로 북쪽 칸에 선 캐릭터를 가리는가.
func _occludes(p: Vector2i) -> bool:
	return map.in_bounds(p) and map.def_at(p).is_wall() and map.explored[map.idx(p)] != 0
