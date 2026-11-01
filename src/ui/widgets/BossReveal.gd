class_name BossReveal
extends Control
## 보스 등장 연출(사용자 2026-11-01 "아 보스랑 싸우는구나 하는 느낌", V22): 방에서 기다리던 보스를 플레이어가 실제로 봤을 때(FieldMonsters.boss_seen)
## 전투 화면을 열기 전에 —
##   ① 위아래 검은 띠가 들어오고 화면 가장자리가 어두워진다(시간은 이미 멈춰 있다 — 전투 시작)
##   ② 카메라가 보스 쪽으로 천천히 옮겨 간다
##   ③ 보스가 깨어난다: 그림이 한 번 크게 숨 쉬듯 부풀고 하얗게 번쩍, 화면이 짧게 흔들린다, 소리(sfx boss_reveal — 파일이 없으면 조용)
##   ④ 위쪽 띠 아래에 보스 이름(크게)과 가는 선 — 글은 이름뿐(부연설명 없음). 대화창(보스 한 줄)은 아래에 그대로
##   ⑤ 잠깐 머문 뒤 끝난다. 이어서 화면이 보스 한 줄(explore.boss_notice)을 보이고 Enter 뒤 전투(ExploreScreen._on_encounter).
## 수치 = render.json ui.boss_reveal. 오토로드 AudioBus를 쓴다(UI).

signal done

var _view: FloorView
var _group: FieldMonsters.Group
var _db: GameDatabase
var _cfg: Dictionary = {}
var _top: ColorRect
var _bottom: ColorRect
var _shade: ColorRect
var _title: Label
var _line: ColorRect


## 화면 parent 위에 연출을 띄우고 끝날 때까지 기다린다. 연출은 남겨 둔다(띠·이름 — 전투 화면이 덮은 뒤 close()로 걷는다).
## below = 이 창보다 아래에 깐다(대화창 — 보스 한 줄이 띠 위에 보이게).
static func play(parent: Control, view: FloorView, group: FieldMonsters.Group, db: GameDatabase, below: Control = null) -> BossReveal:
	var r := BossReveal.new()
	r._view = view
	r._group = group
	r._db = db
	parent.add_child(r)
	if below != null and below.get_parent() == parent:
		parent.move_child(r, below.get_index())
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r._run()
	await r.done
	return r


func _f(key: String, fallback: float) -> float:
	return JsonUtil.get_float(_cfg, key, fallback)


func _run() -> void:
	_cfg = JsonUtil.get_dict(JsonUtil.get_dict(_db.render, "ui"), "boss_reveal")
	var bar := size.y * _f("bar_ratio", 0.11)
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top = _bar(true)
	_bottom = _bar(false)
	_title = UiTheme.label(DataNames.entry(_db, "monsters", _group.boss), "title", "text_title")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.modulate.a = 0.0
	add_child(_title)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.offset_top = bar + _f("title_gap_px", 28.0)
	_line = ColorRect.new()
	_line.color = UiTheme.color("text_title")
	_line.modulate.a = 0.0
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_line)
	_line.set_anchors_preset(Control.PRESET_CENTER_TOP)
	var lw := _f("line_width_px", 420.0)
	_line.offset_left = -lw * 0.5
	_line.offset_right = lw * 0.5
	_line.offset_top = bar + _f("title_gap_px", 28.0) + float(UiTheme.metric("title_font_size", 60)) * 1.35
	_line.offset_bottom = _line.offset_top + 1.0
	var into := _f("bars_sec", 0.45)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_top, "offset_bottom", bar, into)
	tw.tween_property(_bottom, "offset_top", -bar, into)
	tw.tween_property(_shade, "color:a", _f("shade_alpha", 0.25), into)
	var cam := _view.player_view.camera() if _view != null and _view.player_view != null else null
	var home := cam.position if cam != null else Vector2.ZERO
	if cam != null:  # 카메라를 보스 쪽으로(보스와 플레이어 사이 pan_ratio 지점까지)
		var to := _view.feet_position(_group.pos) - _view.player_view.position
		var pan := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pan.tween_property(cam, "position", home + to * _f("pan_ratio", 0.85), _f("pan_sec", 0.9))
		await pan.finished
	else:
		await tw.finished
	if not is_inside_tree():
		return
	AudioBus.play_sfx("boss_reveal")
	var mv := _view.monster_view(_group.id) if _view != null else null
	if mv != null:  # 깨어난다: 한 번 부풀고 하얗게 번쩍
		if _view.session.pos != _group.pos:
			_group.facing = Vector2(_view.session.pos - _group.pos).normalized()  # 플레이어 쪽으로 돈다
		mv.face_toward(_view.player_view.position)
		var wake := create_tween()
		wake.tween_property(mv, "scale", Vector2.ONE * _f("wake_scale", 1.18), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		wake.parallel().tween_property(mv, "modulate", Color(2.2, 2.0, 1.9), 0.09)
		wake.tween_property(mv, "modulate", Color.WHITE, 0.35)
		wake.parallel().tween_property(mv, "scale", Vector2.ONE, 0.35)
	if cam != null:
		_shake(cam, cam.position)
	var show := create_tween().set_parallel(true)
	show.tween_property(_title, "modulate:a", 1.0, _f("title_fade_sec", 0.5))
	show.tween_property(_line, "modulate:a", 0.7, _f("title_fade_sec", 0.5))
	await get_tree().create_timer(_f("hold_sec", 1.3)).timeout
	if not is_inside_tree():
		return
	if cam != null:
		create_tween().tween_property(cam, "position", home, 0.25)
	done.emit()


func _bar(top: bool) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	if top:
		r.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		r.offset_bottom = 0.0
	else:
		r.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		r.offset_top = 0.0
	return r


## 짧게 흔들기(보스가 깨어날 때).
func _shake(cam: Camera2D, at: Vector2) -> void:
	var amp := _f("shake_px", 5.0)
	var t := create_tween()
	for i in 6:
		var k := 1.0 - float(i) / 6.0
		t.tween_property(cam, "offset", Vector2((i % 2) * 2 - 1, (i % 3) - 1) * amp * k, 0.04)
	t.tween_property(cam, "offset", Vector2.ZERO, 0.05)
	cam.position = at


## 띠·이름을 걷는다(전투 화면이 덮은 뒤).
func close() -> void:
	queue_free()
