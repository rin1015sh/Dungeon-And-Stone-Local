extends EffectHandler
## 피해: {"type": "damage", "scaling": "phys"|"magic", "power": 1.0, "damage_type": "slash"|"weapon"|…, "base": 0,
##        "accuracy": 95, "crit_bonus": 0.15, "ranged": false, "power_if_status": {status, power},
##        "drain_if_status": {"status": "bleeding", "ratio": 0.4}, "drain": 0.5}
## 공격자의 상태 lifesteal(생기 흡수)도 흡혈. 공격자의 "consume_on_attack" 상태(진군 명령)는 이 공격으로 사라진다.
## 맞든 안 맞든 대상의 패시브 mark_first_attacker(벤시 원령)를 먼저 처리한다.
## "rider": {"damage_type": "cold", "ratio": 0.3 | "flat": 5} — 맞히면 그 유형 추가 피해(공격자 패시브 hit_rider {on_types, …}도 같다).
## 대상의 보호막(강철빙벽)이 피해를 먼저 흡수한다.
## 계산은 DamageCalc. 치명상(급소)이면 생명력을 0으로 만든다. 출처는 "attack:<공격자 id>".
## 맞힌 뒤 Passives.after_hit(적중 시 효과·반사·반격), 흡혈.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var target := ctx.target
	var source := ctx.source
	if target == null or source == null or target.dead:
		return false
	var rolls := {"hit": ctx.rng.randf(), "crit": ctx.rng.randf(), "var": ctx.rng.randf(), "lethal": ctx.rng.randf()}
	var r := DamageCalc.resolve(ctx.db, source, target, data, rolls, bool(ctx.info.get("aim_weak", false)))
	Passives.on_attacked(ctx)
	for st in source.statuses.ids():
		if JsonUtil.get_bool(ctx.db.get_entry("statuses", st), "consume_on_attack"):
			source.statuses.remove(st)
	var args := {"source": source.display_name, "target": target.display_name, "amount": r["amount"]}
	var ev := r.duplicate()
	ev["type"] = "damage"
	ev["target"] = target
	ctx.events.append(ev)
	if not bool(r["hit"]):
		ctx.say("combat.miss", args, "info")
		return true
	if float(r["affinity"]) <= 0.0:
		ctx.say("combat.immune", args, "warn")
		return true
	var origin := "attack:" + source.id
	_hurt(ctx, target, int(r["amount"]), origin)
	if int(r["amount"]) > 0:
		for broken in target.statuses.on_damaged(str(r["damage_type"])):
			ctx.say("effect.status_broken", {"name": target.display_name, "status": DataNames.entry(ctx.db, "statuses", broken)}, "info")
	var wp_status := JsonUtil.get_str(target.weak_point(), "on_hit_status") if bool(r["weak"]) else ""
	if not wp_status.is_empty():
		target.statuses.apply(wp_status)  # 약점 적중 시 대상에게(캠보르미어 심장 → 재생 정지)
	if bool(r["crit"]):
		ctx.say("combat.crit", args, "danger")
	elif bool(r["weak"]):
		ctx.say("combat.weak_hit", args, "danger")
	else:
		ctx.say("combat.hit", args, "info")
	if float(r["affinity"]) > 1.0:
		ctx.say("combat.effective", args, "good")
	_riders(ctx, data, int(r["amount"]), str(r["damage_type"]), origin)
	if bool(r["lethal"]) and not target.dead:
		target.pool.set_current("hp", 0.0, origin)
		ctx.say("combat.lethal", args, "danger")
	var drain := JsonUtil.get_dict(data, "drain_if_status")
	var ratio := JsonUtil.get_float(data, "drain") + source.statuses.sum_key("lifesteal")
	if not drain.is_empty() and target.statuses.has(JsonUtil.get_str(drain, "status")):
		ratio += JsonUtil.get_float(drain, "ratio")
	if ratio > 0.0 and not source.dead:
		var healed := roundi(float(r["amount"]) * ratio * source.statuses.heal_mult())
		if healed > 0:
			source.pool.modify("hp", float(healed), "drain")
			ctx.say("combat.drain", {"source": source.display_name, "amount": healed}, "info")
	var ranged := JsonUtil.get_bool(data, "ranged") if data.has("ranged") else \
		(JsonUtil.get_str(data, "damage_type", "blunt") == "weapon" and source.weapon_is_ranged())
	Passives.after_hit(ctx, ctx.registry, int(r["amount"]), bool(r["crit"]), ranged, str(r["damage_type"]))
	return true


## 보호막을 거쳐 생명력을 깎는다.
func _hurt(ctx: EffectContext, target: Actor, amount: int, origin: String) -> void:
	var left := target.statuses.absorb(amount) if target.statuses.barrier_total() > 0.0 else amount
	if left < amount:
		ctx.say("combat.barrier_absorb", {"name": target.display_name, "amount": amount - left}, "info")
	target.pool.modify("hp", -float(left), origin)


func _riders(ctx: EffectContext, data: Dictionary, amount: int, dtype: String, origin: String) -> void:
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
		var extra := DamageCalc.rider(ctx.db, ctx.source, ctx.target, rtype, JsonUtil.get_float(rd, "flat") + amount * JsonUtil.get_float(rd, "ratio"))
		if extra > 0:
			_hurt(ctx, ctx.target, extra, origin)
			ctx.say("combat.rider_hit", {"target": ctx.target.display_name, "amount": extra, "type": DataNames.tag(ctx.db, "damage_types", rtype)}, "info")


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not JsonUtil.get_str(data, "scaling", "phys") in ["phys", "magic"]:
		out.append("damage: scaling은 phys/magic")
	if JsonUtil.get_float(data, "power", 1.0) <= 0.0:
		out.append("damage: power는 0보다 커야 한다")
	return out
