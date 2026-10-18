extends RefCounted
## 빙하굴 바닥 바탕(gc.gd 전용): 눈 · 얼음 · 언 호수 · 얼음 계단 · 얼어붙은 뼈(서리 땅) · 얼음 자갈 · 지하 강 · 미끄러운 얼음 · 급경사 · 로프 다리.
## 바탕은 주기 잡음(Seam)과 칸 폭의 정수배 주기 무늬만 쓴다 — 이어 붙여도 이음매가 없다. 잔손질은 gc_floor_detail.gd.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Mat := preload("res://tools/floor_art/rift/gc_mat.gd")


static func base(p: Paint, style: String, col: Color, s: int) -> void:
	var tn := Mat.tone(col)
	match style:
		"snow":
			_snow(p, tn, s, 0.0)
		"frozenbones":
			_snow(p, tn, s, 1.0)
		"ice":
			_ice(p, tn, s, false)
		"slick":
			_ice(p, tn, s, true)
		"frozenlake":
			_lake(p, tn, s)
		"icestairs":
			_stairs(p, tn, s)
		"icegravel":
			_gravel(p, tn, s)
		"river":
			_river(p, tn, s)
		"slope":
			_slope(p, tn, s)
		"ropespan":
			_rope(p, tn, s)
		_:
			for y in p.h:
				for x in p.w:
					p.blend(x, y, tn, 1.0)


## 눈밭(grit = 0) · 서리 땅(grit = 1 — 얼어붙은 뼈 바닥: 회색 서리에 흙 알갱이). 부드러운 둔덕 + 바람 물결 + 반짝임.
static func _snow(p: Paint, tn: Color, s: int, grit: float) -> void:
	var w := p.w
	var h := p.h
	var lo := Seam.field(w, h, Mat.shared(s), 0.02, 2)
	var hf := Seam.field(w, h, s, 0.07, 3)
	var rip := Seam.field(w, h, s + 4, 0.05, 2)
	var fine := Seam.field(w, h, s + 2, 0.32, 2)
	var lit := Mat.mul(tn, 1.07, 1.07, 1.06)
	var shade := Mat.mul(tn, 0.72, 0.8, 0.96)
	if grit > 0.0:
		shade = Mat.mul(tn, 0.68, 0.74, 0.92)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 3.0)  # 잔물결 같은 눈 결(약하게)
			var ph := TAU * float(3 * x + 6 * y) / float(w) + rip[i] * 5.0
			var rr := sin(ph) * smoothstep(0.5, 0.7, rip[i])  # 바람 물결은 군데군데
			var t := 0.66 + r * 0.9 + rr * 0.05 + (fine[i] - 0.5) * 0.06 + (lo[i] - 0.5) * 0.14
			var c := Mat.ramp(t, shade, tn, lit)
			if grit > 0.0:
				if fine[i] < 0.2:  # 서리 밑 흙·자갈 알갱이
					c = c.lerp(Mat.mul(tn, 0.55, 0.52, 0.5), (0.2 - fine[i]) * 3.0)
				if rip[i] < 0.35:  # 녹았다 언 회색 얼룩
					c = c.lerp(Mat.mul(tn, 0.86, 0.88, 0.92), 0.3)
			if fine[i] > 0.84 and r > 0.0:  # 눈 결정 반짝임
				c = c.lerp(Mat.SPARK, clampf((fine[i] - 0.84) * 5.0, 0.0, 0.9))
			p.blend(x, y, c, 1.0)


## 동굴 얼음 바닥 / 미끄러운 얼음(gloss): 속 깊이에 따른 남빛 얼룩 + 얼음 속 깨진 면 + 서리 · 광택 줄.
static func _ice(p: Paint, tn: Color, s: int, gloss: bool) -> void:
	var w := p.w
	var h := p.h
	var deep := Seam.field(w, h, s, 0.045, 3)
	var cl := Seam.field(w, h, s + 3, 0.08, 1, true)
	var fr := Seam.field(w, h, Mat.shared(s) + 5, 0.045, 3)
	var fine := Seam.field(w, h, s + 6, 0.25, 2)
	var dark := Mat.mul(tn, 0.6, 0.74, 0.9)
	var lit := Mat.mul(tn, 1.06, 1.1, 1.1)
	var plane := Mat.mul(tn, 1.22, 1.24, 1.22)
	var frost_c := Mat.mul(tn, 1.1, 1.12, 1.1)
	if gloss:
		dark = Mat.mul(tn, 0.7, 0.82, 0.95)
	for y in h:
		for x in w:
			var i := y * w + x
			var t := 0.54 + (deep[i] - 0.5) * (0.5 if not gloss else 0.3) + Seam.relief(deep, w, h, x, y, 4.0) * (0.4 if not gloss else 0.3)
			var c := Mat.ramp(t, dark, tn, lit)
			if cl[i] < 0.09 and not gloss:  # 얼음 속 깨진 면(흰 결)
				c = c.lerp(plane, 0.55 * (1.0 - cl[i] / 0.09) * (0.4 + deep[i]))
			if gloss:
				var ph := TAU * float(x - y) / float(w)
				var sheen := pow(0.5 + 0.5 * sin(ph), 10.0) * (0.4 + cl[i] * 0.8)  # 넓은 광택 띠(곧은 사선)
				var thin := pow(0.5 + 0.5 * sin(TAU * float(3 * x - 3 * y) / float(w) + fine[i] * 1.2), 40.0)
				c = c.lerp(Mat.mul(tn, 0.8, 0.9, 1.02), (1.0 - sheen) * 0.25 * fr[i])  # 비친 푸른 그늘
				c = c.lerp(Mat.mul(tn, 1.12, 1.12, 1.1), sheen * 0.6)
				var spec := pow(0.5 + 0.5 * sin(ph + 0.35), 60.0) * smoothstep(0.3, 0.6, cl[i])
				c = c.lerp(Mat.SPARK, clampf(spec * 0.85 + thin * 0.6 * smoothstep(0.35, 0.65, fr[i]), 0.0, 0.85))
			else:
				var f := smoothstep(0.58, 0.74, fr[i] + (fine[i] - 0.5) * 0.35)  # 서리 낀 곳(무광)
				c = c.lerp(frost_c.darkened((1.0 - fine[i]) * 0.08), f * 0.7)
			p.blend(x, y, c, 1.0)


## 언 호수: 매끈한 짙은 얼음 + 흰 금 그물(세포 경계) + 금 옆 그늘 + 은은한 광택.
static func _lake(p: Paint, tn: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var deep := Seam.field(w, h, Mat.shared(s), 0.02, 3)
	var cl := Seam.field(w, h, s + 3, 0.032, 1, true)
	var cl2 := Seam.field(w, h, s + 8, 0.08, 1, true)
	var dark := Mat.mul(tn, 0.55, 0.7, 0.9)
	var lit := Mat.mul(tn, 1.05, 1.08, 1.08)
	for y in h:
		for x in w:
			var i := y * w + x
			var t := 0.52 + (deep[i] - 0.5) * 0.6
			var c := Mat.ramp(t, dark, tn, lit)
			var ph := TAU * float(x - 2 * y) / float(w) + deep[i] * 3.0
			c = c.lerp(lit, pow(0.5 + 0.5 * sin(ph), 6.0) * 0.4)  # 광택
			if cl[i] < 0.07:  # 금 옆 흐린 그늘
				c = c.lerp(dark, 0.3 * (1.0 - cl[i] / 0.07))
			c = c.lerp(Mat.SPARK, 0.7 * smoothstep(0.035, 0.0, cl[i]))  # 큰 금(흰 선)
			c = c.lerp(Mat.mul(tn, 1.25, 1.27, 1.25), 0.3 * smoothstep(0.04, 0.0, cl2[i]) * smoothstep(0.45, 0.6, deep[i]))  # 잔금
			p.blend(x, y, c, 1.0)


## 얼음 계단: 칸에 두 단(32px 주기) — 위에서부터 앞턱 빛 → 앞면(그늘, 세로 결) → 아래 골 잉크 → 디딤면(서리).
static func _stairs(p: Paint, tn: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var ef := Seam.field(w, 8, s + 3, 0.12, 2)
	var hf := Seam.field(w, h, s, 0.06, 3)
	var fine := Seam.field(w, h, s + 6, 0.3, 2)
	var vs := Seam.field(w, 8, s + 9, 0.3, 2)
	var period := h / 2.0
	var riser := 9.0 * h / 64.0
	var dark := Mat.mul(tn, 0.55, 0.68, 0.86)
	var lit := Mat.mul(tn, 1.07, 1.07, 1.06)
	var face := Mat.mul(tn, 0.74, 0.86, 1.0)
	for y in h:
		for x in w:
			var i := y * w + x
			var yy := fposmod(float(y) + (ef[x] - 0.5) * 4.0, period)
			var c: Color
			if yy < riser:
				var t := 0.45 + (vs[x] - 0.5) * 0.7 + (fine[i] - 0.5) * 0.15 - yy / riser * 0.25
				c = Mat.ramp(t, dark, face, tn)
				if yy < 1.6:  # 앞턱 빛
					c = c.lerp(Mat.SPARK, 0.75 * (1.0 - yy / 1.6))
				elif yy > riser - 1.8:  # 골
					c = c.lerp(Ink.INK, 0.6 * (yy - (riser - 1.8)) / 1.8)
			else:
				var t := 0.64 + Seam.relief(hf, w, h, x, y, 6.0) * 1.0 + (fine[i] - 0.5) * 0.08 + (hf[i] - 0.5) * 0.12
				t -= (1.0 - smoothstep(riser, riser + 5.0, yy)) * 0.2  # 앞면 밑 그늘
				c = Mat.ramp(t, dark, tn, lit)
				if yy > period - 2.5:  # 다음 앞턱의 윗모서리 둥글림
					c = c.lerp(lit, 0.35)
			p.blend(x, y, c, 1.0)


## 얼음 자갈: 세포 잡음 돌 덩어리 — 덩어리 높이로 왼쪽 위 빛, 사이 골 어둡게, 일부는 푸른 얼음 조각, 위쪽 면에 서리.
static func _gravel(p: Paint, tn: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var cl := Seam.field(w, h, s + 3, 0.075, 1, true)
	var cs := Seam.field(w, h, s + 7, 0.16, 1, true)
	var lo := Seam.field(w, h, s + 1, 0.06, 2)
	var fine := Seam.field(w, h, s + 6, 0.3, 2)
	var hgt := PackedFloat32Array()
	hgt.resize(w * h)
	for i in w * h:
		var big := lo[i] > 0.5  # 굵은 돌 · 잔자갈이 섞인다
		cl[i] = cl[i] if big else cs[i] * 1.2
		hgt[i] = smoothstep(0.0, 0.3, cl[i]) * 0.8 + fine[i] * 0.2
	var dark := Mat.mul(tn, 0.55, 0.57, 0.62)
	var lit := Mat.mul(tn, 1.1, 1.11, 1.12)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hgt, w, h, x, y, 5.0)
			var t := 0.55 + r * 1.0 + (fine[i] - 0.5) * 0.08
			var c := Mat.ramp(t, dark, tn, lit)
			if lo[i] > 0.62:  # 푸른 얼음 조각
				c = c.lerp(Mat.mul(c, 0.82, 1.02, 1.22), smoothstep(0.62, 0.72, lo[i]))
			elif lo[i] < 0.34:  # 짙은 돌
				c = c.lerp(Mat.mul(c, 0.78, 0.76, 0.76), smoothstep(0.34, 0.26, lo[i]))
			if cl[i] < 0.05:  # 돌 사이 골
				c = c.lerp(Mat.mul(tn, 0.4, 0.42, 0.48), 0.6 * (1.0 - cl[i] / 0.05))
			if r > 0.05 and fine[i] > 0.6:  # 위를 향한 면의 서리
				c = c.lerp(Mat.mul(tn, 1.15, 1.17, 1.2), clampf((r - 0.05) * 5.0, 0.0, 0.5))
			p.blend(x, y, c, 1.0)


## 지하 강: 가로로 흐르는 짙은 청록 물 — 가로로 늘인 잡음 결 + 흰 물보라 줄 + 물살 아래 그늘.
static func _river(p: Paint, tn: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var a := Seam.field(w / 8, h, s, 0.2, 3)
	var b := Seam.field(w / 4, h, s + 1, 0.12, 3)
	var lo := Seam.field(w, h, s + 2, 0.03, 2)
	var deep := Mat.mul(tn, 0.3, 0.5, 0.62)
	var lit := Mat.mul(tn, 1.0, 1.35, 1.3)
	for y in h:
		for x in w:
			var i := y * w + x
			var fa := Mat.sample(a, w / 8, h, x / 8.0, y)
			var fb := Mat.sample(b, w / 4, h, x / 4.0 + fa * 2.0, y)
			var t := 0.45 + (fb - 0.5) * 1.1 + (lo[i] - 0.5) * 0.4
			var c := Mat.ramp(t, deep, tn, lit)
			var foam := smoothstep(0.68, 0.8, fa * 0.6 + fb * 0.4 + (lo[i] - 0.5) * 0.2)
			var under := smoothstep(0.58, 0.66, Mat.sample(a, w / 8, h, x / 8.0, y - 1.5))  # 물보라 바로 아래 그늘
			c = c.lerp(deep.darkened(0.3), under * (1.0 - foam) * 0.5)
			c = c.lerp(Color("#dceef0"), foam * 0.9)
			p.blend(x, y, c, 1.0)


## 얼음 급경사: 비탈을 따라 비스듬히 난 결(능선 빛 · 골 그늘) + 큰 얼룩 + 골에 낀 서리.
static func _slope(p: Paint, tn: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, s, 0.04, 3)
	var wf := Seam.field(w, h, s + 2, 0.06, 2)
	var fine := Seam.field(w, h, s + 6, 0.3, 2)
	var dark := Mat.mul(tn, 0.45, 0.58, 0.78)
	var lit := Mat.mul(tn, 1.12, 1.18, 1.2)
	for y in h:
		for x in w:
			var i := y * w + x
			var ph := TAU * float(4 * x + 2 * y) / float(w) + wf[i] * 2.5
			var st := sin(ph)
			var edge := cos(ph)  # 결의 왼쪽 위 사면 = 빛
			var t := 0.52 + (hf[i] - 0.5) * 0.3 + Seam.relief(hf, w, h, x, y, 5.0) * 0.5 - edge * 0.24 + (fine[i] - 0.5) * 0.08
			var c := Mat.ramp(t, dark, tn, lit)
			if st > 0.8:  # 골
				c = c.lerp(dark.darkened(0.3), (st - 0.8) * 3.5)
				if fine[i] > 0.6:
					c = c.lerp(Mat.mul(tn, 1.25, 1.28, 1.3), 0.5)
			p.blend(x, y, c, 1.0)


## 로프 다리(동서로 건넌다): 칸 가운데 띠에 세로로 놓인 나무 판자 6장 + 판자 밑 받침 줄 두 가닥 + 위아래 손잡이 줄,
## 판자 사이와 띠 밖은 짙은 낭떠러지.
static func _rope(p: Paint, tn: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var u := w / 64.0
	var grain := Seam.field(w, h / 4, s, 0.2, 2)
	var fr := Seam.field(w, h, s + 5, 0.07, 3)
	var lo := Seam.field(w, h, s + 2, 0.05, 2)
	var void_c := Mat.mul(tn, 0.12, 0.15, 0.22)
	var wood := Color(tn.r * 1.3, tn.g * 0.92, tn.b * 0.56)
	var rope := Color(tn.r * 1.6, tn.g * 1.05, tn.b * 0.42)
	var n := 6
	var sw := float(w) / n
	var top := 10.0 * u
	var bot := 54.0 * u
	for y in h:
		for x in w:
			var i := y * w + x
			var c := void_c.lerp(Mat.mul(tn, 0.26, 0.34, 0.48), lo[i] * 0.6)  # 저 아래 희미한 얼음빛
			for ry: float in [20.0 * u, 44.0 * u]:  # 받침 줄(판자 사이로 보임)
				var d := absf(y - ry)
				if d < 1.8 * u:
					c = rope.darkened(0.35 + d / (1.8 * u) * 0.3)
			var k := floori(x / sw)
			var lx := fposmod(float(x), sw)
			var jit := (Paint.hash01(k, 3, s % 97) - 0.5) * 3.0 * u
			if lx > 1.0 * u and lx < sw - 1.6 * u and y > top + jit and y < bot + jit * 0.6:
				var tone := 0.85 + Paint.hash01(k, 7, s % 97) * 0.3
				var g := Mat.sample(grain, w, h / 4, x, y / 4.0)
				var side := (lx - 1.0 * u) / (sw - 2.6 * u)
				var t := 0.45 + (g - 0.5) * 0.6 - side * 0.35
				var cc := Mat.ramp(t, wood.darkened(0.45), Mat.mul(wood, tone, tone, tone), wood.lightened(0.25))
				if side < 0.12:
					cc = cc.lightened(0.15)  # 왼쪽 모서리 빛
				elif side > 0.86:
					cc = cc.lerp(Ink.INK, 0.5)
				if absf(y - (top + jit)) < 1.2 * u or absf(y - (bot + jit * 0.6)) < 1.2 * u:
					cc = cc.lerp(Ink.INK, 0.6)  # 판자 끝 잉크
				var f := smoothstep(0.7, 0.85, fr[i])  # 서리
				c = cc.lerp(Mat.mul(tn, 1.15, 1.15, 1.15), f * 0.4)
			if absf(lx - sw * 0.5) < 0.9 * u and ((y > 7.0 * u and y < top + jit) or (y < 57.0 * u and y > bot + jit * 0.6)):
				c = rope.darkened(0.3)  # 판자를 손잡이 줄에 매단 끈
			for hy: float in [5.5 * u, 58.5 * u]:  # 손잡이 줄(꼰 줄)
				var d := y - hy
				var rw := 2.6 * u
				if absf(d) < rw:
					var tw := 0.5 + 0.5 * sin(TAU * float(x) * 12.0 / float(w) + d * 1.3)
					var cc := rope.lightened(0.2 - (d / rw + 1.0) * 0.25).darkened(tw * 0.3)
					if absf(d) > rw - 0.9 * u:
						cc = cc.lerp(Ink.INK, 0.7)
					c = cc
			p.blend(x, y, c, 1.0)
