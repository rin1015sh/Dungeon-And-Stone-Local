extends TestCase
## 탐험 맵 몸 그림(tools/paint_actors.gd → assets/actors, docs/PROMPT_ART_MAP.md A4):
## 고를 수 있는 종족마다 4방향 × 걸음 3장 시트가 있고, 몬스터마다 맵 그림이 있는지. 시트 줄·칸 고르기 규칙.
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
		assert_true(sheet != null, "걷기 시트(4줄 × 3칸): %s %s" % [race, path])
		if sheet != null:
			assert_eq(sheet.texture.get_size(), Vector2(sheet.cell.x * 3, sheet.cell.y * 4), "시트 크기: " + race)


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
	var s := ActorSheet.new()
	assert_eq(s.col_at(3.3, false), ActorSheet.STAND, "멈추면 섬")
	var seen := {}
	for i in 8:
		seen[s.col_at(i / s.fps + 0.01, true)] = true
	assert_eq(seen.size(), 3, "걷는 동안 세 칸을 돈다")
