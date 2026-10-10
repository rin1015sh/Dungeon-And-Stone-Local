class_name TestCase
extends RefCounted
## 아주 작은 테스트 베이스. tests/test_*.gd가 이것을 상속하고 test_* 메서드에서 assert_*를 부른다.
## 러너(run_tests.gd)가 db(실제 data/를 읽은 GameDatabase)를 넣어 준다.

var db: GameDatabase
var _failures: Array[String] = []
var _asserts: int = 0


func before_each() -> void:
	pass


func begin_test() -> void:
	_failures.clear()
	_asserts = 0


func failures() -> Array[String]:
	return _failures


func assert_count() -> int:
	return _asserts


func assert_true(cond: bool, msg: String = "") -> void:
	_asserts += 1
	if not cond:
		_failures.append("참이어야 함 — " + msg)


func assert_false(cond: bool, msg: String = "") -> void:
	_asserts += 1
	if cond:
		_failures.append("거짓이어야 함 — " + msg)


func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	_asserts += 1
	if not _same(actual, expected):
		_failures.append("기대 <%s> 실제 <%s> — %s" % [str(expected), str(actual), msg])


func assert_near(actual: float, expected: float, eps: float = 0.0001, msg: String = "") -> void:
	_asserts += 1
	if absf(actual - expected) > eps:
		_failures.append("기대 ≈%s 실제 %s — %s" % [str(expected), str(actual), msg])


func fail(msg: String) -> void:
	_asserts += 1
	_failures.append(msg)


func _same(a: Variant, b: Variant) -> bool:
	if JsonUtil.is_number(a) and JsonUtil.is_number(b):
		return is_equal_approx(float(a), float(b))
	if typeof(a) != typeof(b):
		return false
	return a == b
