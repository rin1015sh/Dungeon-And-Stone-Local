class_name Fatigue
extends RefCounted
## 피로도: 핵심 스탯 5종이 아닌 별도 수치(플레이어 상태). 도시·미궁 공용이며 미궁에 들어가고 나와도 그대로 이어진다.
## 규칙 값은 data/city.json fatigue — start(null → 0), min·max(null → 제한 없음),
## dungeon{per_hour, per_rest_hour, per_combat_turn, per_step}(미궁 연결 지점, null → 변화 없음), effects(미정).
## 오토로드를 참조하지 않는다.

signal changed(value: float, delta: float, source: String)

## 미궁 연결 지점 이름(ExploreSession이 부른다) — data city.fatigue.dungeon의 키.
const DUNGEON_HOUR := "per_hour"
const DUNGEON_REST_HOUR := "per_rest_hour"
const DUNGEON_COMBAT_TURN := "per_combat_turn"
const DUNGEON_STEP := "per_step"

var value: float = 0.0
## city.json fatigue(디버그 임시값이 반영된 사본). min·max·dungeon을 여기서 읽는다.
var rules: Dictionary = {}


func setup(p_rules: Dictionary, reset_value: bool = true) -> void:
	rules = p_rules.duplicate(true)
	if reset_value:
		value = JsonUtil.get_float(rules, "start", 0.0)
	value = clamp_value(value)


## min·max가 null이면 그쪽은 제한하지 않는다.
func clamp_value(v: float) -> float:
	var lo: Variant = rules.get("min")
	var hi: Variant = rules.get("max")
	if lo is float or lo is int:
		v = maxf(v, float(lo))
	if hi is float or hi is int:
		v = minf(v, float(hi))
	return v


## 피로도를 바꾼다. 실제로 바뀐 양을 돌려준다.
func add(delta: float, source: String = "") -> float:
	var before := value
	value = clamp_value(value + delta)
	var d := value - before
	if not is_zero_approx(d):
		changed.emit(value, d, source)
	return d


func set_value(v: float, source: String = "debug") -> void:
	add(v - value, source)


## 미궁 쪽 연결 지점: 시간 소모 처리(이동·전투·휴식·시간 경과)가 단위 수(amount)와 함께 부른다.
## 규칙(dungeon.<key>)이 null이면 아무것도 하지 않는다 — 미궁에서 피로도가 변하는 규칙은 미정.
func on_dungeon(key: String, amount: float) -> float:
	var rate: Variant = JsonUtil.get_dict(rules, "dungeon").get(key)
	if not (rate is float or rate is int) or is_zero_approx(amount):
		return 0.0
	return add(float(rate) * amount, "dungeon:" + key)


## 피로도에 따른 효과(도시·미궁이 함께 쓰는 한 곳). 효과 내용은 미정이라 비어 있다 — 정해지면 rules.effects를 해석해 여기서 돌려준다.
## 반환 형식(예정): [{"stat": id, "flat": n} …] 같은 수정자 목록.
func effects() -> Array[Dictionary]:
	return []


func to_dict() -> Dictionary:
	return {"value": value}


func load_dict(d: Dictionary) -> void:
	value = clamp_value(JsonUtil.get_float(d, "value", value))
