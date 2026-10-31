extends SceneTree
## 시설 실내 지도 그림(탑뷰 3/4 한 지도 — data/rooms, CT62·CT64·CT66): 방마다 바닥 층 · 벽 층 · 가구 무리 그림 · 잠긴 문.
##   godot --headless --path . --script res://tools/paint_rooms.gd [-- --only=<방 id>]
## → 방 JSON art_dir/ floor.webp · walls.webp · f_<글자 코드>_<w>x<h>.webp(CityRoom.furniture_art). 칸 = view.floor_tile_px × city.json room.art_scale px.
## 바닥·벽 = RoomPaint(+ RoomDecor·RoomWalls), 가구 = RoomFurniture(+ RoomFurniture2 · RoomProps·RoomProps2). 같은 시드면 같은 그림.

const RoomPaint := preload("res://tools/city_art/RoomPaint.gd")
const RoomFurniture := preload("res://tools/city_art/RoomFurniture.gd")
const SEED := 7310


func _initialize() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	var db := GameDatabase.new()
	db.load_all("res://data")
	var view: Dictionary = db.render.get("view", {})
	var scale := JsonUtil.get_float(JsonUtil.get_dict(db.singletons.get("city", {}), "room"), "art_scale", 1.5)
	var t := int(float((view.get("floor_tile_px", [32, 32]) as Array)[0]) * scale)
	for id: String in db.get_collection("rooms"):
		if not only.is_empty() and id != only:
			continue
		var t0 := Time.get_ticks_msec()
		var room := db.get_entry("rooms", id)
		var legend := CityRoom.legend_of(db, room)
		var rows := PackedStringArray()
		for r: Variant in JsonUtil.get_array(room, "rows"):
			rows.append(str(r))
		var dir := JsonUtil.get_str(room, "art_dir")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var layers: Dictionary = RoomPaint.paint(room, rows, legend, t, SEED + id.hash() % 1000)
		layers["floor"].call("save", dir.path_join("floor.webp"))
		layers["walls"].call("save", dir.path_join("walls.webp"))
		var done := {}
		for g: Dictionary in CityRoom.groups(rows, legend, ["furniture", "locked"]):
			var ch := str(g["char"])
			var rc: Rect2i = g["rect"]
			var d := JsonUtil.get_dict(legend, ch)
			var size := rc.size if JsonUtil.get_str(d, "kind") == "furniture" else Vector2i.ONE
			var path := CityRoom.furniture_art(room, ch, size)
			if done.has(path):
				continue
			done[path] = true
			if JsonUtil.get_str(d, "kind") == "locked":
				d = {"shape": "door", "color": "#4a3424"}
			var p: RefCounted = RoomFurniture.paint(d, size, t, SEED + path.hash() % 1000)
			p.call("save", path)
		print("방 %s: %d칸×%d칸 · 가구 그림 %d · %d ms" % [id, rows[0].length(), rows.size(), done.size(), Time.get_ticks_msec() - t0])
	quit(0)
