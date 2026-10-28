class_name BattlerView
extends Control
## 전투 무대 위의 참가자 하나. 그림은 MonsterArt(없으면 CombatFigure 도형): 적은 정면 그림, 아군 소환수는 뒷모습(<id>_back),
## 탐험가는 종족 뒷모습(<종족>_back — 옆모습은 없앴다, UI41).
## 적은 정면 + 머리 위 상태 아이콘(3개씩, 넘으면 깜빡이며 넘김 — StatusIcons)·이름(생명력·상성은 보이지 않는다 — 피어 앤 헝거처럼,
## 받은 피해만 숫자로 떠오른다. 조사·쳐 봐서 알아낸 것은 도감 B에서만 — 사용자 2026-10-27, UI22),
## 아군은 뒷모습만(이름·상태 아이콘·생명력·영혼력은 아래 파티 창에). 지금 차례면 발밑 고리가 빛난다.
## 탐험가는 대기 시트(<종족>_<view>_idle.webp, 가로 3칸)가 있으면 몸이 들썩이는 칸을 0-1-2-1로 넘긴다(render.json ui.combat_party_idle, UI40).
## 대상으로 고르는 중인 적은 고리·금색 이름 대신 그림 모양대로 흰빛이 숨 쉬듯 떠오른다(피어 앤 헝거식 — target_flash 셰이더, UI40).
## 쓰러지거나 도망치면 흐려진다.

var unit: Combatant
var shape: String = "humanoid"
var color: Color = Color.GRAY
var size_k: float = 1.0
var boss: bool = false  ## 보스 등급(render.json ui.combat_boss_ranks) — 크기와 상관없이 무대를 거의 채운다
var front: bool = true
var art: Texture2D = null  ## 몬스터 일러스트(없으면 null)
var _art_body: float = 1.0  ## 그림 속 몸 높이 px
var _idle: Array = []  ## 지금 보기의 대기 칸(AtlasTexture)
var _idle_t: float = 0.0
var _current: bool = false
var _target: bool = false
var _name: Label
var _icons: StatusIcons
var _icon_bottom: float = 0.0  ## 아이콘 줄의 아래 끝(이름 줄 바로 위)
var _flash: TextureRect = null  ## 대상 흰빛(그림 위에 같은 그림을 흰 실루엣으로 — 고를 때만)
var _flash_t: float = 0.0


func setup(u: Combatant, db: GameDatabase) -> void:
	unit = u
	front = u.side != Combatant.SIDE_PARTY
	if u.actor is Monster:
		_look((u.actor as Monster).def, (u.actor as Monster).monster_id + ("" if front else "_back"))  # 아군 소환수는 뒷모습
	elif u.actor is PlayerCharacter:
		var race := (u.actor as PlayerCharacter).race_id
		color = Color.from_string(JsonUtil.get_str(db.get_entry("races", race), "color"), Color.GRAY)
		var tex := MonsterArt.texture_in(MonsterArt.party_dir(), race + "_back")
		if tex != null:
			art = tex
			_art_body = MonsterArt.body_height_in(MonsterArt.party_dir(), race + "_back", tex)
			_idle = _idle_cells(race + "_back_idle")
			_tick_idle()
		_idle_t = randf() * 10.0  # 아군끼리 숨이 맞지 않게
		set_process(not _idle.is_empty())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not front:
		return
	_icons = StatusIcons.new()
	_icons.resized.connect(_place_icons)  # 쪽이 넘어가 개수가 바뀌면 다시 가운데로
	add_child(_icons)
	_name = UiTheme.label(u.label(), "small", "text_title")
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)


## 아직 나오지 않은 몬스터의 크기 견본(무대에 붙이지 않는다 — BattleStage가 소환될 자리를 미리 잴 때). 쓰고 나면 free().
static func probe(db: GameDatabase, monster_id: String) -> BattlerView:
	var v := BattlerView.new()
	v._look(db.get_entry("monsters", monster_id), monster_id)
	return v


func _look(def: Dictionary, art_id: String) -> void:
	shape = JsonUtil.get_str(def, "shape", "humanoid")
	size_k = JsonUtil.get_float(def, "size", 1.0)
	boss = UiTheme.render_array("ui.combat_boss_ranks").has(JsonUtil.get_str(def, "rank"))
	color = Color.from_string(JsonUtil.get_str(def, "color"), Color.GRAY)
	art = MonsterArt.texture(art_id)
	if art != null:
		_art_body = MonsterArt.body_height(art_id, art)


## 대기 시트 → 칸 3개(같은 크기 AtlasTexture). 시트가 없으면 빈 배열.
static func _idle_cells(id: String) -> Array:
	var sheet := MonsterArt.texture_in(MonsterArt.party_dir(), id)
	if sheet == null:
		return []
	var n := int(UiTheme.ui_dict("combat_party_idle").get("cells", 3))
	var w := sheet.get_width() / float(n)
	var out: Array = []
	for i in n:
		var a := AtlasTexture.new()
		a.atlas = sheet
		a.region = Rect2(w * i, 0.0, w, sheet.get_height())
		out.append(a)
	return out


## 대기 칸 고르기: 0-1-2-1 왕복, 칸마다 frame_s초.
func _tick_idle() -> void:
	if _idle.is_empty():
		return
	var cfg := UiTheme.ui_dict("combat_party_idle")
	var n := _idle.size()
	var loop := maxi(1, n * 2 - 2)
	var i := int(_idle_t / maxf(0.01, JsonUtil.get_float(cfg, "frame_s", 0.35))) % loop
	var cell: Texture2D = _idle[i if i < n else loop - i]
	if cell != art:
		art = cell
		queue_redraw()


## 키 h일 때 그림 전체 높이 / h(들어 올린 무기·뿔·이름표 자리 포함 — 무대가 화면 위로 넘치지 않게 줄일 때).
func height_ratio() -> float:
	if art != null:
		return art.get_height() / _art_body
	return CombatFigure.top_of(shape)


## 키 h일 때 차지하는 폭(무대 배치용).
func width_for(h: float) -> float:
	if art != null:
		return art.get_width() * h / _art_body
	return CombatFigure.width_of(shape, h)


## 무대가 정한 자리: 발 위치 · 키. 상태 아이콘 줄 아래 이름(적) — 둘 다 머리 위.
func place(foot: Vector2, h: float) -> void:
	var w := width_for(h)
	size = Vector2(w, art.get_height() * h / _art_body if art != null else h * 1.12)
	position = foot - Vector2(w / 2.0, size.y)
	if front:
		var top := h if art != null else h * CombatFigure.top_of(shape)
		_icon_bottom = maxf(size.y - top - 26.0, 4.0 - position.y + StatusIcons.icon_size())  # 이름 줄 위 — 화면 위로 넘치는 큰 보스도 보이게
		_icons.show_for(unit.actor)
		_place_icons()
		var lw := maxf(w, UiTheme.metric("combat_enemy_label_width", 150))
		_name.size = Vector2(lw, 20)
		_name.position = Vector2((w - lw) / 2.0, _icon_bottom + 2.0)
		_keep_in(_name)
	queue_redraw()


## 아이콘 줄을 가운데에 놓고 무대 안으로.
func _place_icons() -> void:
	_icons.position = Vector2((size.x - _icons.size.x) / 2.0, maxf(_icon_bottom - _icons.size.y, 4.0 - position.y))
	_keep_in(_icons)


## 이름·상태 아이콘 줄이 무대(화면) 양옆으로 넘치지 않게 안쪽으로 민다 — 가장자리에 선 좁은 적의 넓은 이름표.
func _keep_in(l: Control) -> void:
	var stage := get_parent_control()
	if stage == null:
		return
	var pad := float(UiTheme.metric("spacing", 8))
	var gx := clampf(position.x + l.position.x, pad, maxf(pad, stage.size.x - l.size.x - pad))
	l.position.x = gx - position.x


func refresh() -> void:
	if front:
		_icons.show_for(unit.actor)
	modulate.a = 1.0 if unit.is_active() else 0.3
	queue_redraw()


func set_current(on: bool) -> void:
	if _current != on:
		_current = on
		queue_redraw()


func set_targeted(on: bool) -> void:
	if _target != on:
		_target = on
		if art != null:
			_ensure_flash()
			_flash.visible = on
			_flash_t = 0.0
			set_process(on or not _idle.is_empty())
		queue_redraw()


## 흰빛 겹: 그림과 같은 자리·뒤집기로 흰 실루엣(target_flash). 세기는 render.json ui.combat_target_flash {min, max, hz}.
func _ensure_flash() -> void:
	if _flash != null:
		return
	_flash = TextureRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_flash.stretch_mode = TextureRect.STRETCH_SCALE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/target_flash.gdshader") as Shader
	_flash.material = mat
	add_child(_flash)
	move_child(_flash, 0)  # 이름·상태 아이콘보다 아래


func _process(delta: float) -> void:
	if not _idle.is_empty():
		_idle_t += delta
		_tick_idle()
	if _flash == null or not _flash.visible:
		set_process(not _idle.is_empty())
		return
	_flash_t += delta
	var cfg := UiTheme.ui_dict("combat_target_flash")
	var lo := JsonUtil.get_float(cfg, "min", 0.18)
	var hi := JsonUtil.get_float(cfg, "max", 0.42)
	var k := 0.5 - 0.5 * cos(TAU * JsonUtil.get_float(cfg, "hz", 0.9) * _flash_t)
	(_flash.material as ShaderMaterial).set_shader_parameter("amount", lerpf(lo, hi, k))
	_flash.texture = art
	_flash.position = Vector2.ZERO
	_flash.size = size


func _draw() -> void:
	var glow := 0.55 if _current else 0.0  # 대상은 고리 대신 흰빛(_flash)
	if art != null:
		if front:  # 아군 발은 아래 창 뒤로 가라앉아 있다(차례는 밝기로)
			CombatFigure.ground(self, Vector2(size.x / 2.0, size.y), minf(size.x * 0.42, size.y * 0.5), size.y, glow)
		draw_texture_rect(art, Rect2(Vector2.ZERO, size), false, Color(1.12, 1.1, 1.05) if _current else Color.WHITE)
	else:
		var c := color.lightened(0.35 if _target else (0.12 if _current and not front else 0.0))  # 그림 없는 임시 도형: 대상이면 희게
		CombatFigure.paint(self, shape, c, front, Vector2(size.x / 2.0, size.y), size.y / 1.12, glow)


## 몸 위로 떠오르는 숫자/글자(피해 숫자): 크게 튀어나왔다가 잠깐 머문 뒤 위로 흐려진다. big = 피해 숫자(더 크게).
func float_text(text: String, col: Color, big: bool = false) -> void:
	var l := UiTheme.label(text, "header", "text")
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", UiTheme.metric("float_text_size" if big else "header_font_size", 34 if big else 20))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", UiTheme.metric("float_text_outline", 6))
	l.top_level = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var host: Node = get_parent() if get_parent() != null else self  # 무대에 단다 — 쓰러져 몸이 치워져도 숫자는 끝까지 보인다
	host.add_child(l)
	l.z_index = 10  # 쓰러진 몬스터의 먼지(DeathDust z 5) 위에
	var ms := l.get_combined_minimum_size()
	var top := global_position.y + size.y * (0.22 if front else 0.12)  # 아군은 아래가 창 뒤로 가라앉아 있어 위쪽에
	l.position = Vector2(clampf(global_position.x + size.x * 0.5 - ms.x * 0.5, 4.0, get_viewport_rect().size.x - ms.x - 4.0), maxf(top, 8.0))
	l.pivot_offset = ms * 0.5
	l.scale = Vector2(1.5, 1.5)
	var sec := UiTheme.ui_float("float_text_sec", 1.3)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, sec * 0.15)
	tw.tween_interval(sec * 0.45)
	tw.tween_property(l, "position:y", l.position.y - 36, sec * 0.4)
	tw.parallel().tween_property(l, "modulate:a", 0.0, sec * 0.4)
	tw.tween_callback(l.queue_free)
