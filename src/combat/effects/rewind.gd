extends EffectHandler
## 되감기(후회의 군주 민낯 — plans/expansion_f1_3_B §6-4): {"type": "rewind", "ratio": 0.5} — 시전자가 직전 한 바퀴 동안 받은 피해
## (액터 메타 TAKEN — 패턴 regret_lord가 바퀴마다 적는다)의 ratio만큼 생명력을 되돌린다.

const TAKEN := "regret_taken_last_round"


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var a := ctx.source
	if a == null or a.dead:
		return false
	var amount := floorf(float(a.get_meta(TAKEN, 0.0)) * JsonUtil.get_float(data, "ratio", 0.5))
	if amount <= 0.0:
		return false
	a.pool.set_current("hp", minf(a.pool.get_max("hp"), a.pool.get_current("hp") + amount))
	return true
