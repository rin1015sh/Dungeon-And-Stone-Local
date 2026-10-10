class_name ValidatorBase
extends RefCounted
## 데이터 검사 공용 도구: 오류/경고 수집, 수식 키, 수정자 대상, 참조, 범위, 등급·확률.
## 컬렉션별 규칙은 DataValidator가 이것을 상속해 쓴다.

## 수정자 대상 접두어 -> 접미어가 속해야 할 목록("@컬렉션" 또는 "damage" = 피해 유형)
const TARGET_PREFIXES := {"max": "@resources", "regen": "@resources", "dmg_taken": "damage", "dmg_dealt": "damage"}

var errors: Array[String] = []
var warnings: Array[String] = []

var _db: GameDatabase


func _check_formula(where: String, value: Variant) -> void:
	if JsonUtil.is_number(value):
		return
	if not value is String:
		_err(where, "수식은 숫자나 문자열이어야 한다")
		return
	var src: String = value
	if src.is_valid_float():
		return
	var problem := Formula.check(src)
	if not problem.is_empty():
		_err(where, "수식 오류 '%s': %s" % [src, problem])
	for key: String in Formula.extract_keys(src):
		if key == "level":
			continue
		if key.begins_with("bal."):
			if not JsonUtil.is_number(_db.bal(key.substr(4))):
				_err(where, "balance 값 없음/숫자 아님: {%s}" % key)
		elif not _db.stats.has(key):
			_err(where, "알 수 없는 수식 키 {%s}" % key)


func _check_modifier_list(where: String, list: Array) -> void:
	for md: Variant in list:
		if not md is Dictionary:
			_err(where, "수정자는 객체여야 한다")
			continue
		_check_target(where, JsonUtil.get_str(md, "target"))


func _check_target(where: String, target: String) -> void:
	var sep := target.find(":")
	if sep < 0:
		if not _db.stats.has(target):
			_err(where, "수정자 대상 스탯 '%s' 없음" % target)
		return
	var prefix := target.substr(0, sep)
	var suffix := target.substr(sep + 1)
	if not TARGET_PREFIXES.has(prefix):
		_err(where, "수정자 대상 접두어 '%s' 미지원" % prefix)
		return
	var kind: String = TARGET_PREFIXES[prefix]
	if kind == "damage":
		if not (_damage_ids().has(suffix) or suffix == "all"):
			_err(where, "수정자 대상 피해 유형 '%s' 없음" % suffix)
	elif not _db.has_entry(kind.substr(1), suffix):
		_err(where, "수정자 대상 '%s' 없음" % target)


func _check_stat_map(where: String, m: Dictionary) -> void:
	for k: String in m:
		if not _db.stats.has(k):
			_err(where, "스탯 '%s' 없음" % k)
		elif not JsonUtil.is_number(m[k]):
			_err(where, "스탯 '%s' 값이 숫자가 아님" % k)


func _check_ranges(where: String, ranges: Dictionary) -> void:
	for k: String in ranges:
		var r: Variant = ranges[k]
		if not _db.stats.has(k):
			_err(where, "범위의 스탯 '%s' 없음" % k)
		elif not (r is Array and (r as Array).size() == 2 and JsonUtil.is_number(r[0]) and JsonUtil.is_number(r[1])):
			_err(where, "'%s' 범위는 [최소, 최대]" % k)
		elif float(r[0]) > float(r[1]):
			_err(where, "'%s' 범위 최소 > 최대" % k)


func _check_grade(where: String, g: Variant) -> void:
	if not JsonUtil.is_number(g) or int(g) < 1 or int(g) > 9:
		_err(where, "등급은 1~9 (9가 최하)")


func _check_chance(where: String, c: Variant) -> void:
	if not JsonUtil.is_number(c) or float(c) < 0.0 or float(c) > 1.0:
		_err(where, "확률은 0~1")


func _ref(where: String, col: String, id: Variant) -> void:
	if id == null or not _db.has_entry(col, str(id)):
		_err(where, "%s '%s' 참조 대상 없음" % [col, id])


func _damage_ids() -> PackedStringArray:
	var out := _db.tag_ids("damage_types")
	for c: Variant in JsonUtil.get_array(_db.tags, "damage_categories"):
		out.append(str(c))
	return out


func _err(where: String, msg: String) -> void:
	errors.append("[%s] %s" % [where, msg])


func _warn(where: String, msg: String) -> void:
	warnings.append("[%s] %s" % [where, msg])
