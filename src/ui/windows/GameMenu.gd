class_name GameMenu
extends Control
## Tab 메뉴(사용자 결정 2026-10-19 "I·C·B 창을 Tab 하나로 전부 보이게, 안에서 W/A/S/D로 고르고 Enter" →
## 2026-10-25 UI26 "왼쪽 = 어느 아군을 볼지(W/S·Enter), 가운데 = 그 아군 정보·정수, 오른쪽 = 그 아군 장비 + 공용 가방"):
## 화면을 어둡게 덮고 아군(PartyPage — 짧은 생명력·영혼력·허기·피로) · 캐릭터 · 소지품 세 쪽을 나란히 보인다. 열면 소지품 쪽에 커서.
## 도감은 따로 B(CodexMenu — 사용자 2026-10-27, UI32).
## 아군 목록은 전위가 위·후위가 아래(사용자 2026-10-25). 고른 아군에서 Enter 한 번 더 = 전위/후위/파티에서 내보내기(한 번 더 묻는다).
##   W/A/S/D = 지금 쪽 안의 커서(쪽 끝에서 A/D = 옆 쪽으로), Enter = 고르기, Esc = 쪽 안에서 물리기(없으면 닫기), Tab = 닫기.
## 열려 있으면 opened_changed(true) — 탐험 화면이 시간을 멈춘다(메뉴 규칙). 키는 모두 이 메뉴가 먹는다.
## hold가 참이면(위에 떠 있는 대화창 등) 키를 받지 않고 지나보낸다.

signal opened_changed(open: bool)
signal use_requested(item_id: String)
signal party_changed  ## 줄이 바뀌거나 동료를 내보냈다

const PAGES := ["party", "character", "inventory"]

var pc: PlayerCharacter  ## 플레이어(공용 가방의 주인)
var party: Array[PlayerCharacter] = []
var _shown: PlayerCharacter = null  ## 가운데·오른쪽에 보이는 아군
## 참이면 메뉴가 키를 받지 않는다(대화창이 알림을 넘기는 중 등).
var hold: Callable = Callable()

var _pages: Dictionary = {}  # 이름 -> MenuPage
var _active: String = ""


func setup(p_pc: PlayerCharacter, p_party: Array[PlayerCharacter] = []) -> void:
	pc = p_pc
	party = by_row(p_party if not p_party.is_empty() else ([p_pc] as Array[PlayerCharacter]))
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 전위 먼저, 같은 줄 안에서는 들어온 순서.
static func by_row(list: Array[PlayerCharacter]) -> Array[PlayerCharacter]:
	var out: Array[PlayerCharacter] = []
	for want: String in ["front", "back"]:
		for a in list:
			if a.get_row() == want:
				out.append(a)
	return out


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
	for name: String in PAGES:
		var p := _make(name)
		p.popup_host = self
		p.size_flags_vertical = Control.SIZE_EXPAND_FILL
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.size_flags_stretch_ratio = JsonUtil.get_float(JsonUtil.get_dict(UiTheme.ui_dict("menu"), "stretch"), name, 1.0)
		row.add_child(p)
		_pages[name] = p
	party_page().selected = party.find(_shown)
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


## 고른 아군 창: 전위 · 후위 · 파티에서 내보내기(플레이어는 못 내보낸다 — 내보내기는 한 번 더 묻는다).
func _ally_menu(a: PlayerCharacter) -> void:
	var pp := party_page()
	pp.asking = true
	var opts: Array[Dictionary] = [
		{"text": Strings.t("party.front"), "enabled": a.get_row() != "front"},
		{"text": Strings.t("party.back"), "enabled": a.get_row() != "back"},
		{"text": Strings.t("party.release"), "enabled": a != pc, "desc": Strings.t("party.no_release_self") if a == pc else ""},
	]
	var i: int = await ChoicePopup.ask(self, a.display_name, opts, true)
	if not is_open():
		return
	match i:
		0, 1:
			a.row = "front" if i == 0 else "back"
			_reorder(a)
		2:
			var yes: Array[Dictionary] = [{"text": Strings.t("party.release_yes")}, {"text": Strings.t("party.release_no")}]
			var j: int = await ChoicePopup.ask(self, Strings.t("party.release_ask", {"name": a.display_name}), yes, true)
			if not is_open():
				return
			if j == 0:
				GameState.release(a)
				party.erase(a)
				_reorder(pc)
				show_ally(pc)
	pp.asking = false


## 줄 순서로 다시 세우고 a를 고른 채로 목록을 다시 만든다.
func _reorder(a: PlayerCharacter) -> void:
	party = by_row(party)
	party_page().rebuild(party, party.find(a))
	party_changed.emit()


## 쪽 순서(A/D로 옮겨 다니는 차례).
func order() -> Array[String]:
	var out: Array[String] = []
	out.assign(PAGES)
	return out


func inventory() -> InventoryPage:
	return _pages.get("inventory") as InventoryPage


func character() -> CharacterPage:
	return _pages.get("character") as CharacterPage


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
			pp.ally_menu_requested.connect(_ally_menu)
			return pp
		"inventory":
			var inv := InventoryPage.new()
			inv.setup(pc)
			inv.set_wearer(_shown)
			inv.use_requested.connect(func(id: String) -> void: use_requested.emit(id))
			return inv
	var ch := CharacterPage.new()
	ch.setup(_shown)
	return ch


func _input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey or event is InputEventAction) or not event.is_pressed():
		return
	if hold.is_valid() and bool(hold.call()):
		return
	var p := _pages.get(_active) as MenuPage
	if p != null and p.busy():
		return
	get_viewport().set_input_as_handled()  # 열려 있는 동안 키는 모두 이 메뉴가 먹는다
	if event.is_action_pressed("pause") and p != null and p.back():
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("pause"):
		close()
		return
	if p == null:
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
