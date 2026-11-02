class_name SkillBanner
extends PanelContainer
## 전투 무대 위쪽 가운데의 작은 알림창(피어 앤 헝거식 — 사용자 결정 2026-10-22, ASSUMPTIONS UI21): 어떤 스킬·아이템을 썼는지
## 이름만 잠깐 띄운다. 대화창과 달리 넘기지 않아도 되고 차례를 멈추지 않는다(쓴 사람은 무대에서 차례 표시로 보인다).
## 띄울 문구 키는 render.json ui.notice.banner(원래 키 → 알림창 문구 키), 떠 있는 시간·자리는 ui.combat_banner_*.
## 대상을 고르는 동안은 같은 창에 고른 대상 이름을 붙들어 둔다(hold → release — TargetPicker, 사용자 2026-11-02).

var _label: Label
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	_label = UiTheme.label("", "body", "text_title")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	modulate.a = 0.0
	visible = false


## 위쪽 가운데에 둔다(부모 = 전투 화면, 전체 크기).
func place_top() -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_left = 0.0
	offset_right = 0.0
	offset_top = UiTheme.metric("combat_banner_y", 20)


func show_text(text: String) -> void:
	_put(text, true)
	_tween = create_tween()
	_tween.tween_interval(UiTheme.ui_float("combat_banner_sec", 1.2))
	_tween.tween_property(self, "modulate:a", 0.0, UiTheme.ui_float("combat_banner_fade_sec", 0.3))
	_tween.tween_callback(func() -> void: visible = false)


## 대상 고르기: 사라지지 않고 떠 있다(release까지). ok = false면 흐리게(고를 수 없는 대상).
func hold(text: String, ok: bool = true) -> void:
	_put(text, ok)


func release() -> void:
	if _tween != null:
		_tween.kill()
	modulate.a = 0.0
	visible = false


func _put(text: String, ok: bool) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", UiTheme.color("text_title" if ok else "text_dim"))
	visible = true
	var w := get_combined_minimum_size().x  # 글 길이에 맞춰 가운데에
	offset_left = -w / 2.0
	offset_right = w / 2.0
	if _tween != null:
		_tween.kill()
	modulate.a = 1.0


func text() -> String:
	return _label.text if visible else ""
