class_name Combatant
extends RefCounted
## 전투 참가자 하나: 개체(Actor) + 진영·대열·행동 게이지·스킬 쿨타임·도주 여부.

const SIDE_PARTY := 0
const SIDE_ENEMY := 1

var actor: Actor
var side: int = SIDE_PARTY
var row: String = "front"
var gauge: float = 0.0
var fled: bool = false
var order: int = 0              ## 같은 조건일 때 순서를 정하는 등록 순번
var cooldowns: Dictionary = {}  ## 스킬 id -> 남은 자기 차례 수


func _init(p_actor: Actor, p_side: int, p_row: String = "front", p_order: int = 0) -> void:
	actor = p_actor
	side = p_side
	row = p_row
	order = p_order


func is_active() -> bool:
	return not fled and not actor.dead


func speed(min_speed: float) -> float:
	return maxf(min_speed, actor.stats.get_value("agi"))


func label() -> String:
	return actor.display_name


## 자기 차례가 올 때 쿨타임을 하나씩 줄인다.
func tick_cooldowns() -> void:
	for id: String in cooldowns.keys():
		cooldowns[id] = int(cooldowns[id]) - 1
		if int(cooldowns[id]) <= 0:
			cooldowns.erase(id)
