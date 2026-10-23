class_name ItemTooltip
extends RefCounted
## 아이템 설명(스톤샤드식 — Tab 메뉴 소지품 쪽이 커서 아이템 옆에 띄운다): 이름(희귀도 색) · 종류 · 무기 공격력 · 수정자(+초록/−빨강) · 사용 효과 ·
## 크기 · 설명 · 가격. 장비면 같은 칸에 낀 장비를 "장착 중" 툴팁으로 옆에 나란히 보여 준다.


## 툴팁 Control. actor가 있으면 장착품과 비교한다.
static func build(db: GameDatabase, item_id: String, actor: Actor = null, count: int = 1) -> Control:
	var row := BoxContainer.new()  # 옆으로 나란히 — 화면에 자리가 없으면 띄우는 쪽이 세로로 쌓는다(InventoryPage._place_tip)
	row.add_child(panel(db, item_id, false, count))
	if actor != null and not ItemInfo.equip(db, item_id).is_empty():
		var slot := actor.equipment.pick_slot(item_id)
		var worn := actor.equipment.item_in(slot) if not slot.is_empty() else ""
		if not worn.is_empty() and worn != item_id:
			row.add_child(panel(db, worn, true))
	return row


static func panel(db: GameDatabase, item_id: String, equipped: bool, count: int = 1) -> PanelContainer:
	var d := ItemInfo.def(db, item_id)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", GothicStyle.frame_box())
	p.custom_minimum_size.x = UiTheme.metric("tooltip_width", 270)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	if equipped:
		var head := UiTheme.label(Strings.t("inventory.equipped"), "small", "text_dim")
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(head)
	var rarity := JsonUtil.get_str(d, "rarity", "common")
	var title := UiTheme.label(JsonUtil.get_str(d, "name_ko", item_id) + (" ×%d" % count if count > 1 else ""), "header")
	title.add_theme_color_override("font_color", _rarity_color(db, rarity))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UiTheme.label(_subtitle(db, item_id, rarity), "small", "text_dim")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(HSeparator.new())
	var weapon := ItemInfo.weapon(db, item_id)
	if not weapon.is_empty():
		var wl := UiTheme.label(Strings.t("inventory.weapon_line", {"attack": UiTheme.num(JsonUtil.get_float(weapon, "attack")),
			"type": DataNames.tag(db, "damage_types", JsonUtil.get_str(weapon, "damage_type"))}), "body", "text_title")
		wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(wl)
		if ItemInfo.two_handed(db, item_id):
			v.add_child(_stat_row(Strings.t("inventory.two_handed"), "", 0.0))
	for m: Variant in JsonUtil.get_array(ItemInfo.equip(db, item_id), "modifiers"):
		var md: Dictionary = m if m is Dictionary else {}
		var val := JsonUtil.get_float(md, "flat")
		var pct := JsonUtil.get_float(md, "percent")
		var text := ("%+d" % roundi(val)) if not is_zero_approx(val) else ("%+d%%" % roundi(pct * 100.0))
		v.add_child(_stat_row(target_name(db, JsonUtil.get_str(md, "target")), text, val + pct))
	for e: Variant in JsonUtil.get_array(d, "use_effects"):
		var line := _effect_line(db, e if e is Dictionary else {})
		if not line.is_empty():
			v.add_child(_stat_row(line, "", 1.0))
	var size := ItemInfo.size(db, item_id)
	v.add_child(_stat_row(Strings.t("inventory.size"), "%d×%d" % [size.x, size.y], 0.0))
	var desc := JsonUtil.get_str(d, "desc_ko")
	if not desc.is_empty():
		v.add_child(HSeparator.new())
		var dl := UiTheme.label(desc, "small", "text_dim")
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size.x = UiTheme.metric("tooltip_width", 270) - 24
		v.add_child(dl)
	var price := UiTheme.label(Strings.t("inventory.price", {"price": ItemInfo.price(db, item_id)}), "small", "gold")
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(price)
	return p


## 수정자 대상의 이름: 스탯 이름, "max:<자원>" → "<자원> 최대치", 그 밖은 그대로.
static func target_name(db: GameDatabase, target: String) -> String:
	if target.begins_with("max:"):
		return Strings.t("inventory.max_of", {"res": db.resources[target.substr(4)].name_ko}) if db.resources.has(target.substr(4)) else target
	if target.begins_with("regen:"):
		return Strings.t("inventory.regen_of", {"res": db.resources[target.substr(6)].name_ko}) if db.resources.has(target.substr(6)) else target
	return DataNames.entry(db, "stats", target)


static func _subtitle(db: GameDatabase, item_id: String, rarity: String) -> String:
	var slot := ItemInfo.slot(db, item_id)
	var kind := DataNames.tag(db, "equip_slots", slot) if not slot.is_empty() \
		else DataNames.tag(db, "item_categories", JsonUtil.get_str(ItemInfo.def(db, item_id), "category"))
	return "%s %s" % [DataNames.tag(db, "rarities", rarity), kind]


static func _effect_line(db: GameDatabase, e: Dictionary) -> String:
	match JsonUtil.get_str(e, "type"):
		"restore_resource":
			var r := JsonUtil.get_str(e, "resource")
			return Strings.t("inventory.eff_restore", {"res": db.resources[r].name_ko if db.resources.has(r) else r,
				"amount": roundi(JsonUtil.get_float(e, "amount"))})
		"light_source":
			return Strings.t("inventory.eff_light", {"m": UiTheme.num(JsonUtil.get_float(e, "radius_m")),
				"hours": roundi(JsonUtil.get_float(e, "hours"))})
		"apply_status":
			return Strings.t("inventory.eff_status", {"status": DataNames.entry(db, "statuses", JsonUtil.get_str(e, "status")),
				"chance": roundi(JsonUtil.get_float(e, "chance", 1.0) * 100.0)})
	return ""


static func _stat_row(left: String, right: String, sign_value: float) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := UiTheme.label(left, "small", "text")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	if not right.is_empty():
		var key := "stat_pos" if sign_value > 0.0 else ("stat_neg" if sign_value < 0.0 else "text")
		h.add_child(UiTheme.label(right, "small", key))
	return h


static func _rarity_color(db: GameDatabase, rarity: String) -> Color:
	for t: Variant in JsonUtil.get_array(db.tags, "rarities"):
		if t is Dictionary and JsonUtil.get_str(t, "id") == rarity:
			return Color.from_string(JsonUtil.get_str(t, "color"), UiTheme.color("text_title"))
	return UiTheme.color("text_title")
