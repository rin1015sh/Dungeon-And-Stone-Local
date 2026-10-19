class_name PassiveRules
extends RefCounted
## 검사 규칙: 패시브 정의(Passives.gd 키) — 몬스터 passives[], 정수 passive, 보스 페이즈 self_passives,
## 드레드피어 buffs[].passive가 같은 검사를 쓴다. 안쪽 참조(피해 유형·상태이상·게이지·몬스터·효과 목록)까지 본다.

## 효과 목록인 패시브 키.
const EFFECT_KEYS := ["on_hit", "on_crit", "on_kill", "death_effects", "basic_attack_effects"]
## 상태이상 id 배열인 패시브 키.
const STATUS_LIST_KEYS := ["status_immune", "foe_statuses_on_start", "self_statuses_on_start"]
const AURA_TARGETS := ["all", "random"]


static func check(v: ValidatorBase, w: String, p: Dictionary) -> void:
	if JsonUtil.get_str(p, "id").is_empty() or JsonUtil.get_str(p, "name_ko").is_empty():
		v.err(w, "패시브는 {id, name_ko, desc_ko, …}")
	v.check_modifier_list(w + ".modifiers", JsonUtil.get_array(p, "modifiers"))
	for key: String in EFFECT_KEYS:
		if p.has(key) and not p[key] is Array:
			v.err(w + "." + key, "효과 목록(배열)이어야 한다")
		EffectRules.check(v, w + "." + key, JsonUtil.get_array(p, key), true)
	for key: String in STATUS_LIST_KEYS:
		EffectRules.ref_array_key(v, w, "statuses", p, key)
	_damage_filters(v, w, p)
	_statuses(v, w, p)
	_meters(v, w, p)
	_monsters(v, w, p)


## 피해 유형으로 거르는 키: crit_bonus·on_hit_filter·on_damaged_by·meter_on_damaged의 damage_types, hit_rider.
static func _damage_filters(v: ValidatorBase, w: String, p: Dictionary) -> void:
	for key: String in ["crit_bonus", "on_hit_filter", "on_damaged_by", "meter_on_damaged"]:
		if p.has(key):
			EffectRules.damage_type_list(v, w + "." + key, JsonUtil.get_dict(p, key), "damage_types")
	if p.has("hit_rider"):
		var hr := JsonUtil.get_dict(p, "hit_rider")
		EffectRules.damage_type_list(v, w + ".hit_rider", hr, "on_types")
		EffectRules.damage_type(v, w + ".hit_rider", JsonUtil.get_str(hr, "damage_type", EffectRules.DEFAULT_RIDER_TYPE))


static func _statuses(v: ValidatorBase, w: String, p: Dictionary) -> void:
	if p.has("power_vs_status"):
		v.ref(w + ".power_vs_status", "statuses", JsonUtil.get_dict(p, "power_vs_status").get("status"))
	if p.has("mark_first_attacker"):
		v.ref(w + ".mark_first_attacker", "statuses", p["mark_first_attacker"])
	if p.has("turn_end_foe_status"):
		var tf := JsonUtil.get_dict(p, "turn_end_foe_status")
		v.ref(w + ".turn_end_foe_status", "statuses", tf.get("status"))
		if not JsonUtil.get_str(tf, "target", "all") in AURA_TARGETS:
			v.err(w + ".turn_end_foe_status", "target은 all/random")
	if p.has("status_duration_cap"):
		var cap := JsonUtil.get_dict(p, "status_duration_cap")
		for st: String in cap:
			v.ref(w + ".status_duration_cap", "statuses", st)
			if not JsonUtil.is_number(cap[st]):
				v.err(w + ".status_duration_cap", "'%s' 상한은 숫자" % st)


static func _meters(v: ValidatorBase, w: String, p: Dictionary) -> void:
	for key: String in ["meter_on_damaged", "attacker_meter"]:
		if p.has(key):
			v.ref(w + "." + key, "meters", JsonUtil.get_dict(p, key).get("meter"))


static func _monsters(v: ValidatorBase, w: String, p: Dictionary) -> void:
	EffectRules.ref_array_key(v, w, "monsters", p, "start_summons")
	if p.has("low_hp_summons"):
		EffectRules.ref_array_key(v, w + ".low_hp_summons", "monsters", JsonUtil.get_dict(p, "low_hp_summons"), "monsters")
	if p.has("ally_aura"):
		var aura := JsonUtil.get_dict(p, "ally_aura")
		EffectRules.ref_array_key(v, w + ".ally_aura", "monsters", aura, "monsters")
		v.check_modifier_list(w + ".ally_aura.modifiers", JsonUtil.get_array(aura, "modifiers"))
