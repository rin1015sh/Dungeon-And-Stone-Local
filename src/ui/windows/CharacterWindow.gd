class_name CharacterWindow
extends GothicWindow
## 캐릭터 창(2단): 왼쪽 = 이름·종족·템플릿 · 레벨과 공적 · 자원 · 핵심 스탯과 장비 보정,
## 오른쪽 탭 = 정수(흡수 대기가 맨 위 — EssencePanel) · 세부 능력(0이 아닌 세부 스탯과 보정 · 영구 강화 · 패시브 · 걸린 상태).
## 탭 내용은 높이를 고정하고 스크롤한다(창이 화면 밖으로 늘어나지 않게).

var pc: PlayerCharacter

var _left: VBoxContainer
var _tabs: TabContainer
var _now: Callable = Callable()  # 지금 게임 시각(정수 흡수 대기 남은 시간 표시용) — 없으면 숨김


func _init() -> void:
	super(Strings.t("character.title"))


func setup(p_pc: PlayerCharacter, now_hours: Callable = Callable()) -> void:
	pc = p_pc
	_now = now_hours
	custom_minimum_size.x = UiTheme.metric("char_window_width", 780)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTheme.metric("spacing", 8) * 2)
	content.add_child(row)
	_left = VBoxContainer.new()
	_left.custom_minimum_size.x = UiTheme.metric("char_left_width", 360)
	row.add_child(_left)
	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.custom_minimum_size.y = UiTheme.metric("char_tab_height", 440)
	row.add_child(_tabs)
	pc.equipment.changed.connect(func(_s: String) -> void: refresh())
	refresh()


func refresh() -> void:
	for c in _left.get_children():
		c.queue_free()
	var keep := _tabs.current_tab
	for c in _tabs.get_children():
		_tabs.remove_child(c)
		c.queue_free()
	_build_summary()
	var essences := EssencePanel.new()
	essences.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	essences.setup(pc, float(_now.call()) if _now.is_valid() else -1.0)
	essences.changed.connect(refresh)
	_add_tab(Strings.t("character.tab_essence"), essences)
	_add_tab(Strings.t("character.tab_details"), _details())
	_tabs.current_tab = clampi(keep, 0, _tabs.get_tab_count() - 1)


func _build_summary() -> void:
	var db := pc.db
	_left.add_child(UiTheme.label(Strings.t("character.name_line", {"name": pc.display_name, "race": pc.race_name(),
		"template": pc.template_name()}), "header", "text_title"))
	var lv := pc.get_level()
	var next := Progression.exp_for_next(db, lv)
	_left.add_child(UiTheme.label(Strings.t("character.level_line", {"level": lv, "exp": pc.progression.exp_total,
		"next": next if next >= 0 else Strings.t("character.max")}), "body", "gold"))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = UiTheme.metric("bar_height", 14)
	var prev := Progression.exp_for_level(db, lv)
	bar.max_value = maxf(1.0, float(next - prev)) if next >= 0 else 1.0
	bar.value = float(pc.progression.exp_total - prev) if next >= 0 else 1.0
	bar.add_theme_stylebox_override("fill", UiTheme.box(UiTheme.color("gold"), Color.TRANSPARENT, 2, 0))
	_left.add_child(bar)
	var res := ResourcePanel.new()
	_left.add_child(res)
	res.bind(pc.pool)
	_left.add_child(HSeparator.new())
	var grid := GridContainer.new()
	grid.columns = 4
	_left.add_child(grid)
	for id in pc.stats.ids("core"):
		_stat(grid, DataNames.entry(db, "stats", id), pc.stats.get_value(id), pc.stats.get_value(id) - pc.stats.get_base(id))
	_stat(grid, Strings.t("character.attack"), DamageCalc.attack_power(db, pc, {"scaling": "phys"}), 0.0)
	_stat(grid, Strings.t("character.crit"), DamageCalc.crit_chance(db, pc) * 100.0, 0.0, "%")
	_left.add_child(UiTheme.label(Strings.t("character.attack_type", {"type": DataNames.tag(db, "damage_types", pc.attack_damage_type())}), "small", "text_dim"))


## 세부 능력 탭: 0이 아니거나 보정이 붙은 세부 스탯 · 영구 강화(boons) · 패시브 · 걸린 상태.
func _details() -> Control:
	var db := pc.db
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = 4
	var shown := 0
	for id in pc.stats.ids("sub"):
		var def := pc.stats.get_def(id)
		var v := pc.stats.get_value(id)
		var bonus := v - pc.stats.get_base(id)
		if (def != null and not def.visible) or (is_zero_approx(v) and is_zero_approx(bonus)):
			continue
		var name := DataNames.entry(db, "stats", id) + ("" if def == null or def.implemented else Strings.t("character.inert_mark"))
		_stat(grid, name, v, bonus)
		shown += 1
	box.add_child(UiTheme.label(Strings.t("character.sub_stats"), "body", "text_title"))
	box.add_child(grid if shown > 0 else UiTheme.label(Strings.t("character.none"), "small", "text_dim"))
	var inert := UiTheme.label(Strings.t("character.inert_note"), "small", "text_dim")
	inert.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(inert)
	if not pc.boons.is_empty():
		box.add_child(UiTheme.label(Strings.t("character.boons"), "body", "text_title"))
		for k: String in pc.boons:  # 키 = "<아이템 key>@<스탯>"
			var parts := k.split("@")
			box.add_child(UiTheme.label(Strings.t("character.boon_line", {"item": DataNames.entry(db, "items", parts[0]),
				"stat": DataNames.entry(db, "stats", parts[1] if parts.size() > 1 else ""), "n": int(pc.boons[k])}), "small", "text"))
	box.add_child(UiTheme.label(Strings.t("character.passives"), "body", "text_title"))
	if pc.passives.is_empty():
		box.add_child(UiTheme.label(Strings.t("character.none"), "small", "text_dim"))
	for p: Dictionary in pc.passives:
		var l := UiTheme.label(Strings.t("character.passive_line", {"name": JsonUtil.get_str(p, "name_ko", JsonUtil.get_str(p, "id")),
			"desc": JsonUtil.get_str(p, "desc_ko")}), "small", "text")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	box.add_child(UiTheme.label(Strings.t("character.statuses"), "body", "text_title"))
	var st := PackedStringArray()
	for sid in pc.statuses.ids():
		st.append(DataNames.entry(db, "statuses", sid))
	var sl := UiTheme.label(", ".join(st) if not st.is_empty() else Strings.t("character.none"), "small", "text" if not st.is_empty() else "text_dim")
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sl)
	return box


func _add_tab(title: String, body: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_child(body)
	_tabs.add_child(scroll)


func _stat(grid: GridContainer, label: String, value: float, bonus: float, suffix: String = "") -> void:
	grid.add_child(UiTheme.label(label, "small", "text_dim"))
	var text := UiTheme.num(snappedf(value, 0.1)) + suffix
	if not is_zero_approx(bonus):
		text += " (%+d)" % roundi(bonus)
	grid.add_child(UiTheme.label(text, "body", "stat_pos" if bonus > 0.0 else ("stat_neg" if bonus < 0.0 else "text")))
