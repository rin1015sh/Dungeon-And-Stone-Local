class_name LootView
extends Node2D
## 균열 바닥에 놓인 물건(RiftLoot — ExploreSession.loot)을 그 아이템 그림으로 그린다. 본 적 있는 칸만(기억 = 어둡게).
## 물건은 챕터에 열 개 안팎이라 칸이 바뀌거나 물건을 주웠을 때만 다시 그린다.

var view: FloorView
var _box: float = 0.8    ## 그림 크기(칸 대비) — render.json view.loot_px_ratio
var _shadow := Color(0, 0, 0, 0.35)


func setup(p_view: FloorView) -> void:
	view = p_view
	_box = JsonUtil.get_float(JsonUtil.get_dict(view.session.db.render, "view"), "loot_px_ratio", 0.8)
	z_index = -8  # 바닥·데칼·낭떠러지(-9) 위, 캐릭터·벽 아래
	view.session.moved.connect(_on_moved)
	view.session.tiles_changed.connect(_on_tiles)


func _on_moved(_a: Vector2i, _b: Vector2i) -> void:
	queue_redraw()


func _on_tiles(_r: Rect2i) -> void:
	queue_redraw()


func _draw() -> void:
	var s := view.session
	var map := s.map
	var size := view.tile * _box
	for cell: Vector2i in s.loot:
		var i := cell.y * map.width + cell.x
		if map.explored.size() <= i or map.explored[i] == 0:
			continue
		var lit := map.visible_now.size() > i and map.visible_now[i] != 0
		var feet := view.feet_position(cell)
		draw_set_transform(feet + Vector2(0, -size * 0.1), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, size * 0.42, _shadow)
		draw_set_transform(Vector2.ZERO)
		var item := str((s.loot[cell] as Dictionary)["item"])
		var tex := ItemIconPainter.texture(s.db, item)
		if tex != null and tex.get_height() > tex.get_width() * 1.3:  # 긴 물건(망치·창·활)은 바닥에 비스듬히 눕힌다
			var long := size * 1.8
			var k := long / tex.get_height()
			draw_set_transform(feet + Vector2(0, -size * 0.3), -PI * 0.36, Vector2(k, k))
			draw_texture(tex, -Vector2(tex.get_width(), tex.get_height()) * 0.5, Color(1, 1, 1, 1.0 if lit else 0.45))
			draw_set_transform(Vector2.ZERO)
			continue
		var r := Rect2(feet - Vector2(size * 0.5, size * 0.85), Vector2(size, size))
		ItemIconPainter.draw(self, s.db, item, r, 1.0 if lit else 0.45)
