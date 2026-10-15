extends RefCounted
## 마무리 손질: 피(흘러내림·튄 자국) · 때 · 색 보정 · 그레인 — 칠과 잉크가 끝난 그림 위에.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

const BLOOD := Color("#5a0d0a")


static func done(p: Paint, spec: Dictionary, j: Dictionary, H: float) -> void:
	var blood := float(spec.get("blood", 0.0))
	if blood > 0.0:
		_blood(p, j, H, blood)
	grime(p, float(spec.get("grime", 0.35)))
	if spec.has("fade"):  # 아래로 갈수록 흐려지는 유령
		var f0 := float(spec["fade"])
		for y in p.h:
			var a := 1.0 - smoothstep(p.h * f0, p.h * 0.98, float(y)) * (0.75 + 0.25 * 0.0)
			for x in p.w:
				var k := (y * p.w + x) * 4 + 3
				p.buf[k] *= clampf(a + (p.nz("mid", x, y) - 0.5) * 0.4 * (1.0 - a), 0.0, 1.0)
	Ink.grade(p, float(spec.get("desat", 0.18)), 1.05, Color("#1a1412"), Color("#e0d2b0"), 0.1)
	Ink.finish(p, 0.03)


## 피: 손·아래팔·정강이를 적신 얼룩(잡음 가장자리) + 상처에서 흘러내린 가는 줄 + 번진 자국. 칠한 곳 위에 곱하듯 물든다.
static func _blood(p: Paint, j: Dictionary, H: float, amt: float) -> void:
	var soak: Array = []  # [시작, 끝, 반지름] — 끝 쪽이 진하게
	for t: String in ["l", "r"]:
		if j.has("wrist_" + t):
			soak.append([j["elbow_" + t], j["hand_" + t], 0.05 * H])
		if j.has("ankle_" + t) and amt > 0.6:
			soak.append([j["knee_" + t], j["ankle_" + t], 0.045 * H])
	for sk: Array in soak:
		var a3: Vector3 = sk[0]
		var b3: Vector3 = sk[1]
		var a := Vector2(a3.x, a3.y)
		var b := Vector2(b3.x, b3.y)
		var r: float = sk[2]
		var ab := b - a
		var l2 := maxf(1.0, ab.length_squared())
		for y in range(int(minf(a.y, b.y) - r), int(maxf(a.y, b.y) + r) + 1):
			for x in range(int(minf(a.x, b.x) - r), int(maxf(a.x, b.x) + r) + 1):
				if p.alpha_at(x, y) < 0.9:
					continue
				var q := Vector2(x, y)
				var t := clampf((q - a).dot(ab) / l2, 0.0, 1.0)
				if (q - (a + ab * t)).length() > r:
					continue
				var v := p.nz("mid", x, y) * 0.6 + p.nz("hi", x, y) * 0.4 + t * 0.55 * amt
				if v > 0.78:
					_stain(p, x, y, clampf((v - 0.78) * 5.0, 0.0, 0.85))
	var srcs: Array = []
	for k: String in ["chest", "waist", "shoulder_l", "shoulder_r", "head"]:
		if j.has(k):
			var v: Vector3 = j[k]
			srcs.append(Vector2(v.x, v.y + (0.06 * H if k == "head" else 0.0)))
	for i in int(3 + amt * 7):  # 흘러내린 줄
		var s: Vector2 = srcs[p.rng.randi() % srcs.size()] + Vector2(p.rng.randf_range(-1, 1) * H * 0.05, p.rng.randf_range(-0.5, 1) * H * 0.04)
		var length := H * p.rng.randf_range(0.05, 0.16) * (0.5 + amt * 0.6)
		var wd := H * p.rng.randf_range(0.003, 0.007)
		var x := s.x
		var y := s.y
		var ph := p.rng.randf() * 10.0
		for t in int(length):
			var f := float(t) / length
			var rr := wd * (1.0 - f * 0.5) * (0.8 + 0.4 * sin(f * 9.0 + ph))
			x += sin(y * 0.05 + ph) * 0.3
			for xx in range(int(x - rr - 1), int(x + rr + 1) + 1):
				var d := absf(xx + 0.5 - x) / maxf(0.5, rr)
				if d < 1.0 and p.alpha_at(xx, int(y)) > 0.9:
					_stain(p, xx, int(y), (1.0 - d * d) * 0.8)
			y += 1.0
	for i in int(amt * 8):  # 튄 자국·번진 얼룩
		var s: Vector2 = srcs[p.rng.randi() % srcs.size()] + Vector2(p.rng.randf_range(-1, 1), p.rng.randf_range(-1, 1)) * H * 0.06
		var r := H * p.rng.randf_range(0.012, 0.035)
		for yy in range(int(s.y - r), int(s.y + r) + 1):
			for xx in range(int(s.x - r), int(s.x + r) + 1):
				var d := Vector2(xx - s.x, yy - s.y).length() / r
				if d < 1.0 and p.alpha_at(xx, yy) > 0.9 and p.nz("mid", xx, yy) + p.nz("hi", xx, yy) * 0.4 > 0.55 + d * 0.5:
					_stain(p, xx, yy, (1.0 - d) * 0.7)


## 피 물들이기: 밑색의 밝기를 남긴 채 붉게(밝은 살은 선홍, 그늘은 검붉게).
static func _stain(p: Paint, x: int, y: int, a: float) -> void:
	var c := p.get_c(x, y)
	var lum := c.get_luminance()
	var b := Color(0.45 * lum + 0.12, 0.05 * lum + 0.01, 0.04 * lum + 0.01)
	p.tint(x, y, b, a)


## 때: 아래쪽일수록 탁하게 + 큰 얼룩.
static func grime(p: Paint, amt: float) -> void:
	if amt <= 0.0:
		return
	for y in p.h:
		var ty := float(y) / p.h
		for x in p.w:
			var k := (y * p.w + x) * 4
			if p.buf[k + 3] <= 0.0:
				continue
			var n := p.nz("lo", x, y)
			var a := amt * (smoothstep(0.55, 1.0, ty) * 0.5 + clampf((n - 0.6) * 2.0, 0.0, 0.5))
			p.buf[k] = lerpf(p.buf[k], 0.16, a * 0.5)
			p.buf[k + 1] = lerpf(p.buf[k + 1], 0.12, a * 0.5)
			p.buf[k + 2] = lerpf(p.buf[k + 2], 0.09, a * 0.5)
