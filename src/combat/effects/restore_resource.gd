extends EffectHandler
## 자원 회복/감소: {"type": "restore_resource", "resource": "hunger", "amount": 40}
## amount는 숫자 또는 수식(음수면 감소) — 특정값. percent(0.3 = 30%)는 그 자원 최대치의 비율 — 포션은 둘 중 하나로 쓴다. 대상이 없으면 사용자 자신.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.subject()
	var res := JsonUtil.get_str(data, "resource")
	if actor == null or actor.dead or not actor.pool.has_resource(res):
		return false
	var amount := Formula.value(data.get("amount", 0.0), actor.pool.resolve)
	if data.has("percent"):
		amount = floorf(actor.pool.get_max(res) * JsonUtil.get_float(data, "percent"))
	if res == "hp" and amount > 0.0:
		amount *= actor.statuses.heal_mult()  # 원한(heal_block)
	if JsonUtil.get_bool(data, "non_lethal") and amount < 0.0:  # 스스로 치르는 값(정수판 분열): 1은 남긴다
		amount = maxf(amount, 1.0 - actor.pool.get_current(res))
	var name_ko := actor.pool.get_def(res).name_ko
	if amount > 0.0 and actor.pool.get_max(res) - actor.pool.get_current(res) < 0.5:
		ctx.say("effect.restore_none", {"resource": name_ko}, "info")  # 거의 가득 — "0만큼 변했다"로 물건만 쓰지 않게
		return false
	var changed := actor.pool.modify(res, amount, "effect:restore_resource")
	if changed == 0.0:
		ctx.say("effect.restore_none", {"resource": name_ko}, "info")
		return amount < 0.0
	if res == "hp" and changed > 0.0:
		actor.statuses.on_healed()  # 출혈 1중첩 멎음
	ctx.say("effect.restore", {"resource": name_ko, "amount": roundi(absf(changed)), "res": res, "delta": roundi(changed)}, "good" if changed > 0.0 else "warn")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.resources.has(JsonUtil.get_str(data, "resource")):
		out.append("restore_resource: resource '%s' 없음" % data.get("resource"))
	var amount: Variant = data.get("amount")
	if data.has("percent"):
		if not JsonUtil.is_number(data["percent"]):
			out.append("restore_resource: percent는 숫자(0.3 = 최대치의 30%)")
	elif not (JsonUtil.is_number(amount) or amount is String):
		out.append("restore_resource: amount(특정값·수식) 또는 percent(최대치 비율)")
	return out
