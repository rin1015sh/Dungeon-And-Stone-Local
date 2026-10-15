extends SceneTree
## 몬스터 전투 일러스트 생성기: data/monsters의 몬스터마다 tools/monster_art/Specs.gd 설계대로 그려 assets/monsters/<id>.webp(투명 배경).
##   godot --headless --path . --script res://tools/paint_monsters.gd [-- --only=<id,id…>] [--index](그리지 않고 색인만 다시)
## 그림체 = 피어 앤 헝거 몬스터 그림(사용자 첨부 참고, ASSUMPTIONS UI8): 3D 덩어리로 빚은 몸(Clay) → 3~4단 붓 칠·적갈색 그늘 ·
## 잉크 윤곽·골 · 펜 빗금(Render) → 털 붓결·피·때(Fur·Finish). 한 장에 2~10초, 전부 약 4분.
## 그림은 둘레만 남겨 자르고(발 = 아래 끝), index.json에 그림마다 몸 높이 px를 적는다(들어 올린 무기·뿔은 키에서 빼고,
## 네발짐승·덩어리는 사람 키에 견준 비율로 — Specs.body_height).
## 전투 화면(BattlerView → MonsterArt)은 그림이 있으면 그것을, 없으면 CombatFigure 도형을 쓴다.

const Specs := preload("res://tools/monster_art/Specs.gd")
const SEED := 2026
const OUT_DIR := "res://assets/monsters"


func _init() -> void:
	var only := PackedStringArray()
	var index_only := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		index_only = index_only or a == "--index"
	var db := GameDatabase.new()
	db.load_all("res://data")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var n := 0
	var index := {}
	var index_path := OUT_DIR.path_join("index.json")
	if FileAccess.file_exists(index_path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(index_path))
		if old is Dictionary:
			index = old
	for id: String in db.get_collection("monsters"):
		if not only.is_empty() and not only.has(id):
			continue
		if index_only:
			var old_img := Image.load_from_file(ProjectSettings.globalize_path(OUT_DIR.path_join(id + ".webp")))
			if old_img != null:
				index[id] = int(Specs.body_height(id, float(old_img.get_height() - 12)))
			continue
		var t := Time.get_ticks_msec()
		var p: Variant = Specs.paint(id, db.get_entry("monsters", id), SEED + id.hash() % 9973)
		if p == null:
			print("그림 없음(설계 없음): " + id)
			continue
		var img: Image = p.to_image()
		var used := img.get_used_rect().grow(6).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		img.get_region(used).save_webp(OUT_DIR.path_join(id + ".webp"), true, 0.9)  # 그림 둘레만 남긴다(발 = 아래 끝)
		index[id] = int(Specs.body_height(id, float(used.size.y - 12)))
		n += 1
		print("그림: %s (%d ms)" % [id, Time.get_ticks_msec() - t])
	var f := FileAccess.open(index_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(index, "\t", true))
	f.close()
	print("몬스터 그림 %d장" % n)
	quit(0)
