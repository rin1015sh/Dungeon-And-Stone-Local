extends RefCounted
## 탐험 맵 몸 그림용 2D 픽셀 화판(피어 앤 헝거 맵 그림풍): 타원·캡슐·사각형을 뒤에서 앞 순서로 찍으면
## 칸마다 둥근 면의 빛(왼쪽 위)을 4단(그늘·중간·바탕·밝음)으로 나눠 칠하고, 앞 조각과 맞닿은 뒤 조각 가장자리에 어두운 선,
## 몸 둘레에 1px 잉크 바깥선을 두른다. 결 tex: hair(머리카락 결) · fur(털) · wrap(감은 천 띠).
## opt: dim(그늘 쪽 팔다리 — 한 단 어둡게) · flat(빛 없이 바탕색) · noline(경계선 없음 — 눈·작은 점) · lift(한 단 밝게).

const L := Vector3(-0.5, -0.62, 0.6)
const INK := Color(0.07, 0.045, 0.04)

var w: int
var h: int
var _base := PackedColorArray()
var _lvl := PackedInt32Array()
var _part := PackedInt32Array()
var _noline: Array[bool] = []


func _init(width: int, height: int) -> void:
	w = width
	h = height
	_base.resize(w * h)
	_lvl.resize(w * h)
	_part.resize(w * h)
	_part.fill(-1)


func ell(c: Vector2, r: Vector2, col: Color, opt: Dictionary = {}) -> void:
	var box := Rect2(c - r, r * 2.0)
	_fill(box, col, opt, func(p: Vector2) -> Variant:
		var q := Vector2((p.x - c.x) / r.x, (p.y - c.y) / r.y)
		var d2 := q.length_squared()
		return null if d2 > 1.0 else Vector3(q.x, q.y, sqrt(1.0 - d2)))


## a → b 캡슐(반지름 ra → rb).
func cap(a: Vector2, b: Vector2, ra: float, rb: float, col: Color, opt: Dictionary = {}) -> void:
	var m := maxf(ra, rb)
	var box := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(m, m), (a - b).abs() + Vector2(m, m) * 2.0)
	var ab := b - a
	var len2 := maxf(0.0001, ab.length_squared())
	_fill(box, col, opt, func(p: Vector2) -> Variant:
		var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
		var d := p - (a + ab * t)
		var rad := lerpf(ra, rb, t)
		if d.length() > rad:
			return null
		var q := d / rad
		return Vector3(q.x, q.y, sqrt(maxf(0.0, 1.0 - q.length_squared()))))


func rect(p0: Vector2, p1: Vector2, col: Color, opt: Dictionary = {}) -> void:
	var c := (p0 + p1) * 0.5
	var hs := (p1 - p0).abs() * 0.5
	_fill(Rect2(p0, p1 - p0).abs(), col, opt, func(p: Vector2) -> Variant:
		return Vector3((p.x - c.x) / maxf(1.0, hs.x) * 0.6, (p.y - c.y) / maxf(1.0, hs.y) * 0.3, 0.8))


## 칸 하나하나(눈 같은 작은 점): 빛 없이 그 색 그대로.
func dots(pts: Array, col: Color) -> void:
	var id := _new_part(true)
	for v: Vector2i in pts:
		if v.x >= 0 and v.y >= 0 and v.x < w and v.y < h:
			var i := v.y * w + v.x
			_base[i] = col
			_lvl[i] = 2
			_part[i] = id


func _new_part(noline: bool) -> int:
	_noline.append(noline)
	return _noline.size() - 1


func _fill(box: Rect2, col: Color, opt: Dictionary, normal: Callable) -> void:
	var id := _new_part(bool(opt.get("noline", false)))
	var tex := str(opt.get("tex", ""))
	var shift := (-1 if opt.get("dim", false) else 0) + (1 if opt.get("lift", false) else 0)
	var flat := bool(opt.get("flat", false))
	var Ln := L.normalized()
	for y in range(maxi(0, floori(box.position.y)), mini(h, ceili(box.end.y) + 1)):
		for x in range(maxi(0, floori(box.position.x)), mini(w, ceili(box.end.x) + 1)):
			var n: Variant = normal.call(Vector2(x + 0.5, y + 0.5))
			if n == null:
				continue
			var lv := 2
			if not flat:
				var s := (n as Vector3).normalized().dot(Ln)
				lv = 0 if s < -0.05 else (1 if s < 0.35 else (2 if s < 0.75 else 3))
			lv += shift + _tex(tex, x, y)
			var i := y * w + x
			_base[i] = col
			_lvl[i] = clampi(lv, 0, 3)
			_part[i] = id


static func _tex(tex: String, x: int, y: int) -> int:
	match tex:
		"hair":
			return -1 if posmod(x * 2 + (y >> 2), 5) == 0 else 0
		"fur":
			var hsh := posmod(x * 73 + y * 151 + (x * y) % 7, 11)
			return -1 if hsh < 3 else (1 if hsh == 10 else 0)
		"wrap":
			return -1 if posmod(y * 2 + (x >> 1), 6) == 0 else 0
	return 0


## 바탕색의 단: 0 그늘(차갑게 어둡게) · 1 중간 · 2 바탕 · 3 밝음.
static func ramp(c: Color, lv: int) -> Color:
	match lv:
		0:
			return Color(c.r * 0.46, c.g * 0.4, c.b * 0.5 + 0.015)
		1:
			return Color(c.r * 0.72, c.g * 0.68, c.b * 0.74)
		3:
			return c.lightened(0.18)
	return c


## 경계선·바깥선을 넣어 그림으로.
func image() -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var i := y * w + x
			var pid := _part[i]
			if pid < 0:
				if _touches(x, y):
					img.set_pixel(x, y, INK)
				continue
			var c := ramp(_base[i], _lvl[i])
			if not _noline[pid] and _behind(x, y, pid):
				c = Color(c.r * 0.55, c.g * 0.5, c.b * 0.55)
			img.set_pixel(x, y, c)
	return img


func _touches(x: int, y: int) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q := Vector2i(x, y) + d
		if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and _part[q.y * w + q.x] >= 0:
			return true
	return false


## 이 칸(뒤 조각)이 나중에 찍은 앞 조각과 맞닿았는가 — 맞닿은 뒤쪽 칸에 경계선.
func _behind(x: int, y: int, pid: int) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q := Vector2i(x, y) + d
		if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
			continue
		var o := _part[q.y * w + q.x]
		if o > pid and not _noline[o]:
			return true
	return false
