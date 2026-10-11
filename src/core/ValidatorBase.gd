class_name ValidatorBase
extends RefCounted
## 데이터 검사 공용 도구: 오류/경고 수집, 참조·수식·수정자 대상·범위·효과 검사.
## 컬렉션별 규칙(CoreRules / ContentRules / WorldRules)이 이 도구를 써서 검사한다.

## 수정자 대상 접두어 -> 접미어가 속해야 할 목록("@컬렉션" 또는 "damage" = 피해 유형)
const TARGET_PREFIXES := {"max": "@resources", "regen": "@resources", "dmg_taken": "damage", "dmg_dealt": "damage"}

var errors: Array[String] = []
var warnings: Array[String] = []
var db: GameDatabase

## 등록된 효과 타입(src/combat/effects/). 비어 있으면 효과 타입 검사를 건너뛴다.
var effect_types: PackedStringArray = PackedStringArray()
## 효과 데이터 검사기: (data: Dictionary, db) -> PackedStringArray. 없으면 생략.
var effect_checker: Callable = Callable()
## 스킬 effects의 타입까지 엄격히 검사할지(전투 효과 핸들러가 갖춰지는 M2부터 true).
var check_skill_effects: bool = false
## 등록된 층 생성기 id(src/explore/generators/). 비어 있으면 생략.
var generator_ids: PackedStringArray = PackedStringArray()
## 층 정의의 생성기 전용 검사: (floor_def, db) -> PackedStringArray. 없으면 생략.
var generator_checker: Callable = Callable()
## 등록된 몬스터 AI 조건 id(src/combat/ai/). 비어 있으면 생략.
var ai_condition_ids: PackedStringArray = PackedStringArray()

var _skipped_effect_types: bool = false


func err(where: String, msg: String) -> void:
	errors.append("[%s] %s" % [where, msg])


func warn(where: String, msg: String) -> void:
	warnings.append("[%s] %s" % [where, msg])


func ref(where: String, col: String, id: Variant) -> void:
	if id == null or not db.has_entry(col, str(id)):
		err(where, "%s '%s' 참조 대상 없음" % [col, id])


func entries(col: String) -> Dictionary:
	return db.get_collection(col)


func check_formula(where: String, value: Variant) -> void:
	if JsonUtil.is_number(value):
		return
	if not value is String:
		err(where, "수식은 숫자나 문자열이어야 한다")
		return
	var src: String = value
	if src.is_valid_float():
		return
	var problem := Formula.check(src)
	if not problem.is_empty():
		err(where, "수식 오류 '%s': %s" % [src, problem])
	for key: String in Formula.extract_keys(src):
		if key == "level":
			continue
		if key.begins_with("bal."):
			if not JsonUtil.is_number(db.bal(key.substr(4))):
				err(where, "balance 값 없음/숫자 아님: {%s}" % key)
		elif not db.stats.has(key):
			err(where, "알 수 없는 수식 키 {%s}" % key)


func check_modifier_list(where: String, list: Array) -> void:
	for md: Variant in list:
		if not md is Dictionary:
			err(where, "수정자는 객체여야 한다")
			continue
		check_target(where, JsonUtil.get_str(md, "target"))


func check_target(where: String, target: String) -> void:
	var sep := target.find(":")
	if sep < 0:
		if not db.stats.has(target):
			err(where, "수정자 대상 스탯 '%s' 없음" % target)
		return
	var prefix := target.substr(0, sep)
	var suffix := target.substr(sep + 1)
	if not TARGET_PREFIXES.has(prefix):
		err(where, "수정자 대상 접두어 '%s' 미지원" % prefix)
		return
	var kind: String = TARGET_PREFIXES[prefix]
	if kind == "damage":
		if not (damage_ids().has(suffix) or suffix == "all"):
			err(where, "수정자 대상 피해 유형 '%s' 없음" % suffix)
	elif not db.has_entry(kind.substr(1), suffix):
		err(where, "수정자 대상 '%s' 없음" % target)


func check_stat_map(where: String, m: Dictionary) -> void:
	for k: String in m:
		if not db.stats.has(k):
			err(where, "스탯 '%s' 없음" % k)
		elif not JsonUtil.is_number(m[k]):
			err(where, "스탯 '%s' 값이 숫자가 아님" % k)


func check_ranges(where: String, ranges: Dictionary) -> void:
	for k: String in ranges:
		var r: Variant = ranges[k]
		if not db.stats.has(k):
			err(where, "범위의 스탯 '%s' 없음" % k)
		elif not (r is Array and (r as Array).size() == 2 and JsonUtil.is_number(r[0]) and JsonUtil.is_number(r[1])):
			err(where, "'%s' 범위는 [최소, 최대]" % k)
		elif float(r[0]) > float(r[1]):
			err(where, "'%s' 범위 최소 > 최대" % k)


func check_grade(where: String, g: Variant) -> void:
	if not JsonUtil.is_number(g) or int(g) < 1 or int(g) > 9:
		err(where, "등급은 1~9 (9가 최하)")


func check_chance(where: String, c: Variant) -> void:
	if not JsonUtil.is_number(c) or float(c) < 0.0 or float(c) > 1.0:
		err(where, "확률은 0~1")


func check_color(where: String, value: String) -> void:
	if not value.is_empty() and not Color.html_is_valid(value):
		err(where, "색 형식 오류 '%s'" % value)


## 효과 목록 검사. strict면 타입이 레지스트리에 있어야 한다(아니면 아는 타입만 세부 검사).
func check_effects(where: String, list: Array, strict: bool) -> void:
	var damage := damage_ids()
	for e: Variant in list:
		if not e is Dictionary:
			err(where, "효과는 객체여야 한다")
			continue
		var ed: Dictionary = e
		var etype := JsonUtil.get_str(ed, "type")
		var known := effect_types.has(etype)
		if etype.is_empty():
			err(where, "effect에 type 없음")
		elif not known and strict and not effect_types.is_empty():
			err(where, "effect type '%s' 핸들러 없음" % etype)
		elif not known:
			_skipped_effect_types = true
		if known and effect_checker.is_valid():
			for problem: String in effect_checker.call(ed, db):
				err(where, problem)
		if ed.has("damage_type") and not (damage.has(str(ed["damage_type"])) or str(ed["damage_type"]) == "weapon"):
			err(where, "damage_type '%s' 미등록" % ed["damage_type"])
		if ed.has("status"):
			ref(where, "statuses", ed["status"])
		if ed.has("chance"):
			check_chance(where, ed["chance"])


func damage_ids() -> PackedStringArray:
	var out := db.tag_ids("damage_types")
	for c: Variant in JsonUtil.get_array(db.tags, "damage_categories"):
		out.append(str(c))
	return out
