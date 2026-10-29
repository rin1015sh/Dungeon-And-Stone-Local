class_name BestiaryPage
extends MenuPage
## Tab 메뉴의 도감 쪽: 위 = 모든 몬스터(마주친 적이 없으면 ???), 아래 = 커서가 놓인 몬스터의 알아낸 정보.
## W/S = 마주친 몬스터 사이를 옮긴다(목록은 커서를 따라 스크롤).
## 처치 수 · 첫 처치 공적 · 등급·계열·설명(봤으면) · 생명력·스탯(조사했으면) · 상성(직접 겪은 것만), 나머지는 ???.

var pc: PlayerCharacter

var _list: VBoxContainer
var _list_scroll: ScrollContainer
var _detail: Label
var _ids: Array[String] = []  # 목록 순서
var _rows: Array[Label] = []
var _cursor: int = -1  # _ids 번호(마주친 몬스터만 고른다)


func _init() -> void:
	super(Strings.t("bestiary.title"))


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	custom_minimum_size.x = MenuPage.cfg("bestiary_width", 380.0)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", GothicStyle.inset_box())
	top.custom_minimum_size.y = MenuPage.cfg("bestiary_list_height", 260.0)
	content.add_child(top)
	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	top.add_child(_list_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.add_child(_list)
	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", GothicStyle.inset_box())
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom)
	_detail = UiTheme.label("", "small")
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bottom.add_child(_detail)
	refresh()


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	_ids.clear()
	var ids: Array = pc.db.get_collection("monsters").keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return JsonUtil.get_int(pc.db.get_entry("monsters", a), "grade") > JsonUtil.get_int(pc.db.get_entry("monsters", b), "grade") \
			or (JsonUtil.get_int(pc.db.get_entry("monsters", a), "grade") == JsonUtil.get_int(pc.db.get_entry("monsters", b), "grade") and a < b))
	for id: String in ids:
		var seen := pc.knowledge.has_seen(id)
		var l := UiTheme.label(Strings.t("bestiary.entry", {"name": DataNames.entry(pc.db, "monsters", id), "kills": pc.progression.kill_count(id)}) \
			if seen else Strings.t("knowledge.unknown"), "small", "text" if seen else "text_disabled")
		l.clip_text = true
		_list.add_child(l)
		_rows.append(l)
		_ids.append(id)
	_cursor = _step(-1, 1) if _cursor < 0 or not _seen(_cursor) else _cursor
	_show_cursor()


func enter(_from_left: bool) -> void:
	_show_cursor()


func on_active(_on: bool) -> void:
	if _detail != null:
		_show_cursor()


func nav(d: Vector2i) -> bool:
	if d.x != 0:
		return false
	var n := _step(_cursor, d.y)
	if n >= 0:
		_cursor = n
		_show_cursor()
	return true


func current_id() -> String:
	return _ids[_cursor] if _cursor >= 0 and _cursor < _ids.size() else ""


## from에서 dir 쪽으로 마주친 몬스터의 다음 번호(없으면 -1).
func _step(from: int, dir: int) -> int:
	var i := from + dir
	while i >= 0 and i < _ids.size():
		if _seen(i):
			return i
		i += dir
	return -1


func _seen(i: int) -> bool:
	return i >= 0 and i < _ids.size() and pc.knowledge.has_seen(_ids[i])


func _show_cursor() -> void:
	for i in _rows.size():
		var sel := i == _cursor
		var box := UiTheme.box(UiTheme.color("slot_hover") if sel and active else Color.TRANSPARENT,
			UiTheme.color("select") if sel else Color.TRANSPARENT, 0, 2)
		box.set_border_width_all(1 if sel else 0)
		_rows[i].add_theme_stylebox_override("normal", box)
	if _cursor < 0:
		_detail.text = Strings.t("bestiary.empty")
		return
	show_monster(_ids[_cursor])
	if _cursor < _rows.size():
		_list_scroll.ensure_control_visible.call_deferred(_rows[_cursor])


func show_monster(id: String) -> void:
	var db := pc.db
	var d := db.get_entry("monsters", id)
	var k := pc.knowledge
	var unknown := Strings.t("knowledge.unknown")
	var fam := PackedStringArray()
	for f: Variant in JsonUtil.get_array(d, "family"):
		fam.append(DataNames.tag(db, "families", str(f)))
	var lines := PackedStringArray()
	lines.append(Strings.t("bestiary.head", {"name": DataNames.entry(db, "monsters", id), "grade": JsonUtil.get_int(d, "grade"),
		"family": ", ".join(fam)}))
	lines.append(Strings.t("bestiary.kills", {"kills": pc.progression.kill_count(id),
		"exp": Progression.first_kill_exp(db, d) if pc.progression.kill_count(id) > 0 else unknown}))
	lines.append(JsonUtil.get_str(d, "desc_ko"))
	lines.append("")
	if k.knows_stats(id):
		var st := JsonUtil.get_dict(d, "stats")
		lines.append(Strings.t("bestiary.stats", {"hp": JsonUtil.get_int(JsonUtil.get_dict(d, "resources"), "hp"),
			"str": JsonUtil.get_int(st, "str"), "agi": JsonUtil.get_int(st, "agi"),
			"p_res": JsonUtil.get_int(st, "p_res"), "m_res": JsonUtil.get_int(st, "m_res")}))
	else:
		lines.append(Strings.t("bestiary.stats_unknown"))
	lines.append(Strings.t("bestiary.affinity", {"aff": BattleKnowledge.describe_affinities(db, k, id)}))
	if d.has("variant_of"):
		lines.append(Strings.t("bestiary.variant_of", {"name": DataNames.entry(db, "monsters", JsonUtil.get_str(d, "variant_of"))}))
	var shared := Lineage.shared_skills(db, id)
	for sk: Variant in shared:
		var names := PackedStringArray()
		for o: Variant in shared[sk]:
			names.append(DataNames.entry(db, "monsters", str(o)) if k.has_seen(str(o)) else unknown)
		lines.append(Strings.t("bestiary.shared", {"skill": DataNames.entry(db, "skills", str(sk)), "list": ", ".join(names)}))
	_detail.text = "\n".join(lines)
