class_name FloorMapFile
extends RefCounted
## 고정 지도 파일(층 JSON의 fixed_map.file — 모든 게임에서 같은 지도). tools/bake_floor.gd가 만들고 생성기가 읽는다.
## 형식(JSON): {"floor", "seed", "width", "height", "legend": {글자: 타일 id}, "rows": [한 줄 = width글자],
##             "landmarks": [{"id", "pos": [x, y], "rect": [x, y, w, h]}],
##             "features": [{"id": data/events id, "pos": [x, y]}]}  — 동굴 요소(rows에는 요소 밑의 바닥 타일이 적힌다)
## 칸 하나 = 글자 하나라 텍스트 편집기로 열어 좌표(줄 = y, 글자 = x, 0부터)를 바로 읽을 수 있다.
## 구역·암흑지대·포탈·안전지대는 층 JSON의 고정 뼈대(CrossLayout)에서 다시 계산하므로 적지 않는다.

const CHARS := {"rock_wall": "#", "cave_floor": ".", "crystal_wall": "*", "pond_water": "~", "boulder": "B",
	"square_crystal": "C", "monument": "M", "portal": "P"}
const SPARE := "abcdefghijklmnopqrstuvwxyz0123456789"

static var _cache: Dictionary = {}  # 경로 -> 읽은 파일(Dictionary)


## 지도를 파일로 쓴다. 성공하면 OK.
static func save(map: FloorMap, path: String, seed_value: int, base_tile: String = "") -> Error:
	var legend := {}
	var char_of := {}
	var spare := 0
	for def in map.defs:
		if map.tiles.has(def.index):
			var ch: String = CHARS.get(def.id, "")
			if ch.is_empty():
				ch = SPARE[spare]
				spare += 1
			legend[ch] = def.id
			char_of[def.index] = ch
	var under := {}  # 요소 칸 -> 바닥(요소 타일은 FieldFeaturePlacer.apply_tiles가 다시 깐다)
	if not base_tile.is_empty():
		for f: Dictionary in map.features:
			under[map.idx(f["pos"])] = true
		if not under.is_empty() and not legend.values().has(base_tile):
			legend["."] = base_tile
	var base_char := "."
	for ch: String in legend:
		if legend[ch] == base_tile:
			base_char = ch
	var rows: Array[String] = []
	for y in map.height:
		var line := PackedStringArray()
		line.resize(map.width)
		for x in map.width:
			var i := y * map.width + x
			line[x] = base_char if under.has(i) else char_of[map.tiles[i]]
		rows.append("".join(line))
	var marks: Array = []
	for rec: Dictionary in map.landmarks:
		var p: Vector2i = rec["pos"]
		var r: Rect2i = rec["rect"]
		marks.append({"id": rec["id"], "pos": [p.x, p.y], "rect": [r.position.x, r.position.y, r.size.x, r.size.y]})
	var feats: Array = []
	for f: Dictionary in map.features:
		var fp: Vector2i = f["pos"]
		feats.append({"id": f["id"], "pos": [fp.x, fp.y]})
	var data := {"_comment": "tools/bake_floor.gd가 만든 고정 지도. 한 글자 = 한 칸(legend), rows[y][x]. features = 동굴 요소 자리(data/events). 손으로 고쳐도 되지만 다시 구우면 덮어쓴다.",
		"floor": map.floor_id, "seed": seed_value, "width": map.width, "height": map.height, "legend": legend,
		"landmarks": marks, "features": feats, "rows": rows}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	# rows는 한 줄에 하나씩(편집기에서 지도 모양 그대로 보이게).
	var head := JSON.stringify(data.duplicate().merged({"rows": []}, true), "  ", false)
	var body := PackedStringArray()
	for row in rows:
		body.append("    \"%s\"" % row)
	f.store_string(head.replace("\"rows\": []", "\"rows\": [\n%s\n  ]" % ",\n".join(body)) + "\n")
	f.close()
	_cache.erase(path)
	return OK


static func exists(path: String) -> bool:
	return FileAccess.file_exists(path)


## 파일을 읽어 둔다(같은 경로는 한 번만 — 테스트·재입장에서 다시 읽지 않게). 실패하면 빈 사전.
static func read(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var data: Dictionary = parsed if parsed is Dictionary else {}
	_cache[path] = data
	return data


## 파일 내용 검사(검증기·생성기). 문제 목록 — 비면 통과.
static func problems(data: Dictionary, db: GameDatabase, side: int) -> PackedStringArray:
	var out := PackedStringArray()
	if data.is_empty():
		return PackedStringArray(["고정 지도 파일이 없거나 JSON이 아니다"])
	var w := JsonUtil.get_int(data, "width")
	var h := JsonUtil.get_int(data, "height")
	if w != side or h != side:
		out.append("고정 지도 크기 %d×%d ≠ 층 뼈대 %d×%d (gen 값을 바꿨으면 다시 굽기: tools/bake_floor.gd)" % [w, h, side, side])
	var legend := JsonUtil.get_dict(data, "legend")
	for ch: String in legend:
		if ch.length() != 1 or not db.has_entry("tiles", str(legend[ch])):
			out.append("고정 지도 legend '%s' → 타일 '%s' 없음" % [ch, legend[ch]])
	var rows := JsonUtil.get_array(data, "rows")
	if rows.size() != h:
		out.append("고정 지도 줄 수 %d ≠ height %d" % [rows.size(), h])
	for y in rows.size():
		var row := str(rows[y])
		if row.length() != w:
			out.append("고정 지도 %d번째 줄 길이 %d ≠ width %d" % [y, row.length(), w])
			break
	for f: Variant in JsonUtil.get_array(data, "features"):
		var fd: Dictionary = f if f is Dictionary else {}
		var fp := JsonUtil.get_array(fd, "pos")
		if not db.has_entry("events", JsonUtil.get_str(fd, "id")) or fp.size() != 2:
			out.append("고정 지도 동굴 요소 '%s' — events에 없거나 pos가 [x, y]가 아니다" % fd.get("id"))
		elif int(fp[0]) < 0 or int(fp[1]) < 0 or int(fp[0]) >= w or int(fp[1]) >= h:
			out.append("고정 지도 동굴 요소 '%s' 자리 %s가 지도 밖" % [fd.get("id"), fp])
	return out


## 파일의 지형·랜드마크를 map(크기가 맞는 빈 지도)에 옮긴다.
static func apply(data: Dictionary, map: FloorMap) -> void:
	var legend := JsonUtil.get_dict(data, "legend")
	var lut := PackedInt32Array()
	lut.resize(128)
	for ch: String in legend:
		lut[ch.unicode_at(0)] = map.index_of(str(legend[ch]))
	var rows := JsonUtil.get_array(data, "rows")
	for y in mini(rows.size(), map.height):
		var bytes := str(rows[y]).to_ascii_buffer()
		var base := y * map.width
		for x in mini(bytes.size(), map.width):
			map.tiles[base + x] = lut[bytes[x]]
	for m: Variant in JsonUtil.get_array(data, "landmarks"):
		var md: Dictionary = m if m is Dictionary else {}
		var p := JsonUtil.get_array(md, "pos")
		var r := JsonUtil.get_array(md, "rect")
		if p.size() == 2 and r.size() == 4:
			map.landmarks.append({"id": JsonUtil.get_str(md, "id"), "pos": Vector2i(int(p[0]), int(p[1])),
				"rect": Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])), "found": false})
	for f: Variant in JsonUtil.get_array(data, "features"):
		var fd: Dictionary = f if f is Dictionary else {}
		var fp := JsonUtil.get_array(fd, "pos")
		if fp.size() == 2:
			map.features.append({"id": JsonUtil.get_str(fd, "id"), "pos": Vector2i(int(fp[0]), int(fp[1]))})
