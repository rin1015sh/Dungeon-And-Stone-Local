class_name MealForge
extends RefCounted
## 여관 요리(data/meals.json) → 버프 상태 "meal_<id>"(Meals). 상태 키를 그대로 쓴다(modifiers · flee_bonus · crit_bonus · hit_taken ·
## lifesteal · heal_mult · duration …) — kind buff, "meal": 요리 id. GameDatabase.load_all이 데이터를 읽은 직후 한 번 부른다
## (원본 사전만 다룬다 — Actor·GameDatabase를 참조하지 않는다).

const PREFIX := "meal_"
const _MENU_KEYS := ["menu", "weight"]


## 요리를 상태 모음에 넣는다(GameDatabase.load_all이 데이터를 읽은 직후).
static func forge_all(cols: Dictionary) -> void:
	var meals: Dictionary = cols.get("meals", {})
	var statuses: Dictionary = cols.get("statuses", {})
	for id: String in meals:
		if not (meals[id] as Dictionary).has("duration"):
			continue  # 요기(menu plain) — 배만 채운다, 버프 없음
		var st: Dictionary = (meals[id] as Dictionary).duplicate(true)
		for k: String in _MENU_KEYS:
			st.erase(k)
		st["id"] = PREFIX + id
		st["kind"] = "buff"
		st["meal"] = id
		statuses[PREFIX + id] = st
