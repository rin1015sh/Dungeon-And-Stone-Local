class_name CodexMenu
extends Control
## 도감 창(사용자 결정 2026-10-27 "도감은 tab 메뉴가 아니라 B로 볼 수 있게 분리", UI32): 화면을 덮고
## 왼쪽 = 몬스터 · 서적 분야(CodexIndexPage), 오른쪽 = 몬스터 도감(BestiaryPage) 또는 그 분야에서 읽은 대목(LorePage — 도서관, CT52).
##   W/S = 지금 쪽 안의 커서(왼쪽에서 옮기면 오른쪽이 바로 바뀐다), A/D·Enter = 쪽 옮기기, Backspace = 오른쪽이면 왼쪽으로(왼쪽이면 닫기),
##   B·Tab·Esc = 닫기. 열려 있으면 opened_changed(true) — 탐험 시간이 멈춘다. 키는 모두 이 창이 먹는다.

signal opened_changed(open: bool)

var pc: PlayerCharacter
var known: Array[String] = []  ## 읽은 서적 id(CityState.known_info)
## 참이면 키를 받지 않는다(대화창이 알림을 넘기는 중 등).
var hold: Callable = Callable()

var _row: HBoxContainer
var _index: CodexIndexPage
var _page: MenuPage
var _active: MenuPage


func setup(p_pc: PlayerCharacter, p_known: Array[String]) -> void:
	pc = p_pc
	known = p_known
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_open() -> bool:
	return _index != null


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func open(section: String = CodexIndexPage.MONSTERS) -> void:
	if is_open():
		return
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.color("bg"), MenuPage.cfg("dim", 0.6))
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", int(MenuPage.cfg("page_gap", 12.0)))
	add_child(_row)
	var m := float(UiTheme.metric("margin", 16))
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.offset_left = m
	_row.offset_right = -m
	_row.offset_top = m
	_row.offset_bottom = -m
	_index = CodexIndexPage.new()
	_index.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_index.setup(pc.db, known)
	_index.picked.connect(show_section)
	_row.add_child(_index)
	_index.select(section)
	show_section(_index.current())
	_focus(_index)
	opened_changed.emit(true)


func close() -> void:
	if not is_open():
		return
	for c in get_children():
		c.queue_free()
	_index = null
	_page = null
	_active = null
	opened_changed.emit(false)


## 오른쪽 쪽을 그 칸으로 바꾼다(몬스터 도감 또는 서적 분야).
func show_section(section: String) -> void:
	if _page != null:
		_row.remove_child(_page)
		_page.queue_free()
	if section == CodexIndexPage.MONSTERS:
		var be := BestiaryPage.new()
		be.setup(pc)
		_page = be
	else:
		var lp := LorePage.new(CityInfo.field_name(pc.db, section))
		lp.setup(pc.db, known, section)
		_page = lp
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.size_flags_stretch_ratio = MenuPage.cfg("codex_page_stretch", 3.0)
	_row.add_child(_page)


func page() -> MenuPage:
	return _page


func index() -> CodexIndexPage:
	return _index


func active_page() -> MenuPage:
	return _active


func _focus(p: MenuPage) -> void:
	if _active != null:
		_active.active = false
	_active = p
	p.enter(p == _page)
	p.active = true


func _input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey or event is InputEventAction) or not event.is_pressed():
		return
	if hold.is_valid() and bool(hold.call()):
		return
	get_viewport().set_input_as_handled()  # 열려 있는 동안 키는 모두 이 창이 먹는다
	if event.is_action_pressed("pause") and _active == _page:  # Esc: 오른쪽이면 왼쪽으로, 왼쪽이면 닫기
		_focus(_index)
		return
	if event.is_action_pressed("codex") or event.is_action_pressed("menu") or event.is_action_pressed("pause"):
		close()
		return
	if event.is_action_pressed("menu_confirm"):
		if _active == _index:
			_focus(_page)
		return
	for a: Array in [["menu_up", Vector2i.UP], ["menu_down", Vector2i.DOWN], ["menu_left", Vector2i.LEFT], ["menu_right", Vector2i.RIGHT]]:
		if event.is_action_pressed(str(a[0]), true):
			var d: Vector2i = a[1]
			if not _active.nav(d) and d.x != 0:
				_focus(_page if d.x > 0 else _index)
			return
