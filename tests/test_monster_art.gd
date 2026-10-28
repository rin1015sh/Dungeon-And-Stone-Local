extends TestCase
## 몬스터 전투 일러스트(tools/paint_monsters.gd → assets/monsters): 데이터의 몬스터마다 그림과 몸 높이 색인이 있는지.
## 새 몬스터를 추가하면 tools/monster_art/Specs.gd(또는 Specs2)에 설계를 넣고 --only=<id>로 그린다(없으면 도형으로 보인다).


func _dir() -> String:
	return JsonUtil.get_str(JsonUtil.get_dict(db.render, "ui"), "combat_art_dir", "res://assets/monsters")


func test_every_monster_has_art() -> void:
	var missing := PackedStringArray()
	for id: String in db.get_collection("monsters"):
		if not ResourceLoader.exists(_dir().path_join(id + ".webp")):
			missing.append(id)
	assert_eq(missing.size(), 0, "그림 없는 몬스터: " + ", ".join(missing))


func test_index_has_body_heights() -> void:
	var errors: Array[String] = []
	var index: Variant = JsonUtil.read_file(_dir().path_join("index.json"), errors)
	assert_true(index is Dictionary, "index.json 읽기")
	if not index is Dictionary:
		return
	for id: String in db.get_collection("monsters"):
		var tex := load(_dir().path_join(id + ".webp")) as Texture2D
		var body := JsonUtil.get_float(index, id, 0.0)
		assert_true(body > 0.0, "몸 높이: " + id)
		if tex != null:
			assert_true(body < tex.get_height() * 2.0, "몸 높이가 그림에 견줘 터무니없지 않다: " + id)


## 아군 그림(tools/monster_art/Party.gd): 쓸 수 있는 종족마다 탐험가 뒷모습·옆모습, 플레이어가 부를 수 있는 몬스터마다 뒷모습.
func test_party_art_for_races() -> void:
	var dir := JsonUtil.get_str(JsonUtil.get_dict(db.render, "ui"), "combat_party_art_dir", "res://assets/party")
	var errors: Array[String] = []
	var index: Variant = JsonUtil.read_file(dir.path_join("index.json"), errors)
	assert_true(index is Dictionary, "탐험가 그림 색인")
	for race: String in db.get_collection("races"):
		if not JsonUtil.get_bool(db.get_entry("races", race), "enabled", false):
			continue
		for view: String in ["back"]:
			assert_true(ResourceLoader.exists(dir.path_join(race + "_" + view + ".webp")), "탐험가 그림: " + race + "_" + view)
			if index is Dictionary:
				assert_true(JsonUtil.get_float(index, race + "_" + view, 0.0) > 0.0, "탐험가 몸 높이: " + race + "_" + view)
		for sheet: String in ["_back_motions", "_back_dead"]:  # 전투 동작(PartySprite — tools/paint_motions.gd, UI41)
			assert_true(ResourceLoader.exists(dir.path_join(race + sheet + ".webp")), "탐험가 동작 그림: " + race + sheet)


## 행동 → 탐험가 동작(PartySprite.motion_for): 기본 공격 = 칼, 물리 피해 스킬 = 주먹, 마법·그 밖 = 주문.
func test_party_motion_for_actions() -> void:
	assert_eq(PartySprite.motion_for(db, {"kind": "skill", "skill": Battle.BASIC_ATTACK}), "swing", "기본 공격(한손)")
	assert_eq(PartySprite.motion_for(db, {"kind": "skill", "skill": Battle.BASIC_ATTACK}, "two_hand"), "heavy", "기본 공격(양손)")
	assert_eq(PartySprite.motion_for(db, {"kind": "skill", "skill": Battle.BASIC_ATTACK}, "bow"), "shoot", "기본 공격(활)")
	assert_eq(PartySprite.weapon_kind(db, "hunting_bow"), "bow", "사냥 활 = 활")
	assert_eq(PartySprite.weapon_kind(db, "dread_bone_greatsword"), "two_hand", "대검 = 양손")
	assert_eq(PartySprite.motion_for(db, {"kind": "guard"}), "stance", "방어 = 전투 자세")
	assert_eq(PartySprite.motion_for(db, {"kind": "item", "item": "x"}), "spell", "아이템")
	assert_eq(PartySprite.motion_for(db, {"kind": "flee"}), "spell", "도망 = 주문")
	assert_eq(PartySprite.motion_for(db, {"kind": "skill", "skill": "ess_banshee_wail"}), "spell", "마법 스킬")
	assert_eq(PartySprite.motion_for(db, {"kind": "skill", "skill": "ess_blater_cursed_slash"}), "thrust", "물리 스킬")


func test_summon_back_art() -> void:
	var missing := PackedStringArray()
	for id: String in _player_summons():
		if not ResourceLoader.exists(_dir().path_join(id + "_back.webp")):
			missing.append(id)
	assert_eq(missing.size(), 0, "뒷모습 그림 없는 아군 소환수(tools/monster_art/Party.gd SUMMONS에 추가): " + ", ".join(missing))


## 플레이어가 부를 수 있는 몬스터: 정수판 스킬(ess_*)의 summon 효과 + 정수 패시브 low_hp_summons.
func _player_summons() -> PackedStringArray:
	var out := PackedStringArray()
	for sid: String in db.get_collection("skills"):
		if not sid.begins_with("ess_"):
			continue
		for e: Variant in JsonUtil.get_array(db.get_entry("skills", sid), "effects"):
			if e is Dictionary and JsonUtil.get_str(e, "type") == "summon":
				var ids: Array = JsonUtil.get_array(e, "pick").duplicate()
				if JsonUtil.get_str(e, "monster") != "":
					ids.append(JsonUtil.get_str(e, "monster"))
				for m: Variant in ids:
					if not out.has(str(m)):
						out.append(str(m))
	for eid: String in db.get_collection("essences"):
		var pas := JsonUtil.get_dict(db.get_entry("essences", eid), "passive")
		for m: Variant in JsonUtil.get_array(JsonUtil.get_dict(pas, "low_hp_summons"), "monsters"):
			if not out.has(str(m)):
				out.append(str(m))
	return out
