class_name Monster
extends Actor
## 몬스터 개체(data/monsters/<id>.json). 자원 최대치는 데이터의 고정값(resources)을 쓴다.
## 상성: immunities(피해 유형/분류 → 0배), weaknesses(피해 유형 → 배율).

var monster_id: String = ""
var def: Dictionary = {}


static func create(p_db: GameDatabase, p_monster_id: String, label: String = "") -> Monster:
	var d := p_db.get_entry("monsters", p_monster_id)
	var res := JsonUtil.get_dict(d, "resources")
	var m := Monster.new(p_db, JsonUtil.get_dict(d, "stats"), 1, res.keys(), res)
	m.monster_id = p_monster_id
	m.def = d
	m.id = p_monster_id
	m.display_name = JsonUtil.get_str(d, "name_ko", p_monster_id) + label
	for s: Variant in JsonUtil.get_array(d, "skills"):
		m.skills.append(str(s))
	return m


func damage_affinity(damage_type: String, category: String) -> float:
	for im: Variant in JsonUtil.get_array(def, "immunities"):
		if str(im) == damage_type or str(im) == category or str(im) == "all":
			return 0.0
	return JsonUtil.get_float(JsonUtil.get_dict(def, "weaknesses"), damage_type, 1.0)


## 마수는 말이 통하지 않는다. 데이터 "talk": {"understands": true}인 몬스터만 통한다(현재 없음).
func understands_speech() -> bool:
	return JsonUtil.get_bool(JsonUtil.get_dict(def, "talk"), "understands")


func base_attack_type() -> String:
	return "blunt"


func weak_point() -> Dictionary:
	return JsonUtil.get_dict(def, "weak_point")


func behavior() -> Dictionary:
	return JsonUtil.get_dict(def, "behavior")
