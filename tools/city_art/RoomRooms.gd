extends RefCounted
## 시설 실내 방 그림 — 도서관 말고 일곱 곳(탑뷰 3/4 — CT64; tools/paint_rooms.gd 전용). 바탕·벽·마무리는 RoomArt(base·walls·finish),
## 여기서는 뒷벽 앞면(rows 1~2 — 앞에서 본 벽이라 도시 실내 일러스트 부품 InteriorBits·Props·Parts를 그대로 쓴다)만 꾸민다.
## 뒷벽 = y 0.18T ~ 3T(바닥선), 칸 x T ~ (W−1)T. 바닥·벽 재질 = 방 JSON floor + 아래 함수의 벽 이름. 돌려주는 값 = 그린 Paint.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Props := preload("res://tools/city_art/Props.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")


## 탐험가 길드 회관: 판자벽 · 의뢰 게시판(종이·밀랍 봉인) · 길드 방패 문장 · 깃발 · 접수 뒤 상자 선반.
static func guild(room: Dictionary, t: int, seed_value: int) -> Paint:
	var p := RoomArt.base(room, t, seed_value, str(room.get("floor", "boards")), "timber")
	_board(p, Rect2(2.15 * t, 0.55 * t, 3.7 * t, 1.9 * t))
	Bits.shield(p, Vector2(7.5 * t, 1.25 * t), 0.5 * t)
	Props.banner(p, 6.6 * t, 3 * t, Color("#5a2a24"), 2.2 * t)
	Props.banner(p, 8.4 * t, 3 * t, Color("#2e3e4a"), 2.2 * t)
	Bits.shelf_row(p, 9.2 * t, 0.35 * t, 4.6 * t, "boxes")
	Bits.shelf_row(p, 9.2 * t, 1.2 * t, 4.6 * t, "jars")
	var lights: Array = [RoomArt.sconce(p, Vector2(1.5 * t, 1.3 * t), t), RoomArt.sconce(p, Vector2(14.5 * t, 1.3 * t), t)]
	return _end(p, room, t, lights)


## 여관 주점: 회벽 · 왼쪽 난로(불) · 계산대 뒤 술병 선반 둘 · 매단 약초 · 오른쪽 위층 계단(휴식).
static func inn(room: Dictionary, t: int, seed_value: int) -> Paint:
	var p := RoomArt.base(room, t, seed_value, str(room.get("floor", "boards")), "plaster")
	Bits.hearth(p, 1.9 * t, 0.95 * t, 3.0 * t, 2.05 * t)
	Bits.shelf_row(p, 6.1 * t, 0.45 * t, 4.8 * t, "bottles")
	Bits.shelf_row(p, 6.1 * t, 1.3 * t, 4.8 * t, "jars")
	for k in 4:
		Bits.hanging(p, Vector2((6.4 + k * 1.2) * t, 0.2 * t), 10.0, k % 3)
	_stairs(p, Rect2(12.05 * t, 0.2 * t, 2.9 * t, 2.8 * t))
	var lights: Array = [[Vector2(3.4 * t, 2.6 * t), 3.6 * t, Color("#ff9a40"), 0.95], RoomArt.sconce(p, Vector2(11.5 * t, 1.3 * t), t)]
	return _end(p, room, t, lights)


## 신전 예배당: 돌벽 · 가운데 큰 색유리 창(빛줄기) · 기둥 둘 · 양옆 좁은 창 · 촛대.
static func temple(room: Dictionary, t: int, seed_value: int) -> Paint:
	var p := RoomArt.base(room, t, seed_value, str(room.get("floor", "flag")), "ashlar")
	var w := room["rows"][0].length() as int
	var cx := w * 0.5 * t
	_stained(p, cx - 1.6 * t, 0.3 * t, 3.2 * t, 2.45 * t)
	RoomArt.shaft(p, Vector2(cx - 1.4 * t, 3 * t), Vector2(cx + 1.4 * t, 3 * t), Vector2(cx - 2.2 * t, 9 * t), Vector2(cx + 2.2 * t, 9 * t), Color("#c8b8a0"), 0.12)
	for x: float in [cx - 3.1 * t, cx + 3.1 * t]:
		Bits.column(p, Vector2(x, 0.2 * t), Vector2(x, 3 * t), 0.5 * t)
	for x: float in [2.1 * t, w * t - 3.1 * t]:
		RoomArt.window(p, x, 0.6 * t, 1.0 * t, 1.9 * t)
	Bits.candle_stand(p, cx - 4.4 * t, 3 * t)
	Bits.candle_stand(p, cx + 4.4 * t, 3 * t)
	var lights: Array = [[Vector2(cx, 2.2 * t), 4.0 * t, Color("#c8b8a0"), 0.6], [Vector2(cx - 4.4 * t, 1.4 * t), 2.2 * t, RoomArt.WARM, 0.6],
		[Vector2(cx + 4.4 * t, 1.4 * t), 2.2 * t, RoomArt.WARM, 0.6]]
	return _end(p, room, t, lights)


## 잡화점: 판자벽 · 벽을 덮은 선반 세 줄(단지·술병·상자) · 매단 약초·자루.
static func shop(room: Dictionary, t: int, seed_value: int) -> Paint:
	var p := RoomArt.base(room, t, seed_value, str(room.get("floor", "boards")), "timber")
	var w := room["rows"][0].length() as int
	var kinds := ["jars", "bottles", "boxes"]
	for r in 3:
		Bits.shelf_row(p, 1.1 * t, (0.3 + r * 0.85) * t, (w - 2.2) * t, kinds[r])
	for k in 6:
		Bits.hanging(p, Vector2((2.0 + k * 2.2) * t, 0.18 * t), 6.0, k % 3)
	var lights: Array = [RoomArt.sconce(p, Vector2(4.5 * t, 1.6 * t), t), RoomArt.sconce(p, Vector2((w - 4.5) * t, 1.6 * t), t)]
	return _end(p, room, t, lights)


## 대장간 작업장: 벽돌벽 · 왼쪽 큰 화덕(불·덮개) · 걸어 둔 연장 · 오른쪽 벽의 검·방패.
static func smithy(room: Dictionary, t: int, seed_value: int) -> Paint:
	var p := RoomArt.base(room, t, seed_value, str(room.get("floor", "flag")), "brick")
	var hood := Paint.poly([Vector2(1.6 * t, 0.2 * t), Vector2(5.6 * t, 0.2 * t), Vector2(5.2 * t, 0.95 * t), Vector2(2.0 * t, 0.95 * t)])
	p.fill_poly(hood, Mat.brick(p, Color("#3a2a22"), 0, 0, 22, 9))
	Ink.path(p, hood, 2.2)
	Bits.hearth(p, 2.0 * t, 0.95 * t, 3.2 * t, 2.05 * t)
	for k in 4:  # 집게·망치
		var x := (6.4 + k * 0.6) * t
		Ink.line(p, Vector2(x, 0.6 * t), Vector2(x + 4, 1.9 * t), 3.0, Color("#3a3c40"), 1.0, 0.2)
		p.fill_rect(x - 6, 0.5 * t, 14, 10, p.flat(Color("#4a4c50"), 0.1))
	for k in 3:
		var x := (10.2 + k * 1.3) * t
		Ink.line(p, Vector2(x, 0.5 * t), Vector2(x + 0.5 * t, 2.4 * t), 4.0, Color("#8c8a84"), 1.0, 0.1)
		Ink.line(p, Vector2(x - 8, 2.0 * t), Vector2(x + 0.5 * t + 8, 1.95 * t), 4.0, Color("#4a3423"), 1.0, 0.1)
	Bits.shield(p, Vector2(14.2 * t, 1.4 * t), 0.42 * t)
	var lights: Array = [[Vector2(3.6 * t, 2.6 * t), 4.4 * t, Color("#ff8a30"), 1.1]]
	return _end(p, room, t, lights)


## 은행 창구: 돌벽 · 가운데 둥근 금고 문 · 기둥 · 놋쇠 등 · 저울 문장.
static func bank(room: Dictionary, t: int, seed_value: int) -> Paint:
	var p := RoomArt.base(room, t, seed_value, str(room.get("floor", "checker")), "ashlar")
	var w := room["rows"][0].length() as int
	var cx := w * 0.5 * t
	Bits.vault(p, Vector2(cx, 1.6 * t), 1.15 * t)
	for x: float in [1.7 * t, w * t - 1.7 * t]:
		Bits.column(p, Vector2(x, 0.2 * t), Vector2(x, 3 * t), 0.45 * t)
	Bits.scale(p, Vector2(cx - 3.2 * t, 1.5 * t))
	Bits.scale(p, Vector2(cx + 3.2 * t, 1.5 * t))
	Bits.brass_lamp(p, Vector2(cx - 5.0 * t, 2.2 * t))
	Bits.brass_lamp(p, Vector2(cx + 5.0 * t, 2.2 * t))
	var lights: Array = [[Vector2(cx - 5.0 * t, 1.8 * t), 2.8 * t, RoomArt.WARM, 0.7], [Vector2(cx + 5.0 * t, 1.8 * t), 2.8 * t, RoomArt.WARM, 0.7]]
	return _end(p, room, t, lights)


## 훈련장: 판자벽 · 벽의 무기 걸이 · 방패 · 깃발 · 높은 창.
static func training(room: Dictionary, t: int, seed_value: int) -> Paint:
	var p := RoomArt.base(room, t, seed_value, str(room.get("floor", "sand")), "timber")
	var w := room["rows"][0].length() as int
	for x: float in [2.6, 5.2, 10.8, 13.4]:
		Props.weapon_rack(p, x * t, 3 * t)
	for x: float in [3.9, 12.1]:
		Bits.shield(p, Vector2(x * t, 1.1 * t), 0.36 * t)
	RoomArt.window(p, (w * 0.5 - 0.9) * t, 0.5 * t, 1.8 * t, 1.5 * t)
	Props.banner(p, (w * 0.5 - 1.5) * t, 3 * t, Color("#5a2a24"), 2.1 * t)
	Props.banner(p, (w * 0.5 + 1.5) * t, 3 * t, Color("#5a2a24"), 2.1 * t)
	var lights: Array = [[Vector2(w * 0.5 * t, 1.5 * t), 4.2 * t, RoomArt.COOL, 0.6], RoomArt.sconce(p, Vector2(1.5 * t, 1.3 * t), t),
		RoomArt.sconce(p, Vector2((w - 1.5) * t, 1.3 * t), t)]
	return _end(p, room, t, lights)


static func _end(p: Paint, room: Dictionary, t: int, lights: Array) -> Paint:
	RoomArt.walls(p, room, t)
	RoomArt.finish(p, room, t, lights)
	return p


## 의뢰 게시판: 나무 틀 · 코르크 바탕 · 꽂힌 종이(글 줄) · 밀랍 봉인.
static func _board(p: Paint, r: Rect2) -> void:
	var frame := Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y)
	p.fill_poly(frame, Mat.beam(p, Color("#3a281b")))
	var cork := Paint.rect_poly(r.position.x + 7, r.position.y + 7, r.size.x - 14, r.size.y - 14)
	p.fill_poly(cork, p.flat(Color("#6a5236"), 0.2))
	for k in 7:
		var w := p.rng.randf_range(28, 46)
		var h := p.rng.randf_range(30, 44)
		var x := r.position.x + 12 + fmod(k * 37.0, r.size.x - w - 24)
		var y := r.position.y + 12 + (k % 2) * (r.size.y * 0.42) + p.rng.randf_range(-4, 4)
		var sheet := Paint.rect_poly(x, y, w, h)
		p.fill_poly(sheet, p.flat(Color("#c4b898"), 0.12))
		Ink.path(p, sheet, 1.0)
		for l in 4:
			Ink.line(p, Vector2(x + 4, y + 8 + l * 7), Vector2(x + w - 5, y + 8 + l * 7), 0.8, Ink.INK, 0.45, 0.4)
		p.fill_rect(x + w * 0.5 - 3, y - 2, 6, 6, p.flat(Color("#7a2219"), 0.1))
	Ink.path(p, frame, 2.2)


## 위층으로 오르는 계단(앞에서 본 벽): 왼쪽 아래에서 오른쪽 위로 오르는 디딤판 + 난간 + 위 어둠.
static func _stairs(p: Paint, r: Rect2) -> void:
	var opening := Paint.rect_poly(r.position.x + r.size.x * 0.45, r.position.y, r.size.x * 0.55, r.size.y * 0.35)
	p.fill_poly(opening, p.flat(Color("#120d0a"), 0.1))
	var n := 8
	for k in n:
		var f := float(k) / n
		var x := r.position.x + f * r.size.x * 0.75
		var y := r.end.y - (f + 1.0 / n) * r.size.y * 0.9
		var step := Paint.rect_poly(x, y, r.size.x * 0.32, r.size.y * 0.9 / n + 2)
		p.fill_poly(step, Mat.planks(p, Color("#4a3423").darkened(f * 0.3), 0, 0, false, 8))
		Ink.path(p, step, 1.4)
	Ink.line(p, Vector2(r.position.x + 8, r.end.y - 30), Vector2(r.end.x - 6, r.position.y + 14), 4.0, Color("#3a281b"), 1.0, 0.3)
	for k in 6:
		var f := (k + 0.5) / 6.0
		var top := Vector2(r.position.x + 8, r.end.y - 30).lerp(Vector2(r.end.x - 6, r.position.y + 14), f)
		Ink.line(p, top, top + Vector2(0, 26), 2.0, Color("#3a281b"), 1.0, 0.2)


## 색유리 창(뾰족 아치): 돌 틀 + 칸마다 다른 색 유리 + 납 줄.
static func _stained(p: Paint, x: float, y: float, ww: float, wh: float) -> void:
	var outer := Paint.arch_poly(x - 10, y - 10, ww + 20, wh + 20, true)
	p.fill_poly(outer, Mat.ashlar(p, Color("#5e5a50"), int(x), int(y), 30, 18))
	Ink.path(p, outer, 2.2)
	var cols := [Color("#7a2a26"), Color("#2c4a6a"), Color("#a88a3a"), Color("#2e5a3a"), Color("#5a3a6a")]
	var glass := Paint.arch_poly(x, y, ww, wh, true)
	p.fill_poly(glass, func(px: int, py: int) -> Color:
		var cx := floori((px - x) / (ww / 5.0))
		var cy := floori((py - y) / 26.0)
		if posmod(int(px - x), int(ww / 5.0)) < 3 or posmod(int(py - y), 26) < 3:
			return Color("#1a1816")
		var c: Color = cols[int(Paint.hash01(cx, cy, 3) * cols.size()) % cols.size()]
		return p.vary(c.lightened(0.15), px, py, 0.15))
	Ink.path(p, glass, 2.0)
