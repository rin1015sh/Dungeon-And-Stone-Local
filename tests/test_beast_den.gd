extends TestCase
## 2층 짐승의 소굴 1단계(LD11 — floor2.md §2, tools/f2b_layout.py): 1층 동쪽 포탈에서 온다 · 고리 셋 · 갈림길 셋(원정마다 바른 갈래 하나,
## 나머지는 끝이 무너진 돌로 막힘 · 입구 단서) · 바위턱 · 늑대 무리.

const DEN := "f2_beast_den"


func _session(seed_value: int, monsters: bool) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", DEN)
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


func test_east_portal_leads_to_den() -> void:
	assert_eq(FloorTravel.floor_for(db, "floor2_east"), DEN)


func test_forks_one_way_open_each_expedition() -> void:
	var picks := {}
	for seed_value in [1, 2, 3, 4, 5, 6]:
		var s := _session(seed_value, false)
		assert_true(s.forks != null and s.forks.right.size() == 3, "갈림길 셋")
		var seen := _reach(s.map)
		assert_true(seen.has(s.map.center), "시드 %d: 3층 포탈까지 걸어 닿는다" % seed_value)
		var marks: Dictionary = s.map.anchors["marks"]
		var forks := JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "forks")
		for i in forks.size():
			var br := JsonUtil.get_array(forks[i], "branches")
			var pick: int = s.forks.right[i]
			for k in br.size():
				var blk: Vector2i = marks[JsonUtil.get_str(br[k], "block")]
				assert_eq(s.map.is_walkable(blk), k == pick, "시드 %d 갈림길 %d 갈래 %d: 바른 갈래만 열려 있다" % [seed_value, i, k])
				var mouth: Vector2i = marks[JsonUtil.get_str(br[k], "mouth")]
				var want := JsonUtil.get_str(forks[i], "right" if k == pick else "wrong")
				assert_true(s.features.list.any(func(e: Dictionary) -> bool: return e["pos"] == mouth and e["id"] == want),
					"입구 단서 %s" % want)
		picks[str(s.forks.right)] = true
		s.detach()
	assert_true(picks.size() >= 2, "원정마다 바른 갈래가 바뀐다: %s" % str(picks.keys()))


func test_wolves_and_ledges() -> void:
	var s := _session(3, true)
	for z: String in ["f2b_outer", "f2b_wall", "f2b_deep"]:
		assert_true(s.monsters.groups.any(func(g: FieldMonsters.Group) -> bool: return g.region.begins_with(z)), "%s에 무리" % z)
	var ledges := s.features.list.filter(func(e: Dictionary) -> bool: return e["id"] == "watch_post")
	assert_eq(ledges.size(), 3, "바위턱 셋(갈림길을 내려다본다)")
	var seen := _reach(s.map)
	for e: Dictionary in ledges:
		assert_true(FloorMap.DIRS4.any(func(d: Vector2i) -> bool: return seen.has((e["pos"] as Vector2i) + d)) or seen.has(e["pos"]), "바위턱에 오른다")
	s.detach()
