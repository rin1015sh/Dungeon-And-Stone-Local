class_name SandTremor
extends Node2D
## 모래 바다 진동 표시(바위사막 — 레벨 디자인 11차): 플레이어 발밑 둘레에 모래 알갱이가 튀고 잔물결 고리가 번진다.
## 세기 = DesertRules.tremor(진동 / 문턱 — 모래 바다 위에서만). 0이면 그리지 않는다. 문턱에 가까울수록 알갱이가 많고 크게 튀며
## 고리가 빨리 번진다(글 경고 한 줄 대신 눈으로 — UI19). 수치 = render.json view.sand_tremor. 프레임마다 원 몇십 개뿐(칸을 훑지 않는다).

var _view: FloorView
var _cfg: Dictionary = {}
var _t := 0.0
var _k := 0.0  ## 화면에 보이는 세기(진동 값을 부드럽게 따라간다)
var _rng := RandomNumberGenerator.new()


func setup(view: FloorView) -> void:
	_view = view
	_cfg = JsonUtil.get_dict(JsonUtil.get_dict(view.session.db.render, "view"), "sand_tremor")
	z_index = view.player_view.z_index
	_rng.seed = 7


func _f(k: String, d: float) -> float:
	return JsonUtil.get_float(_cfg, k, d)


func _process(delta: float) -> void:
	var s := _view.session
	var want := s.desert.tremor(s) if s.desert != null else 0.0
	_k = move_toward(_k, want, delta * _f("follow", 1.5))
	_t += delta
	position = _view.player_view.position
	visible = _k > 0.02
	if visible:
		queue_redraw()


func _draw() -> void:
	var tile := float(_view.tile)
	var r := tile * _f("radius_tiles", 1.6)
	var col := Color(str(_cfg.get("color", "#5a3c1e")))
	var grain := Color(str(_cfg.get("grain_color", "#7a5530")))
	# 잔물결 고리: 세기가 클수록 빨리 · 진하게 번진다
	var rings := 3
	var speed := _f("ring_speed", 0.6) + _k * _f("ring_speed_k", 1.4)
	for i in rings:
		var ph := fmod(_t * speed + float(i) / rings, 1.0)
		var a := (1.0 - ph) * _k * _f("ring_alpha", 0.5)
		var rr := r * (0.25 + ph * 0.75)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))  # 바닥에 눕힌 고리(3/4 시점)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 32, Color(col, a), _f("ring_width", 2.0), true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 튀는 알갱이: 시각으로 씨를 정해 깜빡이며 다른 자리에서 튄다
	var n := int(_f("grains", 26) * _k)
	var hop := _f("hop_px", 4.0) * (0.4 + _k)
	_rng.seed = int(_t * _f("grain_rate", 12.0))
	for i in n:
		var ang := _rng.randf() * TAU
		var d := sqrt(_rng.randf()) * r
		var p := Vector2(cos(ang) * d, sin(ang) * d * 0.55)
		p.y -= absf(sin(_t * 30.0 + float(i))) * hop
		draw_circle(p, _f("grain_px", 1.4) + _rng.randf() * 1.2, Color(grain, 0.45 + 0.5 * _k))
