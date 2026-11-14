extends TestCase
## 3층 순례자의 길(docs/plans/floor3.md — tools/f3_layout.py): 2층 네 길의 포탈 → 서로 다른 출발점 · 모든 출발점에서 중심 4층 포탈까지 걸어 닿음 ·
## 필드 11곳 · 마녀의 숲(필드 효과 · 마녀의 눈 · 카나바로 · 환각) · 마녀의 오두막(입구 · 정원 · 제물 · 설원 · 히든 피스) · 밤하늘 · 오크 제단.

const F3 := "f3_pilgrim_road"
const DESTS := {"floor3_from_den": "f3_steel", "floor3_from_desert": "f3_dusk", "floor3_from_dead": "f3_estuary", "floor3_from_forest": "f3_greentail"}

static var _maps: Dictionary = {}  # 출발 dest → 지도(생성 1~2초 — 테스트끼리 나눠 쓴다)


func _def(dest: String) -> Dictionary:
	var def := db.get_entry("floors", F3).duplicate()
	def["_arrive"] = dest
	return def


func _map(dest: String) -> FloorMap:
	if not _maps.has(dest):
		_maps[dest] = ContentRegistries.new().generator("fields").generate(db, _def(dest), Rng.new(1))
	return _maps[dest]


func _session(dest: String = "floor3_from_forest", monsters: bool = false) -> ExploreSession:
	var reg := ContentRegistries.new()
	var map: FloorMap = ContentRegistries.new().generator("fields").generate(db, _def(dest), Rng.new(1))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, _def(dest), map, pc, GameClock.new(), Rng.new(7), reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func _reach(map: FloorMap, from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in FloorMap.DIRS4:
			if map.in_bounds(p + d) and not seen.has(p + d) and map.is_walkable(p + d):
				seen[p + d] = true
				queue.append(p + d)
	return seen


func _find(s: ExploreSession, pred: Callable) -> Vector2i:
	for i in s.map.tiles.size():
		var p := s.map.pos_of(i)
		if pred.call(p):
			return p
	return Vector2i(-1, -1)


func test_four_routes_arrive_at_different_fields_and_reach_the_portal() -> void:
	var entries := {}
	for dest: String in DESTS:
		assert_eq(FloorTravel.floor_for(db, dest), F3, "2층 포탈 %s → 3층" % dest)
		var map := _map(dest)
		assert_eq(map.zone_at(map.entry), DESTS[dest], "%s 출발점 구역" % dest)
		assert_false(entries.has(map.entry), "출발점이 서로 다르다")
		entries[map.entry] = true
		var seen := _reach(map, map.entry)
		assert_true(seen.has(map.center), "%s에서 중심 4층 포탈까지 걸어 닿는다" % dest)
		assert_eq(map.zone_at(map.center), "f3_heart", "4층 포탈은 중심부")
		var up: Dictionary = map.portals.filter(func(p: Dictionary) -> bool: return int(p.get("to_floor", 0)) == 4)[0]
		assert_eq(up["pos"], map.center)


func test_fields_are_wide_and_connected() -> void:
	var map := _map("floor3_from_forest")
	var seen := _reach(map, map.entry)
	var per_zone := {}
	for p: Vector2i in seen:
		per_zone[map.zone_at(p)] = int(per_zone.get(map.zone_at(p), 0)) + 1
	var fields := 0
	for z: String in per_zone:
		if z != "f3_hut" and int(per_zone[z]) > 1500:
			fields += 1
	assert_true(fields >= 11, "넓은 필드 11곳 이상이 한 덩어리로 이어진다: %s" % [per_zone])
	assert_true(seen.size() > 60000, "1 · 2층보다 넓은 걸을 수 있는 땅: %d칸" % seen.size())
	assert_false(per_zone.has("f3_hut"), "마녀의 오두막은 걸어서 닿지 않는다(보랏빛 나무로만)")
	assert_true(per_zone.has("f3_witch") and int(per_zone["f3_witch"]) > int(per_zone.get("f3_steel", 0)), "마녀의 숲이 가장 넓다")


func test_temple_is_not_needed_for_the_portal() -> void:
	var map := _map("floor3_from_forest")
	var blocked := map.tiles.duplicate()
	for i in map.tiles.size():
		if map.zones[i] == map.zone_ids.find("f3_temple") and map.defs[map.tiles[i]].walkable:
			map.tiles[i] = map.index_of("f3_rise")
	assert_true(_reach(map, map.entry).has(map.center), "조각 사원을 지나지 않아도 중심에 닿는다")
	map.tiles = blocked


func test_witch_forest_effects_and_hunter() -> void:
	var s := _session("floor3_from_forest", true)
	var w := s.pilgrim.witch
	var spot := _find(s, func(p: Vector2i) -> bool: return s.map.zone_at(p) == "f3_witch" and s.map.is_walkable(p) and s.monsters.group_at(p) == null \
		and Vector2(p - s.map.center).length() > 80.0)
	assert_true(spot.x >= 0 and s.relocate(spot))
	s.pass_time(0.01)
	for st in ["f3_disoriented", "f3_hallucination", "f3_auditory", "f3_pain"]:
		assert_true(s.player.statuses.has(st), "숲 안: " + st)
	assert_false(s.pilgrim.remembers(s), "방향치 — 지나온 길이 기억에 남지 않는다")
	assert_near(w.wait_hours(), 1.0, 0.001, "1일 차 한곳 한도 약 1시간")
	var keys: Array = []
	s.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	for g: FieldMonsters.Group in s.monsters.groups.duplicate():  # 다른 무리가 끼어들지 않게
		s.monsters.groups.erase(g)
	s.monsters.hold_contacts(1.0e9)
	for i in 12:
		s.pass_time(0.05)
	assert_true(keys.any(func(k: String) -> bool: return k.begins_with("f3.witch_omen")), "한도 60%에서 전조")
	assert_true(w.hunter == null, "아직 나오지 않았다")
	for i in 10:
		s.pass_time(0.05)
	assert_true(w.hunter != null and s.monsters.groups.has(w.hunter), "한곳에 1시간 — 카나바로")
	assert_eq(w.hunter.leader(), "canavaro")
	assert_true(Vector2(w.hunter.pos - s.pos).length() >= 6.0, "바로 옆이 아니라 떨어진 곳에서(대응할 틈)")
	var first := w.hunter
	for i in 30:
		s.pass_time(0.05)
	var hunters := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.leader() == "canavaro" and not WitchForest.is_phantom(g))
	assert_eq(hunters.size(), 1, "숲에 카나바로는 한 마리만")
	assert_true(w.hunter == first)
	s.detach()


func test_moving_resets_dwell_and_stage_shortens_wait() -> void:
	var s := _session()
	var w := s.pilgrim.witch
	var a := _find(s, func(p: Vector2i) -> bool: return s.map.zone_at(p) == "f3_witch" and s.map.is_walkable(p))
	assert_true(s.relocate(a))
	s.pass_time(0.01)
	s.pass_time(0.3)
	assert_true(w.dwell > 0.2, "서 있으면 쌓인다")
	var b := _find(s, func(p: Vector2i) -> bool: return s.map.zone_at(p) == "f3_witch" and s.map.is_walkable(p) and Vector2(p - a).length() > 20.0)
	assert_true(s.relocate(b))
	s.pass_time(0.01)
	assert_true(w.dwell < 0.05, "한곳을 벗어나면 그 자리에서 다시 센다")
	var out := _find(s, func(p: Vector2i) -> bool: return s.map.zone_at(p) == "f3_steel" and s.map.is_walkable(p))
	assert_true(s.relocate(out))
	s.pass_time(0.01)
	assert_true(w.dwell == 0.0 and not s.player.statuses.has("f3_hallucination"), "숲을 나가면 머문 시간 · 필드 효과가 풀린다")
	s.pass_time(13.0)
	assert_true(w.stage >= 1 and s.player.statuses.has("f3_witch_eye"), "숲에 든 지 12시간 — 마녀의 눈(숲 밖에서도 흐른다)")
	s.pass_time(36.0)
	assert_true(w.stage >= 3 and w.wait_hours() < 0.2, "3일 차 약 10분")
	s.pass_time(100.0)
	assert_eq(w.stage, 10, "최고 10단계")
	assert_near(w.wait_hours(), 0.05, 0.001, "10단계 약 3분")
	s.detach()


func test_hallucination_vanishes_without_battle() -> void:
	var s := _session("floor3_from_forest", true)
	var spot := _find(s, func(p: Vector2i) -> bool: return s.map.zone_at(p) == "f3_witch" and s.map.is_walkable(p) and Vector2(p - s.map.center).length() > 80.0)
	assert_true(s.relocate(spot))
	for g: FieldMonsters.Group in s.monsters.groups.duplicate():
		s.monsters.groups.erase(g)
	var seen := 0
	for i in 60:
		s.pass_time(0.05)
		for g: FieldMonsters.Group in s.monsters.groups:
			if WitchForest.is_phantom(g):
				seen += 1
				s.engage(g, false)
				assert_false(s.in_combat, "환각 무리는 닿아도 싸우지 않는다")
				break
		s.pilgrim.witch.dwell = 0.0  # 카나바로는 이 시험에서 부르지 않는다
	assert_true(seen > 0, "환각이 보인다")
	s.detach()


func test_witch_hut_entry_capacity_offering_and_expiry() -> void:
	var s := _session()
	var hut := s.pilgrim.hut
	var tree := hut.spawn(s)
	assert_true(tree.x >= 0 and s.map.tile_id_at(tree) == "f3_purple_tree", "보랏빛 나무")
	var beside := tree + Vector2i.DOWN
	assert_true(s.relocate(beside) or s.relocate(tree + Vector2i.LEFT) or s.relocate(tree + Vector2i.RIGHT))
	var mates: Array[PlayerCharacter] = []
	for i in 5:
		mates.append(PlayerCharacter.create(db, "human", "warrior", "동료%d" % i, {}))
	s.companions = mates
	var keys: Array = []
	s.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	s.interact()
	assert_true(keys.has("f3.hut_full") and not hut.inside(), "여섯 명은 못 들어간다(최대 5명)")
	s.companions = [] as Array[PlayerCharacter]
	s.interact()
	assert_true(hut.inside() and s.in_safe_zone(), "오두막 안은 안전지대")
	assert_eq(s.map.zone_at(s.pos), "f3_hut")
	s.pass_time(0.01)
	assert_false(s.player.statuses.has("f3_disoriented"), "필드 효과 해제")
	var left := hut.hours_left(s)
	assert_true(left > 7.0 and left <= 8.0, "8시간")
	var marks: Dictionary = s.map.anchors["marks"]
	assert_true(s.relocate(marks["hut_bonfire"] + Vector2i.DOWN))
	s.interact()
	assert_true(keys.has("f3.hut_offer_none"), "시신이 없으면 바치지 못한다")
	s.player.inventory.add("wrapped_corpse", 1)
	s.interact()
	assert_near(hut.hours_left(s), left - 0.01 + 8.0, 0.05, "시신 하나 = 8시간 연장")
	assert_false(s.player.inventory.has("wrapped_corpse"), "바친 시신은 사라진다(두 번 쓸 수 없다)")
	s.pass_time(17.0)
	assert_false(hut.inside(), "시간이 다 되면 숲으로 밀려난다")
	assert_eq(s.map.zone_at(s.pos), "f3_witch")
	s.detach()


func test_hut_after_riakis_turns_winter_and_hidden_piece_once() -> void:
	var s := _session()
	var hut := s.pilgrim.hut
	s.player.progression.lords_defeated["riakis"] = true
	var tree := hut.spawn(s)
	assert_true(s.relocate(tree + Vector2i.DOWN) or s.relocate(tree + Vector2i.LEFT))
	s.interact()
	assert_true(hut.inside())
	var snow := _find(s, func(p: Vector2i) -> bool: return s.map.tile_id_at(p) == "f3_hut_snow")
	assert_true(snow.x >= 0, "바깥은 설원")
	assert_true(_find(s, func(p: Vector2i) -> bool: return s.map.tile_id_at(p) == "f3_hut_shelf").x >= 0, "안은 그대로(책장)")
	var marks: Dictionary = s.map.anchors["marks"]
	assert_true(s.relocate(marks["hut_hearth"] + Vector2i.DOWN))
	s.interact()
	assert_true(s.player.progression.flags.has(WitchHut.FLAG_HIDDEN), "히든 피스 기록(저장)")
	assert_false(hut.inside(), "숲으로 추방")
	assert_true(hut.spawn(s).x < 0, "오두막은 다시 열리지 않는다")
	var saved := s.player.progression.to_dict()
	var p2 := Progression.new()
	p2.load_dict(saved)
	assert_true(p2.flags.has(WitchHut.FLAG_HIDDEN), "저장 · 불러오기")
	s.detach()


func test_sky_event_on_day_three_night() -> void:
	var s := _session("floor3_from_den")
	var sky := s.pilgrim.sky
	var h := 0.0
	while not sky.active() and h < 120.0:
		s.pass_time(0.5)
		h += 0.5
	assert_true(sky.active(), "3일 차 밤 — 은빛 구체")
	assert_true(h >= 48.0 and h < 76.0, "층에 든 지 이틀이 지난 첫 밤: %.1f시간" % h)
	assert_true(s.clock.hour_of_day() >= 20.0 or s.clock.hour_of_day() < 4.0, "밤")
	var v0 := s.vision_m
	sky.tick_real(s, 30.0)
	assert_true(sky.active() and sky.glow() > 0.5, "가운데쯤 가장 밝다")
	s.refresh_view()
	assert_true(s.vision_m >= v0, "밝아진다")
	sky.tick_real(s, 40.0)
	assert_true(sky.done() and sky.glow() == 0.0, "1분쯤 뒤 원래대로")
	s.detach()


func test_orc_altar_summons_heroes() -> void:
	var s := _session("floor3_from_den", true)
	var at := _find(s, func(p: Vector2i) -> bool: return s.map.tile_id_at(p) == "f3_orc_altar")
	assert_true(at.x >= 0, "오크 제단")
	assert_true(s.relocate(at + Vector2i.DOWN) or s.relocate(at + Vector2i.UP) or s.relocate(at + Vector2i.LEFT))
	var altar := s.pilgrim.altar
	s.player.inventory.add("magic_stone_7", 10)
	s.interact()
	assert_eq(altar.offered, 10, "바친 마석이 쌓인다")
	assert_false(altar.risen)
	altar.offered = altar.need() - 1
	s.player.inventory.add("magic_stone_7", 1)
	s.interact()
	assert_true(altar.risen, "다 차면 히든 보스")
	var bosses := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.leader() in ["orc_hero", "orc_lord"])
	assert_eq(bosses.size(), 1)
	s.detach()
