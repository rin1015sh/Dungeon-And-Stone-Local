extends RefCounted
## 강철의 묘 뒷배경: 묘 바닥 밑으로 무너져 내린 구덩이를 내려다본다 — 깊이마다 다른 깨진 바닥판, 끊긴 바닥 층,
## 늘어진 사슬, 먼지 낀 차가운 빛줄기, 아득한 아래의 금빛 반짝임. 가로로 이어 붙여도 이음매가 없다(모든 도형을 ±w로 한 번 더 그린다).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const L := preload("res://tools/floor_art/rift/it_lib.gd")

const FOG := Color("#0b0d11")
const SLATE := Color("#3c424c")


static func paint(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var haze := Seam.field(w, h, seed_value, 0.004, 4)
	var grain := Seam.field(w, h, seed_value + 1, 0.03, 3)
	for y in h:
		for x in w:
			var i := y * w + x
			var t := float(y) / h
			var c := Color("#1e232b").lerp(Color("#0d0f13"), smoothstep(0.0, 0.55, t)).lerp(Color("#050607"), smoothstep(0.5, 1.0, t))
			c = c.lightened((haze[i] - 0.5) * 0.12 * (1.0 - t)).darkened((grain[i] - 0.5) * 0.15)
			p.blend(x, y, c, 1.0)
	# 깊은 층 → 가까운 층
	_falling(p, 26, Vector2(560, 710), Vector2(3, 8), 0.12, seed_value)
	_ledge(p, 600.0, 22.0, 0.1, seed_value + 5, 14, Vector2(6, 14))
	_falling(p, 16, Vector2(420, 560), Vector2(5, 12), 0.2, seed_value + 1)
	_ledge(p, 455.0, 36.0, 0.25, seed_value + 6, 14, Vector2(10, 24))
	_shaft(p, 260.0, 160.0, 0.26)
	_shaft(p, 900.0, 90.0, 0.12)
	_chains(p, seed_value)
	_ledge(p, 290.0, 60.0, 0.45, seed_value + 7, 16, Vector2(20, 40))
	_ledge(p, 95.0, 100.0, 0.75, seed_value + 8, 14, Vector2(28, 58))
	_glints(p, seed_value)
	_motes(p, 260.0, seed_value)
	Ink.grade(p, 0.12, 1.06, Color("#0a0c10"), Color("#c8d0d8"), 0.1)
	Ink.finish(p, 0.03, 0.0)
	return p


## 깊이 near(0 먼 곳 ~ 1 가까운 곳)에 맞춘 색: 가까울수록 밝고 대비가 크다.
static func _tone(c: Color, near: float) -> Color:
	return FOG.lerp(c, 0.18 + near * 0.82)


## 끊긴 바닥 층: 위에서 본 판석 윗면 띠 + 마름돌 앞면, 군데군데 끊긴다(주기 사인 합 — 이음매 없음).
## 윗면 위에 깨진 판 n개를 얹는다(떠 있지 않게).
static func _ledge(p: Paint, y0: float, thick: float, near: float, s: int, n: int, size: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var w := p.w
	var sc := 0.5 + near
	var waves: Array[Vector3] = []
	for k in 3:
		waves.append(Vector3(rng.randi_range(2, 6), rng.randf_range(3.0, 8.0) * sc, rng.randf() * TAU))
	for k in 4:
		waves.append(Vector3(rng.randi_range(9, 26), rng.randf_range(0.5, 1.4) * sc, rng.randf() * TAU))
	var gaps: Array[Vector3] = []
	for k in 3:
		gaps.append(Vector3(rng.randi_range(1, 5), rng.randf_range(0.4, 1.0), rng.randf() * TAU))
	var top := _tone(SLATE.lightened(0.12), near)
	var front := _tone(SLATE.darkened(0.3), near)
	var joint := 52.0 * sc
	var course := 13.0 * sc
	var tops := PackedFloat32Array()
	tops.resize(w)
	var ons := PackedFloat32Array()
	ons.resize(w)
	for x in w:
		var fx := float(x) / w
		var ty := y0
		for v in waves:
			ty += sin(TAU * v.x * fx + v.z) * v.y
		var on := 0.0
		for g in gaps:
			on += sin(TAU * g.x * fx + g.z) * g.y
		tops[x] = ty
		ons[x] = on
		if on < -0.35:
			continue
		var edge := clampf((on + 0.35) * 5.0, 0.0, 1.0)
		var dep := (12.0 + 20.0 * near) * edge
		var th := thick * edge * (0.75 + 0.25 * sin(TAU * 11.0 * fx + 1.3) + 0.1 * sin(TAU * 37.0 * fx))
		var y_top := ty - dep
		for y in range(maxi(0, int(y_top)), mini(p.h, int(ty + th))):
			var c: Color
			if y < ty:  # 윗면 판석(빛 받음)
				c = top.lerp(top.lightened(0.18), p.nz("mid", x, y)).darkened(0.15 * (y - y_top) / maxf(1.0, dep))
				if fposmod(x, joint) < 1.3 or absf(y - (y_top + dep * 0.5)) < 0.7:
					c = c.darkened(0.45)
				if y < y_top + 1.5:
					c = c.lightened(0.3 * near)
			else:
				var t := (y - ty) / maxf(1.0, th)
				c = front.lerp(front.lightened(0.1), p.nz("mid", x, y)).darkened(t * 0.55)
				var row := int((y - ty) / course)
				if fposmod(y - ty, course) < 1.0 or fposmod(x + row * joint * 0.5, joint) < 1.2:
					c = c.darkened(0.45)
			if absf(y - ty) < 1.0:
				c = c.lerp(Ink.INK, 0.65 * near + 0.1)
			p.blend(x, y, c, 1.0)
		var by := int(ty + th)
		if by < p.h:
			p.blend(x, by, Ink.INK, 0.5 * near)
	var old := p.rng
	p.rng = rng
	for k in n:
		var x := rng.randi_range(0, w - 1)
		if ons[x] < 0.05:
			continue
		var r := rng.randf_range(size.x, size.y)
		var c := Vector2(x, tops[x] - (12.0 + 20.0 * near) * rng.randf_range(0.2, 0.7))
		var poly := L.shard(p, c, r, r * rng.randf_range(0.3, 0.5), rng.randf_range(-0.5, 0.5))
		var col := _tone(SLATE.lerp(Color("#56585e"), rng.randf()).lightened(0.18), near)
		var tk := r * rng.randf_range(0.2, 0.35)
		for off: float in [-p.w, 0.0, p.w]:
			var bb := Paint.bounds(poly)
			if bb.end.x + off < 0 or bb.position.x + off > p.w:
				continue
			var moved := PackedVector2Array()
			for q in poly:
				moved.append(q + Vector2(off, 0))
			L.slab(p, moved, tk, col, 0.4 * near, maxf(1.0, r / 26.0))
	p.rng = old


## 깊은 어둠 속으로 떨어지는 작은 조각들.
static func _falling(p: Paint, n: int, yr: Vector2, size: Vector2, near: float, s: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s + 77
	var old := p.rng
	p.rng = rng
	for k in n:
		var c := Vector2(rng.randf() * p.w, rng.randf_range(yr.x, yr.y))
		var r := rng.randf_range(size.x, size.y)
		var top := L.shard(p, c, r, r * rng.randf_range(0.4, 0.7), rng.randf() * TAU)
		var col := _tone(SLATE, near * (1.0 - (c.y - yr.x) / maxf(1.0, yr.y - yr.x) * 0.5))
		for off: float in [-p.w, 0.0, p.w]:
			var b := Paint.bounds(top)
			if b.end.x + off < 0 or b.position.x + off > p.w:
				continue
			var moved := PackedVector2Array()
			for q in top:
				moved.append(q + Vector2(off, 0))
			L.slab(p, moved, r * 0.35, col, 0.0, 1.0)
	p.rng = old


## 차가운 빛줄기(왼쪽 위 → 오른쪽 아래로 비스듬히): 더하기 빛, 아래로 갈수록 흐려진다.
static func _shaft(p: Paint, x0: float, wd: float, a: float) -> void:
	var col := Color("#9ab0c8")
	for y in p.h:
		var cx := x0 + y * 0.42
		var fall := 1.0 - smoothstep(0.0, 1.0, float(y) / p.h) * 0.75
		for x in p.w:
			var dx := fposmod(x - cx + p.w * 0.5, float(p.w)) - p.w * 0.5
			var d := absf(dx) / wd
			if d >= 1.0:
				continue
			var f := (1.0 - d * d) * (1.0 - d * d)
			p.add_light(x, y, col, a * f * fall * (0.8 + 0.4 * p.nz("lo", x, y)))


## 빛줄기 속 먼지 티끌.
static func _motes(p: Paint, x0: float, s: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s + 31
	for k in 260:
		var y := rng.randf() * p.h * 0.85
		var x := fposmod(x0 + y * 0.42 + rng.randf_range(-120.0, 120.0), float(p.w))
		var r := rng.randf_range(0.6, 1.6)
		var a := rng.randf_range(0.15, 0.55) * (1.0 - y / p.h)
		for off: float in [-p.w, 0.0, p.w]:
			Ink.glow(p, x + off, y, r * 2.2, Color("#dce6f0"), a, true)


## 늘어진 사슬: 위에서 내려와 아래로 사라진다(고리를 번갈아, 깊이 따라 흐려짐).
static func _chains(p: Paint, s: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s + 13
	for k in 7:
		var x := rng.randf() * p.w
		var ln := rng.randf_range(220.0, 560.0)
		var sway := rng.randf_range(-30.0, 30.0)
		var size := rng.randf_range(3.5, 6.0)
		var near := rng.randf_range(0.35, 0.8)
		var n := int(ln / (size * 2.2))
		for j in n:
			var t := float(j) / n
			var q := Vector2(x + sway * t * t, t * ln - 10.0)
			var fade := near * (1.0 - t * 0.7)
			var long := j % 2 == 0
			var e := PackedVector2Array()
			for m in 12:
				var a := TAU * m / 12.0
				e.append(q + Vector2(sin(a) * size * (0.85 if long else 0.3), cos(a) * size * 1.25))
			for off: float in [-p.w, 0.0, p.w]:
				if q.x + off < -20 or q.x + off > p.w + 20:
					continue
				var moved := PackedVector2Array()
				for v in e:
					moved.append(v + Vector2(off, 0))
				Ink.path(p, moved, size * 0.55, true, _tone(Color("#2a2c30"), fade).darkened(0.3), 0.95, 0.1)
				if long:
					Ink.line(p, moved[9] + Vector2(0.5, 0), moved[11] + Vector2(0.5, 0), size * 0.25, _tone(Color("#8a96a4"), fade), 0.6, 0.1)
		if rng.randf() < 0.5:  # 끝에 갈고리
			var q := Vector2(x + sway, ln)
			Ink.path(p, PackedVector2Array([q, q + Vector2(0, size * 3), q + Vector2(size * 2.2, size * 4.2), q + Vector2(size * 3, size * 2)]), size * 0.6, false, _tone(Color("#2a2c30"), near * 0.4), 0.9, 0.1)


## 아득한 아래 금빛 반짝임(묘의 보물·촛대 조각).
static func _glints(p: Paint, s: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s + 57
	for k in 46:
		var q := Vector2(rng.randf() * p.w, rng.randf_range(440.0, 700.0))
		var r := rng.randf_range(0.8, 2.0)
		var a := rng.randf_range(0.25, 0.7)
		var star := rng.randf() < 0.25
		for off: float in [-p.w, 0.0, p.w]:
			if q.x + off < -12 or q.x + off > p.w + 12:
				continue
			Ink.glow(p, q.x + off, q.y, r * 5.0, Color("#c89a40"), a * 0.35, true)
			Ink.glow(p, q.x + off, q.y, r * 1.4, Color("#ffe0a0"), a, true)
			if star:
				Ink.line(p, q + Vector2(off - r * 3, 0), q + Vector2(off + r * 3, 0), 0.7, Color("#ffe8b0"), a * 0.6, 0.0)
