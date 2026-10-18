class_name RiftBlueprintGenerator
extends FloorGenerator
## 균열 챕터 설계도 지도(A5 — docs/plans/rift_spaces.md): 손으로 설계한 장소를 그대로 읽는다(무작위 없음).
## gen: {"blueprint": "res://data/maps/rifts/<균열>_<챕터>.json"}
## 파일: {"width", "height", "floor"(기본 바닥 타일), "legend": {글자: 타일 id}, "rows": [한 줄 = width글자],
##        "marks": {"entry": [x, y], "slots": [[x, y] …], "exit": [x, y], "hidden": [[x, y] …], "hazards": [[x, y] …]}}
## slots = 조우 자리(데이터 encounters 순서 — 수호자는 마지막), hidden = 히든 피스 자리(데이터 hidden 순서 — RiftHidden),
## hazards = 위험 묶음 가운데(데이터 hazards × count 순서 — RiftHazards). 출구 칸에는 tiles.exit(gen.tiles)를 깐다.


func generate(db: GameDatabase, floor_def: Dictionary, rng: Rng) -> FloorMap:
	var g := JsonUtil.get_dict(floor_def, "gen")
	var data := FloorMapFile.read(JsonUtil.get_str(g, "blueprint"))
	var w := JsonUtil.get_int(data, "width")
	var h := JsonUtil.get_int(data, "height")
	var legend := JsonUtil.get_dict(data, "legend")
	var map := FloorMap.new(db, w, h, JsonUtil.get_str(data, "floor"))
	map.floor_id = JsonUtil.get_str(floor_def, "id")
	map.seed_value = rng.seed_value
	var rows := JsonUtil.get_array(data, "rows")
	var index_of := {}
	for ch: String in legend:
		index_of[ch] = map.index_of(str(legend[ch]))
	for y in mini(h, rows.size()):
		var row := str(rows[y])
		for x in mini(w, row.length()):
			map.tiles[y * w + x] = index_of.get(row[x], map.tiles[y * w + x])
	var marks := JsonUtil.get_dict(data, "marks")
	map.entry = _pos(JsonUtil.get_array(marks, "entry"))
	map.center = map.entry
	map.safe_zones.append({"center": map.entry, "radius": 1.5})
	for p: Variant in JsonUtil.get_array(marks, "slots"):
		map.slots.append(_pos(p))
	for key: String in ["hidden", "hazards"]:
		var list: Array[Vector2i] = []
		for p: Variant in JsonUtil.get_array(marks, key):
			list.append(_pos(p))
		map.anchors[key] = list
	var exit := _pos(JsonUtil.get_array(marks, "exit"))
	map.set_tile(exit, JsonUtil.get_str(JsonUtil.get_dict(g, "tiles"), "exit", "rift_exit"))
	map.portals.append({"id": "rift_exit", "pos": exit, "dir": "", "to_floor": 0, "kind": "rift_exit", "found": false})
	return map


static func _pos(a: Variant) -> Vector2i:
	var arr: Array = a if a is Array else []
	return Vector2i(int(arr[0]), int(arr[1])) if arr.size() == 2 else Vector2i(-1, -1)


func validate(floor_def: Dictionary, db: GameDatabase) -> PackedStringArray:
	return problems(FloorMapFile.read(JsonUtil.get_str(JsonUtil.get_dict(floor_def, "gen"), "blueprint")), db)


## 설계도 파일 검사(검증기·테스트). 문제 목록 — 비면 통과.
static func problems(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	if data.is_empty():
		return PackedStringArray(["설계도 파일이 없거나 JSON이 아니다"])
	var out := PackedStringArray()
	var w := JsonUtil.get_int(data, "width")
	var h := JsonUtil.get_int(data, "height")
	if not db.has_entry("tiles", JsonUtil.get_str(data, "floor")):
		out.append("설계도 floor 타일 '%s' 없음" % JsonUtil.get_str(data, "floor"))
	var legend := JsonUtil.get_dict(data, "legend")
	for ch: String in legend:
		if ch.length() != 1 or not db.has_entry("tiles", str(legend[ch])):
			out.append("설계도 legend '%s' → 타일 '%s' 없음" % [ch, legend[ch]])
	var rows := JsonUtil.get_array(data, "rows")
	if rows.size() != h:
		out.append("설계도 줄 수 %d ≠ height %d" % [rows.size(), h])
	for y in rows.size():
		var row := str(rows[y])
		if row.length() != w:
			out.append("설계도 %d번째 줄 길이 %d ≠ width %d" % [y, row.length(), w])
			break
		for x in row.length():
			if not legend.has(row[x]):
				out.append("설계도 (%d, %d) 글자 '%s'가 legend에 없다" % [x, y, row[x]])
				return out
	var marks := JsonUtil.get_dict(data, "marks")
	for key: String in ["entry", "exit"]:
		var p := _pos(JsonUtil.get_array(marks, key))
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			out.append("설계도 marks.%s가 지도 밖이거나 [x, y]가 아니다" % key)
	return out
