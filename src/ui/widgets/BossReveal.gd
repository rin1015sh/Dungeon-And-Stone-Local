class_name BossReveal
extends Control
## 보스 등장 연출(사용자 2026-11-01 "아 보스랑 싸우는구나 하는 느낌", V22): 방에서 기다리던 보스를 플레이어가 실제로 봤을 때(FieldMonsters.boss_seen)
## 전투 화면을 열기 전에 —
##   ① 위아래 검은 띠가 들어오고 화면 가장자리가 어두워진다(시간은 이미 멈춰 있다 — 전투 시작). 그 방의 문목에 창살이 내려온다(ExploreSession.close_boss_gates — V23, 짧은 흔들림 + sfx boss_gate)
##   ② 카메라가 보스 쪽으로 천천히 옮겨 간다
##   ③ 보스가 깨어나 일어선다: 기다리는 자세(무릎 꿇음·왕좌·웅크림 …)에서 선 자세로 일어서는 칸을 돈다(<id>_rise.webp — 사용자 2026-11-01 "앉아 있다가
##      일어서는 그림"), 다 일어서면 화면이 짧게 흔들림 + 소리(sfx boss_reveal — 파일이 없으면 조용). 그 뒤로 맵 그림은 선 채(Group.awake).
##      하얗게 번쩍이던 빛은 없앴다(사용자 2026-11-01 "보스 클로즈업 때 흰색 빛 잠깐 나는 것 없애 줘").
##   ④ 잠깐 머문 뒤 끝난다. 이어서 화면이 보스 한 줄(explore.boss_notice)을 보이고 Enter 뒤 전투(ExploreScreen._on_encounter).
## 화면에 글은 없다 — 보스 이름 글씨·선은 지웠다(사용자 2026-11-01 "보스 이름이 화면에 뜨는 거 삭제", V24).
## 수치 = render.json ui.boss_reveal. 오토로드 AudioBus를 쓴다(UI).

signal done

var _view: FloorView
var _group: FieldMonsters.Group
var _db: GameDatabase
var _cfg: Dictionary = {}
var _top: ColorRect
var _bottom: ColorRect
var _shade: ColorRect


## 화면 parent 위에 연출을 띄우고 끝날 때까지 기다린다. 연출은 남겨 둔다(띠 — 전투 화면이 덮은 뒤 close()로 걷는다).
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
	var into := _f("bars_sec", 0.45)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_top, "offset_bottom", bar, into)
	tw.tween_property(_bottom, "offset_top", -bar, into)
	tw.tween_property(_shade, "color:a", _f("shade_alpha", 0.25), into)
	var cam := _view.player_view.camera() if _view != null and _view.player_view != null else null
	var home := cam.position if cam != null else Vector2.ZERO
	_group.awake = true
	if _view != null and _view.session.close_boss_gates(_group) and cam != null:  # 뒤에서 창살이 내려온다(V23) — 짧게 흔들림
		_shake(cam, cam.position, 0.5)
	if cam != null:  # 카메라를 보스 쪽으로(보스와 플레이어 사이 pan_ratio 지점까지)
		var to := _view.feet_position(_group.pos) - _view.player_view.position
		var pan := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pan.tween_property(cam, "position", home + to * _f("pan_ratio", 0.85), _f("pan_sec", 0.9))
		await pan.finished
	else:
		await tw.finished
	if not is_inside_tree():
		return
	var mv := _view.monster_view(_group.id) if _view != null else null
	if mv != null:  # 깨어나 일어선다(일어서는 칸 — 없는 보스는 한 번 부풀고) — 다 일어서면 흔들림 + 소리
		if _view.session.pos != _group.pos:
			_group.facing = Vector2(_view.session.pos - _group.pos).normalized()  # 플레이어 쪽으로 돈다
		mv.face_toward(_view.player_view.position)
		var rise_sec := _f("rise_sec", 0.7)
		mv.rise(rise_sec)
		var wake := create_tween()
		wake.tween_property(mv, "scale", Vector2.ONE * _f("wake_scale", 1.06), rise_sec).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await wake.finished
		if not is_inside_tree():
			return
		create_tween().tween_property(mv, "scale", Vector2.ONE, 0.3)
	AudioBus.play_sfx("boss_reveal")
	if cam != null:
		_shake(cam, cam.position)
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
func _shake(cam: Camera2D, at: Vector2, k: float = 1.0) -> void:
	var amp := _f("shake_px", 5.0) * k
	var t := create_tween()
	for i in 6:
		var fall := 1.0 - float(i) / 6.0
		t.tween_property(cam, "offset", Vector2((i % 2) * 2 - 1, (i % 3) - 1) * amp * fall, 0.04)
	t.tween_property(cam, "offset", Vector2.ZERO, 0.05)
	cam.position = at


## 띠를 걷는다(전투 화면이 덮은 뒤).
func close() -> void:
	queue_free()
