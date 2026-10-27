extends TestCase
## 전투 중에 나올 적의 자리를 미리(UI37 — BattleReserve): 소환·분열·증원할 수 있는 몬스터를 찾아 진영 상한까지 비워 둔다.


func test_candidates_from_summons_splits_and_reinforce() -> void:
	assert_true(BattleReserve.candidates(db, ["dreadfear"]).has("dreadfear_maggot"), "드레드피어 → 구더기(패턴·상태 효과의 소환)")
	assert_true(BattleReserve.candidates(db, ["king_slime"]).has("slime"), "킹 슬라임 → 슬라임(왕의 분열)")
	assert_true(BattleReserve.candidates(db, ["slime"]).has("slime"), "슬라임 → 자기 자신(분열)")
	assert_true(BattleReserve.candidates(db, ["deadman"], {"reinforce": {"monsters": ["soldier_deadman"]}}).has("soldier_deadman"), "증원")
	assert_true(BattleReserve.candidates(db, ["mummy"]).is_empty(), "부르지 않는 몬스터는 비워 두지 않는다")


func test_plan_fills_up_to_side_cap() -> void:
	var cap := int(db.bal("combat.max_side_units"))
	var plan := BattleReserve.plan(db, ["dreadfear"])
	assert_eq(plan.size(), cap - 1, "드레드피어 혼자면 상한까지 구더기 자리")
	assert_true(plan.all(func(id: String) -> bool: return id == "dreadfear_maggot"))
	assert_eq(BattleReserve.plan(db, ["deadman", "deadman", "deadman", "deadman", "deadman", "deadman", "deadman", "deadman"]).size(), 0, "이미 상한을 넘으면 없음")


## 미리 정한 자리(FoeRows): 큰 보스 뒤 뒷줄 자리가 보스 몸 바로 뒤에 오지 않는다.
func test_rows_never_hide_behind_front_bodies() -> void:
	var widths := PackedFloat32Array([4.0, 0.8, 0.8, 0.8, 0.8, 0.8])
	var out := FoeRows.arrange_fit(widths, 3.0, 0.2, 3, 0)
	var pos: Array = out["pos"]
	for i in range(1, widths.size()):
		var p: Vector2 = pos[i]
		if int(p.y) > 0:
			assert_true(absf(p.x) >= (4.0 + 0.8) * 0.5 * FoeRows.HIDE * float(out["k"]) - 0.01, "%d번 자리(%.2f, 줄 %d)가 보스 바로 뒤가 아니다" % [i, p.x, int(p.y)])
