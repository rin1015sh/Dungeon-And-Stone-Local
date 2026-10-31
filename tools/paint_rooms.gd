extends SceneTree
## 시설 실내 방 그림(탑뷰 3/4 — data/rooms, CT62): 방 한 장 + 소품.
##   godot --headless --path . --script res://tools/paint_rooms.gd [-- --only=<방 id>] [--out=<폴더>]
## → 방 JSON의 art·props[].art 경로(assets/city/rooms/). 칸 = render.json view.floor_tile_px × art_scale px.
## 방마다 그리는 함수: 방 = RoomArt.library · RoomRooms.<id>, 소품 = kind(없으면 소품 id 앞부분 — table_nw → table) → RoomProps·RoomProps2(크기 = rect, variant)
## — 새 방·소품은 아래 rooms·props 표에 한 줄. 같은 그림 경로는 한 번만 그린다. 같은 시드면 같은 그림.

const RoomArt := preload("res://tools/city_art/RoomArt.gd")
const RoomProps := preload("res://tools/city_art/RoomProps.gd")
const RoomRooms := preload("res://tools/city_art/RoomRooms.gd")
const RoomProps2 := preload("res://tools/city_art/RoomProps2.gd")
const SEED := 7310


func _initialize() -> void:
	var only := ""
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var render: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/render.json"))
	var view: Dictionary = render.get("view", {})
	var t := int(float((view.get("floor_tile_px", [32, 32]) as Array)[0]) * float(view.get("art_scale", 2)))
	var dir := DirAccess.open("res://data/rooms")
	for f in dir.get_files():
		if not f.ends_with(".json") or f.begins_with("_"):
			continue
		var room: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms/" + f))
		var id := str(room.get("id", ""))
		if not only.is_empty() and id != only:
			continue
		var t0 := Time.get_ticks_msec()
		var rooms := {"library": RoomArt.library, "guild": RoomRooms.guild, "inn": RoomRooms.inn, "temple": RoomRooms.temple, "shop": RoomRooms.shop,
			"smithy": RoomRooms.smithy, "bank": RoomRooms.bank, "training": RoomRooms.training}
		var props := {"table": RoomProps.table, "desk": RoomProps.desk, "lectern": RoomProps.lectern, "counter": RoomProps2.counter,
			"altar": RoomProps2.altar, "candles": RoomProps2.candles, "pew": RoomProps2.pew, "anvil": RoomProps2.anvil, "rack": RoomProps2.rack,
			"bench": RoomProps2.bench, "dummy": RoomProps2.dummy, "barrel": RoomProps2.barrel, "crate": RoomProps2.crate, "sack": RoomProps2.sack}
		if not rooms.has(id):
			push_warning("방 그림 함수가 없다: RoomArt.%s" % id)
			continue
		var p: RefCounted = (rooms[id] as Callable).call(room, t, SEED + id.hash() % 1000)
		p.call("save", _path(str(room.get("art", "")), out))
		var done := {}
		for v: Variant in room.get("props", []):
			var d: Dictionary = v
			var art := str(d.get("art", ""))
			if art.is_empty() or done.has(art):
				continue
			done[art] = true
			var kind := str(d.get("kind", str(d.get("id", "")).get_slice("_", 0)))
			var r: Array = d.get("rect", [0, 0, 1, 1])
			if not props.has(kind):
				push_warning("소품 그림 함수가 없다: RoomProps.%s" % kind)
				continue
			var pp: RefCounted = (props[kind] as Callable).call(t, SEED + art.hash() % 1000, Vector2i(int(r[2]), int(r[3])), str(d.get("variant", "")))
			pp.call("save", _path(art, out))
		print("방 %s: %d ms" % [id, Time.get_ticks_msec() - t0])
	quit(0)


static func _path(path: String, out: String) -> String:
	return path if out.is_empty() else out.path_join(path.get_file())
