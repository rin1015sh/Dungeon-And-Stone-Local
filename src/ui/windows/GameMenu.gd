class_name GameMenu
extends Control
## Tab 메뉴(사용자 결정 2026-10-19 "I·C·B 창을 Tab 하나로 전부 보이게, 안에서 W/A/S/D로 고르고 Enter"):
## 화면을 어둡게 덮고 캐릭터 · 소지품 · 도감 세 쪽을 나란히 한 번에 보인다. 열면 소지품 쪽에 커서.
##   W/A/S/D = 지금 쪽 안의 커서(쪽 끝에서 A/D = 옆 쪽으로), Enter = 고르기, Backspace = 쪽 안에서 물리기(없으면 닫기), Tab·Esc = 닫기.
## 열려 있으면 opened_changed(true) — 탐험 화면이 시간을 멈춘다(메뉴 규칙). 키는 모두 이 메뉴가 먹는다.
## hold가 참이면(위에 떠 있는 대화창 등) 키를 받지 않고 지나보낸다.

signal opened_changed(open: bool)
signal use_requested(item_id: String)

const PAGES := ["character", "inventory", "bestiary"]

var pc: PlayerCharacter
## 참이면 메뉴가 키를 받지 않는다(대화창이 알림을 넘기는 중 등).
var hold: Callable = Callable()

var _pages: Dictionary = {}  # 이름 -> MenuPage
var _active: String = ""


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_open() -> bool:
	return not _pages.is_empty()


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func open(start: String = "inventory") -> void:
	if is_open():
		focus(start)
		return
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.color("bg"), MenuPage.cfg("dim", 0.6))
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(MenuPage.cfg("page_gap", 12.0)))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	var m := float(UiTheme.metric("margin", 16))
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = m
	row.offset_right = -m
	row.offset_top = m
	row.offset_bottom = -m
	for name: String in PAGES:
		var p := _make(name)
		p.popup_host = self
		p.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(p)
		_pages[name] = p
	_active = ""
	focus.call_deferred(start)  # 자리가 잡힌 뒤 커서를 그린다(설명 창 위치)
	opened_changed.emit(true)


func close() -> void:
	if not is_open():
		return
	for c in get_children():
		c.queue_free()
	_pages.clear()
	_active = ""
	opened_changed.emit(false)


## 쪽을 고른다(커서를 그 쪽으로).
func focus(name: String, from_left: bool = true) -> void:
	if not _pages.has(name) or name == _active:
		return
	if _pages.has(_active):
		(_pages[_active] as MenuPage).active = false
	_active = name
	var p := _pages[name] as MenuPage
	p.enter(from_left)
	p.active = true


func active_page() -> String:
	return _active


func page(name: String) -> MenuPage:
	return _pages.get(name)


func inventory() -> InventoryPage:
	return _pages.get("inventory") as InventoryPage


func character() -> CharacterPage:
	return _pages.get("character") as CharacterPage


func bestiary() -> BestiaryPage:
	return _pages.get("bestiary") as BestiaryPage


## 내용 갱신(아이템 사용 뒤 등).
func refresh() -> void:
	for p: MenuPage in _pages.values():
		p.refresh()


func _make(name: String) -> MenuPage:
	match name:
		"inventory":
			var inv := InventoryPage.new()
			inv.setup(pc)
			inv.use_requested.connect(func(id: String) -> void: use_requested.emit(id))
			return inv
		"character":
			var ch := CharacterPage.new()
			ch.setup(pc)
			return ch
	var be := BestiaryPage.new()
	be.setup(pc)
	return be


func _input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey or event is InputEventAction) or not event.is_pressed():
		return
	if hold.is_valid() and bool(hold.call()):
		return
	var p := _pages.get(_active) as MenuPage
	if p != null and p.busy():
		return
	get_viewport().set_input_as_handled()  # 열려 있는 동안 키는 모두 이 메뉴가 먹는다
	if event.is_action_pressed("menu") or event.is_action_pressed("pause"):
		close()
		return
	if p == null:
		return
	if event.is_action_pressed("menu_back"):
		if not p.back():
			close()
		return
	if event.is_action_pressed("menu_confirm"):
		p.confirm()
		return
	for a: Array in [["menu_up", Vector2i.UP], ["menu_down", Vector2i.DOWN], ["menu_left", Vector2i.LEFT], ["menu_right", Vector2i.RIGHT]]:
		if event.is_action_pressed(str(a[0]), true):
			var d: Vector2i = a[1]
			if not p.nav(d) and d.x != 0:
				var i := PAGES.find(_active) + d.x
				if i >= 0 and i < PAGES.size():
					focus(PAGES[i], d.x > 0)
			return
