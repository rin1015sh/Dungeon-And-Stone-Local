class_name MawTraps
extends RefCounted
## 아귀 입 함정(망자의 땅 — 사용자 2026-11-05 "맵 곳곳에 커다란 아귀입 함정 · 입을 벌리고 닫는 애니메이션 · 잡히면 동전 · 실패하면 목구멍 방",
## FL15): 땅에 박힌 거대한 입이 실제 초 주기로 벌어졌다 닫힌다. 벌어져 있을 때 몸이 입 안(reach)에 들어서면 입이 닫히며 잡는다 →
## 동전(CoinToss "maw" — 앞면이면 빠져나온다, 뒷면이면 삼켜진다). 삼켜지면 목구멍 방(map.anchors.marks "throat_in" — 모든 입이 같은 방)에 떨어지고
## 무작위 무리(throat_monsters 중 하나)와 바로 싸운다. 방의 힘줄 벽(요소 throat_wall — goto "maw_return")을 살펴 삼킨 입 옆으로 올라온다.
## 층 JSON "maws": {"period_sec", "open_sec", "phase_step", "reach", "cooldown_sec", "throat_monsters": [[id …] …]}. 자리 = map.anchors["maws"](FieldsRouteBuild).
## 몬스터는 잡지 않는다. 그리기 = MawView. 시간은 실제 초(탐험이 멈추면 입도 멈춘다 — ExploreSession.tick_realtime).

var def: Dictionary = {}
var cells: Array[Vector2i] = []
var phases: PackedFloat32Array = PackedFloat32Array()
var t: float = 0.0
var shut_until: PackedFloat32Array = PackedFloat32Array()  ## 잡은 뒤 이 시각(t)까지 다문 채
var busy: bool = false  ## 동전 · 삼킴 처리 중


static func build(s: ExploreSession) -> MawTraps:
	var d := JsonUtil.get_dict(s.floor_def, "maws")
	var list: Array = s.map.anchors.get("maws", [])
	if d.is_empty() or list.is_empty():
		return null
	var m := MawTraps.new()
	m.def = d
	var step := JsonUtil.get_float(d, "phase_step", 0.37)
	for q: Vector2i in list:
		m.cells.append(q)
		m.phases.append(fmod(float(m.phases.size()) * step, 1.0))
		m.shut_until.append(-1.0)
	return m


## i번째 입이 벌어진 정도 0(다묾) ~ 1(활짝). 주기 = 다문 채 → 천천히 벌어짐 → 벌어진 채(open_sec) → 탁 닫힘.
func openness(i: int) -> float:
	if t < shut_until[i]:
		return 0.0
	var period := JsonUtil.get_float(def, "period_sec", 5.0)
	var open_s := JsonUtil.get_float(def, "open_sec", 1.8)
	var u := fmod(t / period + phases[i], 1.0) * period
	var rise := period * 0.3
	var closed := period - rise - open_s - 0.25
	if u < closed:
		return 0.0
	if u < closed + rise:
		return smoothstep(0.0, 1.0, (u - closed) / rise)
	if u < closed + rise + open_s:
		return 1.0
	return 1.0 - (u - closed - rise - open_s) / 0.25  # 탁 닫힌다


## 실제 sec초를 흘리고, 벌어진 입 안에 몸이 들어섰으면 잡는다.
func tick(s: ExploreSession, sec: float) -> void:
	if sec <= 0.0:
		return
	t += sec
	if busy or s.player.dead or s.in_combat:
		return
	var reach := JsonUtil.get_float(def, "reach", 0.85)
	for i in cells.size():
		if openness(i) > 0.6 and s.fpos.distance_to(Vector2(cells[i]) + Vector2(0.5, 0.5)) <= reach:
			_catch(s, i)
			return


func _catch(s: ExploreSession, i: int) -> void:
	busy = true
	shut_until[i] = t + JsonUtil.get_float(def, "cooldown_sec", 4.0)
	s.fx.emit("snap", cells[i], -1)
	s.message.emit("explore.maw_caught", {}, "danger")
	s.sound.emit("maw_snap", cells[i])
	var heads := CoinToss.flip(s.db, s.rng, "maw")
	s.toss(heads, func() -> void: _resolve(s, i, heads))


func _resolve(s: ExploreSession, i: int, heads: bool) -> void:
	busy = false
	if s.ended:
		return
	if heads:
		s.message.emit("explore.maw_escape", {}, "good")
		var out := _outside(s, cells[i])
		if out.x >= 0:
			s.relocate(out)
		return
	swallow(s, i)


## 삼켜진다: 돌아올 자리(입 옆)를 표시하고 목구멍 방에 떨어뜨린 뒤 무작위 무리와 싸운다.
func swallow(s: ExploreSession, i: int) -> void:
	var marks: Dictionary = s.map.anchors.get("marks", {})
	if not marks.has("throat_in"):
		return
	marks["maw_return"] = _outside(s, cells[i])
	s.message.emit("explore.maw_swallowed", {}, "danger")
	s.relocate(marks["throat_in"])
	var pool := JsonUtil.get_array(def, "throat_monsters")
	if pool.is_empty() or not s.monsters_enabled:
		return
	var ids: Array = pool[s.rng.randi_range(0, pool.size() - 1)]
	var g := s.monsters.add_fixed(ids, s.pos + Vector2i(0, -2))
	if g != null:
		s.engage(g, false)


## 입 둘레(2칸 밖)의 걸을 수 있는 칸 — 빠져나오거나 올라올 자리.
static func _outside(s: ExploreSession, c: Vector2i) -> Vector2i:
	for r in [2, 3]:
		for d: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var q: Vector2i = c + d * r
			if s.map.is_walkable(q) and s.monsters.group_at(q) == null:
				return q
	return Vector2i(-1, -1)
