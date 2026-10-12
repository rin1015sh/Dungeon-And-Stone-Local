class_name DamageCalc
extends RefCounted
## 피해 공식(docs/PROMPT_FLOOR1_V2.md §1). 계수는 balance.json combat.
##   공격력: 물리 = (무기 공격력 — 몬스터는 natural_weapon, 없으면 맨손 값) + 근력×2, 마법 = 스킬 기본값(base) + 정신력×2
##   피해 = 공격력 × 위력 × 100/(100 + 방어×4) × 상성(약점·면역) × 받는/주는 피해 수정자 × 조건부 위력 × 편차 (치명타면 ×1.5)
##   명중 = (스킬 명중 accuracy, 기본 95 + 명중률 스탯) × (1 + (공격 민첩 − 대상 민첩)×0.005), 30~100%로 제한(약점 노리기 ×배율)
##   치명타 = 5% + 민첩×0.3% + 행운×계수 + 스킬 crit_bonus + 패시브 crit_bonus
##   조건부 위력: 효과 "power_if_status": {"status": [..], "power": 1.5} — 대상이 그 상태면 위력을 바꾼다.
##   패시브 power_vs_status {"status", "mult"}: 그 상태의 대상에게 피해 배율.
##   "ignore_defense": true면 방어 계수를 1로 본다(배신의 장막 오인 공격). "defense_ignore": 0.2면 방어의 20%를 무시.
##   속성 내성·감응도(G6): 피해 유형 x에 대상 resist_x 1점당 −element_resist_per_point(최대 element_resist_max), 공격자 affinity_x 1점당 +affinity_per_point.
##   "str_bonus": k — 물리 공격력에 근력×k를 더한다(키르뒤 휘두르기). 공격자 상태의 crit_bonus도 치명타율에 더한다(샤벨 타이거 기습).
##   약점: 몬스터 weak_point {name_ko, multiplier(없으면 combat.weak_point_damage_mult), ignore_reduction, requires_status}.
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
	if JsonUtil.get_float(rolls, "hit") >= hit_chance(db, attacker, defender, weak, JsonUtil.get_float(effect, "accuracy", -1.0)):
		return out
	out["hit"] = true
	var magic := JsonUtil.get_str(effect, "scaling", "phys") == "magic"
	var defense := 0.0 if JsonUtil.get_bool(effect, "ignore_defense") else defender.stats.get_value("m_res" if magic else "p_res")
	defense *= 1.0 - clampf(JsonUtil.get_float(effect, "defense_ignore"), 0.0, 1.0)  # 방어 일부 무시(송곳니 관통 0.2)
	var k := _c(db, "defense_k", 100.0)
	var amount := attack_power(db, attacker, effect) * _power(effect, defender) * k \
		/ (k + maxf(0.0, defense) * _c(db, "defense_per_point", 4.0))
	amount *= Passives.damage_mult_vs(attacker, defender)
	amount *= float(out["affinity"])
	# 약점(weak_point)을 노려 성공하면 "ignore_reduction": true인 몬스터는 받는 피해 감소를 무시한다(스켈레톤 핵).
	var wp := defender.weak_point()
	var taken := _modifier_mult(defender.stats, "dmg_taken", dtype, category)
	amount *= maxf(1.0, taken) if weak and JsonUtil.get_bool(wp, "ignore_reduction") else taken
	amount *= _modifier_mult(attacker.stats, "dmg_dealt", dtype, category)
	amount *= element_mult(db, attacker, defender, dtype)
	var variance := _c(db, "damage_variance", 0.1)
	amount *= 1.0 + (JsonUtil.get_float(rolls, "var", 0.5) * 2.0 - 1.0) * variance
	if weak:
		amount *= JsonUtil.get_float(wp, "multiplier", _c(db, "weak_point_damage_mult", 2.0))
	if JsonUtil.get_float(rolls, "crit", 1.0) < crit_chance(db, attacker, Passives.crit_bonus(attacker, dtype) + JsonUtil.get_float(effect, "crit_bonus")
			+ attacker.statuses.sum_key("crit_bonus")):
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
	return base + attacker.stats.get_value("str") * (_c(db, "phys_atk_per_str", 1.0) + JsonUtil.get_float(effect, "str_bonus"))


## accuracy: 스킬 명중(퍼센트, 음수면 기본값). 명중률 스탯(accuracy)이 더해진다(실명은 이것을 깎는다).
static func hit_chance(db: GameDatabase, attacker: Actor, defender: Actor, aim_weak: bool, accuracy: float = -1.0) -> float:
	var acc := (accuracy if accuracy >= 0.0 else _c(db, "default_accuracy", 95.0)) + attacker.stats.get_value("accuracy")
	var h := acc / 100.0 * (1.0 + (attacker.stats.get_value("agi") - defender.stats.get_value("agi")) * _c(db, "hit_agi_coef", 0.005))
	if aim_weak:
		h *= _c(db, "weak_point_hit_mult", 0.6)
	return clampf(h, _c(db, "hit_min", 0.3), _c(db, "hit_max", 1.0))


static func crit_chance(db: GameDatabase, attacker: Actor, bonus: float = 0.0) -> float:
	var c := _c(db, "crit_base", 0.05) + attacker.stats.get_value("agi") * _c(db, "crit_per_agi", 0.003) \
		+ attacker.stats.get_value("luck") * _c(db, "crit_per_luck", 0.01) + bonus
	return clampf(c, 0.0, _c(db, "crit_max", 0.6))


## 속성 내성(대상 resist_<유형>)·감응도(공격자 affinity_<유형>) 배율. 그 스탯이 없는 유형(베기 등)은 1.
static func element_mult(db: GameDatabase, attacker: Actor, defender: Actor, dtype: String) -> float:
	var m := 1.0
	if defender.stats.has_stat("resist_" + dtype):
		m *= 1.0 - minf(_c(db, "element_resist_max", 0.75), maxf(0.0, defender.stats.get_value("resist_" + dtype)) * _c(db, "element_resist_per_point", 0.01))
	if attacker != null and attacker.stats.has_stat("affinity_" + dtype):
		m *= 1.0 + maxf(0.0, attacker.stats.get_value("affinity_" + dtype)) * _c(db, "affinity_per_point", 0.02)
	return m


## 추가 속성 피해(냉기 몽둥이 등): base만큼을 그 유형으로 — 대상 상성·받는 피해 수정자·내성·감응도를 따른다(방어·명중 없음).
static func rider(db: GameDatabase, attacker: Actor, defender: Actor, dtype: String, base: float) -> int:
	var category := damage_category(db, dtype)
	var amount := base * defender.damage_affinity(dtype, category) * _modifier_mult(defender.stats, "dmg_taken", dtype, category) \
		* _modifier_mult(attacker.stats, "dmg_dealt", dtype, category) * element_mult(db, attacker, defender, dtype)
	return maxi(0, roundi(amount))


## 위력: 대상이 power_if_status의 상태 중 하나면 그 위력, 아니면 power.
static func _power(effect: Dictionary, defender: Actor) -> float:
	var cond := JsonUtil.get_dict(effect, "power_if_status")
	if not cond.is_empty():
		for st: Variant in JsonUtil.get_array(cond, "status"):
			if defender.statuses.has(str(st)):
				return JsonUtil.get_float(cond, "power", 1.0)
	return JsonUtil.get_float(effect, "power", 1.0)


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
