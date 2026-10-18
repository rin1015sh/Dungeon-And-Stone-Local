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
	return amp * (sin(t * (3 + k) + k * 1.3) * 0.5 + sin(t * (7 + k * 2) + k * 2.1) * 0.3 + sin(t * (13 + k * 3) + k) * 0.2)


static func paint(w: int, h: int, s: int) -> Paint:
	var p := Paint.new(w, h, s)
	var f := Seam.field(w, h, s, 0.006, 4)
	var g := Seam.field(w, h, s + 1, 0.02, 3)
	var vs := Seam.field(w, maxi(2, h / 6), s + 2, 0.05, 3)
	var layers := 5
	var tops: Array[float] = [0.04, 0.22, 0.4, 0.56, 0.7]
	for y in h:
		for x in w:
			var i := y * w + x
			var fy := float(y) / h
			# 가장 깊은 바탕: 아래로 갈수록 남빛 어둠, 아래쪽 가운데 띠에 희미한 찬 빛
			var c := DEEP.lerp(NAVY, smoothstep(0.35, 0.95, fy))
			c = c.lerp(Color("#2a5a78"), exp(-pow((fy - 0.86) / 0.08, 2.0)) * 0.35 * (0.6 + f[i] * 0.8))
			# 얼음벽 층: 위 층일수록 가깝고 밝고 앞에 있다(먼저 맞는 층을 칠한다)
			for k in layers:
				var top := tops[k] * h + _ridge(x, w, k, h * 0.035)
				var bot := top + h * (0.2 - k * 0.025) + _ridge(x + 300.0, w, k + 5, h * 0.03)
				if y < top or y > bot:
					continue
				var near := 1.0 - float(k) / layers
				var ly := (y - top) / maxf(1.0, bot - top)
				var streak := Mat.sample(vs, w, maxi(2, h / 6), x, y / 6.0)
				var t := 0.35 + (streak - 0.5) * 0.7 + (g[i] - 0.5) * 0.4 - ly * 0.35
				var wall := DEEP.lerp(ICE, clampf(t, 0.0, 1.0)).lerp(ICE_HI, clampf((t - 0.75) * 2.0, 0.0, 0.6))
				if absf(fposmod((y - top) + streak * 12.0, 16.0) - 1.0) < 0.9:  # 얼음 층선
					wall = wall.lerp(ICE_HI, 0.25)
				wall = wall.lerp(NAVY, 0.25 + (1.0 - near) * 0.55)  # 멀수록 어둡고 흐림
				wall = wall.lerp(HAZE, (1.0 - near) * 0.18)
				var a := smoothstep(bot, bot - h * 0.04, float(y)) * smoothstep(top - 1.0, top + 1.5, float(y))
				c = c.lerp(wall, a)
				if y - top < 3.0:  # 턱 위 눈선
					c = c.lerp(ICE_HI.lerp(NAVY, (1.0 - near) * 0.6), 0.7 * (1.0 - (y - top) / 3.0))
				break
			# 물안개 띠
			var mist := smoothstep(0.55, 0.8, g[i]) * exp(-pow((fy - 0.62) / 0.12, 2.0))
			c = c.lerp(HAZE, mist * 0.3)
			p.blend(x, y, c, 1.0)
	# 턱마다 늘어진 고드름(가로 주기 — 양쪽으로 한 번 더 그린다)
	for k in layers:
		var near := 1.0 - float(k) / layers
		var n := 40 + k * 12
		for j in n:
			var x := (j + Paint.hash01(j, k, s) * 0.8) * w / n
			var bot := tops[k] * h + _ridge(x, w, k, h * 0.035) + h * (0.2 - k * 0.025) + _ridge(x + 300.0, w, k + 5, h * 0.03)
			var ln := (8.0 + Paint.hash01(j, k + 7, s) * 30.0) * near
			var wd := (1.5 + Paint.hash01(j, k + 3, s) * 2.5) * near
			var light := ICE_HI.lerp(NAVY, (1.0 - near) * 0.65)
			var dark := ICE.lerp(NAVY, 0.4 + (1.0 - near) * 0.5)
			for off: float in [0.0, float(w), -float(w)]:
				var root := Vector2(x + off, bot - 2.0)
				if root.x < -20 or root.x > w + 20:
					continue
				Mat.spike(p, root, root + Vector2(0.5, ln), wd, light, dark, 0.5 * near)
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
