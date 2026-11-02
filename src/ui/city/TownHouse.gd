class_name TownHouse
extends Node2D
## 도시 동네 지도의 집 한 채(CT82 — 2D 3/4 탑뷰): 필지(바닥 칸)의 남쪽 끝에 앞면이 서고, 지붕은 그 위로 필지 깊이만큼(앞면 높이만큼 북쪽으로 밀린다).
## 노드 위치 = (0, 앞면 아래 끝 y) — 발 높이로 앞뒤를 정한다(y_sort). 그림은 처음 한 번(TownBrush — 재질 그림 × 색).
##   ridge "x" = 마루가 동서(처마가 길 쪽 — 남쪽 경사면이 넓게 보이고 지붕창·굴뚝), "y" = 박공이 길 쪽(앞면 위 삼각 박공, 좌우 경사면).
## 시설 건물 꾸밈(간판·차양·아치·기둥·첨탑·원형 돔)은 TownLandmark가 덧그린다.

var house: Dictionary
var render: Dictionary
var tile: float = 32.0
## 그린 범위(세계 좌표 — 가림 판정에 쓴다).
var bounds: Rect2
var _fade: float = 1.0
var _goal: float = 1.0


func setup(h: Dictionary, p_render: Dictionary, p_tile: float) -> void:
	house = h
	render = p_render
	tile = p_tile
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var rc: Rect2i = h["rect"]
	position = Vector2(0, rc.end.y * tile)
	var top := -rc.size.y * tile - height() - roof_rise() - tile * 3.0
	bounds = Rect2(rc.position.x * tile - 8.0, position.y + top, rc.size.x * tile + 16.0, -top)


## 앞면 높이(세계 px).
func height() -> float:
	return int(house.get("floors", 2)) * TownBrush.num(render, "storey_px", 34.0) + TownBrush.num(render, "base_px", 6.0)


func roof_rise() -> float:
	var rc: Rect2i = house["rect"]
	var depth := (rc.size.y if str(house.get("ridge", "x")) == "x" else rc.size.x) * tile
	return clampf(depth * TownBrush.num(render, "roof_rise", 0.3), 20.0, 110.0)


## 가림(플레이어가 이 집 뒤에 있으면 흐리게 — TownWorld가 부른다).
func set_fade(on: bool) -> void:
	_goal = TownBrush.num(render, "fade_alpha", 0.3) if on else 1.0
	set_process(not is_equal_approx(_fade, _goal))


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_fade = move_toward(_fade, _goal, delta * TownBrush.num(render, "fade_speed", 4.0))
	modulate.a = _fade
	if is_equal_approx(_fade, _goal):
		set_process(false)


func _draw() -> void:
	var b := TownBrush.new()
	var style := str(house.get("style", "house"))
	if style == "rotunda":
		TownLandmark.rotunda(b, self)
	elif style == "gothic":
		TownLandmark.gothic(b, self)
	else:
		draw_box(b)
		TownLandmark.dress(b, self)
	b.flush(self)


## 고르는 값(0~999)에서 k번째 선택.
func pick(k: int, n: int) -> int:
	return int(absi(int(house.get("look", 0)) * (k * 7 + 3) + k * 131) / 7) % maxi(1, n)


func wall_color() -> Color:
	match str(house.get("style", "house")):
		"stone", "workshop":
			return TownBrush.col(render, "stone")
		"hall", "inn", "arcade":
			return TownBrush.col(render, "walls", [0, 4, 6][pick(1, 3)])
	return TownBrush.col(render, "walls", pick(1, 7))


func roof_color() -> Color:
	var slate := str(house.get("style", "")) in ["stone", "workshop"] or pick(2, 4) == 0
	return TownBrush.col(render, "slate", pick(3, 2)) if slate else TownBrush.col(render, "roofs", pick(3, 4))


func roof_mat() -> String:
	return "slate" if str(house.get("style", "")) in ["stone", "workshop"] or pick(2, 4) == 0 else "clay"


func wall_mat() -> String:
	return "ashlar" if str(house.get("style", "")) in ["stone", "workshop"] else "plaster"


## 앞면 사각형(로컬 — 아래 끝 y = 0).
func front() -> Rect2:
	var rc: Rect2i = house["rect"]
	return Rect2(rc.position.x * tile, -height(), rc.size.x * tile, height())


## 상자 집: 지붕 → 앞면(밑단·층 띠·창·문) → 처마 그늘 → 윤곽.
func draw_box(b: TownBrush) -> void:
	var rc: Rect2i = house["rect"]
	var f := front()
	var x0 := f.position.x
	var x1 := f.end.x
	var hgt := height()
	var depth := rc.size.y * tile
	var rise := roof_rise()
	var rcol := roof_color()
	var ink := TownBrush.col(render, "ink")
	var uv := Vector2(pick(4, 97) * 13.0, pick(5, 89) * 7.0)
	var o := 4.0
	if str(house.get("ridge", "x")) == "x":
		var yr := -depth * 0.5 - hgt - rise
		var yb := -depth - hgt
		var hip := 0.0 if not str(house.get("style", "")) in ["stone", "hall"] else minf(rise * 0.9, f.size.x * 0.3)
		b.poly_cols(PackedVector2Array([Vector2(x0 - o + hip, yr), Vector2(x1 + o - hip, yr), Vector2(x1 + o, yb), Vector2(x0 - o, yb)]),
			PackedColorArray([TownBrush.shade(rcol, 0.62), TownBrush.shade(rcol, 0.62), TownBrush.shade(rcol, 0.5), TownBrush.shade(rcol, 0.5)]), roof_mat(), uv)  # 북쪽 경사면
		b.poly_cols(PackedVector2Array([Vector2(x0 - o, -hgt + 2), Vector2(x1 + o, -hgt + 2), Vector2(x1 + o - hip, yr), Vector2(x0 - o + hip, yr)]),
			PackedColorArray([TownBrush.shade(rcol, 0.92), TownBrush.shade(rcol, 0.92), TownBrush.shade(rcol, 1.12), TownBrush.shade(rcol, 1.12)]), roof_mat(), uv)  # 남쪽 경사면
		if hip > 0.0:  # 모임지붕 양 끝 삼각
			b.poly(PackedVector2Array([Vector2(x0 - o, -hgt + 2), Vector2(x0 - o + hip, yr), Vector2(x0 - o, yb)]), TownBrush.shade(rcol, 1.0), roof_mat(), uv)
			b.poly(PackedVector2Array([Vector2(x1 + o, -hgt + 2), Vector2(x1 + o, yb), Vector2(x1 + o - hip, yr)]), TownBrush.shade(rcol, 0.72), roof_mat(), uv)
		b.line(Vector2(x0 - o + hip, yr), Vector2(x1 + o - hip, yr), 2.0, TownBrush.shade(rcol, 0.45))
		b.line(Vector2(x0 - o, yb), Vector2(x1 + o, yb), 1.5, ink)  # 뒤 처마
		b.line(Vector2(x0 - o, -hgt + 2), Vector2(x0 - o, yb), 1.5, ink)  # 지붕 옆 끝
		b.line(Vector2(x1 + o, -hgt + 2), Vector2(x1 + o, yb), 1.5, ink)
		_roof_bits(b, x0, x1, -hgt, yr, rcol)
	else:
		var xm := (x0 + x1) * 0.5
		var deep := rc.size.y * tile
		b.poly_cols(PackedVector2Array([Vector2(x0 - o, -hgt + 2), Vector2(xm, -hgt - rise), Vector2(xm, -hgt - rise - deep), Vector2(x0 - o, -hgt - deep)]),
			PackedColorArray([TownBrush.shade(rcol, 1.0), TownBrush.shade(rcol, 1.12), TownBrush.shade(rcol, 1.0), TownBrush.shade(rcol, 0.9)]), roof_mat(), uv)
		b.poly_cols(PackedVector2Array([Vector2(xm, -hgt - rise), Vector2(x1 + o, -hgt + 2), Vector2(x1 + o, -hgt - deep), Vector2(xm, -hgt - rise - deep)]),
			PackedColorArray([TownBrush.shade(rcol, 0.78), TownBrush.shade(rcol, 0.7), TownBrush.shade(rcol, 0.6), TownBrush.shade(rcol, 0.7)]), roof_mat(), uv)
		b.line(Vector2(xm, -hgt - rise), Vector2(xm, -hgt - rise - deep), 2.0, TownBrush.shade(rcol, 0.45))
		if pick(6, 3) == 0:
			_chimney(b, x0 + (x1 - x0) * 0.72, -hgt - rise * 0.5 - deep * 0.5)
	_facade(b, f)
	if str(house.get("ridge", "x")) == "y":  # 박공(앞면 위 삼각)
		var xm := (x0 + x1) * 0.5
		var wc := wall_color()
		b.poly_cols(PackedVector2Array([Vector2(x0, -hgt), Vector2(x1, -hgt), Vector2(xm, -hgt - rise + 3)]),
			PackedColorArray([TownBrush.shade(wc, 0.95), TownBrush.shade(wc, 0.95), TownBrush.shade(wc, 1.05)]), wall_mat(), uv)
		var gw := minf(10.0, f.size.x * 0.25)
		b.rect(Rect2(xm - gw * 0.5, -hgt - rise * 0.55, gw, rise * 0.32), TownBrush.col(render, "glass"))
		b.line(Vector2(x0 - o, -hgt + 2), Vector2(xm, -hgt - rise), 3.0, TownBrush.shade(rcol, 0.55))
		b.line(Vector2(xm, -hgt - rise), Vector2(x1 + o, -hgt + 2), 3.0, TownBrush.shade(rcol, 0.45))
	b.rect_v(Rect2(x0, -hgt, f.size.x, 7), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.0))  # 처마 그늘
	b.line(Vector2(x0 - o, -hgt + 1), Vector2(x1 + o, -hgt + 1), 2.5, TownBrush.shade(rcol, 0.4))  # 앞 처마
	b.line(Vector2(x0, -hgt), Vector2(x0, 0), 1.5, ink)
	b.line(Vector2(x1, -hgt), Vector2(x1, 0), 1.5, ink)


## 앞면: 벽(아래가 조금 어둡다) · 밑단 · 층마다 창 · 1층 문 · 층 띠(반목조 집은 들보).
func _facade(b: TownBrush, f: Rect2) -> void:
	var wc := wall_color()
	var uv := Vector2(pick(7, 61) * 11.0, pick(8, 53) * 5.0)
	b.rect_v(f, TownBrush.shade(wc, 1.02), TownBrush.shade(wc, 0.8), wall_mat(), uv)
	var base := TownBrush.num(render, "base_px", 6.0)
	b.rect(Rect2(f.position.x, -base, f.size.x, base), TownBrush.col(render, "plinth"), "ashlar")
	var storey := TownBrush.num(render, "storey_px", 34.0)
	var floors := int(house.get("floors", 2))
	var timber := str(house.get("style", "house")) in ["inn", "hall"] or (str(house.get("style", "house")) == "house" and pick(9, 5) == 0)
	var n := maxi(1, int((f.size.x - 6.0) / 24.0))
	var door_i := pick(10, n) if str(house.get("facility", "")).is_empty() else -1
	for fl in floors:
		var y0 := -base - (fl + 1) * storey
		if timber and fl > 0:
			b.rect(Rect2(f.position.x, y0 + storey - 3, f.size.x, 3), TownBrush.col(render, "timber"))
			for k in n + 1:
				var bx := f.position.x + 2 + (f.size.x - 4) * float(k) / n
				b.rect(Rect2(bx - 1.5, y0, 3, storey), TownBrush.col(render, "timber"))
		elif fl > 0:
			b.rect(Rect2(f.position.x, y0 + storey - 2, f.size.x, 2), TownBrush.shade(wc, 1.15))
		for k in n:
			var cx := f.position.x + (f.size.x) * (k + 0.5) / n
			if fl == 0 and k == door_i:
				_door(b, cx, -base, 12.0, storey - 6)
			elif fl == 0 and str(house.get("facility", "")).is_empty() and pick(11 + k, 4) == 0:
				_window(b, cx, y0 + 8, 18.0, storey - 14, true)  # 가게 창
			else:
				_window(b, cx, y0 + 7, 9.0, storey - 15, pick(20 + k + fl * 5, 7) == 0)


func _window(b: TownBrush, cx: float, y: float, w: float, h: float, lit: bool) -> void:
	b.rect(Rect2(cx - w * 0.5 - 1.5, y - 1.5, w + 3, h + 3), TownBrush.col(render, "frame"))
	b.rect_v(Rect2(cx - w * 0.5, y, w, h), TownBrush.col(render, "glass_lit" if lit else "glass"), TownBrush.shade(TownBrush.col(render, "glass_lit" if lit else "glass"), 0.7))
	b.rect(Rect2(cx - 0.75, y, 1.5, h), TownBrush.shade(TownBrush.col(render, "frame"), 0.8))
	b.rect(Rect2(cx - w * 0.5 - 2.5, y + h + 1.5, w + 5, 2.5), TownBrush.col(render, "ink"))


func _door(b: TownBrush, cx: float, bottom: float, w: float, h: float) -> void:
	b.rect(Rect2(cx - w * 0.5 - 2, bottom - h - 2, w + 4, h + 2), TownBrush.shade(TownBrush.col(render, "plinth"), 0.8))
	b.rect_v(Rect2(cx - w * 0.5, bottom - h, w, h), TownBrush.col(render, "door"), TownBrush.shade(TownBrush.col(render, "door"), 0.6), "wood")


## 남쪽 경사면의 지붕창·굴뚝.
func _roof_bits(b: TownBrush, x0: float, x1: float, eave: float, ridge: float, rcol: Color) -> void:
	var w := x1 - x0
	if w >= 7 * tile * 0.7 and pick(12, 2) == 0:
		var n := 1 if w < 8 * tile else 2
		for k in n:
			var cx := x0 + w * (k + 1) / (n + 1)
			var y := lerpf(eave, ridge, 0.55)
			b.rect_v(Rect2(cx - 8, y - 4, 16, 14), wall_color(), TownBrush.shade(wall_color(), 0.85), "plaster")
			b.rect(Rect2(cx - 4, y, 8, 9), TownBrush.col(render, "glass"))
			b.poly(PackedVector2Array([Vector2(cx - 11, y - 2), Vector2(cx, y - 12), Vector2(cx + 11, y - 2)]), TownBrush.shade(rcol, 1.05), roof_mat())
	if pick(13, 3) != 0:
		_chimney(b, x0 + w * (0.2 + 0.6 * pick(14, 10) / 10.0), ridge + 2)


func _chimney(b: TownBrush, cx: float, base_y: float) -> void:
	var c := TownBrush.col(render, "brick")
	b.rect_v(Rect2(cx - 5, base_y - 20, 10, 22), TownBrush.shade(c, 1.1), TownBrush.shade(c, 0.75), "ashlar")
	b.rect(Rect2(cx - 6.5, base_y - 23, 13, 4), TownBrush.shade(c, 0.6))
