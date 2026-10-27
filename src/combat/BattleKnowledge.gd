class_name BattleKnowledge
extends RefCounted
## 전투가 플레이어의 정보(Knowledge)를 채운다: 마주친 몬스터는 "봤다",
## 어떤 피해 유형으로 쳐 본 결과(약점·면역·저항)는 그 유형의 상성을 안다. 상태이상(듣지 않음·거는 것)은 Passives.try_status가 적는다.
## 알게 된 것은 전투 중에 알리지 않는다 — 도감 B에서만 보인다(사용자 2026-10-27, UI22).


static func on_start(b: Battle) -> void:
	for p in b.units:
		if not p.actor is PlayerCharacter:
			continue
		for e in b.units:
			if e.actor is Monster:
				(p.actor as PlayerCharacter).knowledge.see((e.actor as Monster).monster_id)


## 전투 중에 새로 나타난 몬스터(증원·소환)도 "봤다".
static func see(b: Battle, u: Combatant) -> void:
	if not u.actor is Monster:
		return
	for p in b.units:
		if p.actor is PlayerCharacter:
			(p.actor as PlayerCharacter).knowledge.see((u.actor as Monster).monster_id)


## 피해 사건 하나(공격자 c): 명중했으면 그 유형의 상성을 기록한다.
static func on_damage(b: Battle, c: Combatant, e: Dictionary) -> void:
	var target: Variant = e.get("target")
	if not c.actor is PlayerCharacter or not target is Monster or not bool(e.get("hit", false)):
		return
	var m := target as Monster
	var dtype := str(e.get("damage_type", ""))
	var aff := float(e.get("affinity", 1.0))
	(c.actor as PlayerCharacter).knowledge.learn_affinity(m.monster_id, dtype, aff)


## 알아낸 상태이상 목록을 이름으로("중독, 공포"). 모르면 "???".
static func describe_statuses(db: GameDatabase, ids: Array[String]) -> String:
	var names := PackedStringArray()
	for id in ids:
		names.append(DataNames.entry(db, "statuses", id))
	return ", ".join(names) if not names.is_empty() else Strings.t("knowledge.unknown")


## 알아낸 상성을 문장으로("화염 약점 ×1.5, 독 면역"). 모르면 "???".
static func describe_affinities(db: GameDatabase, k: Knowledge, monster_id: String) -> String:
	var text := describe(db, k.affinities(monster_id))
	return text if not text.is_empty() else Strings.t("knowledge.unknown")


## 상성 {유형: 배율} 중 보통(×1)이 아닌 것만 문장으로. 없으면 "".
static func describe(db: GameDatabase, aff: Dictionary) -> String:
	var parts := PackedStringArray()
	for t: String in aff:
		var v := float(aff[t])
		if is_equal_approx(v, 1.0):
			continue
		var key := "knowledge.aff_immune" if v <= 0.0 else ("knowledge.aff_weak" if v > 1.0 else "knowledge.aff_resist")
		parts.append(Strings.t(key, {"type": DataNames.tag(db, "damage_types", t), "mult": "%.1f" % v}))
	return ", ".join(parts)
