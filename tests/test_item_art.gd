extends TestCase
## 아이템 그림(tools/paint_items.gd — 사용자 요청 2026-10-23 "아이템 그림을 우리 그림체로 전면 교체"):
## 모든 아이템에 assets/items/<id>.webp가 있고, 크기 = 가방 칸 수 × 그림 칸 px(ItemArt.CELL)이다.
## 새 아이템·소재·종류를 넣었으면 `godot --headless --path . --script res://tools/paint_items.gd -- --only=<id>`로 그린다.

const CELL := 80


func test_every_item_has_painted_art() -> void:
	var ids: Array = db.get_collection("items").keys()
	ids.sort()
	for id: String in ids:
		var path := "res://assets/items/%s.webp" % id
		if not FileAccess.file_exists(path):
			assert_true(false, "%s 그림이 없다(tools/paint_items.gd -- --only=%s)" % [id, id])
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		var sz := ItemInfo.size(db, id)
		assert_eq(Vector2i(img.get_width(), img.get_height()), sz * CELL, "%s 그림 크기 = 칸 %s × %d" % [id, sz, CELL])
	assert_true(ids.size() > 300)
