class_name CoreRules
extends RefCounted
## 검사 규칙: 스탯·자원·상태이상·부상·종족·시작 템플릿.

const STAT_GROUPS := ["body", "mind", "ability", "special"]
const STAT_TIERS := ["core", "sub"]
const CORE_STATS := ["str", "agi", "p_res", "m_res", "int"]
const CORE_RESOURCES := ["hp", "soul", "hunger"]
const SCOPES := ["always", "dungeon_only", "combat_only"]
const REGEN_BASES := ["max_ratio", "flat"]
const TRIGGERS := ["turn", "time", "rest"]
const DURATION_UNITS := ["turn", "hour"]
const DIRECTIONS := ["down", "up"]
const STATUS_KINDS := ["buff", "debuff", "neutral"]
const ON_ZERO_WORDS := ["kill", "none"]


static func run(v: ValidatorBase) -> void:
	_stats(v)
	_resources(v)
	_statuses(v)
	_injuries(v)
	_races_and_classes(v)


static func _stats(v: ValidatorBase) -> void:
	for id: String in v.db.stats:
		var s: StatDef = v.db.stats[id]
		var w := "stats/" + id
		if not s.group in STAT_GROUPS:
			v.err(w, "group '%s'은(는) %s 중 하나여야 한다" % [s.group, STAT_GROUPS])
		if not s.tier in STAT_TIERS:
			v.err(w, "tier '%s' 오류" % s.tier)
		if s.has_min and s.has_max and s.min_value > s.max_value:
			v.err(w, "min > max")
		if not s.parent.is_empty():
			if not v.db.stats.has(s.parent):
				v.err(w, "parent '%s' 없음" % s.parent)
			elif s.coef == 0.0:
				v.warn(w, "parent가 있는데 coef가 0")
		var seen := {id: true}
		var cur := s.parent
		while not cur.is_empty() and v.db.stats.has(cur):
			if seen.has(cur):
				v.err(w, "parent 순환")
				break
			seen[cur] = true
			cur = (v.db.stats[cur] as StatDef).parent
	for core: String in CORE_STATS:
		if not v.db.stats.has(core):
			v.err("stats", "핵심 스탯 '%s' 없음" % core)


static func _resources(v: ValidatorBase) -> void:
	for id: String in v.db.resources:
		var r: ResourceDef = v.db.resources[id]
		var w := "resources/" + id
		var raw := v.db.get_entry("resources", id)
		if not (raw.has("max_formula") or raw.has("max")):
			v.err(w, "max_formula 또는 max 필요")
		v.check_formula(w + ".max", r.max_value)
		if not r.scope in SCOPES:
			v.err(w, "scope '%s' 오류" % r.scope)
		v.check_color(w, JsonUtil.get_str(raw, "color"))
		for rule: Dictionary in r.regen:
			if not JsonUtil.get_str(rule, "trigger") in TRIGGERS:
				v.err(w, "regen.trigger는 %s 중 하나" % [TRIGGERS])
			if not JsonUtil.get_str(rule, "basis", "flat") in REGEN_BASES:
				v.err(w, "regen.basis는 %s 중 하나" % [REGEN_BASES])
			v.check_formula(w + ".regen", rule.get("rate", 0))
		for t: Dictionary in r.thresholds:
			var at := JsonUtil.get_float(t, "at_ratio", -1.0)
			if at < 0.0 or at > 1.0:
				v.err(w, "threshold.at_ratio는 0~1")
			if not JsonUtil.get_str(t, "direction", "down") in DIRECTIONS:
				v.err(w, "threshold.direction은 down/up")
			if t.has("apply_status"):
				v.ref(w, "statuses", t["apply_status"])
		var oz: Variant = raw.get("on_zero")
		if oz is String and not oz in ON_ZERO_WORDS:
			v.err(w, "on_zero 문자열은 %s 중 하나" % [ON_ZERO_WORDS])
		if r.on_zero_kind == ResourceDef.ON_ZERO_STATUS:
			v.ref(w, "statuses", r.on_zero_id)
	for core: String in CORE_RESOURCES:
		if not v.db.resources.has(core):
			v.err("resources", "핵심 자원 '%s' 없음" % core)


static func _statuses(v: ValidatorBase) -> void:
	for id: String in v.entries("statuses"):
		var s := v.db.get_entry("statuses", id)
		var w := "statuses/" + id
		if not JsonUtil.get_str(s, "kind", "debuff") in STATUS_KINDS:
			v.err(w, "kind는 %s 중 하나" % [STATUS_KINDS])
		v.check_modifier_list(w, JsonUtil.get_array(s, "modifiers"))
		for p: Variant in JsonUtil.get_array(s, "periodic"):
			var pd: Dictionary = p if p is Dictionary else {}
			if not JsonUtil.get_str(pd, "trigger") in TRIGGERS:
				v.err(w, "periodic.trigger 오류")
			if not v.db.resources.has(JsonUtil.get_str(pd, "resource")):
				v.err(w, "periodic.resource '%s' 없음" % pd.get("resource"))
			v.check_formula(w + ".periodic", pd.get("amount", 0))
		var dur := JsonUtil.get_dict(s, "duration")
		if not dur.is_empty() and not JsonUtil.get_str(dur, "unit") in DURATION_UNITS:
			v.err(w, "duration.unit은 turn/hour")


static func _injuries(v: ValidatorBase) -> void:
	var parts := v.db.tag_ids("body_parts")
	for id: String in v.entries("injuries"):
		var inj := v.db.get_entry("injuries", id)
		var w := "injuries/" + id
		for p: Variant in JsonUtil.get_array(inj, "parts"):
			if str(p) != "any" and not parts.has(str(p)):
				v.err(w, "부위 '%s' 미등록(tags.body_parts)" % p)
		if inj.has("applies_status"):
			v.ref(w, "statuses", inj["applies_status"])
		var by_part := JsonUtil.get_dict(inj, "modifiers_by_part")
		for p: String in by_part:
			if not parts.has(p):
				v.err(w, "modifiers_by_part 부위 '%s' 미등록" % p)
			v.check_modifier_list(w, by_part[p] if by_part[p] is Array else [])


static func _races_and_classes(v: ValidatorBase) -> void:
	var roles := v.db.tag_ids("roles")
	for id: String in v.entries("races"):
		var race := v.db.get_entry("races", id)
		v.check_ranges("races/" + id, JsonUtil.get_dict(race, "stat_ranges"))
		v.check_color("races/" + id, JsonUtil.get_str(race, "color"))
	if v.db.enabled_ids("races").is_empty():
		v.err("races", "활성화된 종족이 하나도 없다")
	for id: String in v.entries("classes"):
		var c := v.db.get_entry("classes", id)
		var w := "classes/" + id
		v.check_ranges(w, JsonUtil.get_dict(c, "stat_bonus_ranges"))
		if not roles.has(JsonUtil.get_str(c, "role")):
			v.err(w, "role '%s' 미등록(tags.roles)" % c.get("role"))
		for r: Variant in JsonUtil.get_array(c, "allowed_races"):
			v.ref(w, "races", r)
		for eq: Variant in JsonUtil.get_array(c, "start_equipment"):
			v.ref(w + ".start_equipment", "items", eq)
			if v.db.has_entry("items", str(eq)) and JsonUtil.get_dict(v.db.get_entry("items", str(eq)), "equip").is_empty():
				v.err(w + ".start_equipment", "'%s'은(는) 장비가 아니다" % eq)
		for it: Variant in JsonUtil.get_array(c, "start_items"):
			var item: Dictionary = it if it is Dictionary else {}
			v.ref(w + ".start_items", "items", item.get("id"))
			if JsonUtil.get_int(item, "count", 1) < 1:
				v.err(w, "start_items.count는 1 이상")
	if v.db.enabled_ids("classes").is_empty():
		v.err("classes", "활성화된 시작 템플릿이 하나도 없다")
