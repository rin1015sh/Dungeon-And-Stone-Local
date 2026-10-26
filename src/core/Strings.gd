class_name Strings
extends RefCounted
## UI 문자열 로더. data/strings/<locale>.json(중첩 객체)을 "a.b.c" 키로 평탄화해 보관한다.
##   Strings.t("menu.quit")
##   Strings.t("log.damage", {"amount": 10})   # "{amount}" 자리표시자 치환
## 키가 없으면 "[키]"를 그대로 보여 주고 경고를 한 번만 남긴다.
## 스톤 금액: 문구에서 "{자리} 스톤"처럼 스톤 단위 바로 앞에 놓인 수는 만 단위로 끊어 쓴다(stones — "1만 5000 스톤").

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
	if args.is_empty():
		return text
	var unit: String = _table.get("num.stone_unit", "")
	if not unit.is_empty() and text.contains(unit):
		args = _stone_args(text, unit, args)
	return text.format(args)


## 스톤 금액 표시: 만의 자리부터 만·억·조 단위로 끊는다(빈 자리는 생략). 1억 5000만 · 5500만 2000 · 3500.
static func stones(n: int) -> String:
	if _locale.is_empty():
		load_locale()
	var rest: int = absi(n)
	if rest < 10000:
		return str(n)
	var parts: PackedStringArray = []
	var units: PackedStringArray = str(_table.get("num.units", "")).split(",")
	var i := 0
	while rest > 0:
		var group: int = rest % 10000
		rest /= 10000
		if group > 0:
			parts.insert(0, str(group) + (units[i - 1] if i > 0 and i - 1 < units.size() else ""))
		i += 1
	return ("-" if n < 0 else "") + " ".join(parts)


## 스톤 단위 바로 앞(붙여 쓰든 띄어 쓰든)에 놓인 수 인자만 stones()로 바꾼 사본.
static func _stone_args(text: String, unit: String, args: Dictionary) -> Dictionary:
	var out := args.duplicate()
	for k: Variant in args:
		var v: Variant = args[k]
		if not (v is int or v is float):
			continue
		var slot := "{%s}" % str(k)
		if text.contains(slot + unit) or text.contains(slot + " " + unit):
			out[k] = stones(int(v))
	return out


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
