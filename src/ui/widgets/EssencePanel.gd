class_name EssencePanel
extends VBoxContainer
## 캐릭터 쪽의 정수 칸: 슬롯(흡수한 정수는 색으로 칠함)과 흡수한 정수마다 카드(정수 색 테두리 — 이름 · 패시브 · 이능(한 줄씩, 위력) · 능력치,
## UI26 "정수 정보 가시성이 떨어진다") — 보여 주기만.
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
		add_child(_card(db, e))


## 정수 하나의 카드: 정수 색 테두리·옅은 바탕 + 이름 + 칸 이름(어두운 글)과 내용.
func _card(db: GameDatabase, inst: Dictionary) -> Control:
	var col := color_of(db, JsonUtil.get_str(inst, "color"))
	var locked := EssenceSet.is_locked(inst)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(Color(col.darkened(0.7), 0.55), col.darkened(0.6 if locked else 0.1), 2,
		UiTheme.metric("essence_card_pad", 8)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	card.add_child(v)
	var title := UiTheme.label(title_of(db, inst), "body", "text_title")
	title.add_theme_color_override("font_color", col.lightened(0.35) if not locked else UiTheme.color("text_dim"))
	v.add_child(title)
	var def := db.get_entry("essences", JsonUtil.get_str(inst, "essence"))
	var p := JsonUtil.get_dict(def, "passive")
	if not p.is_empty():
		_row(v, Strings.t("essence.row_passive"), JsonUtil.get_str(p, "name_ko"), JsonUtil.get_str(p, "desc_ko")
			+ ("" if JsonUtil.get_bool(p, "implemented", true) else " " + Strings.t("essence.not_implemented")))
	for sid: String in EssenceSet.granted_skills(db, inst):
		var sk := db.get_entry("skills", sid)
		var brief := SkillBrief.describe(db, sk)  # 마지막 줄 = 대상 · 피해 위력 · 상태 확률(desc_ko 줄은 빼고)
		_row(v, Strings.t("essence.row_skill"), DataNames.entry(db, "skills", sid), brief.get_slice("\n", brief.count("\n")))
	var stats := _stat_list(db, inst)
	if not stats.is_empty():
		_row(v, Strings.t("essence.row_stats"), ", ".join(stats), "")
	return card


## 한 줄: 왼쪽 칸 이름(어둡게, 폭 고정) · 이름(밝게) · 아래 작은 설명.
func _row(parent: Control, head: String, name: String, desc: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	parent.add_child(h)
	var hl := UiTheme.label(head, "small", "text_dim")
	hl.custom_minimum_size.x = UiTheme.metric("essence_row_head", 44)
	h.add_child(hl)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nl := UiTheme.label(name, "small", "text")
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nl)
	if not desc.is_empty():
		var dl := UiTheme.label(desc, "small", "text_dim")
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(dl)


static func _stat_list(db: GameDatabase, inst: Dictionary) -> PackedStringArray:
	var stats := PackedStringArray()
	var st := JsonUtil.get_dict(inst, "stats")
	for k: String in st:
		var sd: StatDef = db.stats.get(k)
		stats.append("%s +%d" % [DataNames.entry(db, "stats", k), int(st[k])] \
			+ ("" if sd == null or sd.implemented else Strings.t("essence.stat_inert")))
	var res := JsonUtil.get_dict(inst, "resources")
	for r: String in res:
		var rd: ResourceDef = db.resources.get(r)
		stats.append("%s +%d" % [rd.name_ko if rd != null else r, int(res[r])])
	return stats


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
	var stats := _stat_list(db, inst)
	lines.append(Strings.t("essence.tip_stats", {"list": ", ".join(stats)}))
	return "\n".join(lines)


static func color_of(db: GameDatabase, color_id: String) -> Color:
	for t: Variant in JsonUtil.get_array(db.tags, "essence_colors"):
		if t is Dictionary and JsonUtil.get_str(t, "id") == color_id:
			return Color.html(JsonUtil.get_str(t, "color", "#888888"))
	return Color.html("#888888")
