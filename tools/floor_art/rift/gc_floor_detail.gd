extends RefCounted
## 빙하굴 바닥 잔손질(gc.gd 전용): 변형마다 발자국·눈 둔덕·뼈·금·거품·서리·자갈·물보라·긁힌 자국… 칸 가운데 위주로.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Mat := preload("res://tools/floor_art/rift/gc_mat.gd")

## 재질 → 변형 번호별 잔손질 종류
const KINDS := {
	"snow": ["plain", "prints", "drift", "paws", "stone", "sticks"],
	"ice": ["plain", "crack", "bubbles", "frost", "stone", "crack"],
	"frozenlake": ["plain", "bubbles", "crack", "dust", "bubbles", "deep"],
	"icestairs": ["plain", "chip", "snow", "crack", "worn", "chip"],
	"frozenbones": ["ribs", "plain", "skull", "long", "plain", "scatter"],
	"icegravel": ["plain", "stones", "shards", "frost", "stones", "shards"],
	"river": ["plain", "foam", "rock", "chunk", "plain", "foam"],
	"slick": ["plain", "glare", "scratch", "skid", "glare", "scratch"],
	"slope": ["plain", "claw", "slide", "chips", "claw", "stones"],
	"ropespan": ["plain", "broken", "snow", "icicles", "frayed", "plain"],
}


static func paint(p: Paint, style: String, v: int, col: Color) -> void:
	var kinds: Array = KINDS.get(style, ["plain"])
	var kind := str(kinds[v % kinds.size()])
	var tn := Mat.tone(col)
	var u := p.w / 64.0
	var c := Vector2(p.w, p.h) * 0.5 + Vector2(p.rng.randf_range(-5, 5), p.rng.randf_range(-5, 5)) * u
	var shade := Mat.mul(tn, 0.45, 0.55, 0.78)
	var lit := Mat.mul(tn, 1.3, 1.32, 1.32)
	match kind:
		"plain":
			if style != "river" and style != "ropespan":
				Ink.strokes(p, Paint.rect_poly(p.w * 0.15, p.h * 0.15, p.w * 0.7, p.h * 0.7), 0.6, 9.0 * u, 3.0 * u, 70.0, 0.06, 0.25)
			if style == "snow" or style == "frozenbones":
				Mat.bump(p, c, 13.0 * u, 8.0 * u, 0.4, lit, shade)
		"prints":  # 사람 발자국(비스듬히 지나간 길)
			Mat.bump(p, c + Vector2(6, -4) * u, 12.0 * u, 7.0 * u, 0.35, lit, shade)
			var d := Vector2.from_angle(p.rng.randf_range(-1.2, -0.4))
			for k in 4:
				var side := Vector2(-d.y, d.x) * (3.2 if k % 2 == 0 else -3.2) * u
				Mat.dent(p, c + d * (k - 1.5) * 9.0 * u + side, 2.8 * u, 4.2 * u, 0.9, shade, lit, d.angle() - PI * 0.5)
		"paws":  # 짐승 발자국(작은 점 넷)
			Mat.bump(p, c + Vector2(-6, 5) * u, 12.0 * u, 7.0 * u, 0.35, lit, shade)
			var d := Vector2.from_angle(p.rng.randf_range(0.2, 0.9))
			for k in 4:
				var q := c + d * (k - 1.5) * 8.0 * u + Vector2(-d.y, d.x) * (2.0 if k % 2 == 0 else -2.0) * u
				Mat.dent(p, q, 1.8 * u, 1.6 * u, 0.9, shade, lit)
				for j in 3:
					Mat.dent(p, q + Vector2(-1.6 + j * 1.6, -2.4) * u, 0.7 * u, 0.6 * u, 0.8, shade, lit)
		"drift":
			Mat.bump(p, c, 14.0 * u, 9.0 * u, 0.55, lit, shade)
		"stone":
			if style == "ice":  # 얼음 아래 비치는 돌
				p.fill_poly(Cave._ellipse(c, 7.0 * u, 5.0 * u, 16, p.rng), func(x: int, y: int) -> Color:
					var dd := Vector2((x - c.x) / (7.0 * u), (y - c.y) / (5.0 * u)).length()
					return Color(0.08, 0.1, 0.14, 0.45 * clampf(1.2 - dd, 0.0, 1.0)), 1.0, true)
				Ink.line(p, c + Vector2(-6, -5) * u, c + Vector2(4, -7) * u, 1.4 * u, lit, 0.4, 0.4, true)
			else:  # 눈 위로 튀어나온 돌 + 눈 모자
				Cave._stone(p, c, 6.0 * u, 4.5 * u, Mat.mul(tn, 0.55, 0.56, 0.6))
				Mat.snow_poly(p, Mat.cap_poly(p, c + Vector2(-5.5, -1.5) * u, c + Vector2(4.5, -2.5) * u, 2.5 * u, 1.5 * u), 0.5)
		"sticks":  # 눈 위로 삐죽 나온 마른 풀·가지
			for k in p.rng.randi_range(3, 5):
				var q := c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-5, 5)) * u
				var e := q + Vector2(p.rng.randf_range(-3, 3), -p.rng.randf_range(5, 9)) * u
				Ink.line(p, q + Vector2(1.5, 1) * u, e + Vector2(4, 3) * u, 0.8 * u, shade, 0.35, 0.5, true)
				Ink.line(p, q, e, 1.0 * u, Color(0.1, 0.08, 0.06), 0.85, 0.6)
			Mat.bump(p, c + Vector2(0, 2) * u, 8.0 * u, 4.0 * u, 0.3, lit, shade)
		"crack":
			var light := Mat.mul(tn, 1.55, 1.6, 1.6)
			Mat.crack(p, c + Vector2(-10, -6) * u, p.rng.randi_range(3, 5), 6.5 * u, Vector2.from_angle(p.rng.randf_range(0.0, 1.0)), light, shade.darkened(0.3), 1.0 * u)
		"bubbles":
			var rim := Mat.mul(tn, 1.4, 1.5, 1.5)
			for k in p.rng.randi_range(5, 9):
				var q := c + Vector2(p.rng.randf_range(-11, 11), p.rng.randf_range(-11, 11)) * u
				var r := p.rng.randf_range(0.8, 2.6) * u
				if style == "frozenlake":  # 위로 겹겹이 쌓인 납작한 거품 기둥
					for j in 3:
						Mat.bubble(p, q + Vector2(0, -j * r * 1.4), r * (1.0 - j * 0.25), rim, 0.8 - j * 0.2)
				else:
					Mat.bubble(p, q, r, rim, 0.7)
		"frost":
			for k in 2:
				Mat.frost(p, c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * u, 10.0 * u, Mat.mul(tn, 1.45, 1.5, 1.5), 0.45)
		"dust":  # 언 호수 위 눈가루 얼룩
			Decals._blob(p, c, 10.0 * u, Mat.mul(tn, 1.22, 1.24, 1.24), 0.75, 0.35)
			for k in 6:
				Cave._dot(p, c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-8, 8)) * u, 1.0 * u, Mat.SPARK, 0.6)
		"deep":  # 얼음 속에 가라앉은 나뭇가지 그림자
			var a := c + Vector2(-12, 4) * u
			var b := c + Vector2(10, -5) * u
			Ink.line(p, a, b, 3.0 * u, Color(0.05, 0.08, 0.14), 0.4, 1.2, true)
			Ink.line(p, a.lerp(b, 0.5), a.lerp(b, 0.5) + Vector2(3, 7) * u, 2.0 * u, Color(0.05, 0.08, 0.14), 0.35, 1.0, true)
			Ink.line(p, a.lerp(b, 0.7), a.lerp(b, 0.7) + Vector2(2, -6) * u, 1.6 * u, Color(0.05, 0.08, 0.14), 0.3, 1.0, true)
		"chip":  # 계단 앞턱이 깨진 자리
			var q := Vector2(c.x + p.rng.randf_range(-6, 6) * u, p.h * 0.5)
			var notch := PackedVector2Array([q + Vector2(-6, -1) * u, q + Vector2(-2, 5) * u, q + Vector2(5, 4) * u, q + Vector2(7, -1) * u])
			p.fill_poly(notch, func(x: int, y: int) -> Color: return p.vary(shade, x, y, 0.06))
			Ink.path(p, notch, 1.0 * u, false, Ink.INK, 0.7, 0.3)
			Ink.line(p, notch[0], notch[1], 0.8 * u, lit, 0.6, 0.2)
			for k in 3:
				Cave._stone(p, q + Vector2(p.rng.randf_range(-6, 8), p.rng.randf_range(7, 12)) * u, 1.6 * u, 1.2 * u, lit)
		"snow":
			if style == "icestairs":  # 디딤면 구석에 쌓인 눈
				var q := Vector2(c.x + p.rng.randf_range(-8, 8) * u, (16.0 if p.rng.randf() < 0.5 else 48.0) * u)
				Mat.snow_poly(p, Mat.cap_poly(p, q + Vector2(-10, 4) * u, q + Vector2(10, 4) * u, 6.0 * u, 1.0 * u), 0.5)
			else:  # 로프 다리 판자 위 눈
				for k in 2:
					var q := Vector2(p.w * (0.3 + k * 0.4), p.h * 0.5) + Vector2(p.rng.randf_range(-3, 3), p.rng.randf_range(-8, 8)) * u
					Mat.snow_poly(p, Mat.cap_poly(p, q + Vector2(-6, 2) * u, q + Vector2(6, 2) * u, 4.0 * u, 1.0 * u), 0.5)
		"worn":  # 많이 밟혀 반들거리는 가운데
			Decals._blob(p, c, 11.0 * u, Mat.mul(tn, 0.85, 0.95, 1.08), 0.35, 0.3)
			Ink.line(p, c + Vector2(-8, -3) * u, c + Vector2(6, -6) * u, 1.6 * u, Mat.SPARK, 0.35, 0.6)
		"ribs", "skull", "long", "scatter":
			_bones(p, kind, c, tn, u)
		"stones":
			for k in p.rng.randi_range(2, 4):
				var q := c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-10, 10)) * u
				var r := p.rng.randf_range(3.0, 5.5) * u
				Cave._stone(p, q, r, r * 0.75, Mat.mul(tn, 0.85, 0.86, 0.9))
				if style != "slope":
					Mat.snow_poly(p, Mat.cap_poly(p, q + Vector2(-r * 0.8, -r * 0.2), q + Vector2(r * 0.6, -r * 0.4), r * 0.4, r * 0.25), 0.0)
		"shards", "chips":  # 얼음 조각
			for k in p.rng.randi_range(3, 6):
				var q := c + Vector2(p.rng.randf_range(-11, 11), p.rng.randf_range(-11, 11)) * u
				_shard(p, q, p.rng.randf_range(2.0, 4.0) * u, tn)
		"foam":
			for k in p.rng.randi_range(3, 5):
				var y := c.y + p.rng.randf_range(-14, 14) * u
				var x0 := c.x + p.rng.randf_range(-16, -4) * u
				Ink.line(p, Vector2(x0, y), Vector2(x0 + p.rng.randf_range(12, 24) * u, y + p.rng.randf_range(-1.5, 1.5) * u), 1.4 * u, Color("#e4f2f4"), 0.75, 0.8)
		"rock":  # 물살을 가르는 젖은 바위 + 왼쪽(상류)에 부서지는 물보라 + 오른쪽 꼬리
			for k in 4:
				var y := c.y + (k - 1.5) * 2.4 * u
				Ink.line(p, Vector2(c.x + 4 * u, y), Vector2(c.x + p.rng.randf_range(14, 22) * u, y + (k - 1.5) * 2.0 * u), 1.1 * u, Color("#dceef0"), 0.6, 0.6)
			Cave._stone(p, c, 5.5 * u, 4.0 * u, Color(0.12, 0.15, 0.17))
			Ink.line(p, c + Vector2(-4, -2) * u, c + Vector2(1, -3.5) * u, 1.0 * u, Color("#a8c8d0"), 0.6, 0.3)
			for k in 7:
				Cave._dot(p, c + Vector2(-6 + p.rng.randf_range(-2, 1), p.rng.randf_range(-4, 4)) * u, 1.3 * u, Color("#eef8fa"), 0.85)
		"chunk":  # 떠내려가는 얼음 덩어리
			var poly := PackedVector2Array()
			for k in 7:
				poly.append(c + Vector2.from_angle(TAU * k / 7.0) * Vector2(8, 5) * u * p.rng.randf_range(0.7, 1.15))
			var sh := PackedVector2Array()
			for pt in poly:
				sh.append(pt + Vector2(1.5, 2.0) * u)
			p.fill_poly(sh, func(_x: int, _y: int) -> Color: return Color(0.02, 0.05, 0.08, 0.5))
			p.fill_poly(poly, func(x: int, y: int) -> Color: return p.vary(Mat.mul(tn, 1.9, 1.75, 1.45), x, y, 0.06))
			Ink.path(p, poly, 1.0 * u, true, Ink.INK, 0.6, 0.4)
			Ink.line(p, poly[3], poly[5], 0.8 * u, Mat.SPARK, 0.5, 0.3)
		"glare":
			Ink.glow(p, c.x, c.y, 12.0 * u, Color("#e8f6ff"), 0.45, true, 0.6)
			Ink.line(p, c + Vector2(-9, 4) * u, c + Vector2(9, -4) * u, 1.6 * u, Mat.SPARK, 0.6, 0.4)
		"scratch":
			for k in p.rng.randi_range(4, 7):
				var q := c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-12, 12)) * u
				var d := Vector2.from_angle(p.rng.randf_range(-0.9, -0.3)) * p.rng.randf_range(5, 12) * u
				Ink.line(p, q, q + d, 0.6 * u, Mat.SPARK, 0.5, 0.2)
		"skid":  # 미끄러진 자국(무광으로 긁힌 띠)
			for k in 3:
				var a := c + Vector2(-13, -6 + k * 3) * u
				Ink.line(p, a, a + Vector2(26, 9) * u, 1.4 * u, Mat.mul(tn, 1.2, 1.2, 1.18), 0.45, 1.0, true)
		"claw":  # 미끄러지며 할퀸 세 줄
			var d := Vector2.from_angle(p.rng.randf_range(1.0, 1.4))
			var n := Vector2(-d.y, d.x)
			for k in 3:
				var a := c - d * 12.0 * u + n * (k - 1) * 3.5 * u
				Ink.line(p, a, a + d * p.rng.randf_range(18, 24) * u, 1.6 * u, shade.darkened(0.4), 0.8, 0.5)
				Ink.line(p, a + Vector2(0.9, 0.9) * u, a + d * 20.0 * u + Vector2(0.9, 0.9) * u, 0.8 * u, lit, 0.5, 0.5, true)
		"slide":  # 미끄러져 내려간 반들한 띠
			var a := c + Vector2(-4, -15) * u
			var b := c + Vector2(4, 15) * u
			Ink.line(p, a, b, 7.0 * u, Mat.mul(tn, 1.15, 1.2, 1.24), 0.35, 1.5, true)
			Ink.line(p, a + Vector2(-2, 0) * u, b + Vector2(-2, 0) * u, 1.0 * u, Mat.SPARK, 0.4, 1.0)
		"broken":  # 판자 하나가 빠진 자리(아래가 보인다)
			var sw := p.w / 6.0
			var k := 2 + p.rng.randi_range(0, 1)
			var hole := Paint.rect_poly(k * sw + 0.6 * u, 14.0 * u, sw - 1.2 * u, 38.0 * u)
			p.fill_poly(hole, func(x: int, y: int) -> Color: return Color(tn.r * 0.07, tn.g * 0.09, tn.b * 0.14, 1.0))
			for ry: float in [20.0, 44.0]:  # 받침 줄은 그대로
				Ink.line(p, Vector2(k * sw, ry * u), Vector2((k + 1) * sw, ry * u + 1.0 * u), 2.4 * u, Color(tn.r * 0.8, tn.g * 0.6, tn.b * 0.4), 0.9, 0.6)
			var stub := PackedVector2Array([Vector2(k * sw + 1 * u, 10 * u), Vector2((k + 1) * sw - 2 * u, 10 * u), Vector2((k + 1) * sw - 3 * u, 15 * u), Vector2(k * sw + 4 * u, 18 * u), Vector2(k * sw + 2 * u, 14 * u)])
			p.fill_poly(stub, func(x: int, y: int) -> Color: return p.vary(Color(tn.r * 0.9, tn.g * 0.75, tn.b * 0.6), x, y, 0.08))
			Ink.path(p, stub, 1.0 * u, true, Ink.INK, 0.8, 0.4)
		"icicles":  # 판자 아래로 매달린 작은 고드름
			for k in 4:
				var x := p.w * (0.2 + k * 0.2) + p.rng.randf_range(-2, 2) * u
				var y := 54.0 * u
				Mat.spike(p, Vector2(x, y), Vector2(x, y + p.rng.randf_range(4, 7) * u), 1.2 * u, Mat.ICE_LIGHT, Mat.ICE_MID, 0.6)
		"frayed":  # 끊어져 늘어진 줄
			var a := Vector2(c.x - 6 * u, 47.0 * u)
			var pts := PackedVector2Array()
			for k in 8:
				pts.append(a + Vector2(k * 1.6 * u, k * k * 0.2 * u + sin(k * 1.3) * 0.8 * u))
			Ink.path(p, pts, 2.0 * u, false, Color(tn.r * 1.2, tn.g * 0.9, tn.b * 0.55), 0.9, 0.4)
			Ink.path(p, pts, 0.8 * u, false, Ink.INK, 0.5, 0.4)
			for k in 3:
				Ink.line(p, pts[7], pts[7] + Vector2(p.rng.randf_range(-2, 2), 3) * u, 0.6 * u, Color(tn.r * 1.2, tn.g * 0.9, tn.b * 0.55), 0.8, 0.3)


## 반쯤 서리에 묻힌 뼈: 뼈를 그린 뒤 둘레 서리 얼룩으로 덮는다.
static func _bones(p: Paint, kind: String, c: Vector2, tn: Color, u: float) -> void:
	var bone := Mat.mul(tn, 1.32, 1.27, 1.12)
	match kind:
		"ribs":  # 갈비뼈 우리
			var spine_a := c + Vector2(-12, 2) * u
			var spine_b := c + Vector2(12, -2) * u
			Decals._stick(p, spine_a, spine_b, 2.2 * u, bone)
			for k in 5:
				var q := spine_a.lerp(spine_b, 0.12 + k * 0.19)
				for sgn: float in [-1.0, 1.0]:
					var m := q + Vector2(-1.5, 5.0 * sgn) * u
					var e := q + Vector2(1.0, 9.0 * sgn) * u
					Ink.line(p, q, m, 1.8 * u, Ink.INK, 0.8, 0.2)
					Ink.line(p, m, e, 1.6 * u, Ink.INK, 0.8, 0.2)
					Ink.line(p, q, m, 1.1 * u, bone, 1.0, 0.2)
					Ink.line(p, m, e, 1.0 * u, bone, 1.0, 0.2)
		"skull":
			_skull(p, c, 1.0 * u, bone)
			Decals._stick(p, c + Vector2(6, 6) * u, c + Vector2(16, 1) * u, 2.0 * u, bone)
		"long":
			for k in 2:
				var d := Vector2.from_angle(p.rng.randf() * TAU)
				var q := c + Vector2(p.rng.randf_range(-4, 4), p.rng.randf_range(-4, 4)) * u
				Decals._stick(p, q - d * 9.0 * u, q + d * 9.0 * u, 2.4 * u, bone)
				for e: float in [-1.0, 1.0]:
					Cave._stone(p, q + d * 9.5 * u * e, 2.3 * u, 1.9 * u, bone)
		"scatter":
			Decals._bones(p, c, u * 0.9)
			for k in 4:
				Cave._stone(p, c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-10, 10)) * u, 1.4 * u, 1.1 * u, bone)
	# 서리가 덮어 반쯤 묻힌다
	var frost := Mat.mul(tn, 1.08, 1.1, 1.14)
	for y in range(int(c.y - 18 * u), int(c.y + 18 * u)):
		for x in range(int(c.x - 18 * u), int(c.x + 18 * u)):
			var n := p.nz("mid", x, y) * 0.7 + p.nz("hi", x, y) * 0.3
			var fall := 1.0 - smoothstep(10.0 * u, 18.0 * u, Vector2(x, y).distance_to(c))
			if n > 0.56:
				p.tint(x, y, frost, clampf((n - 0.56) * 5.0, 0.0, 0.85) * fall)


## 두개골(위에서 본): 둥근 정수리 + 눈구멍 둘 + 코 구멍 + 윗니 줄.
static func _skull(p: Paint, q: Vector2, s: float, bone: Color) -> void:
	Cave._stone(p, q, 6.0 * s, 5.2 * s, bone)
	Cave._stone(p, q + Vector2(0.5, 4.5) * s, 3.6 * s, 2.4 * s, bone.darkened(0.08))
	for sx: float in [-2.2, 2.2]:
		Cave._dot(p, q + Vector2(sx, 1.2) * s, 1.6 * s, Color("#120e0c"), 0.95)
	Cave._dot(p, q + Vector2(0, 3.4) * s, 0.8 * s, Color("#120e0c"), 0.9)
	Ink.line(p, q + Vector2(-2.4, 5.6) * s, q + Vector2(2.6, 5.6) * s, 0.7 * s, Ink.INK, 0.6, 0.2)


## 얼음 조각: 작은 모난 결정 — 빛 쪽 면 밝은 청백, 반대 면 푸른 그늘, 잉크.
static func _shard(p: Paint, q: Vector2, r: float, tn: Color) -> void:
	var a := p.rng.randf() * TAU
	var pts := PackedVector2Array()
	for k in 4:
		pts.append(q + Vector2.from_angle(a + k * TAU / 4.0 + p.rng.randf_range(-0.4, 0.4)) * r * p.rng.randf_range(0.6, 1.1))
	var sh := PackedVector2Array()
	for pt in pts:
		sh.append(pt + Vector2(1.0, 1.2) * r * 0.4)
	p.fill_poly(sh, func(_x: int, _y: int) -> Color: return Color(0.05, 0.07, 0.1, 0.35))
	p.fill_poly(pts, func(x: int, y: int) -> Color:
		var t := clampf(0.5 - (x - q.x) / r * 0.4 - (y - q.y) / r * 0.4, 0.0, 1.0)
		return Mat.mul(tn, 0.9, 1.08, 1.25).lerp(Mat.mul(tn, 1.5, 1.6, 1.62), t))
	Ink.path(p, pts, 0.7 * p.w / 64.0, true, Ink.INK, 0.6, 0.2)
