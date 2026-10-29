extends TestCase
## 필드 몬스터의 경계 순찰과 화면 감지(사용자 2026-10-27 "빙빙 돌지 말고 주변을 순찰·경계하는 느낌" + 2026-10-29 "화면 밖에서 감지하는 일은
## 없게, 화면 안에 들어오면 어그로" — V19): 화면 사각형 안이면 벽·바라보는 쪽과 상관없이 알아채고 밖이면 모른다, 순찰 지점 사이를 걷다 서서 둘러보고,
## 놓치면 마지막으로 본 자리를 찾아본 뒤 집으로.


## size×size 빈 방 + 동쪽 지역 하나짜리 필드.
func _room(size: int = 25) -> FieldMonsters:
	var map := FloorMap.new(db, size, size, "rock_wall")
	for y in range(1, size - 1):
		for x in range(1, size - 1):
			map.set_tile(Vector2i(x, y), "cave_floor")
	map.center = Vector2i(size / 2, size / 2)
	map.visible_now.fill(1)
	var def := {"regions": [{"id": "r", "dir": "east", "monsters": ["goblin"]}],
		"spawn": {"groups_per_region": [1, 1], "respawn_hours": 24, "growth_every_hours": 24, "max_extra_groups": 0}}
	return FieldMonsters.new(db, map, def, Rng.new(3))


func _place(fm: FieldMonsters, monster_id: String, at: Vector2i, facing: Vector2) -> FieldMonsters.Group:
	var g := fm.spawn_group({"id": "r", "monsters": [monster_id]}, Vector2i(-99, -99), at, monster_id)
	g.place(at)
	g.home = at
	g.facing = facing
	return g


func _c(cell: Vector2i) -> Vector2:
	return Kinematics.center_of(cell)


## 화면 반 크기(칸, 여유 뺀 값 — MonsterSenses가 뷰포트·칸 크기·줌으로 셈).
func _half() -> Vector2:
	return MonsterSenses.new(db).half


## 화면 안이면 등 뒤·벽 너머라도 알아채고, 화면 밖이면 가로·세로 어느 쪽이든 모른다.
func test_notices_exactly_inside_screen() -> void:
	var h := _half()
	var fm := _room(60)
	var p := Vector2i(30, 30)
	var cases := [[Vector2i(int(h.x), 0), true, "가로 화면 끝 안"], [Vector2i(int(h.x) + 1, 0), false, "가로 화면 밖"],
		[Vector2i(0, -int(h.y)), true, "세로 화면 끝 안"], [Vector2i(0, int(h.y) + 1), false, "세로 화면 밖"],
		[Vector2i(int(h.x), int(h.y)), true, "모서리 안"], [Vector2i(int(h.x) + 1, int(h.y) + 1), false, "모서리 밖"]]
	for c: Array in cases:
		var off: Vector2i = c[0]
		var g := _place(fm, "goblin", p + off, Vector2(off).normalized())  # 플레이어를 등지고 서 있다
		fm.update(_c(p), 0.0, 0.0, false)
		assert_eq(g.state == FieldMonsters.STATE_CHASE, bool(c[1]), "%s (%s) — 등져도 화면 안이면 안다" % [c[2], str(off)])
		fm.groups.erase(g)
	for x in range(26, 35):  # 벽 너머(화면 안)
		fm._map.set_tile(Vector2i(x, 27), "rock_wall")
	var behind := _place(fm, "slime", Vector2i(30, 24), Vector2(0, -1))
	fm.update(_c(p), 0.0, 0.0, false)
	assert_eq(behind.state, FieldMonsters.STATE_CHASE, "화면 안이면 벽 너머라도 알아챈다")


## 순찰: 무작위 한 걸음씩 왔다 갔다 하지 않고(A→B→A가 드물다), 집 둘레를 벗어나지 않고, 서서 둘러보는 때가 있다.
func test_patrol_walks_between_points_and_pauses() -> void:
	var fm := _room()
	var g := _place(fm, "slime", Vector2i(18, 18), Vector2(0, -1))
	var player := _c(Vector2i(60, 60))  # 아주 멀리(보는 거리 밖) 가만히
	var cells: Array[Vector2i] = [g.pos]
	var still := 0
	var longest_still := 0
	var t := 0.0
	var faced := {}
	for i in 600:
		t += 0.01
		fm.update(player, 0.01, t, false)
		faced[Vector2i(g.facing.round())] = true
		if g.pos != cells.back():
			cells.append(g.pos)
			still = 0
		else:
			still += 1
			longest_still = maxi(longest_still, still)
		assert_true(Vector2(g.pos - g.home).length() <= float(db.bal("monsters.wander_radius")) + 1.5, "집 둘레를 벗어나지 않는다")
	var back := 0
	for i in range(2, cells.size()):
		if cells[i] == cells[i - 2]:
			back += 1
	assert_true(cells.size() > 15, "돌아다닌다 (%d칸)" % cells.size())
	assert_true(back * 8 <= cells.size(), "한 걸음 갔다 되돌아오기가 드물다 (%d / %d)" % [back, cells.size()])
	assert_true(longest_still >= 8, "지점에서 서서 둘러본다 (%d)" % longest_still)
	assert_true(faced.size() >= 3, "서 있는 동안 여러 쪽을 본다 (%d)" % faced.size())


func test_lost_player_is_searched_then_home() -> void:
	var fm := _room()
	var g := _place(fm, "goblin", Vector2i(18, 18), Vector2(-1, 0))
	g.state = FieldMonsters.STATE_CHASE
	g.last_seen = Vector2i(12, 18)
	var far := _c(Vector2i(60, 60))
	fm.update(far, 0.0, 0.0, false)
	assert_eq(g.state, FieldMonsters.STATE_SEARCH, "놓치면 찾아본다")
	var t := 0.0
	var reached := false
	var home_again := false
	for i in 400:
		t += 0.01
		fm.update(far, 0.01, t, false)
		reached = reached or g.pos == Vector2i(12, 18)
		if reached and g.state == FieldMonsters.STATE_IDLE and g.pos == g.home:
			home_again = true
			break
	assert_true(reached, "마지막으로 본 자리까지 간다")
	assert_true(home_again, "둘러보고 집으로 돌아간다")


## 쫓는 중엔 화면 끝을 조금(chase_keep_tiles) 넘어도 놓치지 않고, 그보다 멀어지면 놓쳐 찾아본다.
func test_keeps_chasing_just_past_screen_edge() -> void:
	var h := _half()
	var keep := float(db.bal("monsters.chase_keep_tiles"))
	var fm := FieldMonsters.new(db, _hall(), {"regions": [], "spawn": {}}, Rng.new(3))
	var g := _place(fm, "slime", Vector2i(5, 3), Vector2(-1, 0))
	fm.update(_c(Vector2i(5 + int(h.x) + 1, 3)), 0.0, 0.0, false)
	assert_true(g.state != FieldMonsters.STATE_CHASE, "화면 밖은 모른다")
	fm.update(_c(Vector2i(5 + int(h.x), 3)), 0.0, 0.0, false)
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "화면에 들어오면 안다")
	fm.update(_c(Vector2i(5 + int(h.x + keep), 3)), 0.0, 0.0, false)
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "쫓는 중엔 화면 끝을 조금 넘어도 놓치지 않는다")
	fm.update(_c(Vector2i(5 + int(h.x + keep) + 2, 3)), 0.0, 0.0, false)
	assert_eq(g.state, FieldMonsters.STATE_SEARCH, "더 멀어지면 놓치고 찾아본다")


## 화면 밖에서는 움직여도·늑대라도 알아채지 않는다(냄새·사냥·소리 없음).
func test_no_detection_off_screen() -> void:
	var h := _half()
	var fm := _room(60)
	var wolf := _place(fm, "blade_wolf", Vector2i(30 + int(h.x) + 3, 30), Vector2(-1, 0))
	var p := _c(Vector2i(30, 30))
	var t := 0.0
	for i in 30:
		t += 0.01
		fm.update(p + Vector2(0.0, 0.3 * (i % 2)), 0.01, t, false)
		assert_true(wolf.state != FieldMonsters.STATE_CHASE, "화면 밖 늑대는 알아채지 않는다")


## 방에서 기다리는 보스: 화면 안이고 벽에 가리지 않으면 바로 전투, 벽 너머·화면 밖이면 아니다.
func test_boss_engages_on_screen_in_sight() -> void:
	var h := _half()
	var fm := _room(60)
	var boss := _place(fm, "goblin", Vector2i(30 + int(h.x), 30), Vector2(-1, 0))
	boss.boss = "goblin"
	assert_true(fm.update(_c(Vector2i(30 - 2, 30)), 0.0, 0.0, false) == null, "화면 밖이면 아니다")
	assert_true(fm.update(_c(Vector2i(30, 30)), 0.0, 0.0, false) == boss, "화면 안·보이면 바로")
	for y in range(25, 36):
		fm._map.set_tile(Vector2i(32, y), "rock_wall")
	assert_true(fm.update(_c(Vector2i(30, 30)), 0.0, 0.0, false) == null, "벽 너머면 아니다")


## 순찰 길은 칸칸이 꺾지 않고 곧게(V14): 트인 방에서 한 번에 여러 칸 앞을 향해 걷는다.
func test_patrol_walks_straight_legs() -> void:
	var fm := _room()
	var g := _place(fm, "slime", Vector2i(12, 12), Vector2(1, 1).normalized())
	var player := _c(Vector2i(60, 60))
	var diag := 0
	var t := 0.0
	for i in 400:
		t += 0.01
		fm.update(player, 0.01, t, false)
		if g.waypoint.x >= 0.0 and Kinematics.cell_of(g.waypoint).distance_to(g.pos) >= 2.0:
			diag += 1
	print("    곧은 걸음 프레임 %d" % diag)
	assert_true(diag > 20, "여러 칸 앞 지점을 향해 곧게 걷는다 (%d)" % diag)


## 1×W 긴 복도(가운데 줄 y=3, 너비 3칸).
func _hall() -> FloorMap:
	var map := FloorMap.new(db, 40, 7, "rock_wall")
	for y in range(2, 5):
		for x in range(1, 39):
			map.set_tile(Vector2i(x, y), "cave_floor")
	map.visible_now.fill(1)
	return map
