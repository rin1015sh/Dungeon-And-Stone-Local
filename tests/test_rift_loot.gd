extends TestCase
## 균열 바닥에 놓인 물건(RiftLoot)·대기 무리 고정 자리(RiftPosts marks.posts) — 2026-10-30 docs/plans/rift_rooms.md, RF25.


func _chapter(chapter: int) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), pc, GameClock.new(), Rng.new(5), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, "rift_green_mine", s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	for i in chapter:
		cs.rift_run.debug_clear()
		cs = cs.rift_run.use_exit(cs)
	return cs


func _blueprint(chapter: int) -> Dictionary:
	return FloorMapFile.read("res://data/maps/rifts/rift_green_mine_ch%d.json" % (chapter + 1))


func test_loot_lies_where_the_blueprint_says() -> void:
	var cs := _chapter(0)
	var marks := JsonUtil.get_dict(_blueprint(0), "marks")
	var list := JsonUtil.get_array(cs.rift_run.chapters()[0], "loot")
	assert_eq(cs.loot.size(), list.size(), "놓인 물건 수 = 데이터")
	var first: Array = JsonUtil.get_array(marks, "loot")[1]
	var at := Vector2i(int(first[0]), int(first[1]))
	assert_eq(str((cs.loot[at] as Dictionary)["item"]), JsonUtil.get_str(list[1], "item"), "같은 순서의 칸에 놓인다")


func test_pick_up_once_and_keep_it_outside() -> void:
	var cs := _chapter(0)
	var at: Vector2i = cs.loot.keys().filter(func(c: Vector2i) -> bool: return str((cs.loot[c] as Dictionary)["item"]) == "mine_hammer")[0]
	cs.pos = at + Vector2i(0, 1) if cs.map.is_walkable(at + Vector2i(0, 1)) else at
	assert_eq(RiftLoot.target_name(cs), DataNames.entry(db, "items", "mine_hammer"), "살피기 안내에 물건 이름")
	assert_true(RiftLoot.run(cs))
	assert_eq(cs.player.inventory.count("mine_hammer"), 1, "옆에서 살피면 줍는다")
	assert_false(cs.loot.has(at), "한 번뿐")
	assert_false(RiftLoot.run(cs), "두 번 줍지 않는다")
	cs.rift_run.finish()
	assert_eq(cs.player.inventory.count("mine_hammer"), 1, "균열 밖으로 가지고 나간다")


func test_posts_stand_on_fixed_cells() -> void:
	var cs := _chapter(1)
	var cells: Array = JsonUtil.get_array(JsonUtil.get_dict(_blueprint(1), "marks"), "posts")
	for c: Variant in cells:
		var p := Vector2i(int((c as Array)[0]), int((c as Array)[1]))
		var g := cs.monsters.group_at(p)
		assert_true(g != null and g.guard, "%s에 대기 무리" % p)


func test_rift_gear_bonus_does_not_take_the_shop_combo() -> void:
	var helmet := db.get_entry("items", "mine_helmet")
	var mods: Array = JsonUtil.get_array(JsonUtil.get_dict(helmet, "equip"), "modifiers")
	assert_true(mods.any(func(m: Dictionary) -> bool: return str(m["target"]) == "resist_poison"), "광부 안전모의 덤(독 내성)")
	assert_true(db.has_entry("items", "quartz_ring"), "녹수정 반지가 있어도 대장간의 수정 반지는 그대로")
