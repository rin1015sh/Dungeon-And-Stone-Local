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


## 상자(V25): 장비·좋은 회복약만, 한 챕터 3개까지 — 앞뒤를 고르고 동전: 맞히면 담긴 물건, 못 맞히면 그 균열 잡템. 어느 쪽이든 한 번 열면 빈 상자.
func test_chest_guess_gives_item_or_junk() -> void:
	var junk: Array = JsonUtil.get_array(db.get_entry("scavenge", "mine_stores"), "items").map(func(e: Variant) -> String: return str((e as Dictionary)["item"]))
	var hits := 0
	var misses := 0
	for seed in 12:
		var cs := _chapter(0)
		cs.rng = Rng.new(100 + seed * 7)
		var chests: Array = cs.loot.keys().filter(func(c: Vector2i) -> bool: return RiftChest.locked(cs.loot[c]))
		assert_true(chests.size() >= 1 and chests.size() <= int(db.bal("chest.max_per_chapter")), "상자 %d개" % chests.size())
		var at: Vector2i = cs.loot.keys().filter(func(c: Vector2i) -> bool: return str((cs.loot[c] as Dictionary)["item"]) == "mine_hammer")[0]
		assert_true(RiftChest.locked(cs.loot[at]), "장비는 상자에")
		cs.pos = at + Vector2i(0, 1) if cs.map.is_walkable(at + Vector2i(0, 1)) else at
		assert_eq(RiftLoot.target_name(cs), Strings.t("explore.chest"), "열기 전엔 안이 보이지 않는다")
		var pick := seed % 2  # 앞면·뒷면 번갈아 고른다
		var heads := [false]
		cs.coin_guess.connect(func(then: Callable) -> void: then.call(pick))
		cs.coin_toss.connect(func(h: bool, then: Callable) -> void:
			heads[0] = h
			then.call())
		assert_true(RiftLoot.run(cs))
		assert_false(RiftChest.locked(cs.loot[at]), "한 번 열면 빈 상자")
		var hit: bool = (pick == 0) == bool(heads[0])
		if hit:
			hits += 1
			assert_eq(cs.player.inventory.count("mine_hammer"), 1, "맞히면 담긴 물건")
		else:
			misses += 1
			assert_eq(cs.player.inventory.count("mine_hammer"), 0, "못 맞히면 장비는 없다")
			assert_true(junk.any(func(j: String) -> bool: return cs.player.inventory.count(j) > 0), "그 균열 잡템 하나")
		assert_false(RiftLoot.target(cs) == at, "빈 상자는 다시 살피지 않는다")
	assert_true(hits > 0 and misses > 0, "맞힘 %d · 못 맞힘 %d" % [hits, misses])


func test_chest_guess_back_out_keeps_it_closed() -> void:
	var cs := _chapter(0)
	var at: Vector2i = cs.loot.keys().filter(func(c: Vector2i) -> bool: return str((cs.loot[c] as Dictionary)["item"]) == "mine_hammer")[0]
	cs.pos = at + Vector2i(0, 1) if cs.map.is_walkable(at + Vector2i(0, 1)) else at
	var tossed := [false]
	cs.coin_guess.connect(func(then: Callable) -> void: then.call(-1))
	cs.coin_toss.connect(func(_h: bool, _then: Callable) -> void: tossed[0] = true)
	assert_true(RiftLoot.run(cs))
	assert_false(tossed[0], "Esc로 물러나면 던지지 않는다")
	assert_true(RiftChest.locked(cs.loot[at]), "상자는 그대로")


## 가방이 가득하면 동전 전에 "가방에 자리가 없다."만 — 담긴 물건 이름을 미리 알리지 않는다(사용자 2026-11-01).
func test_chest_full_bag_does_not_name_the_item() -> void:
	var cs := _chapter(0)
	var at: Vector2i = cs.loot.keys().filter(func(c: Vector2i) -> bool: return str((cs.loot[c] as Dictionary)["item"]) == "mine_hammer")[0]
	cs.pos = at + Vector2i(0, 1) if cs.map.is_walkable(at + Vector2i(0, 1)) else at
	while cs.player.inventory.fits("mine_hammer", 1):
		if cs.player.inventory.add("magic_stone_9", 99) == 0:
			break
	assert_false(cs.player.inventory.fits("mine_hammer", 1), "가방이 가득")
	var said: Array[String] = []
	cs.message.connect(func(key: String, args: Dictionary, _kind: String) -> void: said.append(Strings.t(key, args)))
	var asked := [false]
	cs.coin_guess.connect(func(_then: Callable) -> void: asked[0] = true)
	assert_true(RiftLoot.run(cs))
	assert_false(asked[0], "자리가 없으면 앞뒤를 묻지 않는다")
	assert_eq(said, [Strings.t("city.reason_bag_full")] as Array[String], "자리가 없다는 말만")
	assert_false(said.any(func(l: String) -> bool: return l.contains(DataNames.entry(db, "items", "mine_hammer"))), "담긴 물건 이름은 말하지 않는다")
	assert_true(RiftChest.locked(cs.loot[at]), "상자는 그대로")


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


func test_coin_is_fair() -> void:
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


## 균열 장비는 대장간의 같은 종류 × 소재보다 세다(balance items.rift_gear — 사용자 2026-11-01 "균열 소재 장비 수치 올려줘").
func test_rift_gear_beats_the_smithy() -> void:
	var sword := JsonUtil.get_dict(db.get_entry("items", "fortress_knight_sword"), "equip")
	var plain := JsonUtil.get_dict(db.get_entry("items", "steel_sword"), "equip")
	assert_true(int(JsonUtil.get_dict(sword, "weapon")["attack"]) > int(JsonUtil.get_dict(plain, "weapon")["attack"]), "공격력이 높다")
	var str_of := func(e: Dictionary) -> int:
		for m: Dictionary in JsonUtil.get_array(e, "modifiers"):
			if str(m["target"]) == "str" and m.has("flat"):
				return int(m["flat"])
		return 0
	assert_true(int(str_of.call(sword)) >= int(str_of.call(plain)) + 2, "힘도 더 오른다")
	var hammer := JsonUtil.get_dict(db.get_entry("items", "mine_hammer"), "equip")
	var cuts := JsonUtil.get_array(hammer, "modifiers").filter(func(m: Dictionary) -> bool: return JsonUtil.get_float(m, "flat") < 0.0)
	assert_true(cuts.is_empty(), "깎이는 수치가 없다(IT13)")
	assert_true(int(db.get_entry("items", "fortress_knight_sword")["price"]) > int(db.get_entry("items", "steel_sword")["price"]), "값도 더 나간다")


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
