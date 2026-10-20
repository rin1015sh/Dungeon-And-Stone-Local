class_name CityBonds
extends RefCounted
## 인연(사용자 결정 2026-10-20, CT38): 시설마다 한 사람(직함만 — 원작 실명 인물 없음, data/city_people).
##   사람 = {id, name_ko, facility, gain{활동 id: 점수}, stages[{at, min_renown, scene, effects[], check{stat, min, pass{scene, effects}, fail{…}}, perks{discount{활동 id: 비율}, unlock[활동 id]}}]}.
##   그 시설에서 활동을 하면 gain만큼(말 걸기 활동은 효과 bond로) 점수가 쌓이고, 다음 단계의 at·min_renown을 채우면 장면이 열린다.
##   장면 = 문자열 키(번호가 붙은 여러 쪽이면 key.1, key.2 …). effects는 그때 한 번(도시 효과 레지스트리), perks는 그 뒤로 계속.
##   check = 능력치 판정(그 스탯 값이 min 이상이면 pass) — 키운 수치가 장면에서 쓰인다.
## 수치는 화면에 보이지 않는다 — 대사·대우가 바뀌는 것으로 안다(간접 체험, UI19). 오토로드를 참조하지 않는다.


static func person_at(db: GameDatabase, facility_id: String) -> String:
	for id: String in db.get_collection("city_people"):
		if JsonUtil.get_str(db.get_entry("city_people", id), "facility") == facility_id:
			return id
	return ""


static func stages_of(db: GameDatabase, person: String) -> Array:
	return JsonUtil.get_array(db.get_entry("city_people", person), "stages")


## 열린 단계 수(0 = 아직 아무 장면도 없음).
static func stage(state: CityState, person: String) -> int:
	return int(state.bond_stage.get(person, 0))


static func points(state: CityState, person: String) -> float:
	return float(state.bonds.get(person, 0.0))


## 활동 한 번을 마쳤다: 그 시설 사람의 gain을 더한다(perform 끝에서).
static func after_activity(ctx: CityContext) -> void:
	var person := person_at(ctx.db, ctx.state.facility)
	if person.is_empty():
		return
	var g := JsonUtil.get_dict(ctx.db.get_entry("city_people", person), "gain")
	if g.has(ctx.activity_id) and g[ctx.activity_id] != null:
		add(ctx, person, float(g[ctx.activity_id]))


## 점수를 더하고 채운 단계의 장면을 연다(여러 단계를 한 번에 넘지는 않는다 — 한 번에 한 장면).
static func add(ctx: CityContext, person: String, amount: float) -> void:
	var state := ctx.state
	state.bonds[person] = points(state, person) + amount
	var stages := stages_of(ctx.db, person)
	var i := stage(state, person)
	if ctx.scene_played or i >= stages.size() or not stages[i] is Dictionary:
		return
	var st: Dictionary = stages[i]
	if points(state, person) < JsonUtil.get_float(st, "at") or CityRenown.stage(state) < JsonUtil.get_int(st, "min_renown"):
		return
	state.bond_stage[person] = i + 1
	ctx.scene_played = true
	_play(ctx, st)
	var check := JsonUtil.get_dict(st, "check")
	if not check.is_empty():
		var stat := JsonUtil.get_str(check, "stat")
		var passed := ctx.pc.stats.has_stat(stat) and ctx.pc.stats.get_value(stat) >= JsonUtil.get_float(check, "min")
		_play(ctx, JsonUtil.get_dict(check, "pass" if passed else "fail"))
		state.bond_checks[person + ":" + str(i + 1)] = passed


## 장면 글 + 그때 한 번의 효과.
static func _play(ctx: CityContext, part: Dictionary) -> void:
	var key := JsonUtil.get_str(part, "scene")
	if not key.is_empty():
		var n := 0
		while Strings.has("%s.%d" % [key, n + 1]):
			n += 1
			ctx.say("%s.%d" % [key, n], {}, "info")
		if n == 0 and Strings.has(key):
			ctx.say(key, {}, "info")
	if ctx.registry == null:
		return
	for e: Variant in JsonUtil.get_array(part, "effects"):
		if e is Dictionary:
			var h := ctx.registry.instance(JsonUtil.get_str(e, "type")) as CityEffect
			if h != null:
				h.apply(ctx, e)


## 열린 단계의 perks(그 단계 이후 계속). 판정에 실패한 단계의 pass.perks는 들어가지 않는다.
static func perks(state: CityState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for person: String in state.bond_stage:
		var stages := stages_of(state.db, person)
		for i in mini(stage(state, person), stages.size()):
			var st := stages[i] as Dictionary
			if st == null:
				continue
			out.append(JsonUtil.get_dict(st, "perks"))
			var check := JsonUtil.get_dict(st, "check")
			if not check.is_empty():
				var passed := bool(state.bond_checks.get(person + ":" + str(i + 1), false))
				out.append(JsonUtil.get_dict(JsonUtil.get_dict(check, "pass" if passed else "fail"), "perks"))
	return out


## 이 활동의 이용료 배율(인연 할인이 여럿이면 곱한다).
static func cost_rate(state: CityState, act_id: String) -> float:
	var rate := 1.0
	for p in perks(state):
		var d := JsonUtil.get_dict(p, "discount")
		if d.has(act_id) and d[act_id] != null:
			rate *= clampf(1.0 - float(d[act_id]), 0.0, 1.0)
	return rate


## 인연으로 열린 활동(이 시설의 것).
static func unlocked_at(state: CityState, facility_id: String) -> Array[String]:
	var out: Array[String] = []
	for p in perks(state):
		for a: Variant in JsonUtil.get_array(p, "unlock"):
			var id := str(a)
			if JsonUtil.get_str(state.db.get_entry("activities", id), "facility") == facility_id and not out.has(id):
				out.append(id)
	return out
