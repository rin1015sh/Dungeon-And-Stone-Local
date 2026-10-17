extends RefCounted
## 랜드마크 벽 그림(tools/paint_floor.gd — 아틀라스 형식은 벽과 같다: 윗면 줄 + 앞면 줄, 변형 2):
##   monument        대현자 기념비 — 닳은 비석 머리 + 비문이 새겨진 앞면(이름 없는 새 문양 — 원작 문장·이름 금지)
##   square_crystal  네모 수정 — 위에서 본 네모난 결정 면 + 빛이 고인 앞면 결정
## 앞면 아래 Cave.skirt px는 밑동(들쭉날쭉하게 끝남). 평균 색은 paint_floor가 타일 색에 맞춘다(스스로 빛나는 부분은 덜).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")


static func cell(style: String, part: String, v: int, w: int, h: int, col: Color, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value + v * 59)
	var s := w / 64.0
	match style + "_" + part:
		"monument_top":
			_slab(p, col, s)
		"monument_face":
			_stele(p, col, s, v)
		"square_crystal_top":
			_crystal_top(p, col, s)
		"square_crystal_face":
			_crystal_face(p, col, s, v)
	return p


## 비석 머리: 모서리를 깎은 돌판, 왼쪽 위가 밝고 오른쪽 아래가 어둡다, 금과 이끼.
static func _slab(p: Paint, col: Color, s: float) -> void:
	var hf := Seam.field(p.w, p.h, 11, 0.07, 3)
	for y in p.h:
		for x in p.w:
			var e := minf(minf(x, p.w - 1 - x), minf(y, p.h - 1 - y))
			var bevel := clampf(1.0 - e / (6.0 * s), 0.0, 1.0)
			var lit := (0.5 - float(x) / p.w) * 0.3 + (0.5 - float(y) / p.h) * 0.3
			var c := col.lerp(col.lightened(0.3), clampf(0.5 + lit + (hf[y * p.w + x] - 0.5) * 0.4, 0.0, 1.0))
			if bevel > 0.0:
				c = c.lightened(0.25 * bevel) if x + y < p.w else c.darkened(0.35 * bevel)
			p.blend(x, y, c, 1.0)
	Cave._crack(p, Vector2(p.w * 0.3, p.h * 0.25), 3, 7 * s, Vector2(1, 1))
	for k in 14:
		Cave._dot(p, Vector2(p.rng.randf_range(2, p.w - 2), p.rng.randf_range(p.h * 0.6, p.h - 2)), 1.6 * s, Color("#4a5a38"), 0.6)
	Ink.path(p, Paint.rect_poly(1, 1, p.w - 2, p.h - 2), 1.4 * s, true, Ink.INK, 0.7, 0.6)


## 비석 앞면: 테두리를 판 비문 판 + 새긴 문양 줄 + 금 + 아래쪽 그늘 + 들쭉날쭉한 밑동.
static func _stele(p: Paint, col: Color, s: float, v: int) -> void:
	var main := float(p.h - Cave.skirt)
	var hf := Seam.field(p.w, p.h, 21 + v, 0.06, 3)
	for y in p.h:
		for x in p.w:
			var foot := main + (0.3 + Paint.hash01(x / 3, v, 5) * 0.7) * Cave.skirt
			if y >= foot:
				continue
			var t := 0.55 + (hf[y * p.w + x] - 0.5) * 0.4 - smoothstep(main * 0.5, foot, float(y)) * 0.35
			if x < 3 * s:
				t += 0.2
			var c := col.darkened(0.35).lerp(col.lightened(0.25), clampf(t, 0.0, 1.0))
			if foot - y < 1.6:
				c = c.lerp(Ink.INK, 0.6)
			p.blend(x, y, c, 1.0)
	var panel := Rect2(8 * s, 10 * s, p.w - 16 * s, main - 22 * s)
	Ink.path(p, Paint.rect_poly(panel.position.x, panel.position.y, panel.size.x, panel.size.y), 1.4 * s, true, Ink.INK, 0.75, 0.4)
	Ink.line(p, panel.position + Vector2(1, panel.size.y + 1.2 * s), panel.end + Vector2(0, 1.2 * s), 1.0 * s, Color("#e8e0c8"), 0.35, 0.3)
	var y := panel.position.y + 6 * s
	while y < panel.end.y - 4 * s:  # 새긴 문양(뜻 없는 새 글자)
		var x := panel.position.x + 4 * s
		while x < panel.end.x - 5 * s:
			var g := p.rng.randi() % 4
			match g:
				0:
					Ink.line(p, Vector2(x, y - 2 * s), Vector2(x, y + 2 * s), 1.0 * s, Ink.INK, 0.7, 0.2)
				1:
					Ink.line(p, Vector2(x - 2 * s, y), Vector2(x + 2 * s, y - 2 * s), 1.0 * s, Ink.INK, 0.7, 0.2)
				2:
					Ink.path(p, Cave._ellipse(Vector2(x, y), 1.8 * s, 1.8 * s, 8), 0.9 * s, true, Ink.INK, 0.65, 0.2)
				_:
					Ink.line(p, Vector2(x - 2 * s, y + 2 * s), Vector2(x + 2 * s, y + 2 * s), 1.0 * s, Ink.INK, 0.7, 0.2)
			x += 6 * s
		y += 7 * s
	Cave._crack(p, Vector2(p.w * (0.65 if v == 0 else 0.25), 4 * s), 4, 8 * s, Vector2(0.2, 1))


## 네모 수정 윗면: 바위 받침 윗면 가운데에 네모반듯한 결정이 박혀 있다(비스듬히 깎인 네 면 + 밝은 가운데 면).
static func _crystal_top(p: Paint, col: Color, s: float) -> void:
	var rock := Color("#4a4452")
	var hf := Seam.field(p.w, p.h, 31, 0.08, 3)
	for y in p.h:
		for x in p.w:
			var t := 0.45 + Seam.relief(hf, p.w, p.h, x, y, 6.0) * 0.6 + (hf[y * p.w + x] - 0.5) * 0.3
			p.blend(x, y, rock.darkened(0.4).lerp(rock.lightened(0.3), clampf(t, 0.0, 1.0)), 1.0)
	var m := 17.0 * s  # 결정 테두리(받침 바위 폭)
	var bev := 6.0 * s
	for y in range(int(m), int(p.h - m)):
		for x in range(int(m), int(p.w - m)):
			var dx := minf(x - m, p.w - m - 1 - x)
			var dy := minf(y - m, p.h - m - 1 - y)
			var c := col.lightened(0.35)
			if dx < bev or dy < bev:
				var lit := (x < p.w / 2 and dx <= dy) or (y < p.h / 2 and dy < dx)
				c = col.lightened(0.15) if lit else col.darkened(0.3)
			p.blend(x, y, p.vary(c, x, y, 0.04), 1.0)
	Ink.path(p, Paint.rect_poly(m, m, p.w - 2 * m, p.h - 2 * m), 1.3 * s, true, Color("#1a1030"), 0.8, 0.3)
	Ink.path(p, Paint.rect_poly(m + bev, m + bev, p.w - 2 * (m + bev), p.h - 2 * (m + bev)), 0.9 * s, true, Color("#1a1030"), 0.5, 0.2)
	Ink.glow(p, p.w * 0.5, p.h * 0.5, 18 * s, Color("#8f6cff"), 0.35)


## 네모 수정 앞면: 바위 받침 앞면 가운데에 네모난 결정의 앞쪽 면이 드러나 있다(빛이 고인 결정 + 둘레 바위).
static func _crystal_face(p: Paint, col: Color, s: float, v: int) -> void:
	var main := float(p.h - Cave.skirt)
	var rock := Color("#5a5262")
	var hf := Seam.field(p.w, p.h, 41 + v, 0.08, 3)
	var m := 17.0 * s
	for y in p.h:
		for x in p.w:
			if y >= main + (0.3 + Paint.hash01(x / 3, v, 9) * 0.7) * Cave.skirt:
				continue
			var c := rock.darkened(0.35).lerp(rock.lightened(0.2), clampf(0.5 + Seam.relief(hf, p.w, p.h, x, y, 5.0) * 0.6, 0.0, 1.0))
			c = c.darkened(smoothstep(main * 0.5, main + Cave.skirt, float(y)) * 0.3)
			if x >= m and x < p.w - m and y < main * 0.7:  # 결정 앞쪽 면
				c = col.lerp(Color("#e8dcff"), clampf(1.0 - Vector2(x - p.w * 0.5, (y - main * 0.3) * 1.6).length() / (p.w * 0.25), 0.0, 1.0) * 0.6)
			p.blend(x, y, p.vary(c, x, y, 0.04), 1.0)
	Ink.path(p, Paint.rect_poly(m, 0, p.w - 2 * m, main * 0.7), 1.2 * s, true, Color("#1a1030"), 0.75, 0.3)
	Ink.line(p, Vector2(m, 1.5 * s), Vector2(p.w - m, 1.5 * s), 1.0 * s, Color("#f0e8ff"), 0.55, 0.2)
