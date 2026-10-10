extends Node
## 현재 게임 진행 상태(오토로드).
## M0: 세션 시드만 가진다. 캐릭터·층·시간·파티는 M1~M4에서 여기에 붙는다.

var master_seed: int = 0
var rng: Rng = null


func _ready() -> void:
	new_session()


## seed_override가 0이면 무작위 시드.
func new_session(seed_override: int = 0) -> void:
	rng = Rng.new(seed_override)
	master_seed = rng.seed_value
