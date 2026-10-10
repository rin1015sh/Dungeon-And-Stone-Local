extends Node
## 시간 시스템(오토로드). 현재 원정(미궁 입장 ~ 귀환)의 시계를 가지고, 흐른 시간을 EventBus로 알린다.
## 규칙 로직은 GameClock(순수 클래스)에 있고, 탐험 규칙은 ExploreSession이 이 시계를 받아 쓴다.
## 도시 달력(포탈 개방일, 다음 날 정오 귀환)은 M4에서 여기에 붙는다.

var clock: GameClock = GameClock.new()


func _ready() -> void:
	_bind(clock)


## 새 원정을 시작한다(미궁 입장 시각 = 0).
func new_expedition() -> GameClock:
	clock = GameClock.new()
	_bind(clock)
	return clock


func _bind(c: GameClock) -> void:
	c.advanced.connect(func(hours: float, _total: float) -> void: EventBus.time_advanced.emit(hours))
