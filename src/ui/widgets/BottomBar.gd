class_name BottomBar
extends PanelContainer
## 하단 바(스톤샤드식): 왼쪽 키 표(메뉴 Tab) · 가운데 생명력/영혼력 큰 막대 + 단축칸 1~0 + 허기 막대 ·
## 오른쪽 키 표(대기·휴식·정지). 위에 상태이상 줄. 누르는 버튼이 아니라 키 이름판이다(키보드만 — 사용자 결정 2026-10-19).
## 단축칸: Tab 메뉴 소지품 쪽에서 등록·빼기, 숫자 키로 사용.

var pc: PlayerCharacter

var _hp: _BigBar
var _soul: _BigBar
var _hunger: ProgressBar
var _status: Label
var _slots: Array[HotbarSlot] = []


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	add_theme_stylebox_override("panel", GothicStyle.frame_box())
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	add_child(outer)
	_status = UiTheme.label("", "small", "warn")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# 상태가 없어도 줄 높이를 늘 차지한다 — 상태가 생길 때 바가 위로 자라 기록창 아랫줄을 가리지 않게.
	_status.custom_minimum_size.y = UiTheme.metric("small_font_size", 14) + 6
	outer.add_child(_status)
	var row := HBoxContainer.new()
	outer.add_child(row)
	var left := HBoxContainer.new()
	left.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(left)
	left.add_child(_key_plate(Strings.t("bottom.menu", {"key": InputSetup.key_label("menu")})))
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 4)
	row.add_child(mid)
	var bars := HBoxContainer.new()
	mid.add_child(bars)
	_hp = _BigBar.new(UiTheme.color("bar_hp"))
	_soul = _BigBar.new(UiTheme.color("bar_soul"))
	bars.add_child(_hp)
	bars.add_child(_soul)
	var hot := HBoxContainer.new()
	hot.add_theme_constant_override("separation", 3)
	mid.add_child(hot)
	for i in PlayerCharacter.HOTBAR_SIZE:
		var s := HotbarSlot.new()
		s.setup(pc, i)
		hot.add_child(s)
		_slots.append(s)
	_hunger = ProgressBar.new()
	_hunger.show_percentage = false
	_hunger.custom_minimum_size.y = 6
	_hunger.add_theme_stylebox_override("fill", UiTheme.box(UiTheme.color("bar_hunger"), Color.TRANSPARENT, 1, 0))
	mid.add_child(_hunger)
	var right := HBoxContainer.new()
	right.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(right)
	for a: String in ["wait", "rest", "pause"]:
		right.add_child(_key_plate(Strings.t("bottom." + a, {"key": InputSetup.key_label(a)})))
	pc.pool.changed.connect(_on_pool_changed)
	pc.inventory.changed.connect(_on_inventory_changed)
	pc.status_changed.connect(_on_status_changed)
	refresh()


func refresh() -> void:
	_hp.set_values(pc.pool.get_current("hp"), pc.pool.get_max("hp"))
	_soul.set_values(pc.pool.get_current("soul"), pc.pool.get_max("soul"))
	if pc.pool.ids().has("hunger"):
		_hunger.max_value = maxf(1.0, pc.pool.get_max("hunger"))
		_hunger.value = pc.pool.get_current("hunger")
		_hunger.visible = pc.pool.is_active("hunger")
	var names := PackedStringArray()
	for id in pc.statuses.ids():
		names.append("[%s]" % DataNames.entry(pc.db, "statuses", id))
	_status.text = " ".join(names)
	for s in _slots:
		s.queue_redraw()


func slot(i: int) -> HotbarSlot:
	return _slots[i]


func _on_pool_changed(_id: String, _c: float, _m: float) -> void:
	refresh()


func _on_inventory_changed(_id: String, _n: int) -> void:
	refresh()


func _on_status_changed(_id: String, _on: bool) -> void:
	refresh()


## 키 이름판(누르는 버튼이 아니다).
func _key_plate(text: String) -> Label:
	var l := UiTheme.label(text, "small", "text")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(UiTheme.metric("side_button", 40) * 1.6, UiTheme.metric("side_button", 40))
	l.add_theme_stylebox_override("normal", GothicStyle.slot_box())
	return l


## 수치가 가운데 적힌 큰 막대(생명력·영혼력).
class _BigBar extends ProgressBar:
	var _label: Label

	func _init(fill: Color) -> void:
		show_percentage = false
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		custom_minimum_size = Vector2(0, UiTheme.metric("bar_big_height", 22))
		add_theme_stylebox_override("fill", UiTheme.box(fill, Color.TRANSPARENT, 2, 0))
		_label = UiTheme.label("", "small", "text_title")
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_label)
		_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func set_values(cur: float, mx: float) -> void:
		max_value = maxf(1.0, mx)
		value = cur
		_label.text = "%d/%d" % [ceili(cur) if cur > 0.0 else 0, roundi(mx)]


## 단축칸 하나.
class HotbarSlot extends Control:
	var pc: PlayerCharacter
	var index: int = 0

	func setup(p_pc: PlayerCharacter, i: int) -> void:
		pc = p_pc
		index = i
		custom_minimum_size = Vector2.ONE * UiTheme.metric("hotbar_slot", 46)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func item_id() -> String:
		return pc.hotbar[index] if index < pc.hotbar.size() else ""

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		GothicStyle.draw_slot(self, r)
		var id := item_id()
		var font := get_theme_default_font()
		var fs := UiTheme.metric("small_font_size", 14)
		if not id.is_empty():
			var n := pc.inventory.count(id)
			ItemIconPainter.draw(self, pc.db, id, r.grow(-5), 1.0 if n > 0 else 0.3)
			var t := str(n)
			draw_string_outline(font, Vector2(size.x - font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x - 3, size.y - 3), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color.BLACK)
			draw_string(font, Vector2(size.x - font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x - 3, size.y - 3), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiTheme.color("text_title"))
		var key := InputSetup.key_label("hotbar_%d" % ((index + 1) % 10))
		draw_string_outline(font, Vector2(3, fs), key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, 3, Color.BLACK)
		draw_string(font, Vector2(3, fs), key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs - 2, UiTheme.color("text_dim"))

	## 아이템을 이 칸에 등록한다(스모크 테스트도 쓴다).
	func assign(item_id_: String) -> void:
		pc.set_hotbar(index, item_id_)
		for s in get_parent().get_children():
			(s as Control).queue_redraw()
