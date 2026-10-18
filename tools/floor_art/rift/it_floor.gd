extends RefCounted
## 강철의 묘 바닥 재질(it.gd가 부른다): 리벳 강철판 · 어두운 판석 · 해진 붉은 카펫 · 깨진 판석 더미 · 돌계단 · 빛줄기 ·
## 칼날 홈 · 압력판 · 화살 구멍 · 회전 칼날. 바탕은 좌표 함수 + 주기 잡음(Seam)만 — 모든 변형의 가장자리가 같다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const L := preload("res://tools/floor_art/rift/it_lib.gd")


static func base(p: Paint, style: String, col: Color, s: int) -> void:
	match style:
		"steelplates", "arrowtrap":
			_plates(p, col, s, "rect" if style == "steelplates" else "holes")
		"bladegroove":
			_plates(p, col, s, "slot")
		"bladetrap":
			_plates(p, col, s, "slit")
		"flagstone", "pressureplate", "rubble", "sunbeam":
			_flags(p, col, s, style)
		"carpet":
			_carpet(p, col, s)
		"stairs":
			_stairs(p, col, s)
		_:
			for y in p.h:
				for x in p.w:
					p.blend(x, y, col, 1.0)


# ── 강철판(한 칸 = 판 한 장, 가장자리 이음매 + 리벳) ─────────────────────

static func _plates(p: Paint, col: Color, s: int, kind: String) -> void:
	var w := p.w
	var h := p.h
	var u := w / 64.0
	var big := Seam.field(w, h, s, 0.035, 3)
	var fine := Seam.field(w, h, s + 1, 0.22, 2)
	var stain := Seam.field(w, h, s + 2, 0.05, 3)
	var dent := Seam.field(w, h, s + 3, 0.09, 2)
	var rv := 2.2 * u
	var rivets: Array[Vector2] = [Vector2(5, 5), Vector2(59, 5), Vector2(5, 59), Vector2(59, 59)]
	if kind == "rect" or kind == "holes":
		rivets.append_array([Vector2(32, 5), Vector2(32, 59), Vector2(5, 32), Vector2(59, 32)])
	if kind == "slot":
		rivets = [Vector2(19, 8), Vector2(19, 24), Vector2(19, 40), Vector2(19, 56), Vector2(45, 8), Vector2(45, 24), Vector2(45, 40), Vector2(45, 56)]
	for y in h:
		for x in w:
			var i := y * w + x
			var streak := sin((y + big[i] * 14.0) * 1.9 / u) * 0.035  # 가로로 쓸린 결
			var t := 0.5 + (big[i] - 0.5) * 0.55 + (fine[i] - 0.5) * 0.14 + streak + Seam.relief(dent, w, h, x, y, 3.0) * 0.25
			var c := col.darkened(0.38).lerp(col.lightened(0.2), clampf(t, 0.0, 1.0))
			if stain[i] > 0.6:  # 녹·기름 얼룩
				c = c.lerp(L.RUST if big[i] > 0.5 else Color("#1a1c20"), clampf((stain[i] - 0.6) * 1.6, 0.0, 0.45))
			var fx := x + 0.5
			var fy := y + 0.5
			c = L.bevel(c, fx, fy, w - fx, h - fy, 3.0 * u, 1.1 * u)
			match kind:
				"rect":  # 새긴 테두리
					var k := 11.0 * u
					if fx > k - 2 and fx < w - k + 2 and fy > k - 2 and fy < h - k + 2:
						var d := minf(minf(absf(fx - k), absf(fx - (w - k))), minf(absf(fy - k), absf(fy - (h - k))))
						if d < 3.0:
							var sd := fx - k if absf(fx - k) == d else (fx - (w - k) if absf(fx - (w - k)) == d else (fy - k if absf(fy - k) == d else fy - (h - k)))
							c = L.groove(c, sd, 1.3 * u, 0.85)
				"holes":
					for gy: float in [20.0, 32.0, 44.0]:
						for gx: float in [20.0, 32.0, 44.0]:
							var d := Vector2(fx - gx * u, (fy - gy * u) * 1.15).length()
							if d < 3.4 * u:
								c = c.lerp(Ink.INK, clampf(3.4 * u - d, 0.0, 1.0) * 0.9)
								if fy < gy * u:
									c = c.lerp(Color("#050608"), 0.4)
							elif d < 4.8 * u:
								c = c.lightened(0.18) if fy > gy * u + 0.5 else c.darkened(0.2)
				"slot":  # 세로로 지나는 칼날 홈
					var dx := fx - w * 0.5
					var ax := absf(dx)
					if ax < 8.0 * u:
						var g := clampf((dx + 8.0 * u) / (16.0 * u), 0.0, 1.0)
						c = Color("#07080a").lerp(Color("#2a2c32"), pow(g, 3.0) * 0.8)
						if dx > 5.5 * u:  # 서쪽을 보는 안벽 — 빛
							c = c.lerp(col.lightened(0.1), 0.6)
						if ax > 7.2 * u:
							c = c.lerp(Ink.INK, 0.8)
					elif ax < 12.0 * u:  # 칼날에 닳은 반들반들한 테
						var lip := (ax - 8.0 * u) / (4.0 * u)
						c = col.lightened(0.15 + 0.2 * (1.0 - lip)).lerp(c, 0.35)
						if dx < 0.0 and lip < 0.3:
							c = c.lerp(L.LIT, 0.25)
						if ax > 11.4 * u:
							c = c.lerp(Ink.INK, 0.45)
				"slit":  # 칼날이 솟는 가로 틈
					var dy := fy - 46.0 * u
					var ex := absf(fx - w * 0.5)
					if ex < 22.0 * u and absf(dy) < 2.6 * u:
						c = Color("#060708").lerp(Color("#202228"), clampf(dy / (2.6 * u) * 0.5 + 0.5, 0.0, 1.0) * 0.5)
					elif ex < 25.0 * u and absf(dy) < 5.0 * u:
						c = c.lightened(0.16) if dy > 0.0 else c.darkened(0.12)
						if absf(absf(dy) - 5.0 * u) < 0.8 or absf(ex - 25.0 * u) < 0.8:
							c = c.lerp(Ink.INK, 0.5)
			for q in rivets:
				c = L.rivet(c, x, y, q * u, rv)
			p.blend(x, y, c, 1.0)


# ── 판석(어긋나게 쌓은 64×32 판: 위 줄 이음매 = 칸 가장자리, 아래 줄 = 가운데) ────────

static func _flags(p: Paint, col: Color, s: int, style: String) -> void:
	var w := p.w
	var h := p.h
	var u := w / 64.0
	var hf := Seam.field(w, h, s, 0.05, 3)
	var fine := Seam.field(w, h, s + 1, 0.3, 2)
	var st := Seam.field(w, h, s + 2, 0.04, 3)
	var dust := Seam.field(w, h, s + 4, 0.07, 3)
	var bright := style == "sunbeam"
	var dusty := style == "rubble"
	var tone := col
	if bright:
		tone = col.darkened(0.3)
	for y in h:
		for x in w:
			var i := y * w + x
			var fx := x + 0.5
			var fy := y + 0.5
			var half := h * 0.5
			var row := 0 if fy < half else 1
			var ly := fy - row * half
			var lx := fx if row == 0 else fposmod(fx + w * 0.5, float(w))
			var slab_t := -0.04 if row == 0 else 0.04
			var t := 0.48 + slab_t + (hf[i] - 0.5) * 0.4 + Seam.relief(hf, w, h, x, y, 5.0) * 0.4 + (fine[i] - 0.5) * 0.12
			if bright:
				t = 0.6 + (hf[i] - 0.5) * 0.32 + Seam.relief(hf, w, h, x, y, 4.0) * 0.22 + (fine[i] - 0.5) * 0.08
			var c := tone.darkened(0.42).lerp(tone.lightened(0.25), clampf(t, 0.0, 1.0))
			if st[i] > 0.6 and not bright:  # 스민 얼룩
				c = c.lerp(Color("#16181c"), (st[i] - 0.6) * 1.2)
			var seam := 1.0 * u
			c = c.lerp(L.bevel(c, lx, ly, w - lx, half - ly, 2.5 * u, seam), 0.3 if bright else 0.65)
			if bright:  # 먼지 속 빛 — 비스듬한 띠(칸 주기)
				var band := sin(TAU * (fx + fy) / w + 0.6) * 0.5 + 0.5
				c = c.lerp(Color("#dce6f0"), 0.1 + band * 0.12)
			if dusty or style == "pressureplate":
				var dd := clampf((dust[i] - 0.35) * 1.6, 0.0, 1.0) * (0.55 if dusty else 0.25)
				c = c.lerp(Color("#9a9a98"), dd)
			if style == "pressureplate":
				c = _plate_px(c, fx, fy, w, u)
			p.blend(x, y, c, 1.0)


## 압력판: 가운데 살짝 솟은 네모 판(왼쪽 위 빛, 아래쪽 두께 + 그림자).
static func _plate_px(c: Color, fx: float, fy: float, w: int, u: float) -> Color:
	var a := 17.0 * u
	var b := w - 17.0 * u
	var lift := 2.5 * u
	var top_b := b - lift
	if fx > a and fx < b and fy > a - lift and fy < top_b:
		var pc := Color("#5c6268").lerp(c, 0.35)
		pc = L.bevel(pc, fx - a, fy - (a - lift), b - fx, top_b - fy, 2.5 * u, 0.9 * u)
		var cd := Vector2(fx - w * 0.5, fy - (a - lift + top_b) * 0.5).length()
		pc = L.groove(pc, cd - 11.0 * u, 1.0 * u, 0.5)
		return pc
	if fx > a and fx < b and fy >= top_b and fy < b:  # 판의 앞 두께
		return Color("#24262a").lerp(c, 0.2).lerp(Ink.INK, 0.3 if fy > b - 1.0 else 0.0)
	if fx > a + 2.0 * u and fx < b + 2.5 * u and fy >= b and fy < b + 2.5 * u:
		return c.darkened(0.35)
	if fx >= b and fx < b + 2.5 * u and fy > a and fy < b:
		return c.darkened(0.3)
	return c


# ── 카펫(붉은 바탕 + 주기 마름모 무늬 — 칸끼리 이어진다) ──────────────────

static func _carpet(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var u := w / 64.0
	var wear := Seam.field(w, h, s, 0.04, 3)
	var pile := Seam.field(w, h, s + 1, 0.35, 2)
	var dirt := Seam.field(w, h, s + 2, 0.06, 3)
	var gold := Color("#8a7038")
	for y in h:
		for x in w:
			var i := y * w + x
			var fx := x + 0.5
			var fy := y + 0.5
			var weave := (sin(fx * 2.4 / u) * sin(fy * 2.4 / u)) * 0.04 + (sin(fy * 1.2 / u) * 0.02)
			var t := 0.5 + (pile[i] - 0.5) * 0.4 + weave * 1.5 + (wear[i] - 0.5) * 0.45
			var c := col.darkened(0.62).lerp(col.lightened(0.08), clampf(t, 0.0, 1.0))
			# 마름모 격자(칸 가장자리 가운데를 잇는 마름모) — 겹 금실
			var dm := absf(fx - w * 0.5) + absf(fy - h * 0.5)
			var r1 := absf(dm - w * 0.5)
			if r1 < 3.4 * u:
				c = c.darkened(0.22)
			if absf(r1 - 2.0 * u) < 0.7 * u:
				c = c.lerp(gold, 0.32)
			# 가운데·모서리 네잎 무늬
			var q := Vector2(fx - w * 0.5, fy - h * 0.5)
			for cc: Vector2 in [q, Vector2(fposmod(fx + w * 0.5, w) - w * 0.5, fposmod(fy + h * 0.5, h) - h * 0.5)]:
				var ang := atan2(cc.y, cc.x)
				var rr := cc.length() / u
				var petal := 5.5 + 2.5 * cos(ang * 4.0)
				if rr < petal:
					c = c.lerp(gold.darkened(0.2), 0.3 * clampf(petal - rr, 0.0, 1.0))
					if rr < 2.0:
						c = c.lerp(Color("#3a0a0c"), 0.6)
				elif absf(rr - petal - 1.2) < 0.8:
					c = c.darkened(0.25)
			var worn := clampf((wear[i] - 0.62) * 2.2, 0.0, 1.0)  # 닳아 실이 드러난 곳
			c = c.lerp(Color("#4a3430"), worn * 0.75)
			if dirt[i] > 0.6:
				c = c.lerp(Color("#3a3634"), (dirt[i] - 0.6) * 1.0)
			p.blend(x, y, c, 1.0)


# ── 돌계단(한 칸 = 4단, 디딤판 + 남쪽 챌판) ─────────────────────────────

static func _stairs(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var u := w / 64.0
	var hf := Seam.field(w, h, s, 0.06, 3)
	var fine := Seam.field(w, h, s + 1, 0.3, 2)
	var period := 16.0 * u
	for y in h:
		for x in w:
			var i := y * w + x
			var fx := x + 0.5
			var fy := y + 0.5
			var k := int(fy / period)
			var ly := fmod(fy, period)
			var tread := 11.0 * u
			var t := 0.5 + (hf[i] - 0.5) * 0.6 + Seam.relief(hf, w, h, x, y, 5.0) * 0.45 + (fine[i] - 0.5) * 0.16
			var c: Color
			if ly < tread:
				c = col.darkened(0.2).lerp(col.lightened(0.22), clampf(t, 0.0, 1.0))
				c = c.darkened(0.15 * (1.0 - ly / tread))  # 윗단 쪽은 그늘
				var mid := 1.0 - absf(fx - w * 0.5) / (w * 0.5)
				c = c.lightened(0.08 * mid * mid)  # 가운데가 닳아 반들반들
				if ly > tread - 2.0 * u:  # 둥근 코 — 빛
					c = c.lerp(L.LIT, 0.18)
				if ly < 1.5 * u:  # 윗단 챌판 밑 그늘
					c = c.darkened(0.3)
			else:
				var rt := (ly - tread) / (period - tread)
				c = col.darkened(0.5 - rt * 0.15).lerp(col.darkened(0.3), clampf(t - 0.3, 0.0, 1.0))
				if ly < tread + 1.0 * u:
					c = c.lerp(Ink.INK, 0.75)
			var jx := 0.0 if k % 2 == 0 else w * 0.5  # 단마다 어긋난 돌 이음매
			var dj := minf(absf(fx - jx), absf(fx - jx - w))
			if jx == 0.0:
				dj = minf(fx, w - fx)
			if dj < 1.0 * u:
				c = c.lerp(Ink.INK, 0.6 * (1.0 - dj / u))
			elif dj < 2.5 * u and fx > jx:
				c = c.lightened(0.08)
			p.blend(x, y, c, 1.0)
