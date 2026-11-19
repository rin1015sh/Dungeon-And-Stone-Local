extends TestCase
## 사건 덱(FloorIncidents — plans/expansion_f1_3_D §0, tools/floor_incidents.py): 원정마다 덱에서 몇 장을 뽑아 후보 자리에,
## 그날이 되면 이미 있는 장치(요소 · 지키는 무리 · 매복)로 놓는다.

const FLOORS := {"f1_crystal_cave": "crystal_cave", "f2_beast_den": "fields", "f2_land_of_dead": "fields",
	"f2_rock_desert": "fields", "f2_goblin_forest": "fields", "f3_pilgrim_road": "fields"}


func _session(fid: String, seed_value: int, monsters: bool = false) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", fid)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator(str(FLOORS[fid])).generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func test_every_floor_draws_and_places_its_deck() -> void:
	for fid: String in FLOORS:
		var s := _session(fid, 1)
		var cfg := JsonUtil.get_dict(s.floor_def, "incidents")
		assert_true(s.incidents != null, "%s 사건 덱" % fid)
		var nr := JsonUtil.get_array(cfg, "per_expedition")
		assert_true(s.incidents.chosen.size() >= 1 and s.incidents.chosen.size() <= int(nr[1]), "%s 뽑은 수 %d" % [fid, s.incidents.chosen.size()])
		var gap := JsonUtil.get_float(cfg, "gap", 40.0)
		for i in s.incidents.chosen.size():
			var a: Vector2i = s.incidents.chosen[i]["at"]
			assert_true(Vector2(a - s.map.entry).length() >= JsonUtil.get_float(cfg, "entry_gap", 20.0), "도착 칸에서 떨어져 있다")
			for j in range(i + 1, s.incidents.chosen.size()):
				assert_true(Vector2(a - (s.incidents.chosen[j]["at"] as Vector2i)).length() >= gap, "사건끼리 떨어져 있다")
		s.clock.advance(24.0 * 9.5)
		s.incidents.update(s)
		for c: Dictionary in s.incidents.chosen:
			assert_true(bool(c["placed"]), "%s %s — 날이 지나면 놓였거나 버렸다" % [fid, c["def"]["id"]])


func test_every_candidate_spot_exists() -> void:
	for fid: String in FLOORS:
		var s := _session(fid, 2)
		for d: Variant in JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "incidents"), "pool"):
			for alt: Variant in JsonUtil.get_array(d as Dictionary, "any"):
				assert_true(FloorIncidents._base(s, alt as Dictionary).x >= 0, "%s %s 후보 %s" % [fid, (d as Dictionary)["id"], str(alt)])


func test_incident_features_appear_on_their_day() -> void:
	var s := _session("f2_land_of_dead", 3)
	var deck := {"per_expedition": [1, 1], "pool": [{"id": "t", "days": [2, 5], "any": [{"node": "graveyard", "at": [6, 6]}],
		"features": [{"event": "knocking_grave"}]}]}
	s.floor_def = s.floor_def.duplicate()
	s.floor_def["incidents"] = deck
	var fi := FloorIncidents.build(s)
	var count := func() -> int: return s.features.list.filter(func(e: Dictionary) -> bool: return str(e["id"]) == "knocking_grave").size()
	var before: int = count.call()
	assert_false(bool(fi.chosen[0]["placed"]), "1일 차에는 아직 없다")
	s.clock.advance(25.0)
	fi.update(s)
	assert_eq(int(count.call()), before + 1, "2일 차에 놓인다")


func test_decks_differ_between_expeditions() -> void:
	var seen := {}
	for seed_value in [1, 2, 3, 4, 5]:
		var s := _session("f2_rock_desert", seed_value)
		var ids := s.incidents.ids()
		ids.sort()
		seen[str(ids) + str(s.incidents.chosen.map(func(c: Dictionary) -> Vector2i: return c["at"]))] = true
	assert_true(seen.size() > 1, "원정마다 뽑은 사건 · 자리가 다르다")
