extends SceneTree
## 균열 파티 시뮬레이터(헤드리스, docs/PROMPT_FLOOR1_V2.md §15). check.sh에는 넣지 않는다.
##   godot --headless --path . --script res://tools/sim_party.gd -- [--n=300]
## tools/sim_parties.json의 파티(Lv4 4인·포션·정수)로 시나리오마다 n번 싸워 승률을 보고 docs/balance/rift.md에 쓴다.
## 아군 AI: 생명력이 potion_hp_ratio 아래면 하급 포션, smart면 [예고]가 찍혔을 때 방어, 아니면 생명력이 가장 낮은 적을 기본 공격.

const CFG := "res://tools/sim_parties.json"
const OUT := "res://docs/balance/rift.md"


func _initialize() -> void:
	var args := {"n": "300"}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var db := GameDatabase.new()
	db.load_all("res://data")
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CFG))
	var n := str(args["n"]).to_int()
	var lines := PackedStringArray(["# 균열 파티 시뮬레이션", "", "`tools/sim_party.gd`가 만든다(파티: `tools/sim_parties.json`, 시나리오당 %d회)." % n, "",
		"| 시나리오 | 승률 | 목표 | 평균 차례 | 쓰러진 아군(평균) |", "|---|---|---|---|---|"])
	var misses := 0
	for sc: Dictionary in cfg["scenarios"]:
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
		var pc := PlayerCharacter.create(db, str(m["race"]), str(m["class"]), str(m["name"]), m["stats"])
		pc.set_level(int(cfg["level"]))
		for e: Dictionary in m["essences"]:
			pc.essences.absorb(pc, {"essence": e["essence"], "color": e["color"], "stats": {}})
		for item: String in cfg["items"]:
			pc.inventory.add(item, int(cfg["items"][item]))
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
		b.act(c, _party_action(b, c, cfg, str(sc["ai"])) if c.side == Combatant.SIDE_PARTY else b.ai_action(c))
	var downs := party.filter(func(a: Actor) -> bool: return a.dead).size()
	return {"win": b.result == Battle.RESULT_VICTORY, "turns": t, "downs": downs}


func _party_action(b: Battle, c: Combatant, cfg: Dictionary, ai: String) -> Dictionary:
	var a := c.actor
	if a.pool.get_ratio("hp") < float(cfg["potion_hp_ratio"]) and a.inventory.count("minor_potion") > 0:
		return {"kind": "item", "item": "minor_potion"}
	if ai == "smart" and a.statuses.has("telegraphed"):
		return {"kind": "guard"}
	var foes := BattleRules.targetable(b, c)
	var best: Combatant = null
	for f in foes:
		if best == null or f.actor.pool.get_current("hp") < best.actor.pool.get_current("hp"):
			best = f
	return {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": best}
