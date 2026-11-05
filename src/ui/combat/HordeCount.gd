class_name HordeCount
extends Label
## 큰 무리 전투에서 아직 뒤에 남은 적 수(Battle.horde — BattleHorde, floor2.md §1-2). 문구 없이 숫자만(UI19) — 무대 오른쪽 위.
## 예비대가 다 들어오면 사라진다. 수치(여백 · 글자 크기)는 render.json ui.horde_count.

var _battle: Battle


func setup(b: Battle) -> void:
	_battle = b
	var cfg := UiTheme.ui_dict("horde_count")
	add_theme_font_size_override("font_size", int(JsonUtil.get_float(cfg, "font_size", 24)))
	add_theme_color_override("font_color", UiTheme.color("text_title"))
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", int(JsonUtil.get_float(cfg, "outline", 5)))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -JsonUtil.get_float(cfg, "x", 24)
	offset_top = JsonUtil.get_float(cfg, "y", 20)
	_show()


func _process(_delta: float) -> void:
	_show()


func _show() -> void:
	var n := _battle.horde.size() if _battle != null else 0
	visible = n > 0
	if visible:
		text = Strings.t("combat.horde_left", {"n": n})
