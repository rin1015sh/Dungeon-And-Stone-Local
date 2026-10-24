class_name PlanOrder
extends RefCounted
## 행동 정하기(피어 앤 헝거식 — 아군 차례가 오면 아직 정하지 않은 아군의 행동을 한꺼번에 정한다)에 들어갈 사람.
## 지금 차례인 사람이 맨 먼저, 그다음 정해 둔 행동이 없는 다른 아군(파티 순). 정해 둔 행동이 있는 사람은 빠진다 —
## 그래서 민첩이 빨라 다른 아군보다 먼저 한 번 더 오는 사람(추가 차례)은 혼자 정한다(C12).


static func who(b: Battle, first: Combatant, planned: Dictionary) -> Array[Combatant]:
	var out: Array[Combatant] = [first]
	for u in b.side_units(Combatant.SIDE_PARTY):
		if u != first and b.is_player_controlled(u) and u.is_active() and not planned.has(u):
			out.append(u)
	return out
