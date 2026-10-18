extends RefCounted
## 빙하굴 그림 공통 부품(gc.gd 전용): 밝기 맞춘 색 · 늘인 주기 잡음 · 고드름 · 움푹한 자국 · 얼음 속 금 · 거품 · 서리 · 눈 둔덕.
## 밝은 재질(눈·얼음)은 평균 맞추기(paint_floor._row — 밝기 0.6 미만만 센다) 전에 tone(밝기 0.46)으로 어둡게 칠한다 —
## 맞추기가 비율 그대로 밝혀 주므로 그늘·빛의 차이가 남는다. 스스로 빛나는 반짝임·거품만 0.8 넘게 칠한다(덜 맞춰짐).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")

const SPARK := Color("#f4f8ff")  ## 반짝임·거품(밝게 남는다)
const ICE_LIGHT := Color("#d8f0fa")
const ICE_MID := Color("#7fb4cc")
const ICE_DARK := Color("#2c5068")
const ICE_GLOW := Color("#8fe0ff")
const SNOW := Color("#e4eaf0")
const SNOW_SHADE := Color("#8a9cb8")


## 밝은 데이터 색 → 밝기 0.46인 같은 색조(어두운 색은 그대로).
static func tone(col: Color) -> Color:
	var l := col.get_luminance()
	if l <= 0.46:
		return col
	var k := 0.46 / l
	return Color(col.r * k, col.g * k, col.b * k)


## 변형끼리 같은 시드(paint_floor는 변형 시드를 바탕 시드 + 1000 × (v + 1)로 준다) — 큰 덩어리 잡음은 모든 변형이 같게 해서
## 칸 가장자리 녹임(Seam.mask)이 네모로 보이지 않게 한다.
static func shared(s: int) -> int:
	return posmod(s, 1000) + 17


## 같은 색을 채널별로 곱한다(색조 유지 — 푸른 그늘·청록 빛).
static func mul(c: Color, r: float, g: float, b: float) -> Color:
	return Color(c.r * r, c.g * g, c.b * b, c.a)


## 세 단계 색 띠: t 0 → a, 0.5 → b, 1 → c.
static func ramp(t: float, a: Color, b: Color, c: Color) -> Color:
	var k := clampf(t, 0.0, 1.0)
	return a.lerp(b, k * 2.0) if k < 0.5 else b.lerp(c, (k - 0.5) * 2.0)


## 늘인 주기 잡음: 작은 주기 장 f(fw × fh)를 (x, y)에서 겹선형으로 읽는다 — 가로·세로로 말려 이어진다.
static func sample(f: PackedFloat32Array, fw: int, fh: int, x: float, y: float) -> float:
	var x0 := floori(x)
	var y0 := floori(y)
	var tx := x - x0
	var ty := y - y0
	var a := lerpf(Seam.at(f, fw, fh, x0, y0), Seam.at(f, fw, fh, x0 + 1, y0), tx)
	var b := lerpf(Seam.at(f, fw, fh, x0, y0 + 1), Seam.at(f, fw, fh, x0 + 1, y0 + 1), tx)
	return lerpf(a, b, ty)


## 고드름·얼음 가시 하나: root에서 끝(tip)까지 뾰족. 왼쪽 면 밝게, 오른쪽 면 푸른 그늘, 가운데 빛 줄, 잉크 윤곽.
static func spike(p: Paint, root: Vector2, tip: Vector2, wd: float, light: Color, dark: Color, ink: float = 1.0) -> void:
	var d := (tip - root).normalized()
	var n := Vector2(-d.y, d.x)
	if n.x > 0.0:
		n = -n  # n = 왼쪽(빛 쪽)
	var l := root + n * wd
	var r := root - n * wd
	var mid := root + d * wd * 0.3
	p.fill_poly(PackedVector2Array([l, tip, mid]), func(x: int, y: int) -> Color: return p.vary(light, x, y, 0.05))
	p.fill_poly(PackedVector2Array([mid, tip, r]), func(x: int, y: int) -> Color: return p.vary(dark, x, y, 0.05))
	Ink.line(p, root.lerp(l, 0.5), tip.lerp(l, 0.08), maxf(0.6, wd * 0.35), SPARK, 0.55, 0.2)
	if ink > 0.0:
		Ink.path(p, PackedVector2Array([l, tip, r]), maxf(0.7, wd * 0.32) * ink, false, Ink.INK, 0.7, 0.2)


## 움푹한 자국(발자국·짐승 발자국·홈): 위·왼쪽 안쪽은 그늘(빛을 가리는 턱), 오른쪽 아래 가장자리는 빛.
static func dent(p: Paint, q: Vector2, rx: float, ry: float, depth: float, shade: Color, lit: Color, ang: float = 0.0) -> void:
	var poly := Cave._ellipse(Vector2.ZERO, rx, ry, 16)
	var rot := PackedVector2Array()
	for v in poly:
		rot.append(q + v.rotated(ang))
	p.fill_poly(rot, func(x: int, y: int) -> Color:
		var d := (Vector2(x, y) - q).rotated(-ang) / Vector2(rx, ry)
		var e := clampf(1.0 - d.length(), 0.0, 1.0)
		return Color(shade.r, shade.g, shade.b, depth * clampf(0.55 - (d.x + d.y) * 0.4, 0.1, 1.0) * (0.4 + e)), 1.0, true)
	var a := q + Vector2(rx * 0.75, ry * 0.2).rotated(ang)
	var b := q + Vector2(-rx * 0.1, ry * 0.95).rotated(ang)
	Ink.line(p, a, b, maxf(0.7, rx * 0.3), lit, 0.45 * depth, 0.3, true)


## 얼음 속 금: 흰 깨진 면(넓고 흐린 빛) + 가는 짙은 심 + 잔가지.
static func crack(p: Paint, start: Vector2, segs: int, seg_len: float, dir: Vector2, lit: Color, core: Color, wd: float) -> void:
	var a := start
	var d := dir.normalized()
	for k in segs:
		d = d.rotated(p.rng.randf_range(-0.6, 0.6)).normalized()
		var b := a + d * seg_len * p.rng.randf_range(0.6, 1.3)
		var ww := maxf(0.5, wd * (1.0 - k * 0.12))
		Ink.line(p, a, b, ww * 2.6, lit, 0.22, 0.5)
		Ink.line(p, a, b, ww * 1.1, lit, 0.7, 0.5)
		Ink.line(p, a + Vector2(0.5, 0.6), b + Vector2(0.5, 0.6), ww * 0.5, core, 0.55, 0.5)
		if p.rng.randf() < 0.45:
			var e := a.lerp(b, p.rng.randf_range(0.3, 0.7))
			var f := e + d.rotated(p.rng.randf_range(0.7, 1.3) * (1.0 if p.rng.randf() < 0.5 else -1.0)) * seg_len * 0.55
			Ink.line(p, e, f, ww * 0.8, lit, 0.55, 0.4)
		a = b


## 얼음에 갇힌 거품: 흐린 고리 + 왼쪽 위 반짝임.
static func bubble(p: Paint, q: Vector2, r: float, rim: Color, a: float = 0.6) -> void:
	var ring := Cave._ellipse(q, r, r * 0.85, 14)
	p.fill_poly(ring, func(_x: int, _y: int) -> Color: return Color(rim.r, rim.g, rim.b, 0.18 * a), 1.0, true)
	Ink.path(p, ring, maxf(0.5, r * 0.28), true, rim, 0.55 * a, 0.2)
	Cave._dot(p, q + Vector2(-r * 0.35, -r * 0.35), maxf(0.6, r * 0.32), SPARK, 0.85 * a)


## 서리 무늬: 한 점에서 뻗은 깃털 같은 흰 잔선.
static func frost(p: Paint, q: Vector2, r: float, c: Color, a: float = 0.4) -> void:
	for k in p.rng.randi_range(5, 8):
		var d := Vector2.from_angle(p.rng.randf() * TAU)
		var ln := r * p.rng.randf_range(0.5, 1.0)
		var e := q + d * ln
		Ink.line(p, q, e, maxf(0.5, r * 0.06), c, a, 0.4, true)
		for j in 3:
			var m := q.lerp(e, 0.3 + j * 0.22)
			for sgn: float in [-1.0, 1.0]:
				Ink.line(p, m, m + d.rotated(0.8 * sgn) * ln * 0.22, maxf(0.4, r * 0.04), c, a * 0.8, 0.2, true)


## 눈 둔덕(바닥 위 부드러운 혹): 왼쪽 위 빛, 오른쪽 아래 푸른 그늘 — 이미 칠한 곳에 덧칠.
static func bump(p: Paint, q: Vector2, rx: float, ry: float, amt: float, lit: Color, shade: Color) -> void:
	for y in range(int(q.y - ry * 1.3), int(q.y + ry * 1.3) + 1):
		for x in range(int(q.x - rx * 1.3), int(q.x + rx * 1.3) + 1):
			var d := Vector2((x - q.x) / rx, (y - q.y) / ry)
			var g := exp(-d.length_squared() * 1.6)
			if g < 0.03:
				continue
			var s := -(d.x * 0.6 + d.y * 0.8) * g * 2.0  # 기울기 · 빛 방향
			if s > 0.0:
				p.tint(x, y, lit, clampf(s * amt, 0.0, 0.8))
			else:
				p.tint(x, y, shade, clampf(-s * amt, 0.0, 0.8))


## 눈 덮개(소품 윗면에 얹힌 눈): poly 안을 흰 눈으로 — 위가 밝고 아래 가장자리 푸른 그늘, 잉크 윤곽 일부.
static func snow_poly(p: Paint, poly: PackedVector2Array, ink: float = 1.0) -> void:
	var r := Paint.bounds(poly)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var t := clampf((y - r.position.y) / maxf(1.0, r.size.y), 0.0, 1.0)
		var sx := clampf((x - r.position.x) / maxf(1.0, r.size.x), 0.0, 1.0)
		return p.vary(SNOW.lerp(SNOW_SHADE, clampf(t * t * 0.9 + sx * 0.3, 0.0, 1.0)), x, y, 0.05))
	if ink > 0.0:
		var n := poly.size()
		for i in n:
			var m := (poly[i] + poly[(i + 1) % n]) * 0.5 - r.get_center()
			if m.y > -r.size.y * 0.1 or m.x > r.size.x * 0.3:  # 아래·오른쪽 윤곽만
				Ink.line(p, poly[i], poly[(i + 1) % n], 1.0 * ink * p.w / 128.0, Color("#2a3448"), 0.6, 0.4)


## 들쭉날쭉한 눈 덮개 다각형: 왼쪽 a에서 오른쪽 b까지 위로 부푼 윗선 + 아래로 흘러내린 밑선.
static func cap_poly(p: Paint, a: Vector2, b: Vector2, puff: float, drip: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := 10
	for i in n + 1:
		var t := float(i) / n
		out.append(a.lerp(b, t) + Vector2(0, -sin(t * PI) * puff * p.rng.randf_range(0.7, 1.15)))
	for i in n + 1:
		var t := 1.0 - float(i) / n
		var dd := drip * (0.4 + p.rng.randf() * 0.9) if i % 2 == 0 else drip * 0.25
		out.append(a.lerp(b, t) + Vector2(0, dd * sin(t * PI) + drip * 0.2))
	return out
