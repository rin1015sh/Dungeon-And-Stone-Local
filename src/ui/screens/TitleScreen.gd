class_name TitleScreen
extends Control
## 타이틀 화면. 새 탐험가 / 기반 점검(개발용) / 종료.

signal new_game_requested
signal foundation_requested
signal quit_requested


func _ready() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.metric("spacing", 8) * 2)
	center.add_child(v)

	var title := UiTheme.label(Strings.t("app.title"), "title", "text_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var subtitle := UiTheme.label(Strings.t("app.subtitle"), "subtitle", "text_dim")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(subtitle)

	var menu := VBoxContainer.new()
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.custom_minimum_size.x = UiTheme.metric("menu_button_width", 260)
	v.add_child(menu)
	var new_game := UiTheme.button(Strings.t("menu.new_game"), _on_new_game)
	menu.add_child(new_game)
	menu.add_child(UiTheme.button(Strings.t("menu.foundation"), _on_foundation))
	menu.add_child(UiTheme.button(Strings.t("menu.quit"), _on_quit))
	new_game.grab_focus.call_deferred()

	var footer := UiTheme.label(Strings.t("app.build"), "small", "text_dim")
	add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, UiTheme.metric("margin", 16))


func _on_new_game() -> void:
	AudioBus.play_sfx("ui_click")
	new_game_requested.emit()


func _on_foundation() -> void:
	AudioBus.play_sfx("ui_click")
	foundation_requested.emit()


func _on_quit() -> void:
	AudioBus.play_sfx("ui_back")
	quit_requested.emit()
