class_name FoundationScreen
extends Control
## M0 '기반 점검' 화면. 스탯 굴림·수정자·자원(생명력/영혼력/허기)을 직접 만져 보는 개발용 화면.
## 상태이상의 수정자 부여는 M2 StatusSet이 맡을 일을 여기서 최소한으로만 흉내 낸다.

signal back_requested

const BUFF_SOURCE := "debug:str_elixir"
const STATUS_SOURCE_PREFIX := "status:"

var _db: GameDatabase
var _rng: Rng
var _stats: StatBlock
var _pool: ResourcePool
var _race_ids: Array[String] = []
var _class_ids: Array[String] = []
var _rerolls_left: int = 0
var _level: int = 1

var _race_opt: OptionButton
var _class_opt: OptionButton
var _reroll_btn: Button
var _info_label: Label
var _stat_panel: StatPanel
var _res_panel: ResourcePanel
var _buff_btn: Button
var _dungeon_btn: CheckButton


func _ready() -> void:
	_db = DataRegistry.db
	_rng = Rng.new(GameState.master_seed)
	_race_ids = _db.enabled_ids("races")
	_class_ids = _db.enabled_ids("classes")
	_build_ui()
	_log("log.welcome", {}, "system")
	_new_character()


# ── 화면 구성 ──────────────────────────────────────────────

func _build_ui() -> void:
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
	var title := UiTheme.label(Strings.t("foundation.title"), "header", "text_title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UiTheme.button(Strings.t("menu.back"), _on_back))
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)
	_build_character_column(cols)
	_build_resource_column(cols)
	var log_panel := LogPanel.new()
	log_panel.custom_minimum_size.x = UiTheme.metric("right_column_width", 380)
	cols.add_child(log_panel)


func _build_character_column(parent: Control) -> void:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = UiTheme.metric("left_column_width", 340)
	parent.add_child(col)
	var box := UiTheme.section(col, Strings.t("foundation.character"))
	_race_opt = _add_option(box, Strings.t("foundation.race"), _race_ids, "races")
	_class_opt = _add_option(box, Strings.t("foundation.template"), _class_ids, "classes")
	_reroll_btn = UiTheme.button("", _on_reroll)
	box.add_child(_reroll_btn)
	_info_label = UiTheme.label("", "small", "text_dim")
	box.add_child(_info_label)
	var lv := HBoxContainer.new()
	box.add_child(lv)
	lv.add_child(UiTheme.button(Strings.t("foundation.level_down"), func() -> void: _change_level(-1)))
	lv.add_child(UiTheme.button(Strings.t("foundation.level_up"), func() -> void: _change_level(1)))
	_stat_panel = StatPanel.new()
	UiTheme.section(col, Strings.t("foundation.stats_header")).add_child(_stat_panel)


func _build_resource_column(parent: Control) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	var box := UiTheme.section(col, Strings.t("foundation.resources_header"))
	_res_panel = ResourcePanel.new()
	box.add_child(_res_panel)
	_dungeon_btn = CheckButton.new()
	_dungeon_btn.text = Strings.t("foundation.in_dungeon")
	_dungeon_btn.toggled.connect(_on_dungeon_toggled)
	box.add_child(_dungeon_btn)

	var act := UiTheme.section(col, Strings.t("foundation.actions_header"))
	var grid := GridContainer.new()
	grid.columns = 2
	act.add_child(grid)
	_add_action(grid, Strings.t("foundation.act_damage", {"amount": _dbg("sandbox_damage")}), _act_damage)
	_add_action(grid, Strings.t("foundation.act_spend_soul", {"amount": _dbg("sandbox_soul_cost")}), _act_spend_soul)
	_add_action(grid, Strings.t("foundation.act_turn"), _act_turn)
	_add_action(grid, Strings.t("foundation.act_hour"), _act_hour)
	_add_action(grid, Strings.t("foundation.act_eat", {"amount": _dbg("sandbox_food")}), _act_eat)
	_add_action(grid, Strings.t("foundation.act_restore"), _act_restore)
	_buff_btn = _add_action(grid, "", _act_toggle_buff)

	var summary := DataSummary.new()
	summary.show_data(_db, DataRegistry.validator)
	UiTheme.section(col, Strings.t("foundation.data_header")).add_child(summary)


func _add_option(parent: Control, caption: String, ids: Array[String], col: String) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := UiTheme.label(caption)
	l.custom_minimum_size.x = UiTheme.metric("caption_width", 96)
	row.add_child(l)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in ids.size():
		opt.add_item(JsonUtil.get_str(_db.get_entry(col, ids[i]), "name_ko", ids[i]), i)
	opt.item_selected.connect(func(_i: int) -> void: _new_character())
	row.add_child(opt)
	return opt


func _add_action(grid: GridContainer, text: String, cb: Callable) -> Button:
	var b := UiTheme.button(text, cb)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(b)
	return b


# ── 캐릭터 ────────────────────────────────────────────────

func _new_character() -> void:
	_rerolls_left = int(_db.bal("char_creation.max_rerolls", 0))
	_level = int(_db.bal("char_creation.start_level", 1))
	_roll()


func _on_reroll() -> void:
	if _rerolls_left <= 0:
		AudioBus.play_sfx("ui_denied")
		return
	_rerolls_left -= 1
	_roll()


func _roll() -> void:
	if _race_ids.is_empty() or _class_ids.is_empty():
		return
	var race_id := _race_ids[maxi(0, _race_opt.selected)]
	var class_id := _class_ids[maxi(0, _class_opt.selected)]
	_stats = StatBlock.new(_db.stats)
	_stats.set_bases(CharacterRoller.roll_base_stats(_db, race_id, class_id, _rng))
	_pool = ResourcePool.new(_db, _stats, [], {}, _level)
	_pool.set_context("dungeon", _dungeon_btn.button_pressed)
	_pool.threshold_crossed.connect(_on_threshold)
	_pool.depleted.connect(_on_depleted)
	_pool.recovered.connect(_on_recovered)
	_stat_panel.bind(_stats)
	_res_panel.bind(_pool)
	_refresh_labels()
	_log("log.rolled", {
		"race": JsonUtil.get_str(_db.get_entry("races", race_id), "name_ko"),
		"template": JsonUtil.get_str(_db.get_entry("classes", class_id), "name_ko")})


func _change_level(delta: int) -> void:
	var lo := int(_db.bal("level.min", 1))
	var hi := int(_db.bal("level.max_cap", 11))
	var next := clampi(_level + delta, lo, hi)
	if next == _level:
		return
	_level = next
	_pool.set_level(_level)
	_refresh_labels()
	_log("log.level", {"level": _level}, "system")


func _refresh_labels() -> void:
	_reroll_btn.text = Strings.t("foundation.reroll", {"left": _rerolls_left})
	_reroll_btn.disabled = _rerolls_left <= 0
	_info_label.text = Strings.t("foundation.info", {"level": _level, "seed": _rng.seed_value})
	var left := _stats.source_remaining(BUFF_SOURCE)
	if left == 0.0:
		_buff_btn.text = Strings.t("foundation.act_buff_on", {"amount": _dbg("sandbox_buff_str"), "hours": _dbg("sandbox_buff_hours")})
	else:
		_buff_btn.text = Strings.t("foundation.act_buff_off", {"left": UiTheme.num(left)})


# ── 조작 ──────────────────────────────────────────────────

func _act_damage() -> void:
	_pool.modify("hp", -_dbg("sandbox_damage"), "debug")
	_log("log.damage", {"amount": _dbg("sandbox_damage")}, "danger")


func _act_spend_soul() -> void:
	var cost := _dbg("sandbox_soul_cost")
	if _pool.spend({"soul": cost}, "debug"):
		_log("log.spend_ok", {"amount": cost})
	else:
		_log("log.spend_fail", {}, "warn")


func _act_turn() -> void:
	_pool.tick("turn", 1.0)
	_announce_expired(_stats.tick("turn", 1.0))
	_log("log.turn")


func _act_hour() -> void:
	_log("log.hour" if _pool.is_active("hunger") else "log.hour_city")
	_pool.tick("time", 1.0)
	_announce_expired(_stats.tick("hour", 1.0))
	_refresh_labels()


func _act_eat() -> void:
	_pool.modify("hunger", _dbg("sandbox_food"), "food")
	_log("log.eat", {}, "good")


func _act_restore() -> void:
	_pool.fill_all()
	_log("log.restore", {}, "good")


func _act_toggle_buff() -> void:
	if _stats.has_source(BUFF_SOURCE):
		_stats.remove_source(BUFF_SOURCE)
		_log("log.buff_off")
	else:
		_stats.add_modifier(Modifier.new(BUFF_SOURCE, "str", _dbg("sandbox_buff_str"), 0.0, _dbg("sandbox_buff_hours"), "hour"))
		_log("log.buff_on", {"amount": _dbg("sandbox_buff_str")}, "good")
	_refresh_labels()


func _on_dungeon_toggled(on: bool) -> void:
	_pool.set_context("dungeon", on)


func _on_back() -> void:
	AudioBus.play_sfx("ui_back")
	back_requested.emit()


# ── 자원 시그널 → 상태이상(임시 연결) ─────────────────────

func _on_threshold(_res_id: String, threshold: Dictionary, entered: bool) -> void:
	_set_status(JsonUtil.get_str(threshold, "apply_status"), entered)


func _on_depleted(res_id: String) -> void:
	var def := _pool.get_def(res_id)
	if def.on_zero_kind == ResourceDef.ON_ZERO_KILL:
		_log("log.depleted_hp", {}, "danger")
		return
	_log("log.depleted", {"resource": def.name_ko}, "danger")
	if def.on_zero_kind == ResourceDef.ON_ZERO_STATUS:
		_set_status(def.on_zero_id, true)


func _on_recovered(res_id: String) -> void:
	var def := _pool.get_def(res_id)
	_log("log.recovered", {"resource": def.name_ko}, "good")
	if def.on_zero_kind == ResourceDef.ON_ZERO_STATUS:
		_set_status(def.on_zero_id, false)


func _set_status(status_id: String, on: bool) -> void:
	if status_id.is_empty():
		return
	var entry := _db.get_entry("statuses", status_id)
	var source := STATUS_SOURCE_PREFIX + status_id
	if on:
		_stats.add_modifiers_from_data(source, JsonUtil.get_array(entry, "modifiers"))
	else:
		_stats.remove_source(source)
	var status_name := JsonUtil.get_str(entry, "name_ko", status_id)
	_log("log.status_on" if on else "log.status_off", {"status": status_name}, "warn" if on else "good")


func _announce_expired(sources: PackedStringArray) -> void:
	if sources.has(BUFF_SOURCE):
		_log("log.buff_expired", {}, "system")


func _dbg(key: String) -> int:
	return int(_db.bal("debug." + key, 0))


func _log(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	EventBus.log_message.emit(Strings.t(key, args), kind)
