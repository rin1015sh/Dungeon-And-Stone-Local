class_name BestiaryWindow
extends GothicWindow
## 도감: 왼쪽 = 모든 몬스터(마주친 적이 없으면 ???), 오른쪽 = 고른 몬스터의 알아낸 정보.
## 처치 수 · 첫 처치 공적 · 등급·계열·설명(봤으면) · 생명력·스탯(조사했으면) · 상성(직접 겪은 것만), 나머지는 ???.

var pc: PlayerCharacter

var _list: VBoxContainer
var _detail: Label


func _init() -> void:
	super(Strings.t("bestiary.title"))


func setup(p_pc: PlayerCharacter) -> void:
	pc = p_pc
	custom_minimum_size.x = UiTheme.metric("bestiary_window_width", 640)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", GothicStyle.inset_box())
	left.custom_minimum_size.x = 200
	row.add_child(left)
	_list = VBoxContainer.new()
	left.add_child(_list)
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", GothicStyle.inset_box())
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_detail = UiTheme.label("", "body")
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	right.add_child(_detail)
	refresh()


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var ids: Array = pc.db.get_collection("monsters").keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return JsonUtil.get_int(pc.db.get_entry("monsters", a), "grade") > JsonUtil.get_int(pc.db.get_entry("monsters", b), "grade") \
			or (JsonUtil.get_int(pc.db.get_entry("monsters", a), "grade") == JsonUtil.get_int(pc.db.get_entry("monsters", b), "grade") and a < b))
	var first := ""
	for id: String in ids:
		var seen := pc.knowledge.has_seen(id)
		var text := Strings.t("bestiary.entry", {"name": DataNames.entry(pc.db, "monsters", id), "kills": pc.progression.kill_count(id)}) \
			if seen else Strings.t("knowledge.unknown")
		var b := UiTheme.button(text, func() -> void: show_monster(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not seen
		_list.add_child(b)
		if seen and first.is_empty():
			first = id
	if first.is_empty():
		_detail.text = Strings.t("bestiary.empty")
	else:
		show_monster(first)


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
	_detail.text = "\n".join(lines)
