class_name InventoryGrid
extends Control
## 격자 가방 그리기(스톤샤드식). 칸 = inv_cell px. 아이템은 크기만큼 칸을 덮고 그림 + 개수를 그린다.
## 조작은 Tab 메뉴의 소지품 쪽(InventoryPage)이 키로 한다: 커서(금빛 테두리) · 옮기는 중이면 놓을 자리(초록/빨강).
## 옮기기 데이터: {"type": "item", "from": "grid", "index": i, "id": id} / {"from": "slot", "slot": 칸, "id": id}

signal changed

var actor: Actor
var cell: int = 38

var _cursor: Rect2i = Rect2i()  # 커서가 덮은 칸(빈 칸 = 1×1, 아이템 = 그 크기)
var _drop_rect: Rect2i = Rect2i()
var _drop_ok: bool = false


func setup(p_actor: Actor) -> void:
	actor = p_actor
	cell = UiTheme.metric("inv_cell", 38)
	custom_minimum_size = Vector2(actor.inventory.width * cell, actor.inventory.height * cell)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor.inventory.changed.connect(func(_id: String, _n: int) -> void: queue_redraw())


## 칸 c를 덮은 사각형(그 칸에 아이템이 있으면 아이템 전체).
func target_at(c: Vector2i) -> Rect2i:
	var i := actor.inventory.stack_at(c)
	if i < 0:
		return Rect2i(c, Vector2i.ONE)
	var s: Dictionary = actor.inventory.stacks()[i]
	return Rect2i(Vector2i(s["pos"]), ItemInfo.size(actor.db, str(s["id"])))


func set_cursor(r: Rect2i) -> void:
	_cursor = r
	queue_redraw()


## 옮기는 중: d를 pos에 놓으면 어떻게 덮이는지(놓을 수 있으면 초록). d가 비면 지운다.
func set_preview(d: Dictionary, pos: Vector2i) -> void:
	if d.is_empty():
		_drop_rect = Rect2i()
	else:
		_drop_ok = _drop_allowed(d, pos)
		_drop_rect = Rect2i(pos, ItemInfo.size(actor.db, str(d["id"])))
	queue_redraw()


func _draw() -> void:
	var inv := actor.inventory
	for y in inv.height:
		for x in inv.width:
			GothicStyle.draw_slot(self, Rect2(x * cell + 1, y * cell + 1, cell - 2, cell - 2))
	var font := get_theme_default_font()
	var fs := UiTheme.metric("small_font_size", 13)
	for i in inv.stacks().size():
		var s: Dictionary = inv.stacks()[i]
		var id := str(s["id"])
		var r := Rect2(Vector2(s["pos"]) * cell, Vector2(ItemInfo.size(actor.db, id)) * cell)
		if _cursor.has_area() and Rect2i(Vector2i(s["pos"]), ItemInfo.size(actor.db, id)) == _cursor:
			draw_rect(r.grow(-1), Color(UiTheme.color("slot_hover"), 0.8))
		ItemIconPainter.draw(self, actor.db, id, r.grow(-3))
		if int(s["count"]) > 1:
			var t := str(s["count"])
			var pos := r.end - Vector2(font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 3, 4)
			draw_string_outline(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color.BLACK)
			draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.color("text_title"))
	if _drop_rect.has_area():
		draw_rect(Rect2(_drop_rect.position * cell, _drop_rect.size * cell),
			Color(UiTheme.color("slot_ok" if _drop_ok else "slot_bad"), 0.6))
	if _cursor.has_area():
		draw_rect(Rect2(_cursor.position * cell, _cursor.size * cell).grow(-1), UiTheme.color("gold"), false, 2.0)


## 옮기던 것을 pos에 놓는다. 성공하면 true.
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
