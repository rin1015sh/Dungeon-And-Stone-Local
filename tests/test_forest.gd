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


func test_route_map_one_stele() -> void:
	var s := _session(3, false)
	var map := s.map
	var seen := _reach(map)
	var walk := 0
	for i in map.tiles.size():
		if map.defs[map.tiles[i]].walkable:
			walk += 1
	assert_eq(seen.size(), walk, "걸을 수 있는 칸은 모두 도착에서 닿는다")
	var ups := map.portals.filter(func(p: Dictionary) -> bool: return int(p.get("to_floor", 0)) == 3)
	assert_eq(ups.size(), 1, "3층 비석은 하나")
	var nodes: Dictionary = map.anchors["nodes"]
	assert_eq(ups[0]["pos"], nodes["old_tree"], "북쪽 끝 늙은 고목 아래")
	assert_true(seen.has(ups[0]["pos"]), "걸어서 닿는다")
	for id in ["chief", "gully", "ford", "bridge", "mush", "hunter_camp"]:
		assert_true(seen.has(nodes[id]) or not map.is_walkable(nodes[id]), "구간 %s까지 걷는다" % id)
	assert_true(map.def_at(nodes["ford"]).sunk, "개울 여울은 낮은 땅")


## 세 갈래가 모두 고목에 닿는다 — 마을을 지나지 않고도(서 · 동).
func test_three_ways_north() -> void:
	var s := _session(3, false)
	var map := s.map
	var nodes: Dictionary = map.anchors["nodes"]
	var vz := map.zone_ids.find("f2g_village")
	var avoid_village := func(q: Vector2i) -> bool: return map.zones[map.idx(q)] != vz
	var seen := {map.entry: true}
	var queue: Array[Vector2i] = [map.entry]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in FloorMap.DIRS4:
			var q := p + d
			if map.in_bounds(q) and not seen.has(q) and map.is_walkable(q) and avoid_village.call(q):
				seen[q] = true
				queue.append(q)
	assert_true(seen.has(nodes["old_tree"]), "마을을 피해서도 고목까지 간다(덫 골짜기 · 개울)")


func test_trap_fields_are_clustered() -> void:
	var s := _session(4, false)
	var hz := s.features.hazards
	var gz := s.map.zone_ids.find("f2g_gully")
	var in_gully := 0
	for p: Vector2i in hz.at:
		if s.map.zones[s.map.idx(p)] == gz:
			in_gully += 1
	assert_true(hz.at.size() >= 40, "덫 칸: %d" % hz.at.size())
	assert_true(in_gully * 10 >= hz.at.size() * 7, "덫은 덫 골짜기에 몰려 있다: %d / %d" % [in_gully, hz.at.size()])
	var cell: Vector2i = hz.at.keys()[0]
	var r: Variant = hz.on_step(s, cell)
	assert_true(r is bool, "밟으면 판정한다")
	assert_true(str(s.map.tile_id_at(cell)) in ["f2g_snare", "f2g_pit", "f2g_spike"], "밟은 덫은 드러난다")


## 망대 경보(FL22): 궁수가 살아 있는 망대 둘레에서 들키면 마을 큰 무리가 쫓아온다. 궁수를 먼저 잡으면 조용하다.
func test_watchtower_alarm() -> void:
	var s := _session(5, true)
	assert_true(s.watch != null and s.watch.towers().size() == 2, "망대 둘")
	var t: Dictionary = s.watch.towers()[0]
	var at: Vector2i = t["at"]
	var village := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.region == "f2g_village")
	assert_eq(village.size(), 3, "마을 큰 무리 셋")
	s.map.visible_now[s.map.idx(at)] = 1
	s.watch.on_enter(s, at + Vector2i(0, 3))
	assert_true(village.all(func(g: FieldMonsters.Group) -> bool: return g.alert_until > s.clock.total_hours), "들키면 마을 무리 모두가 쫓아온다")
	var t2: Dictionary = s.watch.towers()[1]
	s.monsters.groups.erase(t2["guard"])  # 궁수를 먼저 쓰러뜨렸다
	for g: FieldMonsters.Group in village:
		g.alert_until = -1.0
	var at2: Vector2i = t2["at"]
	s.map.visible_now[s.map.idx(at2)] = 1
	s.watch.on_enter(s, at2 + Vector2i(0, 2))
	assert_true(village.all(func(g: FieldMonsters.Group) -> bool: return g.alert_until < 0.0), "궁수가 없는 망대는 조용하다")
	s.detach()


func test_chief_and_brook_hunters() -> void:
	var s := _session(5, true)
	var nodes: Dictionary = s.map.anchors["nodes"]
	var chief := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.region == "" and g.monster_ids[0] == "hobgoblin" and g.monster_ids.size() == 5)
	assert_eq(chief.size(), 1, "족장 무리")
	assert_true(Vector2((chief[0] as FieldMonsters.Group).pos - (nodes["chief"] as Vector2i)).length() <= 6.0, "족장 움막에")
	var brook := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.region == "f2g_brook")
	assert_eq(brook.size(), 2, "개울 사냥꾼 무리 둘")
	for g: FieldMonsters.Group in brook:
		assert_eq(g.monster_ids, ["hobgoblin", "goblin_archer", "goblin_archer"] as Array[String], "홉고블린 + 궁수 둘")
	assert_true(s.features.list.any(func(e: Dictionary) -> bool: return e["id"] == "chief_chest"), "족장 궤짝")
	s.detach()
