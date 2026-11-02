class_name MoatDeck
extends RefCounted
## 낮은 물(타일 art.sunk — 핏물 해자) 위를 건너는 나무 발판(도개교)의 입체감 — VoidChunk의 받침 기둥 층(_under)에 그린다.
## 허공 위 발판은 낭떠러지 셰이더가 들보 면·그늘을 그리지만 물은 바닥 타일이라 셰이더가 없다(그래서 바닥에 붙어 보였다).
##   shadows: 들보 밑 물 위 그림자(진한 띠 → 투명) — 받침 기둥보다 먼저
##   faces:   남쪽 들보 면(위 밝게 → 아래 어둡게) — 받침 기둥 뒤에
##   ink:     들보 면 위·아래 먹선 · 통나무 이음매 · 북쪽 가장자리 먹선
## 수치 = 균열 look.art.abyss.rail(beam_px · deck_shadow_band · deck_shadow_tiles · deck_shadow_alpha — 없으면 기본값).


static func shadows(vc: VoidChunk, t: float, rail: Dictionary) -> void:
	var view := vc.view
	var map := view.map
	var beam := JsonUtil.get_float(rail, "beam_px", 9.0)
	var band := JsonUtil.get_float(rail, "deck_shadow_band", 0.3) * t
	var reach := JsonUtil.get_float(rail, "deck_shadow_tiles", 1.5) * t
	var k := JsonUtil.get_float(rail, "deck_shadow_alpha", 0.85)
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
	for p in vc._decks:
		if map.explored[p.y * map.width + p.x] == 0:
			continue
		var y0 := (p.y + 1) * t + beam * 0.5
		var a0 := Color(0, 0, 0, k * view.fog_mul(p.x, p.y + 1))
		var a1 := Color(0, 0, 0, k * view.fog_mul(p.x + 1, p.y + 1))
		for part in 2:
			_rect(pts, p.x * t, y0 + (band if part == 1 else 0.0), t, band if part == 0 else reach)
			cols[0] = a0
			cols[1] = a1
			cols[2] = a1 if part == 0 else Color(0, 0, 0, 0)
			cols[3] = a0 if part == 0 else Color(0, 0, 0, 0)
			vc._batch.add(pts, cols)


static func faces(vc: VoidChunk, t: float, rail: Dictionary, wood: Color) -> void:
	var view := vc.view
	var map := view.map
	var beam := JsonUtil.get_float(rail, "beam_px", 9.0)
	var pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var cols := PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK])
	for p in vc._decks:
		if map.explored[p.y * map.width + p.x] == 0:
			continue
		var l0 := view.vertex_mul(p.x, p.y + 1, Color.WHITE)
		var l1 := view.vertex_mul(p.x + 1, p.y + 1, Color.WHITE)
		_rect(pts, p.x * t, (p.y + 1) * t, t, beam)
		cols[0] = Color(wood.r * l0.r, wood.g * l0.g, wood.b * l0.b, 1.0)
		cols[1] = Color(wood.r * l1.r, wood.g * l1.g, wood.b * l1.b, 1.0)
		cols[2] = cols[1].darkened(0.45)
		cols[3] = cols[0].darkened(0.45)
		vc._batch.add(pts, cols)


static func ink(vc: VoidChunk, cv: CanvasItem, t: float, rail: Dictionary, wood: Color) -> void:
	var view := vc.view
	var map := view.map
	var beam := JsonUtil.get_float(rail, "beam_px", 9.0)
	var lines := PackedVector2Array()
	var cols := PackedColorArray()
	for p in vc._decks:
		if map.explored[p.y * map.width + p.x] == 0:
			continue
		var c := _ink(view, wood, p.x, p.y + 1)
		var y0 := (p.y + 1) * t
		lines.append_array([Vector2(p.x * t, y0 + 0.5), Vector2((p.x + 1) * t, y0 + 0.5), Vector2(p.x * t, y0 + beam - 0.5), Vector2((p.x + 1) * t, y0 + beam - 0.5)])
		cols.append_array([c, c])
		if posmod(p.x, 3) == 0:  # 통나무 이음매
			lines.append_array([Vector2(p.x * t, y0), Vector2(p.x * t, y0 + beam)])
			cols.append(c)
	for p in vc._decks_n:  # 북쪽 가장자리: 물보다 높은 발판 끝
		if map.explored[p.y * map.width + p.x] == 0:
			continue
		lines.append_array([Vector2(p.x * t, p.y * t + 0.5), Vector2((p.x + 1) * t, p.y * t + 0.5)])
		cols.append(_ink(view, wood, p.x, p.y))
	if not lines.is_empty():
		cv.draw_multiline_colors(lines, cols, 1.2)


static func _ink(view: FloorView, wood: Color, vx: int, vy: int) -> Color:
	var l := view.vertex_mul(vx, vy, Color.WHITE)
	return Color(wood.r * l.r * 0.3, wood.g * l.g * 0.3, wood.b * l.b * 0.3, 1.0)


static func _rect(pts: PackedVector2Array, x: float, y: float, w: float, h: float) -> void:
	pts[0] = Vector2(x, y)
	pts[1] = Vector2(x + w, y)
	pts[2] = Vector2(x + w, y + h)
	pts[3] = Vector2(x, y + h)
