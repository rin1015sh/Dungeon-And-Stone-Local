class_name Strings
extends RefCounted
## UI 문자열 로더. data/strings/<locale>.json(중첩 객체)을 "a.b.c" 키로 평탄화해 보관한다.
##   Strings.t("menu.quit")
##   Strings.t("log.damage", {"amount": 10})   # "{amount}" 자리표시자 치환
## 키가 없으면 "[키]"를 그대로 보여 주고 경고를 한 번만 남긴다.

const DIR := "res://data/strings/"
const DEFAULT_LOCALE := "ko"

static var _table: Dictionary = {}
static var _locale: String = ""
static var _warned: Dictionary = {}


## 로케일 파일을 읽는다. 오류 메시지 목록을 돌려준다(비면 성공).
static func load_locale(locale: String = DEFAULT_LOCALE) -> Array[String]:
	var errors: Array[String] = []
	var data: Variant = JsonUtil.read_file(DIR + locale + ".json", errors)
	_table.clear()
	_warned.clear()
	if data is Dictionary:
		_flatten("", data)
	elif errors.is_empty():
		errors.append("문자열 파일 최상위가 객체가 아님: %s" % locale)
	_locale = locale
	return errors


static func t(key: String, args: Dictionary = {}) -> String:
	if _locale.is_empty():
		load_locale()
	if not _table.has(key):
		if not _warned.has(key):
			_warned[key] = true
			push_warning("문자열 키 없음: %s" % key)
		return "[%s]" % key
	var text: String = _table[key]
	return text if args.is_empty() else text.format(args)


static func has(key: String) -> bool:
	if _locale.is_empty():
		load_locale()
	return _table.has(key)


static func keys() -> PackedStringArray:
	if _locale.is_empty():
		load_locale()
	return PackedStringArray(_table.keys())


static func _flatten(prefix: String, node: Dictionary) -> void:
	for k: String in node:
		if k.begins_with("_"):
			continue
		var full := k if prefix.is_empty() else prefix + "." + k
		var v: Variant = node[k]
		if v is Dictionary:
			_flatten(full, v)
		else:
			_table[full] = str(v)
