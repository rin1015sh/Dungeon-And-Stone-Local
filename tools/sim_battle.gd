extends SceneTree
## 전투 시뮬레이터(헤드리스, docs/PROMPT_FLOOR1_V2.md §15). 밸런스 확인용 — check.sh에는 넣지 않는다.
##   godot --headless --path . --script res://tools/sim_battle.gd -- [--n=200] [--speed_base=10] [--level=1]
## 1층 필드 시나리오마다 종족·템플릿을 무작위로 굴린 Lv1 탐험가(기본 공격만, 포션 없음)로 n번 싸워
## 승률 · 평균 차례 수 · "적 행동 / 아군 행동" 비율을 출력한다. --speed_base를 주면 balance 값을 덮어쓴다.

const SCENARIOS := [
	["goblin"], ["goblin", "goblin", "goblin"], ["ghoul"], ["blade_wolf"], ["blade_wolf", "blade_wolf"],
	["gnome"], ["gnome", "gnome"],
]


func _initialize() -> void:
	var args := {"n": "200", "level": "1"}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var db := GameDatabase.new()
	db.load_all("res://data")
	if args.has("speed_base"):
		(db.singletons["balance"]["combat"] as Dictionary)["speed_base"] = str(args["speed_base"]).to_float()
	var n := str(args["n"]).to_int()
	var level := str(args["level"]).to_int()
	print("전투 시뮬레이터 — speed_base %s, Lv%d, 시나리오당 %d회" % [str(db.bal("combat.speed_base", 0)), level, n])
	print("%-34s %6s %7s %9s" % ["시나리오", "승률", "평균차례", "적/아군행동"])
	for sc: Array in SCENARIOS:
		var wins := 0
		var turns := 0
		var ally_acts := 0
		var foe_acts := 0
		for i in n:
			var rng := Rng.new(1000 + i)
			var races: Array = ["human", "barbarian"]
			var classes: Array = ["warrior", "swordsman", "spearman", "archer"]
			var race := str(rng.pick(races))
			var cls := str(rng.pick(classes))
			var pc := PlayerCharacter.create(db, race, cls, "sim", CharacterRoller.roll_base_stats(db, race, cls, rng))
			pc.set_level(level)
			pc.pool.fill_all()
			var party: Array[Actor] = [pc]
			var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(5000 + i), party, sc, i % 2 == 0)
			for t in 400:
				var c := b.next_turn()
				if c == null:
					break
				if c.side == Combatant.SIDE_PARTY:
					ally_acts += 1
				else:
					foe_acts += 1
				turns += 1
				b.act(c, b.ai_action(c))
			if b.result == Battle.RESULT_VICTORY:
				wins += 1
		print("%-34s %5.0f%% %7.1f %9.2f" % [" + ".join(sc), 100.0 * wins / n, float(turns) / n,
			float(foe_acts) / maxf(1.0, float(ally_acts))])
	quit(0)
