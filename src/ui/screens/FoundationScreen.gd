class_name FoundationScreen
extends Control
## '기반 점검' 화면(개발용). 스탯 굴림·수정자·자원(생명력/영혼력/허기)·상태이상을 직접 만져 본다.
## 개체는 게임과 같은 Actor를 쓰므로 허기 → 굶주림 → 아사, 영혼탈진이 실제 규칙대로 작동한다.

signal back_requested

const BUFF_SOURCE := "debug:str_elixir"

var _db: GameDatabase
var _rng: Rng
var _actor: Actor
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
	_actor = Actor.new(_db, CharacterRoller.roll_base_stats(_db, race_id, class_id, _rng), _level)
	_actor.pool.set_context("dungeon", _dungeon_btn.button_pressed)
	_actor.pool.depleted.connect(_on_depleted)
	_actor.pool.recovered.connect(_on_recovered)
	_actor.status_changed.connect(_on_status_changed)
	_stat_panel.bind(_actor.stats)
	_res_panel.bind(_actor.pool)
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
	_actor.set_level(_level)
	_refresh_labels()
	_log("log.level", {"level": _level}, "system")


func _refresh_labels() -> void:
	_reroll_btn.text = Strings.t("foundation.reroll", {"left": _rerolls_left})
	_reroll_btn.disabled = _rerolls_left <= 0
	_info_label.text = Strings.t("foundation.info", {"level": _level, "seed": _rng.seed_value})
	var left := _actor.stats.source_remaining(BUFF_SOURCE)
	if left == 0.0:
		_buff_btn.text = Strings.t("foundation.act_buff_on", {"amount": _dbg("sandbox_buff_str"), "hours": _dbg("sandbox_buff_hours")})
	else:
		_buff_btn.text = Strings.t("foundation.act_buff_off", {"left": UiTheme.num(left)})


# ── 조작 ──────────────────────────────────────────────────

func _act_damage() -> void:
	_actor.pool.modify("hp", -_dbg("sandbox_damage"), "debug")
	_log("log.damage", {"amount": _dbg("sandbox_damage")}, "danger")


func _act_spend_soul() -> void:
	var cost := _dbg("sandbox_soul_cost")
	if _actor.pool.spend({"soul": cost}, "debug"):
		_log("log.spend_ok", {"amount": cost})
	else:
		_log("log.spend_fail", {}, "warn")


func _act_turn() -> void:
	var had_buff := _actor.stats.has_source(BUFF_SOURCE)
	_actor.advance_turns(1.0)
	_log("log.turn")
	_announce_expired(had_buff)


func _act_hour() -> void:
	var had_buff := _actor.stats.has_source(BUFF_SOURCE)
	_log("log.hour" if _actor.pool.is_active("hunger") else "log.hour_city")
	_actor.advance_hours(1.0)
	_announce_expired(had_buff)
	_refresh_labels()


func _act_eat() -> void:
	_actor.pool.modify("hunger", _dbg("sandbox_food"), "food")
	_log("log.eat", {}, "good")


func _act_restore() -> void:
	_actor.debug_revive()
	_actor.pool.fill_all()
	_log("log.restore", {}, "good")


func _act_toggle_buff() -> void:
	if _actor.stats.has_source(BUFF_SOURCE):
		_actor.stats.remove_source(BUFF_SOURCE)
		_log("log.buff_off")
	else:
		_actor.stats.add_modifier(Modifier.new(BUFF_SOURCE, "str", _dbg("sandbox_buff_str"), 0.0, _dbg("sandbox_buff_hours"), "hour"))
		_log("log.buff_on", {"amount": _dbg("sandbox_buff_str")}, "good")
	_refresh_labels()


func _on_dungeon_toggled(on: bool) -> void:
	_actor.pool.set_context("dungeon", on)


func _on_back() -> void:
	AudioBus.play_sfx("ui_back")
	back_requested.emit()


# ── 자원·상태이상 기록 ────────────────────────────────────

func _on_depleted(res_id: String) -> void:
	var def := _actor.pool.get_def(res_id)
	if def.on_zero_kind == ResourceDef.ON_ZERO_KILL:
		_log("log.depleted_hp", {}, "danger")
	else:
		_log("log.depleted", {"resource": def.name_ko}, "danger")


func _on_recovered(res_id: String) -> void:
	_log("log.recovered", {"resource": _actor.pool.get_def(res_id).name_ko}, "good")


func _on_status_changed(status_id: String, active: bool) -> void:
	var status_name := DataNames.entry(_db, "statuses", status_id)
	_log("log.status_on" if active else "log.status_off", {"status": status_name}, "warn" if active else "good")


func _announce_expired(had_buff: bool) -> void:
	if had_buff and not _actor.stats.has_source(BUFF_SOURCE):
		_log("log.buff_expired", {}, "system")


func _dbg(key: String) -> int:
	return int(_db.bal("debug." + key, 0))


func _log(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	EventBus.log_message.emit(Strings.t(key, args), kind)
