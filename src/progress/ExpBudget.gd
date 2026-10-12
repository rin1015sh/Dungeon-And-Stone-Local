class_name ExpBudget
extends RefCounted
## 경험치 예산 계산(tools/exp_budget.gd와 테스트가 쓴다, docs/PROMPT_FLOOR1_V2.md §5.4·§5.5).
##   층별 실제 합계 = 그 층 몬스터의 종별 첫 처치 경험치 합(Progression.first_kill_exp, 계층군주는 + lord_bonus).
##   층 = Progression.monster_floor. 같은 종을 여러 층에서 만나도 데이터 id는 하나라서 한 번만 센다.
##   예상 합계 = 층마다 max(실제, 목표). 1~4층 예상 합계 / 5레벨 문턱이 lv5_ratio_range 안이면 통과.


## {floors: {층: {actual, target, species}}, lv5_total, lv5_need, ratio, ok, problems, markdown}
static func report(db: GameDatabase) -> Dictionary:
	var targets: Dictionary = db.prog("budget.floor_targets", {})
	var floors := {}
	for k: Variant in targets:
		floors[int(str(k))] = {"actual": 0, "target": int(targets[k]), "species": 0}
	var problems := PackedStringArray()
	var ids: Array = db.get_collection("monsters").keys()
	ids.sort()
	for id: Variant in ids:
		var def := db.get_entry("monsters", str(id))
		var fl := Progression.monster_floor(def)
		var e := Progression.first_kill_exp(db, def)
		if JsonUtil.get_str(def, "rank") == str(db.prog("exp.lord_rank", "lord")):
			e += int(db.prog("exp.lord_bonus", 15))
		if fl <= 0:
			problems.append("%s: 층을 알 수 없다(floor 또는 floor_tags \"f<n>_\")" % id)
			continue
		if not floors.has(fl):
			floors[fl] = {"actual": 0, "target": 0, "species": 0}
		var row: Dictionary = floors[fl]
		row["actual"] = int(row["actual"]) + e
		if e > 0:
			row["species"] = int(row["species"]) + 1
	var lv5_need := Progression.exp_for_next(db, 4)
	var lv5_total := 0
	for f: Variant in db.prog("budget.lv5_floors", [1, 2, 3, 4]):
		var row: Dictionary = floors.get(int(f), {"actual": 0, "target": 0})
		lv5_total += maxi(int(row["actual"]), int(row["target"]))
	var ratio := float(lv5_total) / maxf(1.0, float(lv5_need))
	var rr: Array = db.prog("budget.lv5_ratio_range", [0.93, 0.99])
	var ok := ratio >= float(rr[0]) and ratio <= float(rr[1])
	if not ok:
		problems.append("1~4층 예상 합계 %d는 5레벨(%d)의 %.1f%% — 목표 %d~%d%%" % [lv5_total, lv5_need, ratio * 100.0,
			roundi(float(rr[0]) * 100.0), roundi(float(rr[1]) * 100.0)])
	var out := {"floors": floors, "lv5_total": lv5_total, "lv5_need": lv5_need, "ratio": ratio, "ok": ok, "problems": problems}
	out["markdown"] = _markdown(db, out)
	return out


static func _markdown(db: GameDatabase, r: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("# 경험치 예산 리포트")
	lines.append("")
	lines.append("`tools/exp_budget.gd`가 만든다. 기준: `data/progression.json`, 명세 `docs/PROMPT_FLOOR1_V2.md` §5.")
	lines.append("")
	lines.append("| 층 | 데이터 종 수 | 실제 합계 | 목표 | 예상(합산에 쓰는 값) |")
	lines.append("|---|---|---|---|---|")
	var floors: Dictionary = r["floors"]
	var keys: Array = floors.keys()
	keys.sort()
	var cum := 0
	for k: Variant in keys:
		var row: Dictionary = floors[k]
		var used := maxi(int(row["actual"]), int(row["target"]))
		cum += used
		var mark := "" if int(row["actual"]) >= int(row["target"]) else " (예상)"
		lines.append("| %d | %d | %d | %d | %d%s · 누적 %d |" % [int(k), int(row["species"]), int(row["actual"]),
			int(row["target"]), used, mark, cum])
	lines.append("")
	lines.append("- 1~4층 예상 합계 **%d** / 5레벨 문턱 %d = **%.1f%%** → %s" % [int(r["lv5_total"]), int(r["lv5_need"]),
		float(r["ratio"]) * 100.0, "통과" if bool(r["ok"]) else "실패"])
	lines.append("- 히든·특수 목표 %d (숨겨진 포탈 등, 몬스터 데이터와 별도)" % int(db.prog("budget.hidden_target", 0)))
	lines.append("")
	lines.append("## 레벨 표")
	lines.append("")
	lines.append("| 레벨 | 누적 경험치 |")
	lines.append("|---|---|")
	var table := Progression.exp_table(db)
	for i in table.size():
		lines.append("| %d | %d |" % [i + 1, int(table[i])])
	var problems: PackedStringArray = r["problems"]
	if not problems.is_empty():
		lines.append("")
		lines.append("## 문제")
		lines.append("")
		for p: String in problems:
			lines.append("- " + p)
	lines.append("")
	return "\n".join(lines)
