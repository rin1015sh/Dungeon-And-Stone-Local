class_name StatusSet
extends RefCounted
## 상태이상 묶음(data/statuses.json). 컴포넌트로 Actor에 붙는다.
## - 부여하면 정의의 modifiers를 출처 "status:<id>"로 StatBlock에 붙이고, 해제하면 뗀다.
## - periodic: 턴/시간마다 자원을 바꾼다(출혈·아사 …). 수식은 ResourcePool.resolve로 푼다.
## - duration {amount, unit: turn|hour|battle(전투 수 — end_battle)}: 다 되면 해제. 없으면 영구(조건이 풀릴 때 소유자가 해제).
## - stackable: 다시 걸리면 중첩(수정자·주기 효과가 중첩 수만큼).
## - flags: no_skills, skip_turn, untargetable(은신), no_flee(속박) … (전투가 읽는다)
## - modifiers의 flat/percent가 문자열이면 걸릴 때 소유자 스탯으로 푼 수식(저체온증 "-max(0, 30 - {resist_cold})").
## - immune_if {stat, at_least}: 그 스탯이 넘으면 걸리지 않는다(진압). on_max_stacks {status}: 최대 중첩이 되면 그 상태로 바뀐다(서리 → 빙결).
## - break_on_damage / break_on_damage_types: 피해를 받으면(그 유형이면) 풀린다(진압, 빙결 ← 화염). heal_mult: 받는 치유 배율(원한).
## - grants_immunity [상태 id]: 이 상태가 걸린 동안 그 상태들에 걸리지 않는다(키르뒤 광분 → 공포·기절).
## - barrier: true — 보호막 상태. 양은 set_barrier로 정하고, 받는 피해를 먼저 흡수한다(absorb). 다 닳으면 풀린다(강철빙벽).
## - 지속시간은 자기 차례가 시작될 때 준다. 자기 행동에 영향을 주는 상태(실명·버프)는 '효과를 볼 차례 수 + 1'로 준다.
## - 차례 단위 상태는 전투가 끝나면 풀린다(clear_temporary). "lingers": true(독·출혈 …)는 남아서 전투 밖에서는
##   게임 시간 status.linger_hours_per_turn시간을 한 차례로 쳐서 주기 효과·지속시간이 흐른다(tick_hours).
## - 수식 수정자는 소유자 스탯이 바뀌면 다시 계산한다(냉기 내성을 올리면 저체온증이 바로 약해진다).
## - after_immune: n — 풀리면 n차례 동안 같은 상태에 걸리지 않는다(기절·빙결 사슬 막기, 상태이상 재기획 2026-10-19).
## - on_act {resource, amount}: 소유자가 행동할 때마다 중첩 수만큼(출혈 — 움직일수록 흘린다). heal_cures_stack: 회복을 받으면 1중첩 줄어든다.
## - hit_taken / crit_taken: 이 상태가 걸린 대상을 치는 쪽의 명중(퍼센트 포인트)·치명 확률 보너스(표식 — DamageCalc).

signal applied(status_id: String)
signal removed(status_id: String)

const SOURCE_PREFIX := "status:"
const DEFAULT_MAX_STACKS := 99

var _db: GameDatabase
var _stats: StatBlock
var _pool: ResourcePool
var _active: Dictionary = {}  # id -> {"stacks": int, "remaining": float(음수 = 영구), "unit": String, "mods"?: Array}
## 지속 피해(주기 효과로 생명력이 줄어드는 것) 배율 — 소유자 패시브 dot_mult(본 나이트 방부제)의 곱. Actor가 맞춘다.
var dot_mult: float = 1.0
## 소유자 패시브 status_immune의 합(썩은 거구의 출혈 면역 …). Actor가 맞춘다 — 모든 부여 경로가 immune()에서 막힌다.
var passive_immune: Array[String] = []
var _refreshing: bool = false
var _after: Dictionary = {}  # id -> 남은 차례(after_immune)
var _links: Dictionary = {}  # id -> WeakRef(Actor) — 상태를 건 쪽(대신 맞기 covered의 지키는 사람)


func _init(db: GameDatabase, stats: StatBlock, pool: ResourcePool) -> void:
	_db = db
	_stats = stats
	_pool = pool
	_stats.changed.connect(_refresh_formulas)


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
			_remember_mods(id, def)
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
	_remember_mods(id, def)
	applied.emit(id)
	return true


func remove(id: String) -> bool:
	if not _active.has(id):
		return false
	_active.erase(id)
	_links.erase(id)
	_stats.remove_source(SOURCE_PREFIX + id)
	var after := JsonUtil.get_float(_db.get_entry("statuses", id), "after_immune")
	if after > 0.0:
		_after[id] = after
	removed.emit(id)
	return true


## 상태에 다른 개체를 묶는다(약한 참조 — 대신 맞기). 상태가 풀리면 함께 사라진다.
func set_link(id: String, actor: Actor) -> void:
	if _active.has(id) and actor != null:
		_links[id] = weakref(actor)


func link(id: String) -> Actor:
	if not _active.has(id) or not _links.has(id):
		return null
	return (_links[id] as WeakRef).get_ref() as Actor


## 소유자가 행동했다: on_act(출혈)를 중첩 수만큼 준다.
func on_acted() -> void:
	for id: String in _active.keys():
		var od := JsonUtil.get_dict(_db.get_entry("statuses", id), "on_act")
		var res := JsonUtil.get_str(od, "resource")
		if not od.is_empty() and _pool.has_resource(res):
			var per := JsonUtil.get_float(od, "amount")
			if res == "hp" and per < 0.0:
				per *= dot_mult
			_pool.modify(res, per * stacks(id), SOURCE_PREFIX + id)


## 생명력을 회복받았다: heal_cures_stack인 상태(출혈)를 1중첩 줄인다.
func on_healed() -> void:
	for id: String in _active.keys():
		var def := _db.get_entry("statuses", id)
		if not JsonUtil.get_bool(def, "heal_cures_stack"):
			continue
		var st: Dictionary = _active[id]
		if int(st["stacks"]) <= 1:
			remove(id)
			continue
		st["stacks"] = int(st["stacks"]) - 1
		_stats.remove_source(SOURCE_PREFIX + id)
		for i in int(st["stacks"]):
			_stats.add_modifiers_from_data(SOURCE_PREFIX + id, _mods(def))


## 패시브 면역(status_immune), 스탯 문턱(immune_if), 걸린 상태의 grants_immunity 때문에 걸리지 않는가.
func immune(id: String) -> bool:
	if passive_immune.has(id) or float(_after.get(id, 0.0)) > 0.0:
		return true
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


## 상태 하나가 남긴 보호막 양(카드 표시용).
func barrier_of(id: String) -> float:
	return float((_active[id] as Dictionary).get("barrier", 0.0)) if _active.has(id) else 0.0


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


## 약화 상태(kind debuff) 중 하나를 고른다(필드 효과·전투 한정 표식·자원이 거는 상태(허기·아사 …)는 뺀다). 없으면 "".
func pick_debuff(rng: Rng) -> String:
	var pool: Array[String] = []
	for id: String in _active:
		var def := _db.get_entry("statuses", id)
		if JsonUtil.get_str(def, "kind") == "debuff" and not JsonUtil.get_bool(def, "field_effect") and not def.has("persist") 				and not _resource_bound(id):
			pool.append(id)
	return "" if pool.is_empty() else str(rng.pick(pool))


## 자원 임계값·고갈이 거는 상태인가(자원이 돌아와야 풀린다 — 해제 효과로 지우지 않는다).
func _resource_bound(id: String) -> bool:
	for rid in _pool.ids():
		var rd := _pool.get_def(rid)
		if rd.on_zero_kind == ResourceDef.ON_ZERO_STATUS and rd.on_zero_id == id:
			return true
		for t: Dictionary in rd.thresholds:
			if JsonUtil.get_str(t, "apply_status") == id:
				return true
	return false


## 걸리는 순간 면역(grants_immunity)을 주는 상태가 생겼다: 이미 걸린 그 상태들을 푼다. 푼 id 목록.
func purge_immune() -> Array[String]:
	var out: Array[String] = []
	for id in ids():
		if immune(id) and _active.has(id):
			remove(id)
			out.append(id)
	return out


## 남이 건 그 상태를 버틸 확률(10층 비율 공식): resist_max × 저항 / (저항 + 거는 쪽 힘).
## 저항 = 정의 resist {stats}의 평균, 거는 쪽 힘 = 그 사람의 근력·정신력 중 큰 값(power를 안 주면 저항과 같다고 본다 — 30%).
func resist_chance(id: String, power: float = -1.0) -> float:
	var stats := JsonUtil.get_array(JsonUtil.get_dict(_db.get_entry("statuses", id), "resist"), "stats")
	if stats.is_empty():
		return 0.0
	var total := 0.0
	for st: Variant in stats:
		total += maxf(0.0, _stats.get_value(str(st)))
	var res := total / stats.size()
	var pw := power if power >= 0.0 else res
	if res + pw <= 0.0:
		return 0.0
	return clampf(float(_db.bal("status.resist_max", 0.6)) * res / (res + pw), 0.0, 1.0)


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


## 게임 시간 경과(탐험). 차례 단위 상태(전투 뒤 남은 독·출혈 등)는 status.linger_hours_per_turn시간 = 한 차례로 흐른다.
func tick_hours(hours: float) -> void:
	_periodic("time", hours)
	_countdown("hour", hours)
	var per_turn := float(_db.bal("status.linger_hours_per_turn", 0.25))
	if per_turn > 0.0:
		_periodic("turn", hours / per_turn, "turn")
		_countdown("turn", hours / per_turn)


## 전투가 하나 끝났다: 전투 수 단위(unit "battle" — 여관 식사)의 지속시간이 하나 준다.
func end_battle() -> void:
	_countdown("battle", 1.0)


## 남은 지속시간 [양, 단위]. 영구면 [-1, 단위], 없으면 [].
func remaining(id: String) -> Array:
	if not _active.has(id):
		return []
	var st: Dictionary = _active[id]
	return [float(st["remaining"]), str(st["unit"])]


## 전투가 끝났다: 차례 단위 상태 중 남지 않는 것(lingers가 아닌 것 — 속박·방어 태세·기절 …)을 푼다. 푼 id 목록.
func clear_temporary() -> Array[String]:
	var out: Array[String] = []
	for id in ids():
		var st: Dictionary = _active[id]
		if str(st["unit"]) == "turn" and float(st["remaining"]) >= 0.0 				and not JsonUtil.get_bool(_db.get_entry("statuses", id), "lingers"):
			remove(id)
			out.append(id)
	_after.clear()
	return out


## 미궁을 나왔다: 남은 상태를 모두 푼다(자원 문턱에 묶인 것 — 허기·영혼탈진 — 은 자원이 정한다).
## 미궁 시간이 흐르지 않는 도시에서 독·출혈·저주가 그대로 남아 다음 원정까지 따라오지 않게(2026-10-24 상태이상 점검).
func leave_dungeon() -> void:
	for id in ids():
		if not _resource_bound(id):
			remove(id)
	_after.clear()


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


## unit_only가 있으면 그 지속 단위의 상태만.
## 수식 수정자(문자열 값)가 있는 상태면 지금 계산한 값을 기억한다(_refresh_formulas가 비교).
func _remember_mods(id: String, def: Dictionary) -> void:
	if _has_formula_mods(def) and _active.has(id):
		(_active[id] as Dictionary)["mods"] = _mods(def)


static func _has_formula_mods(def: Dictionary) -> bool:
	for m: Variant in JsonUtil.get_array(def, "modifiers"):
		if m is Dictionary and ((m as Dictionary).get("flat") is String or (m as Dictionary).get("percent") is String):
			return true
	return false


## 스탯이 바뀌었다: 수식 수정자의 값이 달라진 상태는 수정자를 다시 붙인다(중첩 수만큼).
func _refresh_formulas() -> void:
	if _refreshing:
		return
	_refreshing = true
	for id: String in _active.keys():
		var st: Dictionary = _active[id]
		if not st.has("mods"):
			continue
		var def := _db.get_entry("statuses", id)
		var now := _mods(def)
		if now == st["mods"]:
			continue
		st["mods"] = now
		_stats.remove_source(SOURCE_PREFIX + id)
		for i in int(st["stacks"]):
			_stats.add_modifiers_from_data(SOURCE_PREFIX + id, now)
	_refreshing = false


func _periodic(trigger: String, amount: float, unit_only: String = "") -> void:
	for id: String in _active.keys():
		if not _active.has(id):
			continue
		if not unit_only.is_empty() and str((_active[id] as Dictionary)["unit"]) != unit_only:
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
					per *= dot_mult * _element_resist(JsonUtil.get_str(pd, "damage_type"))
				_pool.modify(res, per * n * amount, SOURCE_PREFIX + id)


## 주기 피해의 속성 내성(periodic.damage_type — 중독 = poison): 공격 피해와 같은 resist_<유형> 규칙(DamageCalc.element_mult).
func _element_resist(dtype: String) -> float:
	if dtype.is_empty() or not _stats.has_stat("resist_" + dtype):
		return 1.0
	var per_point := float(_db.bal("combat.element_resist_per_point", 0.01))
	return 1.0 - minf(float(_db.bal("combat.element_resist_max", 0.75)), maxf(0.0, _stats.get_value("resist_" + dtype)) * per_point)


func _countdown(unit: String, amount: float) -> void:
	if unit == "turn":
		for id: String in _after.keys():  # 풀린 뒤 면역은 그다음 차례부터 줄어든다
			_after[id] = float(_after[id]) - amount
			if float(_after[id]) <= 0.000001:
				_after.erase(id)
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
