class_name RiftChapterGenerator
extends FloorGenerator
## 균열 챕터 맵(명세 §8.3 "챕터 하나 = 작은 탐험 맵 + 고정 조우"). RiftRun이 챕터마다 가짜 층 정의를 만들어 부른다.
## gen: {"size": [w, h], "rooms": n, "room_size": [최소, 최대], "corridor_width": 2,
##       "tiles": {"floor", "wall", "exit"}}
## 방 n개를 왼쪽에서 오른쪽으로 늘어놓고(세로는 무작위) 이웃끼리 ㄱ자 통로로 잇는다.
## 시작 = 첫 방 가운데(안전지대), 조우 자리(map.slots) = 두 번째 방부터 마지막 방까지의 가운데,
## 출구 = 마지막 방 오른쪽 끝(타일 tiles.exit, map.portals에 kind "rift_exit").
## 불변식: 걸을 수 있는 칸은 모두 시작 칸에서 닿는다(방·통로만 판다).


func generate(db: GameDatabase, floor_def: Dictionary, rng: Rng) -> FloorMap:
	var g := JsonUtil.get_dict(floor_def, "gen")
	var tiles := JsonUtil.get_dict(g, "tiles")
	var size := JsonUtil.get_array(g, "size")
	var w := int(size[0])
	var h := int(size[1])
	var n := maxi(2, JsonUtil.get_int(g, "rooms", 4))
	var rs := JsonUtil.get_array(g, "room_size")
	var rmin := int(rs[0]) if rs.size() == 2 else 5
	var rmax := int(rs[1]) if rs.size() == 2 else 8
	var cw := maxi(1, JsonUtil.get_int(g, "corridor_width", 2))
	var map := FloorMap.new(db, w, h, JsonUtil.get_str(tiles, "wall"))
	map.floor_id = JsonUtil.get_str(floor_def, "id")
	map.seed_value = rng.seed_value
	var floor_tile := JsonUtil.get_str(tiles, "floor")
	var margin := rmax / 2 + 2
	var rooms: Array[Rect2i] = []
	for i in n:
		var rw := rng.randi_range(rmin, rmax)
		var rh := rng.randi_range(rmin, rmax)
		var cx := margin + roundi(float(i) * float(w - 2 * margin) / float(n - 1))
		var cy := rng.randi_range(margin, h - margin - 1)
		var r := Rect2i(cx - rw / 2, cy - rh / 2, rw, rh).intersection(Rect2i(1, 1, w - 2, h - 2))
		rooms.append(r)
		_carve(map, r, floor_tile)
	for i in range(1, n):
		var a := _center(rooms[i - 1])
		var b := _center(rooms[i])
		_carve(map, Rect2i(mini(a.x, b.x), a.y, absi(b.x - a.x) + cw, cw), floor_tile)
		_carve(map, Rect2i(b.x, mini(a.y, b.y), cw, absi(b.y - a.y) + cw), floor_tile)
	map.entry = _center(rooms[0])
	map.center = map.entry
	map.safe_zones.append({"center": map.entry, "radius": 1.5})
	for i in range(1, n):
		map.slots.append(_center(rooms[i]))
	var last := rooms[n - 1]
	var exit := Vector2i(last.end.x - 2, _center(last).y)
	map.set_tile(exit, JsonUtil.get_str(tiles, "exit"))
	map.portals.append({"id": "rift_exit", "pos": exit, "dir": "", "to_floor": 0, "kind": "rift_exit", "found": false})
	map.dark = FloorMap._zeros(w * h)
	return map


func _carve(map: FloorMap, r: Rect2i, tile_id: String) -> void:
	var clip := r.intersection(Rect2i(1, 1, map.width - 2, map.height - 2))
	for y in range(clip.position.y, clip.end.y):
		for x in range(clip.position.x, clip.end.x):
			map.set_tile(Vector2i(x, y), tile_id)


func _center(r: Rect2i) -> Vector2i:
	return r.position + r.size / 2


func validate(floor_def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var g := JsonUtil.get_dict(floor_def, "gen")
	var size := JsonUtil.get_array(g, "size")
	if size.size() != 2 or int(size[0]) < 20 or int(size[1]) < 12:
		out.append("rift_chapter: gen.size는 [20 이상, 12 이상]")
	var tiles := JsonUtil.get_dict(g, "tiles")
	for key: String in ["floor", "wall", "exit"]:
		if not db.has_entry("tiles", JsonUtil.get_str(tiles, key)):
			out.append("rift_chapter: gen.tiles.%s 타일 없음" % key)
	return out
