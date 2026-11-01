class_name LootView
extends Node2D
## 균열 바닥에 놓인 물건(RiftLoot — ExploreSession.loot)을 그 아이템 그림으로 그린다. 본 적 있는 칸만(기억 = 어둡게).
## 물건은 챕터에 열 개 안팎이라 칸이 바뀌거나 물건을 주웠을 때만 다시 그린다.
## 상자(RiftChest — V25)는 물건 대신 상자 그림: 잠김 = 닫힌 상자 + 검은 테두리, 연 뒤 = 열린 빈 상자(테두리 없음). render.json view.chest.

var view: FloorView
var _box: float = 0.8    ## 그림 크기(칸 대비) — render.json view.loot_px_ratio
var _shadow := Color(0, 0, 0, 0.35)
var _chest := {}  ## "closed"/"open" → Texture2D
var _chest_w: float = 1.1  ## 상자 그림 폭(칸 대비)


func setup(p_view: FloorView) -> void:
	view = p_view
	_box = JsonUtil.get_float(JsonUtil.get_dict(view.session.db.render, "view"), "loot_px_ratio", 0.8)
	z_index = -8  # 바닥·데칼·낭떠러지(-9) 위, 캐릭터·벽 아래
	var cc := JsonUtil.get_dict(JsonUtil.get_dict(view.session.db.render, "view"), "chest")
	_chest_w = JsonUtil.get_float(cc, "width_ratio", 1.1)
	for k in ["closed", "open"]:
		var path := JsonUtil.get_str(cc, k)
		_chest[k] = load(path) if not path.is_empty() and ResourceLoader.exists(path) else null
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
		var entry: Dictionary = s.loot[cell]
		if bool(entry.get("chest", false)):
			_draw_chest(feet, not bool(entry.get("opened", false)), lit)
			continue
		draw_set_transform(feet + Vector2(0, -size * 0.1), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, size * 0.42, _shadow)
		draw_set_transform(Vector2.ZERO)
		var item := str((s.loot[cell] as Dictionary)["item"])
		var tex := ItemIconPainter.texture(s.db, item)
		if tex != null and tex.get_height() > tex.get_width() * 1.3:  # 긴 물건(망치·창·활)은 바닥에 비스듬히 눕힌다
			var long := size * 1.8
			var k := long / tex.get_height()
			draw_set_transform(feet + Vector2(0, -size * 0.3), -PI * 0.36, Vector2(k, k))
			var at := -Vector2(tex.get_width(), tex.get_height()) * 0.5
			Outline.texture_rect(self, tex, Rect2(at, Vector2(tex.get_size())), view.outline_px / k)  # 주울 물건 = 검은 테두리(CT77)
			draw_texture(tex, at, Color(1, 1, 1, 1.0 if lit else 0.45))
			draw_set_transform(Vector2.ZERO)
			continue
		var r := Rect2(feet - Vector2(size * 0.5, size * 0.85), Vector2(size, size))
		if tex != null:
			var sc := minf(r.size.x / tex.get_width(), r.size.y / tex.get_height())
			var sz := Vector2(tex.get_size()) * sc
			Outline.texture_rect(self, tex, Rect2(r.get_center() - sz * 0.5, sz), view.outline_px)
		ItemIconPainter.draw(self, s.db, item, r, 1.0 if lit else 0.45)


## 상자: 발 자리(칸 아래 가운데)에 세운다 — 닫힌 것은 살필 수 있어 검은 테두리.
func _draw_chest(feet: Vector2, locked: bool, lit: bool) -> void:
	var tex: Texture2D = _chest.get("closed" if locked else "open")
	var w := view.tile * _chest_w
	draw_set_transform(feet + Vector2(0, -w * 0.06), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, w * 0.5, _shadow)
	draw_set_transform(Vector2.ZERO)
	if tex == null:
		draw_rect(Rect2(feet - Vector2(w * 0.45, w * 0.55), Vector2(w * 0.9, w * 0.5)), Color(0.35, 0.25, 0.15, 1.0 if lit else 0.45))
		return
	var sz := Vector2(w, w * tex.get_height() / tex.get_width())
	var r := Rect2(feet - Vector2(sz.x * 0.5, sz.y * _foot_y(tex)), sz)
	if locked:
		Outline.texture_rect(self, tex, r, view.outline_px)
	draw_texture_rect(tex, r, false, Color(1, 1, 1, 1.0 if lit else 0.45))


## 그림 속 바닥 접점(아래 끝에서 조금 위 — 그림 아래 여백).
func _foot_y(_tex: Texture2D) -> float:
	return 0.94
