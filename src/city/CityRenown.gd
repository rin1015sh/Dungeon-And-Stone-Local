class_name CityRenown
extends RefCounted
## 명성(사용자 결정 2026-10-20, CT36): 귀환하면 원정에서 한 일(deeds)로 점수를 더하고, 도시가 그 일을 안다.
##   city.json renown.deeds = [{id, notice(탐험 알림 키) | kill(true), points, min_count}] · stages = 단계가 시작되는 점수.
##   deeds 기록 = {"kill": 쓰러뜨린 수, "<알림 키>": 뜬 횟수} (GameState.deeds — 탐험 화면이 센다).
## 귀환 장면(city.return.<deed id>.<번호>, 단계가 오르면 city.return.stage_up.<단계>)을 state.pending_lines에 남긴다 — 도시 화면이 연다.
## 단계는 오늘의 거리 조건(when.min_renown)·인연 단계(stages[].min_renown)가 쓴다. 오토로드를 참조하지 않는다.


static func config(state: CityState) -> Dictionary:
	return CityValues.city_section(state.db, state.overrides, "renown")


## 지금 명성 단계(0부터).
static func stage(state: CityState) -> int:
	return stage_of(state, state.renown)


static func stage_of(state: CityState, points: int) -> int:
	var st := 0
	var stages := JsonUtil.get_array(config(state), "stages")
	for i in stages.size():
		if stages[i] != null and points >= int(stages[i]):
			st = i
	return st


## 한 deed 정의가 이번 원정에서 몇 번 있었나.
static func count_of(deed: Dictionary, deeds: Dictionary) -> int:
	if JsonUtil.get_bool(deed, "kill"):
		return int(deeds.get("kill", 0))
	var key := JsonUtil.get_str(deed, "notice")
	return int(deeds.get(key, 0)) if not key.is_empty() else 0


## 귀환 결산: 점수를 더하고 귀환 장면을 남긴다. 더한 점수를 돌려준다.
static func settle(state: CityState, deeds: Dictionary) -> int:
	var before := stage(state)
	var gained := 0
	var line_id := ""
	for v: Variant in JsonUtil.get_array(config(state), "deeds"):
		var d := v as Dictionary
		if d == null:
			continue
		var n := count_of(d, deeds)
		if n <= 0 or n < JsonUtil.get_int(d, "min_count", 1):
			continue
		gained += n * JsonUtil.get_int(d, "points")
		if line_id.is_empty():
			line_id = JsonUtil.get_str(d, "id")
	state.renown += maxi(0, gained)
	if not line_id.is_empty():
		_line(state, "city.return." + line_id)
	var after := stage(state)
	if after > before:
		_line(state, "city.return.stage_up.%d" % after)
	return gained


## 번호 붙은 문구 중 하나(city.return.<id>.<1..n>)를 날짜로 고른다(판정 난수를 쓰지 않는다).
static func _line(state: CityState, base: String) -> void:
	var n := 0
	while Strings.has("%s.%d" % [base, n + 1]):
		n += 1
	if n > 0:
		state.pending_lines.append("%s.%d" % [base, absi(hash([base, state.month, state.renown])) % n + 1])
	elif Strings.has(base):
		state.pending_lines.append(base)
