extends SceneTree
## 헤드리스 테스트 러너.
##   godot --headless --path . --script res://tests/run_tests.gd
## tests/test_*.gd의 test_* 메서드를 모두 실행한다. 실패가 있으면 종료 코드 1.
## 주의: 런타임 스크립트 오류는 GDScript가 잡아 주지 않으므로, 단언이 0개인 테스트도 실패로 본다.
##       tools/check.sh는 출력의 "SCRIPT ERROR"도 실패로 판정한다.

const TEST_DIR := "res://tests"


func _initialize() -> void:
	var db := GameDatabase.new()
	db.load_all("res://data")
	var files := PackedStringArray()
	for f: String in DirAccess.get_files_at(TEST_DIR):
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(TEST_DIR.path_join(f))
	files.sort()
	var total := 0
	var failed := 0
	for path: String in files:
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			print("FAIL  %s — 스크립트를 불러올 수 없다" % path)
			failed += 1
			continue
		var case: TestCase = script.new()
		case.db = db
		for m: Dictionary in case.get_method_list():
			var method: String = m["name"]
			if not method.begins_with("test_"):
				continue
			total += 1
			case.begin_test()
			case.before_each()
			case.call(method)
			var label := "%s :: %s" % [path.get_file(), method]
			if case.assert_count() == 0:
				failed += 1
				print("FAIL  %s — 단언 0개(중간에 오류로 멈췄을 수 있음)" % label)
			elif not case.failures().is_empty():
				failed += 1
				print("FAIL  %s" % label)
				for msg: String in case.failures():
					print("        - " + msg)
			else:
				print("ok    %s (%d)" % [label, case.assert_count()])
	print("")
	print("테스트 %d개 중 실패 %d개" % [total, failed])
	quit(1 if failed > 0 or total == 0 else 0)
