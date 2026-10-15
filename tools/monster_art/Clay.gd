extends "res://tools/monster_art/ClayBase.gd"
## 몬스터 조형 판(피어 앤 헝거 몬스터 그림을 흉내 내는 첫 단계): ClayBase(그룹별 높이·캡슐·타원체·합치기)에
## 판(slab)·파내기(carve·groove·erase)·표면 위 혹과 줄(bump·ridge)·옷 겹(shell)을 더한다. 그리는 쪽은 Render.gd.


## 판(다각형 + 가장자리에서 안쪽으로 둥글게 솟음): 천·날개 막·칼날·망토. z = 판의 깊이, bulge = 가운데가 솟는 높이,
## edge = 둥글어지는 폭(px), tilt = 화면 위치에 따라 깊이가 바뀌는 기울기(Vector2 · (x, y)).
func slab(g: int, poly: PackedVector2Array, z: float, bulge: float, m: int, k: float = 2.0, edge: float = 10.0, tilt: Vector2 = Vector2.ZERO) -> void:
	if poly.size() < 3:
		return
	var r := _bounds(poly)
	var x0 := maxi(0, int(r.position.x) - 1)
	var y0 := maxi(0, int(r.position.y) - 1)
	var x1 := mini(w - 1, int(r.end.x) + 1)
	var y1 := mini(h - 1, int(r.end.y) + 1)
	var bw := x1 - x0 + 1
	var bh := y1 - y0 + 1
	if bw < 2 or bh < 2:
		return
	var d := PackedFloat32Array()
	d.resize(bw * bh)
	for yy in bh:
		var xs := _span_x(poly, y0 + yy + 0.5)
		var j := 0
		while j + 1 < xs.size():
			for xx in range(maxi(0, int(round(xs[j])) - x0), mini(bw, int(round(xs[j + 1])) - x0)):
				d[yy * bw + xx] = 1.0e6
			j += 2
	chamfer(d, bw, bh)
	var hh: PackedFloat32Array = _H[g]
	var mm: PackedInt32Array = _M[g]
	_H[g] = PackedFloat32Array()
	_M[g] = PackedInt32Array()
	var e := maxf(1.0, edge)
	for yy in bh:
		for xx in bw:
			var dv := d[yy * bw + xx]
			if dv <= 0.0:
				continue
			var t := minf(dv / e, 1.0)
			var prof := sqrt(maxf(0.0, 1.0 - (1.0 - t) * (1.0 - t)))
			var x := x0 + xx
			var y := y0 + yy
			_put(hh, mm, y * w + x, z + bulge * prof + tilt.x * x + tilt.y * y, m, k)
	_H[g] = hh
	_M[g] = mm


## 파내기(타원 모양으로 depth만큼 — 눈구멍·입·콧구멍). 이미 빚은 곳에서만.
func carve(g: int, c: Vector2, rx: float, ry: float, depth: float, rot: float = 0.0) -> void:
	var rr := maxf(rx, ry)
	var cr := cos(rot)
	var sr := sin(rot)
	var hh: PackedFloat32Array = _H[g]
	_H[g] = PackedFloat32Array()
	for y in range(maxi(0, int(c.y - rr) - 1), mini(h - 1, int(c.y + rr) + 1) + 1):
		for x in range(maxi(0, int(c.x - rr) - 1), mini(w - 1, int(c.x + rr) + 1) + 1):
			var i := y * w + x
			if hh[i] <= EMPTY * 0.5:
				continue
			var dx := x + 0.5 - c.x
			var dy := y + 0.5 - c.y
			var u := (dx * cr + dy * sr) / rx
			var v := (-dx * sr + dy * cr) / ry
			var q := u * u + v * v
			if q < 1.0:
				hh[i] -= depth * (1.0 - q) * (1.0 - q * 0.5)
	_H[g] = hh


## 골(선을 따라 파낸 홈 — 근육 사이·갈비뼈 사이·주름·갑옷 이음매). width = 반폭.
func groove(g: int, a: Vector2, b: Vector2, width: float, depth: float) -> void:
	var abx := b.x - a.x
	var aby := b.y - a.y
	var l2 := abx * abx + aby * aby
	var hh: PackedFloat32Array = _H[g]
	_H[g] = PackedFloat32Array()
	for y in range(maxi(0, int(minf(a.y, b.y) - width) - 1), mini(h - 1, int(maxf(a.y, b.y) + width) + 1) + 1):
		for x in range(maxi(0, int(minf(a.x, b.x) - width) - 1), mini(w - 1, int(maxf(a.x, b.x) + width) + 1) + 1):
			var i := y * w + x
			if hh[i] <= EMPTY * 0.5:
				continue
			var t := 0.0
			if l2 > 0.0:
				t = clampf(((x + 0.5 - a.x) * abx + (y + 0.5 - a.y) * aby) / l2, 0.0, 1.0)
			var dx := x + 0.5 - (a.x + abx * t)
			var dy := y + 0.5 - (a.y + aby * t)
			var q := (dx * dx + dy * dy) / (width * width)
			if q < 1.0:
				var taper := minf(1.0, minf(t, 1.0 - t) * 6.0 + 0.15)  # 끝은 얕게
				hh[i] -= depth * (1.0 - q) * (1.0 - q) * taper
	_H[g] = hh


## 굽은 골(점 여러 개).
func grooves(g: int, pts: Array, width: float, depth: float) -> void:
	for i in pts.size() - 1:
		groove(g, pts[i], pts[i + 1], width, depth)


## 표면 위에 얹은 혹(근육·뼈 마디·종기): 가운데가 표면에서 rise만큼 솟는다.
func bump(g: int, c: Vector2, rx: float, ry: float, rise: float, m: int, k: float = 3.0, rot: float = 0.0) -> void:
	var z := surf(g, c.x, c.y)
	if z <= EMPTY * 0.5:
		return
	var rz := maxf(rx, ry) * 0.7
	var was := detail
	detail = true
	ell(g, Vector3(c.x, c.y, z - rz + rise), rx, ry, rz, m, k, rot)
	detail = was


## 표면을 따라 솟은 줄(갈비뼈·쇄골·힘줄·핏줄): 점마다 표면 높이를 읽어 그 위로 rise만큼.
func ridge(g: int, pts: Array, r: float, rise: float, m: int, k: float = 2.0) -> void:
	var p3: Array = []
	var rs: Array = []
	for v: Vector2 in pts:
		var z := surf(g, v.x, v.y)
		if z <= EMPTY * 0.5:
			z = 0.0
		p3.append(Vector3(v.x, v.y, z - r + rise))
		rs.append(r)
	var was := detail
	detail = true
	chain(g, p3, rs, m, k)
	detail = was


## 기록해 둔 부위(tags)를 grow만큼 부풀려 다른 그룹·재질로 한 겹 더 빚는다(옷·갑옷·붕대·장화). clip 다각형 안에서만.
## lift = 앞으로 더 띄움(옷이 살갗에서 떠 있게).
func shell(tags: Array, grow: float, m: int, g: int, clip: PackedVector2Array, k: float = -1.0, lift: float = 0.0, with_detail: bool = false) -> void:
	set_clip(clip)
	var was := tag
	tag = "shell"
	for e: Dictionary in log.duplicate():
		if not tags.has(e["tag"]) or (bool(e["detail"]) and not with_detail):
			continue
		var kk := float(e["k"]) if k < 0.0 else k
		if e["t"] == "cap":
			var a: Vector3 = e["a"]
			var b: Vector3 = e["b"]
			cap(g, a + Vector3(0, 0, lift), b + Vector3(0, 0, lift), float(e["ra"]) + grow, float(e["rb"]) + grow, m, kk, float(e["flat"]))
		else:
			var c: Vector3 = e["c"]
			ell(g, c + Vector3(0, 0, lift), float(e["rx"]) + grow, float(e["ry"]) + grow, float(e["rz"]) + grow, m, kk, float(e["rot"]))
	tag = was
	set_clip(PackedVector2Array())


## 다각형 안 표면의 가장 앞 높이(옷 판을 몸 앞에 띄울 때).
func top_over(g: int, poly: PackedVector2Array) -> float:
	var r := _bounds(poly)
	var best := EMPTY
	var hh: PackedFloat32Array = _H[g]
	var y := r.position.y
	while y <= r.end.y:
		var xs := _span_x(poly, y)
		var j := 0
		while j + 1 < xs.size():
			var x := xs[j]
			while x <= xs[j + 1]:
				var xi := clampi(int(x), 0, w - 1)
				var yi := clampi(int(y), 0, h - 1)
				best = maxf(best, hh[yi * w + xi])
				x += 2.0
			j += 2
		y += 2.0
	return best


## 지우기(찢어진 구멍): 타원 안을 비운다 — 아래 그룹(살갗)이 드러난다. ragged = 가장자리 들쭉날쭉(잡음 시드).
func erase(g: int, c: Vector2, rx: float, ry: float, ragged: float = 0.3) -> void:
	var hh: PackedFloat32Array = _H[g]
	var mm: PackedInt32Array = _M[g]
	_H[g] = PackedFloat32Array()
	_M[g] = PackedInt32Array()
	var ph := c.x * 0.37 + c.y * 0.11
	for y in range(maxi(0, int(c.y - ry) - 1), mini(h - 1, int(c.y + ry) + 1) + 1):
		for x in range(maxi(0, int(c.x - rx) - 1), mini(w - 1, int(c.x + rx) + 1) + 1):
			var dx := (x + 0.5 - c.x) / rx
			var dy := (y + 0.5 - c.y) / ry
			var a := atan2(dy, dx)
			var lim := 1.0 - ragged * (0.5 + 0.5 * sin(a * 5.0 + ph)) * (0.6 + 0.4 * sin(a * 11.0 + ph * 2.0))
			if dx * dx + dy * dy < lim * lim:
				hh[y * w + x] = EMPTY
				mm[y * w + x] = -1
	_H[g] = hh
	_M[g] = mm
