class_name BattleCoin
extends RefCounted
## 보스 동전 기술(사용자 2026-11-08 — C27): 예고 없이, 적이 그 스킬을 쓰는 순간 앞면 · 뒷면을 고르고 동전을 던진다.
## 스킬 JSON "coin": {"hit_mult": 0.0, "guarded_mult": 0.3}
##   맞힘 = 피해 × hit_mult(0이면 피함 — 화면에 '회피'), 틀림 = 그대로 맞는다. 방어 중이면 어느 쪽이든 × guarded_mult.
##   동전은 스킬 한 번에 하나(광역이면 모두 같은 결과). 적이 쓸 때만 — 우리 정수판(ess_*)은 "coin"이 없다.
## 화면(CombatScreen)은 act 전에 wants → 고르기 → roll → 동전 연출 → action["coin"] = roll 결과로 넘긴다.
## 받는 화면이 없으면(시뮬 · 테스트) Battle이 아무 면이나 골라 던진다. 앞면 확률 = balance coin.boss.heads.

const KIND := "boss"


static func spec(b: Battle, skill_id: String) -> Dictionary:
	return JsonUtil.get_dict(b.db.get_entry("skills", skill_id), "coin")


## 이 행동이 동전을 부르는가(적이 동전 스킬을 쓴다).
static func wants(b: Battle, c: Combatant, action: Dictionary) -> bool:
	if c == null or c.side == Combatant.SIDE_PARTY or str(action.get("kind", "")) != "skill":
		return false
	return not spec(b, str(action.get("skill", ""))).is_empty()


## 고른 면(guess: 0 앞면 · 1 뒷면)으로 던진다. 돌려주는 값 = {"guess", "heads", "right"}.
static func roll(b: Battle, guess: int) -> Dictionary:
	var heads := CoinToss.flip(b.db, b.rng, KIND)
	return {"guess": guess, "heads": heads, "right": heads == (guess == 0)}


## Battle._use_skill이 부른다: 동전 스킬이 아니면 {}. 화면이 던진 결과(given)가 없으면 여기서 고르고 던진다.
static func resolve(b: Battle, c: Combatant, skill_id: String, given: Dictionary) -> Dictionary:
	if not wants(b, c, {"kind": "skill", "skill": skill_id}):
		return {}
	var out := given.duplicate() if given.has("right") else roll(b, b.rng.randi_range(0, 1))
	out["spec"] = spec(b, skill_id)
	b.event.emit({"type": "coin", "unit": c, "heads": bool(out["heads"]), "right": bool(out["right"])})
	return out


## 대상 하나에 들어갈 효과: 맞혔으면 hit_mult(0 = 피함), 방어 중이면 guarded_mult를 피해에 곱한다.
static func effects_for(fx: Array, coin: Dictionary, t: Combatant) -> Array:
	var sp: Dictionary = coin.get("spec", {})
	var mult := 1.0
	if bool(coin.get("right", false)):
		var hit := JsonUtil.get_float(sp, "hit_mult", 0.0)
		if hit <= 0.0:
			return _dodged(fx)
		mult *= hit
	if t.actor.statuses.has("guarding"):
		mult *= JsonUtil.get_float(sp, "guarded_mult", 1.0)
	if mult >= 1.0:
		return fx
	return BattleTargets.boosted(fx, {"power_mult": mult, "ignore_defense": false})


## 피해 효과에 "dodged"를 단다 — damage가 빗나감으로 처리하고 뒤따르는 효과(상태 · 밀치기)도 걸리지 않는다.
static func _dodged(fx: Array) -> Array:
	var out: Array = []
	for e: Variant in fx:
		if e is Dictionary and JsonUtil.get_str(e, "type") == "damage":
			var d: Dictionary = (e as Dictionary).duplicate(true)
			d["dodged"] = true
			out.append(d)
		else:
			out.append(e)
	return out
