class_name ItemPickWindow
extends Control
## 소지품 창만 따로 열어 아이템 하나를 고르는 창(사용자 요청 2026-11-03): 상점·대장간·떠돌이 상인·거래소에서 팔 물건을 가방에서 직접 고른다.
##   Tab 메뉴의 소지품 쪽(InventoryPage)을 고르기 모드로 쓴다 — 장비 인형 없이 가방 격자만. W/A/S/D = 커서, Enter = 고르기(picked), Esc = 닫기(closed).
##   고를 수 없는 아이템은 어둡게(filter), 설명의 가격은 price(id)로 바꿔 보인다. 고른 뒤에도 창은 그대로 — 부르는 쪽이 처리하고 refresh()를 부른다.
##   판매 말고도 아이템을 고르는 어느 자리든 쓴다(봉헌·맡기기·넘기기 …): ItemPickWindow.open(host, actor, 제목, filter, price) → picked 시그널.

signal picked(item_id: String)
signal closed

var page: InventoryPage


## host 위에 열어 돌려준다. filter(id) -> bool · price(id) -> int는 선택(Callable()이면 모두 고를 수 있고 기본 가격).
static func open(host: Node, actor: Actor, title: String, filter: Callable = Callable(), price: Callable = Callable()) -> ItemPickWindow:
	var w := ItemPickWindow.new()
	host.add_child(w)
	w.setup(actor, title, filter, price)
	return w


func setup(actor: Actor, title: String, filter: Callable, price: Callable) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.color("bg"), MenuPage.cfg("dim", 0.6))
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page = InventoryPage.new()
	page.popup_host = self
	page.setup(actor)
	page.set_title(title)
	page.custom_minimum_size = Vector2(MenuPage.cfg("inventory_width", 420.0), get_viewport_rect().size.y * MenuPage.cfg("pick_height_ratio", 0.72))
	center.add_child(page)
	page.set_pick_mode(filter, price)
	page.picked.connect(func(id: String) -> void: picked.emit(id))
	page.active = true


func refresh() -> void:
	if page != null:
		page.refresh()


## 닫는다(closed를 낸다).
func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if is_queued_for_deletion() or not (event is InputEventKey or event is InputEventAction) or not event.is_pressed():
		return
	if page != null and page.busy():
		return
	get_viewport().set_input_as_handled()  # 열려 있는 동안 키는 모두 이 창이 먹는다
	if event.is_action_pressed("pause") or event.is_action_pressed("menu"):
		close()
		return
	if event.is_action_pressed("menu_confirm"):
		page.confirm()
		return
	for a: Array in [["menu_up", Vector2i.UP], ["menu_down", Vector2i.DOWN], ["menu_left", Vector2i.LEFT], ["menu_right", Vector2i.RIGHT]]:
		if event.is_action_pressed(str(a[0]), true):
			page.nav(a[1])
			return
