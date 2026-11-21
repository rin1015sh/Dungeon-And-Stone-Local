extends EffectHandler
## 순서 뒤집기(후회의 군주 모래 탈 — plans/expansion_f1_3_B §6-4): {"type": "reverse_order"} — 대상 편의 행동 순서를 거꾸로(가장 빠른 쪽이
## 가장 늦게 — BattleHabits.reverse_order). 전투 중에만(Battle이 사건을 받아 게이지를 맞바꾼다). 한 번만 뒤집도록 대상 하나에게 쓴다.


func apply(ctx: EffectContext, _data: Dictionary) -> bool:
	var t := ctx.subject()
	if t == null or t.dead:
		return false
	ctx.events.append({"type": "reverse_order", "target": t})
	return true
