extends EffectHandler
## 흡수(킹 슬라임): {"type": "absorb_ally", "monsters": ["slime"], "heal_ratio": 0.1}
## 같은 편의 그 몬스터 하나를 삼키고 최대 생명력 heal_ratio만큼 회복한다(전투 중에만 — BattleSpawns.absorb).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	ctx.events.append({"type": "absorb_ally", "monsters": JsonUtil.get_array(data, "monsters"), "heal_ratio": JsonUtil.get_float(data, "heal_ratio", 0.1)})
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	for m: Variant in JsonUtil.get_array(data, "monsters"):
		if not db.has_entry("monsters", str(m)):
			out.append("absorb_ally: monster '%s' 없음" % m)
	return out
