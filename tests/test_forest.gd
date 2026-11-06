extends TestCase
## 2층 고블린 숲(FL21 — docs/plans/floor2.md §5 · §13-3): 1층 북쪽 포탈에서 온다 · 길 그래프 · 포탈 비석 여덟(하나만 진짜) ·
## 지형 덫(숨은 덫 묶음) · 고블린 마을 큰 무리 · 바깥 고리 홉고블린 대장 + 졸개.

const FOREST := "f2_goblin_forest"


func _session(seed_value: int, monsters: bool) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", FOREST)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func _reach(map: FloorMap) -> Dictionary:
	var seen := {map.entry: true}
	var queue: Array[Vector2i] = [map.entry]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in FloorMap.DIRS4:
			if map.in_bounds(p + d) and not seen.has(p + d) and map.is_walkable(p + d):
				seen[p + d] = true
				queue.append(p + d)
	return seen


func test_north_portal_leads_to_forest() -> void:
	assert_eq(FloorTravel.floor_for(db, "floor2_north"), FOREST, "1층 북쪽 포탈 → 고블린 숲")


func test_route_map_and_steles() -> void:
	var s := _session(3, false)
	var map := s.map
	var seen := _reach(map)
	var walk := 0
	for i in map.tiles.size():
		if map.defs[map.tiles[i]].walkable:
			walk += 1
	assert_eq(seen.size(), walk, "걸을 수 있는 칸은 모두 도착에서 닿는다")
	var steles := s.features.list.filter(func(e: Dictionary) -> bool: return e["id"] == "forest_stele")
	assert_eq(steles.size(), 8, "포탈 비석 여덟")
	for e: Dictionary in steles:
		assert_true(FloorMap.DIRS4.any(func(d: Vector2i) -> bool: return seen.has((e["pos"] as Vector2i) + d)), "비석 %s 옆까지 걷는다" % e["pos"])
	var up: Dictionary = map.portals.filter(func(p: Dictionary) -> bool: return int(p.get("to_floor", 0)) == 3)[0]
	assert_true(bool(up["hidden"]) and not bool(up["found"]), "진짜 비석은 깨우기 전엔 포탈로 보이지 않는다")
	assert_true(steles.any(func(e: Dictionary) -> bool: return e["pos"] == up["pos"]), "진짜 = 비석 여덟 중 하나")
	var fake: Dictionary = steles.filter(func(e: Dictionary) -> bool: return e["pos"] != up["pos"])[0]
	s.features.act(s, fake["pos"], "wake")
	assert_eq(map.tile_id_at(fake["pos"]), "f2g_stele_dead", "가짜는 돌덩이")
	assert_true(bool(up["hidden"]), "가짜를 깨워도 포탈은 그대로 숨어 있다")
	var real: Dictionary = steles.filter(func(e: Dictionary) -> bool: return e["pos"] == up["pos"])[0]
	s.features.act(s, real["pos"], "wake")
	assert_eq(map.tile_id_at(real["pos"]), "f2g_portal_up", "진짜는 걸어 들어가는 포탈 칸")
	assert_true(map.is_walkable(real["pos"]) and not bool(up["hidden"]) and bool(up["found"]), "포탈이 드러난다")


func test_real_stele_changes_by_expedition() -> void:
	var picks := {}
	for sd in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]:
		var def := db.get_entry("floors", FOREST)
		var map := ContentRegistries.new().generator("fields").generate(db, def, Rng.new(sd))
		picks[map.anchors["stele_real"]] = true
	assert_true(picks.size() >= 3, "원정마다 진짜 비석이 바뀐다: %d곳" % picks.size())


func test_hidden_traps_on_paths() -> void:
	var s := _session(4, false)
	var hz := s.features.hazards
	assert_true(hz.at.size() >= 60, "덫 칸이 많다: %d" % hz.at.size())
	var cell: Vector2i = hz.at.keys()[0]
	assert_eq(s.map.tile_id_at(cell), "f2g_path", "숨은 덫은 오솔길처럼 보인다")
	var hp := s.player.pool.get_current("hp")
	var r: Variant = hz.on_step(s, cell)
	assert_true(r is bool, "밟으면 판정한다")
	assert_true(str(s.map.tile_id_at(cell)) in ["f2g_snare", "f2g_pit", "f2g_spike"], "밟은 덫은 드러난다")
	if not bool(r):
		assert_true(s.player.pool.get_current("hp") < hp, "걸리면 다친다")


func test_village_horde_and_hobgoblin_escort() -> void:
	var s := _session(5, true)
	var village := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.region == "f2g_village")
	assert_eq(village.size(), 3, "마을 큰 무리 셋")
	var outer := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.region == "f2g_outer")
	assert_true(outer.size() >= 5, "바깥 고리 무리")
	for g: FieldMonsters.Group in outer:
		assert_eq(g.monster_ids[0], "hobgoblin", "대장 = 홉고블린")
		assert_true(g.monster_ids.size() >= 3 and g.monster_ids.slice(1).all(func(id: String) -> bool: return id == "goblin"), "고블린 졸개 둘셋")
	s.detach()
