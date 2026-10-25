class_name PartyPage
extends MenuPage
## Tab 메뉴 맨 왼쪽 쪽(사용자 요청 2026-10-25, UI26): 아군 목록 — 줄마다 이름 + 생명력·영혼력·허기·피로 짧은 막대
## (탐험 화면 하단 바를 없앤 대신 여기서 본다), 맨 끝에 도감. W/S = 커서, Enter = 그 아군을 고른다(가운데·오른쪽 쪽이
## 그 아군으로 바뀐다) / 도감을 연다. 고른 아군은 금빛 테두리, 커서는 밝은 바탕.

signal ally_selected(a: PlayerCharacter)
signal bestiary_requested

const BARS := ["hp", "soul", "hunger"]

var party: Array[PlayerCharacter] = []
var selected: int = 0  ## 고른 아군 번호(도감이면 party.size())

var _cursor: int = 0
var _rows: Array[PanelContainer] = []
var _fills: Array = []  # 줄마다 [[막대, 값 글, 자원 id 또는 "fatigue"], …]


func _init() -> void:
	super(Strings.t("party.title"))


func setup(p_party: Array[PlayerCharacter]) -> void:
	party = p_party
	custom_minimum_size.x = MenuPage.cfg("party_width", 230.0)
	for i in party.size():
		_add_row(i)
	var be := PanelContainer.new()
	be.add_child(UiTheme.label(Strings.t("party.bestiary"), "body", "text_title"))
	content.add_child(be)
	_rows.append(be)
	_fills.append([])
	refresh()


func refresh() -> void:
	for i in party.size():
		var pc := party[i]
		for f: Array in _fills[i]:
			var bar := f[0] as ProgressBar
			var key := str(f[2])
			var row := bar.get_parent() as Control
			if key == "fatigue":
				bar.max_value = JsonUtil.get_float(pc.fatigue.rules, "max", MenuPage.cfg("party_fatigue_max", 100.0))
				bar.value = pc.fatigue.value
				(f[1] as Label).text = "%d" % roundi(pc.fatigue.value)
				continue
			row.visible = pc.pool.has_resource(key) and pc.pool.get_def(key).visible and pc.pool.is_active(key)
			if not row.visible:
				continue
			bar.max_value = maxf(1.0, pc.pool.get_max(key))
			bar.value = pc.pool.get_current(key)
			(f[1] as Label).text = "%d/%d" % [ceili(pc.pool.get_current(key)), roundi(pc.pool.get_max(key))]
	_paint_rows()


func enter(_from_left: bool) -> void:
	_cursor = selected
	_paint_rows()


func on_active(_on: bool) -> void:
	_paint_rows()


## W/S = 위아래(A/D는 옆 쪽으로).
func nav(d: Vector2i) -> bool:
	if d.y == 0:
		return false
	_cursor = clampi(_cursor + d.y, 0, _rows.size() - 1)
	_paint_rows()
	return true


func confirm() -> void:
	selected = _cursor
	_paint_rows()
	if _cursor < party.size():
		ally_selected.emit(party[_cursor])
	else:
		bestiary_requested.emit()


func cursor() -> int:
	return _cursor


## 고른 줄 표시(GameMenu가 아군·도감을 바꿀 때).
func mark(i: int) -> void:
	selected = i
	_paint_rows()


func _add_row(i: int) -> void:
	var pc := party[i]
	var panel := PanelContainer.new()
	content.add_child(panel)
	_rows.append(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)
	var nm := UiTheme.label(pc.display_name if not pc.display_name.is_empty() else Strings.t("party.nameless"), "body", "text_title")
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	var fills: Array = []
	for r: String in BARS:
		if not pc.pool.has_resource(r):
			continue
		var rd: ResourceDef = pc.db.resources.get(r)
		fills.append(_bar_row(v, rd.name_ko if rd != null else r, rd.color if rd != null else Color.GRAY, r))
	fills.append(_bar_row(v, Strings.t("party.fatigue"), UiTheme.color("bar_fatigue", UiTheme.color("gold")), "fatigue"))
	_fills.append(fills)


func _bar_row(parent: Control, label: String, col: Color, key: String) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var l := UiTheme.label(label, "small", "text_dim")
	l.custom_minimum_size.x = MenuPage.cfg("party_label_width", 48.0)
	row.add_child(l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size.y = MenuPage.cfg("party_bar_height", 6.0)
	bar.add_theme_stylebox_override("fill", UiTheme.box(col, Color.TRANSPARENT, 1, 0))
	bar.add_theme_stylebox_override("background", UiTheme.box(Color(0, 0, 0, 0.5), Color.TRANSPARENT, 1, 0))
	row.add_child(bar)
	var val := UiTheme.label("", "small", "text")
	val.custom_minimum_size.x = MenuPage.cfg("party_value_width", 58.0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)
	return [bar, val, key]


func _paint_rows() -> void:
	for i in _rows.size():
		var cur := active and i == _cursor
		var sel := i == selected
		var bg := UiTheme.color("slot_hover") if cur else Color(0, 0, 0, 0)
		var border := UiTheme.color("gold") if sel else Color(0, 0, 0, 0)
		_rows[i].add_theme_stylebox_override("panel", UiTheme.box(bg, border, 2, UiTheme.metric("combat_roster_pad", 6)))
