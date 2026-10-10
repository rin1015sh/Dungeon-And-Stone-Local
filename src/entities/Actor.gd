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
