extends "res://src/combat/patterns/guardian.gd"
## 후회의 군주(plans/expansion_f1_3_B §6-4): 범용 수호자 패턴 + 탈 넷. 페이즈(생명력 20%마다)에 들어설 때 새로 앞에 온 탈의 문구,
## 탈이 깨질 때(summon_on — 몇 번째 페이즈로 넘어갈 때) 깨진 탈의 길 몬스터를 부른다. 탈 순서 = RegretMasks.
##   masks        ["beast", "dead", "sand", "goblin"]
##   mask_lines   {탈: 문자열 키} — 그 탈이 앞으로 돌 때(첫 탈은 intro가 대신한다 — 첫 페이즈엔 부른 제단이 아직 정해지지 않았을 수 있다)
##   mask_summons {탈: [몬스터 id …]} · summon_on [페이즈 번호(0부터)] — 그 페이즈로 넘어갈 때 앞 탈의 몬스터
## 바퀴가 끝날 때마다 그 바퀴에 받은 피해를 액터 메타(rewind.gd TAKEN)에 적는다 — 민낯의 되감기가 그 절반을 되돌린다.

const Rewind := preload("res://src/combat/effects/rewind.gd")


func on_round_end(b: Battle, c: Combatant, skipped: bool = false) -> void:
	super(b, c, skipped)
	var hp := c.actor.pool.get_current("hp")
	c.actor.set_meta(Rewind.TAKEN, maxf(0.0, float(c.memo.get("hp_mark", hp)) - hp))
	c.memo["hp_mark"] = hp


func on_phase(b: Battle, c: Combatant, _ph: Dictionary) -> void:
	var i := RegretMasks.phase_index(c)
	if i <= 0:
		return
	var p := BossHooks.params(c)
	var ord := RegretMasks.order(b, c)
	var now := str(ord[clampi(i, 0, ord.size() - 1)])
	var line := JsonUtil.get_str(JsonUtil.get_dict(p, "mask_lines"), now)
	if not line.is_empty():
		b.message.emit(line, {"name": c.label()}, "danger")
	if JsonUtil.get_array(p, "summon_on").has(float(i)) or JsonUtil.get_array(p, "summon_on").has(i):
		var broke := str(ord[i - 1])
		for mid: Variant in JsonUtil.get_array(JsonUtil.get_dict(p, "mask_summons"), broke):
			BossHooks.apply_effects(b, c, c, [{"type": "summon", "monster": str(mid)}])
