extends RefCounted
## 빙하굴 서 있는 소품(gc.gd 전용) — 얼음 것들: 고드름 기둥 · 길잡이 얼음 기둥 · 얼음 결정 · 얼음 속 오크 · 작은 연못 · 금 간 얼음 기둥.
## 나머지(언 침엽수·바위·토템·천막·썰매·상자·눈 더미·꺼진 모닥불)는 gc_stand2.gd. 칸 = 128 × 192, 발 = (w / 2, h - w × 0.14).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const Mat := preload("res://tools/floor_art/rift/gc_mat.gd")
const Stand2 := preload("res://tools/floor_art/rift/gc_stand2.gd")

const ICE_HI := Color("#e6f6fc")
const ICE_A := Color("#9cd0e4")
const ICE_B := Color("#3f7894")
const ICE_C := Color("#1c3a52")
const RUNE := Color("#a8f0ff")


static func paint(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var foot := Vector2(w * 0.5, h - w * 0.14)
	var u := w / 128.0
	match tile:
		"gc_icicle":
			_icicle(p, foot, u)
		"gc_guide":
			_guide(p, foot, u, false)
		"ice_pillar_cracked":
			_guide(p, foot, u, true)
		"gc_crystal":
			_crystal(p, foot, u)
		"gc_frozen_orc":
			_frozen_orc(p, foot, u)
		"ice_pond":
			_pond(p, foot, u)
		_:
			Stand2.paint(p, tile, foot, u)
	Ink.finish(p, 0.035)  # 그레인
	return p


# ── 얼음 부품 ───────────────────────────────────────────

## 반투명 얼음 덩어리 칠: 왼쪽(빛) 밝은 청백 → 가운데 청록 → 오른쪽 짙은 남청, 가운데 세로 속빛, 붓결.
static func ice_fill(p: Paint, poly: PackedVector2Array, alpha: float = 1.0, core: float = 0.25) -> void:
	var r := Paint.bounds(poly)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var tx := clampf((x - r.position.x) / maxf(1.0, r.size.x), 0.0, 1.0)
		var ty := clampf((y - r.position.y) / maxf(1.0, r.size.y), 0.0, 1.0)
		var t := tx * 0.85 + ty * 0.3 - 0.05
		var c := ICE_A.lerp(ICE_HI, clampf(0.35 - t, 0.0, 1.0) * 2.5) if t < 0.35 else ICE_A.lerp(ICE_B, (t - 0.35) * 1.8) if t < 0.9 else ICE_B.lerp(ICE_C, (t - 0.9) * 3.0)
		c = c.lerp(Color("#c8f4ff"), exp(-pow((tx - 0.42) / 0.16, 2.0)) * core * (1.0 - ty * 0.5))
		c = p.vary(c, x, y, 0.1)
		c.a = alpha
		return c)


## 얼음 속 세로 결(밝은 줄 · 어두운 줄) — 칠한 곳에만.
static func ice_streaks(p: Paint, poly: PackedVector2Array, n: int, u: float) -> void:
	var r := Paint.bounds(poly)
	for k in n:
		var x := r.position.x + r.size.x * p.rng.randf_range(0.12, 0.85)
		var y0 := r.position.y + r.size.y * p.rng.randf_range(0.05, 0.4)
		var y1 := y0 + r.size.y * p.rng.randf_range(0.25, 0.55)
		var lit := k % 2 == 0
		Ink.line(p, Vector2(x, y0), Vector2(x + p.rng.randf_range(-2, 2) * u, y1), (1.6 if lit else 1.0) * u, ICE_HI if lit else ICE_C, 0.35 if lit else 0.3, 1.0, true)


## 가늘어지며 솟는 얼음 기둥 다각형(녹아 흘러내린 듯 울퉁불퉁한 옆선).
static func spire(p: Paint, base: Vector2, r0: float, hgt: float, lean: float, wob: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := 16
	var ph := p.rng.randf() * TAU
	for k in n + 1:
		var t := float(k) / n
		var hw := r0 * pow(1.0 - t, 0.8) * (1.0 + wob * sin(t * 13.0 + ph) * (1.0 - t))
		var cx := base.x + lean * hgt * t * t
		left.append(Vector2(cx - hw, base.y - hgt * t))
		right.append(Vector2(cx + hw * 0.92, base.y - hgt * t))
	right.reverse()
	left.append_array(right)
	for k in 5:  # 바닥 쪽 둥근 밑선
		var t := float(k + 1) / 6.0
		left.append(Vector2(base.x + r0 * 0.92 - t * r0 * 1.92, base.y + sin(t * PI) * r0 * 0.25))
	return left


## 눈 더미 밑동(물건 발치에 쌓인 눈).
static func snow_foot(p: Paint, foot: Vector2, half: float, puff: float) -> void:
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-half, 3), foot + Vector2(half, 3), puff, 2.0), 1.2)


# ── 소품 ───────────────────────────────────────────────

## 고드름 기둥: 바닥에서 솟은 큰 얼음 기둥 + 뒤에 작은 기둥 둘, 반투명한 몸, 속빛, 발치 눈, 푸른 빛 번짐.
static func _icicle(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 30 * u, 9 * u)
	var parts := [[Vector2(-6, -10), 8.0, 60.0, -0.05], [Vector2(-19, -3), 11.0, 82.0, -0.14], [Vector2(18, -5), 11.0, 104.0, 0.1],
		[Vector2(1, 0), 20.0, 156.0, 0.03], [Vector2(-24, 3), 7.0, 40.0, -0.2], [Vector2(26, 2), 7.0, 46.0, 0.22]]
	for sp: Array in parts:
		var base := foot + (sp[0] as Vector2) * u
		var poly := spire(p, base, float(sp[1]) * u, float(sp[2]) * u, float(sp[3]), 0.18)
		ice_fill(p, poly, 1.0, 0.35)
		ice_streaks(p, poly, 4, u)
		var right := PackedVector2Array()
		for q in poly:
			right.append(Vector2(maxf(q.x, base.x + float(sp[3]) * (base.y - q.y) * (base.y - q.y) / maxf(1.0, float(sp[2]) * u)), q.y))
		Ink.hatch(p, right, 3.0 * u, 70.0, 0.22, 0.8 * u, Color("#14283a"))
		var tip := base + Vector2(float(sp[3]) * float(sp[2]) * u, -float(sp[2]) * u)
		Ink.line(p, base + Vector2(-float(sp[1]) * 0.55 * u, -6 * u), tip.lerp(base, 0.12), 1.4 * u, Mat.SPARK, 0.6, 1.0)
		Ink.path(p, poly, 1.7 * u, true, Color("#14202c"), 0.85, 0.4)
	Kit.glow(p, foot + Vector2(0, -60) * u, 46 * u, Color("#9fe0ff"), 0.22)
	snow_foot(p, foot, 30 * u, 9 * u)


## 길잡이 얼음 기둥(cracked면 금 간 기둥 — 속에 박힌 청백 조각): 깎아 세운 맑은 얼음 오벨리스크, 새긴 띠·룬이 푸르게 빛난다.
static func _guide(p: Paint, foot: Vector2, u: float, cracked: bool) -> void:
	Kit.shadow(p, foot, 26 * u, 8 * u)
	var hb := 15.0 * u
	var ht := 11.0 * u
	var top := 140.0 * u
	var dx := 8.0 * u
	var dy := 6.0 * u
	var fl := foot + Vector2(-hb, 0)
	var fr := foot + Vector2(hb, 0)
	var tl := foot + Vector2(-ht, -top)
	var tr := foot + Vector2(ht, -top)
	var apex := foot + Vector2(2 * u, -top - 30 * u)
	var side := PackedVector2Array([fr, fr + Vector2(dx, -dy), tr + Vector2(dx * 0.75, -dy * 0.75), tr])
	var front := PackedVector2Array([fl, tl, tr, fr])
	var cap_f := PackedVector2Array([tl, apex, tr])
	var cap_s := PackedVector2Array([tr, apex, tr + Vector2(dx * 0.75, -dy * 0.75)])
	p.fill_poly(side, func(x: int, y: int) -> Color: return p.vary(ICE_B.lerp(ICE_C, 0.55), x, y, 0.1))
	Ink.hatch(p, side, 3.0 * u, 75.0, 0.3, 0.8 * u, Color("#0e1a26"))
	ice_fill(p, front, 1.0, 0.5)
	ice_fill(p, cap_f, 1.0, 0.3)
	p.fill_poly(cap_s, func(x: int, y: int) -> Color: return p.vary(ICE_C, x, y, 0.1))
	ice_streaks(p, front, 6, u)
	Ink.glow(p, foot.x, foot.y - 80 * u, 44 * u, Color("#7fe0ff"), 0.4)  # 속에서 비치는 빛
	for hy: float in [34.0, 78.0, 118.0]:  # 새긴 띠
		var y := foot.y - hy * u
		var k := hy * u / top
		var hw := hb + (ht - hb) * k
		Ink.line(p, Vector2(foot.x - hw, y), Vector2(foot.x + hw, y), 2.0 * u, Color("#163046"), 0.85, 0.3)
		Ink.line(p, Vector2(foot.x + hw, y), Vector2(foot.x + hw + dx, y - dy), 2.0 * u, Color("#0e1e2c"), 0.85, 0.3)
		Ink.line(p, Vector2(foot.x - hw + 1, y + 2.0 * u), Vector2(foot.x + hw - 1, y + 2.0 * u), 1.2 * u, ICE_HI, 0.6, 0.3)
	for band: Array in [[44.0, 72.0], [86.0, 112.0]]:  # 룬
		var y0 := foot.y - float(band[1]) * u
		var y1 := foot.y - float(band[0]) * u
		var cx := foot.x - 1 * u
		Ink.glow(p, cx, (y0 + y1) * 0.5, 16 * u, Color("#8ff0ff"), 0.6)
		Ink.line(p, Vector2(cx, y0 + 3 * u), Vector2(cx, y1 - 3 * u), 1.6 * u, RUNE, 0.95, 0.3)
		Ink.line(p, Vector2(cx - 5 * u, y0 + 7 * u), Vector2(cx, y0 + 12 * u), 1.4 * u, RUNE, 0.9, 0.3)
		Ink.line(p, Vector2(cx + 5 * u, y0 + 11 * u), Vector2(cx, y0 + 17 * u), 1.4 * u, RUNE, 0.9, 0.3)
		Ink.line(p, Vector2(cx - 4 * u, y1 - 6 * u), Vector2(cx + 4 * u, y1 - 9 * u), 1.4 * u, RUNE, 0.9, 0.3)
	Ink.line(p, fl + Vector2(2 * u, -4 * u), tl + Vector2(2 * u, 4 * u), 1.8 * u, Mat.SPARK, 0.7, 0.4)  # 빛 받은 모서리
	Ink.line(p, tl, apex, 1.4 * u, Mat.SPARK, 0.6, 0.3)
	if cracked:
		var shard := PackedVector2Array([foot + Vector2(1, -108) * u, foot + Vector2(9, -90) * u, foot + Vector2(2, -62) * u, foot + Vector2(-7, -86) * u])
		Ink.glow(p, foot.x, foot.y - 86 * u, 30 * u, Color("#dff4ff"), 0.85)
		p.fill_poly(shard, func(x: int, y: int) -> Color: return Color("#f4fbff").lerp(Color("#9fd8ff"), clampf((x - foot.x) / (8.0 * u) * 0.5 + 0.5, 0.0, 1.0)))
		Ink.path(p, shard, 1.4 * u, true, Color("#1a3a56"), 0.9, 0.2)
		Ink.line(p, shard[0], shard[2], 1.0 * u, Color("#7fb8dc"), 0.7, 0.2)
		var pts := PackedVector2Array([foot + Vector2(-11, -132) * u, foot + Vector2(-4, -116) * u, foot + Vector2(-7, -104) * u, foot + Vector2(3, -90) * u, foot + Vector2(-1, -72) * u, foot + Vector2(8, -56) * u, foot + Vector2(5, -40) * u, foot + Vector2(13, -24) * u])
		for k in pts.size() - 1:
			Ink.line(p, pts[k], pts[k + 1], 3.6 * u, ICE_HI, 0.55, 0.4)
			Ink.line(p, pts[k], pts[k + 1], 1.6 * u, Color("#0c1822"), 0.95, 0.4)
		Ink.line(p, pts[2], pts[2] + Vector2(-8, 6) * u, 1.2 * u, Color("#0c1822"), 0.85, 0.4)
		Ink.line(p, pts[5], pts[5] + Vector2(-9, 3) * u, 1.2 * u, Color("#0c1822"), 0.85, 0.4)
		for k in 4:  # 떨어진 얼음 부스러기
			Cave._stone(p, foot + Vector2(p.rng.randf_range(16, 28), p.rng.randf_range(-2, 6)) * u, 3.0 * u, 2.2 * u, ICE_A)
	Ink.path(p, PackedVector2Array([fl, tl, apex, tr + Vector2(dx * 0.75, -dy * 0.75), fr + Vector2(dx, -dy), fr]), 1.9 * u, true, Color("#101a24"), 0.9, 0.4)
	Ink.line(p, tr, fr, 1.2 * u, Color("#101a24"), 0.7, 0.3)
	Kit.glow(p, foot + Vector2(0, -80) * u, 64 * u, Color("#9fd8ff"), 0.18)
	snow_foot(p, foot, 26 * u, 7 * u)


## 얼음 결정 무리: 한 점에서 비스듬히 솟은 육각 기둥 결정들 — 빛 쪽 면 청백, 반대 면 청록, 잉크, 강한 하늘빛 번짐.
static func _crystal(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 28 * u, 8 * u)
	Kit.glow(p, foot + Vector2(0, -30) * u, 50 * u, Color("#8fe8ff"), 0.3)
	var shards := [[-0.55, 46.0, 7.0, -8.0], [0.5, 40.0, 6.0, 9.0], [-0.25, 64.0, 8.5, -3.0], [0.2, 78.0, 9.5, 3.0], [-0.85, 28.0, 5.0, -16.0], [0.85, 26.0, 5.0, 16.0], [0.05, 34.0, 6.0, 0.0]]
	for sh: Array in shards:
		var ang := -PI * 0.5 + float(sh[0]) * 0.75
		var d := Vector2.from_angle(ang)
		var n := Vector2(-d.y, d.x)
		var root := foot + Vector2(float(sh[3]), 2.0) * u
		var ln := float(sh[1]) * u
		var wd := float(sh[2]) * u
		var tip := root + d * ln
		var sl := root + n * wd + d * ln * 0.8
		var sr := root - n * wd + d * ln * 0.8
		var mid := root + d * ln * 0.05 + n * wd * 0.15
		var midt := root + d * ln * 0.8 + n * wd * 0.15
		var lp := PackedVector2Array([root + n * wd, sl, tip, midt, mid])
		var rp := PackedVector2Array([mid, midt, tip, sr, root - n * wd])
		var lit_l := n.x < 0.0
		var ca := Color("#dff6ff") if lit_l else Color("#3f8aa8")
		var cb := Color("#4a98b8") if lit_l else Color("#cfeefa")
		p.fill_poly(lp, func(x: int, y: int) -> Color: return p.vary(ca.lerp(Color("#8ad8f0"), clampf((y - tip.y) / ln, 0.0, 1.0) * 0.5), x, y, 0.06))
		p.fill_poly(rp, func(x: int, y: int) -> Color: return p.vary(cb.lerp(Color("#2a5a78"), clampf((y - tip.y) / ln, 0.0, 1.0) * 0.4), x, y, 0.06))
		Ink.line(p, midt, tip, 1.0 * u, Mat.SPARK, 0.75, 0.2)
		Ink.line(p, mid, midt, 0.9 * u, Mat.SPARK, 0.35, 0.2)
		Ink.path(p, PackedVector2Array([root + n * wd, sl, tip, sr, root - n * wd]), 1.5 * u, false, Color("#0e2230"), 0.85, 0.3)
	Ink.glow(p, foot.x, foot.y - 40 * u, 36 * u, Color("#a8f0ff"), 0.35)
	snow_foot(p, foot, 24 * u, 6 * u)


## 얼음 속 오크: 반투명 얼음 기둥 덩어리 안에 도끼를 치켜든 오크 전사의 검은 그림자.
static func _frozen_orc(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 34 * u, 9 * u)
	var hw := 25.0 * u
	var hgt := 126.0 * u
	var dx := 9.0 * u
	var dy := 7.0 * u
	var front := PackedVector2Array([foot + Vector2(-hw, 0), foot + Vector2(-hw - 2 * u, -hgt * 0.55), foot + Vector2(-hw + 2 * u, -hgt * 0.9),
		foot + Vector2(-10 * u, -hgt - 4 * u), foot + Vector2(6 * u, -hgt + 2 * u), foot + Vector2(hw - 2 * u, -hgt - 6 * u), foot + Vector2(hw, -hgt * 0.6), foot + Vector2(hw, 0)])
	var side := PackedVector2Array([foot + Vector2(hw, 0), foot + Vector2(hw, -hgt * 0.6), foot + Vector2(hw - 2 * u, -hgt - 6 * u), foot + Vector2(hw - 2 * u + dx, -hgt - 6 * u - dy), foot + Vector2(hw + dx, -hgt * 0.6 - dy), foot + Vector2(hw + dx, -dy)])
	p.fill_poly(side, func(x: int, y: int) -> Color: return p.vary(ICE_B.lerp(ICE_C, 0.5), x, y, 0.1))
	ice_fill(p, front, 1.0, 0.15)
	# 갇힌 오크(얼음 속이라 흐리고 푸르게)
	var body := Color("#1a2420")
	var o := foot + Vector2(-2, 0) * u
	var silh := Paint.new(p.w, p.h, 3)
	Ink.line(silh, o + Vector2(-7, -12) * u, o + Vector2(-9, -44) * u, 9 * u, body, 1.0, 0.4)  # 다리
	Ink.line(silh, o + Vector2(8, -12) * u, o + Vector2(7, -44) * u, 9 * u, body, 1.0, 0.4)
	silh.fill_poly(Cave._ellipse(o + Vector2(0, -64) * u, 17 * u, 24 * u, 18), func(_x: int, _y: int) -> Color: return body)  # 몸통
	silh.fill_poly(PackedVector2Array([o + Vector2(-14, -46) * u, o + Vector2(14, -46) * u, o + Vector2(12, -36) * u, o + Vector2(-12, -36) * u]), func(_x: int, _y: int) -> Color: return body)  # 허리
	silh.fill_poly(PackedVector2Array([o + Vector2(-20, -80) * u, o + Vector2(19, -82) * u, o + Vector2(14, -70) * u, o + Vector2(-16, -68) * u]), func(_x: int, _y: int) -> Color: return body)  # 어깨
	silh.fill_poly(Cave._ellipse(o + Vector2(1, -91) * u, 9 * u, 8 * u, 14), func(_x: int, _y: int) -> Color: return body)  # 머리(어깨에 파묻힌)
	Ink.line(silh, o + Vector2(-17, -78) * u, o + Vector2(-19, -106) * u, 7 * u, body, 1.0, 0.4)  # 치켜든 팔
	Ink.line(silh, o + Vector2(-21, -98) * u, o + Vector2(-4, -116) * u, 3.5 * u, body, 1.0, 0.3)  # 도끼 자루
	silh.fill_poly(PackedVector2Array([o + Vector2(-8, -122) * u, o + Vector2(2, -120) * u, o + Vector2(4, -108) * u, o + Vector2(-6, -110) * u]), func(_x: int, _y: int) -> Color: return body)  # 도끼날
	Ink.line(silh, o + Vector2(16, -78) * u, o + Vector2(20, -52) * u, 7 * u, body, 1.0, 0.4)  # 내린 팔
	for i in p.w * p.h:
		var a := silh.buf[i * 4 + 3]
		if a > 0.0 and p.buf[i * 4 + 3] > 0.0:
			var x := i % p.w
			var y := i / p.w
			p.tint(x, y, Color("#14262e"), a * 0.82)
	for sx: float in [-3.0, 4.5]:  # 얼음 너머 흐린 엄니
		Cave._dot(p, o + Vector2(sx, -88) * u, 1.2 * u, Color("#8aa8a8"), 0.7)
	# 얼음 겉: 비친 빛 줄, 금, 서리
	ice_streaks(p, front, 6, u)
	Ink.line(p, foot + Vector2(-hw + 4 * u, -8 * u), foot + Vector2(-hw + 5 * u, -hgt + 10 * u), 2.4 * u, Mat.SPARK, 0.5, 1.0)
	Mat.crack(p, foot + Vector2(10, -110) * u, 4, 12 * u, Vector2(-0.3, 1.0), ICE_HI, ICE_C, 1.1 * u)
	Ink.glow(p, foot.x, foot.y - 70 * u, 40 * u, Color("#8fe0ff"), 0.18)
	Ink.path(p, front, 1.9 * u, true, Color("#101a24"), 0.9, 0.5)
	Ink.path(p, side, 1.3 * u, true, Color("#101a24"), 0.7, 0.4)
	Mat.snow_poly(p, Mat.cap_poly(p, foot + Vector2(-12, -hgt / u - 2) * u, foot + Vector2(20, -hgt / u - 5) * u, 4 * u, 2 * u), 1.0)
	snow_foot(p, foot, 32 * u, 8 * u)


## 작은 연못: 눈 테두리 안의 언 수면 + 얼음 속에 잠긴 분홍빛 결정(빙정).
static func _pond(p: Paint, foot: Vector2, u: float) -> void:
	var c := foot + Vector2(0, -10) * u
	var rx := 27.0 * u
	var ry := 14.0 * u
	var rim := Cave._ellipse(c, rx + 6 * u, ry + 5 * u, 28, p.rng)
	Mat.snow_poly(p, rim, 0.0)
	var surf := Cave._ellipse(c, rx, ry, 28, p.rng)
	p.fill_poly(surf, func(x: int, y: int) -> Color:
		var d := Vector2((x - c.x) / rx, (y - c.y) / ry)
		var t := clampf(0.5 + d.y * 0.4 - d.x * 0.2, 0.0, 1.0)
		return p.vary(Color("#5d8fac").lerp(Color("#1c3550"), t), x, y, 0.06))
	p.fill_poly(Cave._ellipse(c + Vector2(0, -ry * 0.25), rx * 0.95, ry * 0.65, 24), func(x: int, y: int) -> Color:
		return Color(0.04, 0.06, 0.1, 0.3 * clampf((y - c.y + ry) / ry, 0.0, 1.0)), 1.0, true)  # 위 턱 그늘
	var g := c + Vector2(5, 2) * u  # 잠긴 빙정
	Ink.glow(p, g.x, g.y, 16 * u, Color("#ff7a8a"), 0.55)
	var gem := PackedVector2Array([g + Vector2(0, -6) * u, g + Vector2(4, 0) * u, g + Vector2(0, 5) * u, g + Vector2(-4, 0) * u])
	p.fill_poly(gem, func(x: int, _y: int) -> Color: return Color("#ffd0d8").lerp(Color("#c04a64"), clampf((x - g.x) / (4.0 * u) * 0.5 + 0.5, 0.0, 1.0)))
	Ink.path(p, gem, 0.9 * u, true, Color("#4a1424"), 0.7, 0.1)
	Cave._dot(p, g + Vector2(-1, -3) * u, 1.2 * u, Color("#fff4f6"), 0.95)
	Ink.line(p, c + Vector2(-18, -4) * u, c + Vector2(-4, -8) * u, 1.6 * u, Mat.SPARK, 0.55, 0.6)  # 얼음 광택
	Ink.line(p, c + Vector2(-12, 2) * u, c + Vector2(-6, 0) * u, 1.0 * u, Mat.SPARK, 0.4, 0.4)
	Mat.crack(p, c + Vector2(-20, 6) * u, 3, 7 * u, Vector2(1, -0.2), Color("#c8e8f4"), Color("#10202e"), 0.7 * u)
	Ink.path(p, surf, 1.5 * u, true, Color("#16222e"), 0.8, 0.4)
	for k in 7:  # 테두리 눈 덩이
		var a := PI + p.rng.randf_range(0.1, PI - 0.1)
		Cave._stone(p, c + Vector2(cos(a) * (rx + 3 * u), sin(a) * (ry + 3 * u) + 2 * u), 4.0 * u, 2.6 * u, Color("#dfe6ee"))
