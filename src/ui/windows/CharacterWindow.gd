class_name CharacterWindow
extends GothicWindow
## 캐릭터 창: 이름·종족·템플릿 · 레벨과 공적(경험치) · 자원 · 핵심 스탯과 장비 보정 · 정수 슬롯(정수 설정 보류).

var pc: PlayerCharacter

var _body: VBoxContainer


func _init() -> void:
	super(Strings.t("character.title"))


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	custom_minimum_size.x = UiTheme.metric("char_window_width", 420)
	_body = VBoxContainer.new()
	content.add_child(_body)
	pc.equipment.changed.connect(func(_s: String) -> void: refresh())
	refresh()


func refresh() -> void:
	for c in _body.get_children():
		c.queue_free()
	var db := pc.db
	_body.add_child(UiTheme.label(Strings.t("character.name_line", {"name": pc.display_name, "race": pc.race_name(),
		"template": pc.template_name()}), "header", "text_title"))
	var lv := pc.get_level()
	var next := Progression.exp_for_next(db, lv)
	_body.add_child(UiTheme.label(Strings.t("character.level_line", {"level": lv, "exp": pc.progression.exp_total,
		"next": next if next >= 0 else Strings.t("character.max")}), "body", "gold"))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = UiTheme.metric("bar_height", 14)
	var prev := int((db.bal("level.exp_table", [0]) as Array)[lv - 1])
	bar.max_value = maxf(1.0, float(next - prev)) if next >= 0 else 1.0
	bar.value = float(pc.progression.exp_total - prev) if next >= 0 else 1.0
	bar.add_theme_stylebox_override("fill", UiTheme.box(UiTheme.color("gold"), Color.TRANSPARENT, 2, 0))
	_body.add_child(bar)
	var res := ResourcePanel.new()
	_body.add_child(res)
	res.bind(pc.pool)
	_body.add_child(HSeparator.new())
	var grid := GridContainer.new()
	grid.columns = 4
	_body.add_child(grid)
	for id in pc.stats.ids("core"):
		_stat(grid, DataNames.entry(db, "stats", id), pc.stats.get_value(id), pc.stats.get_value(id) - pc.stats.get_base(id))
	_stat(grid, Strings.t("character.attack"), DamageCalc.attack_power(db, pc, {"scaling": "phys"}), 0.0)
	_stat(grid, Strings.t("character.crit"), DamageCalc.crit_chance(db, pc) * 100.0, 0.0, "%")
	_body.add_child(UiTheme.label(Strings.t("character.attack_type", {"type": DataNames.tag(db, "damage_types", pc.attack_damage_type())}), "small", "text_dim"))
	_body.add_child(HSeparator.new())
	var slots := Progression.essence_slots(db, lv)
	_body.add_child(UiTheme.label(Strings.t("character.essence_slots", {"n": slots}), "body", "text_title"))
	var row := HFlowContainer.new()
	_body.add_child(row)
	for i in slots:
		var s := Panel.new()
		s.custom_minimum_size = Vector2.ONE * UiTheme.metric("hotbar_slot", 46)
		s.add_theme_stylebox_override("panel", GothicStyle.slot_box())
		s.tooltip_text = Strings.t("character.essence_empty")
		row.add_child(s)
	var note := UiTheme.label(Strings.t("character.essence_note"), "small", "text_dim")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(note)


func _stat(grid: GridContainer, label: String, value: float, bonus: float, suffix: String = "") -> void:
	grid.add_child(UiTheme.label(label, "small", "text_dim"))
	var text := UiTheme.num(snappedf(value, 0.1)) + suffix
	if not is_zero_approx(bonus):
		text += " (%+d)" % roundi(bonus)
	grid.add_child(UiTheme.label(text, "body", "stat_pos" if bonus > 0.0 else ("stat_neg" if bonus < 0.0 else "text")))
