extends EffectHandler
## 영혼 베기(본 나이트 증오, 명세 §9.3): {"type": "soul_slash", "base": 0.01, "per_level": 0.005, "ref_level": 8}
## 피해 없음. 확률 = base + (ref_level − 대상 레벨) × per_level(0 이상)로 대상 레벨이 하나 내려간다:
## 누적 경험치를 이전 레벨 문턱으로 내리고, 가진 정수가 새 슬롯 수보다 많으면 무작위 정수 하나가 **소실**된다.
## 공적(progression)이 있는 대상(탐험가)에게만. 정수판: {"soul_ratio": 0.3} — 레벨 대신 대상 영혼력 30% 소실.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.target
	if t == null or t.dead:
		return false
	if data.has("soul_ratio"):
		var lost := roundi(t.pool.get_current("soul") * JsonUtil.get_float(data, "soul_ratio"))
		t.pool.modify("soul", -float(lost), "soul_slash")
		ctx.say("combat.soul_slash_soul", {"name": t.display_name, "amount": lost}, "warn")
		return true
	var lv := t.get_level()
	var p := JsonUtil.get_float(data, "base", 0.01) + maxf(0.0, JsonUtil.get_float(data, "ref_level", 8.0) - lv) * JsonUtil.get_float(data, "per_level", 0.005)
	if not t is PlayerCharacter or lv <= 1 or not ctx.rng.chance(p):
		ctx.say("combat.soul_slash_miss", {"name": t.display_name}, "info")
		return true
	var pc := t as PlayerCharacter
	var drop := pc.progression.exp_total - Progression.exp_for_level(ctx.db, lv - 1)
	pc.progression.lose(pc, maxi(1, drop), ctx.rng)
	ctx.say("combat.soul_slash_level", {"name": t.display_name, "level": pc.get_level()}, "danger")
	var slots := Progression.essence_slots(ctx.db, pc.get_level())
	if pc.essences.absorbed.size() > slots:
		var i := ctx.rng.randi_range(0, pc.essences.absorbed.size() - 1)
		var gone := str(pc.essences.absorbed[i].get("essence", ""))
		pc.essences.remove(pc, i)
		ctx.say("combat.soul_slash_essence", {"name": t.display_name, "essence": DataNames.entry(ctx.db, "essences", gone)}, "danger")
	return true
