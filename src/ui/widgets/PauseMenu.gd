class_name PauseMenu
extends CenterContainer
## 일시정지 메뉴(탐험 화면 위): [계속] · [그래픽 높음/낮음] · [탐험 포기]. 떠 있는 동안 아래 화면의 마우스 입력을 막는다.
## 탐험 포기는 실수로 누르지 않게 한 번 더 눌러야 확정한다(abandon_requested).
## 키: 열리면 [계속]에 포커스 — 방향키로 옮기고 Enter로 고른다(취소 Backspace = 계속은 ExploreScreen이 받는다).

signal resume_requested
signal abandon_requested
signal quality_changed(quality: String)  ## GraphicsSettings에 이미 저장된 뒤

var _resume: Button
var _abandon: Button
var _graphics: Button
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
	_resume = UiTheme.button(Strings.t("pause.resume"), func() -> void: resume_requested.emit())
	v.add_child(_resume)
	_graphics = UiTheme.button(_graphics_text(), _on_graphics)
	v.add_child(_graphics)
	_abandon = UiTheme.button(Strings.t("pause.abandon"), _on_abandon)
	v.add_child(_abandon)


func show_menu(on: bool) -> void:
	visible = on
	_armed = false
	_abandon.text = Strings.t("pause.abandon")
	if on:
		_resume.grab_focus.call_deferred()
	else:
		for b: Button in [_resume, _graphics, _abandon]:
			if b.has_focus():
				b.release_focus()


func _on_abandon() -> void:
	if not _armed:
		_armed = true
		_abandon.text = Strings.t("pause.abandon_confirm")
		return
	abandon_requested.emit()


func _on_graphics() -> void:
	var q := GraphicsSettings.toggle()
	_graphics.text = _graphics_text()
	quality_changed.emit(q)


func _graphics_text() -> String:
	return Strings.t("pause.graphics", {"quality": Strings.t("pause.quality_" + GraphicsSettings.quality())})
