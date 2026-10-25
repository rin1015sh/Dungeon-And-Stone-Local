class_name ExploreHud
extends MarginContainer
## 탐험 HUD(읽기 전용 표시, 스톤샤드의 퀘스트 표시처럼 왼쪽 위에 작게).
##   층 이름 · 미궁 n일차 시각 · 폐쇄까지 남은 시간 · 피로도(도시와 공용) · 빛/시야 · 안전지대 · 발견 현황 · 조작 안내(키는 data/input.json)
## 자원(생명력·영혼력·허기·피로)은 Tab 메뉴 왼쪽 쪽(PartyPage — 하단 바는 없앴다, UI26), 소지품도 Tab 메뉴(GameMenu).

var _session: ExploreSession
var _floor_label: Label
var _time_label: Label
var _fatigue_label: Label
var _light_label: Label
var _zone_label: Label
var _found_label: Label
var _interact_label: Label


func bind(session: ExploreSession) -> void:
	_session = session
	_build()
	session.time_passed.connect(func(_h: float) -> void: refresh())
	session.view_changed.connect(refresh)
	session.moved.connect(func(_a: Vector2i, _b: Vector2i) -> void: refresh())
	session.message.connect(func(_k: String, _a: Dictionary, _kind: String) -> void: refresh())
	session.player.fatigue.changed.connect(func(_v: float, _d: float, _s: String) -> void: refresh())
	refresh()


func refresh() -> void:
	var s := _session
	var pc := s.player
	_floor_label.text = s.floor_name()
	_time_label.text = Strings.t("explore.hud_time", {"day": s.clock.day(), "time": s.clock.hhmm(), "left": ceili(s.hours_until_close())})
	_fatigue_label.text = Strings.t("explore.hud_fatigue", {"value": CityContext.fmt(pc.fatigue.value)})
	var vision := "%.1f" % s.vision_m
	match s.light_kind():
		"torch":
			_light_label.text = Strings.t("explore.light_torch", {"hours": ceili(pc.light.hours_left), "vision": vision})
		"ambient":
			_light_label.text = Strings.t("explore.light_ambient", {"vision": vision})
		_:
			_light_label.text = Strings.t("explore.light_dark", {"vision": vision})
	_zone_label.visible = s.in_safe_zone()
	var target := ExploreInteract.target_name(s)
	_interact_label.visible = not target.is_empty()
	_interact_label.text = Strings.t("explore.hud_interact", {"key": InputSetup.key_label("interact"), "target": target})
	_found_label.text = Strings.t("explore.hud_found", {
		"landmarks": s.found_count(s.map.landmarks), "landmarks_total": s.map.landmarks.size(),
		"portals": s.found_count(s.map.portals), "portals_total": s.map.portals.size()})


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := UiTheme.metric("margin", 16)
	for side: String in ["left", "right", "top", "bottom"]:
		add_theme_constant_override("margin_" + side, m)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	var top := _panel(col)
	_floor_label = _add(top, UiTheme.label("", "header", "text_title"))
	_time_label = _add(top, UiTheme.label(""))
	_fatigue_label = _add(top, UiTheme.label("", "small", "text"))
	_light_label = _add(top, UiTheme.label("", "small", "text"))
	_zone_label = _add(top, UiTheme.label(Strings.t("explore.hud_safe"), "small", "good"))
	_found_label = _add(top, UiTheme.label("", "small", "text_dim"))
	_interact_label = _add(top, UiTheme.label("", "small", "text_title"))



## 반투명 패널 + 내용 상자. 내용 상자(VBox)를 돌려준다.
func _panel(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.metric("spacing", 8) / 2)
	panel.add_child(v)
	return v


func _add(parent: Control, l: Label) -> Label:
	parent.add_child(l)
	return l
