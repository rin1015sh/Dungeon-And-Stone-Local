class_name CityScreen
extends Control
## 도시 화면(라비기온 구역): 횡스크롤 거리(CityStreet) ↔ 시설 내부(FacilityView), 귀퉁이 정보 카드(CityHud — 달력·탐험가·메뉴).
## 시설을 고르면 행동력(facility_entry_cost)을 쓰고 들어간다. 나오면 행동력이 0일 때 다음 순으로 넘어간다.
## 새 게임 시작 후·미궁 귀환 후 모두 이 화면으로 온다. 하순에 행동력을 다 쓰고 거리로 나오면 미궁으로 떠난다(dungeon_requested).
## 시설 안에서 활동을 한 번 하면 저절로 거리로 나오고, 결과는 화면 위 알림 카드에 남는다.
## 창(소지품 I·캐릭터 C·도감 B)과 디버그 패널(F1)을 쓸 수 있다.

signal dungeon_requested
signal title_requested

var state: CityState
var pc: PlayerCharacter
var _registry: ScriptRegistry
var _street: CityStreet
var _facility: FacilityView
var _hud: CityHud
var _toast: Label
var _toast_box: PanelContainer
var _toast_timer: Timer
var _windows: WindowManager
var _debug: CityDebugPanel


func setup(p_state: CityState, p_pc: PlayerCharacter, registry: ScriptRegistry) -> void:
	state = p_state
	pc = p_pc
	_registry = registry


func _ready() -> void:
	_street = CityStreet.new()
	_street.setup(state)
	_street.facility_chosen.connect(choose_facility)
	add_child(_street)
	_street.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UiTheme.metric("margin", 16)
	_toast_box = CityUi.card()
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.visible = false
	add_child(_toast_box)
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, m)
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast = CityUi.label("", "body", "bone")
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.custom_minimum_size.x = UiTheme.render_float("city.toast_width", 420.0)
	_toast_box.add_child(_toast)
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(func() -> void: _toast_box.visible = false)
	add_child(_toast_timer)
	_hud = CityHud.new()
	_hud.setup(state, pc)
	_hud.title_requested.connect(func() -> void: title_requested.emit())
	_hud.window_requested.connect(func(kind: String) -> void: _windows.toggle(kind))
	add_child(_hud)
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	move_child(_toast_box, -1)
	_windows = WindowManager.new()
	_windows.setup(pc)
	_windows.use_requested.connect(use_item)
	add_child(_windows)
	_windows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_debug = CityDebugPanel.new()
	_debug.setup(state, pc)
	_debug.dungeon_requested.connect(func() -> void: dungeon_requested.emit())
	_debug.visible = false
	add_child(_debug)
	_debug.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_debug.offset_left = m
	_debug.offset_right = m + UiTheme.render_float("city.debug_width", 420.0)
	_debug.offset_top = UiTheme.render_float("city.hud_height", 104.0) + m
	state.period_started.connect(_on_period_started)
	state.expedition_due.connect(_on_expedition_due)
	state.advance_if_spent.call_deferred()  # 행동력이 0인 채로 왔으면 바로 다음 순(하순이면 미궁으로)


func street() -> CityStreet:
	return _street


func facility_view() -> FacilityView:
	return _facility


func debug_panel() -> CityDebugPanel:
	return _debug


func is_debug_open() -> bool:
	return _debug.visible


## 거리에서 시설을 고른다: 행동력을 쓰고 내부로. 못 들어가면 안내.
func choose_facility(id: String) -> void:
	if _facility != null:
		return
	var why := state.enter_facility(id)
	if not why.is_empty():
		toast(Strings.t(why))
		return
	_facility = FacilityView.new()
	_facility.setup(state, pc, _registry, id)
	_facility.leave_requested.connect(leave_facility)
	_windows.close_all()  # 시설 안에서는 소지품·캐릭터 창을 쓰지 않는다
	_hud.set_facility_mode(true)
	add_child(_facility)
	move_child(_facility, _street.get_index() + 1)
	_facility.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_street.visible = false
	toast("")


func leave_facility() -> void:
	if _facility == null:
		return
	toast("\n".join(_facility.summary()))
	_facility.queue_free()
	_facility = null
	_street.visible = true
	_hud.set_facility_mode(false)
	state.leave_facility()
	_street.refresh()


func _on_period_started(_month: int, _period: int) -> void:
	var msg := Strings.t("city.period_started", {"date": CityHud.date_text(state), "ap": state.ap})
	toast(msg if _toast.text.is_empty() else _toast.text + "\n" + msg)


## 하순이 끝났다: 미궁으로 떠난다(미궁 기록 첫 줄에 남긴다).
func _on_expedition_due() -> void:
	LogPanel.history.append({"text": Strings.t("city.expedition_auto", {"date": CityHud.date_text(state)}), "kind": "info"})
	dungeon_requested.emit()


## 거리에서 소지품 쓰기(city.json item_use.categories 분류만 — 포션 등). 결과는 위 알림으로.
func use_item(item_id: String) -> void:
	if _facility != null:
		return
	var db := state.db
	var cats := JsonUtil.get_array(CityValues.city_section(db, state.overrides, "item_use"), "categories")
	if not JsonUtil.get_str(db.get_entry("items", item_id), "category") in cats:
		toast(Strings.t("city.cannot_use_here"))
		return
	var ctx := ItemUser.use(DataRegistry.registries.effects, pc, item_id, state.rng)
	if ctx == null:
		return
	var lines := PackedStringArray()
	for m: Dictionary in ctx.messages:
		lines.append(Strings.t(str(m["key"]), m["args"]))
	if lines.is_empty():
		lines.append(Strings.t("city.item_no_effect", {"item": DataNames.entry(db, "items", item_id)}))
	toast("\n".join(lines))
	_windows.refresh()
	_hud.refresh()


## 화면 위 알림 카드(활동 결과·순 넘김·못 들어가는 이유). 빈 글이면 숨긴다. 몇 초 뒤 저절로 사라진다.
func toast(text: String) -> void:
	_toast.text = text
	_toast_box.visible = not text.is_empty()
	_toast_box.reset_size()
	_toast_box.offset_left = -_toast_box.size.x / 2.0
	_toast_box.offset_right = _toast_box.size.x / 2.0
	if _toast_box.visible:
		_toast_timer.start(UiTheme.render_float("city.toast_seconds", 7.0))


func windows_open() -> bool:
	return _windows.any_open()


func toast_text() -> String:
	return _toast.text


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_debug.visible = not _debug.visible
		get_viewport().set_input_as_handled()
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	for kind: String in WindowManager.KINDS:
		if event.is_action_pressed(kind) and _facility == null:
			_windows.toggle(kind)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause") or event.is_action_pressed("menu_back"):  # Esc·취소(Backspace): 시설에서 나가기 · 창 닫기
		if _facility != null:
			_facility.try_leave()
		elif _windows.any_open():
			for kind: String in WindowManager.KINDS:
				_windows.close(kind)
		get_viewport().set_input_as_handled()
