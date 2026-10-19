extends SceneTree
## 균열 파티 시뮬레이터(헤드리스, docs/PROMPT_FLOOR1_V2.md §15). check.sh에는 넣지 않는다.
##   godot --headless --path . --script res://tools/sim_party.gd -- [--n=300] [--only=<이름 일부>]
## --only를 주면 그 시나리오만 돌리고 리포트 파일은 쓰지 않는다(수치 맞추기용).
## --essences=real: 정수의 실제 고정 스탯·생명력을 붙인다(기본은 정수 스탯 없이 sim_parties.json의 stats만).
## --essence_mult=0.8: --essences=real의 스탯·생명력에 곱한다(정수 수치를 얼마나 깎을지 볼 때).
## --base=race: 기본 스탯을 sim_parties.json stats 대신 종족 굴림 범위의 가운데로(정수 성장만 따로 보기). 둘 중 하나라도 주면 리포트 파일은 쓰지 않는다.
## tools/sim_parties.json의 파티(Lv4 4인·포션·정수)로 시나리오마다 n번 싸워 승률을 보고 docs/balance/rift.md에 쓴다.
## 아군 AI: 생명력이 potion_hp_ratio 아래면 하급 포션, smart면 [예고]가 찍혔을 때 방어, 아니면 기본 공격
## (수호자·중간 보스가 있으면 그중 — 졸개가 셋 이상 쌓이면 졸개부터 —, 없으면 생명력이 가장 낮은 적).
## 시나리오 "party_statuses": [..] — 전투 전에 아군 전원에게 건다(빙하굴 3·4챕터 저체온증).
## 공격은 쓸 수 있는 정수 액티브 중 위력 합이 가장 큰 것, 없으면 기본 공격.

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
	cfg["real_essences"] = str(args.get("essences", "")) == "real"
	cfg["race_base"] = str(args.get("base", "")) == "race"
	cfg["essence_mult"] = str(args.get("essence_mult", "1")).to_float()
	var n := str(args["n"]).to_int()
	var lines := PackedStringArray(["# 균열 파티 시뮬레이션", "", "`tools/sim_party.gd`가 만든다(파티: `tools/sim_parties.json`, 시나리오당 %d회)." % n, "",
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
	if args.has("only") or bool(cfg["real_essences"]) or bool(cfg["race_base"]):
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
	return {"kind": "skill", "skill": _best_skill(b, c), "target": best}


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
