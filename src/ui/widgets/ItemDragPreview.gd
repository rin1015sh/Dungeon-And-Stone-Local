class_name ItemDragPreview
extends Control
## 끄는 동안 마우스를 따라다니는 아이템 그림(반투명). 가운데가 마우스에 오도록 놓는다.

var _db: GameDatabase
var _id: String = ""


static func make(db: GameDatabase, item_id: String, cell: int) -> Control:
	var holder := Control.new()
	var p := ItemDragPreview.new()
	p._db = db
	p._id = item_id
	p.size = Vector2(ItemInfo.size(db, item_id)) * cell
	p.position = -p.size * 0.5
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(p)
	return holder


func _draw() -> void:
	ItemIconPainter.draw(self, _db, _id, Rect2(Vector2.ZERO, size).grow(-3), 0.8)
