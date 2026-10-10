extends Node
## 현재 게임 진행 상태(오토로드): 세션 시드, 플레이어 캐릭터, 층 입장 횟수, 디버그 설정.
## (도시·달력·파티·저장은 M4에서 여기에 붙는다)

var master_seed: int = 0
var rng: Rng = null
var player: PlayerCharacter = null
var floor_entries: int = 0
var debug_seed_override: int = 0
var debug_invulnerable: bool = false


func _ready() -> void:
	new_session()


## seed_override가 0이면 무작위 시드.
func new_session(seed_override: int = 0) -> void:
	rng = Rng.new(seed_override)
	master_seed = rng.seed_value
	player = null
	floor_entries = 0


func start_run(pc: PlayerCharacter) -> void:
	player = pc
	floor_entries = 0


## 층 생성 시드: 디버그로 고정했으면 그 값, 아니면 세션 시드·층·입장 횟수로 정한다.
func next_floor_seed(floor_number: int) -> int:
	floor_entries += 1
	if debug_seed_override != 0:
		return debug_seed_override
	return absi(hash([master_seed, floor_number, floor_entries])) + 1


func end_run() -> void:
	player = null
