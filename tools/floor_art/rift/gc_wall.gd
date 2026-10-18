extends RefCounted
## 빙하굴 벽(gc.gd 전용): 얼음벽(눈 덮인 윗면 · 층층이 비치는 얼음 앞면 + 고드름) · 바위 절벽(눈 쌓인 바위 · 층리 턱의 눈) ·
## 폭포(윗면 = 쏟아지는 물, 앞면 = 세로 물줄기 + 발치 물안개). 앞면 아래 밑동(Common.skirt)은 들쭉날쭉 투명하게 끝난다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Common := preload("res://tools/floor_art/rift/Common.gd")
const Mat := preload("res://tools/floor_art/rift/gc_mat.gd")

const KINDS := {
	"icewall_top": ["plain", "snow", "crack", "plain", "snow", "crack"],
	"icewall_face": ["plain", "crack", "glow", "bubbles", "crack", "streak"],
	"cliff_top": ["plain", "snow", "crack", "stones", "snow", "crack"],
	"cliff_face": ["plain", "icicles", "fissure", "snowstreak", "icicles", "bulge"],
	"waterfall_top": ["plain", "foam", "rock", "plain", "foam", "rock"],
	"waterfall_face": ["plain", "ice", "rock", "plain", "ice", "spray"],
}


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if part == "top":
		if style == "waterfall":
			_water_top(p, col, s)
		else:
			_top(p, style, col, s)
	else:
		match style:
			"icewall":
				_ice_face(p, col, s)
			"cliff":
				_cliff_face(p, col, s)
			_:
				_fall_face(p, col, s)


## 얼음벽·절벽 윗면: 세포 잡음 덩어리(왼쪽 위 빛) + 사이 골 + 우묵한 곳에 쌓인 눈.
static func _top(p: Paint, style: String, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var fb := Seam.field(w, h, s, 0.05, 3)
	var cl := Seam.field(w, h, s + 3, 0.065, 1, true)
	var sn := Seam.field(w, h, s + 5, 0.05, 3)
	var fine := Seam.field(w, h, s + 6, 0.3, 2)
	for i in w * h:
		fb[i] = fb[i] * 0.55 + cl[i] * 0.45
	var ice := style == "icewall"
	var lit := Mat.mul(col, 1.5, 1.7, 1.8) if ice else col.lightened(0.4)
	var snow := Color(0.66, 0.72, 0.8) if ice else Color(0.62, 0.66, 0.72)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(fb, w, h, x, y, 5.0)
			var t := 0.45 + r * (0.5 if ice else 0.8) + (fb[i] - 0.5) * 0.3
			var c := Mat.ramp(t, col.darkened(0.55), col, lit)
			if cl[i] < 0.08:
				c = c.lerp(Ink.INK, 0.5 * (1.0 - cl[i] / 0.08))
			var f := smoothstep(0.48, 0.7, sn[i] + r * 0.5 + (fine[i] - 0.5) * 0.1)
			c = c.lerp(snow.darkened(clampf(-r * 2.0, 0.0, 0.35)), f * (0.8 if ice else 0.9))
			p.blend(x, y, c, 1.0)


## 폭포 윗면: 남쪽(아래)으로 쏟아지는 물 — 세로로 늘인 결 + 흰 물살.
static func _water_top(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var a := Seam.field(w, h / 4, s, 0.16, 3)
	var lo := Seam.field(w, h, s + 2, 0.04, 2)
	var deep := Mat.mul(col, 0.4, 0.62, 0.72)
	for y in h:
		for x in w:
			var i := y * w + x
			var fa := Mat.sample(a, w, h / 4, x + lo[i] * 4.0, y / 4.0)
			var c := Mat.ramp(0.45 + (fa - 0.5) * 1.2 + (lo[i] - 0.5) * 0.3, deep, col, col.lightened(0.3))
			c = c.lerp(Color("#e2f0f2"), smoothstep(0.64, 0.78, fa) * 0.85)
			p.blend(x, y, c, 1.0)


## 앞면 공통: 바닥과 만나는 들쭉날쭉한 밑동 y(x), 윗면과 만나는 턱 y(x).
static func _edges(w: int, s: int, main: float) -> Array[PackedFloat32Array]:
	var jag := Seam.field(w, 8, s + 9, 0.1, 3)
	var lip := Seam.field(w, 8, s + 5, 0.12, 2)
	var foot := PackedFloat32Array()
	var top := PackedFloat32Array()
	foot.resize(w)
	top.resize(w)
	for x in w:
		foot[x] = main + (0.25 + jag[x] * 0.75) * Common.skirt
		top[x] = 3.0 + lip[x] * 5.0
	return [foot, top]


## 얼음벽 앞면: 가로로 겹친 반투명 얼음 층 + 속빛 + 흰 층선, 위 턱은 눈, 턱 밑에 고드름, 발치에 눈 더미.
static func _ice_face(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var tn := Mat.tone(col)
	var main := float(h - Common.skirt)
	var e := _edges(w, s, main)
	var hf := Seam.field(w, h, s, 0.035, 3)
	var gf := Seam.field(w, h, s + 2, 0.03, 2)
	var fine := Seam.field(w, h, s + 6, 0.3, 2)
	var deep := Mat.mul(tn, 0.32, 0.52, 0.78)
	var lit := Mat.mul(tn, 1.06, 1.14, 1.16)
	var lh := 9.0 * w / 64.0
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := e[0][x]
			var ly := e[1][x]
			if y >= foot:
				continue
			var yl := (y - ly) + (hf[i] - 0.5) * 10.0  # 물결진 얼음 층
			var layer := floori(yl / lh)
			var ly_in := fposmod(yl, lh) / lh
			var t := 0.52 + (Paint.hash01(layer, 5, s % 89) - 0.5) * 0.5 + Seam.relief(hf, w, h, x, y, 4.0) * 0.4 + (gf[i] - 0.5) * 0.35
			t += (0.5 - ly_in) * 0.12  # 층마다 위가 밝다
			t -= smoothstep(main * 0.3, foot, float(y)) * 0.4
			t += (1.0 - y / main) * 0.08
			var c := Mat.ramp(t, deep, tn, lit)
			if ly_in < 0.1:  # 흰 층선
				c = c.lerp(Mat.mul(tn, 1.35, 1.4, 1.4), 0.55 * (1.0 - ly_in / 0.1))
			elif ly_in > 0.9:
				c = c.lerp(deep, 0.35)
			c = c.lerp(Mat.mul(tn, 1.3, 1.5, 1.55), smoothstep(0.62, 0.82, gf[i]) * 0.3)  # 속에서 비치는 빛
			if y < ly:  # 위 턱의 눈
				c = Mat.mul(tn, 1.32, 1.34, 1.36).lerp(Mat.mul(tn, 1.0, 1.05, 1.15), y / maxf(1.0, ly))
			var dl := absf(y - ly)
			if dl < 1.4:
				c = c.lerp(Ink.INK, 0.65 * (1.0 - dl / 1.4))
			elif y > ly and y < ly + 5.0:
				c = c.darkened(0.25 * (1.0 - (y - ly) / 5.0))
			var df := foot - y
			if df < 6.0 + fine[i] * 3.0:  # 발치 눈 더미
				c = Mat.mul(tn, 1.2, 1.24, 1.28).lerp(Mat.mul(tn, 0.85, 0.92, 1.05), clampf(1.0 - df / 6.0, 0.0, 1.0) * 0.6)
			if df < 1.5:
				c = c.lerp(Ink.INK, 0.5)
			p.blend(x, y, c, 1.0)
	var n := 7
	for k in n:
		var x := (k + Paint.hash01(k, 1, s % 113) * 0.7) * w / n
		var ln := (5.0 + Paint.hash01(k, 2, s % 113) * 11.0) * w / 64.0
		var root := Vector2(x, e[1][clampi(int(x), 0, w - 1)] + 0.5)
		Mat.spike(p, root, root + Vector2(0.5, ln), (1.2 + Paint.hash01(k, 3, s % 113) * 1.4) * w / 64.0, Mat.ICE_LIGHT, Mat.ICE_MID, 0.7)


## 바위 절벽 앞면: 층리 바위(빛 받은 턱 · 턱 밑 그늘 · 잉크) + 턱 위에 쌓인 눈, 윗턱 눈, 발치 눈.
static func _cliff_face(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var main := float(h - Common.skirt)
	var e := _edges(w, s, main)
	var hf := Seam.field(w, h, s, 0.06, 4)
	var sn := Seam.field(w, 8, Mat.shared(s) + 4, 0.035, 2)
	var lw := Seam.field(w, 8, Mat.shared(s) + 7, 0.025, 2)  # 층리 턱은 모든 변형이 같게(칸끼리 이어진다)
	var fine := Seam.field(w, h, s + 6, 0.3, 2)
	var snow := Color(0.7, 0.75, 0.82)
	var period := 28.0 * w / 64.0
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := e[0][x]
			var ly := e[1][x]
			if y >= foot:
				continue
			var base := y - 12.0 * w / 64.0
			var j0 := floori(base / period)
			var yy := period
			var jj := j0
			for j: int in [j0 - 1, j0, j0 + 1]:  # 바로 위의 층리 턱(턱마다 x를 따라 물결진다)
				var d: float = base - j * period - (lw[posmod(j, 8) * w + x] - 0.5) * 18.0
				if d >= 0.0 and d < yy:
					yy = d
					jj = j
			var t := 0.45 + Seam.relief(hf, w, h, x, y, 6.0) * 0.8 + (hf[i] - 0.5) * 0.35 + (fine[i] - 0.5) * 0.1
			t -= smoothstep(main * 0.55, foot, float(y)) * 0.3
			t += 0.14 * (1.0 - yy / period)  # 층 윗부분이 빛을 받는다
			var c := Mat.ramp(t, col.darkened(0.55), col, col.lightened(0.4))
			var sv := sn[posmod(jj, 7) * w + x]
			var sd := 1.0 + sv * 5.0 * w / 64.0  # 턱 위 눈 두께
			if base >= 0.0:
				if yy < sd and sv > 0.3:  # 턱 위 눈
					c = snow.darkened((yy / sd) * 0.25)
				elif yy < 1.3:
					c = c.lerp(Ink.INK, 0.6)
				elif yy < sd + 1.3 and sv > 0.3:
					c = c.lerp(Ink.INK, 0.6)
				elif yy < sd + 8.0:
					c = c.darkened(0.3 * (1.0 - (yy - sd - 1.3) / 6.7))
			if y < ly:
				c = snow.lightened(0.05)
			var dl := absf(y - ly)
			if dl < 1.4:
				c = c.lerp(Ink.INK, 0.65 * (1.0 - dl / 1.4))
			var df := foot - y
			var pile := 3.0 + sn[7 * w + x] * 7.0  # 발치 눈
			if df < pile:
				c = snow.darkened(clampf(1.0 - df / pile, 0.0, 1.0) * 0.3)
			elif df < pile + 1.2:
				c = c.lerp(Ink.INK, 0.5)
			if df < 1.5:
				c = c.lerp(Ink.INK, 0.5)
			p.blend(x, y, c, 1.0)


## 폭포 앞면: 세로로 늘인 물줄기 결 + 흰 물살 + 물 뒤로 비치는 젖은 바위, 위 턱은 넘어가는 물의 빛, 아래는 물안개로 흐려진다.
static func _fall_face(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var tn := Mat.tone(col)
	var main := float(h - Common.skirt)
	var e := _edges(w, s, main)
	var a := Seam.field(w, maxi(2, h / 4), s, 0.18, 3)
	var b := Seam.field(w, maxi(2, h / 8), s + 1, 0.25, 2)
	var mist := Seam.field(w, h, s + 3, 0.06, 3)
	var deep := Mat.mul(tn, 0.42, 0.6, 0.76)
	var lit := Mat.mul(tn, 1.08, 1.12, 1.14)
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := e[0][x]
			var ly := e[1][x]
			var fa := Mat.sample(a, w, maxi(2, h / 4), x, y / 4.0)
			var fb := Mat.sample(b, w, maxi(2, h / 8), x + fa * 3.0, y / 8.0)
			var t := 0.48 + (fa - 0.5) * 1.3 + (fb - 0.5) * 0.5
			var c := Mat.ramp(t, deep, tn, lit)
			if fa < 0.24:  # 물 뒤 젖은 바위
				c = c.lerp(Mat.mul(tn, 0.3, 0.36, 0.42), smoothstep(0.24, 0.14, fa) * 0.8)
			c = c.lerp(Color("#eef8fc"), smoothstep(0.62, 0.76, fa * 0.7 + fb * 0.3) * 0.9)  # 흰 물살
			if y < ly + 4.0:  # 넘어가는 물의 둥근 빛
				c = c.lerp(Color("#f4fbff"), 0.6 * (1.0 - absf(y - ly - 1.0) / 4.0))
			var m := smoothstep(main * 0.62, foot, float(y)) * (0.25 + mist[i] * 0.6 + fa * 0.3)
			c = c.lerp(Color("#e6f2f8"), clampf(m, 0.0, 0.9))  # 물안개
			var alpha := 1.0
			if y >= main - 2.0:
				alpha = clampf(1.0 - (y - (main - 2.0)) / maxf(1.0, foot - main + 2.0), 0.0, 1.0) * (0.7 + mist[i] * 0.3)
			if alpha > 0.0:
				p.blend(x, y, c, alpha)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	var kinds: Array = KINDS.get(style + "_" + part, ["plain"])
	var kind := str(kinds[v % kinds.size()])
	var u := p.w / 64.0
	var main := float(p.h - (Common.skirt if part == "face" else 0))
	var tn := Mat.tone(col)
	var c := Vector2(p.w * 0.5 + p.rng.randf_range(-6, 6) * u, main * 0.5 + p.rng.randf_range(-4, 4) * u)
	match kind:
		"plain":
			if style != "waterfall":
				Ink.strokes(p, Paint.rect_poly(p.w * 0.15, main * 0.15, p.w * 0.7, main * 0.7), 0.6, 9.0 * u, 3.0 * u, 70.0 if part == "top" else 85.0, 0.07, 0.25)
		"snow":
			Mat.snow_poly(p, Mat.cap_poly(p, c + Vector2(-14, 4) * u, c + Vector2(12, 3) * u, 8.0 * u, 2.0 * u), 0.6)
		"crack":
			if style == "icewall":
				var start := c + Vector2(0, -main * 0.35) if part == "face" else c + Vector2(-10, -6) * u
				var dir := Vector2(0.1, 1.0) if part == "face" else Vector2.from_angle(p.rng.randf_range(0.0, 1.2))
				Mat.crack(p, start, p.rng.randi_range(3, 5), main * (0.16 if part == "face" else 0.1), dir, Mat.mul(tn, 1.6, 1.65, 1.65), Ink.INK, 1.0 * u)
			else:
				Cave._crack(p, c + Vector2(-8, -4) * u, p.rng.randi_range(3, 4), 6.0 * u, Vector2.from_angle(p.rng.randf() * TAU))
		"glow":  # 얼음 속에서 새어 나오는 푸른 빛
			Ink.glow(p, c.x, c.y, 14.0 * u, Mat.ICE_GLOW, 0.35)
			Mat.crack(p, c + Vector2(-4, -8) * u, 3, 5.0 * u, Vector2(0.3, 1.0), Color("#e8faff"), Mat.ICE_DARK, 0.8 * u)
		"bubbles":
			for k in p.rng.randi_range(6, 10):
				Mat.bubble(p, c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-main * 0.3, main * 0.3)), p.rng.randf_range(0.8, 2.2) * u, Mat.mul(tn, 1.5, 1.55, 1.55), 0.7)
		"streak":  # 녹았다 언 물자국(세로)
			for k in p.rng.randi_range(2, 3):
				var x := c.x + p.rng.randf_range(-12, 12) * u
				Ink.line(p, Vector2(x, main * 0.2), Vector2(x + p.rng.randf_range(-1, 1) * u, main * 0.85), 1.6 * u, Mat.mul(tn, 1.4, 1.45, 1.45), 0.4, 0.8)
				Ink.line(p, Vector2(x + 1.2 * u, main * 0.2), Vector2(x + 1.2 * u, main * 0.85), 0.7 * u, Mat.ICE_DARK, 0.3, 0.8)
		"stones":
			for k in 3:
				var q := c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-8, 8)) * u
				Cave._stone(p, q, 4.0 * u, 3.0 * u, col.lightened(0.15))
		"icicles":  # 층리 턱에서 늘어진 고드름
			var y0 := main * p.rng.randf_range(0.3, 0.5)
			for k in p.rng.randi_range(3, 5):
				var x := p.w * p.rng.randf_range(0.22, 0.78)
				Mat.spike(p, Vector2(x, y0 + p.rng.randf_range(-2, 2) * u), Vector2(x + 0.5 * u, y0 + p.rng.randf_range(8, 18) * u), p.rng.randf_range(1.3, 2.4) * u, Mat.ICE_LIGHT, Mat.ICE_MID, 0.8)
			Ink.line(p, Vector2(p.w * 0.18, y0), Vector2(p.w * 0.82, y0 + 1.0 * u), 1.4 * u, Ink.INK, 0.6, 1.0)
		"fissure":
			Cave._crack(p, Vector2(p.rng.randf_range(0.35, 0.65) * p.w, 6.0 * u), p.rng.randi_range(4, 6), main * 0.13, Vector2(0, 1))
		"snowstreak":  # 바람에 붙은 눈 줄
			for k in 3:
				var y := main * (0.25 + k * 0.22)
				Ink.line(p, Vector2(p.w * 0.2, y), Vector2(p.w * 0.75, y + p.rng.randf_range(-4, 4) * u), 2.4 * u, Color(0.72, 0.77, 0.84), 0.5, 1.4)
		"bulge":
			var q := c + Vector2(0, main * 0.05)
			var rx := p.w * 0.24
			var ry := main * 0.22
			p.fill_poly(Cave._ellipse(q, rx, ry, 20, p.rng), func(x: int, y: int) -> Color:
				var d := Vector2((x - q.x) / rx, (y - q.y) / ry)
				return Color(0.06, 0.07, 0.1, clampf(d.y * 0.45 + d.x * 0.15, 0.0, 0.45)), 1.0, true)
			Mat.snow_poly(p, Mat.cap_poly(p, q + Vector2(-rx * 0.8, -ry * 0.7), q + Vector2(rx * 0.6, -ry * 0.9), ry * 0.3, ry * 0.15), 0.6)
		"foam":
			for k in p.rng.randi_range(3, 5):
				var x := c.x + p.rng.randf_range(-14, 14) * u
				Ink.line(p, Vector2(x, c.y - 14 * u), Vector2(x + p.rng.randf_range(-1.5, 1.5) * u, c.y + p.rng.randf_range(4, 16) * u), 1.5 * u, Color("#eef8fa"), 0.7, 0.7)
		"rock":
			var q := c + Vector2(0, main * 0.1)
			Cave._stone(p, q, 6.0 * u, 4.5 * u, Color(0.13, 0.16, 0.19))
			for k in 6:
				Cave._dot(p, q + Vector2(p.rng.randf_range(-6, 6), -4.0 + p.rng.randf_range(-2, 1)) * u, 1.3 * u, Color("#eef8fa"), 0.8)
			for k in 3:
				var x := q.x + (k - 1) * 3.0 * u
				Ink.line(p, Vector2(x, q.y + 3 * u), Vector2(x, q.y + 14 * u), 1.2 * u, Color("#e6f4f8"), 0.6, 0.6)
		"ice":  # 폭포 가장자리에 얼어붙은 고드름 발
			var x0 := c.x + p.rng.randf_range(-8, 8) * u
			for k in 5:
				var x := x0 + (k - 2) * 3.4 * u
				var root := Vector2(x, 2.0 * u)
				Mat.spike(p, root, root + Vector2(0.3 * u, main * p.rng.randf_range(0.3, 0.6)), p.rng.randf_range(2.6, 4.0) * u, Color("#cfeaf5"), Color("#4f7f9c"), 1.0)
		"spray":
			for k in 24:
				Cave._dot(p, Vector2(c.x + p.rng.randf_range(-20, 20) * u, main * p.rng.randf_range(0.5, 0.95)), p.rng.randf_range(0.8, 2.0) * u, Color("#f2faff"), 0.6)
