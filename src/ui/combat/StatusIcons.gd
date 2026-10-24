class_name StatusIcons
extends Control
## 머리 위 상태이상 아이콘 줄(UI24 — 피어 앤 헝거처럼 글자 대신 그림, 이름은 쓰지 않는다).
## 그림 = assets/statuses/<상태 id>.webp(tools/paint_status_icons.gd). 여관 요리(meal 키)는 모두 "meal",
## 그림이 없는 상태는 종류에 따라 "buff"·"debuff". 겹친 수가 2 이상이면 아이콘 오른쪽 아래에 작은 숫자.
## 줄 폭(per_row)을 넘으면 위로 한 줄 더 쌓는다(붙어 선 적끼리 겹치지 않게). 크기·간격·최대 개수 = render.json ui.combat_status_icon.

const DIR := "res://assets/statuses"

static var _cache: Dictionary = {}  ## 그림 이름 → Texture2D

var _sig: String = ""  ## 지금 보이는 상태(같으면 다시 만들지 않는다)
var _per_row: int = 99


## 상태 id의 아이콘 그림.
static func texture(db: GameDatabase, id: String) -> Texture2D:
	var def := db.get_entry("statuses", id)
	var key := "meal" if not JsonUtil.get_str(def, "meal").is_empty() else id
	if not ResourceLoader.exists(DIR.path_join(key + ".webp")):
		key = "buff" if JsonUtil.get_str(def, "kind") == "buff" else "debuff"
	if not _cache.has(key):
		_cache[key] = load(DIR.path_join(key + ".webp")) as Texture2D
	return _cache[key]


static func icon_size() -> float:
	return JsonUtil.get_float(UiTheme.ui_dict("combat_status_icon"), "size", 28.0)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 이 폭(px) 안에 한 줄로 놓을 수 있는 만큼(최소 2개). 바뀌면 다음 show_for에서 다시 만든다.
func fit_width(w: float) -> void:
	var cfg := UiTheme.ui_dict("combat_status_icon")
	var gap := JsonUtil.get_float(cfg, "gap", 2.0)
	var n := maxi(2, floori((w + gap) / (icon_size() + gap)))
	if n != _per_row:
		_per_row = n
		_sig = ""


## 이 행동자의 상태로 줄을 다시 만든다. 바뀌었으면 true(자리를 다시 잡을 때).
func show_for(actor: Actor) -> bool:
	var ids := actor.statuses.ids()
	var parts := PackedStringArray()
	for id in ids:
		parts.append("%s:%d" % [id, actor.statuses.stacks(id)])
	var sig := ",".join(parts)
	if sig == _sig:
		return false
	_sig = sig
	for c in get_children():
		c.queue_free()
	var cfg := UiTheme.ui_dict("combat_status_icon")
	var s := icon_size()
	var gap := JsonUtil.get_float(cfg, "gap", 2.0)
	var n := mini(ids.size(), int(JsonUtil.get_float(cfg, "max", 8.0)))
	var cols := mini(n, _per_row)
	var rows := ceili(float(n) / maxf(1.0, cols))
	for i in n:
		var at := Vector2((i % cols) * (s + gap), (rows - 1 - floori(float(i) / cols)) * (s + gap))  # 첫 줄이 맨 아래(머리 쪽)
		var tr := TextureRect.new()
		tr.texture = texture(actor.db, ids[i])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = at
		tr.size = Vector2(s, s)
		add_child(tr)
		var st := actor.statuses.stacks(ids[i])
		if st > 1:
			var l := UiTheme.label(str(st), "small", "text_title")
			l.add_theme_constant_override("outline_size", 4)
			l.add_theme_color_override("font_outline_color", Color.BLACK)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ms := l.get_minimum_size()
			l.position = at + Vector2(s, s) - ms + Vector2(3, 5)  # 오른쪽 아래 모서리
			l.size = ms
			add_child(l)
	size = Vector2(maxf(0.0, cols * (s + gap) - gap), maxf(0.0, rows * (s + gap) - gap))
	return true
