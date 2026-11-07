class_name EssenceLinks
extends RefCounted
## 정수 연계(정수 시너지 ES1~ — docs/plans/essence_synergy.md): "거는 쪽 ↔ 반응하는 쪽"을 데이터에서 읽는다(오토로드 비의존).
##   거는 쪽  = 액티브가 거는 상태(apply_status — 예고 안 포함, 자기에게 거는 것도: 철벽 · 끌어들이기 · 은신 …) · 패시브 on_hit · reflect_status
##   반응 쪽  = 패시브 power_vs_status · hit_vs_status · counter_while · skip_bonus_vs · while_self_status,
##              액티브 power_if_status · consume_status · mult_if_status · if_target_status
##   상태가 다시 적중 효과로 상태를 거는 것(독성부여 → 독)도 따라간다. 적중 조건 "@ranged"(원거리 적중 — 원거리 피해 스킬 ↔ 패시브
##   on_hit_filter.ranged true: 투석병 연타 ↔ 독화살)도 연계로 본다.
## 연계 = 한 정수가 거는 상태에 다른 정수가 반응한다. 화면(Tab 정수 · 정수 획득 창)과 테스트(새 정수도 연계를 갖는지)가 같이 쓴다.

const PASSIVE_REACT_KEYS := ["power_vs_status", "hit_vs_status", "counter_while", "skip_bonus_vs", "while_self_status"]
const RANGED := "@ranged"  ## 적중 조건 — 원거리 피해


static func _ids(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for x: Variant in v:
			out.append(str(x))
	elif v != null and str(v) != "":
		out.append(str(v))
	return out


static func _effects_apply(fx: Array, out: Array[String]) -> void:
	for v: Variant in fx:
		var e: Dictionary = v if v is Dictionary else {}
		match JsonUtil.get_str(e, "type"):
			"apply_status":
				for s in _ids(e.get("status")):
					if not out.has(s):
						out.append(s)
			"delayed":
				_effects_apply(JsonUtil.get_array(e, "effects"), out)


static func _effects_react(fx: Array, out: Array[String]) -> void:
	for v: Variant in fx:
		var e: Dictionary = v if v is Dictionary else {}
		for key: String in ["power_if_status", "mult_if_status"]:
			if e.has(key):
				for s in _ids(JsonUtil.get_dict(e, key).get("status")):
					if not out.has(s):
						out.append(s)
		if JsonUtil.get_str(e, "type") == "consume_status" or e.has("if_target_status"):
			for s in _ids(e.get("status") if JsonUtil.get_str(e, "type") == "consume_status" else e.get("if_target_status")):
				if not out.has(s):
					out.append(s)
		if JsonUtil.get_str(e, "type") == "delayed":
			_effects_react(JsonUtil.get_array(e, "effects"), out)


static func skill_applies(db: GameDatabase, sid: String) -> Array[String]:
	var out: Array[String] = []
	var fx := JsonUtil.get_array(db.get_entry("skills", sid), "effects")
	_effects_apply(fx, out)
	_expand(db, out)
	for v: Variant in fx:
		if v is Dictionary and JsonUtil.get_str(v, "type") == "damage" and JsonUtil.get_bool(v, "ranged") and not out.has(RANGED):
			out.append(RANGED)
	return out


## 상태가 이어 거는 상태도 넣는다: 적중 효과(독성부여 → 독) · 최대 중첩에서 바뀜(서리 3 → 빙결).
static func _expand(db: GameDatabase, out: Array[String]) -> void:
	for s in out.duplicate():
		var def := db.get_entry("statuses", s)
		_effects_apply(JsonUtil.get_array(def, "on_hit"), out)
		var conv := JsonUtil.get_str(JsonUtil.get_dict(def, "on_max_stacks"), "status")
		if not conv.is_empty() and not out.has(conv):
			out.append(conv)


static func skill_reacts(db: GameDatabase, sid: String) -> Array[String]:
	var out: Array[String] = []
	_effects_react(JsonUtil.get_array(db.get_entry("skills", sid), "effects"), out)
	return out


static func passive_applies(p: Dictionary, db: GameDatabase = null) -> Array[String]:
	var out: Array[String] = []
	_effects_apply(JsonUtil.get_array(p, "on_hit"), out)
	_effects_apply(JsonUtil.get_array(p, "on_crit"), out)
	var rs := JsonUtil.get_str(JsonUtil.get_dict(p, "reflect_status"), "status")
	if not rs.is_empty() and not out.has(rs):
		out.append(rs)
	if db != null:
		_expand(db, out)
	return out


static func passive_reacts(p: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if JsonUtil.get_bool(JsonUtil.get_dict(p, "on_hit_filter"), "ranged") and not JsonUtil.get_array(p, "on_hit").is_empty():
		out.append(RANGED)
	for key: String in PASSIVE_REACT_KEYS:
		var s := JsonUtil.get_str(JsonUtil.get_dict(p, key), "status")
		if not s.is_empty() and not out.has(s):
			out.append(s)
	return out


## 정수 사례(색 → 받는 액티브)의 거는 · 반응 상태와 그 출처 이름. {"applies": {상태: [이름]}, "reacts": {상태: [이름]}}
static func of_instance(db: GameDatabase, inst: Dictionary) -> Dictionary:
	var def := db.get_entry("essences", JsonUtil.get_str(inst, "essence"))
	var p := JsonUtil.get_dict(def, "passive")
	var app := {}
	var rea := {}
	var pname := JsonUtil.get_str(p, "name_ko")
	for s in passive_applies(p, db):
		_add(app, s, pname)
	for s in passive_reacts(p):
		_add(rea, s, pname)
	for sid: String in EssenceSet.granted_skills(db, inst):
		var n := DataNames.entry(db, "skills", sid)
		for s in skill_applies(db, sid):
			_add(app, s, n)
		for s in skill_reacts(db, sid):
			_add(rea, s, n)
	return {"applies": app, "reacts": rea}


static func _add(d: Dictionary, k: String, name: String) -> void:
	if not d.has(k):
		d[k] = []
	if not (d[k] as Array).has(name):
		(d[k] as Array).append(name)


## inst와 held(가진 정수들 — 잠긴 것 · inst 자신은 뺀다) 사이의 연계 [{status, from, to}](양쪽 방향, 상태마다 한 줄).
static func links(db: GameDatabase, inst: Dictionary, held: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var me := of_instance(db, inst)
	var seen := {}
	for h in held:
		if EssenceSet.is_locked(h) or h == inst or JsonUtil.get_str(h, "essence") == JsonUtil.get_str(inst, "essence"):
			continue
		var other := of_instance(db, h)
		for pair: Array in [[me, other], [other, me]]:
			var giver: Dictionary = pair[0]["applies"]
			var taker: Dictionary = pair[1]["reacts"]
			for s: String in giver:
				if taker.has(s) and not seen.has(s + str(pair[0] == me)):
					seen[s + str(pair[0] == me)] = true
					out.append({"status": s, "from": str((giver[s] as Array)[0]), "to": str((taker[s] as Array)[0])})
	return out


## 패시브 반응 효과를 짧게(이름 · 수치 · 상태만 — 부연설명 금지): ["기절 대상 ×1.25", "철벽 중 반격 0.5", …]. 문구는 ko.json essence.react_*.
static func passive_brief(db: GameDatabase, p: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var nm := func(s: String) -> String: return DataNames.entry(db, "statuses", s)
	var pv := JsonUtil.get_dict(p, "power_vs_status")
	if not pv.is_empty():
		out.append(Strings.t("essence.react_power", {"status": nm.call(JsonUtil.get_str(pv, "status")), "mult": "%.2f" % JsonUtil.get_float(pv, "mult", 1.0)}))
	var hv := JsonUtil.get_dict(p, "hit_vs_status")
	if not hv.is_empty():
		out.append(Strings.t("essence.react_hit", {"status": nm.call(JsonUtil.get_str(hv, "status")), "n": int(JsonUtil.get_float(hv, "bonus"))}))
	var cw := JsonUtil.get_dict(p, "counter_while")
	if not cw.is_empty():
		out.append(Strings.t("essence.react_counter", {"status": nm.call(JsonUtil.get_str(cw, "status")), "power": "%.1f" % JsonUtil.get_float(cw, "power")}))
	var sk := JsonUtil.get_dict(p, "skip_bonus_vs")
	if not sk.is_empty():
		out.append(Strings.t("essence.react_skip", {"status": nm.call(JsonUtil.get_str(sk, "status")), "pct": roundi(JsonUtil.get_float(sk, "bonus") * 100.0)}))
	var ws := JsonUtil.get_dict(p, "while_self_status")
	if not ws.is_empty():
		out.append(Strings.t("essence.react_self", {"status": nm.call(JsonUtil.get_str(ws, "status")), "pct": roundi(JsonUtil.get_float(ws, "crit_bonus") * 100.0)}))
	for v: Variant in JsonUtil.get_array(p, "on_kill"):
		if v is Dictionary and JsonUtil.get_str(v, "type") == "gauge":
			out.append(Strings.t("essence.react_kill_gauge", {"n": int(JsonUtil.get_float(v, "amount"))}))
	return out
