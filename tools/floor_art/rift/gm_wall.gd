extends RefCounted
## 녹색 탄광 벽(gm.gd가 부른다) — 윗면(top)·앞면(face) 바탕. 갱도 암벽 · 무너진 흙더미 · 판잣집 · 승강기 · 금 간 철로 벽 · 광맥.
## 앞면은 가로로만 이어진다: 칸 가장자리에 걸친 것(기둥·들보·광맥 띠)은 바탕에 주기적으로 넣고, 아래 skirt px는 들쭉날쭉 투명하게 끝낸다.
## 잔손질은 gm_wall2.gd.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Common := preload("res://tools/floor_art/rift/Common.gd")
const K := preload("res://tools/floor_art/rift/gm_kit.gd")

## 판잣집 앞면 판 경계(64 px 칸 기준) · 승강기 앞면 배치(64 px 칸 기준 y — 앞면 88 px)
const SHACK := [0.0, 12.0, 32.0, 46.0, 64.0]
const LIFT_ROPES := [20.0, 44.0]


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if part == "top":
		match style:
			"cavein":
				_rubble_top(p, col, s)
			"shack":
				_roof(p, col, s)
			"lift":
				_platform(p, col, s)
			"orevein":
				_rock_top(p, col, s, true)
			_:
				_rock_top(p, col, s, false)
		return
	match style:
		"cavein":
			_heap_face(p, col, s)
		"shack":
			_shack_face(p, col, s)
		"lift":
			_lift_face(p, col, s)
		"orevein":
			_rock_face(p, col, s)
			_vein_band(p, s)
		_:
			_rock_face(p, col, s)


## 바위 윗면(어두운 청회 덩어리 + 골). veins면 옅은 석영 줄.
static func _rock_top(p: Paint, col: Color, s: int, veins: bool) -> void:
	var w := p.w
	var h := p.h
	var fb := Seam.field(w, h, s, 0.05, 3)
	var cl := Seam.field(w, h, s + 3, 0.06, 1, true)
	var vf := Seam.field(w, h, s + 5, 0.03, 2)
	var tint := col.lerp(K.ROCK_DARK, 0.3)
	for i in w * h:
		fb[i] = fb[i] * 0.55 + cl[i] * 0.45
	for y in h:
		for x in w:
			var i := y * w + x
			var t := 0.42 + Seam.relief(fb, w, h, x, y, 6.0) * 0.6 + (fb[i] - 0.5) * 0.4
			var c := tint.darkened(0.55).lerp(tint.lightened(0.5), clampf(t, 0.0, 1.0))
			if cl[i] < 0.08:
				c = c.lerp(Ink.INK, 0.55 * (1.0 - cl[i] / 0.08))
			if veins:
				var d := absf(vf[i] - 0.5)
				if d < 0.025:
					c = c.lerp(K.QUARTZ.darkened(0.2), 0.6 * (1.0 - d / 0.025))
			p.blend(x, y, c, 1.0)


## 바위 앞면: 덩어리진 청회 암벽(층리 + 세포 덩어리) + 윗면과 만나는 턱 + 바닥으로 내려오는 밑동.
static func _rock_face(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var sk := Common.skirt
	var main := float(h - sk)
	var hf := Seam.field(w, h, s, 0.06, 4)
	var cl := Seam.field(w, h, s + 3, 0.045, 1, true)
	var lip := Seam.field(w, 8, s + 5, 0.12, 2)
	var jag := Seam.field(w, 8, s + 9, 0.1, 3)
	var tone := Seam.field(w, h, s + 7, 0.04, 2)
	var cf := Seam.field(w, h, s + 8, 0.05, 3)
	var hh := PackedFloat32Array()
	hh.resize(w * h)
	for y in h:
		for x in w:
			var i := y * w + x
			hh[i] = hf[i] * 0.4 + smoothstep(0.0, 0.3, cl[i]) * 0.3 + K.streak(cf, w, h, x, y, 3, 1) * 0.3  # 세로로 긴 바위 결
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := main + (0.25 + jag[x] * 0.75) * sk
			if y >= foot:
				continue
			var ly := 3.0 + lip[x] * 4.0 * main / 48.0
			var band := sin((y + hf[i] * 10.0) * 0.45) * 0.5 + 0.5
			var t := 0.42 + (band - 0.5) * 0.15 + Seam.relief(hh, w, h, x, y, 8.0) * 0.85 + (hh[i] - 0.5) * 0.4
			t -= smoothstep(main * 0.55, foot, float(y)) * 0.35
			if y < ly:
				t += 0.3
			var tint := col.lerp(K.ROCK, 0.45).lerp(K.ROCK_VIOLET, clampf((tone[i] - 0.5) * 1.5, 0.0, 0.4))
			var c := tint.darkened(0.5).lerp(tint.lightened(0.35), clampf(t, 0.0, 1.0))
			var dl := absf(y - ly)
			if dl < 1.6:
				c = c.lerp(Ink.INK, 0.7 * (1.0 - dl / 1.6))
			elif y > ly and y < ly + 5.0:
				c = c.darkened(0.25 * (1.0 - (y - ly) / 5.0))
			if cl[i] < 0.035:  # 바위 덩어리 사이 골
				c = c.lerp(Ink.INK, 0.55 * (1.0 - cl[i] / 0.035))
			if foot - y < 1.6 and sk > 0:
				c = c.lerp(Ink.INK, 0.6)
			p.blend(x, y, c, 1.0)


## 광맥 띠(바탕 — 칸을 가로질러 이어지는 옅은 석영 줄 + 녹색 광석 알갱이).
static func _vein_band(p: Paint, s: int) -> void:
	var w := p.w
	var main := float(p.h - Common.skirt)
	var vf := Seam.field(w, 8, s + 11, 0.05, 2)
	var th := Seam.field(w, 8, s + 12, 0.12, 2)
	var ore := Seam.field(w, 8, s + 13, 0.25, 1)
	for x in w:
		var cy := main * 0.5 + sin(TAU * x / w) * 4.0 * main / 48.0 + (vf[x] - 0.5) * 10.0
		var hw := (0.6 + th[x] * 2.2) * main / 48.0
		for y in range(int(cy - hw - 2), int(cy + hw + 3)):
			var d := absf(y - cy)
			if d > hw + 1.0:
				continue
			var c := K.QUARTZ.darkened(0.3 + (y - cy + hw) / (2.0 * hw) * 0.35)
			if ore[x] > 0.7 and d < hw * 0.7:
				c = K.LIME.lerp(K.LIME_LIGHT, (ore[x] - 0.7) * 2.0)
			if d > hw:
				c = Ink.INK
			p.blend(x, y, c, 0.9 if d <= hw else 0.6)


## 무너진 흙더미 윗면: 흙 사이 돌덩이(위에서 본 무더기).
static func _rubble_top(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var cl := Seam.field(w, h, s, 0.1, 1, true)
	var hf := Seam.field(w, h, s + 1, 0.05, 3)
	var tone := Seam.field(w, h, s + 2, 0.07, 2)
	var hh := PackedFloat32Array()
	hh.resize(w * h)
	for i in w * h:
		hh[i] = smoothstep(0.02, 0.3, cl[i]) * 0.65 + hf[i] * 0.35
	for y in h:
		for x in w:
			var i := y * w + x
			var t := 0.42 + Seam.relief(hh, w, h, x, y, 9.0) * 0.7 + (tone[i] - 0.5) * 0.3
			var stone := smoothstep(0.04, 0.12, cl[i])
			var tint := Color("#3a2e24").lerp(col.lerp(K.ROCK, 0.5), stone)
			var c := tint.darkened(0.5).lerp(tint.lightened(0.35), clampf(t, 0.0, 1.0))
			p.blend(x, y, c, 1.0)


## 무너진 흙더미 앞면: 흙과 돌이 쏟아진 경사(턱이 크게 들쭉날쭉).
static func _heap_face(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var sk := Common.skirt
	var main := float(h - sk)
	var cl := Seam.field(w, h, s, 0.055, 1, true)
	var hf := Seam.field(w, h, s + 1, 0.06, 3)
	var tone := Seam.field(w, h, s + 2, 0.06, 2)
	var lip := Seam.field(w, 8, s + 5, 0.09, 2)
	var jag := Seam.field(w, 8, s + 9, 0.12, 3)
	var hh := PackedFloat32Array()
	hh.resize(w * h)
	for i in w * h:
		hh[i] = smoothstep(0.02, 0.32, cl[i]) * 0.7 + hf[i] * 0.3
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := main + (0.15 + jag[x] * 0.85) * sk
			if y >= foot:
				continue
			var ly := 2.0 + lip[x] * 9.0 * main / 60.0
			var stone := smoothstep(0.03, 0.12, cl[i])
			var tint := Color("#3e3228").lerp(col.lerp(K.ROCK, 0.45).lerp(K.ROCK_VIOLET, clampf(tone[i] - 0.5, 0.0, 0.3)), stone)
			var t := 0.44 + Seam.relief(hh, w, h, x, y, 9.0) * 0.75 + (tone[i] - 0.5) * 0.3
			t -= smoothstep(main * 0.5, foot, float(y)) * 0.3
			if y < ly + 2.0:
				t += 0.25
			var c := tint.darkened(0.5).lerp(tint.lightened(0.32), clampf(t, 0.0, 1.0))
			if y < ly:
				c = c.lerp(Ink.INK, 0.8) if y > ly - 1.5 else Color(0, 0, 0, 0)
			if foot - y < 1.6 and sk > 0:
				c = c.lerp(Ink.INK, 0.6)
			if c.a > 0.0:
				p.blend(x, y, c, 1.0)
		# 턱 위(윗면과 만나는 곳)는 윗면 색 덩어리로 채운다
	for x in w:
		var ly := 2.0 + lip[x] * 9.0 * main / 60.0
		for y in range(0, int(ly - 1.0)):
			var i := y * w + x
			p.blend(x, y, Color("#2a241e").lerp(Color("#40362c"), hf[i]), 1.0)


## 판잣집 지붕(위에서): 가로로 겹친 널판(단 주기 16 px) + 때·이끼.
static func _roof(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var sc := w / 64.0
	var per := 16.0 * sc
	var gf := Seam.field(w, h, s, 0.06, 3)
	var hf := Seam.field(w, h, s + 1, 0.04, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var j := int(y / per)
			var py := fposmod(y, per)
			var jx := fposmod(j * 21.0 + 7.0, 32.0) * sc
			var seg := int(fposmod(x - jx, w) / (32.0 * sc))
			var tn := Paint.hash01(j, seg, 9) * 0.3 - 0.15
			var g := K.streak(gf, w, h, x, y, 1, 4)
			var c := col.darkened(0.2 - tn).lerp(col.lightened(0.2 + tn), g)
			c = c.darkened(py / per * 0.3)  # 위 널판이 덮은 아래쪽 그늘
			if py < 1.5 * sc:
				c = c.lerp(Ink.INK, 0.7)
			elif py < 3.0 * sc:
				c = c.lightened(0.12)  # 널판 끝 빛
			if absf(fposmod(x - jx, 32.0 * sc)) < 0.9:
				c = c.lerp(Ink.INK, 0.6)
			if hf[i] > 0.62:
				c = c.lerp(Color("#3a4228"), (hf[i] - 0.62) * 1.4)  # 이끼·곰팡이
			p.blend(x, y, c, 1.0)


## 판잣집 앞면: 세로 널판 4장(폭이 다름) + 가로 띠장 2줄 + 지붕 처마 그늘 + 썩은 밑동.
static func _shack_face(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var sc := w / 64.0
	var sk := Common.skirt
	var main := float(h - sk)
	var gf := Seam.field(w, h, s, 0.06, 3)
	var hf := Seam.field(w, h, s + 1, 0.04, 2)
	var jag := Seam.field(w, 8, s + 9, 0.15, 2)
	var bands := [[10.0 * main / 80.0, 16.0 * main / 80.0], [main - 22.0 * main / 80.0, main - 16.0 * main / 80.0]]
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := main + (0.3 + jag[x] * 0.7) * sk
			if y >= foot:
				continue
			var lx := x / sc
			var b := 0
			for k in 4:
				if lx >= float(SHACK[k]):
					b = k
			var bl := lx - float(SHACK[b])
			var bw := float(SHACK[b + 1]) - float(SHACK[b])
			var tn := Paint.hash01(b, 21) * 0.26 - 0.13
			var g := K.streak(gf, w, h, x, y, 4, 1)
			var c := col.darkened(0.3 - tn).lerp(col.lightened(0.12 + tn), g)
			c = c.darkened(clampf((hf[i] - 0.45) * 0.5, 0.0, 0.3))
			c = c.darkened(smoothstep(main * 0.6, foot, float(y)) * 0.4)  # 썩은 밑동
			if bl < 1.0 or bl > bw - 0.8:
				c = c.lerp(K.VOID, 0.8)  # 널 사이 틈
			elif bl < 2.2:
				c = c.lightened(0.1)
			elif bl > bw - 2.5:
				c = c.darkened(0.25)
			for bd: Array in bands:  # 띠장
				var y0: float = bd[0]
				var y1: float = bd[1]
				if y >= y0 and y < y1:
					c = col.darkened(0.12).lerp(col.lightened(0.15), K.streak(gf, w, h, x, y, 1, 4))
					if y < y0 + 1.0:
						c = c.lightened(0.15)
					elif y >= y1 - 1.2:
						c = c.lerp(Ink.INK, 0.7)
				elif y >= y1 and y < y1 + 2.5:
					c = c.darkened(0.3)
			if y < 4.0 * sc:  # 처마 끝
				c = K.WOOD_DARK.darkened(0.2)
			elif y < 9.0 * sc:
				c = c.darkened(0.45 * (1.0 - (y - 4.0 * sc) / (5.0 * sc)))
			if foot - y < 1.6 and sk > 0:
				c = c.lerp(Ink.INK, 0.6)
			p.blend(x, y, c, 1.0)
	for bd: Array in bands:  # 띠장 못(널판마다)
		for k in 4:
			var cx := (float(SHACK[k]) + float(SHACK[k + 1])) * 0.5 * sc
			K.nail(p, Vector2(cx, (float(bd[0]) + float(bd[1])) * 0.5), 0.9 * sc)


## 승강기 바닥(위에서): 가로 널판 + 앞쪽 쇠 난간·문살.
static func _platform(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var sc := w / 64.0
	var gf := Seam.field(w, h, s, 0.06, 3)
	var per := 8.0 * sc
	for y in h:
		for x in w:
			var j := int(y / per)
			var py := fposmod(y, per)
			var tn := Paint.hash01(j, 4) * 0.24 - 0.12
			var c := col.darkened(0.2 - tn).lerp(col.lightened(0.15 + tn), K.streak(gf, w, h, x, y, 1, 4))
			if py < 1.0:
				c = c.lerp(K.VOID, 0.7)
			elif py > per - 1.5:
				c = c.darkened(0.25)
			var gy := y - 52.0 * sc
			if gy >= 0.0 and gy < 3.0 * sc:  # 문 가로대
				c = K.IRON.lerp(K.RUST, 0.3).lightened(0.2 if gy < 1.0 else 0.0)
			elif gy >= 3.0 * sc and gy < 5.0 * sc:
				c = c.darkened(0.5)
			if absf(fposmod(x, 8.0 * sc) - 4.0 * sc) < 1.1 and y > 48.0 * sc and y < 62.0 * sc:
				c = K.IRON.darkened(0.2)  # 문살
			if absf(fposmod(x, 32.0 * sc) - 16.0 * sc) < 0.8:
				c = c.lerp(Ink.INK, 0.4)
			p.blend(x, y, c, 1.0)


## 승강기 앞면: 어두운 승강로 + 칸 가장자리에 걸친 기둥 + 위 들보 · 가운데 가로대 · 빗장 + 밧줄 2줄 + 아래 발판 들보.
static func _lift_face(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var sc := w / 64.0
	var sk := Common.skirt
	var main := float(h - sk)
	var my := main / 88.0
	var gf := Seam.field(w, h, s, 0.06, 3)
	var hf := Seam.field(w, h, s + 1, 0.05, 3)
	var jag := Seam.field(w, 8, s + 9, 0.15, 2)
	var brace_a := Vector2(5.0 * sc, 10.0 * my)
	var brace_b := Vector2(59.0 * sc, 46.0 * my)
	for y in h:
		for x in w:
			var i := y * w + x
			var foot := main + (0.3 + jag[x] * 0.7) * sk
			if y >= foot:
				continue
			var c := K.VOID.lerp(Color("#1a1824"), hf[i] * 0.8)  # 승강로 어둠
			var lx := fposmod(x + 5.0 * sc, w)
			var q := Vector2(x, y)
			var bd := _seg_dist(q, brace_a, brace_b)
			if bd < 3.0 * sc:  # 빗장
				c = col.darkened(0.3).lerp(col.lightened(0.05), K.streak(gf, w, h, x, y, 2, 2))
				if bd > 2.2 * sc:
					c = c.lerp(Ink.INK, 0.7)
			for rx: float in LIFT_ROPES:  # 밧줄
				var d := x - rx * sc
				if absf(d) < 1.6 * sc and y > 9.0 * my and y < 72.0 * my:
					c = Color("#8a7a5a").darkened(0.35 if fposmod(y + d * 2.0, 4.0) < 2.0 else 0.05)
					if d > 1.0:
						c = c.darkened(0.3)
			if lx < 10.0 * sc:  # 기둥(칸 경계에 걸침)
				c = col.darkened(0.25).lerp(col.lightened(0.1), K.streak(gf, w, h, x, y, 4, 1))
				if lx < 1.8 * sc:
					c = c.lightened(0.15)
				elif lx > 8.2 * sc:
					c = c.lerp(Ink.INK, 0.6)
			elif lx < 12.5 * sc:
				c = c.darkened(0.4)
			for beam: Array in [[0.0, 9.0], [44.0, 50.0], [72.0, 86.0]]:  # 들보·가로대·발판
				var y0 := float(beam[0]) * my
				var y1 := float(beam[1]) * my
				if y >= y0 and y < y1:
					c = col.darkened(0.15).lerp(col.lightened(0.18), K.streak(gf, w, h, x, y, 1, 4))
					if y < y0 + 1.2:
						c = c.lightened(0.18)
					elif y >= y1 - 1.3:
						c = c.lerp(Ink.INK, 0.75)
					if y1 - y0 > 10.0 and absf(y - (y0 + y1) * 0.5) < 0.7:
						c = c.lerp(Ink.INK, 0.5)
					if absf(fposmod(x, 32.0 * sc) - 16.0 * sc) < 2.5 * sc and y1 - y0 > 10.0:
						c = K.IRON.darkened(0.15).lerp(K.RUST, 0.3)  # 쇠 띠
				elif y >= y1 and y < y1 + 3.0 * my and y1 < 80.0:
					c = c.darkened(0.4)
			if foot - y < 1.6 and sk > 0:
				c = c.lerp(Ink.INK, 0.6)
			p.blend(x, y, c, 1.0)


static func _seg_dist(q: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return q.distance_to(a + ab * t)
