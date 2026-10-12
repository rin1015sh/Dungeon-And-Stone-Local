class_name Lineage
extends RefCounted
## 몬스터 계열(명세 §6.0): 원종과 변이종(variant_of)은 같은 lineage를 갖고, 같은 스킬 id를 쓰면 이능을 공유한다.
## 공유 이능이 있는 종끼리는 정수의 중복 규칙 때문에 같은 이능의 정수를 함께 흡수할 수 없다(EssenceSet).


## monster_id와 스킬을 하나라도 공유하는 다른 몬스터: {스킬 id: [몬스터 id…]}.
static func shared_skills(db: GameDatabase, monster_id: String) -> Dictionary:
	var mine := JsonUtil.get_array(db.get_entry("monsters", monster_id), "skills")
	var out := {}
	var ids: Array = db.get_collection("monsters").keys()
	ids.sort()
	for other: Variant in ids:
		if str(other) == monster_id:
			continue
		for s: Variant in JsonUtil.get_array(db.get_entry("monsters", str(other)), "skills"):
			if mine.has(s) and str(s) != "flee":
				if not out.has(s):
					out[s] = []
				(out[s] as Array).append(str(other))
	return out
