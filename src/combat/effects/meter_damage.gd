extends EffectHandler
## 게이지 비례 고정 피해(내면의 거울): {"type": "meter_damage", "meter": "dread_fear", "mult": 2.0}
## 피해 = 대상 게이지 × mult. 명중·방어·피해 수정자를 무시한다(회피·방어 불가). 게이지가 0이면 아무 일도 없다.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.target
	if t == null or t.dead or ctx.source == null:
		return false
	var amount := roundi(Meters.value(t, JsonUtil.get_str(data, "meter")) * JsonUtil.get_float(data, "mult", 1.0))
	var args := {"source": ctx.source.display_name, "target": t.display_name, "amount": amount}
	if amount <= 0:
		ctx.say("combat.meter_damage_none", args, "info")
		return false
	ctx.say("combat.hit", args, "danger")
	DamageApply.hurt(ctx, t, amount, "attack:" + ctx.source.id, "dark")
	ctx.events.append({"type": "damage", "target": t, "hit": true, "amount": amount, "crit": false, "weak": false,
		"damage_type": "dark", "affinity": 1.0})
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.has_entry("meters", JsonUtil.get_str(data, "meter")):
		out.append("meter_damage: meter '%s' 없음" % data.get("meter"))
	if JsonUtil.get_float(data, "mult", 0.0) <= 0.0:
		out.append("meter_damage: mult는 양수")
	return out
