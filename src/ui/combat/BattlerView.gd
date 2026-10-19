class_name BattlerView
extends Control
## 전투 무대 위의 참가자 하나. 그림은 MonsterArt(없으면 CombatFigure 도형): 적은 정면 그림, 아군 소환수는 뒷모습(<id>_back),
## 탐험가는 종족 그림 — 뒷모습(back)과 비스듬히 돌아선 옆모습(side)을 무대가 자리에 따라 고른다(set_view, 오른쪽 자리는 좌우 반전).
## 적은 정면 + 머리 위 이름·발밑 상태(생명력은 보이지 않는다 — 피어 앤 헝거처럼, 받은 피해만 숫자로 떠오른다),
## 아군은 뒷모습만(이름·생명력·영혼력은 아래 파티 창에). 지금 차례·대상으로 고르는 중이면 발밑 고리가 빛난다.
## 쓰러지거나 도망치면 흐려진다.

var unit: Combatant
var shape: String = "humanoid"
var color: Color = Color.GRAY
var size_k: float = 1.0
var boss: bool = false  ## 보스 등급(render.json ui.combat_boss_ranks) — 크기와 상관없이 무대를 거의 채운다
var front: bool = true
var art: Texture2D = null  ## 몬스터 일러스트(없으면 null)
var flip: bool = false  ## 좌우 반전(오른쪽 자리의 옆모습이 무대 가운데를 보게)
var _art_body: float = 1.0  ## 그림 속 몸 높이 px
var _views := {}  ## 탐험가: "back"/"side" → [그림, 몸 높이]
var _current: bool = false
var _target: bool = false
var _name: Label
var _status: Label


func setup(u: Combatant, db: GameDatabase) -> void:
	unit = u
	front = u.side != Combatant.SIDE_PARTY
	if u.actor is Monster:
		var def := (u.actor as Monster).def
		shape = JsonUtil.get_str(def, "shape", "humanoid")
		size_k = JsonUtil.get_float(def, "size", 1.0)
		boss = UiTheme.render_array("ui.combat_boss_ranks").has(JsonUtil.get_str(def, "rank"))
		color = Color.from_string(JsonUtil.get_str(def, "color"), Color.GRAY)
		var art_id := (u.actor as Monster).monster_id + ("" if front else "_back")  # 아군 소환수는 뒷모습
		art = MonsterArt.texture(art_id)
		if art != null:
			_art_body = MonsterArt.body_height(art_id, art)
	elif u.actor is PlayerCharacter:
		var race := (u.actor as PlayerCharacter).race_id
		color = Color.from_string(JsonUtil.get_str(db.get_entry("races", race), "color"), Color.GRAY)
		for view: String in ["back", "side"]:
			var tex := MonsterArt.texture_in(MonsterArt.party_dir(), race + "_" + view)
			if tex != null:
				_views[view] = [tex, MonsterArt.body_height_in(MonsterArt.party_dir(), race + "_" + view, tex)]
		set_view(false, false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not front:
		return
	_name = UiTheme.label(u.label(), "small", "text_title")
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	_status = UiTheme.label("", "small", "warn")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.clip_text = true
	add_child(_status)


## 탐험가 그림 고르기: side면 옆모습(없으면 뒷모습), mirror면 좌우 반전(옆모습일 때만).
func set_view(side: bool, mirror: bool) -> void:
	var key := "side" if side and _views.has("side") else "back"
	if not _views.has(key):
		return
	art = _views[key][0]
	_art_body = _views[key][1]
	flip = mirror and key == "side"
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


## 무대가 정한 자리: 발 위치 · 키. 이름은 머리 위, 상태는 발밑.
func place(foot: Vector2, h: float) -> void:
	var w := width_for(h)
	size = Vector2(w, art.get_height() * h / _art_body if art != null else h * 1.12)
	position = foot - Vector2(w / 2.0, size.y)
	if front:
		var lw := maxf(w, UiTheme.metric("combat_enemy_label_width", 150))
		var top := h if art != null else h * CombatFigure.top_of(shape)
		_name.size = Vector2(lw, 20)
		_name.position = Vector2((w - lw) / 2.0, maxf(size.y - top - 26, 4.0 - position.y))  # 화면 위로 넘치는 큰 보스도 이름은 보이게
		_status.size = Vector2(lw, 20)
		_status.position = Vector2((w - lw) / 2.0, size.y + 8)
	queue_redraw()


func refresh() -> void:
	if front:
		var names := PackedStringArray()
		for id in unit.actor.statuses.ids():
			names.append(DataNames.entry(unit.actor.db, "statuses", id))
		_status.text = ", ".join(names)
	modulate.a = 1.0 if unit.is_active() else 0.3
	queue_redraw()


func set_current(on: bool) -> void:
	if _current != on:
		_current = on
		queue_redraw()


func set_targeted(on: bool) -> void:
	if _target != on:
		_target = on
		if _name != null:
			_name.add_theme_color_override("font_color", UiTheme.color("gold" if on else "text_title"))
		queue_redraw()


func _draw() -> void:
	var glow := 1.0 if _target else (0.55 if _current else 0.0)
	if art != null:
		if front:  # 아군 발은 아래 창 뒤로 가라앉아 있다(차례는 밝기로)
			CombatFigure.ground(self, Vector2(size.x / 2.0, size.y), minf(size.x * 0.42, size.y * 0.5), size.y, glow)
		if flip:
			draw_set_transform(Vector2(size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect(art, Rect2(Vector2.ZERO, size), false, Color(1.12, 1.1, 1.05) if _current else Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var c := color.lightened(0.12) if _current and not front else color
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
	add_child(l)
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
