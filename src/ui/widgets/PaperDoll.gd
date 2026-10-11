class_name PaperDoll
extends Control
## 장비 인형(스톤샤드식 배치): 왼쪽 긴 칸 = 주무기, 오른쪽 긴 칸 = 보조.
## 가운데 위 줄: 몸 · 망토 · 머리(+ 아래 허리), 아래 줄: 장갑 · 반지 2 · 목걸이 · 신발.
## 칸마다 EquipSlot(끌어오기·끌어놓기·툴팁·오른쪽 클릭 벗기).

signal changed

const GHOST := {"main_hand": "sword", "off_hand": "shield", "head": "helmet", "body": "armor", "cloak": "cloak",
	"hands": "gloves", "waist": "belt", "feet": "boots", "ring_l": "ring", "ring_r": "ring", "neck": "amulet"}

var actor: Actor
var slots: Dictionary = {}  # 칸 -> EquipSlot


func setup(p_actor: Actor) -> void:
	actor = p_actor
	var s := float(UiTheme.metric("doll_slot", 58))
	var g := 6.0
	var ring := (s - g) * 0.5
	var col := func(i: int) -> float: return i * (s + g)
	var rects := {
		"main_hand": Rect2(col.call(0), 0, s, s * 2 + g),
		"body": Rect2(col.call(1), 0, s, s),
		"cloak": Rect2(col.call(2), 0, s, s),
		"head": Rect2(col.call(3), 0, s, s * 0.62),
		"waist": Rect2(col.call(3), s * 0.62 + g * 0.5, s, s * 0.38 - g * 0.5),
		"hands": Rect2(col.call(1), s + g, s, s),
		"ring_l": Rect2(col.call(2), s + g, ring, ring),
		"ring_r": Rect2(col.call(2), s + g + ring + g, ring, ring),
		"neck": Rect2(col.call(2) + ring + g, s + g, ring, s),
		"feet": Rect2(col.call(3), s + g, s, s),
		"off_hand": Rect2(col.call(4), 0, s, s * 2 + g),
	}
	for id: String in rects:
		var es := EquipSlot.new()
		es.setup(actor, id, str(GHOST[id]))
		var r: Rect2 = rects[id]
		es.position = r.position
		es.size = r.size
		es.custom_minimum_size = r.size
		es.changed.connect(func() -> void: changed.emit())
		add_child(es)
		slots[id] = es
	custom_minimum_size = Vector2(col.call(5) - g, s * 2 + g)
	actor.equipment.changed.connect(func(_slot: String) -> void: _redraw())


func _redraw() -> void:
	for es: EquipSlot in slots.values():
		es.queue_redraw()


## 장비 칸 하나.
class EquipSlot extends Control:
	signal changed

	var actor: Actor
	var slot: String = ""
	var ghost: String = ""
	var _state: String = ""

	func setup(p_actor: Actor, p_slot: String, p_ghost: String) -> void:
		actor = p_actor
		slot = p_slot
		ghost = p_ghost
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var blocked := slot == "off_hand" and actor.equipment.off_hand_blocked()
		GothicStyle.draw_slot(self, r, _state)
		var id := actor.equipment.item_in(slot)
		if not id.is_empty():
			ItemIconPainter.draw(self, actor.db, id, r.grow(-4))
		elif blocked:
			ItemIconPainter.draw(self, actor.db, actor.equipment.item_in("main_hand"), r.grow(-4), 0.25)
		else:
			ItemIconPainter.paint_ghost(self, ghost, r)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_set_state("hover")
		elif what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_DRAG_END:
			_set_state("")

	func _set_state(s: String) -> void:
		if s != _state:
			_state = s
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_RIGHT or mb.double_click:
				if InventoryActions.unequip_to_bag(actor, slot):
					changed.emit()
				accept_event()

	func _get_tooltip(_at_position: Vector2) -> String:
		var id := actor.equipment.item_in(slot)
		return DataNames.tag(actor.db, "equip_slots", slot) if id.is_empty() else "item"

	func _make_custom_tooltip(for_text: String) -> Object:
		var id := actor.equipment.item_in(slot)
		if for_text != "item" or id.is_empty():
			return null
		return ItemTooltip.panel(actor.db, id, true)

	func _get_drag_data(_at_position: Vector2) -> Variant:
		var id := actor.equipment.item_in(slot)
		if id.is_empty():
			return null
		set_drag_preview(ItemDragPreview.make(actor.db, id, UiTheme.metric("inv_cell", 38)))
		return {"type": "item", "from": "slot", "slot": slot, "id": id}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		var ok := data is Dictionary and str((data as Dictionary).get("from")) == "grid" \
			and actor.equipment.can_equip(str((data as Dictionary)["id"]), slot)
		_set_state("ok" if ok else "bad")
		return ok

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		drop(data as Dictionary)

	## 가방에서 끌어온 아이템을 이 칸에 장착한다(스모크 테스트도 쓴다). 성공하면 true.
	func drop(d: Dictionary) -> bool:
		_set_state("")
		if str(d.get("from")) != "grid" or not actor.equipment.can_equip(str(d["id"]), slot):
			return false
		var ok := InventoryActions.equip_stack(actor, int(d["index"]), slot)
		if ok:
			changed.emit()
		return ok
