class_name GuildSettle
extends RefCounted
## 귀환 정산(사용자 2026-10-28, CT58): 미궁에서 살아 돌아오면 차원광장 정산 천막에서 탐험가 길드 직원이 신원패(이름·탐험가 등급)를 확인하고
## 가방의 마석(아이템 category magic_stone)을 등급별로 세어 스톤으로 바꿔 준다. 값 = 마석 price × city.json settle.ratio × 등급 bonus.
## 탐험가 등급(CT59): 처음 settle.grade(9). 정산 누계(Progression.settled_total)와 레벨이 settle.grades의 다음 등급 조건을 채우면
## 정산 자리에서 한 등급 오른다(한 번에 하나 — promote). 등급은 캐릭터 기록(Progression.explorer_grade)이라 저장된다.
## 순수 로직(오토로드 비의존) — 화면은 PlazaScreen(돌아오는 차원광장).


## 가방의 마석 묶음 [{id, grade, count, each}] — 등급 숫자가 큰 것(흔한 것)부터. each = 이 탐험가 등급의 한 개 값.
static func lots(db: GameDatabase, pc: PlayerCharacter) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var mult := float(_cfg(db).get("ratio", 1.0)) * bonus(db, pc)
	for id in pc.inventory.ids():
		var def := db.get_entry("items", id)
		if JsonUtil.get_str(def, "category") != "magic_stone":
			continue
		var n := pc.inventory.count(id)
		if n <= 0:
			continue
		out.append({"id": id, "grade": grade_of(def), "count": n, "each": roundi(JsonUtil.get_float(def, "price") * mult)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["grade"]) > int(b["grade"]))
	return out


## 정산한다: 마석을 빼고 스톤을 넣고 누계에 더한다. 받은 스톤.
static func settle(db: GameDatabase, pc: PlayerCharacter) -> int:
	var total := 0
	for lot in lots(db, pc):
		if pc.inventory.remove(str(lot["id"]), int(lot["count"])):
			total += int(lot["count"]) * int(lot["each"])
	pc.inventory.add_money(total)
	pc.progression.settled_total += total
	return total


## 지금 탐험가 등급.
static func explorer_grade(db: GameDatabase, pc: PlayerCharacter) -> int:
	return pc.progression.explorer_grade if pc.progression.explorer_grade > 0 else int(_cfg(db).get("grade", 9))


## 지금 등급의 정산 배율.
static func bonus(db: GameDatabase, pc: PlayerCharacter) -> float:
	return JsonUtil.get_float(_row(db, explorer_grade(db, pc)), "bonus", 1.0)


## 바로 위 등급 조건 {grade, settled, level, bonus}(이미 1등급이거나 표가 없으면 빈 것).
static func next_grade(db: GameDatabase, pc: PlayerCharacter) -> Dictionary:
	return _row(db, explorer_grade(db, pc) - 1)


## 조건이 차면 한 등급 올린다 — 오른 등급(오르지 않았으면 0).
static func promote(db: GameDatabase, pc: PlayerCharacter) -> int:
	var nxt := next_grade(db, pc)
	if nxt.is_empty() or pc.progression.settled_total < JsonUtil.get_int(nxt, "settled") or pc.get_level() < JsonUtil.get_int(nxt, "level"):
		return 0
	pc.progression.explorer_grade = JsonUtil.get_int(nxt, "grade")
	return pc.progression.explorer_grade


## 마석 등급: 아이템 grade, 없으면 id 끝 숫자(magic_stone_9 → 9).
static func grade_of(def: Dictionary) -> int:
	if def.has("grade"):
		return JsonUtil.get_int(def, "grade")
	var id := JsonUtil.get_str(def, "id")
	var tail := id.get_slice("_", id.get_slice_count("_") - 1)
	return tail.to_int() if tail.is_valid_int() else 0


static func _row(db: GameDatabase, grade: int) -> Dictionary:
	for r: Variant in JsonUtil.get_array(_cfg(db), "grades"):
		if r is Dictionary and JsonUtil.get_int(r, "grade") == grade:
			return r
	return {}


static func _cfg(db: GameDatabase) -> Dictionary:
	return JsonUtil.get_dict(db.singletons.get("city", {}), "settle")
