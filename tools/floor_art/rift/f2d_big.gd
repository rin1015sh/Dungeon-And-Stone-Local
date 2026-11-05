extends RefCounted
## 망자의 땅 큰 구조물(사용자 2026-11-05 "커다란 구조물 — 부자연스럽지 않은 선에서, 지금은 토핑 뿌린 느낌", FL16).
## 한 그림 = 여러 칸(타일 stand size [8, 10] — 발 = 아래 가운데, 그 칸 줄에서 캐릭터와 y 정렬). 발자리 칸들은 투명 막음 타일(FieldsRouteBuild.landmarks).
## 빛은 왼쪽 위, 잉크 선은 칸 크기 기준으로 가늘게(큰 그림판에서 Kit의 p.w 비례 선은 너무 굵다). T = 바닥 한 칸 px.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")

const STONE := Color("#77746a")
const STONE_DARK := Color("#3c3a34")
const MOSS := Color("#4e5236")
const BARK := Color("#2c2620")
const INK := Color("#100c0a")
const LW := 1.4  ## 잉크 선 기본 굵기(px)


static func paint(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var T := float(w) / 8.0
	var f := Vector2(w * 0.5, h - T * 0.5)
	match tile:
		"mausoleum":
			_mausoleum(p, f, T)
		"angel":
			_angel(p, f, T)
		"tower":
			_tower(p, f, T)
		"tree":
			_tree(p, f, T)
		"knight":
			_knight(p, f, T)
		_:
			pass  # "blank" — 발자리 막음 타일(그림 없음)
	return p


## ── 공통 ──
static func _shadow(p: Paint, c: Vector2, rx: float, ry: float, a: float = 0.45) -> void:
	p.fill_poly(Cave._ellipse(c, rx, ry, 32), func(_x: int, _y: int) -> Color: return Color(0.03, 0.02, 0.03, a))


## 왼쪽이 밝은 돌 면(poly) — 높이에 따라 아래가 어둡게, 잔무늬.
static func _face(p: Paint, poly: PackedVector2Array, col: Color, light: float, ink: bool = true) -> void:
	var r := Paint.bounds(poly)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var ty := clampf((y - r.position.y) / maxf(1.0, r.size.y), 0.0, 1.0)
		var c := col.lightened(light * 0.25) if light > 0.0 else col.darkened(-light * 0.45)
		c = c.darkened(ty * 0.18)
		return p.vary(c, x, y, 0.09))
	if ink:
		Ink.path(p, poly, LW, true, INK, 0.85, 0.3)


## 상자(앞면 + 윗면 + 오른쪽 옆면): 발 가운데 foot, 폭 w, 깊이 d(화면 위로 d*0.5), 높이 h.
static func _box(p: Paint, foot: Vector2, w: float, d: float, h: float, col: Color) -> Dictionary:
	var dd := d * 0.5
	var fl := foot + Vector2(-w * 0.5, 0)
	var fr := foot + Vector2(w * 0.5, 0)
	var front := PackedVector2Array([fl + Vector2(0, -h), fr + Vector2(0, -h), fr, fl])
	var top := PackedVector2Array([fl + Vector2(0, -h), fr + Vector2(0, -h), fr + Vector2(dd * 0.3, -h - dd), fl + Vector2(dd * 0.3, -h - dd)])
	var side := PackedVector2Array([fr + Vector2(0, -h), fr + Vector2(dd * 0.3, -h - dd), fr + Vector2(dd * 0.3, -dd), fr])
	_face(p, side, col, -0.9)
	_face(p, front, col, 0.0)
	_face(p, top, col, 0.9)
	return {"front": front, "top": top, "side": side}


## 쌓은 돌 줄눈(앞면 사각 r 안에 가로줄 + 엇갈린 세로 이음매).
static func _courses(p: Paint, r: Rect2, row_h: float, alpha: float = 0.45) -> void:
	var y := r.position.y + row_h
	var k := 0
	while y < r.end.y - 2:
		Ink.line(p, Vector2(r.position.x + 1, y), Vector2(r.end.x - 1, y), 1.0, INK, alpha, 0.4)
		var x := r.position.x + (row_h * 1.6 if k % 2 == 0 else row_h * 0.8)
		while x < r.end.x - 2:
			Ink.line(p, Vector2(x, y - row_h + 1), Vector2(x, y - 1), 0.9, INK, alpha * 0.8, 0.2)
			x += row_h * 1.6
		y += row_h
		k += 1


static func _moss(p: Paint, c: Vector2, r: float, n: int) -> void:
	for k in n:
		var q := c + Vector2((Paint.hash01(k, 1, n) - 0.5) * r * 2.0, (Paint.hash01(k, 2, n) - 0.5) * r * 0.8)
		Decals._blob(p, q, r * (0.25 + Paint.hash01(k, 3, n) * 0.3), MOSS, 0.55, 0.5)


static func _crack(p: Paint, a: Vector2, dir: Vector2, len: float, seed_k: int) -> void:
	var q := a
	for s in 5:
		var b := q + dir.rotated((Paint.hash01(seed_k, s, 7) - 0.5) * 0.9) * len / 5.0
		Ink.line(p, q, b, 1.2, INK, 0.75, 0.3)
		q = b


static func _rubble(p: Paint, c: Vector2, spread: float, n: int, T: float) -> void:
	for k in n:
		var q := c + Vector2((Paint.hash01(k, 4, n) - 0.5) * spread, (Paint.hash01(k, 5, n) - 0.5) * spread * 0.3)
		var r := T * (0.12 + Paint.hash01(k, 6, n) * 0.18)
		Cave._stone(p, q, r, r * 0.7, STONE.darkened(Paint.hash01(k, 7, n) * 0.3))


## ── 큰 영묘: 계단 기단 · 기둥 넷 · 삼각 박공 · 어두운 문 · 금 · 이끼 ──
static func _mausoleum(p: Paint, f: Vector2, T: float) -> void:
	_shadow(p, f + Vector2(T * 0.4, -T * 0.4), T * 3.6, T * 1.0)
	_box(p, f, T * 6.4, T * 1.8, T * 0.35, STONE.darkened(0.1))
	_box(p, f - Vector2(0, T * 0.35), T * 5.9, T * 1.6, T * 0.3, STONE)
	var base := f - Vector2(0, T * 0.65)
	var body := _box(p, base - Vector2(0, T * 0.2), T * 5.2, T * 2.2, T * 3.4, STONE)
	_courses(p, Paint.bounds(body["front"]), T * 0.42, 0.35)
	var top_y := base.y - T * 3.6
	var door := Paint.arch_poly(base.x - T * 0.55, top_y + T * 1.0, T * 1.1, T * 2.6, true)
	p.fill_poly(door, func(_x: int, y: int) -> Color: return Color("#060505").lerp(Color("#1a1412"), clampf((y - top_y) / (T * 3.6), 0.0, 1.0) * 0.4))
	Ink.path(p, door, LW, true, INK, 0.9, 0.2)
	for k in 5:  # 쇠창살
		var x := base.x - T * 0.45 + k * T * 0.22
		Ink.line(p, Vector2(x, top_y + T * 1.5), Vector2(x, base.y - T * 0.25), 1.6, Color("#2a2622"), 0.95, 0.1)
	for cx: float in [-2.2, -1.25, 1.25, 2.2]:  # 기둥
		var x := base.x + cx * T
		var col := PackedVector2Array([Vector2(x - T * 0.22, base.y - T * 0.2), Vector2(x - T * 0.18, top_y + T * 0.2), Vector2(x + T * 0.18, top_y + T * 0.2), Vector2(x + T * 0.22, base.y - T * 0.2)])
		_face(p, col, STONE.lightened(0.05), 0.5)
		Ink.line(p, Vector2(x + T * 0.06, top_y + T * 0.3), Vector2(x + T * 0.08, base.y - T * 0.3), 1.0, INK, 0.35, 0.3)
		_box(p, Vector2(x, base.y - T * 0.15), T * 0.6, T * 0.4, T * 0.18, STONE)
		_box(p, Vector2(x, top_y + T * 0.3), T * 0.56, T * 0.4, T * 0.16, STONE)
	var ped := PackedVector2Array([Vector2(base.x - T * 2.9, top_y), Vector2(base.x, top_y - T * 1.5), Vector2(base.x + T * 2.9, top_y)])
	_face(p, ped, STONE.lightened(0.05), 0.4)
	var tym := PackedVector2Array([Vector2(base.x - T * 2.2, top_y - T * 0.12), Vector2(base.x, top_y - T * 1.15), Vector2(base.x + T * 2.2, top_y - T * 0.12)])
	_face(p, tym, STONE_DARK, -0.2, false)
	p.fill_poly(Cave._ellipse(Vector2(base.x, top_y - T * 0.45), T * 0.28, T * 0.24, 18), func(x: int, y: int) -> Color: return p.vary(Color("#c8c0aa"), x, y, 0.06))  # 새긴 해골
	for e: Vector2 in [Vector2(-0.1, -0.48), Vector2(0.1, -0.48)]:
		p.fill_poly(Cave._ellipse(Vector2(base.x + e.x * T, top_y + e.y * T), T * 0.06, T * 0.05, 10), func(_x: int, _y: int) -> Color: return INK)
	Ink.line(p, Vector2(base.x - T * 3.0, top_y + T * 0.02), Vector2(base.x + T * 3.0, top_y + T * 0.02), 2.0, INK, 0.8, 0.2)
	_crack(p, Vector2(base.x + T * 1.6, top_y + T * 0.5), Vector2(0.3, 1), T * 1.6, 3)
	_crack(p, Vector2(base.x - T * 2.5, top_y - T * 0.2), Vector2(0.6, 1), T * 0.9, 5)
	_moss(p, base + Vector2(-T * 1.8, -T * 0.2), T * 0.9, 7)
	_moss(p, Vector2(base.x - T * 1.0, top_y - T * 0.4), T * 0.6, 4)
	_rubble(p, f + Vector2(T * 2.6, -T * 0.1), T * 1.6, 7, T)


## ── 날개 꺾인 천사상: 받침 · 접힌 날개(하나는 부러짐) · 두건 쓴 몸 · 얼굴을 가린 손 ──
static func _angel(p: Paint, f: Vector2, T: float) -> void:
	_shadow(p, f + Vector2(T * 0.3, -T * 0.3), T * 2.0, T * 0.7)
	_box(p, f, T * 2.6, T * 1.6, T * 0.4, STONE.darkened(0.1))
	var ped := _box(p, f - Vector2(0, T * 0.4), T * 2.0, T * 1.3, T * 1.3, STONE)
	_courses(p, Paint.bounds(ped["front"]), T * 0.45, 0.3)
	var b := f - Vector2(0, T * 1.85)
	var stone := Color("#8a877c")
	var wl := PackedVector2Array([b + Vector2(-T * 0.4, -T * 3.6), b + Vector2(-T * 1.6, -T * 5.2), b + Vector2(-T * 2.2, -T * 4.6), b + Vector2(-T * 1.9, -T * 2.6), b + Vector2(-T * 1.2, -T * 0.6), b + Vector2(-T * 0.5, -T * 0.4)])
	_face(p, wl, stone, 0.3)
	for k in 5:
		var a := wl[2].lerp(wl[4], float(k) / 5.0)
		Ink.line(p, a, a.lerp(b + Vector2(-T * 0.4, -T * 2.6), 0.6), 1.0, INK, 0.45, 0.4)
	var wr := PackedVector2Array([b + Vector2(T * 0.4, -T * 3.6), b + Vector2(T * 1.3, -T * 4.3), b + Vector2(T * 1.5, -T * 3.4), b + Vector2(T * 1.1, -T * 3.3)])  # 부러진 날개
	_face(p, wr, stone.darkened(0.1), -0.5)
	Ink.line(p, wr[2], wr[3], 1.6, INK, 0.9, 1.2)
	var robe := PackedVector2Array([b + Vector2(-T * 0.75, 0), b + Vector2(-T * 0.55, -T * 2.4), b + Vector2(-T * 0.35, -T * 3.5), b + Vector2(0, -T * 3.85), b + Vector2(T * 0.35, -T * 3.5), b + Vector2(T * 0.55, -T * 2.4), b + Vector2(T * 0.8, 0)])
	_face(p, robe, stone, 0.2)
	for k in 5:  # 옷 주름
		var x := -0.5 + k * 0.25
		Ink.line(p, b + Vector2(x * T, -T * 0.1), b + Vector2(x * T * 0.7, -T * 2.2), 1.0, INK, 0.4, 0.6)
	var hood := Cave._ellipse(b + Vector2(0, -T * 3.65), T * 0.36, T * 0.42, 20)
	_face(p, hood, stone.lightened(0.05), 0.4)
	p.fill_poly(Cave._ellipse(b + Vector2(T * 0.04, -T * 3.55), T * 0.2, T * 0.24, 16), func(_x: int, _y: int) -> Color: return Color("#2a2824"))
	var hand := PackedVector2Array([b + Vector2(-T * 0.22, -T * 3.4), b + Vector2(T * 0.25, -T * 3.5), b + Vector2(T * 0.3, -T * 3.25), b + Vector2(-T * 0.2, -T * 3.15)])
	_face(p, hand, stone.lightened(0.1), 0.6)
	_crack(p, b + Vector2(T * 0.2, -T * 3.0), Vector2(0.2, 1), T * 2.2, 9)
	_moss(p, f - Vector2(T * 0.5, T * 0.6), T * 0.7, 5)
	_moss(p, b + Vector2(-T * 1.6, -T * 3.0), T * 0.5, 3)
	for k in 6:  # 흘러내린 이끼 줄기
		var x := b.x - T * 0.5 + k * T * 0.2
		Ink.line(p, Vector2(x, b.y - T * 2.0), Vector2(x + T * 0.05, b.y - T * (1.2 + Paint.hash01(k, 1, 6) * 0.6)), 1.2, MOSS.darkened(0.2), 0.7, 0.6)


## ── 무너진 종탑: 높은 사각 탑 · 위 종 창(아치 둘 — 하나에 기운 종) · 부서진 꼭대기 · 버팀벽 · 발치 돌무더기 ──
static func _tower(p: Paint, f: Vector2, T: float) -> void:
	_shadow(p, f + Vector2(T * 0.5, -T * 0.4), T * 2.6, T * 0.9)
	var body := _box(p, f, T * 3.0, T * 2.2, T * 6.6, STONE)
	var fr: Rect2 = Paint.bounds(body["front"])
	_courses(p, fr, T * 0.38, 0.3)
	var top := fr.position.y
	var jag := PackedVector2Array([Vector2(fr.position.x - 1, top - 2)])  # 부서진 꼭대기(앞면 위를 검게 깎는다)
	for k in 9:
		var x := fr.position.x + fr.size.x * float(k) / 8.0
		jag.append(Vector2(x, top + T * (0.2 + Paint.hash01(k, 1, 9) * 0.9) * (1.0 if k % 3 != 1 else 0.3)))
	jag.append(Vector2(fr.end.x + T * 0.4, top - 2))
	jag.append(Vector2(fr.end.x + T * 0.4, top - T * 1.4))
	jag.append(Vector2(fr.position.x - 1, top - T * 1.4))
	p.fill_poly(jag, func(_x: int, _y: int) -> Color: return Color(0, 0, 0, 0))
	for x in range(int(fr.position.x), int(fr.end.x + T * 0.5)):
		for y in range(int(top - T * 1.4), int(top + T * 1.2)):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), jag) and x >= 0 and y >= 0 and x < p.w and y < p.h:
				var i := (y * p.w + x) * 4
				p.buf[i + 3] = 0.0
	for k in 9:
		var x := fr.position.x + fr.size.x * float(k) / 8.0
		var y := top + T * (0.2 + Paint.hash01(k, 1, 9) * 0.9) * (1.0 if k % 3 != 1 else 0.3)
		if k > 0:
			var px := fr.position.x + fr.size.x * float(k - 1) / 8.0
			var py := top + T * (0.2 + Paint.hash01(k - 1, 1, 9) * 0.9) * (1.0 if (k - 1) % 3 != 1 else 0.3)
			Ink.line(p, Vector2(px, py), Vector2(x, y), LW, INK, 0.9, 0.3)
	for k in 2:  # 종 창
		var x := fr.position.x + T * (0.45 + k * 1.25)
		var win := Paint.arch_poly(x, top + T * 1.4, T * 0.8, T * 1.5)
		p.fill_poly(win, func(_x: int, _y: int) -> Color: return Color("#070606"))
		Ink.path(p, win, LW, true, INK, 0.9, 0.2)
		if k == 0:  # 기운 종
			var bc := Vector2(x + T * 0.42, top + T * 2.2)
			var bell := PackedVector2Array([bc + Vector2(-T * 0.18, -T * 0.35), bc + Vector2(T * 0.14, -T * 0.38), bc + Vector2(T * 0.32, T * 0.25), bc + Vector2(-T * 0.32, T * 0.3)])
			_face(p, bell, Color("#5a4a2c"), 0.3)
	var lw := PackedVector2Array([Vector2(fr.position.x - T * 0.5, f.y), Vector2(fr.position.x, f.y - T * 2.2), Vector2(fr.position.x, f.y)])  # 버팀벽
	_face(p, lw, STONE.darkened(0.05), 0.4)
	for k in 3:  # 창 아래 좁은 틈
		var y := top + T * (3.6 + k * 0.9)
		p.fill_rect(fr.get_center().x - T * 0.06, y, T * 0.12, T * 0.45, func(_x: int, _y: int) -> Color: return Color("#090807"))
	_crack(p, Vector2(fr.end.x - T * 0.6, top + T * 1.2), Vector2(-0.2, 1), T * 3.0, 4)
	for k in 9:  # 덩굴
		var x := fr.position.x + T * (0.2 + Paint.hash01(k, 3, 9) * 2.6)
		Ink.line(p, Vector2(x, f.y - T * 0.3), Vector2(x + (Paint.hash01(k, 4, 9) - 0.5) * T * 0.6, f.y - T * (1.0 + Paint.hash01(k, 5, 9) * 2.5)), 1.3, MOSS.darkened(0.25), 0.8, 0.9)
	_moss(p, f - Vector2(T * 0.4, T * 0.6), T * 1.0, 6)
	_rubble(p, f + Vector2(T * 1.9, -T * 0.05), T * 2.0, 9, T)


## ── 거대한 고목: 굵은 밑동 · 드러난 뿌리 · 넓게 퍼진 앙상한 가지 · 늘어진 이끼 ──
static func _tree(p: Paint, f: Vector2, T: float) -> void:
	_shadow(p, f + Vector2(T * 0.3, -T * 0.2), T * 2.0, T * 0.6)
	var trunk := PackedVector2Array([f + Vector2(-T * 1.1, 0), f + Vector2(-T * 0.55, -T * 0.6), f + Vector2(-T * 0.42, -T * 3.4), f + Vector2(-T * 0.2, -T * 4.6), f + Vector2(T * 0.25, -T * 4.5), f + Vector2(T * 0.45, -T * 3.2), f + Vector2(T * 0.6, -T * 0.6), f + Vector2(T * 1.2, 0)])
	_face(p, trunk, BARK, 0.2)
	for k in 7:  # 껍질 결
		var x := -0.35 + k * 0.12
		Ink.line(p, f + Vector2(x * T, -T * 0.2), f + Vector2(x * T * 0.6, -T * 3.8), 1.0, INK, 0.5, 0.8)
	for k in 4:  # 뿌리
		var d := Vector2(-1.6 + k * 1.05, 0.15)
		Ink.line(p, f + Vector2(d.x * 0.3, -T * 0.3) * Vector2(T, 1.0), f + Vector2(d.x * T, T * 0.1), T * 0.22, BARK.darkened(0.1), 1.0, 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	_branch(p, f + Vector2(0, -T * 4.4), Vector2(-0.6, -1.0), T * 2.0, T * 0.5, 5, rng)
	_branch(p, f + Vector2(T * 0.1, -T * 4.3), Vector2(0.7, -0.9), T * 2.1, T * 0.48, 5, rng)
	_branch(p, f + Vector2(0, -T * 4.5), Vector2(0.05, -1.0), T * 1.6, T * 0.36, 4, rng)
	_branch(p, f + Vector2(-T * 0.3, -T * 3.0), Vector2(-1.0, -0.35), T * 1.7, T * 0.34, 4, rng)
	_branch(p, f + Vector2(T * 0.35, -T * 2.6), Vector2(1.0, -0.3), T * 1.6, T * 0.32, 4, rng)
	_moss(p, f - Vector2(T * 0.2, T * 0.3), T * 0.8, 5)


static func _branch(p: Paint, a: Vector2, dir: Vector2, len: float, wd: float, depth: int, rng: RandomNumberGenerator) -> void:
	var b := a + dir.normalized() * len
	Ink.line(p, a, b, maxf(1.2, wd), BARK, 1.0, 0.8)
	Ink.line(p, a + Vector2(-wd * 0.25, 0), b + Vector2(-wd * 0.2, 0), maxf(0.8, wd * 0.25), Color("#4a4238"), 0.5, 0.8)
	if depth == 1 and rng.randf() < 0.5:  # 늘어진 이끼
		Ink.line(p, b, b + Vector2(rng.randf_range(-3, 3), rng.randf_range(len * 0.4, len * 0.9)), 1.2, MOSS.darkened(0.3), 0.6, 0.5)
	if depth <= 0:
		return
	for k in 2 + (1 if rng.randf() < 0.4 else 0):
		var d := dir.normalized().rotated(rng.randf_range(-0.75, 0.75))
		_branch(p, a.lerp(b, rng.randf_range(0.55, 1.0)), d, len * rng.randf_range(0.55, 0.75), wd * 0.62, depth - 1, rng)


## ── 문지기 기사상: 받침 · 투구 · 망토 · 땅에 꽂은 대검 ──
static func _knight(p: Paint, f: Vector2, T: float) -> void:
	_shadow(p, f + Vector2(T * 0.3, -T * 0.3), T * 1.6, T * 0.6)
	_box(p, f, T * 2.1, T * 1.4, T * 0.35, STONE.darkened(0.1))
	var ped := _box(p, f - Vector2(0, T * 0.35), T * 1.6, T * 1.1, T * 1.4, STONE)
	_courses(p, Paint.bounds(ped["front"]), T * 0.45, 0.3)
	var b := f - Vector2(0, T * 1.9)
	var stone := Color("#7e7c74")
	var cape := PackedVector2Array([b + Vector2(-T * 0.7, 0), b + Vector2(-T * 0.55, -T * 2.9), b + Vector2(T * 0.55, -T * 2.9), b + Vector2(T * 0.75, 0)])
	_face(p, cape, stone.darkened(0.15), -0.2)
	var body := PackedVector2Array([b + Vector2(-T * 0.38, -T * 0.1), b + Vector2(-T * 0.5, -T * 2.8), b + Vector2(-T * 0.2, -T * 3.05), b + Vector2(T * 0.2, -T * 3.05), b + Vector2(T * 0.5, -T * 2.8), b + Vector2(T * 0.4, -T * 0.1)])
	_face(p, body, stone, 0.25)
	for k in 4:  # 갑옷 판
		var y := b.y - T * (0.8 + k * 0.45)
		Ink.line(p, Vector2(b.x - T * 0.42, y), Vector2(b.x + T * 0.42, y + T * 0.04), 1.0, INK, 0.45, 0.3)
	var helm := PackedVector2Array([b + Vector2(-T * 0.25, -T * 3.0), b + Vector2(-T * 0.22, -T * 3.55), b + Vector2(0, -T * 3.7), b + Vector2(T * 0.22, -T * 3.55), b + Vector2(T * 0.25, -T * 3.0)])
	_face(p, helm, stone.lightened(0.05), 0.4)
	Ink.line(p, b + Vector2(-T * 0.16, -T * 3.32), b + Vector2(T * 0.16, -T * 3.32), 2.0, INK, 0.9, 0.1)
	var blade := PackedVector2Array([b + Vector2(-T * 0.09, -T * 2.0), b + Vector2(T * 0.09, -T * 2.0), b + Vector2(T * 0.05, T * 0.2), b + Vector2(0, T * 0.35), b + Vector2(-T * 0.05, T * 0.2)])
	_face(p, blade, Color("#9a9a94"), 0.5)
	Ink.line(p, b + Vector2(-T * 0.45, -T * 2.0), b + Vector2(T * 0.45, -T * 2.0), 3.0, Color("#4a4640"), 1.0, 0.1)  # 코등이
	Ink.line(p, b + Vector2(0, -T * 2.0), b + Vector2(0, -T * 2.45), 3.0, Color("#3a3630"), 1.0, 0.1)
	p.fill_poly(Cave._ellipse(b + Vector2(0, -T * 2.15), T * 0.32, T * 0.12, 14), func(x: int, y: int) -> Color: return p.vary(stone, x, y, 0.06))  # 손잡이 쥔 손
	_crack(p, b + Vector2(T * 0.3, -T * 2.6), Vector2(0.1, 1), T * 1.5, 11)
	_moss(p, f - Vector2(0, T * 0.5), T * 0.6, 4)
