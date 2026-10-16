class_name BattleStage
extends Control
## 전투 무대(피어 앤 헝거식 — 정면에서 맞닥뜨린다): 어둠 속 바닥에 떨어진 빛 웅덩이,
## 그 위 가운데에 적이 이쪽을 보고 서고(덩치에 따라 크게), 화면 아래쪽 앞줄에 아군이 등을 보이고 선다(다리는 아래 창에 가린다).
## 배치 수치는 render.json ui.combat_* (bottom_reserve = 아래 창 높이).

signal unit_clicked(unit: Combatant)

var _views: Dictionary = {}  # Combatant -> BattlerView
var _db: GameDatabase


func setup(db: GameDatabase) -> void:
	_db = db
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(layout)


func add_unit(u: Combatant) -> void:
	if _views.has(u):
		return
	var v := BattlerView.new()
	v.setup(u, _db)
	v.clicked.connect(func(x: Combatant) -> void: unit_clicked.emit(x))
	add_child(v)
	_views[u] = v
	_order()
	layout()


func remove_unit(u: Combatant) -> void:
	var v: BattlerView = _views.get(u)
	if v == null:
		return
	_views.erase(u)
	v.queue_free()
	layout()


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


## 적: 가운데 한 줄(키 = 사람 키 × 크기 — 작은 건 작게·큰 건 크게, 보스 등급은 크기와 상관없이 무대를 거의 채운다.
## 화면 폭을 넘으면 다 같이 줄인다). 아군: 아래 앞줄에 고르게.
func layout() -> void:
	if size.x <= 0.0:
		return
	var stage_h := size.y - _bottom()
	var floor_y := stage_h * UiTheme.ui_float("combat_enemy_floor", 0.92)
	var base_h := stage_h * UiTheme.ui_float("combat_enemy_height", 0.4)  # 크기 1(사람 키)일 때
	var size_exp := UiTheme.ui_float("combat_enemy_size_exp", 1.0)
	var foes: Array[Combatant] = []
	var party: Array[Combatant] = []
	for u: Combatant in _views:
		(party if u.side == Combatant.SIDE_PARTY else foes).append(u)
	var heights: Array[float] = []
	var total := 0.0
	var gap := float(UiTheme.metric("combat_enemy_gap", 24))
	for u in foes:
		var v: BattlerView = _views[u]
		var h: float
		if v.boss:  # 보스: 크기 값과 상관없이 크게. 머리는 위 안내 줄 아래, 치켜든 무기·뿔은 위로 넘쳐도 된다
			var broom := floor_y - float(UiTheme.metric("combat_boss_top_room", 72))
			h = minf(stage_h * UiTheme.ui_float("combat_boss_height", 0.92), broom / clampf(v.height_ratio(), 1.0, UiTheme.ui_float("combat_boss_head_room", 1.15)))
		else:  # 나머지: 키 = 사람 키 × 크기(작은 건 작게, 큰 건 크게). 위 안내 줄·이름표 자리를 남긴다
			var room := floor_y - float(UiTheme.metric("combat_enemy_top_room", 96))
			h = minf(base_h * pow(clampf(v.size_k, 0.3, 2.4), size_exp), room / maxf(1.0, v.height_ratio()))
		heights.append(h)
		total += v.width_for(h) + gap
	var avail := size.x * 0.92
	var fit := minf(1.0, avail / maxf(1.0, total))
	var x := (size.x - total * fit) / 2.0 + gap * fit / 2.0
	for i in foes.size():
		var v: BattlerView = _views[foes[i]]
		var h := heights[i] * fit
		var w := v.width_for(h)
		v.place(Vector2(x + w / 2.0, floor_y), h)
		x += w + gap * fit
	var ph := stage_h * UiTheme.ui_float("combat_party_height", 0.38)
	var sink := float(UiTheme.metric("combat_party_sink", 100))
	var side_from := UiTheme.ui_float("combat_party_side_from", 0.2)
	var n := party.size()
	for i in n:  # 가장자리 탐험가는 무대 가운데(적)를 보며 비스듬히 돌아선 옆모습, 소환수는 크기만큼(작은 것은 덜 가라앉혀 보이게)
		var v: BattlerView = _views[party[i]]
		var px := _party_x(i, n)
		v.set_view(absf(px - 0.5) >= side_from, px > 0.5)
		var k := clampf(v.size_k, 0.5, UiTheme.ui_float("combat_party_size_max", 1.2)) if v.unit.actor is Monster else 1.0
		var half := v.width_for(ph * k) * 0.5  # 화면 밖으로 넘치지 않게
		v.place(Vector2(clampf(size.x * px, half, maxf(half, size.x - half)), stage_h + sink * minf(1.0, k) * minf(1.0, k)), ph * k)
	queue_redraw()


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
	var c := Vector2(size.x / 2.0, stage_h * UiTheme.ui_float("combat_enemy_floor", 0.92))
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
