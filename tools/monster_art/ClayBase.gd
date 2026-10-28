extends RefCounted
## 몬스터 조형 판의 바탕(Clay가 이어받는다): 몸을 3D 덩어리(캡슐·타원체·판)로 빚어 "앞 표면 높이"를 쌓는다.
## 같은 그룹(한 팔·한 다리·몸통…) 안의 덩어리는 부드럽게 녹여 붙여(smooth max) 근육 사이가 골로 이어지고,
## 다른 그룹끼리는 앞에 있는 쪽이 가린다(가린 경계 = 잉크 선). carve·groove는 높이를 파낸다(눈구멍·입·근육 사이 골·주름).
## 그리는 쪽은 Render.gd — 여기서 만든 높이·재질로 명암·빗금·잉크를 입힌다.
## 좌표: x 오른쪽, y 아래(화면 픽셀), z 보는 사람 쪽(클수록 앞).

const EMPTY := -1.0e9

var w: int
var h: int
var mats: Array = []  ## 재질 {"c": Color, "kind": String, …}
var tag := ""  ## 지금 빚는 부위 이름(몸통·팔…) — 기록해 두었다가 옷·갑옷을 같은 모양으로 한 겹 더 씌운다(shell)
var detail := false  ## 잔근육·핏줄 같은 잔손질 중이면 true(옷 겹에는 넣지 않는다)
var log: Array = []  ## 빚은 덩어리 기록 [{t, tag, detail, …}]
var marked: Array[int] = []  ## 따로 뽑을 그룹(손 무기 — 전투 아군 무기 덮개 그림, Party.figure layer)
var _clip := PackedByteArray()  ## 비어 있지 않으면 이 안에서만 빚는다
var _H: Array = []  ## 그룹마다 PackedFloat32Array(앞 표면 높이, 비면 EMPTY)
var _M: Array = []  ## 그룹마다 PackedInt32Array(재질)
## resolve() 뒤 합친 결과
var top_h := PackedFloat32Array()
var top_g := PackedInt32Array()
var top_m := PackedInt32Array()


func _init(p_w: int, p_h: int) -> void:
	w = p_w
	h = p_h


func mat(c: Color, kind: String = "skin", opts: Dictionary = {}) -> int:
	var m := opts.duplicate()
	m["c"] = c
	m["kind"] = kind
	mats.append(m)
	return mats.size() - 1


func group() -> int:
	var hh := PackedFloat32Array()
	hh.resize(w * h)
	hh.fill(EMPTY)
	var mm := PackedInt32Array()
	mm.resize(w * h)
	mm.fill(-1)
	_H.append(hh)
	_M.append(mm)
	return _H.size() - 1


func group_count() -> int:
	return _H.size()


func height_of(g: int) -> PackedFloat32Array:
	return _H[g]


## 두 높이를 부드럽게 합친다(k = 녹는 폭 px, 0이면 그냥 큰 쪽).
static func smax(a: float, b: float, k: float) -> float:
	if k <= 0.0:
		return maxf(a, b)
	var t := clampf(0.5 + 0.5 * (a - b) / k, 0.0, 1.0)
	return lerpf(b, a, t) + k * t * (1.0 - t) * 0.5


## 캡슐(두 끝 a·b, 반지름 ra·rb). flat < 1이면 앞뒤로 납작(판판한 정강이·갑옷판).
func cap(g: int, a: Vector3, b: Vector3, ra: float, rb: float, m: int, k: float = 4.0, flat: float = 1.0) -> void:
	log.append({"t": "cap", "tag": tag, "detail": detail, "a": a, "b": b, "ra": ra, "rb": rb, "k": k, "flat": flat})
	var rmax := maxf(ra, rb)
	var x0 := maxi(0, int(minf(a.x, b.x) - rmax) - 1)
	var x1 := mini(w - 1, int(maxf(a.x, b.x) + rmax) + 1)
	var y0 := maxi(0, int(minf(a.y, b.y) - rmax) - 1)
	var y1 := mini(h - 1, int(maxf(a.y, b.y) + rmax) + 1)
	var abx := b.x - a.x
	var aby := b.y - a.y
	var l2 := abx * abx + aby * aby
	var clipped := not _clip.is_empty()
	var hh: PackedFloat32Array = _H[g]
	var mm: PackedInt32Array = _M[g]
	_H[g] = PackedFloat32Array()  # 참조를 하나로 — 고칠 때 통째 복사되지 않게
	_M[g] = PackedInt32Array()
	for y in range(y0, y1 + 1):
		var py := y + 0.5
		for x in range(x0, x1 + 1):
			var px := x + 0.5
			var t := 0.0
			if l2 > 0.0:
				t = clampf(((px - a.x) * abx + (py - a.y) * aby) / l2, 0.0, 1.0)
			var dx := px - (a.x + abx * t)
			var dy := py - (a.y + aby * t)
			var r := ra + (rb - ra) * t
			var d2 := dx * dx + dy * dy
			if d2 >= r * r:
				continue
			var i := y * w + x
			if clipped and _clip[i] == 0:
				continue
			_put(hh, mm, i, a.z + (b.z - a.z) * t + sqrt(r * r - d2) * flat, m, k)
	_H[g] = hh
	_M[g] = mm


## 점 여러 개를 잇는 캡슐 줄(손가락·꼬리·척추). radii는 점마다.
func chain(g: int, pts: Array, radii: Array, m: int, k: float = 4.0, flat: float = 1.0) -> void:
	for i in pts.size() - 1:
		cap(g, pts[i], pts[i + 1], radii[i], radii[i + 1], m, k, flat)


## 타원체(화면에서 rot 라디안 돌린 rx·ry, 앞으로 rz만큼 솟음).
func ell(g: int, c: Vector3, rx: float, ry: float, rz: float, m: int, k: float = 4.0, rot: float = 0.0) -> void:
	log.append({"t": "ell", "tag": tag, "detail": detail, "c": c, "rx": rx, "ry": ry, "rz": rz, "k": k, "rot": rot})
	var clipped := not _clip.is_empty()
	var rr := maxf(rx, ry)
	var x0 := maxi(0, int(c.x - rr) - 1)
	var x1 := mini(w - 1, int(c.x + rr) + 1)
	var y0 := maxi(0, int(c.y - rr) - 1)
	var y1 := mini(h - 1, int(c.y + rr) + 1)
	var cr := cos(rot)
	var sr := sin(rot)
	var hh: PackedFloat32Array = _H[g]
	var mm: PackedInt32Array = _M[g]
	_H[g] = PackedFloat32Array()
	_M[g] = PackedInt32Array()
	for y in range(y0, y1 + 1):
		var dy := y + 0.5 - c.y
		for x in range(x0, x1 + 1):
			var dx := x + 0.5 - c.x
			var u := (dx * cr + dy * sr) / rx
			var v := (-dx * sr + dy * cr) / ry
			var q := u * u + v * v
			if q >= 1.0:
				continue
			var i := y * w + x
			if clipped and _clip[i] == 0:
				continue
			_put(hh, mm, i, c.z + rz * sqrt(1.0 - q), m, k)
	_H[g] = hh
	_M[g] = mm


func _put(hh: PackedFloat32Array, mm: PackedInt32Array, i: int, v: float, m: int, k: float) -> void:
	var old := hh[i]
	if old <= EMPTY * 0.5:
		hh[i] = v
		mm[i] = m
		return
	hh[i] = smax(old, v, k)
	if v > old:
		mm[i] = m


## 그 자리의 표면 높이(비었으면 EMPTY).
func surf(g: int, x: float, y: float) -> float:
	var xi := clampi(int(x), 0, w - 1)
	var yi := clampi(int(y), 0, h - 1)
	var hh: PackedFloat32Array = _H[g]
	return hh[yi * w + xi]


## 빚기 범위를 다각형 안으로 제한(빈 배열이면 해제).
func set_clip(poly: PackedVector2Array) -> void:
	_clip = PackedByteArray()
	if poly.size() < 3:
		return
	_clip.resize(w * h)
	var r := _bounds(poly)
	for y in range(maxi(0, int(r.position.y)), mini(h, int(r.end.y) + 1)):
		var xs := _span_x(poly, y + 0.5)
		var j := 0
		while j + 1 < xs.size():
			for x in range(maxi(0, int(round(xs[j]))), mini(w, int(round(xs[j + 1])))):
				_clip[y * w + x] = 1
			j += 2


## 그룹을 합친다: 칸마다 가장 앞(높은) 그룹이 보인다.
func resolve() -> void:
	var n := w * h
	top_h.resize(n)
	top_h.fill(EMPTY)
	top_g.resize(n)
	top_g.fill(-1)
	top_m.resize(n)
	top_m.fill(-1)
	for g in _H.size():
		var hh: PackedFloat32Array = _H[g]
		var mm: PackedInt32Array = _M[g]
		for i in n:
			if hh[i] > top_h[i]:
				top_h[i] = hh[i]
				top_g[i] = g
				top_m[i] = mm[i]


func covered(i: int) -> bool:
	return top_g[i] >= 0


# ── 도움 ───────────────────────────────────────────────


static func _bounds(poly: PackedVector2Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for v in poly:
		r = r.expand(v)
	return r


static func _span_x(poly: PackedVector2Array, sy: float) -> PackedFloat32Array:
	var xs: Array[float] = []
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
			xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
	xs.sort()
	return PackedFloat32Array(xs)


## 2단 모서리 거리: 안쪽(>0) 칸 = 가장 가까운 바깥까지 거리.
static func chamfer(d: PackedFloat32Array, w2: int, h2: int) -> void:
	var s2 := 1.4142
	for y in h2:
		for x in w2:
			var i := y * w2 + x
			if d[i] <= 0.0:
				continue
			var m := d[i]
			m = minf(m, (d[i - 1] if x > 0 else 0.0) + 1.0)
			if y > 0:
				m = minf(m, d[i - w2] + 1.0)
				m = minf(m, (d[i - w2 - 1] if x > 0 else 0.0) + s2)
				m = minf(m, (d[i - w2 + 1] if x + 1 < w2 else 0.0) + s2)
			else:
				m = minf(m, 1.0)
			if x == 0 or x == w2 - 1 or y == h2 - 1:
				m = minf(m, 1.0)
			d[i] = m
	for y in range(h2 - 1, -1, -1):
		for x in range(w2 - 1, -1, -1):
			var i := y * w2 + x
			if d[i] <= 0.0:
				continue
			var m := d[i]
			m = minf(m, (d[i + 1] if x + 1 < w2 else 0.0) + 1.0)
			if y + 1 < h2:
				m = minf(m, d[i + w2] + 1.0)
				m = minf(m, (d[i + w2 + 1] if x + 1 < w2 else 0.0) + s2)
				m = minf(m, (d[i + w2 - 1] if x > 0 else 0.0) + s2)
			d[i] = m
