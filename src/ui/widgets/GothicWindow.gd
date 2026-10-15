class_name GothicWindow
extends PanelContainer
## 스톤샤드풍 창 틀: 돌판 테두리 + 머리 장식(고딕 아치 띠) + 가운데 이름판 + 오른쪽 위 닫기(✕).
## 내용은 content(VBox)에 넣는다. 닫기를 누르면 close_requested.

signal close_requested

var content: VBoxContainer
var _title: String = ""


func _init(title: String = "") -> void:
	_title = title
	add_theme_stylebox_override("panel", GothicStyle.frame_box())
	mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	add_child(v)
	var header := _Header.new()
	header.custom_minimum_size.y = UiTheme.metric("window_header_height", 92)
	v.add_child(header)
	var plaque := PanelContainer.new()
	plaque.add_theme_stylebox_override("panel", GothicStyle.plaque_box())
	plaque.add_child(UiTheme.label(_title, "body", "text_title"))
	header.add_child(plaque)
	plaque.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	plaque.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var close := UiTheme.button("×", func() -> void: close_requested.emit())
	close.focus_mode = Control.FOCUS_NONE
	close.tooltip_text = Strings.t("window.close")
	header.add_child(close)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	v.add_child(content)


func title() -> String:
	return _title


class _Header extends Control:
	func _draw() -> void:
		GothicStyle.draw_arches(self, Rect2(Vector2(0, 14), size - Vector2(0, 14)))
