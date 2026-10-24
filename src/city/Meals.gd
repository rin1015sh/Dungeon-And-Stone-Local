class_name Meals
extends RefCounted
## 여관 식사(사용자 결정 2026-10-23 "식사 = 정보가 아니라 음식을 먹고 미궁에서 잠깐 받는 버프, 그럴듯한 이름의 랜덤 요리"):
## 요리(data/meals.json) 하나 = 버프 상태 하나("meal_<id>" — 로드 때 MealForge가 만든다).
## 지속 = duration {amount, unit: battle(전투 수 — 전투가 끝날 때마다 하나) | hour(미궁 시간 — 도시에선 흐르지 않는다)}.
## 한 번에 한 요리만(새로 먹으면 앞의 것은 사라진다 — 두 번 먹으면 마지막 것만), 원정에서 돌아오면 남은 것도 사라진다(clear).
## 차림표 = 값대(CT48): plain 요기(버프 없음 — 피로만, 걸린 요리 효과는 그대로) · light 식사(미궁 12시간 소소한 내성·시야) ·
## hearty 든든한 식사(전투 3번 능력치·도주·치명 …) · special 특식(전투 4번·24시간 두 가지). 값·피로는 활동 JSON(inn_snack·inn_meal·inn_hearty·inn_feast).
## 오토로드를 참조하지 않는다.

const PREFIX := MealForge.PREFIX

## 디버그·캡처: 비어 있지 않으면 차림표와 상관없이 이 요리를 낸다(screenshot --meal_pick).
static var force_pick: String = ""


## 차림표(menu)에서 무게대로 하나 고른다. 없으면 "".
static func pick(db: GameDatabase, menu: String, rng: Rng) -> String:
	if not force_pick.is_empty() and db.has_entry("meals", force_pick):
		return force_pick
	var ids: Array[String] = []
	for id: String in db.get_collection("meals"):
		if JsonUtil.get_str(db.get_entry("meals", id), "menu") == menu:
			ids.append(id)
	if ids.is_empty():
		return ""
	ids.sort()
	var w: Array = ids.map(func(id: String) -> float: return maxf(0.0, JsonUtil.get_float(db.get_entry("meals", id), "weight", 1.0)))
	var i := rng.weighted_index(w)
	return ids[i] if i >= 0 else ""


## 먹는다: 앞의 식사 효과를 지우고 이 요리의 효과를 건다. 버프 없는 요기(상태가 없는 요리)는 앞의 효과를 건드리지 않는다.
static func eat(a: Actor, meal_id: String) -> bool:
	if not a.db.has_entry("statuses", PREFIX + meal_id):
		return a.db.has_entry("meals", meal_id)
	clear(a)
	return a.statuses.apply(PREFIX + meal_id)


## 걸린 식사 효과(상태 id). 없으면 "".
static func current(a: Actor) -> String:
	for id in a.statuses.ids():
		if id.begins_with(PREFIX):
			return id
	return ""


static func clear(a: Actor) -> void:
	for id in a.statuses.ids():
		if id.begins_with(PREFIX):
			a.statuses.remove(id)
