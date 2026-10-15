class_name CityState
extends RefCounted
## 도시(라비기온) 진행 상태: 순(旬) 달력 · 행동력 · 신전 공적치 · 은행 잔액 · 얻은 소문/정보 · 지금 들어가 있는 시설.
## 행동력은 시설에 들어갈 때만 쓴다(시설 안 활동은 행동력을 쓰지 않는다).
## 하순에 행동력을 다 쓰고 거리로 나오면 미궁으로 떠난다(expedition_due). 미궁에서 돌아오면 다음 달 상순(return_from_dungeon).
## 규칙 값은 data/city.json. 디버그 임시값(overrides)은 저장하지 않는다.
## 오토로드를 참조하지 않는다.

signal changed
signal period_started(month: int, period: int)
signal expedition_due  ## 하순이 끝났다 — 미궁으로 떠날 차례

var db: GameDatabase
var rng: Rng
## 시작부터 센 달(1부터). 연 = (month − 1) / months_per_year + 1.
var month: int = 1
## calendar.periods 인덱스(0 = 상순).
var period: int = 0
var ap: int = 0
var temple_merit: float = 0.0
var bank_balance: int = 0
## 얻은 소문·정보 id(얻은 순서). 내용은 data/city_info.
var known_info: Array[String] = []
## 지금 들어가 있는 시설 id(거리면 "").
var facility: String = ""
## 디버그 임시값(CityValues 경로 → 값). 저장하지 않고 데이터 파일도 바꾸지 않는다.
var overrides: Dictionary = {}


func _init(p_db: GameDatabase, seed_value: int = 0) -> void:
	db = p_db
	rng = Rng.new(seed_value)


## 새 게임: 시작 날짜(calendar.start)와 행동력.
func start() -> void:
	var st := JsonUtil.get_dict(calendar(), "start")
	month = maxi(1, JsonUtil.get_int(st, "month", 1))
	period = maxi(0, period_index(JsonUtil.get_str(st, "period")))
	ap = ap_per_period()
	facility = ""
	changed.emit()


func calendar() -> Dictionary:
	return CityValues.city_section(db, overrides, "calendar")


func periods() -> Array:
	return JsonUtil.get_array(calendar(), "periods")


func period_index(id: String) -> int:
	var list := periods()
	for i in list.size():
		if JsonUtil.get_str(list[i], "id") == id:
			return i
	return 0


func period_name(i: int = -1) -> String:
	var list := periods()
	var k := period if i < 0 else i
	return JsonUtil.get_str(list[k], "name_ko") if k >= 0 and k < list.size() else ""


func months_per_year() -> int:
	return maxi(1, JsonUtil.get_int(calendar(), "months_per_year", 12))


func year() -> int:
	return (month - 1) / months_per_year() + 1


func month_of_year() -> int:
	return (month - 1) % months_per_year() + 1


func ap_per_period() -> int:
	return maxi(0, JsonUtil.get_int(calendar(), "action_points_per_period", 0))


func entry_cost() -> int:
	var v: Variant = CityValues.city_value(db, overrides, "facility_entry_cost")
	return maxi(0, int(v)) if (v is int or v is float) else 0


## 다음 순으로: 상순 → 중순 → 하순 → 다음 달 상순. 행동력을 순당 값으로 채운다(남은 것은 이월하지 않는다).
func next_period() -> void:
	period += 1
	if period >= maxi(1, periods().size()):
		period = 0
		month += 1
	ap = ap_per_period()
	period_started.emit(month, period)
	changed.emit()


func can_spend(n: int) -> bool:
	return n <= ap


## 행동력을 쓴다. 모자라면 쓰지 않고 false. 0 아래로 내려가지 않는다.
func spend_ap(n: int) -> bool:
	if n < 0 or n > ap:
		return false
	ap -= n
	changed.emit()
	return true


## 거리 → 시설 내부. 행동력 facility_entry_cost를 쓴다(되돌릴 수 없다). 실패하면 이유 문자열 키.
func enter_facility(id: String) -> String:
	if not facility.is_empty():
		return "city.reason_inside"
	if not db.has_entry("facilities", id):
		return "city.reason_unknown"
	if not spend_ap(entry_cost()):
		return "city.reason_no_ap"
	facility = id
	changed.emit()
	return ""


## 시설 → 거리. 행동력을 다 썼으면 다음 순으로 넘어간다(넘어갔으면 true).
func leave_facility() -> bool:
	facility = ""
	changed.emit()
	return advance_if_spent()


## 거리에 있고 행동력이 0이면 다음 순으로. 하순이면 순을 넘기지 않고 expedition_due를 낸다.
func advance_if_spent() -> bool:
	if not facility.is_empty() or ap > 0:
		return false
	if is_last_period():
		expedition_due.emit()
	else:
		next_period()
	return true


func is_last_period() -> bool:
	return period >= periods().size() - 1


## 미궁에서 돌아왔다: 다음 달 상순, 행동력을 새로 채운다.
func return_from_dungeon() -> void:
	facility = ""
	period = 0
	month += 1
	ap = ap_per_period()
	period_started.emit(month, period)
	changed.emit()


## 거리 순서(facility_order, 없으면 각 시설의 order).
func facility_ids() -> Array[String]:
	var out: Array[String] = []
	for v: Variant in (db.singletons.get("city", {}) as Dictionary).get("facility_order", []):
		if db.has_entry("facilities", str(v)):
			out.append(str(v))
	if out.is_empty():
		for id: String in db.get_collection("facilities"):
			out.append(id)
		out.sort_custom(func(a: String, b: String) -> bool:
			return JsonUtil.get_int(db.get_entry("facilities", a), "order") < JsonUtil.get_int(db.get_entry("facilities", b), "order"))
	return out


## 활동 정의(디버그 임시값 반영 사본).
func activity(id: String) -> Dictionary:
	return CityValues.entry(db, overrides, "activities", id)


func set_override(path: String, value: Variant) -> void:
	if value == null:
		overrides.erase(path)
	else:
		overrides[path] = value
	changed.emit()


func learn_info(id: String) -> bool:
	if known_info.has(id) or not db.has_entry("city_info", id):
		return false
	known_info.append(id)
	return true


## 저장 대상(저장 기능이 생기면 쓴다): 날짜·행동력·공적치·잔액·얻은 소문/정보. 디버그 임시값은 넣지 않는다.
func to_dict() -> Dictionary:
	return {"month": month, "period": period, "ap": ap, "temple_merit": temple_merit,
		"bank_balance": bank_balance, "known_info": known_info.duplicate(), "rng": rng.get_state_string()}


func load_dict(d: Dictionary) -> void:
	month = maxi(1, JsonUtil.get_int(d, "month", 1))
	period = clampi(JsonUtil.get_int(d, "period"), 0, maxi(0, periods().size() - 1))
	ap = maxi(0, JsonUtil.get_int(d, "ap", ap_per_period()))
	temple_merit = JsonUtil.get_float(d, "temple_merit")
	bank_balance = maxi(0, JsonUtil.get_int(d, "bank_balance"))
	known_info.clear()
	for v: Variant in JsonUtil.get_array(d, "known_info"):
		known_info.append(str(v))
	if d.has("rng"):
		rng.set_state_string(JsonUtil.get_str(d, "rng"))
	facility = ""
	changed.emit()
