extends TestCase
## 정수 스킬의 값어치(사용자 2026-10-24 "스킬을 써도 일반 공격보다 낮은 경우가 있다 — 스킬 메리트가 거의 없다", C15):
## 기본 공격(위력 1.0)과 견줘 — 영혼력을 쓰는 단일 대상 피해 스킬은 1.35 이상(추가 효과가 없으면 1.5),
## 대가 없는 스킬은 1.1 이상, 전체 공격은 0.8 이상. 상태를 거는 게 본업인 약한 스킬(0.6 이하)은 확률 60% 이상.
## 행동 방해(기절·마비·석화·혼란·공포)는 25% 이상, 그 밖의 상태는 50% 이상.
## 9등급 정수에만 있는 스킬은 영혼력 단일 피해 1.2 이상(사용자 2026-11-04 "135%는 고작 9등급인데 높다" — C26).

const CC := ["stun", "paralysis", "petrify", "confusion", "fear"]
const RIDER_TYPES := ["apply_status", "push_back", "gauge", "consume_status", "remove_status"]
const RIDER_KEYS := ["defense_ignore", "crit_bonus", "power_if_status", "power_if_hp_below", "rider", "drain", "power_per_summon"]


func test_essence_skills_beat_basic_attack() -> void:
	var n := 0
	var low := _grade9_only_skills()
	for id: String in db.get_collection("skills"):
		if not id.begins_with("ess_"):
			continue
		var sk := db.get_entry("skills", id)
		var effs := JsonUtil.get_array(sk, "effects")
		var total := 0.0
		var rider := false
		var statuses: Array = []
		for e: Dictionary in effs:
			var t := JsonUtil.get_str(e, "type")
			if t == "damage":
				total += JsonUtil.get_float(e, "power", 1.0) * maxi(1, JsonUtil.get_int(e, "hits", 1))
				for k in RIDER_KEYS:
					rider = rider or e.has(k)
			elif t in RIDER_TYPES:
				rider = true
			if t == "apply_status":
				statuses.append(e)
		if total <= 0.0:
			continue
		n += 1
		var aoe := JsonUtil.get_str(sk, "target") in ["enemy_all", "enemy_row"]
		var free := JsonUtil.get_dict(sk, "cost").is_empty()
		var focus := not aoe and not statuses.is_empty() and total <= 0.6 + 0.001
		var floor_ := 0.5 if focus else (0.8 if aoe else (1.1 if free else (1.2 if low.has(id) else (1.35 if rider else 1.5))))
		assert_true(total >= floor_ - 0.001, "%s 위력 %.2f < %.2f" % [id, total, floor_])
		for e: Dictionary in statuses:
			var c := JsonUtil.get_float(e, "chance", 1.0)
			var lo := 0.25 if JsonUtil.get_str(e, "status") in CC else (0.6 if focus else 0.5)
			assert_true(c >= lo - 0.001, "%s [%s] 확률 %.2f" % [id, JsonUtil.get_str(e, "status"), c])
	assert_true(n > 50, "정수 피해 스킬 %d개" % n)


## 9등급 정수에서만 얻는 스킬 id → true.
func _grade9_only_skills() -> Dictionary:
	var grades := {}
	for eid: String in db.get_collection("essences"):
		var e := db.get_entry("essences", eid)
		for a: Dictionary in JsonUtil.get_array(e, "actives"):
			var sid := JsonUtil.get_str(a, "skill")
			if not grades.has(sid):
				grades[sid] = {}
			(grades[sid] as Dictionary)[JsonUtil.get_int(e, "grade")] = true
	var out := {}
	for sid: String in grades:
		var g: Dictionary = grades[sid]
		if g.size() == 1 and g.has(9):
			out[sid] = true
	return out
