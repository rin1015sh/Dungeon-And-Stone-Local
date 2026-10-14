extends Node
## 현재 게임 진행 상태(오토로드): 세션 시드, 플레이어 캐릭터, 층 입장 횟수, 디버그 설정.
## 도시(M4): city = 순 달력·행동력·신전 공적치·은행·소문/정보(CityState). 파티·저장은 아직 없다.

var master_seed: int = 0
var rng: Rng = null
var player: PlayerCharacter = null
var floor_entries: int = 0
var debug_seed_override: int = 0
var debug_invulnerable: bool = false
var debug_fast_combat: bool = false  ## 적 차례 연출 지연 없음(테스트·스모크용)
var rift_calendar: RiftCalendar = null  ## 균열 자연 개방 달력(원정 = 1달). 탐험가마다 새로(도시 달력과의 관계는 미정 — ASSUMPTIONS CT)
var city: CityState = null  ## 도시 진행 상태(탐험가마다 새로)


func _ready() -> void:
	new_session()


## seed_override가 0이면 무작위 시드.
func new_session(seed_override: int = 0) -> void:
	rng = Rng.new(seed_override)
	master_seed = rng.seed_value
	player = null
	floor_entries = 0


## 새 탐험마다 지도 시드를 새로 굴린다(같은 실행 안에서 매 판 같은 층이 나오지 않게). 세션 rng로 굴려 재현은 된다.
func start_run(pc: PlayerCharacter) -> void:
	player = pc
	master_seed = rng.randi_range(1, 2147483646)
	floor_entries = 0
	rift_calendar = RiftCalendar.new(DataRegistry.db)
	city = CityState.new(DataRegistry.db, absi(hash([master_seed, "city"])) + 1)
	city.start()


## 층 생성 시드: 디버그로 고정했으면 그 값, 아니면 세션 시드·층·입장 횟수로 정한다.
func next_floor_seed(floor_number: int) -> int:
	floor_entries += 1
	if debug_seed_override != 0:
		return debug_seed_override
	return absi(hash([master_seed, floor_number, floor_entries])) + 1


func end_run() -> void:
	player = null
	city = null
	debug_invulnerable = false  # 디버그 무적은 다음 탐험으로 넘기지 않는다
