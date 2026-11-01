class_name MonsterView
extends Node2D
## 탐험 맵의 무리 그림. 노드 원점 = 앞장선 한 마리의 발(무리 자리 — y 정렬 기준).
## 무리의 모든 마리를 따로 그린다(PackMember — 걷기 시트·한 장 그림·보스 기다리는 자세): 앞장선 한 마리 뒤로 나머지가 두 줄로 따라 걷고,
## 방향을 틀면 천천히 따라 돈다(render.json view.pack). 몇 마리인지·무슨 몬스터인지 그림으로 보인다 — ×N 표시는 없다(사용자 2026-10-26).
## 몬스터 무리 = monster_ids 마리마다 그 몬스터 그림, 보스 방(group.boss)은 보스를 기다리는 자세로 앞에.
## 탐험가 무리 = 사람 몸 시트를 members 마리(약탈자 = render.json view.raider_sprite 두건·망토, 없으면 종족 시트에 raider_tint 색).

var group: FieldMonsters.Group
var facing: Vector2i = Vector2i(-1, 0)

var _db: GameDatabase
var _members: Array[PackMember] = []
var _ids: Array[String] = []          ## 그림을 만든 구성(바뀌면 다시 만든다 — 전투 뒤 남은 마리)
var _offsets: Array[Vector2] = []     ## 마리마다 지금 자리(노드 좌표 — 목표 자리로 천천히 따라간다)
var _heading: Vector2 = Vector2(0, 1) ## 걸어가는 쪽(월드)
var _spacing: float = 20.0
var _side: float = 16.0
var _follow: float = 6.0
var _step: float = 0.13
var _walk_t: float = 0.0
var _still: float = 1.0
var _last_pos: Vector2 = Vector2.INF
var _up: bool = false
var _settled: bool = false
var _rise_sec: float = 0.0  ## 일어서는 데 걸리는 시간(0 = 일어서는 중이 아님 — rise())


func setup(p_group: FieldMonsters.Group, db: GameDatabase) -> void:
	group = p_group
	_db = db
	var pack := JsonUtil.get_dict(JsonUtil.get_dict(db.render, "view"), "pack")
	_spacing = JsonUtil.get_float(pack, "spacing_px", 20.0)
	_side = JsonUtil.get_float(pack, "side_px", 16.0)
	_follow = JsonUtil.get_float(pack, "follow_rate", 6.0)
	_step = JsonUtil.get_float(pack, "step_offset_sec", 0.13)
	_build()


## 구성이 바뀌었으면(전투 뒤 남은 마리) 그림을 다시 만든다.
func refresh() -> void:
	if group.monster_ids != _ids or (not group.party.is_empty() and _members.size() != _party_count()):
		_build()


func _party_count() -> int:
	return maxi(1, int(group.party.get("members", group.monster_ids.size())))


func _build() -> void:
	_ids = group.monster_ids.duplicate()
	_members.clear()
	if not group.party.is_empty():
		var view := JsonUtil.get_dict(_db.render, "view")
		var tint := Color.WHITE
		var sheet: ActorSheet = null
		if str(group.party.get("kind")) == "raider":  # 약탈자 = 두건·망토 시트, 없으면 종족 시트에 색만
			sheet = ActorSheet.load_for(_db.render, JsonUtil.get_str(view, "raider_sprite"))
			if sheet == null:
				tint = Color.from_string(JsonUtil.get_str(view, "raider_tint", "#b0a090"), Color.WHITE)
		if sheet == null:
			sheet = ActorSheet.load_for(_db.render, JsonUtil.get_str(_db.get_entry("races", str(group.party.get("look", "human"))), "sprite"))
		for i in _party_count():
			_members.append(PackMember.for_sheet(_db, sheet, tint))
	else:
		var order: Array[String] = group.monster_ids.duplicate()
		if not group.boss.is_empty():  # 보스가 앞에(기다리는 자세)
			order.erase(group.boss)
			order.push_front(group.boss)
		for i in order.size():
			_members.append(PackMember.for_monster(_db, order[i], i == 0 and not group.boss.is_empty()))
		if group.awake and not _members.is_empty():
			_members[0].rise_t = 1.0  # 이미 일어선 보스(전투에서 도망친 뒤 등)
	_offsets.resize(_members.size())
	for i in _members.size():
		_offsets[i] = _target(i)
	queue_redraw()


## i번째 마리의 대형 자리(노드 좌표): 0 = 앞장, 나머지는 걷는 쪽 뒤로 두 마리씩 줄을 짓는다(가운데를 비워 엇갈리게).
func _target(i: int) -> Vector2:
	if i == 0:
		return Vector2.ZERO
	var back := -_heading.normalized()
	var perp := Vector2(-back.y, back.x)
	var row := (i + 1) / 2
	var side := -1.0 if i % 2 == 1 else 1.0
	if _members.size() == 2:
		side = 0.35
	var k := _unit()
	return back * row * _spacing * k + perp * side * _side * k


## 큰 몬스터가 섞이면 간격을 넓힌다(사람 몸 시트 폭 36px = 1).
func _unit() -> float:
	var w := 0.0
	for m in _members:
		w = maxf(w, m.size().x)
	return clampf(w / 36.0, 1.0, 2.5)


## 멈춰 있을 때 바라보는 쪽: 적은 실제로 보는 쪽(group.facing — 시야각 판정과 같다), 다른 탐험가는 플레이어 쪽.
func face_toward(target: Vector2) -> void:
	if _still >= 0.12:
		_set_facing(group.facing if group.hostile() else target - position)


## 방향(월드) → 4방향 중 큰 쪽(옆모습을 조금 더 — ActorSheet.row_for). 한 장 그림은 좌우만 쓴다.
func _set_facing(d: Vector2) -> void:
	if d.length() < 0.01:
		return
	var f := Vector2i(int(signf(d.x)), 0) if absf(d.x) >= absf(d.y) * 0.8 else Vector2i(0, int(signf(d.y)))
	if f != facing:
		facing = f
		queue_redraw()


## 보스가 일어선다(등장 연출 — BossReveal, V22): sec초 동안 일어서는 칸을 돈다. 그 뒤로는 선 채(Group.awake).
func rise(sec: float) -> void:
	group.awake = true
	if _members.is_empty() or _members[0].rise_tex == null:
		return
	_members[0].rise_t = 0.0
	_rise_sec = maxf(0.01, sec)
	queue_redraw()


func _process(delta: float) -> void:
	if _rise_sec > 0.0 and not _members.is_empty():
		var m := _members[0]
		m.rise_t = minf(1.0, m.rise_t + delta / _rise_sec)
		if m.rise_t >= 1.0:
			_rise_sec = 0.0
		queue_redraw()
	if position != _last_pos and _last_pos != Vector2.INF:
		var d := position - _last_pos
		_set_facing(d)
		_heading = _heading.lerp(d.normalized(), clampf(delta * _follow, 0.0, 1.0)).normalized() if d.length() > 0.01 else _heading
		_up = d.y < -0.01 and absf(d.y) > absf(d.x)
		_walk_t += delta
		_still = 0.0
		_settled = false
	elif _still < 0.2:
		_still += delta
	var moved := false
	if not _settled:
		var done := true
		for i in _offsets.size():
			var t := _target(i)
			_offsets[i] = _offsets[i].lerp(t, clampf(delta * _follow, 0.0, 1.0))
			done = done and _offsets[i].distance_to(t) < 0.5
		_settled = done and _still >= 0.12
		moved = true
	if moved or _still < 0.2:
		queue_redraw()
	_last_pos = position


func _draw() -> void:
	var order := range(_members.size())
	order.sort_custom(func(a: int, b: int) -> bool: return _offsets[a].y < _offsets[b].y)  # 뒤(위)에 선 마리부터
	var walking := _still < 0.12
	for i: int in order:
		_members[i].draw(self, _offsets[i], facing, _walk_t + i * _step, walking, _up)
