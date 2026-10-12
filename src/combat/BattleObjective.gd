class_name BattleObjective
extends RefCounted
## 전투 목표(Battle.objective, 균열 생존 웨이브 — 명세 §9.1 "6라운드 생존"):
##   {"survive_rounds": 6, "reinforce": {"monsters": [..], "count": [1, 2]}}
## 라운드 = 아군 맨 앞(등록 순서가 가장 이른 살아 있는) 참가자의 차례 하나. 라운드가 끝날 때마다 적 진영에 증원,
## survive_rounds를 버티면 적이 남아 있어도 승리(Battle.finish). 적을 먼저 다 쓰러뜨려도 승리.


static func after_turn(b: Battle, c: Combatant) -> void:
	if b.objective.is_empty() or not b.result.is_empty() or c != _leader(b):
		return
	var r := int(b.objective.get("round", 0)) + 1
	b.objective["round"] = r
	var need := JsonUtil.get_int(b.objective, "survive_rounds", 0)
	if need > 0 and r >= need:
		b.message.emit("combat.survived", {"rounds": r}, "good")
		b.finish(Battle.RESULT_VICTORY)
		return
	b.message.emit("combat.survive_round", {"round": r, "total": need}, "system")
	var rf := JsonUtil.get_dict(b.objective, "reinforce")
	var pool := JsonUtil.get_array(rf, "monsters")
	var cnt := JsonUtil.get_array(rf, "count")
	if pool.is_empty():
		return
	for i in b.rng.randi_range(int(cnt[0]), int(cnt[1])) if cnt.size() == 2 else 1:
		if b.side_units(Combatant.SIDE_ENEMY).size() >= int(b.db.bal("combat.max_side_units", 6)):
			break
		var m := Monster.create(b.db, str(b.rng.pick(pool)), " +")
		var u := b.add(m, Combatant.SIDE_ENEMY, JsonUtil.get_str(m.behavior(), "row", "front"))
		b.message.emit("combat.reinforce", {"monster": m.display_name}, "danger")
		b.event.emit({"type": "summon", "unit": u})


static func _leader(b: Battle) -> Combatant:
	var best: Combatant = null
	for u in b.side_units(Combatant.SIDE_PARTY):
		if best == null or u.order < best.order:
			best = u
	return best
