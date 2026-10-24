class_name BossRules
extends RefCounted
## 검사 규칙: 전투 게이지(meters.json), 보스 패턴·페이즈(몬스터 pattern·pattern_params·phases),
## 상태이상의 G3·G4 키(오인·저항·면역 문턱·중첩 전환·수식 수정자),
## 예고 공격(delayed)의 안쪽 효과. 패턴별 pattern_params 참조는 BossParamRules.

## 상태이상 flags 어휘(StatusSet.has_flag("…")로 코드가 읽는 것 전부).
const STATUS_FLAGS := ["skip_turn", "no_skills", "may_skip_turn", "no_flee", "untargetable", "no_ally_single",
	"no_regen", "always_hit", "draws_attacks", "no_split"]


static func run(v: ValidatorBase) -> void:
	for id: String in v.entries("meters"):
		var m := v.db.get_entry("meters", id)
		var w := "meters/" + id
		if JsonUtil.get_float(m, "max", 0.0) <= 0.0:
			v.err(w, "max는 양수")
		var st := JsonUtil.get_str(JsonUtil.get_dict(m, "on_full"), "status")
		if not st.is_empty():
			v.ref(w + ".on_full", "statuses", st)
		v.check_color(w, JsonUtil.get_str(m, "color", "#ffffff"))
	for id: String in v.entries("statuses"):
		_status(v, id, v.db.get_entry("statuses", id))
	for id: String in v.entries("skills"):
		for e: Variant in JsonUtil.get_array(v.db.get_entry("skills", id), "effects"):
			if e is Dictionary and JsonUtil.get_str(e, "type") == "delayed":
				EffectRules.check(v, "skills/" + id + ".delayed", JsonUtil.get_array(e, "effects"), v.check_skill_effects)
	for id: String in v.entries("monsters"):
		_monster(v, id, v.db.get_entry("monsters", id))


static func _monster(v: ValidatorBase, id: String, m: Dictionary) -> void:
	var w := "monsters/" + id
	var pid := JsonUtil.get_str(m, "pattern")
	if not pid.is_empty():
		var path := "%s/%s.gd" % [BossHooks.PATTERN_DIR, pid]
		if not ResourceLoader.exists(path):
			v.err(w, "pattern '%s' 없음(%s)" % [pid, BossHooks.PATTERN_DIR])
		else:
			var pat := (load(path) as GDScript).new() as BossPattern
			if pat != null:
				for msg in pat.validate(m, v.db):
					v.err(w, msg)
		BossParamRules.run(v, w, pid, m)
	var last := 2.0
	for ph: Variant in JsonUtil.get_array(m, "phases"):
		var pd: Dictionary = ph if ph is Dictionary else {}
		var pw := w + ".phases." + JsonUtil.get_str(pd, "id", "?")
		var above := JsonUtil.get_float(pd, "hp_above", -1.0)
		if above < 0.0 or above >= last:
			v.err(pw, "hp_above는 위에서부터 줄어드는 0~1 값")
		last = above
		for key in ["self_statuses", "foe_statuses", "remove_foe_statuses", "remove_self_statuses"]:
			for st: Variant in JsonUtil.get_array(pd, key):
				v.ref(pw + "." + key, "statuses", st)
		EffectRules.check(v, pw + ".round_effects", JsonUtil.get_array(pd, "round_effects"), v.check_skill_effects)
		for sp: Variant in JsonUtil.get_array(pd, "self_passives"):
			PassiveRules.check(v, pw + ".self_passives", sp if sp is Dictionary else {})
		if pd.has("cast"):
			v.ref(pw + ".cast", "skills", pd["cast"])
		if pd.has("message") and not (pd["message"] is String and not JsonUtil.get_str(pd, "message").is_empty()):
			v.err(pw, "message는 비지 않은 문자열 키")
		if pd.has("target_rule") and not JsonUtil.get_str(pd, "target_rule") in ["guard_front", "lowest_hp", "highest_hp", "random"]:
			v.err(pw, "target_rule은 guard_front/lowest_hp/highest_hp/random")


static func _status(v: ValidatorBase, id: String, s: Dictionary) -> void:
	var w := "statuses/" + id
	var mis := JsonUtil.get_dict(s, "misdirect")
	if not mis.is_empty():
		v.check_chance(w + ".misdirect", mis.get("chance"))
	for st: Variant in JsonUtil.get_array(JsonUtil.get_dict(s, "resist"), "stats"):
		if not v.db.stats.has(str(st)):
			v.err(w + ".resist", "스탯 '%s' 없음" % st)
	var im := JsonUtil.get_dict(s, "immune_if")
	if not im.is_empty() and not v.db.stats.has(JsonUtil.get_str(im, "stat")):
		v.err(w + ".immune_if", "스탯 '%s' 없음" % im.get("stat"))
	var conv := JsonUtil.get_dict(s, "on_max_stacks")
	if not conv.is_empty():
		v.ref(w + ".on_max_stacks", "statuses", conv.get("status"))
		if not JsonUtil.get_bool(s, "stackable") or JsonUtil.get_int(s, "max_stacks", 0) < 2:
			v.err(w, "on_max_stacks는 stackable + max_stacks 2 이상일 때만")
	for f: Variant in JsonUtil.get_array(s, "flags"):
		if not str(f) in STATUS_FLAGS:
			v.err(w + ".flags", "flag '%s'은(는) %s 중 하나" % [f, STATUS_FLAGS])
	EffectRules.check(v, w + ".on_hit", JsonUtil.get_array(s, "on_hit"), true)
	EffectRules.ref_array_key(v, w, "statuses", s, "grants_immunity")
	EffectRules.damage_type_list(v, w, s, "break_on_damage_types")
	for key in ["lingers", "break_on_damage", "battle_only", "boss_mechanic"]:
		if s.has(key) and not s[key] is bool:
			v.err(w, "%s는 true/false" % key)
	for m: Variant in JsonUtil.get_array(s, "modifiers"):
		for k in ["flat", "percent"]:
			var val: Variant = (m as Dictionary).get(k) if m is Dictionary else null
			if val is String:
				v.check_formula(w + ".modifiers", val)
