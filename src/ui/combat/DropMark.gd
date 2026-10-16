class_name DropMark
extends Control
## 전투 무대에 남은 드롭(DropPickup): 정수 = 그 색으로 빛나는 구슬(천천히 떠오르내림), 전리품 = 아이템 그림 + 희미한 빛.
## 지금 묻고 있는 드롭이면 둘레에 금빛 고리가 뛴다. 고르고 나면 흐려지며 사라진다(vanish).

var drop: Dictionary = {}
var _db: GameDatabase
var _col: Color = Color.WHITE
var _t: float = 0.0
var _current: bool = false


func setup(db: GameDatabase, d: Dictionary) -> void:
	_db = db
	drop = d
	var s := float(UiTheme.metric("drop_mark_size", 64))
	size = Vector2(s, s)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if str(d.get("kind")) == "essence":
		var cid := JsonUtil.get_str(d["inst"], "color")
		for item: Variant in JsonUtil.get_array(db.tags, "essence_colors"):
			if item is Dictionary and JsonUtil.get_str(item, "id") == cid:
				_col = Color.from_string(JsonUtil.get_str(item, "color"), Color.WHITE)


func set_current(on: bool) -> void:
	_current = on
	queue_redraw()


func vanish() -> void:
	_current = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, UiTheme.ui_float("drop_vanish_sec", 0.4))
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5 + Vector2(0.0, sin(_t * 2.2) * size.y * 0.05)
	var r := size.x * 0.5
	if _current:  # 지금 묻는 드롭: 둘레 금빛 고리
		var gold := UiTheme.color("gold")
		var k := 0.5 + 0.5 * sin(_t * 6.0)
		draw_arc(c, r * (0.92 + 0.06 * k), 0.0, TAU, 40, Color(gold, 0.55 + 0.4 * k), 2.5, true)
	if str(drop.get("kind")) == "essence":
		for i in 7:  # 번지는 빛
			draw_circle(c, r * (1.0 - i * 0.11), Color(_col, 0.05 + i * 0.03))
		for i in 4:  # 도는 빛살
			var a := _t * 0.8 + i * PI * 0.5
			draw_line(c + Vector2.from_angle(a) * r * 0.25, c + Vector2.from_angle(a) * r * 0.8, Color(_col.lightened(0.4), 0.35), 1.5, true)
		draw_circle(c, r * 0.26, _col.lightened(0.35))
		draw_circle(c, r * 0.13, Color(1, 1, 1, 0.9))
		return
	draw_circle(c, r * 0.75, Color(0.9, 0.85, 0.6, 0.1))
	draw_circle(c, r * 0.5, Color(0.9, 0.85, 0.6, 0.12))
	ItemIconPainter.draw(self, _db, str(drop.get("id")), Rect2(c - Vector2(r, r) * 0.6, Vector2(r, r) * 1.2))
