class_name MawView
extends Node2D
## 아귀 입(MawTraps)을 그린다 — 땅에 박힌 거대한 입. 다물었을 때 = 살덩이 둔덕 위 이빨 끝이 맞물린 금,
## 벌어질수록 입술이 위아래로 젖혀지고 안쪽 검붉은 목구멍 · 둘레 이빨 줄이 드러난다. 보이거나 지나온 칸만. 수치 · 색 = render.json view.maw.

var view: FloorView
var _cfg: Dictionary = {}


func setup(p_view: FloorView) -> void:
	view = p_view
	_cfg = JsonUtil.get_dict(JsonUtil.get_dict(view.session.db.render, "view"), "maw")
	z_index = -8  # 바닥 위, 캐릭터 아래(칼날 홈과 같은 층)


func _process(_delta: float) -> void:
	if view.session.maws != null:
		queue_redraw()


func _draw() -> void:
	var m := view.session.maws
	if m == null:
		return
	var map := view.session.map
	var rx := view.tile * JsonUtil.get_float(_cfg, "half_width", 1.3)
	var ry := rx * JsonUtil.get_float(_cfg, "squash", 0.5)
	var flesh := _col("flesh", "#5a2a26")
	var lip := _col("lip", "#7a3a32")
	var throat := _col("throat", "#140405")
	var tooth := _col("tooth", "#d8ccb0")
	var gum := _col("gum", "#8a2a2a")
	for i in m.cells.size():
		var c := m.cells[i]
		if not map.in_bounds(c) or map.explored[map.idx(c)] == 0:
			continue
		var lit := view.vertex_mul(c.x, c.y, Color(0.5, 0.5, 0.5))
		var shade := Color(clampf(lit.r, 0.25, 1.4), clampf(lit.g, 0.25, 1.4), clampf(lit.b, 0.25, 1.4))
		var k := m.openness(i)
		var base := view.feet_of(Vector2(c) + Vector2(0.5, 0.5))
		draw_set_transform(base)
		draw_colored_polygon(_ellipse(Vector2(0, ry * 0.25), rx * 1.25, ry * 1.15), Color(0, 0, 0, 0.35))
		draw_colored_polygon(_ellipse(Vector2.ZERO, rx * 1.15, ry * 1.05), flesh * shade)  # 살덩이 둔덕
		var open_h := ry * 0.95 * k
		if k > 0.02:
			draw_colored_polygon(_mouth(rx, open_h + ry * 0.12), gum * shade)
			draw_colored_polygon(_mouth(rx * 0.86, open_h), throat)
			_teeth(rx * 0.9, open_h, tooth * shade, -1.0)  # 윗니(아래로)
			_teeth(rx * 0.9, open_h, tooth * shade, 1.0)   # 아랫니(위로)
		draw_polyline(_lip(rx, -open_h), lip * shade, maxf(2.0, view.tile * 0.12))
		draw_polyline(_lip(rx, open_h), lip * shade, maxf(2.0, view.tile * 0.12))
		if k <= 0.02:  # 다문 이빨 끝
			for j in 9:
				var x := -rx * 0.8 + rx * 1.6 * float(j) / 8.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 0), Vector2(x, -4 - (j % 2) * 2), Vector2(x + 3, 0)]), tooth * shade)
	draw_set_transform(Vector2.ZERO)


## 입술 선: 가로 폭 rx, 가운데가 dy만큼 벌어진 활 모양.
func _lip(rx: float, dy: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for j in 17:
		var u := -1.0 + 2.0 * float(j) / 16.0
		pts.append(Vector2(u * rx, dy * (1.0 - u * u)))
	return pts


## 벌어진 입 안(위아래 활 사이).
func _mouth(rx: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for j in 17:
		var u := -1.0 + 2.0 * float(j) / 16.0
		pts.append(Vector2(u * rx, -h * (1.0 - u * u)))
	for j in range(16, -1, -1):
		var u := -1.0 + 2.0 * float(j) / 16.0
		pts.append(Vector2(u * rx, h * (1.0 - u * u)))
	return pts


## 이빨 줄: 입술 활을 따라 안쪽(목구멍 쪽)을 향한 세모. side -1 = 윗니, +1 = 아랫니.
func _teeth(rx: float, h: float, col: Color, side: float) -> void:
	var n := 11
	for j in n:
		var u := -0.9 + 1.8 * (float(j) + 0.5) / float(n)
		var y := side * h * (1.0 - u * u)
		var len := (0.35 + 0.25 * float((j * 7) % 3) / 2.0) * h * (1.0 - absf(u) * 0.5) + 2.0
		var w := rx * 1.6 / float(n) * 0.45
		draw_colored_polygon(PackedVector2Array([Vector2(u * rx - w, y), Vector2(u * rx, y - side * len), Vector2(u * rx + w, y)]), col)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for j in 28:
		var a := TAU * float(j) / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _col(key: String, fallback: String) -> Color:
	return Color.html(JsonUtil.get_str(_cfg, key, fallback))
