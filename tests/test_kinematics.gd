extends TestCase
## 부드러운 이동의 충돌(Kinematics): 벽 미끄러짐·터널링 방지·모서리 보정·통로 통과·대각선 틈 차단.

const HALF := 0.3


## 문자열 지도: '#' 벽, '.' 바닥.
func _map(rows: Array) -> FloorMap:
	var h := rows.size()
	var w := str(rows[0]).length()
	var map := FloorMap.new(db, w, h, "rock_wall")
	for y in h:
		for x in w:
			if str(rows[y])[x] == ".":
				map.set_tile(Vector2i(x, y), "cave_floor")
	return map


func test_open_floor_moves_freely() -> void:
	var m := _map(["#####", "#...#", "#...#", "#...#", "#####"])
	var p := Kinematics.move(m, Vector2(2.5, 2.5), Vector2(0.4, -0.3), HALF)
	assert_near(p.x, 2.9, 0.0001)
	assert_near(p.y, 2.2, 0.0001)


func test_wall_stops_and_slides() -> void:
	var m := _map(["#####", "#...#", "#...#", "#...#", "#####"])
	var p := Kinematics.move(m, Vector2(2.5, 2.5), Vector2(5.0, 0.0), HALF)
	assert_near(p.x, 4.0 - HALF, 0.002, "동쪽 벽에 붙어 멈춘다")
	assert_false(Kinematics.blocked(m, p, HALF))
	var q := Kinematics.move(m, Vector2(3.6, 2.5), Vector2(1.0, -0.5), HALF)
	assert_near(q.y, 2.0, 0.0001, "벽에 비스듬히 부딪히면 벽을 따라 미끄러진다")
	assert_near(q.x, 4.0 - HALF, 0.002)


func test_no_tunneling_through_thin_wall() -> void:
	var m := _map(["#######", "#..#..#", "#######"])
	var p := Kinematics.move(m, Vector2(1.5, 1.5), Vector2(4.0, 0.0), HALF)
	assert_true(p.x < 3.0, "한 칸 벽을 뚫고 지나가지 않는다 (x=%.2f)" % p.x)


func test_one_wide_corridor_and_corner_assist() -> void:
	var m := _map(["#######", "#...###", "#......", "#...###", "#######"])
	var p := Kinematics.move(m, Vector2(2.5, 2.5), Vector2(3.0, 0.0), HALF)
	assert_true(p.x > 5.0, "한 칸 폭 통로를 지나간다")
	var start := Vector2(2.5, 2.25)  # 통로 입구 모서리에 걸치는 높이
	var q := start
	for i in 20:
		q = Kinematics.move(m, q, Vector2(0.2, 0.0), HALF, 0.45)
	assert_true(q.x > 4.5, "모서리에 걸려도 통로 중심으로 밀려 들어간다 (%s)" % str(q))
	var r := start
	for i in 20:
		r = Kinematics.move(m, r, Vector2(0.2, 0.0), HALF, 0.0)
	assert_true(r.x < 4.0, "보정이 없으면 모서리에 걸린다")


func test_diagonal_gap_is_closed() -> void:
	var m := _map(["####", "#.##", "##.#", "####"])
	var p := Kinematics.move(m, Vector2(1.5, 1.5), Vector2(1.0, 1.0), HALF)
	assert_eq(Kinematics.cell_of(p), Vector2i(1, 1), "대각선으로 맞붙은 벽 틈은 못 지나간다")
