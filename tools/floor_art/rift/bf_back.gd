extends RefCounted
## 핏빛성채 뒷배경(낭떠러지 너머 — 고원 끝에서 내려다본 깊은 골): 소용돌이치는 핏빛 안개, 안개 속에 잠긴 뾰족한 바위탑·무너진 탑
## 그림자 세 겹(먼 것은 위·작게·흐리게, 가까운 것은 아래·크게·검게), 깊은 아래에서 올라오는 진홍빛, 날리는 재.
## 가로로 이어 붙여도 이음매가 없다(잡음은 Seam 주기 잡음, 탑 자리는 가로 주기로 감아 돈다).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")

## 겹: [윗선 y 비율, 높이 비율, 탑 수, 폭 배율, 색, 흐림]
const LAYERS := [
	[0.42, 0.26, 14, 0.7, Color("#3a1416"), 0.55],
	[0.66, 0.36, 10, 1.0, Color("#1e0a0c"), 0.3],
	[0.98, 0.5, 7, 1.5, Color("#0c0506"), 0.1],
]


static func paint(w: int, h: int, s: int) -> Paint:
	var p := Paint.new(w, h, s)
	var mist := Seam.field(w, w, s, 0.0035, 4)
	var wisp := Seam.field(w, w, s + 1, 0.009, 3)
	var deep := Seam.field(w, w, s + 2, 0.002, 2)
	var fine := Seam.field(w, w, s + 3, 0.05, 2)
	var buf := PackedColorArray()
	buf.resize(w * h)
	# 바탕: 위는 핏빛 안개, 아래로 갈수록 검게 — 깊은 곳에서 번지는 진홍빛 웅덩이
	for y in h:
		var ty := float(y) / h
		for x in w:
			var i := y * w + x
			var c := Color("#3a1212").lerp(Color("#120607"), smoothstep(0.1, 0.95, ty))
			var m := clampf(mist[i] * 0.65 + wisp[i] * 0.45 - 0.3, 0.0, 1.0)
			c = c.lerp(Color("#7a2a24"), m * m * (0.75 - ty * 0.45))  # 안개 덩어리
			var glow := smoothstep(0.55, 0.85, deep[i]) * smoothstep(0.25, 0.75, ty) * (1.0 - smoothstep(0.85, 1.0, ty) * 0.5)
			c = c.lerp(Color("#a8221a"), glow * 0.5 * (0.6 + wisp[i] * 0.6))  # 아래에서 올라오는 붉은빛
			c = c.lightened((fine[i] - 0.5) * 0.04)
			buf[i] = c
	# 바위탑 겹(먼 것부터)
	for li in LAYERS.size():
		var ly: Array = LAYERS[li]
		_layer(buf, w, h, float(ly[0]) * h, float(ly[1]) * h, int(ly[2]), float(ly[3]), ly[4], float(ly[5]), s + 10 + li, mist, wisp)
		if li < LAYERS.size() - 1:
			_veil(buf, w, h, float(ly[0]) * h, wisp, mist, 0.42 - li * 0.1)
	for i in w * h:
		var c := buf[i]
		p.buf[i * 4] = c.r
		p.buf[i * 4 + 1] = c.g
		p.buf[i * 4 + 2] = c.b
		p.buf[i * 4 + 3] = 1.0
	_ash(p, s)
	Ink.grade(p, 0.12, 1.06, Color("#140a0a"), Color("#e0b8a0"), 0.1)
	Ink.finish(p, 0.03, 0.0)
	return p


## 한 겹의 탑 그림자: 열마다 윗선 높이(뾰족한 바위 · 톱니 성벽 탑)를 먼저 구하고 그 아래를 칠한다 — 아래로 갈수록 안개에 잠긴다.
static func _layer(buf: PackedColorArray, w: int, h: int, base_y: float, hgt: float, n: int, scale: float, col: Color, haze: float, s: int, mist: PackedFloat32Array, wisp: PackedFloat32Array) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = s
	var prof := PackedFloat32Array()
	prof.resize(w)
	prof.fill(1e9)
	var rim := PackedFloat32Array()  # 왼쪽 위 빛 받은 면(0~1)
	rim.resize(w)
	var jag := Seam.field(w, 4, s, 0.06, 3)
	for k in n:
		var tower := r.randf() < 0.22
		var subs := 1 if tower else r.randi_range(2, 3)
		for sub in subs:
			var sx := (k + r.randf_range(0.1, 0.9)) * w / n + (sub * r.randf_range(-1.0, 1.0) * 22.0 * scale)
			var th := hgt * r.randf_range(0.45, 1.0) * (1.0 if sub == 0 else r.randf_range(0.45, 0.75))
			var hw := r.randf_range(12.0, 26.0) * scale * (1.0 if sub == 0 else 0.7)
			var lean := r.randf_range(-0.25, 0.25)
			_spire(prof, rim, jag, w, sx, base_y - th, th, hw, lean, tower, scale)
	_fill(buf, w, h, prof, rim, hgt, col, haze, mist, wisp)


## 탑 하나를 열 윗선(prof)에 더한다.
static func _spire(prof: PackedFloat32Array, rim: PackedFloat32Array, jag: PackedFloat32Array, w: int, sx: float, top: float, th: float, hw: float, lean: float, tower: bool, scale: float) -> void:
	for dxi in range(-int(hw * 3.0), int(hw * 3.0) + 1):
		var x := posmod(int(sx) + dxi, w)
		var dx := float(dxi)
		var y: float
		if tower:  # 무너진 탑: 곧은 몸 + 톱니 + 부서진 윗머리
			if absf(dx) > hw:
				continue
			y = top + (8.0 * scale if fposmod(dx + hw, 10.0 * scale) < 5.0 * scale else 0.0)
			y += maxf(0.0, dx) * 0.35 * (jag[x] + 0.3)
		else:  # 뾰족한 바위탑(오목한 옆구리, 기울고 들쭉날쭉)
			var t := absf(dx - lean * hw * 2.0 * (1.0 - absf(dx) / (hw * 3.0))) / (hw * 3.0)
			y = top + pow(t, 0.55) * th * 1.15 + (jag[x] - 0.5) * 16.0 * scale + (jag[posmod(x * 3, w)] - 0.5) * 6.0 * scale
		if y < prof[x]:
			prof[x] = y
			rim[x] = clampf(-dx / hw, 0.0, 1.0) if not tower else (0.6 if dx < -hw * 0.6 else 0.0)


## 윗선 아래를 칠한다 — 아래로 갈수록 안개에 잠긴다.
static func _fill(buf: PackedColorArray, w: int, h: int, prof: PackedFloat32Array, rim: PackedFloat32Array, hgt: float, col: Color, haze: float, mist: PackedFloat32Array, wisp: PackedFloat32Array) -> void:
	for x in w:
		var y0 := prof[x]
		if y0 > h:
			continue
		for y in range(maxi(0, int(y0)), h):
			var i := y * w + x
			var depth := (y - y0) / maxf(1.0, hgt)
			var c := col.lerp(Color("#5a1a18"), rim[x] * 0.35 * clampf(1.0 - depth * 2.0, 0.0, 1.0))  # 붉은빛 받은 가장자리
			var sink := smoothstep(0.15, 1.0, depth)  # 안개에 잠기는 밑동
			var a := (1.0 - haze) * (1.0 - sink * 0.85) * clampf(1.0 - (mist[i] + wisp[i] - 0.9) * 0.6, 0.4, 1.0)
			if y - y0 < 1.5:
				a = minf(1.0, a * 1.15)
			buf[i] = buf[i].lerp(c, clampf(a, 0.0, 1.0))


## 날리는 재(작은 회색 점 + 짧은 꼬리 — 가로로 감아 돈다).
static func _ash(p: Paint, s: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = s + 77
	for k in 520:
		var q := Vector2(r.randf() * p.w, r.randf() * p.h)
		var size := r.randf_range(0.6, 1.8) * (0.6 + q.y / p.h * 0.8)
		var a := r.randf_range(0.15, 0.45)
		var col := Color("#b8a8a0") if r.randf() < 0.8 else Color("#ff8a5a")
		for t in 4:
			var pt := q + Vector2(t * 1.2, -t * 0.5)
			for yy in range(int(pt.y - size), int(pt.y + size) + 1):
				for xx in range(int(pt.x - size), int(pt.x + size) + 1):
					if yy < 0 or yy >= p.h:
						continue
					var d := Vector2(xx - pt.x, yy - pt.y).length() / size
					if d < 1.0:
						p.tint(posmod(xx, p.w), yy, col, a * (1.0 - d) * (1.0 - t * 0.25))


## 겹 사이 안개 띠(가로로 길게 늘인 잡음 — 소용돌이치는 핏빛 안개).
static func _veil(buf: PackedColorArray, w: int, h: int, cy: float, wisp: PackedFloat32Array, mist: PackedFloat32Array, strength: float) -> void:
	for y in range(maxi(0, int(cy - h * 0.3)), mini(h, int(cy + h * 0.12))):
		var band := 1.0 - absf(y - (cy - h * 0.06)) / (h * 0.2)
		if band <= 0.0:
			continue
		var sy := posmod(int(y * 0.3) + 97, h)
		for x in w:
			var v := clampf(wisp[sy * w + x] * 1.4 - 0.45 + (mist[y * w + x] - 0.5) * 0.4, 0.0, 1.0)
			var i := y * w + x
			buf[i] = buf[i].lerp(Color("#6e2420"), v * band * strength)
