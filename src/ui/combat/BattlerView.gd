class_name BattlerView
extends Control
## 전투 무대 위의 참가자 하나. 그림은 MonsterArt(없으면 CombatFigure 도형): 적은 정면 그림, 아군 소환수는 뒷모습(<id>_back),
## 탐험가는 종족 그림 — 뒷모습(back)과 비스듬히 돌아선 옆모습(side)을 무대가 자리에 따라 고른다(set_view, 오른쪽 자리는 좌우 반전).
## 적은 정면 + 머리 위 이름·발밑 상태(생명력은 보이지 않는다 — 피어 앤 헝거처럼, 받은 피해만 숫자로 떠오른다.
## 단 아군이 그 종을 조사해 두었으면 이름 아래 생명력 막대, 쳐 봐서 알아낸 상성은 그 아래 한 줄 — 지식이 남는 전투, UI22),
## 아군은 뒷모습만(이름·생명력·영혼력은 아래 파티 창에). 지금 차례·대상으로 고르는 중이면 발밑 고리가 빛난다.
## 쓰러지거나 도망치면 흐려진다.

var unit: Combatant
var shape: String = "humanoid"
var color: Color = Color.GRAY
var size_k: float = 1.0
var boss: bool = false  ## 보스 등급(render.json ui.combat_boss_ranks) — 크기와 상관없이 무대를 거의 채운다
var front: bool = true
var art: Texture2D = null  ## 몬스터 일러스트(없으면 null)
var flip: bool = false  ## 좌우 반전(오른쪽 자리의 옆모습이 무대 가운데를 보게)
var _art_body: float = 1.0  ## 그림 속 몸 높이 px
var _views := {}  ## 탐험가: "back"/"side" → [그림, 몸 높이]
var _current: bool = false
var _target: bool = false
var _name: Label
var _status: Label
var _aff: Label
var _knowers: Array[Knowledge] = []
var _bar := Rect2()  ## 생명력 막대 자리(조사한 종일 때만 그린다)
var _show_bar: bool = false


func setup(u: Combatant, db: GameDatabase, knowers: Array[Knowledge] = []) -> void:
	unit = u
	_knowers = knowers
	front = u.side != Combatant.SIDE_PARTY
	if u.actor is Monster:
		var def := (u.actor as Monster).def
		shape = JsonUtil.get_str(def, "shape", "humanoid")
		size_k = JsonUtil.get_float(def, "size", 1.0)
		boss = UiTheme.render_array("ui.combat_boss_ranks").has(JsonUtil.get_str(def, "rank"))
		color = Color.from_string(JsonUtil.get_str(def, "color"), Color.GRAY)
		var art_id := (u.actor as Monster).monster_id + ("" if front else "_back")  # 아군 소환수는 뒷모습
		art = MonsterArt.texture(art_id)
		if art != null:
			_art_body = MonsterArt.body_height(art_id, art)
	elif u.actor is PlayerCharacter:
		var race := (u.actor as PlayerCharacter).race_id
		color = Color.from_string(JsonUtil.get_str(db.get_entry("races", race), "color"), Color.GRAY)
		for view: String in ["back", "side"]:
			var tex := MonsterArt.texture_in(MonsterArt.party_dir(), race + "_" + view)
			if tex != null:
				_views[view] = [tex, MonsterArt.body_height_in(MonsterArt.party_dir(), race + "_" + view, tex)]
		set_view(false, false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not front:
		return
	_name = UiTheme.label(u.label(), "small", "text_title")
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	_status = UiTheme.label("", "small", "warn")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.clip_text = true
	add_child(_status)
	_aff = UiTheme.label("", "small", "text_dim")
	_aff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aff.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aff.clip_text = true
	add_child(_aff)
	_read_knowledge()


## 탐험가 그림 고르기: side면 옆모습(없으면 뒷모습), mirror면 좌우 반전(옆모습일 때만).
func set_view(side: bool, mirror: bool) -> void:
	var key := "side" if side and _views.has("side") else "back"
	if not _views.has(key):
		return
	art = _views[key][0]
	_art_body = _views[key][1]
	flip = mirror and key == "side"
	queue_redraw()


## 키 h일 때 그림 전체 높이 / h(들어 올린 무기·뿔·이름표 자리 포함 — 무대가 화면 위로 넘치지 않게 줄일 때).
func height_ratio() -> float:
	if art != null:
		return art.get_height() / _art_body
	return CombatFigure.top_of(shape)


## 키 h일 때 차지하는 폭(무대 배치용).
func width_for(h: float) -> float:
	if art != null:
		return art.get_width() * h / _art_body
	return CombatFigure.width_of(shape, h)


## 무대가 정한 자리: 발 위치 · 키. 이름은 머리 위, 상태는 발밑.
func place(foot: Vector2, h: float) -> void:
	var w := width_for(h)
	size = Vector2(w, art.get_height() * h / _art_body if art != null else h * 1.12)
	position = foot - Vector2(w / 2.0, size.y)
	if front:
		var lw := maxf(w, UiTheme.metric("combat_enemy_label_width", 150))
		var top := h if art != null else h * CombatFigure.top_of(shape)
		_name.size = Vector2(lw, 20)
		_name.position = Vector2((w - lw) / 2.0, maxf(size.y - top - 26, 4.0 - position.y))  # 화면 위로 넘치는 큰 보스도 이름은 보이게
		_status.size = Vector2(lw, 20)
		_status.position = Vector2((w - lw) / 2.0, size.y + 8)
		var bar := UiTheme.ui_dict("combat_enemy_bar")
		var bw := minf(JsonUtil.get_float(bar, "width", 96.0), lw)
		var bh := JsonUtil.get_float(bar, "height", 5.0)
		_bar = Rect2((w - bw) / 2.0, _name.position.y + 22.0, bw, bh)
		var aw := maxf(lw, JsonUtil.get_float(bar, "text_width", 240.0))
		_aff.size = Vector2(aw, 20)
		_aff.position = Vector2((w - aw) / 2.0, _bar.end.y + 2.0 if _show_bar else _name.position.y + 20.0)
		for l: Label in [_name, _status, _aff]:
			_keep_in(l)
	queue_redraw()


## 이름·상태·상성 줄이 무대(화면) 양옆으로 넘치지 않게 안쪽으로 민다 — 가장자리에 선 좁은 적의 넓은 이름표.
func _keep_in(l: Label) -> void:
	var stage := get_parent_control()
	if stage == null:
		return
	var pad := float(UiTheme.metric("spacing", 8))
	var gx := clampf(position.x + l.position.x, pad, maxf(pad, stage.size.x - l.size.x - pad))
	l.position.x = gx - position.x


func refresh() -> void:
	if front:
		var names := PackedStringArray()
		for id in unit.actor.statuses.ids():
			names.append(DataNames.entry(unit.actor.db, "statuses", id))
		_status.text = ", ".join(names)
		_read_knowledge()
	modulate.a = 1.0 if unit.is_active() else 0.3
	queue_redraw()


## 아군 기록에서 이 몬스터의 생명력(조사했는가)·알아낸 상성을 읽는다.
func _read_knowledge() -> void:
	if not unit.actor is Monster:
		return
	var id := (unit.actor as Monster).monster_id
	var show := BattleKnowledge.party_knows_stats(_knowers, id)
	_aff.text = BattleKnowledge.describe(unit.actor.db, BattleKnowledge.party_affinities(_knowers, id), true)
	if show != _show_bar:
		_show_bar = show
		_aff.position.y = _bar.end.y + 2.0 if show else _name.position.y + 20.0


func set_current(on: bool) -> void:
	if _current != on:
		_current = on
		queue_redraw()


func set_targeted(on: bool) -> void:
	if _target != on:
		_target = on
		if _name != null:
			_name.add_theme_color_override("font_color", UiTheme.color("gold" if on else "text_title"))
		queue_redraw()


func _draw() -> void:
	var glow := 1.0 if _target else (0.55 if _current else 0.0)
	if art != null:
		if front:  # 아군 발은 아래 창 뒤로 가라앉아 있다(차례는 밝기로)
			CombatFigure.ground(self, Vector2(size.x / 2.0, size.y), minf(size.x * 0.42, size.y * 0.5), size.y, glow)
		if flip:
			draw_set_transform(Vector2(size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect(art, Rect2(Vector2.ZERO, size), false, Color(1.12, 1.1, 1.05) if _current else Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var c := color.lightened(0.12) if _current and not front else color
		CombatFigure.paint(self, shape, c, front, Vector2(size.x / 2.0, size.y), size.y / 1.12, glow)
	if front and _show_bar and _bar.size.x > 0.0:
		draw_rect(_bar.grow(1.0), UiTheme.color("bar_bg"))
		draw_rect(Rect2(_bar.position, Vector2(_bar.size.x * unit.actor.pool.get_ratio("hp"), _bar.size.y)), UiTheme.color("bar_hp"))


## 몸 위로 떠오르는 숫자/글자(피해 숫자): 크게 튀어나왔다가 잠깐 머문 뒤 위로 흐려진다. big = 피해 숫자(더 크게).
func float_text(text: String, col: Color, big: bool = false) -> void:
	var l := UiTheme.label(text, "header", "text")
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", UiTheme.metric("float_text_size" if big else "header_font_size", 34 if big else 20))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", UiTheme.metric("float_text_outline", 6))
	l.top_level = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var ms := l.get_combined_minimum_size()
	var top := global_position.y + size.y * (0.22 if front else 0.12)  # 아군은 아래가 창 뒤로 가라앉아 있어 위쪽에
	l.position = Vector2(clampf(global_position.x + size.x * 0.5 - ms.x * 0.5, 4.0, get_viewport_rect().size.x - ms.x - 4.0), maxf(top, 8.0))
	l.pivot_offset = ms * 0.5
	l.scale = Vector2(1.5, 1.5)
	var sec := UiTheme.ui_float("float_text_sec", 1.3)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, sec * 0.15)
	tw.tween_interval(sec * 0.45)
	tw.tween_property(l, "position:y", l.position.y - 36, sec * 0.4)
	tw.parallel().tween_property(l, "modulate:a", 0.0, sec * 0.4)
	tw.tween_callback(l.queue_free)
