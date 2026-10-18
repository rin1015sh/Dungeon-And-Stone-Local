extends RefCounted
## 핏빛성채 벽 재질(bf.gd가 부른다): 윗면(위에서 본 성벽 길·지붕·기둥 머리)과 남쪽 앞면(가로로만 이어짐, 아래 밑동은 들쭉날쭉 투명).
## 짜인 무늬(돌 쌓기·목골·기둥 홈·판자)는 고정 배치, 결·얼룩만 시드로 — 변형끼리 가장자리가 맞는다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Common := preload("res://tools/floor_art/rift/Common.gd")
const K := preload("res://tools/floor_art/rift/bf_kit.gd")

const TOP_CUTS := [[0, 24], [40, 8], [16, 52]]
const ASHLAR := [[0, 36], [18, 50], [6, 40]]
const SMALL := [[0, 32], [16, 48], [0, 32], [16, 48], [0, 32], [16, 48]]

const KINDS := {
	"masonry_top": ["plain", "moss", "crack", "plain", "stain", "moss"],
	"masonry_face": ["plain", "drip", "crack", "chain", "drip", "plain"],
	"house_top": ["plain", "patch", "moss", "plain", "broken", "patch"],
	"house_face": ["window", "brace", "post", "window", "cross", "lath"],
	"pillar_top": ["plain", "crack", "plain", "stain", "plain", "crack"],
	"pillar_face": ["plain", "drip", "chip", "drip", "carve", "plain"],
	"stainedglass_top": ["plain", "crack", "plain", "stain", "plain", "plain"],
	"stainedglass_face": ["rose", "lancet", "rose", "broken", "lancet", "rose"],
	"gate_top": ["plain", "plain", "nails", "plain", "nails", "plain"],
	"gate_face": ["ring", "plain", "hand", "arrow", "ring", "split"],
}


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if part == "top":
		_top(p, style, col, s)
	else:
		_face(p, style, col, s)


# ── 윗면 ─────────────────────────────────────────────

static func _top(p: Paint, style: String, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.09, 3)
	var st := Seam.field(w, h, s + 1, 0.04, 2)
	var jx := Seam.field(w, h, 81, 0.08, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var c: Color
			match style:
				"house":  # 기와(가로 줄, 아래 끝이 둥근 비늘)
					var row := int(y / 8.0)
					var fx := posmod(x + (row % 2) * 6.0, 12.0)
					var fy := posmod(float(y), 8.0)
					var bulge := sqrt(maxf(0.0, 1.0 - pow((fx - 6.0) / 6.0, 2.0)))
					var t := 0.35 + fy / 8.0 * 0.4 * bulge + (1.0 - fx / 12.0) * 0.15 + (hf[i] - 0.5) * 0.3 + (Paint.hash01(row, int((x + (row % 2) * 6) / 12), 2) - 0.5) * 0.3
					c = col.darkened(0.5).lerp(col.lightened(0.45).lerp(Color("#6a2a20"), 0.3), clampf(t, 0.0, 1.0))
					if fy > 6.6 * bulge + 0.6 or fx < 0.8:
						c = c.lerp(K.INK, 0.7)
				"gate":  # 두꺼운 들보(가로 나뭇결)
					var g := sin(y * 1.3 + hf[i] * 6.0) * 0.5 + 0.5
					var t := 0.45 + (g - 0.5) * 0.25 + Seam.relief(hf, w, h, x, y, 3.0) * 0.3
					c = col.darkened(0.4).lerp(col.lightened(0.35), clampf(t, 0.0, 1.0))
					var fy := posmod(float(y), 21.333)
					if fy < 1.2:
						c = c.lerp(K.INK, 0.75)
				_:  # 성벽 길 판석(성벽·기둥·창 벽)
					var q := K.slab(x + (jx[i] - 0.5) * 5.0, y, w, [0, 21, 43], TOP_CUTS, 4.0)
					var tone := Paint.hash01(int(q.y), 4, 1)
					var t := 0.45 + Seam.relief(hf, w, h, x, y, 5.0) * 0.45 + (tone - 0.5) * 0.3 + q.z * 0.25
					var cc := col
					if style == "pillar":  # 기둥 머리: 줄기 둘의 둥근 윗면(16·48 px)
						var u := absf(x + 0.5 - (16.0 if x < 32 else 48.0)) / 15.0
						t = 0.42 + Seam.relief(hf, w, h, x, y, 5.0) * 0.4 + (hf[i] - 0.5) * 0.2 - pow(u, 3.0) * 0.3
						q.x = 9.0 if u < 1.0 else 0.0
					c = cc.darkened(0.45).lerp(cc.lightened(0.4), clampf(t, 0.0, 1.0))
					if q.x < 1.3:
						c = c.lerp(K.INK, 0.8)
					if style == "stainedglass":  # 창에서 새는 붉은 빛
						c = c.lerp(Color("#6a1a1a"), clampf((y / float(h)) * 0.5, 0.0, 0.5))
			if st[i] > 0.62:
				c = c.lerp(Color("#1a1210"), (st[i] - 0.62) * 1.2)
			p.blend(x, y, c, 1.0)


# ── 앞면 ─────────────────────────────────────────────

static func _face(p: Paint, style: String, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var main := float(h - Common.skirt)
	var hf := Seam.field(w, h, s, 0.08, 3)
	var st := Seam.field(w, h, s + 1, 0.05, 2)
	var vs := Seam.field(w, h, s + 3, 0.04, 2)
	var jag := Seam.field(w, 8, s + 9, 0.1, 3)
	var lip := Seam.field(w, 8, s + 5, 0.12, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := main + (0.25 + jag[x] * 0.75) * Common.skirt
			if y >= foot:
				continue
			var t := 0.5 + Seam.relief(hf, w, h, x, y, 4.0) * 0.4 + (hf[i] - 0.5) * 0.2
			var c: Color
			match style:
				"masonry", "stainedglass":
					var q: Vector3
					if style == "masonry":
						q = K.slab(x, y - 3.0, w, [0, 21, 43], ASHLAR, 4.0)
					else:
						q = K.slab(x, y - 3.0, w, [0, 11, 21, 32, 43, 53], SMALL, 3.0)
					var tone := Paint.hash01(int(q.y), int(floor((y - 3.0) / 64.0)), 9)
					t += (tone - 0.5) * 0.3 + q.z * 0.3
					c = col.darkened(0.55).lerp(col.lightened(0.3), clampf(t, 0.0, 1.0))
					if style == "stainedglass":
						c = Color("#140a0c").lerp(Color("#4a2a2e"), clampf(t, 0.0, 1.0))
					if q.x < 1.3:
						c = c.lerp(K.INK, 0.8)
					elif q.x < 2.5:
						c = c.darkened(0.25)
					if style == "stainedglass":
						c = _glass(x, y, main, c, hf[i])
				"house":
					c = _house(x, y, main, col, t, hf[i])
				"pillar":
					c = _pillar(x, y, main, col, t, hf[i])
				"gate":
					c = _gate(x, y, main, col, t, hf[i])
				_:
					c = col
			# 공통: 흘러내린 때 · 바닥 쪽 그늘 · 턱 · 밑동 잉크
			if st[i] > 0.6:
				c = c.lerp(Color("#1a100e"), (st[i] - 0.6) * 1.1)
			c = c.darkened(clampf((vs[i] - 0.55) * 0.8, 0.0, 0.25) * float(y) / main)
			c = c.darkened(smoothstep(main * 0.6, foot, float(y)) * 0.35)
			var ly := 2.0 + lip[x] * 3.0
			if y < ly:
				c = c.lightened(0.22)
			elif absf(y - ly) < 1.4:
				c = c.lerp(K.INK, 0.75)
			if foot - y < 1.6 and Common.skirt > 0:
				c = c.lerp(K.INK, 0.6)
			p.blend(x, y, c, 1.0)


## 목골 집: 위·아래 들보 + 가장자리 기둥(칸 경계) + 회벽 + 아래 돌 기단.
static func _house(x: int, y: int, main: float, col: Color, t: float, hf: float) -> Color:
	var plaster := Color("#8a7c68").lerp(col, 0.45)
	var timber := Color("#2a1c16")
	var c := plaster.darkened(0.35).lerp(plaster.lightened(0.15), clampf(t + (hf - 0.5) * 0.3, 0.0, 1.0))
	var plinth := main - 12.0
	var beams := [Vector2(6.0, 12.0), Vector2(plinth - 7.0, plinth - 1.0)]
	var dx := minf(float(x), 63.0 - x)
	for b: Vector2 in beams:
		if y >= b.x and y < b.y:
			c = timber.lerp(timber.lightened(0.3), clampf(t - (y - b.x) / (b.y - b.x) * 0.4 + 0.1, 0.0, 1.0))
			if y < b.x + 1.0:
				c = c.lightened(0.15)
	if dx < 3.5 and y >= 6.0 and y < plinth:  # 칸 경계 기둥
		c = timber.lerp(timber.lightened(0.3), clampf(t + (0.2 if x < 32 else -0.2), 0.0, 1.0))
		if dx < 0.8:
			c = c.lerp(K.INK, 0.7)
	if y >= plinth:  # 돌 기단
		var fy := posmod(y - plinth, 6.0)
		var fx := posmod(x + (int((y - plinth) / 6.0) % 2) * 10.0, 20.0)
		c = Color("#4a3c38").darkened(0.2).lerp(Color("#6a5a52"), clampf(t, 0.0, 1.0))
		if fy < 1.0 or fx < 1.0:
			c = c.lerp(K.INK, 0.7)
	if y < 6.0:  # 처마 그늘
		c = Color("#1a1210").lerp(timber, float(y) / 6.0)
	return c


## 묶음 기둥: 칸마다 원통 줄기 둘(16·48 px), 사이 골은 깊게. 줄기마다 오목한 세로 홈 넷, 위 머리 띠 · 가운데 고리 · 아래 받침, 밑은 핏빛.
static func _pillar(x: int, y: int, main: float, col: Color, t: float, hf: float) -> Color:
	var cx := 16.0 if x < 32 else 48.0
	var r := 13.5
	var bands := [Vector2(3.0, 13.0), Vector2(main * 0.48 - 3.0, main * 0.48 + 3.0), Vector2(main - 16.0, main)]
	var band := -1
	for k in bands.size():
		var b: Vector2 = bands[k]
		if y >= b.x and y < b.y:
			band = k
	if band >= 0:
		r = 15.8 if band != 1 else 15.0
	var u := (x + 0.5 - cx) / r
	if absf(u) > 1.0:  # 줄기 사이 골
		return Color("#0a0606").lerp(Color("#3a0a0a"), smoothstep(main * 0.5, main, float(y)) * 0.6)
	var nx := u  # 원통 표면 법선(가로)
	var lit := clampf(0.55 - nx * 0.75, 0.0, 1.0)  # 왼쪽이 밝다
	var shade := 0.18 + lit * 0.62 - pow(absf(u), 6.0) * 0.3
	if band < 0:  # 오목한 홈: 홈 안쪽 왼벽은 그늘, 오른벽은 빛
		var ph := posmod((u + 1.0) * 2.0, 1.0)
		shade += (ph - 0.5) * 0.45 * (1.0 - absf(u) * 0.7)
		if ph < 0.12 or ph > 0.9:
			shade -= 0.25
	else:
		var b: Vector2 = bands[band]
		var fy := (y - b.x) / (b.y - b.x)
		shade += 0.3 if fy < 0.25 else (-0.3 if fy > 0.7 else 0.05)
	shade += (hf - 0.5) * 0.2 + (t - 0.5) * 0.5
	var c := Color("#0e0809").lerp(Color("#6e5052"), clampf(shade, 0.0, 1.0))
	var red := smoothstep(main * 0.45, main, float(y))
	c = c.lerp(Color("#6a1012"), red * 0.6)
	if u > 0.6:  # 오른쪽 가장자리에 붉은 창빛
		c = c.lerp(Color("#9a2018"), (u - 0.6) * 1.3)
	if absf(u) > 0.9:
		c = c.lerp(K.INK, (absf(u) - 0.9) * 8.0)
	return c


## 붉게 빛나는 뾰족 아치 창(앞면 거의 전체 — 칸 사이는 좁은 돌 기둥): 돌 테 → 붉은 유리 조각 · 납 선 · 가운데 문설주.
static func _glass(x: int, y: int, main: float, stone: Color, hf: float) -> Color:
	var x0 := 7.0
	var ww := 50.0
	var y0 := 4.0
	var yb := main - 6.0
	var ys := y0 + ww * 0.866
	var fx := x + 0.5
	var fy := y + 0.5
	var d := minf(minf(fx - x0, x0 + ww - fx), yb - fy)
	if fy < ys:
		d = minf(d, minf(ww - Vector2(fx, fy).distance_to(Vector2(x0 + ww, ys)), ww - Vector2(fx, fy).distance_to(Vector2(x0, ys))))
	if d < -3.5:
		return stone
	if d <= 0.0:  # 돌 테(깎은 몰딩 — 바깥은 밝고 안쪽은 그늘)
		var m := Color("#3a2226").lerp(Color("#6a4448"), clampf(1.0 + d / 3.5, 0.0, 1.0) * 0.8)
		return m.lerp(K.INK, 0.8) if d > -0.9 or d < -3.0 else m
	var pw := ww / 6.0
	var colx := int((fx - x0) / pw)
	var row := int((fy - y0 + (colx % 2) * 3.5) / 7.0)
	var hsh := Paint.hash01(colx, row, 31)
	var c := Color("#b01410").lerp(Color("#ff3a24"), hsh)
	if hsh > 0.92:
		c = Color("#ff8a3a")  # 호박빛 조각
	elif hsh < 0.18:
		c = Color("#6a0812")  # 짙은 진홍
	var glow := clampf(1.0 - absf(fx - 32.0) / 30.0, 0.0, 1.0) * clampf(1.0 - absf(fy - main * 0.55) / main, 0.0, 1.0)
	c = c.lightened(glow * 0.18 + (hf - 0.5) * 0.1)
	if d < 1.2 or posmod(fx - x0, pw) < 0.9 or posmod(fy - y0 + (colx % 2) * 3.5, 7.0) < 0.9:
		c = Color("#1a0606")  # 납 선
	if absf(fx - 32.0) < 1.8 and fy > y0 + 6.0:
		c = Color("#2a1416").lerp(Color("#4a2a2c"), clampf(32.0 - fx, 0.0, 1.0))  # 문설주
	return c


## 쇠테를 두른 나무 문: 세로 판자(64/6) + 가로 쇠띠 둘 + 징.
static func _gate(x: int, y: int, main: float, col: Color, t: float, hf: float) -> Color:
	var pw := 64.0 / 6.0
	var fx := posmod(float(x), pw)
	var k := int(x / pw)
	var grain := sin(y * 0.35 + hf * 8.0 + k * 2.1) * 0.5 + 0.5
	var shade := 0.45 + (grain - 0.5) * 0.25 + (Paint.hash01(k, 3, 4) - 0.5) * 0.3 + (t - 0.5) * 0.4
	shade += 0.12 if fx < 2.0 else (-0.15 if fx > pw - 2.5 else 0.0)
	var c := col.darkened(0.45).lerp(col.lightened(0.35), clampf(shade, 0.0, 1.0))
	if fx < 0.9:
		c = c.lerp(K.INK, 0.75)
	for by: float in [main * 0.18, main * 0.68]:
		var dy := y - by
		if dy >= 0.0 and dy < 7.0:
			c = K.IRON.lerp(K.RUST, clampf(hf * 1.4 - 0.3, 0.0, 0.7)).lightened(0.25 if dy < 1.5 else (-0.3 if dy > 5.0 else 0.0))
			var sx := posmod(float(x) + 4.0, 10.6667)
			var stud := Vector2(sx - 5.33, dy - 3.5).length()
			if stud < 2.2:
				c = K.IRON.lightened(0.35 - stud * 0.2) if (sx < 5.33 and dy < 3.5) else K.IRON.darkened(0.3)
			if dy >= 6.0:
				c = c.lerp(K.INK, 0.7)
		elif dy >= 7.0 and dy < 9.0:
			c = c.darkened(0.35)
	return c


# ── 잔손질 ───────────────────────────────────────────

static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	var key := style + "_" + part
	var kinds: Array = KINDS.get(key, ["plain"])
	var kind := str(kinds[v % kinds.size()])
	var s := p.w / 64.0
	var main := float(p.h - Common.skirt) if part == "face" else float(p.h)
	var c := Vector2(p.w * 0.5, main * 0.5)
	match key + ":" + kind:
		"masonry_top:moss", "house_top:moss":
			for k in 3:
				Decals._blob(p, c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-14, 14)) * s, p.rng.randf_range(4, 7) * s, Color("#2a3220"), 0.55, 0.45)
		"masonry_top:crack", "pillar_top:crack", "stainedglass_top:crack", "masonry_face:crack":
			var st := c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-12, 0)) * s
			Cave._crack(p, st, p.rng.randi_range(3, 5), 6.0 * s, Vector2(p.rng.randf_range(-0.4, 0.4), 1.0))
		"masonry_top:stain", "pillar_top:stain", "stainedglass_top:stain":
			K.stain(p, c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * s, 8.0 * s, 0.5)
		"masonry_face:drip", "pillar_face:drip":
			for k in p.rng.randi_range(2, 3):
				var x := p.rng.randf_range(0.22, 0.78) * p.w
				var y0 := p.rng.randf_range(0.0, 0.3) * main
				var ln := p.rng.randf_range(0.4, 0.8) * main
				Ink.line(p, Vector2(x, y0), Vector2(x + p.rng.randf_range(-1, 1), y0 + ln), 2.2 * s, Color("#4a0608"), 0.75, 0.6)
				Ink.line(p, Vector2(x - 0.5, y0), Vector2(x - 0.5, y0 + ln * 0.8), 0.7 * s, Color("#a02018"), 0.5, 0.6)
				Cave._dot(p, Vector2(x, y0 + ln), 1.6 * s, Color("#4a0608"), 0.85)
		"masonry_face:chain":
			var a := Vector2(p.w * 0.5, main * 0.25)
			Cave._dot(p, a, 2.5 * s, K.IRON.lightened(0.2), 0.95)
			for k in 5:
				Ink.path(p, Cave._ellipse(a + Vector2(0, 3.5 + k * 3.6) * s, 1.4 * s, 2.2 * s, 10), 1.0 * s, true, Color("#6a6468"), 0.9, 0.2)
		"house_top:patch":
			Decals._blob(p, c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-8, 8)) * s, 9.0 * s, Color("#1a1210"), 0.4, 0.4)
		"house_top:broken":
			var q := c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * s
			p.fill_poly(Cave._ellipse(q, 9.0 * s, 6.0 * s, 14, p.rng), func(_x: int, _y: int) -> Color: return Color("#0c0808"))
			for k in 3:
				Ink.line(p, q + Vector2(-8 + k * 6, -4) * s, q + Vector2(-6 + k * 6, 5) * s, 1.6 * s, K.WOOD_DARK, 0.9, 0.4)
		"house_face:window":
			_shutter(p, Vector2(p.w * 0.5, main * 0.42), s, v)
		"house_face:brace", "house_face:cross":
			var top := 12.0
			var bot := main - 19.0
			var pairs := [[Vector2(10, bot), Vector2(32, top)], [Vector2(32, top), Vector2(54, bot)]] if kind == "brace" else [[Vector2(10, top), Vector2(54, bot)], [Vector2(10, bot), Vector2(54, top)]]
			for pr: Array in pairs:
				var a: Vector2 = pr[0]
				var b: Vector2 = pr[1]
				Ink.line(p, a * Vector2(s, 1), b * Vector2(s, 1), 5.6 * s, K.INK, 0.9, 0.3)
				Ink.line(p, a * Vector2(s, 1), b * Vector2(s, 1), 4.2 * s, Color("#3a2a20"), 1.0, 0.3)
				Ink.line(p, a * Vector2(s, 1) + Vector2(-1, -1), b * Vector2(s, 1) + Vector2(-1, -1), 1.0 * s, Color("#6a5040"), 0.6, 0.3)
		"house_face:post":
			for x: float in [p.w * 0.5]:
				p.fill_rect(x - 3.0 * s, 12.0, 6.0 * s, main - 31.0, func(xx: int, yy: int) -> Color: return p.vary(Color("#2e2018").lightened(0.15 if xx < x else 0.0), xx, yy, 0.1))
				Ink.line(p, Vector2(x - 3.0 * s, 12), Vector2(x - 3.0 * s, main - 19.0), 1.0 * s, K.INK, 0.8, 0.3)
				Ink.line(p, Vector2(x + 3.0 * s, 12), Vector2(x + 3.0 * s, main - 19.0), 1.2 * s, K.INK, 0.8, 0.3)
			Ink.grime(p, 10.0 * s, main - 19.0, 44.0 * s, 8.0, 0.4)
		"house_face:lath":
			var q := Vector2(p.w * 0.5 + p.rng.randf_range(-6, 6) * s, main * 0.5)
			var poly := Cave._ellipse(q, 11.0 * s, 9.0, 14, p.rng)
			p.fill_poly(poly, func(_x: int, _y: int) -> Color: return Color("#1e1410"))
			for k in 5:
				Ink.line(p, q + Vector2(-10, -7 + k * 3.5) * Vector2(s, 1), q + Vector2(10, -7 + k * 3.5) * Vector2(s, 1), 1.2, Color("#5a4232"), 0.85, 0.5)
			Ink.path(p, poly, 1.2 * s, true, K.INK, 0.8, 0.5)
		"pillar_face:chip":
			for k in 2:
				var q := Vector2(p.rng.randf_range(0.25, 0.75) * p.w, p.rng.randf_range(0.2, 0.8) * main)
				Cave._pit(p, q, 3.0 * s)
		"pillar_face:carve":  # 줄기마다 새긴 해골 문양 띠
			for cx: float in [16.0, 48.0]:
				var q := Vector2(cx * s, main * 0.5)
				K.skull(p, q, s * 0.9, col.lightened(0.25))
		"stainedglass_face:rose", "stainedglass_face:lancet", "stainedglass_face:broken":
			_window(p, main, s, kind)
		"gate_face:ring":
			var q := Vector2(p.w * (0.3 if v % 2 == 0 else 0.7), main * 0.45)
			Cave._dot(p, q, 3.5 * s, K.IRON, 0.95)
			Ink.path(p, Cave._ellipse(q + Vector2(0, 6) * s, 5.0 * s, 6.0 * s, 18), 1.8 * s, true, Color("#5a5658"), 0.95, 0.2)
			Ink.path(p, Cave._ellipse(q + Vector2(-0.6, 5.4) * s, 5.0 * s, 6.0 * s, 18), 0.6 * s, true, Color("#9a9498"), 0.5, 0.2)
		"gate_face:hand":
			var q := Vector2(p.w * 0.5 + p.rng.randf_range(-8, 8) * s, main * 0.45)
			Decals._blob(p, q, 4.0 * s, Color("#4a0608"), 0.8, 0.3)
			for k in 4:
				Ink.line(p, q + Vector2(-3 + k * 2, -2) * s, q + Vector2(-4 + k * 2.6, -9) * s, 1.6 * s, Color("#4a0608"), 0.8, 0.3)
			Ink.line(p, q + Vector2(0, 3) * s, q + Vector2(1, 16) * s, 1.4 * s, Color("#4a0608"), 0.6, 0.5)
		"gate_face:arrow":
			var q := Vector2(p.w * 0.45, main * 0.4)
			Ink.line(p, q, q + Vector2(14, 6) * s, 1.6 * s, Color("#5a4630"), 0.95, 0.2)
			for k in 3:
				Ink.line(p, q + Vector2(11 + k * 1.2, 5 + k * 0.5) * s, q + Vector2(14 + k * 1.2, 1 + k * 0.5) * s, 0.9 * s, Color("#9a9080"), 0.8, 0.2)
			Cave._pit(p, q, 1.4 * s)
		"gate_face:split":
			var x := p.w * 0.5 + p.rng.randf_range(-6, 6) * s
			Ink.line(p, Vector2(x, main * 0.3), Vector2(x + 3 * s, main * 0.62), 1.6 * s, K.INK, 0.9, 1.2)
			Ink.line(p, Vector2(x - 1, main * 0.3), Vector2(x + 2 * s, main * 0.62), 0.6 * s, Color("#8a6a4a"), 0.5, 1.2)
		"gate_top:nails":
			for k in 6:
				Cave._dot(p, Vector2(p.rng.randf_range(0.2, 0.8) * p.w, p.rng.randf_range(0.2, 0.8) * main), 1.3 * s, K.IRON.lightened(0.2), 0.9)
		_:
			if part == "top":
				Cave._brush(p, 0.06)


## 덧문 달린 작은 창(어두운 창 구멍 + 반쯤 열린 덧문 판자).
static func _shutter(p: Paint, q: Vector2, s: float, v: int) -> void:
	var ww := 14.0 * s
	var wh := 18.0 * s
	var hole := Paint.rect_poly(q.x - ww * 0.5, q.y - wh * 0.5, ww, wh)
	p.fill_poly(hole, func(_x: int, _y: int) -> Color: return Color("#0a0606"))
	if v % 2 == 0:  # 희미한 붉은 불빛
		Ink.glow(p, q.x, q.y + 2, 9.0 * s, Color("#a03018"), 0.35)
	Ink.line(p, Vector2(q.x, q.y - wh * 0.5), Vector2(q.x, q.y + wh * 0.5), 1.4 * s, Color("#2a1c16"), 0.95, 0.2)
	for sd: float in [-1.0, 1.0]:  # 덧문
		var x0 := q.x + sd * ww * 0.5
		var poly := PackedVector2Array([Vector2(x0, q.y - wh * 0.5), Vector2(x0 + sd * 8.0 * s, q.y - wh * 0.5 - 1.5), Vector2(x0 + sd * 8.0 * s, q.y + wh * 0.5 + 1.5), Vector2(x0, q.y + wh * 0.5)])
		p.fill_poly(poly, func(x: int, y: int) -> Color: return p.vary(Color("#3e2c20").lightened(0.1 if sd < 0 else -0.1), x, y, 0.12))
		for k in 3:
			var yy := q.y - wh * 0.5 + (k + 0.5) * wh / 3.0
			Ink.line(p, Vector2(x0, yy), Vector2(x0 + sd * 8.0 * s, yy), 0.7 * s, K.INK, 0.6, 0.2)
		Ink.path(p, poly, 1.1 * s, true, K.INK, 0.85, 0.3)
	Ink.path(p, hole, 1.3 * s, true, K.INK, 0.9, 0.3)
	Ink.line(p, Vector2(q.x - ww * 0.6, q.y + wh * 0.5 + 1.5), Vector2(q.x + ww * 0.6, q.y + wh * 0.5 + 1.5), 2.4 * s, Color("#4a3c34"), 0.95, 0.2)


## 창 잔손질: 장미창(둥근 테 + 꽃잎 살) · 긴 창(가로 돌살) · 깨진 조각, 창 아래로 번진 붉은 빛.
static func _window(p: Paint, main: float, s: float, kind: String) -> void:
	var cx := p.w * 0.5
	match kind:
		"rose":
			var rq := Vector2(cx, 4.0 + 50.0 * 0.5)
			p.fill_poly(Cave._ellipse(rq, 11.0 * s, 11.0 * s, 28), func(x: int, y: int) -> Color:
				var d := Vector2(x, y).distance_to(rq) / (11.0 * s)
				return Color("#ff9a50").lerp(Color("#c01c14"), d))
			Ink.path(p, Cave._ellipse(rq, 11.0 * s, 11.0 * s, 28), 2.4 * s, true, Color("#2a1416"), 0.95, 0.2)
			for k in 8:
				var a := TAU * k / 8.0
				Ink.line(p, rq, rq + Vector2(cos(a), sin(a)) * 11.0 * s, 1.3 * s, Color("#2a1416"), 0.9, 0.2)
			Cave._dot(p, rq, 2.4 * s, Color("#ffd090"), 0.95)
		"lancet":
			for yy: float in [main * 0.42, main * 0.7]:
				Ink.line(p, Vector2(7.0 * s, yy), Vector2(57.0 * s, yy), 2.6 * s, Color("#2a1416"), 0.95, 0.2)
				Ink.line(p, Vector2(7.0 * s, yy - 1.2), Vector2(57.0 * s, yy - 1.2), 0.7 * s, Color("#6a4448"), 0.7, 0.2)
		"broken":
			var q := Vector2(cx + 9.0 * s, main * 0.62)
			var hole := PackedVector2Array([q + Vector2(-6, -7) * s, q + Vector2(5, -9) * s, q + Vector2(8, 2) * s, q + Vector2(-2, 8) * s, q + Vector2(-7, 1) * s])
			p.fill_poly(hole, func(_x: int, _y: int) -> Color: return Color("#100406"))
			Ink.path(p, hole, 1.0 * s, true, Color("#ff8a5a"), 0.5, 0.6)
	Ink.glow(p, cx, main * 0.55, 30.0 * s, Color("#ff4a20"), 0.12)
