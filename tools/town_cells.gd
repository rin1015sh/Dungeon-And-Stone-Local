extends SceneTree
## 동네 지도 칸 정보(종류 · 높이)를 user://town_cells.json으로 — 바닥 굽기(tools/town_ground_bake.py)가 계단 · 정원(닿지 않는 틈) · 계단 높이를 쓴다(CT99).
##   godot --headless --path . --script res://tools/town_cells.gd


func _init() -> void:
	var db := GameDatabase.new()
	db.load_all("res://data")
	var t := TownMap.load_for(db)
	var kinds := PackedStringArray()
	var hs := PackedFloat32Array()
	for y in t.height:
		for x in t.width:
			kinds.append(t.kind_at(Vector2i(x, y)))
			hs.append(t.height_at(Vector2i(x, y)))
	var f := FileAccess.open("user://town_cells.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"width": t.width, "height": t.height, "max_h": t.max_height(), "kinds": kinds, "heights": hs}))
	f.close()
	print("칸: %d×%d" % [t.width, t.height])
	quit(0)
