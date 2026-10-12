extends EffectHandler
## 대열 섞기(면죄부): {"type": "shuffle_rows"} — 대상 진영의 전열·후열을 무작위로 바꾼다. 전투 중에만.


func apply(ctx: EffectContext, _data: Dictionary) -> bool:
	if ctx.subject() == null:
		return false
	ctx.events.append({"type": "shuffle_rows", "target": ctx.subject()})
	return true
