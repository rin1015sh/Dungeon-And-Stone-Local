class_name InventoryGrid
extends Control
## 격자 가방 그리기·조작(스톤샤드식). 칸 = inv_cell px. 아이템은 크기만큼 칸을 덮고 그림 + 개수를 그린다.
##   끌어서 옮기기(같은 아이템 위면 쌓기) · 장비 칸에서 끌어와 벗기 · 오른쪽 클릭/두 번 클릭 = 사용 또는 장착
##   마우스를 올리면 아이템 툴팁(장착품 비교).
## 끌기 데이터: {"type": "item", "from": "grid", "index": i, "id": id} / {"from": "slot", "slot": 칸, "id": id}

signal activated(index: int)  ## 오른쪽 클릭·두 번 클릭(창이 장착/사용을 정한다)
signal changed

var actor: Actor
var cell: int = 38

var _hover: Vector2i = Vector2i(-1, -1)
var _drop_rect: Rect2i = Rect2i()
var _drop_ok: bool = false


func setup(p_actor: Actor) -> void:
	actor = p_actor
	cell = UiTheme.metric("inv_cell", 38)
	custom_minimum_size = Vector2(actor.inventory.width * cell, actor.inventory.height * cell)
	mouse_filter = Control.MOUSE_FILTER_STOP
	actor.inventory.changed.connect(func(_id: String, _n: int) -> void: queue_redraw())


func cell_at(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / cell), floori(p.y / cell))


func _draw() -> void:
	var inv := actor.inventory
	for y in inv.height:
		for x in inv.width:
			GothicStyle.draw_slot(self, Rect2(x * cell + 1, y * cell + 1, cell - 2, cell - 2))
	if _drop_rect.has_area():
		draw_rect(Rect2(_drop_rect.position * cell, _drop_rect.size * cell),
			Color(UiTheme.color("slot_ok" if _drop_ok else "slot_bad"), 0.6))
	var hi := inv.stack_at(_hover)
	var font := get_theme_default_font()
	var fs := UiTheme.metric("small_font_size", 13)
	for i in inv.stacks().size():
		var s: Dictionary = inv.stacks()[i]
		var id := str(s["id"])
		var r := Rect2(Vector2(s["pos"]) * cell, Vector2(ItemInfo.size(actor.db, id)) * cell)
		if i == hi:
			draw_rect(r.grow(-1), Color(UiTheme.color("slot_hover"), 0.8))
		ItemIconPainter.draw(self, actor.db, id, r.grow(-3))
		if int(s["count"]) > 1:
			var t := str(s["count"])
			var pos := r.end - Vector2(font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 3, 4)
			draw_string_outline(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color.BLACK)
			draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.color("text_title"))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c := cell_at((event as InputEventMouseMotion).position)
		if c != _hover:
			_hover = c
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mb := event as InputEventMouseButton
		var i := actor.inventory.stack_at(cell_at(mb.position))
		if i >= 0 and (mb.button_index == MOUSE_BUTTON_RIGHT or mb.double_click):
			activated.emit(i)
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_DRAG_END:
		_hover = Vector2i(-1, -1)
		_drop_rect = Rect2i()
		queue_redraw()


func _get_tooltip(at_position: Vector2) -> String:
	var i := actor.inventory.stack_at(cell_at(at_position))
	return "" if i < 0 else "item:%d" % i


func _make_custom_tooltip(for_text: String) -> Object:
	var i := for_text.trim_prefix("item:").to_int()
	if not for_text.begins_with("item:") or i < 0 or i >= actor.inventory.stacks().size():
		return null
	var s: Dictionary = actor.inventory.stacks()[i]
	return ItemTooltip.build(actor.db, str(s["id"]), actor, int(s["count"]))


func _get_drag_data(at_position: Vector2) -> Variant:
	var i := actor.inventory.stack_at(cell_at(at_position))
	if i < 0:
		return null
	var id := str(actor.inventory.stacks()[i]["id"])
	set_drag_preview(ItemDragPreview.make(actor.db, id, cell))
	return {"type": "item", "from": "grid", "index": i, "id": id}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or str((data as Dictionary).get("type")) != "item":
		return false
	var d := data as Dictionary
	var pos := drop_pos(at_position, str(d["id"]))
	_drop_ok = _drop_allowed(d, pos)
	_drop_rect = Rect2i(pos, ItemInfo.size(actor.db, str(d["id"])))
	queue_redraw()
	return _drop_ok


func _drop_data(at_position: Vector2, data: Variant) -> void:
	drop(data as Dictionary, drop_pos(at_position, str((data as Dictionary)["id"])))


## 놓을 왼쪽 위 칸: 아이템 가운데가 마우스 칸에 오도록.
func drop_pos(at_position: Vector2, id: String) -> Vector2i:
	var size := ItemInfo.size(actor.db, id)
	return cell_at(at_position) - Vector2i((size.x - 1) / 2, (size.y - 1) / 2)


## 끌어온 것을 pos에 놓는다(스모크 테스트도 이 함수를 쓴다). 성공하면 true.
func drop(d: Dictionary, pos: Vector2i) -> bool:
	var ok := false
	match str(d.get("from")):
		"grid":
			ok = actor.inventory.move_stack(int(d["index"]), pos)
		"slot":
			ok = InventoryActions.unequip_to_bag(actor, str(d["slot"]), pos)
	_drop_rect = Rect2i()
	queue_redraw()
	if ok:
		changed.emit()
	return ok


func _drop_allowed(d: Dictionary, pos: Vector2i) -> bool:
	var id := str(d["id"])
	if str(d.get("from")) == "grid":
		var other := actor.inventory.stack_at(pos)
		if other >= 0 and other != int(d["index"]) and actor.inventory.stacks()[other]["id"] == id:
			return true
		return actor.inventory.can_place(id, pos, int(d["index"]))
	return actor.inventory.can_place(id, pos)
