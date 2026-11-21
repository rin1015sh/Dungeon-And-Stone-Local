class_name RegretMasks
extends RefCounted
## 후회의 군주 탈 순서(plans/expansion_f1_3_B §6-4) — 순수 로직. 페이즈는 데이터 순서(p1~p5 — 생명력 20%마다)이고,
## 페이즈마다 어느 탈이 앞에 오는지를 여기서 정한다: 부른 제단의 길 탈(액터 메타 LEAD — LordWatch.prepare_battle)이 맨 앞,
## 나머지 탈(pattern_params.masks)은 전투 난수로 섞고, 마지막 페이즈는 민낯(FACE). 처음 물을 때 정해 memo에 둔다.

const LEAD := "regret_lead_mask"
const FACE := "face"


static func order(b: Battle, c: Combatant) -> Array:
	if c.memo.has("masks"):
		return c.memo["masks"]
	var rest: Array = JsonUtil.get_array(BossHooks.params(c), "masks").duplicate()
	var lead := str(c.actor.get_meta(LEAD, ""))
	var out: Array = []
	if rest.has(lead):
		rest.erase(lead)
		out.append(lead)
	b.rng.shuffle(rest)
	out.append_array(rest)
	out.append(FACE)
	c.memo["masks"] = out
	return out


## 지금 페이즈의 탈(페이즈 전이면 첫 탈).
static func current(b: Battle, c: Combatant) -> String:
	var ord := order(b, c)
	var i := phase_index(c)
	return str(ord[clampi(i, 0, ord.size() - 1)])


static func phase_index(c: Combatant) -> int:
	var phases := JsonUtil.get_array(BossHooks._def(c), "phases")
	for i in phases.size():
		if JsonUtil.get_str(phases[i], "id") == str(c.memo.get("phase", "")):
			return i
	return 0
