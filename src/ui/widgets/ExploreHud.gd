class_name ExploreHud
extends MarginContainer
## 탐험 HUD(읽기 전용 표시).
##   좌상단: 층 이름 · 미궁 n일차 시각 · 폐쇄까지 남은 시간 · 빛/시야 · 안전지대 · 발견 현황
##   좌하단: 탐험가 · 자원 게이지 · 상태이상 · 소지품
##   맨 아래: 조작 안내(키는 data/input.json에서 읽는다)

var _session: ExploreSession
var _floor_label: Label
var _time_label: Label
var _light_label: Label
var _zone_label: Label
var _found_label: Label
var _name_label: Label
var _status_label: Label
var _items_label: Label
var _res_panel: ResourcePanel


func bind(session: ExploreSession) -> void:
	_session = session
	_build()
	session.time_passed.connect(func(_h: float) -> void: refresh())
	session.view_changed.connect(refresh)
	session.player.inventory.changed.connect(func(_id: String, _n: int) -> void: refresh())
	session.player.status_changed.connect(func(_id: String, _on: bool) -> void: refresh())
	refresh()


func refresh() -> void:
	var s := _session
	var pc := s.player
	_floor_label.text = s.floor_name()
	_time_label.text = Strings.t("explore.hud_time", {"day": s.clock.day(), "time": s.clock.hhmm(), "left": ceili(s.hours_until_close())})
	var vision := "%.1f" % s.vision_m
	match s.light_kind():
		"torch":
			_light_label.text = Strings.t("explore.light_torch", {"hours": ceili(pc.light.hours_left), "vision": vision})
		"ambient":
			_light_label.text = Strings.t("explore.light_ambient", {"vision": vision})
		_:
			_light_label.text = Strings.t("explore.light_dark", {"vision": vision})
	_zone_label.visible = s.in_safe_zone()
	_found_label.text = Strings.t("explore.hud_found", {
		"landmarks": s.found_count(s.map.landmarks), "landmarks_total": s.map.landmarks.size(),
		"portals": s.found_count(s.map.portals), "portals_total": s.map.portals.size()})
	_name_label.text = Strings.t("explore.hud_name", {"name": pc.display_name, "race": pc.race_name(),
		"template": pc.template_name(), "level": pc.get_level()})
	var statuses := PackedStringArray()
	for id in pc.statuses.ids():
		statuses.append(DataNames.entry(s.db, "statuses", id))
	_status_label.text = Strings.t("explore.hud_status", {"list": ", ".join(statuses)}) if not statuses.is_empty() \
		else Strings.t("explore.hud_status_none")
	_status_label.add_theme_color_override("font_color", UiTheme.color("warn" if not statuses.is_empty() else "text_dim"))
	var items := PackedStringArray()
	for id in pc.inventory.ids():
		items.append("%s %d" % [DataNames.entry(s.db, "items", id), pc.inventory.count(id)])
	_items_label.text = Strings.t("explore.hud_items", {"list": " · ".join(items)}) if not items.is_empty() \
		else Strings.t("explore.hud_items_none")


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
	_light_label = _add(top, UiTheme.label("", "small", "text"))
	_zone_label = _add(top, UiTheme.label(Strings.t("explore.hud_safe"), "small", "good"))
	_found_label = _add(top, UiTheme.label("", "small", "text_dim"))

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	var bottom := _panel(col)
	(bottom.get_parent() as Control).custom_minimum_size.x = UiTheme.metric("hud_panel_width", 360)
	_name_label = _add(bottom, UiTheme.label("", "body", "text_title"))
	_res_panel = ResourcePanel.new()
	bottom.add_child(_res_panel)
	_res_panel.bind(_session.player.pool)
	_status_label = _add(bottom, UiTheme.label("", "small"))
	_items_label = _add(bottom, UiTheme.label("", "small", "text_dim"))
	_items_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var keys := UiTheme.label(Strings.t("explore.keys", {
		"up": InputSetup.key_label("move_up"), "left": InputSetup.key_label("move_left"),
		"down": InputSetup.key_label("move_down"), "right": InputSetup.key_label("move_right"),
		"wait": InputSetup.key_label("wait"), "rest": InputSetup.key_label("rest"),
		"torch": InputSetup.key_label("torch"), "eat": InputSetup.key_label("eat"),
		"interact": InputSetup.key_label("interact"), "pause": InputSetup.key_label("pause"), "debug": InputSetup.key_label("debug_toggle")}), "small", "text_dim")
	col.add_child(keys)


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
