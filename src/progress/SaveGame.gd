class_name SaveGame
extends RefCounted
## 한 칸 저장(사용자 결정 2026-10-15): 차원광장에서 포탈로 들어가기 직전에만 쓴다. 불러오면 차원광장에서 이어 간다.
## 파일 = user://dungeon_and_stone/save.json. 웹(itch.io 등)에서는 user://가 브라우저 IndexedDB인데,
## 같은 주소에 올라간 다른 Godot 게임과 겹치지 않게 게임 이름 폴더를 한 겹 둔다(docs/DEPLOY.md).
## 내용: 탐험가(이름·종족·템플릿·기본 스탯·자원·상태·광원·스킬·성장 전부) + 도시(CityState) + 균열 달력 + 세션 시드·층 입장 횟수.
## 오토로드를 참조하지 않는다(GameState가 부른다). 버전이 다르거나 깨진 파일은 없는 것으로 본다.

const VERSION := 1
const DEFAULT_PATH := "user://dungeon_and_stone/save.json"


static func exists(path: String = DEFAULT_PATH) -> bool:
	return not read(path).is_empty()


static func write(data: Dictionary, path: String = DEFAULT_PATH) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()  # 웹: 닫을 때 IndexedDB로 동기화된다
	return true


## 저장 파일을 읽는다. 없거나 깨졌거나 버전이 다르면 빈 사전.
static func read(path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()  # parse_string은 깨진 파일에서 오류를 찍는다
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary or JsonUtil.get_int(parsed, "version") != VERSION:
		return {}
	return parsed


static func delete(path: String = DEFAULT_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## 지금 상태를 저장용 사전으로.
static func capture(pc: PlayerCharacter, city: CityState, rifts: RiftCalendar, master_seed: int, floor_entries: int) -> Dictionary:
	return {
		"version": VERSION,
		"saved_unix": int(Time.get_unix_time_from_system()),
		"where": "plaza",
		"player": {
			"name": pc.display_name, "race": pc.race_id, "class": pc.class_id,
			"pool": pc.pool.to_dict(), "statuses": pc.statuses.to_dict(), "light": pc.light.to_dict(),
			"skills": pc.skills.duplicate(), "progress": pc.progress_to_dict(),
		},
		"city": city.to_dict() if city != null else {},
		"rift_calendar": rifts.to_dict() if rifts != null else {},
		"game": {"master_seed": master_seed, "floor_entries": floor_entries},
	}


## 저장 사전 → 탐험가. 시작 소지품·장비는 주지 않고 저장된 것만 되살린다.
static func restore_player(db: GameDatabase, data: Dictionary) -> PlayerCharacter:
	var p := JsonUtil.get_dict(data, "player")
	var progress := JsonUtil.get_dict(p, "progress")
	var level := Progression.level_for(db, JsonUtil.get_int(JsonUtil.get_dict(progress, "progression"), "exp_total"))
	var pc := PlayerCharacter.new(db, JsonUtil.get_dict(progress, "base_stats"), maxi(1, level))
	pc.id = "player"
	pc.display_name = JsonUtil.get_str(p, "name")
	pc.race_id = JsonUtil.get_str(p, "race")
	pc.class_id = JsonUtil.get_str(p, "class")
	pc.fatigue.changed.connect(pc._on_fatigue_changed)
	pc.fatigue.setup(JsonUtil.get_dict(db.singletons.get("city", {}), "fatigue"))
	PlayerCharacter.grant_innate_skills(pc)
	for s: Variant in JsonUtil.get_array(p, "skills"):
		if db.has_entry("skills", str(s)):
			pc.learn_skill(str(s))
	pc.progress_load_dict(progress)
	pc.statuses.load_dict(JsonUtil.get_dict(p, "statuses"))
	pc.light.load_dict(JsonUtil.get_dict(p, "light"))
	pc.pool.load_dict(JsonUtil.get_dict(p, "pool"))
	return pc
