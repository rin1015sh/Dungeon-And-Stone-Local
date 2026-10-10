class_name StatBlock
extends RefCounted
## 스탯 레지스트리(StatDef 사전) 기반 능력치 묶음.
## 값 = 클램프((기본값 + Σflat + Σ(자식 스탯 × coef)) × max(0, 1 + Σpercent))
## 계산 순서: 기본값 → 합연산(flat, 자식 기여) → 곱연산(percent 합산 후 1회) → 상·하한.
## 스탯이 아닌 대상("max:hp" 등)도 apply_modifiers()로 같은 규칙을 쓴다.

signal changed

const MAX_DEPTH := 16
const EPSILON := 0.000001

var _defs: Dictionary = {}       # id -> StatDef (GameDatabase.stats를 공유)
var _children: Dictionary = {}   # 부모 id -> Array[String]
var _base: Dictionary = {}       # id -> float
var _mods: Array[Modifier] = []
var _cache: Dictionary = {}


func _init(defs: Dictionary = {}) -> void:
	_defs = defs
	for id: String in _defs:
		var def: StatDef = _defs[id]
		if def.parent.is_empty():
			continue
		if not _children.has(def.parent):
			_children[def.parent] = []
		(_children[def.parent] as Array).append(id)


func has_stat(id: String) -> bool:
	return _defs.has(id)


func get_def(id: String) -> StatDef:
	return _defs.get(id)


## 정의 순서(stats.json 순)의 id 목록. tier를 주면 그 층만.
func ids(tier: String = "") -> Array[String]:
	var out: Array[String] = []
	for id: String in _defs:
		if tier.is_empty() or (_defs[id] as StatDef).tier == tier:
			out.append(id)
	return out


func get_base(id: String) -> float:
	if _base.has(id):
		return _base[id]
	var def: StatDef = _defs.get(id)
	return def.default_value if def != null else 0.0


func set_base(id: String, value: float) -> void:
	_base[id] = value
	_invalidate()


func set_bases(values: Dictionary) -> void:
	for id: String in values:
		_base[id] = float(values[id])
	_invalidate()


func get_value(id: String) -> float:
	return _value(id, 0)


## 스탯이 아닌 대상(예: "max:hp", "regen:soul")에 수정자를 적용한 값.
func apply_modifiers(target: String, base_value: float) -> float:
	var flat := 0.0
	var pct := 0.0
	for m: Modifier in _mods:
		if m.target == target:
			flat += m.flat
			pct += m.percent
	return (base_value + flat) * maxf(0.0, 1.0 + pct)


func add_modifier(mod: Modifier) -> void:
	_mods.append(mod)
	_invalidate()


## 데이터의 수정자 목록([{target, flat, percent}...])을 한 출처로 붙인다.
func add_modifiers_from_data(source_id: String, list: Array, duration: float = Modifier.PERMANENT,
		unit: String = "turn") -> void:
	for d: Variant in list:
		if d is Dictionary:
			var m := Modifier.from_dict(d, source_id)
			m.source_id = source_id
			m.duration = duration
			m.unit = unit
			_mods.append(m)
	_invalidate()


## 해당 출처의 수정자를 모두 제거하고 제거한 개수를 돌려준다.
func remove_source(source_id: String) -> int:
	var kept: Array[Modifier] = []
	for m: Modifier in _mods:
		if m.source_id != source_id:
			kept.append(m)
	var removed := _mods.size() - kept.size()
	if removed > 0:
		_mods = kept
		_invalidate()
	return removed


func has_source(source_id: String) -> bool:
	for m: Modifier in _mods:
		if m.source_id == source_id:
			return true
	return false


func get_modifiers(target: String = "") -> Array[Modifier]:
	var out: Array[Modifier] = []
	for m: Modifier in _mods:
		if target.is_empty() or m.target == target:
			out.append(m)
	return out


## 해당 출처 수정자 중 가장 긴 남은 지속량(영구면 -1, 없으면 0).
func source_remaining(source_id: String) -> float:
	var best := 0.0
	for m: Modifier in _mods:
		if m.source_id == source_id:
			if m.is_permanent():
				return Modifier.PERMANENT
			best = maxf(best, m.duration)
	return best


## unit 단위로 amount만큼 시간을 흘려 지속형 수정자를 줄인다. 만료된 출처 id 목록을 돌려준다.
func tick(unit: String, amount: float) -> PackedStringArray:
	var expired := PackedStringArray()
	var kept: Array[Modifier] = []
	for m: Modifier in _mods:
		if not m.is_permanent() and m.unit == unit:
			m.duration -= amount
			if m.duration <= EPSILON:
				if not expired.has(m.source_id):
					expired.append(m.source_id)
				continue
		kept.append(m)
	if kept.size() != _mods.size():
		_mods = kept
		_invalidate()
	return expired


## 저장용: 기본값과 수정자만(정의는 저장하지 않는다).
func to_dict() -> Dictionary:
	var mods: Array = []
	for m: Modifier in _mods:
		mods.append(m.to_dict())
	return {"base": _base.duplicate(), "mods": mods}


func load_dict(d: Dictionary) -> void:
	_base.clear()
	var base := JsonUtil.get_dict(d, "base")
	for id: String in base:
		_base[id] = float(base[id])
	_mods.clear()
	for md: Variant in JsonUtil.get_array(d, "mods"):
		if md is Dictionary:
			_mods.append(Modifier.from_dict(md))
	_invalidate()


func _value(id: String, depth: int) -> float:
	if _cache.has(id):
		return _cache[id]
	if depth > MAX_DEPTH:
		push_error("StatBlock: 부모 관계가 너무 깊거나 순환함 (%s)" % id)
		return 0.0
	var base := get_base(id)
	for child: String in _children.get(id, []):
		base += _value(child, depth + 1) * (_defs[child] as StatDef).coef
	var v := apply_modifiers(id, base)
	var def: StatDef = _defs.get(id)
	if def != null:
		v = def.clamp_value(v)
	_cache[id] = v
	return v


func _invalidate() -> void:
	_cache.clear()
	changed.emit()
