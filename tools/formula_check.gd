extends SceneTree
## 피해 공식 점검(docs/PROMPT_FLOOR1_V2.md §1 "목표 피해량"·기준 탐험가). 헤드리스:
##   godot --headless --path . --script res://tools/formula_check.gd [-- --legacy]
## --legacy: G2 이전 공식(근력×1, 방어×1, 옛 무기값)으로 같은 표를 출력만 한다(파일은 쓰지 않음).
## 몬스터마다 기본 공격·가장 센 피해 스킬의 평균 피해(명중·편차 중간, 치명 없음)를 기준 탐험가 셋에게 계산하고,
## 기준 탐험가의 평타가 몬스터를 몇 번에 잡는지 계산해 docs/balance/formula.md에 쓴다.
## 목표: 균열 Lv4 기준 탐험가에게 평타 9등급 ~15, 8등급 ~25, 7등급 ~35(±40%면 통과로 본다). 벗어나면 종료 코드 1.
## 일반·정예만 판정하고(마법형은 평타와 스킬 중 큰 값), 무등급·보스급은 참고로 적는다
## (변이종이 위로 벗어나는 것은 원작 2층 필드급이라 참고로만 적는다).

const OUT := "res://docs/balance/formula.md"
## [이름, 스탯, 레벨, 무기 공격력]. 무기는 근력에 (무기 − 맨손)/2를 더해 흉내 낸다(피해 계산에만 쓴다).
const BENCHES := [
	["인간 Lv1", {"str": 12, "agi": 12, "p_res": 8, "m_res": 5, "int": 8}, 1, 10],
	["바바리안 Lv1", {"str": 18, "agi": 10, "p_res": 12, "m_res": 3, "int": 4}, 1, 12],
	["균열 Lv4", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10}, 4, 14],
]
const TARGET_BY_GRADE := {9: 15.0, 8: 25.0, 7: 35.0}
const TOLERANCE := 0.4
## 목표로 판정하는 랭크. 무등급(전투력이 약한 쥐·잡몹)과 중간 보스·수호자·군주(파티 시뮬레이터로 맞춤)는 참고로만.
const JUDGED_RANKS := ["normal", "elite"]
const ROLLS := {"hit": 0.0, "crit": 1.0, "var": 0.5, "lethal": 1.0}


func _initialize() -> void:
	var db := GameDatabase.new()
	db.load_all("res://data")
	var legacy := OS.get_cmdline_user_args().has("--legacy")
	var benches: Array = BENCHES.duplicate(true)
	if legacy:
		# G2 이전 공식과 비교: 공격력 = 무기 + 근력×1, 방어 100/(100+방어), 무기 공격력 옛값(검 5·도끼 대용 6·Lv4 7).
		var c: Dictionary = db.singletons["balance"]["combat"]
		c["phys_atk_per_str"] = 1.0
		c["mag_atk_per_int"] = 1.0
		c["defense_per_point"] = 1.0
		for b: Array in benches:
			b[3] = {10: 5, 12: 6, 14: 7}[b[3]]
	var lines := PackedStringArray()
	var problems := PackedStringArray()
	lines.append("# 피해 공식 점검")
	lines.append("")
	lines.append("`tools/formula_check.gd`가 만든다. 공식은 명세 §1, 평균 피해(편차 중간·치명 없음).")
	lines.append("목표: 균열 Lv4 기준 탐험가(18·16·14·8·10, 생명력 159)에게 평타 9등급 ~15 · 8등급 ~25 · 7등급 ~35 (±%d%%)." % roundi(TOLERANCE * 100))
	lines.append("")
	var defenders: Array[Actor] = []
	var hdr := "| 몬스터 | 등급 | "
	for b: Array in benches:
		defenders.append(_bench(db, b, false))
		hdr += "%s(생명력 %d) | " % [b[0], roundi(defenders[-1].pool.get_max("hp"))]
	lines.append("## 몬스터 → 탐험가 (칸 = 평타 / 가장 센 피해 스킬 (생명력 대비 %))")
	lines.append("")
	lines.append(hdr + "판정 |")
	lines.append("|---|---|" + "---|".repeat(benches.size()) + "---|")
	var ids: Array = db.get_collection("monsters").keys()
	ids.sort()
	for id: Variant in ids:
		var m := Monster.create(db, str(id))
		var grade := JsonUtil.get_int(m.def, "grade", 9)
		var row := "| %s | %d |" % [m.display_name, grade]
		var lv4_basic := 0.0
		for d: Actor in defenders:
			var basic := _avg(db, m, d, _skill_damage(db, Battle.BASIC_ATTACK))
			var best := 0.0
			for sid: String in _monster_skills(m):
				best = maxf(best, _avg(db, m, d, _skill_damage(db, sid)))
			row += " %d / %d (%d%%) |" % [roundi(basic), roundi(best), roundi(maxf(basic, best) / d.pool.get_max("hp") * 100.0)]
			# 마법형(평타가 약하고 스킬이 주력)은 둘 중 큰 값으로 본다.
			lv4_basic = maxf(basic, best) if natural_weak(m) else basic
		var verdict := "참고(%s)" % JsonUtil.get_str(m.def, "rank", "normal")
		if TARGET_BY_GRADE.has(grade) and JsonUtil.get_str(m.def, "rank", "normal") in JUDGED_RANKS:
			var t: float = TARGET_BY_GRADE[grade]
			var ok := absf(lv4_basic - t) <= t * TOLERANCE
			# 변이종은 원작에서 한 층 아래(2층 필드) 몬스터라 위로 벗어나는 것은 참고로만 적는다(명세 §6).
			var variant := not JsonUtil.get_str(m.def, "variant_of").is_empty() and lv4_basic > t
			verdict = "%s (목표 ~%d)" % ["통과" if ok else ("높음 · 변이종" if variant else "벗어남"), roundi(t)]
			if not ok and not variant:
				problems.append("%s 평타 %d — 목표 ~%d" % [m.display_name, roundi(lv4_basic), roundi(t)])
		lines.append(row + " " + verdict + " |")
	lines.append("")
	lines.append("## 탐험가 평타 → 몬스터 (피해 · 명중률 · 처치까지 평타 수)")
	lines.append("")
	var h2 := "| 몬스터 | 생명력 · 물리내성 |"
	for b: Array in benches:
		h2 += " %s |" % b[0]
	lines.append(h2)
	lines.append("|---|---|" + "---|".repeat(benches.size()))
	for id: Variant in ids:
		var m := Monster.create(db, str(id))
		var hp := m.pool.get_max("hp")
		var row := "| %s | %d · %d |" % [m.display_name, roundi(hp), roundi(m.stats.get_value("p_res"))]
		for b: Array in benches:
			var atk := _bench(db, b, true)
			var dmg := _avg(db, atk, m, _skill_damage(db, Battle.BASIC_ATTACK))
			var hit := DamageCalc.hit_chance(db, atk, m, false)
			row += " %d · %d%% · %d타 |" % [roundi(dmg), roundi(hit * 100.0), ceili(hp / maxf(1.0, dmg))]
		lines.append(row)
	lines.append("")
	lines.append("- 결과: %s" % ("모든 목표 통과" if problems.is_empty() else "%d개 벗어남" % problems.size()))
	for p in problems:
		lines.append("  - " + p)
	lines.append("")
	if legacy:
		print("\n".join(lines))
		quit(0)
		return
	var dir := DirAccess.open("res://")
	dir.make_dir_recursive("docs/balance")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	print("\n".join(lines))
	quit(0 if problems.is_empty() else 1)


## 기준 탐험가. as_attacker면 무기 공격력을 근력으로 흉내 낸다.
func _bench(db: GameDatabase, b: Array, as_attacker: bool) -> Actor:
	var stats: Dictionary = (b[1] as Dictionary).duplicate()
	if as_attacker:
		stats["str"] = float(stats["str"]) + (float(b[3]) - float(db.bal("combat.unarmed_atk", 2))) / float(db.bal("combat.phys_atk_per_str", 2.0))
	var a := Actor.new(db, stats)
	a.set_level(int(b[2]))
	a.pool.fill_all()
	return a


func _skill_damage(db: GameDatabase, skill_id: String) -> Array:
	var out: Array = []
	for e: Variant in JsonUtil.get_array(db.get_entry("skills", skill_id), "effects"):
		if e is Dictionary and JsonUtil.get_str(e, "type") == "damage":
			out.append(e)
	return out


## 효과 목록의 평균 피해 합(명중 확률 반영 안 함 — 맞았을 때 값).
func _avg(db: GameDatabase, src: Actor, tgt: Actor, effects: Array) -> float:
	var total := 0.0
	for e: Dictionary in effects:
		var eff := e.duplicate()
		eff["accuracy"] = 1000.0
		total += float(DamageCalc.resolve(db, src, tgt, eff, ROLLS)["amount"]) * JsonUtil.get_float(e, "hits", 1.0)
	return total


func _monster_skills(m: Monster) -> Array[String]:
	var out: Array[String] = []
	for r: Variant in JsonUtil.get_array(m.def, "ai"):
		var s := JsonUtil.get_str(r, "use")
		if not s.is_empty() and not out.has(s):
			out.append(s)
	for s: Variant in JsonUtil.get_array(m.def, "ai_cycle"):
		if not out.has(str(s)):
			out.append(str(s))
	return out


## 평타가 스킬보다 약한 마법형(정신력이 근력보다 높다).
func natural_weak(m: Monster) -> bool:
	return m.stats.get_value("int") > m.stats.get_value("str")
