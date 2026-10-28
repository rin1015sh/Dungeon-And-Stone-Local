extends SceneTree
## 전투 아군 동작 시트(탐험가 — 종족 뒷모습): tools/monster_art/party_motions.json의 동작마다 3칸(PartyMotion이 잰 관절을 3D 뼈대로).
## 칸 크기·발 자리는 한 시트 안의 모든 동작이 같다(무대가 칸을 바꿔 끼워도 몸이 튀지 않게). 줄 = 동작(json 순서), 칸 = 3.
##   godot --headless --path . --script res://tools/paint_motions.gd -- [--only=human_back,…] [--motions=idle,thrust] [--out=<폴더>]
## → <폴더>/<id>_motions.png (기본 user://motions — 게임에는 아직 안 쓴다)

const Party := preload("res://tools/monster_art/Party.gd")
const SEED := 2026


func _init() -> void:
	var out := "user://motions"
	var only := PackedStringArray(["human_back", "barbarian_back"])
	var pick := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		elif a.begins_with("--motions="):
			pick = a.trim_prefix("--motions=").split(",")
	DirAccess.make_dir_recursive_absolute(out)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tools/monster_art/party_motions.json"))
	var names: Array = []
	for m: String in (data as Dictionary):
		if not m.begins_with("_") and (pick.is_empty() or pick.has(m)):
			names.append(m)
	for id: String in only:
		var rows: Array = []
		var box := Rect2i()
		for m: String in names:
			var row: Array[Image] = []
			for fr: Dictionary in (data[m]["frames"] as Array):
				var sp := Party.spec_of(id)
				sp["motion_frame"] = fr
				if (data[m] as Dictionary).has("weapon"):
					var kit: Dictionary = (sp.get("kit", {}) as Dictionary).duplicate()
					kit["weapon"] = data[m]["weapon"]
					sp["kit"] = kit
				var img: Image = Party.figure(sp, SEED + id.hash() % 9973).to_image()
				var used := img.get_used_rect()
				box = used if box.size == Vector2i.ZERO else box.merge(used)
				row.append(img)
			rows.append(row)
		box = box.grow(6).intersection(Rect2i(Vector2i.ZERO, (rows[0][0] as Image).get_size()))
		var sheet := Image.create(box.size.x * 3, box.size.y * rows.size(), false, Image.FORMAT_RGBA8)
		for r in rows.size():
			for i in (rows[r] as Array).size():
				sheet.blit_rect(rows[r][i], box, Vector2i(i * box.size.x, r * box.size.y))
		sheet.save_png(out.path_join(id + "_motions.png"))
		print("시트: %s 칸 %dx%d · 동작 %s" % [id, box.size.x, box.size.y, ", ".join(names)])
	quit(0)
