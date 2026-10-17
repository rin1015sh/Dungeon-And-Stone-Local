extends SceneTree
## 데칼 좌표 굽기: 층 JSON art.decor 규칙으로 고정 지도 전체의 데칼 자리를 계산해 art.decor.baked 파일에 쓴다.
##   godot --headless --path . --script res://tools/bake_decor.gd -- [--floor=f1_crystal_cave]
## 실행 중엔 이 파일의 색인만 읽는다(FloorDecor.cells — 청크마다 규칙 계산 없음). 규칙·kinds·지도를 바꾸면 다시 굽는다
## (tests/test_floor_decor.gd가 파일과 규칙 결과를 비교한다). 그림 층 검사(FloorArtCheck)에 문제가 있으면 쓰지 않는다.
## 파일은 손으로 고쳐도 된다(한 줄 = [x, y, 종류 번호, 변형, 방향 0~3, 뒤집기, 크기×100, 흔들림 x×100, y×100]) — 다시 구우면 덮어쓴다.

var _args: Dictionary = {"floor": "f1_crystal_cave"}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	var db := GameDatabase.new()
	db.load_all("res://data")
	var def := db.get_entry("floors", str(_args["floor"]))
	var path := JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(def, "art"), "decor"), "baked")
	if path.is_empty():
		print("층 %s에 art.decor.baked가 없다" % _args["floor"])
		quit(1)
		return
	var map := ContentRegistries.new().generator(JsonUtil.get_str(def, "generator")).generate(db, def, Rng.new(1))
	var decor := FloorDecor.compile(map, def)
	var t := Time.get_ticks_msec()
	var list := decor.all(true)
	var problems := FloorArtCheck.problems(map, {"decor": list})
	print("데칼 %d개, 계산 %dms, 그림 층 검사: %s" % [list.size(), Time.get_ticks_msec() - t, "통과" if problems.is_empty() else str(problems)])
	if not problems.is_empty():
		quit(1)
		return
	var lines := PackedStringArray()
	for e in list:
		lines.append(JSON.stringify(FloorDecor.pack(e)))
	var head := JSON.stringify({"_comment": "tools/bake_decor.gd가 만든 데칼 자리(층 JSON art.decor 규칙의 결과). 한 줄 = [x, y, 종류 번호(kinds), 변형, 방향 0~3, 뒤집기, 크기×100, 흔들림 x×100, y×100]. 다시 구우면 덮어쓴다.",
		"floor": JsonUtil.get_str(def, "id"), "kinds": decor.kinds}, "  ", false)
	var text := head.substr(0, head.length() - 2) + ",\n  \"cells\": [\n    " + ",\n    ".join(lines) + "\n  ]\n}\n"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("쓰기 실패: " + path)
		quit(1)
		return
	f.store_string(text)
	f.close()
	print("데칼 저장: %s" % ProjectSettings.globalize_path(path))
	quit(0)
