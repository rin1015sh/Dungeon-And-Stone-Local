extends TestCase
## 아이템 공식(ItemForge — 사용자 결정 2026-10-23, docs/balance/item_pool.md): 장비 = 종류 × 소재 등급.
## 증가 스탯·공격력만 등급 배율을 받고 감소는 종류 값 그대로(소재 가벼움·무거움만), 소재 특성, 가격, 지금 장비 id 유지.


func _mods(id: String) -> Dictionary:
	var out := {}
	for m: Variant in JsonUtil.get_array(ItemInfo.equip(db, id), "modifiers"):
		var d: Dictionary = m
		out[str(d["target"])] = JsonUtil.get_float(d, "flat", JsonUtil.get_float(d, "percent"))
	return out


func _atk(id: String) -> int:
	return JsonUtil.get_int(ItemInfo.weapon(db, id), "attack")


func test_every_type_and_material_is_forged() -> void:
	var n := 0
	for tid: String in db.get_collection("item_types"):
		var t := db.get_entry("item_types", tid)
		for mid: String in db.get_collection("materials"):
			if not JsonUtil.get_array(t, "kinds").has(JsonUtil.get_str(db.get_entry("materials", mid), "kind")):
				continue
			n += 1
			var found := false
			for id: String in db.get_collection("items"):
				var f := JsonUtil.get_dict(db.get_entry("items", id), "forged")
				found = found or (JsonUtil.get_str(f, "type") == tid and JsonUtil.get_str(f, "material") == mid)
			assert_true(found, "%s × %s 장비가 있다" % [mid, tid])
	assert_true(n >= 300, "종류 × 소재 조합 %d개" % n)


func test_spear_grows_attack_but_penalty_stays() -> void:
	assert_eq(_atk("steel_spear"), 13, "강철 창 공격력 13")
	assert_eq(_mods("steel_spear").get("agi"), -2.0, "창 = 민첩 −2(사용자 예)")
	assert_eq(_atk("mithril_spear"), 52, "미스릴(5단계) 창 = 13 × 4.0")
	assert_eq(_atk("mystium_spear"), 65, "미스티움(6단계) 창 = 13 × 5.0")
	assert_eq(_mods("airilje_spear").get("agi"), -2.0, "감소는 등급과 무관")
	assert_eq(_mods("lightium_spear").get("agi"), -1.0, "라이티늄은 가벼워 민첩 감소 절반")
	assert_eq(_mods("adamantium_plate").get("agi"), -6.0, "아다만티움은 무거워 판금 −4 × 1.5")
	assert_eq(_mods("steel_sword").get("accuracy"), 3.0)
	assert_eq(_mods("airilje_sword").get("accuracy"), 7.0, "증가는 3 × 2.3 → 7")


func test_material_traits() -> void:
	assert_near(float(_mods("airilje_spear").get("dmg_dealt:pierce", 0.0)), 0.1, 0.001, "아이릴제 = 그 무기 피해 유형 +10%")
	assert_near(float(_mods("airilje_sword").get("dmg_dealt:slash", 0.0)), 0.1, 0.001)
	assert_near(float(_mods("adamantium_plate").get("dmg_taken:magical", 0.0)), -0.5, 0.001, "아다만티움 방어구 = 속성 피해 −50%")
	assert_false(_mods("adamantium_sword").has("dmg_taken:magical"), "무기에는 방어구 특성이 없다")
	var drake := _mods("drake_leather_armor")
	assert_eq(drake.get("p_res"), roundf(3.0 * 3.1 * 0.5), "드레이크 가죽 = 물리내성 증가 절반")
	assert_eq(drake.get("m_res"), roundf(1.0 * 3.1 * 2.0) + 2.0, "항마력 증가 ×2 +2")
	var myst := _mods("mystium_spear")
	assert_eq(myst.get("agi"), -1.0, "미스티움 주 스탯 +1이 창의 민첩 −2와 합쳐진다")
	assert_eq(myst.get("str"), 1.0)


func test_prices_and_rarity() -> void:
	assert_eq(ItemInfo.price(db, "steel_sword"), 2000, "강철 장검 2,000(기준)")
	assert_eq(ItemInfo.price(db, "airilje_sword"), 480000, "아이릴제 장검 = 원작 1,200만 ÷ 25")
	assert_eq(ItemInfo.price(db, "mithril_sword"), 5000000, "5단계 장검 = 원작 억 단위")
	assert_true(ItemInfo.price(db, "mystium_sword") > ItemInfo.price(db, "mithril_sword"))
	assert_eq(JsonUtil.get_str(db.get_entry("items", "steel_sword"), "rarity"), "common")
	assert_eq(JsonUtil.get_str(db.get_entry("items", "lightium_sword"), "rarity"), "fine")
	assert_eq(JsonUtil.get_str(db.get_entry("items", "ark_sword"), "rarity"), "precious")
	assert_eq(ItemForge.nice(1234.0), 1200)
	assert_eq(ItemForge.nice(1250.0), 1300)
	assert_eq(ItemForge.nice(42.0), 40)


func test_existing_equipment_keeps_id_and_name() -> void:
	var it := db.get_entry("items", "hunting_dagger")
	assert_eq(JsonUtil.get_str(it, "name_ko"), "사냥용 단검", "이름은 그대로")
	assert_eq(JsonUtil.get_dict(it, "forged"), {"type": "dagger", "material": "steel"})
	assert_false(db.has_entry("items", "steel_dagger"), "같은 조합을 또 만들지 않는다")
	assert_eq(JsonUtil.get_str(db.get_entry("items", "lightium_spear"), "name_ko"), "라이티늄 창", "새 장비 이름 = 소재 + 종류")
	for id: Variant in JsonUtil.get_array(db.get_entry("activities", "smithy_trade"), "stock"):
		var e := db.get_entry("items", str(id))
		assert_false(e.is_empty(), "대장간 진열 %s" % id)
		assert_true(JsonUtil.get_int(e, "tier", 1) <= 2, "대장간은 2단계까지 %s" % id)


func test_smoke_bomb_raises_flee() -> void:
	var pc := PlayerCharacter.create(db, "human", "warrior", "도망", {"agi": 8})
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(2), [pc] as Array[Actor], ["goblin"], Combatant.SIDE_PARTY)
	var c := b.side_units(Combatant.SIDE_PARTY)[0]
	var before := b.flee_chance(c)
	pc.statuses.apply("smoke_cover")
	assert_true(b.flee_chance(c) > before, "연막이면 도주 확률이 오른다")
