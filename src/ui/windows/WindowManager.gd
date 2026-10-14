class_name WindowManager
extends Control
## 탐험 화면의 창(소지품·캐릭터·도감)을 열고 닫는다. 소지품은 오른쪽, 캐릭터는 왼쪽, 도감은 가운데.
## 창이 하나라도 열려 있으면 opened_changed(true) — 탐험 화면이 시간을 멈춘다(메뉴 규칙).

signal opened_changed(any_open: bool)
signal use_requested(item_id: String)

const KINDS := ["inventory", "character", "bestiary"]

var pc: PlayerCharacter
var now_hours: Callable = Callable()  ## 지금 게임 시각(캐릭터 창의 정수 남은 시간)

var _windows: Dictionary = {}  # 종류 -> GothicWindow


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_open(kind: String) -> bool:
	return _windows.has(kind)


func any_open() -> bool:
	return not _windows.is_empty()


func window(kind: String) -> GothicWindow:
	return _windows.get(kind)


func toggle(kind: String) -> void:
	if is_open(kind):
		close(kind)
	else:
		open(kind)


func open(kind: String) -> GothicWindow:
	if is_open(kind):
		return _windows[kind]
	var w: GothicWindow
	match kind:
		"inventory":
			var inv := InventoryWindow.new()
			inv.setup(pc)
			inv.use_requested.connect(func(id: String) -> void: use_requested.emit(id))
			w = inv
		"character":
			var ch := CharacterWindow.new()
			ch.setup(pc, now_hours)
			w = ch
		"bestiary":
			var be := BestiaryWindow.new()
			be.setup(pc)
			w = be
		_:
			return null
	w.close_requested.connect(func() -> void: close(kind))
	add_child(w)
	_place(w, kind)
	_windows[kind] = w
	opened_changed.emit(true)
	return w


func close(kind: String) -> void:
	if not is_open(kind):
		return
	(_windows[kind] as Node).queue_free()
	_windows.erase(kind)
	opened_changed.emit(any_open())


func close_all() -> void:
	for k: String in _windows.keys():
		close(k)


## 창 내용 갱신(아이템 사용 뒤 등).
func refresh() -> void:
	for w: Variant in _windows.values():
		if w is InventoryWindow:
			(w as InventoryWindow).refresh()
		elif w is CharacterWindow:
			(w as CharacterWindow).refresh()


func _place(w: Control, kind: String) -> void:
	var m := UiTheme.metric("margin", 16)
	match kind:
		"inventory":
			w.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			w.offset_right = -m
			w.offset_left = -m - w.get_combined_minimum_size().x
			w.offset_top = m
		"character":
			w.set_anchors_preset(Control.PRESET_TOP_LEFT)
			w.offset_left = m
			w.offset_top = m
		_:
			w.set_anchors_preset(Control.PRESET_CENTER_TOP)
			w.offset_left = -w.get_combined_minimum_size().x * 0.5
			w.offset_right = w.get_combined_minimum_size().x * 0.5
			w.offset_top = m
	w.grow_horizontal = Control.GROW_DIRECTION_BOTH if kind == "bestiary" else (Control.GROW_DIRECTION_BEGIN if kind == "inventory" else Control.GROW_DIRECTION_END)
