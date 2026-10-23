extends SceneTree
## 아이템 그림 생성기(사용자 요청 2026-10-23 — 아이템 그림을 몬스터·도시와 같은 그림체로): data의 아이템마다
## tools/item_art/ItemArt.gd로 그려 assets/items/<id>.webp(투명 배경, 가방 칸 크기 × ItemArt.CELL px).
##   godot --headless --path . --script res://tools/paint_items.gd [-- --only=<id,id…>] [--kind=<종류 id>](그 종류 장비만)
## 게임은 assets/items/<id>.webp가 있으면 그것을 쓴다(ItemIconPainter — 없으면 옛 도형). 그린 뒤 --import.

const ItemArt := preload("res://tools/item_art/ItemArt.gd")
const OUT_DIR := "res://assets/items"
const SEED := 2026


func _init() -> void:
	var only := PackedStringArray()
	var kind := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		elif a.begins_with("--kind="):
			kind = a.trim_prefix("--kind=")
	var db := GameDatabase.new()
	db.load_all("res://data")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ids: Array = db.get_collection("items").keys()
	ids.sort()
	var n := 0
	var missing: Array[String] = []
	var t0 := Time.get_ticks_msec()
	for id: String in ids:
		if not only.is_empty() and not only.has(id):
			continue
		if not kind.is_empty() and JsonUtil.get_str(JsonUtil.get_dict(db.get_entry("items", id), "forged"), "type") != kind:
			continue
		var p: Variant = ItemArt.paint(db, id, SEED + id.hash() % 9973)
		if p == null:
			missing.append(id)
			continue
		p.save(OUT_DIR.path_join(id + ".webp"), 0.88)
		n += 1
	print("아이템 그림 %d장 (%d초)" % [n, (Time.get_ticks_msec() - t0) / 1000])
	if not missing.is_empty():
		print("그리지 못함(그림 종류 없음): " + ", ".join(missing))
	quit(0)
