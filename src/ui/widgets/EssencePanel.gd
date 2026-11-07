class_name EssencePanel
extends VBoxContainer
## 캐릭터 쪽의 정수 칸: 슬롯(흡수한 정수는 차분한 정수 색)과 흡수한 정수마다 카드(이름 · 등급 · 패시브 · 이능(한 줄씩, 위력) · 능력치,
## UI26). 색은 창 돌판 색에 정수 색을 조금만 섞는다(사용자 2026-10-27 "너무 쨍하다", UI34).
## 순서 바꾸기(UI34): cursor = 커서가 놓인 카드(-1 = 없음), grabbed = 집어 든 카드(옮기는 중) — CharacterPage가 키로 움직인다.
## 흡수는 전투 장면에서 떨어졌을 때만(CombatDrops), 삭제는 도시 시설(대신전).

var pc: PlayerCharacter
var cursor: int = -1
var grabbed: bool = false
var _cards: Array[PanelContainer] = []


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	_build()


func card(i: int) -> Control:
	return _cards[i] if i >= 0 and i < _cards.size() else null


func count() -> int:
	return _cards.size()


## 정수를 옮겼다 — 다시 만든다(커서·집음은 그대로).
func rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_cards.clear()
	_build()


## 커서·집음 표시만 다시 칠한다.
func paint() -> void:
	for i in _cards.size():
		_cards[i].add_theme_stylebox_override("panel", _card_box(pc.db, pc.essences.absorbed[i], i))


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
			b.bg_color = calm(color_of(db, JsonUtil.get_str(es.absorbed[i], "color")), 0.34)
			if EssenceSet.is_locked(es.absorbed[i]):
				b.bg_color = b.bg_color.darkened(UiTheme.metric("essence_locked_darken", 70) / 100.0)
			s.add_theme_stylebox_override("panel", b)
		else:
			s.add_theme_stylebox_override("panel", GothicStyle.slot_box())
		row.add_child(s)
	for i in es.absorbed.size():
		var c := _card(db, es.absorbed[i], i)
		_cards.append(c)
		add_child(c)


## 정수 하나의 카드: 돌판 바탕에 정수 색을 조금 · 차분한 정수 색 테두리 + 정수 색 구슬 · 이름 · 등급 + 칸 이름(어두운 글)과 내용.
func _card(db: GameDatabase, inst: Dictionary, i: int) -> PanelContainer:
	var col := color_of(db, JsonUtil.get_str(inst, "color"))
	var locked := EssenceSet.is_locked(inst)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_box(db, inst, i))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	card.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	v.add_child(head)
	var gem := Panel.new()  # 정수 색 구슬
	var gs := UiTheme.metric("essence_gem", 10)
	gem.custom_minimum_size = Vector2.ONE * gs
	gem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var gb := UiTheme.box(calm(col, 0.55).darkened(0.4 if locked else 0.0), calm(col, 0.3), gs / 2, 0)
	gem.add_theme_stylebox_override("panel", gb)
	head.add_child(gem)
	var title := UiTheme.label(title_of(db, inst), "body", "text_title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", UiTheme.color("text_title").lerp(col, 0.22) if not locked else UiTheme.color("text_dim"))
	head.add_child(title)
	var def := db.get_entry("essences", JsonUtil.get_str(inst, "essence"))
	head.add_child(UiTheme.label(Strings.t("essence.grade", {"n": JsonUtil.get_int(def, "grade")}), "small", "text_dim"))
	var p := JsonUtil.get_dict(def, "passive")
	if not p.is_empty():
		var pdesc := JsonUtil.get_str(p, "desc_ko")
		var react := EssenceLinks.passive_brief(db, p)  # 반응 효과(기절 대상 ×1.25 …) — 설명 글이 없어도 수치로 보인다
		if not react.is_empty():
			pdesc = (pdesc + " " if not pdesc.is_empty() else "") + ", ".join(react)
		_row(v, Strings.t("essence.row_passive"), JsonUtil.get_str(p, "name_ko"), pdesc
			+ ("" if JsonUtil.get_bool(p, "implemented", true) else " " + Strings.t("essence.not_implemented")))
	for sid: String in EssenceSet.granted_skills(db, inst):
		var sk := db.get_entry("skills", sid)
		var brief := SkillBrief.describe(db, sk)  # 마지막 줄 = 대상 · 피해 위력 · 상태 확률(desc_ko 줄은 빼고)
		_row(v, Strings.t("essence.row_skill"), DataNames.entry(db, "skills", sid), brief.get_slice("\n", brief.count("\n")))
	var stats := _stat_list(db, inst)
	if not stats.is_empty():
		_row(v, Strings.t("essence.row_stats"), ", ".join(stats), "")
	if not locked:  # 연계(정수 시너지 ES4): 이 정수와 다른 정수가 상태로 이어지는 곳
		var ls := link_texts(db, inst, pc.essences.absorbed)
		if not ls.is_empty():
			_row(v, Strings.t("essence.row_link"), ", ".join(ls), "")
	return card


## 연계 한 줄씩("출혈: 물어뜯기 → 피 냄새"). held = 가진 정수(잠긴 것은 EssenceLinks가 뺀다).
static func link_texts(db: GameDatabase, inst: Dictionary, held: Array[Dictionary]) -> PackedStringArray:
	var out := PackedStringArray()
	for l: Dictionary in EssenceLinks.links(db, inst, held):
		var st := str(l["status"])
		out.append(Strings.t("essence.link", {"status": Strings.t("essence.link_ranged") if st == EssenceLinks.RANGED else DataNames.entry(db, "statuses", st),
			"from": str(l["from"]).trim_suffix(Strings.t("essence.skill_suffix")), "to": str(l["to"]).trim_suffix(Strings.t("essence.skill_suffix"))}))
	return out


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


## 카드 판: 커서 = 뼈빛 테두리, 집어 들었으면 더 굵은 뼈빛 + 조금 밝은 바탕, 그 밖은 차분한 정수 색 테두리.
func _card_box(db: GameDatabase, inst: Dictionary, i: int) -> StyleBoxFlat:
	var col := color_of(db, JsonUtil.get_str(inst, "color"))
	var locked := EssenceSet.is_locked(inst)
	var bg := UiTheme.color("frame").lerp(col, 0.08 if not locked else 0.03)
	var edge := calm(col, 0.3).darkened(0.0 if not locked else 0.45)
	var w := 1
	if i == cursor:
		edge = UiTheme.color("select")
		w = 2
		if grabbed:
			bg = bg.lightened(0.08)
			w = 3
	var b := UiTheme.box(bg, edge, 2, UiTheme.metric("essence_card_pad", 8))
	b.set_border_width_all(w)
	return b


## 정수 색을 창 테두리 색 쪽으로 눌러 채도를 뺀다(k = 섞는 양 0~1).
static func muted(col: Color, k: float) -> Color:
	var g := col.get_luminance()
	return col.lerp(Color(g, g, g), k * 0.6).lerp(UiTheme.color("frame_edge"), k * 0.5)


## 차분한 칸 색: 채도를 빼고 밝기를 lum_max 아래로(하얀·무지갯빛 정수가 흰 칸으로 튀지 않게).
static func calm(col: Color, lum_max: float) -> Color:
	var c := muted(col, 0.6)
	var l := c.get_luminance()
	return c.darkened(1.0 - lum_max / l) if l > lum_max else c


static func color_of(db: GameDatabase, color_id: String) -> Color:
	for t: Variant in JsonUtil.get_array(db.tags, "essence_colors"):
		if t is Dictionary and JsonUtil.get_str(t, "id") == color_id:
			return Color.html(JsonUtil.get_str(t, "color", "#888888"))
	return Color.html("#888888")
