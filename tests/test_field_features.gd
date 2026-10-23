extends TestCase
## 1층 동굴 요소(data/events — FieldFeatures·FieldFeatureAct·FieldFeaturePlacer): 고정 지도 배치, 뒤지기·줍기·마시기·씻기·담기,
## 하루 한 번·한 번만, 숨은 물건 탐지, 함정, 지키는 무리, 노움 경보, 공물, 모닥불 휴식, 근처 문구, 피로 효과.

const FLOOR := "f1_crystal_cave"

var _reg: ContentRegistries


func _def() -> Dictionary:
	return db.get_entry("floors", FLOOR)


func _session(monsters: bool = false, seed_value: int = 5) -> ExploreSession:
	if _reg == null:
		_reg = ContentRegistries.new()
	var map := _reg.generator("crystal_cave").generate(db, _def(), Rng.new(seed_value))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {})
	var s := ExploreSession.new(db, _def(), map, pc, GameClock.new(), Rng.new(seed_value + 1), _reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


## 그 종류의 첫 요소 자리.
func _first(s: ExploreSession, id: String) -> Vector2i:
	for f: Dictionary in s.map.features:
		if str(f["id"]) == id:
			return f["pos"]
	return Vector2i(-1, -1)


## 요소 옆(또는 위)의 걸을 수 있는 칸으로 옮긴다.
func _stand_at(s: ExploreSession, at: Vector2i) -> bool:
	return s.relocate(at)


func _keys(s: ExploreSession) -> Array[String]:
	var keys: Array[String] = []
	s.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	return keys


func test_baked_map_places_every_feature_on_walkable_cells() -> void:
	var s := _session()
	var counts := {}
	for f: Dictionary in s.map.features:
		counts[f["id"]] = int(counts.get(f["id"], 0)) + 1
		assert_true(s.map.is_walkable(f["pos"]), "%s %s는 걸을 수 있는 칸" % [f["id"], f["pos"]])
		assert_false(s.map.is_dark(f["pos"]) and not JsonUtil.get_dict(db.get_entry("tiles", s.map.tile_id_at(f["pos"])), "light").is_empty(),
			"암흑지대에 빛나는 요소 없음")
	for spec: Variant in JsonUtil.get_array(_def(), "features"):
		var sd: Dictionary = spec
		assert_eq(int(counts.get(sd["event"], 0)), int(sd["count"]), "%s 개수" % sd["event"])
	var zone_of := {"wolf_den": "east", "gnome_stash": "west", "ghoul_feast": "south", "goblin_camp": "north", "goblin_snare": "north"}
	for f: Dictionary in s.map.features:
		if zone_of.has(f["id"]):
			assert_eq(s.map.zone_at(f["pos"]), zone_of[f["id"]], "%s는 제 구역" % f["id"])
	assert_eq(CrossLayoutCheck.problems(s.map, CrossLayout.new(JsonUtil.get_dict(_def(), "gen"))).size(), 0, "요소를 놓아도 지도 검사 통과")


func test_corpse_search_once_gives_loot_and_zone_line() -> void:
	var s := _session()
	var at := _first(s, "explorer_corpse")
	assert_true(_stand_at(s, at))
	assert_eq(s.features.target_name(s), "탐험가의 시체")
	var keys := _keys(s)
	var before := s.player.inventory.ids().size() + s.player.inventory.count("magic_stone_9")
	s.interact()
	var zone := s.map.zone_at(at)
	assert_true(keys.any(func(k: String) -> bool: return k.begins_with("field.corpse.%s." % zone)), "구역별 상처 문구 (%s)" % [keys])
	s.interact()
	assert_eq(keys[-1], "field.corpse_done", "두 번째는 이미 뒤졌다")
	assert_true(s.player.inventory.ids().size() + s.player.inventory.count("magic_stone_9") >= before)


func test_spring_drink_wash_fill() -> void:
	var s := _session()
	var at := _first(s, "clear_spring")
	assert_true(_stand_at(s, at))
	var choices: Array[Vector2i] = []
	s.feature_choice.connect(func(p: Vector2i) -> void: choices.append(p))
	s.interact()
	assert_eq(choices, [at] as Array[Vector2i], "행동이 여럿이면 고르게 한다")
	assert_eq(s.features.actions_at(at).size(), 3)
	var keys := _keys(s)
	s.player.fatigue.set_value(30.0)
	s.features.act(s, at, "drink")
	assert_true(s.player.fatigue.value < 30.0, "마시면 피로가 풀린다")
	var after := s.player.fatigue.value
	s.features.act(s, at, "drink")
	assert_eq(keys[-1], "field.spring_full", "하루에 한 번")
	assert_eq(s.player.fatigue.value, after)
	s.clock.advance(24.0)
	s.features.act(s, at, "drink")
	assert_true(s.player.fatigue.value < after, "다음 날 다시 마실 수 있다")
	s.features.act(s, at, "wash")
	assert_eq(keys[-1], "field.spring_no_wound", "상처가 없으면 씻을 게 없다")
	s.player.statuses.apply("bleeding", 3)
	s.features.act(s, at, "wash")
	assert_false(s.player.statuses.has("bleeding"), "씻으면 출혈이 멎는다")
	s.features.act(s, at, "fill")
	assert_eq(s.player.inventory.count("spring_water"), 1, "샘물 병")
	s.player.fatigue.set_value(20.0)
	assert_true(s.use_item("spring_water"))
	assert_true(s.player.fatigue.value < 20.0, "샘물 병을 마시면 피로가 풀린다")


func test_pickups_clear_and_offering_needs_stone() -> void:
	var s := _session()
	var at := _first(s, "glow_mushroom")
	assert_true(_stand_at(s, at))
	s.interact()
	assert_true(s.player.inventory.count("crystal_mushroom") >= 1, "버섯을 땄다")
	assert_eq(s.map.tile_id_at(at), "cave_floor", "딴 자리는 바닥으로")
	assert_eq(s.features.target_name(s), "", "다 딴 버섯은 살필 수 없다")
	var off := _first(s, "offering_pile")
	assert_true(_stand_at(s, off))
	var keys := _keys(s)
	s.player.inventory.remove("magic_stone_9", s.player.inventory.count("magic_stone_9"))
	s.features.act(s, off, "offer")
	assert_eq(keys[-1], "field.offering_no_stone")
	s.player.inventory.add("magic_stone_9", 2)
	s.features.act(s, off, "offer")
	assert_eq(s.player.inventory.count("magic_stone_9"), 1, "마석 하나를 바쳤다")
	s.features.act(s, off, "take")
	assert_true(s.player.inventory.count("magic_stone_9") >= 3, "공물을 집어 들었다")


func test_hidden_cache_must_be_found_first() -> void:
	var s := _session()
	var at := _first(s, "hidden_cache")
	assert_eq(s.map.tile_id_at(at), "cave_floor", "숨은 돌무더기는 바닥처럼 보인다")
	assert_true(_stand_at(s, at))
	var e: Dictionary = s.features._by_cell[at]
	assert_true(e.has("rolled"), "옆에 오면 탐지 판정을 한 번 한다")
	e["found"] = true  # 판정 결과와 무관하게 찾은 뒤의 동작을 본다
	assert_eq(s.features.target_name(s), "돌무더기")
	s.interact()
	var got := s.player.inventory.count("ration") + s.player.inventory.count("minor_potion") + s.player.inventory.count("torch")
	assert_true(got > 0, "꾸러미를 찾았다")


func test_snares_are_hazards_in_the_north() -> void:
	var s := _session()
	assert_true(s.features.hazards.at.size() >= 10 * 5, "함정·비탈 묶음이 깔렸다")
	var snare_cells := 0
	for p: Vector2i in s.features.hazards.at:
		var hd: Dictionary = s.features.hazards.at[p]
		if str(hd.get("id")) == "goblin_snare":
			snare_cells += 1
			assert_eq(s.map.zone_at(p), "north")
			assert_eq(s.map.tile_id_at(p), "cave_floor", "숨은 덫은 바닥처럼 보인다")
	assert_true(snare_cells > 0)
	var any: Vector2i = s.features.hazards.at.keys()[0]
	var hd_of_any: Dictionary = s.features.hazards.at[any]
	var hp := s.player.pool.get_current("hp")
	assert_true(s.relocate(any))
	assert_false(s.features.hazards.at.has(any), "밟은 묶음은 판정 뒤 다시 발동하지 않는다")
	assert_eq(s.map.tile_id_at(any), JsonUtil.get_str(hd_of_any, "tile"), "밟은 덫·비탈은 드러난 채 남는다")
	assert_true(s.player.pool.get_current("hp") <= hp)


func test_guards_and_gnome_alert() -> void:
	var s := _session(true)
	for id: String in ["wolf_den", "goblin_camp"]:
		var at := _first(s, id)
		var near := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return Vector2(g.home - at).length() <= 3.0)
		assert_true(not near.is_empty(), "%s를 지키는 무리" % id)
	var stash := _first(s, "gnome_stash")
	for other in s.monsters.groups.duplicate():
		if Vector2(other.pos - stash).length() < 3.0:
			s.monsters.groups.erase(other)
	var spot := Vector2i(-1, -1)
	for r in range(4, 12):
		for d in FloorMap.DIRS4:
			if spot.x < 0 and s.map.is_walkable(stash + d * r):
				spot = stash + d * r
	var g := s.monsters.add_fixed(["gnome"], spot)
	assert_true(g != null and _stand_at(s, stash))
	s.interact()
	assert_true(g.alert_until > s.clock.total_hours, "은닉처를 건드리면 노움이 쫓아온다")
	assert_eq(g.state, FieldMonsters.STATE_CHASE)


func test_wolf_den_teaches_bestiary_and_campfire_rest_bonus() -> void:
	var s := _session()
	var den := _first(s, "wolf_den")
	assert_true(_stand_at(s, den))
	s.interact()
	assert_true(s.player.knowledge.knows_stats("blade_wolf"), "늑대 잠자리를 살피면 도감에 습성")
	var fire := _first(s, "dead_campfire")
	assert_true(s.features.rest_bonus(fire) < 0.0)
	assert_eq(s.features.rest_bonus(_first(s, "cairn")), 0.0, "모닥불에서 먼 곳은 보너스 없음")
	assert_true(_stand_at(s, fire))
	s.player.fatigue.set_value(60.0)
	s.rest()
	var by_fire := s.player.fatigue.value
	var t := _session()
	assert_true(t.relocate(_first(t, "cairn")))
	t.player.fatigue.set_value(60.0)
	t.rest()
	assert_true(by_fire < t.player.fatigue.value, "모닥불 곁에서 쉬면 피로가 더 풀린다 (%.1f < %.1f)" % [by_fire, t.player.fatigue.value])


func test_near_notice_once() -> void:
	var s := _session()
	var at := _first(s, "rot_smell")
	var keys := _keys(s)
	assert_true(s.relocate(at))
	assert_eq(keys.count("field.rot_smell"), 1, "썩은 냄새 문구")
	assert_true(s.relocate(at + Vector2i(1, 0)) or s.relocate(at + Vector2i(0, 1)) or s.relocate(at + Vector2i(-1, 0)))
	assert_eq(keys.count("field.rot_smell"), 1, "한 번만")


func test_fatigue_effect_and_mushroom() -> void:
	var s := _session()
	s.player.fatigue.set_value(0.0)
	s.player.inventory.add("spring_water", 1)
	assert_false(s.use_item("spring_water"), "지친 데가 없으면 쓰지 않는다")
	assert_eq(s.player.inventory.count("spring_water"), 1)
	s.player.pool.set_current("hunger", 10.0)
	s.player.inventory.add("crystal_mushroom", 1)
	assert_true(s.use_item("crystal_mushroom"))
	assert_true(s.player.pool.get_current("hunger") > 10.0, "버섯으로 허기를 조금 채운다")
