class_name CoinFlip
extends Control
## 동전 던지기 연출(사용자 2026-11-01 "피어 앤 헝거처럼 동전 던지기 — 애니메이션은 첨부 영상 참고", V25).
## 결과(앞면 = 성공)는 로직이 이미 정했다(CoinToss) — 이 창은 그 결과대로 던져 보여 줄 뿐이다. 글은 없다(동전 면이 결과).
##   ① 화면이 조금 어두워지고 아래에서 동전이 튀어 오른다 — 비스듬한 축으로 빙글빙글 돈다(면 → 테두리 → 뒷면 …, 위로 갈수록 빠르게)
##   ② 떨어져 바닥에 닿고(소리 coin_land) 작게 한 번 더 튄다 — 도는 것이 느려지며 결과 면 쪽으로 눕는다
##   ③ 결과 면이 화면을 향해 일어서며 커진다(앞면 = 늙은 현자 얼굴, 뒷면 = 마석 문장) → 잠깐 머문 뒤 사라진다
## 그림 = assets/ui/coin/heads·tails·edge.webp(tools/paint_coin.gd). 수치 = render.json ui.coin_flip. 오토로드 AudioBus를 쓴다(UI).
## 돌리기는 그림 한 장을 눌러 그린다: 축 둘레 각 θ — 보이는 면 = cos θ의 부호, 세로 눌림 = |cos θ|, 두께 = sin θ만큼 뒤 면을 밀어 그 사이를 테두리로 메운다.

signal done

var heads: bool = true
var _cfg: Dictionary = {}
var _tex := {}  ## "heads"/"tails"/"edge" → Texture2D
var _t := 0.0
var _total := 2.6
var _shade := 0.0
var _spin_turns := 6  ## 튀어 오르는 동안 반 바퀴 수(결과 면으로 끝나게 짝·홀을 맞춘다)


## parent 위에 띄우고 끝날 때까지 기다린다(끝나면 스스로 사라진다).
static func play(parent: Control, p_heads: bool) -> void:
	var c := CoinFlip.new()
	c.heads = p_heads
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await c.done


func _ready() -> void:
	_cfg = UiTheme.ui_dict("coin_flip")
	var dir := JsonUtil.get_str(_cfg, "dir", "res://assets/ui/coin")
	for k in ["heads", "tails", "edge"]:
		var path := "%s/%s.webp" % [dir, k]
		_tex[k] = load(path) if ResourceLoader.exists(path) else null
	_total = _f("toss_sec", 1.15) + _f("bounce_sec", 0.45) + _f("rise_sec", 0.4) + _f("hold_sec", 0.7) + _f("fade_sec", 0.25)
	_spin_turns = int(_f("half_turns", 9.0))
	if _spin_turns % 2 == 0:  # 튄 뒤 반 바퀴 더 돌아 결과 면으로 눕는다 — 그래서 홀수
		_spin_turns += 1
	AudioBus.play_sfx("coin_toss")
	if DialogueBox.auto_skip:  # 캡처·테스트: 기다리지 않는다
		_t = _total


func _f(key: String, fallback: float) -> float:
	return JsonUtil.get_float(_cfg, key, fallback)


func _process(delta: float) -> void:
	var before := _t
	_t += minf(delta, 1.0 / 30.0)  # 그림을 처음 부르는 프레임이 길어도 연출을 건너뛰지 않게
	var land := _f("toss_sec", 1.15)
	if before < land and _t >= land:
		AudioBus.play_sfx("coin_land")
	queue_redraw()
	if _t >= _total:
		set_process(false)
		done.emit()
		queue_free()


## 지금 시각의 (위치 오프셋 y(위 = 음수, 바닥 = 0), 축 둘레 각 θ, 눕힌 기울기 φ, 크기 배율, 바닥 그림자 세기).
func _pose() -> Array:
	var toss := _f("toss_sec", 1.15)
	var bounce := _f("bounce_sec", 0.45)
	var rise := _f("rise_sec", 0.4)
	var hgt := size.y * _f("height_ratio", 0.42)
	var end_theta := 0.0 if heads else PI
	var spun := end_theta + PI * _spin_turns + PI * 0.35  # 튀어 오르는 동안 돌 각(끝에서 조금 덜 돈 채 떨어진다)
	var flat := end_theta + PI * (_spin_turns + 1)  # 결과 면이 정면(θ ≡ 0 앞면 · π 뒷면)
	var lie := acos(_f("lie_squash", 0.38))  # 바닥에 누운 결과 면의 기울기
	if _t < toss:  # ① 위로 갔다 내려온다(포물선) · 처음엔 빠르게 돌다 점점 느리게
		var u := _t / toss
		var y := -hgt * 4.0 * u * (1.0 - u)
		var theta := spun * (1.0 - pow(1.0 - u, 1.6))
		return [y, theta, 0.35 + 0.25 * sin(u * 7.0), 1.0, 1.0 - 4.0 * u * (1.0 - u) * 0.7]
	var t := _t - toss
	if t < bounce:  # ② 작게 한 번 튄다 · 반 바퀴쯤 더 돌아 결과 면으로 눕는다
		var u := t / bounce
		var y := -hgt * 0.12 * 4.0 * u * (1.0 - u)
		var theta := lerpf(spun, flat + lie, smoothstep(0.0, 1.0, u))
		return [y, theta, 0.35, 1.0, 0.9]
	t -= bounce
	var u2 := smoothstep(0.0, 1.0, clampf(t / rise, 0.0, 1.0))  # ③ 일어서며 커진다(정면 = θ 0 또는 π)
	return [-hgt * 0.18 * u2, flat + lie * (1.0 - u2), 0.35 * (1.0 - u2), lerpf(1.0, _f("end_scale", 1.7), u2), 0.9 * (1.0 - u2)]


func _draw() -> void:
	var a := 1.0
	var fade := _f("fade_sec", 0.25)
	if _t > _total - fade:
		a = clampf((_total - _t) / fade, 0.0, 1.0)
	var shade_in := clampf(_t / 0.2, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, _f("shade_alpha", 0.45) * shade_in * a))
	var p := _pose()
	var ground := Vector2(size.x * 0.5, size.y * _f("ground_ratio", 0.62))
	var r := size.y * _f("radius_ratio", 0.075) * float(p[3])
	var theta: float = p[1]
	var tilt: float = p[2]
	var shadow: float = p[4]
	if shadow > 0.01:  # 바닥 그림자(높이 오를수록 작고 옅게)
		draw_set_transform(ground + Vector2(0, r * 0.85), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, r * (0.6 + 0.4 * shadow), Color(0, 0, 0, 0.45 * shadow * a))
		draw_set_transform(Vector2.ZERO)
	_coin(ground + Vector2(0, float(p[0])), r, theta, tilt, a)


## 동전 하나: 가운데 c, 반지름 r, 축 둘레 각 theta, 화면 안 기울기 tilt.
func _coin(c: Vector2, r: float, theta: float, tilt: float, a: float) -> void:
	var cs := cos(theta)
	var squash := maxf(0.04, absf(cs))
	var thick := r * _f("thick_ratio", 0.12)
	var push := Vector2(0, sin(theta) * thick).rotated(tilt)  # 앞 면과 뒤 면 사이(두께)
	var front: Texture2D = _tex.get("heads" if cs >= 0.0 else "tails")
	var edge: Texture2D = _tex.get("edge")
	var dark := Color(0.32, 0.25, 0.14, a)
	# 뒤 면(어두운 원판) → 테두리 띠 → 앞 면
	draw_set_transform(c + push, tilt, Vector2(1.0, squash))
	draw_circle(Vector2.ZERO, r, dark)
	draw_set_transform(Vector2.ZERO)
	var ax := Vector2(r, 0).rotated(tilt)
	var band := PackedVector2Array([c - ax, c + ax, c + ax + push, c - ax + push])
	if edge != null:
		draw_colored_polygon(band, Color(1, 1, 1, a), PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), edge)
	else:
		draw_colored_polygon(band, dark)
	draw_set_transform(c, tilt, Vector2(1.0, squash))
	if front != null:
		var light := 0.55 + 0.45 * squash  # 비스듬할수록 어둡게(빛을 덜 받는다)
		draw_texture_rect(front, Rect2(-Vector2(r, r), Vector2(r, r) * 2.0), false, Color(light, light, light, a))
	else:
		draw_circle(Vector2.ZERO, r, Color(0.8, 0.65, 0.3, a))
	draw_set_transform(Vector2.ZERO)
