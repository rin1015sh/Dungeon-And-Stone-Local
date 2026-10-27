class_name BattleStage
extends Control
## 전투 무대(피어 앤 헝거식 — 정면에서 맞닥뜨린다): 어둠 속 바닥에 떨어진 빛 웅덩이,
## 그 위 가운데에 적이 이쪽을 보고 서고(덩치에 따라 크게, 아군 머리보다 위 — 가리지 않게, 자리 고정),
## 화면 아래쪽 앞줄에 아군이 등을 보이고 선다(다리는 아래 창에 가린다). 뒤에는 그 층·균열의 전투 뒷그림(소실점 통로 — set_backdrop).
## 적이 많아 통로 벽(뒷그림 half_width m) 안에 한 줄로 못 서면 뒷줄로 — 깊이만큼 작아지고 소실점 쪽으로 다가간다(FoeRows, UI29).
## 배치 수치는 render.json ui.combat_* (bottom_reserve = 아래 창 높이).

var _views: Dictionary = {}  # Combatant -> BattlerView
var _db: GameDatabase
var _slots: Dictionary = {}  # 적 Combatant -> {"x": 가운데에서 m(앞줄 기준), "row": 줄(0 = 앞), "h": 앞줄 키 / 무대 높이} — 고정 자리
var _floor_y: float = 0.0    # 적 발 높이(px) — 빛 웅덩이도 여기
var _layout_queued: bool = false
var _back: Texture2D = null  # 전투 뒷그림(층 art.battleback · 균열 look.art.battleback) — 없으면 어둠뿐
var _half_width: float = 3.0  # 통로 반 폭(m, 앞줄 적 크기 기준) — 적이 이 안에 선다


func setup(db: GameDatabase) -> void:
	_db = db
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func() -> void:
		_slots.clear()  # 화면 크기가 바뀌면 자리를 새로 정한다(처음 크기가 정해질 때 포함)
		layout())


## 전투 뒷그림(경로가 비었거나 파일이 없으면 어둠만) + 통로 반 폭(m — 0이면 render.json 기본값).
func set_backdrop(path: String, half_width: float = 0.0) -> void:
	_back = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	_half_width = half_width if half_width > 0.0 else UiTheme.ui_float("combat_rows_half_width", 3.0)
	_slots.clear()
	queue_redraw()


func add_unit(u: Combatant) -> void:
	if _views.has(u):
		return
	var v := BattlerView.new()
	v.setup(u, _db)
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


## 뒷줄 적 → 앞줄 적 → 아군 순서로 그린다(앞에 선 것이 위에).
func _order() -> void:
	var foes: Array[Combatant] = []
	for u: Combatant in _views:
		if u.side != Combatant.SIDE_PARTY:
			foes.append(u)
	foes.sort_custom(func(a: Combatant, b: Combatant) -> bool: return _row(a) > _row(b))
	for u in foes:
		move_child(_views[u], -1)
	for u: Combatant in _views:
		if u.side == Combatant.SIDE_PARTY:
			move_child(_views[u], -1)


func _row(u: Combatant) -> int:
	return int((_slots.get(u, {}) as Dictionary).get("row", 0))


func _bottom() -> float:
	return DialogueBox.box_size().y + UiTheme.metric("margin", 16)


## 배치: 아군을 먼저 세우고(아래 앞줄), 적의 발 높이는 아군 머리 위로 올린다(combat_enemy_clear — 아군이 적을 가리지 않게,
## combat_enemy_floor_min 아래로는 내리지 않는다). 적은 처음 나온 무리 그대로 통로 안에 앞줄부터 선 **고정 자리**에 선다(FoeRows) —
## 쓰러져도 남은 적이 모이지 않고, 새로 나온 적(소환·증원·분열)은 빈자리 중 앞줄·가운데에 가까운 곳에(자리가 없으면 다시 정렬).
## 키 = 사람 키 × 크기(작은 건 작게·큰 건 크게), 보스 등급은 크기와 상관없이 무대를 거의 채운다. 뒷줄은 깊이 배율만큼 작고 소실점 쪽으로.
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
		var boss_new := fresh.any(func(u: Combatant) -> bool: return (_views[u] as BattlerView).boss)  # 보스는 늘 가운데 — 다시 정렬
		if _slots.is_empty() or boss_new or not _fit_new(fresh, stage_h):
			_pack(foes, stage_h)
		_order()
	var ppm := _ppm(stage_h)
	var hy := _horizon_y()
	var drop := maxf(_floor_y - hy, float(UiTheme.metric("combat_rows_min_drop", 40)))
	var step := UiTheme.ui_float("combat_rows_depth_step", 0.45)
	var rise := stage_h * UiTheme.ui_float("combat_rows_rise", 0.1)  # 뒷줄이 적어도 이만큼 위에(지평선이 낮아도 앞줄 뒤에 묻히지 않게)
	var deep := foes.any(func(u: Combatant) -> bool: return _row(u) > 0)
	# 뒷줄이 있으면 앞줄을 이쪽으로 당긴다(아래로·조금 크게) — 뒷줄이 앞줄 머리 위로 보이게
	var front_y := minf(_floor_y + stage_h * UiTheme.ui_float("combat_rows_front_pull", 0.22), stage_h * 0.97) if deep else _floor_y
	var front_k := UiTheme.ui_float("combat_rows_front_scale", 1.08) if deep else 1.0
	for u in foes:
		var v: BattlerView = _views[u]
		var sl: Dictionary = _slots[u]
		var row := int(sl["row"])
		var k := FoeRows.scale_of(row, step) if row > 0 else front_k
		var foot_y := front_y if row == 0 else _floor_y - maxf(drop * (1.0 - k), rise * row)
		# 옆 자리는 모든 줄이 앞줄 배율로 — 뒷줄이 화면에서도 앞줄 사이 틈에 온다(원근대로 가운데로 모으면 앞줄 뒤에 숨는다)
		v.place(Vector2(size.x / 2.0 + float(sl["x"]) * ppm * front_k, foot_y), stage_h * float(sl["h"]) * k)
	queue_redraw()


## 앞줄에서 1m의 화면 px(사람 키 = 무대 높이 × combat_enemy_height가 combat_human_m).
func _ppm(stage_h: float) -> float:
	return stage_h * UiTheme.ui_float("combat_enemy_height", 0.4) / UiTheme.ui_float("combat_human_m", 1.7)


## 뒷그림의 지평선(소실점) 화면 y — 그림을 화면을 덮게 깐 배율로(그림이 없어도 같은 자리).
func _horizon_y() -> float:
	var cam := UiTheme.ui_dict("combat_backdrop_camera")
	var ts := Vector2(JsonUtil.get_float(cam, "width", 1280.0), JsonUtil.get_float(cam, "height", 720.0))
	if _back != null:
		ts = _back.get_size()
	var k := maxf(size.x / ts.x, size.y / ts.y)
	return (size.y - ts.y * k) / 2.0 + JsonUtil.get_float(cam, "horizon", 250.0) * k


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


## 적 전원의 자리를 새로 정한다(처음 나왔을 때, 또는 새 적이 들어갈 빈자리가 없을 때): 통로 안에 앞줄부터(FoeRows),
## 줄이 combat_rows_max를 넘거나 한 마리가 화면 폭을 넘으면 다 같이 줄인다.
func _pack(foes: Array[Combatant], stage_h: float) -> void:
	var ppm := _ppm(stage_h)
	var gap := float(UiTheme.metric("combat_enemy_gap", 24)) / ppm
	var heights: Array[float] = []
	var widths := PackedFloat32Array()
	var widest := 0.0
	for u in foes:
		var h := _foe_height(_views[u], stage_h)
		heights.append(h)
		var wpx := (_views[u] as BattlerView).width_for(h)
		widest = maxf(widest, wpx)
		widths.append(wpx / ppm)
	var fit := minf(1.0, size.x * UiTheme.ui_float("combat_enemy_span", 0.92) / maxf(1.0, widest))
	for i in widths.size():
		widths[i] *= fit
	var pinned := -1  # 첫 보스(계층군주·수호자·중간 보스)는 늘 앞줄 한가운데
	for i in foes.size():
		if (_views[foes[i]] as BattlerView).boss:
			pinned = i
			break
	var out := FoeRows.arrange_fit(widths, _half_width, gap, UiTheme.metric("combat_rows_max", 3), pinned)
	var pos: Array = out["pos"]
	_slots.clear()
	for i in foes.size():
		var p: Vector2 = pos[i]
		_slots[foes[i]] = {"x": p.x, "row": int(p.y), "h": heights[i] * fit * float(out["k"]) / stage_h}


## 새 적을 지금 자리를 건드리지 않고 빈자리(앞줄·가운데에 가까운 곳부터)에 넣는다. 하나라도 못 넣으면 false(다시 정렬).
func _fit_new(fresh: Array[Combatant], stage_h: float) -> bool:
	var ppm := _ppm(stage_h)
	var gap := float(UiTheme.metric("combat_enemy_gap", 24)) / ppm
	for u in fresh:
		var taken: Array[Vector3] = []
		for o: Combatant in _slots:
			var sl: Dictionary = _slots[o]
			taken.append(Vector3(float(sl["x"]), float(sl["row"]), (_views[o] as BattlerView).width_for(stage_h * float(sl["h"])) / ppm))
		var h := _foe_height(_views[u], stage_h)
		var at := FoeRows.fit_new(taken, (_views[u] as BattlerView).width_for(h) / ppm, _half_width, gap, UiTheme.metric("combat_rows_max", 3))
		if at.y < 0.0:
			return false
		_slots[u] = {"x": at.x, "row": int(at.y), "h": h / stage_h}
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


## 뒷그림(화면을 덮게 — 비율 유지, 넘치는 쪽은 가운데 기준으로 자른다) 또는 어둠 + 적 발밑 빛 웅덩이(겹친 타원) + 위에서 떨어지는 희미한 빛기둥.
func _draw() -> void:
	if _back != null:
		var ts := _back.get_size()
		var k := maxf(size.x / ts.x, size.y / ts.y)
		draw_texture_rect(_back, Rect2((size - ts * k) / 2.0, ts * k), false)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.018, 0.016, UiTheme.ui_float("combat_backdrop_dim", 0.15)))
	else:
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
