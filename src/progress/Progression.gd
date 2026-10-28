class_name Progression
extends RefCounted
## 성장(캐릭터 단위 영구 기록): 경험치(공적) · 도감 처치 수 · 레벨 (docs/PROMPT_FLOOR1_V2.md §5, data/progression.json).
##   획득원: 종별 첫 처치(grade_base − 등급, 상위 변이종 +1, 무등급·토큰 0) · 수호자 처치(반복, 8층 이상 더 많이)
##          · 계층군주 처치(군주별 1회) · 포탈 통과(매달 포탈마다 첫 통과, 6층부터는 1회) · 숨겨진 포탈 최초 개방 · 꿈꾸는 영혼.
##   레벨 = 누적 경험치가 level.exp_table[레벨−1] 이상인 가장 높은 레벨(최대 level.max).
##   레벨이 바뀌면 PlayerCharacter.set_level이 영혼력·생명력(자원 수식)과 정수 슬롯 잠금을 맞춘다.
## 개체를 필드로 들지 않는다 — 레벨을 바꿀 때만 인자로 받는다.

var exp_total: int = 0
var kills: Dictionary = {}           # 몬스터 id -> 처치 수
var portals_opened: Dictionary = {}  # 포탈 기록 키 -> true (기록 키 = 포탈 id 또는 "포탈 id@달")
var lords_defeated: Dictionary = {}  # 계층군주 id -> true
var dreaming_soul: String = ""       # "" / "waiting"(먹었지만 10레벨 전) / "done"
var explorer_grade: int = 0          # 탐험가 등급(신원패 — 9 → 1, 0 = 아직 정하지 않음 → city.json settle.grade) — GuildSettle(CT59)
var settled_total: int = 0           # 길드 귀환 정산으로 받은 스톤 누계(등급 오르기 조건)
## 마지막 record_kill의 내역 {first, guardian, lord}(보상 메시지용).
var last_kill: Dictionary = {}


## 종별 첫 처치 경험치. 무등급·토큰은 0.
static func first_kill_exp(db: GameDatabase, monster_def: Dictionary) -> int:
	if JsonUtil.get_str(monster_def, "rank", "normal") in (db.prog("exp.no_exp_ranks", []) as Array):
		return 0
	var v := int(db.prog("exp.grade_base", 10)) - JsonUtil.get_int(monster_def, "grade", 9)
	if JsonUtil.get_bool(monster_def, "upper_variant"):
		v += int(db.prog("exp.upper_variant_bonus", 1))
	return maxi(0, v)


## 수호자 처치 보너스(반복). 수호자가 아니면 0. 층은 몬스터의 floor(없으면 floor_tags의 "f<n>_").
static func guardian_exp(db: GameDatabase, monster_def: Dictionary) -> int:
	if not JsonUtil.get_str(monster_def, "rank", "normal") in (db.prog("exp.guardian_ranks", []) as Array):
		return 0
	if monster_floor(monster_def) >= int(db.prog("exp.guardian_deep_floor", 8)):
		return int(db.prog("exp.guardian_bonus_deep", 5))
	return int(db.prog("exp.guardian_bonus", 3))


## 몬스터가 나오는 층(모르면 0).
static func monster_floor(monster_def: Dictionary) -> int:
	if monster_def.has("floor"):
		return JsonUtil.get_int(monster_def, "floor")
	for t: Variant in JsonUtil.get_array(monster_def, "floor_tags"):
		var s := str(t)
		if s.begins_with("f"):
			var n := s.substr(1).get_slice("_", 0)
			if n.is_valid_int():
				return n.to_int()
	return 0


## 처치를 기록하고 줄 경험치 합을 돌려준다(첫 처치 + 수호자 + 군주). 내역은 last_kill.
func record_kill(db: GameDatabase, monster_id: String) -> int:
	var def := db.get_entry("monsters", monster_id)
	var first := not kills.has(monster_id)
	kills[monster_id] = int(kills.get(monster_id, 0)) + 1
	last_kill = {"first": first_kill_exp(db, def) if first else 0, "guardian": guardian_exp(db, def), "lord": 0}
	if JsonUtil.get_str(def, "rank") == str(db.prog("exp.lord_rank", "lord")) and not lords_defeated.has(monster_id):
		lords_defeated[monster_id] = true
		last_kill["lord"] = int(db.prog("exp.lord_bonus", 15))
	return int(last_kill["first"]) + int(last_kill["guardian"]) + int(last_kill["lord"])


func kill_count(monster_id: String) -> int:
	return int(kills.get(monster_id, 0))


## 포탈 통과(개방). 1~5층 포탈은 달(month)마다 첫 통과에 경험치, 그보다 깊은 층은 처음 한 번. 줄 경험치.
func record_portal(db: GameDatabase, portal_id: String, floor_no: int = 1, month: int = 0) -> int:
	var key := portal_id
	if floor_no <= int(db.prog("exp.portal_monthly_reset_max_floor", 5)):
		key = "%s@%d" % [portal_id, month]
	if portals_opened.has(key):
		return 0
	portals_opened[key] = true
	return int(db.prog("exp.portal_monthly", 2))


## 숨겨진 지역 포탈 최초 개방(1회). 줄 경험치.
func record_hidden_portal(db: GameDatabase, portal_id: String) -> int:
	var key := "hidden:" + portal_id
	if portals_opened.has(key):
		return 0
	portals_opened[key] = true
	return int(db.prog("exp.hidden_portal_first", 99))


## 꿈꾸는 영혼을 먹는다. 10레벨이면 바로, 아니면 10레벨에 닿을 때 경험치를 받는다. 이미 먹었으면 false.
func use_dreaming_soul(a: Actor) -> bool:
	if not dreaming_soul.is_empty():
		return false
	dreaming_soul = "waiting"
	gain(a, 0)
	return true


## 경험치를 더하고 레벨을 맞춘다. 새 레벨.
func gain(a: Actor, amount: int, rng: Rng = null) -> int:
	exp_total += maxi(0, amount)
	if dreaming_soul == "waiting" and level_for(a.db, exp_total) >= int(a.db.prog("exp.dreaming_soul_min_level", 10)):
		dreaming_soul = "done"
		exp_total += int(a.db.prog("exp.dreaming_soul", 10000))
	_apply_level(a, rng)
	return a.get_level()


## 레벨을 정해 맞춘다(디버그). 누적 경험치도 그 레벨의 시작값으로 맞춘다 — 레벨만 바꾸면 다음 경험치(전투 보상)에서
## 레벨이 경험치 기준으로 되돌아가 정수가 잠긴다(스킬이 사라진다). 새 레벨.
func set_to_level(a: Actor, level: int, rng: Rng = null) -> int:
	exp_total = exp_for_level(a.db, clampi(level, int(a.db.prog("level.min", 1)), max_level(a.db)))
	_apply_level(a, rng)
	return a.get_level()


## 경험치를 잃는다(영혼 베기 같은 함정·스킬). 레벨이 내려가면 정수 슬롯이 무작위로 잠긴다. 새 레벨.
func lose(a: Actor, amount: int, rng: Rng = null) -> int:
	exp_total = maxi(0, exp_total - maxi(0, amount))
	_apply_level(a, rng)
	return a.get_level()


func _apply_level(a: Actor, rng: Rng) -> void:
	var lv := level_for(a.db, exp_total)
	if lv == a.get_level():
		return
	# PlayerCharacter.change_level(정수 슬롯 잠금까지). 클래스 이름을 직접 쓰면 스크립트 순환 참조로 종료 시 누수가 난다.
	if a.has_method("change_level"):
		a.call("change_level", lv, rng)
	else:
		a.set_level(lv)


static func level_for(db: GameDatabase, total_exp: int) -> int:
	var table := exp_table(db)
	var lv := 1
	for i in table.size():
		if total_exp >= int(table[i]):
			lv = i + 1
	return clampi(lv, int(db.prog("level.min", 1)), max_level(db))


## 다음 레벨이 되는 누적 경험치. 최대 레벨이면 -1.
static func exp_for_next(db: GameDatabase, level: int) -> int:
	var table := exp_table(db)
	if level >= max_level(db) or level >= table.size():
		return -1
	return int(table[level])


## 지금 레벨이 시작된 누적 경험치.
static func exp_for_level(db: GameDatabase, level: int) -> int:
	var table := exp_table(db)
	return int(table[clampi(level - 1, 0, table.size() - 1)]) if not table.is_empty() else 0


static func exp_table(db: GameDatabase) -> Array:
	var t: Variant = db.prog("level.exp_table", [0])
	return t if t is Array else [0]


static func max_level(db: GameDatabase) -> int:
	return int(db.prog("level.max", 11))


static func essence_slots(db: GameDatabase, level: int) -> int:
	return level * int(db.prog("level.essence_slots_per_level", 1))


func to_dict() -> Dictionary:
	return {"exp": exp_total, "kills": kills.duplicate(), "portals": portals_opened.duplicate(),
		"lords": lords_defeated.duplicate(), "dreaming_soul": dreaming_soul, "explorer_grade": explorer_grade, "settled_total": settled_total}


func load_dict(d: Dictionary) -> void:
	exp_total = JsonUtil.get_int(d, "exp")
	kills = JsonUtil.get_dict(d, "kills").duplicate()
	portals_opened = JsonUtil.get_dict(d, "portals").duplicate()
	lords_defeated = JsonUtil.get_dict(d, "lords").duplicate()
	dreaming_soul = JsonUtil.get_str(d, "dreaming_soul")
	explorer_grade = JsonUtil.get_int(d, "explorer_grade")
	settled_total = JsonUtil.get_int(d, "settled_total")
