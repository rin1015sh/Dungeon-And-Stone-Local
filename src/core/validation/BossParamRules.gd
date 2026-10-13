class_name BossParamRules
extends RefCounted
## 검사 규칙: 보스 패턴별 pattern_params의 안쪽 참조(몬스터 "pattern" 값으로 고른다).
## 패턴 스크립트의 validate(필수 키·기본 참조)와 겹치지 않는 것만 여기서 본다.
##   guardian  force_phase {status, phase}, per_foe_status {status, buff}, mumbles [문자열 키], intro 문자열 키
##   dreadfear proliferate.status, gnaw [효과], hatred.meter, buffs[].passive·round_self_effects, extra_status,
##             proliferate/maggots/hatred/cycle의 phases와 flags.phase(이 몬스터의 페이즈 id), flags.twisted_status


static func run(v: ValidatorBase, w: String, pattern_id: String, m: Dictionary) -> void:
	var p := JsonUtil.get_dict(m, "pattern_params")
	var phase_ids: Array = []
	for ph: Variant in JsonUtil.get_array(m, "phases"):
		phase_ids.append(JsonUtil.get_str(ph if ph is Dictionary else {}, "id"))
	match pattern_id:
		"guardian":
			_guardian(v, w + ".pattern_params", p, phase_ids)
		"dreadfear":
			_dreadfear(v, w + ".pattern_params", p, phase_ids)


static func _guardian(v: ValidatorBase, w: String, p: Dictionary, phase_ids: Array) -> void:
	if p.has("force_phase"):
		var fp := JsonUtil.get_dict(p, "force_phase")
		v.ref(w + ".force_phase", "statuses", fp.get("status"))
		_phase(v, w + ".force_phase", fp.get("phase"), phase_ids)
	if p.has("per_foe_status"):
		var pf := JsonUtil.get_dict(p, "per_foe_status")
		v.ref(w + ".per_foe_status", "statuses", pf.get("status"))
		v.ref(w + ".per_foe_status.buff", "statuses", pf.get("buff"))
	if p.has("mumbles"):
		if not p["mumbles"] is Array:
			v.err(w + ".mumbles", "문자열 키 배열이어야 한다")
		else:
			for mb: Variant in (p["mumbles"] as Array):
				_text_key(v, w + ".mumbles", mb)
	if p.has("intro"):
		_text_key(v, w + ".intro", p["intro"])


static func _dreadfear(v: ValidatorBase, w: String, p: Dictionary, phase_ids: Array) -> void:
	if p.has("proliferate"):
		v.ref(w + ".proliferate", "statuses", JsonUtil.get_dict(p, "proliferate").get("status"))
	if p.has("gnaw") and not p["gnaw"] is Array:
		v.err(w + ".gnaw", "효과 목록(배열)이어야 한다")
	EffectRules.check(v, w + ".gnaw", JsonUtil.get_array(p, "gnaw"), v.check_skill_effects)
	if p.has("hatred"):
		v.ref(w + ".hatred", "meters", JsonUtil.get_dict(p, "hatred").get("meter"))
	if p.has("extra_status"):
		v.ref(w + ".extra_status", "statuses", p["extra_status"])
	for b: Variant in JsonUtil.get_array(p, "buffs"):
		var bd: Dictionary = b if b is Dictionary else {}
		if bd.has("passive"):
			PassiveRules.check(v, w + ".buffs.passive", JsonUtil.get_dict(bd, "passive"))
		EffectRules.check(v, w + ".buffs.round_self_effects", JsonUtil.get_array(bd, "round_self_effects"), v.check_skill_effects)
	for key: String in ["proliferate", "maggots", "hatred", "cycle"]:
		var phases: Variant = JsonUtil.get_dict(p, key).get("phases")
		if phases == null:
			continue
		if not phases is Array:
			v.err(w + "." + key + ".phases", "페이즈 id 배열이어야 한다")
			continue
		for pid: Variant in (phases as Array):
			_phase(v, w + "." + key + ".phases", pid, phase_ids)
	if p.has("flags"):
		var fl := JsonUtil.get_dict(p, "flags")
		_phase(v, w + ".flags.phase", fl.get("phase"), phase_ids)
		v.ref(w + ".flags.twisted_status", "statuses", fl.get("twisted_status"))


static func _phase(v: ValidatorBase, where: String, pid: Variant, phase_ids: Array) -> void:
	if pid == null or not phase_ids.has(str(pid)):
		v.err(where, "페이즈 '%s' 없음(이 몬스터의 phases)" % pid)


static func _text_key(v: ValidatorBase, where: String, key: Variant) -> void:
	if not key is String or str(key).is_empty():
		v.err(where, "비지 않은 문자열 키여야 한다")
