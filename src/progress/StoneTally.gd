class_name StoneTally
extends RefCounted
## 전투 뒤 마석 획득 문구를 한 줄로 모은다(사용자 2026-11-01 "마석 획득할 때 문장 하나하나 띄우지 말고 n등급 마석 x개를 획득했다로 —
## 한 전투에서 다른 등급 마석을 여러 개 얻는 경우도"): 한 등급이면 item.got(_n) "9등급 마석 3개를 얻었다.",
## 여러 등급이면 item.got_list "8등급 마석 1개, 9등급 마석 3개를 얻었다."(높은 등급부터 — 등급 숫자가 작은 쪽).
## tally = {아이템 id: 개수}.


static func is_stone(db: GameDatabase, id: String) -> bool:
	return JsonUtil.get_str(db.get_entry("items", id), "category") == "magic_stone"


## 한 줄 안내 {key, args, kind}. tally가 비었으면 {}.
static func message(db: GameDatabase, tally: Dictionary) -> Dictionary:
	var ids: Array[String] = []
	for id: String in tally:
		if int(tally[id]) > 0:
			ids.append(id)
	if ids.is_empty():
		return {}
	ids.sort_custom(func(a: String, b: String) -> bool: return _grade(db, a) < _grade(db, b))
	if ids.size() == 1:
		var n := int(tally[ids[0]])
		return {"key": ItemInfo.got_key(n), "args": {"item": DataNames.entry(db, "items", ids[0]), "n": n}, "kind": "good"}
	var parts: PackedStringArray = []
	for id in ids:
		parts.append(Strings.t("item.count_of", {"item": DataNames.entry(db, "items", id), "n": int(tally[id])}))
	return {"key": "item.got_list", "args": {"items": Strings.t("item.list_sep").join(parts)}, "kind": "good"}


static func _grade(db: GameDatabase, id: String) -> int:
	var digits := id.get_slice("_", id.get_slice_count("_") - 1)
	return int(digits) if digits.is_valid_int() else JsonUtil.get_int(db.get_entry("items", id), "grade", 99)
