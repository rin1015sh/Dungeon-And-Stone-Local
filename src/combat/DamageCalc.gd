class_name DamageCalc
extends RefCounted
## 피해 공식(DESIGN §5, PROMPT §6.4). 계수는 balance.json combat.
##   공격력: 물리 = (주무기 공격력, 없으면 맨손 값) + 근력×계수, 마법 = 스킬 기본값 + 정신력×계수
##   피해 = 공격력 × 위력 × 100/(100+방어) × 상성(약점·면역) × 받는/주는 피해 수정자 × 편차 (치명타면 ×배율)
##   명중 = 기본 + (공격자 민첩 − 방어자 민첩)×계수 (약점 노리기면 ×배율), 치명타 = 기본 + 민첩×계수 + 행운×계수
##   치명상(급소): 치명타가 들어가 대상 생명력이 일정 비율 이하로 떨어지면 확률로 즉사 — 양쪽 모두, 끌 수 없다.
## 무작위 값은 rolls(0~1)로 받아서 순수 계산만 한다(테스트 가능).


## rolls: {"hit", "crit", "var", "lethal"} 각 0~1. 결과: hit, crit, lethal, weak, amount, damage_type, affinity
static func resolve(db: GameDatabase, attacker: Actor, defender: Actor, effect: Dictionary, rolls: Dictionary,
		aim_weak: bool = false) -> Dictionary:
	var dtype := JsonUtil.get_str(effect, "damage_type", "blunt")
	if dtype == "weapon":
		dtype = attacker.attack_damage_type()
	var category := damage_category(db, dtype)
	var weak := aim_weak and not defender.weak_point().is_empty()
	var out := {"hit": false, "crit": false, "lethal": false, "weak": weak, "amount": 0, "damage_type": dtype,
		"affinity": defender.damage_affinity(dtype, category)}
	if JsonUtil.get_float(rolls, "hit") >= hit_chance(db, attacker, defender, weak):
		return out
	out["hit"] = true
	var magic := JsonUtil.get_str(effect, "scaling", "phys") == "magic"
	var defense := defender.stats.get_value("m_res" if magic else "p_res")
	var k := _c(db, "defense_k", 100.0)
	var amount := attack_power(db, attacker, effect) * JsonUtil.get_float(effect, "power", 1.0) * k / (k + maxf(0.0, defense))
	amount *= float(out["affinity"])
	amount *= _modifier_mult(defender.stats, "dmg_taken", dtype, category)
	amount *= _modifier_mult(attacker.stats, "dmg_dealt", dtype, category)
	var variance := _c(db, "damage_variance", 0.1)
	amount *= 1.0 + (JsonUtil.get_float(rolls, "var", 0.5) * 2.0 - 1.0) * variance
	if weak:
		amount *= _c(db, "weak_point_damage_mult", 2.0)
	if JsonUtil.get_float(rolls, "crit", 1.0) < crit_chance(db, attacker):
		out["crit"] = true
		amount *= _c(db, "crit_mult", 1.5)
	var dealt := 0 if float(out["affinity"]) <= 0.0 else maxi(int(_c(db, "min_damage", 1.0)), roundi(amount))
	out["amount"] = dealt
	if bool(out["crit"]) and dealt > 0:
		var hp_after := defender.pool.get_current("hp") - dealt
		var max_hp := maxf(1.0, defender.pool.get_max("hp"))
		if hp_after > 0.0 and hp_after / max_hp <= _c(db, "lethal_hp_ratio", 0.3) \
				and JsonUtil.get_float(rolls, "lethal", 1.0) < _c(db, "lethal_chance_base", 0.1):
			out["lethal"] = true
	return out


static func attack_power(db: GameDatabase, attacker: Actor, effect: Dictionary) -> float:
	if JsonUtil.get_str(effect, "scaling", "phys") == "magic":
		return JsonUtil.get_float(effect, "base", 0.0) + attacker.stats.get_value("int") * _c(db, "mag_atk_per_int", 1.0)
	var weapon := attacker.weapon_attack()
	var base := weapon if weapon >= 0.0 else _c(db, "unarmed_atk", 2.0)
	return base + attacker.stats.get_value("str") * _c(db, "phys_atk_per_str", 1.0)


static func hit_chance(db: GameDatabase, attacker: Actor, defender: Actor, aim_weak: bool) -> float:
	var h := _c(db, "hit_base", 0.9) + (attacker.stats.get_value("agi") - defender.stats.get_value("agi")) * _c(db, "hit_agi_coef", 0.01)
	if aim_weak:
		h *= _c(db, "weak_point_hit_mult", 0.6)
	return clampf(h, _c(db, "hit_min", 0.3), _c(db, "hit_max", 0.98))


static func crit_chance(db: GameDatabase, attacker: Actor) -> float:
	var c := _c(db, "crit_base", 0.05) + attacker.stats.get_value("agi") * _c(db, "crit_per_agi", 0.005) \
		+ attacker.stats.get_value("luck") * _c(db, "crit_per_luck", 0.01)
	return clampf(c, 0.0, _c(db, "crit_max", 0.6))


## 피해 유형의 분류(physical / magical). tags.json damage_types.
static func damage_category(db: GameDatabase, dtype: String) -> String:
	for t: Variant in JsonUtil.get_array(db.tags, "damage_types"):
		if t is Dictionary and JsonUtil.get_str(t, "id") == dtype:
			return JsonUtil.get_str(t, "category", "physical")
	return "physical"


## "dmg_taken:<유형|분류|all>" 수정자를 곱으로 모은다.
static func _modifier_mult(stats: StatBlock, prefix: String, dtype: String, category: String) -> float:
	var m := 1.0
	for key: String in [dtype, category, "all"]:
		m *= stats.apply_modifiers(prefix + ":" + key, 1.0)
	return maxf(0.0, m)


static func _c(db: GameDatabase, key: String, fallback: float) -> float:
	return float(db.bal("combat." + key, fallback))
