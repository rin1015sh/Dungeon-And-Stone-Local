extends TestCase
## 격자 인벤토리 · 장비 · 가방↔장비 옮기기 · 무기 피해.


func _pc(cls: String = "warrior") -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", cls, "시험", {"str": 10, "agi": 8, "p_res": 5})


func test_grid_placement_and_stacking() -> void:
	var inv := Inventory.new(db, 4, 3)
	assert_eq(inv.add("padded_armor"), 1)
	assert_eq(inv.stacks()[0]["pos"], Vector2i(0, 0), "왼쪽 위부터")
	assert_eq(inv.add("leather_armor"), 1)
	assert_eq(inv.stacks()[1]["pos"], Vector2i(2, 0), "옆 빈자리")
	assert_eq(inv.add("leather_hood"), 0, "2×2 자리가 없다")
	assert_eq(inv.add("magic_stone_9", 60), 0, "남은 칸이 없다")
	assert_eq(Inventory.new(db, 4, 3).add("steel_spear"), 0, "1×4 창은 높이 3 가방에 안 들어간다")
	var big := Inventory.new(db, 4, 3)
	assert_eq(big.add("magic_stone_9", 60), 60)
	assert_eq(big.stacks().size(), 2, "50개씩 쌓인다")
	assert_eq(big.count("magic_stone_9"), 60)
	assert_true(big.remove("magic_stone_9", 55))
	assert_eq(big.stacks().size(), 1)
	assert_eq(big.count("magic_stone_9"), 5)


func test_move_merge_and_bounds() -> void:
	var inv := Inventory.new(db, 6, 4)
	inv.add("steel_sword")
	inv.add("ration", 3)
	var sword := inv.stack_at(Vector2i(0, 0))
	assert_false(inv.move_stack(sword, Vector2i(5, 2)), "1×3 검이 밖으로 나간다")
	assert_true(inv.move_stack(sword, Vector2i(5, 1)))
	assert_eq(inv.stack_at(Vector2i(5, 3)), sword, "검이 덮는 칸")
	assert_true(inv.place("ration", 2, Vector2i(3, 3)))
	var second := inv.stack_at(Vector2i(3, 3))
	var first := -1
	for i in inv.stacks().size():
		if inv.stacks()[i]["id"] == "ration" and i != second:
			first = i
	assert_true(inv.move_stack(second, inv.stacks()[first]["pos"]), "같은 아이템 위에 놓으면 쌓인다")
	assert_eq(inv.count("ration"), 5)
	assert_eq(inv.stacks().filter(func(s: Dictionary) -> bool: return s["id"] == "ration").size(), 1)


func test_inventory_save_roundtrip() -> void:
	var pc := _pc()
	pc.inventory.add("magic_stone_9", 7)
	var copy := Inventory.new(db)
	copy.load_dict(pc.inventory.to_dict())
	assert_eq(copy.count("magic_stone_9"), 7)
	assert_eq(copy.count("torch"), pc.inventory.count("torch"))
	assert_eq(copy.money, pc.inventory.money)
	assert_eq(copy.stacks().size(), pc.inventory.stacks().size())


func test_start_equipment_and_modifiers() -> void:
	var pc := _pc("warrior")
	assert_eq(pc.equipment.item_in("main_hand"), "iron_mace")
	assert_eq(pc.equipment.item_in("off_hand"), "wooden_shield")
	assert_eq(pc.attack_damage_type(), "blunt", "철퇴 = 타격")
	var bare := _pc("warrior")
	for s in Equipment.SLOTS:
		bare.equipment.unequip(bare.stats, s)
	assert_near(pc.stats.get_value("p_res") - bare.stats.get_value("p_res"), 3.0 + 3.0 + 1.0, 0.001, "방패 3 + 누빔 3 + 허리띠 1")
	assert_true(pc.inventory.money > 0, "시작 스톤")
	assert_true(pc.hotbar.has("minor_potion") and pc.hotbar.has("torch"), "쓸 수 있는 소지품이 단축칸에")


func test_two_handed_and_rings() -> void:
	var pc := _pc("warrior")
	pc.inventory.add("steel_spear")
	var i := pc.inventory.stacks().size() - 1
	assert_true(InventoryActions.equip_stack(pc, i), "양손 창 장착")
	assert_eq(pc.equipment.item_in("main_hand"), "steel_spear")
	assert_true(pc.equipment.is_empty("off_hand"), "양손이면 보조 칸이 빈다")
	assert_eq(pc.inventory.count("iron_mace"), 1, "철퇴는 가방으로")
	assert_eq(pc.inventory.count("wooden_shield"), 1, "방패도 가방으로")
	assert_false(pc.stats.has_source("equip:off_hand"), "방패 수정자가 떨어졌다")
	pc.inventory.add("copper_ring", 2)
	for n in 2:
		var r := -1
		for k in pc.inventory.stacks().size():
			if pc.inventory.stacks()[k]["id"] == "copper_ring":
				r = k
		assert_true(InventoryActions.equip_stack(pc, r))
	assert_false(pc.equipment.is_empty("ring_l") or pc.equipment.is_empty("ring_r"), "반지 두 개")
	assert_true(InventoryActions.unequip_to_bag(pc, "ring_l"))
	assert_eq(pc.inventory.count("copper_ring"), 1)


func test_equip_swap_and_no_room() -> void:
	var pc := _pc("swordsman")
	pc.inventory = Inventory.new(db, 1, 3)
	pc.inventory.add("iron_mace")
	assert_true(InventoryActions.equip_stack(pc, 0), "철퇴가 빠진 자리에 검이 들어간다")
	assert_eq(pc.equipment.item_in("main_hand"), "iron_mace")
	assert_eq(pc.inventory.count("steel_sword"), 1)
	assert_eq(pc.inventory.add("ration"), 0, "1×3 가방은 검으로 가득")
	assert_false(InventoryActions.unequip_to_bag(pc, "body"), "자리가 없으면 벗지 않는다(아이템을 잃지 않는다)")
	assert_eq(pc.equipment.item_in("body"), "leather_armor")


func test_weapon_changes_damage() -> void:
	var pc := _pc("warrior")
	var with_weapon := DamageCalc.attack_power(db, pc, {"scaling": "phys"})
	pc.equipment.unequip(pc.stats, "main_hand")
	var bare := DamageCalc.attack_power(db, pc, {"scaling": "phys"})
	var mace := float(ItemInfo.weapon(db, "iron_mace")["attack"])
	assert_near(with_weapon - bare, mace - float(db.bal("combat.unarmed_atk")), 0.001, "철퇴 공격력")
	assert_eq(pc.attack_damage_type(), "blunt", "맨손은 템플릿 기본 유형")
