class_name ItemIconPainter
extends RefCounted
## 아이템 그림(스프라이트가 없을 때의 임시 도형). 아이템 icon 종류 + color로 rect 안에 그린다.
## 스프라이트(items/<id>.json sprite)가 있으면 그것을 쓴다.
## 종류: sword mace spear dagger bow shield armor cloak hood helmet gloves belt boots ring amulet
##       potion food bread torch stone scroll pouch


static func draw(c: CanvasItem, db: GameDatabase, item_id: String, r: Rect2, alpha: float = 1.0) -> void:
	var sprite := JsonUtil.get_str(ItemInfo.def(db, item_id), "sprite")
	if not sprite.is_empty() and ResourceLoader.exists(sprite):
		c.draw_texture_rect(load(sprite) as Texture2D, r, false, Color(1, 1, 1, alpha))
		return
	var col := ItemInfo.color(db, item_id)
	col.a = alpha
	paint(c, ItemInfo.icon(db, item_id), r.grow(-maxf(2.0, minf(r.size.x, r.size.y) * 0.08)), col)


## 칸 종류의 빈 실루엣(장비 인형의 빈 칸).
static func paint_ghost(c: CanvasItem, kind: String, r: Rect2) -> void:
	paint(c, kind, r.grow(-minf(r.size.x, r.size.y) * 0.18), Color(1, 1, 1, 0.07))


static func paint(c: CanvasItem, kind: String, r: Rect2, col: Color) -> void:
	var dark := Color(col.darkened(0.45), col.a)
	var light := Color(col.lightened(0.3), col.a)
	var cx := r.get_center().x
	var w := r.size.x
	var h := r.size.y
	var x := r.position.x
	var y := r.position.y
	match kind:
		"sword", "dagger":
			var blade_end := y + h * (0.62 if kind == "sword" else 0.55)
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx, y), Vector2(cx + w * 0.11, y + h * 0.1),
				Vector2(cx + w * 0.11, blade_end), Vector2(cx - w * 0.11, blade_end), Vector2(cx - w * 0.11, y + h * 0.1)]), light)
			c.draw_line(Vector2(cx, y + h * 0.08), Vector2(cx, blade_end), dark, 1.0)
			c.draw_rect(Rect2(cx - w * 0.32, blade_end, w * 0.64, h * 0.05), Color(0.55, 0.45, 0.3, col.a))
			c.draw_rect(Rect2(cx - w * 0.07, blade_end + h * 0.05, w * 0.14, h * 0.26), Color(0.35, 0.24, 0.16, col.a))
			c.draw_circle(Vector2(cx, blade_end + h * 0.33), w * 0.1, Color(0.55, 0.45, 0.3, col.a))
		"mace":
			c.draw_rect(Rect2(cx - w * 0.07, y + h * 0.3, w * 0.14, h * 0.68), Color(0.4, 0.28, 0.18, col.a))
			c.draw_circle(Vector2(cx, y + h * 0.18), w * 0.3, col)
			for k in 6:
				var a := TAU * k / 6.0
				c.draw_circle(Vector2(cx, y + h * 0.18) + Vector2(cos(a), sin(a)) * w * 0.3, w * 0.08, light)
		"spear":
			c.draw_rect(Rect2(cx - w * 0.06, y + h * 0.16, w * 0.12, h * 0.84), Color(0.45, 0.32, 0.2, col.a))
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx, y), Vector2(cx + w * 0.2, y + h * 0.13),
				Vector2(cx, y + h * 0.19), Vector2(cx - w * 0.2, y + h * 0.13)]), light)
		"bow":
			var pts := PackedVector2Array()
			for k in 13:
				var t := k / 12.0
				pts.append(Vector2(x + w * (0.3 + 0.45 * sin(t * PI)), y + h * t))
			c.draw_polyline(pts, col, maxf(2.0, w * 0.08))
			c.draw_line(Vector2(x + w * 0.3, y), Vector2(x + w * 0.3, y + h), Color(0.85, 0.82, 0.75, col.a), 1.0)
		"shield":
			var pts := PackedVector2Array([Vector2(x + w * 0.1, y + h * 0.08), Vector2(x + w * 0.9, y + h * 0.08),
				Vector2(x + w * 0.9, y + h * 0.5), Vector2(cx, y + h * 0.95), Vector2(x + w * 0.1, y + h * 0.5)])
			c.draw_colored_polygon(pts, col)
			pts.append(pts[0])
			c.draw_polyline(pts, Color(0.55, 0.55, 0.6, col.a), maxf(2.0, w * 0.06))
			c.draw_circle(Vector2(cx, y + h * 0.42), w * 0.1, Color(0.6, 0.6, 0.65, col.a))
		"armor", "cloak":
			var flare := 0.5 if kind == "cloak" else 0.38
			c.draw_colored_polygon(PackedVector2Array([Vector2(x + w * 0.28, y + h * 0.04), Vector2(x + w * 0.72, y + h * 0.04),
				Vector2(x + w * 0.96, y + h * 0.22), Vector2(cx + w * flare, y + h * 0.96), Vector2(cx - w * flare, y + h * 0.96),
				Vector2(x + w * 0.04, y + h * 0.22)]), col)
			c.draw_line(Vector2(cx, y + h * 0.1), Vector2(cx, y + h * 0.9), dark, 1.0)
			c.draw_rect(Rect2(x + w * 0.36, y + h * 0.02, w * 0.28, h * 0.08), dark)
		"hood", "helmet":
			c.draw_circle(Vector2(cx, y + h * 0.48), w * 0.38, col)
			c.draw_rect(Rect2(x + w * 0.12, y + h * 0.48, w * 0.76, h * 0.38), col)
			c.draw_rect(Rect2(x + w * 0.3, y + h * 0.42, w * 0.4, h * 0.36), Color(0.05, 0.05, 0.06, col.a) if kind == "hood" else dark)
		"gloves":
			for k in 2:
				var gx := x + w * (0.08 + 0.46 * k)
				c.draw_rect(Rect2(gx, y + h * 0.3, w * 0.38, h * 0.62), col)
				for f in 3:
					c.draw_rect(Rect2(gx + w * 0.02 + f * w * 0.12, y + h * 0.1, w * 0.1, h * 0.24), col)
		"belt":
			c.draw_rect(Rect2(x, r.get_center().y - h * 0.18, w, h * 0.36), col)
			c.draw_rect(Rect2(cx - w * 0.12, r.get_center().y - h * 0.26, w * 0.24, h * 0.52), Color(0.7, 0.6, 0.3, col.a), false, 2.0)
		"boots":
			for k in 2:
				var bx := x + w * (0.06 + 0.48 * k)
				c.draw_rect(Rect2(bx, y + h * 0.1, w * 0.26, h * 0.7), col)
				c.draw_rect(Rect2(bx, y + h * 0.68, w * 0.42, h * 0.22), dark)
		"ring":
			c.draw_arc(r.get_center(), minf(w, h) * 0.32, 0.0, TAU, 24, col, maxf(2.0, w * 0.12))
			c.draw_circle(r.get_center() - Vector2(0, minf(w, h) * 0.32), minf(w, h) * 0.1, light)
		"amulet":
			c.draw_arc(Vector2(cx, y + h * 0.3), w * 0.3, 0.0, PI, 16, Color(0.6, 0.55, 0.45, col.a), 1.5)
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx, y + h * 0.55), Vector2(cx + w * 0.18, y + h * 0.75),
				Vector2(cx, y + h * 0.98), Vector2(cx - w * 0.18, y + h * 0.75)]), col)
		"potion":
			c.draw_circle(Vector2(cx, y + h * 0.64), w * 0.32, Color(0.75, 0.8, 0.85, 0.5 * col.a))
			c.draw_circle(Vector2(cx, y + h * 0.68), w * 0.26, col)
			c.draw_rect(Rect2(cx - w * 0.1, y + h * 0.12, w * 0.2, h * 0.24), Color(0.75, 0.8, 0.85, 0.6 * col.a))
			c.draw_rect(Rect2(cx - w * 0.13, y + h * 0.06, w * 0.26, h * 0.08), Color(0.5, 0.36, 0.22, col.a))
		"food", "bread":
			c.draw_circle(Vector2(cx, y + h * 0.55), w * 0.38, col)
			c.draw_circle(Vector2(cx - w * 0.1, y + h * 0.48), w * 0.16, light)
			if kind == "food":
				c.draw_rect(Rect2(x + w * 0.1, y + h * 0.7, w * 0.8, h * 0.12), dark)
		"torch":
			c.draw_rect(Rect2(cx - w * 0.1, y + h * 0.3, w * 0.2, h * 0.7), col)
			c.draw_circle(Vector2(cx, y + h * 0.22), w * 0.22, Color(1.0, 0.6, 0.2, col.a))
			c.draw_circle(Vector2(cx, y + h * 0.18), w * 0.12, Color(1.0, 0.9, 0.5, col.a))
		"stone":
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx, y + h * 0.08), Vector2(x + w * 0.88, y + h * 0.4),
				Vector2(x + w * 0.7, y + h * 0.92), Vector2(x + w * 0.3, y + h * 0.92), Vector2(x + w * 0.12, y + h * 0.4)]), col)
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx, y + h * 0.08), Vector2(x + w * 0.62, y + h * 0.42),
				Vector2(x + w * 0.38, y + h * 0.42)]), light)
		"scroll":
			c.draw_rect(Rect2(x + w * 0.1, y + h * 0.3, w * 0.8, h * 0.4), col)
			c.draw_circle(Vector2(x + w * 0.1, y + h * 0.5), h * 0.2, dark)
			c.draw_circle(Vector2(x + w * 0.9, y + h * 0.5), h * 0.2, dark)
		_:
			c.draw_circle(Vector2(cx, y + h * 0.58), w * 0.36, col)
			c.draw_rect(Rect2(cx - w * 0.14, y + h * 0.12, w * 0.28, h * 0.2), dark)
