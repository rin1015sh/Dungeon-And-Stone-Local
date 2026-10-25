class_name GameMenu
extends Control
## Tab 메뉴(사용자 결정 2026-10-19 "I·C·B 창을 Tab 하나로 전부 보이게, 안에서 W/A/S/D로 고르고 Enter" →
## 2026-10-25 UI26 "왼쪽 = 어느 아군을 볼지(W/S·Enter), 가운데 = 그 아군 정보·정수, 오른쪽 = 그 아군 장비 + 공용 가방"):
## 화면을 어둡게 덮고 아군(PartyPage — 짧은 생명력·영혼력·허기·피로, 맨 끝에 도감) · 캐릭터 · 소지품 세 쪽을 나란히 보인다.
## 왼쪽에서 도감을 고르면 가운데·오른쪽 대신 도감 쪽. 열면 소지품 쪽에 커서.
##   W/A/S/D = 지금 쪽 안의 커서(쪽 끝에서 A/D = 옆 쪽으로), Enter = 고르기, Backspace = 쪽 안에서 물리기(없으면 닫기), Tab·Esc = 닫기.
## 열려 있으면 opened_changed(true) — 탐험 화면이 시간을 멈춘다(메뉴 규칙). 키는 모두 이 메뉴가 먹는다.
## hold가 참이면(위에 떠 있는 대화창 등) 키를 받지 않고 지나보낸다.

signal opened_changed(open: bool)
signal use_requested(item_id: String)

const PAGES := ["party", "character", "inventory", "bestiary"]

var pc: PlayerCharacter  ## 플레이어(공용 가방의 주인)
var party: Array[PlayerCharacter] = []
var _shown: PlayerCharacter = null  ## 가운데·오른쪽에 보이는 아군
var _bestiary_mode: bool = false
## 참이면 메뉴가 키를 받지 않는다(대화창이 알림을 넘기는 중 등).
var hold: Callable = Callable()

var _pages: Dictionary = {}  # 이름 -> MenuPage
var _active: String = ""


func setup(p_pc: PlayerCharacter, p_party: Array[PlayerCharacter] = []) -> void:
	pc = p_pc
	party = p_party if not p_party.is_empty() else ([p_pc] as Array[PlayerCharacter])
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
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # 쪽들이 가로로 늘어나 화면을 채운다(render.json ui.menu.stretch — 사용자 2026-10-25)
	add_child(row)
	var m := float(UiTheme.metric("margin", 16))
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = m
	row.offset_right = -m
	row.offset_top = m
	row.offset_bottom = -m
	_shown = pc if _shown == null or not party.has(_shown) else _shown
	_bestiary_mode = start == "bestiary"
	for name: String in PAGES:
		var p := _make(name)
		p.popup_host = self
		p.size_flags_vertical = Control.SIZE_EXPAND_FILL
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.size_flags_stretch_ratio = JsonUtil.get_float(JsonUtil.get_dict(UiTheme.ui_dict("menu"), "stretch"), name, 1.0)
		row.add_child(p)
		_pages[name] = p
	party_page().selected = party.find(_shown) if not _bestiary_mode else party.size()
	_apply_mode()
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
	if name == "bestiary" and not _bestiary_mode and _pages.has(name):
		_bestiary_mode = true
		_apply_mode()
	elif (name == "character" or name == "inventory") and _bestiary_mode:
		_bestiary_mode = false
		_apply_mode()
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


func party_page() -> PartyPage:
	return _pages.get("party") as PartyPage


## 가운데·오른쪽에 보이는 아군.
func shown() -> PlayerCharacter:
	return _shown


## 왼쪽에서 아군을 골랐다: 가운데(정보·정수)·오른쪽(장비)을 그 아군으로. 가방은 공용 그대로.
func show_ally(a: PlayerCharacter) -> void:
	_shown = a
	party_page().mark(party.find(a))
	character().set_actor(a)
	inventory().set_wearer(a)
	_bestiary_mode = false
	_apply_mode()


func show_bestiary() -> void:
	party_page().mark(party.size())
	_bestiary_mode = true
	_apply_mode()
	focus("bestiary")


## 지금 보이는 쪽 순서(A/D로 옮겨 다니는 차례).
func order() -> Array[String]:
	var out: Array[String] = ["party"]
	out.append_array(["bestiary"] if _bestiary_mode else ["character", "inventory"])
	return out


func _apply_mode() -> void:
	for name: String in PAGES:
		(_pages[name] as Control).visible = order().has(name)


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
		"party":
			var pp := PartyPage.new()
			pp.setup(party)
			pp.ally_selected.connect(show_ally)
			pp.bestiary_requested.connect(show_bestiary)
			return pp
		"inventory":
			var inv := InventoryPage.new()
			inv.setup(pc)
			inv.set_wearer(_shown)
			inv.use_requested.connect(func(id: String) -> void: use_requested.emit(id))
			return inv
		"character":
			var ch := CharacterPage.new()
			ch.setup(_shown)
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
				var ord := order()
				var i := ord.find(_active) + d.x
				if i >= 0 and i < ord.size():
					focus(ord[i], d.x > 0)
			return
