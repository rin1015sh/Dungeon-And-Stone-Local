class_name MessageSounds
extends RefCounted
## 문구 키 → 소리 키(data/audio.json on_message — 끝이 *면 앞부분이 같은 키). 화면에 띄우지 않는 문구(UI19 silent)도 소리는 난다.


static func key_for(db: GameDatabase, message_key: String) -> String:
	var m := SoundData.section(db, "on_message")
	if m.has(message_key):
		return str(m[message_key])
	for k: String in m:
		if k.ends_with("*") and message_key.begins_with(k.trim_suffix("*")):
			return str(m[k])
	return ""
