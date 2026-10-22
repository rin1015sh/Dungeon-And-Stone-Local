class_name BattleStage
extends Control
## 전투 무대(피어 앤 헝거식 — 정면에서 맞닥뜨린다): 어둠 속 바닥에 떨어진 빛 웅덩이,
## 그 위 가운데에 적이 이쪽을 보고 서고(덩치에 따라 크게, 아군 머리보다 위 — 가리지 않게, 자리 고정),
## 화면 아래쪽 앞줄에 아군이 등을 보이고 선다(다리는 아래 창에 가린다).
## 배치 수치는 render.json ui.combat_* (bottom_reserve = 아래 창 높이).

var _views: Dictionary = {}  # Combatant -> BattlerView
var _db: GameDatabase
var _slots: Dictionary = {}  # 적 Combatant -> {"x": 화면 폭 비율(발 가운데), "h": 키 / 무대 높이} — 고정 자리
var _floor_y: float = 0.0    # 적 발 높이(px) — 빛 웅덩이도 여기
var _layout_queued: bool = false
var _knowers: Array[Knowledge] = []  # 아군의 기록 — 조사한 몬스터는 생명력·알아낸 상성이 보인다(BattlerView)


func setup(db: GameDatabase, knowers: Array[Knowledge] = []) -> void:
	_db = db
	_knowers = knowers
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func() -> void:
		_slots.clear()  # 화면 크기가 바뀌면 자리를 새로 정한다(처음 크기가 정해질 때 포함)
		layout())


func add_unit(u: Combatant) -> void:
	if _views.has(u):
		return
	var v := BattlerView.new()
	v.setup(u, _db, _knowers)
	add_child(v)
	_views[u] = v
	_order()
	_queue_layout()  # 처음 나온 적은 한꺼번에 들어온 뒤 가운데 정렬(하나씩 정렬하면 첫 적이 가운데에 박힌다)


func remove_unit(u: Combatant) -> void:
	var v: BattlerView = _views.get(u)
	if v == null:
		return
	if v.art != null and v.front and u.actor is Monster and not u.is_active() and not u.fled:  # 쓰러진 몬스터 = 빛나는 먼지로
		var dust := DeathDust.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = u.order * 7919 + 13
		dust.setup(v.art, Rect2(v.position, v.size), v.flip, UiTheme.ui_dict("combat_death_dust"), rng)
		dust.z_index = 5  # 남은 몬스터가 그 자리로 다시 서도 위에 보이게
		add_child(dust)
	_views.erase(u)
	v.queue_free()
	layout()


func _queue_layout() -> void:
	if not _layout_queued:
		_layout_queued = true
		(func() -> void:
			_layout_queued = false
			layout()).call_deferred()


func view(u: Combatant) -> BattlerView:
	return _views.get(u)


func views() -> Dictionary:
	return _views


## 아군을 적보다 앞(나중)에 그린다.
func _order() -> void:
	for u: Combatant in _views:
		if u.side == Combatant.SIDE_PARTY:
			move_child(_views[u], -1)


func _bottom() -> float:
	return float(UiTheme.metric("combat_bottom_height", 200)) + UiTheme.metric("margin", 16)


## 배치: 아군을 먼저 세우고(아래 앞줄), 적의 발 높이는 아군 머리 위로 올린다(combat_enemy_clear — 아군이 적을 가리지 않게,
## combat_enemy_floor_min 아래로는 내리지 않는다). 적은 처음 나온 무리 그대로 가운데 정렬한 **고정 자리**에 선다 —
## 쓰러져도 남은 적이 가운데로 모이지 않고, 새로 나온 적(소환·증원·분열)은 빈자리 중 가운데에 가까운 곳에(자리가 없으면 다시 정렬).
## 키 = 사람 키 × 크기(작은 건 작게·큰 건 크게), 보스 등급은 크기와 상관없이 무대를 거의 채운다. 자리 = 화면 폭 비율·무대 높이 비율.
func layout() -> void:
	var stage_h := size.y - _bottom()
	if size.x <= 0.0 or stage_h <= 0.0:
		return
	var foes: Array[Combatant] = []
	var party: Array[Combatant] = []
	for u: Combatant in _views:
		(party if u.side == Combatant.SIDE_PARTY else foes).append(u)
	var ally_top := _layout_party(party, stage_h)
	_floor_y = stage_h * UiTheme.ui_float("combat_enemy_floor", 0.92)
	if not party.is_empty():
		_floor_y = maxf(stage_h * UiTheme.ui_float("combat_enemy_floor_min", 0.4), minf(_floor_y, ally_top - UiTheme.metric("combat_enemy_clear", 8)))
	for u: Combatant in _slots.keys():
		if not _views.has(u):
			_slots.erase(u)
	var fresh: Array[Combatant] = foes.filter(func(u: Combatant) -> bool: return not _slots.has(u))
	if not fresh.is_empty():
		if _slots.is_empty() or not _fit_new(fresh, stage_h):
			_pack(foes, stage_h)
	for u in foes:
		var v: BattlerView = _views[u]
		var sl: Dictionary = _slots[u]
		v.place(Vector2(size.x * float(sl["x"]), _floor_y), stage_h * float(sl["h"]))
	queue_redraw()


## 아군: 아래 앞줄에 고르게. 가장 높은 머리(그림 위끝)의 y를 돌려준다(아군이 없으면 무대 바닥).
func _layout_party(party: Array[Combatant], stage_h: float) -> float:
	var ph := stage_h * UiTheme.ui_float("combat_party_height", 0.38)
	var sink := float(UiTheme.metric("combat_party_sink", 100))
	var side_from := UiTheme.ui_float("combat_party_side_from", 0.2)
	var n := party.size()
	var top := stage_h
	for i in n:  # 가장자리 탐험가는 무대 가운데(적)를 보며 비스듬히 돌아선 옆모습, 소환수는 크기만큼(작은 것은 덜 가라앉혀 보이게)
		var v: BattlerView = _views[party[i]]
		var px := _party_x(i, n)
		v.set_view(absf(px - 0.5) >= side_from, px > 0.5)
		var k := clampf(v.size_k, 0.5, UiTheme.ui_float("combat_party_size_max", 1.2)) if v.unit.actor is Monster else 1.0
		var half := v.width_for(ph * k) * 0.5  # 화면 밖으로 넘치지 않게
		v.place(Vector2(clampf(size.x * px, half, maxf(half, size.x - half)), stage_h + sink * minf(1.0, k) * minf(1.0, k)), ph * k)
		top = minf(top, v.position.y)
	return top


## 적 하나의 키(px): 보스는 무대를 거의 채우고(머리는 위 안내 줄 아래, 치켜든 무기·뿔은 위로 넘쳐도 된다), 나머지는 사람 키 × 크기.
func _foe_height(v: BattlerView, stage_h: float) -> float:
	if v.boss:
		var broom := _floor_y - float(UiTheme.metric("combat_boss_top_room", 72))
		return minf(stage_h * UiTheme.ui_float("combat_boss_height", 0.92), broom / clampf(v.height_ratio(), 1.0, UiTheme.ui_float("combat_boss_head_room", 1.15)))
	var room := _floor_y - float(UiTheme.metric("combat_enemy_top_room", 96))
	var base_h := stage_h * UiTheme.ui_float("combat_enemy_height", 0.4)  # 크기 1(사람 키)일 때
	return minf(base_h * pow(clampf(v.size_k, 0.3, 2.4), UiTheme.ui_float("combat_enemy_size_exp", 1.0)), room / maxf(1.0, v.height_ratio()))


## 적 전원을 한 줄로 가운데 정렬해 자리를 새로 정한다(처음 나왔을 때, 또는 새 적이 들어갈 빈자리가 없을 때). 화면 폭을 넘으면 다 같이 줄인다.
func _pack(foes: Array[Combatant], stage_h: float) -> void:
	var gap := float(UiTheme.metric("combat_enemy_gap", 24))
	var heights: Array[float] = []
	var total := 0.0
	for u in foes:
		var h := _foe_height(_views[u], stage_h)
		heights.append(h)
		total += (_views[u] as BattlerView).width_for(h) + gap
	var fit := minf(1.0, size.x * UiTheme.ui_float("combat_enemy_span", 0.92) / maxf(1.0, total))
	var x := (size.x - total * fit) / 2.0 + gap * fit / 2.0
	_slots.clear()
	for i in foes.size():
		var h := heights[i] * fit
		var w := (_views[foes[i]] as BattlerView).width_for(h)
		_slots[foes[i]] = {"x": (x + w / 2.0) / size.x, "h": h / stage_h}
		x += w + gap * fit


## 새 적을 지금 자리를 건드리지 않고 빈자리(가운데에 가까운 곳부터)에 넣는다. 하나라도 못 넣으면 false(다시 정렬).
func _fit_new(fresh: Array[Combatant], stage_h: float) -> bool:
	var gap := float(UiTheme.metric("combat_enemy_gap", 24))
	var lo := size.x * (1.0 - UiTheme.ui_float("combat_enemy_span", 0.92)) / 2.0
	var hi := size.x - lo
	for u in fresh:
		var v: BattlerView = _views[u]
		var h := _foe_height(v, stage_h)
		var w := v.width_for(h) + gap
		var taken: Array[Vector2] = []  # 차지한 [왼쪽, 오른쪽] px
		for o: Combatant in _slots:
			var ov: BattlerView = _views[o]
			var ow := ov.width_for(stage_h * float(_slots[o]["h"])) + gap
			var ox := size.x * float(_slots[o]["x"])
			taken.append(Vector2(ox - ow / 2.0, ox + ow / 2.0))
		var best := -1.0
		var cands: Array[float] = [size.x / 2.0]
		for t in taken:
			cands.append(t.x - w / 2.0)
			cands.append(t.y + w / 2.0)
		for c in cands:
			if c - w / 2.0 < lo - 0.5 or c + w / 2.0 > hi + 0.5:
				continue
			if taken.any(func(t: Vector2) -> bool: return c + w / 2.0 > t.x + 0.5 and c - w / 2.0 < t.y - 0.5):
				continue
			if best < 0.0 or absf(c - size.x / 2.0) < absf(best - size.x / 2.0):
				best = c
		if best < 0.0:
			return false
		_slots[u] = {"x": best / size.x, "h": h / stage_h}
	return true


## 아군 자리(화면 폭 비율): 피어 앤 헝거처럼 앞줄을 넓게 벌려 선다 — 가운데(적 정면)는 비워 둔다.
static func _party_x(i: int, n: int) -> float:
	match n:
		1:
			return 0.27
		2:
			return [0.24, 0.76][i]
		3:
			return [0.18, 0.5, 0.82][i]
		4:
			return [0.11, 0.3, 0.7, 0.89][i]
	return 0.08 + 0.84 * i / maxf(1.0, n - 1)


## 어둠 + 적 발밑 빛 웅덩이(겹친 타원) + 위에서 떨어지는 희미한 빛기둥.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.018, 0.016, UiTheme.ui_float("combat_dim_alpha", 0.96)))
	var stage_h := size.y - _bottom()
	var c := Vector2(size.x / 2.0, _floor_y if _floor_y > 0.0 else stage_h * UiTheme.ui_float("combat_enemy_floor", 0.92))
	var light := UiTheme.color("combat_floor", Color(0.42, 0.36, 0.3))
	var cone := PackedVector2Array([Vector2(c.x - size.x * 0.12, 0), Vector2(c.x + size.x * 0.12, 0), Vector2(c.x + size.x * 0.34, c.y), Vector2(c.x - size.x * 0.34, c.y)])
	draw_colored_polygon(cone, Color(light.r, light.g, light.b, 0.035))
	for i in 12:
		var t := 1.0 - i / 12.0
		var rx := size.x * 0.44 * t
		var pts := PackedVector2Array()
		for j in 40:
			var a := TAU * j / 40.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * rx * 0.2))
		draw_colored_polygon(pts, Color(light.r, light.g, light.b, 0.035))
