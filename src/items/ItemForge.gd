class_name ItemForge
extends RefCounted
## 아이템 공식(사용자 결정 2026-10-23 — docs/balance/item_pool.md): 장비 = 종류(data/item_types.json) × 소재(data/materials.json).
## GameDatabase.load_all이 데이터를 읽은 직후 한 번 부른다(오토로드·GameDatabase를 참조하지 않는다 — 원본 사전만 다룬다).
##   1) 아이템 JSON의 "forge": {"type", "material"} — equip·price·tier는 공식으로 덮고, 나머지(이름·크기·그림·색·분류·희귀도)는
##      비어 있을 때만 채운다(지금 장비 — id·이름·크기 유지, 저장 호환).
##      forge "bonus": [{target, flat|percent}] = 그 물건만의 덤(균열에서 줍는 장비 — 2026-10-30 docs/plans/rift_rooms.md). 덤이 있는 물건은
##      공식 조합을 차지하지 않는다(같은 종류 × 소재의 범용 장비 "<소재>_<종류>"는 그대로 만든다 — 대장간이 판다).
##   2) 종류 × 그 종류가 쓰는 소재(kinds)의 모든 조합 중 1)이 차지하지 않은 것을 "<소재>_<종류>" id, "<소재> <종류>" 이름으로 만든다.
## 수치(balance.items):
##   공격력·마력(weapon.attack·magic) = 종류 값 × attack_by_tier[등급−1] × 소재 atk — 반올림
##   증가(grow) = 종류 값 × grow_by_tier[등급−1] × 소재 stat_mult — 반올림, 최소 1. 단 unscaled(명중률·시각·속성 내성/감응도 — % 단위)는 단계 배율 없이
##   (소재 장비 = 범용 — 10층에서도 힘의 약 4분의 1, 그 위는 넘버스 몫: docs/plans/balance_10floors.md §6)
##   감소(penalty) = 종류 값 그대로. 소재 agi_pen만 민첩 감소에 곱한다(가벼움 0.5 = 내림 · 무거움 1.5 = 반올림)
##   소재 trait: mods(모든 장비) · weapon_mods(무기 — 대상 "dmg_dealt:weapon"은 그 무기 피해 유형) · armor_mods(무기가 아닌 것)
##   구입가 = base_price × 종류 price_mult × kind_price[소재 종류] × price_by_tier[등급−1] × 소재 price_mult → 유효숫자 두 자리
##   희귀도 = rarity_by_tier[등급−1]. 판매가는 상점 sell_ratio(city.json). 설명(desc_ko) = 소재 flavor_ko + 종류 flavor_ko(IT7 — 아이템 JSON에 desc_ko가 있으면 그것).


static func forge_all(cols: Dictionary, bal: Dictionary) -> void:
	var items: Dictionary = cols.get("items", {})
	var types: Dictionary = cols.get("item_types", {})
	var mats: Dictionary = cols.get("materials", {})
	var cfg := JsonUtil.get_dict(bal, "items")
	if types.is_empty() or mats.is_empty() or cfg.is_empty():
		return
	var claimed := {}
	for id: String in items:
		var it: Dictionary = items[id]
		var f := JsonUtil.get_dict(it, "forge")
		var t: Dictionary = types.get(JsonUtil.get_str(f, "type"), {})
		var m: Dictionary = mats.get(JsonUtil.get_str(f, "material"), {})
		if t.is_empty() or m.is_empty():
			continue  # forge가 없거나 잘못됐다(검증기가 알린다)
		var bonus := JsonUtil.get_array(f, "bonus")
		if bonus.is_empty():
			claimed[_key(t, m)] = true
		var made := build(t, m, cfg)
		_add_bonus(made, bonus)
		for k: String in made:
			if k in ["equip", "price", "tier", "forged"] or not it.has(k):
				it[k] = made[k]
	for tid: String in types:
		var t: Dictionary = types[tid]
		for mid: String in mats:
			var m: Dictionary = mats[mid]
			if not JsonUtil.get_array(t, "kinds").has(JsonUtil.get_str(m, "kind")) or claimed.has(_key(t, m)):
				continue
			var id := "%s_%s" % [mid, tid]
			if items.has(id):
				continue
			var made := build(t, m, cfg)
			made["id"] = id
			items[id] = made


## 종류 t × 소재 m 아이템 항목(id 제외).
static func build(t: Dictionary, m: Dictionary, cfg: Dictionary) -> Dictionary:
	var tier := clampi(JsonUtil.get_int(m, "tier", 1), 1, 6)
	var grow := _at(cfg, "grow_by_tier", tier, 1.0)
	var atk_mult := _at(cfg, "attack_by_tier", tier, grow)
	var feat := JsonUtil.get_dict(m, "trait")
	var smult := JsonUtil.get_dict(feat, "stat_mult")
	var flat := {}  # 대상 -> 값(넣은 순서 유지)
	var g := JsonUtil.get_dict(t, "grow")
	for k: String in g:
		var gm := 1.0 if unscaled(cfg, k) else grow
		flat[k] = float(flat.get(k, 0.0)) + maxf(1.0, roundf(float(g[k]) * gm * JsonUtil.get_float(smult, k, 1.0)))
	var pen := JsonUtil.get_dict(t, "penalty")
	for k: String in pen:
		var v := float(pen[k])
		if k == "agi" and feat.has("agi_pen"):
			var ap := JsonUtil.get_float(feat, "agi_pen", 1.0)
			v = -floorf(absf(v) * ap + (0.5 if ap > 1.0 else 0.0))
		flat[k] = float(flat.get(k, 0.0)) + v
	var weapon := JsonUtil.get_dict(t, "weapon")
	var extra: Array = JsonUtil.get_array(feat, "mods").duplicate()
	extra.append_array(JsonUtil.get_array(feat, "weapon_mods" if not weapon.is_empty() else "armor_mods"))
	var pct: Array[Dictionary] = []
	for md: Variant in extra:
		var d: Dictionary = md if md is Dictionary else {}
		var target := JsonUtil.get_str(d, "target").replace(":weapon", ":" + JsonUtil.get_str(weapon, "damage_type"))
		if d.has("percent"):
			pct.append({"target": target, "percent": JsonUtil.get_float(d, "percent")})
		else:
			flat[target] = float(flat.get(target, 0.0)) + JsonUtil.get_float(d, "flat")
	var mods: Array[Dictionary] = []
	for k: String in flat:
		if float(flat[k]) != 0.0:
			mods.append({"target": k, "flat": int(flat[k])})
	mods.append_array(pct)
	var equip := {"slot": JsonUtil.get_str(t, "slot"), "modifiers": mods}
	if JsonUtil.get_bool(t, "two_handed"):
		equip["two_handed"] = true
	if not weapon.is_empty():
		var w := weapon.duplicate()
		w["attack"] = int(roundf(JsonUtil.get_float(weapon, "attack") * atk_mult * JsonUtil.get_float(feat, "atk", 1.0)))
		if weapon.has("magic"):  # 지팡이 마력(마법 공격력에 더한다)
			w["magic"] = int(roundf(JsonUtil.get_float(weapon, "magic") * atk_mult * JsonUtil.get_float(feat, "atk", 1.0)))
		equip["weapon"] = w
	var price := JsonUtil.get_float(cfg, "base_price", 2000.0) * JsonUtil.get_float(t, "price_mult", 1.0) \
		* JsonUtil.get_float(JsonUtil.get_dict(cfg, "kind_price"), JsonUtil.get_str(m, "kind"), 1.0) \
		* _at(cfg, "price_by_tier", tier, 1.0) * JsonUtil.get_float(m, "price_mult", 1.0)
	var rarities := JsonUtil.get_array(cfg, "rarity_by_tier")
	var flavor := ("%s %s" % [JsonUtil.get_str(m, "flavor_ko"), JsonUtil.get_str(t, "flavor_ko")]).strip_edges()  # 소재 한 줄 + 생김새 한 줄(IT7)
	return {"name_ko": "%s %s" % [JsonUtil.get_str(m, "name_ko"), JsonUtil.get_str(t, "name_ko")], "desc_ko": flavor,
		"category": JsonUtil.get_str(t, "category", "armor"), "size": JsonUtil.get_array(t, "size").duplicate(), "stack": 1,
		"price": nice(price), "icon": JsonUtil.get_str(t, "icon"), "color": JsonUtil.get_str(m, "color"),
		"rarity": str(rarities[tier - 1]) if rarities.size() >= tier else "common", "tier": tier,
		"forged": {"type": JsonUtil.get_str(t, "id"), "material": JsonUtil.get_str(m, "id")}, "equip": equip, "source": "placeholder"}


## 덤 수정자를 장비 수정자에 더한다(같은 대상의 고정값은 합친다).
static func _add_bonus(made: Dictionary, bonus: Array) -> void:
	var mods: Array = (made["equip"] as Dictionary)["modifiers"]
	for b: Variant in bonus:
		var d: Dictionary = b if b is Dictionary else {}
		var target := JsonUtil.get_str(d, "target")
		var same: Array = mods.filter(func(x: Dictionary) -> bool: return str(x["target"]) == target and x.has("flat"))
		if d.has("flat") and not same.is_empty():
			same[0]["flat"] = int(same[0]["flat"]) + JsonUtil.get_int(d, "flat")
		elif d.has("percent"):
			mods.append({"target": target, "percent": JsonUtil.get_float(d, "percent")})
		else:
			mods.append({"target": target, "flat": JsonUtil.get_int(d, "flat")})


## 가격표처럼 유효숫자 두 자리(100 미만은 5 단위).
## 단계 배율을 받지 않는 스탯(balance.items.unscaled — 이름 또는 접두사 "resist_" 꼴).
static func unscaled(cfg: Dictionary, stat: String) -> bool:
	for u: Variant in JsonUtil.get_array(cfg, "unscaled"):
		var key := str(u)
		if stat == key or (key.ends_with("_") and stat.begins_with(key)):
			return true
	return false


static func nice(v: float) -> int:
	if v < 100.0:
		return maxi(5, int(floorf(v / 5.0 + 0.5)) * 5)
	var unit := pow(10.0, float(str(int(v)).length() - 2))
	return int(floorf(v / unit + 0.5) * unit)


static func _at(cfg: Dictionary, key: String, tier: int, fallback: float) -> float:
	var a := JsonUtil.get_array(cfg, key)
	return float(a[tier - 1]) if a.size() >= tier else fallback


static func _key(t: Dictionary, m: Dictionary) -> String:
	return "%s|%s" % [JsonUtil.get_str(t, "id"), JsonUtil.get_str(m, "id")]
