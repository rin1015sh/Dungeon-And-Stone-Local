class_name BattleRev
extends RefCounted
## 기세(피어 앤 헝거 2식 — 사용자 결정 2026-11-02, C20). 아군(직접 조종하는 사람 — 소환수 빼고)만 쓴다.
## 방어하면 guard_bonus개, 기세를 얹지 않은 기본 공격을 하면 basic_bonus개 차고 max개까지(자기 차례 시작의 per_turn은 0 — 사용자 2026-11-02)
## (Combatant.rev — 전투가 끝나면 사라진다).
## 피해를 주는 스킬(기본 공격 포함)에 n개를 얹으면 위력 × power[n]. max개를 모두 얹은 기본 공격은 basic_full_hits번 × basic_full_power.
## 피해가 없는 스킬·방어·아이템·도주에는 얹지 않는다(행동의 "rev"를 무시하고 쓰지도 않는다).
## 정수 스킬에 기세 비용을 새로 붙이지 않는다(C15 — 위력을 줄이는 셈).


static func cap(db: GameDatabase) -> int:
	return int(db.bal("combat.rev.max", 3))


## 기세를 쓰는 사람인가(아군 중 직접 조종하는 사람).
static func uses_rev(b: Battle, c: Combatant) -> bool:
	return c != null and b.is_player_controlled(c)


static func charge(b: Battle, c: Combatant, n: int) -> void:
	if n > 0 and uses_rev(b, c):
		c.rev = mini(cap(b.db), c.rev + n)


## 자기 차례가 시작됐다(Battle.next_turn).
static func on_turn_start(b: Battle, c: Combatant) -> void:
	charge(b, c, int(b.db.bal("combat.rev.per_turn", 0)))


static func on_guard(b: Battle, c: Combatant) -> void:
	charge(b, c, int(b.db.bal("combat.rev.guard_bonus", 1)))


## 기세를 얹지 않은 기본 공격을 했다(Battle._use_skill — 맞든 빗나가든).
static func on_basic(b: Battle, c: Combatant) -> void:
	charge(b, c, int(b.db.bal("combat.rev.basic_bonus", 1)))


## 행동을 미리 정할 때 얹을 수 있는 개수: 지금 차례인 사람은 가진 만큼, 차례가 아직 안 온 사람은 그 차례에 찰 것까지.
static func plan_max(b: Battle, c: Combatant) -> int:
	if not uses_rev(b, c):
		return 0
	var pending := 0 if c == b.current else int(b.db.bal("combat.rev.per_turn", 0))
	return mini(cap(b.db), c.rev + pending)


## 이 스킬에 기세를 얹을 수 있는가(피해를 준다).
static func applies(sk: Dictionary) -> bool:
	for e: Variant in JsonUtil.get_array(sk, "effects"):
		if e is Dictionary and JsonUtil.get_str(e as Dictionary, "type") == "damage":
			return true
	return false


## n개 얹었을 때의 위력 배율.
static func power(db: GameDatabase, n: int) -> float:
	var table: Variant = db.bal("combat.rev.power", [])
	if not table is Array or (table as Array).is_empty():
		return 1.0
	var arr: Array = table
	return float(arr[clampi(n, 0, arr.size() - 1)])


## 이 행동이 몇 번 치는가(Battle._use_skill이 use()보다 먼저 부른다 — use()가 기세를 쓰기 전에 본다): max개를 모두 얹은 기본 공격 = basic_full_hits번, 그 밖은 1번.
## 효과를 겹쳐 한 번에 넣지 않고 Battle이 타격마다 따로 돌린다 — 화면이 모션·피해 숫자를 한 번씩 따로 보인다(사용자 2026-11-03).
static func strikes(b: Battle, c: Combatant, skill_id: String, sk: Dictionary, want: int) -> int:
	if skill_id == Battle.BASIC_ATTACK and mini(want, c.rev) >= cap(b.db) and uses_rev(b, c) and applies(sk):
		return maxi(1, int(b.db.bal("combat.rev.basic_full_hits", 2)))
	return 1


## 스킬을 쓸 때(Battle._use_skill): want개(가진 만큼으로 줄인다)를 쓰고 효과 목록을 바꿔 돌려준다.
static func use(b: Battle, c: Combatant, skill_id: String, sk: Dictionary, fx: Array, want: int) -> Array:
	var n := mini(want, c.rev)
	if n <= 0 or not uses_rev(b, c) or not applies(sk):
		return fx
	c.rev -= n
	if skill_id == Battle.BASIC_ATTACK and n >= cap(b.db):
		return BattleTargets.boosted(fx, {"power_mult": float(b.db.bal("combat.rev.basic_full_power", 1.0)), "ignore_defense": false})  # 한 타격분 — 타격 수는 strikes()
	return BattleTargets.boosted(fx, {"power_mult": power(b.db, n), "ignore_defense": false})
