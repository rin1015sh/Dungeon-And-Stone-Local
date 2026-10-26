extends TestCase
## 갑옷 겹 그림(ArmorLook · render.json view.armor_art, AM43): 장착한 장비 소재 종류 → 벌(가죽 leather · 쇠 iron), 얹는 순서는 order,
## 겹 그림을 그리는 종족은 벌 × 칸 그림이 모두 있다(맵 걷기 시트 · 전투 뒷모습·옆모습).


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 10, "p_res": 10, "m_res": 8, "int": 8})


func _wear(pc: PlayerCharacter, id: String) -> void:
	assert_false(db.get_entry("items", id).is_empty(), "장비 %s가 있다" % id)
	for slot in Equipment.SLOTS:
		if pc.equipment.item_in(slot) != "" and pc.equipment.slots_for(id).has(slot):
			pc.equipment.unequip(pc.stats, slot)
	pc.equipment.equip(pc.stats, id, pc.equipment.pick_slot(id))


func test_layers_follow_material_kind_in_order() -> void:
	var pc := _pc()
	for slot: String in ["head", "body", "hands", "feet"]:
		if pc.equipment.item_in(slot) != "":
			pc.equipment.unequip(pc.stats, slot)
	assert_eq(ArmorLook.layers(db, pc.equipment, db.render), [] as Array[String], "맨몸 = 겹 없음")
	_wear(pc, "iron_helm")
	_wear(pc, "leather_armor")
	_wear(pc, "leather_boots")
	_wear(pc, "steel_gauntlets")
	assert_eq(ArmorLook.layers(db, pc.equipment, db.render), ["leather_feet", "leather_body", "iron_hands", "iron_head"] as Array[String], "칸 순서 = 신발 · 몸 · 장갑 · 머리")
	_wear(pc, "padded_armor")
	assert_false(ArmorLook.layers(db, pc.equipment, db.render).has("leather_body"), "천(누비 갑옷)은 겹이 없다 — 밑옷 그대로")


func test_every_layer_painted_for_human() -> void:
	var c := ArmorLook.cfg(db.render)
	var sheet := JsonUtil.get_dict(JsonUtil.get_dict(db.render, "view"), "actor_sheet")
	var cell := JsonUtil.get_array(sheet, "cell")
	for set_id: Variant in JsonUtil.get_dict(c, "sets").values():
		for slot: Variant in JsonUtil.get_array(c, "order"):
			var name := "%s_%s.webp" % [set_id, slot]
			var map_path := JsonUtil.get_str(c, "map_dir").path_join("human").path_join(name)
			assert_true(ResourceLoader.exists(map_path), "맵 겹 그림 %s — tools/paint_actors.gd --armor" % map_path)
			if ResourceLoader.exists(map_path):
				var tex := load(map_path) as Texture2D
				assert_eq(Vector2i(tex.get_size()), Vector2i(int(cell[0]) * JsonUtil.get_int(sheet, "cols", 5), int(cell[1]) * 4), "%s = 걷기 시트 크기" % name)
			for view: String in ["back", "side"]:
				var path := JsonUtil.get_str(c, "party_dir").path_join("human_" + view).path_join(name)
				assert_true(ResourceLoader.exists(path), "전투 겹 그림 %s — tools/paint_monsters.gd --armor" % path)
				var body := load("res://assets/party/human_%s.webp" % view) as Texture2D
				if ResourceLoader.exists(path):
					assert_eq(Vector2i((load(path) as Texture2D).get_size()), Vector2i(body.get_size()), "%s %s = 몸 그림 크기" % [view, name])
