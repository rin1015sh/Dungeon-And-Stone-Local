extends RefCounted
## 탐험 맵 데칼(바닥 위에 얹는 투명 그림 — tools/paint_floor.gd): 종류 = 시트 한 줄, 변형 = 칸.
## 물가(그림 위쪽 = 물 쪽, 게임이 돌려 놓는다) · 자갈 · 이끼 · 물기 · 수정 조각 · 발톱 자국 · 진흙 · 썩은 얼룩 · 고블린 쓰레기 · 뼈.
## 밝기는 바닥과 비슷한 중립(빛은 게임이 곱한다). 가장자리는 부드럽게 사라진다. 칠은 Cave의 돌·점·수정 부품 + Ink.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")


static func paint(kind: String, v: int, w: int, seed_value: int) -> Paint:
	var p := Paint.new(w, w, seed_value + v * 131 + kind.hash() % 1000)
	var s := w / 64.0
	var c := Vector2(w, w) * 0.5
	match kind:
		"shore":
			_shore(p, s)
		"gravel":
			for k in p.rng.randi_range(6, 11):
				var q := c + Vector2(p.rng.randf_range(-17, 17), p.rng.randf_range(-12, 14)) * s
				var r := p.rng.randf_range(1.6, 4.2) * s
				Cave._stone(p, q, r, r * p.rng.randf_range(0.6, 0.85), Color("#5e5862").lightened(p.rng.randf_range(-0.1, 0.15)))
		"moss":
			_blob(p, c, 20.0 * s, Color("#3c4630"), 0.85, 0.12)
			for k in p.rng.randi_range(20, 34):
				var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-14, 14)) * s
				Cave._dot(p, q, p.rng.randf_range(0.8, 1.8) * s, Color("#6a7a48") if p.rng.randf() < 0.6 else Color("#1e2418"), 0.6)
		"wet":
			_blob(p, c, 19.0 * s, Color("#1a1e2a"), 0.55, 0.2)
			for k in p.rng.randi_range(3, 6):
				var q := c + Vector2(p.rng.randf_range(-10, 6), p.rng.randf_range(-9, 4)) * s
				_spot(p, q, p.rng.randf_range(0.7, 1.3) * s, Color("#b8c4dc"), 0.55)
		"crystal_bits":
			_blob(p, c, 12.0 * s, Color("#2a2240"), 0.35, 0.3)
			for k in p.rng.randi_range(2, 4):
				var q := c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-9, 10)) * s
				Cave._cluster(p, q, p.rng.randf_range(0.3, 0.45) * s, false)
		"claws":
			var ang := p.rng.randf_range(-0.9, -0.4)
			var d := Vector2.from_angle(ang)
			var nrm := Vector2(-d.y, d.x)
			var ln := p.rng.randf_range(20, 30) * s
			for k in p.rng.randi_range(3, 4):
				var a := c - d * ln * 0.5 + nrm * (k - 1.5) * 5.0 * s
				Ink.line(p, a, a + d * ln * p.rng.randf_range(0.8, 1.0), 2.0 * s, Color("#141018"), 0.8, 0.8)
				Ink.line(p, a + Vector2(0.8, 1.0) * s, a + Vector2(0.8, 1.0) * s + d * ln * 0.85, 0.9 * s, Color("#9a90a0"), 0.45, 0.8)
		"mud":
			_blob(p, c, 18.0 * s, Color("#3e3226"), 0.95, 0.25)
			for k in p.rng.randi_range(4, 7):
				var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-14, 14)) * s
				_blob(p, q, p.rng.randf_range(2.5, 5.0) * s, Color("#4a3c2c"), 0.95, 0.3)
			for k in p.rng.randi_range(4, 8):
				var q := c + Vector2(p.rng.randf_range(-12, 10), p.rng.randf_range(-12, 8)) * s
				_spot(p, q, p.rng.randf_range(0.6, 1.2) * s, Color("#c8b898"), 0.5)
		"rot":
			_blob(p, c, 18.0 * s, Color("#3a3a22"), 0.7, 0.25)
			_blob(p, c + Vector2(p.rng.randf_range(-5, 5), p.rng.randf_range(-5, 5)) * s, 9.0 * s, Color("#2a1a14"), 0.6, 0.3)
			for k in p.rng.randi_range(5, 9):
				var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-14, 14)) * s
				Cave._dot(p, q, p.rng.randf_range(0.8, 2.2) * s, Color("#5a1a12") if p.rng.randf() < 0.5 else Color("#6a6a30"), 0.65)
		"trash":
			_trash(p, c, s)
		"bones":
			_bones(p, c, s)
		"weeds":
			_weeds(p, c, s, p.rng.randi_range(3, 6))
		"fern":
			_fern(p, c, s)
		"sunpatch":  # 잎 사이로 떨어진 햇빛 얼룩(밝은 노란 초록 — 숲, FL24)
			for k in p.rng.randi_range(5, 9):
				var q := c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-11, 11)) * s
				_blob(p, q, p.rng.randf_range(3.0, 7.0) * s, Color("#e8f4a0"), 0.28, 0.4)
		"stones":
			_stones(p, c, s)
		"roots":
			_roots(p, c, s)
		"litter":
			_litter(p, c, s)
		"flowers":
			_weeds(p, c, s, p.rng.randi_range(2, 3))
			for k in p.rng.randi_range(6, 11):
				var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-12, 12)) * s
				_spot(p, q, p.rng.randf_range(0.9, 1.5) * s, Color("#c8c4d8") if p.rng.randf() < 0.6 else Color("#d8c890"), 0.9)
	_soft_edge(p)
	return p


## ── 숲(고블린 숲 — 사용자 2026-11-06 "잡초나 잡돌 같은 표현", FL23) ──

## 잡초 덤불 n개: 뿌리 자리에서 부채꼴로 뻗는 가는 잎(어두운 밑 → 밝은 끝), 덤불 밑 그늘.
static func _weeds(p: Paint, c: Vector2, s: float, n: int) -> void:
	for t in n:
		var root := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-10, 13)) * s
		_blob(p, root + Vector2(0, 1) * s, 4.0 * s, Color("#141810"), 0.45, 0.3)
		for k in p.rng.randi_range(7, 13):
			var a := -PI * 0.5 + p.rng.randf_range(-1.1, 1.1)
			var ln := p.rng.randf_range(5.0, 11.0) * s
			var tip := root + Vector2.from_angle(a) * ln + Vector2(p.rng.randf_range(-1.5, 1.5), 0) * s
			var col := Color("#2a4a1c").lerp(Color("#8ab43a"), p.rng.randf())
			Ink.line(p, root, root.lerp(tip, 0.55), 1.3 * s, col.darkened(0.3), 0.95, 0.3)
			Ink.line(p, root.lerp(tip, 0.5), tip, 0.9 * s, col, 0.95, 0.3)


## 고사리: 가운데에서 휘어 뻗는 잎줄기 다섯여섯, 줄기마다 양옆 작은 잎.
static func _fern(p: Paint, c: Vector2, s: float) -> void:
	_blob(p, c + Vector2(0, 2) * s, 8.0 * s, Color("#121610"), 0.5, 0.3)
	for k in p.rng.randi_range(5, 7):
		var a := -PI * 0.5 + (k - 3) * 0.45 + p.rng.randf_range(-0.15, 0.15)
		var ln := p.rng.randf_range(14.0, 20.0) * s
		var bend := p.rng.randf_range(-0.25, 0.25)
		var prev := c
		for j in 8:
			var t := float(j + 1) / 8.0
			var q := c + Vector2.from_angle(a + bend * t) * ln * t + Vector2(0, t * t * 6.0) * s  # 끝이 처진다
			Ink.line(p, prev, q, 1.0 * s, Color("#2a4a1e"), 0.95, 0.2)
			var side := Vector2.from_angle(a + bend * t + PI * 0.5) * (1.0 - t * 0.7) * 3.5 * s
			var leaf := Color("#3e6a2a").lerp(Color("#8ab43a"), t)
			Ink.line(p, q, q + side, 1.2 * s, leaf, 0.9, 0.2)
			Ink.line(p, q, q - side, 1.2 * s, leaf.darkened(0.2), 0.9, 0.2)
			prev = q


## 잡돌: 크고 작은 돌 몇 개(이끼 낀 윗면), 사이에 잔자갈.
static func _stones(p: Paint, c: Vector2, s: float) -> void:
	for k in p.rng.randi_range(2, 4):
		var q := c + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-9, 10)) * s
		var r := p.rng.randf_range(3.0, 6.5) * s
		Cave._stone(p, q, r, r * p.rng.randf_range(0.6, 0.8), Color("#5c5e58").lightened(p.rng.randf_range(-0.12, 0.1)))
		if p.rng.randf() < 0.6:
			_blob(p, q + Vector2(-r * 0.2, -r * 0.35), r * 0.5, Color("#3e4c34"), 0.7, 0.4)
	for k in p.rng.randi_range(5, 9):
		var q := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-13, 13)) * s
		var r := p.rng.randf_range(0.9, 1.8) * s
		Cave._stone(p, q, r, r * 0.7, Color("#4e504a"))


## 땅 위로 드러난 뿌리: 굵게 시작해 가늘어지는 굽은 줄 둘셋(위쪽 밝은 테).
static func _roots(p: Paint, c: Vector2, s: float) -> void:
	for k in p.rng.randi_range(2, 3):
		var a := c + Vector2(p.rng.randf_range(-16, -6), p.rng.randf_range(-10, 10)) * s
		var d := Vector2.from_angle(p.rng.randf_range(-0.5, 0.5))
		var prev := a
		for j in 9:
			var t := float(j + 1) / 9.0
			var q := a + d * 32.0 * s * t + Vector2(0, sin(t * PI * 2.0 + k) * 3.0) * s
			var wd := (3.2 - t * 2.4) * s
			Ink.line(p, prev, q, wd, Color("#2e261e"), 1.0, 0.2)
			Ink.line(p, prev + Vector2(0, -wd * 0.3), q + Vector2(0, -wd * 0.3), wd * 0.35, Color("#5a4c3c"), 0.7, 0.2)
			prev = q


## 낙엽 무더기: 겹친 잎(갈색 · 붉은 갈색 · 마른 노랑) + 잎맥.
static func _litter(p: Paint, c: Vector2, s: float) -> void:
	_blob(p, c, 14.0 * s, Color("#2a241a"), 0.4, 0.3)
	for k in p.rng.randi_range(14, 24):
		var q := c + Vector2(p.rng.randf_range(-15, 15), p.rng.randf_range(-11, 11)) * s
		var a := p.rng.randf() * TAU
		var r := p.rng.randf_range(2.0, 3.6) * s
		var col: Color = [Color("#6a4a2a"), Color("#7a5a30"), Color("#5a3a24"), Color("#7a6a3a")][p.rng.randi_range(0, 3)]
		var pts := PackedVector2Array()
		for j in 10:
			var t := TAU * j / 10.0
			pts.append(q + Vector2(cos(t) * r, sin(t) * r * 0.45).rotated(a))
		p.fill_poly(pts, func(x: int, y: int) -> Color: return p.vary(col, x, y, 0.1))
		Ink.line(p, q - Vector2(r, 0).rotated(a), q + Vector2(r, 0).rotated(a), 0.5 * s, Color("#1e160e"), 0.5, 0.2)


## 물가: 위쪽(물 쪽)에 젖어 검은 바위 둑이 울퉁불퉁 튀어나오고, 아래로 갈수록 젖은 자국이 옅어진다.
static func _shore(p: Paint, s: float) -> void:
	var w := p.w
	var bank := PackedFloat32Array()
	bank.resize(w)
	var phase := p.rng.randf() * 10.0
	for x in w:
		bank[x] = (14.0 + sin(x * 0.19 + phase) * 4.0 + sin(x * 0.53 + phase * 2.0) * 2.0) * s
	for y in w:
		for x in w:
			var b := bank[x]
			if y < b:
				var t := float(y) / b
				p.blend(x, y, Color("#2e2a34").lerp(Color("#423c48"), t), clampf(0.55 + t * 0.4, 0.0, 0.95))
			else:
				var fall := 1.0 - (y - b) / (w * 0.6)
				if fall > 0.0:
					p.blend(x, y, Color("#1e1c26"), 0.5 * fall * fall)
	for x in range(0, w, 2):  # 물에 닿은 둑 끝의 젖은 빛
		Cave._dot(p, Vector2(x, bank[x] * 0.25), 0.9 * s, Color("#a8b8d0"), 0.35)
	for k in p.rng.randi_range(4, 7):
		var q := Vector2(p.rng.randf_range(6, w - 6), p.rng.randf_range(4, 20) * s)
		var r := p.rng.randf_range(2.0, 4.5) * s
		Cave._stone(p, q, r, r * 0.7, Color("#4a4452"))


## 둥근 얼룩(테두리가 들쭉날쭉하고 가장자리로 갈수록 옅다). rough = 테두리 흔들림.
static func _blob(p: Paint, q: Vector2, r: float, col: Color, alpha: float, rough: float) -> void:
	var phase := p.rng.randf() * TAU
	for y in range(int(q.y - r * 1.4), int(q.y + r * 1.4) + 1):
		for x in range(int(q.x - r * 1.4), int(q.x + r * 1.4) + 1):
			var d := Vector2(x - q.x, y - q.y)
			var a := d.angle()
			var rr := r * (1.0 + rough * (sin(a * 3.0 + phase) * 0.6 + sin(a * 7.0 + phase * 1.7) * 0.4))
			var t := d.length() / maxf(1.0, rr)
			if t < 1.0:
				p.blend(x, y, p.vary(col, x, y, 0.08), alpha * smoothstep(1.0, 0.55, t))


## 반짝이는 점(물기·진흙의 번들거림) — 투명한 곳에도 찍힌다.
static func _spot(p: Paint, q: Vector2, r: float, c: Color, a: float) -> void:
	for y in range(int(q.y - r) - 1, int(q.y + r) + 2):
		for x in range(int(q.x - r) - 1, int(q.x + r) + 2):
			var d := Vector2(x - q.x, y - q.y).length() / maxf(r, 0.1)
			if d < 1.0:
				p.blend(x, y, c, a * (1.0 - d * d))


## 뼈: 긴 뼈 한두 개 + 갈비 조각 + 가끔 두개골 조각. 상아색, 오른쪽 아래 그늘 + 잉크.
static func _bones(p: Paint, c: Vector2, s: float) -> void:
	var bone := Color("#b8ae98")
	for k in p.rng.randi_range(1, 2):
		var d := Vector2.from_angle(p.rng.randf() * TAU)
		var q := c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-8, 8)) * s
		var ln := p.rng.randf_range(10, 16) * s
		_stick(p, q - d * ln * 0.5, q + d * ln * 0.5, 2.0 * s, bone)
		for e: float in [-0.5, 0.5]:
			Cave._stone(p, q + d * ln * e, 2.4 * s, 2.0 * s, bone)
	for k in p.rng.randi_range(2, 4):  # 갈비
		var q := c + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-12, 12)) * s
		var a := q + Vector2.from_angle(p.rng.randf() * TAU) * 7.0 * s
		var m := (q + a) * 0.5 + Vector2(p.rng.randf_range(-2, 2), -3.0) * s
		Ink.line(p, q, m, 1.6 * s, bone.darkened(0.1), 0.95, 0.3)
		Ink.line(p, m, a, 1.4 * s, bone.darkened(0.1), 0.95, 0.3)
	if p.rng.randf() < 0.45:
		var q := c + Vector2(p.rng.randf_range(-8, 8), p.rng.randf_range(-6, 6)) * s
		Cave._stone(p, q, 5.0 * s, 4.2 * s, bone)
		Cave._dot(p, q + Vector2(-1.6, 0.0) * s, 1.3 * s, Color("#1a1412"), 0.9)
		Cave._dot(p, q + Vector2(1.6, 0.0) * s, 1.3 * s, Color("#1a1412"), 0.9)


## 고블린 쓰레기: 넝마 조각 · 부러진 막대 · 뼈 부스러기 · 깨진 그릇.
static func _trash(p: Paint, c: Vector2, s: float) -> void:
	var rag := PackedVector2Array()
	var q := c + Vector2(p.rng.randf_range(-6, 6), p.rng.randf_range(-6, 6)) * s
	for i in 7:
		var a := TAU * i / 7.0
		rag.append(q + Vector2(cos(a), sin(a) * 0.7) * p.rng.randf_range(5, 10) * s)
	p.fill_poly(rag, func(x: int, y: int) -> Color: return p.vary(Color("#4a3e2e"), x, y, 0.12))
	Ink.path(p, rag, 1.0 * s, true, Ink.INK, 0.6, 0.6)
	for k in p.rng.randi_range(1, 2):
		var a := c + Vector2(p.rng.randf_range(-16, 8), p.rng.randf_range(-14, 14)) * s
		_stick(p, a, a + Vector2.from_angle(p.rng.randf() * TAU) * p.rng.randf_range(10, 18) * s, 1.6 * s, Color("#5a4630"))
	for k in p.rng.randi_range(2, 4):
		var b := c + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-14, 14)) * s
		Cave._stone(p, b, 1.8 * s, 1.4 * s, Color("#b0a690"))
	var pot := c + Vector2(p.rng.randf_range(4, 12), p.rng.randf_range(-10, 10)) * s
	Cave._stone(p, pot, 4.0 * s, 3.0 * s, Color("#6a4a34"))
	Ink.line(p, pot + Vector2(-3, -1) * s, pot + Vector2(1, 2) * s, 1.0 * s, Ink.INK, 0.8, 0.4)


## 막대(뼈·나뭇가지): 그늘 → 몸 → 밝은 등 → 잉크.
static func _stick(p: Paint, a: Vector2, b: Vector2, wd: float, col: Color) -> void:
	Ink.line(p, a + Vector2(1.2, 1.5), b + Vector2(1.2, 1.5), wd * 1.2, Color(0.05, 0.04, 0.05), 0.4, 0.2)
	Ink.line(p, a, b, wd * 1.3, Ink.INK, 0.85, 0.3)
	Ink.line(p, a, b, wd, col, 1.0, 0.3)
	Ink.line(p, a - Vector2(0.5, 0.5), b - Vector2(0.5, 0.5), wd * 0.35, col.lightened(0.3), 0.7, 0.3)


## 칸 가장자리 몇 px는 투명으로(이웃 칸과 겹칠 때 네모 테두리가 보이지 않게).
static func _soft_edge(p: Paint) -> void:
	var band := p.w * 0.08
	for y in p.h:
		for x in p.w:
			var d := minf(minf(x + 0.5, p.w - x - 0.5), minf(y + 0.5, p.h - y - 0.5))
			if d < band:
				var i := (y * p.w + x) * 4 + 3
				p.buf[i] *= d / band
