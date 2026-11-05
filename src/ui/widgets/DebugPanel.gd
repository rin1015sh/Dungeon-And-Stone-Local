class_name DebugPanel
extends PanelContainer
## 디버그 패널(F1). 테스트 플레이를 빠르게 하는 치트 모음.
## 다음 마일스톤 항목(포탈 개방일)은 자리만 있고 비활성이다.

signal regenerate_requested(seed_value: int)

const STAT_SOURCE := "debug:stat_bump"

var _session: ExploreSession
var _seed_edit: LineEdit
var _rift_pick: OptionButton


func bind(session: ExploreSession) -> void:
	_session = session


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	UiTheme.keyboard_panel(self)
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
	_btn(grid, Strings.t("debug.go_up"), func() -> void:
		if not ExploreDebug.go_up(_session):
			_session.message.emit("debug.go_up_none", {}, "system"))
	_btn(grid, Strings.t("debug.level_up"), func() -> void: _change_level(1))
	_btn(grid, Strings.t("debug.level_down"), func() -> void: _change_level(-1))
	_btn(grid, Strings.t("debug.stat_up", {"stat": DataNames.entry(db, "stats", "str"), "amount": bump}), func() -> void: _bump("str", bump))
	_btn(grid, Strings.t("debug.stat_up", {"stat": DataNames.entry(db, "stats", "agi"), "amount": bump}), func() -> void: _bump("agi", bump))
	_btn(grid, Strings.t("debug.hunger_zero"), func() -> void: _session.player.pool.set_current("hunger", 0.0, "debug"))
	_btn(grid, Strings.t("debug.restore"), func() -> void: _session.player.pool.fill_all())
	var invuln := CheckButton.new()
	invuln.text = Strings.t("debug.invulnerable")
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
	_btn(v, Strings.t("debug.summon_lord"), func() -> void: _session.lord.summon(_session))
	_btn(v, Strings.t("debug.add_companion"), _add_companion)
	_add_rift_row(v)
	for key: String in ["debug.portal_open_locked"]:
		later.append(Strings.t(key))
	var later_label := UiTheme.label(Strings.t("debug.later", {"list": " · ".join(later)}), "small", "text_dim")
	later_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(later_label)


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := UiTheme.button(text, cb)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(b)
	return b


func _change_level(delta: int) -> void:
	var pc := _session.player
	var lo := int(_session.db.prog("level.min", 1))
	var hi := Progression.max_level(_session.db)
	pc.progression.set_to_level(pc, clampi(pc.get_level() + delta, lo, hi), pc.essence_rng)  # 경험치도 맞춘다(다음 전투에서 레벨이 되돌아가지 않게)
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


## 무작위 정수 하나를 바로 흡수한다(못 하면 이유를 기록에).
func _give_essence() -> void:
	var ids: Array = _session.db.get_collection("essences").keys()
	if ids.is_empty():
		return
	ids.sort()
	var inst := EssenceDrop.make(_session.db, str(_session.rng.pick(ids)), "", _session.rng)
	_session.take_drop({"kind": "essence", "inst": inst}, _session.player)


## 무작위 동료 하나를 파티에 들인다(가득 차면 이유를 기록에). 실제 게임에 동료를 얻는 길이 생기기 전까지의 시험용.
func _add_companion() -> void:
	if _session.companions.size() + 1 >= int(_session.db.bal("party.max_size", 5)):
		EventBus.notice.emit("party.full", {}, "warn")
		return
	var mate := CharacterRoller.random_companion(_session.db, _session.rng, _session.player.get_level(), int(Time.get_ticks_usec() % 1000000))
	mate.display_name = Strings.t("party.mate_name", {"race": mate.race_name(), "class": mate.template_name()})
	if GameState.player == _session.player:
		GameState.add_companion(mate)  # 보통은 GameState.companions = 세션의 동료 배열(Main)
	if not _session.companions.has(mate):
		_session.companions.append(mate)


## 균열: 바깥 층이면 종류를 골라 강제 개방(옆에 포탈), 균열 안이면 이 챕터 조우 치우기.
func _add_rift_row(v: VBoxContainer) -> void:
	if _session.rift_run != null:
		_btn(v, Strings.t("debug.rift_clear_chapter"), func() -> void: _session.rift_run.debug_clear())
		return
	var row := HBoxContainer.new()
	v.add_child(row)
	_rift_pick = OptionButton.new()
	for id in RiftWatch.rifts_for(_session):
		_rift_pick.add_item(DataNames.entry(_session.db, "rifts", id))
		_rift_pick.set_item_metadata(_rift_pick.item_count - 1, id)
	row.add_child(_rift_pick)
	_btn(row, Strings.t("debug.rift_force_open"), func() -> void:
		if _rift_pick.item_count > 0:
			_session.rifts.force_open(_session, str(_rift_pick.get_item_metadata(_rift_pick.selected)), _session.pos))
	_btn(v, Strings.t("debug.give_rift_stones"), func() -> void:  # 기념비 마석 바치기 조건(Monument)
		var off := Monument.offering(_session)
		_session.player.inventory.add(JsonUtil.get_str(off, "item"), JsonUtil.get_int(off, "count", 1))
		for m: Variant in JsonUtil.get_array(off, "kills"):
			_session.kills[str(m)] = 1)
	_btn(v, Strings.t("debug.lord_ready"), func() -> void:  # 기념비 계층군주 부르기 조건(그 층 균열 수호자 모두)
		for id in RiftWatch.rifts_for(_session):
			_session.player.progression.record_kill(_session.db, JsonUtil.get_str(_session.db.get_entry("rifts", id), "guardian")))
