extends RefCounted
## 전투 뒷그림 재질 부품(세계 좌표 m — 원근에 맞춰 줄어든다): 잡음 · 판석 · 벽돌 · 바위 · 판자 · 쇠판.
## 각 함수는 {c, h, ink}를 돌려주고, 장면 재질 함수(Room.material)가 섞어 쓴다. tools/paint_battlebacks.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")

var _n: Dictionary = {}  ## 이름 → FastNoiseLite
var seed_base: int


func _init(s: int) -> void:
	seed_base = s


## 잡음 0~1. kind: lo(큰 얼룩, 2m) · mid(30cm) · hi(5cm) · cell(조각 경계 — 0이 경계)
func nz(kind: String, a: float, b: float) -> float:
	var n: FastNoiseLite = _n.get(kind)
	if n == null:
		n = FastNoiseLite.new()
		n.seed = seed_base + absi(kind.hash()) % 977
		n.fractal_type = FastNoiseLite.FRACTAL_FBM
		match kind:
			"lo":
				n.frequency = 0.45
				n.fractal_octaves = 3
			"mid":
				n.frequency = 3.0
				n.fractal_octaves = 3
			"hi":
				n.frequency = 18.0
				n.fractal_octaves = 2
			"cell":
				n.noise_type = FastNoiseLite.TYPE_CELLULAR
				n.frequency = 1.6
				n.fractal_type = FastNoiseLite.FRACTAL_NONE
				n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
			"cell2":
				n.noise_type = FastNoiseLite.TYPE_CELLULAR
				n.frequency = 1.6
				n.fractal_type = FastNoiseLite.FRACTAL_NONE
				n.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
			_:
				n.frequency = 1.0
				n.fractal_octaves = 3
		_n[kind] = n
	return clampf(n.get_noise_2d(a, b) * 0.5 + 0.5, 0.0, 1.0)


## 붓결처럼 색을 흔든다(큰 얼룩 + 붓 자국 + 고운 결).
func vary(c: Color, a: float, b: float, amt: float) -> Color:
	var v := (nz("lo", a, b) - 0.5) * 1.2 + (nz("mid", a, b) - 0.5) * 0.8 + (nz("hi", a, b) - 0.5) * 0.4
	return c.lightened(v * amt) if v > 0.0 else c.darkened(-v * amt)


## 줄 쌓기(벽돌·판석): u 가로, v 세로(m). 줄마다 반 칸 어긋난다. → {c, h, ink}
func courses(u: float, v: float, bw: float, bh: float, base: Color, mortar: Color, jitter: float = 0.18, joint: float = 0.035) -> Dictionary:
	var row := floori(v / bh)
	var uu := u + (0.5 * bw if row % 2 != 0 else 0.0) + (Paint.hash01(row, 7, seed_base) - 0.5) * bw * 0.3 + (nz("lo", u * 0.8, row * 3.1) - 0.5) * bw * 0.9
	var col := floori(uu / bw)
	var fu := uu / bw - col
	var fv := v / bh - row
	var wob := (nz("mid", u * 2.0, v * 2.0) - 0.5) * 0.5 + (nz("hi", u, v) - 0.5) * 0.4
	var ju := minf(fu, 1.0 - fu) * bw + wob * joint
	var jv := minf(fv, 1.0 - fv) * bh + wob * joint
	var j := minf(ju, jv)
	var k := Paint.hash01(col, row, seed_base)
	var c := base.lightened((k - 0.5) * jitter) if k > 0.5 else base.darkened((0.5 - k) * jitter)
	c = vary(c, u * 1.3, v * 1.3, 0.22)
	var chip := nz("cell", u * 1.7 + k * 9.0, v * 1.7)
	var edge := smoothstep(joint * 0.4, joint * 1.6, j)
	var hgt := 0.02 * edge + 0.01 * (nz("mid", u + k * 5.0, v) - 0.5) - 0.006 * (1.0 - smoothstep(0.0, 0.12, chip))
	c = c.darkened(0.25 * (1.0 - smoothstep(joint, joint * 3.5, j)) * nz("mid", u * 3.0, v * 3.0))  # 모서리 닳음·때
	if j < joint:
		c = mortar.lerp(c, j / joint * 0.4)
	return {"c": c, "h": hgt, "ink": (1.0 - smoothstep(joint * 0.2, joint * 0.9, j)) * 0.55}


## 막돌 판석(불규칙한 조각 — 세포 잡음 경계 = 줄눈): a·b 바닥 좌표 m, scale = 조각 크기 배율(1 ≈ 60cm).
func flags(a: float, b: float, scale: float, base: Color, mortar: Color, jitter: float = 0.3) -> Dictionary:
	var wa := a / scale + (nz("mid", a, b) - 0.5) * 0.12
	var wb := b / scale + (nz("mid", b + 7.0, a) - 0.5) * 0.12
	var cell := nz("cell", wa, wb)
	var cv := nz("cell2", wa, wb)
	var c := base.lightened((cv - 0.5) * jitter) if cv > 0.5 else base.darkened((0.5 - cv) * jitter)
	c = vary(c, a * 1.4, b * 1.4, 0.24)
	var edge := smoothstep(0.0, 0.16, cell)
	c = c.darkened(0.3 * (1.0 - smoothstep(0.05, 0.3, cell)) * nz("mid", a * 3.0, b * 3.0))
	if cell < 0.05:
		c = mortar.lerp(c, cell / 0.05 * 0.4)
	return {"c": c, "h": 0.025 * edge + 0.008 * nz("mid", a * 2.0 + cv * 9.0, b * 2.0), "ink": (1.0 - smoothstep(0.0, 0.045, cell)) * 0.6}


## 거친 바위(동굴 벽): 조각 경계는 갈라진 금.
func rock(a: float, b: float, base: Color, crack: float = 0.5) -> Dictionary:
	var wa := a + (nz("lo", a * 1.3, b * 1.3) - 0.5) * 0.7
	var wb := b + (nz("lo", b * 1.3 + 5.0, a * 1.3) - 0.5) * 0.7
	var big := nz("lo", a * 0.7, b * 0.7)
	var cell := nz("cell", wa * 0.75, wb * 0.95)
	var small := nz("cell", wa * 2.4 + 11.0, wb * 2.1)
	var cv := nz("cell2", wa * 0.75, wb * 0.95)
	var c := base.lightened((cv - 0.5) * 0.22) if cv > 0.5 else base.darkened((0.5 - cv) * 0.28)
	c = vary(c, a, b, 0.32)
	c = c.darkened(0.25 * (1.0 - smoothstep(0.0, 0.35, cell)))
	var hgt := big * 0.16 + smoothstep(0.0, 0.3, cell) * 0.06 + smoothstep(0.0, 0.2, small) * 0.02 + nz("mid", a, b) * 0.035 + nz("hi", a, b) * 0.008
	var ink := (1.0 - smoothstep(0.0, 0.045, cell)) * crack * smoothstep(0.3, 0.55, nz("mid", a * 0.7 + 3.0, b * 0.7))
	ink = maxf(ink, (1.0 - smoothstep(0.0, 0.03, small)) * crack * 0.35 * smoothstep(0.5, 0.7, nz("mid", a + 9.0, b)))
	return {"c": c, "h": hgt, "ink": ink}


## 판자(세로 결): u 가로, v 결 방향.
func planks(u: float, v: float, pw: float, base: Color) -> Dictionary:
	var col := floori(u / pw)
	var fu := u / pw - col
	var k := Paint.hash01(col, 3, seed_base)
	var c := base.darkened(k * 0.3)
	var grain := nz("hi", u * 6.0 + k * 10.0, v * 0.6)
	c = c.lerp(c.darkened(0.35), grain * 0.6)
	var j := minf(fu, 1.0 - fu) * pw
	return {"c": vary(c, u, v, 0.15), "h": 0.01 * smoothstep(0.0, 0.02, j) + grain * 0.004, "ink": (1.0 - smoothstep(0.0, 0.012, j)) * 0.7}


## 쇠판(리벳 박은 판): u·v 판 크기 pw·ph.
func plates(u: float, v: float, pw: float, ph: float, base: Color) -> Dictionary:
	var col := floori(u / pw)
	var row := floori(v / ph)
	var fu := u / pw - col
	var fv := v / ph - row
	var k := Paint.hash01(col, row, seed_base + 5)
	var c := base.darkened(k * 0.25)
	var rust := smoothstep(0.55, 0.85, nz("lo", u * 1.5 + 3.0, v * 1.5)) * smoothstep(0.3, 0.8, nz("mid", u, v))
	c = c.lerp(Color("#4a2e1e"), rust * 0.6)
	c = vary(c, u, v, 0.18)
	var j := minf(minf(fu, 1.0 - fu) * pw, minf(fv, 1.0 - fv) * ph)
	var hgt := 0.01 * smoothstep(0.0, 0.03, j)
	var ink := (1.0 - smoothstep(0.0, 0.015, j)) * 0.75
	for ru: float in [0.07, 0.93]:  # 리벳 — 판 네 귀퉁이
		for rv: float in [0.1, 0.9]:
			var d := Vector2((fu - ru) * pw, (fv - rv) * ph).length()
			if d < 0.035:
				hgt += 0.02 * (1.0 - d / 0.035)
				ink = maxf(ink, 0.25 if d > 0.025 else 0.0)
	return {"c": c, "h": hgt, "ink": ink, "spec": 0.35 * (1.0 - rust)}


## 피 얼룩(바닥·벽): 0~1 덮임.
func blood(a: float, b: float, amount: float) -> float:
	var v := nz("lo", a * 0.9 + 40.0, b * 0.9) * 0.7 + nz("mid", a + 40.0, b) * 0.3
	return smoothstep(1.0 - amount, 1.0 - amount + 0.08, v)
