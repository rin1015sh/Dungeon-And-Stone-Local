class_name RevPips
extends Control
## 파티 창 이름 옆 Rev 삼각형(피어 앤 헝거 2식 — C20). 글자가 아니라 그린다(웹 글꼴에 ▲ 없음).
## 빈 칸 = 테두리만(text_dim) · 모아 둔 것 = 채움(text_dim) · 이번 행동에 얹을 것 = 뼈빛(select)으로 채우고 조금 올린다.
## 수치 = render.json ui.combat_rev{size, gap, lift}.

var _max: int = 3
var _have: int = 0
var _pick: int = 0


func _init() -> void:
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func _cfg(key: String, fallback: float) -> float:
	return JsonUtil.get_float(UiTheme.ui_dict("combat_rev"), key, fallback)


func show_rev(max_n: int, have: int, pick: int) -> void:
	if max_n == _max and have == _have and pick == _pick and custom_minimum_size.x > 0.0:
		return
	_max = maxi(0, max_n)
	_have = have
	_pick = pick
	var s := _cfg("size", 11.0)
	custom_minimum_size = Vector2(_max * s + maxi(0, _max - 1) * _cfg("gap", 3.0), s + _cfg("lift", 3.0))
	visible = _max > 0
	queue_redraw()


func _draw() -> void:
	var s := _cfg("size", 11.0)
	var gap := _cfg("gap", 3.0)
	var lift := _cfg("lift", 3.0)
	var dim := UiTheme.color("text_dim")
	for i in _max:
		var x := i * (s + gap)
		var up := i < _pick
		var y := lift - (lift if up else 0.0)
		var pts := PackedVector2Array([Vector2(x + s * 0.5, y), Vector2(x + s, y + s), Vector2(x, y + s)])
		if up:
			draw_colored_polygon(pts, UiTheme.color("select"))
		elif i < _have:
			draw_colored_polygon(pts, dim)
		else:
			var loop := pts.duplicate()
			loop.append(pts[0])
			draw_polyline(loop, dim, 1.0, true)
