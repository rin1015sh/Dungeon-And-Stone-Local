extends EffectHandler
## 여신의 눈물(핏빛성채 히든 피스): {"type": "smite", "families": ["undead"], "amount": 180, "status": "tear_sealed", "heal": 80, "damage_type": "holy"}
## 갱도 폭약(녹색 탄광): heal 0 — 싸울 때만 쓴다(전투 밖이면 쓰지 않고 남는다).
## 전투 중이면 상대 진영의 해당 계열 전원에게 고정 신성 피해 + 상태(저항 봉인). 해당 적이 없거나 전투 밖이면 사용자 생명력 회복.
## "single": true면 고른 적 하나만(균열 전투 도구 — 성수 병·얼음 송곳·화약 주머니·봉인 부적, 사용자 2026-10-30 RF27). 대상 = ctx.target.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var in_battle := bool(ctx.info.get("in_battle", false))
	if not in_battle and JsonUtil.get_float(data, "heal") <= 0.0:
		ctx.say("effect.battle_only", {}, "info")
		return false  # 회복이 없는 것(갱도 폭약)은 싸울 때만
	if not in_battle and ctx.source != null and ctx.source.pool.get_ratio("hp") >= 1.0:
		ctx.say("effect.restore_none", {"resource": ctx.source.pool.get_def("hp").name_ko}, "info")
		return false  # 전투 밖, 생명력이 가득하면 아무 일도 없다 — 귀한 물건을 그냥 쓰지 않는다
	ctx.events.append({"type": "smite", "families": JsonUtil.get_array(data, "families"), "amount": JsonUtil.get_float(data, "amount"),
		"status": JsonUtil.get_str(data, "status"), "heal": JsonUtil.get_float(data, "heal"), "damage_type": JsonUtil.get_str(data, "damage_type", "holy"),
		"single": JsonUtil.get_bool(data, "single"), "target": ctx.target})
	ctx.success = true
	if not in_battle and ctx.source != null:
		ctx.source.pool.modify("hp", JsonUtil.get_float(data, "heal") * ctx.source.statuses.heal_mult(), "smite")
		ctx.say("effect.smite_heal", {"name": ctx.source.display_name}, "good")
	return true
