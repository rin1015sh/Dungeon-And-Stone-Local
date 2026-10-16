extends RefCounted
## 1층 수정동굴 재질 칸 그리기(tools/paint_floor.gd 전용): 젖은 석회암 바닥 · 거친 암벽(윗면·앞면) · 수정 박힌 암벽 · 물 · 진흙.
## 칸 하나 = 가장자리 띠는 모든 변형이 같은 바탕(Seam 주기 잡음 — 칸끼리 이어진다), 안쪽은 변형마다 다른 시드의 바탕 +
## 다른 잔손질(돌·금·물기·수정). 안쪽 그림은 가장자리에서 공통 바탕으로 녹아든다(Seam.mask) — 같은 무늬가 격자로 반복되지 않게. 빛은 그리지 않고 중립 밝기로 칠한다 — 게임이 꼭짓점 빛을 곱한다.
## 스스로 빛나는 수정만 밝게 굽는다. 칠은 city_art의 Paint(캔버스)·Ink(잉크 선·붓 자국)를 쓴다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")

const CRYSTAL_LIGHT := Color("#c9b8ff")
const CRYSTAL_DARK := Color("#3e2a78")
const CRYSTAL_GLOW := Color("#8f6cff")

## 재질마다 변형 번호 → 잔손질 종류(짝수 번호 무리·홀수 번호 무리에 비슷한 종류가 고루 들어가게 — FloorArtLayer)
const KINDS := {
	"limestone": ["plain", "plain", "crack", "pebbles", "pebbles", "crack", "wet", "dimples"],
	"rock_top": ["plain", "crack", "rubble", "pits", "crack", "rubble"],
	"rock_face": ["plain", "fissure", "bulge", "drip", "fissure", "ledge"],
	"crystal_top": ["one", "vein", "small", "one", "vein", "two"],
	"crystal_face": ["one", "two", "one", "two", "one", "small"],
	"water": ["plain", "ring", "specks", "plain", "ring", "scum"],
	"mud": ["plain", "puddle", "prints", "puddle", "lumps", "prints"],
}


## 재질 style의 칸 하나(part = floor / top / face). col = 타일 평균 색(data/tiles.json colors).
static func cell(style: String, part: String, v: int, w: int, h: int, col: Color, seed_value: int) -> Paint:
	var key := style + ("_" + part if part != "floor" else "")
	var edge := Paint.new(w, h, seed_value)
	_base(edge, key, col, seed_value)
	var base := edge.buf
	var p := Paint.new(w, h, seed_value * 31 + v * 977 + 7)
	_base(p, key, col, seed_value + 1000 * (v + 1))
	var kinds: Array = KINDS.get(key, ["plain"])
	_details(p, key, str(kinds[v % kinds.size()]), col)
	var band := w * 0.14
	for y in h:
		for x in w:
			var m := Seam.mask(x, y, w, h, band, part == "face")
			var i := (y * w + x) * 4
			for j in 4:
				p.buf[i + j] = lerpf(base[i + j], p.buf[i + j], m)
	return p


# ── 바탕(변형 공통) ─────────────────────────────────────

static func _base(p: Paint, key: String, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	match key:
		"limestone":
			var hf := Seam.field(w, h, s, 0.035, 3)
			var st := Seam.field(w, h, s + 1, 0.03, 3)
			var fine := Seam.field(w, h, s + 2, 0.2, 2)
			for y in h:
				for x in w:
					var i := y * w + x
					var t := 0.45 + (hf[i] - 0.5) * 0.45 + Seam.relief(hf, w, h, x, y, 4.0) * 0.35 + (fine[i] - 0.5) * 0.08
					var c := col.darkened(0.42).lerp(col.lightened(0.28), clampf(t, 0.0, 1.0))
					if st[i] > 0.58:  # 물이 스민 얼룩
						c = c.lerp(Color("#2a2a36"), (st[i] - 0.58) * 1.1)
					p.blend(x, y, c, 1.0)
		"rock_top", "crystal_top":
			var fb := Seam.field(w, h, s, 0.05, 3)
			var cl := Seam.field(w, h, s + 3, 0.06, 1, true)
			var tint := col if key == "rock_top" else col.lerp(Color("#2a2240"), 0.3)
			for y in h:
				for x in w:
					var i := y * w + x
					var hf := fb[i] * 0.55 + cl[i] * 0.45
					fb[i] = hf
			for y in h:
				for x in w:
					var i := y * w + x
					var t := 0.42 + Seam.relief(fb, w, h, x, y, 6.0) * 0.6 + (fb[i] - 0.5) * 0.4
					var c := tint.darkened(0.55).lerp(tint.lightened(0.5), clampf(t, 0.0, 1.0))
					if cl[i] < 0.08:  # 바위 덩어리 사이 골
						c = c.lerp(Ink.INK, 0.55 * (1.0 - cl[i] / 0.08))
					p.blend(x, y, c, 1.0)
		"rock_face", "crystal_face":
			var hf := Seam.field(w, h, s, 0.06, 4)
			var lip := Seam.field(w, 8, s + 5, 0.12, 2)
			var tint := col if key == "rock_face" else col.lerp(Color("#4a3a6a"), 0.35)
			for y in h:
				for x in w:
					var i := y * w + x
					var ly := 3.0 + lip[x] * 4.0 * h / 48.0  # 윗면과 만나는 들쭉날쭉한 턱
					var band := sin((y + hf[i] * 10.0) * 0.5) * 0.5 + 0.5  # 층리
					var t := 0.42 + (band - 0.5) * 0.28 + Seam.relief(hf, w, h, x, y, 6.0) * 0.7 + (hf[i] - 0.5) * 0.3
					t -= smoothstep(h * 0.55, float(h), float(y)) * 0.35  # 바닥 쪽 그늘
					if y < ly:
						t += 0.3
					var c := tint.darkened(0.5).lerp(tint.lightened(0.35), clampf(t, 0.0, 1.0))
					var dl := absf(y - ly)
					if dl < 1.6:  # 턱 아래 잉크
						c = c.lerp(Ink.INK, 0.7 * (1.0 - dl / 1.6))
					elif y > ly and y < ly + 5.0:  # 턱이 드리운 그늘
						c = c.darkened(0.25 * (1.0 - (y - ly) / 5.0))
					if absf(band - 0.5) < 0.05 and hf[i] > 0.45:  # 층리 사이 가는 골
						c = c.lerp(Ink.INK, 0.35)
					p.blend(x, y, c, 1.0)
		"water":
			var hf := Seam.field(w, h, s, 0.04, 3)
			var rp := Seam.field(w, h, s + 7, 0.06, 2)
			for y in h:
				for x in w:
					var i := y * w + x
					var r := Seam.relief(rp, w, h, x, y, 5.0)
					var c := col.darkened(0.45).lerp(col.lightened(0.15), clampf(hf[i], 0.0, 1.0))
					c = c.lerp(Color("#9ab4cc"), pow(clampf(r * 2.0, 0.0, 1.0), 2.0) * 0.45)  # 물결 반사
					p.blend(x, y, c, 1.0)
		"mud":
			var hf := Seam.field(w, h, s, 0.08, 3)
			var wet := Seam.field(w, h, s + 2, 0.04, 2)
			for y in h:
				for x in w:
					var i := y * w + x
					var r := Seam.relief(hf, w, h, x, y, 6.0)
					var c := col.darkened(0.4).lerp(col.lightened(0.2), clampf(0.45 + r * 0.8 + (hf[i] - 0.5) * 0.3, 0.0, 1.0))
					if wet[i] > 0.55 and r > 0.15:  # 젖은 진흙의 번들거림
						c = c.lerp(Color("#b8a890"), (r - 0.15) * 0.8)
					p.blend(x, y, c, 1.0)
		_:
			for y in h:
				for x in w:
					p.blend(x, y, col, 1.0)


## 붓 자국(밑색을 조금씩 밝히거나 어둡게 덧칠) — 칸 안쪽만(가장자리는 mask가 바탕으로 되돌린다).
static func _brush(p: Paint, amt: float) -> void:
	var s := float(p.w) / 64.0
	Ink.strokes(p, Paint.rect_poly(0, 0, p.w, p.h), 0.8, 9.0 * s, 3.0 * s, 70.0, amt, 0.3)


# ── 잔손질(변형마다) ────────────────────────────────────

static func _details(p: Paint, key: String, kind: String, col: Color) -> void:
	var s := float(p.w) / 64.0
	var c := Vector2(p.w, p.h) * 0.5
	match kind:
		"plain":
			if key != "water":
				_brush(p, 0.08)
		"crack", "fissure":
			var n := 1 if kind == "fissure" else p.rng.randi_range(1, 2)
			for k in n:
				var start := c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-12, 8)) * s
				if kind == "fissure":
					start = Vector2(p.rng.randf_range(0.3, 0.7) * p.w, 5.0 * s)
				_crack(p, start, p.rng.randi_range(3, 5), 7.0 * s, Vector2(0, 1) if kind == "fissure" else Vector2.from_angle(p.rng.randf() * TAU))
		"pebbles", "rubble", "lumps":
			var n := p.rng.randi_range(2, 4) if kind != "rubble" else p.rng.randi_range(4, 7)
			for k in n:
				var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-16, 16)) * s
				var rx := p.rng.randf_range(2.0, 5.5) * s
				var tone := col.lightened(p.rng.randf_range(0.0, 0.3)) if kind != "lumps" else col.darkened(0.1)
				_stone(p, q, rx, rx * p.rng.randf_range(0.6, 0.85), tone)
		"wet", "puddle":
			_puddle(p, c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * s, p.rng.randf_range(9, 14) * s, col)
		"dimples", "pits", "prints":
			var n := p.rng.randi_range(1, 3)
			for k in n:
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-15, 15)) * s
				_pit(p, q, p.rng.randf_range(1.5, 3.5) * s * (1.6 if kind == "prints" else 1.0))
		"bulge":  # 앞면에 튀어나온 바위 혹 — 아래쪽 그늘 + 윤곽 일부
			var q := c + Vector2(p.rng.randf_range(-6, 6) * s, p.h * 0.08)
			var rx := p.w * 0.24
			var ry := p.h * 0.26
			p.fill_poly(_ellipse(q, rx, ry, 20, p.rng), func(x: int, y: int) -> Color:
				var d := Vector2((x - q.x) / rx, (y - q.y) / ry)
				return Color(0.08, 0.06, 0.08, clampf(d.y * 0.45 + d.x * 0.15, 0.0, 0.45)), 1.0, true)
			Ink.line(p, q + Vector2(-rx * 0.9, ry * 0.4), q + Vector2(rx * 0.6, ry * 0.95), 1.2 * s, Ink.INK, 0.5, 1.0)
		"drip":
			for k in p.rng.randi_range(2, 4):
				var x := p.rng.randf_range(0.25, 0.75) * p.w
				for y in range(int(6 * s), p.h):
					var a := 0.35 * (1.0 - float(y) / p.h) * (0.6 + 0.4 * sin(y * 0.4 + x))
					p.tint(int(x), y, Color("#1c1e28"), a)
					p.tint(int(x) + 1, y, Color("#c8c8d8"), a * 0.25)
		"ledge":
			var y0 := p.h * p.rng.randf_range(0.45, 0.6)
			Ink.line(p, Vector2(p.w * 0.12, y0), Vector2(p.w * 0.88, y0 + p.rng.randf_range(-3, 3) * s), 1.6 * s, Ink.INK, 0.65, 1.2)
			for x in range(int(p.w * 0.12), int(p.w * 0.88)):
				for k in int(4 * s):
					p.tint(x, int(y0) - k - 1, Color("#e0d8e8"), 0.12 * (1.0 - k / (4.0 * s)))
		"one", "two", "small":
			var n := 2 if kind == "two" else 1
			for k in n:
				var q := c + Vector2(p.rng.randf_range(-10, 10), p.rng.randf_range(-6, 8)) * s
				if key == "crystal_face":
					q = Vector2(p.rng.randf_range(0.3, 0.7) * p.w, p.h * p.rng.randf_range(0.75, 0.95))
				_cluster(p, q, (0.55 if kind == "small" else 1.0) * s, key == "crystal_face")
		"vein":  # 바위에 박힌 가는 수정 줄
			var a := c + Vector2(p.rng.randf_range(-14, -6), p.rng.randf_range(-8, 8)) * s
			var b := a + Vector2.from_angle(p.rng.randf_range(-0.6, 0.6)) * p.rng.randf_range(16, 24) * s
			Ink.glow(p, (a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 12.0 * s, CRYSTAL_GLOW, 0.25)
			Ink.line(p, a, b, 2.2 * s, CRYSTAL_DARK, 0.9, 1.2)
			Ink.line(p, a, b, 1.0 * s, CRYSTAL_LIGHT, 0.85, 1.2)
		"ring":
			var q := c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * s
			for r: float in [5.0 * s, 9.0 * s]:
				var pts := _ellipse(q, r, r * 0.7, 24)
				Ink.path(p, pts, 1.0 * s, true, Color("#a8c0d8"), 0.25, 0.6)
		"specks", "scum":
			for k in p.rng.randi_range(6, 12) * (2 if kind == "scum" else 1):
				var q := c + Vector2(p.rng.randf_range(-18, 18), p.rng.randf_range(-18, 18)) * s
				var tone := Color("#c8d8e8") if kind == "specks" else Color("#4a5a3a")
				_dot(p, q, p.rng.randf_range(0.6, 1.6) * s, tone, 0.6 if kind == "specks" else 0.45)


## 금: 꺾이며 이어지는 잉크 선 + 아래쪽 가장자리에 빛 받은 가는 선(왼쪽 위 빛).
static func _crack(p: Paint, start: Vector2, segs: int, seg_len: float, dir: Vector2) -> void:
	var a := start
	var d := dir.normalized()
	for k in segs:
		d = d.rotated(p.rng.randf_range(-0.7, 0.7)).normalized()
		var b := a + d * seg_len * p.rng.randf_range(0.6, 1.3)
		var wd := maxf(0.6, (1.6 - k * 0.25)) * p.w / 64.0
		Ink.line(p, a, b, wd, Ink.INK, 0.75, 0.6)
		Ink.line(p, a + Vector2(0.8, 0.8), b + Vector2(0.8, 0.8), wd * 0.5, Color("#d8d0c8"), 0.18, 0.6, true)
		if p.rng.randf() < 0.35:  # 잔가지
			var e := a.lerp(b, 0.5)
			Ink.line(p, e, e + d.rotated(p.rng.randf_range(0.6, 1.2) * (1 if p.rng.randf() < 0.5 else -1)) * seg_len * 0.5, wd * 0.6, Ink.INK, 0.55, 0.5)
		a = b


## 돌 한 개: 오른쪽 아래 그림자 → 왼쪽 위가 밝은 덩어리 → 오른쪽 아래 윤곽 잉크.
static func _stone(p: Paint, q: Vector2, rx: float, ry: float, tone: Color) -> void:
	var off := Vector2(rx, ry) * 0.3
	var shadow := _ellipse(q + off, rx * 1.05, ry * 1.05, 18)
	p.fill_poly(shadow, func(_x: int, _y: int) -> Color: return Color(0.06, 0.05, 0.07, 0.45))
	var poly := _ellipse(q, rx, ry, 18, p.rng)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var d := Vector2((x - q.x) / rx, (y - q.y) / ry)
		var t := clampf(0.55 - d.x * 0.3 - d.y * 0.35 - d.length_squared() * 0.25, 0.0, 1.0)
		return p.vary(tone.darkened(0.35).lerp(tone.lightened(0.25), t), x, y, 0.08))
	var n := poly.size()
	for i in n:
		var m := (poly[i] + poly[(i + 1) % n]) * 0.5 - q
		if m.x + m.y > -0.2 * (rx + ry):  # 그늘 쪽 윤곽만
			Ink.line(p, poly[i], poly[(i + 1) % n], 1.1 * p.w / 64.0, Ink.INK, 0.6, 0.3)


## 물기 얼룩: 어둡고 푸르게 + 반짝임 몇 점.
static func _puddle(p: Paint, q: Vector2, r: float, col: Color) -> void:
	var poly := _ellipse(q, r, r * 0.72, 22, p.rng)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var d := Vector2((x - q.x) / r, (y - q.y) / (r * 0.72)).length()
		return Color(0.1, 0.12, 0.17, 0.55 * clampf(1.2 - d, 0.0, 1.0)), 1.0, true)
	Ink.path(p, poly, 0.9 * p.w / 64.0, true, Ink.INK, 0.25, 0.5)
	for k in p.rng.randi_range(3, 5):
		var a := q + Vector2(p.rng.randf_range(-0.6, 0.2) * r, p.rng.randf_range(-0.5, 0.1) * r * 0.72)
		_dot(p, a, p.rng.randf_range(0.6, 1.2) * p.w / 64.0, Color("#c0c8e0"), 0.5)


## 움푹한 자국: 안쪽 그늘(왼쪽 위) + 오른쪽 아래 가장자리에 빛.
static func _pit(p: Paint, q: Vector2, r: float) -> void:
	p.fill_poly(_ellipse(q, r, r * 0.8, 12), func(x: int, y: int) -> Color:
		var d := Vector2(x - q.x, y - q.y) / r
		return Color(0.05, 0.04, 0.06, clampf(0.28 - (d.x + d.y) * 0.15, 0.0, 0.35)), 1.0, true)
	Ink.line(p, q + Vector2(r * 0.2, r * 0.9), q + Vector2(r * 0.95, r * 0.1), 0.8 * p.w / 64.0, Color("#d0c8d0"), 0.2, 0.3, true)


## 수정 무리: 한 점에서 뻗은 육각 기둥 조각들 — 빛 쪽 면은 밝은 라일락, 반대 면은 짙은 보라, 잉크 윤곽, 둘레 빛 번짐.
## upright(벽 앞면)면 위로 솟고, 아니면(윗면) 위에서 내려다본 방사형.
static func _cluster(p: Paint, root: Vector2, scale: float, upright: bool) -> void:
	var n := p.rng.randi_range(3, 5)
	Ink.glow(p, root.x, root.y - (6.0 * scale if upright else 0.0), 16.0 * scale, CRYSTAL_GLOW, 0.35)
	var shards: Array[Array] = []
	for k in n:
		var ang := (-PI * 0.5 + p.rng.randf_range(-0.75, 0.75)) if upright else p.rng.randf() * TAU
		var ln := p.rng.randf_range(8.0, 15.0) * scale
		var wd := p.rng.randf_range(2.2, 3.8) * scale
		shards.append([ang, ln, wd])
	shards.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))  # 긴 것부터(짧은 것이 앞)
	for sh: Array in shards:
		var d := Vector2.from_angle(float(sh[0]))
		var nrm := Vector2(-d.y, d.x)
		var ln := float(sh[1])
		var wd := float(sh[2])
		var tip := root + d * ln
		var bl := root + nrm * wd
		var br := root - nrm * wd
		var sl := root + nrm * wd + d * ln * 0.78
		var sr := root - nrm * wd + d * ln * 0.78
		var mid := root + d * ln * 0.1
		var left := PackedVector2Array([bl, sl, tip, mid])
		var right := PackedVector2Array([mid, tip, sr, br])
		var lit_left := nrm.dot(Vector2(-0.7, -0.7)) > 0.0
		var ca := CRYSTAL_LIGHT if lit_left else CRYSTAL_DARK.lightened(0.15)
		var cb := CRYSTAL_DARK if lit_left else CRYSTAL_LIGHT.darkened(0.1)
		p.fill_poly(left, func(x: int, y: int) -> Color: return p.vary(ca, x, y, 0.05))
		p.fill_poly(right, func(x: int, y: int) -> Color: return p.vary(cb, x, y, 0.05))
		Ink.line(p, mid, tip, 0.7 * scale, Color("#f0e8ff"), 0.45, 0.2)  # 모서리 빛
		Ink.path(p, PackedVector2Array([bl, sl, tip, sr, br]), 1.0 * scale, false, Color("#1a1030"), 0.75, 0.3)


static func _dot(p: Paint, q: Vector2, r: float, c: Color, a: float) -> void:
	for y in range(int(q.y - r) - 1, int(q.y + r) + 2):
		for x in range(int(q.x - r) - 1, int(q.x + r) + 2):
			var d := Vector2(x - q.x, y - q.y).length() / maxf(r, 0.1)
			if d < 1.0:
				p.tint(x, y, c, a * (1.0 - d * d))


static func _ellipse(q: Vector2, rx: float, ry: float, n: int, rng: RandomNumberGenerator = null) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var k := 1.0 if rng == null else rng.randf_range(0.85, 1.12)
		out.append(q + Vector2(cos(a) * rx * k, sin(a) * ry * k))
	return out
