extends TestCase
## 대화창 한 쪽 = 한 문장(사용자 결정 2026-10-31, UI44): DialogueSplit이 글을 문장으로 나눈다.


func test_splits_sentences_and_lines() -> void:
	assert_eq(DialogueSplit.sentences("굴이 어둡다. 무엇이 움직인다! 누구냐? 아무도 없다…"),
		PackedStringArray(["굴이 어둡다.", "무엇이 움직인다!", "누구냐?", "아무도 없다…"]))
	assert_eq(DialogueSplit.sentences("첫 줄\n둘째 줄이다. 셋째."), PackedStringArray(["첫 줄", "둘째 줄이다.", "셋째."]))


func test_keeps_quotes_and_numbers() -> void:
	assert_eq(DialogueSplit.sentences("\"멈춰라.\" 그가 말했다. 값은 1.5배다."),
		PackedStringArray(["\"멈춰라.\"", "그가 말했다.", "값은 1.5배다."]))


func test_title_line_joins_first_sentence() -> void:
	assert_eq(DialogueSplit.sentences("『허기』\n배가 고프다. 힘이 빠진다."), PackedStringArray(["『허기』\n배가 고프다.", "힘이 빠진다."]))
	assert_eq(DialogueSplit.sentences("『제목만』"), PackedStringArray(["『제목만』"]))
	assert_eq(DialogueSplit.sentences(""), PackedStringArray())
