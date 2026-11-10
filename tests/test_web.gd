extends TestCase
## 웹(itch.io) 배포 점검: 웹에는 시스템 글꼴이 없으므로 화면 글자가 모두 동봉 글꼴에 있어야 하고(없으면 네모로 보인다),
## 내보내기 설정이 데이터 JSON을 싣고 스레드를 끄는지(SharedArrayBuffer 없이 itch.io에서 돈다) 본다. docs/DEPLOY.md.

const REGEX := "\"(?:[^\"\\\\]|\\\\.)*\""


func _font() -> Font:
	return UiTheme.resolve_font(JsonUtil.get_dict(db.render, "font"))  # 본 폰트 + fallbacks(송명에 없는 기호는 Noto, UI47)


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
	assert_true(str(cfg.get_value(web, "include_filter", "")).contains("assets/*.json"), "그림 색인 JSON(몸 높이 · 동네 바닥 · 실내 · 집 가림)을 싣는다")
	assert_false(bool(cfg.get_value(web + ".options", "variant/thread_support", true)), "스레드 끔(SharedArrayBuffer 불필요)")
	var proj := ConfigFile.new()
	assert_eq(proj.load("res://project.godot"), OK, "project.godot")
	assert_false(bool(proj.get_value("display", "window/dpi/allow_hidpi.web", true)), "웹은 레티나 2배로 그리지 않는다(iPad 렉 — 화소 4배, DEPLOY.md §3)")
	assert_true(str(cfg.get_value(web + ".options", "html/head_include", "")).contains("HAN="), "키 넘기기 스크립트(tools/web_key_shim.js — 포커스 · iPad 키 이름 · 한글 자판, DEPLOY.md §3)")


func _files(dir: String, ext: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(ext):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(d), ext))
	return out


## 그림 가져오기 압축(2026-11-09): 원본이 손실 .webp면 손실 0.9, 무손실(VP8L — 동작 시트 · 바닥 타일)이면 무손실.
## 어긋나면 python3 tools/texture_compress.py 로 맞춘다(새 그림은 project.godot importer_defaults가 손실로 만든다).
func test_texture_import_matches_source() -> void:
	var bad := PackedStringArray()
	for path in _files("res://assets", ".webp"):
		var cfg := ConfigFile.new()
		if cfg.load(path + ".import") != OK:
			continue
		var head := FileAccess.get_file_as_bytes(path).slice(0, 256)
		var lossless := _has_bytes(head, "VP8L".to_ascii_buffer())
		var mode := int(cfg.get_value("params", "compress/mode", 0))
		if mode != (0 if lossless else 1):
			bad.append(path)
	assert_true(bad.is_empty(), "압축 설정이 원본과 어긋남(tools/texture_compress.py): %s" % [", ".join(bad.slice(0, 5))])


func _has_bytes(hay: PackedByteArray, needle: PackedByteArray) -> bool:
	for i in hay.size() - needle.size() + 1:
		if hay.slice(i, i + needle.size()) == needle:
			return true
	return false
