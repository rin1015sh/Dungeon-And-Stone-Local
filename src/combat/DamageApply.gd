class_name DamageApply
extends RefCounted
## 계산이 끝난 피해를 대상에게 실제로 입힌다(모든 피해 경로 공통 — 스킬 피해·추가 피해·반사·반격·여신의 눈물·게이지 피해):
##   보호막(barrier)이 먼저 흡수 → 쓰러질 피해면 revive_once로 버티기 → 생명력 감소 → 피해로 풀리는 상태(break_on_damage).
## 실제로 생명력이 줄어든 양을 돌려준다. 메시지는 ctx에 남긴다.


static func hurt(ctx: EffectContext, target: Actor, amount: int, origin: String, damage_type: String = "") -> int:
	if target == null or target.dead or amount <= 0:
		return 0
	var left := target.statuses.absorb(amount) if target.statuses.barrier_total() > 0.0 else amount
	if left < amount:
		ctx.say("combat.barrier_absorb", {"name": target.display_name, "amount": amount - left}, "info")
	if left <= 0:
		return 0
	var before := target.pool.get_current("hp")
	if not Passives.endure(ctx, target, left):
		target.pool.modify("hp", -float(left), origin)
	var lost := maxi(0, roundi(before - target.pool.get_current("hp")))
	if lost > 0 and not target.dead:
		for broken in target.statuses.on_damaged(damage_type):
			ctx.say("effect.status_broken", {"name": target.display_name, "status": DataNames.entry(ctx.db, "statuses", broken)}, "info")
	return lost
