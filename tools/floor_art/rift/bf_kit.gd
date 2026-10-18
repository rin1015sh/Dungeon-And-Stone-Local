extends RefCounted
## 핏빛성채 그림 공용 부품(bf.gd 전용): 색 · 판석 줄눈 · 감아 도는 선(칸 이음) · 피 금 · 해골 · 빛 무리.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")

const INK := Color("#140c0c")
const BLOOD_DARK := Color("#2a0406")
const BLOOD := Color("#6a0a0e")
const BLOOD_LIT := Color("#c41e1a")
const BLOOD_HOT := Color("#ff6a3a")
const IRON := Color("#46444a")
const RUST := Color("#6a3c24")
const BONE := Color("#b4a890")
const WOOD := Color("#4a3426")
const WOOD_DARK := Color("#2a1c16")
const STONE := Color("#5a4c4e")
const GOLD := Color("#8a6a34")
const SKIN := Color("#8a7c6c")
const CLOTH := Color("#4a4034")
const LIT := Color("#f0dcc0")


## 판석 줄눈: 칸(size px)을 rows(줄이 시작하는 y, 0부터 오름차순)로 나누고, 줄마다 자른 자리 cuts[r].
## 돌아옴 = (가장 가까운 줄눈 거리, 돌 번호, 모서리 빛 -1~1 — 돌의 왼쪽·위 모서리는 밝고 오른쪽·아래는 어둡다, bev px 안쪽까지).
static func slab(x: float, y: float, size: float, rows: Array, cuts: Array, bev: float = 4.0) -> Vector3:
	var fy0 := posmod(y, size)
	var r := 0
	for k in rows.size():
		if fy0 >= float(rows[k]):
			r = k
	var top := float(rows[r])
	var bot := float(rows[r + 1]) if r + 1 < rows.size() else size
	var fy := fy0 - top
	var rh := bot - top
	var row_cuts: Array = cuts[r]
	var fx := posmod(x, size)
	var dl := 1e9
	var dr := 1e9
	var seg := 0
	for k in row_cuts.size():
		var c := float(row_cuts[k])
		var a := posmod(fx - c, size)
		if a < dl:
			dl = a
			seg = k
		dr = minf(dr, posmod(c - fx, size))
	var d := minf(minf(fy, rh - fy), minf(dl, dr))
	var lit := clampf(1.0 - fy / bev, 0.0, 1.0) - clampf(1.0 - (rh - fy) / bev, 0.0, 1.0)
	lit += (clampf(1.0 - dl / bev, 0.0, 1.0) - clampf(1.0 - dr / bev, 0.0, 1.0)) * 0.7
	return Vector3(d, r * 16 + seg, clampf(lit, -1.0, 1.0))


## 칸 경계를 넘어 감아 도는 선(바탕에 그린 선이 이웃 칸으로 이어지게 — 9번 겹쳐 긋는다).
static func wline(p: Paint, a: Vector2, b: Vector2, wd: float, c: Color, alpha: float, wob: float = 0.5) -> void:
	for oy: int in [-1, 0, 1]:
		for ox: int in [-1, 0, 1]:
			var o := Vector2(ox * p.w, oy * p.h)
			var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) + o
			var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + o
			if hi.x < -wd or hi.y < -wd or lo.x > p.w + wd or lo.y > p.h + wd:
				continue
			Ink.line(p, a + o, b + o, wd, c, alpha, wob)


## 빛나는 피가 고인 금: 꺾인 선을 굵은 검붉은 테 → 붉은 피 → 뜨거운 심 순으로 칠하고 둘레를 붉게 물들인다.
static func blood_crack(p: Paint, start: Vector2, dir: Vector2, segs: int, seg_len: float, wd: float, heat: float = 1.0) -> void:
	var pts := PackedVector2Array([start])
	var d := dir.normalized()
	for k in segs:
		d = d.rotated(p.rng.randf_range(-0.6, 0.6)).normalized()
		pts.append(pts[pts.size() - 1] + d * seg_len * p.rng.randf_range(0.6, 1.25))
	for k in pts.size() - 1:
		var m := (pts[k] + pts[k + 1]) * 0.5
		Ink.glow(p, m.x, m.y, wd * 4.0, Color("#a01810"), 0.22 * heat)
	for k in pts.size() - 1:
		var t := 1.0 - float(k) / pts.size() * 0.6
		Ink.line(p, pts[k], pts[k + 1], wd * 1.9 * t, INK, 0.85, 0.5)
		Ink.line(p, pts[k], pts[k + 1], wd * 1.2 * t, BLOOD_LIT.lerp(BLOOD, 1.0 - heat), 0.95, 0.5)
		Ink.line(p, pts[k], pts[k + 1], wd * 0.45 * t, BLOOD_HOT, 0.8 * heat, 0.5)
		if p.rng.randf() < 0.4:  # 잔금
			var e := pts[k].lerp(pts[k + 1], 0.5)
			var f := e + d.rotated(p.rng.randf_range(0.8, 1.4) * (1.0 if p.rng.randf() < 0.5 else -1.0)) * seg_len * 0.6
			Ink.line(p, e, f, wd * 0.9 * t, INK, 0.75, 0.4)
			Ink.line(p, e, f, wd * 0.45 * t, BLOOD_LIT, 0.7 * heat, 0.4)


## 피 웅덩이(바닥에 고인 것): 들쭉날쭉한 검붉은 물 + 왼쪽 위 안쪽에 비친 붉은 띠 + 분홍 반짝임. glow = 스스로 빛남.
static func pool(p: Paint, q: Vector2, r: float, wet: float = 1.0, glow: float = 0.0) -> void:
	var phase := p.rng.randf() * TAU
	for y in range(int(q.y - r), int(q.y + r) + 1):
		for x in range(int(q.x - r * 1.35), int(q.x + r * 1.35) + 1):
			var d := Vector2(x - q.x, (y - q.y) / 0.7)
			var a := d.angle()
			var rr := r * (1.0 + 0.22 * (sin(a * 3.0 + phase) * 0.6 + sin(a * 5.0 + phase * 1.7) * 0.4))
			var t := d.length() / rr
			if t >= 1.0:
				continue
			var c := BLOOD_DARK.lerp(BLOOD, (1.0 - t) * 0.5)
			var refl := clampf(1.0 - absf(t - 0.68) / 0.22, 0.0, 1.0) * clampf(-(d.x + d.y) / rr, 0.0, 1.0)
			c = c.lerp(BLOOD_LIT, refl * (0.45 + glow * 0.4))
			c = c.lerp(BLOOD_LIT.lerp(BLOOD_HOT, 0.3), glow * pow(1.0 - t, 1.5) * 0.6)
			if t > 0.86:
				c = c.lerp(INK, (t - 0.86) * 4.0)
			p.blend(x, y, c, clampf((1.0 - t) * 8.0, 0.0, 0.96))
	var s := p.w / 64.0
	if wet > 0.0:
		for k in p.rng.randi_range(1, 2):
			var e := q + Vector2(p.rng.randf_range(-0.5, -0.1) * r, p.rng.randf_range(-0.35, -0.1) * r)
			Ink.line(p, e, e + Vector2(p.rng.randf_range(2.5, 5.0), -0.4) * s, 1.0 * s, Color("#f0b0a0"), 0.45 * wet, 0.2)
	if glow > 0.0:
		Ink.glow(p, q.x, q.y, r * 1.5, Color("#c02018"), 0.18 * glow)


## 마른 피 얼룩(검붉게 스민 자국 + 튄 점).
static func stain(p: Paint, q: Vector2, r: float, a: float = 0.55) -> void:
	Decals._blob(p, q, r, Color("#3a0a0a"), a, 0.35)
	for k in p.rng.randi_range(3, 6):
		var s := q + Vector2.from_angle(p.rng.randf() * TAU) * r * p.rng.randf_range(1.0, 1.7)
		Cave._dot(p, s, p.rng.randf_range(0.6, 1.4) * p.w / 64.0, Color("#3a0a0a"), a)


## 해골(위에서 본 둥근 머리 + 눈구멍 + 이빨줄). s = 배율(64px 칸 기준 1).
static func skull(p: Paint, q: Vector2, s: float, tone: Color = BONE) -> void:
	Cave._stone(p, q, 5.2 * s, 4.4 * s, tone)
	Cave._stone(p, q + Vector2(0.4, 3.6) * s, 3.2 * s, 2.0 * s, tone.darkened(0.08))
	for sx: float in [-1.0, 1.0]:
		Cave._dot(p, q + Vector2(sx * 1.9, 0.6) * s, 1.45 * s, INK, 0.95)
	Cave._dot(p, q + Vector2(0, 2.4) * s, 0.7 * s, INK, 0.8)
	Ink.line(p, q + Vector2(-2.0, 4.2) * s, q + Vector2(2.4, 4.2) * s, 0.6 * s, INK, 0.6, 0.2)


## 긴 뼈(양 끝 마디).
static func bone(p: Paint, a: Vector2, b: Vector2, s: float, tone: Color = BONE) -> void:
	Decals._stick(p, a, b, 1.9 * s, tone)
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	for e: Vector2 in [a, b]:
		Cave._stone(p, e + n * 0.9 * s, 1.5 * s, 1.3 * s, tone)
		Cave._stone(p, e - n * 0.9 * s, 1.5 * s, 1.3 * s, tone)


## 갈비뼈 묶음(위에서 본 등뼈 + 휜 갈비).
static func ribs(p: Paint, q: Vector2, ang: float, s: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := Vector2(-d.y, d.x)
	Decals._stick(p, q - d * 8.0 * s, q + d * 8.0 * s, 1.6 * s, BONE.darkened(0.05))
	for k in 4:
		var o := q + d * (-5.0 + k * 3.4) * s
		for sg: float in [-1.0, 1.0]:
			var m := o + n * sg * 4.0 * s + d * 1.5 * s
			var e := o + n * sg * 6.5 * s + d * 4.0 * s
			Ink.line(p, o, m, 1.4 * s, INK, 0.7, 0.2)
			Ink.line(p, m, e, 1.2 * s, INK, 0.7, 0.2)
			Ink.line(p, o, m, 0.9 * s, BONE, 0.95, 0.2)
			Ink.line(p, m, e, 0.8 * s, BONE, 0.95, 0.2)


## 소품 빛 무리: 투명한 곳까지 반투명 색을 깐다(Ink.glow는 칠한 곳만 밝힌다 — 공중의 빛 번짐은 이것으로).
static func halo(p: Paint, c: Vector2, r: float, col: Color, a: float, squash: float = 1.0) -> void:
	for yy in range(int(c.y - r * squash), int(c.y + r * squash) + 1):
		for xx in range(int(c.x - r), int(c.x + r) + 1):
			if xx < 0 or yy < 0 or xx >= p.w or yy >= p.h:
				continue
			var d := Vector2(xx - c.x, (yy - c.y) / squash).length() / r
			if d >= 1.0:
				continue
			var f := (1.0 - d) * (1.0 - d) * a
			if p.alpha_at(xx, yy) > 0.0:
				p.add_light(xx, yy, col, f)
			else:
				p.blend(xx, yy, col, f * 0.6)


## 칸 하나 크기의 잡음 값(주기) 읽기.
static func at(f: PackedFloat32Array, w: int, h: int, x: int, y: int) -> float:
	return f[posmod(y, h) * w + posmod(x, w)]


## 흙탕물 웅덩이(물): 탁한 갈색 물 + 위쪽 가장자리 빛 + 붉은 하늘이 비친 띠.
static func puddle(p: Paint, q: Vector2, r: float, tone: Color = Color("#1e1814")) -> void:
	var poly := Cave._ellipse(q, r, r * 0.65, 24, p.rng)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var dd := Vector2((x - q.x) / r, (y - q.y) / (r * 0.65)).length()
		var c := tone.lerp(Color("#3a2422"), clampf(0.5 - (y - q.y) / r, 0.0, 1.0) * 0.6)
		return Color(c.r, c.g, c.b, clampf((1.1 - dd) * 4.0, 0.0, 0.85)))
	Ink.path(p, poly, 0.9 * p.w / 64.0, true, INK, 0.3, 0.4)
	var s := p.w / 64.0
	Ink.line(p, q + Vector2(-r * 0.5, -r * 0.3), q + Vector2(r * 0.1, -r * 0.42), 1.0 * s, Color("#c8a898"), 0.3, 0.3)
