class_name DataErrorScreen
extends Control
## 데이터 검증 실패 시 첫 화면. 오류 목록을 보여 주고 게임 진행을 막는다.

signal quit_requested


func _ready() -> void:
	var v := DataRegistry.validator
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UiTheme.metric("margin", 16)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, m)
	var col := VBoxContainer.new()
	margin.add_child(col)
	col.add_child(UiTheme.label(Strings.t("error.data_title"), "header", "bad"))
	col.add_child(UiTheme.label(Strings.t("error.count", {"errors": v.errors.size(), "warnings": v.warnings.size()}), "body", "text"))
	var hint := UiTheme.label(Strings.t("error.data_hint"), "small", "text_dim")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)
	var list := RichTextLabel.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.bbcode_enabled = false
	col.add_child(list)
	for e: String in v.errors:
		list.push_color(UiTheme.color("bad"))
		list.add_text(e)
		list.pop()
		list.newline()
	for w: String in v.warnings:
		list.push_color(UiTheme.color("warn"))
		list.add_text(w)
		list.pop()
		list.newline()
	var quit := UiTheme.button(Strings.t("menu.quit"), func() -> void: quit_requested.emit())
	quit.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.add_child(quit)
