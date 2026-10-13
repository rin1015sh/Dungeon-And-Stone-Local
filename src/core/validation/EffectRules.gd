class_name EffectRules
extends RefCounted
## 검사 도구: 효과 목록의 깊은 검사(ValidatorBase.check_effects 위에 얹는다)와 id 목록 참조 검사.
##   수식 양(amount — restore_resource·barrier·meter), 조건부 위력 power_if_status {status: [..]},
##   조건부 흡혈 drain_if_status {status: ".."}, 추가 피해 rider {damage_type}, 안쪽 효과 목록(delayed effects).
## 효과 핸들러(src/combat/effects/)는 건드리지 않고 규칙 층에서 목록을 훑는다.

## amount가 수식일 수 있는 효과 타입(핸들러가 Formula.value로 푼다).
const FORMULA_AMOUNT_TYPES := ["restore_resource", "barrier", "meter"]
## rider·hit_rider에 damage_type이 없을 때 쓰는 값(damage.gd와 같게).
const DEFAULT_RIDER_TYPE := "cold"


## 효과 목록 하나: 기본 검사(check_effects) + 깊은 검사.
static func check(v: ValidatorBase, where: String, list: Array, strict: bool) -> void:
	v.check_effects(where, list, strict)
	deep(v, where, list)


## 깊은 검사만(기본 검사는 이미 한 목록).
static func deep(v: ValidatorBase, where: String, list: Array) -> void:
	for e: Variant in list:
		if not e is Dictionary:
			continue
		var ed: Dictionary = e
		var etype := JsonUtil.get_str(ed, "type")
		if etype in FORMULA_AMOUNT_TYPES and ed.has("amount"):
			v.check_formula("%s.%s.amount" % [where, etype], ed["amount"])
		if ed.has("power_if_status"):
			var pis: Variant = ed["power_if_status"]
			var sts: Variant = (pis as Dictionary).get("status") if pis is Dictionary else null
			if not sts is Array:
				v.err(where + ".power_if_status", "status는 상태이상 id 배열")
			else:
				ref_list(v, where + ".power_if_status", "statuses", sts as Array)
		if ed.has("drain_if_status"):
			var dis: Variant = ed["drain_if_status"]
			var dst: Variant = (dis as Dictionary).get("status") if dis is Dictionary else null
			if not dst is String:
				v.err(where + ".drain_if_status", "status는 상태이상 id 문자열")
			else:
				v.ref(where + ".drain_if_status", "statuses", dst)
		if ed.has("rider"):
			var rd: Variant = ed["rider"]
			if not rd is Dictionary:
				v.err(where + ".rider", "rider는 {damage_type, ratio|flat}")
			else:
				damage_type(v, where + ".rider", JsonUtil.get_str(rd as Dictionary, "damage_type", DEFAULT_RIDER_TYPE))
		var inner: Variant = ed.get("effects")
		if inner is Array:
			deep(v, where + "." + etype, inner as Array)


## id 배열의 각 항목이 컬렉션에 있어야 한다.
static func ref_list(v: ValidatorBase, where: String, col: String, ids: Array) -> void:
	for id: Variant in ids:
		v.ref(where, col, id)


## 값이 배열이고 각 항목이 컬렉션에 있어야 한다(키가 없으면 통과).
static func ref_array_key(v: ValidatorBase, where: String, col: String, d: Dictionary, key: String) -> void:
	if not d.has(key):
		return
	if not d[key] is Array:
		v.err(where + "." + key, "%s id 배열이어야 한다" % col)
		return
	ref_list(v, where + "." + key, col, d[key] as Array)


## 구체적인 피해 유형 id(tags.damage_types — 분류 physical/magical 제외)여야 한다.
static func damage_type(v: ValidatorBase, where: String, id: String) -> void:
	if not v.db.tag_ids("damage_types").has(id):
		v.err(where, "피해 유형 '%s' 미등록(tags.damage_types)" % id)


## 딕셔너리 d의 key가 있으면 피해 유형 id 배열이어야 한다.
static func damage_type_list(v: ValidatorBase, where: String, d: Dictionary, key: String) -> void:
	if not d.has(key):
		return
	if not d[key] is Array:
		v.err(where + "." + key, "피해 유형 id 배열이어야 한다")
		return
	for t: Variant in (d[key] as Array):
		damage_type(v, where + "." + key, str(t))
