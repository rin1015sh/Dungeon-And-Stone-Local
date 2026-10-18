extends RefCounted
## 빙하굴 뒷배경(gc.gd 전용): 깊은 얼음 크레바스를 내려다본 모습 — 겹겹이 물러나는 반투명 푸른 얼음벽(위가 가깝고 밝다),
## 턱마다 늘어진 고드름, 저 아래 남빛 어둠과 희미한 찬 빛, 물안개 띠, 떠도는 눈 알갱이. 가로로 이어 붙여도 이음매가 없다(주기 잡음·정수 주기 사인).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Mat := preload("res://tools/floor_art/rift/gc_mat.gd")

const NAVY := Color("#070d18")
const DEEP := Color("#0f2236")
const ICE := Color("#4f86a4")
const ICE_HI := Color("#a8d4e6")
const HAZE := Color("#5c7c94")


## x 주기 w의 능선(정수 주기 사인 합) — 층마다 다른 모양.
static func _ridge(x: float, w: int, k: int, amp: float) -> float:
	var t := TAU * x / w
	var v := sin(t * (2 + k) + k * 1.3) * 0.45 + sin(t * (5 + k * 2) + k * 2.1) * 0.25
	v += (absf(sin(t * (11 + k * 3) + k)) - 0.6) * 0.2 + (absf(sin(t * (29 + k * 5) + k * 0.7)) - 0.6) * 0.06  # 모난 얼음 턱
	return amp * v


static func paint(w: int, h: int, s: int) -> Paint:
	var p := Paint.new(w, h, s)
	var f := Seam.field(w, h, s, 0.006, 4)
	var g := Seam.field(w, h, s + 1, 0.012, 3)
	var vs := Seam.field(w, maxi(2, h / 8), s + 2, 0.04, 3)
	var tops: Array[float] = [-0.02, 0.15, 0.31, 0.46, 0.6, 0.72]
	var layers := tops.size()
	var lip := PackedFloat32Array()  # 층마다 x별 턱 높이
	lip.resize(layers * w)
	for k in layers:
		for x in w:
			lip[k * w + x] = tops[k] * h + _ridge(x, w, k, h * (0.03 + k * 0.004))
	for y in h:
		for x in w:
			var i := y * w + x
			var fy := float(y) / h
			var c := DEEP.lerp(NAVY, smoothstep(0.4, 0.95, fy))  # 가장 깊은 바탕
			c = c.lerp(Color("#2a5a78"), exp(-pow((fy - 0.88) / 0.07, 2.0)) * 0.3 * (0.5 + f[i]))  # 저 아래 희미한 찬 빛
			for k in range(layers - 1, -1, -1):  # 아래(먼) 층부터 칠하고 위(가까운) 층이 덮는다
				var top := lip[k * w + x]
				if y < top:
					continue
				var near := 1.0 - float(k) / layers
				var depth := (y - top) / (h * 0.24)
				var streak := Mat.sample(vs, w, maxi(2, h / 8), x, y / 8.0)
				var t := 0.5 + ((streak - 0.5) * 0.8 + (g[i] - 0.5) * 0.6) * (0.5 + near * 0.7) - depth * 0.55 + near * 0.12
				t += sin((y - top) * 0.12 + streak * 4.0) * 0.04  # 옅은 얼음 층
				var wall := DEEP.lerp(ICE, clampf(t, 0.0, 1.0)).lerp(ICE_HI, clampf((t - 0.7) * 1.6, 0.0, 0.55))
				wall = wall.lerp(Color("#7fd0ec"), smoothstep(0.66, 0.85, g[i]) * 0.25 * clampf(1.0 - depth, 0.0, 1.0))  # 비치는 속빛
				wall = wall.lerp(NAVY, clampf(0.1 + (1.0 - near) * 0.55 + depth * 0.3, 0.0, 0.92))
				wall = wall.lerp(HAZE, (1.0 - near) * 0.2 * (1.0 - depth * 0.5))
				var dl := y - top
				if dl < 3.5:  # 턱 위 눈
					wall = wall.lerp(ICE_HI.lerp(NAVY, (1.0 - near) * 0.55), 0.8 * (1.0 - dl / 3.5))
				elif dl < 9.0:  # 턱 밑 그늘
					wall = wall.darkened(0.3 * (1.0 - (dl - 3.5) / 5.5))
				c = wall
				break
			var mist := smoothstep(0.5, 0.8, f[i]) * (exp(-pow((fy - 0.55) / 0.1, 2.0)) + exp(-pow((fy - 0.8) / 0.08, 2.0)) * 0.7)
			c = c.lerp(HAZE, mist * 0.28)  # 물안개 띠
			p.blend(x, y, c, 1.0)
	# 턱에서 늘어진 고드름(가로 주기 — 가장자리 것은 반대쪽에도 그린다)
	for k in layers:
		var near := 1.0 - float(k) / layers
		var n := 70 + k * 16
		for j in n:
			if Paint.hash01(j, k + 11, s) < 0.35:
				continue
			var x := (j + Paint.hash01(j, k, s) * 0.8) * w / n
			var top := lip[k * w + clampi(int(x), 0, w - 1)]
			var ln := (6.0 + pow(Paint.hash01(j, k + 7, s), 2.0) * 46.0) * near
			var wd := (1.4 + Paint.hash01(j, k + 3, s) * 2.6) * near
			var light := ICE_HI.lerp(NAVY, (1.0 - near) * 0.6)
			var dark := ICE.lerp(NAVY, 0.45 + (1.0 - near) * 0.45)
			for off: float in [0.0, float(w), -float(w)]:
				var root := Vector2(x + off, top + 2.0)
				if root.x < -20 or root.x > w + 20:
					continue
				Mat.spike(p, root, root + Vector2(0.4, ln), wd, light, dark, 0.6 * near)
	# 떠도는 눈 알갱이
	for k in 420:
		var q := Vector2(p.rng.randf() * w, p.rng.randf() * h)
		var r := p.rng.randf_range(0.6, 2.0)
		var a := p.rng.randf_range(0.25, 0.7) * (1.0 - q.y / h * 0.5)
		for off: float in [0.0, float(w), -float(w)]:
			_flake(p, q + Vector2(off, 0), r, a)
	Ink.grade(p, 0.12, 1.05, Color("#0a0e14"), Color("#d8e4ea"), 0.1)
	Ink.finish(p, 0.03, 0.0)
	return p


static func _flake(p: Paint, q: Vector2, r: float, a: float) -> void:
	if q.x < -4 or q.x > p.w + 4:
		return
	for y in range(int(q.y - r) - 1, int(q.y + r) + 2):
		for x in range(int(q.x - r) - 1, int(q.x + r) + 2):
			var d := Vector2(x - q.x, y - q.y).length() / r
			if d < 1.0:
				p.add_light(x, y, Color("#c8dcea"), a * (1.0 - d * d))
