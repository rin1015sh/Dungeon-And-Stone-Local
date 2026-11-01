extends SceneTree
## 동전 그림(사용자 2026-11-01 "피어 앤 헝거처럼 동전 던지기 — 애니메이션은 첨부 영상 참고", V25):
##   godot --headless --path . --script res://tools/paint_coin.gd [-- --out=<폴더>]
## → assets/ui/coin/heads.webp(앞면 — 늙은 현자의 옆얼굴) · tails.webp(뒷면 — 마석 문장과 고리) · edge.webp(옆 테두리 띠, 가로로 늘여 쓴다).
## 칠은 높이장 하나로 한다: 판·두툼한 테·구슬 고리·돋을새김(옆얼굴·문장)을 높이로 쌓고 → 기울기로 법선 → 왼쪽 위 빛으로 금속 칠
## (어두운 금 · 밝은 금 · 반사 하이라이트) → 오목한 곳에 때(높이를 흐린 것과의 차이) → 긁힘·얼룩 잡음 → 가장자리 투명.
## 실행 중 돌리기·튀기기는 CoinFlip(src/ui/widgets/CoinFlip.gd)이 그림을 눌러 그린다(이 그림은 정면 한 장씩).

const SIZE := 256
const R := 120.0  ## 동전 반지름(px)
const C := Vector2(128, 128)

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	var out := "res://assets/ui/coin"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	_rng.seed = 7
	_face(_heads_relief(), 11).save_webp(out + "/heads.webp", true, 0.9)
	_rng.seed = 8
	_face(_tails_relief(), 12).save_webp(out + "/tails.webp", true, 0.9)
	_edge().save_webp(out + "/edge.webp", true, 0.9)
	print("동전 그림 → ", out)
	quit()


# ── 높이장 ─────────────────────────────────────────────

func _new_field() -> PackedFloat32Array:
	var f := PackedFloat32Array()
	f.resize(SIZE * SIZE)
	return f


## 판 · 테 · 구슬 고리(앞뒤 같다).
func _base(f: PackedFloat32Array) -> void:
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(C)
			if d > R:
				continue
			var h := 0.25 + 0.08 * (1.0 - d / R)  # 판이 가운데로 아주 조금 볼록
			var rim := smoothstep(R - 13.0, R - 9.0, d) * (1.0 - smoothstep(R - 2.5, R, d) * 0.45)
			h += rim * 0.75
			f[y * SIZE + x] = h
	for i in 56:  # 테 안쪽 구슬 고리
		var t := TAU * float(i) / 56.0
		_bump(f, C + Vector2(cos(t), sin(t)) * (R - 19.0), 2.6, 0.32)


func _bump(f: PackedFloat32Array, at: Vector2, rad: float, hgt: float) -> void:
	for y in range(int(at.y - rad - 1), int(at.y + rad + 2)):
		for x in range(int(at.x - rad - 1), int(at.x + rad + 2)):
			if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
				continue
			var d := Vector2(x + 0.5, y + 0.5).distance_to(at) / rad
			if d < 1.0:
				f[y * SIZE + x] = maxf(f[y * SIZE + x], 0.25 + hgt * sqrt(1.0 - d * d))


## 다각형 덩어리를 돋을새김으로(가장자리를 흐린 마스크 × 높이 — 둥글게 솟는다).
func _emboss(f: PackedFloat32Array, poly: PackedVector2Array, hgt: float, soft: int) -> PackedFloat32Array:
	var m := _new_field()
	for y in SIZE:
		for x in SIZE:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
				m[y * SIZE + x] = 1.0
	m = _blur(m, soft)
	for i in SIZE * SIZE:
		if m[i] > 0.0:
			f[i] += hgt * pow(m[i], 0.6)
	return m


## 새긴 선(높이를 깎는다).
func _groove(f: PackedFloat32Array, pts: PackedVector2Array, width: float, depth: float) -> void:
	for k in pts.size() - 1:
		var a := pts[k]
		var b := pts[k + 1]
		var r := Rect2(a, Vector2.ZERO).expand(b).grow(width + 1.0)
		for y in range(maxi(0, int(r.position.y)), mini(SIZE, int(r.end.y) + 1)):
			for x in range(maxi(0, int(r.position.x)), mini(SIZE, int(r.end.x) + 1)):
				var p := Vector2(x + 0.5, y + 0.5)
				var d := p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))
				if d < width:
					f[y * SIZE + x] -= depth * (1.0 - d / width)


func _blur(src: PackedFloat32Array, rad: int) -> PackedFloat32Array:
	if rad <= 0:
		return src
	var tmp := _new_field()
	var out := _new_field()
	for y in SIZE:
		for x in SIZE:
			var s := 0.0
			for k in range(-rad, rad + 1):
				s += src[y * SIZE + clampi(x + k, 0, SIZE - 1)]
			tmp[y * SIZE + x] = s / float(rad * 2 + 1)
	for x in SIZE:
		for y in SIZE:
			var s := 0.0
			for k in range(-rad, rad + 1):
				s += tmp[clampi(y + k, 0, SIZE - 1) * SIZE + x]
			out[y * SIZE + x] = s / float(rad * 2 + 1)
	return out


func _pts(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in arr:
		out.append(C + (v - Vector2(0.5, 0.5)) * R * 2.0 * 0.78)
	return out


## 앞면: 왼쪽을 보는 늙은 현자의 옆얼굴(두건·긴 수염) — 좌표는 동전 안쪽 0~1, 선은 곡선(_curve)으로.
func _heads_relief() -> PackedFloat32Array:
	var f := _new_field()
	_base(f)
	var head := _curve([
		Vector2(0.50, 0.07), Vector2(0.66, 0.08), Vector2(0.78, 0.18), Vector2(0.84, 0.34), Vector2(0.82, 0.52),  # 두건 뒤
		Vector2(0.76, 0.64), Vector2(0.74, 0.78), Vector2(0.80, 0.93), Vector2(0.62, 0.97),  # 목·옷깃
		Vector2(0.50, 0.93), Vector2(0.42, 0.86), Vector2(0.34, 0.83), Vector2(0.29, 0.75),  # 수염 끝
		Vector2(0.31, 0.65), Vector2(0.29, 0.60), Vector2(0.31, 0.555),  # 수염 앞·입술
		Vector2(0.285, 0.525), Vector2(0.30, 0.50), Vector2(0.255, 0.455), Vector2(0.235, 0.42),  # 코끝
		Vector2(0.27, 0.37), Vector2(0.275, 0.33), Vector2(0.27, 0.28), Vector2(0.31, 0.18), Vector2(0.40, 0.10),  # 이마·두건 앞
	], true)
	_emboss(f, _pts(head), 0.55, 6)
	var hood := _curve([Vector2(0.40, 0.10), Vector2(0.50, 0.07), Vector2(0.66, 0.08), Vector2(0.78, 0.18), Vector2(0.84, 0.34),
		Vector2(0.82, 0.52), Vector2(0.76, 0.64), Vector2(0.64, 0.60), Vector2(0.60, 0.44), Vector2(0.54, 0.30), Vector2(0.44, 0.22),
		Vector2(0.33, 0.22)], true)
	_emboss(f, _pts(hood), 0.18, 4)  # 두건은 얼굴보다 한 겹 더
	_bump_rel(f, Vector2(0.43, 0.47), 0.085, 0.14)  # 광대
	_bump_rel(f, Vector2(0.33, 0.33), 0.05, 0.1)  # 눈썹 뼈
	_bump_rel(f, Vector2(0.27, 0.45), 0.035, 0.12)  # 콧방울
	_groove(f, _pts(_curve([Vector2(0.33, 0.22), Vector2(0.44, 0.22), Vector2(0.54, 0.30), Vector2(0.60, 0.44), Vector2(0.64, 0.60), Vector2(0.76, 0.64)])), 2.0, 0.2)
	_groove(f, _pts(_curve([Vector2(0.30, 0.355), Vector2(0.345, 0.34), Vector2(0.39, 0.355)])), 1.7, 0.16)  # 눈두덩
	_groove(f, _pts(_curve([Vector2(0.32, 0.385), Vector2(0.35, 0.395), Vector2(0.375, 0.385)])), 1.3, 0.2)  # 감은 눈
	_groove(f, _pts(_curve([Vector2(0.38, 0.40), Vector2(0.41, 0.43), Vector2(0.415, 0.48)])), 1.1, 0.09)  # 눈가 주름
	_groove(f, _pts(_curve([Vector2(0.30, 0.535), Vector2(0.35, 0.565), Vector2(0.40, 0.55), Vector2(0.44, 0.52)])), 1.5, 0.15)  # 콧수염
	for i in 8:  # 수염 결(물결)
		var x0 := 0.33 + i * 0.032
		var pts: Array = []
		for k in 6:
			var t := float(k) / 5.0
			pts.append(Vector2(x0 + 0.015 * sin(t * 5.0 + i) + t * 0.01, 0.58 + t * (0.22 - absf(i - 3.5) * 0.02)))
		_groove(f, _pts(_curve(pts)), 1.0, 0.11)
	for i in 4:  # 두건 주름(뒤로 흐르는 호)
		var pts2: Array = []
		for k in 6:
			var t := float(k) / 5.0
			pts2.append(Vector2(0.60 + i * 0.045 + t * 0.12, 0.14 + i * 0.05 + t * t * 0.32))
		_groove(f, _pts(_curve(pts2)), 1.1, 0.09)
	_groove(f, _pts(_curve([Vector2(0.56, 0.40), Vector2(0.52, 0.44), Vector2(0.53, 0.50), Vector2(0.57, 0.52)])), 1.5, 0.15)  # 귀
	_ticks(f, 0.0)
	return f


func _bump_rel(f: PackedFloat32Array, at: Vector2, rad: float, hgt: float) -> void:
	var c := C + (at - Vector2(0.5, 0.5)) * R * 2.0 * 0.78
	var rr := rad * R * 2.0 * 0.78
	for y in range(int(c.y - rr - 1), int(c.y + rr + 2)):
		for x in range(int(c.x - rr - 1), int(c.x + rr + 2)):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c) / rr
			if d < 1.0 and x >= 0 and y >= 0 and x < SIZE and y < SIZE:
				f[y * SIZE + x] += hgt * (0.5 + 0.5 * cos(d * PI))


## 점들을 지나는 매끈한 곡선(캣멀롬, 구간마다 8점). closed면 끝과 처음을 잇는다.
func _curve(pts: Array, closed: bool = false) -> Array:
	var out: Array = []
	var n := pts.size()
	var segs := n if closed else n - 1
	for i in segs:
		var p0: Vector2 = pts[(i - 1 + n) % n] if closed or i > 0 else pts[0]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n] if closed or i + 2 < n else pts[n - 1]
		for k in 8:
			var t := float(k) / 8.0
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	if not closed:
		out.append(pts[n - 1])
	return out


## 뒷면: 가운데 마석(마름모 결정)과 두 겹 고리, 빛살.
func _tails_relief() -> PackedFloat32Array:
	var f := _new_field()
	_base(f)
	for y in SIZE:  # 두 겹 고리(살짝 엇갈린 원 둘 — 참고 영상 뒷면의 고리 느낌)
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			for ring: Array in [[C + Vector2(-12, 6), 44.0], [C + Vector2(14, -8), 36.0]]:
				var d := absf(p.distance_to(ring[0] as Vector2) - float(ring[1]))
				if d < 4.0 and p.distance_to(C) < R - 22.0:
					f[y * SIZE + x] += 0.22 * (1.0 - d / 4.0)
	var gem := PackedVector2Array([C + Vector2(0, -40), C + Vector2(24, -6), C + Vector2(0, 40), C + Vector2(-24, -6)])
	_emboss(f, gem, 0.55, 3)
	_groove(f, PackedVector2Array([C + Vector2(-24, -6), C + Vector2(24, -6)]), 1.4, 0.14)  # 결정 깎은 면
	_groove(f, PackedVector2Array([C + Vector2(0, -40), C + Vector2(0, 40)]), 1.2, 0.1)
	for i in 16:  # 빛살
		var t := TAU * i / 16.0 + 0.2
		var a := C + Vector2(cos(t), sin(t)) * 56.0
		var b := C + Vector2(cos(t), sin(t)) * (84.0 if i % 2 == 0 else 74.0)
		_groove(f, PackedVector2Array([a, b]), 1.6, 0.14)
	_ticks(f, 0.5)
	return f


## 테 안쪽 글자 자리처럼 보이는 짧은 새김 눈금(읽히는 글자는 없다).
func _ticks(f: PackedFloat32Array, phase: float) -> void:
	for i in 40:
		var t := TAU * (float(i) + phase) / 40.0
		if absf(sin(t * 0.5)) < 0.12:
			continue
		var dir := Vector2(cos(t), sin(t))
		var a := C + dir * (R - 30.0)
		var b := C + dir * (R - 25.0) + dir.orthogonal() * _rng.randf_range(-2.0, 2.0)
		_groove(f, PackedVector2Array([a, b]), 1.1, 0.12)


# ── 칠 ─────────────────────────────────────────────────

const DARK := Color("#34260f")
const MID := Color("#8a6c30")
const LIGHT := Color("#d8c07a")
const SPEC := Color("#fff4cc")
const GRIME := Color("#1c140a")


func _face(f: PackedFloat32Array, seed_value: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.035
	var fine := FastNoiseLite.new()
	fine.seed = seed_value + 1
	fine.frequency = 0.3
	var low := _blur(f, 5)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var light := Vector3(-0.55, -0.6, 0.58).normalized()
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(C)
			if d > R + 1.0:
				continue
			var hx := (f[y * SIZE + mini(x + 1, SIZE - 1)] - f[y * SIZE + maxi(x - 1, 0)]) * 0.5
			var hy := (f[mini(y + 1, SIZE - 1) * SIZE + x] - f[maxi(y - 1, 0) * SIZE + x]) * 0.5
			var n := Vector3(-hx * 9.0, -hy * 9.0, 1.0).normalized()
			var lam := clampf(n.dot(light), 0.0, 1.0)
			var refl := (2.0 * n.dot(light) * n - light)
			var spec := pow(clampf(refl.z, 0.0, 1.0), 18.0)
			var c := DARK.lerp(MID, smoothstep(0.1, 0.6, lam)).lerp(LIGHT, smoothstep(0.55, 0.95, lam))
			c = c.lerp(SPEC, spec * 0.75)
			var cavity := clampf((low[y * SIZE + x] - f[y * SIZE + x]) * 4.0, 0.0, 1.0)  # 오목한 곳 때
			c = c.lerp(GRIME, cavity * 0.75)
			var blot := noise.get_noise_2d(x, y) * 0.5 + 0.5  # 얼룩(산화)
			c = c.lerp(Color("#4a3a1c"), smoothstep(0.62, 0.9, blot) * 0.35)
			c = c.darkened(clampf(fine.get_noise_2d(x, y), 0.0, 1.0) * 0.12)  # 잔 긁힘
			if _rng.randf() < 0.004:
				c = c.lightened(0.25)
			var a := clampf(R + 0.5 - d, 0.0, 1.0)
			if d > R - 1.5:  # 바깥 테 잉크
				c = c.lerp(Color("#20160a"), 0.6)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	return img


## 옆 테두리 띠(가로 128 × 세로 16 — 세로 톱니 결, 위쪽이 밝다). CoinFlip이 동전 두께로 눌러 쓴다.
func _edge() -> Image:
	var img := Image.create(128, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 128:
			var t := float(y) / 15.0
			var c := LIGHT.lerp(DARK, smoothstep(0.0, 1.0, t))
			if x % 4 == 0:
				c = c.darkened(0.35)
			c = c.darkened(0.15 * absf(sin(x * 0.11)))
			img.set_pixel(x, y, c)
	return img
