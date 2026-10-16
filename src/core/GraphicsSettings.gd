class_name GraphicsSettings
extends RefCounted
## 그래픽 품질(high / low) — 기기마다 남는 설정(user://, 저장 슬롯과 따로). low = 그레인·입자·맥동·횃불 흔들림 끔.

const DEFAULT_PATH := "user://dungeon_and_stone/settings.json"
const QUALITIES := ["high", "low"]

static var path: String = DEFAULT_PATH
static var _quality: String = ""


static func quality() -> String:
	if _quality.is_empty():
		_quality = "high"
		if FileAccess.file_exists(path):
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if data is Dictionary and str((data as Dictionary).get("quality", "")) in QUALITIES:
				_quality = str((data as Dictionary)["quality"])
	return _quality


## 품질을 바꾸고 파일에 남긴다(쓰지 못해도 이번 실행 동안은 바뀐 값을 쓴다).
static func set_quality(q: String) -> void:
	if not q in QUALITIES:
		return
	_quality = q
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"quality": q}))


## high ↔ low.
static func toggle() -> String:
	set_quality("low" if quality() == "high" else "high")
	return _quality


## 다음 quality()가 파일을 다시 읽게 한다(테스트가 경로를 되돌린 뒤).
static func reset() -> void:
	_quality = ""
