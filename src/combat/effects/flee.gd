extends EffectHandler
## 도주 요청: {"type": "flee"}. 성공 여부(민첩 비교)는 전투(Battle)가 판정한다.


func apply(ctx: EffectContext, _data: Dictionary) -> bool:
	ctx.events.append({"type": "flee", "actor": ctx.source})
	return true
