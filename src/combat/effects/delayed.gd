extends EffectHandler
## 예고 공격(죽은 자의 기억 등): {"type": "delayed", "rounds": 2, "hits": 3, "effects": [ … ]}
## 시전자의 다음 차례 시작을 rounds번 지나면 무작위 적(끌어들이는 상태 draws_attacks가 있으면 그쪽 먼저)에게
## effects를 hits번 적용한다. 전투 중에만(Battle이 사건을 받아 BattleDelayed에 맡긴다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	ctx.events.append({"type": "delayed", "rounds": JsonUtil.get_int(data, "rounds", 1), "hits": JsonUtil.get_int(data, "hits", 1),
		"effects": JsonUtil.get_array(data, "effects"), "name": str(ctx.info.get("skill_name", ""))})
	ctx.say("combat.delayed_warn", {"name": ctx.source.display_name if ctx.source != null else ""}, "danger")
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if JsonUtil.get_int(data, "rounds", 0) < 1:
		out.append("delayed: rounds는 1 이상")
	if JsonUtil.get_array(data, "effects").is_empty():
		out.append("delayed: effects가 비었다")
	return out
