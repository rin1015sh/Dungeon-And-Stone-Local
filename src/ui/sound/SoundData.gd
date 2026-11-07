class_name SoundData
extends RefCounted
## data/audio.json 읽기 도우미(오토로드 비의존 — 테스트가 그대로 부른다).


static func audio(db: GameDatabase) -> Dictionary:
	return db.singletons.get("audio", {})


static func section(db: GameDatabase, key: String) -> Dictionary:
	return JsonUtil.get_dict(audio(db), key)


## 키가 소리로 풀리는가(sfx 파일 · 별칭 · 묶음 중 하나).
static func known(db: GameDatabase, key: String) -> bool:
	return section(db, "sfx").has(key) or section(db, "alias").has(key) or section(db, "cues").has(key)
