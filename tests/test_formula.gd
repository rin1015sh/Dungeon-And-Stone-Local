extends TestCase
## Formula: {키} 치환 수식 평가·검사.


func _resolver(values: Dictionary) -> Callable:
	return func(k: String) -> float: return float(values.get(k, 0.0))


func test_evaluate_arithmetic() -> void:
	var r := _resolver({"a": 3.0, "b.c": 10.0})
	assert_near(Formula.evaluate("{a} * 2 + {b.c}", r), 16.0)
	assert_near(Formula.evaluate("-{a} * (1 + 0.5)", r), -4.5)
	assert_near(Formula.evaluate("min({a}, 1) + max({a}, 5)", r), 6.0)


func test_value_accepts_numbers_and_numeric_strings() -> void:
	var r := _resolver({})
	assert_near(Formula.value(12, r), 12.0)
	assert_near(Formula.value(2.5, r), 2.5)
	assert_near(Formula.value("7.5", r), 7.5)


func test_extract_keys_unique_in_order() -> void:
	var keys := Formula.extract_keys("{bal.hp.base} + {level} * {str} + {level}")
	assert_eq(keys.size(), 3)
	assert_eq(keys[0], "bal.hp.base")
	assert_eq(keys[1], "level")
	assert_eq(keys[2], "str")


func test_reserved_words_are_safe_as_keys() -> void:
	# str/int는 GDScript 내장 이름이지만 {키}는 내부 변수로 바뀌므로 안전해야 한다.
	var r := _resolver({"str": 4.0, "int": 6.0})
	assert_near(Formula.evaluate("{str} + {int}", r), 10.0)


func test_check_reports_errors() -> void:
	assert_eq(Formula.check("{a} + 1"), "")
	assert_false(Formula.check("{a} +* 2").is_empty(), "문법 오류")
	assert_false(Formula.check("unknown_name + 1").is_empty(), "중괄호 없는 이름")
