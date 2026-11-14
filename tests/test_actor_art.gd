extends TestCase
## 탐험 맵 몸 그림(tools/paint_actors.gd → assets/actors, docs/PROMPT_ART_MAP.md A4):
## 고를 수 있는 종족마다 4방향 × 걸음 cols장(render.json actor_sheet) 시트가 있고, 몬스터마다 맵 그림이 있는지. 시트 줄·칸 고르기 규칙.
## 그림이 없으면 탐험가는 예전 그림, 몬스터는 도형으로 보인다 — 새 종족·몬스터를 추가하면 paint_actors.gd --only=<id>로 그린다.


func _cfg() -> Dictionary:
	return JsonUtil.get_dict(JsonUtil.get_dict(db.render, "view"), "actor_sheet")


func test_enabled_races_have_walk_sheets() -> void:
	for race: String in db.get_collection("races"):
		var def := db.get_entry("races", race)
		if not JsonUtil.get_bool(def, "enabled", false):
			continue
		var path := JsonUtil.get_str(def, "sprite")
		var sheet := ActorSheet.load_for(db.render, path)
		assert_true(sheet != null, "걷기 시트(4줄 × cols칸): %s %s" % [race, path])
		if sheet != null:
			assert_eq(sheet.texture.get_size(), Vector2(sheet.cell.x * sheet.cols, sheet.cell.y * 4), "시트 크기: " + race)


func test_every_monster_has_map_art() -> void:
	var dir := JsonUtil.get_str(_cfg(), "monster_dir", "res://assets/actors/monsters")
	var missing := PackedStringArray()
	for id: String in db.get_collection("monsters"):
		if not ResourceLoader.exists(dir.path_join(id + ".webp")):
			missing.append(id)
	assert_eq(missing.size(), 0, "맵 그림 없는 몬스터: " + ", ".join(missing))


func test_sheet_rows_and_walk_cycle() -> void:
	assert_eq(ActorSheet.row_for(Vector2i(0, 1)), 0, "아래")
	assert_eq(ActorSheet.row_for(Vector2i(-1, 0)), 1, "왼쪽")
	assert_eq(ActorSheet.row_for(Vector2i(1, -1)), 2, "대각선은 옆모습")
	assert_eq(ActorSheet.row_for(Vector2i(0, -1)), 3, "위")
	var s := ActorSheet.load_for(db.render, "res://assets/actors/human.webp")
	assert_true(s != null, "인간 시트")
	if s == null:
		return
	assert_eq(s.col_at(3.3, false), s.stand, "멈추면 섬")
	var seen := {}
	var stands := 0
	for i in s.cycle.size():
		var c := s.col_at(i / s.fps + 0.01, true)
		seen[c] = true
		if c == s.stand:
			stands += 1
	assert_eq(seen.size(), s.cols, "걷는 동안 모든 칸(걸음·반걸음·섬)을 돈다")
	assert_eq(stands, 2, "한 바퀴에 선 칸이 두 번(걸음 사이마다)")
	for i in s.cycle.size():  # 이웃한 칸끼리는 한 칸씩만 바뀐다(걸음 → 섬으로 건너뛰지 않는다)
		assert_true(absi(s.cycle[i] - s.cycle[(i + 1) % s.cycle.size()]) == 1, "칸 순서가 이어진다: %s" % [s.cycle])


## 걷기 시트가 색인(sheets.json)에 있는 몬스터는 시트를 읽을 수 있다(칸 크기 × cols·4줄). 보스는 시트 없이 기다리는 자세 한 장(AM34).
func test_monster_walk_sheets_load() -> void:
	var dir := JsonUtil.get_str(_cfg(), "monster_dir", "res://assets/actors/monsters")
	var path := dir.path_join("sheets.json")
	assert_true(FileAccess.file_exists(path), "몬스터 시트 색인")
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(index is Dictionary and not (index as Dictionary).is_empty(), "색인이 비어 있지 않다")
	if not index is Dictionary:
		return
	for id: String in index:
		var sheet := ActorSheet.load_monster(db.render, id)
		assert_true(sheet != null, "걷기 시트를 읽는다: " + id)
		if sheet != null:
			assert_eq(sheet.texture.get_size(), Vector2(sheet.cell.x * sheet.cols, sheet.cell.y * 4), "시트 크기: " + id)
	assert_true(ActorSheet.load_monster(db.render, "blater") == null, "보스는 걷기 시트가 없다")


## 웹 내보내기에 몬스터 시트 색인이 들어간다(FileAccess로 읽는 json은 include_filter에 있어야 한다).
func test_sheet_index_exported() -> void:
	assert_true(FileAccess.get_file_as_string("res://export_presets.cfg").contains("assets/*.json"), "export_presets include_filter(시트 색인 sheets.json)")


## 돌아다니는 몬스터(rank normal)는 모두 걷기 시트가 있다(AM67 — 보스 · 중간보스는 기다리는 자세 한 장, 사람 약탈자는 탐험가 시트).
func test_roaming_monsters_have_walk_sheets() -> void:
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/actors/monsters/sheets.json"))
	assert_true(index is Dictionary, "sheets.json")
	if not (index is Dictionary):
		return
	var missing := PackedStringArray()
	for id: String in db.get_collection("monsters"):
		if JsonUtil.get_str(db.get_entry("monsters", id), "rank") != "normal":
			continue
		if not (index as Dictionary).has(id) or not FileAccess.file_exists("res://assets/actors/monsters/%s_walk.webp" % id):
			missing.append(id)
	assert_eq(missing.size(), 0, "걷기 시트 없는 몬스터: " + ", ".join(missing))
