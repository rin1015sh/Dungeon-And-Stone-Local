class_name HealFloats
extends Node
## 전투 중 생명력이 차오르면(회복 아이템·스킬·재생·흡혈·집어삼키기 …) 그 참가자 위에 초록 "+n"을 피해 숫자처럼 띄운다
## (사용자 결정 2026-10-29 "회복되면 대화 글 대신 피해 숫자처럼 초록색으로", UI44 — 회복 문구는 render.json ui.notice.silent).
## 효과마다 사건을 따로 내지 않고 자원 묶음(ResourcePool.changed)을 지켜본다: 최대치가 그대로인데 현재치가 늘면 회복.

var _stage: BattleStage
var _seen: Dictionary = {}  # Combatant -> Vector2(현재, 최대)


func setup(stage: BattleStage) -> void:
	_stage = stage


func watch(u: Combatant) -> void:
	if _seen.has(u) or not u.actor.pool.has_resource("hp"):
		return
	_seen[u] = Vector2(u.actor.pool.get_current("hp"), u.actor.pool.get_max("hp"))
	u.actor.pool.changed.connect(_on_changed.bind(u))


func _on_changed(res: String, current: float, maximum: float, u: Combatant) -> void:
	if res != "hp":
		return
	var old: Vector2 = _seen.get(u, Vector2(current, maximum))
	_seen[u] = Vector2(current, maximum)
	if absf(maximum - old.y) > 0.001:  # 최대치가 바뀐 것(강화·약화)은 회복이 아니다
		return
	var gain := roundi(current - old.x)
	var v: BattlerView = _stage.view(u) if _stage != null else null
	if gain <= 0 or v == null or not v.is_inside_tree():
		return
	v.float_text(Strings.t("combat.float_heal", {"n": gain}), UiTheme.color("dmg_heal"), true)
