class_name CombatSounds
extends RefCounted
## 전투 소리(data/audio.json combat · cries — 오토로드 비의존, 키만 돌려준다 — CombatScreen이 AudioBus로 튼다).
##   시작: 맞닥뜨림 · 덮쳐 옴 · 먼저 발견 · 큰 무리(예비대) + 처음 보는 적 하나의 울음(cries — id → family)
##   act: 스킬을 쓸 때 — 원거리면 활시위 · 쏘기, 마법(scaling magic)이면 피해 유형별 시전 소리
##   damage: 헛침 · 면역 · 막힘 · 치명타 · 피해 유형별 타격(슬라임 계열 대상 · 채찍 스킬은 따로). 지속 피해(dot)는 소리 없음
##   down: 털썩(아군이면 비명도) · phase: 낮은 종 · summon: 위협 울음 · end 승리


static func _cfg(db: GameDatabase) -> Dictionary:
	return SoundData.section(db, "combat")


static func start_keys(db: GameDatabase, b: Battle, first_side: int) -> Array[String]:
	var c := _cfg(db)
	var out: Array[String] = []
	var k := "start"
	if not b.horde.is_empty():
		k = "start_horde"
	elif first_side == Combatant.SIDE_ENEMY:
		k = "start_ambushed"
	elif first_side == Combatant.SIDE_PARTY:
		k = "start_first"
	out.append(JsonUtil.get_str(c, k))
	for u in b.side_units(Combatant.SIDE_ENEMY):
		var cry := cry_for(db, u)
		if not cry.is_empty():
			out.append(cry)
			break
	return out


## 몬스터 울음 키(id가 먼저, 없으면 family 첫 항목).
static func cry_for(db: GameDatabase, u: Combatant) -> String:
	if not u.actor is Monster:
		return ""
	var m := u.actor as Monster
	var cr := SoundData.section(db, "cries")
	var by_id := JsonUtil.get_dict(cr, "by_id")
	if by_id.has(m.monster_id):
		return str(by_id[m.monster_id])
	var by_fam := JsonUtil.get_dict(cr, "by_family")
	for f: Variant in JsonUtil.get_array(m.def, "family"):
		if by_fam.has(str(f)):
			return str(by_fam[str(f)])
	return ""


static func event_keys(db: GameDatabase, e: Dictionary) -> Array[String]:
	var c := _cfg(db)
	var out: Array[String] = []
	match str(e.get("type")):
		"act":
			var act: Dictionary = e.get("action", {})
			if str(act.get("kind", "")) == "skill":
				out.append_array(_cast(db, str(act.get("skill", ""))))
		"damage":
			if bool(e.get("dot", false)):
				return out
			out.append(_hit(db, e))
		"down":
			out.append(JsonUtil.get_str(c, "fall"))
			var u: Combatant = e.get("unit")
			if u != null and u.side == Combatant.SIDE_PARTY and not u.summoned:
				out.append(JsonUtil.get_str(c, "party_down"))
		"phase":
			out.append(JsonUtil.get_str(c, "phase"))
		"summon":
			out.append(JsonUtil.get_str(c, "summon"))
		"windup", "windup_broken":
			out.append(str(e["type"]))
		"end":
			if str(e.get("result", "")) == Battle.RESULT_VICTORY:
				out.append(JsonUtil.get_str(c, "victory"))

	return out.filter(func(k: String) -> bool: return not k.is_empty())


static func _cast(db: GameDatabase, skill_id: String) -> Array[String]:
	var c := _cfg(db)
	var out: Array[String] = []
	var sk := db.get_entry("skills", skill_id)
	if JsonUtil.get_array(c, "whip_skills").has(skill_id):
		out.append(JsonUtil.get_str(c, "whip"))  # 꼬리 · 붕대 · 휘감기 — 채찍 소리(맞는 소리와 겹친다)
		return out
	for v: Variant in JsonUtil.get_array(sk, "effects"):
		var fx: Dictionary = v if v is Dictionary else {}
		if JsonUtil.get_str(fx, "type") != "damage":
			continue
		if JsonUtil.get_bool(fx, "ranged"):
			out.append(JsonUtil.get_str(c, "ranged"))
		elif JsonUtil.get_str(fx, "scaling") == "magic":
			out.append(JsonUtil.get_str(JsonUtil.get_dict(c, "cast"), JsonUtil.get_str(fx, "damage_type")))
		break
	return out


static func _hit(db: GameDatabase, e: Dictionary) -> String:
	var c := _cfg(db)
	if not bool(e.get("hit", false)):
		return JsonUtil.get_str(c, "miss")
	if bool(e.get("immune", false)):
		return JsonUtil.get_str(c, "immune")
	if int(e.get("lost", e.get("amount", 0))) <= 0:
		return JsonUtil.get_str(c, "blocked")
	if bool(e.get("crit", false)):
		return JsonUtil.get_str(c, "crit")
	var t: Variant = e.get("target")
	if t is Monster and JsonUtil.get_array(c, "slime_lineages").any(func(l: Variant) -> bool: return JsonUtil.get_array((t as Monster).def, "family").has(l)):
		return JsonUtil.get_str(c, "slime")
	var dt := str(e.get("damage_type", ""))
	return JsonUtil.get_str(JsonUtil.get_dict(c, "hit"), dt, JsonUtil.get_str(c, "hit_default"))


## 상태 이름(문구 인자) → 소리 키(combat.status — 걸린 상태 id로).
static func status_key(db: GameDatabase, status_name: String) -> String:
	var map := JsonUtil.get_dict(_cfg(db), "status")
	for id: String in map:
		if JsonUtil.get_str(db.get_entry("statuses", id), "name_ko") == status_name:
			return str(map[id])
	return ""


## 아군 중 생명력이 문턱 아래인 사람이 있는가(심장 박동).
static func heart_on(db: GameDatabase, b: Battle) -> bool:
	var below := JsonUtil.get_float(_cfg(db), "heart_below", 0.3)
	for u in b.side_units(Combatant.SIDE_PARTY):
		if not u.summoned and u.actor.pool.get_ratio("hp") < below:
			return true
	return false
