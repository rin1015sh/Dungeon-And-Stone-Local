extends Control
## 진입점(Main.tscn). 테마를 입히고, 데이터 검증 결과에 따라 첫 화면을 고른다.
## 화면 전환은 여기서만 한다: 화면은 시그널만 내보낸다.

var _screen: Control = null


func _ready() -> void:
	theme = UiTheme.build(DataRegistry.db.render)
	UiTheme.apply_global_font()
	var bg := ColorRect.new()
	bg.color = UiTheme.color("bg")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if DataRegistry.has_errors():
		var err := DataErrorScreen.new()
		err.quit_requested.connect(_quit)
		_show(err)
	else:
		_show_title()


func _show(screen: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _show_title() -> void:
	var t := TitleScreen.new()
	t.foundation_requested.connect(_show_foundation)
	t.quit_requested.connect(_quit)
	_show(t)


func _show_foundation() -> void:
	var f := FoundationScreen.new()
	f.back_requested.connect(_show_title)
	_show(f)


func _quit() -> void:
	get_tree().quit()
