extends TestCase
## 필드 몬스터: 지역 스폰, 접촉·추적, 비선공, 은신, 유예, 리스폰·증가, 휴식 습격, 전투 결과 반영.

const FLOOR := "f1_crystal_cave"


func _session(d: GameDatabase = null, seed_value: int = 5) -> ExploreSession:
	var dbx := d if d != null else db
	var reg := ContentRegistries.new()
	var def := dbx.get_entry("floors", FLOOR)
	var map := reg.generator("crystal_cave").generate(dbx, def, Rng.new(seed_value))
	var pc := PlayerCharacter.create(dbx, "human", "warrior", "시험", {"agi": 8})
	var s := ExploreSession.new(dbx, def, map, pc, GameClock.new(), Rng.new(seed_value + 1), reg.effects)
	s.start()
	return s


## 15×15 빈 방 + 동쪽 지역 하나(monster_id)짜리 필드.
func _room_field(monster_id: String) -> FieldMonsters:
	var map := FloorMap.new(db, 15, 15, "rock_wall")
	for y in range(1, 14):
		for x in range(1, 14):
			map.set_tile(Vector2i(x, y), "cave_floor")
	map.center = Vector2i(7, 7)
	map.visible_now.fill(1)
	var def := {"regions": [{"id": "r", "dir": "east", "monsters": [monster_id]}],
		"spawn": {"groups_per_region": [1, 1], "respawn_hours": 24, "growth_every_hours": 24, "max_extra_groups": 2}}
	return FieldMonsters.new(db, map, def, Rng.new(1))


func _place(fm: FieldMonsters, monster_id: String, at: Vector2i) -> FieldMonsters.Group:
	var g := fm.spawn_group({"id": "r", "monsters": [monster_id]}, Vector2i(-99, -99), at)
	g.place(at)
	g.home = at
	return g


func _c(cell: Vector2i) -> Vector2:
	return Kinematics.center_of(cell)


func _move_hours(_monster_id: String) -> float:
	return float(db.bal("explore.move_hours_base"))


func test_initial_spawns_by_region() -> void:
	var s := _session()
	var fm := s.monsters
	assert_true(fm.groups.size() >= 8, "5지역(중심부·4팔) × 2~3무리 (%d)" % fm.groups.size())
	var bad := 0
	for g in fm.groups:
		for r: Variant in JsonUtil.get_array(s.floor_def, "regions"):
			if JsonUtil.get_str(r, "id") == g.region and not JsonUtil.get_array(r, "monsters").has(g.leader()):
				bad += 1
		if s.map.in_safe_zone(g.pos) or not s.map.is_walkable(g.pos):
			bad += 1
	assert_eq(bad, 0, "지역 몬스터·걸을 수 있는 칸·안전지대 밖")
	var east := fm.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.region == "f1_east")
	assert_true(not east.is_empty() and east.all(func(g: FieldMonsters.Group) -> bool: return g.pos.x > s.map.center.x and g.leader() == "blade_wolf"), "동쪽 팔은 칼날늑대만")


func test_bumping_a_group_starts_combat() -> void:
	var s := _session()
	var g: FieldMonsters.Group = s.monsters.groups[0]
	var spot := Vector2i(-1, -1)
	for d in FloorMap.DIRS4:
		if s.map.is_walkable(g.pos - d) and s.monsters.group_at(g.pos - d) == null:
			spot = g.pos - d
			break
	assert_true(ExploreDebug.teleport(s, spot))
	if s.in_combat:
		return  # 순간이동만으로 이미 붙었다(다른 무리) — 다음 단언은 건너뛴다
	var seen := [null, false]
	s.encounter.connect(func(group: FieldMonsters.Group, party_first: bool) -> void:
		seen[0] = group
		seen[1] = party_first)
	var t0 := s.clock.total_hours
	assert_true(s.try_move(g.pos - spot))
	assert_true(seen[0] == g and bool(seen[1]), "부딪히면 먼저 발견한 쪽으로 전투")
	assert_true(s.in_combat)
	assert_near(s.clock.total_hours, t0, 0.0001, "전투 시작에는 시간이 들지 않는다")
	assert_false(s.try_move(Vector2i(1, 0)), "전투 중에는 움직일 수 없다")


func test_chase_until_contact() -> void:
	var fm := _room_field("blade_wolf")
	var g := _place(fm, "blade_wolf", Vector2i(12, 7))
	g.facing = Vector2(-1, 0)  # 플레이어 쪽을 보고 있다(시야각 — test_monster_patrol)
	var player := Vector2i(8, 7)
	fm.set_player_moving(true)
	fm.update(_c(player), 0.01, 0.01, false)  # 먼저 멈칫하고 본다(의심 — 경계도가 차오르는 중, V22)
	assert_eq(g.state, FieldMonsters.STATE_SUSPECT)
	var t := 0.01
	for i in 20:  # 경계도가 차면 쫓는다(의심하는 동안은 서 있다)
		t += 0.002
		fm.update(_c(player), 0.002, t, false)
		if g.state == FieldMonsters.STATE_CHASE:
			break
	assert_eq(g.state, FieldMonsters.STATE_CHASE)
	var hit := fm.update(_c(player), fm._steer.move_hours("blade_wolf") * 3.0 + 0.00001, t + 0.1, false)
	assert_true(g.pos.x <= 9, "다가온다 (%s)" % str(g.pos))
	assert_true(hit == g, "붙으면 전투")


func test_non_aggressive_waits_and_grace() -> void:
	var fm := _room_field("ghoul")
	var g := _place(fm, "ghoul", Vector2i(12, 7))
	var player := Vector2i(3, 7)
	assert_true(fm.update(_c(player), _move_hours("ghoul") * 5.0, 0.0, false) == null, "구울은 멀리서는 덤비지 않는다")
	assert_true(g.state != FieldMonsters.STATE_CHASE)
	g.place(Vector2i(4, 7))
	g.facing = Vector2(-1, 0)  # 플레이어 쪽을 본다(등 돌리고 있으면 모른다 — V20)
	fm.set_player_moving(true)
	assert_true(fm.update(_c(player), 0.001, 0.001, false) == null, "구울은 먼저 덤비지 않으니 알아채기 전에는 싸우지 않는다")
	assert_true(fm.update(_c(player), 0.1, 0.1, false) == g, "바로 옆에서 알아채면 싸운다")
	fm.set_grace(g, 0.1)
	assert_true(fm.update(_c(player), 0.0, 0.1, false) == null, "도망친 직후에는 쫓지 않는다")
	fm.update(_c(player), 0.0, 1.0, false)
	assert_true(fm.update(_c(player), 0.1, 1.1, false) == g, "유예가 지나면 다시(다시 알아채고)")
	assert_true(fm.update(_c(player), 0.0, 1.1, true) == null, "안전지대에서는 덤비지 않는다")


func test_gnome_hides_until_close() -> void:
	var fm := _room_field("gnome")
	var g := _place(fm, "gnome", Vector2i(12, 7))
	assert_false(fm.is_visible(g, Vector2i(8, 7)), "4m 밖에서는 안 보인다")
	assert_true(fm.is_visible(g, Vector2i(10, 7)), "3m 안이면 보인다")


func test_respawn_and_growth() -> void:
	var fm := _room_field("goblin")
	var g := _place(fm, "goblin", Vector2i(12, 7))
	fm.remove(g, 0.0)
	assert_eq(fm.groups.size(), 0)
	fm.update(_c(Vector2i(2, 2)), 0.0, 10.0, false)
	assert_eq(fm.groups.size(), 0, "리스폰 전")
	fm.update(_c(Vector2i(2, 2)), 0.0, 25.0, false)
	assert_eq(fm.groups.size(), 2, "리스폰 + 하루 지나 1무리 증가")
	fm.update(_c(Vector2i(2, 2)), 0.0, 200.0, false)
	assert_eq(fm.groups.size(), 3, "증가는 최대 2무리까지")


func test_rest_outside_can_be_ambushed() -> void:
	var d := GameDatabase.new()
	d.load_all("res://data")
	(d.singletons["balance"]["monsters"] as Dictionary)["rest_ambush_chance_per_hour"] = 1.0
	var s := _session(d)
	s.monsters.groups.clear()
	var seen := [false]
	s.encounter.connect(func(_g: FieldMonsters.Group, party_first: bool) -> void: seen[0] = not party_first)
	var t0 := s.clock.total_hours
	s.rest()
	assert_true(seen[0], "잠결에 습격(적이 먼저)")
	assert_true(s.in_combat)
	assert_near(s.clock.total_hours - t0, 1.0, 0.0001, "첫 시간에 깨어난다")


func test_resolve_victory_and_flee() -> void:
	var s := _session()
	var g: FieldMonsters.Group = s.monsters.groups[0]
	var n := s.monsters.groups.size()
	s.engage(g, true)
	s.resolve_encounter(g, Battle.RESULT_VICTORY, 10)
	assert_false(s.in_combat)
	assert_eq(s.monsters.groups.size(), n - 1, "이긴 무리는 사라진다")
	assert_near(s.clock.total_hours, 10.0 * float(db.bal("combat.hours_per_turn")), 0.0001, "전투 차례만큼 시간이 흐른다")
	var g2: FieldMonsters.Group = s.monsters.groups[0]
	s.engage(g2, false)
	s.resolve_encounter(g2, Battle.RESULT_FLED, 1)
	assert_true(s.monsters.groups.has(g2), "도망치면 무리는 남는다")
	assert_true(g2.grace_until > s.clock.total_hours, "도망친 뒤 잠시 쫓지 않는다")
	var g3: FieldMonsters.Group = s.monsters.groups[1] if s.monsters.groups[0] == g2 else s.monsters.groups[0]
	var first := g3.monster_ids[0]
	var size := g3.monster_ids.size()
	s.engage(g3, false)
	s.resolve_encounter(g3, Battle.RESULT_FLED, 1, [first] as Array[String])
	if size > 1:
		assert_eq(g3.monster_ids.size(), size - 1, "쓰러뜨리고 도망치면 쓰러뜨린 몬스터는 무리에서 빠진다")
	else:
		assert_false(s.monsters.groups.has(g3), "다 쓰러뜨렸으면 도망쳐도 이긴 것")


## 플레이어가 가만히 있어도 실시간으로 몬스터가 다가와 전투가 시작되고, 전투 중에는 시간이 멈추고, 끝나면 다시 흐른다.
func test_monsters_move_in_realtime_while_player_stands_still() -> void:
	var s := _session()
	s.monsters.groups.clear()
	var spot := _straight_corridor(s, 4)
	assert_true(spot.size() == 2, "직선 4칸 빈 곳")
	if spot.size() != 2:
		return
	var at: Vector2i = spot[0]
	var dir: Vector2i = spot[1]
	assert_true(ExploreDebug.teleport(s, at))
	var region: Dictionary = JsonUtil.get_array(s.floor_def, "regions")[0]
	var g := s.monsters.spawn_group(region, Vector2i(-99, -99), at, "goblin")
	assert_true(g != null)
	g.place(at + dir * 4)
	g.home = g.pos
	g.facing = Vector2(-dir)  # 플레이어 쪽을 보고 있다
	var seen := [null]
	s.encounter.connect(func(group: FieldMonsters.Group, _pf: bool) -> void: seen[0] = group)
	var p0 := s.pos
	var g0 := g.pos
	for i in 100:
		if s.in_combat:
			break
		s.tick_realtime(0.05)
	assert_eq(s.pos, p0, "플레이어는 움직이지 않았다")
	assert_true(g.pos != g0, "몬스터는 스스로 다가왔다")
	assert_true(seen[0] == g and s.in_combat, "붙으면 전투가 시작된다")
	var t_combat := s.clock.total_hours
	for i in 20:
		s.tick_realtime(0.1)
	assert_near(s.clock.total_hours, t_combat, 0.0000001, "전투 중에는 탐험 시간이 멈춘다")
	s.resolve_encounter(g, Battle.RESULT_VICTORY, 5)
	assert_near(s.clock.total_hours - t_combat, 5.0 * float(db.bal("combat.hours_per_turn")), 0.0001, "전투가 끝나면 차례 수만큼 시간이 반영된다")
	var t_after := s.clock.total_hours
	s.tick_realtime(0.25)
	assert_true(s.clock.total_hours > t_after, "탐험으로 돌아오면 다시 흐른다")


## 안전지대 밖에서 한 방향으로 n칸 넘게 트인 자리 [위치, 방향]. 없으면 [].
func _straight_corridor(s: ExploreSession, n: int) -> Array:
	for i in s.map.tiles.size():
		var p := s.map.pos_of(i)
		if not s.map.is_walkable(p) or s.map.in_safe_zone(p):
			continue
		for d in FloorMap.DIRS4:
			var ok := true
			for k in range(1, n + 2):
				var q := p + d * k
				if not s.map.is_walkable(q) or s.map.in_safe_zone(q) or s.map.blocks_sight(q):
					ok = false
					break
			if ok:
				return [p, d]
	return []


## 보스가 기다리는 방(사용자 2026-10-18): 보스 등급이 있는 무리는 움직이지 않고, 화면에 들어오고 벽에 가리지 않으면 바로 전투(V16 → V19).
func test_boss_waits_then_engages() -> void:
	var map := FloorMap.new(db, 40, 12, "rock_wall")
	for x in range(1, 39):  # 긴 복도(y 3) + 벽 너머 나란한 복도(y 8)
		map.set_tile(Vector2i(x, 3), "cave_floor")
		map.set_tile(Vector2i(x, 8), "cave_floor")
	map.center = Vector2i(20, 3)
	map.visible_now.fill(1)
	var fm := FieldMonsters.new(db, map, {"regions": [], "spawn": {}}, Rng.new(1))
	var g := fm.add_fixed(["goblin", "blater"], Vector2i(30, 3))
	assert_eq(g.boss, "blater", "구성에 보스가 있으면 보스 방")
	var reach := MonsterSight.new(db, map).half.x  # 화면 반 폭(V19)
	assert_true(reach >= 8.0, "멀리서 마주쳐도 전투(%.1f칸)" % reach)
	var far := _c(Vector2i(30 - int(reach) - 3, 3))
	assert_true(fm.update(far, 2.0, 1.0, false) == null, "화면 밖이면 기다린다")
	assert_eq(g.pos, Vector2i(30, 3), "보스는 쫓아오지 않는다")
	assert_true(fm.update(_c(Vector2i(30, 8)), 0.01, 1.5, false) == null, "벽 너머면 가까워도 모른다")
	var near := _c(Vector2i(30 - int(floor(reach)), 3))
	map.visible_now.fill(0)
	assert_true(fm.update(near, 0.01, 2.0, false) == null, "화면 안이어도 플레이어 눈에 안 보이면(어둠·시야 밖) 아니다(V22)")
	map.visible_now.fill(1)
	assert_true(fm.update(near, 0.01, 2.0, false) == g, "보이면 바로 전투")
	var plain := fm.add_fixed(["goblin"], Vector2i(10, 10))
	assert_eq(plain.boss, "", "보스 없는 무리는 보통")
	var chain := fm.add_fixed(["goblin"], Vector2i(12, 3))
	chain.waves = [["katumba"]]
	fm.mark_boss(chain)
	assert_eq(chain.boss, "katumba", "연전 끝의 보스도 기다리는 방")


## 기다리던 보스가 알아채면 전투 직전에 한 줄(V17): 보스 등급 몬스터마다 제 문구가 있다.
func test_every_waiting_boss_has_a_notice_line() -> void:
	var ranks: Array = db.bal("monsters.boss_ranks", [])
	for id: String in db.get_collection("monsters"):
		if ranks.has(JsonUtil.get_str(db.get_entry("monsters", id), "rank")):
			assert_true(Strings.has("explore.boss_notice." + id), "%s 전투 직전 문구" % id)
