extends Node
## 현재 게임 진행 상태(오토로드): 세션 시드, 플레이어 캐릭터, 층 입장 횟수, 디버그 설정.
## 도시(M4): city = 순 달력·행동력·신전 공적치·은행·소문/정보(CityState). 파티는 아직 없다.
## 저장: 한 칸(SaveGame) — 차원광장에서만 save_run(), 타이틀 "이어하기" = load_run(). 사망하면 지운다(balance save.delete_on_death).

var master_seed: int = 0
var rng: Rng = null
var player: PlayerCharacter = null
var floor_entries: int = 0
var debug_seed_override: int = 0
var debug_invulnerable: bool = false
var debug_fast_combat: bool = false  ## 적 차례 연출 지연 없음(테스트·스모크용)
var rift_calendar: RiftCalendar = null  ## 균열 자연 개방 달력(원정 = 1달 = 도시 한 달 — 포탈은 한 달에 한 번). 탐험가마다 새로(ASSUMPTIONS PA9)
var city: CityState = null  ## 도시 진행 상태(탐험가마다 새로)
var save_path: String = SaveGame.DEFAULT_PATH  ## 테스트는 다른 경로를 쓴다(실제 저장을 덮지 않게)


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


## 지금 탐험가·도시를 한 칸에 저장한다(차원광장에서만 부른다).
func save_run() -> bool:
	if player == null or city == null:
		return false
	return SaveGame.write(SaveGame.capture(player, city, rift_calendar, master_seed, floor_entries), save_path)


func has_save() -> bool:
	return SaveGame.exists(save_path)


## 저장을 불러와 진행 상태를 갈아 끼운다. 실패하면 false(상태는 그대로).
func load_run() -> bool:
	var data := SaveGame.read(save_path)
	if data.is_empty():
		return false
	var db: GameDatabase = DataRegistry.db
	var game := JsonUtil.get_dict(data, "game")
	player = SaveGame.restore_player(db, data)
	master_seed = JsonUtil.get_int(game, "master_seed", master_seed)
	floor_entries = JsonUtil.get_int(game, "floor_entries")
	rift_calendar = RiftCalendar.new(db)
	rift_calendar.load_dict(JsonUtil.get_dict(data, "rift_calendar"))
	city = CityState.new(db, absi(hash([master_seed, "city"])) + 1)
	city.start()
	city.load_dict(JsonUtil.get_dict(data, "city"))
	return true


## 사망: 하드코어 — 저장을 지운다(balance save.delete_on_death가 false면 남긴다).
func on_death() -> void:
	if bool(DataRegistry.db.bal("save.delete_on_death", true)):
		SaveGame.delete(save_path)
