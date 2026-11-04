extends SceneTree
## 1층 혼자 원정 생존율(헤드리스 — 밸런스 확인용, check.sh에는 넣지 않는다).
## 한 명의 Lv1 탐험가가 무리를 연달아 만난다(생명력은 이어진다). 한 판씩 이기는 확률(sim_battle)이 아니라 "원정 중 죽지 않고 몇 번 싸우나"를 본다.
##   godot --headless --path . --script res://tools/sim_survive.gd -- [--n=200] [--fights=40] [--pack=1,1] [--potions=2] [--rest=0.5] [--essence=goblin]
## --pack=a,b: 한 무리 마릿수 [최소, 최대](1층 pack_by_day — 1~3일 차 [1,1], 4~5일 [1,2], 6~7일 [2,3]).
## --potions: 하급 포션 개수(생명력이 potion_at 아래면 마신다 — 최대 생명력 15% 또는 40 중 큰 값).
## --rest=r: 생명력이 r 아래면 여관 밖에서 쉰다(rest_hours 8 × 시간당 5% 회복, 쉬는 동안 매복 시간당 4% — 걸리면 그 무리와 싸운다). 0이면 쉬지 않는다.
## --drops=on: 이긴 뒤 정수 드롭을 실제로 굴려(DropPickup — 연속 실패 보정 포함) 나온 정수를 흡수한다. --pity=off면 보정을 끈다. --level=n: 시작 레벨(정수 칸 수).
## --essence=<id>: 그 정수 하나를 흡수한 채(1층 Lv1 슬롯 1칸). 없으면 정수 없음.

const MONSTERS := ["blade_wolf", "gnome", "ghoul", "goblin"]


func _initialize() -> void:
	var args := {"n": "200", "fights": "40", "pack": "1,1", "potions": "2", "rest": "0.5", "essence": "", "drops": "off", "pity": "on", "level": "1"}
	for a: String in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var db := GameDatabase.new()
	db.load_all("res://data")
	var n := str(args["n"]).to_int()
	var fights := str(args["fights"]).to_int()
	var pack := str(args["pack"]).split(",")
	var pmin := str(pack[0]).to_int()
	var pmax := str(pack[1]).to_int() if pack.size() > 1 else pmin
	var potions0 := str(args["potions"]).to_int()
	var rest_at := str(args["rest"]).to_float()
	var ess := str(args["essence"])
	var drops_on := str(args["drops"]) == "on"
	if str(args["pity"]) == "off":
		((db.singletons["balance"] as Dictionary)["essence"] as Dictionary)["pity"] = {"enabled": false}
	var absorbed_sum := 0
	var died_at: Array[int] = []
	var survived := 0
	var hp_sum := 0.0
	var fights_done := 0
	for i in n:
		var rng := Rng.new(7000 + i)
		var race := str(rng.pick(["human", "barbarian"]))
		var cls := str(rng.pick(["warrior", "swordsman", "spearman", "archer"]))
		var pc := PlayerCharacter.create(db, race, cls, "sim", CharacterRoller.roll_base_stats(db, race, cls, rng))
		pc.set_level(str(args["level"]).to_int())
		pc.pool.fill_all()
		if not ess.is_empty():
			pc.essences.absorb(pc, EssenceDrop.make(db, ess, "red", Rng.new(3)))
			pc.pool.fill_all()
		var potions := potions0
		var dead := false
		var f := 0
		while f < fights and not dead:
			var size := rng.randi_range(pmin, pmax)
			var sc: Array = []
			var kind := str(rng.pick(MONSTERS))
			for k in size:
				sc.append(kind)
			var res := _fight(db, rng, pc, sc, i * 100 + f)
			f += 1
			fights_done += 1
			if not res:
				dead = true
				break
			if drops_on:
				var killed: Array[String] = []
				for k in size:
					killed.append(kind)
				for dr: Dictionary in DropPickup.roll(db, killed, rng, false, 1.0, [], pc):
					if str(dr["kind"]) == "essence" and pc.essences.absorb(pc, dr["inst"]).is_empty():
						absorbed_sum += 1
			var ratio := pc.pool.get_ratio("hp")
			if potions > 0 and ratio < 0.4:
				pc.pool.modify("hp", maxf(40.0, 0.15 * pc.pool.get_max("hp")), "potion")
				potions -= 1
			ratio = pc.pool.get_ratio("hp")
			if rest_at > 0.0 and ratio < rest_at:
				for h in int(db.bal("explore.rest_hours", 8.0)):
					pc.pool.modify("hp", 0.05 * pc.pool.get_max("hp"), "rest")
					if rng.randf() < float(db.bal("monsters.rest_ambush_chance_per_hour", 0.04)):
						if not _fight(db, rng, pc, [str(rng.pick(MONSTERS))], i * 100 + f + 50):
							dead = true
							break
				if dead:
					break
		if dead:
			died_at.append(f)
		else:
			survived += 1
			hp_sum += pc.pool.get_ratio("hp")
	var avg_death := 0.0
	for d in died_at:
		avg_death += d
	print("1층 혼자 원정 — Lv1%s, 무리 %d~%d마리, 연속 %d판, 포션 %d, 휴식 %.0f%%, %d명" % [
		(" + 정수 " + ess) if not ess.is_empty() else "", pmin, pmax, fights, potions0, rest_at * 100.0, n])
	if drops_on:
		print("  원정 중 얻은 정수 평균 %.2f개 (보정 %s)" % [float(absorbed_sum) / n, str(args["pity"])])
	print("  생존 %.0f%% · 사망 %d명(평균 %.1f번째 판에서)" % [100.0 * survived / n, died_at.size(), avg_death / maxf(1.0, died_at.size())])
	quit(0)


func _fight(db: GameDatabase, rng: Rng, pc: PlayerCharacter, sc: Array, seed_i: int) -> bool:
	var party: Array[Actor] = [pc]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(5000 + seed_i), party, sc)
	for t in 400:
		var c := b.next_turn()
		if c == null:
			break
		b.act(c, b.ai_action(c))
	return b.result == Battle.RESULT_VICTORY
