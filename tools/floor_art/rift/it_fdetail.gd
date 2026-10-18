extends RefCounted
## 강철의 묘 바닥 잔손질(변형마다): 긁힘·녹·금·깨진 판석 조각·카펫 얼룩·화살·경고 문양·회전 칼날.
## 칸 가장자리는 Common.cell이 바탕으로 되돌리므로 가운데(약 12~52px) 위주로 그린다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const L := preload("res://tools/floor_art/rift/it_lib.gd")

const KINDS := {
	"steelplates": ["scratch", "rust", "dent", "plain", "weld", "oil"],
	"flagstone": ["crack", "chips", "plain", "stain", "crack", "pebbles"],
	"carpet": ["plain", "blood", "hole", "dust", "wax", "fold"],
	"stairs": ["plain", "chip", "crack", "dust", "pebbles", "stain"],
}
const MARK := Color("#a8683a")


static func detail(p: Paint, style: String, v: int, col: Color) -> void:
	var u := p.w / 64.0
	var c := Vector2(p.w, p.h) * 0.5
	if style != "sunbeam":  # 붓결·때(바탕은 주기 잡음뿐이라 가운데에만 덧칠)
		Ink.strokes(p, Paint.rect_poly(9 * u, 9 * u, 46 * u, 46 * u), 0.7, 9.0 * u, 3.0 * u, 20.0, 0.09, 0.3)
		for k in 3:
			Cave._dot(p, c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-16, 16)) * u, p.rng.randf_range(0.6, 1.4) * u, L.SHADE, 0.5)
	match style:
		"rubble":
			_rubble(p, v, u)
			return
		"sunbeam":
			_motes(p, v, u)
			return
		"bladegroove":
			_sweeps(p, v, u, col)
			return
		"pressureplate":
			_glyph(p, v, u)
			return
		"arrowtrap":
			var n: int = [1, 2, 1, 3, 0, 2][v % 6]
			_scratches(p, 3, u, 0.18)
			for k in n:
				var a := c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-14, 14)) * u
				_arrow(p, a, Vector2.from_angle(p.rng.randf() * TAU), p.rng.randf_range(16, 24) * u, u, p.rng.randf() < 0.35)
			if n == 0:
				_rust(p, c + Vector2(4, 6) * u, 9 * u)
			return
		"bladetrap":
			_blade(p, v, u)
			return
	var kinds: Array = KINDS.get(style, ["plain"])
	var kind := str(kinds[v % kinds.size()])
	match kind:
		"plain":
			Ink.strokes(p, Paint.rect_poly(10 * u, 10 * u, 44 * u, 44 * u), 0.6, 8.0 * u, 2.5 * u, 10.0, 0.06, 0.25)
		"scratch":
			_scratches(p, p.rng.randi_range(5, 8), u, 0.3)
		"rust":
			_rust(p, c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * u, 11 * u)
			_rust(p, c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-12, 12)) * u, 5 * u)
		"dent":
			var q := c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * u
			p.fill_poly(Cave._ellipse(q, 9 * u, 7 * u, 18, p.rng), func(x: int, y: int) -> Color:
				var d := (Vector2(x, y) - q) / (9.0 * u)
				return Color(0.04, 0.05, 0.06, clampf(0.35 - (d.x + d.y) * 0.3, 0.0, 0.45)), 1.0, true)
			Ink.line(p, q + Vector2(2, 7) * u, q + Vector2(8, 2) * u, 1.0 * u, L.LIT, 0.3, 0.5, true)
			_scratches(p, 2, u, 0.25)
		"weld":
			var a := c + Vector2(-14, p.rng.randf_range(-8, 8)) * u
			var b := a + Vector2(28, p.rng.randf_range(-6, 6)) * u
			for k in 14:
				var q := a.lerp(b, k / 13.0)
				Cave._stone(p, q, 2.2 * u, 1.6 * u, col.darkened(0.1))
			Cave._crack(p, b, 2, 5 * u, Vector2(1, 0.3))
		"oil":
			Cave._puddle(p, c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * u, 10 * u, col)
			_scratches(p, 3, u, 0.25)
		"crack":
			Cave._crack(p, c + Vector2(p.rng.randf_range(-12, 4), p.rng.randf_range(-12, 4)) * u, p.rng.randi_range(3, 5), 7.0 * u, Vector2.from_angle(p.rng.randf_range(0.2, 1.2)))
		"chips":
			for k in 3:
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-15, 15)) * u
				Cave._pit(p, q, p.rng.randf_range(2.0, 4.0) * u)
			Cave._stone(p, c + Vector2(6, 8) * u, 3 * u, 2.2 * u, L.STONE)
		"stain", "blood":
			var tone := Color("#141418") if kind == "stain" else Color("#2a0606")
			var q := c + Vector2(p.rng.randf_range(-5, 5), p.rng.randf_range(-5, 5)) * u
			p.fill_poly(Cave._ellipse(q, 13 * u, 10 * u, 22, p.rng), func(x: int, y: int) -> Color:
				var d := Vector2(x - q.x, y - q.y).length() / (13.0 * u)
				return Color(tone.r, tone.g, tone.b, clampf(0.75 - d * 0.6, 0.0, 0.6) * (0.7 + 0.5 * p.nz("mid", x, y))), 1.0, true)
			if kind == "blood":
				for k in 5:
					Cave._dot(p, q + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-14, 14)) * u, p.rng.randf_range(0.8, 2.0) * u, tone, 0.7)
		"pebbles":
			for k in p.rng.randi_range(3, 5):
				var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-16, 16)) * u
				var rx := p.rng.randf_range(1.8, 4.0) * u
				Cave._stone(p, q, rx, rx * 0.75, L.STONE.lightened(p.rng.randf_range(-0.1, 0.15)))
		"hole":  # 해져 바닥 돌이 드러난 구멍
			var q := c + Vector2(p.rng.randf_range(-4, 4), p.rng.randf_range(-4, 4)) * u
			var poly := Cave._ellipse(q, 6 * u, 4 * u, 14, p.rng)
			p.fill_poly(poly, func(x: int, y: int) -> Color: return p.vary(Color("#3c3e44"), x, y, 0.12))
			for i in poly.size():
				var a := poly[i]
				var b := poly[(i + 1) % poly.size()]
				Ink.line(p, a, b, 1.2 * u, Color("#2a0a0a"), 0.7, 0.8)
				Ink.line(p, a, a + (a - q).normalized() * p.rng.randf_range(1.0, 3.0) * u, 0.9 * u, Color("#7a5a48"), 0.6, 0.4)
		"dust":
			for k in 4:
				var q := c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-12, 12)) * u
				Cave._dot(p, q, p.rng.randf_range(4.0, 8.0) * u, Color("#8a8480"), 0.3)
			for k in 2:  # 먼지 위 발자국
				var q := c + Vector2(-6 + k * 10, 4 - k * 9) * u
				p.fill_poly(Cave._ellipse(q, 2.2 * u, 3.6 * u, 12), func(_x: int, _y: int) -> Color: return Color(0.1, 0.05, 0.05, 0.35), 1.0, true)
		"wax":
			for k in p.rng.randi_range(4, 7):
				var q := c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-14, 14)) * u
				Cave._dot(p, q, p.rng.randf_range(1.0, 2.4) * u, L.CANDLE, 0.85)
		"fold":
			var y0 := c.y + p.rng.randf_range(-8, 8) * u
			for x in range(int(10 * u), int(54 * u)):
				var yy := y0 + sin(x * 0.15) * 2.0 * u
				for k in int(4 * u):
					p.tint(x, int(yy) - k, L.LIT, 0.1 * (1.0 - k / (4.0 * u)))
					p.tint(x, int(yy) + k + 1, L.SHADE, 0.35 * (1.0 - k / (4.0 * u)))
		"chip":
			var q := Vector2(c.x + p.rng.randf_range(-12, 12) * u, 16.0 * u * p.rng.randi_range(1, 2) + 9.0 * u)
			L.slab(p, PackedVector2Array([q + Vector2(-5, -3) * u, q + Vector2(3, -4) * u, q + Vector2(4, 1) * u, q + Vector2(-4, 2) * u]), 1.5 * u, L.STONE)


static func _scratches(p: Paint, n: int, u: float, a: float) -> void:
	for k in n:
		var q := Vector2(p.rng.randf_range(14, 50), p.rng.randf_range(14, 50)) * u
		var d := Vector2.from_angle(p.rng.randf_range(-0.5, 0.5) + (PI * 0.5 if p.rng.randf() < 0.3 else 0.0))
		var ln := p.rng.randf_range(6, 14) * u
		Ink.line(p, q, q + d * ln, 0.7 * u, L.LIT, a, 0.3, true)
		Ink.line(p, q + Vector2(0, -0.8) * u, q + d * ln + Vector2(0, -0.8) * u, 0.6 * u, L.SHADE, a * 0.8, 0.3, true)


static func _rust(p: Paint, q: Vector2, r: float) -> void:
	p.fill_poly(Cave._ellipse(q, r, r * 0.8, 20, p.rng), func(x: int, y: int) -> Color:
		var d := Vector2(x - q.x, y - q.y).length() / r
		var tone := L.RUST.lerp(Color("#7a4a28"), p.nz("hi", x, y))
		return Color(tone.r, tone.g, tone.b, clampf(0.85 - d * 0.75, 0.0, 0.7) * (0.6 + 0.6 * p.nz("mid", x, y))), 1.0, true)


## 화살 한 개: 촉(a 쪽) + 자루 + 깃.
static func _arrow(p: Paint, a: Vector2, d: Vector2, ln: float, u: float, broken: bool) -> void:
	var b := a + d * (ln * (0.55 if broken else 1.0))
	Ink.line(p, a + Vector2(1, 1.4) * u, b + Vector2(1, 1.4) * u, 1.6 * u, L.SHADE, 0.35, 0.2)
	Ink.line(p, a, b, 1.7 * u, Color("#1a120c"), 0.9, 0.2)
	Ink.line(p, a, b, 0.9 * u, Color("#7a5a3a"), 0.9, 0.2)
	var n := Vector2(-d.y, d.x)
	var head := PackedVector2Array([a - d * 4.0 * u, a + n * 1.6 * u, a - n * 1.6 * u])
	p.fill_poly(head, func(_x: int, _y: int) -> Color: return Color("#5a6068"))
	Ink.path(p, head, 0.7 * u, true, Ink.INK, 0.8, 0.1)
	if broken:
		Ink.line(p, b, b + d.rotated(0.4) * 2.5 * u, 0.8 * u, Color("#a08060"), 0.8, 0.2)
	else:
		for sgn: float in [-1.0, 1.0]:
			Ink.line(p, b - d * 4.0 * u, b + n * sgn * 2.0 * u, 1.0 * u, Color("#b8b0a0"), 0.75, 0.2)
			Ink.line(p, b - d * 1.5 * u, b + d * 0.5 * u + n * sgn * 2.0 * u, 1.0 * u, Color("#b8b0a0"), 0.75, 0.2)


## 깨진 판석 더미: 판 조각 3~6개 + 부스러기 + 먼지.
static func _rubble(p: Paint, v: int, u: float) -> void:
	var c := Vector2(p.w, p.h) * 0.5
	for k in 3:
		Cave._dot(p, c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-10, 10)) * u, p.rng.randf_range(6, 10) * u, Color("#a8a8a4"), 0.22)
	var n := 3 + v % 4
	var pieces: Array[Vector2] = []
	for k in n:
		pieces.append(c + Vector2(p.rng.randf_range(-13, 13), p.rng.randf_range(-13, 11)) * u)
	pieces.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	for q in pieces:
		var rx := p.rng.randf_range(5.0, 9.0) * u
		var tone := L.STONE.lerp(Color("#4a4c52"), p.rng.randf()).lightened(p.rng.randf_range(0.0, 0.15))
		L.slab(p, L.shard(p, q, rx, rx * p.rng.randf_range(0.55, 0.8), p.rng.randf() * TAU), p.rng.randf_range(2.0, 3.5) * u, tone)
	for k in p.rng.randi_range(4, 7):
		var q := c + Vector2(p.rng.randf_range(-17, 17), p.rng.randf_range(-17, 17)) * u
		var rx := p.rng.randf_range(1.2, 2.6) * u
		Cave._stone(p, q, rx, rx * 0.75, L.STONE.lightened(0.1))


## 빛줄기 속 먼지 티끌.
static func _motes(p: Paint, v: int, u: float) -> void:
	var c := Vector2(p.w, p.h) * 0.5
	for k in 7 + v % 3 * 3:
		var q := c + Vector2(p.rng.randf_range(-19, 19), p.rng.randf_range(-19, 19)) * u
		var r := p.rng.randf_range(0.5, 1.3) * u
		Cave._dot(p, q, r * 2.5, Color("#ffffff"), 0.12)
		Cave._dot(p, q, r, Color("#fbfdff"), p.rng.randf_range(0.4, 0.8))
	if v % 2 == 1:
		Cave._crack(p, c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-8, 8)) * u, 3, 5.0 * u, Vector2(1, 0.4))
		var poly := Paint.rect_poly(8 * u, 8 * u, 48 * u, 48 * u)
		Ink.shade(p, poly, Vector2(8, 8) * u, Vector2(56, 56) * u, 0.0, 0.0)


## 칼날 홈 둘레: 칼날이 휩쓴 호 모양 긁힘 + 쇳가루·피.
static func _sweeps(p: Paint, v: int, u: float, col: Color) -> void:
	var c := Vector2(p.w * 0.5, p.h * 0.5 + p.rng.randf_range(-6, 6) * u)
	for k in 3 + v % 3:
		var r := p.rng.randf_range(13, 21) * u
		var a0 := p.rng.randf_range(-0.9, -0.3) if p.rng.randf() < 0.5 else p.rng.randf_range(PI + 0.3, PI + 0.9)
		var pts := PackedVector2Array()
		for j in 8:
			var a := a0 + j * 0.09 * (1 if k % 2 == 0 else -1)
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.9))
		Ink.path(p, pts, 0.8 * u, false, L.LIT, 0.32, 0.2)
	if v % 3 == 1:
		for k in 4:
			Cave._dot(p, c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-12, 12)) * u, p.rng.randf_range(0.8, 1.8) * u, Color("#3a0808"), 0.7)
	if v % 3 == 2:
		for k in 8:
			Cave._dot(p, c + Vector2(p.rng.randf_range(-18, 18), p.rng.randf_range(-16, 16)) * u, 0.7 * u, col.lightened(0.5), 0.7)


## 압력판 위 경고 문양(바랜 녹빛 물감).
static func _glyph(p: Paint, v: int, u: float) -> void:
	var c := Vector2(p.w * 0.5, p.h * 0.5 - 1.5 * u)
	var wd := 1.5 * u
	match v % 6:
		0, 5:  # 눈이 든 삼각형
			var tri := PackedVector2Array([c + Vector2(0, -8) * u, c + Vector2(8, 6) * u, c + Vector2(-8, 6) * u])
			Ink.path(p, tri, wd, true, MARK, 0.75, 0.4)
			Ink.path(p, Cave._ellipse(c + Vector2(0, 1.5) * u, 3.0 * u, 1.6 * u, 12), wd * 0.8, true, MARK, 0.75, 0.3)
			Cave._dot(p, c + Vector2(0, 1.5) * u, 1.0 * u, MARK.darkened(0.4), 0.9)
		1:  # 고리 + 십자
			Ink.path(p, Cave._ellipse(c, 7 * u, 7 * u, 20), wd, true, MARK, 0.75, 0.4)
			Ink.line(p, c + Vector2(-9, 0) * u, c + Vector2(9, 0) * u, wd, MARK, 0.75, 0.3)
			Ink.line(p, c + Vector2(0, -9) * u, c + Vector2(0, 9) * u, wd, MARK, 0.75, 0.3)
		2:  # 해골 닮은 둥근 표
			Ink.path(p, Cave._ellipse(c + Vector2(0, -1) * u, 6 * u, 5.5 * u, 16), wd, true, MARK, 0.75, 0.4)
			Cave._dot(p, c + Vector2(-2.5, -1.5) * u, 1.6 * u, MARK.darkened(0.3), 0.9)
			Cave._dot(p, c + Vector2(2.5, -1.5) * u, 1.6 * u, MARK.darkened(0.3), 0.9)
			for k in 3:
				Ink.line(p, c + Vector2(-3 + k * 3, 5) * u, c + Vector2(-3 + k * 3, 8) * u, wd * 0.8, MARK, 0.75, 0.2)
		3:  # 번개 꺾임
			Ink.path(p, PackedVector2Array([c + Vector2(-7, -6) * u, c + Vector2(-2, -1) * u, c + Vector2(-5, 1) * u, c + Vector2(6, 7) * u]), wd * 1.2, false, MARK, 0.75, 0.3)
		4:  # 소용돌이
			var pts := PackedVector2Array()
			for k in 26:
				var a := k * 0.42
				pts.append(c + Vector2(cos(a), sin(a)) * (1.0 + k * 0.32) * u)
			Ink.path(p, pts, wd, false, MARK, 0.75, 0.3)
	Ink.strokes(p, Paint.rect_poly(18 * u, 14 * u, 28 * u, 30 * u), 0.8, 6.0 * u, 2.0 * u, 20.0, 0.08, 0.3)
	if v % 2 == 0:
		Cave._crack(p, Vector2(40, 20) * u, 2, 4.0 * u, Vector2(-0.4, 1))


## 회전 칼날: 바닥 틈에서 솟은 둥근 톱날(남쪽을 보는 원판의 위 반쪽) + 움직임 호 + 반짝임.
static func _blade(p: Paint, v: int, u: float) -> void:
	var hub := Vector2(p.w * 0.5, 46.0 * u)
	var r := 18.0 * u
	var rot := v * 0.37
	var teeth := 14
	var disc := PackedVector2Array()
	for k in teeth * 2 + 1:
		var a := PI + PI * k / (teeth * 2.0)
		var rr := r if k % 2 == 0 else r * 0.86
		var aa := a + (rot if k % 2 == 0 else rot) * 0.0
		disc.append(hub + Vector2(cos(aa + 0.06 * (k % 2)), sin(aa + 0.06 * (k % 2))) * rr)
	disc.append(hub + Vector2(r, 0))
	disc.append(hub + Vector2(-r, 0))
	Cave._dot(p, hub + Vector2(4, 2) * u, r * 1.1, L.SHADE, 0.35)
	p.fill_poly(disc, func(x: int, y: int) -> Color:
		var d := Vector2(x + 0.5, y + 0.5) - hub
		var rr := d.length() / r
		var ang := atan2(d.y, d.x)
		var t := 0.5 + cos(ang + PI * 0.75) * 0.25 + sin(rr * 18.0 + rot * 5.0) * 0.05
		var cc := Color("#4a5058").lerp(Color("#c8d0d8"), clampf(t, 0.0, 1.0))
		if rr > 0.8:
			cc = cc.lightened(0.15)
		return p.vary(cc, x, y, 0.05))
	Ink.path(p, disc, 1.1 * u, true, Ink.INK, 0.85, 0.15)
	for k in 3:  # 날을 잡은 홈 링
		var pts := PackedVector2Array()
		var rr := r * (0.35 + k * 0.17)
		for j in 13:
			var a := PI + PI * j / 12.0
			pts.append(hub + Vector2(cos(a), sin(a)) * rr)
		Ink.path(p, pts, 0.6 * u, false, L.SHADE, 0.45, 0.1)
	var hubp := PackedVector2Array()
	for j in 9:
		var a := PI + PI * j / 8.0
		hubp.append(hub + Vector2(cos(a), sin(a)) * 4.0 * u)
	p.fill_poly(hubp, func(_x: int, _y: int) -> Color: return Color("#2a2c30"))
	Ink.path(p, hubp, 0.8 * u, true, Ink.INK, 0.8, 0.1)
	for k in 2:  # 휙 도는 호
		var pts := PackedVector2Array()
		var rr := r + (2.5 + k * 2.5) * u
		var a0 := PI * 1.12 + v * 0.2
		for j in 9:
			var a := a0 + j * 0.11
			pts.append(hub + Vector2(cos(a), sin(a)) * rr)
		Ink.path(p, pts, 0.8 * u, false, Color("#e8f0ff"), 0.35 - k * 0.12, 0.2)
	L.glint(p, hub + Vector2(-r * 0.55, -r * 0.6), 3.0 * u, 0.9)
	if v % 3 == 1:  # 날에 묻은 피
		for k in 3:
			var a := PI + p.rng.randf_range(0.3, 2.8)
			Cave._dot(p, hub + Vector2(cos(a), sin(a)) * r * 0.85, 2.0 * u, Color("#3a0606"), 0.75)
		Cave._dot(p, hub + Vector2(6, 9) * u, 3.0 * u, Color("#2a0505"), 0.6)
	if v % 3 == 2:  # 불똥
		for k in 5:
			var q := hub + Vector2(p.rng.randf_range(-r, r), p.rng.randf_range(-3, 2) * u)
			Cave._dot(p, q, 0.8 * u, Color("#ffe0a0"), 0.9)
