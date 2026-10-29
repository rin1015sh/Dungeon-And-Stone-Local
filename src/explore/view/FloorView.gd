class_name FloorView
extends Node2D
## 3/4 시점(오블리크 탑다운) 층 그리기. 논리는 바닥 평면 그리드(FloorMap), 높이는 여기서만 다룬다.
##   바닥: FloorChunk(청크 단위, 항상 벽·캐릭터 아래) · 데칼·소품: DecorChunk · 맥동 빛: GlowChunk · 노드 관리: ChunkStream
##   그림 파일: FloorTextures(타일 아틀라스·소품·턱·데칼 시트), 거시 색조: FloorTint
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
var stream: ChunkStream              # 플레이어 둘레 청크 노드(render.json view.stream_chunks)
var floor_layer: Node2D
var decor_layer: Node2D
var glow_layer: Node2D
var _last_rect: Rect2i = Rect2i()
var _diff := VertexDiff.new()        # 다시 그리기 전후 꼭짓점 값 비교
var _last_cap: int = -1              # 지난 갱신의 화면 반경(칸) — 바뀌면 전체 갱신
var _vlight: PackedColorArray       # 꼭짓점 빛(시야 사각형 안만 갱신)
var _light_color: Color = Color.WHITE
var _light_center: Vector2 = Vector2.ZERO
var _vision: float = 1.0
var _cfg: Dictionary = {}
const FOG_ALL_SEEN := 4 | (4 << 3)
var _vfog: PackedByteArray          # 꼭짓점 둘레 네 칸: 탐험한 수(아래 3비트) | 보이는 수 << 3
var _vknown: PackedByteArray        # 꼭짓점 둘레 4×4칸 중 "아는" 칸 수(탐험했거나 벽 — 미탐험 바닥만 모른다), 0~16
const KNOWN_ALL := 16
var art: FloorArt
var _nb: Color = Color.BLACK          # art 값 사본(vertex_color는 아주 자주 불린다)
var _unexplored: Color = Color.BLACK
var _mem: Color = Color.GRAY         # 기억 색조 × 밝기
var glow_texture: GradientTexture2D   # GlowChunk들이 같이 쓴다
var glow_material: ShaderMaterial
var _particles: AmbientParticles
var tile_tex: Array[Texture2D] = []  # map.defs 번호 -> 재질 아틀라스(없으면 null — 색칠한 칸으로 그린다)
var tex_material: ShaderMaterial     # 아틀라스 그림의 기억 탈색(floor_tex) — 바닥 청크·벽 줄이 같이 쓴다
var decor: FloorDecor                 # 데칼 배치(층 art.decor)
var tint := FloorTint.new()           # 거시 색조(층 art.macro) — 청크를 만들 때 그 꼭짓점만 채운다
var decor_tex: Texture2D              # 데칼 시트(그래픽 품질 low면 null — 데칼을 그리지 않는다)
var decor_sheet: Texture2D            # 읽어 둔 데칼 시트
var prop_tex: Dictionary = {}         # 소품·턱 시트 경로 -> Texture2D(읽기용)
var prop_by_def: Array[Texture2D] = [] # map.defs 번호 -> 소품 시트(없으면 null — 그리기에서 칸마다 사전을 찾지 않게)
var stand_by_def: Array[Texture2D] = [] # map.defs 번호 -> 서 있는 소품 시트(art.stand — WallRow가 덩어리 대신 그림으로)
var under_by_def: PackedInt32Array = PackedInt32Array()  # map.defs 번호 -> 소품 밑 바닥 타일 번호(FloorChunk)
var void_layer: Node2D                # 낭떠러지·구덩이(VoidChunk — 층 art.abyss가 있을 때만, 바닥·데칼 위에서 땅 가장자리를 깎는다)
var abyss_material: ShaderMaterial    # 절벽 면·어둠 셰이더(세계 좌표 — abyss.gdshader)
var smooth_by_def: PackedByteArray = PackedByteArray()  # map.defs 번호 -> 부드러운 암벽(WallShape)이면 1
var smooth_any: bool = false
var blend_by_def: PackedByteArray = PackedByteArray()   # map.defs 번호 -> 가장자리를 사선으로 다듬는 바닥(물 — FloorChunk)이면 1
var blend_any: bool = false
var base_floor: int = -1             # 층의 기본 바닥 타일 번호(깎은 벽 모서리 아래를 채운다 — gen.tiles.floor)
var wall_round: float = 0.5          # 암벽 모서리를 깎는 폭(칸 비율 — view.wall_round)
var wall_bulge: float = 0.06         # 깎은 사선 가운데가 모서리 쪽으로 휘는 정도(칸 비율 — view.wall_bulge)
var wall_skirt: int = 0              # 벽 앞면 밑동(px — render.json view.wall_skirt_px)
var prop_highlight: float = 1.15      # 소품(상호작용 대상) 밝기 배율 — 주변보다 한 단계 밝게


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
	_vknown = PackedByteArray()
	_vknown.resize((map.width + 1) * (map.height + 1))
	FloorTextures.load_into(self, _cfg)
	stream = ChunkStream.new(self, maxi(1, JsonUtil.get_int(_cfg, "stream_chunks", 3)))
	y_sort_enabled = true
	floor_layer = Node2D.new()
	floor_layer.z_index = -10
	add_child(floor_layer)
	decor_layer = Node2D.new()
	decor_layer.z_index = -9
	add_child(decor_layer)
	if abyss_material != null:
		void_layer = Node2D.new()
		void_layer.z_index = -9  # 데칼 층(-9)보다 나중에 붙여 같은 z에서 위에 — 가장자리 데칼도 함께 깎인다
		add_child(void_layer)
	if art.has_pulse():
		glow_layer = Node2D.new()
		glow_layer.z_index = JsonUtil.get_int(_cfg, "glow_z", 5)
		glow_texture = GlowChunk.make_texture()
		glow_material = GlowChunk.make_material(art.pulse_period, art.pulse_depth)
		add_child(glow_layer)
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
	FloorTextures.apply_detail(self)
	stream.recompute_decals()
	refresh(true)
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
	# 걸을 때는 화면 안만 갱신한다(밝은 균열은 시야 = 지도 전체) — 화면 밖은 들어오기 전에 갱신된다.
	# 처음·화면 크기가 바뀌었을 때는 시야 전체(처음엔 화면이 아직 2×2라 범위를 믿을 수 없다).
	var cap := _screen_radius()
	var whole := full or not _last_rect.has_area() or cap != _last_cap
	_last_cap = cap
	var r := ceili(_vision) + 2 if whole else mini(ceili(_vision) + 2, cap)
	var rect := Rect2i(session.pos - Vector2i(r, r), Vector2i(r * 2 + 1, r * 2 + 1)).intersection(Rect2i(0, 0, map.width, map.height))
	var dirty := rect.merge(_last_rect) if not whole else Rect2i()
	if not whole:
		_diff.take(dirty, map.width + 1, map.height + 1, _vlight, _vfog, _vknown)
	_update_vertex_light(rect)
	_last_rect = rect
	stream.around(session.pos)  # 새로 만든 노드는 처음 그려질 때 이미 최신이다
	if whole:
		update_fog(stream.active_cells())
		stream.redraw_all()
	else:
		update_fog(dirty)
		stream.redraw_rect(_diff.changed_cells(_vlight, _vfog, _vknown))  # 값이 바뀐 곳만(밝은 균열은 걸어도 거의 안 바뀐다)
	player_view.face(session.facing)
	player_view.set_occluded(_occludes(session.pos + Vector2i(0, 1)))
	sync_monsters()
	player_view.set_light(_light_color, kind == "torch", _vision * tile)
	if _particles != null:
		_particles.set_radius(_vision * tile)
	var tint_k := JsonUtil.get_float(_cfg, "actor_light_tint", 0.5)
	player_view.self_modulate = Color.WHITE.lerp(_light_color, tint_k)


## 원정 중에 타일이 바뀐 칸(새 시체 등 — ExploreSession.tiles_changed): 소품 칸에 넣고 그 둘레를 다시 그린다.
func cells_changed(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var dc: DecorChunk = stream.decor_chunks.get(Vector2i(x, y) / chunk)
			if dc != null:
				dc.note_prop(Vector2i(x, y))
	stream.redraw_rect(r.grow(1))


## 몬스터 무리 그림을 세션 상태에 맞춘다: 새 무리는 만들고, 사라진 무리는 지우고, 보이는 것만 표시.
func sync_monsters() -> void:
	var alive := {}
	for g in session.monsters.groups:
		alive[g.id] = true
		var mv: MonsterView = _monster_views.get(g.id)
		if not session.monsters.is_awake(g, session.pos):  # 쉬는 무리는 멀어서 보이지 않는다(그림 노드도 다가올 때 만든다)
			if mv != null:
				mv.visible = false
			continue
		if mv == null:
			mv = MonsterView.new()
			mv.setup(g, session.db)
			add_child(mv)
			_monster_views[g.id] = mv
		mv.refresh()
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
	if tint.enabled:
		var tc := tint.colors[i]
		lit = Color(lit.r * tc.r, lit.g * tc.g, lit.b * tc.b)
	var kn := _vknown[i]
	if f == FOG_ALL_SEEN and kn == KNOWN_ALL:  # 가장 흔한 경우(시야 한가운데)
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
	return _unexplored.lerp(c, known_fade(kn))


## 재질 그림용 꼭짓점 색: rgb = 그림에 곱할 빛 배율, a = 보이는 비율(셰이더가 1 - a만큼 탈색 — floor_tex).
## mean = 그림의 평균 색(타일 colors) — 근흑색 바닥을 배율로 바꾸는 데 쓴다. 미탐험 쪽 감쇠는 순흑으로.
func vertex_mul(vx: int, vy: int, mean: Color) -> Color:
	var i := vy * (map.width + 1) + vx
	var f := _vfog[i]
	var lit := _vlight[i]
	if tint.enabled:
		var tc := tint.colors[i]
		lit = Color(lit.r * tc.r, lit.g * tc.g, lit.b * tc.b)
	var fr := _nb.r / maxf(mean.r, 0.02)
	var fg := _nb.g / maxf(mean.g, 0.02)
	var fb := _nb.b / maxf(mean.b, 0.02)
	var kn := _vknown[i]
	if f == FOG_ALL_SEEN and kn == KNOWN_ALL:
		return Color(maxf(lit.r, fr), maxf(lit.g, fg), maxf(lit.b, fb), 1.0)
	var e := f & 7
	if e == 0:
		return Color(0, 0, 0, 0)
	var s := f >> 3
	var k := float(s) / float(e)
	var m := _mem.lerp(lit, k) if s > 0 else _mem
	var fade := known_fade(kn)
	return Color(maxf(m.r, fr) * fade, maxf(m.g, fg) * fade, maxf(m.b, fb) * fade, k)


## 뒷배경(낭떠러지 너머)의 꼭짓점 밝기: 보이면 1, 기억이면 기억 밝기, 미탐험 쪽은 순흑으로 감쇠(횃불 빛은 곱하지 않는다 — 먼 곳).
func fog_mul(vx: int, vy: int) -> float:
	var i := vy * (map.width + 1) + vx
	var f := _vfog[i]
	var e := f & 7
	if e == 0:
		return 0.0
	var k := float(f >> 3) / float(e)
	return lerpf(minf(1.0, art.memory_brightness + 0.2), 1.0, k) * known_fade(_vknown[i])


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


## 미탐험 바닥 경계 감쇠: 꼭짓점 둘레 4×4칸 중 아는 칸이 절반(경계 위)이면 0 → 두 칸 안쪽(모두 앎)이면 1.
## 한 칸이 아니라 두 칸에 걸쳐 둥글게 어두워져 시야 끝이 칸 계단으로 보이지 않는다.
static func known_fade(kn: int) -> float:
	var k := clampf((kn - 8) / 8.0, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


## 칸 사각형 cells를 둘러싼 꼭짓점들의 안개 값을 다시 센다(칸 값 = 탐험 1 + 보임 8을 한 번 모아 네 칸씩 더한다).
func update_fog(cells: Rect2i) -> void:
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
	# 아는 칸(탐험했거나 벽, 지도 밖도 바위)의 4×4 합 — 누적합 표(꼭짓점마다 네 번 읽기)
	var e2 := r.grow(2)
	var sw := e2.size.x + 1
	var sat := PackedInt32Array()
	sat.resize(sw * (e2.size.y + 1))
	for y in range(e2.size.y):
		var gy := e2.position.y + y
		var run := 0
		for x in range(e2.size.x):
			var gx := e2.position.x + x
			var known := 1
			if gx >= 0 and gy >= 0 and gx < map.width and gy < map.height:
				var j := gy * map.width + gx
				known = 1 if map.explored[j] != 0 or map.defs[map.tiles[j]].is_wall() else 0
			run += known
			sat[(y + 1) * sw + x + 1] = sat[y * sw + x + 1] + run
	for vy in range(r.position.y, r.end.y + 1):
		var y0 := (vy - 2 - e2.position.y) * sw
		var y1 := (vy + 2 - e2.position.y) * sw
		for vx in range(r.position.x, r.end.x + 1):
			var x0 := vx - 2 - e2.position.x
			var x1 := vx + 2 - e2.position.x
			_vknown[vy * w + vx] = sat[y1 + x1] - sat[y0 + x1] - sat[y1 + x0] + sat[y0 + x0]


## 플레이어에서 화면 끝까지의 칸 수 + 여유(벽 앞면·안개 번짐). 이보다 먼 꼭짓점은 화면에 들어오기 전에 다시 계산된다.
func _screen_radius() -> int:
	var half := get_viewport_rect().size * 0.5 / (tile * maxf(0.1, JsonUtil.get_float(_cfg, "camera_zoom", 2.0)))
	return ceili(maxf(half.x, half.y)) + 4


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


func _process(_delta: float) -> void:
	stream.process_one()


## 칸 p의 벽이 바로 북쪽 칸에 선 캐릭터를 가리는가.
func _occludes(p: Vector2i) -> bool:
	return map.in_bounds(p) and map.def_at(p).is_wall() and map.explored[map.idx(p)] != 0
