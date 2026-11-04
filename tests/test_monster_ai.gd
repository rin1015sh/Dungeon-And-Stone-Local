extends TestCase
## 적 AI(V22 → V28 — 사용자 2026-11-02 "그냥 플레이어 화면 안에 들어오면 어그로 · 이리저리 움직이면 바로 어그로가 풀린다"):
## 화면 안이면 바라보는 쪽·벽과 상관없이 바로 쫓고, 화면 안에 있는 동안은 놓치지 않는다(영역도 보지 않는다).
## 화면 밖으로 놓치면 마지막으로 본 곳 → 수색 → 귀환. 추적을 시작하면 동료를 부른다.


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


## 화면에 들면 바로(한 번의 갱신에) 쫓는다 — 쫓기 시작할 때 소리는 한 번.
func test_chases_at_once() -> void:
	var h := _half()
	var fm := _room()
	var heard: Array = []
	fm.alerted.connect(func(gg: FieldMonsters.Group) -> void: heard.append(gg.id))
	var near := _place(fm, "goblin", Vector2i(33, 30), Vector2(-1, 0))
	var far := _place(fm, "deadman", Vector2i(30 + int(h.x) - 1, 30), Vector2(1, 0))
	fm.set_player_moving(false)
	fm.update(_c(Vector2i(30, 30)), 0.001, 0.001, false)
	assert_eq(near.state, FieldMonsters.STATE_CHASE, "가까이")
	assert_eq(far.state, FieldMonsters.STATE_CHASE, "화면 끝, 등 돌리고 서 있어도")
	_watch(fm, Vector2i(30, 30), 0.05, 0.001)
	assert_eq(heard.count(near.id), 1, "쫓기 시작할 때 한 번 소리")


## 바라보는 쪽·벽·장식은 보지 않는다 — 화면 안이면 쫓는다.
func test_ignores_facing_and_walls() -> void:
	var fm := _room()
	var p := Vector2i(30, 30)
	var away := _place(fm, "deadman", Vector2i(34, 30), Vector2(1, 0))
	for x in range(26, 35):
		fm._map.set_tile(Vector2i(x, 26), "rock_wall")
	var walled := _place(fm, "deadman", Vector2i(30, 24), Vector2(0, -1))
	fm._map.set_tile(Vector2i(25, 30), "bf_tent")
	var behind_prop := _place(fm, "deadman", Vector2i(21, 30), Vector2(1, 0))
	fm.set_player_moving(false)
	fm.update(_c(p), 0.001, 0.001, false)
	assert_eq(away.state, FieldMonsters.STATE_CHASE, "등 돌리고 있어도")
	assert_eq(walled.state, FieldMonsters.STATE_CHASE, "벽 너머라도 화면 안이면")
	assert_eq(behind_prop.state, FieldMonsters.STATE_CHASE, "장식 뒤")


## 이리저리 움직여도(기둥 사이를 돌며 방향을 바꿔도) 화면 안에 있는 동안은 어그로가 풀리지 않는다.
func test_moving_around_keeps_aggro() -> void:
	var fm := _room()
	for c: Vector2i in [Vector2i(28, 28), Vector2i(32, 28), Vector2i(28, 32), Vector2i(32, 32), Vector2i(30, 26), Vector2i(30, 34)]:
		fm._map.set_tile(c, "rock_wall")
	var g := _place(fm, "slime", Vector2i(37, 30), Vector2(1, 0))  # 느린 몬스터(닿기 전에 오래 쫓게)
	g.guard = false
	var mh := float(db.bal("explore.move_hours_base"))
	var loop: Array[Vector2i] = []
	for x in range(26, 35):
		loop.append(Vector2i(x, 30))
	for y in range(30, 25, -1):
		loop.append(Vector2i(34, y))
	for x in range(34, 25, -1):
		loop.append(Vector2i(x, 25))
	for y in range(25, 31):
		loop.append(Vector2i(25, y))
	fm.set_player_moving(true)
	var t := 0.0
	var lost := ""
	var caught := false
	for lap in 3:
		for cell in loop:
			for k in 2:
				t += mh / 2.0
				if fm.update(_c(cell), mh / 2.0, t, false) == g:
					caught = true
				if g.state != FieldMonsters.STATE_CHASE and lost.is_empty():
					lost = "%s at %s" % [g.state, str(cell)]
			if caught:
				break
		if caught:
			break
	assert_true(lost.is_empty(), "움직여도 놓지 않는다 (%s)" % lost)


## 영역(leash_tiles)이 있는 몬스터도 화면 안에서는 계속 쫓고, 화면 밖으로 놓치면 바로 돌아간다.
func test_leash_only_when_lost() -> void:
	var fm := _room(90)
	var g := _place(fm, "yeti", Vector2i(10, 45), Vector2(1, 0))  # leash_tiles 4
	g.guard = false
	var t := 0.0
	fm.set_player_moving(true)
	var mh := float(db.bal("explore.move_hours_base"))
	var lost := false
	for x in range(14, 30):  # 영역 밖으로 끌고 간다(몬스터보다 빨리 걷는다)
		for k in 2:
			t += mh / 2.0
			if fm.update(_c(Vector2i(x, 45)), mh / 2.0, t, false) == g:
				break
		lost = lost or g.state != FieldMonsters.STATE_CHASE
	assert_false(lost, "화면 안에서는 영역을 넘어도 쫓는다")
	assert_true(Vector2(g.pos - g.home).length() > 4.0, "영역 밖까지 (%s)" % str(g.pos))
	fm.update(_c(Vector2i(80, 45)), 0.01, t + 0.01, false)  # 화면 밖으로
	assert_eq(g.state, FieldMonsters.STATE_RETURN, "영역 밖에서 놓치면 바로 돌아간다")


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


## 화면 밖으로 사라지면 마지막으로 본 곳 → 움직이던 쪽으로 더 → 수색 → 결국 집으로.
func test_lost_target_pursue_search_return() -> void:
	var map := FloorMap.new(db, 120, 40, "rock_wall")
	for x in range(2, 118):
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
	var hide := Vector2i(75, 5)  # 화면 밖 멀리(active_radius_tiles 안 — 쉬지 않게)
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


## 무리 부르기: 추적을 시작한 고블린이 둘레(화면 밖)의 고블린을 부른다 — 그 자리를 보러 달려온다. 슬라임은 부르지 않는다.
func test_pack_call() -> void:
	var h := _half()
	var fm := _room()
	var g := _place(fm, "goblin", Vector2i(30 + int(h.x) - 2, 30), Vector2(-1, 0))
	var mate := _place(fm, "goblin", Vector2i(30 + int(h.x) + 6, 30), Vector2(1, 0))  # 화면 밖
	var slime := _place(fm, "slime", Vector2i(30 + int(h.x) + 6, 33), Vector2(1, 0))
	fm.set_player_moving(false)
	fm.update(_c(Vector2i(30, 30)), 0.001, 0.001, false)
	assert_eq(g.state, FieldMonsters.STATE_CHASE)
	assert_eq(mate.state, FieldMonsters.STATE_INVESTIGATE, "동료가 부르면 온다")
	assert_true(mate.called)
	assert_eq(slime.state, FieldMonsters.STATE_IDLE, "다른 편(슬라임)은 오지 않는다")


## 몬스터 감지 화면 = 보이는 화면(V19): 화면 확대(render.json view.camera_zoom)를 바꿔도 감지 범위가 그대로 따라간다.
func test_sight_follows_camera_zoom() -> void:
	var view := JsonUtil.get_dict(db.render, "view")
	var zoom := JsonUtil.get_float(view, "camera_zoom", 2.0)
	var tile := JsonUtil.get_array(view, "floor_tile_px")
	var margin := float(db.bal("monsters.screen_margin_tiles", 0.5))
	var half := MonsterSight.new(db, FloorMap.new(db, 3, 3, "rock_wall")).half
	assert_near(half.x, 1280.0 * 0.5 / (float(tile[0]) * zoom) - margin, 0.0001, "감지 반 폭 = 화면 반 폭 − 여유")
	assert_near(half.y, 720.0 * 0.5 / (float(tile[1]) * zoom) - margin, 0.0001, "감지 반 높이 = 화면 반 높이 − 여유")
	var sight := MonsterSight.new(db, FloorMap.new(db, 3, 3, "rock_wall"))
	assert_true(sight.on_screen(Vector2(half.x - 0.1, 0.0)) and not sight.on_screen(Vector2(half.x + 0.1, 0.0)), "화면 가장자리 안쪽만 본다")
