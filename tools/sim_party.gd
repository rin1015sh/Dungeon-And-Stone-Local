extends SceneTree
## 균열 파티 시뮬레이터(헤드리스, docs/PROMPT_FLOOR1_V2.md §15). check.sh에는 넣지 않는다.
##   godot --headless --path . --script res://tools/sim_party.gd -- [--n=300] [--only=<이름 일부>]
## --only를 주면 그 시나리오만 돌리고 리포트 파일은 쓰지 않는다(수치 맞추기용).
## 기본(2026-10-19~): 탐험가 기본 스탯 = 종족 굴림 범위의 가운데, 정수 = 실제 고정 스탯·생명력(J11~J13).
## --essences=none: 정수 스탯·생명력을 빼고 --base=config: sim_parties.json의 stats를 쓴다(2026-10-18까지의 방식 — 비교용).
## --essence_mult=0.8: 정수 스탯·생명력에 곱한다(정수 수치를 얼마나 깎을지 볼 때). 기본이 아닌 옵션을 주면 리포트 파일은 쓰지 않는다.
## tools/sim_parties.json의 파티(Lv4 4인·포션·정수)로 시나리오마다 n번 싸워 승률을 보고 docs/balance/rift.md에 쓴다.
## 아군 AI: 생명력이 potion_hp_ratio 아래면 하급 포션, smart면 [예고]가 찍혔을 때 방어, 아니면 기본 공격
## (수호자·중간 보스가 있으면 그중 — 졸개가 셋 이상 쌓이면 졸개부터 —, 없으면 생명력이 가장 낮은 적).
## 시나리오 "party_statuses": [..] — 전투 전에 아군 전원에게 건다(빙하굴 3·4챕터 저체온증).
## 공격은 쓸 수 있는 정수 액티브 중 위력 합이 가장 큰 것, 없으면 기본 공격.
## --curve=<층>: 파티를 10층 곡선의 그 층 기준 탐험가로(docs/balance/curve.json — 첫 전사 = 탱커, 나머지 = 딜러: 정수를 흡수한 뒤
##   주 스탯·생명력·공격력을 곡선 값에 맞춘다 — 이능은 1층 정수 그대로). 보스가 "몇 층 위 파티용"인지 확인할 때(docs/plans/balance_10floors.md §4).
## --rev=full: 기세(C20)를 쓴다 — 기세가 가득(max)이면 그 차례의 공격(정수 스킬이든 기본 공격이든)에 모두 얹는다. 기세는 얹지 않은
##   기본 공격·방어로 찬다. --rev=build: 기세가 가득이 아니면 정수 스킬 대신 기본 공격으로 기세를 모으고, 가득이면 가장 센 공격에 모두 얹는다(상한 보기).
##   기본(none)은 기세를 쓰지 않는다(예전 리포트와 같은 조건). 기본이 아닌 값이면 리포트 파일은 쓰지 않는다.

const CFG := "res://tools/sim_parties.json"
const OUT := "res://docs/balance/rift.md"
const BOSS_RANKS := ["guardian", "variant_guardian", "midboss", "lord"]
const ADDS_LIMIT := 3


func _initialize() -> void:
	var args := {"n": "300"}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var db := GameDatabase.new()
	db.load_all("res://data")
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CFG))
	cfg["real_essences"] = str(args.get("essences", "real")) == "real"
	cfg["race_base"] = str(args.get("base", "race")) == "race"
	cfg["essence_mult"] = str(args.get("essence_mult", "1")).to_float()
	cfg["rev"] = str(args.get("rev", "none"))
	var curve_floor := str(args.get("curve", cfg.get("curve_floor", "")))
	if not curve_floor.is_empty() and curve_floor != "none":  # 기본 = sim_parties.json curve_floor(균열 = 3층 파티용), --curve=none이면 예전처럼 1층 정수 파티
		var refs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/balance/curve.json"))
		cfg["curve"] = refs.get(str(int(float(curve_floor))), {})
		cfg["level"] = int(JsonUtil.get_float(cfg["curve"], "level", 4))
	var custom := args.has("essences") or args.has("base") or args.has("essence_mult") or args.has("curve") or args.has("rev")
	var n := str(args["n"]).to_int()
	var who := "곡선 %s층 기준 탐험가 5인(docs/balance/curve.json)" % curve_floor if cfg.has("curve") else "1층 정수 파티"
	var lines := PackedStringArray(["# 균열 파티 시뮬레이션", "", "`tools/sim_party.gd`가 만든다(파티: `tools/sim_parties.json` — %s, 시나리오당 %d회)." % [who, n], "",
		"| 시나리오 | 승률 | 목표 | 평균 차례 | 쓰러진 아군(평균) |", "|---|---|---|---|---|"])
	var misses := 0
	for sc: Dictionary in cfg["scenarios"]:
		if args.has("only") and not str(sc["name"]).contains(str(args["only"])):
			continue
		var wins := 0
		var turns := 0
		var downs := 0
		for i in n:
			var r := _fight(db, cfg, sc, i)
			wins += 1 if r["win"] else 0
			turns += int(r["turns"])
			downs += int(r["downs"])
		var rate := float(wins) / n
		var ok := rate >= float(sc["min"]) and rate <= float(sc["max"])
		misses += 0 if ok else 1
		lines.append("| %s | %.0f%% | %.0f~%.0f%% | %.1f | %.2f |%s" % [sc["name"], rate * 100.0, float(sc["min"]) * 100.0,
			float(sc["max"]) * 100.0, float(turns) / n, float(downs) / n, "" if ok else " ← 벗어남"])
	lines.append("")
	lines.append("- 목표 벗어남 %d개" % misses)
	lines.append("")
	if args.has("only") or custom:
		print("\n".join(lines))
		quit(0)
		return
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	print("\n".join(lines))
	quit(0)


func _fight(db: GameDatabase, cfg: Dictionary, sc: Dictionary, i: int) -> Dictionary:
	var party: Array[Actor] = []
	var reg := ContentRegistries.new()
	var b := Battle.new(db, reg.effects, reg.ai_conditions, Rng.new(9000 + i))
	var tank_taken := false
	for m: Dictionary in cfg["party"]:
		var stats: Dictionary = _race_mid(db, str(m["race"])) if bool(cfg["race_base"]) else m["stats"]
		var pc := PlayerCharacter.create(db, str(m["race"]), str(m["class"]), str(m["name"]), stats)
		pc.set_level(int(cfg["level"]))
		for e: Dictionary in m["essences"]:
			var inst := EssenceDrop.make(db, str(e["essence"]), str(e["color"]), Rng.new(1)) if bool(cfg["real_essences"]) \
				else {"essence": e["essence"], "color": e["color"], "stats": {}}
			for part: String in ["stats", "resources"]:
				var vals := JsonUtil.get_dict(inst, part)
				for k: String in vals:
					vals[k] = roundi(float(vals[k]) * float(cfg["essence_mult"]))
			pc.essences.absorb(pc, inst)
		if cfg.has("curve"):  # 정수(이능)는 그대로 두고 스탯·생명력만 곡선 값에 맞춘다
			var role := "tank" if str(m["class"]) == "warrior" and not tank_taken else "dps"
			tank_taken = tank_taken or role == "tank"
			_to_curve(pc, JsonUtil.get_dict(cfg["curve"], role))
		for item: String in cfg["items"]:
			pc.inventory.add(item, int(cfg["items"][item]))
		for st: Variant in sc.get("party_statuses", []):
			pc.statuses.apply(str(st))
		pc.pool.fill_all()
		party.append(pc)
		b.add(pc, Combatant.SIDE_PARTY, str(m["row"]))
	for id: Variant in sc["monsters"]:
		var mon := Monster.create(db, str(id))
		b.add(mon, Combatant.SIDE_ENEMY, JsonUtil.get_str(mon.behavior(), "row", "front"))
	b.start(i % 2 == 0)
	var t := 0
	while t < 600:
		var c := b.next_turn()
		if c == null:
			break
		t += 1
		var action := _party_action(b, c, cfg, str(sc["ai"])) if b.is_player_controlled(c) else b.ai_action(c)
		if not b.act(c, action) and not b.act(c, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": null}):
			b.act(c, {"kind": "guard"})  # 거부된 행동이 같은 차례를 되풀이하지 않게(화면과 같은 대체 순서)
	var downs := party.filter(func(a: Actor) -> bool: return a.dead).size()
	return {"win": b.result == Battle.RESULT_VICTORY, "turns": t, "downs": downs}


## 곡선 기준 탐험가로 맞춘다: 주 스탯(근력은 무기 공격력을 빼고 공격력이 곡선 값이 되게)·최대 생명력.
func _to_curve(pc: PlayerCharacter, ref: Dictionary) -> void:
	var want := ref.duplicate()
	want["str"] = (JsonUtil.get_float(ref, "atk") - maxf(0.0, pc.weapon_attack())) / 2.0
	for k: String in ["str", "agi", "p_res", "m_res", "int"]:
		pc.stats.add_modifier(Modifier.new("curve", k, JsonUtil.get_float(want, k) - pc.stats.get_value(k)))
	pc.stats.add_modifier(Modifier.new("curve", "max:hp", JsonUtil.get_float(ref, "hp") - pc.pool.get_max("hp")))


func _party_action(b: Battle, c: Combatant, cfg: Dictionary, ai: String) -> Dictionary:
	var a := c.actor
	if a.pool.get_ratio("hp") < float(cfg["potion_hp_ratio"]) and a.inventory.count("minor_potion") > 0:
		return {"kind": "item", "item": "minor_potion"}
	if ai == "smart" and a.statuses.has("telegraphed"):
		return {"kind": "guard"}
	var foes := BattleRules.targetable(b, c)
	var bosses := foes.filter(func(f: Combatant) -> bool:
		return f.actor is Monster and JsonUtil.get_str((f.actor as Monster).def, "rank") in BOSS_RANKS)
	# 수호자·중간 보스를 먼저 치되, 졸개가 셋 이상 쌓이면 졸개부터 정리한다.
	if not bosses.is_empty() and foes.size() - bosses.size() < ADDS_LIMIT:
		foes = bosses
	elif not bosses.is_empty():
		foes = foes.filter(func(f: Combatant) -> bool: return not bosses.has(f))
	var best: Combatant = null
	for f in foes:
		if best == null or f.actor.pool.get_current("hp") < best.actor.pool.get_current("hp"):
			best = f
	var act := {"kind": "skill", "skill": _best_skill(b, c), "target": best}
	var rev := str(cfg.get("rev", "none"))
	if rev != "none" and c.rev >= BattleRev.cap(b.db):
		act["rev"] = c.rev  # 기세가 가득이면 모두 얹는다
	elif rev == "build":
		act["skill"] = Battle.BASIC_ATTACK  # 기세를 모은다
	return act


## 종족 stat_ranges의 가운데(반올림).
func _race_mid(db: GameDatabase, race: String) -> Dictionary:
	var out := {}
	var ranges := JsonUtil.get_dict(db.get_entry("races", race), "stat_ranges")
	for k: String in ranges:
		var r: Array = ranges[k]
		out[k] = roundf((float(r[0]) + float(r[1])) / 2.0)
	return out


## 쓸 수 있는 공격 스킬 중 위력 합이 가장 큰 것(정수 액티브), 없으면 기본 공격.
func _best_skill(b: Battle, c: Combatant) -> String:
	var best := Battle.BASIC_ATTACK
	var best_power := 1.0
	for sid in c.actor.skills:
		var sk := b.db.get_entry("skills", sid)
		if not JsonUtil.get_str(sk, "target") in ["enemy_single", "enemy_all"] or not b.can_use(c, sid).is_empty():
			continue
		var power := 0.0
		for e: Variant in JsonUtil.get_array(sk, "effects"):
			if e is Dictionary and JsonUtil.get_str(e, "type") == "damage":
				power += JsonUtil.get_float(e, "power", 1.0) * minf(1.0, JsonUtil.get_float(e, "accuracy", 95.0) / 95.0)
		power *= 100.0 / (100.0 + JsonUtil.get_float(sk, "delay_cost"))  # 다음 차례가 늦어지는 만큼 깎는다
		if JsonUtil.get_str(sk, "target") == "enemy_all":
			power *= float(b.opponents(c).size())
		if power > best_power:
			best = sid
			best_power = power
	return best
