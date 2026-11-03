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
	for p: Variant in JsonUtil.get_array(d, "passives"):
		if p is Dictionary:
			m.add_passive(p)
			m.stats.add_modifiers_from_data("passive:" + JsonUtil.get_str(p, "id"), JsonUtil.get_array(p, "modifiers"))
	return m


## 몬스터는 비율 지속 피해를 줄여 받는다(보스 생명력이 수천 — balance status.monster_dot_scale).
func _hp_ratio_dot_scale() -> float:
	return float(db.bal("status.monster_dot_scale", 0.25))


func damage_affinity(damage_type: String, category: String) -> float:
	for im: Variant in JsonUtil.get_array(def, "immunities"):
		if str(im) == damage_type or str(im) == category or str(im) == "all":
			return 0.0
	return JsonUtil.get_float(JsonUtil.get_dict(def, "weaknesses"), damage_type, 1.0)


## 마수는 말이 통하지 않는다. 데이터 "talk": {"understands": true}인 몬스터만 통한다(현재 없음).
func understands_speech() -> bool:
	return JsonUtil.get_bool(JsonUtil.get_dict(def, "talk"), "understands")


## 기본 공격: natural_weapon {attack, damage_type, ranged}(명세 §1 "몬스터는 natural_weapon").
func base_attack_type() -> String:
	return JsonUtil.get_str(JsonUtil.get_dict(def, "natural_weapon"), "damage_type", "blunt")


func attack_damage_type() -> String:
	return base_attack_type()


func weapon_attack() -> float:
	var w := JsonUtil.get_dict(def, "natural_weapon")
	return JsonUtil.get_float(w, "attack", -1.0) if not w.is_empty() else -1.0


func magic_power() -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(def, "natural_weapon"), "magic", 0.0)


func weapon_is_ranged() -> bool:
	return JsonUtil.get_bool(JsonUtil.get_dict(def, "natural_weapon"), "ranged")


## 계열(도감 묶음·공유 이능 안내). 데이터 lineage, 없으면 자기 id.
func lineage() -> String:
	return JsonUtil.get_str(def, "lineage", monster_id)


func behavior() -> Dictionary:
	return JsonUtil.get_dict(def, "behavior")
