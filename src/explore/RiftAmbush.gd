class_name RiftAmbush
extends RefCounted
## 균열 매복(조우 kind "ambush", 사용자 2026-10-30 "도개교 중간을 지나갈 때 화면 양옆에서 데드맨 무리들이 공격해 온다 —
## 두 무리 중 하나와 부딪치면 전투, 한 무리와 싸우면 데드맨 무리는 전부 사라진다", RF26).
## {"kind": "ambush", "trigger": [x, y, w, h], "packs": [구성, …], "from": [[x, y], …]}
##   플레이어가 trigger 칸(사각형)에 처음 들어서면 packs[i]가 from[i] 칸(화면 가장자리 밖)에 나타나 곧장 쫓아온다
##   (balance rift.ambush_alert_hours 동안은 보지 못해도 — FieldMonsters.Group.alert_until). 한 번뿐.
## 나타난 무리(tag "ambush") 하나와 전투가 끝나면(이기든 도망치든) 그 챕터의 매복 무리를 모두 걷는다(RiftRun.on_battle_end → clear).
## 아직 터지지 않은 매복은 챕터 세션(ExploreSession.ambushes)에 남는다 — 되돌아갔다 와도 그대로.


## 플레이어가 새 칸에 들어섰다. 터진 매복의 무리를 돌려준다.
static func on_step(s: ExploreSession, compose: Callable) -> Array[FieldMonsters.Group]:
	var out: Array[FieldMonsters.Group] = []
	for e: Dictionary in s.ambushes.duplicate():
		if trigger_rect(e).has_point(s.pos):
			s.ambushes.erase(e)
			out.append_array(spring(s, e, compose))
	return out


static func trigger_rect(e: Dictionary) -> Rect2i:
	var r := JsonUtil.get_array(e, "trigger")
	if r.size() < 4:
		return Rect2i()
	return Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))


static func spring(s: ExploreSession, e: Dictionary, compose: Callable) -> Array[FieldMonsters.Group]:
	var out: Array[FieldMonsters.Group] = []
	var packs := JsonUtil.get_array(e, "packs")
	var from := JsonUtil.get_array(e, "from")
	var until := s.clock.total_hours + float(s.db.bal("rift.ambush_alert_hours", 1.0))
	for i in mini(packs.size(), from.size()):
		var c: Array = from[i]
		var g := s.monsters.add_fixed(compose.call(packs[i]), Vector2i(int(c[0]), int(c[1])))
		if g == null:
			continue
		g.tag = "ambush"
		g.alert_until = until
		g.state = FieldMonsters.STATE_CHASE
		out.append(g)
	if not out.is_empty():
		s.monsters.alerted.emit(out[0])  # 쫓기 시작하는 소리(behavior alert_sfx) — 글은 없다(UI19)
	return out


## 매복 무리를 모두 걷는다(remaining = RiftRun이 아직 치우지 않은 조우 무리).
static func clear(s: ExploreSession, remaining: Array) -> void:
	for g: FieldMonsters.Group in s.monsters.groups.duplicate():
		if g.tag == "ambush":
			s.monsters.groups.erase(g)
			remaining.erase(g)
	s.monsters.changed.emit()
