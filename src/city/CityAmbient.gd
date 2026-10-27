class_name CityAmbient
extends RefCounted
## 거리 사건(사용자 결정 2026-10-21, CT42): 순이 바뀔 때(시작·귀환 포함) 행동력을 쓰지 않고 저절로 일어나는 일 — data/street_events.
##   사건 = {id, name_ko, weight, forced, cooldown_months, weather_weight{날씨: 배율},
##           when{from_month, months_of_year[], periods[], weather[], tax_month, tax_owed, residence_min, residence_max}, residence_weight{등급: 배율},
##           갈래(cost_stones · effects[] · check{stats[], target, base, per_point, min, max} · success[] · fail[]) 또는 choices[{id, 갈래}]}.
##   forced = 조건이 맞으면 굴림 없이 반드시(교수형). 그 밖은 city.json ambient.chance 확률로 하나를 weight(× 날씨 배율)로 고른다.
##   when.tax_month = 세금 기한 달에서 몇 달 뒤(0 = 기한 달), tax_owed = 올해 세금이 남았는가.
##   장면 = city.street.<id>.intro.<n>, 결과 = city.street.<id>.<결과>.<n>(n = 1부터 차례로 모두 — 결과 = 선택지 id 또는 result,
##   판정이 있으면 뒤에 _ok·_fail). 효과 = 도시 효과 레지스트리(src/city/effects). 판정은 CityState.rng. 오토로드를 참조하지 않는다.

const COL := "street_events"
const RESULT := "result"
## 거리 사건에서도 띄우는 효과 문구(장면으로 말할 수 없는 것 — 못 받은 물건).
const SHOWN_FX := ["city.fx.item_no_room"]

## 테스트·캡처에서 끈다(꺼지면 굴리지 않는다).
static var enabled: bool = true


static func config(state: CityState) -> Dictionary:
	return CityValues.city_section(state.db, state.overrides, "ambient")


static func entry(state: CityState, id: String) -> Dictionary:
	return state.db.get_entry(COL, id)


## 이번 순의 사건을 고른다(순마다 한 번 — CityState.ambient_pending, 이미 굴렸으면 ""). 고른 id(없으면 "").
static func roll(state: CityState, race_id: String) -> String:
	if not state.ambient_pending:
		return ""
	state.ambient_pending = false
	state.ambient = ""
	if not enabled:
		return ""
	var pool := eligible(state, race_id)
	var forced := pool.filter(func(id: String) -> bool: return JsonUtil.get_bool(entry(state, id), "forced"))
	var id := ""
	if not forced.is_empty():
		id = str(forced[0])
	else:
		pool = pool.filter(func(e: String) -> bool: return not JsonUtil.get_bool(entry(state, e), "forced"))
		if pool.is_empty() or not state.rng.chance(clampf(CityValues.num(config(state), "chance"), 0.0, 1.0)):
			return ""
		id = _pick(state, pool)
	state.ambient = id
	state.ambient_seen[id] = state.month
	state.changed.emit()
	return id


## 굴리지 않고 이 사건을 이번 순 사건으로(디버그·테스트·캡처). 없는 id면 "".
static func force(state: CityState, id: String) -> String:
	if not state.db.has_entry(COL, id):
		return ""
	state.ambient_pending = false
	state.ambient = id
	state.ambient_seen[id] = state.month
	return id


## 지금 일어날 수 있는 사건 id(이름순).
static func eligible(state: CityState, race_id: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in state.db.get_collection(COL):
		if _ok(state, entry(state, id), id, race_id):
			out.append(id)
	out.sort()
	return out


static func _ok(state: CityState, e: Dictionary, id: String, race_id: String) -> bool:
	if _weight(state, e) <= 0.0:
		return false
	if state.ambient_seen.has(id) and state.month - int(state.ambient_seen[id]) < JsonUtil.get_int(e, "cooldown_months"):
		return false
	var w := JsonUtil.get_dict(e, "when")
	if state.month < JsonUtil.get_int(w, "from_month", 1):
		return false
	var months := JsonUtil.get_array(w, "months_of_year")
	if not months.is_empty() and not months.has(float(state.month_of_year())) and not months.has(state.month_of_year()):
		return false
	var periods := JsonUtil.get_array(w, "periods")
	if not periods.is_empty() and not JsonUtil.get_str(state.periods()[state.period] as Dictionary, "id") in periods:
		return false
	var weather := JsonUtil.get_array(w, "weather")
	if not weather.is_empty() and not state.weather in weather:
		return false
	if w.get("tax_month") != null:
		var mpy := state.months_per_year()
		if (CityTax.due_month(state) - 1 + int(w["tax_month"])) % mpy + 1 != state.month_of_year():
			return false
	if w.get("tax_owed") != null and bool(w["tax_owed"]) != CityTax.owed(state, race_id):
		return false
	return CityResidence.when_ok(state, w)  # 거주 등급 residence_min·max(CT53)


static func _weight(state: CityState, e: Dictionary) -> float:
	return JsonUtil.get_float(e, "weight", 1.0) * JsonUtil.get_float(JsonUtil.get_dict(e, "weather_weight"), state.weather, 1.0) \
		* CityResidence.weight_mult(state, e)  # 거주 등급마다(residence_weight — 뒷골목엔 소매치기, 고지대엔 검문, CT53)


static func _pick(state: CityState, pool: Array) -> String:
	var total := 0.0
	for id: Variant in pool:
		total += _weight(state, entry(state, str(id)))
	var roll_v := state.rng.randf() * total
	for id: Variant in pool:
		roll_v -= _weight(state, entry(state, str(id)))
		if roll_v < 0.0:
			return str(id)
	return str(pool[-1])


## 이번 사건의 선택지(없으면 빈 배열 — 장면만 보고 결과가 바로 난다).
static func choices(state: CityState) -> Array:
	return JsonUtil.get_array(entry(state, state.ambient), "choices")


## 이 선택지를 고를 수 있는가(이용료만큼 돈이 있는가).
static func can_choose(pc: PlayerCharacter, choice: Dictionary) -> bool:
	return pc.inventory.money >= maxi(0, int(CityValues.num(choice, "cost_stones")))


## 사건을 끝낸다(choice = 선택지 번호, 선택지가 없으면 무시). 돌려줌 {outcome: 결과 이름, ctx: CityContext}.
static func resolve(state: CityState, pc: PlayerCharacter, choice: int, registry: ScriptRegistry) -> Dictionary:
	var e := entry(state, state.ambient)
	var ctx := CityContext.new(state, pc, "street:" + state.ambient)
	var list := JsonUtil.get_array(e, "choices")
	var outcome := RESULT
	if list.is_empty():
		outcome = _run(ctx, registry, e, RESULT)
	elif choice >= 0 and choice < list.size() and list[choice] is Dictionary and can_choose(pc, list[choice]):
		var c: Dictionary = list[choice]
		outcome = _run(ctx, registry, c, JsonUtil.get_str(c, "id"))
	state.changed.emit()
	return {"outcome": outcome, "ctx": ctx}


## 갈래 하나: 이용료 → effects → (판정이 있으면) success·fail. 결과 이름.
static func _run(ctx: CityContext, registry: ScriptRegistry, b: Dictionary, name: String) -> String:
	var cost := maxi(0, int(CityValues.num(b, "cost_stones")))
	if cost > 0:
		ctx.pc.inventory.add_money(-cost)
	_apply(ctx, registry, JsonUtil.get_array(b, "effects"))
	var chk := JsonUtil.get_dict(b, "check")
	if chk.is_empty():
		return name
	var ok := ctx.rng().chance(check_chance(ctx.pc, chk))
	_apply(ctx, registry, JsonUtil.get_array(b, "success" if ok else "fail"))
	return name + ("_ok" if ok else "_fail")


## 판정 확률 = clamp(base + (Σ스탯 − target) × per_point, min, max).
static func check_chance(pc: PlayerCharacter, chk: Dictionary) -> float:
	var sum := 0.0
	for s: Variant in JsonUtil.get_array(chk, "stats"):
		if pc.stats.has_stat(str(s)):
			sum += pc.stats.get_value(str(s))
	var p := CityValues.num(chk, "base") + (sum - CityValues.num(chk, "target")) * CityValues.num(chk, "per_point")
	return clampf(p, JsonUtil.get_float(chk, "min", 0.0), JsonUtil.get_float(chk, "max", 1.0))


static func _apply(ctx: CityContext, registry: ScriptRegistry, effects: Array) -> void:
	for fx: Variant in effects:
		if fx is Dictionary:
			var h := registry.instance(JsonUtil.get_str(fx, "type")) as CityEffect
			if h != null:
				h.apply(ctx, fx)


## 장면 문구 키(city.street.<id>.<part>.1, .2 …) — 있는 것 모두 차례로.
static func line_keys(id: String, part: String) -> PackedStringArray:
	var out := PackedStringArray()
	while Strings.has("city.street.%s.%s.%d" % [id, part, out.size() + 1]):
		out.append("city.street.%s.%s.%d" % [id, part, out.size() + 1])
	return out
