extends EffectHandler
## 행동 게이지 당기기·밀기(정수 재기획): {"type": "gauge", "amount": 30} — 대상(또는 "to": "self"면 시전자)의 게이지를 amount만큼(음수면 늦어진다).
## 전투 중에만(Battle이 gauge 사건을 반영한다). 밀기에 확률이 필요하면 push_back.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.source if JsonUtil.get_str(data, "to") == "self" else ctx.subject()
	if t == null or t.dead:
		return false
	ctx.events.append({"type": "gauge", "target": t, "amount": JsonUtil.get_float(data, "amount")})
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	return PackedStringArray() if not is_zero_approx(JsonUtil.get_float(data, "amount")) else PackedStringArray(["gauge: amount가 0"])
