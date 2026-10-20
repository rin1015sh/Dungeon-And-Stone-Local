class_name Formula
extends RefCounted
## 데이터 수식 평가기. "{키}" 자리표시자 + 사칙연산/min/max/floor 등(Godot Expression).
##   예) "{bal.hp.base} + {level} * {bal.hp.per_level} + {p_res} * {bal.hp.per_p_res}"
## 키의 의미는 호출자가 resolver(Callable: key -> float)로 정한다.
## 표준 키: level, bal.<balance.json 경로>, <스탯 id>.

const KEY_PATTERN := "\\{([A-Za-z0-9_.:]+)\\}"

static var _regex: RegEx = null
static var _cache: Dictionary = {}  # 원문 -> {"expr": Expression, "keys": PackedStringArray, "error": String}


## 숫자면 그대로, 문자열이면 수식으로 평가한다.
static func value(v: Variant, resolver: Callable) -> float:
	if v is float or v is int:
		return float(v)
	if v is String:
		var s: String = v
		if s.is_valid_float():
			return s.to_float()
		return evaluate(s, resolver)
	return 0.0


static func evaluate(src: String, resolver: Callable) -> float:
	var c := _compile(src)
	if not str(c["error"]).is_empty():
		push_error("수식 파싱 실패 '%s': %s" % [src, c["error"]])
		return 0.0
	var inputs: Array = []
	for key: String in c["keys"]:
		inputs.append(float(resolver.call(key)))
	var expr: Expression = c["expr"]
	var result: Variant = expr.execute(inputs, null, false)
	if expr.has_execute_failed() or not (result is float or result is int):
		push_error("수식 실행 실패 '%s': %s" % [src, expr.get_error_text()])
		return 0.0
	return float(result)


## 수식에 쓰인 키 목록(중복 제거, 등장 순).
static func extract_keys(src: String) -> PackedStringArray:
	return _compile(src)["keys"]


## 문법/실행 검사. 문제가 없으면 빈 문자열. (모든 키를 1.0으로 두고 한 번 실행해 본다)
static func check(src: String) -> String:
	var c := _compile(src)
	if not str(c["error"]).is_empty():
		return str(c["error"])
	var inputs: Array = []
	for _key: String in c["keys"]:
		inputs.append(1.0)
	var expr: Expression = c["expr"]
	var result: Variant = expr.execute(inputs, null, false)
	if expr.has_execute_failed():
		var msg := expr.get_error_text()
		return msg if not msg.is_empty() else "실행 실패"
	if not (result is float or result is int):
		return "결과가 숫자가 아님"
	return ""


static func _compile(src: String) -> Dictionary:
	if _cache.has(src):
		return _cache[src]
	if _regex == null:
		_regex = RegEx.create_from_string(KEY_PATTERN)
	var keys := PackedStringArray()
	var text := ""
	var last := 0
	for m: RegExMatch in _regex.search_all(src):
		var key := m.get_string(1)
		var idx := keys.find(key)
		if idx < 0:
			idx = keys.size()
			keys.append(key)
		text += src.substr(last, m.get_start() - last) + "_k%d" % idx
		last = m.get_end()
	text += src.substr(last)
	var names := PackedStringArray()
	for i in keys.size():
		names.append("_k%d" % i)
	var expr := Expression.new()
	var err := expr.parse(text, names)
	var entry := {"expr": expr, "keys": keys, "error": "" if err == OK else expr.get_error_text()}
	_cache[src] = entry
	return entry
