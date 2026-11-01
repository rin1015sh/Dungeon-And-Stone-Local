extends TestCase
## 보스 방 문 닫힘(V23 — BossGates): 보스가 깨어나면 그 방의 문목을 창살로 막고(트인 곳은 닫지 않는다), 보스를 쓰러뜨리면 연다.


## 보스 방 12×10(x 22~33, y 18~27) + 서쪽 3칸 복도(y 21~23) → 서쪽 큰 방 + 북쪽 1칸 문(x 27) → 북쪽 큰 방
## + 방 안 기둥 2×2(x 25~26, y 24~25 — 기둥 사이·벽 사이 좁은 칸은 문목이 아니다) + 동쪽 벽감(x 34, y 19~20 — 막다른 곳).
func _room() -> FloorMap:
	var map := FloorMap.new(db, 60, 40, "rock_wall")
	for y in range(18, 28):
		for x in range(22, 34):
			map.set_tile(Vector2i(x, y), "cave_floor")
	for x in range(14, 22):  # 서쪽 복도
		for y in range(21, 24):
			map.set_tile(Vector2i(x, y), "cave_floor")
	for y in range(2, 14):  # 서쪽 큰 방
		for x in range(2, 14):
			map.set_tile(Vector2i(x, y), "cave_floor")
	for y in range(13, 24):
		for x in range(2, 5):
			map.set_tile(Vector2i(x, y), "cave_floor")
	for x in range(2, 15):
		for y in range(21, 24):
			map.set_tile(Vector2i(x, y), "cave_floor")
	for y in range(12, 18):  # 북쪽 좁은 문
		map.set_tile(Vector2i(27, y), "cave_floor")
	for y in range(1, 12):  # 북쪽 큰 방
		for x in range(20, 50):
			map.set_tile(Vector2i(x, y), "cave_floor")
	for c: Vector2i in [Vector2i(25, 24), Vector2i(26, 24), Vector2i(25, 25), Vector2i(26, 25)]:
		map.set_tile(c, "rock_wall")  # 기둥
	map.set_tile(Vector2i(34, 19), "cave_floor")  # 벽감
	map.set_tile(Vector2i(34, 20), "cave_floor")
	map.set_tile(Vector2i(29, 22), "bf_table")  # 방 안의 서 있는 장식 — 벽으로 치지 않는다
	map.visible_now.fill(1)
	return map


func test_finds_doorways_of_the_room() -> void:
	var map := _room()
	var gates := BossGates.find(map, Vector2i(30, 22), Vector2i(24, 26), 4, 1600)
	assert_true(gates.has(Vector2i(21, 21)) and gates.has(Vector2i(21, 22)) and gates.has(Vector2i(21, 23)), "서쪽 복도 입구 세 칸 (%s)" % str(gates))
	assert_true(gates.has(Vector2i(27, 17)), "북쪽 문")
	assert_eq(gates.size(), 4, "문목만 — 기둥 둘레·벽감에는 내리지 않는다 (%s)" % str(gates))
	for g in gates:
		assert_true(map.is_walkable(g), "걸을 수 있던 칸에만")


## 플레이어가 복도에서 보스를 봤으면 플레이어 뒤쪽 복도를 막는다(플레이어 바로 곁은 빼고).
func test_player_in_corridor_is_shut_in_behind() -> void:
	var map := _room()
	var player := Vector2i(18, 22)
	var gates := BossGates.find(map, Vector2i(30, 22), player, 4, 1600)
	assert_false(gates.is_empty())
	for g in gates:
		assert_true(maxi(absi(g.x - player.x), absi(g.y - player.y)) > 1, "플레이어 바로 곁에는 내리지 않는다 %s" % str(g))
	assert_true(gates.any(func(g: Vector2i) -> bool: return g.x < player.x - 1), "플레이어 뒤쪽(서쪽)에 막는다 (%s)" % str(gates))


func test_open_field_is_not_shut() -> void:
	var map := FloorMap.new(db, 80, 80, "rock_wall")
	for y in range(1, 79):
		for x in range(1, 79):
			map.set_tile(Vector2i(x, y), "cave_floor")
	assert_true(BossGates.find(map, Vector2i(40, 40), Vector2i(35, 40), 4, 1600).is_empty(), "트인 곳에는 창살을 내리지 않는다")


## 세션: 닫으면 걸을 수 없고, 보스 무리를 쓰러뜨리면 원래 타일로.
func test_close_then_open_on_victory() -> void:
	var map := _room()
	var fm := FieldMonsters.new(db, map, {"regions": [], "spawn": {}}, Rng.new(1))
	var g := fm.add_fixed(["blater"], Vector2i(30, 22))
	var bg := BossGates.new()
	var cells := bg.close(map, g, Vector2i(24, 26), db, fm.groups)
	assert_eq(cells.size(), 4)
	assert_false(map.is_walkable(Vector2i(21, 22)), "창살은 지나갈 수 없다")
	assert_eq(map.tile_id_at(Vector2i(21, 22)), str(db.bal("boss_gate.tile")))
	assert_false(bg.sealed(), "문목이 있으면 길목은 그대로")
	assert_true(bg.close(map, g, Vector2i(24, 26), db, fm.groups).is_empty(), "한 번만 닫는다")
	bg.open(map, g.id)
	assert_true(map.is_walkable(Vector2i(21, 22)) and map.tile_id_at(Vector2i(21, 22)) == "cave_floor", "열면 원래대로")


## 트인 굴(챕터 전체가 보스 터 — 문목이 없다): 균열 길목 입구를 막고 길목을 봉한다. 쓰러뜨리면 풀린다.
func test_open_arena_seals_passages() -> void:
	var map := FloorMap.new(db, 40, 40, "rock_wall")
	for y in range(1, 39):
		for x in range(1, 39):
			map.set_tile(Vector2i(x, y), "cave_floor")
	map.set_tile(Vector2i(0, 20), "cave_floor")
	map.portals.append({"id": "rift_back", "pos": Vector2i(0, 20), "kind": "rift_back", "passage": true, "mouth": [Vector2i(0, 20)] as Array[Vector2i]})
	var fm := FieldMonsters.new(db, map, {"regions": [], "spawn": {}}, Rng.new(1))
	var g := fm.add_fixed(["blater"], Vector2i(20, 20))
	var bg := BossGates.new()
	var cells := bg.close(map, g, Vector2i(15, 20), db, fm.groups)
	assert_eq(cells, [Vector2i(0, 20)] as Array[Vector2i], "길목 입구")
	assert_true(bg.sealed(), "길목이 봉해졌다")
	bg.open(map, g.id)
	assert_false(bg.sealed())
	assert_true(map.is_walkable(Vector2i(0, 20)))
