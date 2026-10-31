class_name CityRoomRules
extends RefCounted
## 검사 규칙: 시설 실내(data/rooms — CityRoom, CT62·CT64·CT66) · 시설 JSON room 참조 · city.json room(공통 범례).
## 칸 글자마다 범례가 있는가 · 입구·들어온 자리 · 살필 자리마다 입구에서 걸어서 닿는가(잠긴 문은 열고, needs 가구는 비켜) · 활동·사건 참조 · 그림(없으면 경고만).

const KINDS := ["floor", "rug", "decor", "wall", "walldeco", "furniture", "door", "doorway", "locked", "entry", "stairs", "ladder", "open", "rail", "void", "npc"]
const WALK := ["floor", "rug", "decor", "door", "doorway", "entry", "stairs", "ladder", "locked"]


static func run(v: ValidatorBase) -> void:
	var city: Dictionary = v.db.singletons.get("city", {})
	var cfg := JsonUtil.get_dict(city, "room")
	for key: String in ["floor_tile", "block_tile"]:
		v.ref("city.room." + key, "tiles", JsonUtil.get_str(cfg, key))
	for id: String in v.entries("facilities"):
		var room := JsonUtil.get_str(v.db.get_entry("facilities", id), "room")
		if room.is_empty():
			continue
		v.ref("facilities/%s.room" % id, "rooms", room)
		if JsonUtil.get_str(v.db.get_entry("rooms", room), "facility") != id:
			v.err("facilities/" + id, "방 '%s'의 facility가 '%s'가 아니다" % [room, id])
	for id: String in v.entries("rooms"):
		_room(v, id)


static func _room(v: ValidatorBase, id: String) -> void:
	var r := v.db.get_entry("rooms", id)
	var w := "rooms/" + id
	var fac := JsonUtil.get_str(r, "facility")
	v.ref(w + ".facility", "facilities", fac)
	var legend := CityRoom.legend_of(v.db, r)
	var rows := PackedStringArray()
	for row: Variant in JsonUtil.get_array(r, "rows"):
		rows.append(str(row))
	if rows.is_empty():
		v.err(w, "rows가 비었다")
		return
	var entries := 0
	for row in rows:
		for ch in row:
			var d := JsonUtil.get_dict(legend, ch)
			if d.is_empty():
				v.err(w, "칸 글자 '%s'의 범례가 없다" % ch)
				continue
			entries += 1 if JsonUtil.get_str(d, "kind") == "entry" else 0
	for ch: String in legend:
		var d := JsonUtil.get_dict(legend, ch)
		var k := JsonUtil.get_str(d, "kind")
		if not k in KINDS:
			v.err("%s.legend.%s" % [w, ch], "kind는 %s 중에서" % [KINDS])
		if not JsonUtil.get_str(d, "needs").is_empty():
			v.ref("%s.legend.%s.needs" % [w, ch], "activities", JsonUtil.get_str(d, "needs"))
		if not JsonUtil.get_str(d, "opens").is_empty():
			v.ref("%s.legend.%s.opens" % [w, ch], "city_events", JsonUtil.get_str(d, "opens"))
	if entries == 0:
		v.err(w, "입구(kind entry)가 없다 — 나갈 수 없다")
	var walk := func(c: Vector2i) -> bool:
		if c.y < 0 or c.y >= rows.size() or c.x < 0 or c.x >= rows[c.y].length():
			return false
		var d := JsonUtil.get_dict(legend, rows[c.y][c.x])
		return JsonUtil.get_str(d, "kind") in WALK or (JsonUtil.get_str(d, "kind") == "furniture" and not JsonUtil.get_str(d, "needs").is_empty())
	var st := JsonUtil.get_array(r, "start")
	var start := Vector2i(floori(float(st[0])), floori(float(st[1]))) if st.size() == 2 else Vector2i(-1, -1)
	if not walk.call(start):
		v.err(w, "start는 걷는 칸 [x, y]")
		return
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not seen.has(c + d) and walk.call(c + d):
				seen[c + d] = true
				todo.append(c + d)
	var placed: Array[String] = []
	for s: Variant in JsonUtil.get_array(r, "spots"):
		var d: Dictionary = s
		var acts := CityRoom.spot_activities(d)
		if acts.is_empty() and not JsonUtil.get_bool(d, "rest"):
			v.err(w + ".spots", "자리에 activity·activities가 없다")
		for act in acts:
			v.ref(w + ".spots", "activities", act)
			if JsonUtil.get_str(v.db.get_entry("activities", act), "facility") != fac:
				v.err(w + ".spots", "활동 '%s'은(는) '%s' 시설 활동이 아니다" % [act, fac])
		placed.append_array(acts)
		var rc := CityRoom.rect_of(d)
		var reach := false
		for y in range(rc.position.y, rc.end.y):
			for x in range(rc.position.x, rc.end.x):
				for dd: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n := Vector2i(x, y) + dd
					reach = reach or (seen.has(n) and not rc.has_point(n))
		if not reach:
			v.err(w + ".spots", "입구에서 걸어서 닿지 않는 자리: %s" % [acts if not acts.is_empty() else JsonUtil.get_str(d, "name_ko")])
	for a: Variant in JsonUtil.get_array(v.db.get_entry("facilities", fac), "activities"):  # 이번 순 사건 활동 말고는 자리가 있어야 걸어가서 한다
		if not placed.has(str(a)):
			v.err(w, "시설 활동 '%s'을(를) 할 자리(spots)가 없다" % a)
	for n: Variant in JsonUtil.get_array(r, "npcs"):
		var at := JsonUtil.get_array(n as Dictionary, "at")
		if at.size() != 2 or int(at[1]) >= rows.size() or int(at[0]) >= rows[int(at[1])].length():
			v.err(w + ".npcs", "at가 지도 밖이다")
		_art(v, w + ".npcs", JsonUtil.get_str(n as Dictionary, "look"))
		var act := JsonUtil.get_str(n as Dictionary, "act")
		if not act.is_empty():  # 동작 그림(tools/paint_actors.gd --acts — CT69)
			_art(v, w + ".npcs", "res://assets/actors/acts/%s__%s.webp" % [JsonUtil.get_str(n as Dictionary, "look").get_file().get_basename(), act])
	for f: String in ["floor.webp", "walls.webp"]:
		_art(v, w, JsonUtil.get_str(r, "art_dir").path_join(f))


static func _art(v: ValidatorBase, w: String, path: String) -> void:
	if path.is_empty():
		return
	if not path.begins_with("res://"):
		v.err(w, "그림은 res:// 경로")
	elif not FileAccess.file_exists(path):
		v.warn(w, "그림 '%s'이(가) 없다(tools/paint_rooms.gd)" % path)
