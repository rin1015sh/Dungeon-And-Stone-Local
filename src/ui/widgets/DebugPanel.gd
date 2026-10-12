class_name DebugPanel
extends PanelContainer
## 디버그 패널(F1). 테스트 플레이를 빠르게 하는 치트 모음.
## 다음 마일스톤 항목(포탈 개방일)은 자리만 있고 비활성이다.

signal regenerate_requested(seed_value: int)

const STAT_SOURCE := "debug:stat_bump"

var _session: ExploreSession
var _seed_edit: LineEdit


func bind(session: ExploreSession) -> void:
	_session = session


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	custom_minimum_size.x = UiTheme.metric("debug_panel_width", 300)
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(UiTheme.label(Strings.t("debug.title"), "header", "warn"))
	var grid := GridContainer.new()
	grid.columns = 2
	v.add_child(grid)
	var db := _session.db
	var short := int(db.bal("debug.skip_hours_short", 1))
	var long := int(db.bal("debug.skip_hours_long", 12))
	var bump := int(db.bal("debug.stat_bump", 5))
	_btn(grid, Strings.t("debug.skip", {"hours": short}), func() -> void: _session.wait(short))
	_btn(grid, Strings.t("debug.skip", {"hours": long}), func() -> void: _session.wait(long))
	_btn(grid, Strings.t("debug.close_soon"), func() -> void: ExploreDebug.close_in(_session, 1.0))
	_btn(grid, Strings.t("debug.reveal"), func() -> void: ExploreDebug.reveal(_session))
	_btn(grid, Strings.t("debug.to_monument"), func() -> void: ExploreDebug.to_monument(_session))
	_btn(grid, Strings.t("debug.to_portal"), func() -> void: ExploreDebug.teleport(_session, ExploreDebug.nearest_portal(_session)))
	_btn(grid, Strings.t("debug.level_up"), func() -> void: _change_level(1))
	_btn(grid, Strings.t("debug.level_down"), func() -> void: _change_level(-1))
	_btn(grid, Strings.t("debug.stat_up", {"stat": DataNames.entry(db, "stats", "str"), "amount": bump}), func() -> void: _bump("str", bump))
	_btn(grid, Strings.t("debug.stat_up", {"stat": DataNames.entry(db, "stats", "agi"), "amount": bump}), func() -> void: _bump("agi", bump))
	_btn(grid, Strings.t("debug.hunger_zero"), func() -> void: _session.player.pool.set_current("hunger", 0.0, "debug"))
	_btn(grid, Strings.t("debug.restore"), func() -> void: _session.player.pool.fill_all())
	var invuln := CheckButton.new()
	invuln.text = Strings.t("debug.invulnerable")
	invuln.focus_mode = Control.FOCUS_NONE
	invuln.button_pressed = GameState.debug_invulnerable
	invuln.toggled.connect(_set_invulnerable)
	v.add_child(invuln)
	_set_invulnerable(invuln.button_pressed)
	var seed_row := HBoxContainer.new()
	v.add_child(seed_row)
	_seed_edit = LineEdit.new()
	_seed_edit.placeholder_text = Strings.t("debug.seed_placeholder", {"seed": _session.map.seed_value})
	_seed_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(_seed_edit)
	_btn(seed_row, Strings.t("debug.regenerate"), _regenerate)
	var later := PackedStringArray()
	_btn(v, Strings.t("debug.spawn_monster"), func() -> void: ExploreDebug.spawn_and_engage(_session))
	_btn(v, Strings.t("debug.give_essence"), _give_essence)
	for key: String in ["debug.portal_open_locked"]:
		later.append(Strings.t(key))
	var later_label := UiTheme.label(Strings.t("debug.later", {"list": " · ".join(later)}), "small", "text_dim")
	later_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(later_label)


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := UiTheme.button(text, cb)
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b


func _change_level(delta: int) -> void:
	var pc := _session.player
	var lo := int(_session.db.bal("level.min", 1))
	var hi := int(_session.db.bal("level.max_cap", 11))
	pc.set_level(clampi(pc.get_level() + delta, lo, hi))
	_session.refresh_view()


func _bump(stat: String, amount: int) -> void:
	_session.player.stats.add_modifier(Modifier.new(STAT_SOURCE, stat, float(amount)))
	_session.refresh_view()


func _set_invulnerable(on: bool) -> void:
	GameState.debug_invulnerable = on
	_session.player.pool.set_min_value("hp", 1.0 if on else 0.0)


func _regenerate() -> void:
	var text := _seed_edit.text.strip_edges()
	regenerate_requested.emit(text.to_int() if text.is_valid_int() else 0)


## 무작위 정수 하나를 흡수 대기 목록에 넣는다(시간 제한 없음).
func _give_essence() -> void:
	var ids: Array = _session.db.get_collection("essences").keys()
	if ids.is_empty():
		return
	ids.sort()
	var inst := EssenceDrop.make(_session.db, str(_session.rng.pick(ids)), "", _session.rng)
	_session.player.essences.add_pending(_session.db, inst)
	_session.message.emit("reward.essence", {"name": DataNames.entry(_session.db, "essences", str(inst["essence"])),
		"color": DataNames.tag(_session.db, "essence_colors", str(inst["color"]))}, "good")
