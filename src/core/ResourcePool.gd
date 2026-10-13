class_name ResourcePool
extends RefCounted
## 한 개체의 자원 게이지 묶음(생명력·영혼력·허기 …). 컴포넌트로 Actor에 붙는다.
## - 최대치 = 수식(ResourceDef.max_value 또는 overrides) → 수정자 "max:<id>" 적용.
## - 스탯이 바뀌면(StatBlock.changed) 최대치를 다시 계산한다. 현재값은 유지(넘치면 클램프).
## - 임계값·고갈·회복은 시그널로만 알린다. 상태이상 부여/사망 처리는 소유자(Actor)의 몫.
## - 코스트는 어떤 자원이든 {"soul": 5, "hp": 10} 형태로 지불한다.

signal changed(res_id: String, current: float, maximum: float)
signal threshold_crossed(res_id: String, threshold: Dictionary, entered: bool)
signal depleted(res_id: String)
signal recovered(res_id: String)
signal context_changed(key: String, active: bool)

const EPSILON := 0.000001

var _db: GameDatabase
var _stats: StatBlock
var _level: int = 1
var _ids: Array[String] = []
var _overrides: Dictionary = {}   # id -> 숫자|수식 (몬스터 고정 최대치 등)
var _current: Dictionary = {}
var _max: Dictionary = {}
var _depleted: Dictionary = {}
var _last_source: Dictionary = {} # id -> 마지막으로 값을 바꾼 출처(사인 판정용)
var _mins: Dictionary = {}        # id -> 하한(디버그 무적 등). 기본 0
var _context: Dictionary = {}     # "dungeon" / "combat" -> bool
var _clipped: Dictionary = {}     # id -> 최대치가 줄어 잘린 현재값(최대치가 다시 늘면 그만큼 돌려준다)


## ids가 비면 활성화된(enabled) 모든 자원을 가진다.
func _init(db: GameDatabase, stats: StatBlock, ids: Array = [], overrides: Dictionary = {}, level: int = 1) -> void:
	_db = db
	_stats = stats
	_overrides = overrides
	_level = level
	var wanted: Array = ids
	if wanted.is_empty():
		wanted = db.enabled_resource_ids()
	for v: Variant in wanted:
		var rid := str(v)
		if db.resources.has(rid):
			_ids.append(rid)
		else:
			push_error("ResourcePool: 알 수 없는 자원 '%s'" % rid)
	for rid in _ids:
		_max[rid] = _calc_max(rid)
		_current[rid] = _start_value(rid)
		_depleted[rid] = float(_current[rid]) <= 0.0
	_stats.changed.connect(recompute_max)


func ids() -> Array[String]:
	return _ids.duplicate()


func has_resource(id: String) -> bool:
	return _current.has(id)


func get_def(id: String) -> ResourceDef:
	return _db.resources.get(id)


func get_current(id: String) -> float:
	return _current.get(id, 0.0)


func get_max(id: String) -> float:
	return _max.get(id, 0.0)


func get_ratio(id: String) -> float:
	var m := get_max(id)
	return get_current(id) / m if m > 0.0 else 0.0


func is_depleted(id: String) -> bool:
	return _depleted.get(id, false)


## 마지막으로 이 자원을 바꾼 출처(예: "status:starvation"). 사망 원인 표시에 쓴다.
func get_last_source(id: String) -> String:
	return _last_source.get(id, "")


## 현재값 하한. 디버그 무적은 생명력 하한을 1로 둔다.
func set_min_value(id: String, value: float) -> void:
	if value <= 0.0:
		_mins.erase(id)
	else:
		_mins[id] = value


func get_level() -> int:
	return _level


func set_level(level: int) -> void:
	_level = level
	recompute_max()


## 범위(scope) 판정용 문맥. key: "dungeon" / "combat".
func set_context(key: String, active: bool) -> void:
	if bool(_context.get(key, false)) == active:
		return
	_context[key] = active
	context_changed.emit(key, active)


func is_active(id: String) -> bool:
	var def := get_def(id)
	if def == null:
		return false
	match def.scope:
		"dungeon_only":
			return bool(_context.get("dungeon", false))
		"combat_only":
			return bool(_context.get("combat", false))
	return true


## delta만큼 더하고 실제 변화량을 돌려준다. source는 기록/로그용.
func modify(id: String, delta: float, source: String = "") -> float:
	if not _current.has(id):
		push_error("ResourcePool.modify: 없는 자원 '%s'" % id)
		return 0.0
	return _apply(id, float(_current[id]) + delta, source)


func set_current(id: String, value: float, source: String = "") -> float:
	if not _current.has(id):
		push_error("ResourcePool.set_current: 없는 자원 '%s'" % id)
		return 0.0
	return _apply(id, value, source)


func fill(id: String) -> void:
	set_current(id, get_max(id), "fill")


func fill_all() -> void:
	for id in _ids: fill(id)


func can_afford(costs: Dictionary) -> bool:
	for id: String in costs:
		if not _current.has(id):
			return false
		var cost := float(costs[id])
		var cur: float = _current[id]
		if cur + EPSILON < cost:
			return false
		if get_def(id).cost_strict and cost > 0.0 and cur - cost <= EPSILON:
			return false
	return true


## 모두 낼 수 있을 때만 한꺼번에 지불한다(원자적).
func spend(costs: Dictionary, source: String = "") -> bool:
	if not can_afford(costs):
		return false
	for id: String in costs:
		modify(id, -float(costs[id]), source)
	return true


## trigger(turn/time/rest) 기준으로 amount 단위만큼 재생/감소. 비활성 범위 자원은 멈춘다.
func tick(trigger: String, amount: float = 1.0) -> void:
	for id in _ids:
		if not is_active(id):
			continue
		var per_unit := regen_per_unit(id, trigger)
		if per_unit != 0.0:
			modify(id, per_unit * amount, "regen:" + trigger)


## 단위(1턴/1시간/휴식 1시간)당 변화량. 수정자 "regen:<id>" 적용 후.
func regen_per_unit(id: String, trigger: String) -> float:
	var def := get_def(id)
	var total := 0.0
	var any := false
	for rule: Dictionary in def.regen:
		if JsonUtil.get_str(rule, "trigger") != trigger:
			continue
		any = true
		var rate := Formula.value(rule.get("rate", 0.0), resolve)
		if JsonUtil.get_str(rule, "basis", "flat") == "max_ratio":
			rate *= get_max(id)
		total += rate
	if not any:
		return 0.0
	# 수정자 "regen:<id>": percent는 모든 기준에, flat은 휴식(rest)이 아닌 기준에만 더한다(휴식은 시간 경과와 함께 흐르므로 두 번 들지 않게).
	# "regen:<id>:<trigger>"는 그 기준에만.
	var flat := 0.0
	var pct := 0.0
	for mod: Modifier in _stats.get_modifiers("regen:" + id):
		pct += mod.percent
		if trigger != "rest":
			flat += mod.flat
	for mod: Modifier in _stats.get_modifiers("regen:%s:%s" % [id, trigger]):
		pct += mod.percent
		flat += mod.flat
	return (total + flat) * maxf(0.0, 1.0 + pct)


## 현재 들어가 있는 임계 구간 목록(불러오기 후 상태 동기화용).
func active_thresholds(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var r := get_ratio(id)
	for t: Dictionary in get_def(id).thresholds:
		if _in_zone(t, r):
			out.append(t)
	return out


func recompute_max() -> void:
	for id in _ids:
		var new_max := _calc_max(id)
		var old_max: float = _max[id]
		if absf(new_max - old_max) < EPSILON:
			continue
		var old_ratio := get_ratio(id)
		_max[id] = new_max
		var cur := float(_current[id])
		var clipped := float(_clipped.get(id, 0.0))
		if cur > new_max:
			clipped += cur - new_max
			cur = new_max
		elif new_max > old_max and clipped > 0.0:
			var back := minf(clipped, new_max - old_max)  # 일시 약화가 풀리면 잘렸던 만큼 돌아온다(R11)
			cur = minf(new_max, cur + back)
			clipped -= back
		_clipped[id] = clipped
		_current[id] = cur
		changed.emit(id, cur, new_max)
		_check_thresholds(id, old_ratio, get_ratio(id))
		_check_zero(id)


## 소유자가 시그널을 이은 뒤 부른다: 처음부터 임계 구간·고갈인 자원의 상태를 알린다.
func sync_initial() -> void:
	for id in _ids:
		var r := get_ratio(id)
		for t: Dictionary in get_def(id).thresholds:
			if _in_zone(t, r):
				threshold_crossed.emit(id, t, true)
		if float(_current[id]) <= 0.0 and get_max(id) > 0.0:
			depleted.emit(id)


## 저장용: 레벨·현재값·문맥만. 최대치는 불러올 때 수식으로 다시 계산한다.
func to_dict() -> Dictionary:
	return {"level": _level, "current": _current.duplicate(), "context": _context.duplicate()}


func load_dict(d: Dictionary) -> void:
	_level = JsonUtil.get_int(d, "level", _level)
	_context = JsonUtil.get_dict(d, "context").duplicate()
	var cur := JsonUtil.get_dict(d, "current")
	_clipped.clear()
	for id in _ids:
		_max[id] = _calc_max(id)
		_current[id] = clampf(JsonUtil.get_float(cur, id, _max[id]), 0.0, _max[id])
		_depleted[id] = float(_current[id]) <= 0.0
		changed.emit(id, _current[id], _max[id])


func _apply(id: String, value: float, source: String) -> float:
	var maximum: float = _max[id]
	var nv := clampf(value, minf(float(_mins.get(id, 0.0)), maximum), maximum)
	if nv < EPSILON:
		nv = 0.0
	var old: float = _current[id]
	if nv == old:
		return 0.0
	var old_ratio := get_ratio(id)
	_current[id] = nv
	_last_source[id] = source
	changed.emit(id, nv, maximum)
	_check_thresholds(id, old_ratio, get_ratio(id))
	_check_zero(id)
	return nv - old


func _check_thresholds(id: String, old_ratio: float, new_ratio: float) -> void:
	for t: Dictionary in get_def(id).thresholds:
		var was_in := _in_zone(t, old_ratio)
		var now_in := _in_zone(t, new_ratio)
		if was_in != now_in:
			threshold_crossed.emit(id, t, now_in)


func _in_zone(t: Dictionary, ratio: float) -> bool:
	var at := JsonUtil.get_float(t, "at_ratio")
	if JsonUtil.get_str(t, "direction", "down") == "up":
		return ratio >= at
	return ratio <= at


func _check_zero(id: String) -> void:
	var cur: float = _current[id]
	if cur <= 0.0:
		if not _depleted[id]:
			_depleted[id] = true
			depleted.emit(id)
	elif _depleted[id] and get_ratio(id) >= get_def(id).recover_at_ratio:
		_depleted[id] = false
		recovered.emit(id)


func _calc_max(id: String) -> float:
	var src: Variant = _overrides.get(id, get_def(id).max_value)
	var base := Formula.value(src, resolve)
	return maxf(0.0, _stats.apply_modifiers("max:" + id, base))


func _start_value(id: String) -> float:
	var s: Variant = get_def(id).start
	if s is float or s is int:
		return clampf(float(s), 0.0, 1.0) * get_max(id)
	if str(s) == "empty":
		return 0.0
	return get_max(id)


## 수식 키 해석: level / bal.<경로> / 스탯 id. (상태이상·효과 수식도 이것을 쓴다)
func resolve(key: String) -> float:
	if key == "level":
		return float(_level)
	if key.begins_with("bal."):
		return float(_db.bal(key.substr(4), 0.0))
	if key.begins_with("max_") and has_resource(key.substr(4)):
		return get_max(key.substr(4))
	return _stats.get_value(key)
