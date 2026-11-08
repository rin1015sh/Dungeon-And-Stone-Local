extends EffectHandler
## 피해: {"type": "damage", "scaling": "phys"|"magic", "power": 1.0, "damage_type": "slash"|"weapon"|…, "base": 0,
##        "accuracy": 95, "crit_bonus": 0.15, "ranged": false, "power_if_status": {status, power},
##        "drain_if_status": {"status": "bleeding", "ratio": 0.4}, "drain": 0.5, "power_per_summon": 0.25(내 소환수 하나마다 위력 ×(1+k))}
## 대상 패시브 aoe_taken_mult(떼): 광역 스킬(ctx.info.aoe — 대상 enemy_all)이면 피해 ×그 값.
## 공격자의 상태 lifesteal(생기 흡수)도 흡혈. 공격자의 "consume_on_attack" 상태(진군 명령)는 이 공격으로 사라진다
## (스킬 사용이면 Battle이 스킬 한 번이 끝난 뒤에 — 광역·연타 전체에 적용).
## 맞든 안 맞든 대상의 패시브 mark_first_attacker(벤시 원령)를 먼저 처리한다.
## "rider": {"damage_type": "cold", "ratio": 0.3 | "flat": 5} — 맞히면 그 유형 추가 피해(공격자 패시브 hit_rider {on_types, …}도 같다).
## 피해는 DamageApply로 입힌다(보호막 → revive_once → 생명력 → 피해로 풀리는 상태). 출처는 "attack:<공격자 id>".
## 치명상(급소)은 보호막이 막지 않고 실제로 생명력이 깎여 비율 이하가 됐을 때만 생명력을 0으로 만든다.
## 빗나가거나 면역이면 ctx.landed = 0 — 같은 대상에게 뒤따르는 효과(상태·밀치기)는 걸리지 않는다(EffectRegistry).
## "ranged"가 없으면 마법은 원거리, 무기 공격은 무기(활)를 따른다(is_ranged — 반사·반격·근접 적중 효과가 본다).
## 맞힌 뒤 Passives.after_hit(적중 시 효과·반사·반격), 흡혈.
## "dodged": true = 반드시 빗나간다(보스 동전을 맞혀 피함 — BattleCoin).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var target := ctx.target
	var source := ctx.source
	if target == null or source == null or target.dead:
		return false  # 시전자가 쓰러져도 남은 효과(자폭 death_effects)는 들어간다 — 스킬 도중 쓰러지면 Battle이 멈춘다
	var rolls := {"hit": ctx.rng.randf(), "crit": ctx.rng.randf(), "var": ctx.rng.randf(), "lethal": ctx.rng.randf()}
	if JsonUtil.get_bool(data, "dodged"):
		rolls["hit"] = INF  # 명중 확률이 얼마든 빗나간다
	var per_summon := JsonUtil.get_float(data, "power_per_summon")  # 구울로드 포식자의 손톱: 내 소환수 하나마다 위력 +
	if per_summon > 0.0 and int(ctx.info.get("summons", 0)) > 0:
		data = data.duplicate()
		data["power"] = JsonUtil.get_float(data, "power", 1.0) * (1.0 + per_summon * int(ctx.info["summons"]))
	var r := DamageCalc.resolve(ctx.db, source, target, data, rolls)
	var aoe := Passives.sum(target, "aoe_taken_mult")  # 떼(박쥐 · 까마귀 — 2층): 광역 스킬에 더 아프다
	if aoe > 0.0 and bool(ctx.info.get("aoe", false)):
		r["amount"] = int(round(float(r["amount"]) * aoe))
	Passives.on_attacked(ctx)
	if not ctx.info.has("skill_id"):
		for st in source.statuses.ids():
			if JsonUtil.get_bool(ctx.db.get_entry("statuses", st), "consume_on_attack"):
				source.statuses.remove(st)
	var args := {"source": source.display_name, "target": target.display_name, "amount": r["amount"]}
	var ev := r.duplicate()
	ev["type"] = "damage"
	ev["target"] = target
	ctx.events.append(ev)
	if not bool(r["hit"]):
		ctx.landed = 0
		ctx.say("combat.miss", args, "info")
		return true
	if float(r["affinity"]) <= 0.0:
		ctx.landed = 0
		ev["immune"] = true
		ctx.say("combat.immune", args, "warn")
		return true
	ctx.landed = 1
	var origin := "attack:" + source.id
	var dtype := str(r["damage_type"])
	var lost := DamageApply.hurt(ctx, target, int(r["amount"]), origin, dtype)
	ev["lost"] = lost  # 화면에 떠오르는 숫자 = 실제로 깎인 생명력(보호막에 막힌 만큼은 빼고). amount는 계산된 피해 그대로
	var landed_amount := int(r["amount"]) if lost > 0 else 0  # 보호막이 다 막았으면 맞힌 것으로 치지 않는다
	if lost > 0:
		Passives.on_damaged(ctx, dtype)
	if bool(r["crit"]):
		ctx.say("combat.crit", args, "danger")
	else:
		ctx.say("combat.hit", args, "info")
	if float(r["affinity"]) > 1.0:
		ctx.say("combat.effective", args, "good")
	_riders(ctx, data, float(r.get("raw", r["amount"])), dtype, origin)
	if bool(r["lethal"]) and lost > 0 and not target.dead and not _lethal_immune(ctx, target) \
			and target.pool.get_ratio("hp") <= float(ctx.db.bal("combat.lethal_hp_ratio", 0.3)):
		var now := target.pool.get_current("hp")
		if Passives.endure(ctx, target, int(ceil(now))):
			target.pool.set_current("hp", minf(now, target.pool.get_current("hp")), "revive")  # 버티기는 생명력을 올려 주지 않는다
		else:
			target.pool.set_current("hp", 0.0, origin)
			ctx.say("combat.lethal", args, "danger")
	var drain := JsonUtil.get_dict(data, "drain_if_status")
	var ratio := JsonUtil.get_float(data, "drain") + source.statuses.sum_key("lifesteal")
	if not drain.is_empty() and target.statuses.has(JsonUtil.get_str(drain, "status")):
		ratio += JsonUtil.get_float(drain, "ratio")
	if ratio > 0.0 and not source.dead and landed_amount > 0:
		var healed := roundi(float(landed_amount) * ratio * source.statuses.heal_mult())
		if healed > 0:
			source.pool.modify("hp", float(healed), "drain")
			ctx.say("combat.drain", {"source": source.display_name, "amount": healed}, "info")
	Passives.after_hit(ctx, ctx.registry, landed_amount, bool(r["crit"]), is_ranged(data, source), dtype)
	return true


## 원거리 공격인가: 데이터 "ranged"가 있으면 그것, 없으면 마법(scaling magic)은 원거리, 무기 공격은 무기(활)를 따른다.
static func is_ranged(data: Dictionary, source: Actor) -> bool:
	if data.has("ranged"):
		return JsonUtil.get_bool(data, "ranged")
	if JsonUtil.get_str(data, "scaling", "phys") == "magic":
		return true
	return JsonUtil.get_str(data, "damage_type", "blunt") == "weapon" and source.weapon_is_ranged()


## 추가 속성 피해. 비율형은 받는/주는 피해 수정자를 넣기 전의 피해(raw) 기준 — 수정자는 추가 피해 쪽에서 한 번만 곱해진다.
func _riders(ctx: EffectContext, data: Dictionary, raw: float, dtype: String, origin: String) -> void:
	var list: Array = []
	if data.has("rider"):
		list.append(JsonUtil.get_dict(data, "rider"))
	for p in ctx.source.passives:
		var hr := JsonUtil.get_dict(p, "hit_rider")
		if not hr.is_empty() and (JsonUtil.get_array(hr, "on_types").is_empty() or JsonUtil.get_array(hr, "on_types").has(dtype)):
			list.append(hr)
	for rd: Dictionary in list:
		if ctx.target.dead:
			return
		var rtype := JsonUtil.get_str(rd, "damage_type", "cold")
		var extra := DamageCalc.rider(ctx.db, ctx.source, ctx.target, rtype, JsonUtil.get_float(rd, "flat") + raw * JsonUtil.get_float(rd, "ratio"))
		if extra > 0:
			DamageApply.hurt(ctx, ctx.target, extra, origin, rtype)
			ctx.say("combat.rider_hit", {"target": ctx.target.display_name, "amount": extra, "type": DataNames.tag(ctx.db, "damage_types", rtype)}, "info")


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not JsonUtil.get_str(data, "scaling", "phys") in ["phys", "magic"]:
		out.append("damage: scaling은 phys/magic")
	if JsonUtil.get_float(data, "power", 1.0) <= 0.0:
		out.append("damage: power는 0보다 커야 한다")
	return out


## 치명상(급소 즉사)이 듣지 않는 몬스터 — 중간 보스·수호자·변이종·계층군주(combat.lethal_immune_ranks).
static func _lethal_immune(ctx: EffectContext, target: Actor) -> bool:
	if not (target is Monster):
		return false
	var rank := JsonUtil.get_str((target as Monster).def, "rank")
	return (ctx.db.bal("combat.lethal_immune_ranks", []) as Array).has(rank)
