extends TestCase
## 도시 동네 지도(CT82 — 2026-11-02 사용자 "횡스크롤을 버리자 · 7구역 전체 · M0"): 라비기온 7구역 칸 지도 · 시설 문 · 걷기 · 실내는 없다.
## v3(CT95 — 2026-11-03 "좋은데 이대로 진행해 봐"): 도시 구상 v3 안 A 1/4 판(80 × 110칸 · 살짝 뒤틀린 집 · 단 셋 · 수로 · 퀘스트 자리).


func _town() -> TownMap:
	return TownMap.load_for(db)


func test_district_is_dense_and_every_door_is_reachable() -> void:
	var t := _town()
	assert_eq(Vector2i(t.width, t.height), Vector2i(80, 110), "v3 1/4 판 80×110칸(세로로 길다)")
	assert_true(t.is_walkable(t.start), "들어온 자리는 걷는 칸")
	var plain := t.houses.filter(func(h: Dictionary) -> bool: return str(h["facility"]).is_empty())
	assert_true(plain.size() >= 70, "집이 오밀조밀하다(%d채)" % plain.size())
	var reach := t.map.reachable_from(t.start)
	var order: Array = JsonUtil.get_array(db.singletons.get("city", {}), "facility_order")
	for fac: Variant in order:
		var h := t.house_of(str(fac))
		assert_false(h.is_empty(), "%s 건물" % fac)
		var front := Vector2i(t.door_front(str(fac)).floor())
		assert_true(reach[t.map.idx(front)] != 0, "%s 문 앞까지 걸어 닿는다" % fac)
		assert_eq(t.target(t.door_front(str(fac)), Vector2i.UP).get("door", ""), str(fac), "%s 문 앞에서 위를 보면 그 문" % fac)
	assert_eq(t.house_of("library").get("style", ""), "rotunda", "도서관은 원형 열람당(사용자 2026-11-02)")


func test_houses_are_twisted_and_block_walking() -> void:
	var t := _town()
	var big := 0
	var twisted := 0
	var plain := 0
	for h: Dictionary in t.houses:
		if not str(h["facility"]).is_empty():
			continue
		plain += 1
		var size: Vector2 = h["size"]
		if size.x > 12.5 or size.y > 12.5:
			big += 1
		if absf(rad_to_deg(float(h["angle"]))) > 3.0:
			twisted += 1
		for y in range((h["rect"] as Rect2i).position.y, (h["rect"] as Rect2i).end.y):
			for x in range((h["rect"] as Rect2i).position.x, (h["rect"] as Rect2i).end.x):
				var d := Vector2(x + 0.5, y + 0.5) - (h["center"] as Vector2)
				var a := float(h["angle"])
				if absf(d.dot(Vector2(cos(a), sin(a)))) <= size.x * 0.5 and absf(d.dot(Vector2(-sin(a), cos(a)))) <= size.y * 0.5:
					if t.kind_at(Vector2i(x, y)) != "void":  # 지도 가장자리 빈곳에 걸친 집 끝은 그대로 빈곳
						assert_eq(t.kind_at(Vector2i(x, y)), "house", "집 칸은 막힌다")
	assert_eq(big, 0, "집은 사람 크기 문에 맞는 크기(폭 · 깊이 ≤ 12칸 — 창고가 가장 크다)")
	assert_true(twisted * 2 >= plain, "집 절반 이상이 살짝 뒤틀렸다(%d/%d)" % [twisted, plain])


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
	assert_true(stairs > 40, "단 사이 계단")
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


func test_every_house_is_baked() -> void:
	var t := _town()
	var missing := PackedStringArray()
	for h: Dictionary in t.houses:
		if TownHouse.baked(h).is_empty():
			missing.append(str(h["id"]))
	assert_true(missing.is_empty(), "집 그림이 다 구워졌다 — 지도를 바꿨으면 tools/paint_town_houses.gd로 다시 굽는다(빠짐 %d: %s)" % [missing.size(), ", ".join(missing.slice(0, 8))])
	var idx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TownHouse.INDEX))
	var pages := {}
	for e: Variant in (idx["houses"] as Dictionary).values():
		pages[int((e as Dictionary)["page"])] = true
	for k: int in pages:
		assert_true(ResourceLoader.exists("res://assets/town/houses/p%d.webp" % k), "그림판 %d" % k)


func test_terraces_heights_and_places() -> void:
	var t := _town()
	var north := t.height_at(Vector2i(10, 10))
	var mid := t.height_at(t.start)
	var south := t.height_at(Vector2i(10, 92))
	assert_true(north > mid and mid > south, "북쪽이 높은 단 셋(%.1f · %.1f · %.1f)" % [north, mid, south])
	var retain := 0
	for x in t.width:
		for y in t.height:
			if t.kind_at(Vector2i(x, y)) == "retain":
				retain += 1
	assert_true(retain > 60, "단 경계는 옹벽(%d칸)" % retain)
	var stair := Vector2i(-1, -1)
	for y in t.height:
		for x in t.width:
			if stair.x < 0 and t.kind_at(Vector2i(x, y)) == "stairs" and t.kind_at(Vector2i(x, y + 1)) == "stairs":
				stair = Vector2i(x, y)
	assert_true(stair.x >= 0, "계단")
	assert_true(t.height_at(stair) > t.height_at(stair + Vector2i.DOWN), "계단은 남쪽으로 내려간다")
	var e := t.elevation(Vector2(stair) + Vector2(0.5, 0.95))
	assert_true(e < t.height_at(stair) and e > t.height_at(stair + Vector2i.DOWN), "계단 위 몸 높이는 칸 사이를 잇는다")
	var ids := {}
	for p: Dictionary in t.places:
		ids[str(p["id"])] = true
	for id in ["tavern", "well", "sewer_entrance", "black_market", "guard_post", "under_bridge"]:
		assert_true(ids.has(id), "퀘스트 자리 " + id)
	var water := 0
	for y in t.height:
		for x in t.width:
			if t.kind_at(Vector2i(x, y)) == "water":
				water += 1
				assert_true(t.height_at(Vector2i(x, y)) < south, "수로 물은 아랫단보다 낮다")
	assert_true(water > 100, "남쪽 수로")
