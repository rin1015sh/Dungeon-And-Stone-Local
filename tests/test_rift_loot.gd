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
	var at: Vector2i = cs.loot.keys().filter(func(c: Vector2i) -> bool: return str((cs.loot[c] as Dictionary)["item"]) == "mine_rough_gem")[0]
	assert_false(RiftChest.locked(cs.loot[at]), "보석은 상자가 아니라 바닥에 놓인다")
	cs.pos = at + Vector2i(0, 1) if cs.map.is_walkable(at + Vector2i(0, 1)) else at
	assert_eq(RiftLoot.target_name(cs), DataNames.entry(db, "items", "mine_rough_gem"), "살피기 안내에 물건 이름")
	assert_true(RiftLoot.run(cs))
	assert_eq(cs.player.inventory.count("mine_rough_gem"), 1, "옆에서 살피면 줍는다")
	assert_false(cs.loot.has(at), "한 번뿐")
	assert_false(RiftLoot.run(cs), "두 번 줍지 않는다")
	cs.rift_run.finish()
	assert_eq(cs.player.inventory.count("mine_rough_gem"), 1, "균열 밖으로 가지고 나간다")


## 상자(V25): 장비·좋은 회복약만, 한 챕터 3개까지 — 동전 앞면이면 꺼내고(상자는 열린 채 남는다), 뒷면이면 함정(생명력이 준다)이고 다시 던질 수 있다.
func test_chest_holds_gear_and_opens_by_coin() -> void:
	var cs := _chapter(0)
	var chests: Array = cs.loot.keys().filter(func(c: Vector2i) -> bool: return RiftChest.locked(cs.loot[c]))
	assert_true(chests.size() >= 1 and chests.size() <= int(db.bal("chest.max_per_chapter")), "상자 %d개" % chests.size())
	var at: Vector2i = cs.loot.keys().filter(func(c: Vector2i) -> bool: return str((cs.loot[c] as Dictionary)["item"]) == "mine_hammer")[0]
	assert_true(RiftChest.locked(cs.loot[at]), "장비는 상자에")
	cs.pos = at + Vector2i(0, 1) if cs.map.is_walkable(at + Vector2i(0, 1)) else at
	assert_eq(RiftLoot.target_name(cs), Strings.t("explore.chest"), "열기 전엔 안이 보이지 않는다")
	var tails := 0
	for i in 60:
		var hp := cs.player.pool.get_current("hp")
		assert_true(RiftLoot.run(cs))
		if not RiftChest.locked(cs.loot[at]):
			break
		tails += 1
		assert_true(cs.player.pool.get_current("hp") < hp, "뒷면 = 자물쇠 함정")
		cs.player.pool.fill_all()
	assert_false(RiftChest.locked(cs.loot[at]), "언젠가 앞면")
	assert_eq(cs.player.inventory.count("mine_hammer"), 1, "앞면이면 꺼낸다")
	assert_true(cs.loot.has(at), "열린 상자는 남는다")
	assert_false(RiftLoot.run(cs) and cs.player.inventory.count("mine_hammer") > 1, "빈 상자에서 두 번 꺼내지 않는다")


func test_chest_pick_rule() -> void:
	var list := [{"item": "fortress_bread", "count": 2}, {"item": "fortress_knight_sword", "count": 1}, {"item": "fortress_wine", "count": 1},
		{"item": "fortress_chainmail", "count": 1}, {"item": "fortress_halberd", "count": 1}, {"item": "fortress_holy_water", "count": 1},
		{"item": "fortress_tourniquet", "count": 1, "chest": true}]
	var got := RiftChest.pick(db, list)
	assert_true(got.has(6), "chest: true는 늘 상자")
	assert_eq(got.size(), int(db.bal("chest.max_per_chapter")), "한 챕터 상자 수 한도 (%s)" % str(got))
	assert_eq([1, 3, 4].filter(func(i: int) -> bool: return got.has(i)).size(), got.size() - 1, "남은 자리는 장비 먼저 — 회복약보다 (%s)" % str(got))
	assert_false(got.has(0) or got.has(5), "빵·성수는 바닥")
	var all_rifts := 0
	var boxes := 0
	for r: String in ["rift_blood_fortress", "rift_glacier_cave", "rift_green_mine", "rift_iron_tomb"]:
		for ch: Variant in JsonUtil.get_array(db.get_entry("rifts", r), "chapters"):
			var loot := JsonUtil.get_array(ch as Dictionary, "loot")
			all_rifts += loot.size()
			boxes += RiftChest.pick(db, loot).size()
	assert_true(boxes * 3 < all_rifts, "상자를 남용하지 않는다: 놓인 물건 %d개 중 상자 %d" % [all_rifts, boxes])


func test_important_battles_flip_a_coin() -> void:
	assert_true(CoinToss.important(db, ["blater"]), "수호자")
	assert_true(CoinToss.important(db, ["skull_rat", "corpse_golem"]), "중간보스가 낀 구성")
	assert_false(CoinToss.important(db, ["goblin", "goblin"]), "보통 전투는 정정당당하게")
	var reg := ContentRegistries.new()
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	var party: Array[Actor] = [pc]
	var b := Battle.from_encounter(db, reg, Rng.new(1), party, ["blater"], Combatant.SIDE_PARTY, "combat.start_coin_heads")
	assert_eq(str(b.history[0]["key"]), "combat.start_coin_heads")
	assert_true(b.side_units(Combatant.SIDE_PARTY)[0].gauge > b.side_units(Combatant.SIDE_ENEMY)[0].gauge, "앞면 = 아군이 앞서 시작")
	var heads := 0
	var rng := Rng.new(9)
	for i in 400:
		heads += 1 if CoinToss.flip(db, rng, "chest") else 0
	assert_true(heads > 150 and heads < 250, "반반 (%d/400)" % heads)


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


func test_every_loot_and_post_is_reachable() -> void:
	for rid: String in db.get_collection("rifts"):
		for ch: Variant in JsonUtil.get_array(db.get_entry("rifts", rid), "chapters"):
			var path := JsonUtil.get_str(JsonUtil.get_dict(ch as Dictionary, "map"), "blueprint")
			var data := FloorMapFile.read(path)
			var marks := JsonUtil.get_dict(data, "marks")
			var seen := _reach(data, JsonUtil.get_array(marks, "entry"))
			for key: String in ["loot", "posts"]:
				for c: Variant in JsonUtil.get_array(marks, key):
					assert_true(seen.has(Vector2i(int((c as Array)[0]), int((c as Array)[1]))), "%s %s %s에 시작에서 걸어서 닿는다" % [path.get_file(), key, c])


## 설계도에서 시작 칸부터 걸을 수 있는 칸(4방향).
func _reach(data: Dictionary, entry: Array) -> Dictionary:
	var rows := JsonUtil.get_array(data, "rows")
	var legend := JsonUtil.get_dict(data, "legend")
	var walk := func(p: Vector2i) -> bool:
		if p.y < 0 or p.y >= rows.size() or p.x < 0 or p.x >= str(rows[p.y]).length():
			return false
		return JsonUtil.get_bool(db.get_entry("tiles", str(legend.get(str(rows[p.y])[p.x], ""))), "walkable")
	var start := Vector2i(int(entry[0]), int(entry[1]))
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_back()
		for d in FloorMap.DIRS4:
			if not seen.has(p + d) and walk.call(p + d):
				seen[p + d] = true
				queue.append(p + d)
	return seen
