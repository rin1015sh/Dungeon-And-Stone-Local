class_name PauseMenu
extends CenterContainer
## 일시정지 메뉴(탐험 화면 위): [계속] · [탐험 포기]. 떠 있는 동안 아래 화면의 마우스 입력을 막는다.
## 탐험 포기는 실수로 누르지 않게 한 번 더 눌러야 확정한다(abandon_requested).

signal resume_requested
signal abandon_requested

var _abandon: Button
var _armed: bool = false


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # 정지 중 하단 바·단축칸 클릭이 새어 나가지 않게
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	panel.add_child(v)
	v.add_child(UiTheme.label(Strings.t("explore.paused"), "header", "text_title"))
	v.add_child(UiTheme.label(Strings.t("explore.paused_hint", {"key": InputSetup.key_label("pause")}), "small", "text_dim"))
	var resume := UiTheme.button(Strings.t("pause.resume"), func() -> void: resume_requested.emit())
	resume.focus_mode = Control.FOCUS_NONE
	v.add_child(resume)
	_abandon = UiTheme.button(Strings.t("pause.abandon"), _on_abandon)
	_abandon.focus_mode = Control.FOCUS_NONE
	v.add_child(_abandon)


func show_menu(on: bool) -> void:
	visible = on
	_armed = false
	_abandon.text = Strings.t("pause.abandon")


func _on_abandon() -> void:
	if not _armed:
		_armed = true
		_abandon.text = Strings.t("pause.abandon_confirm")
		return
	abandon_requested.emit()
