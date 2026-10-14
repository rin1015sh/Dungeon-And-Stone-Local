class_name CombatantCard
extends PanelContainer
## 전투 무대의 참가자 하나: 도형(서로 마주 봄) · 이름 · 생명력 막대 · 전투 게이지(공포 등, 0보다 클 때만) · 상태이상.
## 현재 차례면 테두리를 강조하고(행동창에서 대상으로 고르는 중이면 금색), 피해를 입으면 숫자가 떠오른다. 쓰러지거나 도망치면 흐려진다.
## 상태는 중첩(×n)·보호막 남은 양을 함께 보이고, 마우스를 올리면 설명. 폭은 CombatScreen이 참가자 수에 맞춰 줄인다(set_width).

var unit: Combatant

var _figure: _Figure
var _bar: ProgressBar
var _hp_label: Label
var _status: Label
var _meters: RichTextLabel
var _normal_box: StyleBoxFlat
var _current_box: StyleBoxFlat
var _target_box: StyleBoxFlat
var _name: Label
var _is_current: bool = false
var _is_target: bool = false


func setup(u: Combatant, db: GameDatabase) -> void:
	unit = u
	var r := UiTheme.metric("corner_radius", 2)
	var pad := UiTheme.metric("padding", 8)
	_normal_box = UiTheme.box(UiTheme.color("panel"), UiTheme.color("panel_border"), r, pad)
	_current_box = UiTheme.box(UiTheme.color("panel"), UiTheme.color("warn"), r, pad)
	_current_box.set_border_width_all(2)
	_target_box = UiTheme.box(UiTheme.color("slot_hover"), UiTheme.color("gold"), r, pad)
	_target_box.set_border_width_all(3)
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
	_name = UiTheme.label(u.label(), "body", "text_title")
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.tooltip_text = u.label()
	_name.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(_name)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size.y = UiTheme.metric("bar_height", 14)
	_bar.add_theme_stylebox_override("fill", UiTheme.box(db.resources["hp"].color, Color.TRANSPARENT, r, 0))
	v.add_child(_bar)
	_hp_label = UiTheme.label("", "small", "text_dim")
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_hp_label)
	_meters = RichTextLabel.new()
	_meters.bbcode_enabled = true
	_meters.fit_content = true
	_meters.scroll_active = false
	_meters.add_theme_font_size_override("normal_font_size", UiTheme.metric("small_font_size", UiTheme.metric("font_size", 16)))
	_meters.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_meters)
	_status = UiTheme.label("", "small", "warn")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.mouse_filter = Control.MOUSE_FILTER_PASS  # 마우스를 올리면 상태 설명
	_status.max_lines_visible = UiTheme.metric("combat_card_status_lines", 3)  # 상태가 많아도 카드가 아래 칸을 밀지 않게
	v.add_child(_status)
	refresh()


func refresh() -> void:
	var pool := unit.actor.pool
	_bar.max_value = maxf(1.0, pool.get_max("hp"))
	_bar.value = pool.get_current("hp")
	_hp_label.text = "%d / %d" % [ceili(pool.get_current("hp")), roundi(pool.get_max("hp"))]
	var parts := PackedStringArray()
	for m: Dictionary in Meters.list(unit.actor.db, unit.actor):
		parts.append("[color=%s]%s %d/%d[/color]" % [str(m["color"]), str(m["name"]), roundi(float(m["value"])), roundi(float(m["max"]))])
	_meters.text = " · ".join(parts)
	_meters.visible = not parts.is_empty()
	var names := PackedStringArray()
	var st := unit.actor.statuses
	for id in st.ids():
		var n := DataNames.entry(unit.actor.db, "statuses", id)
		if st.stacks(id) > 1:
			n += Strings.t("combat.card_stacks", {"n": st.stacks(id)})
		if st.barrier_of(id) > 0.0:
			n += Strings.t("combat.card_barrier", {"n": roundi(st.barrier_of(id))})
		names.append(n)
	_status.text = ", ".join(names)
	_status.tooltip_text = StatusTips.lines(unit.actor.db, unit.actor.statuses.ids())
	modulate.a = 1.0 if unit.is_active() else 0.35


func set_current(on: bool) -> void:
	_is_current = on
	_apply_box()


## 행동창에서 이 참가자를 대상으로 고르는 중(커서가 올라가 있음).
func set_targeted(on: bool) -> void:
	_is_target = on
	_apply_box()


func _apply_box() -> void:
	add_theme_stylebox_override("panel", _target_box if _is_target else (_current_box if _is_current else _normal_box))


func set_width(w: int) -> void:
	custom_minimum_size.x = w


## 머리 위로 떠오르는 숫자/글자(카드 가운데). 컨테이너 배치를 받지 않게 top_level로 띄운다.
func float_text(text: String, color: Color) -> void:
	var l := UiTheme.label(text, "header", "text")
	l.add_theme_color_override("font_color", color)
	l.top_level = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.position = global_position + Vector2(size.x * 0.5 - l.get_combined_minimum_size().x * 0.5, 10)
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
