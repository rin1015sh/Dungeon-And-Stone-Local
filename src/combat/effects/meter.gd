extends EffectHandler
## 전투 게이지 더하기: {"type": "meter", "meter": "dread_fear", "amount": 5, "to": "target"|"self"}
## amount는 숫자 또는 수식(받는 쪽 스탯으로 푼다, 예: "max(3, 10 - {int} / 10)"). 가득 차면 Meters가 상태이상을 건다.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var who := ctx.source if JsonUtil.get_str(data, "to", "target") == "self" else ctx.subject()
	if who == null or who.dead:
		return false
	var amount := Formula.value(data.get("amount", 0.0), who.pool.resolve)
	Meters.add(ctx.db, who, JsonUtil.get_str(data, "meter"), amount, ctx)
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.has_entry("meters", JsonUtil.get_str(data, "meter")):
		out.append("meter: meter '%s' 없음(meters.json)" % data.get("meter"))
	if not JsonUtil.get_str(data, "to", "target") in ["target", "self"]:
		out.append("meter: to는 target/self")
	var amount: Variant = data.get("amount")
	if not (JsonUtil.is_number(amount) or amount is String):
		out.append("meter: amount는 숫자 또는 수식")
	return out
