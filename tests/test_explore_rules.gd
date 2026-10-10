extends TestCase
## 탐험 규칙(ExploreSession): 이동 시간·충돌·허기·휴식·폐쇄·아사·아이템·발견·성능.

const FLOOR := "f1_crystal_cave"


func _session(seed_value: int = 5, agi: float = 0.0) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", FLOOR)
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(seed_value))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"agi": agi})
	var s := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(seed_value + 1), reg.effects)
	s.start()
	return s


func _open_dir(s: ExploreSession) -> Vector2i:
	for d in FloorMap.DIRS4:
		if s.map.is_walkable(s.pos + d):
			return d
	return Vector2i.ZERO


## 벽에 붙은 바닥 칸으로 옮기고 그 벽 방향을 돌려준다.
func _face_wall(s: ExploreSession) -> Vector2i:
	for i in s.map.tiles.size():
		var p := s.map.pos_of(i)
		if not s.map.is_walkable(p):
			continue
		for d in FloorMap.DIRS4:
			if not s.map.is_walkable(p + d):
				s.debug_teleport(p)
				return d
	return Vector2i.ZERO


func _b(path: String) -> float:
	return float(db.bal(path, 0.0))


func test_move_costs_time_by_agility() -> void:
	var s := _session(5, 0.0)
	assert_near(s.move_hours(), _b("explore.move_hours_base"), 0.000001, "민첩 0")
	var t0 := s.clock.total_hours
	assert_true(s.try_move(_open_dir(s)))
	assert_near(s.clock.total_hours - t0, s.move_hours(), 0.000001)
	var fast := _session(5, 50.0)
	assert_near(fast.move_hours(), _b("explore.move_hours_base") / (1.0 + 50.0 * _b("explore.move_agi_coef")), 0.000001)
	assert_true(fast.move_hours() < s.move_hours(), "민첩이 높으면 빠르다")


func test_bumping_a_wall_costs_nothing() -> void:
	var s := _session()
	var d := _face_wall(s)
	var t0 := s.clock.total_hours
	var p0 := s.pos
	assert_false(s.try_move(d))
	assert_eq(s.pos, p0)
	assert_near(s.clock.total_hours, t0)


func test_hunger_drops_in_dungeon() -> void:
	var s := _session()
	s.pass_time(10.0)
	assert_near(s.player.pool.get_current("hunger"), 100.0 - 10.0 * _b("hunger.decay_per_hour"))


func test_wait_and_rest() -> void:
	var s := _session()
	var t0 := s.clock.total_hours
	s.wait(2.0)
	assert_near(s.clock.total_hours - t0, 2.0)
	var hp_max := s.player.pool.get_max("hp")
	s.player.pool.modify("hp", -30.0, "test")
	s.rest()
	assert_near(s.player.pool.get_current("hp"), hp_max - 30.0, 0.0001, "안전지대 밖 휴식은 회복이 없다")
	for r in range(1, 4):
		if s.debug_teleport(s.map.center + Vector2i(0, r)):
			break
	assert_true(s.in_safe_zone())
	s.rest()
	var gain := hp_max * _b("rest.hp_ratio_per_hour") * _b("explore.rest_hours")
	assert_near(s.player.pool.get_current("hp"), minf(hp_max, hp_max - 30.0 + gain), 0.0001, "기념비 곁 휴식")


func test_closing_warnings_and_forced_return() -> void:
	var s := _session()
	var warns: Array = []
	var closed := [false]
	s.closing_warning.connect(func(h: float) -> void: warns.append(h))
	s.floor_closed.connect(func() -> void: closed[0] = true)
	s.debug_close_in(30.0)
	assert_eq(warns.size(), 0)
	s.wait(7.0)
	s.wait(20.0)
	s.wait(5.0)
	assert_true(closed[0], "층 폐쇄")
	assert_true(s.ended)
	assert_near(s.clock.total_hours, s.close_hours(), 0.0001, "폐쇄 시각을 넘지 않는다")
	assert_eq(warns.size(), 2, "24시간·6시간 전 경고")
	assert_false(s.try_move(_open_dir(s)), "닫힌 뒤에는 움직일 수 없다")


func test_starvation_ends_the_run() -> void:
	var s := _session()
	var cause := [""]
	s.player_died.connect(func(c: String) -> void: cause[0] = c)
	s.player.inventory.remove("ration", s.player.inventory.count("ration"))
	var hours := 0
	while not s.ended and hours < 400:
		s.wait(1.0)
		hours += 1
	assert_true(s.player.dead, "먹을 것이 없으면 굶어 죽는다")
	assert_eq(cause[0], "status:starvation")
	assert_true(s.clock.total_hours < s.close_hours(), "1층 폐쇄 전에 죽는다(식량 관리가 필요하다)")


func test_items_in_session() -> void:
	var s := _session()
	assert_false(s.use_category("food"), "배부르면 먹지 않는다")
	assert_eq(s.player.inventory.count("ration"), 3)
	s.pass_time(50.0)
	assert_true(s.use_category("food"))
	assert_eq(s.player.inventory.count("ration"), 2)
	assert_true(s.use_category("light"))
	assert_eq(s.light_kind(), "torch")
	assert_near(s.vision_m, 7.0, 0.0001, "횃불 7m (상한 9m 안)")
	assert_false(s.use_category("potion"), "없는 분류")


func test_discovery_and_interaction() -> void:
	var s := _session()
	var keys: Array = []
	s.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	assert_true(s.map.explored.count(1) > 0, "입장하자마자 주변을 본다")
	assert_eq(s.map.visible_now[s.map.idx(s.pos)], 1)
	assert_true(s.debug_teleport(s.nearest_portal()))
	assert_true(keys.has("explore.portal_found"))
	assert_true(keys.has("explore.portal_here"))
	s.interact()
	assert_true(keys.has("explore.portal_locked"))
	for r in range(1, 4):
		if s.debug_teleport(s.map.center + Vector2i(0, r)):
			break
	assert_true(keys.has("explore.landmark_found"), "기념비 발견")
	assert_true(keys.has("explore.safe_enter"))
	s.interact()
	assert_true(keys.has("explore.monument"))
	assert_true(s.found_count(s.map.landmarks) >= 1)


func test_step_performance() -> void:
	var s := _session()
	var moves := 0
	var t := Time.get_ticks_usec()
	for i in 200:
		var d := FloorMap.DIRS4[i % 4] if s.map.is_walkable(s.pos + FloorMap.DIRS4[i % 4]) else _open_dir(s)
		if s.try_move(d):
			moves += 1
	var ms := (Time.get_ticks_usec() - t) / 1000.0
	print("    이동 %d회 %.0fms (1회 %.2fms)" % [moves, ms, ms / maxf(1.0, moves)])
	assert_true(moves > 0)
	assert_true(ms / maxf(1.0, moves) < 25.0, "한 걸음 처리 25ms 미만")
