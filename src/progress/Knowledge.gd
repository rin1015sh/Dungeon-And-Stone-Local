class_name Knowledge
extends RefCounted
## 정보의 가치(캐릭터 단위 기록): 몬스터 정보는 처음엔 `???`이고 겪은 만큼 공개된다.
##   seen      전투에서 마주쳤다 → 이름·등급·계열·설명
##   stats     '조사'했다 → 생명력 최대치·핵심 스탯
##   affinity  그 피해 유형으로 직접 쳐 봤다 → 약점(배율 > 1)·면역(0)·저항(< 1)
##   status    그 상태이상을 걸어 봤는데 듣지 않았다(st_immune) · 그 몬스터가 아군에게 그 상태를 걸었다(st_inflicts)
## (길드 정보 구매 = M4에서 learn_all을 부른다.)
## 사실(fact): 몬스터 밖의 알게 된 것(강철의 묘 벽화 힌트 "riddle:<문항>:<번호>"). 저장 dict의 "_facts".
## 조사 수(survey): 전투에서 '조사'를 쓴 몬스터 수(종별 — 한 마리에 한 번). 길드 조사 의뢰에 넘기면 지워진다(CityGuild). "_surveys".

const FACTS_KEY := "_facts"
const SURVEYS_KEY := "_surveys"

var _m: Dictionary = {}  # 몬스터 id -> {"seen", "stats": bool, "aff": {피해 유형: 배율}, "st_immune"·"st_inflicts": {상태 id: true}}
var _facts: Dictionary = {}
var _surveys: Dictionary = {}  # 몬스터 id -> 조사한 마리 수


## 사실을 알게 됐다. 새로 알았으면 true.
func learn_fact(key: String) -> bool:
	if _facts.has(key):
		return false
	_facts[key] = true
	return true


func knows_fact(key: String) -> bool:
	return _facts.has(key)


func note_survey(id: String) -> void:
	_surveys[id] = int(_surveys.get(id, 0)) + 1


func surveys(id: String) -> int:
	return int(_surveys.get(id, 0))


func clear_surveys() -> void:
	_surveys.clear()


func see(id: String) -> bool:
	var e := _entry(id)
	var first := not bool(e["seen"])
	e["seen"] = true
	return first


func learn_stats(id: String) -> bool:
	var e := _entry(id)
	var first := not bool(e["stats"])
	e["seen"] = true
	e["stats"] = true
	return first


func learn_affinity(id: String, damage_type: String, mult: float) -> bool:
	var aff: Dictionary = _entry(id)["aff"]
	var first := not aff.has(damage_type)
	aff[damage_type] = mult
	return first


## 상태이상을 알게 됐다. kind = "st_immune"(듣지 않는다) | "st_inflicts"(거는 상태). 새로 알았으면 true.
func learn_status(id: String, kind: String, status_id: String) -> bool:
	var into: Dictionary = _entry(id)[kind]
	var first := not into.has(status_id)
	into[status_id] = true
	return first


## 알아낸 상태이상 id 목록(kind는 learn_status와 같다).
func statuses(id: String, kind: String) -> Array[String]:
	var out: Array[String] = []
	if _m.has(id):
		for s: String in _m[id][kind]:
			out.append(s)
	return out


## 몬스터 데이터의 상성·상태이상 면역을 모두 안다(정보 구매).
func learn_all(db: GameDatabase, id: String) -> void:
	learn_stats(id)
	var def := db.get_entry("monsters", id)
	var w := JsonUtil.get_dict(def, "weaknesses")
	for t: String in w:
		learn_affinity(id, t, float(w[t]))
	for t: Variant in JsonUtil.get_array(def, "immunities"):
		learn_affinity(id, str(t), 0.0)
	for st: Variant in JsonUtil.get_array(def, "status_immune"):
		learn_status(id, "st_immune", str(st))


func has_seen(id: String) -> bool:
	return _m.has(id) and bool(_m[id]["seen"])


func knows_stats(id: String) -> bool:
	return _m.has(id) and bool(_m[id]["stats"])


## 알아낸 상성 {피해 유형: 배율}.
func affinities(id: String) -> Dictionary:
	return (_m[id]["aff"] as Dictionary).duplicate() if _m.has(id) else {}


func seen_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in _m:
		if bool(_m[id]["seen"]):
			out.append(id)
	return out


func to_dict() -> Dictionary:
	var out := _m.duplicate(true)
	out[FACTS_KEY] = _facts.duplicate()
	out[SURVEYS_KEY] = _surveys.duplicate()
	return out


func load_dict(d: Dictionary) -> void:
	_m.clear()
	_facts = JsonUtil.get_dict(d, FACTS_KEY).duplicate()
	_surveys = JsonUtil.get_dict(d, SURVEYS_KEY).duplicate()
	for id: String in d:
		if id == FACTS_KEY or id == SURVEYS_KEY:
			continue
		var e: Dictionary = d[id] if d[id] is Dictionary else {}
		_m[id] = {"seen": JsonUtil.get_bool(e, "seen"), "stats": JsonUtil.get_bool(e, "stats"),
			"aff": JsonUtil.get_dict(e, "aff").duplicate(),
			"st_immune": JsonUtil.get_dict(e, "st_immune").duplicate(), "st_inflicts": JsonUtil.get_dict(e, "st_inflicts").duplicate()}


func _entry(id: String) -> Dictionary:
	if not _m.has(id):
		_m[id] = {"seen": false, "stats": false, "aff": {}, "st_immune": {}, "st_inflicts": {}}
	return _m[id]
