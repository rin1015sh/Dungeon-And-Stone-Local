class_name StatusIcons
extends Control
## 상태이상 아이콘 줄(UI24 — 피어 앤 헝거처럼 글자 대신 그림, 이름은 쓰지 않는다): 적은 무대의 이름 위, 아군은 파티 창 이름 옆.
## 그림 = assets/statuses/<상태 id>.webp(tools/paint_status_icons.gd). 여관 요리(meal 키)는 모두 "meal",
## 그림이 없는 상태는 종류에 따라 "buff"·"debuff". 겹친 수가 2 이상이면 아이콘 오른쪽 아래에 작은 숫자.
## 한 번에 per_page개(3)만 — 넘으면 page_sec마다 깜빡이며(blink_sec 동안 흐려졌다 밝아짐) 다음 묶음으로 넘어간다(UI25).
## 수치 = render.json ui.combat_status_icon{size, roster_size, gap, per_page, page_sec, blink_sec}.

const DIR := "res://assets/statuses"

static var _cache: Dictionary = {}  ## 그림 이름 → Texture2D

var _sig: String = ""  ## 지금 걸린 상태(같으면 다시 만들지 않는다)
var _all: Array = []  ## [[그림, 겹친 수], …]
var _page: int = 0
var _t: float = 0.0
var _px: float = 28.0
var _rects: Array[TextureRect] = []
var _counts: Array[Label] = []


## 상태 id의 아이콘 그림.
static func texture(db: GameDatabase, id: String) -> Texture2D:
	var def := db.get_entry("statuses", id)
	var key := "meal" if not JsonUtil.get_str(def, "meal").is_empty() else id
	if not ResourceLoader.exists(DIR.path_join(key + ".webp")):
		key = "buff" if JsonUtil.get_str(def, "kind") == "buff" else "debuff"
	if not _cache.has(key):
		_cache[key] = load(DIR.path_join(key + ".webp")) as Texture2D
	return _cache[key]


static func _cfg(key: String, fallback: float) -> float:
	return JsonUtil.get_float(UiTheme.ui_dict("combat_status_icon"), key, fallback)


## 아이콘 한 칸 크기: 무대(size) · 파티 창(roster_size).
static func icon_size(roster: bool = false) -> float:
	return _cfg("roster_size", 24.0) if roster else _cfg("size", 28.0)


## roster = 파티 창 이름 옆(작은 아이콘, 줄 폭 고정 — 상태가 없어도 자리를 차지해 옆 칸이 흔들리지 않게).
func _init(roster: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_px = icon_size(roster)
	var gap := _cfg("gap", 2.0)
	for i in int(_cfg("per_page", 3.0)):
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(i * (_px + gap), 0)
		tr.size = Vector2(_px, _px)
		add_child(tr)
		_rects.append(tr)
		var l := UiTheme.label("", "small", "text_title")
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		_counts.append(l)
	if roster:
		custom_minimum_size = Vector2(_rects.size() * (_px + gap) - gap, _px)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_show_page()


## 이 행동자의 상태로 다시 채운다. 보이는 개수가 바뀌었으면 true(자리를 다시 잡을 때).
func show_for(actor: Actor) -> bool:
	var ids := actor.statuses.ids()
	var parts := PackedStringArray()
	for id in ids:
		parts.append("%s:%d" % [id, actor.statuses.stacks(id)])
	var sig := ",".join(parts)
	if sig == _sig:
		return false
	var before := _shown()
	_sig = sig
	_all.clear()
	for id in ids:
		_all.append([texture(actor.db, id), actor.statuses.stacks(id)])
	if _page * _rects.size() >= _all.size():
		_page = 0
		_t = 0.0
	_show_page()
	return _shown() != before


func page_count() -> int:
	return ceili(float(_all.size()) / _rects.size())


## 지금 쪽에 보이는 아이콘 수.
func shown() -> int:
	return _shown()


func _shown() -> int:
	return clampi(_all.size() - _page * _rects.size(), 0, _rects.size())


func _show_page() -> void:
	var gap := _cfg("gap", 2.0)
	var n := _shown()
	for i in _rects.size():
		var k := _page * _rects.size() + i
		var on := i < n
		_rects[i].visible = on
		_counts[i].visible = on and int(_all[k][1]) > 1
		if not on:
			continue
		_rects[i].texture = _all[k][0]
		if _counts[i].visible:
			_counts[i].text = str(_all[k][1])
			var ms := _counts[i].get_minimum_size()
			_counts[i].size = ms
			_counts[i].position = _rects[i].position + Vector2(_px, _px) - ms + Vector2(3, 5)  # 오른쪽 아래 모서리
	size = Vector2(maxf(custom_minimum_size.x, n * (_px + gap) - gap), _px)


func _process(delta: float) -> void:
	if page_count() < 2:
		modulate.a = 1.0
		return
	var sec := _cfg("page_sec", 1.8)
	var blink := _cfg("blink_sec", 0.25)
	_t += delta
	if _t >= sec:
		_t = 0.0
		_page = (_page + 1) % page_count()
		_show_page()
	modulate.a = clampf(minf(_t, sec - _t) / blink, 0.0, 1.0)
