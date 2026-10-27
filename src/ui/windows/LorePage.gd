class_name LorePage
extends MenuPage
## 도감(B)의 서적 쪽(사용자 2026-10-27, UI32·CT52): 위 = 한 분야에서 읽은 대목 제목, 아래 = 커서가 놓인 대목의 글.
## W/S = 대목 사이(목록은 커서를 따라 스크롤). 읽지 않은 대목은 목록에 없다(몇 개가 남았는지도 보이지 않는다).

var db: GameDatabase
var known: Array[String] = []
var field: String = ""

var _list: VBoxContainer
var _list_scroll: ScrollContainer
var _detail: Label
var _ids: Array[String] = []
var _rows: Array[Label] = []
var _cursor: int = 0


func _init(title: String) -> void:
	super(title)


func setup(p_db: GameDatabase, p_known: Array[String], p_field: String) -> void:
	db = p_db
	known = p_known
	field = p_field
	custom_minimum_size.x = MenuPage.cfg("lore_width", 480.0)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", GothicStyle.inset_box())
	top.custom_minimum_size.y = MenuPage.cfg("lore_list_height", 220.0)
	content.add_child(top)
	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	top.add_child(_list_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list)
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", GothicStyle.inset_box())
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom)
	_detail = UiTheme.label("", "body")
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bottom.add_child(_detail)
	refresh()


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	_ids = CityInfo.known_in(db, known, field)
	for id in _ids:
		var l := UiTheme.label(Strings.t("codex.entry", {"name": JsonUtil.get_str(db.get_entry("city_info", id), "name_ko", id)}), "small")
		l.clip_text = true
		_list.add_child(l)
		_rows.append(l)
	_cursor = clampi(_cursor, 0, maxi(0, _ids.size() - 1))
	_show_cursor()


func enter(_from_left: bool) -> void:
	_show_cursor()


func on_active(_on: bool) -> void:
	if _detail != null:
		_show_cursor()


func nav(d: Vector2i) -> bool:
	if d.x != 0:
		return false
	if not _ids.is_empty():
		_cursor = clampi(_cursor + d.y, 0, _ids.size() - 1)
		_show_cursor()
	return true


func current_id() -> String:
	return _ids[_cursor] if _cursor >= 0 and _cursor < _ids.size() else ""


func _show_cursor() -> void:
	for i in _rows.size():
		var sel := i == _cursor
		var box := UiTheme.box(UiTheme.color("slot_hover") if sel and active else Color.TRANSPARENT,
			UiTheme.color("gold") if sel else Color.TRANSPARENT, 0, 2)
		box.set_border_width_all(1 if sel else 0)
		_rows[i].add_theme_stylebox_override("normal", box)
	if _ids.is_empty():
		_detail.text = Strings.t("codex.lore_empty")
		return
	var e := db.get_entry("city_info", _ids[_cursor])
	_detail.text = Strings.t("codex.lore_text", {"name": JsonUtil.get_str(e, "name_ko"), "text": JsonUtil.get_str(e, "text_ko")})
	_list_scroll.ensure_control_visible.call_deferred(_rows[_cursor])
