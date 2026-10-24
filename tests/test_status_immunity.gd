extends TestCase
## 보스 상태이상 면역(UI25)과 상태 아이콘 3개씩 넘기기(StatusIcons).


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 14, "agi": 12, "p_res": 12, "m_res": 8, "int": 10})
	pc.pool.fill_all()
	return pc


func test_boss_ranks_ignore_foe_debuffs() -> void:
	var pc := _pc()
	var ranks: Array = db.bal("combat.status_immune_ranks", [])
	for id: String in db.get_collection("monsters"):
		var m := Monster.create(db, id, "대상")
		var boss := ranks.has(JsonUtil.get_str(m.def, "rank"))
		if m.def.has("status_immune_all"):
			boss = JsonUtil.get_bool(m.def, "status_immune_all")
		var r := Passives.try_status(db, null, pc, m, "stun")
		if boss:
			assert_eq(r, "immune", id + " 기절 면역")
		elif not Passives.is_immune(m, "stun"):
			assert_true(r != "immune", id + "는 등급 면역이 아니다")


func test_boss_still_gets_own_and_mechanic_statuses() -> void:
	var pc := _pc()
	var boss := Monster.create(db, "king_slime", "킹")
	assert_eq(Passives.try_status(db, null, pc, boss, "poison"), "immune")
	assert_eq(Passives.try_status(db, null, null, boss, "poison"), "", "출처 없는 것(패턴·균열 목표)은 걸린다")
	assert_eq(Passives.try_status(db, null, boss, boss, "stun"), "", "자기 자신에게는 걸린다")
	assert_eq(Passives.try_status(db, null, pc, boss, "haste"), "", "이로운 상태는 걸린다")
	for sid in ["regen_stopped", "tear_sealed", "blast_scorched"]:
		assert_true(JsonUtil.get_bool(db.get_entry("statuses", sid), "boss_mechanic"), sid)
		assert_eq(Passives.try_status(db, null, pc, boss, sid), "", sid + " 는 보스에게도(약점·히든 피스)")


func test_monster_flag_overrides_rank() -> void:
	var pc := _pc()
	var gob := Monster.create(db, "goblin", "고블린")
	gob.def = gob.def.duplicate()
	gob.def["status_immune_all"] = true
	assert_eq(Passives.try_status(db, null, pc, gob, "bleeding"), "immune")
	var boss := Monster.create(db, "king_slime", "킹")
	boss.def = boss.def.duplicate()
	boss.def["status_immune_all"] = false
	assert_eq(Passives.try_status(db, null, pc, boss, "bleeding"), "")


func test_icons_page_three_at_a_time() -> void:
	var pc := _pc()
	var icons := StatusIcons.new()
	for sid in ["poison", "bleeding", "stun", "marked", "frost"]:
		pc.statuses.apply(sid)
	assert_true(icons.show_for(pc))
	assert_eq(icons.page_count(), 2)
	assert_eq(icons.shown(), 3)
	icons._process(_sec() + 0.01)
	assert_eq(icons.shown(), 2, "다음 쪽")
	icons._process(_sec() + 0.01)
	assert_eq(icons.shown(), 3, "처음으로 돌아온다")
	pc.statuses.remove("frost")
	pc.statuses.remove("marked")
	icons.show_for(pc)
	assert_eq(icons.page_count(), 1)
	icons._process(_sec() + 0.01)
	assert_eq(icons.modulate.a, 1.0, "한 쪽이면 깜빡이지 않는다")
	icons.free()


func _sec() -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(JsonUtil.get_dict(db.render, "ui"), "combat_status_icon"), "page_sec", 1.8)
