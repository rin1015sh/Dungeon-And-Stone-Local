class_name ContentRules
extends RefCounted
## 검사 규칙: 몬스터·스킬·정수·아이템. 패시브 정의는 PassiveRules, 효과 목록의 깊은 검사는 EffectRules.

## 몬스터 AI 규칙의 대상 고르기(MonsterAi.target).
const AI_TARGETS := ["random", "lowest_hp", "highest_hp", "with_status", "without_status", "highest_meter",
	"guard_front", "taunt_first", "ally_lowest_hp"]
## AI 조건(src/combat/ai/) -> 그 조건이 읽는 참조 키 [키, 컬렉션].
const AI_CONDITION_REFS := {"foe_status": ["status", "statuses"], "self_status": ["status", "statuses"],
	"foe_meter_at_least": ["meter", "meters"]}


static func run(v: ValidatorBase) -> void:
	_monsters(v)
	_skills(v)
	_essences(v)
	_items(v)
	ItemPoolRules.run(v)


static func _monsters(v: ValidatorBase) -> void:
	var types := v.db.tag_ids("monster_types")
	var families := v.db.tag_ids("families")
	var damage := v.damage_ids()
	for id: String in v.entries("monsters"):
		var m := v.db.get_entry("monsters", id)
		var w := "monsters/" + id
		v.check_grade(w, m.get("grade"))
		v.check_grade(w + ".magic_stone_grade", m.get("magic_stone_grade", m.get("grade")))
		if m.has("rank") and not v.db.tag_ids("monster_ranks").has(JsonUtil.get_str(m, "rank")):
			v.err(w, "rank '%s' 미등록(tags.monster_ranks)" % m.get("rank"))
		for st: Variant in JsonUtil.get_array(m, "status_immune"):
			v.ref(w + ".status_immune", "statuses", st)
		if m.has("upper_variant") and not m["upper_variant"] is bool:
			v.err(w, "upper_variant는 true/false")
		if m.has("variant_of"):
			v.ref(w, "monsters", m["variant_of"])
		if m.has("floor") and JsonUtil.get_int(m, "floor") < 1:
			v.err(w, "floor는 1 이상의 층 번호")
		if not types.has(JsonUtil.get_str(m, "type")):
			v.err(w, "type '%s' 미등록(tags.monster_types)" % m.get("type"))
		for f: Variant in JsonUtil.get_array(m, "family"):
			if not families.has(str(f)):
				v.err(w, "family '%s' 미등록" % f)
		for im: Variant in JsonUtil.get_array(m, "immunities"):
			if not damage.has(str(im)):
				v.err(w, "immunities '%s' 미등록 피해 유형" % im)
		var weak := JsonUtil.get_dict(m, "weaknesses")
		for k: String in weak:
			if not damage.has(k):
				v.err(w, "weaknesses '%s' 미등록 피해 유형" % k)
			if not JsonUtil.is_number(weak[k]) or float(weak[k]) <= 0.0:
				v.err(w, "weaknesses 배율은 양수")
		v.check_stat_map(w, JsonUtil.get_dict(m, "stats"))
		var res := JsonUtil.get_dict(m, "resources")
		for r: String in res:
			if not v.db.resources.has(r):
				v.err(w, "resources '%s' 없는 자원" % r)
			v.check_formula(w + ".resources", res[r])
		for s: Variant in JsonUtil.get_array(m, "skills"):
			v.ref(w, "skills", s)
		_ai(v, w, m)
		for sk: Variant in JsonUtil.get_array(m, "ai_cycle"):
			v.ref(w + ".ai_cycle", "skills", sk)
		if m.has("lineage") and JsonUtil.get_str(m, "lineage").is_empty():
			v.err(w, "lineage는 계열 id 문자열")
		var nw := JsonUtil.get_dict(m, "natural_weapon")
		if not nw.is_empty() and (not damage.has(JsonUtil.get_str(nw, "damage_type")) or JsonUtil.get_float(nw, "attack", -1.0) < 0.0):
			v.err(w, "natural_weapon은 {attack ≥ 0, damage_type: 피해 유형, ranged?}")
		for p: Variant in JsonUtil.get_array(m, "passives"):
			PassiveRules.check(v, w + ".passives", p if p is Dictionary else {})
		for t: Variant in JsonUtil.get_array(m, "types"):
			EffectRules.ref_list(v, w + ".types.skills", "skills", JsonUtil.get_array(t if t is Dictionary else {}, "skills"))
		if not v.db.tag_ids("monster_shapes").has(JsonUtil.get_str(m, "shape", "humanoid")):
			v.err(w, "shape '%s' 미등록(tags.monster_shapes)" % m.get("shape"))
		v.check_color(w, JsonUtil.get_str(m, "color"))
		var wp: Variant = m.get("weak_point")
		if wp != null and not (wp is Dictionary and (wp as Dictionary).has("name_ko")):
			v.err(w, "weak_point는 null 또는 {name_ko, …}")
		var beh := JsonUtil.get_dict(m, "behavior")
		var pack := JsonUtil.get_array(beh, "pack_size")
		if pack.size() != 2 or int(pack[0]) < 1 or int(pack[0]) > int(pack[1]):
			v.err(w, "behavior.pack_size는 [최소 1 이상, 최대]")
		for drop: Variant in JsonUtil.get_array(m, "drops"):
			var dr: Dictionary = drop if drop is Dictionary else {}
			v.ref(w + ".drops", "items", dr.get("item"))
			if JsonUtil.get_str(v.db.get_entry("items", str(dr.get("item"))), "rift_bound").is_empty():  # 잡템 금지(2026-10-21) — 균열 열쇠만
				v.err(w + ".drops", "처치 드롭은 마석·정수뿐이다 — drops에는 균열 열쇠(rift_bound 아이템)만: '%s'" % dr.get("item"))
			if dr.has("chance"):
				v.check_chance(w + ".drops", dr.get("chance"))
		if m.has("lord_drops") and JsonUtil.get_str(m, "rank") != "lord":
			v.err(w, "lord_drops는 계층군주(rank lord)만")
		for drop: Variant in JsonUtil.get_array(m, "lord_drops"):
			var ld: Dictionary = drop if drop is Dictionary else {}
			v.ref(w + ".lord_drops", "items", ld.get("item"))
			v.check_chance(w + ".lord_drops", ld.get("chance", 1.0))
		for drop: Variant in JsonUtil.get_array(m, "essence_drops"):
			var dd: Dictionary = drop if drop is Dictionary else {}
			v.ref(w, "essences", dd.get("essence"))
			v.check_chance(w, dd.get("chance"))


## 몬스터 ai[] 규칙: 쓸 스킬, 조건 id와 조건이 읽는 상태·게이지, 대상 규칙, phase 조건의 페이즈 id.
static func _ai(v: ValidatorBase, w: String, m: Dictionary) -> void:
	var phase_ids: Array = []
	for ph: Variant in JsonUtil.get_array(m, "phases"):
		phase_ids.append(JsonUtil.get_str(ph if ph is Dictionary else {}, "id"))
	var type_skills: Array = []
	for t: Variant in JsonUtil.get_array(m, "types"):
		type_skills.append_array(JsonUtil.get_array(t if t is Dictionary else {}, "skills"))
	for rule: Variant in JsonUtil.get_array(m, "ai"):
		var rd: Dictionary = rule if rule is Dictionary else {}
		var aw := w + ".ai"
		v.ref(aw, "skills", rd.get("use"))
		if rd.has("target") and not JsonUtil.get_str(rd, "target") in AI_TARGETS:
			v.err(aw, "target '%s'은(는) %s 중 하나" % [rd.get("target"), AI_TARGETS])
		if rd.has("target_status"):
			v.ref(aw + ".target_status", "statuses", rd["target_status"])
		if rd.has("target_meter") or JsonUtil.get_str(rd, "target") == "highest_meter":
			v.ref(aw + ".target_meter", "meters", rd.get("target_meter"))
		var conds: Array = [rd]
		conds.append_array(JsonUtil.get_array(rd, "also"))
		for cd: Variant in conds:
			var cdd: Dictionary = cd if cd is Dictionary else {}
			var cond := JsonUtil.get_str(cdd, "if", "always")
			if not v.ai_condition_ids.is_empty() and not v.ai_condition_ids.has(cond):
				v.err(aw, "조건 '%s' 없음(src/combat/ai/)" % cond)
			if AI_CONDITION_REFS.has(cond):
				var pair: Array = AI_CONDITION_REFS[cond]
				v.ref("%s.%s.%s" % [aw, cond, pair[0]], str(pair[1]), cdd.get(str(pair[0])))
			if cond == "phase":
				var want: Variant = cdd.get("value")
				if not want is Array:
					v.err(aw + ".phase", "value는 페이즈 id 배열")
				else:
					for pid: Variant in (want as Array):
						if not phase_ids.has(str(pid)):
							v.err(aw + ".phase", "페이즈 '%s' 없음(이 몬스터의 phases)" % pid)
		if rd.get("use") != Battle.BASIC_ATTACK and not JsonUtil.get_array(m, "skills").has(rd.get("use")) and not type_skills.has(rd.get("use")):
			v.warn(aw, "스킬 '%s'이(가) skills 목록에 없다" % rd.get("use"))


static func _skills(v: ValidatorBase) -> void:
	var targets := v.db.tag_ids("skill_targets")
	for id: String in v.entries("skills"):
		var s := v.db.get_entry("skills", id)
		var w := "skills/" + id
		if not targets.has(JsonUtil.get_str(s, "target")):
			v.err(w, "target '%s' 미등록(tags.skill_targets)" % s.get("target"))
		var cost := JsonUtil.get_dict(s, "cost")
		for r: String in cost:
			if not v.db.resources.has(r):
				v.err(w, "cost '%s' 없는 자원" % r)
			elif not JsonUtil.is_number(cost[r]) or float(cost[r]) < 0.0:
				v.err(w, "cost 값은 0 이상의 숫자")
		EffectRules.check(v, w, JsonUtil.get_array(s, "effects"), v.check_skill_effects)
		if s.has("innate") and not s["innate"] is bool:
			v.err(w, "innate는 true/false")
		if s.has("essence_of") and JsonUtil.get_str(s, "essence_of").is_empty():
			v.err(w, "essence_of는 원래 스킬 id 문자열")
		elif s.has("essence_of"):
			v.ref(w + ".essence_of", "skills", s["essence_of"])
	for id: Variant in v.db.bal("party.innate_skills", []):
		v.ref("balance.party.innate_skills", "skills", id)
		if v.db.has_entry("skills", str(id)) and not JsonUtil.get_bool(v.db.get_entry("skills", str(id)), "innate"):
			v.err("skills/" + str(id), "기본 스킬(party.innate_skills)은 \"innate\": true여야 한다")


## 정수(docs/PROMPT_FLOOR1_V2.md §2·§3): 패시브 1개 + 색 → 액티브. 고유(unique) 스킬은 넣지 않는다.
static func _essences(v: ValidatorBase) -> void:
	var colors := v.db.tag_ids("essence_colors")
	var guardian_color := str(v.db.bal("essence.guardian_color", "rainbow"))
	for id: String in v.entries("essences"):
		var e := v.db.get_entry("essences", id)
		var w := "essences/" + id
		v.check_grade(w, e.get("grade"))
		var fixed := JsonUtil.get_dict(e, "stats")
		for k: String in fixed:
			if not v.db.stats.has(k):
				v.err(w, "stats '%s' 없는 스탯" % k)
			elif not JsonUtil.is_number(fixed[k]):
				v.err(w, "stats '%s' 값은 숫자" % k)
		if e.has("stat_ranges"):
			v.err(w, "stat_ranges는 없어졌다 — 고정값 stats를 쓴다(J13)")
		if e.has("source_monster"):
			v.ref(w, "monsters", e["source_monster"])
		var res := JsonUtil.get_dict(e, "resources")
		for r: String in res:
			if not v.db.resources.has(r):
				v.err(w, "resources '%s' 없는 자원" % r)
			elif not JsonUtil.is_number(res[r]):
				v.err(w, "resources '%s' 값은 숫자" % r)
		PassiveRules.check(v, w + ".passive", JsonUtil.get_dict(e, "passive"))
		var actives := JsonUtil.get_array(e, "actives")
		if actives.is_empty():
			v.err(w, "actives가 비어 있다")
		var seen := PackedStringArray()
		for a: Variant in actives:
			var ad: Dictionary = a if a is Dictionary else {}
			var c := JsonUtil.get_str(ad, "color")
			if not colors.has(c) or c == guardian_color:
				v.err(w + ".actives", "color '%s' 미등록(tags.essence_colors, 무지갯빛 제외)" % c)
			if seen.has(c):
				v.err(w + ".actives", "color '%s' 중복" % c)
			seen.append(c)
			var sid := JsonUtil.get_str(ad, "skill")
			v.ref(w + ".actives", "skills", sid)
			if JsonUtil.get_bool(v.db.get_entry("skills", sid), "unique"):
				v.err(w + ".actives", "고유(unique) 스킬 '%s'은(는) 정수에 넣을 수 없다" % sid)


static func _items(v: ValidatorBase) -> void:
	var categories := v.db.tag_ids("item_categories")
	for id: String in v.entries("items"):
		var it := v.db.get_entry("items", id)
		var w := "items/" + id
		if not categories.has(JsonUtil.get_str(it, "category")):
			v.err(w, "category '%s' 미등록(tags.item_categories)" % it.get("category"))
		if JsonUtil.get_float(it, "price", -1.0) < 0.0:
			v.err(w, "price는 0 이상의 숫자")
		if JsonUtil.get_int(it, "stack", 1) < 1:
			v.err(w, "stack은 1 이상")
		EffectRules.check(v, w + ".use_effects", JsonUtil.get_array(it, "use_effects"), true)
		_item_shape(v, w, it)


## 격자 크기·장비 정보·희귀도(M3).
static func _item_shape(v: ValidatorBase, w: String, it: Dictionary) -> void:
	var size := JsonUtil.get_array(it, "size")
	if it.has("size") and (size.size() != 2 or int(size[0]) < 1 or int(size[1]) < 1 or int(size[0]) > 4 or int(size[1]) > 4):
		v.err(w, "size는 [가로, 세로] 1~4칸")
	if it.has("rarity") and not v.db.tag_ids("rarities").has(JsonUtil.get_str(it, "rarity")):
		v.err(w, "rarity '%s' 미등록(tags.rarities)" % it.get("rarity"))
	if not it.has("equip") or it["equip"] == null:
		return
	var e := JsonUtil.get_dict(it, "equip")
	if not v.db.tag_ids("equip_slots").has(JsonUtil.get_str(e, "slot")):
		v.err(w + ".equip", "slot '%s' 미등록(tags.equip_slots)" % e.get("slot"))
	if JsonUtil.get_int(it, "stack", 1) != 1:
		v.err(w, "장비는 stack 1")
	v.check_modifier_list(w + ".equip.modifiers", JsonUtil.get_array(e, "modifiers"))
	if e.has("weapon"):
		var wp := JsonUtil.get_dict(e, "weapon")
		if JsonUtil.get_str(e, "slot") != "main_hand":
			v.err(w + ".equip", "weapon은 main_hand 장비만")
		if not v.damage_ids().has(JsonUtil.get_str(wp, "damage_type")):
			v.err(w + ".equip.weapon", "damage_type '%s' 미등록" % wp.get("damage_type"))
		if JsonUtil.get_float(wp, "attack", -1.0) < 0.0:
			v.err(w + ".equip.weapon", "attack은 0 이상")
