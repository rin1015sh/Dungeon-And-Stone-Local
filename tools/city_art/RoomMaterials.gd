extends RefCounted
## 시설 실내 바닥·벽 재질(RoomPaint·RoomWalls 전용 — CT67: 사용자 "죄다 마루바닥이 똑같고 너무 어둡다 — 라비기온 7구역처럼 적당히 밝고 한눈에 건물 특색이 드러나게").
## 바닥: oak 넓은 참나무 판자(길드) · honey 꿀빛 판자(여관) · parquet 바구니 엮음 쪽마루(도서관·은행 2층) · terracotta 붉은 흙 타일(주방) ·
##   brick 엇갈려 쌓은 붉은 벽돌(잡화점) · limestone 흰 석회암 큰 판석(신전) · flag 회색 막돌 판석 · cobble 둥근 자갈(대장간) · marble 크림·잿빛 갈색 대리석 바둑판(은행 — 칸 하나 = 타일 하나) ·
##   dirt 다진 흙(훈련장·뒷마당) · dark 어두운 돌(지하) · wood 보통 판자.
## 벽: ashlar 돌 · limestone 흰 석회암 · plaster 따뜻한 회벽 · panel 짙은 나무 판벽(도서관) · brick 벽돌 · timber 판자벽 · marble 흰 대리석 판.

const Paint := preload("res://tools/city_art/Paint.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")


static func floor(p: Paint, m: String, t: int) -> Callable:
	match m:
		"oak":
			return _boards(p, Color("#7a5634"), int(t * 0.5), 220, true)
		"honey":
			return _boards(p, Color("#9a7040"), int(t * 0.36), 170, false)
		"parquet":
			return _parquet(p, Color("#6e4a2c"), Color("#8a6038"), t)
		"terracotta":
			return _tiles(p, Color("#9e5236"), Color("#5a3a2a"), int(t * 0.5), 0.0)
		"brick":
			return _bond(p, Color("#8a5038"), Color("#4e3a2e"), t)
		"limestone":
			return Mat.ashlar(p, Color("#b4ab98"), 0, 0, int(t * 1.8), int(t * 1.2))
		"flag":
			return _flag(p, Color("#8a857a"), Color("#4a4640"))
		"cobble":
			return _cobble(p, Color("#847c70"), Color("#3a342e"))
		"marble":
			return _tiles(p, Color("#c8bea8"), Color("#4e463e"), t, 1.0)
		"dirt":
			return func(x: int, y: int) -> Color: return p.vary(Color("#8a7454").darkened(absf(p.nz("hs", x, y) - 0.5) * 0.4), x, y, 0.22)
		"dark":
			return Mat.ashlar(p, Color("#5a5652"), 0, 0, int(t * 1.2), int(t * 0.8))
	return _boards(p, Color("#7a5a3a"), int(t * 0.42), 190, false)


static func wall(p: Paint, w: String, t: int) -> Callable:
	match w:
		"limestone":
			return Mat.ashlar(p, Color("#8e8676"), 0, 0, int(t * 1.1), int(t * 0.45))
		"plaster":
			return Mat.plaster(p, Color("#a8957a"), 0.18)
		"panel":
			return _panel(p, Color("#4a3020"), t)
		"brick":
			return Mat.brick(p, Color("#7a4634"), 0, 0, int(t * 0.5), int(t * 0.2))
		"timber":
			return Mat.planks(p, Color("#6a4a30"), 0, 0, true, int(t * 0.28))
		"marble":  # 바닥 바둑판과 헷갈리지 않게 — 크림색 회벽 판 + 세로 붙임기둥 줄
			return _pilaster(p, Color("#c4b9a2"), t)
	return Mat.ashlar(p, Color("#6a655c"), 0, 0, int(t * 0.95), int(t * 0.42))


## 판자: 가로 판, 판마다 이음매가 엇갈리고 색이 조금씩 — nails면 이음매 곁에 못 자국.
static func _boards(p: Paint, base: Color, bh: int, span: int, nails: bool) -> Callable:
	return func(x: int, y: int) -> Color:
		var row := floori(y / float(bh))
		var ly := posmod(y, bh)
		var len := span + int(Paint.hash01(row, 3) * span * 0.6)
		var off := int(Paint.hash01(row, 9) * 400.0)
		var lx := posmod(x + off, len)
		var idx := floori((x + off) / float(len))
		if ly == 0 or lx == 0:
			return p.vary(base.darkened(0.6), x, y, 0.1)
		if nails and (lx == 4 or lx == len - 5) and (ly == 3 or ly == bh - 4):
			return Color("#2a221a")
		var tone := base.lightened((Paint.hash01(row, idx, 5) - 0.5) * 0.24).darkened(absf(p.nz("hs", x, y) - 0.5) * 0.35)
		if ly == 1:
			tone = tone.lightened(0.1)
		elif ly >= bh - 2:
			tone = tone.darkened(0.22)
		return p.vary(tone, x, y, 0.12)


## 바구니 엮음 쪽마루: 칸 반 크기 네모마다 판 방향이 가로·세로로 번갈아.
static func _parquet(p: Paint, a: Color, b: Color, t: int) -> Callable:
	var s := t / 2
	var strip := maxi(4, s / 4)
	return func(x: int, y: int) -> Color:
		var cx := floori(x / float(s))
		var cy := floori(y / float(s))
		var vertical := (cx + cy) % 2 == 0
		var u := posmod(x if vertical else y, s)
		var line := posmod(u, strip) == 0
		var base := a if (floori(u / float(strip)) % 2 == 0) else b
		if posmod(x, s) == 0 or posmod(y, s) == 0:
			return p.vary(a.darkened(0.55), x, y, 0.1)
		if line:
			return p.vary(base.darkened(0.35), x, y, 0.1)
		return p.vary(base.darkened(absf(p.nz("vs" if vertical else "hs", x, y) - 0.5) * 0.3), x, y, 0.1)


## 네모 타일(grout 줄눈). checker 1이면 바둑판(a·b 번갈아 — 대리석), 0이면 a 하나에 색 흔들기.
static func _tiles(p: Paint, a: Color, grout: Color, s: int, checker: float) -> Callable:
	return func(x: int, y: int) -> Color:
		var cx := floori(x / float(s))
		var cy := floori(y / float(s))
		if posmod(x, s) < 2 or posmod(y, s) < 2:
			return p.vary(grout, x, y, 0.08)
		var c := a
		if checker > 0.0 and (cx + cy) % 2 == 1:
			c = Color("#6a5e52")
		c = c.lightened((Paint.hash01(cx, cy, 11) - 0.5) * 0.14)
		if checker > 0.0:
			c = c.lerp(Color("#e0d8c4") if (cx + cy) % 2 == 0 else Color("#7a6e60"), absf(p.nz("vs", x, y) - 0.5) * 0.3)  # 대리석 결
		return p.vary(c, x, y, 0.08)


## 엇갈려 쌓은 벽돌: 가로로 긴 벽돌(칸 반 × 칸 4분의 1), 줄마다 반 장씩 어긋난다.
static func _bond(p: Paint, a: Color, grout: Color, t: int) -> Callable:
	var bw := t / 2
	var bh := t / 4
	return func(x: int, y: int) -> Color:
		var row := floori(y / float(bh))
		var xx := x + (bw / 2 if row % 2 == 1 else 0)
		var col := floori(xx / float(bw))
		if posmod(y, bh) < 2 or posmod(xx, bw) < 2:
			return p.vary(grout, x, y, 0.08)
		var c := a.lightened((Paint.hash01(col, row, 17) - 0.5) * 0.24)
		return p.vary(c.darkened(absf(p.nz("hs", x, y) - 0.5) * 0.25), x, y, 0.12)


## 막돌 판석: 세포 잡음 경계 = 줄눈.
static func _flag(p: Paint, a: Color, grout: Color) -> Callable:
	return func(x: int, y: int) -> Color:
		var n := p.nz("cell", x / 2, y / 2)
		if n < 0.08:
			return p.vary(grout, x, y, 0.08)
		return p.vary(a.lightened((p.nz("lo", x, y) - 0.5) * 0.3), x, y, 0.12)


## 둥근 자갈: 작은 세포 + 가운데 밝게.
static func _cobble(p: Paint, a: Color, grout: Color) -> Callable:
	return func(x: int, y: int) -> Color:
		var n := p.nz("cell", x * 3 / 4, y * 3 / 4)
		if n < 0.1:
			return p.vary(grout, x, y, 0.08)
		return p.vary(a.lightened((n - 0.4) * 0.35).darkened(p.nz("lo", x, y) * 0.2), x, y, 0.14)


## 나무 판벽: 위 판 · 가운데 틀(몰딩) · 아래 판.
static func _panel(p: Paint, base: Color, t: int) -> Callable:
	return func(x: int, y: int) -> Color:
		var u := posmod(x, int(t * 0.8))
		var v := posmod(y, t)
		var c := base
		if u < 3 or v < 3:
			c = base.darkened(0.45)
		elif u < 6 or v < 6:
			c = base.lightened(0.18)
		return p.vary(c.darkened(absf(p.nz("vs", x, y) - 0.5) * 0.3), x, y, 0.12)


## 붙임기둥 벽: 크림색 회벽 판, 칸 1.5개마다 세로 기둥(밝은 면 + 그늘 줄).
static func _pilaster(p: Paint, base: Color, t: int) -> Callable:
	var span := int(t * 1.5)
	return func(x: int, y: int) -> Color:
		var u := posmod(x, span)
		var c := base.darkened(absf(p.nz("vs", x, y) - 0.5) * 0.2)
		if u < 5:
			c = base.lightened(0.12)
		elif u < 8:
			c = base.darkened(0.35)
		return p.vary(c, x, y, 0.06)
