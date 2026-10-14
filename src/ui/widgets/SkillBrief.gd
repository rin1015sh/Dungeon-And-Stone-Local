class_name SkillBrief
extends RefCounted
## 스킬 한 줄 설명(행동창 설명줄용). desc_ko가 있으면 앞에 두고, 데이터에서 대상 · 피해 유형 · 거는 상태 · 재사용을 뽑아 잇는다.
## 정수판 스킬처럼 desc_ko가 없는 스킬도 무엇을 하는지 알 수 있게 한다.


static func describe(db: GameDatabase, sk: Dictionary) -> String:
	var parts := PackedStringArray()
	var kind := JsonUtil.get_str(sk, "target")
	if not kind.is_empty():
		parts.append(Strings.t("target_kind." + kind))
	for e: Variant in JsonUtil.get_array(sk, "effects"):
		var phrase := _effect(db, e if e is Dictionary else {})
		if not phrase.is_empty() and not parts.has(phrase):
			parts.append(phrase)
	var cd := JsonUtil.get_int(sk, "cooldown")
	if cd > 0:
		parts.append(Strings.t("combat.brief_cooldown", {"n": cd}))
	var meta := " · ".join(parts)
	var desc := JsonUtil.get_str(sk, "desc_ko")
	return meta if desc.is_empty() else desc + "\n" + meta


static func _effect(db: GameDatabase, e: Dictionary) -> String:
	match JsonUtil.get_str(e, "type"):
		"damage":
			return Strings.t("combat.brief_damage", {"type": DataNames.tag(db, "damage_types", JsonUtil.get_str(e, "damage_type", "blunt"))})
		"apply_status":
			return Strings.t("combat.brief_status", {"status": DataNames.entry(db, "statuses", JsonUtil.get_str(e, "status"))})
		"barrier":
			return Strings.t("combat.brief_barrier")
		"restore_resource":
			if str(e.get("amount", 0)).begins_with("-"):
				return ""  # 대가로 깎는 것(정수판 분열)은 회복이 아니다
			var res := JsonUtil.get_str(e, "resource")
			var rd: ResourceDef = db.resources.get(res)
			return Strings.t("combat.brief_restore", {"res": rd.name_ko if rd != null else res})
		"summon":
			return Strings.t("combat.brief_summon")
		"delayed":
			return Strings.t("combat.brief_delayed")
		"remove_status":
			return Strings.t("combat.brief_cleanse")
	return ""
