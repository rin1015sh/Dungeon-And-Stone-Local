class_name Floor3Overlay
extends Control
## 3층 화면 연출(PilgrimRoad를 매 프레임 읽어 그린다 — 글 대화창이 아니라 그림으로, UI19):
##   지역명 띠: 구역이 바뀌면 화면 위쪽에 그 지역 이름이 잠깐 떴다 사라진다(마녀의 숲 방향치 중에는 뜨지 않는다 — 위치 안내 제한).
##   중앙 첨탑: 강철바위 언덕 · 바람결 고개(높은 땅)에서 첨탑 쪽 화면 가장자리에 멀리 솟은 첨탑 실루엣.
##   밤하늘(SkyLanterns): 은빛 구체가 화면 아래에서 떠올라 위에서 사라지고 화면이 서서히 밝아졌다 돌아온다(다른 곳에서는 옅게).
##   카나바로 전조(WitchForest.dread): 한곳에 머물수록 화면 가장자리가 짙어지고 맥박처럼 일렁인다.
##   마녀의 오두막: 드나들 때 보랏빛 안개가 화면을 덮었다 걷히고, 안에 있는 동안 남은 시간을 위에 작게.
## 수치는 render.json ui.floor3.

var _s: ExploreSession
var _cfg: Dictionary = {}
var _banner: Label
var _timer: Label
var _banner_t: float = 99.0
var _seen_since: float = -2.0
var _orbs: Array = []   ## [x 0~1, 지연 0~1, 오르는 초, 크기]
var _mist: float = 0.0
var _was_inside: bool = false
var _time: float = 0.0


func bind(s: ExploreSession) -> void:
	_s = s
	_cfg = UiTheme.ui_dict("floor3")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner = UiTheme.label("", "title", "text")
	_banner.add_theme_font_size_override("font_size", JsonUtil.get_int(_cfg, "banner_font", 30))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	add_child(_banner)
	_timer = UiTheme.label("", "small", "text_dim")
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var px := JsonUtil.get_array(_cfg, "orb_px")
	var rise := JsonUtil.get_array(_cfg, "orb_rise_sec")
	var n := JsonUtil.get_int(JsonUtil.get_dict(s.floor_def, "sky_event"), "orbs", 90)
	for i in n:
		_orbs.append([rng.randf(), rng.randf() * 0.7, rng.randf_range(float(rise[0]), float(rise[1])) if rise.size() == 2 else 12.0,
			rng.randf_range(float(px[0]), float(px[1])) if px.size() == 2 else 3.0])


func _process(delta: float) -> void:
	if _s == null or _s.pilgrim == null:
		return
	_time += delta
	var p := _s.pilgrim
	# 지역명 띠
	if p.zone_since != _seen_since:
		_seen_since = p.zone_since
		var lost := p.witch != null and p.witch.inside and _s.player.statuses.has("f3_disoriented")
		if not p.zone_name.is_empty() and not lost:
			_banner.text = p.zone_name
			_banner_t = 0.0
	_banner_t += delta
	var sec := JsonUtil.get_float(_cfg, "banner_sec", 3.2)
	var fade := JsonUtil.get_float(_cfg, "banner_fade_sec", 0.7)
	_banner.modulate.a = clampf(minf(_banner_t / fade, (sec - _banner_t) / fade), 0.0, 1.0)
	_banner.size = Vector2(size.x, 48)
	_banner.position = Vector2(0, size.y * JsonUtil.get_float(_cfg, "banner_y", 0.16))
	# 오두막
	var inside := p.hut != null and p.hut.inside()
	if inside != _was_inside:
		_was_inside = inside
		_mist = 1.0
	_mist = maxf(0.0, _mist - delta / JsonUtil.get_float(_cfg, "mist_sec", 1.4))
	_timer.visible = inside
	if inside:
		var left := p.hut.hours_left(_s)
		_timer.text = Strings.t("f3.hut_timer", {"h": int(left), "m": int(fmod(left, 1.0) * 60.0)})
		_timer.size = Vector2(size.x, 28)
		_timer.position = Vector2(0, size.y * JsonUtil.get_float(_cfg, "timer_y", 0.06))
	queue_redraw()


func _draw() -> void:
	if _s == null or _s.pilgrim == null:
		return
	var p := _s.pilgrim
	_draw_spire(p)
	_draw_sky(p)
	_draw_omen(p)
	if _mist > 0.0:
		var mc := Color(JsonUtil.get_str(_cfg, "mist_color", "#8a5ac8"))
		mc.a = _mist * 0.9
		draw_rect(Rect2(Vector2.ZERO, size), mc)


## 높은 땅에서 보이는 중앙 첨탑(첨탑 쪽 화면 가장자리 위쪽).
func _draw_spire(p: PilgrimRoad) -> void:
	if not (p.zone in ["f3_steel", "f3_windpass"]):
		return
	var d := Vector2(_s.map.center - _s.pos)
	if d.length() < 1.0:
		return
	d = d.normalized()
	var base := Vector2(clampf(size.x * (0.5 + d.x * 0.42), size.x * 0.3, size.x * 0.94), size.y * (0.4 + d.y * 0.08))  # 왼쪽 위 HUD는 비킨다
	var h := size.y * JsonUtil.get_float(_cfg, "spire_h", 0.42)
	var w := size.x * JsonUtil.get_float(_cfg, "spire_w", 0.035)
	var col := Color(JsonUtil.get_str(_cfg, "spire_color", "#2a2436"))
	col.a = JsonUtil.get_float(_cfg, "spire_alpha", 0.55)
	var pts := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.7, -h * 0.45), base + Vector2(-w * 1.1, -h * 0.5),
		base + Vector2(-w * 0.45, -h * 0.82), base + Vector2(0, -h), base + Vector2(w * 0.45, -h * 0.82), base + Vector2(w * 1.1, -h * 0.5),
		base + Vector2(w * 0.7, -h * 0.45), base + Vector2(w, 0)])
	var halo := Color(JsonUtil.get_str(_cfg, "spire_glow", "#c0a0ff"))
	halo.a = 0.08
	draw_colored_polygon(pts, col)
	draw_polyline(pts, halo * Color(1, 1, 1, 3.0), 2.0)
	var glow := Color(JsonUtil.get_str(_cfg, "spire_glow", "#c0a0ff"))
	glow.a = 0.25 + 0.15 * sin(_time * 1.3)
	draw_circle(base + Vector2(0, -h), w * 0.9, glow)


## 밤하늘: 은빛 구체가 떠올라 위에서 사라진다 + 화면이 밝아진다.
func _draw_sky(p: PilgrimRoad) -> void:
	if p.sky == null or not p.sky.active():
		return
	var k := p.sky.progress()
	var amt := 1.0 if p.sky.near(_s) else JsonUtil.get_float(p.sky.cfg(), "far_alpha", 0.25)
	var tint := Color(JsonUtil.get_str(_cfg, "sky_tint", "#c8d4ff"))
	tint.a = JsonUtil.get_float(_cfg, "sky_alpha", 0.22) * p.sky.glow() * amt
	draw_rect(Rect2(Vector2.ZERO, size), tint)
	var orb := Color(JsonUtil.get_str(p.sky.cfg(), "color", "#dce4ff"))
	var t := k * p.sky.duration()
	for o: Array in _orbs:
		var start: float = float(o[1]) * p.sky.duration()
		var u := (t - start) / float(o[2])
		if u < 0.0 or u > 1.0:
			continue
		var x := size.x * float(o[0]) + sin(t * 0.6 + float(o[0]) * 20.0) * 14.0
		var y := size.y * (1.05 - u * 1.15)
		var a := minf(1.0, u * 5.0) * (1.0 - smoothstep(0.75, 1.0, u)) * amt
		draw_circle(Vector2(x, y), float(o[3]) * 2.6, Color(orb, a * 0.18))
		draw_circle(Vector2(x, y), float(o[3]), Color(orb, a))


## 카나바로 전조: 머문 시간이 한도에 가까울수록 가장자리가 짙어지고 일렁인다.
func _draw_omen(p: PilgrimRoad) -> void:
	if p.witch == null:
		return
	var dr := p.witch.dread()
	var on := JsonUtil.get_float(p.witch.cfg(), "omen_at", 0.6)
	if dr <= on * 0.7:
		return
	var k := clampf((dr - on * 0.7) / maxf(0.01, 1.0 - on * 0.7), 0.0, 1.0)
	var col := Color(JsonUtil.get_str(_cfg, "omen_color", "#1a0826"))
	var a := JsonUtil.get_float(_cfg, "omen_alpha", 0.55) * k * (0.75 + 0.25 * sin(_time * (3.0 + 5.0 * k)))
	var band := minf(size.x, size.y) * (0.08 + 0.14 * k)
	for i in 6:
		var b := band * (1.0 - i / 6.0)
		var c := Color(col, a / 6.0 * 2.0)
		draw_rect(Rect2(0, 0, size.x, b), c)
		draw_rect(Rect2(0, size.y - b, size.x, b), c)
		draw_rect(Rect2(0, 0, b, size.y), c)
		draw_rect(Rect2(size.x - b, 0, b, size.y), c)
