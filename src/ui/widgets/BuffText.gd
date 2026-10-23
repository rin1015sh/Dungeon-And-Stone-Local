class_name BuffText
extends RefCounted
## 상태 효과를 짧은 수치 줄로("근력 +10%", "도주 확률 +30%p", "받는 물리 피해 −10%") + 남은 지속("전투 3번", "12시간").
## 캐릭터 쪽 "걸린 상태"에서 여관 식사(Meals)를 보일 때 쓴다 — 이름·수치·상태만(설명 문장 없음).


## 효과 줄 목록.
static func effects(db: GameDatabase, status_id: String) -> PackedStringArray:
	var d := db.get_entry("statuses", status_id)
	var out := PackedStringArray()
	for m: Variant in JsonUtil.get_array(d, "modifiers"):
		var md: Dictionary = m if m is Dictionary else {}
		var flat := JsonUtil.get_float(md, "flat")
		var v := _signed(flat) if not is_zero_approx(flat) else _signed(JsonUtil.get_float(md, "percent") * 100.0) + "%"
		out.append("%s %s" % [_target(db, JsonUtil.get_str(md, "target")), v])
	for key: String in ["flee_bonus", "crit_bonus"]:
		if d.has(key):
			out.append(Strings.t("buff." + key, {"v": _signed(JsonUtil.get_float(d, key) * 100.0) + "%p"}))
	if d.has("hit_taken"):
		out.append(Strings.t("buff.hit_taken", {"v": _signed(JsonUtil.get_float(d, "hit_taken")) + "%p"}))
	if d.has("lifesteal"):
		out.append(Strings.t("buff.lifesteal", {"v": "%d%%" % roundi(JsonUtil.get_float(d, "lifesteal") * 100.0)}))
	if d.has("heal_mult"):
		out.append(Strings.t("buff.heal_mult", {"v": _signed((JsonUtil.get_float(d, "heal_mult", 1.0) - 1.0) * 100.0) + "%"}))
	return out


## 남은 지속: "전투 3번" / "12시간"(영구·없음이면 "").
static func left(a: Actor, status_id: String) -> String:
	var r := a.statuses.remaining(status_id)
	if r.is_empty() or float(r[0]) < 0.0:
		return ""
	return Strings.t("buff.left_" + str(r[1]), {"n": UiTheme.num(snappedf(float(r[0]), 0.1))})


## 한 줄: "오징어다리 먹물 튀김 (도주 확률 +30%p · 전투 3번)".
static func line(a: Actor, status_id: String) -> String:
	var parts := effects(a.db, status_id)
	var l := left(a, status_id)
	if not l.is_empty():
		parts.append(l)
	return Strings.t("buff.line", {"name": DataNames.entry(a.db, "statuses", status_id), "parts": " · ".join(parts)})


static func _target(db: GameDatabase, target: String) -> String:
	for k: String in ["dmg_taken", "dmg_dealt"]:
		if target.begins_with(k + ":"):
			var t := target.substr(k.length() + 1)
			if t == "all":
				return Strings.t("buff.%s_all" % k)
			var name := Strings.t("buff.cat_" + t) if t in ["physical", "magical"] else DataNames.tag(db, "damage_types", t)
			return Strings.t("buff." + k, {"type": name})
	return ItemTooltip.target_name(db, target)


static func _signed(v: float) -> String:
	var n := UiTheme.num(snappedf(absf(v), 0.1))
	return ("+" if v >= 0.0 else "−") + n
