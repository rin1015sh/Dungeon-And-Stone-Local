extends RefCounted
## 시설 실내 벽 층 장식(RoomPaint 전용): 벽 재질(RoomMaterials.wall) · 벽 윗면 · 벽 장식 무리(style — 앞에서 본 벽이라
## 도시 실내 일러스트 부품 InteriorBits·Props를 그대로 쓴다): glass 색유리 · window 창 · books 책장 · book_ladder 책장 사다리 · sealed 봉인된 책장 ·
## shelf_bottles/jars/boxes 선반 · board 게시판·포고문 · chart 등급표 · banner 깃발 · shields 방패 · trophy 박제·뿔 · niche 아치 벽감 · statue 성인상 ·
## curtain 휘장 · bones 납골 벽 · barrels 술통 벽 · hanging 매단 고기·약초 · clock 벽시계 · vault 금고 문 · pillar_gold 금빛 기둥 · tools 연장 ·
## weapons 무기 벽 · hearth 난로 · stove 아궁이 · hood 화덕 덮개 · door_shut 닫힌 문.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Props := preload("res://tools/city_art/Props.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")
const RoomMaterials := preload("res://tools/city_art/RoomMaterials.gd")


static func material(p: Paint, wall: String, t: int) -> Callable:
	return RoomMaterials.wall(p, wall, t)


static func top_shader(p: Paint) -> Callable:
	return func(x: int, y: int) -> Color: return p.vary(Color("#3a3530").lerp(Color("#4c463e"), p.nz("cell", x, y) * 0.6), x, y, 0.12)


static func decorate(p: Paint, rows: PackedStringArray, legend: Dictionary, t: int) -> void:
	for g: Dictionary in CityRoom.groups(rows, legend, ["walldeco"]):
		var d := JsonUtil.get_dict(legend, str(g["char"]))
		var rc: Rect2i = g["rect"]
		var r := Rect2(rc.position * t, rc.size * t)
		var col := Color.from_string(JsonUtil.get_str(d, "color", "#6a5a4a"), Color("#6a5a4a"))
		match JsonUtil.get_str(d, "style"):
			"glass":
				if rc.size.x >= 6:  # 세 폭(가운데가 높고 금빛 상)
					var pw := r.size.x / 3.0
					for k in 3:
						var top := t * (0.05 if k == 1 else 0.35)
						_stained(p, Rect2(r.position.x + k * pw + 4, r.position.y + top, pw - 8, r.size.y - top - 4))
					_figure(p, Vector2(r.get_center().x, r.end.y - 8), r.size.y * 0.7, Color("#c8a040"))
				else:
					_stained(p, r.grow(-t * 0.1))
			"window":
				RoomArt.window(p, r.position.x + r.size.x * 0.18, r.position.y + t * 0.15, r.size.x * 0.64, r.size.y - t * 0.3)
			"books", "book_ladder", "sealed":
				_bookcase(p, r.grow(-2), t)
				if JsonUtil.get_str(d, "style") == "book_ladder":
					for k in 2:
						Ink.line(p, Vector2(r.position.x + r.size.x * (0.3 + k * 0.4), r.position.y + 4), Vector2(r.position.x + r.size.x * (0.2 + k * 0.4), r.end.y - 2), 4.0, Color("#7a5a3a"), 1.0, 0.2)
					for k in 5:
						var f := (k + 0.5) / 5.0
						Ink.line(p, Vector2(r.position.x + r.size.x * (0.3 - 0.1 * f), r.position.y + 4 + (r.size.y - 6) * f), Vector2(r.position.x + r.size.x * (0.7 - 0.1 * f), r.position.y + 4 + (r.size.y - 6) * f), 3.0, Color("#6a4a2e"), 1.0, 0.1)
				if JsonUtil.get_str(d, "style") == "sealed":
					for k in 3:
						Ink.line(p, Vector2(r.position.x, r.position.y + r.size.y * (0.25 + k * 0.25)), Vector2(r.end.x, r.position.y + r.size.y * (0.2 + k * 0.25)), 3.0, Color("#6a6e72"), 0.95, 0.4)
			"shelf_bottles", "shelf_jars", "shelf_boxes":
				var kinds := {"shelf_bottles": ["bottles", "jars"], "shelf_jars": ["jars", "bottles"], "shelf_boxes": ["boxes", "jars"]}[JsonUtil.get_str(d, "style")] as Array
				var n := maxi(1, int(r.size.y / (t * 0.95)))
				for k in n + 1:
					Bits.shelf_row(p, r.position.x + 2, r.position.y + k * r.size.y / (n + 1) - t * 0.3, r.size.x - 4, str(kinds[k % 2]))
			"board":
				_board(p, r.grow(-t * 0.12))
			"chart":
				p.fill_rect(r.position.x + 6, r.position.y + 6, r.size.x - 12, r.size.y - 12, p.flat(Color("#b8a47c"), 0.1))
				for k in 9:
					var yy := r.position.y + 10 + k * (r.size.y - 20) / 9.0
					p.fill_rect(r.position.x + 12, yy, (r.size.x - 24) * (0.3 + k * 0.07), 3, p.flat(Color("#5a2a1a").lerp(Color("#a88a3a"), k / 8.0), 0.05))
				Ink.path(p, Paint.rect_poly(r.position.x + 6, r.position.y + 6, r.size.x - 12, r.size.y - 12), 1.6)
			"banner":
				var cx := r.position.x + r.size.x * 0.5
				var cloth := Paint.poly([Vector2(cx - r.size.x * 0.32, r.position.y + 6), Vector2(cx + r.size.x * 0.32, r.position.y + 6), Vector2(cx + r.size.x * 0.32, r.end.y - t * 0.3), Vector2(cx, r.end.y - 4), Vector2(cx - r.size.x * 0.32, r.end.y - t * 0.3)])
				p.fill_poly(cloth, p.flat(col, 0.15))
				Ink.shade(p, cloth, Vector2(cx - r.size.x * 0.3, 0), Vector2(cx + r.size.x * 0.3, 0), 0.0, 0.35)
				Ink.path(p, cloth, 1.6)
				Bits.shield(p, Vector2(cx, r.position.y + r.size.y * 0.42), minf(r.size.x * 0.18, t * 0.3))
			"shields":
				var n := maxi(1, rc.size.x)
				for k in n:
					Bits.shield(p, Vector2(r.position.x + (k + 0.5) * r.size.x / n, r.position.y + r.size.y * 0.5), t * 0.36)
			"trophy":
				_trophy(p, Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.45), t, col)
			"niche", "statue":
				var arch := Paint.arch_poly(r.position.x + r.size.x * 0.15, r.position.y + 4, r.size.x * 0.7, r.size.y - 6, false)
				p.fill_poly(arch, p.flat(Color("#16120e"), 0.08))
				Ink.path(p, arch, 2.0)
				if JsonUtil.get_str(d, "style") == "statue":
					var cx := r.position.x + r.size.x * 0.5
					var fig := Paint.poly([Vector2(cx - t * 0.22, r.end.y - 4), Vector2(cx - t * 0.16, r.position.y + r.size.y * 0.35), Vector2(cx, r.position.y + r.size.y * 0.18), Vector2(cx + t * 0.16, r.position.y + r.size.y * 0.35), Vector2(cx + t * 0.22, r.end.y - 4)])
					p.fill_poly(fig, p.flat(col, 0.12))
					Ink.shade(p, fig, Vector2(cx - t * 0.2, 0), Vector2(cx + t * 0.2, 0), 0.0, 0.5)
					Ink.path(p, fig, 1.4)
			"curtain":
				p.fill_rect(r.position.x, r.position.y + 2, r.size.x, r.size.y - 2, func(x: int, y: int) -> Color:
					var fold := 0.5 + 0.5 * sin((x - r.position.x) * TAU / (t * 0.45))
					return p.vary(col.darkened(0.35 * (1.0 - fold)), x, y, 0.1))
				Ink.line(p, r.position + Vector2(0, 3), Vector2(r.end.x, r.position.y + 3), 4.0, Color("#8a6a2a"), 1.0, 0.1)
			"bones":
				p.fill_rect(r.position.x, r.position.y, r.size.x, r.size.y, p.flat(Color("#2a2620"), 0.1))
				var sx := r.position.x + t * 0.25
				while sx < r.end.x - 4:
					var sy := r.position.y + t * 0.3
					while sy < r.end.y - 4:
						if p.rng.randf() < 0.45:
							Bits.skull(p, Vector2(sx, sy), t * 0.13)
						else:
							Ink.line(p, Vector2(sx - t * 0.18, sy), Vector2(sx + t * 0.18, sy + p.rng.randf_range(-3, 3)), 4.0, col, 1.0, 0.2)
						sy += t * 0.4
					sx += t * 0.42
			"barrels":
				var sx := r.position.x + t * 0.3
				while sx < r.end.x:
					for row in 2:
						var c := Vector2(sx + row * t * 0.15, r.position.y + t * (0.55 + row * 0.9))
						p.fill_poly(_circle(c, t * 0.28), p.flat(col, 0.15))
						Ink.path(p, _circle(c, t * 0.28), 2.0)
						Ink.path(p, _circle(c, t * 0.1), 1.2, true, Ink.INK, 0.6)
					sx += t * 0.6
			"hanging":
				var n := maxi(1, rc.size.x * 2)
				for k in n:
					Bits.hanging(p, Vector2(r.position.x + (k + 0.5) * r.size.x / n, r.position.y + 2), r.size.y * 0.25, k % 3)
			"clock":
				var c := r.get_center()
				p.fill_poly(_circle(c, minf(r.size.x, r.size.y) * 0.4), p.flat(Color("#c8b890"), 0.1))
				Ink.path(p, _circle(c, minf(r.size.x, r.size.y) * 0.4), 3.0, true, Color("#6a4a2a"))
				Ink.line(p, c, c + Vector2(0, -t * 0.3), 2.0)
				Ink.line(p, c, c + Vector2(t * 0.22, 0), 2.0)
			"vault":
				Bits.vault(p, r.get_center(), minf(r.size.x, r.size.y) * 0.45)
			"pillar_gold":
				Bits.column(p, Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), r.size.x * 0.6)
				p.fill_rect(r.position.x + 2, r.position.y + 2, r.size.x - 4, t * 0.2, p.flat(Color("#c8a040"), 0.1))
			"tools":
				var n := maxi(1, rc.size.x * 2)
				for k in n:
					var x := r.position.x + (k + 0.5) * r.size.x / n
					Ink.line(p, Vector2(x, r.position.y + t * 0.3), Vector2(x + 3, r.end.y - t * 0.3), 3.0, Color("#3a3c40"), 1.0, 0.2)
					p.fill_rect(x - 6, r.position.y + t * 0.2, 13, 9, p.flat(Color("#4a4c50"), 0.1))
			"weapons":
				var n := maxi(1, rc.size.x)
				for k in n:
					var x := r.position.x + (k + 0.5) * r.size.x / n
					Ink.line(p, Vector2(x - t * 0.25, r.position.y + t * 0.3), Vector2(x + t * 0.25, r.end.y - t * 0.3), 3.0, Color("#8c8a84"), 1.0, 0.1)
					Ink.line(p, Vector2(x + t * 0.25, r.position.y + t * 0.3), Vector2(x - t * 0.25, r.end.y - t * 0.3), 3.0, Color("#6a4a2e"), 1.0, 0.1)
			"hearth", "stove":
				Bits.hearth(p, r.position.x + 4, r.position.y + 2, r.size.x - 8, r.size.y - 2)
			"hood":
				var hood := Paint.poly([Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x - t * 0.3, r.end.y), Vector2(r.position.x + t * 0.3, r.end.y)])
				p.fill_poly(hood, Mat.brick(p, col, 0, 0, 22, 9))
				Ink.path(p, hood, 2.2)
			"door_shut":
				var dr := Paint.arch_poly(r.position.x + r.size.x * 0.18, r.position.y + 4, r.size.x * 0.64, r.size.y - 4, false)
				p.fill_poly(dr, Mat.planks(p, col, 0, 0, true, 8))
				Ink.path(p, dr, 2.0)
				p.fill_rect(r.position.x + r.size.x * 0.62, r.position.y + r.size.y * 0.55, 4, 4, p.flat(Color("#8a7448"), 0.1))


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 18:
		pts.append(c + Vector2.from_angle(TAU * i / 18.0) * r)
	return pts


## 책장(앞면): 짙은 틀 · 책 칸 · 갓.
static func _bookcase(p: Paint, r: Rect2, t: int) -> void:
	var frame := Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y)
	p.fill_poly(frame, Mat.planks(p, Color("#3a281b"), 0, 0, true, 11))
	var inner := Paint.rect_poly(r.position.x + 5, r.position.y + t * 0.12, r.size.x - 10, r.size.y - t * 0.2)
	p.fill_poly(inner, Bits.books_shader(p))
	Ink.shade(p, inner, Vector2(0, r.position.y), Vector2(0, r.end.y), 0.35, 0.05)
	Ink.path(p, inner, 1.4)
	Ink.path(p, frame, 2.2)


## 게시판: 나무 틀 · 코르크 · 꽂힌 종이 · 밀랍 봉인.
static func _board(p: Paint, r: Rect2) -> void:
	var frame := Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y)
	p.fill_poly(frame, Mat.beam(p, Color("#3a281b")))
	p.fill_rect(r.position.x + 5, r.position.y + 5, r.size.x - 10, r.size.y - 10, p.flat(Color("#6a5236"), 0.2))
	var n := maxi(2, int(r.size.x / 30.0))
	for k in n:
		var w := p.rng.randf_range(20, 30)
		var h := p.rng.randf_range(22, 32)
		var x := r.position.x + 8 + k * (r.size.x - 16 - w) / maxf(1.0, n - 1)
		var y := r.position.y + 8 + (k % 2) * (r.size.y * 0.35)
		p.fill_rect(x, y, w, h, p.flat(Color("#c4b898"), 0.12))
		Ink.path(p, Paint.rect_poly(x, y, w, h), 1.0)
		for l in 3:
			Ink.line(p, Vector2(x + 3, y + 7 + l * 6), Vector2(x + w - 4, y + 7 + l * 6), 0.8, Ink.INK, 0.45, 0.4)
		p.fill_rect(x + w * 0.5 - 2, y - 2, 5, 5, p.flat(Color("#7a2219"), 0.1))
	Ink.path(p, frame, 2.0)


## 색유리 창(뾰족 아치): 돌 틀 + 칸마다 다른 색 + 납 줄.
static func _stained(p: Paint, r: Rect2) -> void:
	var outer := Paint.arch_poly(r.position.x, r.position.y, r.size.x, r.size.y, true)
	p.fill_poly(outer, Mat.ashlar(p, Color("#5e5a50"), 0, 0, 30, 18))
	Ink.path(p, outer, 2.2)
	var cols := [Color("#7a2a26"), Color("#2c4a6a"), Color("#a88a3a"), Color("#2e5a3a"), Color("#5a3a6a")]
	var g := r.grow(-7)
	var glass := Paint.arch_poly(g.position.x, g.position.y, g.size.x, g.size.y, true)
	var cw := maxf(8.0, g.size.x / 6.0)
	p.fill_poly(glass, func(px: int, py: int) -> Color:
		var cx := floori((px - g.position.x) / cw)
		var cy := floori((py - g.position.y) / 20.0)
		if posmod(int(px - g.position.x), int(cw)) < 2 or posmod(int(py - g.position.y), 20) < 2:
			return Color("#1a1816")
		var c: Color = cols[int(Paint.hash01(cx, cy, 3) * cols.size()) % cols.size()]
		return p.vary(c.lightened(0.15), px, py, 0.15))
	Ink.path(p, glass, 2.0)


## 색유리 가운데 금빛 인물 상(발 = base, 키 h).
static func _figure(p: Paint, base: Vector2, h: float, col: Color) -> void:
	var w := h * 0.22
	var fig := Paint.poly([base + Vector2(-w, 0), base + Vector2(-w * 0.7, -h * 0.62), base + Vector2(-w * 1.2, -h * 0.55), base + Vector2(-w * 0.5, -h * 0.8),
		base + Vector2(0, -h), base + Vector2(w * 0.5, -h * 0.8), base + Vector2(w * 1.2, -h * 0.55), base + Vector2(w * 0.7, -h * 0.62), base + Vector2(w, 0)])
	p.fill_poly(fig, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.3 * clampf((base.x - x) / w, -1.0, 1.0)), x, y, 0.1))
	Ink.path(p, fig, 1.6)
	p.fill_poly(_circle(base + Vector2(0, -h * 0.92), w * 0.4), p.flat(Color("#e8d080"), 0.1))


## 박제 머리·사슴뿔: 방패 판 + 머리 + 뿔.
static func _trophy(p: Paint, c: Vector2, t: int, col: Color) -> void:
	var plaque := _circle(c, t * 0.3)
	p.fill_poly(plaque, p.flat(Color("#4a3424"), 0.1))
	Ink.path(p, plaque, 1.6)
	var head := Paint.poly([c + Vector2(-t * 0.14, -t * 0.08), c + Vector2(t * 0.14, -t * 0.08), c + Vector2(t * 0.06, t * 0.26), c + Vector2(-t * 0.06, t * 0.26)])
	p.fill_poly(head, p.flat(col, 0.15))
	Ink.path(p, head, 1.4)
	for s: float in [-1.0, 1.0]:
		Ink.line(p, c + Vector2(s * t * 0.1, -t * 0.08), c + Vector2(s * t * 0.34, -t * 0.4), 3.0, Color("#c8bca0"), 1.0, 0.3)
		Ink.line(p, c + Vector2(s * t * 0.22, -t * 0.24), c + Vector2(s * t * 0.1, -t * 0.42), 2.0, Color("#c8bca0"), 1.0, 0.3)
