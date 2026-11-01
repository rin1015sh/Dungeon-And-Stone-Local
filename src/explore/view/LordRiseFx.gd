class_name LordRiseFx
extends Node2D
## 계층군주 소환 연출(사용자 2026-11-01 "드레드피어 — 탐험 화면용으로 주변에서 구더기가 땅에서 나오며 드레드피어를 이루는 소환 애니메이션", V27).
##   ① 군주가 설 자리 둘레(radius 칸 안)의 땅이 곳곳에서 패이며 구더기가 하나씩 솟아 나온다(흙 구멍 + 튀는 흙)
##   ② 꿈틀대며 가운데로 기어 모인다(몸을 구부렸다 펴며 — 머리 쪽이 어둡다)
##   ③ 가운데에서 서로 타고 올라 더미가 솟는다(아래가 넓고 위가 좁게 — 점점 높이)
##   ④ 더미 속에서 군주가 일어선다(MonsterView를 아래에서부터 드러냄 + 붉은 빛) · 남은 구더기는 흩어지며 땅속으로 사라진다
## 끝나면 done. 그림은 코드로 그린다(마디 원 넷 + 테두리). 수치 = render.json view.lord_rise. 오토로드를 쓰지 않는다(소리는 부르는 쪽).

signal done

var _view: FloorView
var _mv: MonsterView
var _cfg: Dictionary = {}
var _t := 0.0
var _total := 3.6
var _worms: Array = []  ## {from, to, start, phase, size, side}
var _tile := 32.0
var _rng := RandomNumberGenerator.new()
const SKIN := Color("#e2d6b0")
const HEAD := Color("#6a4a3a")
const INK := Color("#1a1210")


static func play(view: FloorView, group: FieldMonsters.Group, seed_value: int) -> LordRiseFx:
	var fx := LordRiseFx.new()
	fx._view = view
	fx._mv = view.monster_view(group.id)
	fx._rng.seed = seed_value
	fx.position = view.feet_of(group.fpos)
	view.add_child(fx)
	return fx


func _f(k: String, d: float) -> float:
	return JsonUtil.get_float(_cfg, k, d)


func _ready() -> void:
	_cfg = JsonUtil.get_dict(JsonUtil.get_dict(_view.session.db.render, "view"), "lord_rise")
	_tile = _view.tile
	_total = _f("emerge_sec", 1.0) + _f("crawl_sec", 1.1) + _f("heap_sec", 0.8) + _f("rise_sec", 1.0)
	z_index = 2  # 바닥·물건 위, 같은 줄의 몸들과 함께(군주 그림보다는 앞 — 더미가 군주를 덮고 있다가 걷힌다)
	var n := int(_f("count", 34.0))
	var rad := _f("radius", 3.2) * _tile
	for i in n:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(0.35, 1.0) * rad
		var from := Vector2(cos(a), sin(a) * 0.6) * d
		var to := Vector2(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.08, 0.12)) * _tile
		_worms.append({"from": from, "to": to, "start": _rng.randf() * _f("emerge_sec", 1.0) * 0.85, "phase": _rng.randf() * TAU,
			"size": _rng.randf_range(0.75, 1.2), "side": _rng.randf_range(-1.0, 1.0), "stack": _rng.randf()})
	if _mv != null:
		_mv.modulate.a = 0.0
	if DialogueBox.auto_skip:  # 캡처·테스트: 기다리지 않는다
		_t = _total


func _process(delta: float) -> void:
	_t += minf(delta, 1.0 / 30.0)
	var rise0 := _total - _f("rise_sec", 1.0)
	if _mv != null:  # ④ 더미 속에서 일어선다: 아래에서 위로 드러나며(세로 늘임) 짙어진다 — 어둠 속이어도 붉은 빛 안에서는 보인다(끝나면 다시 시야대로)
		var u := clampf((_t - rise0) / _f("rise_sec", 1.0), 0.0, 1.0)
		_mv.visible = u > 0.0 or _mv.visible
		_mv.modulate = Color(1.0 + 0.6 * (1.0 - u), 0.85 + 0.15 * u, 0.85 + 0.15 * u, smoothstep(0.0, 0.6, u))
		_mv.scale = Vector2(1.0, lerpf(0.35, 1.0, smoothstep(0.0, 1.0, u)))
	queue_redraw()
	if _t >= _total:
		if _mv != null:
			_mv.modulate = Color.WHITE
			_mv.scale = Vector2.ONE
			_view.sync_monsters()  # 다시 시야대로(어둠 속이면 숨는다)
		set_process(false)
		done.emit()
		queue_free()


func _draw() -> void:
	var emerge := _f("emerge_sec", 1.0)
	var crawl := _f("crawl_sec", 1.1)
	var heap := _f("heap_sec", 0.8)
	var rise0 := _total - _f("rise_sec", 1.0)
	var s := _tile * _f("worm_size", 0.2)
	# 바닥의 붉은 기운(모일수록 짙게)
	var glow := clampf(_t / (emerge + crawl), 0.0, 1.0) * (1.0 - clampf((_t - rise0) / _f("rise_sec", 1.0), 0.0, 1.0) * 0.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, _tile * 1.4, Color(0.55, 0.05, 0.05, 0.28 * glow))
	draw_circle(Vector2.ZERO, _tile * 0.8, Color(0.75, 0.1, 0.08, 0.25 * glow))
	draw_set_transform(Vector2.ZERO)
	# 흙 구멍(나온 자리 — 사라지며 옅어진다)
	for w: Dictionary in _worms:
		var age := _t - float(w["start"])
		if age > 0.0 and _t < rise0 + 0.4:
			var fade := clampf(1.0 - (_t - (emerge + crawl)) / 1.0, 0.0, 1.0)
			draw_set_transform(w["from"] as Vector2, 0.0, Vector2(1.0, 0.45))
			draw_circle(Vector2.ZERO, s * 0.9 * minf(1.0, age * 4.0), Color(0.06, 0.04, 0.03, 0.75 * fade))
			draw_set_transform(Vector2.ZERO)
	# 더미(③ — 모인 구더기가 쌓인 봉우리: 아래 넓고 위 좁게, 높이가 자란다 / ④에서 무너지며 줄어든다)
	var hp := clampf((_t - (emerge + crawl * 0.6)) / (crawl * 0.4 + heap), 0.0, 1.0)
	var fall := clampf((_t - rise0) / _f("rise_sec", 1.0), 0.0, 1.0)
	var hh := _tile * _f("heap_height", 1.6) * hp * (1.0 - fall * 0.85)
	if hp > 0.0:
		var heap_rng := RandomNumberGenerator.new()
		heap_rng.seed = 7
		for k in int(40 * hp):
			var v := heap_rng.randf()  # 0 = 밑, 1 = 꼭대기
			var wide := (1.0 - v) * _tile * 0.75 + _tile * 0.12
			var p := Vector2(heap_rng.randf_range(-wide, wide), -v * hh + heap_rng.randf_range(-2.0, 2.0))
			_worm(p, heap_rng.randf() * TAU + sin(_t * 6.0 + k) * 0.6, s * heap_rng.randf_range(0.8, 1.1), _t * 8.0 + k, 1.0 - fall * 0.7)
	# 기어 오는 구더기(①·② — 더미에 닿으면 사라진다, ④에서 남은 것은 흩어진다)
	for w: Dictionary in _worms:
		var age := _t - float(w["start"])
		if age <= 0.0:
			continue
		var pop := clampf(age / 0.35, 0.0, 1.0)  # 땅에서 솟는 중
		var u := clampf((_t - emerge * 0.6 - float(w["start"]) * 0.5) / crawl, 0.0, 1.0)
		var from: Vector2 = w["from"]
		var to: Vector2 = w["to"]
		if u >= 1.0 and fall <= 0.0:
			continue  # 더미에 섞였다
		var dir := (to - from).normalized()
		var side := Vector2(-dir.y, dir.x) * sin(u * 9.0 + float(w["phase"])) * _tile * 0.12 * float(w["side"])
		var p := from.lerp(to, u * u * (3.0 - 2.0 * u)) + side
		var ang := dir.angle() + sin(_t * 10.0 + float(w["phase"])) * 0.35
		var alpha := pop
		if fall > 0.0:  # 흩어져 땅속으로
			p = to + (from - to).normalized() * fall * _tile * 1.2 * float(w["stack"]) + side
			ang = (from - to).angle()
			alpha = 1.0 - fall
		_worm(p - Vector2(0, s * 0.3 * (1.0 - pop)), ang, s * float(w["size"]) * (0.4 + 0.6 * pop), _t * 9.0 + float(w["phase"]), alpha)


## 구더기 하나: 마디 원 넷(꼬리 → 머리, 머리 쪽 어둡게) + 테두리 · 꿈틀(마디가 번갈아 부푼다).
func _worm(at: Vector2, ang: float, s: float, wig: float, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var d := Vector2.from_angle(ang)
	var n := Vector2(-d.y, d.x)
	for k in 4:
		var u := float(k) / 3.0
		var c := at + d * (u - 0.5) * s * 1.8 + n * sin(wig + k * 1.3) * s * 0.12
		var r := s * (0.32 + 0.12 * sin(u * PI)) * (1.0 + 0.08 * sin(wig * 1.7 + k))
		draw_circle(c, r + 1.0, Color(INK.r, INK.g, INK.b, alpha * 0.8))
		var col := SKIN.lerp(HEAD, 0.55) if k == 3 else SKIN.darkened(0.1 * (1 - u))
		draw_circle(c, r, Color(col.r, col.g, col.b, alpha))
		draw_circle(c - Vector2(r * 0.3, r * 0.35), r * 0.35, Color(1.0, 0.97, 0.88, alpha * 0.45))
