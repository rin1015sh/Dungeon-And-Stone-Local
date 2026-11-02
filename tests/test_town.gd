extends TestCase
## 도시 동네 지도(CT82 — 2026-11-02 사용자 "횡스크롤을 버리자 · 7구역 전체 · M0"): 라비기온 7구역 칸 지도 · 시설 문 · 걷기 · 실내는 없다.


func _town() -> TownMap:
	return TownMap.load_for(db)


func test_district_is_dense_and_every_door_is_reachable() -> void:
	var t := _town()
	assert_eq(Vector2i(t.width, t.height), Vector2i(160, 220), "7구역 전체 160×220칸")
	assert_true(t.is_walkable(t.start), "들어온 자리는 걷는 칸")
	var plain := t.houses.filter(func(h: Dictionary) -> bool: return str(h["facility"]).is_empty())
	assert_true(plain.size() >= 300, "집이 오밀조밀하다(%d채)" % plain.size())
	var reach := t.map.reachable_from(t.start)
	var order: Array = JsonUtil.get_array(db.singletons.get("city", {}), "facility_order")
	for fac: Variant in order:
		var h := t.house_of(str(fac))
		assert_false(h.is_empty(), "%s 건물" % fac)
		var front := Vector2i(t.door_front(str(fac)).floor())
		assert_true(reach[t.map.idx(front)] != 0, "%s 문 앞까지 걸어 닿는다" % fac)
		assert_eq(t.target(t.door_front(str(fac)), Vector2i.UP).get("door", ""), str(fac), "%s 문 앞에서 위를 보면 그 문" % fac)
	assert_eq(t.house_of("library").get("style", ""), "rotunda", "도서관은 원형 열람당(사용자 2026-11-02)")


func test_lots_are_shallow_and_do_not_overlap() -> void:
	var t := _town()
	var grid := PackedByteArray()
	grid.resize(t.width * t.height)
	var overlaps := 0
	var bad := 0
	for h: Dictionary in t.houses:
		var rc: Rect2i = h["rect"]
		if str(h["facility"]).is_empty() and (mini(rc.size.x, rc.size.y) < 2 or mini(rc.size.x, rc.size.y) > TownMap.ROW_MAX + 2):
			bad += 1
		if str(h.get("style", "")) == "rotunda":
			continue
		for y in range(rc.position.y, rc.end.y):
			for x in range(rc.position.x, rc.end.x):
				var i := y * t.width + x
				overlaps += grid[i]
				grid[i] = 1
	assert_eq(bad, 0, "집 깊이는 얕다(줄 깊이 %d~%d)" % [TownMap.ROW_MIN, TownMap.ROW_MAX])
	assert_eq(overlaps, 0, "필지가 겹치지 않는다")


func test_walk_blocked_by_houses_and_stairs_go_up_down() -> void:
	var t := _town()
	var h := t.house_of("inn")
	var front := t.door_front("inn")
	var moved := Kinematics.move(t.map, front, Vector2(0, -3), 0.3, 0.8, 0.25)
	assert_true(moved.y > front.y - 1.0, "문 앞에서 위로 걸어도 건물 안으로 들어가지 않는다")
	assert_false(h.is_empty())
	var stairs := 0
	for y in t.height:
		for x in t.width:
			if t.kind_at(Vector2i(x, y)) == "stairs":
				stairs += 1
	assert_true(stairs > 40, "테라스 사이 계단")
	assert_true(t.gates.size() > 0, "구역문")
	var ring := t.target(Vector2(t.dais["center"]) + Vector2(0.5, float(t.dais["r"]) + 0.5), Vector2i.UP)
	assert_true(ring.has("ring"), "광장 돌 단을 바라본다")


func test_no_interiors_left() -> void:
	assert_false(db.collections.has("rooms") and not db.get_collection("rooms").is_empty(), "걸어 다니는 실내 방은 지웠다(사용자 2026-11-02)")
	for id: String in db.get_collection("facilities"):
		var f := db.get_entry("facilities", id)
		assert_false(f.has("room") or f.has("interior"), "%s 실내 항목 없음" % id)
	assert_false(ResourceLoader.exists("res://assets/city/interiors/inn.webp"), "실내 그림 없음")
	for id in ["cobble", "slabs", "plaster", "clay", "slate", "lead"]:
		assert_true(ResourceLoader.exists("res://assets/town/mat/%s.webp" % id), "재질 그림 " + id)
