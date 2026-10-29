extends TestCase
## 필드 몬스터의 경계 순찰과 화면 감지(사용자 2026-10-27 "빙빙 돌지 말고 주변을 순찰·경계하는 느낌" + 2026-10-29 "화면 밖에서 감지하는 일은
## 없게, 화면 안에 들어오면 어그로 · 벽이랑 등 돌리고 있으면 못 알아채게" — V19·V20): 화면 사각형 안이고 벽에 가리지 않고 바라보는 쪽이면
## 알아채고 밖이면 모른다, 순찰 지점 사이를 걷다 서서 둘러보고,
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


## 플레이어가 cell에 선 채로 의심 시간이 지나도록 본다(V21) — 지금 시각 t부터, 끝난 시각을 돌려준다.
func _look_at(fm: FieldMonsters, cell: Vector2i, t: float = 0.0) -> float:
	fm.update(_c(cell), 0.0, t, false)
	fm.update(_c(cell), 0.0, t + 0.2, false)
	return t + 0.2


## 화면 안이고 플레이어 쪽을 보고 있으면 알아채고, 화면 밖이면 가로·세로 어느 쪽이든 모른다.
func test_notices_exactly_inside_screen() -> void:
	var h := _half()
	var fm := _room(60)
	var p := Vector2i(30, 30)
	var cases := [[Vector2i(int(h.x), 0), true, "가로 화면 끝 안"], [Vector2i(int(h.x) + 1, 0), false, "가로 화면 밖"],
		[Vector2i(0, -int(h.y)), true, "세로 화면 끝 안"], [Vector2i(0, int(h.y) + 1), false, "세로 화면 밖"],
		[Vector2i(int(h.x), int(h.y)), true, "모서리 안"], [Vector2i(int(h.x) + 1, int(h.y) + 1), false, "모서리 밖"]]
	for c: Array in cases:
		var off: Vector2i = c[0]
		var g := _place(fm, "goblin", p + off, -Vector2(off).normalized())  # 플레이어 쪽을 본다
		_look_at(fm, p)
		assert_eq(g.state == FieldMonsters.STATE_CHASE, bool(c[1]), "%s (%s)" % [c[2], str(off)])
		fm.groups.erase(g)


## 등 돌리고 있거나 벽에 가리면 화면 안이어도 모른다(V20). 바로 옆(시야각 180도 끝)은 본다.
func test_back_turned_or_walled_does_not_notice() -> void:
	var fm := _room(60)
	var p := Vector2i(30, 30)
	var away := _place(fm, "goblin", Vector2i(34, 30), Vector2(1, 0))
	var close := _place(fm, "goblin", Vector2i(31, 34), Vector2(0, 1))
	var side := _place(fm, "goblin", Vector2i(25, 33), Vector2(0, -1))
	for x in range(26, 35):  # 위쪽 벽
		fm._map.set_tile(Vector2i(x, 27), "rock_wall")
	var walled := _place(fm, "slime", Vector2i(30, 24), Vector2(0, 1))
	var t := _look_at(fm, p)
	assert_true(away.state != FieldMonsters.STATE_CHASE, "등 돌리고 있으면 모른다")
	assert_true(close.state != FieldMonsters.STATE_CHASE, "바로 뒤라도 등 돌리고 있으면 모른다")
	assert_true(walled.state != FieldMonsters.STATE_CHASE, "벽에 가리면 플레이어 쪽을 봐도 모른다")
	assert_eq(side.state, FieldMonsters.STATE_CHASE, "옆으로 보이는 곳(시야각 180도 끝)은 본다")
	away.facing = Vector2(-1, 0)
	_look_at(fm, p, t + 1.0)
	assert_eq(away.state, FieldMonsters.STATE_CHASE, "돌아보면 안다")


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
		# 집은 고른 순찰 지점으로 옮겨 간다(home_drift_chance) — 그 지점까지 가는 동안은 순찰 반경 두 배까지 떨어질 수 있다
		assert_true(Vector2(g.pos - g.home).length() <= float(db.bal("monsters.wander_radius")) * 2.0 + 1.5, "집 둘레를 벗어나지 않는다")
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


## 쫓는 중엔 화면 끝을 조금(chase_keep_tiles) 넘어도 놓치지 않고(등을 보여도), 그보다 멀어지면 놓쳐 찾아본다.
func test_keeps_chasing_just_past_screen_edge() -> void:
	var h := _half()
	var keep := float(db.bal("monsters.chase_keep_tiles"))
	var fm := FieldMonsters.new(db, _hall(), {"regions": [], "spawn": {}}, Rng.new(3))
	var g := _place(fm, "slime", Vector2i(5, 3), Vector2(1, 0))
	fm.update(_c(Vector2i(5 + int(h.x) + 1, 3)), 0.0, 0.0, false)
	assert_true(g.state != FieldMonsters.STATE_CHASE, "화면 밖은 모른다")
	var t := _look_at(fm, Vector2i(5 + int(h.x), 3))
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "화면에 들어오면 안다")
	g.facing = Vector2(-1, 0)
	fm.update(_c(Vector2i(5 + int(h.x + keep), 3)), 0.0, t, false)
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "쫓는 중엔 화면 끝을 조금 넘어도·등을 보여도 놓치지 않는다")
	fm.update(_c(Vector2i(5 + int(h.x + keep) + 2, 3)), 0.0, t, false)
	assert_eq(g.state, FieldMonsters.STATE_SEARCH, "더 멀어지면 놓치고 찾아본다")


## 화면 밖에서는 움직여도·늑대라도 알아채지 않는다(냄새·사냥·소리 없음).
func test_no_detection_off_screen() -> void:
	var h := _half()
	var fm := _room(60)
	var wolf := _place(fm, "blade_wolf", Vector2i(30 + int(h.x) + 3, 30), Vector2(-1, 0))
	wolf.guard = true  # 순찰로 화면 안까지 걸어 들어오지 않게 제자리에
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


## 의심(V21): 처음 보면 멈칫하고 그쪽을 본다(걷지 않는다). 그새 사라지면 본 자리까지 가서 둘러보고, 계속 보이면 쫓으며 소리(alerted)를 낸다.
## 화면 끝에서 본 것은 바로 앞에서 본 것보다 오래 멈칫한다.
func test_suspect_before_chase() -> void:
	var h := _half()
	var fm := _room(60)
	var heard: Array = []
	fm.alerted.connect(func(gg: FieldMonsters.Group) -> void: heard.append(gg.id))
	var near := _place(fm, "goblin", Vector2i(33, 30), Vector2(-1, 0))
	var far := _place(fm, "goblin", Vector2i(30, 30 + int(h.y)), Vector2(0, -1))
	fm.update(_c(Vector2i(30, 30)), 0.0, 0.0, false)
	assert_eq(near.state, FieldMonsters.STATE_SUSPECT, "처음 보면 멈칫한다")
	assert_true(far.suspect_until > near.suspect_until, "화면 끝은 더 오래 멈칫한다 (%.3f > %.3f)" % [far.suspect_until, near.suspect_until])
	var at := near.fpos
	fm.update(_c(Vector2i(30, 30)), 0.01, 0.01, false)
	assert_eq(near.fpos, at, "멈칫하는 동안 걷지 않는다")
	fm.update(_c(Vector2i(30, 30)), 0.0, 0.2, false)
	assert_eq(near.state, FieldMonsters.STATE_CHASE, "계속 보이면 쫓는다")
	assert_eq(heard.count(near.id), 1, "쫓기 시작할 때 한 번 소리를 낸다")
	var gone := _room(60)
	var g := _place(gone, "goblin", Vector2i(33, 30), Vector2(-1, 0))
	gone.update(_c(Vector2i(30, 30)), 0.0, 0.0, false)
	gone.update(_c(Vector2i(30 - int(h.x) - 8, 30)), 0.0, 0.01, false)  # 그새 화면 밖으로
	assert_eq(g.state, FieldMonsters.STATE_SEARCH, "사라지면 본 자리를 찾아본다")
	assert_eq(g.last_seen, Vector2i(30, 30))


## 기척(V21): 등 돌린 몬스터라도 바로 곁(hear_tiles)에서 움직이면 멈춰 돌아보고, 돌아본 뒤에 본다. 서 있거나 조금 떨어지면 모른다.
func test_close_movement_makes_it_turn() -> void:
	var fm := _room(60)
	var g := _place(fm, "goblin", Vector2i(31, 30), Vector2(1, 0))
	var other := _place(fm, "goblin", Vector2i(30, 34), Vector2(0, 1))
	fm.update(_c(Vector2i(30, 30)), 0.0, 0.0, false)
	assert_true(g.look == Vector2.ZERO, "서 있으면 들리지 않는다")
	fm.set_player_moving(true)
	fm.update(_c(Vector2i(30, 30)), 0.001, 0.0, false)
	assert_true(g.look.dot(Vector2(-1, 0)) > 0.99, "바로 곁에서 움직이면 그쪽을 돌아본다")
	assert_true(other.look == Vector2.ZERO and other.state == FieldMonsters.STATE_IDLE, "4칸 떨어진 등 뒤는 모른다")
	var t := 0.0
	for i in 60:
		t += 0.01
		fm.update(_c(Vector2i(30, 30)), 0.01, t, false)
		if g.state == FieldMonsters.STATE_CHASE:
			break
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "돌아보고 멈칫한 뒤 쫓는다")
	assert_true(t > 0.04, "돌아보는 데 시간이 든다 (%.2f시간)" % t)


## 빠르기(V21): 늑대는 플레이어보다 빠르고 고블린은 같고 슬라임은 느리다.
func test_species_speed() -> void:
	var fm := _room()
	var base := float(db.bal("explore.move_hours_base"))
	assert_true(fm._steer.move_hours("blade_wolf") < base, "늑대는 빠르다")
	assert_eq(fm._steer.move_hours("goblin"), base, "고블린은 플레이어와 같다")
	assert_true(fm._steer.move_hours("slime") > base, "슬라임은 느리다")


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
