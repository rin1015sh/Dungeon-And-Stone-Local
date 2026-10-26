class_name CharacterPage
extends MenuPage
## Tab 메뉴의 캐릭터 쪽: 이름·종족·템플릿 · 레벨과 공적 · 자원 · 핵심 스탯과 장비 보정 · 정수(슬롯 + 목록) ·
## 세부 능력(0이 아닌 세부 스탯과 보정 · 영구 강화 · 패시브 · 걸린 상태). 내용은 높이를 고정하고 W/S로 스크롤한다.

var pc: PlayerCharacter

var _scroll: ScrollContainer
var _box: VBoxContainer


func _init() -> void:
	super(Strings.t("character.title"))


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	custom_minimum_size.x = MenuPage.cfg("character_width", 400.0)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_scroll)
	var pad := MarginContainer.new()  # 세로 스크롤 막대가 줄 끝(접힌 글)을 덮지 않게
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", int(MenuPage.cfg("scroll_gap", 14.0)))
	_scroll.add_child(pad)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(_box)
	pc.equipment.changed.connect(_on_worn_changed)
	refresh()


## 보일 아군을 바꾼다(Tab 메뉴 왼쪽 쪽에서 고름).
func set_actor(a: PlayerCharacter) -> void:
	if a == pc:
		return
	if pc.equipment.changed.is_connected(_on_worn_changed):
		pc.equipment.changed.disconnect(_on_worn_changed)
	pc = a
	pc.equipment.changed.connect(_on_worn_changed)
	refresh()
	_scroll.scroll_vertical = 0


func _on_worn_changed(_slot: String) -> void:
	refresh()


func refresh() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_build_summary()
	_box.add_child(HSeparator.new())
	var essences := EssencePanel.new()
	essences.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	essences.setup(pc)
	_box.add_child(essences)
	_box.add_child(HSeparator.new())
	_box.add_child(_build_details())


func enter(_from_left: bool) -> void:
	_scroll.scroll_vertical = 0


## W/S = 한 걸음씩 스크롤(고를 것은 없다).
func nav(d: Vector2i) -> bool:
	if d.x != 0:
		return false
	_scroll.scroll_vertical += d.y * int(MenuPage.cfg("scroll_step", 60.0))
	return true


func _build_summary() -> void:
	var db := pc.db
	_box.add_child(UiTheme.label(Strings.t("character.name_line", {"name": pc.display_name, "race": pc.race_name(),
		"template": pc.template_name()}), "header", "text_title"))
	var lv := pc.get_level()
	var next := Progression.exp_for_next(db, lv)
	_box.add_child(UiTheme.label(Strings.t("character.level_line", {"level": lv, "exp": pc.progression.exp_total,
		"next": next if next >= 0 else Strings.t("character.max")}), "body", "gold"))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = UiTheme.metric("bar_height", 14)
	var prev := Progression.exp_for_level(db, lv)
	bar.max_value = maxf(1.0, float(next - prev)) if next >= 0 else 1.0
	bar.value = float(pc.progression.exp_total - prev) if next >= 0 else 1.0
	bar.add_theme_stylebox_override("fill", UiTheme.box(UiTheme.color("gold"), Color.TRANSPARENT, 2, 0))
	_box.add_child(bar)
	var res := ResourcePanel.new()
	_box.add_child(res)
	res.bind(pc.pool)
	var grid := GridContainer.new()
	grid.columns = 4
	_box.add_child(grid)
	for id in pc.stats.ids("core"):
		_stat(grid, DataNames.entry(db, "stats", id), pc.stats.get_value(id), pc.stats.get_value(id) - pc.stats.get_base(id))
	_stat(grid, Strings.t("character.attack"), DamageCalc.attack_power(db, pc, {"scaling": "phys"}), 0.0)
	_stat(grid, Strings.t("character.crit"), DamageCalc.crit_chance(db, pc) * 100.0, 0.0, "%")
	_box.add_child(UiTheme.label(Strings.t("character.attack_type", {"type": DataNames.tag(db, "damage_types", pc.attack_damage_type())}), "small", "text_dim"))
	var known := PackedStringArray()
	for t in pc.masteries:  # 무기 숙련(IT9)
		known.append(Strings.t("character.mastery", {"name": DataNames.entry(db, "item_types", t)}))
	if not known.is_empty():
		_box.add_child(UiTheme.label(" · ".join(known), "small", "gold"))


## 세부 능력: 0이 아니거나 보정이 붙은 세부 스탯 · 영구 강화(boons) · 패시브 · 걸린 상태.
func _build_details() -> Control:
	var db := pc.db
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(UiTheme.label(Strings.t("character.sub_stats"), "body", "text_title"))
	var grid := GridContainer.new()
	grid.columns = 4
	var shown := 0
	for id in pc.stats.ids("sub"):
		var def := pc.stats.get_def(id)
		var v := pc.stats.get_value(id)
		var bonus := v - pc.stats.get_base(id)
		if (def != null and not def.visible) or (is_zero_approx(v) and is_zero_approx(bonus)):
			continue
		var inert := def != null and not def.implemented
		_stat(grid, DataNames.entry(db, "stats", id) + (Strings.t("character.inert_mark") if inert else ""), v, bonus)
		shown += 1
	if shown > 0:
		box.add_child(grid)
	else:
		grid.free()  # 트리에 붙지 않은 노드는 저절로 지워지지 않는다(종료 시 누수 경고였다)
		box.add_child(UiTheme.label(Strings.t("character.none"), "small", "text_dim"))
	if not pc.boons.is_empty():
		box.add_child(UiTheme.label(Strings.t("character.boons"), "body", "text_title"))
		for k: String in pc.boons:  # 키 = "<아이템 key>@<스탯>"
			var parts := k.split("@")
			box.add_child(UiTheme.label(Strings.t("character.boon_line", {"item": DataNames.entry(db, "items", parts[0]),
				"stat": DataNames.entry(db, "stats", parts[1] if parts.size() > 1 else ""), "n": int(pc.boons[k])}), "small", "text"))
	var from_essence := {}  # 정수 패시브는 위 정수 카드에 있다 — 여기선 그 밖의 것만(두 번 보이지 않게, UI26)
	for e: Dictionary in pc.essences.absorbed:
		from_essence[JsonUtil.get_str(JsonUtil.get_dict(db.get_entry("essences", JsonUtil.get_str(e, "essence")), "passive"), "id")] = true
	var others := pc.passives.filter(func(p: Dictionary) -> bool: return not from_essence.has(JsonUtil.get_str(p, "id")))
	if not others.is_empty():
		box.add_child(UiTheme.label(Strings.t("character.passives"), "body", "text_title"))
	for p: Dictionary in others:
		var l := UiTheme.label(Strings.t("character.passive_line", {"name": JsonUtil.get_str(p, "name_ko", JsonUtil.get_str(p, "id")),
			"desc": JsonUtil.get_str(p, "desc_ko")}), "small", "text")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	box.add_child(UiTheme.label(Strings.t("character.statuses"), "body", "text_title"))
	var st := PackedStringArray()
	var meal := Meals.current(pc)
	for sid in pc.statuses.ids():
		if sid != meal:
			st.append(DataNames.entry(db, "statuses", sid))
	if not meal.is_empty():  # 여관 식사는 따로 한 줄 — 효과 수치·남은 지속까지(BuffText)
		var ml := UiTheme.label(BuffText.line(pc, meal), "small", "text")
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(ml)
	if not st.is_empty() or meal.is_empty():
		var sl := UiTheme.label(", ".join(st) if not st.is_empty() else Strings.t("character.none"), "small", "text" if not st.is_empty() else "text_dim")
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(sl)
	return box


func _stat(grid: GridContainer, label: String, value: float, bonus: float, suffix: String = "") -> void:
	grid.add_child(UiTheme.label(label, "small", "text_dim"))
	var text := UiTheme.num(snappedf(value, 0.1)) + suffix
	if not is_zero_approx(bonus):
		text += " (%+d)" % roundi(bonus)
	grid.add_child(UiTheme.label(text, "body", "stat_pos" if bonus > 0.0 else ("stat_neg" if bonus < 0.0 else "text")))
