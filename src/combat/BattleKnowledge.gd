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


## 전투 중에 새로 나타난 몬스터(증원·소환)도 "봤다".
static func see(b: Battle, u: Combatant) -> void:
	if not u.actor is Monster:
		return
	for p in b.units:
		if p.actor is PlayerCharacter:
			(p.actor as PlayerCharacter).knowledge.see((u.actor as Monster).monster_id)


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


## 이 전투의 아군 탐험가들의 기록(전투 화면이 지식을 보일 때 — 누가 알든 파티가 안다).
static func knowers(b: Battle) -> Array[Knowledge]:
	var out: Array[Knowledge] = []
	for u in b.units:
		if u.side == Combatant.SIDE_PARTY and u.actor is PlayerCharacter:
			out.append((u.actor as PlayerCharacter).knowledge)
	return out


## 누군가 이 몬스터를 조사했는가(생명력이 보인다 — 2026-10-22 지식이 남는 전투, ASSUMPTIONS UI22).
static func party_knows_stats(ks: Array[Knowledge], monster_id: String) -> bool:
	for k in ks:
		if k.knows_stats(monster_id):
			return true
	return false


## 파티가 알아낸 상성을 합친 것 {피해 유형: 배율}.
static func party_affinities(ks: Array[Knowledge], monster_id: String) -> Dictionary:
	var out := {}
	for k in ks:
		out.merge(k.affinities(monster_id), true)
	return out


## 알아낸 상성을 문장으로("화염 약점 ×1.5, 독 면역"). 모르면 "???".
static func describe_affinities(db: GameDatabase, k: Knowledge, monster_id: String) -> String:
	var text := describe(db, k.affinities(monster_id))
	return text if not text.is_empty() else Strings.t("knowledge.unknown")


## 상성 {유형: 배율} 중 보통(×1)이 아닌 것만 문장으로. 없으면 "". short = 전투 무대용 짧은 꼴("화염 ×1.5 · 독 면역").
static func describe(db: GameDatabase, aff: Dictionary, short: bool = false) -> String:
	var parts := PackedStringArray()
	for t: String in aff:
		var v := float(aff[t])
		if is_equal_approx(v, 1.0):
			continue
		var key := "knowledge.aff_immune" if v <= 0.0 else ("knowledge.aff_weak" if v > 1.0 else "knowledge.aff_resist")
		if short:
			key = "knowledge.stage_immune" if v <= 0.0 else "knowledge.stage_mult"
		parts.append(Strings.t(key, {"type": DataNames.tag(db, "damage_types", t), "mult": "%.1f" % v}))
	return (" · " if short else ", ").join(parts)
