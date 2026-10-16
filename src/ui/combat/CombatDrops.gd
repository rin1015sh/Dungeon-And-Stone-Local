class_name CombatDrops
extends RefCounted
## 전투가 끝난 뒤 무대에 남은 드롭을 하나씩 처리한다(사용자 결정 2026-10-16 — ASSUMPTIONS UI13):
##   몬스터가 쓰러진 자리에 정수·전리품(DropMark)이 보이고, 차례로 그 위에 작은 창 "○○ — 획득할까?" [획득한다 / 두고 간다].
##   획득 → 받을 사람이 둘 이상이면 "누가 받을까?"(못 받는 사람은 흐리고 이유 — Backspace는 앞 질문으로), 하나면 바로 그 사람.
##   받을 수 있는 사람이 없으면(정수 슬롯·겹침) 묻지 않고 두고 간다. 실제로 주고 두는 일은 taker(drop, pc)·leaver(drop, reason).


## 드롭을 다 처리하고 안내 메시지 목록을 돌려준다. spots = 쓰러진 순서(killed)대로의 무대 좌표.
static func collect(screen: Control, stage: Control, db: GameDatabase, drops: Array[Dictionary], spots: Array[Vector2],
		takers: Array[PlayerCharacter], taker: Callable, leaver: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var marks: Array[DropMark] = []
	var per_spot := {}
	for d in drops:
		var k := int(d.get("slot", -1))
		var n := int(per_spot.get(k, 0))
		per_spot[k] = n + 1
		var at: Vector2 = spots[k] if k >= 0 and k < spots.size() else Vector2(stage.size.x * 0.5, stage.size.y * 0.6)
		var m := DropMark.new()
		m.setup(db, d)
		stage.add_child(m)
		var gap := m.size.x * 1.05
		m.position = at - Vector2(m.size.x * 0.5, m.size.y * UiTheme.ui_float("drop_mark_lift", 2.0)) + Vector2((n - 0.5 * float(_count(drops, k) - 1)) * gap, 0.0)  # 결과 칸 위로 떠 있게
		marks.append(m)
	for i in drops.size():
		if not screen.is_inside_tree():
			return out
		marks[i].set_current(true)
		var near := marks[i].global_position - screen.global_position + Vector2(marks[i].size.x * 0.5, 0.0)
		var msg: Dictionary = await _offer(screen, db, drops[i], takers, taker, leaver, near)
		if not msg.is_empty():
			out.append(msg)
		if is_instance_valid(marks[i]):
			marks[i].vanish()
	return out


static func _count(drops: Array[Dictionary], slot: int) -> int:
	var n := 0
	for d in drops:
		if int(d.get("slot", -1)) == slot:
			n += 1
	return n


static func _offer(screen: Control, db: GameDatabase, d: Dictionary, takers: Array[PlayerCharacter], taker: Callable, leaver: Callable, near: Vector2) -> Dictionary:
	var able: Array[PlayerCharacter] = []
	var first_reason := ""
	for pc in takers:
		var why := DropPickup.check(d, pc)
		if why.is_empty():
			able.append(pc)
		elif first_reason.is_empty():
			first_reason = why
	if able.is_empty():
		return leaver.call(d, first_reason if not first_reason.is_empty() else "combat.drop_cannot")
	var ask := Strings.t("combat.drop_ask", {"what": DropPickup.label(db, d)})
	var yes_no: Array[Dictionary] = [{"text": Strings.t("combat.drop_take")}, {"text": Strings.t("combat.drop_leave")}]
	while true:
		var pick: int = await ChoicePopup.ask(screen, ask, yes_no, false, near)
		if pick != 0:
			return leaver.call(d, "")
		if takers.size() == 1:
			return taker.call(d, able[0])
		var opts: Array[Dictionary] = []
		for pc in takers:
			var why := DropPickup.check(d, pc)
			var warn := "" if not why.is_empty() or DropPickup.fits(d, pc) else Strings.t("combat.drop_no_room")
			opts.append({"text": pc.display_name, "enabled": why.is_empty(), "desc": Strings.t(why) if not why.is_empty() else warn})
		var w: int = await ChoicePopup.ask(screen, Strings.t("combat.drop_who"), opts, true, near)
		if w >= 0:
			return taker.call(d, takers[w])
	return {}
