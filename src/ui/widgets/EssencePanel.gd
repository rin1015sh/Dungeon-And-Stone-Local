class_name EssencePanel
extends VBoxContainer
## 캐릭터 쪽의 정수 칸: 슬롯(흡수한 정수는 색으로 칠함)과 흡수한 정수 목록(이름 · 패시브 · 이능 · 능력치) — 보여 주기만.
## 흡수는 전투 장면에서 떨어졌을 때만(CombatDrops), 삭제는 도시 시설(대신전).

var pc: PlayerCharacter


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	_build()


func _build() -> void:
	var db := pc.db
	var es := pc.essences
	var slots := Progression.essence_slots(db, pc.get_level())
	add_child(UiTheme.label(Strings.t("essence.slots", {"used": es.absorbed.size() - es.locked_count(), "n": slots}), "body", "text_title"))
	var row := HFlowContainer.new()
	add_child(row)
	for i in maxi(slots, es.absorbed.size()):
		var s := Panel.new()
		s.custom_minimum_size = Vector2.ONE * UiTheme.metric("essence_slot", 46)
		if i < es.absorbed.size():
			var b := GothicStyle.slot_box()
			b.bg_color = color_of(db, JsonUtil.get_str(es.absorbed[i], "color"))
			if EssenceSet.is_locked(es.absorbed[i]):
				b.bg_color = b.bg_color.darkened(UiTheme.metric("essence_locked_darken", 70) / 100.0)
			s.add_theme_stylebox_override("panel", b)
		else:
			s.add_theme_stylebox_override("panel", GothicStyle.slot_box())
		row.add_child(s)
	for e: Dictionary in es.absorbed:
		var lines := describe(db, e).split("\n")
		add_child(UiTheme.label(lines[0], "body", "text_title"))
		var l := UiTheme.label("\n".join(lines.slice(1)), "small", "text")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(l)


## "붉은 고블린의 정수" 꼴(잠겼으면 뒤에 표시).
static func title_of(db: GameDatabase, inst: Dictionary) -> String:
	var t := Strings.t("essence.title", {"color": DataNames.tag(db, "essence_colors", JsonUtil.get_str(inst, "color")),
		"name": DataNames.entry(db, "essences", JsonUtil.get_str(inst, "essence"))})
	return t + Strings.t("essence.locked_suffix") if EssenceSet.is_locked(inst) else t


## 설명: 이름 · 패시브 · 액티브 · 스탯(한 줄씩).
static func describe(db: GameDatabase, inst: Dictionary) -> String:
	var def := db.get_entry("essences", JsonUtil.get_str(inst, "essence"))
	var lines := PackedStringArray([title_of(db, inst)])
	var p := JsonUtil.get_dict(def, "passive")
	if not p.is_empty():
		lines.append(Strings.t("essence.tip_passive", {"name": JsonUtil.get_str(p, "name_ko"), "desc": JsonUtil.get_str(p, "desc_ko")}))
		if not JsonUtil.get_bool(p, "implemented", true):
			lines.append(Strings.t("essence.not_implemented"))
	var skills := PackedStringArray()
	for sid: String in EssenceSet.granted_skills(db, inst):
		skills.append(DataNames.entry(db, "skills", sid))
	lines.append(Strings.t("essence.tip_skills", {"list": ", ".join(skills)}))
	var stats := PackedStringArray()
	var st := JsonUtil.get_dict(inst, "stats")
	for k: String in st:
		var sd: StatDef = db.stats.get(k)
		stats.append("%s +%d" % [DataNames.entry(db, "stats", k), int(st[k])] \
			+ ("" if sd == null or sd.implemented else Strings.t("essence.stat_inert")))
	lines.append(Strings.t("essence.tip_stats", {"list": ", ".join(stats)}))
	return "\n".join(lines)


static func color_of(db: GameDatabase, color_id: String) -> Color:
	for t: Variant in JsonUtil.get_array(db.tags, "essence_colors"):
		if t is Dictionary and JsonUtil.get_str(t, "id") == color_id:
			return Color.html(JsonUtil.get_str(t, "color", "#888888"))
	return Color.html("#888888")
