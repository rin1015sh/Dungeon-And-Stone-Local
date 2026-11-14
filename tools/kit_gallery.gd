extends Node2D
## 에셋 라이브러리 갤러리(AM69) — 키트 에셋을 분류별로 한눈에 본다. 게임과 따로 도는 시험 씬이다(Main · 오토로드를 쓰지 않는다).
##   godot --path . res://tools/kit_gallery.tscn                      A/D = 분류 · W/S = 내리기/올리기 · Esc = 끝
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . res://tools/kit_gallery.tscn -- --shots=<폴더> [--group=<id>]
## 분류 표 = kit.json `library.groups`(tools/dungeon_kit/library.py), 배치 시험 = `library.tests`(세트 이름 — DungeonKit.build_set).

const VIEW := Vector2(1280, 720)
const HEAD_H := 46.0
const PAD := 14.0
const LABEL_H := 16.0
const BG := Color("#2a2725")
const INK := Color("#d8ccb0")
const DIM := Color("#8c8474")
const SCROLL_STEP := 180.0

var _kit: DungeonKit
var _font: Font
var _groups: Array = []
var _at := 0
var _page: Node2D
var _page_h := 0.0
var _head: Label
var _hint: Label


func _ready() -> void:
	RenderingServer.set_default_clear_color(BG)
	get_window().size = Vector2i(VIEW)
	_kit = DungeonKit.open()
	_font = load("res://assets/fonts/NotoSansKR-Regular.otf")
	var lib: Dictionary = _kit.data.get("library", {})
	for g: Dictionary in lib.get("groups", []):
		_groups.append(g)
	for set_name: String in lib.get("tests", []):
		_groups.append({"id": "test_" + set_name, "name_ko": "배치 시험 — " + String(_kit.data["sets"][set_name].get("name_ko", set_name)), "set": set_name})
	var bar := ColorRect.new()
	bar.color = Color("#1a1716")
	bar.size = Vector2(VIEW.x, HEAD_H)
	bar.z_index = 100
	add_child(bar)
	_head = _label("", 20, INK)
	_head.position = Vector2(PAD, 8)
	_head.z_index = 101
	add_child(_head)
	_hint = _label("", 13, DIM)
	_hint.position = Vector2(VIEW.x - 330, 14)
	_hint.z_index = 101
	add_child(_hint)
	var args := _args()
	if args.has("group"):
		for i in _groups.size():
			if String(_groups[i]["id"]) == String(args["group"]):
				_at = i
	if args.has("shots"):
		await _shoot(String(args["shots"]), args.has("group"))
		get_tree().quit()
		return
	_show(_at)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	match key.keycode:
		KEY_D, KEY_RIGHT:
			_show(posmod(_at + 1, _groups.size()))
		KEY_A, KEY_LEFT:
			_show(posmod(_at - 1, _groups.size()))
		KEY_S, KEY_DOWN:
			_scroll(SCROLL_STEP)
		KEY_W, KEY_UP:
			_scroll(-SCROLL_STEP)
		KEY_ESCAPE:
			get_tree().quit()


func _args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return out


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _scroll(by: float) -> void:
	if _page == null:
		return
	_page.position.y = clampf(_page.position.y - by, minf(HEAD_H, VIEW.y - _page_h - PAD), HEAD_H)


func _show(i: int) -> void:
	if _groups.is_empty():
		_head.text = "kit.json에 library 표가 없다 — python3 tools/dungeon_kit/build.py"
		return
	_at = i
	if _page != null:
		_page.queue_free()
	var g: Dictionary = _groups[i]
	_page = Node2D.new()
	_page.position = Vector2(0, HEAD_H)
	add_child(_page)
	var n_assets := 0
	if g.has("set"):
		_page_h = _fill_set(String(g["set"]))
	else:
		n_assets = (g["ids"] as Array).size()
		_page_h = _fill_assets(g["ids"])
	_head.text = "%d / %d   %s%s" % [i + 1, _groups.size(), String(g["name_ko"]), ("   에셋 %d종" % n_assets) if n_assets > 0 else ""]
	_hint.text = "A · D 분류      W · S 올리기 · 내리기      Esc 끝"


## 에셋마다: 이름 줄(이름 · id · 분류 · 층) + 변형 그림들(변형 이름). 넘치면 다음 줄로. → 쓴 높이.
func _fill_assets(ids: Array) -> float:
	var y := PAD
	for id: String in ids:
		if not _kit.has(id):
			continue
		var a := _kit.info(id)
		var note := "%s    %s · %s · %s%s%s" % [String(a.get("name_ko", id)), id, String(a.get("cat", "")), String(a.get("layer", "")),
			" · 충돌" if a.has("collide") else "", (" · " + String(a["interact"])) if a.has("interact") else ""]
		var title := _label(note, 14, INK)
		title.position = Vector2(PAD, y)
		_page.add_child(title)
		y += 24.0
		var x := PAD
		var row_h := 0.0
		for v: String in _kit.variants(id):
			var fr: Array = a["variants"][v]["frames"]
			var size := Vector2(float(fr[0][2]), float(fr[0][3]))
			var k := minf(1.0, minf(360.0 / size.x, 300.0 / size.y))   # 큰 타일 · 구조물은 줄여 보인다
			var cell_w := maxf(size.x * k, float(v.length()) * 7.5 + 8.0) + PAD
			if x + cell_w > VIEW.x - PAD and x > PAD:
				x = PAD
				y += row_h + LABEL_H + 10.0
				row_h = 0.0
			var node := _kit.make(id, v, {"collision": false})
			var o := _kit.origin(id, v)
			node.z_index = 0
			node.scale = Vector2.ONE * k
			node.position = Vector2(x, y) + o * k
			_page.add_child(node)
			var tag := _label(v + (" ×%d" % fr.size() if fr.size() > 1 else ""), 11, DIM)
			tag.position = Vector2(x, y + size.y * k + 1.0)
			_page.add_child(tag)
			x += cell_w
			row_h = maxf(row_h, size.y * k)
		y += row_h + LABEL_H + 18.0
	return y


func _fill_set(set_name: String) -> float:
	var s: Dictionary = _kit.data["sets"][set_name]
	var full := Vector2(float(s["size"][0]) + 2.0, float(s["size"][1]) + DungeonKit.NORTH + 1.0) * _kit.px
	var k := minf(1.0, minf((VIEW.x - PAD * 2.0) / full.x, (VIEW.y - HEAD_H - PAD * 2.0) / full.y))
	var room := _kit.build_set(set_name, {"scale": k, "collision": false})
	room.position = Vector2((VIEW.x - full.x * k) * 0.5, PAD)
	_page.add_child(room)
	return full.y * k + PAD * 2.0


## 분류마다(길면 화면 단위로 내려 가며) 찍는다 → <폴더>/<번호>_<id>[_<쪽>].png
func _shoot(dir: String, only_one: bool) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for i in _groups.size():
		if only_one and i != _at:
			continue
		_show(i)
		var part := 0
		while true:
			for f in 5:
				await get_tree().process_frame
			var path := dir.path_join("%02d_%s%s.png" % [i + 1, String(_groups[i]["id"]), "" if part == 0 else "_%d" % part])
			get_viewport().get_texture().get_image().save_png(path)
			print("찍음: ", path)
			var before := _page.position.y
			_scroll(VIEW.y - HEAD_H - 40.0)
			part += 1
			if is_equal_approx(before, _page.position.y) or part > 40:
				break
