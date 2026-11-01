class_name ItemPoolRules
extends RefCounted
## 검사 규칙: 아이템 공식(ItemForge — 사용자 결정 2026-10-23) — 소재(materials)·종류(item_types)·아이템 forge 참조.

const KINDS := ["metal", "leather", "wood", "cloth", "bone", "gem"]


static func run(v: ValidatorBase) -> void:
	var cfg := JsonUtil.get_dict(v.db.singletons.get("balance", {}), "items")
	for key in ["grow_by_tier", "price_by_tier", "rarity_by_tier"]:
		if JsonUtil.get_array(cfg, key).size() != 6:
			v.err("balance.items." + key, "등급 1~6 값 6개")
	for r: Variant in JsonUtil.get_array(cfg, "rarity_by_tier"):
		if not v.db.tag_ids("rarities").has(str(r)):
			v.err("balance.items.rarity_by_tier", "rarity '%s' 미등록" % r)
	for k: String in KINDS:
		if not JsonUtil.get_dict(cfg, "kind_price").has(k):
			v.err("balance.items.kind_price", "소재 종류 '%s' 값 없음" % k)
	for id: String in v.entries("materials"):
		var m := v.db.get_entry("materials", id)
		var w := "materials/" + id
		if JsonUtil.get_int(m, "tier") < 1 or JsonUtil.get_int(m, "tier") > 6:
			v.err(w, "tier는 1~6")
		if not KINDS.has(JsonUtil.get_str(m, "kind")):
			v.err(w, "kind '%s'(%s 중 하나)" % [m.get("kind"), ", ".join(KINDS)])
		v.check_color(w + ".color", JsonUtil.get_str(m, "color"))
		var tr := JsonUtil.get_dict(m, "trait")
		for key in ["mods", "weapon_mods", "armor_mods"]:
			var list: Array = []
			for md: Variant in JsonUtil.get_array(tr, key):  # "dmg_dealt:weapon" = 무기 피해 유형(검사는 참격으로)
				var d: Dictionary = (md as Dictionary).duplicate() if md is Dictionary else {}
				d["target"] = JsonUtil.get_str(d, "target").replace(":weapon", ":slash")
				list.append(d)
			v.check_modifier_list(w + ".trait." + key, list)
		v.check_stat_map(w + ".trait.stat_mult", JsonUtil.get_dict(tr, "stat_mult"))
		_no_cut(v, w + ".trait", JsonUtil.get_array(tr, "mods") + JsonUtil.get_array(tr, "weapon_mods") + JsonUtil.get_array(tr, "armor_mods"))
		if tr.has("agi_pen"):
			v.err(w + ".trait.agi_pen", "민첩 감소는 없앴다(IT13)")
	for id: String in v.entries("item_types"):
		var t := v.db.get_entry("item_types", id)
		var w := "item_types/" + id
		if not v.db.tag_ids("equip_slots").has(JsonUtil.get_str(t, "slot")):
			v.err(w, "slot '%s' 미등록(tags.equip_slots)" % t.get("slot"))
		if JsonUtil.get_array(t, "kinds").is_empty():
			v.err(w, "kinds(쓰는 소재 종류)가 비었다")
		for k: Variant in JsonUtil.get_array(t, "kinds"):
			if not KINDS.has(str(k)):
				v.err(w, "소재 종류 '%s' 없음" % k)
		if t.has("penalty"):  # 장비는 스탯을 깎지 않는다(사용자 결정 2026-11-01, IT13)
			v.err(w + ".penalty", "감소 스탯은 없앴다 — 특색은 grow로")
		var mods: Array = []
		var g := JsonUtil.get_dict(t, "grow")
		for target: String in g:
			mods.append({"target": target, "flat": g[target]})
			if float(g[target]) <= 0.0:
				v.err(w + ".grow", "%s는 양수" % target)
		v.check_modifier_list(w + ".grow", mods)
		var found := false
		for mid: String in v.entries("materials"):
			found = found or JsonUtil.get_array(t, "kinds").has(JsonUtil.get_str(v.db.get_entry("materials", mid), "kind"))
		if not found:
			v.err(w, "쓸 수 있는 소재가 없다")
	for id: String in v.entries("items"):
		var it := v.db.get_entry("items", id)
		_no_cut(v, "items/%s.equip" % id, JsonUtil.get_array(JsonUtil.get_dict(it, "equip"), "modifiers"))
		var f := JsonUtil.get_dict(it, "forge")
		if f.is_empty():
			continue
		v.ref("items/%s.forge.type" % id, "item_types", f.get("type"))
		v.ref("items/%s.forge.material" % id, "materials", f.get("material"))
		var t := v.db.get_entry("item_types", JsonUtil.get_str(f, "type"))
		var m := v.db.get_entry("materials", JsonUtil.get_str(f, "material"))
		if not t.is_empty() and not m.is_empty() and not JsonUtil.get_array(t, "kinds").has(JsonUtil.get_str(m, "kind")):
			v.err("items/" + id + ".forge", "%s은(는) %s 소재를 쓰지 않는다" % [f.get("type"), m.get("kind")])


## 장비 수정자가 스탯을 깎지 않는가(IT13): 고정값은 양수만. 비율은 dmg_taken(받는 피해 — 음수가 이롭다)만 음수를 허락한다.
static func _no_cut(v: ValidatorBase, where: String, mods: Array) -> void:
	for md: Variant in mods:
		var d: Dictionary = md if md is Dictionary else {}
		var target := JsonUtil.get_str(d, "target")
		var val := JsonUtil.get_float(d, "flat", JsonUtil.get_float(d, "percent"))
		if (val < 0.0) != target.begins_with("dmg_taken"):
			v.err(where, "%s %s — 장비는 스탯을 깎지 않는다(IT13)" % [target, val])
