extends RefCounted
## 녹색 탄광 바닥 재질(gm.gd가 부른다): 다진 흙 · 청석 · 철로 · 돌무더기 · 나무 계단 · 판자 길 · 슬라임 웅덩이 · 부서진 다리 · 바위 계단.
## 바탕은 주기 잡음(Seam)과 칸에 고정된 배치(철로·침목·판자·계단 단 — 모든 변형이 같은 자리)만 쓴다 → 칸끼리 이어진다.
## 잔손질(변형마다 — 칸 가운데 위주)은 gm_floor2. 빛은 굽지 않고 중립 밝기 — 슬라임·결정의 발광만 밝게.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const K := preload("res://tools/floor_art/rift/gm_kit.gd")

## 판자 경계(64 px 칸 기준 — 세로로 놓인 판 4장) · 판 이음 높이
const BOARDS := [0.0, 15.0, 32.0, 48.0, 64.0]
const JOINTS := [9.0, 41.0, 25.0, 54.0]
## 철로: 레일 윗면 높이 2줄, 침목 주기 16 px
const RAILS := [16.0, 44.0]


static func base(p: Paint, style: String, col: Color, s: int) -> void:
	match style:
		"minedirt":
			_dirt(p, col, s)
		"bluestone":
			_bluestone(p, col, s)
		"rails":
			_rails(p, col, s)
		"rubble":
			_rubble(p, col, s)
		"woodstairs":
			_stairs(p, col, s, false)
		"rockstairs":
			_stairs(p, col, s, true)
		"planks":
			_planks(p, col, s, false)
		"brokenplanks":
			_planks(p, col, s, true)
		"ooze":
			_ooze(p, col, s)


static func _dirt(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.05, 3)
	var grit := Seam.field(w, h, s + 1, 0.4, 1)
	var coal := Seam.field(w, h, s + 2, 0.035, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var t := 0.5 + (hf[i] - 0.5) * 0.4 + Seam.relief(hf, w, h, x, y, 4.0) * 0.35 + (grit[i] - 0.5) * 0.25
			var c := col.darkened(0.42).lerp(col.lightened(0.22), clampf(t, 0.0, 1.0))
			if coal[i] > 0.58:  # 석탄 가루가 앉은 자리
				c = c.lerp(Color("#1c1a1c"), minf(0.55, (coal[i] - 0.58) * 2.2))
			if grit[i] > 0.8:  # 자갈 알갱이
				c = c.lightened((grit[i] - 0.8) * 1.2)
			elif grit[i] < 0.18:
				c = c.darkened((0.18 - grit[i]) * 2.0)
			p.blend(x, y, c, 1.0)


static func _bluestone(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.035, 4)
	var wear := Seam.field(w, h, s + 1, 0.025, 2)
	var cl := Seam.field(w, h, s + 2, 0.045, 1, true)
	var strata := Seam.field(w, h, s + 3, 0.05, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var worn := smoothstep(0.52, 0.72, wear[i])  # 발에 닳아 매끈한 자리
			var t := 0.46 + (hf[i] - 0.5) * 0.35 + Seam.relief(hf, w, h, x, y, lerpf(6.0, 1.5, worn)) * 0.45
			var tint := col.lerp(K.ROCK_VIOLET, clampf((strata[i] - 0.4) * 1.5, 0.0, 0.6))
			var c := tint.darkened(0.45).lerp(tint.lightened(0.28), clampf(t, 0.0, 1.0)).lightened(0.1 * worn)
			if cl[i] < 0.05:  # 바위 결 사이 가는 금
				c = c.lerp(Ink.INK, 0.45 * (1.0 - cl[i] / 0.05))
			p.blend(x, y, c, 1.0)


static func _rails(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var sc := w / 64.0
	var hf := Seam.field(w, h, s, 0.05, 3)
	var grit := Seam.field(w, h, s + 1, 0.4, 1)
	var gf := Seam.field(w, h, s + 2, 0.06, 3)
	var rf := Seam.field(w, h, s + 3, 0.08, 2)
	var per := 16.0 * sc
	for y in h:
		for x in w:
			var i := y * w + x
			# 자갈 깐 흙(바닥)
			var t := 0.5 + (hf[i] - 0.5) * 0.3 + Seam.relief(hf, w, h, x, y, 4.0) * 0.3 + (grit[i] - 0.5) * 0.4
			var c := col.darkened(0.45).lerp(col.lightened(0.15), clampf(t, 0.0, 1.0)).lerp(Color("#5a5652"), 0.25)
			# 침목(세로로 놓인 나무 — 레일 아래)
			var lx := fposmod(x, per)
			var k := int(x / per)
			var jag := (Seam.at(gf, w, h, x * 3, 0) - 0.5) * 3.0 * sc
			var y0 := 8.0 * sc + jag
			var y1 := 56.0 * sc - jag
			if lx >= 3.0 * sc and lx < 13.0 * sc and y >= y0 and y < y1:
				var g := K.streak(gf, w, h, x, y, 4, 1)
				var tone := Paint.hash01(k, 3) * 0.2 - 0.1
				var wc := K.WOOD.darkened(0.25 - tone).lerp(K.WOOD.lightened(0.05), g)
				if lx < 4.2 * sc:
					wc = wc.lightened(0.12)
				elif lx >= 11.8 * sc:
					wc = wc.darkened(0.35)
				if y > y1 - 2.0 * sc or y < y0 + 1.0 * sc:
					wc = wc.darkened(0.3)
				c = wc
			elif lx >= 13.0 * sc and lx < 15.5 * sc and y >= y0 + 2.0 and y < y1 + 1.0:
				c = c.darkened(0.35)  # 침목 그림자
			# 레일(가로로 이어짐): 닳아 빛나는 윗면 → 어두운 옆면 → 잉크 → 그림자
			for ry: float in RAILS:
				var dy := y - ry * sc
				if dy >= -2.5 * sc and dy < 7.5 * sc and lx >= 6.0 * sc and lx < 10.0 * sc and (dy < 0.0 or dy >= 5.0 * sc):
					c = K.IRON.darkened(0.35)  # 받침쇠
					if absf(lx - 8.0 * sc) < 1.0 and absf(dy - (-1.5 if dy < 0.0 else 6.5) * sc) < 1.0:
						c = Color("#2a2622")  # 못
				if dy >= -1.0 and dy < 0.0:
					c = c.lerp(Ink.INK, 0.5)
				elif dy >= 0.0 and dy < 2.5 * sc:
					var rs := clampf((rf[i] - 0.55) * 3.0, 0.0, 0.7)
					c = K.STEEL.lerp(Color("#d0d4d8"), 0.5 if dy < 1.0 else 0.0).lerp(K.RUST, rs * 0.5)
				elif dy >= 2.5 * sc and dy < 5.0 * sc:
					c = K.IRON.darkened(0.3).lerp(K.RUST.darkened(0.3), clampf(rf[i] * 1.2 - 0.2, 0.0, 1.0))
				elif dy >= 5.0 * sc and dy < 5.0 * sc + 1.0:
					c = c.lerp(Ink.INK, 0.75)
				elif dy >= 5.0 * sc and dy < 8.5 * sc:
					c = c.darkened(0.4 * (1.0 - (dy - 5.0 * sc) / (3.5 * sc)))
			p.blend(x, y, c, 1.0)


static func _rubble(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var cl := Seam.field(w, h, s, 0.11, 1, true)
	var hf := Seam.field(w, h, s + 1, 0.05, 3)
	var tone := Seam.field(w, h, s + 2, 0.08, 2)
	var dust := Seam.field(w, h, s + 3, 0.04, 2)
	var hh := PackedFloat32Array()
	hh.resize(w * h)
	for i in w * h:
		hh[i] = smoothstep(0.0, 0.28, cl[i]) * 0.7 + hf[i] * 0.3
	for y in h:
		for x in w:
			var i := y * w + x
			var t := 0.42 + Seam.relief(hh, w, h, x, y, 9.0) * 0.75 + (tone[i] - 0.5) * 0.35
			var tint := col.lerp(K.ROCK, clampf((tone[i] - 0.45) * 1.2, 0.0, 0.45))
			var c := tint.darkened(0.5).lerp(tint.lightened(0.3), clampf(t, 0.0, 1.0))
			if cl[i] < 0.06:  # 돌 사이 틈
				c = c.lerp(Color("#1a1614"), 0.6 * (1.0 - cl[i] / 0.06))
			if dust[i] > 0.6:  # 가루 먼지
				c = c.lerp(Color("#9a9080"), (dust[i] - 0.6) * 0.9)
			p.blend(x, y, c, 1.0)


## 계단(위가 북쪽 — 올라갈수록 화면 위): 단마다 디딤판(나무결·바위) → 밝은 코 → 어두운 챌판. 단 주기 16 px.
static func _stairs(p: Paint, col: Color, s: int, rock: bool) -> void:
	var w := p.w
	var h := p.h
	var sc := w / 64.0
	var per := 16.0 * sc
	var tread := (11.0 if rock else 10.0) * sc
	var gf := Seam.field(w, h, s, 0.06, 3)
	var hf := Seam.field(w, h, s + 1, 0.07, 3)
	var nf := Seam.field(w, h, s + 2, 0.08, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var j := int(y / per)
			var wob := (Seam.at(nf, w, h, x, j * 16) - 0.5) * (3.0 if rock else 0.8) * sc
			var py := fposmod(y, per) - wob
			var c: Color
			if py < tread:
				var back := 1.0 - py / tread
				if rock:
					var t := 0.48 + Seam.relief(hf, w, h, x, y, 6.0) * 0.5 + (hf[i] - 0.5) * 0.3 - back * 0.15
					c = col.darkened(0.4).lerp(col.lightened(0.3), clampf(t, 0.0, 1.0))
				else:
					var jx := fposmod(j * 37.0 + 13.0, 64.0) * sc
					var tn := Paint.hash01(j, 0, 5) * 0.24 - 0.12
					var g := K.streak(gf, w, h, x, y, 1, 4)
					c = col.darkened(0.3 - tn).lerp(col.lightened(0.15 + tn), g).darkened(back * 0.4)
					c = c.darkened(clampf((hf[i] - 0.5) * 0.5, 0.0, 0.2))  # 발에 닳은 때
					if (absf(x - jx) < 1.0 or absf(x - jx - w) < 1.0 or absf(x - jx + w) < 1.0) and j % 2 == 0:
						c = c.lerp(Ink.INK, 0.6)  # 판 이음(두 단에 하나)
				if py >= tread - 1.6 * sc:
					c = c.lightened(0.22)  # 빛 받은 코
			else:
				var rt := (py - tread) / (per - tread)
				if rock:
					c = col.darkened(0.5).lerp(col.darkened(0.3), hf[i]).darkened(rt * 0.15)
				else:
					c = col.darkened(0.62).lerp(col.darkened(0.45), K.streak(gf, w, h, x, y, 3, 1))
				if py < tread + 1.2 * sc:
					c = c.lerp(Ink.INK, 0.75)  # 코 밑 잉크
				elif rt > 0.82:
					c = c.lerp(Ink.INK, 0.4)
			p.blend(x, y, c, 1.0)
	if not rock:
		for j in range(0, int(h / per), 2):
			var jx := fposmod(j * 37.0 + 13.0, 64.0) * sc
			for e: float in [-3.0, 3.0]:
				K.nail(p, Vector2(fposmod(jx + e * sc, w), j * per + tread * 0.5), 0.8 * sc)


## 판자 길: 세로로 놓인 판 4장, 판 사이 틈으로 아래 어둠. broken이면 낡고 틈이 넓다.
static func _planks(p: Paint, col: Color, s: int, broken: bool) -> void:
	var w := p.w
	var h := p.h
	var sc := w / 64.0
	var gf := Seam.field(w, h, s, 0.06, 3)
	var hf := Seam.field(w, h, s + 1, 0.04, 2)
	var gap := 2.6 if broken else 1.6
	for y in h:
		for x in w:
			var i := y * w + x
			var b := _board(x / sc)
			var bx0: float = BOARDS[b]
			var bx1: float = BOARDS[b + 1]
			var lx := x / sc - bx0
			var bw := bx1 - bx0
			var c: Color
			if lx < gap * 0.5 or lx >= bw - gap * 0.5:
				c = K.VOID.lerp(K.WOOD_DARK, 0.15)  # 판 사이 틈
			else:
				var tn := Paint.hash01(b, 11) * 0.24 - 0.12
				var g := K.streak(gf, w, h, x, y, 4, 1)
				c = col.darkened(0.28 - tn).lerp(col.lightened(0.1 + tn), g)
				c = c.darkened((hf[i] - 0.4) * (0.5 if broken else 0.3))  # 때·물 얼룩
				if lx < gap * 0.5 + 1.2:
					c = c.lightened(0.12)
				elif lx >= bw - gap * 0.5 - 1.5:
					c = c.darkened(0.28)
				var jy: float = JOINTS[b] * sc
				var dj := y - jy
				if absf(dj) < 0.9 * sc:
					c = c.lerp(Ink.INK, 0.8)  # 판 이음
				elif dj > 0.0 and dj < 2.5 * sc:
					c = c.darkened(0.2)
			p.blend(x, y, c, 1.0)
	for b in 4:  # 이음 양쪽 못
		var jy: float = JOINTS[b] * sc
		for side: float in [-3.5, 3.5]:
			for e: float in [float(BOARDS[b]) + 3.5, float(BOARDS[b + 1]) - 3.5]:
				K.nail(p, Vector2(e * sc, jy + side * sc), 0.9 * sc)


static func _board(x: float) -> int:
	for b in 4:
		if x < float(BOARDS[b + 1]):
			return b
	return 3


## 슬라임 웅덩이: 휘감긴 끈적한 흐름(주기 잡음을 주기 잡음으로 비틂) + 빛나는 주머니 + 번들거리는 반사.
static func _ooze(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.045, 3)
	var wx := Seam.field(w, h, s + 1, 0.03, 2)
	var wy := Seam.field(w, h, s + 2, 0.03, 2)
	var hh := PackedFloat32Array()
	hh.resize(w * h)
	for y in h:
		for x in w:
			var i := y * w + x
			hh[i] = Seam.at(hf, w, h, x + int((wx[i] - 0.5) * 26.0), y + int((wy[i] - 0.5) * 26.0))
	# 데이터 색이 밝아도 평균 맞추기 배율(최대 3배) 안에서 탁한 독녹색으로 남게 어둡게 칠한다 — 빛나는 결만 밝다.
	var deep := Color("#040904")
	var mid := Color("#12260c")
	for y in h:
		for x in w:
			var i := y * w + x
			var v := hh[i]
			var c := deep.lerp(mid, smoothstep(0.2, 0.75, v))
			if v > 0.66:  # 빛나는 주머니
				c = c.lerp(K.LIME.darkened(0.2), (v - 0.66) * 1.4)
			var band := absf(fposmod(v * 7.0, 1.0) - 0.5)
			if band < 0.07:  # 흐름 결
				c = c.lerp(K.LIME_DARK, 0.5 * (1.0 - band / 0.07))
			var r := Seam.relief(hf, w, h, x, y, 7.0)
			c = c.lerp(K.LIME_LIGHT, pow(clampf(r * 2.4 - 0.35, 0.0, 1.0), 2.0) * 0.8)  # 번들거림
			c = c.darkened(clampf(-r * 0.8, 0.0, 0.3))
			p.blend(x, y, c, 1.0)
