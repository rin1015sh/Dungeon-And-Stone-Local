class_name CombatantCard
extends PanelContainer
## 전투 무대의 참가자 하나: 도형(서로 마주 봄) · 이름 · 생명력 막대 · 상태이상.
## 현재 차례면 테두리를 강조하고, 피해를 입으면 숫자가 떠오른다. 쓰러지거나 도망치면 흐려진다.

var unit: Combatant

var _figure: _Figure
var _bar: ProgressBar
var _hp_label: Label
var _status: Label
var _normal_box: StyleBoxFlat
var _current_box: StyleBoxFlat


func setup(u: Combatant, db: GameDatabase) -> void:
	unit = u
	var r := UiTheme.metric("corner_radius", 2)
	var pad := UiTheme.metric("padding", 8)
	_normal_box = UiTheme.box(UiTheme.color("panel"), UiTheme.color("panel_border"), r, pad)
	_current_box = UiTheme.box(UiTheme.color("panel"), UiTheme.color("warn"), r, pad)
	_current_box.set_border_width_all(2)
	add_theme_stylebox_override("panel", _normal_box)
	custom_minimum_size.x = UiTheme.metric("combat_card_width", 150)
	var v := VBoxContainer.new()
	add_child(v)
	_figure = _Figure.new()
	_figure.custom_minimum_size = Vector2(0, UiTheme.metric("combat_figure_height", 110))
	var facing := Vector2i(1, 0) if u.side == Combatant.SIDE_PARTY else Vector2i(-1, 0)
	if u.actor is Monster:
		var def := (u.actor as Monster).def
		_figure.setup(JsonUtil.get_str(def, "shape", "humanoid"), JsonUtil.get_float(def, "size", 1.0),
			Color.from_string(JsonUtil.get_str(def, "color"), Color.GRAY), facing)
	elif u.actor is PlayerCharacter:
		var race := db.get_entry("races", (u.actor as PlayerCharacter).race_id)
		_figure.setup("humanoid", 1.0, Color.from_string(JsonUtil.get_str(race, "color"), Color.GRAY), facing)
	v.add_child(_figure)
	var name_label := UiTheme.label(u.label(), "body", "text_title")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_label)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size.y = UiTheme.metric("bar_height", 14)
	_bar.add_theme_stylebox_override("fill", UiTheme.box(db.resources["hp"].color, Color.TRANSPARENT, r, 0))
	v.add_child(_bar)
	_hp_label = UiTheme.label("", "small", "text_dim")
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_hp_label)
	_status = UiTheme.label("", "small", "warn")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_status)
	refresh()


func refresh() -> void:
	var pool := unit.actor.pool
	_bar.max_value = maxf(1.0, pool.get_max("hp"))
	_bar.value = pool.get_current("hp")
	_hp_label.text = "%d / %d" % [ceili(pool.get_current("hp")), roundi(pool.get_max("hp"))]
	var names := PackedStringArray()
	for id in unit.actor.statuses.ids():
		names.append(DataNames.entry(unit.actor.db, "statuses", id))
	_status.text = ", ".join(names)
	modulate.a = 1.0 if unit.is_active() else 0.35


func set_current(on: bool) -> void:
	add_theme_stylebox_override("panel", _current_box if on else _normal_box)


## 머리 위로 떠오르는 숫자/글자.
func float_text(text: String, color: Color) -> void:
	var l := UiTheme.label(text, "header", "text")
	l.add_theme_color_override("font_color", color)
	l.position = Vector2(size.x * 0.5 - 12, 10)
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 36, UiTheme.ui_float("float_text_sec", 0.8))
	tw.parallel().tween_property(l, "modulate:a", 0.0, UiTheme.ui_float("float_text_sec", 0.8))
	tw.tween_callback(l.queue_free)


class _Figure extends Control:
	var shape := "humanoid"
	var scale_k := 1.0
	var color := Color.GRAY
	var facing := Vector2i(1, 0)

	func setup(p_shape: String, p_scale: float, p_color: Color, p_facing: Vector2i) -> void:
		shape = p_shape
		scale_k = p_scale
		color = p_color
		facing = p_facing

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()  # 배치가 끝나 크기가 정해진 뒤 다시 그린다

	func _draw() -> void:
		var base := Transform2D(0.0, Vector2(1.8, 1.8), 0.0, Vector2(size.x * 0.5, size.y - 8))
		FigurePainter.paint(self, shape, scale_k, color, facing, false, false, base)
