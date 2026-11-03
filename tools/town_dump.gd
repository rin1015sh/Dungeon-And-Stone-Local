extends SceneTree
## 동네 전체 그림용 칸 정보(CT103): 집(앞 y · 땅 높이) · 소품(발 · 높이) → user://town_dump.json
##   godot --headless --path . --script res://tools/town_dump.gd  →  python3 tools/town_overview.py → docs/plans/town/v4/town_full*.jpg

func _init() -> void:
	var db := GameDatabase.new()
	db.load_all("res://data")
	var t := TownMap.load_for(db)
	var hs := []
	for h: Dictionary in t.houses:
		hs.append({"id": h["id"], "front_y": TownHouse.front_y_of(h), "elev": float(h.get("elev", 0.0))})
	var ps := []
	var all: Array = []
	for p: Dictionary in t.props:
		all.append([str(p["kind"]), p["rect"]])
	if not t.dais.is_empty():
		var c: Vector2i = t.dais["center"]
		var r := int(ceil(float(t.dais["r"])))
		all.append(["dais", Rect2i(c - Vector2i(r, r), Vector2i(r * 2, r * 2))])
	for a: Array in all:
		var rc: Rect2i = a[1]
		ps.append({"kind": a[0], "x": (rc.position.x + rc.size.x * 0.5) * 32.0, "y": rc.end.y * 32.0, "lift": t.height_at(Vector2i(rc.get_center())) * 32.0})
	var f := FileAccess.open("user://town_dump.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"houses": hs, "props": ps, "w": t.width, "h": t.height, "max_h": t.max_height()}))
	f.close()
	quit(0)
