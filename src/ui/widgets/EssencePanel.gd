class_name EssencePanel
extends VBoxContainer
## 캐릭터 창의 정수 칸: 흡수 대기 목록(맨 위 — 흡수 버튼·남은 시간) + 슬롯(흡수한 정수는 색으로 칠함, 마우스를 올리면 내용).
## 삭제(대신전)는 도시 시설에서 붙인다 — 여기서는 보여 주기와 흡수만.

signal changed

var pc: PlayerCharacter
var _now: float = -1.0  # 지금 게임 시각(음수면 남은 시간을 보이지 않는다)


func setup(p_pc: PlayerCharacter, now_hours: float = -1.0) -> void:
	pc = p_pc
	_now = now_hours
	_build()


func _build() -> void:
	var db := pc.db
	var es := pc.essences
	_build_pending()
	var slots := Progression.essence_slots(db, pc.get_level())
	add_child(UiTheme.label(Strings.t("essence.slots", {"used": es.absorbed.size() - es.locked_count(), "n": slots}), "body", "text_title"))
	var row := HFlowContainer.new()
	add_child(row)
	for i in maxi(slots, es.absorbed.size()):
		var s := Panel.new()
		s.custom_minimum_size = Vector2.ONE * UiTheme.metric("hotbar_slot", 46)
		if i < es.absorbed.size():
			var b := GothicStyle.slot_box()
			b.bg_color = color_of(db, JsonUtil.get_str(es.absorbed[i], "color"))
			if EssenceSet.is_locked(es.absorbed[i]):
				b.bg_color = b.bg_color.darkened(UiTheme.metric("essence_locked_darken", 70) / 100.0)
			s.add_theme_stylebox_override("panel", b)
			s.tooltip_text = describe(db, es.absorbed[i])
		else:
			s.add_theme_stylebox_override("panel", GothicStyle.slot_box())
			s.tooltip_text = Strings.t("character.essence_empty")
		row.add_child(s)
	for e: Dictionary in es.absorbed:
		var l := UiTheme.label(title_of(db, e), "small", "text")
		l.tooltip_text = describe(db, e)
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(l)


## 흡수 대기: 이름(마우스 = 내용) · 남은 시간 · [흡수](못 하면 이유를 곁에 적는다).
func _build_pending() -> void:
	var db := pc.db
	var es := pc.essences
	if es.pending.is_empty():
		return
	add_child(UiTheme.label(Strings.t("essence.pending_title"), "body", "gold"))
	for i in es.pending.size():
		var line := HBoxContainer.new()
		add_child(line)
		var l := UiTheme.label(title_of(db, es.pending[i]), "small", "text")
		l.tooltip_text = describe(db, es.pending[i])
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(l)
		if _now >= 0.0 and es.pending[i].has("expires_at"):
			line.add_child(UiTheme.label(Strings.t("essence.pending_left", {"hours": UiTheme.num(snappedf(
				maxf(0.0, float(es.pending[i]["expires_at"]) - _now), 0.1))}), "small", "warn"))
		var why := es.check_absorb(pc, es.pending[i])
		var btn := UiTheme.button(Strings.t("essence.absorb"), _absorb.bind(i))
		btn.disabled = not why.is_empty()
		btn.tooltip_text = Strings.t(why) if not why.is_empty() else ""
		line.add_child(btn)
		if not why.is_empty():
			var r := UiTheme.label(Strings.t(why), "small", "text_dim")
			r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(r)
	add_child(HSeparator.new())


func _absorb(i: int) -> void:
	pc.essences.absorb_pending(pc, i)
	changed.emit()


## "붉은 고블린의 정수" 꼴(잠겼으면 뒤에 표시).
static func title_of(db: GameDatabase, inst: Dictionary) -> String:
	var t := Strings.t("essence.title", {"color": DataNames.tag(db, "essence_colors", JsonUtil.get_str(inst, "color")),
		"name": DataNames.entry(db, "essences", JsonUtil.get_str(inst, "essence"))})
	return t + Strings.t("essence.locked_suffix") if EssenceSet.is_locked(inst) else t


## 마우스 설명: 이름 · 패시브 · 액티브 · 스탯.
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
