extends TestCase
## 아이템 획득 문구는 하나(사용자 2026-11-01 "아이템 획득 문구 전부 통일 · 앞으로 문구 항상 통일되도록"):
## 물건을 얻는 알림은 item.got(_n)·item.got_by(_n)("{item}을(를) 얻었다." — ItemInfo.got_key)뿐이다.
##   ① ko.json에서 item.* 밖의 문구가 아이템 자리({item})와 함께 "주웠다·챙겼다·꺼냈다·건졌다·얻었다·손에 넣었다·손에 쥐었다"를 쓰지 않는다
##   ② 균열 히든 피스·동굴 요소 장면 문구(message·line)에 아이템 이름 자리가 없다(무엇을 얻었는지는 이어지는 통일 문구가 말한다)
##   ③ 탐험·성장·도시 로직에서 가방에 물건을 넣는 파일은 ItemInfo.got_key로 알린다(구매·옮기기·시작 장비·디버그는 획득 알림이 아니다)

const VERBS := ["주웠", "챙겼", "꺼냈", "건졌", "얻었", "손에 넣었", "손에 쥐었"]
## 가방에 넣지만 "얻었다"가 아닌 곳: 상점 구매(값과 함께 "샀다") · 아군 사이 옮기기 · 시작 장비 · 디버그
const NOT_GAIN := ["res://src/city/CityShop.gd", "res://src/ui/windows/InventoryPage.gd", "res://src/entities/PlayerCharacter.gd",
	"res://src/ui/widgets/DebugPanel.gd"]


func _walk(o: Variant, path: String, out: Array) -> void:
	if o is Dictionary:
		for k: String in (o as Dictionary):
			_walk(o[k], (path + "." + k) if not path.is_empty() else k, out)
	elif o is String:
		out.append([path, o])


func test_no_other_gain_wording() -> void:
	var all: Array = []
	_walk(JSON.parse_string(FileAccess.get_file_as_string("res://data/strings/ko.json")), "", all)
	for e: Array in all:
		var key := str(e[0])
		var text := str(e[1])
		if key.begins_with("item.") or not text.contains("{item}"):
			continue
		for v: String in VERBS:
			assert_false(text.contains(v), "%s = \"%s\" — 아이템을 얻는 문구는 item.got 하나" % [key, text])


func test_scene_lines_do_not_name_the_item() -> void:
	for r: String in db.get_collection("rifts"):
		for ch: Variant in JsonUtil.get_array(db.get_entry("rifts", r), "chapters"):
			for h: Variant in JsonUtil.get_array(ch as Dictionary, "hidden"):
				var key := JsonUtil.get_str(h as Dictionary, "message")
				if not key.is_empty():
					assert_true(not _raw(key).is_empty() and not _raw(key).contains("{item}"),
						"%s 히든 피스 장면 %s에 아이템 이름 자리가 있다" % [r, key])


func _raw(key: String) -> String:
	var o: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings/ko.json"))
	for part in key.split("."):
		if not (o is Dictionary) or not (o as Dictionary).has(part):
			return ""
		o = o[part]
	return str(o)


func test_every_gain_uses_the_one_line() -> void:
	var files: Array[String] = []
	for dir: String in ["res://src/explore", "res://src/progress", "res://src/city", "res://src/items", "res://src/ui"]:
		_scan(dir, files)
	var checked := 0
	for f in files:
		var src := FileAccess.get_file_as_string(f)
		if not src.contains("inventory.add(") or NOT_GAIN.has(f):
			continue
		checked += 1
		assert_true(src.contains("ItemInfo.got_key("), "%s — 가방에 물건을 넣으면 ItemInfo.got_key(item.got)로 알린다" % f)
	assert_true(checked >= 8, "획득 자리 %d곳" % checked)


func _scan(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		_scan(dir + "/" + d, out)
