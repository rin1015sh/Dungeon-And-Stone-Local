extends TestCase
## 적 AI(사용자 2026-11-01 "다 갈아엎고 오래 쓸 AI로" — V22, src/explore/ai): 화면 안 · 뒤로 완전히 돌지 않음 · 벽에 안 가림이면 경계도가 차올라
## 의심 → 추적, 장식은 시선을 막지 않는다, 모퉁이를 돌아도 기억·발소리로 쫓는다, 놓치면 내다보고 수색 → 귀환, 흘끗 본 것은 조사,
## 추적을 시작하면 동료를 부른다.


func _room(size: int = 60) -> FieldMonsters:
	var map := FloorMap.new(db, size, size, "rock_wall")
	for y in range(1, size - 1):
		for x in range(1, size - 1):
			map.set_tile(Vector2i(x, y), "cave_floor")
	map.center = Vector2i(size / 2, size / 2)
	map.visible_now.fill(1)
	return FieldMonsters.new(db, map, {"regions": [], "spawn": {}}, Rng.new(3))


func _place(fm: FieldMonsters, monster_id: String, at: Vector2i, facing: Vector2) -> FieldMonsters.Group:
	var g := fm.spawn_group({"id": "", "monsters": [monster_id]}, Vector2i(-99, -99), at, monster_id)
	g.place(at)
	g.home = at
	g.facing = facing
	g.guard = true  # 순찰로 제자리를 떠나지 않게(시험할 것만 보게)
	return g


func _c(cell: Vector2i) -> Vector2:
	return Kinematics.center_of(cell)


## 플레이어가 cell에 선 채(움직이는 중으로 셈) hours 동안 지켜본다. 끝난 시각.
func _watch(fm: FieldMonsters, cell: Vector2i, hours: float, t: float = 0.0, moving: bool = true) -> float:
	fm.set_player_moving(moving)
	var n := maxi(1, ceili(hours / 0.005))
	for i in n:
		t += hours / n
		fm.update(_c(cell), hours / n, t, false)
	return t


func _half() -> Vector2:
	return MonsterSight.new(db, FloorMap.new(db, 3, 3, "rock_wall")).half


## 화면 안이고 그쪽을 보면 알아채고(경계도가 차서 추적), 화면 밖이면 오래 있어도 모른다.
func test_notices_inside_screen_only() -> void:
	var h := _half()
	var p := Vector2i(30, 30)
	var cases := [[Vector2i(int(h.x), 0), true, "가로 화면 끝 안"], [Vector2i(int(h.x) + 1, 0), false, "가로 화면 밖"],
		[Vector2i(0, -int(h.y)), true, "세로 화면 끝 안"], [Vector2i(0, int(h.y) + 1), false, "세로 화면 밖"],
		[Vector2i(int(h.x), int(h.y)), true, "모서리 안"]]
	for c: Array in cases:
		var fm := _room()
		var off: Vector2i = c[0]
		var g := _place(fm, "goblin", p + off, -Vector2(off).normalized())
		_watch(fm, p, 0.3)
		assert_eq(g.state == FieldMonsters.STATE_CHASE, bool(c[1]), "%s (%s)" % [c[2], str(off)])


## 바로 알아채지 않는다: 먼저 의심(멈춰 그쪽을 본다), 경계도가 차면 추적 — 가까울수록 빨리.
func test_suspect_then_chase_faster_when_near() -> void:
	var h := _half()
	var fm := _room()
	var heard: Array = []
	fm.alerted.connect(func(gg: FieldMonsters.Group) -> void: heard.append(gg.id))
	var near := _place(fm, "goblin", Vector2i(33, 30), Vector2(-1, 0))
	var far := _place(fm, "goblin", Vector2i(30 + int(h.x) - 1, 30), Vector2(-1, 0))
	var t := _watch(fm, Vector2i(30, 30), 0.012)
	assert_true(near.state != FieldMonsters.STATE_CHASE, "보자마자 쫓지는 않는다")
	assert_true(near.awareness > far.awareness, "가까울수록 빨리 알아챈다 (%.2f > %.2f)" % [near.awareness, far.awareness])
	var at := near.fpos
	t = _watch(fm, Vector2i(30, 30), 0.02, t)
	assert_eq(near.state, FieldMonsters.STATE_CHASE, "계속 보이면 쫓는다")
	assert_true(far.state == FieldMonsters.STATE_SUSPECT, "화면 끝은 아직 의심 중 (%s %.2f)" % [far.state, far.awareness])
	assert_eq(heard.count(near.id), 1, "쫓기 시작할 때 한 번 소리")
	var fm2 := _room()
	var g := _place(fm2, "goblin", Vector2i(33, 30), Vector2(-1, 0))
	_watch(fm2, Vector2i(30, 30), 0.01)
	assert_eq(g.state, FieldMonsters.STATE_SUSPECT, "의심 — 멈춰 본다")
	assert_eq(g.fpos, Vector2(33.5, 30.5), "의심하는 동안 걷지 않는다")
	assert_true(at != Vector2.ZERO)


## 뒤로 완전히 돈 몬스터와 벽 너머는 모른다. 옆(곁눈)은 느리지만 알아챈다. 서 있는 장식(천막·석상 …)은 시선을 막지 않는다.
func test_back_wall_side_and_props() -> void:
	var fm := _room()
	var p := Vector2i(30, 30)
	var away := _place(fm, "deadman", Vector2i(34, 30), Vector2(1, 0))  # 부르지 않는 몬스터(서로 불러 모이지 않게)
	var side := _place(fm, "deadman", Vector2i(30, 35), Vector2(1, 0))
	for x in range(26, 35):
		fm._map.set_tile(Vector2i(x, 26), "rock_wall")
	var walled := _place(fm, "deadman", Vector2i(30, 23), Vector2(0, 1))
	fm._map.set_tile(Vector2i(25, 30), "bf_tent")  # 서 있는 장식(시선을 막는 타일이지만 art.stand)
	var behind_prop := _place(fm, "deadman", Vector2i(21, 30), Vector2(1, 0))
	_watch(fm, p, 0.3, 0.0, false)
	assert_true(away.state != FieldMonsters.STATE_CHASE, "등 뒤는 모른다")
	assert_true(walled.state != FieldMonsters.STATE_CHASE, "벽 너머는 모른다")
	assert_eq(side.state, FieldMonsters.STATE_CHASE, "옆(곁눈)은 느려도 알아챈다")
	assert_eq(behind_prop.state, FieldMonsters.STATE_CHASE, "장식 하나에 가려도 몸이 보인다")


## 모퉁이(사용자 "벽에서 코너를 돌면 바로 포기"): 쫓던 상대가 모퉁이를 돌아 사라져도 그 모퉁이까지 쫓아오고,
## 움직이는 발소리·꺾인 굴을 따라 내다보기로 다시 자리를 알아 끝내 따라붙는다(플레이어는 걷는 빠르기로).
func test_follows_around_corner() -> void:
	var map := FloorMap.new(db, 40, 40, "rock_wall")
	for x in range(2, 30):  # ㄱ자 굴: 가로(y 4~6) → 세로(x 28~30)
		for w in range(4, 7):
			map.set_tile(Vector2i(x, w), "cave_floor")
	for y in range(4, 36):
		for w in range(28, 31):
			map.set_tile(Vector2i(w, y), "cave_floor")
	map.visible_now.fill(1)
	var fm := FieldMonsters.new(db, map, {"regions": [], "spawn": {}}, Rng.new(5))
	var g := _place(fm, "goblin", Vector2i(14, 5), Vector2(1, 0))
	g.guard = false
	var t := _watch(fm, Vector2i(20, 5), 0.15)
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "본다")
	var mh := float(db.bal("explore.move_hours_base"))
	var path: Array[Vector2i] = []
	for x in range(21, 30):
		path.append(Vector2i(x, 5))
	for y in range(6, 34):
		path.append(Vector2i(29, y))
	var caught := false
	var lost := false
	fm.set_player_moving(true)
	for cell in path:  # 한 칸 걷는 시간마다 한 칸 — 모퉁이를 돌아 계속 걸어간다
		for k in 4:
			t += mh / 4.0
			if fm.update(_c(cell), mh / 4.0, t, false) == g:
				caught = true
		lost = lost or not (g.state == FieldMonsters.STATE_CHASE or caught)
		if caught:
			break
	assert_false(lost, "모퉁이를 돌아도 놓지 않는다 (%s %s)" % [g.state, g.phase])
	for i in 200:
		t += 0.005
		if caught or fm.update(_c(Vector2i(29, 33)), 0.005, t, false) == g:
			caught = true
			break
	assert_true(caught, "끝내 따라붙는다")


## 숨어서 가만히 있으면(발소리 없음) 놓친다: 마지막으로 본 곳 → 움직이던 쪽으로 더 → 수색 → 결국 집으로.
func test_lost_target_pursue_search_return() -> void:
	var map := FloorMap.new(db, 40, 40, "rock_wall")
	for x in range(2, 38):
		for w in range(4, 7):
			map.set_tile(Vector2i(x, w), "cave_floor")
	for y in range(6, 30):  # 갈림길 아래 방
		for w in range(18, 21):
			map.set_tile(Vector2i(w, y), "cave_floor")
	map.visible_now.fill(1)
	var fm := FieldMonsters.new(db, map, {"regions": [], "spawn": {}}, Rng.new(7))
	var g := _place(fm, "goblin", Vector2i(4, 5), Vector2(1, 0))
	g.guard = false
	var t := 0.0
	for x in range(10, 19):  # 오른쪽으로 걸어가는 모습을 본다
		t = _watch(fm, Vector2i(x, 5), 0.01, t)
	assert_eq(g.state, FieldMonsters.STATE_CHASE)
	var hide := Vector2i(19, 26)  # 갈림길 아래로 내려가 숨는다(멀리, 가만히)
	var phases := {}
	var states := {}
	var home_again := false
	for i in 1500:
		t += 0.005
		fm.set_player_moving(false)
		fm.update(_c(hide), 0.005, t, false)
		phases[g.phase] = true
		states[g.state] = true
		if states.has(FieldMonsters.STATE_SEARCH) and g.state == FieldMonsters.STATE_IDLE:
			home_again = true
			break
	assert_true(phases.has("pursue"), "마지막으로 본 곳까지 쫓는다")
	assert_true(states.has(FieldMonsters.STATE_SEARCH), "수색한다")
	assert_true(home_again, "끝내 그만두고 순찰로 (%s)" % str(states.keys()))


## 의심하다 사라지면 본 자리까지 가서 둘러본다(조사).
func test_glimpse_is_investigated() -> void:
	var h := _half()
	var fm := _room()
	var g := _place(fm, "slime", Vector2i(30 + int(h.x) - 2, 30), Vector2(-1, 0))
	g.guard = false
	var t := _watch(fm, Vector2i(30, 30), 0.06)
	assert_eq(g.state, FieldMonsters.STATE_SUSPECT, "흘끗 봤다 — 의심")
	var gone := Vector2i(30 - int(h.x) - 6, 30)  # 화면 밖으로
	var reached := false
	for i in 600:
		t += 0.005
		fm.set_player_moving(false)
		fm.update(_c(gone), 0.005, t, false)
		if g.state == FieldMonsters.STATE_INVESTIGATE and Vector2(g.pos - Vector2i(30, 30)).length() <= 1.5:
			reached = true
			break
	assert_true(reached, "본 자리까지 보러 간다 (%s %s)" % [g.state, str(g.pos)])


## 바로 곁의 발소리: 등 돌린 몬스터도 돌아본다. 서 있으면 들리지 않고, 벽 너머 먼 길은 들리지 않는다.
func test_footsteps_turn_heads() -> void:
	var fm := _room()
	var g := _place(fm, "goblin", Vector2i(32, 30), Vector2(1, 0))
	_watch(fm, Vector2i(30, 30), 0.01, 0.0, false)
	assert_true(g.look == Vector2.ZERO and g.awareness == 0.0, "서 있으면 들리지 않는다")
	_watch(fm, Vector2i(30, 30), 0.005, 0.01, true)
	assert_true(g.look.dot(Vector2(-1, 0)) > 0.9 or g.facing.dot(Vector2(-1, 0)) > 0.5, "곁에서 움직이면 돌아본다")
	var t := _watch(fm, Vector2i(30, 30), 0.3, 0.02, true)
	assert_eq(g.state, FieldMonsters.STATE_CHASE, "돌아보고 알아챈다")
	assert_true(t > 0.02)


## 무리 부르기: 추적을 시작한 고블린이 둘레의 고블린을 부른다(보지 못한 고블린도 그 자리를 보러 온다). 슬라임은 부르지 않는다.
func test_pack_call() -> void:
	var fm := _room()
	var g := _place(fm, "goblin", Vector2i(33, 30), Vector2(-1, 0))
	var mate := _place(fm, "goblin", Vector2i(38, 30), Vector2(1, 0))  # 등 돌리고 있다
	var slime := _place(fm, "slime", Vector2i(38, 33), Vector2(1, 0))
	_watch(fm, Vector2i(30, 30), 0.05)
	assert_eq(g.state, FieldMonsters.STATE_CHASE)
	assert_true(mate.state in [FieldMonsters.STATE_INVESTIGATE, FieldMonsters.STATE_SUSPECT, FieldMonsters.STATE_CHASE], "동료가 부르면 온다 (%s)" % mate.state)
	assert_true(slime.state == FieldMonsters.STATE_IDLE, "다른 편(슬라임)은 오지 않는다")


## 성격: 언데드는 늦게 알아채고 늑대는 빨리.
func test_personality() -> void:
	var fm := _room()
	var wolf := _place(fm, "blade_wolf", Vector2i(36, 30), Vector2(-1, 0))
	var dead := _place(fm, "deadman", Vector2i(30, 36), Vector2(0, -1))
	_watch(fm, Vector2i(30, 30), 0.01)
	assert_true(wolf.awareness > dead.awareness, "늑대가 먼저 알아챈다 (%.2f > %.2f)" % [wolf.awareness, dead.awareness])
