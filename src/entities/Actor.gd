class_name Actor
extends RefCounted
## 탐험·전투의 개체(플레이어·동료·몬스터 공통). 컴포넌트 조합:
##   StatBlock(스탯) · ResourcePool(자원) · StatusSet(상태이상) · Inventory(소지품) · LightSource(광원)
## 자원 임계값·고갈을 상태이상으로 잇고, 생명력이 0이 되면 died를 낸다.
## 오토로드를 참조하지 않는다(테스트에서 직접 만든다).

signal died(cause: String)
signal status_changed(status_id: String, active: bool)

var id: String = ""
var display_name: String = ""
var db: GameDatabase
var stats: StatBlock
var pool: ResourcePool
var statuses: StatusSet
var inventory: Inventory
var light: LightSource
var dead: bool = false
var death_cause: String = ""
## 쓸 수 있는 스킬 id(전투). 기본 공격(basic_attack)은 커맨드로 따로 쓴다.
## 기본 스킬(대화·조사, 스킬 데이터의 "innate": true)도 여기에 들어간다.
var skills: Array[String] = []


## bases: 기본 스탯. resource_ids가 비면 활성 자원 전부. overrides: 자원 최대치 고정값(몬스터).
func _init(p_db: GameDatabase, bases: Dictionary = {}, level: int = 1, resource_ids: Array = [],
		overrides: Dictionary = {}) -> void:
	db = p_db
	stats = StatBlock.new(db.stats)
	stats.set_bases(bases)
	pool = ResourcePool.new(db, stats, resource_ids, overrides, level)
	statuses = StatusSet.new(db, stats, pool)
	inventory = Inventory.new()
	light = LightSource.new()
	pool.threshold_crossed.connect(_on_threshold)
	pool.depleted.connect(_on_depleted)
	pool.recovered.connect(_on_recovered)
	# 람다로 self를 잡으면 RefCounted 순환 참조(누수)가 생기므로 메서드로 잇는다.
	statuses.applied.connect(_on_status_applied)
	statuses.removed.connect(_on_status_removed)


func get_level() -> int:
	return pool.get_level()


func set_level(level: int) -> void:
	pool.set_level(level)


## 게임 내 시간 경과(탐험): 자원 재생·감소 → 상태이상 주기 효과·지속시간 → 수정자 지속시간 → 광원.
func advance_hours(hours: float) -> void:
	if dead or hours <= 0.0:
		return
	pool.tick("time", hours)
	if dead:
		return
	statuses.tick_hours(hours)
	stats.tick("hour", hours)
	light.burn(hours)


## 전투 턴 경과(M2 CTB가 부른다).
func advance_turns(n: float = 1.0) -> void:
	if dead:
		return
	pool.tick("turn", n)
	if dead:
		return
	statuses.tick_turns(n)
	stats.tick("turn", n)


## 휴식: 휴식 회복을 먼저 더하고 그만큼 시간이 흐른다.
func rest(hours: float) -> void:
	if dead:
		return
	pool.tick("rest", hours)
	advance_hours(hours)


func kill(cause: String) -> void:
	if dead:
		return
	dead = true
	death_cause = cause
	died.emit(cause)


## 스킬을 익힌다(이미 있으면 그대로). 새로 익혔으면 true.
func learn_skill(skill_id: String) -> bool:
	if skill_id.is_empty() or skills.has(skill_id):
		return false
	skills.append(skill_id)
	return true


## 스킬을 잊는다. 기본 스킬(innate)은 잊을 수 없다. 잊었으면 true.
func forget_skill(skill_id: String) -> bool:
	if JsonUtil.get_bool(db.get_entry("skills", skill_id), "innate") or not skills.has(skill_id):
		return false
	skills.erase(skill_id)
	return true


## 말이 통하는가(전투 스킬 '대화'). 사람은 통한다. 몬스터가 덮어쓴다.
func understands_speech() -> bool:
	return true


## 받는 피해 배율(상성): 1 = 보통, 0 = 면역. 몬스터가 덮어쓴다.
func damage_affinity(_damage_type: String, _category: String) -> float:
	return 1.0


## 기본 공격의 피해 유형(무기 — M3 장비 전까지는 템플릿/몬스터 기본값).
func attack_damage_type() -> String:
	return "blunt"


## 약점 정보 {name_ko, …}. 없으면 빈 사전.
func weak_point() -> Dictionary:
	return {}


## 개발용(기반 점검·디버그): 사망 상태를 되돌린다. 게임 규칙상 죽음은 영구다.
func debug_revive() -> void:
	dead = false
	death_cause = ""


func _on_status_applied(status_id: String) -> void:
	status_changed.emit(status_id, true)


func _on_status_removed(status_id: String) -> void:
	status_changed.emit(status_id, false)


func _on_threshold(_res_id: String, threshold: Dictionary, entered: bool) -> void:
	var status_id := JsonUtil.get_str(threshold, "apply_status")
	if status_id.is_empty():
		return
	if entered:
		statuses.apply(status_id)
	else:
		statuses.remove(status_id)


func _on_depleted(res_id: String) -> void:
	var def := pool.get_def(res_id)
	if def.on_zero_kind == ResourceDef.ON_ZERO_KILL:
		kill(pool.get_last_source(res_id))
	elif def.on_zero_kind == ResourceDef.ON_ZERO_STATUS:
		statuses.apply(def.on_zero_id)


func _on_recovered(res_id: String) -> void:
	var def := pool.get_def(res_id)
	if def.on_zero_kind == ResourceDef.ON_ZERO_STATUS:
		statuses.remove(def.on_zero_id)
