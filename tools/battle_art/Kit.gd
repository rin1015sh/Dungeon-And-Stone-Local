extends RefCounted
## 전투 뒷그림 소품·마감 부품(Room 위에 칠한다): 투영한 면(픽셀마다 그 면 위의 세계 점을 되짚어 빛·결) · 상자 · 기둥 · 결정 · 고드름 ·
## 들보 · 불꽃 · 빛 번짐 · 사슬 · 바닥 그림자 · 그늘 빗금 · 붓결 · 색 보정. 소품 면은 벽 뒤로 숨는다(Room.zbuf 깊이 검사).
## tools/paint_battlebacks.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")


static func proj(room: Room, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector3 in pts:
		out.append(room.pt(v.x, v.y, maxf(0.05, v.z)))
	return out


## 평평한 면 하나(꼭짓점 3D, 법선 N — 카메라 쪽): 픽셀마다 면 위 점 P를 되짚어 tex(P) 색을 빛으로 칠한다.
## outline = 잉크 굵기 배율(0이면 없음). 벽(zbuf)보다 뒤인 픽셀은 칠하지 않는다.
static func face(p: Paint, room: Room, pts: Array, N: Vector3, tex: Callable, spec: float = 0.0, outline: float = 1.0) -> void:
	var poly := proj(room, pts)
	var P0: Vector3 = pts[0]
	var O := Vector3(0, room.eye, 0)
	var num := N.dot(P0 - O)
	var sh := func(x: int, y: int) -> Color:
		var D := Vector3((x + 0.5 - room.cx) / room.f, (room.hy - (y + 0.5)) / room.f, 1.0)
		var den := N.dot(D)
		if absf(den) < 1e-6:
			return Color(0, 0, 0, 0)
		var t := num / den
		if t <= 0.0 or t > room.depth_at(x, y) + 0.15:
			return Color(0, 0, 0, 0)
		var P := O + D * t
		var c := room.lit(P, N, tex.call(P), spec)
		c.a = 1.0
		return c
	p.fill_poly(poly, sh)
	if outline > 0.0:
		var zc := 0.0
		for v: Vector3 in pts:
			zc += v.z
		zc /= pts.size()
		Ink.path(p, poly, clampf(room.px(0.035, zc), 0.8, 3.2) * outline, true, Ink.INK, clampf(1.1 - zc * 0.04, 0.25, 0.9), 0.6)


## 상자(c = 바닥 가운데, s = 폭·높이·깊이): 카메라에서 보이는 면(앞 · 안쪽 옆 · 위나 아래)만.
static func box(p: Paint, room: Room, c: Vector3, s: Vector3, tex: Callable, spec: float = 0.0, outline: float = 1.0) -> void:
	var x0 := c.x - s.x / 2.0
	var x1 := c.x + s.x / 2.0
	var y0 := c.y
	var y1 := c.y + s.y
	var z0 := c.z - s.z / 2.0
	var z1 := c.z + s.z / 2.0
	if c.x > s.x / 2.0:  # 오른쪽에 있는 상자 = 왼쪽 옆면이 보인다
		face(p, room, [Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0)], Vector3.LEFT, tex, spec, outline)
	elif c.x < -s.x / 2.0:
		face(p, room, [Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0)], Vector3.RIGHT, tex, spec, outline)
	if y1 < room.eye:
		face(p, room, [Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1)], Vector3.UP, tex, spec, outline)
	elif y0 > room.eye:
		face(p, room, [Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1)], Vector3.DOWN, tex, spec, outline)
	face(p, room, [Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0)], Vector3(0, 0, -1), tex, spec, outline)


## 둥근 기둥(가운데 x·z, 반지름 r, 높이 y0~y1): 화면 열마다 둥근 면의 법선을 되짚어 빛을 받는다. tex(P) 색.
static func pillar(p: Paint, room: Room, x: float, z: float, r: float, y0: float, y1: float, tex: Callable, spec: float = 0.0) -> void:
	var a := room.pt(x - r, y1, z)
	var b := room.pt(x + r, y0, z)
	var poly := Paint.rect_poly(a.x, a.y, b.x - a.x, b.y - a.y)
	var sh := func(sx: int, sy: int) -> Color:
		var u := clampf(((sx + 0.5) - (a.x + b.x) / 2.0) / ((b.x - a.x) / 2.0), -1.0, 1.0)
		var dz := sqrt(maxf(0.0, 1.0 - u * u))
		var P := Vector3(x + u * r, room.eye - ((sy + 0.5) - room.hy) * z / room.f, z - dz * r)
		if P.z > room.depth_at(sx, sy) + 0.15:
			return Color(0, 0, 0, 0)
		var c := room.lit(P, Vector3(u, 0.0, -dz).normalized(), tex.call(P), spec)
		c.a = 1.0
		return c
	p.fill_poly(poly, sh)
	var wpx := clampf(room.px(0.04, z), 0.8, 3.5)
	Ink.line(p, Vector2(a.x, a.y), Vector2(a.x, b.y), wpx, Ink.INK, clampf(1.1 - z * 0.04, 0.25, 0.9))
	Ink.line(p, Vector2(b.x, a.y), Vector2(b.x, b.y), wpx, Ink.INK, clampf(1.1 - z * 0.04, 0.25, 0.9))


## 결정·고드름·석순(밑 가운데 base, 끝 tip, 밑 반지름 r): 육각 기둥처럼 세 면(왼쪽·앞·오른쪽)이 보이고 끝에서 뾰족해진다.
## 면마다 빛을 따로 받고(앞면이 가장 밝게 빛난다), 모서리에 잉크. emit = 스스로 내는 빛(결정).
static func shard(p: Paint, room: Room, base: Vector3, tip: Vector3, r: float, col: Color, emit: Color = Color.BLACK, spec: float = 0.4) -> void:
	var axis := tip - base
	var ln := axis.length()
	if ln < 1e-4:
		return
	axis /= ln
	var fwd := Vector3(0, 0, -1)
	var side := axis.cross(fwd).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	fwd = side.cross(axis).normalized()
	if fwd.z > 0.0:
		fwd = -fwd
	var neck := base + axis * ln * 0.74
	var offs: Array[Vector2] = [Vector2(-1.0, 0.0), Vector2(-0.45, 0.8), Vector2(0.45, 0.8), Vector2(1.0, 0.0)]
	var cb: Array[Vector3] = []
	var cn: Array[Vector3] = []
	for o in offs:
		cb.append(base + side * o.x * r + fwd * o.y * r)
		cn.append(neck + (side * o.x * r + fwd * o.y * r) * 0.9)
	var normals: Array[Vector3] = [(-side + fwd).normalized(), fwd, (side + fwd).normalized()]
	var glow_k: Array[float] = [0.35, 0.8, 0.2]
	var flat := func(_P: Vector3) -> Color: return col
	for k in 3:
		face(p, room, [cb[k], cb[k + 1], cn[k + 1], tip, cn[k]], normals[k], flat, spec, 0.0)
		if emit != Color.BLACK:
			var fp := proj(room, [cb[k], cb[k + 1], cn[k + 1], tip, cn[k]])
			var e := emit * glow_k[k]
			p.fill_poly(fp, func(x: int, y: int) -> Color:
				if room.depth_at(x, y) < base.z - r * 2.0:
					return Color(0, 0, 0, 0)
				return Color(minf(1.0, col.r * 0.3 + e.r), minf(1.0, col.g * 0.3 + e.g), minf(1.0, col.b * 0.3 + e.b), 0.45 * (0.6 + 0.4 * p.nz("mid", x, y))))
	var zc := (base.z + tip.z) / 2.0
	var wpx := clampf(room.px(0.02, zc), 0.6, 2.2)
	var a := clampf(1.0 - zc * 0.035, 0.2, 0.85)
	Ink.path(p, proj(room, [cb[0], cn[0], tip, cn[3], cb[3]]), wpx, false, Ink.INK, a, 0.3)
	for k in [1, 2]:
		var q := proj(room, [cb[k], cn[k], tip])
		Ink.path(p, q, wpx * 0.6, false, Ink.INK, a * 0.55, 0.3)


## 해골(바닥에 놓인 — 밑 가운데 at, 반지름 m): 둥근 머리통 + 눈구멍 둘 + 코.
static func skull(p: Paint, room: Room, at: Vector3, r: float, col: Color) -> void:
	var c := room.pt(at.x, at.y + r, at.z)
	var rp := room.px(r, at.z)
	var head := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		head.append(c + Vector2(cos(a) * rp, sin(a) * rp * (0.9 if sin(a) < 0 else 1.15)))
	var lc := room.lit(at + Vector3(0, r, 0), Vector3(-0.3, 0.6, -0.7).normalized(), col)
	var dc := lc.darkened(0.55)
	p.fill_poly(head, func(x: int, y: int) -> Color:
		var t := clampf(((x - c.x) + (y - c.y)) / (rp * 2.0) + 0.5, 0.0, 1.0)
		return p.vary(lc.lerp(dc, t), x, y, 0.1))
	for e: float in [-1.0, 1.0]:
		var ec := c + Vector2(e * rp * 0.36, rp * 0.18)
		var eye := PackedVector2Array()
		for k in 10:
			var a := TAU * k / 10.0
			eye.append(ec + Vector2(cos(a) * rp * 0.2, sin(a) * rp * 0.17 + absf(sin(a)) * e * rp * 0.03))
		p.fill_poly(eye, p.flat(Color("#0e0a08"), 0.05))
	p.fill_poly(Paint.poly([c + Vector2(-rp * 0.08, rp * 0.5), c + Vector2(rp * 0.08, rp * 0.5), c + Vector2(0, rp * 0.32)]), p.flat(Color("#0e0a08"), 0.05))
	Ink.path(p, head, clampf(rp * 0.12, 0.7, 2.5), true, Ink.INK, 0.8, 0.4)


## 결정 무리(밑 at, 자라는 쪽 up, 크기 m): 큰 결정 하나 + 둘레 작은 결정 몇 개.
static func cluster(p: Paint, room: Room, at: Vector3, up: Vector3, size: float, col: Color, emit: Color, n: int = 5) -> void:
	var u := up.normalized()
	var side := u.cross(Vector3(0, 0, 1)).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var shards: Array = []
	for k in n:
		var t := 0.0 if k == 0 else p.rng.randf_range(-1.0, 1.0)
		var ln := size * (1.0 if k == 0 else p.rng.randf_range(0.35, 0.7))
		var base := at + side * t * size * 0.45 + Vector3(0, 0, p.rng.randf_range(-0.2, 0.2) * size)
		var dir := (u + side * (t * 0.7 + p.rng.randf_range(-0.2, 0.2))).normalized()
		shards.append([base, base + dir * ln, ln * 0.2])
	shards.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector3).z > (b[0] as Vector3).z)
	for sh: Array in shards:
		shard(p, room, sh[0], sh[1], sh[2], col, emit)


## 빛 번짐(3D 점, 반경 m) — 더하기 빛.
static func glow(p: Paint, room: Room, P: Vector3, radius_m: float, c: Color, strength: float) -> void:
	var q := room.pt(P.x, P.y, P.z)
	Ink.glow(p, q.x, q.y, room.px(radius_m, P.z), c, strength)


## 횃불·화로의 불꽃(3D 점 = 불꽃 밑, 키 m).
static func flame(p: Paint, room: Room, P: Vector3, size_m: float) -> void:
	var c := room.pt(P.x, P.y, P.z)
	var s := room.px(size_m, P.z)
	Ink.glow(p, c.x, c.y - s * 0.35, s * 4.5, Color("#ff8a30"), 0.55, false)
	for layer in 4:
		var col: Color = [Color("#7a2a10"), Color("#c8501a"), Color("#f39030"), Color("#ffe8a0")][layer]
		var fh := s * (1.0 - layer * 0.2)
		var fw := s * 0.36 * (1.0 - layer * 0.22)
		var lean := s * 0.08 * sin(float(layer) + c.x)
		var fl := Paint.poly([c + Vector2(-fw, 0), c + Vector2(-fw * 0.8, -fh * 0.35), c + Vector2(-fw * 0.2 + lean, -fh * 0.7), c + Vector2(lean * 2.0, -fh), c + Vector2(fw * 0.35 + lean, -fh * 0.62), c + Vector2(fw * 0.9, -fh * 0.3), c + Vector2(fw, 0), c + Vector2(0, fw * 0.5)])
		p.fill_poly(fl, p.flat(col, 0.12))
	Ink.glow(p, c.x, c.y - s * 0.3, s * 1.4, Color("#ffd080"), 0.5, false)


## 사슬(위 끝 3D 점에서 아래로 길이 m, 흔들림 sway m).
static func chain(p: Paint, room: Room, top: Vector3, length: float, sway: float = 0.0, col: Color = Color("#2a2622")) -> void:
	var n := int(length / 0.09)
	for i in n:
		var t := float(i) / n
		var P := top + Vector3(sin(t * PI) * sway, -length * t, 0)
		var q := room.pt(P.x, P.y, P.z)
		var r := room.px(0.035, P.z)
		var e := PackedVector2Array()
		for k in 10:
			var a := TAU * k / 10.0
			e.append(q + Vector2(cos(a) * r * (0.55 if i % 2 == 0 else 0.2), sin(a) * r))
		Ink.path(p, e, clampf(r * 0.45, 0.6, 2.2), true, col, 0.9, 0.2)


## 바닥에 드리운 둥근 그림자(가운데 x·z, 반지름 m).
static func floor_shadow(p: Paint, room: Room, x: float, z: float, r: float, amount: float = 0.5) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		var q := room.pt(x + cos(a) * r, 0.0, z + sin(a) * r)
		pts.append(q)
	var c := room.pt(x, 0.0, z)
	var rx := maxf(1.0, room.px(r, z))
	p.fill_poly(pts, func(sx: int, sy: int) -> Color:
		var d := Vector2((sx - c.x) / rx, (sy - c.y) / maxf(1.0, rx * 0.3)).length()
		return Color(0.04, 0.03, 0.03, amount * clampf(1.0 - d, 0.0, 1.0)), 1.0, true)


## 그늘 빗금: 어두운 곳(밝기 lo~hi)에 짧은 펜 빗금 묶음(3~5줄)을 흩뿌린다 — 피어 앤 헝거 그림의 거친 펜 그늘. count = 시도 수.
static func hatch_dark(p: Paint, count: int, angle_deg: float, lo: float, hi: float, alpha: float = 0.3) -> void:
	for n in count:
		var q := Vector2(p.rng.randf() * p.w, p.rng.randf() * p.h)
		var lum := p.get_c(int(q.x), int(q.y)).get_luminance()
		if lum <= lo or lum >= hi:
			continue
		var ang := deg_to_rad(-angle_deg + p.rng.randf_range(-10.0, 10.0))
		var dir := Vector2.from_angle(ang)
		var nrm := Vector2(-dir.y, dir.x)
		var ln := p.rng.randf_range(7.0, 15.0)
		var gap := p.rng.randf_range(2.6, 3.6)
		var k := (hi - lum) / (hi - lo)
		for l in p.rng.randi_range(3, 5):
			var c := q + nrm * gap * l + dir * p.rng.randf_range(-2.0, 2.0)
			Ink.line(p, c - dir * ln * 0.5, c + dir * ln * 0.5, 0.9, Ink.INK, alpha * k * p.rng.randf_range(0.5, 1.0), 0.4)


## 붓결: 화면 전체에 짧은 반투명 덧칠(밝은 곳일수록 촘촘히 보인다).
static func brush(p: Paint, density: float = 0.5, length: float = 9.0, width: float = 6.0) -> void:
	Ink.strokes(p, Paint.rect_poly(0, 0, p.w, p.h), density, length, width, 20.0, 0.07, 0.35)


## 때: 화면에 큰 얼룩으로 어둡게 번진 자국(오래된 그림의 더께).
static func grime(p: Paint, amount: float = 0.3, c: Color = Color("#100c0a")) -> void:
	for y in p.h:
		for x in p.w:
			var v := p.nz("lo", x, y) * 0.7 + p.nz("mid", x, y) * 0.3
			p.tint(x, y, c, amount * smoothstep(0.45, 0.85, v))


## 마감: 색 보정(피어 앤 헝거 톤 — 채도 빼고 그늘은 차갑게·밝은 곳은 누렇게) + 그레인 + 비네트.
static func finish(p: Paint, shadow: Color, high: Color, desat: float = 0.3, vignette: float = 0.55) -> void:
	Ink.grade(p, desat, 1.1, shadow, high, 0.16)
	Ink.finish(p, 0.04, vignette)
