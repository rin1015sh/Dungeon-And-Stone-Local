extends RefCounted
## 잉크·빛·마감(Paint 캔버스 위): 떨리는 잉크 선 · 윤곽 · 그늘 빗금 · 빛 번짐 · 그늘 그라디언트 · 색 보정 · 그레인 · 비네트.
## tools/paint_city.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")
const INK := Color("#17110d")


## 손으로 그은 선: 획 두께가 가운데에서 굵고 끝에서 가늘며, 수직으로 살짝 떨린다.
static func line(p: Paint, a: Vector2, b: Vector2, width: float, c: Color = INK, alpha: float = 0.9, wobble: float = 0.8, tint_only: bool = false) -> void:
	var length := a.distance_to(b)
	if length < 0.5:
		return
	var dir := (b - a) / length
	var nrm := Vector2(-dir.y, dir.x)
	var steps := int(length * 1.5) + 1
	var phase := p.rng.randf() * 100.0
	var pts := PackedVector2Array()
	var radii := PackedFloat32Array()
	for i in steps + 1:
		var t := float(i) / steps
		var q := a.lerp(b, t)
		var wob := sin(t * length * 0.11 + phase) * 0.6 + sin(t * length * 0.37 + phase * 1.7) * 0.4
		pts.append(q + nrm * wob * wobble)
		var press := 0.55 + 0.45 * sin(t * PI)
		radii.append(maxf(0.35, width * 0.5 * press * (0.85 + 0.3 * sin(t * 9.0 + phase))))
	_stamp_path(p, pts, radii, c, alpha, tint_only)


## 꺾인 선(닫으면 윤곽).
static func path(p: Paint, pts: PackedVector2Array, width: float, closed: bool = true, c: Color = INK, alpha: float = 0.9, wobble: float = 0.8) -> void:
	var n := pts.size()
	for i in (n if closed else n - 1):
		line(p, pts[i], pts[(i + 1) % n], width, c, alpha, wobble)
	if width >= 1.8:  # 스케치처럼 한 번 더 비껴 긋는다
		var off := Vector2(p.rng.randf_range(-1.5, 1.5), p.rng.randf_range(-1.5, 1.5))
		for i in (n if closed else n - 1):
			if p.rng.randf() < 0.6:
				line(p, pts[i] + off, pts[(i + 1) % n] + off, width * 0.5, c, alpha * 0.35, wobble * 1.5)


static func _stamp_path(p: Paint, pts: PackedVector2Array, radii: PackedFloat32Array, c: Color, alpha: float, tint_only: bool = false) -> void:
	var touched := PackedInt32Array()
	for i in pts.size():
		var q := pts[i]
		var rad := radii[i]
		for yy in range(maxi(0, int(q.y - rad - 1)), mini(p.h - 1, int(q.y + rad + 1)) + 1):
			for xx in range(maxi(0, int(q.x - rad - 1)), mini(p.w - 1, int(q.x + rad + 1)) + 1):
				var d := Vector2(xx + 0.5, yy + 0.5).distance_to(q)
				var cov := clampf(rad - d + 0.5, 0.0, 1.0)
				var k := yy * p.w + xx
				if cov > p._stroke[k]:
					if p._stroke[k] <= 0.0:
						touched.append(k)
					p._stroke[k] = cov
	for k in touched:
		var xx := k % p.w
		var yy := k / p.w
		var a := p._stroke[k] * alpha * (0.8 + 0.4 * p.nz("hi", xx, yy))
		if tint_only:
			p.tint(xx, yy, c, a)
		else:
			p.blend(xx, yy, c, a)
		p._stroke[k] = 0.0


## 붓 자국: 다각형 안(이미 칠한 곳)에 짧고 굵은 반투명 획을 흩뿌린다 — 밑색을 조금씩 밝거나 어둡게 바꿔 덧칠한 느낌.
static func strokes(p: Paint, poly: PackedVector2Array, density: float = 1.0, length: float = 14.0, width: float = 5.0, angle_deg: float = 75.0, amt: float = 0.12, alpha: float = 0.35) -> void:
	var r := Paint.bounds(poly)
	var n := int(r.size.x * r.size.y / (length * width * 2.5) * density)
	for i in n:
		var q := Vector2(r.position.x + p.rng.randf() * r.size.x, r.position.y + p.rng.randf() * r.size.y)
		if not Geometry2D.is_point_in_polygon(q, poly):
			continue
		var base := p.get_c(int(q.x), int(q.y))
		if base.a <= 0.0:
			continue
		var d := p.rng.randf_range(-amt, amt)
		var c := base.lightened(d) if d > 0.0 else base.darkened(-d)
		c = c.lerp(Color(c.r * 1.06, c.g, c.b * 0.92) if p.rng.randf() < 0.5 else Color(c.r * 0.94, c.g, c.b * 1.06), 0.5)
		var dir := Vector2.from_angle(deg_to_rad(-angle_deg + p.rng.randf_range(-14.0, 14.0)))
		var ln := length * p.rng.randf_range(0.6, 1.4)
		line(p, q - dir * ln / 2.0, q + dir * ln / 2.0, width * p.rng.randf_range(0.6, 1.2), c, alpha, 0.6, true)


## 때 자국: (x..x+gw) 아래로 흘러내린 얼룩(창턱·돌림띠 밑).
static func grime(p: Paint, x: float, y: float, gw: float, max_len: float, strength: float = 0.4, c: Color = Color("#1e1a12")) -> void:
	for xx in range(int(x), int(x + gw)):
		var ln := max_len * (0.3 + p.nz("vs", xx, int(y)) * 0.9) * (0.6 + 0.4 * sin(float(xx - x) / gw * PI))
		for k in int(ln):
			var t := float(k) / maxf(1.0, ln)
			p.tint(xx, int(y) + k, c, strength * (1.0 - t) * (1.0 - t) * (0.6 + 0.6 * p.nz("mid", xx, int(y) + k)))


## 전체 빛 방향: 왼쪽 위에서 오른쪽 아래로 어두워진다(칠한 곳만).
static func light_dir(p: Paint, amount: float = 0.35, c: Color = Color("#0e0d0c")) -> void:
	for y in p.h:
		for x in p.w:
			var t := clampf((float(x) / p.w) * 0.55 + (float(y) / p.h) * 0.45, 0.0, 1.0)
			p.tint(x, y, c, amount * t * t)


## 빗금: 다각형 안에 기울어진 평행선(펜 그늘). 선마다 끊기고 흔들린다.
static func hatch(p: Paint, poly: PackedVector2Array, spacing: float, angle_deg: float = 60.0, alpha: float = 0.35, width: float = 1.0, c: Color = INK) -> void:
	var r := Paint.bounds(poly)
	var dir := Vector2.from_angle(deg_to_rad(-angle_deg))
	var nrm := Vector2(-dir.y, dir.x)
	var center := r.get_center()
	var reach := r.size.length() / 2.0 + 2.0
	var off := -reach
	while off < reach:
		var base := center + nrm * (off + p.rng.randf_range(-spacing * 0.25, spacing * 0.25))
		var a := base - dir * reach
		var b := base + dir * reach
		var seg := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), poly)
		for s: PackedVector2Array in seg:
			if s.size() >= 2 and p.rng.randf() < 0.88:
				var t0 := p.rng.randf_range(0.0, 0.12)
				var t1 := p.rng.randf_range(0.88, 1.0)
				line(p, s[0].lerp(s[1], t0), s[0].lerp(s[1], t1), width, c, alpha * p.rng.randf_range(0.6, 1.0), 0.5)
		off += spacing


## 다각형 안을 방향 그라디언트로 어둡게/물들이기(그늘). from→to 사이 amount_a → amount_b.
static func shade(p: Paint, poly: PackedVector2Array, from: Vector2, to: Vector2, amount_a: float, amount_b: float, c: Color = Color("#120e0c")) -> void:
	var d := to - from
	var len2 := maxf(1.0, d.length_squared())
	var sh := func(x: int, y: int) -> Color:
		var t := clampf((Vector2(x, y) - from).dot(d) / len2, 0.0, 1.0)
		return Color(c.r, c.g, c.b, lerpf(amount_a, amount_b, t))
	p.fill_poly(poly, sh, 1.0, true)


## 둥근 빛 번짐(더하기). radius 밖은 0, 가운데로 갈수록 제곱으로 밝다.
static func glow(p: Paint, cx: float, cy: float, radius: float, c: Color, strength: float, only_painted: bool = true, squash: float = 1.0) -> void:
	for yy in range(int(cy - radius * squash), int(cy + radius * squash) + 1):
		for xx in range(int(cx - radius), int(cx + radius) + 1):
			var d := Vector2(xx - cx, (yy - cy) / squash).length() / radius
			if d < 1.0:
				var f := (1.0 - d) * (1.0 - d)
				p.add_light(xx, yy, c, strength * f * (0.85 + 0.3 * p.nz("mid", xx, yy)), only_painted)


## 칠한 그림 둘레에 잉크 윤곽(알파 경계). width 픽셀.
static func silhouette(p: Paint, width: int = 2, c: Color = INK, alpha: float = 0.85) -> void:
	var marks: Array[Vector3] = []
	for y in p.h:
		for x in p.w:
			if p.alpha_at(x, y) > 0.5:
				continue
			var best := 0.0
			for dy in range(-width, width + 1):
				for dx in range(-width, width + 1):
					if dx * dx + dy * dy <= width * width and p.alpha_at(x + dx, y + dy) > 0.5:
						best = maxf(best, 1.0 - (sqrt(dx * dx + dy * dy) - 1.0) / width * 0.5)
			if best > 0.0:
				marks.append(Vector3(x, y, best))
	for m in marks:
		p.blend(int(m.x), int(m.y), c, alpha * m.z)


## 색 보정: 채도를 빼고, 그늘은 차가운 녹갈색 · 밝은 곳은 병든 황록빛으로 민다(피어 앤 헝거 2 톤).
static func grade(p: Paint, desat: float = 0.3, contrast: float = 1.08, shadow: Color = Color("#1d2120"), high: Color = Color("#d8cf9a"), split: float = 0.12) -> void:
	for i in p.w * p.h:
		var k := i * 4
		if p.buf[k + 3] <= 0.0:
			continue
		var c := Color(p.buf[k], p.buf[k + 1], p.buf[k + 2])
		var lum := c.get_luminance()
		c = c.lerp(Color(lum, lum, lum), desat)
		c = Color((c.r - 0.5) * contrast + 0.5, (c.g - 0.5) * contrast + 0.5, (c.b - 0.5) * contrast + 0.5)
		c = c.lerp(shadow, split * (1.0 - lum) * (1.0 - lum)).lerp(high, split * lum * lum)
		p.buf[k] = clampf(c.r, 0.0, 1.0)
		p.buf[k + 1] = clampf(c.g, 0.0, 1.0)
		p.buf[k + 2] = clampf(c.b, 0.0, 1.0)


## 필름 그레인 + (선택) 비네트.
static func finish(p: Paint, grain: float = 0.035, vignette: float = 0.0) -> void:
	var cx := p.w / 2.0
	var cy := p.h / 2.0
	var rmax := Vector2(cx, cy).length()
	for y in p.h:
		for x in p.w:
			var k := (y * p.w + x) * 4
			if p.buf[k + 3] <= 0.0:
				continue
			var g := (p.rng.randf() - 0.5) * grain * 2.0
			var v := 1.0
			if vignette > 0.0:
				var d := Vector2((x - cx) / rmax, (y - cy) / rmax * 1.25).length()
				v = 1.0 - vignette * smoothstep(0.35, 1.05, d)
			for j in 3:
				p.buf[k + j] = clampf((p.buf[k + j] + g) * v, 0.0, 1.0)
