extends TestCase
## 균열 매복(RiftAmbush — 핏빛성채 도개교)·떠도는 무리(조우 kind roam) — 2026-10-30 RF26.


func _chapter(rift_id: String, chapter: int) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), pc, GameClock.new(), Rng.new(5), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, rift_id, s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	return cs if chapter == 0 else cs.rift_run.build_chapter(chapter)  # 출구 물건(폭약) 없이 바로 그 챕터를


func _ambush_groups(cs: ExploreSession) -> Array:
	return cs.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.tag == "ambush")


func _bridge() -> Dictionary:
	var ch: Dictionary = JsonUtil.get_array(db.get_entry("rifts", "rift_blood_fortress"), "chapters")[1]
	return JsonUtil.get_array(ch, "encounters").filter(func(e: Dictionary) -> bool: return JsonUtil.get_str(e, "kind") == "ambush")[0]


func test_bridge_is_empty_until_the_middle() -> void:
	var cs := _chapter("rift_blood_fortress", 1)
	var r := RiftAmbush.trigger_rect(_bridge())
	assert_eq(_ambush_groups(cs).size(), 0, "처음엔 도개교에 데드맨이 없다")
	for g: FieldMonsters.Group in cs.monsters.groups:
		assert_false(absi(g.pos.y - 20) <= 1 and g.pos.x >= 44 and g.pos.x <= 58, "다리 위에 서 있는 무리 없음 %s" % g.pos)
	assert_true(cs.relocate(r.position + Vector2i(1, 1)), "다리 한가운데로")
	var amb := _ambush_groups(cs)
	assert_eq(amb.size(), 2, "양쪽에서 두 무리")
	var xs := amb.map(func(g: FieldMonsters.Group) -> int: return g.pos.x)
	assert_true(xs.min() < r.position.x and xs.max() > r.end.x, "한 무리는 뒤(서쪽), 한 무리는 앞(동쪽)")
	for g: FieldMonsters.Group in amb:
		assert_eq(g.state, FieldMonsters.STATE_CHASE, "곧장 쫓아온다")
		assert_true(cs.rift_run.remaining.has(g))
	cs.relocate(r.position)
	assert_eq(_ambush_groups(cs).size(), 2, "한 번뿐 — 다시 지나도 더 나오지 않는다")


func test_one_fight_clears_every_ambush_pack() -> void:
	for result: String in [Battle.RESULT_VICTORY, Battle.RESULT_FLED]:
		var cs := _chapter("rift_blood_fortress", 1)
		cs.relocate(RiftAmbush.trigger_rect(_bridge()).position + Vector2i(1, 1))
		var g: FieldMonsters.Group = _ambush_groups(cs)[0]
		cs.in_combat = true
		cs.resolve_encounter(g, result, 1, [] as Array[String])
		assert_eq(_ambush_groups(cs).size(), 0, "%s: 한 무리와 싸우면 데드맨 무리 모두 사라진다" % result)
		assert_false(cs.rift_run.remaining.any(func(q: FieldMonsters.Group) -> bool: return q.tag == "ambush"))


func test_roaming_packs_are_placed_in_every_chapter() -> void:
	for rid: String in db.get_collection("rifts"):
		var chapters := JsonUtil.get_array(db.get_entry("rifts", rid), "chapters")
		for i in chapters.size():
			var want := 0
			for e: Variant in JsonUtil.get_array(chapters[i], "encounters"):
				if JsonUtil.get_str(e, "kind") == "roam":
					want += JsonUtil.get_int(e, "count")
			if want == 0:
				continue
			var cs := _chapter(rid, i)
			var roam := cs.rift_run.remaining.filter(func(g: FieldMonsters.Group) -> bool: return g.tag == "roam" and not g.guard)
			assert_eq(roam.size(), want, "%s %d챕터: 떠도는 무리 수" % [rid, i + 1])
