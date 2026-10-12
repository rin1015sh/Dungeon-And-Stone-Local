extends EffectHandler
## 보호막(강철빙벽): {"type": "barrier", "status": "steel_ice_wall", "amount": "{int} * 4"}
## 대상에게 보호막 상태(정의 barrier: true)를 걸고, 양은 시전자 스탯으로 푼 amount. 받는 피해를 먼저 흡수한다(StatusSet.absorb).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.subject()
	if t == null or t.dead:
		return false
	var who := ctx.source if ctx.source != null else t
	var amount := Formula.value(data.get("amount", 0.0), who.pool.resolve)
	var id := JsonUtil.get_str(data, "status")
	if amount <= 0.0 or not t.statuses.apply(id):
		return false
	t.statuses.set_barrier(id, amount)
	ctx.say("effect.barrier_on", {"name": t.display_name, "amount": roundi(amount)}, "good")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not JsonUtil.get_bool(db.get_entry("statuses", JsonUtil.get_str(data, "status")), "barrier"):
		out.append("barrier: status '%s'가 없거나 barrier가 아니다" % data.get("status"))
	if not (JsonUtil.is_number(data.get("amount")) or data.get("amount") is String):
		out.append("barrier: amount는 숫자 또는 수식")
	return out
