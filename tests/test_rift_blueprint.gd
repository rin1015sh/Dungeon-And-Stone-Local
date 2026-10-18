extends TestCase
## A5 균열 설계도 지도(docs/plans/rift_spaces.md, RiftBlueprintGenerator): 모든 챕터가 설계도를 쓰고,
## 시작에서 조우·출구·함정 자리에 걸어서 닿으며, 히든 피스는 옆 칸에서 살필 수 있고, 정해진 자리에 놓인다.


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14})
	pc.pool.fill_all()
	return pc


func _enter(rift: String) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), _pc(), GameClock.new(), Rng.new(5), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, rift, s.pos)
	return s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])


func test_every_chapter_uses_blueprint() -> void:
	for rid: String in db.get_collection("rifts"):
		for ch: Variant in JsonUtil.get_array(db.get_entry("rifts", rid), "chapters"):
			var path := JsonUtil.get_str(JsonUtil.get_dict(ch, "map"), "blueprint")
			assert_true(FloorMapFile.exists(path), "설계도: %s %s" % [rid, JsonUtil.get_str(ch, "id")])
			assert_eq(RiftBlueprintGenerator.problems(FloorMapFile.read(path), db).size(), 0, "설계도 형식: " + path)


func test_chapters_are_walkable_and_anchored() -> void:
	for rid: String in db.get_collection("rifts"):
		var cs := _enter(rid)
		var run := cs.rift_run
		for i in run.chapters().size():
			if i > 0:
				cs = run.build_chapter(i)
			var where := "%s %d" % [rid, i + 1]
			var m := cs.map
			assert_eq(cs.floor_def["generator"], "rift_blueprint", where)
			assert_true(m.width * m.height >= 2000, "챕터가 넓다(네모 방 이은 48×16이 아니다): " + where)
			var seen := m.reachable_from(m.entry)
			for p: Vector2i in m.slots:
				assert_eq(seen[m.idx(p)], 1, "조우 자리에 닿는다 %s %s" % [where, p])
			assert_eq(seen[m.idx(m.portals[0]["pos"])], 1, "출구에 닿는다: " + where)
			var spots: Array = m.anchors.get("hazards", [])
			for p: Vector2i in spots:
				assert_true(run.hazards.at.has(p), "함정은 정해진 자리에 %s %s" % [where, p])
			for p: Vector2i in run.hidden.at:
				var ok := false
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					ok = ok or (m.in_bounds(p + d) and seen[m.idx(p + d)] == 1)
				assert_true(ok, "히든 피스 옆 칸에 닿는다 %s %s" % [where, p])
			assert_eq(run.hidden.at.size(), JsonUtil.get_array(run.chapters()[i], "hidden").size(), "히든 피스가 다 놓인다: " + where)


func test_outdoor_chapters_see_farther() -> void:
	var cs := _enter("rift_blood_fortress")
	var out := cs.rift_run.chapter_floor_def(0)
	var inner := cs.rift_run.chapter_floor_def(3)
	assert_true(float(out["visibility_cap_m"]) > float(inner["visibility_cap_m"]), "하늘이 열린 바깥 챕터는 더 멀리 보인다")


func test_void_tiles_block_walk_not_sight() -> void:
	for id: String in ["bf_void", "gc_void", "gm_void", "it_void"]:
		var t := TileDef.from_dict(db.get_entry("tiles", id), 0)
		assert_true(t.is_void and not t.walkable and not t.blocks_sight, "낭떠러지: " + id)
