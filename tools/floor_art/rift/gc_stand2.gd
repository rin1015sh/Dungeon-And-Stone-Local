extends RefCounted
## 빙하굴 서 있는 소품(gc_stand.gd가 부른다) — 언 침엽수 · 눈 모자 바위 · 토템 · 버려진 천막 · 썰매 · 상자 · 눈 더미 · 꺼진 모닥불.
## 따뜻한 색은 토템(빛나는 눈구멍·숯 그릇)에만. 빛은 왼쪽 위, 잉크 윤곽, 눈은 푸른 그늘.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const Mat := preload("res://tools/floor_art/rift/gc_mat.gd")

const WOOD := Color("#6e4f36")
const OLD_WOOD := Color("#5e5044")
const CANVAS := Color("#8a7a62")
const FUR := Color("#4a3626")
const BONE := Color("#cfc6b0")
const STONE := Color("#6e747e")
const NEEDLE := Color("#2a4a40")
const EMBER := Color("#ff9a48")


static func paint(p: Paint, tile: String, foot: Vector2, u: float) -> void:
	match tile:
		"gc_pine":
			_pine(p, foot, u)
		"gc_rock":
			_rock(p, foot, u)
		"gc_totem":
			_totem(p, foot, u)
		"gc_tent":
			_tent(p, foot, u)
		"gc_sled":
			_sled(p, foot, u)
		"gc_crate":
			_crate(p, foot, u)
		"gc_drift":
			_drift(p, foot, u)
		"gc_campfire":
			_campfire(p, foot, u)
		_:
			Kit.shadow(p, foot, 24 * u, 8 * u)
			Kit.box(p, foot, 40 * u, 30 * u, 30 * u, STONE)


## 언 침엽수: 줄기 + 아래로 처진 가지 다섯 층(왼쪽 빛), 층마다 윗면에 눈.
static func _pine(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 34 * u, 10 * u)
	Kit.post(p, foot + Vector2(0, 2) * u, foot + Vector2(0, -34) * u, 8 * u, Color("#3a2a20"))
	var tiers := 5
	for k in tiers:
		var by := foot.y - (20.0 + k * 27.0) * u
		var hw := (36.0 - k * 6.4) * u
		var th := (46.0 - k * 2.5) * u
		var cx := foot.x + sin(k * 1.7) * 1.5 * u
		var apex := Vector2(cx, by - th)
		var poly := PackedVector2Array([apex])
		for j in range(1, 6):  # 왼쪽 비탈(삐죽한 가지 끝)
			var t := float(j) / 5.0
			poly.append(apex.lerp(Vector2(cx - hw, by), t) + Vector2(-3.5 * u if j % 2 == 1 else 1.5 * u, 2.0 * u if j % 2 == 1 else 0.0))
		for j in range(1, 8):  # 처진 아랫단
			var t := float(j) / 8.0
			poly.append(Vector2(cx - hw + 2.0 * hw * t, by + (6.0 if j % 2 == 1 else 1.0) * u + p.rng.randf_range(-1, 1) * u))
		for j in range(5, 0, -1):  # 오른쪽 비탈
			var t := float(j) / 5.0
			poly.append(apex.lerp(Vector2(cx + hw, by), t) + Vector2(3.5 * u if j % 2 == 1 else -1.5 * u, 2.0 * u if j % 2 == 1 else 0.0))
		p.fill_poly(poly, func(x: int, y: int) -> Color:
			var tx := clampf((x - (cx - hw)) / (2.0 * hw), 0.0, 1.0)
			var ty := clampf((y - apex.y) / (by - apex.y), 0.0, 1.0)
			return p.vary(NEEDLE.lightened(0.18).lerp(NEEDLE.darkened(0.55), clampf(tx * 0.7 + ty * 0.45, 0.0, 1.0)), x, y, 0.12))
		Ink.strokes(p, poly, 1.4, 6.0 * u, 1.6 * u, 25.0, 0.18, 0.4)
		Ink.path(p, poly, 1.5 * u, true, Color("#0e1612"), 0.85, 0.4)
		var cap := PackedVector2Array([apex + Vector2(0, -2) * u])  # 눈(왼쪽 비탈에 많이)
		for j in range(1, 4):
			cap.append(apex.lerp(Vector2(cx - hw, by), j * 0.2) + Vector2(-2.5, 1.0) * u)
		for j in 5:
			var t := float(j) / 4.0
			var a := apex.lerp(Vector2(cx - hw, by), 0.6)
			var b := apex.lerp(Vector2(cx + hw, by), 0.42)
			cap.append(a.lerp(b, t) + Vector2(0, (3.0 if j % 2 == 0 else -1.0) * u - sin(t * PI) * 4.0 * u))
		cap.append(apex.lerp(Vector2(cx + hw, by), 0.2) + Vector2(1.5, 0.5) * u)
		Mat.snow_poly(p, cap, 1.0)


## 눈 모자를 쓴 바위: 큰 돌 + 작은 돌, 윗면에 두툼한 눈, 그늘 쪽 빗금.
static func _rock(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 34 * u, 10 * u)
	var c := foot + Vector2(3, -16) * u
	Kit.blob(p, foot + Vector2(-22, -6) * u, 13 * u, 9 * u, STONE.darkened(0.15))
	Kit.blob(p, c, 30 * u, 21 * u, STONE)
	Ink.hatch(p, Cave._ellipse(c + Vector2(12, 8) * u, 14 * u, 10 * u, 14), 3.2 * u, 55.0, 0.3, 0.8 * u)
	Cave._crack(p, c + Vector2(2, -4) * u, 3, 6 * u, Vector2(0.4, 1.0))
	Mat.snow_poly(p, Mat.cap_poly(p, c + Vector2(-27, -6) * u, c + Vector2(24, -12) * u, 13 * u, 4 * u), 1.0)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-32, -10) * u, foot + Vector2(-13, -12) * u, 5 * u, 2 * u), 0.8)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-36, 4) * u, foot + Vector2(34, 4) * u, 4 * u, 1.5 * u), 0.8)


## 토템: 나무 기둥에 새긴 얼굴 셋(눈구멍에 숯불), 가로대에 매단 두개골·부적, 털가죽, 꼭대기 뿔, 발치 숯 그릇의 주황빛.
static func _totem(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 26 * u, 8 * u)
	Kit.glow(p, foot + Vector2(0, -70) * u, 70 * u, Color("#ff9a5a"), 0.2)
	Kit.post(p, foot + Vector2(0, 2) * u, foot + Vector2(0, -150) * u, 14 * u, WOOD.darkened(0.2))
	for k in 3:  # 새긴 얼굴
		var hc := foot + Vector2(0, -(34.0 + k * 34.0)) * u
		var face := PackedVector2Array([hc + Vector2(-13, -15) * u, hc + Vector2(13, -16) * u, hc + Vector2(15, 0) * u, hc + Vector2(12, 15) * u, hc + Vector2(-12, 16) * u, hc + Vector2(-15, 1) * u])
		p.fill_poly(face, func(x: int, y: int) -> Color:
			var t := clampf((x - hc.x) / (30.0 * u) + 0.5, 0.0, 1.0)
			return p.vary(WOOD.lightened(0.12).lerp(WOOD.darkened(0.45), t), x, y, 0.12))
		Ink.strokes(p, face, 1.0, 8.0 * u, 1.4 * u, 88.0, 0.15, 0.35)
		Ink.line(p, hc + Vector2(-12, -6) * u, hc + Vector2(12, -7) * u, 2.4 * u, Ink.INK, 0.85, 0.5)  # 눈썹뼈
		Ink.line(p, hc + Vector2(-11, -8.5) * u, hc + Vector2(10, -9.5) * u, 1.2 * u, WOOD.lightened(0.35), 0.6, 0.4)
		for sx: float in [-6.0, 6.0]:
			Cave._dot(p, hc + Vector2(sx, -2) * u, 3.0 * u, Color("#120a06"), 0.95)
			Cave._dot(p, hc + Vector2(sx, -2) * u, 1.5 * u, EMBER, 0.95)
			Ink.glow(p, hc.x + sx * u, hc.y - 2 * u, 7 * u, EMBER, 0.5, false)
		var mouth := PackedVector2Array([hc + Vector2(-8, 6) * u, hc + Vector2(8, 6) * u, hc + Vector2(6, 11) * u, hc + Vector2(-6, 11) * u])
		p.fill_poly(mouth, func(_x: int, _y: int) -> Color: return Color("#140c08"))
		for j in 4:
			Ink.line(p, hc + Vector2(-5 + j * 3.3, 6) * u, hc + Vector2(-5 + j * 3.3, 8.5) * u, 1.3 * u, BONE, 0.9, 0.1)
		Ink.path(p, face, 1.6 * u, true, Ink.INK, 0.85, 0.5)
	Kit.post(p, foot + Vector2(-30, -124) * u, foot + Vector2(30, -128) * u, 6 * u, WOOD)  # 가로대
	var pelt := PackedVector2Array([foot + Vector2(-18, -130) * u, foot + Vector2(18, -131) * u, foot + Vector2(20, -112) * u, foot + Vector2(14, -104) * u, foot + Vector2(8, -110) * u, foot + Vector2(2, -100) * u, foot + Vector2(-5, -108) * u, foot + Vector2(-12, -101) * u, foot + Vector2(-20, -112) * u])
	p.fill_poly(pelt, func(x: int, y: int) -> Color: return p.vary(FUR.lerp(FUR.darkened(0.5), clampf((x - foot.x) / (40.0 * u) + 0.5, 0.0, 1.0)), x, y, 0.15))
	Ink.strokes(p, pelt, 2.0, 7.0 * u, 1.2 * u, 95.0, 0.25, 0.5)
	Ink.path(p, pelt, 1.4 * u, true, Ink.INK, 0.8, 0.6)
	for side: float in [-1.0, 1.0]:  # 매단 두개골 · 부적 끈
		var top := foot + Vector2(side * 26, -125) * u
		var sk := top + Vector2(0, 18) * u
		Ink.line(p, top, sk + Vector2(0, -5) * u, 1.0 * u, Color("#2a2018"), 0.9, 0.3)
		Cave._stone(p, sk, 5.5 * u, 5.0 * u, BONE)
		Cave._stone(p, sk + Vector2(0, 5) * u, 3.4 * u, 2.2 * u, BONE.darkened(0.1))
		for sx: float in [-2.0, 2.0]:
			Cave._dot(p, sk + Vector2(sx, 0) * u, 1.4 * u, Color("#120e0c"), 0.95)
		var f := top + Vector2(-side * 9, 0) * u
		Ink.line(p, f, f + Vector2(0, 14) * u, 0.9 * u, Color("#2a2018"), 0.85, 0.3)
		Decals._stick(p, f + Vector2(0, 14) * u, f + Vector2(side * 2, 22) * u, 1.6 * u, BONE)
	for side: float in [-1.0, 1.0]:  # 뿔
		var pts := PackedVector2Array()
		for j in 7:
			var t := float(j) / 6.0
			pts.append(foot + Vector2(side * (4 + t * 20), -146 - t * 18 + t * t * 10) * u)
		Ink.path(p, pts, 4.6 * u, false, Ink.INK, 0.9, 0.2)
		Ink.path(p, pts, 3.2 * u, false, BONE, 1.0, 0.2)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-29, -131) * u, foot + Vector2(-8, -133) * u, 3 * u, 1.5 * u), 0.8)
	var bowl := foot + Vector2(0, 2) * u  # 숯 그릇
	Ink.glow(p, bowl.x, bowl.y - 6 * u, 26 * u, EMBER, 0.45, false)
	Cave._stone(p, bowl, 15 * u, 6 * u, Color("#3a3430"))
	for j in 9:
		Cave._dot(p, bowl + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-4, 1)) * u, p.rng.randf_range(1.4, 2.6) * u, EMBER.lerp(Color("#ffd890"), p.rng.randf()), 0.95)


## 버려진 천막: 찢긴 캔버스 박공 천막 — 앞 박공의 어두운 입구와 펄럭이는 자락, 지붕 찢긴 틈, 기둥 끝, 줄, 왼쪽을 묻은 눈.
static func _tent(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(6, -4) * u, 40 * u, 12 * u)
	var back := Vector2(10, -26) * u
	var a := foot + Vector2(-30, 0) * u
	var b := foot + Vector2(30, 0) * u
	var f := foot + Vector2(0, -58) * u
	var left := PackedVector2Array([a, f, f + back, a + back])
	var right := PackedVector2Array([f, f + back, b + back, b])
	var gable := PackedVector2Array([a, f, b])
	p.fill_poly(left, func(x: int, y: int) -> Color: return p.vary(CANVAS.lightened(0.12), x, y, 0.12))
	p.fill_poly(right, func(x: int, y: int) -> Color: return p.vary(CANVAS.darkened(0.42), x, y, 0.12))
	Ink.hatch(p, right, 3.6 * u, 120.0, 0.25, 0.8 * u)
	p.fill_poly(gable, func(x: int, y: int) -> Color: return p.vary(CANVAS.darkened(0.12).lerp(CANVAS.darkened(0.35), clampf((y - f.y) / (58.0 * u), 0.0, 1.0) * 0.6), x, y, 0.12))
	Ink.strokes(p, gable, 1.0, 10 * u, 2.0 * u, 80.0, 0.12, 0.35)
	var tear := PackedVector2Array([f + back * 0.4 + Vector2(6, 8) * u, f + back * 0.6 + Vector2(10, 10) * u, f + back * 0.5 + Vector2(16, 22) * u, f + back * 0.3 + Vector2(10, 18) * u, f + back * 0.35 + Vector2(12, 13) * u])
	p.fill_poly(tear, func(_x: int, _y: int) -> Color: return Color("#120e0c"))
	Ink.path(p, tear, 1.0 * u, true, Ink.INK, 0.8, 0.5)
	var door := PackedVector2Array([foot + Vector2(-13, 0) * u, foot + Vector2(-1, -44) * u, foot + Vector2(11, 0) * u])
	p.fill_poly(door, func(x: int, y: int) -> Color: return p.vary(Color("#0e0b0a"), x, y, 0.1))
	var flap := PackedVector2Array([foot + Vector2(1, -40) * u, foot + Vector2(17, -20) * u, foot + Vector2(24, -6) * u, foot + Vector2(18, -3) * u, foot + Vector2(14, -8) * u, foot + Vector2(8, 0) * u])
	p.fill_poly(flap, func(x: int, y: int) -> Color: return p.vary(CANVAS.lightened(0.05), x, y, 0.12))
	Ink.path(p, flap, 1.3 * u, true, Ink.INK, 0.85, 0.6)
	Ink.line(p, foot + Vector2(-12, -2) * u, foot + Vector2(-20, 6) * u, 1.0 * u, CANVAS.darkened(0.2), 0.9, 0.6)  # 늘어진 끈
	for d: Vector2 in [Vector2(-7, -9), Vector2(7, -9)]:  # 기둥 끝
		Ink.line(p, f + d * u, f + Vector2(0, 2) * u, 2.4 * u, Color("#3a2a20"), 0.95, 0.3)
	Ink.line(p, f, foot + Vector2(-44, 4) * u, 0.8 * u, Color("#3a3028"), 0.75, 0.3)  # 버팀줄
	Ink.line(p, f + back, foot + Vector2(46, -16) * u, 0.8 * u, Color("#3a3028"), 0.75, 0.3)
	Ink.path(p, PackedVector2Array([a, f, f + back, b + back, b, a]), 1.8 * u, true, Ink.INK, 0.9, 0.5)
	Ink.line(p, f, b, 1.4 * u, Ink.INK, 0.8, 0.4)
	Ink.line(p, a + Vector2(2, -3) * u, f + Vector2(-1, 3) * u, 1.2 * u, Color("#e8dcc4"), 0.35, 0.4)
	Mat.snow_poly(p, PackedVector2Array([f + Vector2(-2, -1) * u, f + back + Vector2(0, -2) * u, f + back * 0.6 + Vector2(-12, 14) * u, f + Vector2(-14, 18) * u, f + Vector2(-6, 9) * u]), 0.8)
	Mat.snow_poly(p, Mat.cap_poly(p, a + Vector2(-10, 5) * u, a + Vector2(26, 5) * u, 16 * u, 2 * u), 1.0)


## 썰매: 앞이 말려 올라간 나무 썰매날 둘 + 버팀 + 바닥판, 위에 자루·말아 묶은 털가죽·작은 상자, 묶은 줄, 눈.
static func _sled(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(4, -4) * u, 42 * u, 11 * u)
	var depth := Vector2(8, -12) * u
	for k in 2:
		var o := foot + (depth if k == 0 else Vector2.ZERO)
		var pts := PackedVector2Array([o + Vector2(36, 0) * u, o + Vector2(-34, 0) * u, o + Vector2(-41, -3) * u, o + Vector2(-43, -9) * u, o + Vector2(-39, -13) * u])
		Ink.path(p, pts, 4.4 * u, false, Ink.INK, 0.9, 0.3)
		Ink.path(p, pts, 2.8 * u, false, OLD_WOOD.lightened(0.05 if k == 1 else -0.2), 1.0, 0.3)
		for sx: float in [-24.0, 0.0, 24.0]:
			Kit.post(p, o + Vector2(sx, -1) * u, o + Vector2(sx, -9) * u, 3 * u, OLD_WOOD.darkened(0.2))
	Kit.box(p, foot + Vector2(2, -8) * u, 70 * u, 20 * u, 4 * u, OLD_WOOD)
	Kit.blob(p, foot + Vector2(-16, -20) * u, 13 * u, 9 * u, Color("#6a5c48"))  # 자루
	Kit.box(p, foot + Vector2(17, -12) * u, 22 * u, 16 * u, 15 * u, WOOD)  # 작은 상자
	Kit.blob(p, foot + Vector2(2, -30) * u, 18 * u, 7 * u, FUR)  # 말아 묶은 털가죽
	Ink.strokes(p, Cave._ellipse(foot + Vector2(2, -30) * u, 16 * u, 6 * u, 14), 2.0, 5.0 * u, 1.2 * u, 20.0, 0.25, 0.5)
	for x: float in [-10.0, 10.0]:  # 묶은 줄
		Ink.line(p, foot + Vector2(x - 4, -6) * u, foot + Vector2(x + 2, -36) * u, 1.2 * u, Color("#b09a74"), 0.85, 0.4)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-26, -26) * u, foot + Vector2(-6, -27) * u, 4 * u, 1.5 * u), 0.8)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-12, -35) * u, foot + Vector2(16, -36) * u, 4 * u, 1.5 * u), 0.8)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(12, -36) * u, foot + Vector2(30, -40) * u, 3 * u, 1.5 * u), 0.8)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-46, 4) * u, foot + Vector2(-20, 4) * u, 6 * u, 1.5 * u), 0.8)


## 상자: 서리 낀 나무 궤짝 + 위에 작은 궤짝, 쇠 모서리, 판자 줄, 윗면 눈.
static func _crate(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 32 * u, 10 * u)
	var col := Color("#7a603e")
	var big: Dictionary = Kit.box(p, foot, 48 * u, 36 * u, 34 * u, col)
	Kit.planks(p, big["front"], 3, col)
	var small: Dictionary = Kit.box(p, foot + Vector2(-4, -34) * u, 28 * u, 22 * u, 20 * u, col.lightened(0.05))
	Kit.planks(p, small["front"], 2, col)
	for poly: PackedVector2Array in [big["front"], small["front"]]:  # 쇠 모서리
		var r := Paint.bounds(poly)
		for cx: float in [r.position.x + 2.5 * u, r.end.x - 2.5 * u]:
			Ink.line(p, Vector2(cx, r.position.y + 1), Vector2(cx, r.end.y - 1), 3.2 * u, Color("#3a3c40"), 0.9, 0.2)
			Cave._dot(p, Vector2(cx, r.position.y + 4 * u), 1.0 * u, Color("#9aa0a8"), 0.9)
	Ink.line(p, Paint.bounds(big["front"]).position + Vector2(6, 6) * u, Paint.bounds(big["front"]).end - Vector2(6, 6) * u, 2.0 * u, col.darkened(0.5), 0.6, 0.3)  # 엇댄 판자
	var t: PackedVector2Array = small["top"]
	Mat.snow_poly(p, PackedVector2Array([t[0] + Vector2(1, 1) * u, t[3] + Vector2(2, 0), t[2] + Vector2(-2, 0), t[1] + Vector2(-1, 2) * u, t[1] + Vector2(-8, 4) * u, t[0] + Vector2(8, 5) * u]), 0.8)
	var bt: PackedVector2Array = big["top"]
	Mat.snow_poly(p, PackedVector2Array([bt[1] + Vector2(-14, -1) * u, bt[2] + Vector2(-3, 1) * u, bt[1] + Vector2(0, 2) * u, bt[1] + Vector2(-10, 4) * u]), 0.8)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-30, 4) * u, foot + Vector2(-6, 4) * u, 7 * u, 1.5 * u), 0.8)


## 눈 더미: 바람에 깎인 둔덕 — 왼쪽 위 밝은 비탈, 오른쪽 처마(코니스) 밑 푸른 그늘, 바람 결.
static func _drift(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 36 * u, 9 * u, 0.25)
	var pts := PackedVector2Array([foot + Vector2(-36, 3) * u, foot + Vector2(-28, -8) * u, foot + Vector2(-16, -18) * u, foot + Vector2(-2, -26) * u,
		foot + Vector2(10, -31) * u, foot + Vector2(19, -30) * u, foot + Vector2(22, -25) * u, foot + Vector2(20, -20) * u, foot + Vector2(26, -12) * u, foot + Vector2(34, 3) * u])
	var r := Paint.bounds(pts)
	p.fill_poly(pts, func(x: int, y: int) -> Color:
		var tx := clampf((x - r.position.x) / r.size.x, 0.0, 1.0)
		var ty := clampf((y - r.position.y) / r.size.y, 0.0, 1.0)
		var t := clampf(tx * 0.75 + ty * 0.35 - 0.2, 0.0, 1.0)
		var c := Mat.SNOW.lerp(Mat.SNOW_SHADE, t * t * 1.3)
		if x > foot.x + 17 * u and y > foot.y - 24 * u:
			c = c.lerp(Color("#5a6a88"), 0.35)  # 처마 밑 그늘
		return p.vary(c, x, y, 0.04))
	for k in 4:  # 바람 결
		var y := foot.y - (4.0 + k * 5.0) * u
		Ink.line(p, Vector2(foot.x - 26 * u + k * 5 * u, y), Vector2(foot.x + 4 * u + k * 3 * u, y - 6 * u), 1.0 * u, Color("#8a9cb8"), 0.4, 1.2)
	Ink.line(p, foot + Vector2(10, -31) * u, foot + Vector2(22, -25) * u, 1.6 * u, Color("#2a3448"), 0.8, 0.4)
	Ink.line(p, foot + Vector2(20, -20) * u, foot + Vector2(34, 3) * u, 1.6 * u, Color("#2a3448"), 0.75, 0.4)
	Ink.line(p, foot + Vector2(-34, 2) * u, foot + Vector2(34, 3) * u, 1.2 * u, Color("#2a3448"), 0.45, 0.6)
	for k in 10:
		Cave._dot(p, foot + Vector2(p.rng.randf_range(-24, 8), p.rng.randf_range(-24, -2)) * u, 0.9 * u, Mat.SPARK, 0.8)


## 꺼진 모닥불: 돌 고리 안의 재와 서리 낀 숯 통나무(불꽃 없음), 눈가루.
static func _campfire(p: Paint, foot: Vector2, u: float) -> void:
	var c := foot + Vector2(0, -8) * u
	Decals._blob(p, c, 20 * u, Color("#2c2a2a"), 0.9, 0.2)
	Decals._blob(p, c + Vector2(2, 1) * u, 11 * u, Color("#4a4644"), 0.7, 0.3)
	for k in 9:  # 뒤쪽 돌
		var a := TAU * k / 9.0 + 0.2
		if sin(a) < 0.0:
			Cave._stone(p, c + Vector2(cos(a) * 24, sin(a) * 12) * u, 5.0 * u, 3.8 * u, STONE)
	for k in 3:  # 숯 통나무
		var d := Vector2.from_angle(-0.4 + k * 1.1) * 15 * u
		Decals._stick(p, c - d, c + d * 0.8, 4.4 * u, Color("#24201c"))
		Ink.line(p, c - d + Vector2(0, -2) * u, c + d * 0.8 + Vector2(0, -2) * u, 1.2 * u, Color("#c8d4e0"), 0.5, 0.3)
	for k in 9:  # 앞쪽 돌
		var a := TAU * k / 9.0 + 0.2
		if sin(a) >= 0.0:
			Cave._stone(p, c + Vector2(cos(a) * 24, sin(a) * 12) * u, 5.5 * u, 4.0 * u, STONE)
			Cave._dot(p, c + Vector2(cos(a) * 24 - 1.5, sin(a) * 12 - 2.5) * u, 2.0 * u, Mat.SNOW, 0.9)
	for k in 14:
		Cave._dot(p, c + Vector2(p.rng.randf_range(-20, 20), p.rng.randf_range(-10, 10)) * u, 1.0 * u, Color("#dce4ec"), 0.7)
