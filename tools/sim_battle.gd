extends SceneTree
## 전투 시뮬레이터(헤드리스, docs/PROMPT_FLOOR1_V2.md §15). 밸런스 확인용 — check.sh에는 넣지 않는다.
##   godot --headless --path . --script res://tools/sim_battle.gd -- [--n=200] [--speed_base=10] [--level=1] [--bench]
## --bench: 무작위 캐릭터 대신 명세 기준 탐험가(인간 검사, 기준 스탯 고정)로 싸운다.
## 1층 필드 시나리오마다 종족·템플릿을 무작위로 굴린 Lv1 탐험가(기본 공격만, 포션 없음)로 n번 싸워
## 승률 · 평균 차례 수 · "적 행동 / 아군 행동" 비율을 출력한다. --speed_base를 주면 balance 값을 덮어쓴다.

## [몬스터 목록, 목표 승률(최소)]. 시뮬레이터 탐험가는 기본 공격만(포션·정수·도주 없음) 쓰므로 실제보다 약하다.
## 1층 필드: 원종 하나는 거의 이기고, 무리·변이종은 위험하게(명세 §15 "인간 Lv1 vs 고블린 1체 95%+", PROMPT §15 "초반이 잔혹하지만 극복 가능").
const SCENARIOS := [
	[["goblin"], 0.95], [["goblin", "goblin"], 0.7], [["goblin", "goblin", "goblin"], 0.3], [["goblin", "goblin_archer", "goblin_swordsman"], 0.2],
	[["ghoul"], 0.9], [["blade_wolf"], 0.9], [["blade_wolf", "blade_wolf"], 0.4], [["gnome"], 0.9], [["gnome", "gnome"], 0.7],
	[["goblin_swordsman"], 0.8], [["goblin_archer"], 0.8], [["elder_ghoul"], 0.5], [["giant_blade_wolf"], 0.6],
	[["blood_blade_wolf"], 0.7], [["corrupted_gnome"], 0.7],
]
## 명세 §1 기준 탐험가(인간 Lv1 12·12·8·5·8, 한손검)
const BENCH := {"str": 12, "agi": 12, "p_res": 8, "m_res": 5, "int": 8}


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
	print("%-44s %6s %6s %7s %9s" % ["시나리오", "승률", "목표", "평균차례", "적/아군행동"])
	var misses := 0
	for row: Array in SCENARIOS:
		var sc: Array = row[0]
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
			var bases := CharacterRoller.roll_base_stats(db, race, cls, rng)
			if args.has("bench"):
				race = "human"
				cls = "swordsman"
				bases = BENCH
			var pc := PlayerCharacter.create(db, race, cls, "sim", bases)
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
		var rate := float(wins) / n
		var ok := rate >= float(row[1])
		if not ok:
			misses += 1
		print("%-44s %5.0f%% %5.0f%% %7.1f %9.2f %s" % [" + ".join(sc), 100.0 * rate, 100.0 * float(row[1]), float(turns) / n,
			float(foe_acts) / maxf(1.0, float(ally_acts)), "" if ok else "← 목표 미달"])
	print("목표 미달 %d개" % misses)
	quit(0)
