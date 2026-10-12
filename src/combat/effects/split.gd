extends EffectHandler
## 분열(슬라임): {"type": "split"} — 시전자의 남은 생명력을 반으로 나눠 같은 몬스터 하나를 만든다(전투 중에만 — BattleSpawns.split).


func apply(ctx: EffectContext, _data: Dictionary) -> bool:
	if ctx.source == null:
		return false
	ctx.events.append({"type": "split", "skill": str(ctx.info.get("skill_id", ""))})
	return true
