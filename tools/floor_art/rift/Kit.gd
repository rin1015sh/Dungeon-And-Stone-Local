extends RefCounted
## 균열 소품 그리기 부품(3/4 시점 — 탐험 맵: 위에서 비스듬히 내려다봄, 빛은 왼쪽 위, 잉크 윤곽 + 붓 결).
## 좌표는 그림 px. foot = 바닥에 닿는 앞 가운데 점. 깊이(d)는 화면에서 위로 눌린 높이(d × DEPTH).
## 장소 모듈(bf·gc·gm·it.gd)이 쓴다 — 색만 바꿔 여러 물건을 조립한다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")

const DEPTH := 0.55  ## 바닥 깊이가 화면에서 눌리는 비율(3/4 시점)
const LIT := Color("#fff2d8")


## 발밑 그림자(바닥에 깔린 흐린 타원).
static func shadow(p: Paint, foot: Vector2, rx: float, ry: float, a: float = 0.42) -> void:
	p.fill_poly(Cave._ellipse(foot + Vector2(rx * 0.12, 0), rx, ry, 28), func(_x: int, _y: int) -> Color: return Color(0.03, 0.02, 0.03, a))


## 상자(나무 궤짝·돌 받침·탁자 상판 덩어리): 너비 w, 깊이 d(바닥), 높이 h. 앞면 + 윗면 + 오른쪽 옆면(그늘).
static func box(p: Paint, foot: Vector2, w: float, d: float, h: float, col: Color, ink: float = 1.0, grain: float = 0.08) -> Dictionary:
	var dd := d * DEPTH
	var fl := foot + Vector2(-w * 0.5, 0)
	var fr := foot + Vector2(w * 0.5, 0)
	var front := PackedVector2Array([fl + Vector2(0, -h), fr + Vector2(0, -h), fr, fl])
	var top := PackedVector2Array([fl + Vector2(0, -h), fr + Vector2(0, -h), fr + Vector2(dd * 0.35, -h - dd), fl + Vector2(dd * 0.35, -h - dd)])
	var side := PackedVector2Array([fr + Vector2(0, -h), fr + Vector2(dd * 0.35, -h - dd), fr + Vector2(dd * 0.35, -dd), fr])
	p.fill_poly(side, func(x: int, y: int) -> Color: return p.vary(col.darkened(0.45), x, y, grain))
	p.fill_poly(front, func(x: int, y: int) -> Color:
		var t := clampf((y - (foot.y - h)) / maxf(1.0, h), 0.0, 1.0)
		return p.vary(col.darkened(0.12 + t * 0.2), x, y, grain))
	p.fill_poly(top, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.22), x, y, grain))
	var u := ink * p.w / 128.0
	Ink.path(p, PackedVector2Array([fl, fl + Vector2(0, -h), fl + Vector2(dd * 0.35, -h - dd), fr + Vector2(dd * 0.35, -h - dd), fr + Vector2(dd * 0.35, -dd), fr, fl]), 1.6 * u, true, Ink.INK, 0.85, 0.4)
	Ink.line(p, fl + Vector2(0, -h), fr + Vector2(0, -h), 1.0 * u, LIT, 0.35, 0.3)
	Ink.line(p, fr + Vector2(0, -h), fr, 1.1 * u, Ink.INK, 0.6, 0.3)
	return {"front": front, "top": top, "side": side}


## 판자 무늬(앞면 poly 안에 가로줄 n개).
static func planks(p: Paint, poly: PackedVector2Array, n: int, col: Color) -> void:
	var r := Paint.bounds(poly)
	for k in range(1, n):
		var y := r.position.y + r.size.y * k / n
		Ink.line(p, Vector2(r.position.x + 1, y), Vector2(r.end.x - 1, y), 0.9 * p.w / 128.0, col.darkened(0.6), 0.55, 0.5)


## 원통(통·기둥·탑): 반지름 r, 높이 h. 둥근 윗면 + 왼쪽이 밝은 몸통 + 테(hoops).
static func cyl(p: Paint, foot: Vector2, r: float, h: float, col: Color, hoops: int = 0, hoop_col: Color = Color("#2a2420")) -> void:
	var ry := r * DEPTH * 0.6
	var body := PackedVector2Array()
	for k in 13:
		var a := PI * k / 12.0
		body.append(foot + Vector2(cos(a) * r, sin(a) * ry))
	body.append(foot + Vector2(-r, -h))
	for k in 13:
		var a := PI + PI * k / 12.0
		body.append(foot + Vector2(cos(a) * r, -h + sin(a) * ry))
	body.append(foot + Vector2(r, 0))
	p.fill_poly(body, func(x: int, y: int) -> Color:
		var t := clampf((x - (foot.x - r)) / (2.0 * r), 0.0, 1.0)
		var shade := 0.15 + pow(t, 1.3) * 0.5 - (1.0 - absf(t - 0.3) * 2.0) * 0.12
		return p.vary(col.darkened(clampf(shade, 0.0, 0.8)), x, y, 0.07))
	var top := Cave._ellipse(foot + Vector2(0, -h), r, ry, 24)
	p.fill_poly(top, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.15), x, y, 0.07))
	for k in hoops:
		var hy := -h * (0.18 + 0.64 * k / maxf(1.0, hoops - 1))
		var pts := PackedVector2Array()
		for j in 13:
			var a := PI * j / 12.0
			pts.append(foot + Vector2(cos(a) * r, hy + sin(a) * ry))
		Ink.path(p, pts, 2.2 * p.w / 128.0, false, hoop_col, 0.85, 0.2)
	var u := p.w / 128.0
	Ink.path(p, top, 1.3 * u, true, Ink.INK, 0.7, 0.3)
	Ink.line(p, foot + Vector2(-r, -h), foot + Vector2(-r, 0), 1.5 * u, Ink.INK, 0.8, 0.3)
	Ink.line(p, foot + Vector2(r, -h), foot + Vector2(r, 0), 1.5 * u, Ink.INK, 0.8, 0.3)
	var bot := PackedVector2Array()
	for k in 13:
		var a := PI * k / 12.0
		bot.append(foot + Vector2(cos(a) * r, sin(a) * ry))
	Ink.path(p, bot, 1.5 * u, false, Ink.INK, 0.8, 0.3)


## 기둥·말뚝·다리(두 점 사이 굵은 막대 — 왼쪽 가장자리 밝게).
static func post(p: Paint, a: Vector2, b: Vector2, wd: float, col: Color) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x) * wd * 0.5
	var poly := PackedVector2Array([a + n, b + n, b - n, a - n])
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var s := (Vector2(x, y) - a).dot(n.normalized()) / maxf(0.5, wd * 0.5)
		return p.vary(col.darkened(0.15 - s * 0.2), x, y, 0.08))
	var u := p.w / 128.0
	Ink.line(p, a + n, b + n, 1.2 * u, Ink.INK, 0.75, 0.3)
	Ink.line(p, a - n, b - n, 1.2 * u, Ink.INK, 0.75, 0.3)


## 원뿔·뾰족한 덩어리(천막·고드름·결정·말뚝 끝): 밑변 가운데 base, 반폭 r, 높이 h. 왼쪽 면 밝게.
static func cone(p: Paint, base: Vector2, r: float, h: float, col: Color, lean: float = 0.0) -> void:
	var tip := base + Vector2(lean * h, -h)
	var left := PackedVector2Array([base + Vector2(-r, 0), tip, base + Vector2(r * 0.1, r * 0.25)])
	var right := PackedVector2Array([base + Vector2(r * 0.1, r * 0.25), tip, base + Vector2(r, 0)])
	p.fill_poly(left, func(x: int, y: int) -> Color: return p.vary(col.lightened(0.12), x, y, 0.06))
	p.fill_poly(right, func(x: int, y: int) -> Color: return p.vary(col.darkened(0.35), x, y, 0.06))
	Ink.path(p, PackedVector2Array([base + Vector2(-r, 0), tip, base + Vector2(r, 0)]), 1.3 * p.w / 128.0, false, Ink.INK, 0.8, 0.3)


## 덩어리(바위·자루·눈 더미·버섯 갓): 왼쪽 위가 밝은 둥근 덩어리(Cave._stone).
static func blob(p: Paint, c: Vector2, rx: float, ry: float, col: Color) -> void:
	Cave._stone(p, c, rx, ry, col)


## 빛 번짐(화로·촛불·랜턴·결정) — 그림 바깥까지 은은하게(only_painted = false).
static func glow(p: Paint, c: Vector2, r: float, col: Color, strength: float = 0.6) -> void:
	Ink.glow(p, c.x, c.y, r, col, strength, false)


## 불꽃(화로·모닥불·촛불): 바깥 주황 → 안쪽 노랑 → 흰 심.
static func flame(p: Paint, c: Vector2, size: float) -> void:
	glow(p, c + Vector2(0, -size * 0.4), size * 3.2, Color("#ff9a40"), 0.45)
	for k in 3:
		var s := size * (1.0 - k * 0.28)
		var col: Color = [Color("#e8601c"), Color("#ffb040"), Color("#fff2c0")][k]
		var poly := PackedVector2Array([c + Vector2(-s * 0.55, 0), c + Vector2(-s * 0.3, -s * 0.9), c + Vector2(0, -s * 1.7), c + Vector2(s * 0.32, -s * 0.85), c + Vector2(s * 0.55, 0)])
		p.fill_poly(poly, func(_x: int, _y: int) -> Color: return col)
