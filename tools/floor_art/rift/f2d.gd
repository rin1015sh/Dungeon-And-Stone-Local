extends RefCounted
## 2층 망자의 땅 그림(A5 — Common.gd 계약, docs/plans/floor2.md §3). 사용자 2026-11-05 두 번: "길 경계가 흐리다 · 황량하다",
## "땅이 벽돌 같다 — 묘지 느낌 · 무채색이고 휑하다 · 외곽 검은 곳 장식이 이상하다 · 석조 건축물"(첨부 그림: 붉은 하늘 아래 이끼 낀 묘지,
## 쇠 울타리 · 등불 · 마른 나무 · 안개). 그래서 바닥은 묘지 흙(풀 · 이끼 · 낙엽) · 굳은 흙(마른 풀) · 깨진 판석(틈에 풀), 길 밖은 검은 물(맨물) ·
## 덤불(가시 · 마른 풀 — 걷지 못함), 벽은 이끼 낀 납골당 돌. 서 있는 소품 중 쇠 울타리 · 등불 · 덤불은 여기서(stand.webp), 나머지는 핏빛성채 그림(BF).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const BF := preload("res://tools/floor_art/rift/bf.gd")
const Common := preload("res://tools/floor_art/rift/Common.gd")

const WATER_DEEP := Color("#0a0e0e")
const GLOSS := Color("#9ab0b0")
const MOSS := Color("#5a5a3c")       # 사용자 2026-11-05 "초록은 에바" — 바랜 올리브 · 잿빛(FL11)
const MOSS_DARK := Color("#2e2e22")
const GRASS := Color("#6e6a4a")
const DRY := Color("#8a7a4a")
const LEAF := Color("#7a3a1e")
const IRON := Color("#24221f")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	match style:
		"blackwater":
			_water(p, col, s)
		"graveearth":
			_earth(p, col, s, 0.55, MOSS, GRASS)
		"dryearth":
			_earth(p, col, s, 0.25, DRY.darkened(0.25), DRY)
		"flagstone":
			_flags(p, col, s)
		"thicket":
			_thicket(p, col, s)
		"bank":  # 길 밖 흙 둔덕(벽 — 둥근 윤곽 · 윗면 = 덤불, 앞면 = 흙 벼랑, 1층 수정동굴처럼 입체감, FL11)
			if part == "face":
				_bank_face(p, col, s)
			else:
				_thicket(p, col, s)
		"cryptstone":
			BF.base(p, "masonry", part, col, s)
			_moss_over(p, s, 0.5 if part == "face" else 0.35)
		_:
			BF.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	match style:
		"blackwater", "thicket", "bank":
			return  # 길 밖은 맨바탕(칸마다 무늬가 찍히면 벽지처럼 보인다)
		"graveearth", "dryearth", "flagstone":
			_ground_detail(p, style, v)
			return
		"cryptstone":
			BF.detail(p, "masonry", part, v, col)
			return
	if style in ["ash", "mudroad"] and part == "floor":  # 잔손질이 칸마다 찍히면 격자 무늬로 보인다(변형은 체스판 짝 · 홀 칸 — FloorArtLayer.variant)
		if v != 2:
			return
		v = 4
	BF.detail(p, style, part, v, col)


static func stand(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	match tile:
		"f2d_fence":
			_fence(p)
		"f2d_lantern":
			_lantern(p)
		"f2d_bush":
			_bush(p)
		_:
			return BF.stand(tile, w, h, seed_value)
	return p


## ── 바닥 ──────────────────────────────────────────────

## 검은 물: 깊이(고정 무늬)로 어둡게, 물결 밝은 쪽에 차가운 번들거림 — 잔손질 없음.
static func _water(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, 263, 0.025, 3)
	var rp := Seam.field(w, h, s, 0.045, 2)
	var sh := Seam.field(w, h, s + 1, 0.03, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(rp, w, h, x, y, 2.0)
			var c := WATER_DEEP.lerp(col, clampf(0.4 + hf[i] * 0.4, 0.0, 1.0))
			var gloss := pow(clampf(r * 1.6, 0.0, 1.0), 3.0) * smoothstep(0.5, 0.85, sh[i])
			c = c.lerp(GLOSS, gloss * 0.22)
			c = c.lerp(Color("#050607"), pow(clampf(-r * 1.6, 0.0, 1.0), 2.0) * 0.25)
			p.blend(x, y, c, 1.0)


## 흙 + 풀: 덩어리진 흙(빛 받은 기복), 풀(잡음 위 — 가는 결로 밝고 어두운 잎), 이끼 얼룩, 흩어진 낙엽 점.
static func _earth(p: Paint, col: Color, s: int, grass_amt: float, grass_dark: Color, grass_lit: Color) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.06, 3)
	var gm := Seam.field(w, h, s + 311, 0.11, 3)  # 풀 자리(잘게 — 칸 하나에 큰 덩어리가 있으면 칸마다 같은 모양이 찍혀 보인다)
	var blade := Seam.field(w, h, s + 7, 0.6, 1)
	var moss := Seam.field(w, h, 312, 0.05, 2)
	var leaf := Seam.field(w, h, s + 9, 0.5, 1)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 4.0)
			var c := col.darkened(0.3).lerp(col.lightened(0.18), clampf(0.5 + r * 0.6 + (hf[i] - 0.5) * 0.3, 0.0, 1.0))
			var g := smoothstep(0.58 - grass_amt * 0.25, 0.75 - grass_amt * 0.25, gm[i]) * (0.55 + blade[i] * 0.45)
			if g > 0.0:
				c = c.lerp(grass_dark.lerp(grass_lit, clampf(blade[i] * 1.4 - 0.2 + r * 0.4, 0.0, 1.0)), g * 0.85)
			if moss[i] > 0.66:
				c = c.lerp(MOSS_DARK, (moss[i] - 0.66) * 2.0)
			if leaf[i] > 0.86:
				c = c.lerp(LEAF, (leaf[i] - 0.86) * 4.0)
			p.blend(x, y, c, 1.0)


## 깨진 판석: 셀 잡음 경계 = 틈(검고, 풀 · 이끼가 비집고 난다), 판마다 밝기 다르게, 몇 판은 빠져 흙.
static func _flags(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var cell := Seam.field(w, h, s + 401, 0.04, 1, true)  # 판 경계(변형마다 — 고정이면 칸마다 같은 판이 찍혀 보인다, 가장자리는 Common.cell이 잇는다)
	var tone := Seam.field(w, h, s + 402, 0.05, 1)
	var hf := Seam.field(w, h, s, 0.08, 3)
	var fine := Seam.field(w, h, s + 2, 0.4, 1)
	var gm := Seam.field(w, h, s + 403, 0.09, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 3.0)
			var t := 0.5 + (tone[i] - 0.5) * 0.35 + r * 0.3 + (fine[i] - 0.5) * 0.15
			var c := col.darkened(0.3).lerp(col.lightened(0.12), clampf(t, 0.0, 1.0))
			var edge := 1.0 - smoothstep(0.04, 0.12, cell[i])  # 틈
			if edge > 0.0:
				var crack := Color("#1a1a14").lerp(MOSS.lerp(GRASS, fine[i]), smoothstep(0.35, 0.6, gm[i]))
				c = c.lerp(crack, edge)
			if tone[i] < 0.18:  # 빠진 판 — 흙과 풀
				c = c.lerp(Color("#3a3426").lerp(MOSS, fine[i] * 0.6), smoothstep(0.18, 0.12, tone[i]))
			if gm[i] > 0.7:  # 판 위를 덮은 이끼
				c = c.lerp(MOSS, (gm[i] - 0.7) * 1.6)
			p.blend(x, y, c, 1.0)


## 덤불(길 밖 — 걷지 못함): 검푸른 가시덤불 · 마른 풀 결, 사이사이 어두운 틈.
static func _thicket(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, 501, 0.08, 3)
	var fine := Seam.field(w, h, s, 0.5, 1)
	var dry := Seam.field(w, h, 502, 0.04, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 6.0)
			var c := Color("#0c0e0a").lerp(col, clampf(0.35 + r * 0.9 + (fine[i] - 0.5) * 0.6, 0.0, 1.0))
			if dry[i] > 0.6:
				c = c.lerp(DRY.darkened(0.4), (dry[i] - 0.6) * 1.2 * fine[i])
			p.blend(x, y, c, 1.0)


## 흙 둔덕 앞면: 위 턱 = 덤불 · 마른 풀이 늘어진 가장자리, 몸 = 층진 흙(빛 받은 기복 · 박힌 돌 · 뿌리), 아래로 갈수록 어둡고,
## 바닥과 만나는 밑동은 들쭉날쭉 투명(Common.skirt — 바닥 위로 내려온다).
static func _bank_face(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var main := float(h - Common.skirt)
	var jag := Seam.field(w, 8, s + 9, 0.1, 3)
	var lip := Seam.field(w, 8, s + 5, 0.12, 2)
	var hf := Seam.field(w, h, s, 0.07, 4)
	var strata := Seam.field(w, h, 611, 0.03, 2)
	var stones := Seam.field(w, h, s + 3, 0.12, 1, true)
	var fine := Seam.field(w, h, s + 6, 0.35, 1)
	var u := w / 64.0
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := main + (0.25 + jag[x] * 0.75) * Common.skirt
			if y >= foot:
				continue
			var ly := (4.0 + lip[x] * 8.0) * u
			var r := Seam.relief(hf, w, h, x, y, 6.0)
			var t := 0.5 + r * 0.8 + (hf[i] - 0.5) * 0.3 + (fine[i] - 0.5) * 0.12
			t += sin((y + strata[i] * 18.0 * u) / (7.0 * u)) * 0.06  # 흙 층
			t -= smoothstep(main * 0.35, foot, float(y)) * 0.35  # 아래로 어둡게(그늘)
			var c := col.darkened(0.55).lerp(col.lightened(0.3), clampf(t, 0.0, 1.0))
			if stones[i] < 0.12:  # 박힌 돌
				c = Color("#6a6658").darkened(0.2 - r * 0.3).lerp(Ink.INK, smoothstep(0.08, 0.12, stones[i]) * 0.6)
			if y < ly:  # 위 턱: 늘어진 덤불 · 마른 풀
				c = Color("#2a2a22").lerp(DRY.darkened(0.35), fine[i] * 0.6)
			elif y < ly + 1.4 * u:
				c = c.lerp(Ink.INK, 0.6)
			elif y < ly + 8.0 * u:
				c = c.darkened(0.35 * (1.0 - (y - ly) / (8.0 * u)))  # 턱 밑 그늘
			if foot - y < 1.6 * u:
				c = c.lerp(Ink.INK, 0.5)
			p.blend(x, y, c, 1.0)
	for k in 7:  # 뿌리 · 마른 풀 줄기가 턱에서 늘어진다
		var x0 := Paint.hash01(k, s % 97, 7) * w
		var y0 := (5.0 + lip[int(x0) % w] * 8.0) * u
		Ink.line(p, Vector2(x0, y0), Vector2(x0 + (Paint.hash01(k, 2, 7) - 0.5) * 6 * u, y0 + (6 + Paint.hash01(k, 3, 7) * 14) * u), 0.9 * u, Color("#1e1a14"), 0.7, 0.8)


## 벽 위 이끼(아래쪽에 더 많이).
static func _moss_over(p: Paint, s: int, amt: float) -> void:
	var w := p.w
	var h := p.h
	var m := Seam.field(w, h, s + 77, 0.07, 3)
	for y in h:
		for x in w:
			if p.alpha_at(x, y) < 0.5:
				continue
			var low := float(y) / float(h)
			var k := smoothstep(0.62 - amt * 0.3 - low * 0.15, 0.78, m[y * w + x])
			if k > 0.0:
				p.blend(x, y, MOSS.lerp(MOSS_DARK, 1.0 - m[y * w + x]), k * 0.75)


## 바닥 잔손질 — 짝 · 홀 칸에 하나씩(2 · 5): 묘지 흙 = 풀 다발 · 낙엽, 굳은 흙 = 마른 풀 · 잔돌, 판석 = 금 · 이끼.
static func _ground_detail(p: Paint, style: String, v: int) -> void:
	if v != 2 and v != 5:
		return
	var u := p.w / 64.0
	var c := Vector2(p.w * 0.5, p.h * 0.5)
	if style == "flagstone":
		if v == 2:
			Ink.line(p, c + Vector2(-12, -6) * u, c + Vector2(2, 1) * u, 0.9 * u, Color("#14140f"), 0.7, 0.8)
			Ink.line(p, c + Vector2(2, 1) * u, c + Vector2(10, 9) * u, 0.8 * u, Color("#14140f"), 0.6, 0.8)
		else:
			Decals._blob(p, c, 9 * u, MOSS, 0.5, 0.5)
		return
	if v == 2:  # 풀 다발
		for k in 9:
			var b := c + Vector2((Paint.hash01(k, 1, v) - 0.5) * 14, 4 + (Paint.hash01(k, 2, v) - 0.5) * 4) * u
			var t := b + Vector2((Paint.hash01(k, 3, v) - 0.5) * 8, -(6 + Paint.hash01(k, 4, v) * 8)) * u
			var gc := (GRASS if style == "graveearth" else DRY).lerp(Color("#2a2a18"), Paint.hash01(k, 5, v) * 0.5)
			Ink.line(p, b, t, 1.1 * u, gc, 0.9, 0.4)
	elif style == "graveearth":  # 낙엽
		for k in 7:
			var q := c + Vector2((Paint.hash01(k, 6, v) - 0.5) * 22, (Paint.hash01(k, 7, v) - 0.5) * 16) * u
			Cave._dot(p, q, 1.6 * u, LEAF.lerp(DRY, Paint.hash01(k, 8, v)), 0.85)
	else:  # 잔돌
		for k in 4:
			var q := c + Vector2((Paint.hash01(k, 6, v) - 0.5) * 20, (Paint.hash01(k, 7, v) - 0.5) * 14) * u
			Cave._stone(p, q, 2.4 * u, 1.7 * u, Color("#6a6458"))


## ── 서 있는 소품(발 = (w/2, h - w·0.14), 바닥 칸 폭 = w/2) ──────────

## 쇠 울타리 한 칸: 좌우 끝이 칸 가장자리(발 ± w/4)에 닿는다 — 창끝 살 다섯, 가로대 둘, 덩굴.
static func _fence(p: Paint) -> void:
	var u := p.w / 128.0
	var f := Vector2(p.w * 0.5, p.h - p.w * 0.14)
	var l := f.x - 32.0 * u
	var top := 64.0 * u
	Kit.shadow(p, f + Vector2(0, 2 * u), 34 * u, 4 * u, 0.3)
	for ry: float in [10.0, 50.0]:
		Ink.line(p, Vector2(l, f.y - ry * u), Vector2(l + 64 * u, f.y - ry * u), 3.0 * u, IRON, 1.0, 0.2)
		Ink.line(p, Vector2(l, f.y - ry * u - 1.0 * u), Vector2(l + 64 * u, f.y - ry * u - 1.0 * u), 1.0 * u, Color("#5a4a3a"), 0.5, 0.2)
	for k in 5:
		var x := l + (k + 0.5) * 64.0 * u / 5.0
		var hh := top + (4.0 if k % 2 == 0 else 0.0) * u
		Ink.line(p, Vector2(x, f.y), Vector2(x, f.y - hh), 2.6 * u, IRON, 1.0, 0.15)
		Ink.line(p, Vector2(x - 0.8 * u, f.y - 4 * u), Vector2(x - 0.8 * u, f.y - hh + 4 * u), 0.8 * u, Color("#6a5848"), 0.45, 0.2)
		var tip := Vector2(x, f.y - hh)
		p.fill_poly(PackedVector2Array([tip + Vector2(-3, 2) * u, tip + Vector2(0, -7) * u, tip + Vector2(3, 2) * u]), func(_x: int, _y: int) -> Color: return IRON)
		if Paint.hash01(k, 9, 3) > 0.5:  # 덩굴
			Ink.line(p, Vector2(x, f.y - 6 * u), Vector2(x + 3 * u, f.y - 22 * u), 1.4 * u, MOSS, 0.8, 0.8)


## 등불 기둥: 쇠 기둥 + 갈고리에 매단 등(붉은 주황 빛).
static func _lantern(p: Paint) -> void:
	var u := p.w / 128.0
	var f := Vector2(p.w * 0.5, p.h - p.w * 0.14)
	Kit.shadow(p, f, 10 * u, 4 * u, 0.4)
	Kit.post(p, f, f + Vector2(0, -96 * u), 4.0 * u, IRON.lightened(0.15))
	var arm := f + Vector2(0, -92 * u)
	Ink.line(p, arm, arm + Vector2(14, 0) * u, 2.4 * u, IRON, 1.0, 0.2)
	Ink.line(p, arm + Vector2(14, 0) * u, arm + Vector2(14, 6) * u, 1.2 * u, IRON, 1.0, 0.1)
	var c := arm + Vector2(14, 16) * u
	Kit.glow(p, c, 30 * u, Color("#ff6a2a"), 0.5)
	var body := PackedVector2Array([c + Vector2(-6, -9) * u, c + Vector2(6, -9) * u, c + Vector2(7, 8) * u, c + Vector2(-7, 8) * u])
	p.fill_poly(body, func(x: int, y: int) -> Color:
		var d := Vector2(x - c.x, y - c.y).length() / (9.0 * u)
		return Color("#fff0b0").lerp(Color("#e0501c"), clampf(d, 0.0, 1.0)))
	Ink.path(p, body, 1.6 * u, true, IRON, 1.0, 0.1)
	Ink.line(p, c + Vector2(0, -9) * u, c + Vector2(0, 8) * u, 1.0 * u, IRON, 0.8, 0.1)
	p.fill_poly(PackedVector2Array([c + Vector2(-8, -9) * u, c + Vector2(0, -15) * u, c + Vector2(8, -9) * u]), func(_x: int, _y: int) -> Color: return IRON)


## 마른 가시덤불(길 가장자리 · 덤불 속).
static func _bush(p: Paint) -> void:
	var u := p.w / 128.0
	var f := Vector2(p.w * 0.5, p.h - p.w * 0.14)
	Kit.shadow(p, f, 26 * u, 7 * u, 0.4)
	Kit.blob(p, f + Vector2(-8, -10) * u, 16 * u, 11 * u, Color("#2c3020"))
	Kit.blob(p, f + Vector2(9, -12) * u, 15 * u, 12 * u, Color("#323622"))
	Kit.blob(p, f + Vector2(0, -20) * u, 13 * u, 10 * u, Color("#3a3e26"))
	for k in 14:
		var a := f + Vector2((Paint.hash01(k, 1, 4) - 0.5) * 36, -8 - Paint.hash01(k, 2, 4) * 16) * u
		var b := a + Vector2((Paint.hash01(k, 3, 4) - 0.5) * 24, -(6 + Paint.hash01(k, 4, 4) * 16)) * u
		Ink.line(p, a, b, 1.1 * u, Color("#1a1a12").lerp(DRY.darkened(0.3), Paint.hash01(k, 5, 4)), 0.9, 0.6)
