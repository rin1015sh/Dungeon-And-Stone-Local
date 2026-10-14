extends RefCounted
## 픽셀 그림 도구(도시 그림 생성기 tools/paint_city.gd 전용): Image 위에 판자·돌·기와·창·문·담쟁이를 칠한다.
## 시드 고정 — 같은 시드면 같은 그림. 게임 코드는 이 파일을 쓰지 않는다(생성된 PNG만 쓴다).

var img: Image
var rng: RandomNumberGenerator
var w: int
var h: int


func _init(p_w: int, p_h: int, seed_value: int) -> void:
	w = p_w
	h = p_h
	img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value


func save(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	img.save_png(path)


func px(x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	if c.a >= 0.999:
		img.set_pixel(x, y, c)
	elif c.a > 0.0:
		var under := img.get_pixel(x, y)
		img.set_pixel(x, y, Color(lerpf(under.r, c.r, c.a), lerpf(under.g, c.g, c.a), lerpf(under.b, c.b, c.a), maxf(under.a, c.a)))


func get_c(x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= w or y >= h:
		return Color(0, 0, 0, 0)
	return img.get_pixel(x, y)


func opaque(x: int, y: int) -> bool:
	return get_c(x, y).a > 0.5


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			px(xx, yy, c)


## 밝기를 조금 흔든다(amt 0~1).
func jit(c: Color, amt: float) -> Color:
	var d := rng.randf_range(-amt, amt)
	return c.lightened(d) if d > 0.0 else c.darkened(-d)


func noisy_rect(x: int, y: int, rw: int, rh: int, c: Color, amt: float = 0.05) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			px(xx, yy, jit(c, amt))


func gradient_v(x: int, y: int, rw: int, rh: int, top: Color, bottom: Color, amt: float = 0.0) -> void:
	for yy in rh:
		var c := top.lerp(bottom, float(yy) / maxf(1.0, rh - 1.0))
		for xx in rw:
			px(x + xx, y + yy, jit(c, amt) if amt > 0.0 else c)


## 이미 칠한 픽셀을 어둡게/밝게(factor < 0 어둡게).
func shade(x: int, y: int, rw: int, rh: int, factor: float) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			var c := get_c(xx, yy)
			if c.a > 0.0:
				px(xx, yy, c.darkened(-factor) if factor < 0.0 else c.lightened(factor))


## 위→아래로 점점 어두워지는 그늘(처마 밑).
func shade_grad(x: int, y: int, rw: int, rh: int, top_factor: float, bottom_factor: float) -> void:
	for yy in rh:
		var f := lerpf(top_factor, bottom_factor, float(yy) / maxf(1.0, rh - 1.0))
		shade(x, y + yy, rw, 1, f)


## 세로 판자 벽. bw = 판자 폭.
func planks_v(x: int, y: int, rw: int, rh: int, base: Color, bw: int = 4) -> void:
	var cx := x
	while cx < x + rw:
		var pw := mini(maxi(2, bw + rng.randi_range(-1, 1)), x + rw - cx)
		var tone := jit(base, 0.09)
		for yy in rh:
			for xx in pw:
				var c := tone
				if xx == 0:
					c = tone.darkened(0.5)
				elif xx == 1:
					c = tone.lightened(0.07)
				if rng.randf() < 0.07:
					c = c.darkened(0.14)
				px(cx + xx, y + yy, jit(c, 0.035))
		if pw > 2 and rh > 6 and rng.randf() < 0.5:
			px(cx + rng.randi_range(1, pw - 1), y + rng.randi_range(2, rh - 3), tone.darkened(0.45))
		cx += pw


## 가로 판자(통나무) 벽. bh = 판자 높이.
func planks_h(x: int, y: int, rw: int, rh: int, base: Color, bh: int = 4) -> void:
	var cy := y
	while cy < y + rh:
		var ph := mini(maxi(2, bh + rng.randi_range(-1, 0)), y + rh - cy)
		var tone := jit(base, 0.08)
		for yy in ph:
			for xx in rw:
				var c := tone
				if yy == ph - 1:
					c = tone.darkened(0.5)
				elif yy == 0:
					c = tone.lightened(0.08)
				if rng.randf() < 0.06:
					c = c.darkened(0.15)
				px(x + xx, cy + yy, jit(c, 0.035))
		cy += ph


## 불규칙한 돌 벽: 줄마다 높이가 다른 돌 + 어두운 줄눈, 돌마다 위·왼쪽 밝고 아래·오른쪽 어둡게.
func stones(x: int, y: int, rw: int, rh: int, base: Color, mortar: Color, min_w: int = 5, max_w: int = 9) -> void:
	rect(x, y, rw, rh, mortar)
	var ry := y
	while ry < y + rh:
		var sh := rng.randi_range(3, 5)
		var cx := x - rng.randi_range(0, max_w / 2)
		while cx < x + rw:
			var sw := rng.randi_range(min_w, max_w)
			var tone := jit(base, 0.12)
			for yy in sh - 1:
				for xx in sw - 1:
					var gx := cx + xx
					var gy := ry + yy
					if gx < x or gx >= x + rw or gy >= y + rh:
						continue
					var c := tone
					if yy == 0 or xx == 0:
						c = tone.lightened(0.12)
					elif yy == sh - 2 or xx == sw - 2:
						c = tone.darkened(0.18)
					px(gx, gy, jit(c, 0.05))
			cx += sw
		ry += sh


## 다각형 지붕 기와(나무 너와·점판암). sw×sh 비늘을 줄마다 엇갈려 깐다. moss = 이끼 덩이 수.
func shingles(poly: PackedVector2Array, base: Color, sw: int = 4, sh: int = 3, moss: int = 0, moss_c: Color = Color("#56702f")) -> void:
	var r := _bounds(poly)
	var tones := {}
	for yy in range(int(r.position.y), int(r.end.y) + 1):
		for xx in range(int(r.position.x), int(r.end.x) + 1):
			if not Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), poly):
				continue
			var row := (yy - int(r.position.y)) / sh
			var off := (row % 2) * (sw / 2)
			var col := (xx + off) / sw
			var key := Vector2i(row, col)
			if not tones.has(key):
				tones[key] = jit(base, 0.11)
			var c: Color = tones[key]
			var ly := (yy - int(r.position.y)) % sh
			if ly == sh - 1:
				c = c.darkened(0.45)
			elif (xx + off) % sw == 0:
				c = c.darkened(0.3)
			elif ly == 0:
				c = c.lightened(0.06)
			px(xx, yy, jit(c, 0.03))
	for i in moss:
		var cx := rng.randf_range(r.position.x, r.end.x)
		var cy := rng.randf_range(r.position.y + r.size.y * 0.3, r.end.y)
		blob(int(cx), int(cy), rng.randi_range(2, 5), moss_c, poly)


## 둥근 얼룩(이끼·담쟁이·나뭇잎). clip이 있으면 그 다각형 안에만.
func blob(cx: int, cy: int, radius: int, c: Color, clip: PackedVector2Array = PackedVector2Array(), density: float = 0.75) -> void:
	for yy in range(cy - radius, cy + radius + 1):
		for xx in range(cx - radius, cx + radius + 1):
			var d := Vector2(xx - cx, (yy - cy) * 1.2).length()
			if d > radius or rng.randf() > density * (1.0 - d / (radius + 1.0) * 0.5):
				continue
			if not clip.is_empty() and not Geometry2D.is_point_in_polygon(Vector2(xx + 0.5, yy + 0.5), clip):
				continue
			var t := rng.randf()
			px(xx, yy, c.lightened(0.18) if t < 0.25 else (c.darkened(0.25) if t > 0.75 else c))


## 담쟁이: 벽 위 영역에 잎 덩이 + 늘어진 줄기.
func ivy(x: int, y: int, rw: int, rh: int, count: int, c: Color = Color("#3f6128")) -> void:
	for i in count:
		var cx := x + rng.randi_range(0, rw)
		var cy := y + rng.randi_range(0, rh / 2)
		blob(cx, cy, rng.randi_range(2, 4), c)
		var vy := cy
		var vx := cx
		for k in rng.randi_range(3, rh - (cy - y)):
			vy += 1
			if rng.randf() < 0.3:
				vx += rng.randi_range(-1, 1)
			px(vx, vy, c.darkened(0.15) if rng.randf() < 0.5 else c.lightened(0.1))
			if rng.randf() < 0.25:
				px(vx + rng.randi_range(-1, 1), vy, c.lightened(0.2))


## 창문: 나무 틀 + 유리(lit = 따뜻한 불빛) + 십자 창살 + 창턱.
func window(x: int, y: int, ww: int, wh: int, lit: bool, frame: Color = Color("#2c2119"), arch: bool = false) -> void:
	rect(x - 1, y - 1, ww + 2, wh + 2, frame)
	for yy in wh:
		for xx in ww:
			if arch and yy < ww / 2:
				var d := Vector2(xx - (ww - 1) / 2.0, yy - ww / 2.0).length()
				if d > ww / 2.0:
					continue
			var t := float(yy) / maxf(1.0, wh - 1.0)
			var c := Color("#f0c070").lerp(Color("#b8702c"), t) if lit else Color("#3a4a55").lerp(Color("#1c2228"), t)
			if not lit and xx == 1 and yy > 1:
				c = c.lightened(0.18)
			px(x + xx, y + yy, jit(c, 0.04))
	var mx := x + ww / 2
	var my := y + wh / 2
	for yy in wh:
		px(mx, y + yy, frame)
	for xx in ww:
		px(x + xx, my, frame)
	rect(x - 2, y + wh + 1, ww + 4, 1, frame.lightened(0.15))


## 문: 판자 + 쇠띠 + 손잡이. arch = 위가 둥근 문.
func door(x: int, y: int, dw: int, dh: int, base: Color, arch: bool = false, frame: Color = Color("#231912")) -> void:
	rect(x - 1, y - 1, dw + 2, dh + 1, frame)
	planks_v(x, y, dw, dh, base, 3)
	if arch:
		var r := dw / 2.0
		for yy in int(r):
			for xx in dw:
				var d := Vector2(xx - (dw - 1) / 2.0, yy - r).length()
				if d > r:
					px(x + xx, y + yy, frame)
	for by in [y + dh / 4, y + dh * 3 / 4]:
		rect(x, by, dw, 1, Color("#1b1b1d"))
		for xx in range(x + 1, x + dw, 3):
			px(xx, by, Color("#5d5d60"))
	px(x + dw - 3, y + dh / 2, Color("#c9a24a"))
	px(x + dw - 3, y + dh / 2 + 1, Color("#7a5f2a"))


## 그림 둘레에 어두운 외곽선(스톤샤드풍 테두리).
func outline(c: Color = Color("#17120f")) -> void:
	var marks: Array[Vector2i] = []
	for yy in h:
		for xx in w:
			if opaque(xx, yy):
				continue
			if opaque(xx - 1, yy) or opaque(xx + 1, yy) or opaque(xx, yy - 1) or opaque(xx, yy + 1):
				marks.append(Vector2i(xx, yy))
	for p in marks:
		img.set_pixel(p.x, p.y, c)


## 작은 글자 그림(문자열 줄 배열, 글자 → 색). '.'은 비움.
func sprite(x: int, y: int, rows: PackedStringArray, colors: Dictionary) -> void:
	for yy in rows.size():
		var row := rows[yy]
		for xx in row.length():
			var ch := row[xx]
			if colors.has(ch):
				px(x + xx, y + yy, colors[ch])


func line(a: Vector2i, b: Vector2i, c: Color) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var t := float(i) / maxf(1.0, n)
		px(roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)), c)


func _bounds(poly: PackedVector2Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		r = r.expand(p)
	return r
