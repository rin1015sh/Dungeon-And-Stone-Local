class_name BattleKnowledge
extends RefCounted
## 전투가 플레이어의 정보(Knowledge)를 채운다: 마주친 몬스터는 "봤다",
## 어떤 피해 유형으로 쳐 본 결과(약점·면역·저항)는 그 유형의 상성을 안다.


static func on_start(b: Battle) -> void:
	for p in b.units:
		if not p.actor is PlayerCharacter:
			continue
		for e in b.units:
			if e.actor is Monster:
				(p.actor as PlayerCharacter).knowledge.see((e.actor as Monster).monster_id)


## 피해 사건 하나(공격자 c): 명중했으면 그 유형의 상성을 기록하고, 처음 알게 된 약점·면역·저항은 알린다.
static func on_damage(b: Battle, c: Combatant, e: Dictionary) -> void:
	var target: Variant = e.get("target")
	if not c.actor is PlayerCharacter or not target is Monster or not bool(e.get("hit", false)):
		return
	var m := target as Monster
	var dtype := str(e.get("damage_type", ""))
	var aff := float(e.get("affinity", 1.0))
	var first := (c.actor as PlayerCharacter).knowledge.learn_affinity(m.monster_id, dtype, aff)
	if first and not is_equal_approx(aff, 1.0):
		var kind := "immune" if aff <= 0.0 else ("weak" if aff > 1.0 else "resist")
		b.message.emit("knowledge.learned_" + kind, {"name": DataNames.entry(b.db, "monsters", m.monster_id),
			"type": DataNames.tag(b.db, "damage_types", dtype)}, "system")


## 알아낸 상성을 문장으로("화염 약점 ×1.5, 독 면역"). 모르면 "???".
static func describe_affinities(db: GameDatabase, k: Knowledge, monster_id: String) -> String:
	var parts := PackedStringArray()
	var aff := k.affinities(monster_id)
	for t: String in aff:
		var v := float(aff[t])
		if is_equal_approx(v, 1.0):
			continue
		var key := "knowledge.aff_immune" if v <= 0.0 else ("knowledge.aff_weak" if v > 1.0 else "knowledge.aff_resist")
		parts.append(Strings.t(key, {"type": DataNames.tag(db, "damage_types", t), "mult": "%.1f" % v}))
	return ", ".join(parts) if not parts.is_empty() else Strings.t("knowledge.unknown")
