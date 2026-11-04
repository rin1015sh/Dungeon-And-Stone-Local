class_name GrooveBladeView
extends Node2D
## 칼날 홈을 오가는 칼날(GrooveBlades)을 그린다 — 바닥 홈에서 반쯤 솟은 톱날이 돌며 미끄러진다. 지금 보이는 칸만.
## 홈이 남북이면 칼날 면을 비스듬히 보므로 가로로 눌러 그린다(squash_ns). 수치·색 = render.json view.groove_blade.

var view: FloorView
var _cfg: Dictionary = {}


func setup(p_view: FloorView) -> void:
	view = p_view
	_cfg = JsonUtil.get_dict(JsonUtil.get_dict(view.session.db.render, "view"), "groove_blade")
	z_index = -8  # 바닥·데칼 위, 캐릭터·벽 아래(LootView와 같은 층)


func _process(_delta: float) -> void:
	if view.session.blades != null:
		queue_redraw()


func _draw() -> void:
	var gb := view.session.blades
	if gb == null:
		return
	var map := view.session.map
	var r := view.tile * JsonUtil.get_float(_cfg, "radius", 0.42)
	var teeth := JsonUtil.get_int(_cfg, "teeth", 12)
	var spin := gb.t * JsonUtil.get_float(_cfg, "spin", 9.0)
	var steel := _col("steel", "#b4b9c2")
	var edge := _col("edge", "#eef2f6")
	var dark := _col("dark", "#24262a")
	for i in gb.runs.size():
		var p := gb.blade_at(i)
		var cell := Vector2i(floori(p.x), floori(p.y))
		if not map.in_bounds(cell) or map.visible_now[map.idx(cell)] == 0:
			continue
		var broken := bool(gb.runs[i].get("broken", false))
		var sx := JsonUtil.get_float(_cfg, "squash_ns", 0.5) if absf(gb.axis(i).y) > 0.5 else 1.0
		var base := view.feet_of(p) - Vector2(0, view.tile * JsonUtil.get_float(_cfg, "lift", 0.12))
		draw_set_transform(base, 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, r * 0.9, Color(0, 0, 0, 0.35))
		draw_set_transform(base, 0.0, Vector2(sx, 1.0))
		var rot := 0.0 if broken else spin
		draw_colored_polygon(_half_saw(r, teeth, rot), dark)
		draw_colored_polygon(_half_saw(r * 0.92, teeth, rot), steel)
		draw_arc(Vector2.ZERO, r * 0.62, PI, TAU, 18, edge, maxf(1.0, r * 0.08))
		draw_colored_polygon(_half_disc(r * 0.24), dark)
		draw_line(Vector2(-r * 1.05, 0), Vector2(r * 1.05, 0), dark, maxf(2.0, r * 0.14))  # 홈 입구
	draw_set_transform(Vector2.ZERO)


## 바닥 위로 솟은 톱날 반쪽(위쪽 반원) — rot만큼 돈 톱니.
func _half_saw(r: float, teeth: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := teeth * 4
	for k in n + 1:
		var a := PI + PI * float(k) / float(n)
		var f := fposmod((a - rot) * float(teeth) / TAU, 1.0)
		pts.append(Vector2(cos(a), sin(a)) * r * (0.8 + 0.2 * f))
	return pts


func _half_disc(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 13:
		var a := PI + PI * float(k) / 12.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _col(key: String, fallback: String) -> Color:
	return Color.html(JsonUtil.get_str(_cfg, key, fallback))
