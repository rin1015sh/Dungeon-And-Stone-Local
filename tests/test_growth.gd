extends TestCase
## G1 성장 체계(docs/PROMPT_FLOOR1_V2.md §5): 레벨 문턱 · 레벨업 보상 · 획득원 · 레벨 하락과 정수 슬롯 잠금 · 경험치 예산.


func _pc(bases: Dictionary = {"str": 12, "agi": 12, "p_res": 8, "m_res": 5, "int": 8}) -> PlayerCharacter:
	# 장비 보정이 끼지 않게 시작 장비가 없는 템플릿 대신 장비를 벗긴다.
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", bases)
	for slot: String in pc.equipment.to_dict().keys():
		pc.equipment.unequip(pc.stats, slot)
	pc.pool.fill_all()
	return pc


func test_level_thresholds() -> void:
	var table := Progression.exp_table(db)
	assert_eq(table.map(func(v: Variant) -> int: return int(v)), [0, 8, 50, 250, 660, 1000, 1400, 2600, 3400, 4400, 18000],
		"명세 §5.2 레벨 표")
	assert_eq(Progression.level_for(db, 7), 1)
	assert_eq(Progression.level_for(db, 8), 2, "문턱 그대로 2레벨")
	assert_eq(Progression.level_for(db, 659), 4)
	assert_eq(Progression.level_for(db, 660), 5)
	assert_eq(Progression.level_for(db, 17999), 10)
	assert_eq(Progression.level_for(db, 18000), 11)
	assert_eq(Progression.level_for(db, 999999), 11, "만렙 11")
	assert_eq(Progression.exp_for_next(db, 4), 660)
	assert_eq(Progression.exp_for_level(db, 5), 660)


func test_level_rewards_soul_hp_slots() -> void:
	var pc := _pc()
	assert_eq(pc.pool.get_max("hp"), 99.0, "인간 Lv1 기준 탐험가 생명력 99 (§1의 102에서 근력×1.5 뺌 — J12, 항마력×3 더함 — BL2)")
	assert_eq(pc.pool.get_max("soul"), 30.0, "Lv1 영혼력 30")
	var expect := {2: 40.0, 5: 70.0, 6: 100.0, 11: 250.0}
	for lv: int in expect:
		pc.set_level(lv)
		assert_eq(pc.pool.get_max("soul"), float(expect[lv]), "Lv%d 영혼력" % lv)
		assert_eq(Progression.essence_slots(db, lv), lv, "슬롯 = 레벨")
	pc.set_level(4)
	assert_eq(pc.pool.get_max("hp"), 129.0, "레벨당 생명력 +10")


func test_exp_sources() -> void:
	var p := Progression.new()
	assert_eq(Progression.first_kill_exp(db, {"grade": 7, "upper_variant": true}), 4, "상위 변이종 +1")
	assert_eq(Progression.first_kill_exp(db, {"grade": 9, "rank": "ungraded"}), 0, "무등급 0")
	assert_eq(Progression.first_kill_exp(db, {"grade": 9, "rank": "token"}), 0, "토큰 0")
	assert_eq(Progression.guardian_exp(db, {"grade": 6, "rank": "guardian", "floor": 1}), 3)
	assert_eq(Progression.guardian_exp(db, {"grade": 3, "rank": "guardian", "floor": 8}), 5, "8층 이상 +5")
	assert_eq(Progression.guardian_exp(db, {"grade": 9}), 0)
	assert_eq(Progression.monster_floor({"floor_tags": ["f1_north"]}), 1)
	# 포탈: 1~5층은 달마다, 6층부터는 한 번
	assert_eq(p.record_portal(db, "east", 1, 0), 2)
	assert_eq(p.record_portal(db, "east", 1, 0), 0, "같은 달 두 번째 통과")
	assert_eq(p.record_portal(db, "east", 1, 1), 2, "다음 달 다시")
	assert_eq(p.record_portal(db, "deep", 6, 0), 2)
	assert_eq(p.record_portal(db, "deep", 6, 1), 0, "6층부터는 리셋 없음")
	assert_eq(p.record_hidden_portal(db, "h1"), 99)
	assert_eq(p.record_hidden_portal(db, "h1"), 0)


func test_guardian_repeats_and_lord_once() -> void:
	var d := GameDatabase.new()
	d.load_all("res://data")
	var g := d.get_entry("monsters", "goblin").duplicate(true)
	g["id"] = "test_guardian"
	g["grade"] = 6
	g["rank"] = "guardian"
	d.put_entry("monsters", g)
	var l := d.get_entry("monsters", "goblin").duplicate(true)
	l["id"] = "test_lord"
	l["grade"] = 5
	l["rank"] = "lord"
	d.put_entry("monsters", l)
	var p := Progression.new()
	assert_eq(p.record_kill(d, "test_guardian"), 4 + 3, "첫 처치 4 + 수호자 3")
	assert_eq(p.record_kill(d, "test_guardian"), 3, "수호자 보너스는 반복")
	assert_eq(p.record_kill(d, "test_lord"), 15, "군주는 첫 처치 경험치 없이 보너스 15만(명세 §5.6)")
	assert_eq(p.record_kill(d, "test_lord"), 0, "군주 보너스는 1회")


func test_dreaming_soul() -> void:
	var pc := _pc()
	assert_true(pc.progression.use_dreaming_soul(pc))
	assert_false(pc.progression.use_dreaming_soul(pc), "한 번만")
	assert_eq(pc.progression.exp_total, 0, "10레벨 전에는 대기")
	pc.progression.gain(pc, 4400)
	assert_eq(pc.progression.exp_total, 14400, "10레벨에 닿으면 +10000")
	assert_eq(pc.get_level(), 10)
	pc.progression.gain(pc, 3600)
	assert_eq(pc.get_level(), 11, "18000 → 11레벨")


func test_level_down_locks_and_unlocks_essence_slots() -> void:
	var pc := _pc()
	pc.essence_rng = Rng.new(11)
	pc.progression.gain(pc, 250)
	assert_eq(pc.get_level(), 4)
	for e: Array in [["goblin", "red"], ["ghoul", "red"], ["blade_wolf", "red"], ["gnome", "blue"]]:
		assert_eq(pc.essences.absorb(pc, {"essence": e[0], "color": e[1], "stats": {}}), "")
	var soul_skills := pc.skills.size()
	assert_eq(pc.progression.lose(pc, 201, Rng.new(3)), 2, "영혼 베기: 250 → 49 = 2레벨")
	assert_eq(pc.essences.locked_count(), 2, "슬롯 2개 → 정수 2개 잠김")
	assert_eq(pc.skills.size(), soul_skills - 2, "잠긴 정수의 이능은 쓸 수 없다")
	assert_eq(pc.essences.absorb(pc, {"essence": "goblin", "color": "green", "stats": {}}), "essence.reason_no_slot",
		"잠긴 정수도 슬롯을 차지한다")
	var locked_a := PackedStringArray()
	for e in pc.essences.absorbed:
		if EssenceSet.is_locked(e):
			locked_a.append(str(e["essence"]))
	# 같은 시드면 같은 정수가 잠긴다
	var pc2 := _pc()
	pc2.progression.gain(pc2, 250)
	for e: Array in [["goblin", "red"], ["ghoul", "red"], ["blade_wolf", "red"], ["gnome", "blue"]]:
		pc2.essences.absorb(pc2, {"essence": e[0], "color": e[1], "stats": {}})
	pc2.progression.lose(pc2, 201, Rng.new(3))
	var locked_b := PackedStringArray()
	for e in pc2.essences.absorbed:
		if EssenceSet.is_locked(e):
			locked_b.append(str(e["essence"]))
	assert_eq(locked_a, locked_b, "시드 고정 → 같은 잠금")
	pc.progression.gain(pc, 201)
	assert_eq(pc.get_level(), 4)
	assert_eq(pc.essences.locked_count(), 0, "레벨이 돌아오면 풀린다")
	assert_eq(pc.skills.size(), soul_skills)
	var data := pc.progress_to_dict()
	pc.progression.lose(pc, 201, Rng.new(3))
	var copy := _pc()
	copy.progress_load_dict(pc.progress_to_dict())
	assert_eq(copy.essences.locked_count(), 2, "잠금 상태도 저장된다")
	assert_eq(data["essences"]["absorbed"].size(), 4)


func test_exp_budget_report() -> void:
	var r := ExpBudget.report(db)
	var floors: Dictionary = r["floors"]
	assert_eq(int(floors[1]["actual"]), 117, "1층: 명세 §5.6 합계 108(변종 수호자 제외) + 무등급이던 데드맨 3종·스컬 랫을 9등급으로(사용자 2026-10-29, UI48) 4 + 핏빛성채 스켈레톤 아처 · 메이지 · 벤시 8등급으로(BL13) 5")
	assert_eq(int(floors[1]["species"]), 49, "필드 10 + 군주 1 + 핏빛성채 14(데드맨 3종·스컬 랫 포함, UI48) + 빙하굴 10 + 녹색 탄광 7 + 강철의 묘 7(토큰·변종 수호자 제외)")
	assert_eq(int(r["lv5_need"]), 660)
	assert_eq(int(r["lv5_total"]), 647, "1~4층 합(데이터가 모자라면 목표치) — 1층 117 + 530")
	assert_true(bool(r["ok"]), "647 / 660 = 98% — 93~99% 범위")
	assert_true(str(r["markdown"]).contains("경험치 예산"))
