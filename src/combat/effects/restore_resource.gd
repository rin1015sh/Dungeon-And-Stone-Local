extends EffectHandler
## 자원 회복/감소: {"type": "restore_resource", "resource": "hunger", "amount": 40}
## amount는 숫자 또는 수식(음수면 감소). 대상이 없으면 사용자 자신.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.subject()
	var res := JsonUtil.get_str(data, "resource")
	if actor == null or actor.dead or not actor.pool.has_resource(res):
		return false
	var amount := Formula.value(data.get("amount", 0.0), actor.pool.resolve)
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
	ctx.say("effect.restore", {"resource": name_ko, "amount": roundi(absf(changed))}, "good" if changed > 0.0 else "warn")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.resources.has(JsonUtil.get_str(data, "resource")):
		out.append("restore_resource: resource '%s' 없음" % data.get("resource"))
	var amount: Variant = data.get("amount")
	if not (JsonUtil.is_number(amount) or amount is String):
		out.append("restore_resource: amount는 숫자 또는 수식")
	return out
