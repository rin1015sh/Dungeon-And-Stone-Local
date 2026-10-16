extends TestCase
## 웹(itch.io) 배포 점검: 웹에는 시스템 글꼴이 없으므로 화면 글자가 모두 동봉 글꼴에 있어야 하고(없으면 네모로 보인다),
## 내보내기 설정이 데이터 JSON을 싣고 스레드를 끄는지(SharedArrayBuffer 없이 itch.io에서 돈다) 본다. docs/DEPLOY.md.

const REGEX := "\"(?:[^\"\\\\]|\\\\.)*\""


func _font() -> Font:
	return load(str(db.render.get("font", {}).get("path", ""))) as Font


func _missing(text: String, font: Font, out: Dictionary) -> void:
	for c in text:
		var code := c.unicode_at(0)
		if code > 127 and not font.has_char(code):
			out[c] = true


func test_bundled_font_has_every_on_screen_character() -> void:
	var font := _font()
	assert_true(font != null, "render.json font.path")
	if font == null:
		return
	var missing := {}
	for path in _files("res://data", ".json"):
		if not path.begins_with("res://data/maps/"):  # 고정 지도(글자 = 타일, 화면에 나오지 않는다)
			_missing(FileAccess.get_file_as_string(path), font, missing)
	var re := RegEx.create_from_string(REGEX)
	for path in _files("res://src", ".gd"):
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.strip_edges().begins_with("#"):
				continue
			for m in re.search_all(line):
				_missing(m.get_string(), font, missing)
	assert_eq(missing.keys(), [], "동봉 글꼴에 없는 글자(웹에서 네모로 보인다)")


func test_web_export_preset() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK, "export_presets.cfg")
	var web := ""
	for s in cfg.get_sections():
		if str(cfg.get_value(s, "platform", "")) == "Web":
			web = s
	assert_false(web.is_empty(), "Web 내보내기 설정")
	if web.is_empty():
		return
	assert_true(str(cfg.get_value(web, "include_filter", "")).contains("data/*.json"), "데이터 JSON을 싣는다")
	assert_true(str(cfg.get_value(web, "include_filter", "")).contains("assets/monsters/index.json"), "몬스터 그림 몸 높이 색인을 싣는다")
	assert_true(str(cfg.get_value(web, "include_filter", "")).contains("assets/party/index.json"), "탐험가 그림 몸 높이 색인을 싣는다")
	assert_false(bool(cfg.get_value(web + ".options", "variant/thread_support", true)), "스레드 끔(SharedArrayBuffer 불필요)")


func _files(dir: String, ext: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(ext):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(d), ext))
	return out
