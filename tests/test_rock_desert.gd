extends TestCase
## 2층 바위사막 1단계(LD14 — floor2.md §4, tools/f2r_layout.py): 1층 서쪽 포탈 · 횃불 옛길(돌 화로) · 모래 바다(걸으면 진동 → 샌드웜) ·
## 낮 열기(그늘 밖 — 허기 · 피로, 샘물로 식힘) · 오후 모래 폭풍.

const DESERT := "f2_rock_desert"


func _session(seed_value: int, monsters: bool) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", DESERT)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func _find(s: ExploreSession, pred: Callable) -> Vector2i:
	for i in s.map.tiles.size():
		var p := s.map.pos_of(i)
		if pred.call(p):
			return p
	return Vector2i(-1, -1)


func test_map_road_and_sea() -> void:
	assert_eq(FloorTravel.floor_for(db, "floor2_west"), DESERT)
	var s := _session(2, false)
	var seen := {s.map.entry: true}
	var queue: Array[Vector2i] = [s.map.entry]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in FloorMap.DIRS4:
			if s.map.in_bounds(p + d) and not seen.has(p + d) and s.map.is_walkable(p + d):
				seen[p + d] = true
				queue.append(p + d)
	assert_true(seen.has(s.map.center), "3층 포탈까지 걸어 닿는다")
	var fires := 0
	var sand := 0
	for i in s.map.tiles.size():
		var id := s.map.tile_id_at(s.map.pos_of(i))
		fires += 1 if id == "f2d_fire" else 0
		sand += 1 if id == "f2r_sand" else 0
	assert_true(fires >= 10, "옛길 돌 화로 줄: %d" % fires)
	assert_true(sand > 1000, "모래 바다: %d칸" % sand)
	s.detach()


func test_heat_shade_and_water() -> void:
	var s := _session(2, false)
	var open := _find(s, func(p: Vector2i) -> bool: return s.map.zone_at(p) == "f2r_road" and s.map.tile_id_at(p) == "f2d_hard" and not s.desert.shaded(s, p))
	assert_true(open.x >= 0 and s.relocate(open))
	s.pass_time(fposmod(12.0 - s.clock.hour_of_day(), 24.0))
	assert_true(s.player.statuses.has("heat"), "한낮 그늘 밖 = 열기")
	var f0 := s.player.fatigue.value
	s.pass_time(1.0)
	assert_true(s.player.fatigue.value > f0, "열기 속에서는 더 지친다")
	s.player.statuses.apply("refreshed")
	s.pass_time(0.1)
	assert_false(s.player.statuses.has("heat"), "샘물로 목을 축이면 열기가 풀린다")
	s.player.statuses.remove("refreshed")
	var shade := _find(s, func(p: Vector2i) -> bool: return s.map.is_walkable(p) and s.map.zone_at(p) == "f2r_road" and s.desert.shaded(s, p))
	assert_true(shade.x >= 0 and s.relocate(shade))
	s.pass_time(0.1)
	assert_false(s.player.statuses.has("heat"), "화로 · 잔해 · 바위산 그늘에선 없다")
	s.pass_time(fposmod(22.0 - s.clock.hour_of_day(), 24.0))
	assert_true(s.relocate(open))
	s.pass_time(0.1)
	assert_false(s.player.statuses.has("heat"), "밤엔 없다")
	s.detach()


func test_sand_sea_vibration_raises_worm() -> void:
	var s := _session(2, true)
	var sand := _find(s, func(p: Vector2i) -> bool: return s.map.tile_id_at(p) == "f2r_sand" and FloorMap.DIRS4.all(func(d: Vector2i) -> bool: return s.map.tile_id_at(p + d * 4) == "f2r_sand"))
	assert_true(sand.x >= 0)
	var keys: Array[String] = []
	s.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	var n := s.monsters.groups.size()
	var thr := 14
	for i in thr:
		s.desert.on_enter(s, sand)
	assert_true(keys.any(func(k: String) -> bool: return k.begins_with("field.sand_tremor")), "먼저 발밑이 떨린다(경고)")
	assert_eq(s.monsters.groups.size(), n + 1, "진동이 차면 샌드웜이 솟는다")
	assert_eq(s.monsters.groups[-1].state, FieldMonsters.STATE_CHASE)
	s.desert.vibration = 10.0
	s.last_move_hours = -1.0
	s.desert.update(s, 1.0)
	assert_eq(s.desert.vibration, 0.0, "서 있으면 진동이 가라앉는다")
	s.detach()
