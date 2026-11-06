extends RefCounted
## 2층 고블린 숲 그림(A5 — Common.gd 계약, docs/plans/floor2.md §5 · §13-3, FL21). 팔레트 = 짙은 초록 + 별빛 은색(§8)을
## 망자의 땅 리텍스처(FL20)처럼 채도를 눌러: 검은 흙 위 낙엽 · 이끼, 다져진 오솔길(뿌리 · 자갈), 빈터 풀(이슬 은빛),
## 고블린 마을 짓밟힌 진창(짚 · 뼈), 덫 셋(올가미 · 가린 구덩이 · 말뚝)이 박힌 오솔길. 서 있는 소품 = 나무 · 덤불 · 그루터기 ·
## 쓰러진 통나무 · 버섯 · 고블린 토템 · 포탈 비석(룬이 빛남) · 돌덩이 비석 · 고블린 말뚝 울타리.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const BF := preload("res://tools/floor_art/rift/bf.gd")
const F2D := preload("res://tools/floor_art/rift/f2d.gd")

const LOAM := Color("#24261f")
const LEAF_D := Color("#232c22")
const LEAF := Color("#36442f")
const LEAF_L := Color("#56664a")
const MOSS := Color("#3e4c38")
const LITTER := Color("#5a4c36")
const BARK := Color("#352d26")
const BARK_L := Color("#5c5044")
const ROOT := Color("#2a2219")
const SILVER := Color("#c4d0d8")
const STRAW := Color("#7e7250")
const IRON := Color("#1e2022")
const ROPE := Color("#8a7a58")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	match style:
		"forestfloor":
			_floor(p, col, s, 0.7, 0.0)
		"clearing":
			_grass(p, col, s)
		"dirtpath", "snarepath", "pitpath", "spikepath":
			_path(p, col, s)
		"trampled":
			_floor(p, col, s, 0.15, 0.5)
		"brook":
			_brook(p, col, s)
		"pebbles":
			_pebbles(p, col, s)
		_:
			BF.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	var u := p.w / 64.0
	var c := Vector2(p.w * 0.5, p.h * 0.5)
	match style:
		"brook":
			return
		"pebbles":
			return
		"snarepath":  # 올가미: 고리진 밧줄 + 휘어 박은 말뚝
			_dots(p, c, v, 3, ROOT, 1.2)
			var pts := PackedVector2Array()
			for k in 17:
				var a := TAU * k / 16.0
				pts.append(c + Vector2(cos(a) * 11, sin(a) * 6) * u)
			Ink.path(p, pts, 1.6 * u, true, ROPE, 0.95, 0.3)
			Ink.line(p, c + Vector2(11, 0) * u, c + Vector2(22, -10) * u, 1.4 * u, ROPE, 0.9, 0.3)
			Kit.post(p, c + Vector2(22, -8) * u, c + Vector2(24, -16) * u, 2.2 * u, BARK)
		"pitpath":  # 나뭇가지로 가린 구덩이(가운데가 꺼져 검다)
			Decals._blob(p, c, 13 * u, Color("#0c0c0a"), 0.8, 0.3)
			for k in 9:
				var a := c + Vector2((Paint.hash01(k, 1, v) - 0.5) * 30, (Paint.hash01(k, 2, v) - 0.5) * 18) * u
				var b := a + Vector2((Paint.hash01(k, 3, v) - 0.5) * 20, (Paint.hash01(k, 4, v) - 0.5) * 8) * u
				Ink.line(p, a, b, 1.3 * u, BARK_L, 0.9, 0.5)
			_dots(p, c, v, 6, LITTER, 1.4)
		"spikepath":  # 흙에 박은 깎은 말뚝 끝
			for k in 6:
				var q := c + Vector2((Paint.hash01(k, 5, v) - 0.5) * 30, (Paint.hash01(k, 6, v) - 0.5) * 18) * u
				p.fill_poly(PackedVector2Array([q + Vector2(-2.2, 1.5) * u, q + Vector2(0, -7) * u, q + Vector2(2.2, 1.5) * u]),
					func(_x: int, _y: int) -> Color: return BARK_L)
				Ink.line(p, q + Vector2(0, -7) * u, q + Vector2(0, 1) * u, 0.6 * u, ROOT, 0.7, 0.2)
		"forestfloor", "trampled", "clearing", "dirtpath":
			_leaves(p, v, {"forestfloor": 26, "trampled": 4, "clearing": 0, "dirtpath": 5}[style])
			if style == "clearing":
				_blades(p, v)
			if v != 2 and v != 5:  # 잔손질이 칸마다 찍히면 격자로 보인다(짝 · 홀 칸 하나씩)
				return
			if style == "forestfloor":
				if v == 2:
					Decals._blob(p, c, 8 * u, MOSS, 0.6, 0.5)
				else:
					_twigs(p, c, v, u)
			elif style == "trampled":
				for k in 7:
					var a := c + Vector2((Paint.hash01(k, 1, v) - 0.5) * 26, (Paint.hash01(k, 2, v) - 0.5) * 18) * u
					Ink.line(p, a, a + Vector2(6, (Paint.hash01(k, 3, v) - 0.5) * 4) * u, 0.9 * u, STRAW, 0.8, 0.4)
				if v == 5:
					Ink.line(p, c + Vector2(-6, 3) * u, c + Vector2(6, 1) * u, 1.8 * u, Color("#c8bea8"), 0.9, 0.2)  # 뼈
			elif style == "clearing":
				_dots(p, c, v, 5, Color("#8a8aa8"), 1.0)  # 작은 꽃
			else:
				_twigs(p, c, v, u)
		_:
			BF.detail(p, style, part, v, col)


## 숲 바닥: 검은 흙 기복 + 낙엽 점(litter 비율) + 이끼 얼룩, wet이면 짓밟힌 진창의 번들거림.
static func _floor(p: Paint, col: Color, s: int, litter: float, wet: float) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.06, 3)
	var leaf := Seam.field(w, h, s + 9, 0.45, 1)
	var lm := Seam.field(w, h, s + 13, 0.09, 2)
	var moss := Seam.field(w, h, s + 312, 0.05, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 1.5)
			var c := col.darkened(0.3).lerp(col.lightened(0.12), clampf(0.5 + r * 0.35 + (hf[i] - 0.5) * 0.5, 0.0, 1.0))
			var lk := smoothstep(0.45, 0.8, lm[i]) * litter * 0.5
			if lk > 0.0:
				c = c.lerp(LITTER.lerp(Color("#7a5a3a"), leaf[(i * 7) % (w * h)]), lk)
			if moss[i] > 0.62:
				c = c.lerp(MOSS, (moss[i] - 0.62) * 1.6)
			if wet > 0.0:
				c = c.lerp(SILVER, pow(clampf(r * 1.8, 0.0, 1.0), 2.5) * wet * 0.45)
			p.blend(x, y, c, 1.0)


## 개울: 흐르는 얕은 물(가로로 늘인 물결 · 은빛 반짝임 · 바닥 자갈이 비친다). 변형마다 다른 물결(같은 무늬가 칸마다 찍히지 않게).
static func _brook(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var flow := Seam.field(w, h, s, 0.06, 3)
	var ripple := Seam.field(w, h, s + 1, 0.2, 2)
	var stones := Seam.field(w, h, s + 2, 0.12, 1)
	for y in h:
		for x in w:
			var i := y * w + x
			var f := Seam.at(flow, w, h, x / 3, y)  # 흐름 방향으로 늘인 결
			var c := col.darkened(0.35).lerp(col.lightened(0.15), clampf(0.4 + (f - 0.5) * 0.9 + (stones[i] - 0.5) * 0.3, 0.0, 1.0))
			if stones[i] > 0.72:
				c = c.lerp(Color("#5a5c52"), (stones[i] - 0.72) * 1.8)
			var sp := smoothstep(0.78, 0.95, ripple[i]) * smoothstep(0.45, 0.7, f)
			c = c.lerp(Color("#c8d8e0"), sp * 0.6)
			p.blend(x, y, c, 1.0)


## 개울가 자갈밭: 젖은 검은 모래 위 둥근 자갈(셀 잡음 — 돌마다 위쪽이 밝고 아래 그늘), 사이사이 물기.
static func _pebbles(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var cell := Seam.field(w, h, s + 5, 0.16, 1, true)
	var tone := Seam.field(w, h, s + 6, 0.16, 1)
	var hf := Seam.field(w, h, s, 0.08, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var c := col.darkened(0.45).lerp(col.darkened(0.2), hf[i])
			var k := smoothstep(0.08, 0.2, cell[i])  # 돌 안쪽
			if k > 0.0:
				var up := Seam.at(cell, w, h, x, y - 2) - cell[i]  # 위쪽이 더 안쪽이면 밝게
				var stone := Color("#6a6c62").lerp(Color("#4a4c46"), tone[i]).lightened(clampf(-up * 4.0, -0.3, 0.3))
				c = c.lerp(stone, k)
			else:
				c = c.lerp(Color("#9aa8b0"), smoothstep(0.7, 0.9, hf[i]) * 0.25)  # 물기
			p.blend(x, y, c, 1.0)


## 빈터 풀: 잎 결이 촘촘한 풀밭, 등성이에 이슬 은빛.
static func _grass(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.07, 3)
	var blade := Seam.field(w, h, s + 7, 0.7, 1)
	var dew := Seam.field(w, h, s + 8, 0.05, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 1.2)
			var c := col.darkened(0.3).lerp(col.lightened(0.2), clampf(0.5 + r * 0.3 + (blade[i] - 0.5) * 0.7, 0.0, 1.0))
			c = c.lerp(SILVER, smoothstep(0.75, 0.95, blade[i]) * smoothstep(0.5, 0.8, dew[i]) * 0.35)
			p.blend(x, y, c, 1.0)


## 다져진 오솔길: 밝은 흙 + 바퀴 · 발자국 골(가로 흐름) + 잔자갈.
static func _path(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.08, 3)
	var fine := Seam.field(w, h, s + 2, 0.5, 1)
	var pb := Seam.field(w, h, s + 4, 0.35, 1)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 1.2)
			var c := col.darkened(0.22).lerp(col.lightened(0.1), clampf(0.5 + r * 0.3 + (hf[i] - 0.5) * 0.4 + (fine[i] - 0.5) * 0.1, 0.0, 1.0))
			if pb[i] > 0.88:
				c = c.lerp(Color("#7a7468"), (pb[i] - 0.88) * 6.0)
			p.blend(x, y, c, 1.0)


## 흩어진 낙엽(칸 전체 — 변형마다 다른 자리, 작은 타원 잎 · 잎맥 한 줄).
static func _leaves(p: Paint, v: int, n: int) -> void:
	var u := p.w / 64.0
	for k in n:
		var q := Vector2(Paint.hash01(k, 31, v) * p.w, Paint.hash01(k, 32, v) * p.h)
		var a := Paint.hash01(k, 33, v) * TAU
		var r := (1.6 + Paint.hash01(k, 34, v) * 1.8) * u
		var col: Color = [LITTER, Color("#6a4e30"), Color("#4a4a30"), Color("#3a3226")][int(Paint.hash01(k, 35, v) * 4.0) % 4]
		var pts := PackedVector2Array()
		for j in 10:
			var t := TAU * j / 10.0
			pts.append(q + Vector2(cos(t) * r, sin(t) * r * 0.45).rotated(a))
		p.fill_poly(pts, func(x: int, y: int) -> Color: return p.vary(col, x, y, 0.1), 0.9)
		Ink.line(p, q - Vector2(r, 0).rotated(a), q + Vector2(r, 0).rotated(a), 0.5 * u, Color("#1a1610"), 0.4, 0.2)


## 풀잎 결(빈터 — 칸 전체에 짧은 잎 획).
static func _blades(p: Paint, v: int) -> void:
	var u := p.w / 64.0
	for k in 40:
		var b := Vector2(Paint.hash01(k, 41, v) * p.w, Paint.hash01(k, 42, v) * p.h)
		var t := b + Vector2((Paint.hash01(k, 43, v) - 0.5) * 4, -(3 + Paint.hash01(k, 44, v) * 4)) * u
		Ink.line(p, b, t, 0.8 * u, LEAF.lerp(LEAF_L, Paint.hash01(k, 45, v)), 0.8, 0.3)


static func _dots(p: Paint, c: Vector2, v: int, n: int, col: Color, size: float) -> void:
	var u := p.w / 64.0
	for k in n:
		var q := c + Vector2((Paint.hash01(k, 11, v) - 0.5) * 34, (Paint.hash01(k, 12, v) - 0.5) * 22) * u
		Cave._dot(p, q, size * u, col, 0.85)


static func _twigs(p: Paint, c: Vector2, v: int, u: float) -> void:
	for k in 4:
		var a := c + Vector2((Paint.hash01(k, 21, v) - 0.5) * 26, (Paint.hash01(k, 22, v) - 0.5) * 16) * u
		var b := a + Vector2((Paint.hash01(k, 23, v) - 0.5) * 16, (Paint.hash01(k, 24, v) - 0.5) * 6) * u
		Ink.line(p, a, b, 1.0 * u, ROOT, 0.85, 0.5)


## ── 서 있는 소품 ───────────────────────────────────────

static func stand(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	match tile:
		"f2g_tree":
			_tree(p)
		"f2g_bush":
			_bush(p)
		"f2g_stump":
			_stump(p)
		"f2g_log":
			_log(p)
		"f2g_mush":
			_mush(p)
		"f2g_totem":
			_totem(p)
		"f2g_stele":
			_stele(p, true)
		"f2g_stele_dead":
			_stele(p, false)
		"f2g_stakes":
			_stakes(p)
		_:
			return BF.stand(tile, w, h, seed_value)
	return p


static func _foot(p: Paint) -> Vector2:
	return Vector2(p.w * 0.5, p.h - p.w * 0.14)


## 잎 덩어리: 겹친 둥근 잎 뭉치(어두운 밑 → 밝은 위), 윗쪽 가장자리에 별빛 은빛 몇 점.
static func _canopy(p: Paint, c: Vector2, r: float, s: int) -> void:
	var u := p.w / 128.0
	for k in 14:
		var a := Paint.hash01(k, 1, s) * TAU
		var d := Paint.hash01(k, 2, s) * r * 0.75
		var q := c + Vector2(cos(a) * d, sin(a) * d * 0.8)
		var rr := r * (0.35 + Paint.hash01(k, 3, s) * 0.25)
		var t := clampf(0.5 - (q.y - c.y) / r * 0.6 - (q.x - c.x) / r * 0.2, 0.0, 1.0)
		Kit.blob(p, q, rr, rr * 0.85, LEAF_D.lerp(LEAF_L, t))
	for k in 10:
		var a := PI + Paint.hash01(k, 4, s) * PI
		var q := c + Vector2(cos(a) * r * 0.7, sin(a) * r * 0.6)
		Cave._dot(p, q, 1.3 * u, SILVER, 0.5)


static func _tree(p: Paint) -> void:
	var u := p.w / 128.0
	var f := _foot(p)
	Kit.shadow(p, f, 34 * u, 9 * u, 0.45)
	Kit.post(p, f, f + Vector2(-3, -110) * u, 12.0 * u, BARK)
	Ink.line(p, f + Vector2(-4, -30) * u, f + Vector2(-6, -100) * u, 1.2 * u, BARK_L, 0.5, 0.6)
	for k in 3:  # 뿌리
		Ink.line(p, f + Vector2((k - 1) * 5, -4) * u, f + Vector2((k - 1) * 16, 3) * u, 3.0 * u, BARK, 1.0, 0.3)
	_canopy(p, f + Vector2(-3, -132) * u, 56 * u, 3)


static func _bush(p: Paint) -> void:
	var u := p.w / 128.0
	var f := _foot(p)
	Kit.shadow(p, f, 28 * u, 7 * u, 0.4)
	_canopy(p, f + Vector2(0, -20) * u, 26 * u, 5)


static func _stump(p: Paint) -> void:
	var u := p.w / 128.0
	var f := _foot(p)
	Kit.shadow(p, f, 22 * u, 6 * u, 0.4)
	Kit.cyl(p, f, 16 * u, 22 * u, BARK)
	Kit.blob(p, f + Vector2(0, -22) * u, 15 * u, 7 * u, Color("#7a6a50"))
	for k in 3:
		Ink.path(p, PackedVector2Array([f + Vector2(-12 + k * 4, -22) * u, f + Vector2(0, -26 + k * 1.5) * u, f + Vector2(12 - k * 4, -22) * u]), 0.7 * u, false, BARK, 0.6, 0.2)
	Decals._blob(p, f + Vector2(-10, -6) * u, 6 * u, MOSS, 0.7, 0.4)


static func _log(p: Paint) -> void:
	var u := p.w / 128.0
	var f := _foot(p)
	Kit.shadow(p, f, 50 * u, 8 * u, 0.4)
	var a := f + Vector2(-46, -8) * u
	var b := f + Vector2(46, -12) * u
	Kit.post(p, a, b, 18.0 * u, BARK)
	Ink.line(p, a + Vector2(0, -6) * u, b + Vector2(0, -6) * u, 1.2 * u, BARK_L, 0.5, 0.5)
	Kit.blob(p, b, 8 * u, 9 * u, Color("#7a6a50"))
	Decals._blob(p, f + Vector2(-14, -16) * u, 9 * u, MOSS, 0.8, 0.4)


static func _mush(p: Paint) -> void:
	var u := p.w / 128.0
	var f := _foot(p)
	for k in 5:
		var q := f + Vector2((Paint.hash01(k, 1, 9) - 0.5) * 40, -(Paint.hash01(k, 2, 9)) * 6) * u
		var hh := (8 + Paint.hash01(k, 3, 9) * 12) * u
		Kit.post(p, q, q + Vector2(0, -hh), 2.4 * u, Color("#cfc6b0"))
		Kit.blob(p, q + Vector2(0, -hh), 6 * u, 3.4 * u, Color("#8a9ab0").lerp(Color("#c0c8e0"), Paint.hash01(k, 4, 9)))
		Kit.glow(p, q + Vector2(0, -hh), 9 * u, Color("#9ab8ff"), 0.25)


## 고블린 토템: 기운 막대 + 묶은 짐승 해골 + 깃털 · 천 조각.
static func _totem(p: Paint) -> void:
	var u := p.w / 128.0
	var f := _foot(p)
	Kit.shadow(p, f, 14 * u, 5 * u, 0.45)
	Kit.post(p, f, f + Vector2(4, -96) * u, 5.0 * u, BARK)
	var sk := f + Vector2(3, -82) * u
	Kit.blob(p, sk, 10 * u, 8 * u, Color("#d0c6ae"))
	Cave._dot(p, sk + Vector2(-4, 0) * u, 2.4 * u, Color("#0a0a08"), 1.0)
	Cave._dot(p, sk + Vector2(4, 0) * u, 2.4 * u, Color("#0a0a08"), 1.0)
	Ink.line(p, sk + Vector2(-8, -5) * u, sk + Vector2(-16, -18) * u, 2.0 * u, Color("#c8bea6"), 1.0, 0.2)  # 뿔
	Ink.line(p, sk + Vector2(8, -5) * u, sk + Vector2(16, -18) * u, 2.0 * u, Color("#c8bea6"), 1.0, 0.2)
	for k in 3:
		Ink.line(p, f + Vector2(4, -60 + k * 6) * u, f + Vector2(14 + k * 3, -48 + k * 8) * u, 2.0 * u, [Color("#6a3a2a"), STRAW, Color("#3a4a5a")][k], 0.9, 0.4)


## 포탈 비석: 이끼 낀 선돌 + 새긴 고리 룬. 살아 있으면(live) 룬이 차가운 은청빛으로 빛난다, 아니면 금 간 돌덩이.
static func _stele(p: Paint, live: bool) -> void:
	var u := p.w / 128.0
	var f := _foot(p)
	Kit.shadow(p, f, 26 * u, 7 * u, 0.45)
	var pts := PackedVector2Array([f + Vector2(-17, 0) * u, f + Vector2(-19, -70) * u, f + Vector2(-8, -96) * u, f + Vector2(9, -98) * u, f + Vector2(18, -72) * u, f + Vector2(16, 0) * u])
	var stone := Color("#5c6260")
	p.fill_poly(pts, func(x: int, y: int) -> Color: return p.vary(stone.lightened(0.12 - (x - f.x) / (18.0 * u) * 0.15), x, y, 0.08))
	Ink.path(p, pts, 1.6 * u, true, Ink.INK, 0.9, 0.3)
	var c := f + Vector2(0, -56) * u
	var ring := PackedVector2Array()
	for k in 17:
		var a := TAU * k / 16.0
		ring.append(c + Vector2(cos(a) * 10, sin(a) * 12) * u)
	if live:
		Kit.glow(p, c, 30 * u, Color("#8ab4ff"), 0.55)
		Ink.path(p, ring, 2.0 * u, true, Color("#d8e8ff"), 1.0, 0.1)
		Ink.line(p, c + Vector2(0, -12) * u, c + Vector2(0, 12) * u, 1.6 * u, Color("#d8e8ff"), 1.0, 0.1)
	else:
		Ink.path(p, ring, 1.4 * u, true, Color("#2a2e2c"), 0.8, 0.2)
		Ink.line(p, f + Vector2(-6, -94) * u, f + Vector2(3, -60) * u, 1.2 * u, Ink.INK, 0.9, 0.6)  # 금
		Ink.line(p, f + Vector2(3, -60) * u, f + Vector2(-2, -30) * u, 1.0 * u, Ink.INK, 0.8, 0.6)
	Decals._blob(p, f + Vector2(-10, -14) * u, 8 * u, MOSS, 0.8, 0.4)
	Decals._blob(p, f + Vector2(8, -88) * u, 5 * u, MOSS, 0.6, 0.4)


## 고블린 말뚝 울타리(이웃 칸과 이어진다): 깎은 말뚝 넷 + 묶은 밧줄.
static func _stakes(p: Paint) -> void:
	var u := p.w / 128.0
	var f := _foot(p)
	var l := f.x - 32.0 * u
	Kit.shadow(p, f + Vector2(0, 2 * u), 34 * u, 4 * u, 0.3)
	for k in 4:
		var x := l + (k + 0.5) * 16.0 * u
		var lean := (Paint.hash01(k, 1, 3) - 0.5) * 6 * u
		var top := Vector2(x + lean, f.y - (52 + Paint.hash01(k, 2, 3) * 14) * u)
		Kit.post(p, Vector2(x, f.y), top + Vector2(0, 8 * u), 5.0 * u, BARK)
		p.fill_poly(PackedVector2Array([top + Vector2(-2.6, 8) * u, top, top + Vector2(2.6, 8) * u]), func(_x: int, _y: int) -> Color: return Color("#7a6a52"))
	Ink.line(p, Vector2(l, f.y - 26 * u), Vector2(l + 64 * u, f.y - 28 * u), 1.6 * u, ROPE, 0.9, 0.3)
