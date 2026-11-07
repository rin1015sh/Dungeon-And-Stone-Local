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


## 2단계(LD12): 새 몬스터 다섯이 제자리에 · 여왕을 쓰러뜨리면 벽두더지 매복이 멈춘다.
func test_new_beasts_and_queen_stops_moles() -> void:
	var s := _session(3, true)
	for id: String in ["moon_rock_bear", "mole_queen", "werewolf", "bulkar"]:
		assert_true(s.monsters.groups.any(func(g: FieldMonsters.Group) -> bool: return g.monster_ids.has(id)), "%s가 지도에 있다" % id)
	assert_eq(s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.monster_ids.has("bulkar")).size(), 3, "불카르 셋(바위 곁)")
	var holes := s.features.list.filter(func(e: Dictionary) -> bool: return e["id"] == "den_mole_holes")
	assert_eq(holes.size(), 3, "매복 앞 단서 셋")
	var spots := s.ambush.spots()
	var marks: Dictionary = s.map.anchors["marks"]
	var a: Vector2i = spots.filter(func(p: Vector2i) -> bool: return Vector2(p - (marks["mole_a"] as Vector2i)).length() < 4.0)[0]
	var n := s.monsters.groups.size()
	s.ambush.on_enter(s, a)
	assert_eq(s.monsters.groups.size(), n + 1, "여왕이 살아 있으면 벽에서 튀어나온다")
	for g: FieldMonsters.Group in s.monsters.groups.duplicate():
		if g.monster_ids.has("mole_queen"):
			s.monsters.groups.erase(g)  # 여왕을 쓰러뜨렸다
	var b: Vector2i = spots.filter(func(p: Vector2i) -> bool: return Vector2(p - (marks["mole_b"] as Vector2i)).length() < 4.0)[0]
	n = s.monsters.groups.size()
	s.ambush.on_enter(s, b)
	assert_eq(s.monsters.groups.size(), n, "여왕이 쓰러지면 매복도 멈춘다")
	s.detach()


## 높낮이(레벨 디자인 11차): 뼈 무덤 구덩이 · 곰굴 마른 개울은 낮은 땅 — 비탈로 내려가 닿는다(돌무더기에 막히지 않는다).
func test_sunken_pit_and_wash_reachable() -> void:
	var s := _session(3, false)
	var seen := _reach(s.map)
	var low := 0
	var ramps := 0
	for p: Vector2i in seen:
		var d := s.map.def_at(p)
		low += 1 if d.sunk else 0
		ramps += 1 if d.ramp else 0
	assert_true(low > 60, "닿는 낮은 땅 %d칸" % low)
	assert_true(ramps >= 8, "비탈 %d칸" % ramps)
	var marks: Dictionary = s.map.anchors.get("marks", {})
	for nm: String in ["bone_pit", "bear_cave"]:
		assert_true(seen.has(marks[nm]), "%s에 닿는다" % nm)
	assert_true(s.map.def_at(marks["bone_pit"]).sunk, "뼈 무덤은 구덩이 바닥")
	s.detach()
