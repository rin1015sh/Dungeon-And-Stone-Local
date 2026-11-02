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
var uses: Dictionary = {}       ## 스킬 id -> 이번 전투에서 쓴 횟수(uses_per_battle)
var acted: int = 0              ## 이번 전투에서 행동한 횟수(AI 첫 차례·순환)
var was_hit: bool = false       ## 마지막 자기 행동 뒤에 피해를 받았는가(AI)
var memo: Dictionary = {}       ## 보스 패턴·예고 공격의 전투 중 기록(BossHooks, BattleDelayed)
var summoned: bool = false      ## 전투 중 생겨난 개체(소환·분열·동반·증원). 아군 소환수는 AI가 움직이고 승패에 들지 않는다
var last_turn: int = -1         ## 마지막으로 차례가 온 순번(Battle.turns)
var joined_at: int = 0          ## 들어온 때의 Battle.turns(소환·증원은 그 뒤 차례만 추가 차례 판정에 센다)
var rev: int = 0                ## 모아 둔 Rev(아군만 — BattleRev, C20)
var extra_turn: bool = false    ## 지금 차례가 추가 차례인가 — 지난 자기 차례 뒤로 아직 차례가 오지 않은 다른 참가자가 있다(민첩, C14)


func _init(p_actor: Actor, p_side: int, p_row: String = "front", p_order: int = 0) -> void:
	actor = p_actor
	side = p_side
	row = p_row
	order = p_order


func is_active() -> bool:
	return not fled and not actor.dead


## 행동 게이지 속도 = (민첩 + speed_base)^speed_exp(balance combat.speed_base·speed_exp). 등급 배율은 Timeline이 곱한다.
func speed(min_speed: float, speed_base: float = 0.0, speed_exp: float = 1.0) -> float:
	return maxf(min_speed, pow(maxf(0.0, actor.stats.get_value("agi") + speed_base), speed_exp))


func label() -> String:
	return actor.display_name


## 자기 차례가 올 때 쿨타임을 하나씩 줄인다.
func tick_cooldowns() -> void:
	for id: String in cooldowns.keys():
		cooldowns[id] = int(cooldowns[id]) - 1
		if int(cooldowns[id]) <= 0:
			cooldowns.erase(id)
