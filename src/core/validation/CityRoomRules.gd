class_name CityRoomRules
extends RefCounted
## 검사 규칙: 시설 실내 방(data/rooms — CityRoom, CT62) · 시설 JSON room 참조 · city.json room.
## 그림 파일이 없으면 경고만(방은 그림 없이도 걷는다 — tools/paint_rooms.gd로 그린다).

const CHARS := "#B.D"


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
	var rows := JsonUtil.get_array(r, "rows")
	if rows.is_empty():
		v.err(w, "rows가 비었다")
		return
	var width := str(rows[0]).length()
	var doors := 0
	for row: Variant in rows:
		if str(row).length() != width:
			v.err(w, "rows의 길이가 모두 같아야 한다")
		for ch in str(row):
			if not ch in CHARS:
				v.err(w, "rows 글자는 # B . D 중에서: '%s'" % ch)
			doors += 1 if ch == "D" else 0
	if doors == 0:
		v.err(w, "문(D)이 없다 — 나갈 수 없다")
	var walk := func(c: Vector2i) -> bool:
		return c.y >= 0 and c.y < rows.size() and c.x >= 0 and c.x < width and str(rows[c.y])[c.x] in ".D"
	var st := JsonUtil.get_array(r, "start")
	if st.size() != 2 or not walk.call(Vector2i(floori(float(st[0])), floori(float(st[1])))):
		v.err(w, "start는 바닥 칸 [x, y]")
	_art(v, w, JsonUtil.get_str(r, "art"))
	var acts := JsonUtil.get_array(v.db.get_entry("facilities", fac), "activities")
	for p: Variant in JsonUtil.get_array(r, "props"):
		var d: Dictionary = p
		var pw := "%s.props.%s" % [w, JsonUtil.get_str(d, "id")]
		var rc := CityRoom.rect_of(d)
		for y in range(rc.position.y, rc.end.y):
			for x in range(rc.position.x, rc.end.x):
				if not walk.call(Vector2i(x, y)) or str(rows[y])[x] == "D":
					v.err(pw, "rect는 바닥 칸 위에(크기 1 이상)")
		if rc.size.x < 1 or rc.size.y < 1:
			v.err(pw, "rect [x, y, w, h] — 크기 1 이상")
		if JsonUtil.get_str(d, "art").is_empty() == JsonUtil.get_str(d, "sprite").is_empty():
			v.err(pw, "art 또는 sprite 하나")
		_art(v, pw, JsonUtil.get_str(d, "art") + JsonUtil.get_str(d, "sprite"))
		var needs := JsonUtil.get_str(d, "needs")
		if not needs.is_empty():
			v.ref(pw + ".needs", "activities", needs)
	for s: Variant in JsonUtil.get_array(r, "spots"):
		var d: Dictionary = s
		var act := JsonUtil.get_str(d, "activity")
		v.ref(w + ".spots", "activities", act)
		if JsonUtil.get_str(v.db.get_entry("activities", act), "facility") != fac:
			v.err(w + ".spots", "활동 '%s'은(는) '%s' 시설 활동이 아니다" % [act, fac])
		var rc := CityRoom.rect_of(d)
		if rc.size.x < 1 or rc.size.y < 1 or rc.position.x < 0 or rc.position.y < 0 or rc.end.x > width or rc.end.y > rows.size():
			v.err(w + ".spots", "rect가 방 밖이다: " + act)
	for a: Variant in acts:  # 이번 순 사건 활동 말고는 자리가 있어야 걸어가서 한다
		if not JsonUtil.get_array(r, "spots").any(func(s: Variant) -> bool: return JsonUtil.get_str(s as Dictionary, "activity") == str(a)):
			v.err(w, "시설 활동 '%s'을(를) 할 자리(spots)가 없다" % a)


static func _art(v: ValidatorBase, w: String, path: String) -> void:
	if path.is_empty():
		return
	if not path.begins_with("res://"):
		v.err(w, "그림은 res:// 경로")
	elif not FileAccess.file_exists(path):
		v.warn(w, "그림 '%s'이(가) 없다(tools/paint_rooms.gd)" % path)
