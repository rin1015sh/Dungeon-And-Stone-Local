extends RefCounted
## 이어 붙여도 이음매가 안 보이는 재질 칸을 위한 도구(tools/paint_floor.gd 전용).
##   field  = 주기 잡음(가로·세로로 말려 이어지는 높이장) — 같은 시드면 모든 변형이 같은 바탕을 쓴다.
##   relief = 높이장의 기울기로 왼쪽 위 빛을 받은 밝기(붓으로 덩어리를 빚은 느낌).
##   mask   = 가장자리 0 → 안쪽 1. 변형마다 다른 잔손질(돌·금·물기)을 가장자리에서 바탕으로 되돌려 칸끼리 이어지게 한다.

const LIGHT := Vector3(-0.55, -0.6, 0.58)  ## 왼쪽 위 앞(ART §2 — Render.LIGHT와 같은 방향)


## 주기 잡음 w×h(0~1). cellular면 돌 덩어리 경계.
static func field(w: int, h: int, seed_value: int, freq: float, octaves: int = 4, cellular: bool = false) -> PackedFloat32Array:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = octaves
	if cellular:
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
		n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var im := n.get_seamless_image(w, h, false, false, 0.1, true)
	im.convert(Image.FORMAT_L8)
	var data := im.get_data()
	var out := PackedFloat32Array()
	out.resize(w * h)
	for i in w * h:
		out[i] = data[i] / 255.0
	return out


static func at(f: PackedFloat32Array, w: int, h: int, x: int, y: int) -> float:
	return f[posmod(y, h) * w + posmod(x, w)]


## 높이장 f의 (x, y)에서 빛 받은 정도(-1~1). bump = 높낮이 세기.
static func relief(f: PackedFloat32Array, w: int, h: int, x: int, y: int, bump: float) -> float:
	var dx := (at(f, w, h, x + 1, y) - at(f, w, h, x - 1, y)) * bump
	var dy := (at(f, w, h, x, y + 1) - at(f, w, h, x, y - 1)) * bump
	var nrm := Vector3(-dx, -dy, 1.0).normalized()
	return nrm.dot(LIGHT.normalized()) - LIGHT.normalized().z


## 가장자리에서 band px 안쪽까지 0 → 1. horiz_only면 좌우 가장자리만(벽 앞면 — 위아래는 잇지 않는다).
static func mask(x: int, y: int, w: int, h: int, band: float, horiz_only: bool = false) -> float:
	var d := minf(x + 0.5, w - x - 0.5)
	if not horiz_only:
		d = minf(d, minf(y + 0.5, h - y - 0.5))
	return smoothstep(0.0, band, d - band * 0.25)
