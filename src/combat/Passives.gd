class_name Passives
extends RefCounted
## 패시브(몬스터 데이터 passives · 정수 패시브 공통, docs/PROMPT_FLOOR1_V2.md §6). Actor.passives에 정의(Dictionary)가 들어 있다.
## 정의 키(모두 선택):
##   modifiers        [수정자] — 붙이는 것은 소유자 몫(Monster.create / EssenceSet)
##   on_hit           [효과] — 피해를 맞혔을 때 대상에게(예: 마비독 30%). on_hit_filter {ranged: bool, damage_types: [..]}
##   on_kill          [효과] — 공격으로 적을 쓰러뜨렸을 때 자신에게(회복·출혈 해제 …)
##   hit_vs_status {status, bonus} · reflect_status {status, chance} · counter_while {status, power}
##   skip_bonus_vs {status, bonus} — 상대가 그 상태(공포)면 행동을 건너뛸 확률 + bonus(BattleRules.fear_skip, 벤시)
##   on_crit          [효과] — 치명타를 냈을 때 대상에게(예: 어설픈 검술의 출혈)
##   crit_bonus       {value, damage_types} — 치명타율 보정(피해 유형이 맞을 때)
##   power_vs_status  {status, mult} — 그 상태의 대상에게 피해 배율(피 냄새). 패시브끼리 곱하되 combat.status_payoff_cap까지(정수 시너지 ES2)
##   while_self_status {status, crit_bonus, mult} — 자기가 그 상태(은신 …)인 동안 치명타율 + · 피해 ×(불카르 그늘 사냥 — ES3)
##   reflect_melee    비율 — 근접 공격을 받으면 받은 피해의 그만큼을 공격자에게(두꺼운 칼날털)
##   status_immune    [상태이상 id] — 걸리지 않는다(썩은 거구의 출혈 면역)
##   start_gauge      전투 시작 때 행동 게이지 보너스(네 발 짐승의 첫 차례 선공)
##   see_hidden       true — 은신한 대상도 고를 수 있다(추적 후각)
##   flee_penalty     비율 — 상대 진영의 도주 확률을 깎는다(추적 후각)
##   meter_on_damaged {meter, per_percent} — 피해를 받으면 최대 생명력 1%당 그만큼 자기 게이지(드레드피어 분노)
##   attacker_meter   {meter, amount} — 이 개체를 공격해 맞힌 쪽의 게이지가 오른다(드레드피어 P2 원망)
##   mark_first_attacker 상태 id — 전투에서 이 개체를 처음 공격한 쪽에게 그 상태(벤시 원령 → 원한의 징표)
##   status_duration_cap {상태: 턴} — 자기에게 걸리는 그 상태의 지속 상한(데스핀드 육체보존: 출혈 1)
##   regen_per_round  비율 — 자기 차례가 끝날 때 최대 생명력의 그만큼 회복(flag no_regen 상태면 멈춤)
##   dot_mult         배율 — 자기에게 걸린 지속 피해(본 나이트 방부제 0.5). Actor가 StatusSet에 맞춘다
##   ally_aura        {lineages|monsters, modifiers} — 전투 중 같은 편 해당 개체에 수정자(지휘관 데드맨·구울로드)
##   start_summons    [몬스터 id] — 전투 시작 때 같은 편으로 함께 나온다(구울로드)
##   foe_statuses_on_start [상태 id] — 전투 시작 때 상대 전원에게(블라터 원한)
##   basic_attack_effects [효과] — 기본 공격을 이 효과들로 바꾼다(키메라 울프 여러 개의 머리)
##   basic_extra_hit_chance 확률 — 기본 공격 뒤 한 번 더(키메라 정수판)
##   self_statuses_on_start [상태 id] — 전투 시작 때 자기에게(샤벨 타이거 기습 사냥꾼)
##   turn_end_foe_status {status, target: all|random} — 자기 차례가 끝날 때 상대에게(아이스 골렘 냉기 오러)
##   hit_rider {on_types, damage_type, flat|ratio} — 그 유형으로 맞히면 추가 속성 피해(타룬바스 정수 냉기 +5)
##   defense_ignore 비율 — 자기 공격이 대상 방어의 그만큼을 무시(홉고블린 광부 곡괭이 0.25)
##   on_damaged_by {damage_types, chance, self_damage_ratio, message} — 그 유형 피해를 받으면 확률로 자기 최대 생명력 비율 피해(폭탄병 유도 폭발)
##   death_effects [효과] — 쓰러지면 상대 전원에게(폭탄병 자폭). low_hp_summons {ratio, monsters} — 처음 비율 이하가 되면 한 번 소환(킹 슬라임 정수)
##   revive_once {ratio | hp, message} — 전투당 한 번, 쓰러질 피해를 받으면 그 생명력으로 버틴다(배리드언 30%, 정수판 1)
##   trap_watcher 비율 — 살아 있는 동안 그 균열 챕터 함정 발동 확률 ×(1+값)(수호자의 눈, RiftHazards)
##   걸린 상태 정의의 on_hit [효과]도 적중 시 대상에게 적용한다(독성부여)
##   meter_on_damaged에 damage_types·per_point를 주면 그 유형 피해량 × per_point(시체골렘 화염 누적)


static func of(a: Actor) -> Array[Dictionary]:
	return a.passives


## 치명타율 보정 합.
static func crit_bonus(a: Actor, dtype: String) -> float:
	var v := 0.0
	for p in a.passives:
		var cb := JsonUtil.get_dict(p, "crit_bonus")
		if cb.is_empty():
			continue
		var types := JsonUtil.get_array(cb, "damage_types")
		if types.is_empty() or types.has(dtype):
			v += JsonUtil.get_float(cb, "value")
	for p in a.passives:
		var ws := JsonUtil.get_dict(p, "while_self_status")
		if not ws.is_empty() and a.statuses.has(JsonUtil.get_str(ws, "status")):
			v += JsonUtil.get_float(ws, "crit_bonus")
	return v


## 공격자 패시브의 대상 상태별 피해 배율(곱 — 상한 combat.status_payoff_cap, 0이면 없음) × 자기 상태 배율(while_self_status — 상한 밖).
## 상한이 있어 출혈 반응 패시브를 여럿 모아도 한 대상에 대한 반응 배율이 끝없이 커지지 않는다(정수 시너지 ES2).
static func damage_mult_vs(attacker: Actor, defender: Actor) -> float:
	var m := 1.0
	for p in attacker.passives:
		var pv := JsonUtil.get_dict(p, "power_vs_status")
		if not pv.is_empty() and defender.statuses.has(JsonUtil.get_str(pv, "status")):
			m *= JsonUtil.get_float(pv, "mult", 1.0)
	var cap := float(attacker.db.bal("combat.status_payoff_cap", 0.0)) if attacker.db != null else 0.0
	if cap > 0.0:
		m = minf(m, cap)
	for p in attacker.passives:
		var ws := JsonUtil.get_dict(p, "while_self_status")
		if not ws.is_empty() and attacker.statuses.has(JsonUtil.get_str(ws, "status")):
			m *= JsonUtil.get_float(ws, "mult", 1.0)
	return m


## 공격자 패시브 hit_vs_status {status, bonus}: 대상이 그 상태면 명중(퍼센트 포인트) + bonus(칼날늑대 추적 후각 — 출혈 대상).
static func hit_bonus_vs(attacker: Actor, defender: Actor) -> float:
	var v := 0.0
	for p in attacker.passives:
		var hv := JsonUtil.get_dict(p, "hit_vs_status")
		if not hv.is_empty() and defender.statuses.has(JsonUtil.get_str(hv, "status")):
			v += JsonUtil.get_float(hv, "bonus")
	return v


## source가 target에게 상태를 건다: 면역(패시브·grants_immunity·immune_if) → 저항(남이 건 것만) → 지속 상한(status_duration_cap).
## "" = 걸렸다, "immune" | "resisted" | "failed". 모든 전투 부여 경로가 이것을 쓴다(메시지는 부르는 쪽).
static func try_status(db: GameDatabase, rng: Rng, source: Actor, target: Actor, status_id: String, duration: float = -1.0) -> String:
	if target == null or target.dead:
		return "failed"
	if is_immune(target, status_id) or target.statuses.immune(status_id):
		return "immune"
	if source != null and source != target and rng != null \
			and rng.chance(target.statuses.resist_chance(status_id, maxf(source.stats.get_value("str"), source.stats.get_value("int")))):
		return "resisted"
	var dur := duration
	var cap := duration_cap(target, status_id)
	if cap >= 0.0:
		var base := dur if dur >= 0.0 else JsonUtil.get_float(JsonUtil.get_dict(db.get_entry("statuses", status_id), "duration"), "amount", cap)
		dur = minf(base, cap)
	return "" if target.statuses.apply(status_id, dur) else "failed"


## 면역: 패시브 status_immune 또는 몬스터 status_immune(보스마다 개연성 있는 몇 가지 — UI25).
static func is_immune(a: Actor, status_id: String) -> bool:
	if a is Monster and JsonUtil.get_array((a as Monster).def, "status_immune").has(status_id):
		return true
	for p in a.passives:
		if JsonUtil.get_array(p, "status_immune").has(status_id):
			return true
	return false


static func has_flag(a: Actor, key: String) -> bool:
	for p in a.passives:
		if JsonUtil.get_bool(p, key):
			return true
	return false


static func sum(a: Actor, key: String) -> float:
	var v := 0.0
	for p in a.passives:
		v += JsonUtil.get_float(p, key)
	return v


## 피해를 맞힌 뒤: 공격자의 on_hit·on_crit, 맞은 쪽의 반사·반격. ranged = 원거리 공격.
static func after_hit(ctx: EffectContext, registry: EffectRegistry, dealt: int, crit: bool, ranged: bool, dtype: String) -> void:
	var src := ctx.source
	var tgt := ctx.target
	if src == null or tgt == null:
		return
	if dealt <= 0:
		return  # 보호막이 다 막았다 — 적중 효과·반사·반격 없음
	if not tgt.dead:
		for p in src.passives:
			if _filter_ok(JsonUtil.get_dict(p, "on_hit_filter"), ranged, dtype):
				_apply_list(ctx, registry, JsonUtil.get_array(p, "on_hit"), tgt)
			if crit:
				_apply_list(ctx, registry, JsonUtil.get_array(p, "on_crit"), tgt)
		for st in src.statuses.ids():
			_apply_list(ctx, registry, JsonUtil.get_array(ctx.db.get_entry("statuses", st), "on_hit"), tgt)
	_meters_after_hit(ctx, dealt, dtype)
	if tgt.dead and not src.dead:  # 쓰러뜨렸다 — on_kill(정수 재기획: 구울·데스핀드)은 공격자 자신에게
		for p in src.passives:
			_apply_list(ctx, registry, JsonUtil.get_array(p, "on_kill"), src)
	if ranged or tgt.dead:
		return
	var reflect := sum(tgt, "reflect_melee")
	if reflect > 0.0 and not src.dead:
		var back := maxi(1, roundi(dealt * reflect))
		ctx.say("combat.reflect", {"source": tgt.display_name, "target": src.display_name, "amount": back}, "warn")
		DamageApply.hurt(ctx, src, back, "reflect:" + tgt.id)
		for p in tgt.passives:  # reflect_status {status, chance}: 반사에 상태가 묻어난다(거대 칼날늑대 — 출혈)
			var rs := JsonUtil.get_dict(p, "reflect_status")
			if not rs.is_empty() and not src.dead and ctx.rng.chance(JsonUtil.get_float(rs, "chance", 1.0)):
				try_status(ctx.db, ctx.rng, tgt, src, JsonUtil.get_str(rs, "status"))
	var counter := tgt.statuses.counter_power()
	for p in tgt.passives:  # counter_while {status, power}: 그 상태(방어 태세)인 동안 근접으로 맞으면 반격(가고일 돌 피부)
		var cw := JsonUtil.get_dict(p, "counter_while")
		if not cw.is_empty() and tgt.statuses.has(JsonUtil.get_str(cw, "status")):
			counter = maxf(counter, JsonUtil.get_float(cw, "power"))
	if counter > 0.0 and not src.dead:
		var rolls := {"hit": ctx.rng.randf(), "crit": ctx.rng.randf(), "var": ctx.rng.randf(), "lethal": 1.0}
		var r := DamageCalc.resolve(ctx.db, tgt, src, {"scaling": "phys", "power": counter, "damage_type": "weapon"}, rolls)
		if bool(r["hit"]) and int(r["amount"]) > 0:
			ctx.say("combat.counter", {"source": tgt.display_name, "target": src.display_name, "amount": r["amount"]}, "warn")
			DamageApply.hurt(ctx, src, int(r["amount"]), "counter:" + tgt.id, str(r["damage_type"]))


## 쓰러질 피해(incoming ≥ 남은 생명력)를 revive_once로 버티면 생명력을 정하고 true(전투가 끝나면 다시 쓸 수 있다 — META).
const REVIVED_META := "revived_once"
const MARKED_META := "marked_first"  ## mark_first_attacker를 이번 전투에 이미 썼다(전투가 끝나면 지운다)


static func endure(ctx: EffectContext, target: Actor, incoming: int) -> bool:
	if target.dead or float(incoming) < target.pool.get_current("hp") or target.has_meta(REVIVED_META):
		return false
	for p in target.passives:
		var rv := JsonUtil.get_dict(p, "revive_once")
		if rv.is_empty():
			continue
		target.set_meta(REVIVED_META, true)
		var hp := JsonUtil.get_float(rv, "hp") if rv.has("hp") else roundf(target.pool.get_max("hp") * JsonUtil.get_float(rv, "ratio", 0.3))
		target.pool.set_current("hp", maxf(1.0, hp), "revive")
		ctx.say(JsonUtil.get_str(rv, "message", "combat.revive"), {"name": target.display_name}, "danger")
		return true
	return false


## 피해를 받았다(맞은 뒤): on_damaged_by — 그 유형이면 확률로 자기 피해(폭탄병 폭약 주머니 유도 폭발).
static func on_damaged(ctx: EffectContext, dtype: String) -> void:
	var tgt := ctx.target
	for p in tgt.passives:
		var od := JsonUtil.get_dict(p, "on_damaged_by")
		if od.is_empty() or tgt.dead or not JsonUtil.get_array(od, "damage_types").has(dtype):
			continue
		if ctx.rng.chance(JsonUtil.get_float(od, "chance", 1.0)):
			var amount := roundi(tgt.pool.get_max("hp") * JsonUtil.get_float(od, "self_damage_ratio"))
			ctx.say(JsonUtil.get_str(od, "message", "combat.self_blast"), {"name": tgt.display_name, "amount": amount}, "good")
			DamageApply.hurt(ctx, tgt, amount, "self:" + tgt.id)


## 공격받았다(맞든 안 맞든, 면역이어도): 처음 공격한 쪽에게 표식.
static func on_attacked(ctx: EffectContext) -> void:
	var tgt := ctx.target
	var src := ctx.source
	for p in tgt.passives:
		var st := JsonUtil.get_str(p, "mark_first_attacker")
		if not st.is_empty() and not tgt.has_meta(MARKED_META) and src != null and src != tgt:
			tgt.set_meta(MARKED_META, true)
			if not try_status(ctx.db, null, tgt, src, st).is_empty():
				continue
			ctx.say("combat.marked", {"name": src.display_name, "source": tgt.display_name,
				"status": DataNames.entry(ctx.db, "statuses", st)}, "danger")


## 자기에게 걸리는 상태의 지속 상한(없으면 -1).
static func duration_cap(a: Actor, status_id: String) -> float:
	var cap := -1.0
	for p in a.passives:
		var c := JsonUtil.get_dict(p, "status_duration_cap")
		if c.has(status_id):
			cap = float(c[status_id]) if cap < 0.0 else minf(cap, float(c[status_id]))
	return cap


static func _meters_after_hit(ctx: EffectContext, dealt: int, dtype: String = "") -> void:
	var tgt := ctx.target
	for p in tgt.passives:
		var md := JsonUtil.get_dict(p, "meter_on_damaged")
		var types := JsonUtil.get_array(md, "damage_types")
		if not md.is_empty() and dealt > 0 and not tgt.dead and (types.is_empty() or types.has(dtype)):
			var pct := float(dealt) / maxf(1.0, tgt.pool.get_max("hp")) * 100.0
			var amount := float(dealt) * JsonUtil.get_float(md, "per_point") if md.has("per_point") \
				else pct * JsonUtil.get_float(md, "per_percent", 1.0)
			Meters.add(ctx.db, tgt, JsonUtil.get_str(md, "meter"), amount, ctx)
		var am := JsonUtil.get_dict(p, "attacker_meter")
		if not am.is_empty():
			Meters.add(ctx.db, ctx.source, JsonUtil.get_str(am, "meter"), JsonUtil.get_float(am, "amount"), ctx)


static func _filter_ok(f: Dictionary, ranged: bool, dtype: String) -> bool:
	if f.has("ranged") and JsonUtil.get_bool(f, "ranged") != ranged:
		return false
	var types := JsonUtil.get_array(f, "damage_types")
	return types.is_empty() or types.has(dtype)


static func _apply_list(ctx: EffectContext, registry: EffectRegistry, list: Array, target: Actor) -> void:
	if list.is_empty() or registry == null:
		return
	var sub := EffectContext.new(ctx.db, ctx.source, target, ctx.rng)
	sub.info = ctx.info
	registry.apply_all(sub, list)
	ctx.messages.append_array(sub.messages)
	ctx.events.append_array(sub.events)
