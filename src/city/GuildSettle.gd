class_name GuildSettle
extends RefCounted
## 귀환 정산(사용자 2026-10-28, CT58): 미궁에서 살아 돌아오면 차원광장에서 탐험가 길드 직원이 신원패(이름·탐험가 등급)를 확인하고
## 가방의 마석(아이템 category magic_stone)을 등급별로 세어 스톤으로 바꿔 준다. 값 = 마석 price × city.json settle.ratio.
## 순수 로직(오토로드 비의존) — 화면은 PlazaScreen(돌아오는 차원광장).


## 가방의 마석 묶음 [{id, grade, count, each}] — 등급 숫자가 큰 것(흔한 것)부터.
static func lots(db: GameDatabase, inv: Inventory) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ratio := float(_cfg(db).get("ratio", 1.0))
	for id in inv.ids():
		var def := db.get_entry("items", id)
		if JsonUtil.get_str(def, "category") != "magic_stone":
			continue
		var n := inv.count(id)
		if n <= 0:
			continue
		out.append({"id": id, "grade": grade_of(def), "count": n, "each": roundi(JsonUtil.get_float(def, "price") * ratio)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["grade"]) > int(b["grade"]))
	return out


## 정산한다: 마석을 빼고 스톤을 넣는다. 받은 스톤.
static func settle(db: GameDatabase, inv: Inventory) -> int:
	var total := 0
	for lot in lots(db, inv):
		if inv.remove(str(lot["id"]), int(lot["count"])):
			total += int(lot["count"]) * int(lot["each"])
	inv.add_money(total)
	return total


## 탐험가 등급(지금은 모두 settle.grade — 등급 올리기는 기획 대기).
static func explorer_grade(db: GameDatabase) -> int:
	return int(_cfg(db).get("grade", 9))


## 마석 등급: 아이템 grade, 없으면 id 끝 숫자(magic_stone_9 → 9).
static func grade_of(def: Dictionary) -> int:
	if def.has("grade"):
		return JsonUtil.get_int(def, "grade")
	var id := JsonUtil.get_str(def, "id")
	var tail := id.get_slice("_", id.get_slice_count("_") - 1)
	return tail.to_int() if tail.is_valid_int() else 0


static func _cfg(db: GameDatabase) -> Dictionary:
	return JsonUtil.get_dict(db.singletons.get("city", {}), "settle")
