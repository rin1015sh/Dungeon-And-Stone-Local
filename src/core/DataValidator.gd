class_name DataValidator
extends ValidatorBase
## data/ 스키마·참조 무결성 검사기(컬렉션별 규칙). errors가 비어 있어야 통과.
## tools/validate_data.gd, tests/, DataRegistry가 같은 검사기를 쓴다.
## 공용 검사 도구(수식·수정자 대상·참조·범위)는 ValidatorBase에 있다.

const STAT_GROUPS := ["body", "mind", "ability", "special"]
const STAT_TIERS := ["core", "sub"]
const SCOPES := ["always", "dungeon_only", "combat_only"]
const REGEN_BASES := ["max_ratio", "flat"]
const TRIGGERS := ["turn", "time", "rest"]
const DURATION_UNITS := ["turn", "hour"]
const DIRECTIONS := ["down", "up"]
const STATUS_KINDS := ["buff", "debuff", "neutral"]
const ON_ZERO_WORDS := ["kill", "none"]
const REQUIRED_SINGLETONS := ["balance", "render", "tags"]

## 등록된 효과 타입(M2 효과 핸들러 레지스트리). 비어 있으면 효과 타입 검사를 건너뛴다.
var effect_types: PackedStringArray = PackedStringArray()


func validate(db: GameDatabase) -> bool:
	_db = db
	errors.clear()
	warnings.clear()
	errors.append_array(db.load_errors)
	for s: String in REQUIRED_SINGLETONS:
		if (db.singletons.get(s, {}) as Dictionary).is_empty():
			_err("singletons", "필수 파일 '%s'이(가) 비었거나 없다" % s)
	_check_stats()
	_check_resources()
	_check_statuses()
	_check_injuries()
	_check_races_and_classes()
	_check_monsters()
	_check_skills()
	_check_essences()
	_check_common_fields()
	return errors.is_empty()


func _check_stats() -> void:
	for id: String in _db.stats:
		var s: StatDef = _db.stats[id]
		var w := "stats/" + id
		if not s.group in STAT_GROUPS:
			_err(w, "group '%s'은(는) %s 중 하나여야 한다" % [s.group, STAT_GROUPS])
		if not s.tier in STAT_TIERS:
			_err(w, "tier '%s' 오류" % s.tier)
		if s.has_min and s.has_max and s.min_value > s.max_value:
			_err(w, "min > max")
		if not s.parent.is_empty():
			if not _db.stats.has(s.parent):
				_err(w, "parent '%s' 없음" % s.parent)
			elif s.coef == 0.0:
				_warn(w, "parent가 있는데 coef가 0")
		var seen := {id: true}
		var cur := s.parent
		while not cur.is_empty() and _db.stats.has(cur):
			if seen.has(cur):
				_err(w, "parent 순환")
				break
			seen[cur] = true
			cur = (_db.stats[cur] as StatDef).parent
	for core: String in ["str", "agi", "p_res", "m_res", "int"]:
		if not _db.stats.has(core):
			_err("stats", "핵심 스탯 '%s' 없음" % core)


func _check_resources() -> void:
	for id: String in _db.resources:
		var r: ResourceDef = _db.resources[id]
		var w := "resources/" + id
		var raw := _db.get_entry("resources", id)
		if not (raw.has("max_formula") or raw.has("max")):
			_err(w, "max_formula 또는 max 필요")
		_check_formula(w + ".max", r.max_value)
		if not r.scope in SCOPES:
			_err(w, "scope '%s' 오류" % r.scope)
		if not Color.html_is_valid(JsonUtil.get_str(raw, "color", "#888")):
			_err(w, "color 형식 오류")
		for rule: Dictionary in r.regen:
			if not JsonUtil.get_str(rule, "trigger") in TRIGGERS:
				_err(w, "regen.trigger는 %s 중 하나" % [TRIGGERS])
			if not JsonUtil.get_str(rule, "basis", "flat") in REGEN_BASES:
				_err(w, "regen.basis는 %s 중 하나" % [REGEN_BASES])
			_check_formula(w + ".regen", rule.get("rate", 0))
		for t: Dictionary in r.thresholds:
			var at := JsonUtil.get_float(t, "at_ratio", -1.0)
			if at < 0.0 or at > 1.0:
				_err(w, "threshold.at_ratio는 0~1")
			if not JsonUtil.get_str(t, "direction", "down") in DIRECTIONS:
				_err(w, "threshold.direction은 down/up")
			if t.has("apply_status"):
				_ref(w, "statuses", t["apply_status"])
		var oz: Variant = raw.get("on_zero")
		if oz is String and not oz in ON_ZERO_WORDS:
			_err(w, "on_zero 문자열은 %s 중 하나" % [ON_ZERO_WORDS])
		if r.on_zero_kind == ResourceDef.ON_ZERO_STATUS:
			_ref(w, "statuses", r.on_zero_id)
	for core: String in ["hp", "soul", "hunger"]:
		if not _db.resources.has(core):
			_err("resources", "핵심 자원 '%s' 없음" % core)


func _check_statuses() -> void:
	for id: String in _db.get_collection("statuses"):
		var s := _db.get_entry("statuses", id)
		var w := "statuses/" + id
		if not JsonUtil.get_str(s, "kind", "debuff") in STATUS_KINDS:
			_err(w, "kind는 %s 중 하나" % [STATUS_KINDS])
		_check_modifier_list(w, JsonUtil.get_array(s, "modifiers"))
		for p: Variant in JsonUtil.get_array(s, "periodic"):
			var pd: Dictionary = p if p is Dictionary else {}
			if not JsonUtil.get_str(pd, "trigger") in TRIGGERS:
				_err(w, "periodic.trigger 오류")
			if not _db.resources.has(JsonUtil.get_str(pd, "resource")):
				_err(w, "periodic.resource '%s' 없음" % pd.get("resource"))
			_check_formula(w + ".periodic", pd.get("amount", 0))
		var dur := JsonUtil.get_dict(s, "duration")
		if not dur.is_empty() and not JsonUtil.get_str(dur, "unit") in DURATION_UNITS:
			_err(w, "duration.unit은 turn/hour")


func _check_injuries() -> void:
	var parts := _db.tag_ids("body_parts")
	for id: String in _db.get_collection("injuries"):
		var inj := _db.get_entry("injuries", id)
		var w := "injuries/" + id
		for p: Variant in JsonUtil.get_array(inj, "parts"):
			if str(p) != "any" and not parts.has(str(p)):
				_err(w, "부위 '%s' 미등록(tags.body_parts)" % p)
		if inj.has("applies_status"):
			_ref(w, "statuses", inj["applies_status"])
		var by_part := JsonUtil.get_dict(inj, "modifiers_by_part")
		for p: String in by_part:
			if not parts.has(p):
				_err(w, "modifiers_by_part 부위 '%s' 미등록" % p)
			_check_modifier_list(w, by_part[p] if by_part[p] is Array else [])


func _check_races_and_classes() -> void:
	var roles := _db.tag_ids("roles")
	for id: String in _db.get_collection("races"):
		_check_ranges("races/" + id, JsonUtil.get_dict(_db.get_entry("races", id), "stat_ranges"))
	if _db.enabled_ids("races").is_empty():
		_err("races", "활성화된 종족이 하나도 없다")
	for id: String in _db.get_collection("classes"):
		var c := _db.get_entry("classes", id)
		var w := "classes/" + id
		_check_ranges(w, JsonUtil.get_dict(c, "stat_bonus_ranges"))
		if not roles.has(JsonUtil.get_str(c, "role")):
			_err(w, "role '%s' 미등록(tags.roles)" % c.get("role"))
		for r: Variant in JsonUtil.get_array(c, "allowed_races"):
			_ref(w, "races", r)
		for it: Variant in JsonUtil.get_array(c, "start_items"):
			_ref(w, "items", it)
	if _db.enabled_ids("classes").is_empty():
		_err("classes", "활성화된 시작 템플릿이 하나도 없다")


func _check_monsters() -> void:
	var types := _db.tag_ids("monster_types")
	var families := _db.tag_ids("families")
	var damage := _damage_ids()
	for id: String in _db.get_collection("monsters"):
		var m := _db.get_entry("monsters", id)
		var w := "monsters/" + id
		_check_grade(w, m.get("grade"))
		_check_grade(w + ".magic_stone_grade", m.get("magic_stone_grade", m.get("grade")))
		if not types.has(JsonUtil.get_str(m, "type")):
			_err(w, "type '%s' 미등록(tags.monster_types)" % m.get("type"))
		for f: Variant in JsonUtil.get_array(m, "family"):
			if not families.has(str(f)):
				_err(w, "family '%s' 미등록" % f)
		for im: Variant in JsonUtil.get_array(m, "immunities"):
			if not damage.has(str(im)):
				_err(w, "immunities '%s' 미등록 피해 유형" % im)
		var weak := JsonUtil.get_dict(m, "weaknesses")
		for k: String in weak:
			if not damage.has(k):
				_err(w, "weaknesses '%s' 미등록 피해 유형" % k)
			if not JsonUtil.is_number(weak[k]) or float(weak[k]) <= 0.0:
				_err(w, "weaknesses 배율은 양수")
		_check_stat_map(w, JsonUtil.get_dict(m, "stats"))
		var res := JsonUtil.get_dict(m, "resources")
		for r: String in res:
			if not _db.resources.has(r):
				_err(w, "resources '%s' 없는 자원" % r)
			_check_formula(w + ".resources", res[r])
		for s: Variant in JsonUtil.get_array(m, "skills"):
			_ref(w, "skills", s)
		for rule: Variant in JsonUtil.get_array(m, "ai"):
			if rule is Dictionary and (rule as Dictionary).has("use"):
				_ref(w + ".ai", "skills", rule["use"])
		for drop: Variant in JsonUtil.get_array(m, "essence_drops"):
			var dd: Dictionary = drop if drop is Dictionary else {}
			_ref(w, "essences", dd.get("essence"))
			_check_chance(w, dd.get("chance"))


func _check_skills() -> void:
	var targets := _db.tag_ids("skill_targets")
	var damage := _damage_ids()
	var skipped := false
	for id: String in _db.get_collection("skills"):
		var s := _db.get_entry("skills", id)
		var w := "skills/" + id
		if not targets.has(JsonUtil.get_str(s, "target")):
			_err(w, "target '%s' 미등록(tags.skill_targets)" % s.get("target"))
		var cost := JsonUtil.get_dict(s, "cost")
		for r: String in cost:
			if not _db.resources.has(r):
				_err(w, "cost '%s' 없는 자원" % r)
			elif not JsonUtil.is_number(cost[r]) or float(cost[r]) < 0.0:
				_err(w, "cost 값은 0 이상의 숫자")
		for e: Variant in JsonUtil.get_array(s, "effects"):
			var ed: Dictionary = e if e is Dictionary else {}
			var etype := JsonUtil.get_str(ed, "type")
			if etype.is_empty():
				_err(w, "effect에 type 없음")
			elif effect_types.is_empty():
				skipped = true
			elif not effect_types.has(etype):
				_err(w, "effect type '%s' 핸들러 없음" % etype)
			if ed.has("damage_type") and not damage.has(str(ed["damage_type"])):
				_err(w, "damage_type '%s' 미등록" % ed["damage_type"])
			if ed.has("status"):
				_ref(w, "statuses", ed["status"])
			if ed.has("chance"):
				_check_chance(w, ed["chance"])
	if skipped:
		warnings.append("효과 핸들러 레지스트리가 아직 없어(M2) 효과 type 검사를 건너뛰었다")


func _check_essences() -> void:
	for id: String in _db.get_collection("essences"):
		var e := _db.get_entry("essences", id)
		var w := "essences/" + id
		_check_grade(w, e.get("grade"))
		_check_ranges(w, JsonUtil.get_dict(e, "stat_ranges"))
		if e.has("source_monster"):
			_ref(w, "monsters", e["source_monster"])
		for r: String in JsonUtil.get_dict(e, "resource_mods"):
			if not _db.resources.has(r):
				_err(w, "resource_mods '%s' 없는 자원" % r)
		for sk: Variant in JsonUtil.get_array(e, "skills"):
			_ref(w, "skills", (sk as Dictionary).get("id") if sk is Dictionary else sk)


## 모든 컬렉션 공통: name_ko 권장, sprite 경로 형식. 스프라이트 파일이 없으면 경고 한 줄로 모은다.
func _check_common_fields() -> void:
	var missing_sprites := 0
	for col: String in _db.collections:
		var entries: Dictionary = _db.collections[col]
		for id: String in entries:
			var e: Dictionary = entries[id]
			if not e.has("name_ko"):
				_warn(col + "/" + id, "name_ko 없음")
			if e.has("sprite"):
				var sp := JsonUtil.get_str(e, "sprite")
				if not sp.begins_with("res://"):
					_err(col + "/" + id, "sprite는 res:// 경로여야 한다")
				elif not ResourceLoader.exists(sp):
					missing_sprites += 1
	if missing_sprites > 0:
		warnings.append("스프라이트 파일 없음 %d개 — 임시 그래픽으로 표시된다" % missing_sprites)
