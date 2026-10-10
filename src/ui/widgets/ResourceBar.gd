class_name ResourceBar
extends HBoxContainer
## 자원 게이지 한 줄: 이름 · 막대 · 수치.

var _def: ResourceDef
var _bar: ProgressBar
var _value_label: Label


func setup(def: ResourceDef) -> void:
	_def = def
	var name_label := UiTheme.label(def.name_ko)
	name_label.custom_minimum_size.x = UiTheme.metric("bar_label_width", 72)
	add_child(name_label)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.custom_minimum_size.y = UiTheme.metric("bar_height", 14)
	_bar.add_theme_stylebox_override("fill", UiTheme.box(def.color, Color.TRANSPARENT, UiTheme.metric("corner_radius", 2), 0))
	add_child(_bar)
	_value_label = UiTheme.label("", "small")
	_value_label.custom_minimum_size.x = UiTheme.metric("bar_value_width", 104)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_value_label)


func set_values(current: float, maximum: float) -> void:
	_bar.max_value = maxf(maximum, 0.001)
	_bar.value = (maximum - current) if _def.display_inverted else current
	# 0과 1 사이 값은 1로 보여 준다(살아 있는데 0으로 보이지 않게).
	var shown := ceilf(current) if current > 0.0 else 0.0
	_value_label.text = "%s / %s" % [UiTheme.num(shown), UiTheme.num(maximum)]
