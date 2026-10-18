extends RefCounted
## 녹색 탄광 뒷배경: 낭떠러지 너머 끝없는 갱도 구렁을 내려다본 모습.
## 청회 바위 절벽 결 → 아래로 내려가는 비계·사다리·밧줄(깊을수록 안개에 묻힘) → 먼 랜턴 점 · 깊은 곳 녹색 결정 빛 → 먼지 안개.
## 가로로 이어 붙여도 이음매가 없게: 잡음은 가로 주기(Seam), 물건은 x ± w에 한 번 더 그린다. 세로는 이어 붙이지 않는다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const K := preload("res://tools/floor_art/rift/gm_kit.gd")

const TOP := Color("#1e222c")
const MID := Color("#0d0f15")
const DEEP := Color("#050609")
const FOG := Color("#2a3040")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var haze := Seam.field(w, h, seed_value, 0.004, 4)
	var rock := Seam.field(w, h, seed_value + 1, 0.0035, 5)
	var fine := Seam.field(w, h, seed_value + 2, 0.03, 3)
	for y in h:
		var t := float(y) / h
		var bg := TOP.lerp(MID, smoothstep(0.0, 0.45, t)).lerp(DEEP, smoothstep(0.45, 1.0, t))
		for x in w:
			var i := y * w + x
			var c := bg.lerp(FOG, (haze[i] - 0.3) * 0.25 * (1.0 - t))
			# 바위 턱: 가로로 늘인 잡음(가로 주기) — 윗변은 빛 받고 아래는 그늘, 아래로 갈수록 어둠에 묻힘
			var ry := y * 2
			var v := Seam.at(rock, w, h, x, ry) * 0.9 + Seam.at(fine, w, h, x, y) * 0.1
			var th := 0.6 + t * 0.12
			if v > th:
				var above := Seam.at(rock, w, h, x, ry - 6) * 0.9 + Seam.at(fine, w, h, x, y - 3) * 0.1
				var rc := K.ROCK.lerp(K.ROCK_VIOLET, haze[i]).darkened(0.55)
				if above <= th:
					rc = rc.lightened(0.35)  # 턱 윗변
				rc = rc.darkened(clampf((v - th) * 2.5, 0.0, 0.4))
				c = c.lerp(rc, smoothstep(th, th + 0.02, v) * (1.0 - smoothstep(0.1, 0.9, t)))
			elif v > th - 0.03:
				c = c.lerp(Color("#06070a"), 0.4 * (1.0 - smoothstep(0.1, 0.9, t)))  # 턱 아래 그늘
			p.blend(x, y, c, 1.0)
	_fog_band(p, h * 0.32, h * 0.08, 0.10)
	_fog_band(p, h * 0.58, h * 0.1, 0.07)
	var rng := p.rng
	for k in 9:  # 내려가는 비계(먼 것부터)
		var depth := float(k) / 8.0
		_tower(p, rng.randf() * w, rng.randf_range(-40.0, h * 0.25), rng.randf_range(34.0, 70.0) * (0.6 + depth * 0.6), depth)
	for k in 26:  # 밧줄·사슬
		var x := rng.randf() * w
		var ln := rng.randf_range(h * 0.2, h * 0.75)
		_wline(p, Vector2(x, -5), Vector2(x + rng.randf_range(-6, 6), ln), rng.randf_range(0.8, 1.6), Color("#4a4034"), 0.5, ln)
	for k in 6:  # 사다리
		var x := rng.randf() * w
		var y0 := rng.randf_range(-20.0, h * 0.3)
		var ln := rng.randf_range(120.0, 300.0)
		_ladder(p, Vector2(x, y0), ln)
	var spots: Array[Vector2] = []
	for k in 5:
		spots.append(Vector2(rng.randf() * w, rng.randf_range(h * 0.5, h * 0.9)))
	for k in 18:  # 깊은 곳 녹색 결정 빛(몇 무리로 모임)
		var q := spots[k % 5] + Vector2(rng.randf_range(-90, 90), rng.randf_range(-40, 40))
		var r := rng.randf_range(10.0, 40.0)
		_wglow(p, q, r * 2.2, K.LIME_GLOW, rng.randf_range(0.08, 0.18))
		_wglow(p, q, r * 0.35, K.LIME_LIGHT, 0.25)
		for j in rng.randi_range(2, 4):
			var a := q + Vector2(rng.randf_range(-r * 0.3, r * 0.3), rng.randf_range(-2, 2))
			_wline(p, a, a + Vector2(rng.randf_range(-3, 3), -rng.randf_range(3.0, r * 0.35)), rng.randf_range(1.2, 2.2), K.LIME, 0.7, 0.0)
	for k in 18:  # 먼 랜턴 점
		var q := Vector2(rng.randf() * w, rng.randf_range(h * 0.12, h * 0.85))
		var t := q.y / h
		_wglow(p, q, rng.randf_range(10.0, 22.0) * (1.0 - t * 0.5), K.LAMP, 0.32 * (1.0 - t * 0.6))
		_wdot(p, q, 1.3, Color("#ffe0a0"), 0.9 * (1.0 - t * 0.5))
	for k in 1400:  # 떠도는 먼지
		var q := Vector2(rng.randf() * w, rng.randf() * h)
		p.add_light(int(q.x), int(q.y), Color("#8a90a0"), rng.randf_range(0.03, 0.12) * (1.0 - q.y / h * 0.6))
	Ink.finish(p, 0.025, 0.0)
	return p


## 가로 안개 띠(더하기 빛 — 칠한 바탕 위).
static func _fog_band(p: Paint, cy: float, hw: float, a: float) -> void:
	for y in range(maxi(0, int(cy - hw * 2.0)), mini(p.h - 1, int(cy + hw * 2.0)) + 1):
		var f := exp(-pow((y - cy) / hw, 2.0)) * a
		for x in p.w:
			p.add_light(x, y, FOG, f * (0.6 + 0.8 * p.nz("lo", x, y)))


## 비계 탑 하나(기둥 둘 + X자 빗장 + 발판 + 걸린 랜턴): depth 0 = 멀다(작고 흐림), 1 = 가깝다.
static func _tower(p: Paint, x: float, y0: float, tw: float, depth: float) -> void:
	var col := Color("#2a2c34").lerp(Color("#3e3024"), depth)
	var bay := tw * 1.1
	var y1 := p.h * (0.7 + depth * 0.25)
	var wd := 1.2 + depth * 2.0
	var a := 0.35 + depth * 0.45
	for e: float in [0.0, tw]:
		_wline(p, Vector2(x + e, y0), Vector2(x + e, y1), wd, col, a, y1)
	var y := y0 + bay * 0.3
	var n := 0
	while y < y1 - bay * 0.5:
		_wline(p, Vector2(x - 4, y), Vector2(x + tw + 4, y), wd * 0.9, col.lightened(0.05), a, y1)
		if n % 2 == 0:
			_wline(p, Vector2(x, y), Vector2(x + tw, y + bay), wd * 0.6, col, a * 0.8, y1)
		else:
			_wline(p, Vector2(x + tw, y), Vector2(x, y + bay), wd * 0.6, col, a * 0.8, y1)
		if p.rng.randf() < 0.18 and y < p.h * 0.8:
			var q := Vector2(x + p.rng.randf_range(0.2, 0.8) * tw, y + 6.0)
			_wglow(p, q, 12.0 + depth * 14.0, K.LAMP, 0.3 * (1.0 - y / p.h * 0.5))
			_wdot(p, q, 1.2 + depth, Color("#ffe0a0"), 0.9)
		y += bay
		n += 1


static func _ladder(p: Paint, top: Vector2, ln: float) -> void:
	var col := Color("#3a3028")
	var y1 := top.y + ln
	for e: float in [0.0, 12.0]:
		_wline(p, top + Vector2(e, 0), Vector2(top.x + e, y1), 1.4, col, 0.6, y1)
	var y := top.y + 6.0
	while y < y1:
		_wline(p, Vector2(top.x, y), Vector2(top.x + 12.0, y), 1.1, col, 0.55, y1)
		y += 9.0


## 가로로 감싸 그리는 선: x가 가장자리 너머면 반대쪽에 한 번 더. fade_y > 0이면 아래쪽 끝으로 갈수록 어둠에 묻힌다.
static func _wline(p: Paint, a: Vector2, b: Vector2, wd: float, c: Color, alpha: float, fade_y: float) -> void:
	for off: float in [-p.w, 0.0, p.w]:
		var aa := a + Vector2(off, 0)
		var bb := b + Vector2(off, 0)
		if maxf(aa.x, bb.x) < -wd * 2.0 or minf(aa.x, bb.x) > p.w + wd * 2.0:
			continue
		if fade_y > 0.0:  # 깊어질수록 흐려지게 네 토막으로
			for k in 4:
				var t0 := k / 4.0
				var t1 := (k + 1) / 4.0
				var ya := aa.lerp(bb, t0)
				var fade := 1.0 - smoothstep(0.3, 1.0, ya.y / maxf(1.0, p.h))
				Ink.line(p, ya, aa.lerp(bb, t1), wd, c, alpha * fade, 0.4)
		else:
			Ink.line(p, aa, bb, wd, c, alpha, 0.4)


static func _wglow(p: Paint, q: Vector2, r: float, c: Color, s: float) -> void:
	for off: float in [-p.w, 0.0, p.w]:
		if q.x + off + r < 0.0 or q.x + off - r > p.w:
			continue
		Ink.glow(p, q.x + off, q.y, r, c, s)


static func _wdot(p: Paint, q: Vector2, r: float, c: Color, a: float) -> void:
	for off: float in [-p.w, 0.0, p.w]:
		if q.x + off + r < 0.0 or q.x + off - r > p.w:
			continue
		for y in range(int(q.y - r) - 1, int(q.y + r) + 2):
			for x in range(int(q.x + off - r) - 1, int(q.x + off + r) + 2):
				var d := Vector2(x - q.x - off, y - q.y).length() / maxf(r, 0.1)
				if d < 1.0:
					p.tint(x, y, c, a * (1.0 - d * d))
