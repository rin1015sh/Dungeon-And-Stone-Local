class_name PaperDoll
extends Control
## 장비 인형(스톤샤드식 배치): 왼쪽 긴 칸 = 주무기, 오른쪽 긴 칸 = 보조.
## 가운데 위 줄: 몸 · 망토 · 머리(+ 아래 허리), 아래 줄: 장갑 · 반지 2 · 목걸이 · 신발.
## 칸마다 EquipSlot(그리기 + 커서 표시). 장착·벗기는 Tab 메뉴의 소지품 쪽(InventoryPage)이 키로 한다.

signal changed

const GHOST := {"main_hand": "sword", "off_hand": "shield", "head": "helmet", "body": "armor", "cloak": "cloak",
	"hands": "gloves", "waist": "belt", "feet": "boots", "ring_l": "ring", "ring_r": "ring", "neck": "amulet"}

var actor: Actor
var slots: Dictionary = {}  # 칸 -> EquipSlot


## slot_px = 칸 한 변(없으면 render.json doll_slot — Tab 메뉴는 쪽 크기에 맞춰 키운다).
func setup(p_actor: Actor, slot_px: float = -1.0) -> void:
	actor = p_actor
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := slot_px if slot_px > 0.0 else float(UiTheme.metric("doll_slot", 58))
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
		add_child(es)
		slots[id] = es
	custom_minimum_size = Vector2(col.call(5) - g, s * 2 + g)
	actor.equipment.changed.connect(func(_slot: String) -> void: _redraw())


## 커서가 놓인 칸(빈 글 = 없음).
func set_cursor(slot: String) -> void:
	for id: String in slots:
		(slots[id] as EquipSlot).set_cursor(id == slot)


func _redraw() -> void:
	for es: EquipSlot in slots.values():
		es.queue_redraw()


## 장비 칸 하나.
class EquipSlot extends Control:
	signal changed

	var actor: Actor
	var slot: String = ""
	var ghost: String = ""
	var _cursor: bool = false

	func setup(p_actor: Actor, p_slot: String, p_ghost: String) -> void:
		actor = p_actor
		slot = p_slot
		ghost = p_ghost
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_cursor(on: bool) -> void:
		if on != _cursor:
			_cursor = on
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var blocked := slot == "off_hand" and actor.equipment.off_hand_blocked()
		GothicStyle.draw_slot(self, r, "hover" if _cursor else "")
		var id := actor.equipment.item_in(slot)
		if not id.is_empty():
			ItemIconPainter.draw(self, actor.db, id, _art_rect(id, r.grow(-4)))
		elif blocked:
			var main := actor.equipment.item_in("main_hand")
			ItemIconPainter.draw(self, actor.db, main, _art_rect(main, r.grow(-4)), 0.25)
		else:
			ItemIconPainter.paint_ghost(self, ghost, r)
		if _cursor:
			draw_rect(r.grow(-1), UiTheme.color("select"), false, 2.0)

	## 손 칸(긴 칸)은 가방 칸 크기 비율대로 — 칸 하나 = 긴 칸을 render.json ui.doll_hand_cells([가로, 세로] 칸)로 나눈 크기.
	## 그대로 칸에 꽉 채우면 1×2 단검이 1×4 창만큼 길어 보였다(사용자 2026-10-29, UI47). 다른 칸은 칸에 맞춘다.
	func _art_rect(item_id: String, r: Rect2) -> Rect2:
		if not slot in ["main_hand", "off_hand"]:
			return r
		var cells := UiTheme.ui_array("doll_hand_cells")
		var k := minf(r.size.x / float(cells[0]), r.size.y / float(cells[1])) if cells.size() == 2 else minf(r.size.x * 0.5, r.size.y * 0.25)
		var sz := Vector2(ItemInfo.size(actor.db, item_id)) * k
		sz = Vector2(minf(sz.x, r.size.x), minf(sz.y, r.size.y))
		return Rect2(r.get_center() - sz * 0.5, sz)

	## 가방에서 고른 아이템을 이 칸에 장착한다(스모크 테스트도 쓴다). 성공하면 true.
	func drop(d: Dictionary) -> bool:
		if str(d.get("from")) != "grid" or not actor.equipment.can_equip(str(d["id"]), slot):
			return false
		var ok := InventoryActions.equip_stack(actor, int(d["index"]), slot)
		if ok:
			changed.emit()
		return ok
