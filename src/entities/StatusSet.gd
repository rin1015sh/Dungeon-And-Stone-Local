class_name StatusSet
extends RefCounted
## 상태이상 묶음(data/statuses.json). 컴포넌트로 Actor에 붙는다.
## - 부여하면 정의의 modifiers를 출처 "status:<id>"로 StatBlock에 붙이고, 해제하면 뗀다.
## - periodic: 턴/시간마다 자원을 바꾼다(출혈·아사 …). 수식은 ResourcePool.resolve로 푼다.
## - duration {amount, unit: turn|hour}: 다 되면 해제. 없으면 영구(조건이 풀릴 때 소유자가 해제).
## - stackable: 다시 걸리면 중첩(수정자·주기 효과가 중첩 수만큼).
## - flags: no_skills, skip_turn, untargetable(은신), no_flee(속박) … (전투가 읽는다)
## - 지속시간은 자기 차례가 시작될 때 준다. 자기 행동에 영향을 주는 상태(실명·버프)는 '효과를 볼 차례 수 + 1'로 준다.

signal applied(status_id: String)
signal removed(status_id: String)

const SOURCE_PREFIX := "status:"
const DEFAULT_MAX_STACKS := 99

var _db: GameDatabase
var _stats: StatBlock
var _pool: ResourcePool
var _active: Dictionary = {}  # id -> {"stacks": int, "remaining": float(음수 = 영구), "unit": String}


func _init(db: GameDatabase, stats: StatBlock, pool: ResourcePool) -> void:
	_db = db
	_stats = stats
	_pool = pool


## duration < 0이면 정의의 지속시간을 쓴다. 성공하면 true.
func apply(id: String, duration: float = -1.0, unit: String = "") -> bool:
	var def := _db.get_entry("statuses", id)
	if def.is_empty():
		push_error("StatusSet: 알 수 없는 상태이상 '%s'" % id)
		return false
	var dur_def := JsonUtil.get_dict(def, "duration")
	var dur := duration if duration >= 0.0 else JsonUtil.get_float(dur_def, "amount", -1.0)
	var dur_unit := unit if not unit.is_empty() else JsonUtil.get_str(dur_def, "unit", "turn")
	if _active.has(id):
		var st: Dictionary = _active[id]
		var max_stacks := JsonUtil.get_int(def, "max_stacks", DEFAULT_MAX_STACKS)
		if JsonUtil.get_bool(def, "stackable") and int(st["stacks"]) < max_stacks:
			st["stacks"] = int(st["stacks"]) + 1
			_stats.add_modifiers_from_data(SOURCE_PREFIX + id, JsonUtil.get_array(def, "modifiers"))
		var rem: float = st["remaining"]
		if rem >= 0.0:
			st["remaining"] = -1.0 if dur < 0.0 else maxf(rem, dur)
		return true
	_active[id] = {"stacks": 1, "remaining": dur, "unit": dur_unit}
	_stats.add_modifiers_from_data(SOURCE_PREFIX + id, JsonUtil.get_array(def, "modifiers"))
	applied.emit(id)
	return true


func remove(id: String) -> bool:
	if not _active.has(id):
		return false
	_active.erase(id)
	_stats.remove_source(SOURCE_PREFIX + id)
	removed.emit(id)
	return true


func has(id: String) -> bool:
	return _active.has(id)


func stacks(id: String) -> int:
	return int((_active.get(id, {}) as Dictionary).get("stacks", 0))


func ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in _active:
		out.append(id)
	return out


func has_flag(flag: String) -> bool:
	for id: String in _active:
		if JsonUtil.get_array(_db.get_entry("statuses", id), "flags").has(flag):
			return true
	return false


## 반격 태세: 걸린 상태 정의의 "counter": {"power": 0.7} 중 가장 큰 위력(없으면 0).
func counter_power() -> float:
	var best := 0.0
	for id: String in _active:
		best = maxf(best, JsonUtil.get_float(JsonUtil.get_dict(_db.get_entry("statuses", id), "counter"), "power"))
	return best


func tick_turns(n: float = 1.0) -> void:
	_periodic("turn", n)
	_countdown("turn", n)


func tick_hours(hours: float) -> void:
	_periodic("time", hours)
	_countdown("hour", hours)


func to_dict() -> Dictionary:
	return _active.duplicate(true)


## 수정자는 StatBlock 저장분에 이미 들어 있으므로 여기서는 상태만 되살린다.
func load_dict(d: Dictionary) -> void:
	_active.clear()
	for id: String in d:
		if d[id] is Dictionary and _db.has_entry("statuses", id):
			_active[id] = (d[id] as Dictionary).duplicate()


func _periodic(trigger: String, amount: float) -> void:
	for id: String in _active.keys():
		if not _active.has(id):
			continue
		var n := stacks(id)
		for p: Variant in JsonUtil.get_array(_db.get_entry("statuses", id), "periodic"):
			var pd: Dictionary = p if p is Dictionary else {}
			if JsonUtil.get_str(pd, "trigger") != trigger:
				continue
			var res := JsonUtil.get_str(pd, "resource")
			if _pool.has_resource(res):
				var per := Formula.value(pd.get("amount", 0.0), _pool.resolve)
				_pool.modify(res, per * n * amount, SOURCE_PREFIX + id)


func _countdown(unit: String, amount: float) -> void:
	var expired: Array[String] = []
	for id: String in _active:
		var st: Dictionary = _active[id]
		var rem: float = st["remaining"]
		if rem < 0.0 or str(st["unit"]) != unit:
			continue
		st["remaining"] = rem - amount
		if float(st["remaining"]) <= 0.000001:
			expired.append(id)
	for id in expired:
		remove(id)
