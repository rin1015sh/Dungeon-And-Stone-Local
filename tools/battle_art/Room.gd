extends RefCounted
## 전투 뒷그림의 원근 공간(한 점 투시 굴·복도 — 피어 앤 헝거 전투 배경처럼 소실점으로 빨려 드는 통로).
## 화면 픽셀마다 시선을 쏘아(표로 만든 단면을 걸음 + 이분법) 바닥·천장·좌우 벽·끝 벽에 닿는 곳을 찾고,
## 장면이 준 재질 함수(세계 좌표)와 점광원으로 칠한다. 결은 높이(h)의 화면 기울기로 법선을 흔들어 빛을 받게 한다.
## 소품은 pt()로 투영한 다각형으로 그 위에 칠한다(Kit). 좌표: x 오른쪽 · y 위(바닥 0) · z 앞(멀어짐), 단위 m.
## 카메라 = (0, eye, 0)에서 +z를 본다. tools/paint_battlebacks.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")
const RoomRender := preload("res://tools/battle_art/RoomRender.gd")

const NONE := 0
const FLOOR := 1
const CEIL := 2
const WALL_L := 3
const WALL_R := 4
const END := 5
const DZ := 0.05  ## 단면 표 간격(m)
const PROF_N := 64

var w: int
var h: int
var cx: float
var hy: float = 215.0     ## 지평선(소실점) y px
var f: float = 700.0      ## 초점 거리 px
var eye: float = 1.1      ## 카메라 높이 m
var z_end: float = 34.0   ## 끝 벽 거리 m
var ambient: Color = Color(0.07, 0.06, 0.06)
var fog_c: Color = Color("#0a0807")
var fog_k: float = 0.1    ## 거리 안개 짙기(1/m)
var fog_z0: float = 3.0   ## 이 거리까지는 안개 없음
var lights: Array[Dictionary] = []  ## {p: Vector3, c: Color, s: 세기, r: 반경 m}
## 재질: (kind, P: Vector3, N: Vector3) -> {c: Color, h: 높이 m(결), ink: 0~1 잉크, emit: Color, spec: 0~1 광택, flat: true면 빛·안개 없이 c 그대로(하늘·낭떠러지)}
var material: Callable
var bump: float = 1.0
var profile: String = "box"  ## box(곧은 벽) · vault(아치 천장) · cave(둥근 굴)
var spring: float = 0.55     ## vault: 벽이 휘기 시작하는 높이(천장 높이 비율)
var zbuf: PackedFloat32Array
var kind_buf: PackedByteArray
var _l := PackedFloat32Array()
var _r := PackedFloat32Array()
var _c := PackedFloat32Array()
var _f := PackedFloat32Array()   ## z → 바닥 높이(계단·내리막 — 비면 0)
var _tl := PackedFloat32Array()  ## z → 왼벽 꼭대기(그 위는 트였다 — 바깥 장면, 비면 끝없음)
var _tr := PackedFloat32Array()
var _f_max: float = 0.0
var _prof := PackedFloat32Array()
var _min_hw: float = 1.0
var _min_ch: float = 2.0


func _init(p_w: int, p_h: int) -> void:
	w = p_w
	h = p_h
	cx = p_w / 2.0


## 단면: left(z)·right(z) = 가운데에서 벽까지 m, ceil_h(z) = 천장 높이 m. 단면 모양은 profile.
## floor_h(z) = 바닥 높이(계단·내리막, 없으면 0), top_l·top_r(z) = 벽 꼭대기(그 위로는 트여 끝 벽·하늘이 보인다 — 바깥 장면).
func shape(left: Callable, right: Callable, ceil_h: Callable, floor_h: Callable = Callable(), top_l: Callable = Callable(), top_r: Callable = Callable()) -> void:
	var n := int(z_end / DZ) + 3
	_f = PackedFloat32Array()
	_tl = PackedFloat32Array()
	_tr = PackedFloat32Array()
	_f_max = 0.0
	if floor_h.is_valid():
		_f.resize(n)
		_f_max = -1e9
		for i in n:
			_f[i] = float(floor_h.call(i * DZ))
			_f_max = maxf(_f_max, _f[i])
	if top_l.is_valid():
		_tl.resize(n)
		_tr.resize(n)
		for i in n:
			_tl[i] = float(top_l.call(i * DZ))
			_tr[i] = float((top_r if top_r.is_valid() else top_l).call(i * DZ))
	_l.resize(n)
	_r.resize(n)
	_c.resize(n)
	_min_hw = 1e9
	_min_ch = 1e9
	for i in n:
		var z := i * DZ
		_l[i] = maxf(0.3, float(left.call(z)))
		_r[i] = maxf(0.3, float(right.call(z)))
		_c[i] = maxf(eye + 0.2, float(ceil_h.call(z)))
		_min_hw = minf(_min_hw, minf(_l[i], _r[i]))
		_min_ch = minf(_min_ch, _c[i])
	_prof.resize(PROF_N + 1)
	for i in PROF_N + 1:
		var yn := float(i) / PROF_N
		match profile:
			"vault":
				_prof[i] = 1.0 if yn <= spring else sqrt(maxf(0.0, 1.0 - pow((yn - spring) / (1.0 - spring), 2.0)))
			"cave":
				_prof[i] = pow(maxf(0.0, 1.0 - pow(yn, 2.6)), 0.4)
			_:
				_prof[i] = 1.0
	if profile != "box":  # 굴·아치는 위가 좁아 천장 판 대신 벽이 덮는다
		_min_ch = minf(_min_ch, eye + 0.2)


func left_at(z: float) -> float:
	return _tab(_l, z)


func right_at(z: float) -> float:
	return _tab(_r, z)


func ceil_at(z: float) -> float:
	return _tab(_c, z)


func floor_at(z: float) -> float:
	return 0.0 if _f.is_empty() else _tab(_f, z)


## 그 높이에서 벽까지 거리(m). side -1 왼쪽, 1 오른쪽.
func wall_x(z: float, y: float, side: int) -> float:
	var ch := _tab(_c, z)
	return (_tab(_r, z) if side > 0 else _tab(_l, z)) * _prof_at(y / ch)


func pt(x: float, y: float, z: float) -> Vector2:
	return Vector2(cx + f * x / z, hy + f * (eye - y) / z)


## 거리 z에서 m 길이의 화면 px.
func px(m: float, z: float) -> float:
	return f * m / z


static func _tab(a: PackedFloat32Array, z: float) -> float:
	var t := clampf(z / DZ, 0.0, a.size() - 1.001)
	var i := int(t)
	return lerpf(a[i], a[i + 1], t - i)


func _prof_at(yn: float) -> float:
	var t := clampf(yn, 0.0, 1.0) * PROF_N
	var i := mini(int(t), PROF_N - 1)
	return lerpf(_prof[i], _prof[i + 1], t - i)


## 깊이 t의 시선 위 점이 공간 밖이면 그 면.
func _outside(dx: float, dy: float, t: float) -> int:
	var y := eye + dy * t
	if y < (0.0 if _f.is_empty() else _tab(_f, t)):
		return FLOOR
	var ch := _tab(_c, t)
	if y > ch:
		return CEIL
	var x := dx * t
	var pr := _prof_at(y / ch)
	if x > 0.0 and x > _tab(_r, t) * pr and (_tr.is_empty() or y < _tab(_tr, t)):
		return WALL_R
	if x < 0.0 and -x > _tab(_l, t) * pr and (_tl.is_empty() or y < _tab(_tl, t)):
		return WALL_L
	return NONE


## 시선 하나: (깊이, 면). 바닥은 식으로, 벽·천장은 걸음 + 이분법.
func _hit(dx: float, dy: float) -> Vector2:
	var t_floor := eye / -dy if dy < 0.0 else 1e9
	if not _f.is_empty():  # 높낮이 있는 바닥 = 걸어서 찾는다(가장 높은 바닥보다 먼저 닿지는 않는다)
		t_floor = 1e9
	var t_max := minf(t_floor, z_end)
	var t := 0.2
	if absf(dx) > 1e-4 and _tl.is_empty():
		t = maxf(t, _min_hw * 0.98 / (absf(dx) * 1.0))
	if dy > 1e-4:
		t = minf(t, maxf(0.2, (_min_ch - eye) / dy))
	if not _f.is_empty() and dy < -1e-4:
		t = minf(t, maxf(0.2, (eye - _f_max) / -dy))
	t = minf(t, t_max)
	if _outside(dx, dy, t) != NONE:  # 이미 밖 = 아주 가까운 벽(화면 귀퉁이)
		var a0 := 0.05
		var b0 := t
		for i in 10:
			var m := (a0 + b0) * 0.5
			if _outside(dx, dy, m) != NONE:
				b0 = m
			else:
				a0 = m
		return Vector2(b0, _outside(dx, dy, b0))
	var stp := 0.35
	while t < t_max:
		var nt := minf(t + stp, t_max)
		if _outside(dx, dy, nt) != NONE and nt < t_max:
			var a := t
			var b := nt
			for i in 8:
				var m := (a + b) * 0.5
				if _outside(dx, dy, m) != NONE:
					b = m
				else:
					a = m
			return Vector2(b, _outside(dx, dy, b))
		t = nt
		stp = minf(1.0, stp * 1.06)
	if not _f.is_empty() and _outside(dx, dy, z_end) == FLOOR:
		return Vector2(z_end, FLOOR)
	return Vector2(t_max, FLOOR if t_floor <= z_end else END)


## 면의 법선(공간 안쪽을 본다).
func _normal(kind: int, P: Vector3) -> Vector3:
	match kind:
		FLOOR:
			if _f.is_empty():
				return Vector3.UP
			return Vector3(0.0, 1.0, -(_tab(_f, P.z + 0.02) - _tab(_f, P.z - 0.02)) / 0.04).normalized()
		CEIL:
			var dc := (_tab(_c, P.z + 0.1) - _tab(_c, P.z - 0.1)) / 0.2
			return Vector3(0.0, -1.0, dc).normalized()
		WALL_L, WALL_R:
			var s := 1.0 if kind == WALL_R else -1.0
			var ch := _tab(_c, P.z)
			var arr := _r if kind == WALL_R else _l
			var hw := _tab(arr, P.z)
			var yn := P.y / ch
			var pr := _prof_at(yn)
			var dpr := (_prof_at(yn + 0.02) - _prof_at(yn - 0.02)) / 0.04
			var dhw := (_tab(arr, P.z + 0.1) - _tab(arr, P.z - 0.1)) / 0.2
			# F = s*x - hw(z)*prof(y/ch) — 바깥 기울기 = (s, -hw*prof'/ch, -hw'*prof) → 안쪽 법선은 반대
			return -Vector3(s, -hw * dpr / ch, -dhw * pr).normalized()
	return Vector3(0, 0, -1)


## 칠한다: 시선 → 면·재질 → (결 기울기로 흔든 법선) 빛 → 잉크 → 안개. 캔버스 전체를 덮는다(RoomRender).
func render(p: Paint) -> void:
	RoomRender.run(self, p)


## 시선 하나(RoomRender가 부른다): 화면 픽셀 → [깊이, 면, 세계 점, 법선].
func trace(x: int, y: int) -> Array:
	var dy := (hy - (y + 0.5)) / f
	var dx := ((x + 0.5) - cx) / f
	var hit := _hit(dx, dy)
	var t := hit.x
	var kind := int(hit.y)
	var P := Vector3(dx * t, eye + dy * t, t)
	return [t, kind, P, _normal(kind, P)]


## 점 P(법선 N)에 떨어지는 빛 × 색. 소품도 이것으로 칠한다(Kit).
func shade(P: Vector3, N: Vector3, albedo: Color, spec: float = 0.0) -> Color:
	var r := ambient.r
	var g := ambient.g
	var b := ambient.b
	var view := (Vector3(0, eye, 0) - P).normalized()
	for L: Dictionary in lights:
		var d: Vector3 = (L["p"] as Vector3) - P
		var dist := d.length()
		if dist < 1e-4:
			continue
		var l := d / dist
		var rad: float = L["r"]
		var att: float = float(L["s"]) / (1.0 + (dist / rad) * (dist / rad))
		var ndl := maxf(0.0, N.dot(l)) * 0.85 + 0.15 * maxf(0.0, 0.5 + 0.5 * N.dot(l))  # 감싸는 빛 조금(완전한 검정 그늘 막기)
		var lc: Color = L["c"]
		var k := att * ndl
		if spec > 0.0:
			var hv := (l + view).normalized()
			k += att * spec * pow(maxf(0.0, N.dot(hv)), 24.0) * 3.0
		r += lc.r * k
		g += lc.g * k
		b += lc.b * k
	return Color(albedo.r * r, albedo.g * g, albedo.b * b)


## 거리 안개(먼 곳은 어둠으로 녹는다).
func fog(c: Color, z: float) -> Color:
	var k := 1.0 - exp(-fog_k * maxf(0.0, z - fog_z0))
	return c.lerp(fog_c, clampf(k, 0.0, 1.0))


## 소품용: 점 P의 빛 받은 색(+ 안개).
func lit(P: Vector3, N: Vector3, albedo: Color, spec: float = 0.0) -> Color:
	return fog(shade(P, N, albedo, spec), P.z)


## 그 화면 점의 깊이(소품이 벽 뒤로 숨는지).
func depth_at(x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= w or y >= h:
		return 1e9
	return zbuf[y * w + x]
