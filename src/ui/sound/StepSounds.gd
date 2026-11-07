class_name StepSounds
extends RefCounted
## 걸음 고리 키(data/audio.json step_sounds): 선 칸 타일의 그림 경로 · id로 바닥 갈래를 고르고(위 규칙부터), 쫓기는 중이면 달리기.


static func ground(db: GameDatabase, tile_id: String) -> String:
	var cfg := SoundData.section(db, "step_sounds")
	var t := db.get_entry("tiles", tile_id)
	var text := tile_id + " " + JsonUtil.get_str(JsonUtil.get_dict(t, "art"), "atlas")
	for v: Variant in JsonUtil.get_array(cfg, "classes"):
		var c: Dictionary = v if v is Dictionary else {}
		for m: Variant in JsonUtil.get_array(c, "match"):
			if text.contains(str(m)):
				return JsonUtil.get_str(c, "class")
	return JsonUtil.get_str(cfg, "default", "dirt")


## 걷는 중이 아니면 "".
static func key_for(db: GameDatabase, tile_id: String, moving: bool, chased: bool) -> String:
	if not moving:
		return ""
	var cfg := SoundData.section(db, "step_sounds")
	return JsonUtil.get_str(JsonUtil.get_dict(cfg, "run" if chased else "walk"), ground(db, tile_id))
