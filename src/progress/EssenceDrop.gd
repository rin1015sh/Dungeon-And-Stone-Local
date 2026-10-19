class_name EssenceDrop
extends RefCounted
## 정수 드롭(docs/PROMPT_FLOOR1_V2.md §3): 몬스터를 쓰러뜨리면 확률로 정수 하나를 뱉는다.
##   확률: 몬스터 essence_drops가 있으면 그 값, 없으면 rank(무등급·중간 보스·수호자) → 등급별 확률.
##         balance essence.drop_mode가 "original"이면 일반 몬스터는 drop_chance_original. 균열 안이면 × rift_mult.
##   정수 = data/essences에서 source_monster가 그 몬스터인 항목. 색은 actives 중 하나(수호자급이면 무지갯빛).
##   스탯(stats)·자원 최대치(resources — 생명력)는 정수마다 고정값이다(수호자 정수 × guardian_stat_mult, 반올림 — J13).
## 정수 사례(instance): {"essence": id, "color": 색 id, "stats": {스탯 id: 값}, "resources": {자원 id: 최대치 증가}}

const GUARDIAN_RANKS := ["guardian", "variant_guardian"]


## 몬스터 하나의 정수 드롭. 없으면 {}. mult: 확률 배율(수수께끼 문지기 약화 ×2).
static func roll(db: GameDatabase, monster_id: String, rng: Rng, in_rift: bool = false, mult: float = 1.0, color: String = "") -> Dictionary:
	var def := db.get_entry("monsters", monster_id)
	var explicit := JsonUtil.get_array(def, "essence_drops")
	if not explicit.is_empty():
		for d: Variant in explicit:
			var dd: Dictionary = d if d is Dictionary else {}
			if db.has_entry("essences", JsonUtil.get_str(dd, "essence")) and rng.chance(JsonUtil.get_float(dd, "chance") * mult):
				return make(db, JsonUtil.get_str(dd, "essence"), color, rng, _is_guardian(def))
		return {}
	var essence_id := essence_of_monster(db, monster_id)
	if essence_id.is_empty() or not rng.chance(minf(1.0, drop_chance(db, def, in_rift) * mult)):
		return {}
	return make(db, essence_id, color, rng, _is_guardian(def))


## 몬스터 정의의 정수 드롭 확률.
static func drop_chance(db: GameDatabase, monster_def: Dictionary, in_rift: bool = false) -> float:
	var rank := JsonUtil.get_str(monster_def, "rank", "normal")
	var by_rank: Dictionary = db.bal("essence.drop_chance_by_rank", {})
	if by_rank.has(rank):
		return float(by_rank[rank])
	var p := 0.0
	if str(db.bal("essence.drop_mode", "game")) == "original":
		p = float(db.bal("essence.drop_chance_original", 0.0001))
	else:
		var by_grade: Dictionary = db.bal("essence.drop_chance_by_grade", {})
		p = float(by_grade.get(str(JsonUtil.get_int(monster_def, "grade", 9)), 0.0))
	if in_rift:
		p *= float(db.bal("essence.rift_mult", 4))
	return clampf(p, 0.0, 1.0)


## 그 몬스터에게서 나오는 정수 id(없으면 "").
static func essence_of_monster(db: GameDatabase, monster_id: String) -> String:
	var col := db.get_collection("essences")
	var ids: Array = col.keys()
	ids.sort()
	for id: Variant in ids:
		if JsonUtil.get_str(col[id], "source_monster") == monster_id:
			return str(id)
	return ""


## 정수 사례를 만든다. color가 ""이면 무작위(guardian이면 무지갯빛).
static func make(db: GameDatabase, essence_id: String, color: String, rng: Rng, guardian: bool = false) -> Dictionary:
	var def := db.get_entry("essences", essence_id)
	var c := color
	if guardian:
		c = str(db.bal("essence.guardian_color", "rainbow"))
	elif c.is_empty():
		var colors: Array = []
		for a: Variant in JsonUtil.get_array(def, "actives"):
			colors.append(JsonUtil.get_str(a if a is Dictionary else {}, "color"))
		c = str(rng.pick(colors)) if not colors.is_empty() else ""
	return {"essence": essence_id, "color": c, "stats": values(db, JsonUtil.get_dict(def, "stats"), guardian),
		"resources": values(db, JsonUtil.get_dict(def, "resources"), guardian)}


## 정수 정의의 고정값(stats·resources)을 사례에 담는다. 수호자면 × guardian_stat_mult(반올림).
static func values(db: GameDatabase, fixed: Dictionary, guardian: bool = false) -> Dictionary:
	var mult := float(db.bal("essence.guardian_stat_mult", 1.5)) if guardian else 1.0
	var out := {}
	for k: Variant in fixed:
		out[str(k)] = roundi(float(fixed[k]) * mult)
	return out


static func _is_guardian(monster_def: Dictionary) -> bool:
	return JsonUtil.get_str(monster_def, "rank", "normal") in GUARDIAN_RANKS
