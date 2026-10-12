class_name StatusSet
extends RefCounted
## 상태이상 묶음(data/statuses.json). 컴포넌트로 Actor에 붙는다.
## - 부여하면 정의의 modifiers를 출처 "status:<id>"로 StatBlock에 붙이고, 해제하면 뗀다.
## - periodic: 턴/시간마다 자원을 바꾼다(출혈·아사 …). 수식은 ResourcePool.resolve로 푼다.
## - duration {amount, unit: turn|hour}: 다 되면 해제. 없으면 영구(조건이 풀릴 때 소유자가 해제).
## - stackable: 다시 걸리면 중첩(수정자·주기 효과가 중첩 수만큼).
## - flags: no_skills, skip_turn, untargetable(은신), no_flee(속박) … (전투가 읽는다)
## - modifiers의 flat/percent가 문자열이면 걸릴 때 소유자 스탯으로 푼 수식(저체온증 "-max(0, 30 - {resist_cold})").
## - immune_if {stat, at_least}: 그 스탯이 넘으면 걸리지 않는다(진압). on_max_stacks {status}: 최대 중첩이 되면 그 상태로 바뀐다(서리 → 빙결).
## - break_on_damage / break_on_damage_types: 피해를 받으면(그 유형이면) 풀린다(진압, 빙결 ← 화염). heal_mult: 받는 치유 배율(원한).
## - grants_immunity [상태 id]: 이 상태가 걸린 동안 그 상태들에 걸리지 않는다(키르뒤 광분 → 공포·기절).
## - barrier: true — 보호막 상태. 양은 set_barrier로 정하고, 받는 피해를 먼저 흡수한다(absorb). 다 닳으면 풀린다(강철빙벽).
## - 지속시간은 자기 차례가 시작될 때 준다. 자기 행동에 영향을 주는 상태(실명·버프)는 '효과를 볼 차례 수 + 1'로 준다.

signal applied(status_id: String)
signal removed(status_id: String)

const SOURCE_PREFIX := "status:"
const DEFAULT_MAX_STACKS := 99

var _db: GameDatabase
var _stats: StatBlock
var _pool: ResourcePool
var _active: Dictionary = {}
## 지속 피해(주기 효과로 생명력이 줄어드는 것) 배율 — 소유자 패시브 dot_mult(본 나이트 방부제)의 곱. Actor가 맞춘다.
var dot_mult: float = 1.0  # id -> {"stacks": int, "remaining": float(음수 = 영구), "unit": String}


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
	if immune(id):
		return false
	var dur_def := JsonUtil.get_dict(def, "duration")
	var dur := duration if duration >= 0.0 else JsonUtil.get_float(dur_def, "amount", -1.0)
	var dur_unit := unit if not unit.is_empty() else JsonUtil.get_str(dur_def, "unit", "turn")
	if _active.has(id):
		var st: Dictionary = _active[id]
		var max_stacks := JsonUtil.get_int(def, "max_stacks", DEFAULT_MAX_STACKS)
		if JsonUtil.get_bool(def, "stackable") and int(st["stacks"]) < max_stacks:
			st["stacks"] = int(st["stacks"]) + 1
			_stats.add_modifiers_from_data(SOURCE_PREFIX + id, _mods(def))
			var conv := JsonUtil.get_str(JsonUtil.get_dict(def, "on_max_stacks"), "status")
			if int(st["stacks"]) >= max_stacks and not conv.is_empty():
				remove(id)
				return apply(conv)
		var rem: float = st["remaining"]
		if rem >= 0.0:
			st["remaining"] = -1.0 if dur < 0.0 else maxf(rem, dur)
		return true
	_active[id] = {"stacks": 1, "remaining": dur, "unit": dur_unit}
	_stats.add_modifiers_from_data(SOURCE_PREFIX + id, _mods(def))
	applied.emit(id)
	return true


func remove(id: String) -> bool:
	if not _active.has(id):
		return false
	_active.erase(id)
	_stats.remove_source(SOURCE_PREFIX + id)
	removed.emit(id)
	return true


## 스탯 문턱(immune_if)이나 걸린 상태의 grants_immunity 때문에 걸리지 않는가.
func immune(id: String) -> bool:
	for a: String in _active:
		if JsonUtil.get_array(_db.get_entry("statuses", a), "grants_immunity").has(id):
			return true
	var im := JsonUtil.get_dict(_db.get_entry("statuses", id), "immune_if")
	return not im.is_empty() and _stats.get_value(JsonUtil.get_str(im, "stat")) >= JsonUtil.get_float(im, "at_least")


## 보호막 양을 정한다(걸려 있을 때만). 이미 있으면 큰 쪽.
func set_barrier(id: String, amount: float) -> void:
	if _active.has(id):
		var st: Dictionary = _active[id]
		st["barrier"] = maxf(float(st.get("barrier", 0.0)), amount)


func barrier_total() -> float:
	var v := 0.0
	for id: String in _active:
		v += float((_active[id] as Dictionary).get("barrier", 0.0))
	return v


## 피해를 보호막으로 먼저 받는다. 남은 피해를 돌려준다(다 닳은 보호막 상태는 풀린다).
func absorb(amount: int) -> int:
	var left := amount
	for id: String in _active.keys():
		var st: Dictionary = _active[id]
		var b := float(st.get("barrier", 0.0))
		if left <= 0 or b <= 0.0:
			continue
		var used := mini(left, int(ceil(b)))
		left -= used
		st["barrier"] = b - used
		if float(st["barrier"]) <= 0.0:
			remove(id)
	return left


## 약화 상태(kind debuff) 중 하나를 고른다(필드 효과·전투 한정 표식은 뺀다). 없으면 "".
func pick_debuff(rng: Rng) -> String:
	var pool: Array[String] = []
	for id: String in _active:
		var def := _db.get_entry("statuses", id)
		if JsonUtil.get_str(def, "kind") == "debuff" and not JsonUtil.get_bool(def, "field_effect") and not def.has("persist"):
			pool.append(id)
	return "" if pool.is_empty() else str(rng.pick(pool))


## 남이 건 그 상태를 버틸 확률: 정의 resist {stats}의 합 × status.resist_per_point, 최대 status.resist_max.
func resist_chance(id: String) -> float:
	var total := 0.0
	for st: Variant in JsonUtil.get_array(JsonUtil.get_dict(_db.get_entry("statuses", id), "resist"), "stats"):
		total += _stats.get_value(str(st))
	return clampf(total * float(_db.bal("status.resist_per_point", 0.01)), 0.0, float(_db.bal("status.resist_max", 0.6)))


## 피해를 받았다: break_on_damage(유형 무관)·break_on_damage_types(그 유형)인 상태를 푼다. 푼 id 목록.
func on_damaged(damage_type: String) -> Array[String]:
	var out: Array[String] = []
	for id in ids():
		var def := _db.get_entry("statuses", id)
		if JsonUtil.get_bool(def, "break_on_damage") or JsonUtil.get_array(def, "break_on_damage_types").has(damage_type):
			remove(id)
			out.append(id)
	return out


## 걸린 상태 정의의 숫자 키 합(중첩 수만큼) — 예: lifesteal.
func sum_key(key: String) -> float:
	var v := 0.0
	for id: String in _active:
		v += JsonUtil.get_float(_db.get_entry("statuses", id), key) * stacks(id)
	return v


## 받는 치유 배율(걸린 상태들의 heal_mult 곱).
func heal_mult() -> float:
	var m := 1.0
	for id: String in _active:
		m *= JsonUtil.get_float(_db.get_entry("statuses", id), "heal_mult", 1.0)
	return m


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


## 수정자 목록 — 문자열 값은 지금 스탯으로 푼다.
func _mods(def: Dictionary) -> Array:
	var out: Array = []
	for m: Variant in JsonUtil.get_array(def, "modifiers"):
		if not m is Dictionary:
			continue
		var md: Dictionary = (m as Dictionary).duplicate()
		for k in ["flat", "percent"]:
			if md.get(k) is String:
				md[k] = Formula.value(md[k], _pool.resolve)
		out.append(md)
	return out


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
				if res == "hp" and per < 0.0:
					per *= dot_mult
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
