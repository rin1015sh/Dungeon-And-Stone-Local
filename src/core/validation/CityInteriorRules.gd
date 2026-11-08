class_name CityInteriorRules
extends RefCounted
## 검사 규칙: 시설 실내(data/interiors — CityInterior, CT106).
## 시설 interior가 있는 실내를 가리키는가 · 범례에 없는 글자 · kind · 그림 이름 · 사람 자리(npc 칸 · 몸 그림) · 방마다 이름과 크기 상한 ·
## 그 시설 활동이 모두 어느 자리에 있는가 · 바깥 문에서 모든 자리 앞에 걸어서 닿는가 · 구운 그림(index.json).

const KINDS := ["wallart", "furniture", "low", "door", "back", "npc"]


static func run(v: ValidatorBase) -> void:
	var city: Dictionary = v.db.singletons.get("city", {})
	var max_room := JsonUtil.get_array(JsonUtil.get_dict(city, "interior"), "max_room")
	for fid: String in v.entries("facilities"):
		var iid := JsonUtil.get_str(v.db.get_entry("facilities", fid), "interior")
		if not iid.is_empty():
			v.ref("facilities/%s.interior" % fid, "interiors", iid)
	for iid: String in v.entries("interiors"):
		_one(v, iid, max_room)
	var kinds := JsonUtil.get_dict(JsonUtil.get_dict(city, "interior"), "house_kinds")  # 일반 집 바리에이션 → 실내(CT110)
	for design: String in kinds:
		v.ref("city.interior.house_kinds." + design, "interiors", JsonUtil.get_str(kinds, design))


static func _one(v: ValidatorBase, iid: String, max_room: Array) -> void:
	var d := v.db.get_entry("interiors", iid)
	var w := "interiors/" + iid
	var fac := JsonUtil.get_str(d, "facility")
	if not fac.is_empty():  # 일반 집 실내는 시설이 없다(CT110)
		v.ref(w + ".facility", "facilities", fac)
	var legend := JsonUtil.get_dict(d, "legend")
	var rows := PackedStringArray()
	for r: Variant in JsonUtil.get_array(d, "rows"):
		rows.append(str(r))
	if rows.is_empty():
		v.err(w, "rows가 비었다")
		return
	for ch: String in legend:
		var e := JsonUtil.get_dict(legend, ch)
		var k := JsonUtil.get_str(e, "kind")
		if not k in KINDS:
			v.err(w, "legend %s kind는 %s 중에서" % [ch, KINDS])
		if k in ["wallart", "furniture", "low"] and JsonUtil.get_str(e, "art").is_empty():
			v.err(w, "legend %s에 art(그림 이름)가 없다" % ch)
		if e.has("opens"):
			v.err(w, "legend %s opens(사건 순에만 열리는 문)는 없앴다(CT114) — 늘 잠그려면 locked" % ch)
		if e.has("needs"):
			v.ref(w + ".legend." + ch + ".needs", "activities", JsonUtil.get_str(e, "needs"))
	for y in rows.size():
		for x in rows[y].length():
			var ch := rows[y][x]
			if not ch in ["#", ".", "D", " "] and not legend.has(ch):
				v.err(w, "%d줄 %d칸 글자 %s가 범례에 없다" % [y, x, ch])
	for n: Variant in JsonUtil.get_array(d, "npcs"):
		var at := JsonUtil.get_array(n as Dictionary, "at")
		var look := JsonUtil.get_str(n as Dictionary, "look")
		if at.size() != 2 or int(at[1]) >= rows.size() or int(at[0]) >= rows[int(at[1])].length() \
			or JsonUtil.get_str(CityInterior.cell_def(legend, rows[int(at[1])][int(at[0])]), "kind") != "npc":
			v.err(w, "npcs %s 자리가 npc 칸이 아니다" % [at])
		if not ResourceLoader.exists(look):
			v.err(w, "npcs 몸 그림이 없다: " + look)
	var rooms := CityInterior.room_cells(rows, legend)
	for cells: Array in rooms:
		var named := false
		var lo := Vector2i(9999, 9999)
		var hi := Vector2i(-1, -1)
		for c: Vector2i in cells:
			lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
			hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
			for r: Variant in JsonUtil.get_array(d, "rooms"):
				var at := JsonUtil.get_array(r as Dictionary, "at")
				named = named or (at.size() == 2 and Vector2i(int(at[0]), int(at[1])) == c)
		if not named:
			v.err(w, "방(%d, %d 둘레)에 rooms 이름이 없다" % [lo.x, lo.y])
		if max_room.size() == 2 and (hi.x - lo.x + 3 > int(max_room[0]) or hi.y - lo.y + 3 > int(max_room[1])):
			v.err(w, "방(%d, %d 둘레)이 한 화면(city.json interior.max_room %s)보다 크다" % [lo.x, lo.y, max_room])
	_spots(v, w, d, fac, rows, legend)
	var art := JsonUtil.get_str(d, "art_dir").path_join("index.json")
	if not FileAccess.file_exists(art):
		v.warn(w, "구운 그림이 없다(python3 tools/interior_bake.py %s): %s" % [iid, art])


## 활동 자리: 활동이 있는가 · 그 시설 활동이 모두 자리에 있는가 · 바깥 문에서 자리 앞까지 닿는가.
static func _spots(v: ValidatorBase, w: String, d: Dictionary, fac: String, rows: PackedStringArray, legend: Dictionary) -> void:
	var placed := {}
	var reach := _reach(rows, legend)
	for s: Variant in JsonUtil.get_array(d, "spots"):
		var sd: Dictionary = s
		for a: Variant in JsonUtil.get_array(sd, "activities"):
			v.ref(w + ".spots", "activities", str(a))
			placed[str(a)] = true
		var cells: Array[Vector2i] = []
		var at := JsonUtil.get_array(sd, "at")
		if at.size() == 2:
			cells.append(Vector2i(int(at[0]), int(at[1])))
		for y in rows.size():
			for x in rows[y].length():
				if not JsonUtil.get_str(sd, "char").is_empty() and rows[y][x] == JsonUtil.get_str(sd, "char"):
					cells.append(Vector2i(x, y))
		var ok := false
		for c in cells:
			for dir: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
				ok = ok or reach.has(c + dir)
		if not ok:
			v.err(w, "자리 %s 앞에 바깥 문에서 걸어서 닿지 못한다" % [JsonUtil.get_array(sd, "activities")])
	if fac.is_empty():
		return
	for a: Variant in JsonUtil.get_array(v.db.get_entry("facilities", fac), "activities"):
		if not placed.has(str(a)):
			v.err(w, "시설 활동 %s를 할 자리가 없다(spots)" % str(a))


## 바깥 문(D)에서 걸어서 닿는 칸(잠긴 문은 닫힌 것으로).
static func _reach(rows: PackedStringArray, legend: Dictionary) -> Dictionary:
	var walk := func(c: Vector2i) -> bool:
		if c.y < 0 or c.y >= rows.size() or c.x < 0 or c.x >= rows[c.y].length():
			return false
		var e := CityInterior.cell_def(legend, rows[c.y][c.x])
		return JsonUtil.get_str(e, "kind") in CityInterior.WALK and not JsonUtil.get_bool(e, "locked")
	var seen := {}
	var todo: Array[Vector2i] = []
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] == "D":
				seen[Vector2i(x, y)] = true
				todo.append(Vector2i(x, y))
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for dir: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
			var n := c + dir
			if not seen.has(n) and walk.call(n):
				seen[n] = true
				todo.append(n)
	return seen
