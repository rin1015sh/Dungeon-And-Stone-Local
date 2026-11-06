extends RefCounted
## 고블린 숲 큰 구조물(FL21 — f2d_big.gd와 같은 틀: 한 그림 = 바닥 8 × 10칸, 발 = 아래 가운데, 발자리 칸은 막음 타일).
## 빈터의 거대한 나무(살아 있는 숲 — 넓은 잎 지붕 · 굵은 뿌리), 고블린 오두막(진흙 벽 + 짚 지붕), 가죽 천막, 망대(기둥 넷 위 판자).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Big := preload("res://tools/floor_art/rift/f2d_big.gd")

const BARK := Color("#352d26")
const BARK_L := Color("#5c5044")
const LEAF_D := Color("#1e281e")
const LEAF := Color("#34422e")
const LEAF_L := Color("#56664a")
const MUD := Color("#5a4e3e")
const THATCH := Color("#7a6a46")
const HIDE := Color("#6e5a44")
const SILVER := Color("#c4d0d8")
const INK := Color("#100c0a")
const LW := 1.4


static func paint(tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var T := float(w) / 8.0
	var f := Vector2(w * 0.5, h - T * 0.5)
	match tile:
		"bigtree":
			_bigtree(p, f, T)
		"hut":
			_hut(p, f, T)
		"tent":
			_tent(p, f, T)
		"watch":
			_watch(p, f, T)
		"oak", "pine", "birch", "dead", "giant_oak", "giant_pine", "giant_pale":
			_tree(p, f, T, tile, seed_value)
		_:
			pass
	return p


static func _leaves(p: Paint, c: Vector2, rx: float, ry: float, n: int, s: int) -> void:
	var blobs: Array[Vector3] = []
	for k in n:
		var a := Paint.hash01(k, 1, s) * TAU
		var d := sqrt(Paint.hash01(k, 2, s))
		blobs.append(Vector3(c.x + cos(a) * rx * d * 0.85, c.y + sin(a) * ry * d * 0.85, rx * (0.16 + Paint.hash01(k, 3, s) * 0.14)))
	blobs.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)  # 위(먼) 덩어리부터 — 아래 덩어리가 덮는다
	for k in blobs.size():
		var q := Vector2(blobs[k].x, blobs[k].y)
		var rr := blobs[k].z
		var t := clampf(0.55 - (q.y - c.y) / ry * 0.5 - (q.x - c.x) / rx * 0.25, 0.0, 1.0)
		var pts := PackedVector2Array()  # 잎 가장자리가 들쭉날쭉
		for j in 28:
			var an := TAU * j / 28.0
			var r2 := rr * (0.88 + 0.14 * sin(an * 7.0 + k) + 0.06 * Paint.hash01(j, k, s))
			pts.append(q + Vector2(cos(an) * r2, sin(an) * r2 * 0.82))
		var base := LEAF_D.lerp(LEAF_L, t)
		p.fill_poly(pts, func(x: int, y: int) -> Color:
			var dy := (y - q.y) / rr  # 덩어리 아래쪽은 그늘
			var leaf := Paint.hash01(int(x / 3.0), int(y / 3.0), k + s)  # 잎 결(잘게 얼룩)
			return base.darkened(clampf(dy * 0.35 + 0.1, 0.0, 0.45)).lightened((leaf - 0.5) * 0.18))
		Ink.path(p, pts, LW * 0.6, true, INK, 0.3, 0.4)
	for k in 26:
		var an := PI + Paint.hash01(k, 4, s) * PI
		Cave._dot(p, c + Vector2(cos(an) * rx * 0.8, sin(an) * ry * 0.75), 1.6, SILVER, 0.55)


## 빈터의 거대한 나무: 갈라진 굵은 줄기 + 땅을 움켜쥔 뿌리 + 넓은 잎 지붕(그림판 위쪽 대부분).
static func _bigtree(p: Paint, f: Vector2, T: float) -> void:
	Big._shadow(p, f + Vector2(0, -T * 0.2), T * 3.4, T * 1.1)
	for k in 5:  # 뿌리
		var dx := (k - 2) * T * 0.9
		Ink.line(p, f + Vector2(dx * 0.3, -T * 1.2), f + Vector2(dx * 1.3, T * 0.1), T * 0.38, BARK, 1.0, 0.3)
	var trunk := PackedVector2Array([f + Vector2(-T * 1.1, 0), f + Vector2(-T * 0.7, -T * 4.0), f + Vector2(-T * 1.4, -T * 6.0),
		f + Vector2(T * 1.3, -T * 6.0), f + Vector2(T * 0.7, -T * 4.0), f + Vector2(T * 1.2, 0)])
	Big._face(p, trunk, BARK, 0.2)
	for k in 6:  # 껍질 결
		var x := f.x + (k - 2.5) * T * 0.35
		Ink.line(p, Vector2(x, f.y - T * 0.3), Vector2(x + (k - 2.5) * T * 0.1, f.y - T * 5.5), LW, BARK_L, 0.5, 0.7)
	Decals._blob(p, f + Vector2(-T * 0.6, -T * 1.2), T * 0.5, Color("#3e4c38"), 0.7, 0.4)
	_leaves(p, f + Vector2(0, -T * 6.9), T * 3.8, T * 2.1, 46, 7)


## 고블린 오두막: 둥근 진흙 벽(짚 섞임) + 원뿔 짚 지붕 + 낮은 문 구멍 + 지붕 위 해골.
static func _hut(p: Paint, f: Vector2, T: float) -> void:
	Big._shadow(p, f, T * 2.6, T * 0.9)
	var wall := Big._box(p, f, T * 4.2, T * 2.4, T * 2.2, MUD)
	var front: PackedVector2Array = wall["front"]
	p.fill_poly(PackedVector2Array([f + Vector2(-T * 0.45, 0), f + Vector2(-T * 0.45, -T * 1.3), f + Vector2(T * 0.45, -T * 1.3), f + Vector2(T * 0.45, 0)]),
		func(_x: int, _y: int) -> Color: return Color("#0a0806"))
	for k in 9:
		var q := front[3] + Vector2(Paint.hash01(k, 1, 4) * T * 4.2, -Paint.hash01(k, 2, 4) * T * 2.0)
		Ink.line(p, q, q + Vector2(T * 0.25, -T * 0.05), LW, THATCH, 0.6, 0.3)
	var apex := f + Vector2(T * 0.2, -T * 6.2)
	var roof := PackedVector2Array([f + Vector2(-T * 2.8, -T * 2.0), apex, f + Vector2(T * 3.1, -T * 2.3), f + Vector2(T * 0.3, -T * 1.6)])
	Big._face(p, roof, THATCH, 0.1)
	for k in 12:
		var t := float(k) / 12.0
		Ink.line(p, apex, roof[0].lerp(roof[2], t), LW * 0.8, THATCH.darkened(0.35), 0.5, 0.4)
	p.fill_poly(Cave._ellipse(apex + Vector2(0, T * 0.2), T * 0.35, T * 0.3, 14), func(_x: int, _y: int) -> Color: return Color("#cfc6ae"))


## 가죽 천막: 기운 막대 셋에 덮은 기운 가죽(꿰맨 줄) + 앞 자락 젖힘.
static func _tent(p: Paint, f: Vector2, T: float) -> void:
	Big._shadow(p, f, T * 2.4, T * 0.8)
	var apex := f + Vector2(0, -T * 4.6)
	var left := PackedVector2Array([f + Vector2(-T * 2.4, 0), apex, f + Vector2(-T * 0.2, T * 0.1)])
	var right := PackedVector2Array([f + Vector2(-T * 0.2, T * 0.1), apex, f + Vector2(T * 2.3, -T * 0.3)])
	Big._face(p, right, HIDE, -0.7)
	Big._face(p, left, HIDE, 0.4)
	p.fill_poly(PackedVector2Array([f + Vector2(-T * 0.6, T * 0.05), apex + Vector2(0, T * 1.6), f + Vector2(T * 0.4, 0)]), func(_x: int, _y: int) -> Color: return Color("#0c0a08"))
	for k in 3:
		Ink.line(p, apex, apex + Vector2((k - 1) * T * 0.4, -T * 0.8), LW * 1.6, BARK, 1.0, 0.2)
	for k in 4:
		var t := 0.25 + k * 0.18
		Ink.line(p, apex.lerp(left[0], t), apex.lerp(left[0], t) + Vector2(T * 0.6, T * 0.1), LW, HIDE.darkened(0.4), 0.7, 0.3)


## 망대: 기둥 넷 위 판자 바닥 + 난간, 사다리.
static func _watch(p: Paint, f: Vector2, T: float) -> void:
	Big._shadow(p, f, T * 2.2, T * 0.7)
	for x in [-1.6, 1.6]:
		Ink.line(p, f + Vector2(x * T, 0), f + Vector2(x * T * 0.85, -T * 5.0), T * 0.3, BARK, 1.0, 0.2)
		Ink.line(p, f + Vector2(x * T * 0.7, -T * 0.6), f + Vector2(x * T * 0.6, -T * 5.2), T * 0.24, BARK.darkened(0.3), 1.0, 0.2)
	Ink.line(p, f + Vector2(-T * 1.5, -T * 1.5), f + Vector2(T * 1.5, -T * 3.5), T * 0.12, BARK_L, 0.8, 0.2)
	Big._box(p, f + Vector2(0, -T * 5.0), T * 3.8, T * 2.0, T * 0.35, BARK_L)
	for k in 5:
		var x := -T * 1.8 + k * T * 0.9
		Ink.line(p, f + Vector2(x, -T * 5.3), f + Vector2(x, -T * 6.3), T * 0.12, BARK, 1.0, 0.2)
	Ink.line(p, f + Vector2(-T * 1.9, -T * 6.2), f + Vector2(T * 1.9, -T * 6.2), T * 0.14, BARK, 1.0, 0.2)
	for k in 6:  # 사다리
		var y := -T * 0.5 - k * T * 0.75
		Ink.line(p, f + Vector2(-T * 0.35, y), f + Vector2(T * 0.35, y), T * 0.1, BARK_L, 0.9, 0.2)


## ── 나무(사용자 2026-11-06 "나무 여러 가지 — 화면을 뚫고 나갈 정도의 나무들의 숲", FL23) ──
## 그림판 = 바닥 8 × 18칸. 중간 나무(참나무 · 전나무 · 자작 · 죽은 나무) = 높이 8~11칸, 거목 = 줄기가 그림판 꼭대기까지(화면 위로 뚫고 나간다 —
## 잎은 맨 위에만 조금). 발 = 아래 가운데, 밑동은 뿌리로 벌어진다. 빛은 왼쪽 위, 줄기 결 · 이끼 · 옹이.

const PALE := Color("#9a9a90")
const NEEDLE := Color("#26322a")


static func _tree(p: Paint, f: Vector2, T: float, kind: String, s: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var giant := kind.begins_with("giant")
	var bark := PALE if kind in ["birch", "giant_pale"] else (BARK.lightened(0.05) if kind == "dead" else BARK)
	var half := T * (rng.randf_range(0.95, 1.25) if giant else rng.randf_range(0.5, 0.65))
	var top_y := 0.0 if giant else f.y - T * rng.randf_range(7.5, 10.5)
	var lean := rng.randf_range(-0.15, 0.15) * T
	Big._shadow(p, f + Vector2(T * 0.4, 0), half * 3.2, half * 0.9)
	for k in (5 if giant else 3):  # 뿌리 — 밑동이 땅을 움켜쥔다
		var dx := (k - (2.0 if giant else 1.0)) * half * 0.9
		var a := f + Vector2(dx * 0.4, -half * 1.4)
		var b := f + Vector2(dx * 1.6 + rng.randf_range(-0.2, 0.2) * T, rng.randf_range(-0.1, 0.2) * T)
		Ink.line(p, a, b, half * 0.55, bark.darkened(0.15), 1.0, 0.3)
	var pts := PackedVector2Array()  # 줄기(아래가 넓고 위로 좁아진다 — 거목은 거의 그대로 끝까지)
	var n := 12
	for j in n + 1:
		var t := float(j) / n
		var w := half * (1.0 + (1.0 - t) * (1.3 if j == 0 else 0.25)) * (1.0 - t * (0.15 if giant else 0.55))
		pts.append(Vector2(f.x - w + lean * t, lerpf(f.y, top_y, t)))
	for j in range(n, -1, -1):
		var t := float(j) / n
		var w := half * (1.0 + (1.0 - t) * (1.3 if j == 0 else 0.25)) * (1.0 - t * (0.15 if giant else 0.55))
		pts.append(Vector2(f.x + w + lean * t, lerpf(f.y, top_y, t)))
	p.fill_poly(pts, func(x: int, y: int) -> Color:
		var t := clampf((f.y - y) / maxf(1.0, f.y - top_y), 0.0, 1.0)
		var cx := f.x + lean * t
		var u := (x - cx) / maxf(1.0, half)
		var c := bark.lerp(bark.lightened(0.35), clampf(0.5 - u * 0.55, 0.0, 1.0)).darkened(clampf(absf(u) * 0.35, 0.0, 0.5))
		var fis := Paint.hash01(int((x - cx) / 3.0), int(y / 14.0), 9)  # 세로로 갈라진 껍질
		return p.vary(c.darkened(0.12 if fis > 0.8 else 0.0), x, y, 0.08))
	Ink.path(p, pts, LW, true, INK, 0.75, 0.3)
	for k in (14 if giant else 6):  # 껍질 결 · 옹이 · 이끼
		var t := rng.randf_range(0.05, 0.95)
		var y := lerpf(f.y, top_y, t)
		var x := f.x + lean * t + rng.randf_range(-0.6, 0.6) * half
		if kind in ["birch", "giant_pale"]:
			Ink.line(p, Vector2(x - half * 0.3, y), Vector2(x + half * 0.25, y + T * 0.05), LW * 1.6, Color("#2a2a26"), 0.8, 0.4)
		else:
			Ink.line(p, Vector2(x, y), Vector2(x + rng.randf_range(-0.1, 0.1) * T, y - T * rng.randf_range(0.6, 1.6)), LW, bark.darkened(0.45), 0.6, 0.7)
	for k in (4 if giant else 2):
		var t := rng.randf_range(0.0, 0.35)
		Decals._blob(p, Vector2(f.x + lean * t - half * 0.4, lerpf(f.y, top_y, t)), half * 0.6, Color("#3e4c38"), 0.7, 0.4)
	match kind:
		"oak":
			_leaves(p, Vector2(f.x + lean, top_y + T * 1.0), T * rng.randf_range(2.7, 3.1), T * 2.5, 52, s)
		"birch":
			_leaves(p, Vector2(f.x + lean, top_y + T * 1.2), T * 2.1, T * 2.8, 40, s + 3)
		"pine":
			for k in 7:  # 층진 침엽 — 아래가 넓다
				var t := float(k) / 7.0
				var cy := lerpf(f.y - T * 3.0, top_y, t)
				var hw := T * (2.8 - t * 2.1)
				var tri := PackedVector2Array([Vector2(f.x + lean * t - hw, cy + T * 0.6), Vector2(f.x + lean * t, cy - T * 1.4), Vector2(f.x + lean * t + hw, cy + T * 0.6)])
				_needles(p, tri, f.x + lean * t, hw, T, s + k)
		"dead":
			for k in 6:
				var t := rng.randf_range(0.45, 1.0)
				var a := Vector2(f.x + lean * t, lerpf(f.y, top_y, t))
				var e := a + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, -0.3)) * T * rng.randf_range(1.2, 2.4)
				Ink.line(p, a, e, half * 0.4, bark, 1.0, 0.4)
				Ink.line(p, e, e + Vector2(rng.randf_range(-0.8, 0.8), -0.8) * T, half * 0.2, bark, 1.0, 0.4)
		"giant_oak", "giant_pale":
			for k in 3:  # 높은 곳에서 갈라져 나간 굵은 가지(그림판 위로 사라진다)
				var t := rng.randf_range(0.55, 0.85)
				var a := Vector2(f.x + lean * t, lerpf(f.y, top_y, t))
				var e := a + Vector2((-1.0 if k % 2 == 0 else 1.0) * rng.randf_range(1.5, 2.4), -rng.randf_range(1.6, 2.6)) * T
				Ink.line(p, a, e, half * 0.3, bark.darkened(0.3), 1.0, 0.3)
			_leaves(p, Vector2(f.x + lean, T * 1.8), T * 3.0, T * 1.4, 34, s + 5)
		"giant_pine":
			for k in 9:  # 죽은 아랫가지 그루터기
				var t := rng.randf_range(0.2, 0.75)
				var a := Vector2(f.x + lean * t, lerpf(f.y, top_y, t))
				var sd := -1.0 if k % 2 == 0 else 1.0
				Ink.line(p, a, a + Vector2(sd * rng.randf_range(0.6, 1.4), rng.randf_range(-0.2, 0.3)) * T, LW * 2.4, bark.darkened(0.3), 1.0, 0.3)
			for k in 4:
				var cy := T * (0.6 + k * 1.1)
				var hw := T * (1.5 + k * 0.45)
				var tri := PackedVector2Array([Vector2(f.x + lean - hw, cy + T * 0.8), Vector2(f.x + lean, cy - T * 1.0), Vector2(f.x + lean + hw, cy + T * 0.8)])
				_needles(p, tri, f.x + lean, hw, T, s + k + 20)


## 침엽 한 층: 들쭉날쭉한 아래 가장자리 + 처진 바늘잎 결(밝은 왼쪽 · 어두운 아래).
static func _needles(p: Paint, tri: PackedVector2Array, cx: float, hw: float, T: float, s: int) -> void:
	var jag := PackedVector2Array([tri[0]])
	var steps := 9
	for j in range(1, steps):  # 아래 가장자리 톱니
		var x := tri[0].x + (tri[2].x - tri[0].x) * j / steps
		jag.append(Vector2(x, tri[0].y + (T * 0.35 if j % 2 == 0 else -T * 0.05)))
	jag.append(tri[2])
	jag.append(tri[1])
	p.fill_poly(jag, func(x: int, y: int) -> Color:
		var u := (x - cx) / maxf(1.0, hw)
		var v := clampf((y - tri[1].y) / maxf(1.0, tri[0].y - tri[1].y), 0.0, 1.0)
		var nz := Paint.hash01(int(x / 2.0), int(y / 4.0), s)
		return NEEDLE.lerp(LEAF, clampf(0.55 - u * 0.4 - v * 0.25, 0.0, 1.0)).lightened((nz - 0.5) * 0.2))
	for k in 14:  # 바늘잎 결
		var a := tri[1].lerp(tri[0].lerp(tri[2], Paint.hash01(k, 1, s)), Paint.hash01(k, 2, s) * 0.8 + 0.2)
		Ink.line(p, a, a + Vector2((a.x - cx) * 0.15, T * 0.4), LW * 0.8, NEEDLE.darkened(0.35), 0.5, 0.4)
	Ink.path(p, jag, LW * 0.7, true, INK, 0.45, 0.4)
