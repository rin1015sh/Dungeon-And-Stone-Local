class_name FieldFx
extends Node2D
## 탐험 맵의 짧은 움직임(글 대신 화면으로 — 2026-11-08 점검 §2): 세션 신호 fx(kind, at, group_id)를 FloorView가 받아 이 노드를 띄운다.
##   bang  = 무리 머리 위 "!"(쫓기 시작 · 매복 · 경보로 깨어남 — 튀어 올랐다 잠시 머문다)
##   rings = 경보를 낸 자리에서 퍼지는 고리(망대 · 봉화대 · 까마귀 · 북잡이 · 다리목 해골)
##   burst = 땅 · 벽 · 모래가 터지며 흙먼지(매복 · 무덤에서 일어남 · 샌드웜 · 발밑이 꺼짐)
##   snap  = 덫이 튐(바닥에서 솟는 날 · 먼지)
##   stars = 머리 위를 도는 별(멧돼지가 벽에 박혀 비틀거림)
## 그림은 코드로(텍스처 없음), 색은 render.json view.field_fx. 끝나면 스스로 사라진다.

const LIFE := {"bang": 1.4, "rings": 1.6, "burst": 0.9, "snap": 0.6, "stars": 1.8}

var kind: String = "bang"
var head_px: float = 40.0   ## 머리 높이(무리 그림 키 — bang · stars)
var tile: float = 32.0
var col: Color = Color("#e8dcc0")
var _t: float = 0.0
var _seeds: Array[Vector2] = []


func setup(p_kind: String, p_tile: float, p_head: float, colors: Dictionary) -> void:
	kind = p_kind
	tile = p_tile
	head_px = p_head
	col = Color.from_string(str(colors.get(kind, "#e8dcc0")), col)
	z_index = 200
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(get_instance_id()))
	for i in 10:
		_seeds.append(Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(0.3, 1.0)))


func _process(delta: float) -> void:
	_t += delta
	if _t >= float(LIFE.get(kind, 1.0)):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var life := float(LIFE.get(kind, 1.0))
	var k := clampf(_t / life, 0.0, 1.0)
	match kind:
		"bang":
			var pop := minf(1.0, _t / 0.12)
			var y := -head_px - 4.0 - 4.0 * pop + (2.0 * sin(_t * 9.0) if _t > 0.15 else 0.0)
			var a := 1.0 if k < 0.75 else (1.0 - k) / 0.25
			_bang(Vector2(0, y), 0.6 + 0.2 * (1.0 - pop), Color(col, a))
		"rings":
			for i in 3:
				var kk := clampf(k * 1.4 - i * 0.2, 0.0, 1.0)
				if kk <= 0.0:
					continue
				var r := lerpf(tile * 0.4, tile * 4.0, kk)
				draw_arc(Vector2(0, -tile * 0.3), r, 0.0, TAU, 40, Color(col, (1.0 - kk) * 0.8), 2.0)
		"burst":
			for s in _seeds:
				var d := Vector2(s.x, -s.y) * tile * (0.4 + 1.3 * k)
				draw_circle(d + Vector2(0, tile * 0.1 * k * k), tile * 0.22 * (1.0 - k * 0.6), Color(col, 0.75 * (1.0 - k)))
			for i in 6:  # 갈라지는 금
				var ang := TAU * i / 6.0 + 0.3
				draw_line(Vector2.ZERO, Vector2(cos(ang), sin(ang) * 0.5) * tile * 0.9 * minf(1.0, k * 3.0), Color(col.darkened(0.6), 1.0 - k), 2.0)
		"snap":
			var up := minf(1.0, k * 4.0)
			for i in 5:
				var x := (i - 2) * tile * 0.18
				draw_line(Vector2(x, 0), Vector2(x * 1.2, -tile * 0.55 * up), Color(col, 1.0 - k), 2.5)
			draw_circle(Vector2.ZERO, tile * 0.5 * k, Color(col.darkened(0.5), 0.5 * (1.0 - k)))
		"stars":
			var a2 := 1.0 if k < 0.8 else (1.0 - k) / 0.2
			for i in 3:
				var ang := _t * 5.0 + TAU * i / 3.0
				_star(Vector2(cos(ang) * tile * 0.45, -head_px - 4.0 + sin(ang) * tile * 0.15), 4.0, Color(col, a2))


## "!" 글자 대신 그린 모양(웹 글꼴 걱정 없이): 위가 굵은 막대 + 점, 검은 테.
func _bang(c: Vector2, s: float, cl: Color) -> void:
	var bar := PackedVector2Array([c + Vector2(-3.5, -14) * s, c + Vector2(3.5, -14) * s, c + Vector2(2, 0) * s, c + Vector2(-2, 0) * s])
	draw_colored_polygon(bar, Color(0.05, 0.03, 0.02, cl.a))
	var inner := PackedVector2Array([c + Vector2(-2.2, -12.8) * s, c + Vector2(2.2, -12.8) * s, c + Vector2(1.1, -1.2) * s, c + Vector2(-1.1, -1.2) * s])
	draw_colored_polygon(inner, cl)
	draw_circle(c + Vector2(0, 5) * s, 3.2 * s, Color(0.05, 0.03, 0.02, cl.a))
	draw_circle(c + Vector2(0, 5) * s, 2.0 * s, cl)


func _star(c: Vector2, r: float, cl: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + PI * i / 5.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, cl)
