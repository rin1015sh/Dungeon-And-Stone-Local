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
	var kinds := PackedStringArray()  # 칸마다 종류 한 줄(막힘 겹쳐 보기 — town_overview.py --blocks)
	for y in t.height:
		var row := ""
		for x in t.width:
			var k := t.kind_at(Vector2i(x, y))
			row += "." if k in TownMap.WALK else k.substr(0, 1)
		kinds.append(row)
	var f := FileAccess.open("user://town_dump.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"houses": hs, "props": ps, "w": t.width, "h": t.height, "max_h": t.max_height(), "kinds": kinds, "fine": _fine(t), "sub": t.collide.sub, "heights": _heights(t)}))
	f.close()
	quit(0)


static func _heights(t: TownMap) -> Array:
	var out := []
	for y in t.height:
		var row := []
		for x in t.width:
			row.append(t.height_at(Vector2i(x, y)))
		out.append(row)
	return out


static func _fine(t: TownMap) -> PackedStringArray:
	var out := PackedStringArray()
	var m := t.collide.map
	for y in m.height:
		var row := ""
		for x in m.width:
			row += "." if m.is_walkable(Vector2i(x, y)) else "#"
		out.append(row)
	return out
