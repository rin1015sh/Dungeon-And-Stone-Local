extends RefCounted
## 조형 판(Clay)을 그림으로: 면의 방향으로 낸 명암을 3~4단 붓 칠로 나누고(부드러운 띠 경계),
## 오목한 골(근육 사이·주름)은 어둡게 + 가는 잉크, 가려진 경계·바깥 윤곽은 굵기가 바뀌는 잉크 선,
## 그늘에는 형태를 따라 도는 손 빗금 — 피어 앤 헝거 몬스터 그림처럼 "칠한 위에 펜으로 긁은" 느낌.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Pen := preload("res://tools/monster_art/Pen.gd")
const Kinds := preload("res://tools/monster_art/Kinds.gd")

const LIGHT := Vector3(-0.45, -0.55, 0.7)
const SHADOW_TINT := Color(0.13, 0.07, 0.08)
const WARM := Color(1.0, 0.9, 0.74)



## scale = 그림 크기 기준(몸 높이 px). 잉크 굵기·빗금 간격이 따라 커진다.
## light = 빛 방향(탐험 맵 몸 그림은 더 앞에서 비춰 얼굴 양쪽이 고르게 밝다 — tools/paint_actors.gd).
static func render(cl: Clay, p: Paint, scale: float, light: Vector3 = LIGHT) -> void:
	cl.resolve()
	var n := cl.w * cl.h
	var nx := PackedFloat32Array()
	var ny := PackedFloat32Array()
	var nzz := PackedFloat32Array()
	nx.resize(n)
	ny.resize(n)
	nzz.resize(n)
	_normals(cl, nx, ny, nzz)
	var cav := _cavity(cl, nzz, maxf(2.0, scale / 120.0))
	var cav2 := _cavity(cl, nzz, maxf(4.0, scale / 40.0))
	var tone := PackedFloat32Array()
	tone.resize(n)
	var L := light.normalized()
	for y in cl.h:
		for x in cl.w:
			var i := y * cl.w + x
			var m := cl.top_m[i]
			if m < 0:
				continue
			var md: Dictionary = cl.mats[m]
			var kind := str(md["kind"])
			var kd: Dictionary = Kinds.KINDS.get(kind, Kinds.KINDS["skin"])
			var nv := Vector3(nx[i], ny[i], nzz[i])
			var diff := nv.dot(L)
			var t := clampf(diff * 1.1 - 0.12, 0.0, 1.0)
			t -= (cav[i] * 1.3 + cav2[i] * 0.75) * float(md.get("cav", 1.0))  # 재질 cav = 오목한 곳 어둡게 하는 정도
			t -= pow(1.0 - nzz[i], 1.6) * 0.55  # 옆을 향한 면(덩어리 가장자리)은 어둡게 — 가운데 밝고 둘레 그늘
			t -= smoothstep(0.55, 1.0, float(y) / cl.h) * 0.12  # 아래쪽(다리)은 조금 어둡게
			t += (p.nz("mid", x, y) - 0.5) * 0.26 + (_tex(p, kind, x, y) - 0.5) * float(md.get("tex", kd["tex"]))
			tone[i] = t
			p.blend(x, y, _color(md, kd, kind, t, nv, L, p, x, y), 1.0)
	Pen.brush(cl, p, nx, ny, scale)
	var ink := PackedFloat32Array()
	ink.resize(n)
	Pen.edges(cl, p, ink, nx, ny, scale)
	Pen.creases(cl, p, ink, cav, scale)
	Pen.hatch(cl, p, ink, tone, scale)
	for i in n:
		if ink[i] > 0.0:
			var x := i % cl.w
			var y := i / cl.w
			var a := minf(1.0, ink[i])
			if cl.top_g[i] < 0:
				p.blend(x, y, Kinds.INK_C, a)
			else:
				p.tint(x, y, Kinds.INK_C, a * 0.95)


static func _color(md: Dictionary, kd: Dictionary, kind: String, t: float, nv: Vector3, L: Vector3, p: Paint, x: int, y: int) -> Color:
	var base: Color = md["c"]
	if kind == "glow":
		return base
	var con := float(md.get("contrast", kd["contrast"]))
	# 그늘은 회색이 아니라 따뜻한 적갈색으로(피어 앤 헝거 살갗: 밝은 살 + 근육 사이 붉은 갈색 그늘)
	var sh_c: Color = md.get("shade", Color(base.r * 0.5, base.g * 0.36, base.b * 0.34))
	var deep := Color(sh_c.r * 0.42, sh_c.g * 0.4, sh_c.b * 0.42)
	var shad := sh_c
	var mid := Color(base.r * 0.78, base.g * 0.64, base.b * 0.62)
	var lit := base.lerp(WARM, 0.06)
	var c: Color
	# 붓 칠 띠(3~4단 납작한 색 덩어리, 경계는 잡음으로 들쭉날쭉): 깊은 그늘 · 그늘 · 중간 · 밝음
	var tt := 0.5 + (t - 0.5) * con + (p.nz("hi", x, y) - 0.5) * 0.08
	var e := 0.018
	c = deep.lerp(shad, smoothstep(0.16 - e, 0.16 + e, tt))
	c = c.lerp(mid, smoothstep(0.36 - e, 0.36 + e, tt))
	c = c.lerp(lit, smoothstep(0.56 - e, 0.56 + e, tt))
	c = c.lerp(lit.lightened(0.12), smoothstep(0.8 - e, 0.8 + e, tt) * 0.6)
	var spec := float(md.get("spec", kd["spec"]))
	if spec > 0.0:
		var hv := (L + Vector3(0, 0, 1)).normalized()
		var s := pow(maxf(0.0, nv.dot(hv)), 24.0 if kind != "metal" else 10.0) * spec
		if kind == "metal":  # 쇠: 위를 향한 면은 하늘빛, 아래는 어둡게 — 띠 진 반사
			s += smoothstep(0.1, -0.5, nv.y) * 0.25 * spec
			c = c.darkened(smoothstep(0.0, 0.6, nv.y) * 0.25)
		if s > 0.35:
			s = 0.35 + (s - 0.35) * 0.5
		c = c.lerp(Color(1.0, 0.96, 0.88), clampf(s, 0.0, 0.85))
	if kind == "slime":  # 속이 비치는 덩어리: 가장자리 진하고 안쪽 밝게
		c = c.lerp(base.lightened(0.25), clampf(nv.z - 0.6, 0.0, 0.4))
	if md.has("mottle"):
		var mc: Color = md["mottle"]
		var mn := p.nz("lo", x, y)
		if mn > 0.5:
			c = c.lerp(mc * Color(c.get_luminance() * 2.0, c.get_luminance() * 2.0, c.get_luminance() * 2.0), clampf((mn - 0.5) * 2.5, 0.0, 1.0) * float(md.get("mottle_amt", 0.5)))
	return Color(c.r, c.g, c.b, 1.0)


static func _tex(p: Paint, kind: String, x: int, y: int) -> float:
	match kind:
		"fur", "hair", "cloth", "wood":
			return p.nz("vs", x, y) * 0.6 + p.nz("hi", x, y) * 0.4
		"stone":
			return p.nz("cell", x, y) * 0.7 + p.nz("hi", x, y) * 0.3
		"metal":
			return p.nz("lo", x, y) * 0.6 + p.nz("hi", x, y) * 0.4
	return p.nz("hi", x, y) * 0.5 + p.nz("lo", x, y) * 0.5


## 면의 방향: 그 칸을 덮은 그룹의 높이로(그룹 밖 이웃은 자기 값으로 — 다른 덩어리에 끌려가지 않게).
static func _normals(cl: Clay, nx: PackedFloat32Array, ny: PackedFloat32Array, nzz: PackedFloat32Array) -> void:
	var hs: Array = []
	for g in cl.group_count():
		hs.append(cl.height_of(g))
	var lim := 7.0
	for y in cl.h:
		for x in cl.w:
			var i := y * cl.w + x
			var g := cl.top_g[i]
			if g < 0:
				continue
			var hh: PackedFloat32Array = hs[g]
			var c := hh[i]
			var l := hh[i - 1] if x > 0 else Clay.EMPTY
			var r := hh[i + 1] if x + 1 < cl.w else Clay.EMPTY
			var u := hh[i - cl.w] if y > 0 else Clay.EMPTY
			var d := hh[i + cl.w] if y + 1 < cl.h else Clay.EMPTY
			var gx := 0.0
			var gy := 0.0
			var lo := Clay.EMPTY * 0.5
			if l > lo and r > lo:
				gx = (r - l) * 0.5
			elif r > lo:
				gx = r - c
			elif l > lo:
				gx = c - l
			if u > lo and d > lo:
				gy = (d - u) * 0.5
			elif d > lo:
				gy = d - c
			elif u > lo:
				gy = c - u
			if l <= lo or r <= lo or u <= lo or d <= lo:  # 그룹 가장자리: 둥글게 돌아가는 면
				var ex := (-1.0 if l <= lo else 0.0) + (1.0 if r <= lo else 0.0)
				var ey := (-1.0 if u <= lo else 0.0) + (1.0 if d <= lo else 0.0)
				gx -= ex * lim * 0.6
				gy -= ey * lim * 0.6
			gx = clampf(gx, -lim, lim)
			gy = clampf(gy, -lim, lim)
			var v := Vector3(-gx, -gy, 1.0).normalized()
			nx[i] = v.x
			ny[i] = v.y
			nzz[i] = v.z


## 오목함: 반지름 r 안 평균 높이 − 내 높이(양수 = 골). 바깥 테두리(면이 옆을 향함)는 거짓 골이라 줄인다.
static func _cavity(cl: Clay, nzz: PackedFloat32Array, r: float) -> PackedFloat32Array:
	var w := cl.w
	var h := cl.h
	var sh := PackedFloat64Array()
	var sc := PackedFloat64Array()
	sh.resize((w + 1) * (h + 1))
	sc.resize((w + 1) * (h + 1))
	for y in h:
		var rowh := 0.0
		var rowc := 0.0
		for x in w:
			var i := y * w + x
			if cl.top_g[i] >= 0:
				rowh += cl.top_h[i]
				rowc += 1.0
			var k := (y + 1) * (w + 1) + x + 1
			sh[k] = sh[k - w - 1] + rowh
			sc[k] = sc[k - w - 1] + rowc
	var out := PackedFloat32Array()
	out.resize(w * h)
	var ri := int(ceil(r))
	for y in h:
		var ya := maxi(0, y - ri)
		var yb := mini(h, y + ri + 1)
		for x in w:
			var i := y * w + x
			if cl.top_g[i] < 0:
				continue
			var xa := maxi(0, x - ri)
			var xb := mini(w, x + ri + 1)
			var k1 := yb * (w + 1) + xb
			var k2 := ya * (w + 1) + xb
			var k3 := yb * (w + 1) + xa
			var k4 := ya * (w + 1) + xa
			var cnt := sc[k1] - sc[k2] - sc[k3] + sc[k4]
			if cnt <= 0.0:
				continue
			var avg := (sh[k1] - sh[k2] - sh[k3] + sh[k4]) / cnt
			var c := clampf((avg - cl.top_h[i]) / (r * 0.9), 0.0, 1.0)
			out[i] = c * smoothstep(0.25, 0.6, nzz[i])
	return out
