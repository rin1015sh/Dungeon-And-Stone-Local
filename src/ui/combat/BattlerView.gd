class_name BattlerView
extends Control
## 전투 무대 위의 참가자 하나(CombatFigure로 그린 몸). 적은 정면 + 머리 위 이름·발밑 생명력 막대·상태,
## 아군은 뒷모습만(이름·생명력·영혼력은 아래 파티 창에). 지금 차례·대상으로 고르는 중이면 발밑 고리가 빛난다.
## 쓰러지거나 도망치면 흐려진다. 누르면 clicked(대상 고르기 중이면 그 대상을 고른다).

signal clicked(unit: Combatant)

var unit: Combatant
var shape: String = "humanoid"
var color: Color = Color.GRAY
var size_k: float = 1.0
var front: bool = true
var _current: bool = false
var _target: bool = false
var _name: Label
var _bar: ProgressBar
var _status: Label


func setup(u: Combatant, db: GameDatabase) -> void:
	unit = u
	front = u.side != Combatant.SIDE_PARTY
	if u.actor is Monster:
		var def := (u.actor as Monster).def
		shape = JsonUtil.get_str(def, "shape", "humanoid")
		size_k = JsonUtil.get_float(def, "size", 1.0)
		color = Color.from_string(JsonUtil.get_str(def, "color"), Color.GRAY)
	elif u.actor is PlayerCharacter:
		color = Color.from_string(JsonUtil.get_str(db.get_entry("races", (u.actor as PlayerCharacter).race_id), "color"), Color.GRAY)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not front:
		return
	_name = UiTheme.label(u.label(), "small", "text_title")
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.custom_minimum_size.y = UiTheme.metric("combat_enemy_bar_height", 6)
	_bar.add_theme_stylebox_override("fill", UiTheme.box(db.resources["hp"].color, Color.TRANSPARENT, 1, 0))
	_bar.add_theme_stylebox_override("background", UiTheme.box(Color(0, 0, 0, 0.6), Color.TRANSPARENT, 1, 0))
	add_child(_bar)
	_status = UiTheme.label("", "small", "warn")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.clip_text = true
	add_child(_status)


## 무대가 정한 자리: 발 위치 · 키. 이름은 머리 위, 막대·상태는 발밑.
func place(foot: Vector2, h: float) -> void:
	var w := CombatFigure.width_of(shape, h)
	size = Vector2(w, h * 1.12)
	position = foot - Vector2(w / 2.0, size.y)
	if front:
		var lw := maxf(w, UiTheme.metric("combat_enemy_label_width", 150))
		_name.size = Vector2(lw, 20)
		_name.position = Vector2((w - lw) / 2.0, size.y - h * CombatFigure.top_of(shape) - 26)
		_bar.size = Vector2(minf(w * 0.7, 160.0), _bar.custom_minimum_size.y)
		_bar.position = Vector2((w - _bar.size.x) / 2.0, size.y + 8)
		_status.size = Vector2(lw, 20)
		_status.position = Vector2((w - lw) / 2.0, size.y + 14)
	queue_redraw()


func refresh() -> void:
	if front:
		var pool := unit.actor.pool
		_bar.max_value = maxf(1.0, pool.get_max("hp"))
		_bar.value = pool.get_current("hp")
		var names := PackedStringArray()
		for id in unit.actor.statuses.ids():
			names.append(DataNames.entry(unit.actor.db, "statuses", id))
		_status.text = ", ".join(names)
		_status.tooltip_text = StatusTips.lines(unit.actor.db, unit.actor.statuses.ids())
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
	var c := color.lightened(0.12) if _current and not front else color
	CombatFigure.paint(self, shape, c, front, Vector2(size.x / 2.0, size.y), size.y / 1.12, glow)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(unit)
		accept_event()


## 몸 위로 떠오르는 숫자/글자.
func float_text(text: String, col: Color) -> void:
	var l := UiTheme.label(text, "header", "text")
	l.add_theme_color_override("font_color", col)
	l.top_level = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.position = global_position + Vector2(size.x * 0.5 - l.get_combined_minimum_size().x * 0.5, size.y * 0.25)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40, UiTheme.ui_float("float_text_sec", 0.8))
	tw.parallel().tween_property(l, "modulate:a", 0.0, UiTheme.ui_float("float_text_sec", 0.8))
	tw.tween_callback(l.queue_free)
