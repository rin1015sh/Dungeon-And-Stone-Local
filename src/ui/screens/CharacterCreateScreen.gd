class_name CharacterCreateScreen
extends Control
## 새 탐험가: 이름·종족·시작 템플릿을 고르고 타고난 몸(기본 스탯)을 굴린다(리롤 횟수 제한).
## 확정하면 confirmed(player). 종족·템플릿을 바꾸면 새 사람으로 보고 리롤 횟수를 되돌린다.

signal confirmed(player: PlayerCharacter)
signal back_requested

var _db: GameDatabase
var _rng: Rng
var _race_ids: Array[String] = []
var _class_ids: Array[String] = []
var _rerolls_left: int = 0
var _pc: PlayerCharacter

var _name_edit: LineEdit
var _race_opt: OptionButton
var _class_opt: OptionButton
var _race_desc: Label
var _class_desc: Label
var _reroll_btn: Button
var _stat_panel: StatPanel
var _res_panel: ResourcePanel
var _items_label: Label


func _ready() -> void:
	_db = DataRegistry.db
	_rng = GameState.rng
	_race_ids = _db.enabled_ids("races")
	_class_ids = _db.enabled_ids("classes")
	_build()
	_new_person()


func _build() -> void:
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UiTheme.metric("margin", 16)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, m)
	var root := VBoxContainer.new()
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := UiTheme.label(Strings.t("create.title"), "header", "text_title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiTheme.button(Strings.t("menu.back"), func() -> void: back_requested.emit()))
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	var left := _column(cols, UiTheme.metric("left_column_width", 340))
	var who := UiTheme.section(left, Strings.t("create.who"))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = Strings.t("create.default_name")
	_name_edit.max_length = 16
	_row(who, Strings.t("create.name"), _name_edit)
	_race_opt = _option(who, Strings.t("create.race"), _race_ids, "races")
	_race_desc = _desc(who)
	_class_opt = _option(who, Strings.t("create.template"), _class_ids, "classes")
	_class_desc = _desc(who)
	_reroll_btn = UiTheme.button("", _on_reroll)
	who.add_child(_reroll_btn)

	var mid := _column(cols, UiTheme.metric("left_column_width", 340))
	_stat_panel = StatPanel.new()
	UiTheme.section(mid, Strings.t("create.body_header")).add_child(_stat_panel)
	_res_panel = ResourcePanel.new()
	UiTheme.section(mid, Strings.t("create.resources_header")).add_child(_res_panel)

	var right := _column(cols, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bag := UiTheme.section(right, Strings.t("create.items_header"))
	_items_label = _desc(bag)
	var go := UiTheme.section(right, Strings.t("create.enter_header"))
	_desc(go, Strings.t("create.floor_hint", {"floor": DataNames.entry(_db, "floors", str(_db.bal("explore.start_floor", "")))}))
	var enter := UiTheme.button(Strings.t("create.enter"), _on_enter)
	go.add_child(enter)
	enter.grab_focus.call_deferred()


func _column(parent: Control, width: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = width
	parent.add_child(col)
	return col


func _row(parent: Control, caption: String, field: Control) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := UiTheme.label(caption)
	l.custom_minimum_size.x = UiTheme.metric("caption_width", 96)
	row.add_child(l)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)


func _option(parent: Control, caption: String, ids: Array[String], col: String) -> OptionButton:
	var opt := OptionButton.new()
	for i in ids.size():
		opt.add_item(DataNames.entry(_db, col, ids[i]), i)
	opt.item_selected.connect(func(_i: int) -> void: _new_person())
	_row(parent, caption, opt)
	return opt


func _desc(parent: Control, text: String = "") -> Label:
	var l := UiTheme.label(text, "small", "text_dim")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


func _new_person() -> void:
	_rerolls_left = int(_db.bal("char_creation.max_rerolls", 0))
	_roll()


func _on_reroll() -> void:
	if _rerolls_left <= 0:
		return
	_rerolls_left -= 1
	_roll()


func _roll() -> void:
	var race_id := _race_ids[maxi(0, _race_opt.selected)]
	var class_id := _class_ids[maxi(0, _class_opt.selected)]
	var bases := CharacterRoller.roll_base_stats(_db, race_id, class_id, _rng)
	_pc = PlayerCharacter.create(_db, race_id, class_id, "", bases)
	_stat_panel.bind(_pc.stats)
	_res_panel.bind(_pc.pool)
	_race_desc.text = JsonUtil.get_str(_db.get_entry("races", race_id), "desc_ko")
	_class_desc.text = JsonUtil.get_str(_db.get_entry("classes", class_id), "desc_ko")
	_reroll_btn.text = Strings.t("create.reroll", {"left": _rerolls_left})
	_reroll_btn.disabled = _rerolls_left <= 0
	var items := PackedStringArray()
	for id in _pc.inventory.ids():
		items.append("%s ×%d" % [DataNames.entry(_db, "items", id), _pc.inventory.count(id)])
	_items_label.text = "\n".join(items) if not items.is_empty() else Strings.t("create.items_none")


func _on_enter() -> void:
	var name_text := _name_edit.text.strip_edges()
	_pc.display_name = name_text if not name_text.is_empty() else Strings.t("create.default_name")
	AudioBus.play_sfx("ui_click")
	confirmed.emit(_pc)
