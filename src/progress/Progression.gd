class_name Progression
extends RefCounted
## 성장(캐릭터 단위 영구 기록): 경험치(공적) · 도감 처치 수 · 레벨.
##   경험치는 같은 몬스터를 처음 잡을 때만(도감 채우기). 양 = 데이터 exp_first_kill, 없으면 (grade_base − 등급).
##   레벨 = 누적 경험치가 level.exp_table[레벨−1] 이상인 가장 높은 레벨(1차 상한 level.max_initial).
##   레벨이 오르면 영혼력 최대치가 오르고(자원 수식이 레벨을 쓴다) 정수 슬롯 수가 는다(정수 설정은 보류).
## 개체를 필드로 들지 않는다 — 레벨을 바꿀 때만 인자로 받는다.

var exp_total: int = 0
var kills: Dictionary = {}           # 몬스터 id -> 처치 수
var portals_opened: Dictionary = {}  # 포탈 id -> true (최초 개방 경험치, M6에서 부른다)


static func first_kill_exp(db: GameDatabase, monster_def: Dictionary) -> int:
	if monster_def.has("exp_first_kill"):
		return maxi(0, JsonUtil.get_int(monster_def, "exp_first_kill"))
	return maxi(1, int(db.bal("exp.grade_base", 10)) - JsonUtil.get_int(monster_def, "grade", 9))


## 처치를 기록한다. 처음 잡은 종이면 줄 경험치, 아니면 0.
func record_kill(db: GameDatabase, monster_id: String) -> int:
	var first := not kills.has(monster_id)
	kills[monster_id] = int(kills.get(monster_id, 0)) + 1
	return first_kill_exp(db, db.get_entry("monsters", monster_id)) if first else 0


func kill_count(monster_id: String) -> int:
	return int(kills.get(monster_id, 0))


## 포탈 최초 개방(M6에서 부른다). 처음이면 줄 경험치.
func record_portal(db: GameDatabase, portal_id: String) -> int:
	if portals_opened.has(portal_id):
		return 0
	portals_opened[portal_id] = true
	return int(db.bal("exp.portal_first_open", 2))


## 경험치를 더하고 레벨을 맞춘다. 새 레벨(안 올랐으면 지금 레벨).
func gain(a: Actor, amount: int) -> int:
	exp_total += maxi(0, amount)
	var lv := level_for(a.db, exp_total)
	if lv > a.get_level():
		a.set_level(lv)
	return a.get_level()


static func level_for(db: GameDatabase, total_exp: int) -> int:
	var table: Array = db.bal("level.exp_table", [0])
	var cap := int(db.bal("level.max_initial", 5))
	var lv := 1
	for i in table.size():
		if total_exp >= int(table[i]):
			lv = i + 1
	return clampi(lv, int(db.bal("level.min", 1)), cap)


## 다음 레벨까지 필요한 누적 경험치. 상한이면 -1.
static func exp_for_next(db: GameDatabase, level: int) -> int:
	var table: Array = db.bal("level.exp_table", [0])
	if level >= int(db.bal("level.max_initial", 5)) or level >= table.size():
		return -1
	return int(table[level])


static func essence_slots(db: GameDatabase, level: int) -> int:
	return level * int(db.bal("level.essence_slots_per_level", 1))


func to_dict() -> Dictionary:
	return {"exp": exp_total, "kills": kills.duplicate(), "portals": portals_opened.duplicate()}


func load_dict(d: Dictionary) -> void:
	exp_total = JsonUtil.get_int(d, "exp")
	kills = JsonUtil.get_dict(d, "kills").duplicate()
	portals_opened = JsonUtil.get_dict(d, "portals").duplicate()
