class_name ItemPoolRules
extends RefCounted
## 검사 규칙: 아이템 공식(ItemForge — 사용자 결정 2026-10-23) — 소재(materials)·종류(item_types)·아이템 forge 참조.
## 장비 스킬(IT8·IT9): 종류 skills는 mastery가 그 종류인 스킬만, 아이템 equip.skills는 mastery가 있는 스킬만, mastery 스킬은 어느 장비든 하나가 준다.

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
	var given := {}  # 장비가 주는 스킬 id
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
		for key in ["grow", "penalty"]:
			var mods: Array = []
			var d := JsonUtil.get_dict(t, key)
			for target: String in d:
				mods.append({"target": target, "flat": d[target]})
				if (key == "grow") != (float(d[target]) > 0.0):
					v.err(w + "." + key, "%s는 %s" % [target, "양수" if key == "grow" else "음수"])
			v.check_modifier_list(w + "." + key, mods)
		var found := false
		for mid: String in v.entries("materials"):
			found = found or JsonUtil.get_array(t, "kinds").has(JsonUtil.get_str(v.db.get_entry("materials", mid), "kind"))
		if not found:
			v.err(w, "쓸 수 있는 소재가 없다")
		_gear_refs(v, w + ".skills", JsonUtil.get_array(t, "skills"), given, id)
	for id: String in v.entries("items"):
		_gear_refs(v, "items/%s.equip.skills" % id, JsonUtil.get_array(JsonUtil.get_dict(v.db.get_entry("items", id), "equip"), "skills"), given, "")
	for id: String in v.entries("skills"):
		if v.db.get_entry("skills", id).has("mastery") and not given.has(id):
			v.err("skills/" + id, "장비 스킬(mastery)인데 주는 장비(item_types·items equip.skills)가 없다")
	for id: String in v.entries("items"):
		var f := JsonUtil.get_dict(v.db.get_entry("items", id), "forge")
		if f.is_empty():
			continue
		v.ref("items/%s.forge.type" % id, "item_types", f.get("type"))
		v.ref("items/%s.forge.material" % id, "materials", f.get("material"))
		var t := v.db.get_entry("item_types", JsonUtil.get_str(f, "type"))
		var m := v.db.get_entry("materials", JsonUtil.get_str(f, "material"))
		if not t.is_empty() and not m.is_empty() and not JsonUtil.get_array(t, "kinds").has(JsonUtil.get_str(m, "kind")):
			v.err("items/" + id + ".forge", "%s은(는) %s 소재를 쓰지 않는다" % [f.get("type"), m.get("kind")])


## type_id가 있으면(종류 skills) 스킬 mastery가 그 종류여야 한다. 고유 장비(type_id "")는 mastery만 있으면 된다.
static func _gear_refs(v: ValidatorBase, where: String, list: Array, given: Dictionary, type_id: String) -> void:
	for sid: Variant in list:
		v.ref(where, "skills", sid)
		given[str(sid)] = true
		if not v.db.has_entry("skills", str(sid)):
			continue
		var m := JsonUtil.get_str(v.db.get_entry("skills", str(sid)), "mastery")
		if m.is_empty() or (not type_id.is_empty() and m != type_id):
			v.err(where, "'%s'의 mastery '%s' — 장비 스킬은 mastery = 그 무기 종류" % [sid, m])
