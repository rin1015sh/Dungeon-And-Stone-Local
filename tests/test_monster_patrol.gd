extends TestCase
## 필드 몬스터의 경계 순찰과 시야각 감지(사용자 2026-10-27 "빙빙 돌지 말고 주변을 순찰·경계하는 느낌, 시야 기반 감지"):
## 바라보는 쪽 시야각(내적) 안만 보고, 가까운 기척은 등 뒤도, 움직이는 소리엔 돌아보고, 순찰 지점 사이를 걷다 서서 둘러보고,
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


func test_sees_only_inside_view_cone() -> void:
	var fm := _room()
	var g := _place(fm, "goblin", Vector2i(12, 12), Vector2(-1, 0))
	var player := Vector2i(9, 12)  # 3칸 서쪽(감지 반경 안)
	fm.update(_c(player), 0.0, 0.0, false)
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "바라보는 쪽에 있으면 알아챈다")
	var h := _place(fm, "goblin", Vector2i(12, 18), Vector2(1, 0))
	fm.update(_c(Vector2i(9, 18)), 0.0, 0.0, false)
	assert_true(h.state != FieldMonsters.STATE_CHASE, "등 뒤에 가만히 있으면 모른다")
	var side := _place(fm, "goblin", Vector2i(18, 5), Vector2(0, 1))
	fm.update(_c(Vector2i(15, 5)), 0.0, 0.0, false)
	assert_true(side.state != FieldMonsters.STATE_CHASE, "시야각(120도) 바깥 옆도 모른다")
	var close := _place(fm, "goblin", Vector2i(5, 20), Vector2(1, 0))
	fm.update(_c(Vector2i(4, 20)), 0.0, 0.0, false)
	assert_eq(close.state, FieldMonsters.STATE_CHASE, "바로 뒤의 기척은 안다")


func test_moving_behind_makes_it_turn_and_see() -> void:
	var fm := _room()
	var g := _place(fm, "goblin", Vector2i(12, 12), Vector2(1, 0))
	var player := _c(Vector2i(9, 12))
	fm.set_player_moving(true)
	fm.update(player, 0.001, 0.0, false)
	assert_true(g.state != FieldMonsters.STATE_CHASE, "소리만으로는 아직 알아채지 않는다")
	assert_true(g.look.dot(Vector2(-1, 0)) > 0.99, "소리 쪽을 돌아본다")
	var t := 0.0
	for i in 40:
		t += 0.01
		fm.update(player, 0.01, t, false)
		if g.state == FieldMonsters.STATE_CHASE:
			break
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "돌아보고 나서 본다")
	assert_true(t > 0.05, "돌아보는 데 시간이 든다 (%.3f시간)" % t)


## 순찰: 무작위 한 걸음씩 왔다 갔다 하지 않고(A→B→A가 드물다), 집 둘레를 벗어나지 않고, 서서 둘러보는 때가 있다.
func test_patrol_walks_between_points_and_pauses() -> void:
	var fm := _room()
	var g := _place(fm, "slime", Vector2i(18, 18), Vector2(0, -1))
	var player := _c(Vector2i(2, 2))  # 멀리 가만히
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
	var far := _c(Vector2i(2, 2))
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
