extends TestCase
## 필드 몬스터의 경계 순찰(사용자 2026-10-27 "빙빙 돌지 말고 주변을 순찰·경계하는 느낌") · 화면 밖은 모른다(V19) · 종마다 빠르기.
## 감지·의심·추적·수색·조사·무리 부르기는 test_monster_ai(V22).


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


## 화면 반 크기(칸, 여유 뺀 값 — MonsterSight가 뷰포트·칸 크기·줌으로 셈).
func _half() -> Vector2:
	return MonsterSight.new(db, FloorMap.new(db, 3, 3, "rock_wall")).half




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
