extends TestCase
## 원정마다 바뀌는 자리(plans/expansion_f1_3_E §3 ② — RouteSpots.pick, tools/route_variety.py): route_spots 항목의
## "any"(자리 후보 중 하나) · "appear"(나올 확률). 고정 지도는 그대로, 매복 · 지키는 무리 · 숨은 물건 자리만 원정마다 다르다.

const FLOORS := ["f2_beast_den", "f2_goblin_forest", "f2_land_of_dead", "f2_rock_desert"]


func _session(fid: String, seed_value: int) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", fid)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = false
	s.start()
	return s


func test_every_alternative_spot_exists() -> void:
	for fid: String in FLOORS:
		var s := _session(fid, 1)
		var rs := JsonUtil.get_dict(s.floor_def, "route_spots")
		var n := 0
		for lst: String in ["guards", "features", "ambush"]:
			for it: Variant in JsonUtil.get_array(rs, lst):
				for alt: Variant in JsonUtil.get_array(it as Dictionary, "any"):
					n += 1
					assert_true(RouteSpots._anchor(s, alt as Dictionary).x >= 0, "%s %s 후보 자리 %s가 지도에 있다" % [fid, lst, str(alt)])
				var ap := JsonUtil.get_float(it as Dictionary, "appear", 1.0)
				assert_true(ap > 0.0 and ap <= 1.0, "appear는 0~1")
		assert_true(n > 0 or fid == "f2_rock_desert", "%s에 자리 후보가 있다" % fid)


func test_pick_follows_any_and_appear() -> void:
	var s := _session("f2_rock_desert", 1)
	var d := {"mark": "dune_w", "monsters": ["gnome"], "any": [{"mark": "plaza"}, {"mark": "cave", "at": [1, 1]}]}
	var seen := {}
	for i in 20:
		var p := RouteSpots.pick(s, d)
		seen[str(p["mark"])] = true
		assert_true(p["monsters"] == ["gnome"], "자리 말고는 그대로")
	assert_true(seen.has("plaza") and seen.has("cave") and not seen.has("dune_w"), "후보 중에서만 고른다")
	var none := 0
	for i in 40:
		none += 1 if RouteSpots.pick(s, {"mark": "plaza", "appear": 0.5}).is_empty() else 0
	assert_true(none > 5 and none < 35, "appear 0.5면 반쯤 빠진다")
	assert_true(RouteSpots.pick(s, {"mark": "plaza"}) == {"mark": "plaza"}, "키가 없으면 그대로")


func test_ambush_spots_differ_between_expeditions() -> void:
	var sets := {}
	for seed_value in [1, 2, 3, 4]:
		var s := _session("f2_land_of_dead", seed_value)
		var spots := s.ambush.spots()
		spots.sort()
		sets[str(spots)] = true
	assert_true(sets.size() > 1, "망자의 땅 길목 매복이 원정마다 다르다")


## 2 · 3층 다른 탐험가(CP-12 — tools/floor_explorers.py): 그 층 마석으로 거래하고, 날마다 신참 · 약탈자가 찬다.
func test_upper_floors_have_explorers_with_floor_stone() -> void:
	var stones := {"f2_rock_desert": "magic_stone_8", "f3_pilgrim_road": "magic_stone_7"}
	for fid: String in stones:
		var reg := ContentRegistries.new()
		var def := db.get_entry("floors", fid)
		var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
		var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(2)), pc, GameClock.new(), Rng.new(3), reg.effects)
		s.start()
		var ex := JsonUtil.get_dict(def, "explorers")
		assert_eq(FieldPartyMeet.stone(s), stones[fid], "%s 거래 마석" % fid)
		assert_eq(s.parties.of_kind(s, FieldParties.ROOKIE).size(), int(JsonUtil.get_array(ex, "rookies_by_day")[0]), "%s 1일 차 신참" % fid)
		assert_eq(JsonUtil.get_int(ex, "wounded_per_hour"), 0, "다친 탐험가 사건은 1층처럼 없다(사용자 2026-10-26)")
		var rookie: FieldMonsters.Group = s.parties.of_kind(s, FieldParties.ROOKIE)[0]
		rookie.party["trade"] = {"give": "ration", "n": 1, "price": 1}
		var opts := FieldPartyMeet.options(s, rookie)
		var trade: Dictionary = opts.filter(func(o: Dictionary) -> bool: return o["id"] == "trade")[0]
		assert_false(bool(trade["enabled"]), "그 층 마석이 없으면 못 산다")
		pc.inventory.add(stones[fid], 1)
		FieldPartyMeet.act(s, rookie, "trade")
		assert_eq(pc.inventory.count(stones[fid]), 0, "그 층 마석으로 값을 낸다")
		assert_true(pc.inventory.count("ration") >= 1)
