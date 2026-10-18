extends RefCounted
## 강철의 묘 그림 부품(it.gd 전용): 리벳·새긴 선(칸 바탕용 — 픽셀 함수라 시드와 무관) · 돋을새김(마스크 → 왼쪽 위 빛) ·
## 깨진 판(윗면 + 남쪽 두께) · 돌림체(항아리·촛대 기둥) · 금속 면 칠.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")

const STEEL := Color("#68707a")
const IRON := Color("#3a3c40")
const GOLD := Color("#a8883a")
const CRIMSON := Color("#7a1a1c")
const RUST := Color("#5e3a26")
const STONE := Color("#6a6c72")
const CANDLE := Color("#d8ccb0")
const LIT := Color("#e8eef4")
const SHADE := Color("#0c0e12")


# ── 칸 바탕용 픽셀 함수(같은 좌표면 같은 색 — 변형끼리 가장자리가 맞는다) ──────────

## 리벳: 오른쪽 아래 그림자 + 왼쪽 위가 밝은 둥근 머리 + 그늘 쪽 잉크.
static func rivet(c: Color, x: int, y: int, q: Vector2, r: float) -> Color:
	var d := Vector2(x + 0.5, y + 0.5) - q
	var dl := d.length()
	if dl > r * 2.2:
		return c
	var ds := (d - Vector2(r * 0.5, r * 0.6)).length()
	if dl >= r and ds < r * 1.3:
		c = c.lerp(SHADE, 0.5 * clampf((r * 1.3 - ds) / (r * 0.6), 0.0, 1.0))
	if dl < r + 0.5:
		var cov := clampf(r + 0.5 - dl, 0.0, 1.0)
		var n := d / r
		var t := clampf(0.5 - n.x * 0.5 - n.y * 0.5, 0.0, 1.0)
		var rc := c.darkened(0.4).lerp(c.lightened(0.5), t)
		if (n + Vector2(0.38, 0.38)).length() < 0.32:
			rc = rc.lerp(LIT, 0.55)
		if dl > r - 1.0:
			rc = rc.lerp(Ink.INK, 0.55 * clampf(n.x + n.y + 0.4, 0.0, 1.0))
		c = c.lerp(rc, cov)
	return c


## 새긴 선(음각): d = 선까지 부호 거리(+ = 오른쪽·아래). 골은 잉크, 오른쪽 아래 벽은 빛을 받는다.
static func groove(c: Color, d: float, wd: float, amt: float = 1.0) -> Color:
	var a := absf(d)
	if a < wd * 0.5 + 0.5:
		return c.lerp(Ink.INK, 0.72 * amt * clampf(wd * 0.5 + 0.5 - a, 0.0, 1.0))
	if d > 0.0 and d < wd * 0.5 + 1.8:
		return c.lerp(LIT, 0.2 * amt)
	if d < 0.0 and a < wd * 0.5 + 1.5:
		return c.darkened(0.12 * amt)
	return c


## 도드라진 판의 모서리: 왼쪽·위 안쪽은 밝게, 오른쪽·아래 안쪽은 어둡게, 맨 가장자리는 이음매 잉크.
static func bevel(c: Color, dl: float, dt: float, dr: float, db: float, wd: float, seam: float = 1.0) -> Color:
	var m := minf(minf(dl, dt), minf(dr, db))
	if m < seam:
		return c.lerp(Ink.INK, 0.8 * clampf(seam - m + 0.3, 0.0, 1.0))
	if minf(dr, db) < wd:
		return c.darkened(0.28 * (1.0 - minf(dr, db) / wd))
	if minf(dl, dt) < wd:
		return c.lightened(0.2 * (1.0 - minf(dl, dt) / wd))
	return c


## 들어간 판(문짝 칸막이): 위·왼쪽 안은 그늘, 아래·오른쪽 안은 빛.
static func recess(c: Color, dl: float, dt: float, dr: float, db: float, wd: float) -> Color:
	var m := minf(minf(dl, dt), minf(dr, db))
	if m < 0.9:
		return c.lerp(Ink.INK, 0.7)
	if minf(dl, dt) < wd:
		return c.darkened(0.35 * (1.0 - minf(dl, dt) / wd))
	if minf(dr, db) < wd:
		return c.lightened(0.18 * (1.0 - minf(dr, db) / wd))
	return c


## 벽 앞면 밑동: 바닥과 만나는 들쭉날쭉한 아래 끝(jag 0~1). 칠하지 않을 곳이면 -1.
static func foot_y(main: float, skirt: int, jag: float) -> float:
	return main + (0.25 + jag * 0.75) * skirt


# ── 잔손질용(붓·잉크) ───────────────────────────────────

## 돋을새김(raised) 또는 음각: draw(m: Paint)가 마스크 캔버스에 흰 도형을 그리면, 그 모양을 왼쪽 위 빛으로 새긴다.
## face = 도형 안 색(금 상감 등), face_amt = 그 세기.
static func relief(p: Paint, draw: Callable, face: Color, face_amt: float, raised: bool = true, strength: float = 1.0) -> void:
	var m := Paint.new(p.w, p.h, 11)
	draw.call(m)
	for y in p.h:
		for x in p.w:
			var a := m.alpha_at(x, y)
			var ul := (m.alpha_at(x - 1, y - 1) + m.alpha_at(x - 2, y - 2)) * 0.5
			var lr := (m.alpha_at(x + 1, y + 1) + m.alpha_at(x + 2, y + 2)) * 0.5
			if a <= 0.0 and ul <= 0.0:
				continue
			if a > 0.0:
				p.tint(x, y, face, a * face_amt)
			if raised:
				p.tint(x, y, LIT, maxf(0.0, a - ul) * 0.45 * strength)
				p.tint(x, y, SHADE, maxf(0.0, ul - a) * 0.6 * strength)
				p.tint(x, y, Ink.INK, maxf(0.0, a - lr) * 0.35 * strength)
			else:
				p.tint(x, y, SHADE, maxf(0.0, a - ul) * 0.7 * strength)
				p.tint(x, y, LIT, maxf(0.0, a - lr) * 0.3 * strength)


## 깨진 판·돌덩이: 윗면 다각형 top + 남쪽을 향한 두께 thick(앞면) + 오른쪽 아래 그림자 + 잉크.
static func slab(p: Paint, top: PackedVector2Array, thick: float, col: Color, shadow: float = 0.45, u: float = 1.0) -> void:
	var sh := PackedVector2Array()
	for q in top:
		sh.append(q + Vector2(thick * 0.9 + 1.5 * u, thick + 1.5 * u))
	p.fill_poly(_hull(sh, top, thick), func(_x: int, _y: int) -> Color: return Color(SHADE.r, SHADE.g, SHADE.b, shadow))
	var n := top.size()
	for i in n:
		var a := top[i]
		var b := top[(i + 1) % n]
		var nrm := _out(top, a, b)
		if nrm.y <= 0.05:
			continue
		var quad := PackedVector2Array([a, b, b + Vector2(0, thick), a + Vector2(0, thick)])
		var dk := 0.35 + clampf(nrm.x, -1.0, 1.0) * 0.18
		p.fill_poly(quad, func(x: int, y: int) -> Color: return p.vary(col.darkened(dk), x, y, 0.08))
		Ink.line(p, a + Vector2(0, thick), b + Vector2(0, thick), 1.0 * u, Ink.INK, 0.7, 0.3)
		Ink.line(p, a, a + Vector2(0, thick), 0.8 * u, Ink.INK, 0.5, 0.2)
	var r := Paint.bounds(top)
	p.fill_poly(top, func(x: int, y: int) -> Color:
		var t := clampf(0.6 - (x - r.position.x) / maxf(1.0, r.size.x) * 0.3 - (y - r.position.y) / maxf(1.0, r.size.y) * 0.25, 0.0, 1.0)
		return p.vary(col.darkened(0.12).lerp(col.lightened(0.18), t), x, y, 0.1))
	Ink.path(p, top, 1.1 * u, true, Ink.INK, 0.75, 0.4)
	for i in n:  # 빛 받은 위·왼쪽 모서리
		var a := top[i]
		var b := top[(i + 1) % n]
		var nrm := _out(top, a, b)
		if nrm.y < -0.3 or nrm.x < -0.5:
			Ink.line(p, a.lerp(b, 0.1) + Vector2(0.8, 0.8) * u, a.lerp(b, 0.9) + Vector2(0.8, 0.8) * u, 0.8 * u, LIT, 0.3, 0.3, true)


## 변 a→b의 바깥 방향 법선.
static func _out(poly: PackedVector2Array, a: Vector2, b: Vector2) -> Vector2:
	var e := (b - a).normalized()
	var nrm := Vector2(e.y, -e.x)
	if Geometry2D.is_point_in_polygon((a + b) * 0.5 + nrm * 0.6, poly):
		nrm = -nrm
	return nrm


## 그림자 다각형(윗면 + 아래로 민 윗면의 둘레 — 대충 볼록 껍질).
static func _hull(a: PackedVector2Array, b: PackedVector2Array, thick: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append_array(a)
	for q in b:
		pts.append(q + Vector2(0, thick))
	return Geometry2D.convex_hull(pts)


## 마구 깨진 판 모양(가운데 c, 반지름 r, 각 a0 — 4~6각).
static func shard(p: Paint, c: Vector2, rx: float, ry: float, a0: float) -> PackedVector2Array:
	var n := p.rng.randi_range(4, 6)
	var out := PackedVector2Array()
	for k in n:
		var a := a0 + TAU * k / n + p.rng.randf_range(-0.35, 0.35)
		var kk := p.rng.randf_range(0.7, 1.15)
		out.append(c + Vector2(cos(a) * rx * kk, sin(a) * ry * kk))
	return out


## 돌림체: prof = [Vector2(높이, 반지름)…](아래 → 위). 왼쪽 빛, metal이면 반사 띠. 윤곽 잉크.
static func lathe(p: Paint, foot: Vector2, prof: Array[Vector2], col: Color, metal: bool = false, ink: float = 1.0) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for v in prof:
		poly.append(foot + Vector2(-v.y, -v.x))
	for k in range(prof.size() - 1, -1, -1):
		poly.append(foot + Vector2(prof[k].y, -prof[k].x))
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var r := radius_at(prof, foot.y - y)
		var nx := clampf((x + 0.5 - foot.x) / maxf(0.6, r), -1.0, 1.0)
		return p.vary(shade_round(col, nx, metal), x, y, 0.06))
	var u := p.w / 128.0
	if ink > 0.0:
		Ink.path(p, poly, 1.3 * u * ink, true, Ink.INK, 0.8, 0.25)
	return poly


static func radius_at(prof: Array[Vector2], hy: float) -> float:
	if hy <= prof[0].x:
		return prof[0].y
	for k in range(1, prof.size()):
		if hy <= prof[k].x:
			var t := (hy - prof[k - 1].x) / maxf(0.001, prof[k].x - prof[k - 1].x)
			return lerpf(prof[k - 1].y, prof[k].y, t)
	return prof[-1].y


## 둥근 면의 밝기(nx = -1 왼쪽 가장자리 ~ 1 오른쪽). 금속은 좁은 반사 띠 + 어두운 띠.
static func shade_round(col: Color, nx: float, metal: bool) -> Color:
	var nz := sqrt(maxf(0.0, 1.0 - nx * nx))
	var lam := clampf(-0.62 * nx + 0.55 * nz + 0.1, 0.0, 1.0)
	var c := col.darkened(0.62).lerp(col.lightened(0.12), lam)
	if metal:
		c = c.lerp(LIT, 0.6 * exp(-pow((nx + 0.45) / 0.12, 2.0)))
		c = c.darkened(0.35 * exp(-pow((nx - 0.25) / 0.18, 2.0)))
		c = c.lerp(col.lightened(0.1), 0.25 * exp(-pow((nx - 0.88) / 0.08, 2.0)))  # 오른쪽 가장자리 되비침
	return c


## 판 다각형을 칠한다: 둥근 정도 round(0 평면 ~ 1 원통)로 가로 그늘, 위쪽 살짝 밝게. 잉크 윤곽.
static func part(p: Paint, poly: PackedVector2Array, col: Color, round: float = 0.6, metal: bool = false, ink: float = 1.0) -> void:
	var r := Paint.bounds(poly)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var nx := clampf(((x + 0.5) - r.get_center().x) / maxf(1.0, r.size.x * 0.5), -1.0, 1.0)
		var ty := ((y + 0.5) - r.position.y) / maxf(1.0, r.size.y)
		var flat := col.lerp(col.darkened(0.3), clampf(nx * 0.5 + 0.5, 0.0, 1.0) * 0.6)
		var c := flat.lerp(shade_round(col, nx, metal), round)
		c = c.lightened(clampf(0.12 - ty * 0.18, -0.1, 0.12))
		return p.vary(c, x, y, 0.07))
	if ink > 0.0:
		Ink.path(p, poly, 1.2 * ink * p.w / 128.0, true, Ink.INK, 0.8, 0.3)


## 반짝임(금속·금화): 짧은 십자 빛.
static func glint(p: Paint, q: Vector2, r: float, a: float = 0.8) -> void:
	Ink.glow(p, q.x, q.y, r * 1.6, Color("#fff0c0"), a * 0.5, false)
	Ink.line(p, q - Vector2(r, 0), q + Vector2(r, 0), maxf(0.7, r * 0.18), Color("#fffbe8"), a, 0.0)
	Ink.line(p, q - Vector2(0, r), q + Vector2(0, r), maxf(0.7, r * 0.18), Color("#fffbe8"), a, 0.0)


## 빛 번짐(투명 바탕에도 보이게): 칠한 곳은 더하기 빛, 빈 곳은 옅은 빛 색을 깐다.
static func halo(p: Paint, q: Vector2, r: float, col: Color, a: float) -> void:
	for y in range(maxi(0, int(q.y - r)), mini(p.h, int(q.y + r) + 1)):
		for x in range(maxi(0, int(q.x - r)), mini(p.w, int(q.x + r) + 1)):
			var d := Vector2(x + 0.5 - q.x, y + 0.5 - q.y).length() / r
			if d >= 1.0:
				continue
			var f := (1.0 - d) * (1.0 - d)
			if p.alpha_at(x, y) > 0.5:
				p.add_light(x, y, col, a * f * 1.2)
			else:
				p.blend(x, y, col, a * f * 0.55)
