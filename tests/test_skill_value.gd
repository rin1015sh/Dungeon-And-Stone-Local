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


## 효율 하한(CB8 — 사용자 2026-11-07 "효율이 낮은 스킬도 올려"): 영혼력을 쓰는 피해 스킬(위력 0.6 넘게)의 위력 ÷ 영혼력이
## 같은 등급 이하(더 낮은 정수 포함) 같은 종류(단일 · 전체) 정수 스킬 중앙값의 70% 이상 — 높은 등급 정수가 낮은 정수보다 눈에 띄게 손해가 아니게.
func test_essence_skill_efficiency_floor() -> void:
	var grade := {}
	for eid: String in db.get_collection("essences"):
		var e := db.get_entry("essences", eid)
		for a: Dictionary in JsonUtil.get_array(e, "actives"):
			var sid := JsonUtil.get_str(a, "skill")
			grade[sid] = maxi(int(grade.get(sid, 0)), JsonUtil.get_int(e, "grade"))
	var rows: Array = []
	for sid: String in grade:
		var sk := db.get_entry("skills", sid)
		var p := 0.0
		for e: Dictionary in JsonUtil.get_array(sk, "effects"):
			if JsonUtil.get_str(e, "type") == "damage":
				p += JsonUtil.get_float(e, "power", 1.0) * maxi(1, JsonUtil.get_int(e, "hits", 1))
		var soul := JsonUtil.get_float(JsonUtil.get_dict(sk, "cost"), "soul", 0.0)
		if p <= 0.6 + 0.001 or soul <= 0.0:
			continue
		rows.append({"id": sid, "g": int(grade[sid]), "aoe": JsonUtil.get_str(sk, "target") in ["enemy_all", "enemy_row"], "e": p / soul})
	for r: Dictionary in rows:
		var ref: Array = []
		for o: Dictionary in rows:
			if o["id"] != r["id"] and o["aoe"] == r["aoe"] and int(o["g"]) >= int(r["g"]):
				ref.append(float(o["e"]))
		if ref.is_empty():
			continue
		ref.sort()
		var med: float = ref[ref.size() / 2] if ref.size() % 2 == 1 else (float(ref[ref.size() / 2 - 1]) + float(ref[ref.size() / 2])) / 2.0
		assert_true(float(r["e"]) >= med * 0.7 - 0.001, "%s 효율 %.3f < 중앙 %.3f × 0.7" % [r["id"], r["e"], med])
