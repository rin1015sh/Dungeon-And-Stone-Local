class_name BattleReserve
extends RefCounted
## 전투 중에 적 진영에 새로 나올 수 있는 몬스터(사용자 2026-10-27 "즉석에서 줄이지 말고 미리 배치를 만들라" — UI37).
## 무대(BattleStage)가 전투를 시작할 때 이 몬스터들의 자리까지 함께 정해 둔다 — 소환·분열·증원은 미리 비워 둔 자리에 선다.
## 찾는 곳: 적 몬스터 정의와 그 안에서 이름이 나오는 스킬(정의·패턴·상태 효과 어디든) — {"type": "summon", "monster"} = 그 몬스터,
## {"type": "split"} = 쓰는 몬스터 자신, 나온 몬스터도 다시 살핀다(슬라임 → 분열). 전투 목표 reinforce.monsters(증원)도.
## 순수 로직(오토로드 비의존).


## 나올 수 있는 몬스터 id(처음 나온 순서, 겹치지 않게).
static func candidates(db: GameDatabase, monster_ids: Array, objective: Dictionary = {}, horde: Array = []) -> Array[String]:
	var out: Array[String] = []
	var seen_skills := {}
	var queue: Array[String] = []
	for id: Variant in horde:  # 큰 무리의 예비대(BattleHorde)가 먼저 들어온다
		_add(db, str(id), out, queue)
	for id: Variant in monster_ids:
		if not queue.has(str(id)):
			queue.append(str(id))
	for id: Variant in JsonUtil.get_array(JsonUtil.get_dict(objective, "reinforce"), "monsters"):
		_add(db, str(id), out, queue)
	var head := 0
	while head < queue.size():
		var owner := queue[head]
		head += 1
		_scan(db, db.get_entry("monsters", owner), owner, out, queue, seen_skills)
	return out


## 처음 선 적 present(몬스터 id) 말고 비워 둘 자리 = 진영 상한(combat.max_side_units)까지, 나올 수 있는 몬스터를 돌려 가며.
static func plan(db: GameDatabase, present: Array, objective: Dictionary = {}, horde: Array = []) -> Array[String]:
	var cands := candidates(db, present, objective, horde)
	var out: Array[String] = []
	if cands.is_empty():
		return out
	for i in maxi(0, int(db.bal("combat.max_side_units", 6)) - present.size()):
		out.append(cands[i % cands.size()])
	return out


static func _scan(db: GameDatabase, v: Variant, owner: String, out: Array[String], queue: Array[String], seen: Dictionary) -> void:
	if v is Dictionary:
		var d: Dictionary = v
		match JsonUtil.get_str(d, "type"):
			"summon":
				_add(db, JsonUtil.get_str(d, "monster"), out, queue)
			"split":
				_add(db, owner, out, queue)
		for k: Variant in d:
			_scan(db, d[k], owner, out, queue, seen)
	elif v is Array:
		for x: Variant in v:
			_scan(db, x, owner, out, queue, seen)
	elif v is String and not seen.has(owner + "/" + v) and db.has_entry("skills", v):
		seen[owner + "/" + v] = true
		_scan(db, db.get_entry("skills", v), owner, out, queue, seen)


static func _add(db: GameDatabase, id: String, out: Array[String], queue: Array[String]) -> void:
	if id.is_empty() or not db.has_entry("monsters", id):
		return
	if not out.has(id):
		out.append(id)
	if not queue.has(id):
		queue.append(id)
