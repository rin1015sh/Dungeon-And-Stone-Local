extends RefCounted
## 페인터리 캔버스(도시 그림 생성기 tools/paint_city.gd 전용 — 게임 코드는 생성된 그림만 쓴다).
## 손으로 칠한 듯한 어두운 일러스트(거친 붓결 · 떨리는 잉크 윤곽 · 그늘의 빗금 · 탁한 색 · 필름 그레인)를 흉내 낸다.
## 픽셀은 RGBA 실수 버퍼에 쌓고 save()에서 한 번에 이미지로 만든다. 시드 고정 — 같은 시드면 같은 그림.

var w: int
var h: int
var rng: RandomNumberGenerator
var buf: PackedFloat32Array  # r,g,b,a 순서(곱하지 않은 알파)
var _noise: Dictionary = {}  # 종류 → PackedFloat32Array(w*h, 0~1)
var _stroke: PackedFloat32Array  # 잉크 한 획의 덮임(최댓값) — 겹쳐 찍어도 진해지지 않게
var _seed: int
## 사람 등 '어둠을 덜 받는' 자리(0~1) — NpcParts.stamp가 채우고 Interiors.light가 읽는다. 비어 있으면 없음.
var keep: PackedFloat32Array
## 부품 자리(Parts가 남긴다 — 거주 구역 꾸밈 Dress가 창 밑 꽃상자·금테·문 현관을 단다): 종류(window·door·ledge) → [[Rect2, 모양] …].
var marks: Dictionary = {}


func _init(p_w: int, p_h: int, seed_value: int) -> void:
	w = p_w
	h = p_h
	_seed = seed_value
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	buf = PackedFloat32Array()
	buf.resize(w * h * 4)
	_stroke = PackedFloat32Array()
	_stroke.resize(w * h)


## 잃는 압축(WebP)으로 저장 — 붓결·그레인은 PNG로는 매우 커진다. quality 0~1.
func save(path: String, quality: float = 0.86) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	to_image().save_webp(path, true, quality)


func to_image() -> Image:
	var bytes := PackedByteArray()
	bytes.resize(w * h * 4)
	for i in w * h * 4:
		bytes[i] = clampi(int(buf[i] * 255.0 + 0.5), 0, 255)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)


func mark(kind: String, r: Rect2, style: String = "") -> void:
	if not marks.has(kind):
		marks[kind] = []
	(marks[kind] as Array).append([r, style])


# ── 잡음 ────────────────────────────────────────────────

## kind: lo(큰 얼룩) · mid(붓 자국) · hi(고운 결) · vs(세로 줄무늬 — 빗물 자국·나뭇결) · hs(가로 줄무늬) · cell(돌 조각 경계)
func nz(kind: String, x: int, y: int) -> float:
	var a: PackedFloat32Array = _noise.get(kind, PackedFloat32Array())
	if a.is_empty():
		a = _make_noise(kind)
		_noise[kind] = a
	return a[clampi(y, 0, h - 1) * w + clampi(x, 0, w - 1)]


func _make_noise(kind: String) -> PackedFloat32Array:
	var n := FastNoiseLite.new()
	n.seed = _seed + kind.hash() % 1000
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	var gw := w
	var gh := h
	match kind:
		"lo":
			n.frequency = 0.012
			n.fractal_octaves = 4
		"mid":
			n.frequency = 0.06
			n.fractal_octaves = 3
		"hi":
			n.frequency = 0.45
			n.fractal_octaves = 2
		"vs":
			n.frequency = 0.08
			n.fractal_octaves = 3
			gh = maxi(2, h / 14)
		"hs":
			n.frequency = 0.08
			n.fractal_octaves = 3
			gw = maxi(2, w / 14)
		"cell":
			n.noise_type = FastNoiseLite.TYPE_CELLULAR
			n.frequency = 0.05
			n.fractal_type = FastNoiseLite.FRACTAL_NONE
			n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var im := n.get_image(gw, gh, false, false, true)
	if gw != w or gh != h:
		im.resize(w, h, Image.INTERPOLATE_CUBIC)
	var data := im.get_data()
	var step := 1 if im.get_format() == Image.FORMAT_L8 else 4
	var out := PackedFloat32Array()
	out.resize(w * h)
	for i in w * h:
		out[i] = data[i * step] / 255.0
	return out


## 정수 좌표 해시 → 0~1(돌·판자·기와 한 장마다 다른 색).
static func hash01(a: int, b: int, s: int = 0) -> float:
	var v := (a * 73856093) ^ (b * 19349663) ^ (s * 83492791)
	v = (v ^ (v >> 13)) * 1274126177
	return float(absi(v ^ (v >> 16)) % 10007) / 10007.0


# ── 픽셀 ────────────────────────────────────────────────

func blend(x: int, y: int, c: Color, a: float) -> void:
	if x < 0 or y < 0 or x >= w or y >= h or a <= 0.0:
		return
	var i := (y * w + x) * 4
	var da := buf[i + 3]
	var oa := a + da * (1.0 - a)
	if oa <= 0.0:
		return
	var k := da * (1.0 - a)
	buf[i] = (c.r * a + buf[i] * k) / oa
	buf[i + 1] = (c.g * a + buf[i + 1] * k) / oa
	buf[i + 2] = (c.b * a + buf[i + 2] * k) / oa
	buf[i + 3] = oa


## 이미 칠한 곳에만 덧칠(알파는 그대로) — 그늘·빛·때.
func tint(x: int, y: int, c: Color, a: float) -> void:
	if x < 0 or y < 0 or x >= w or y >= h or a <= 0.0:
		return
	var i := (y * w + x) * 4
	if buf[i + 3] <= 0.0:
		return
	buf[i] = lerpf(buf[i], c.r, a)
	buf[i + 1] = lerpf(buf[i + 1], c.g, a)
	buf[i + 2] = lerpf(buf[i + 2], c.b, a)


## 더하기 빛(창 불빛·등불 번짐). only_painted면 칠한 곳에만.
func add_light(x: int, y: int, c: Color, a: float, only_painted: bool = true) -> void:
	if x < 0 or y < 0 or x >= w or y >= h or a <= 0.0:
		return
	var i := (y * w + x) * 4
	if only_painted and buf[i + 3] <= 0.0:
		return
	buf[i] = minf(1.0, buf[i] + c.r * a)
	buf[i + 1] = minf(1.0, buf[i + 1] + c.g * a)
	buf[i + 2] = minf(1.0, buf[i + 2] + c.b * a)


func get_c(x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= w or y >= h:
		return Color(0, 0, 0, 0)
	var i := (y * w + x) * 4
	return Color(buf[i], buf[i + 1], buf[i + 2], buf[i + 3])


func alpha_at(x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= w or y >= h:
		return 0.0
	return buf[(y * w + x) * 4 + 3]


# ── 도형 채우기 ─────────────────────────────────────────

## 다각형을 칠한다. shader(x, y) -> Color(알파 포함). 가장자리는 위아래 두 줄 표본으로 부드럽게. tint_only = 칠한 곳에만 덧칠.
func fill_poly(poly: PackedVector2Array, shader: Callable, opacity: float = 1.0, tint_only: bool = false) -> void:
	var r := bounds(poly)
	var y0 := maxi(0, int(floor(r.position.y)))
	var y1 := mini(h - 1, int(ceil(r.end.y)))
	var x0 := maxi(0, int(floor(r.position.x)))
	var x1 := mini(w - 1, int(ceil(r.end.x)))
	if x1 < x0:
		return
	var cov := PackedFloat32Array()
	cov.resize(x1 - x0 + 2)
	for y in range(y0, y1 + 1):
		cov.fill(0.0)
		var any := false
		for sub: float in [0.25, 0.75]:
			var xs := _span_x(poly, y + sub)
			var k := 0
			while k + 1 < xs.size():
				any = true
				_cover(cov, x0, x1, xs[k], xs[k + 1])
				k += 2
		if not any:
			continue
		for x in range(x0, x1 + 1):
			var cv := cov[x - x0] * 0.5
			if cv <= 0.002:
				continue
			var c: Color = shader.call(x, y)
			if tint_only:
				tint(x, y, c, c.a * minf(1.0, cv) * opacity)
			else:
				blend(x, y, c, c.a * minf(1.0, cv) * opacity)


func fill_rect(x: float, y: float, rw: float, rh: float, shader: Callable, opacity: float = 1.0) -> void:
	fill_poly(rect_poly(x, y, rw, rh), shader, opacity)


## 단색 셰이더(붓결 있음).
func flat(c: Color, amt: float = 0.06) -> Callable:
	return func(x: int, y: int) -> Color: return vary(c, x, y, amt)


## 붓결: 큰 얼룩 + 붓 자국 + 고운 결로 밝기를 흔든다.
func vary(c: Color, x: int, y: int, amt: float) -> Color:
	var v := (nz("lo", x, y) - 0.5) * 1.2 + (nz("mid", x, y) - 0.5) * 0.7 + (nz("hi", x, y) - 0.5) * 0.5
	var out := c.lightened(v * amt) if v > 0.0 else c.darkened(-v * amt)
	out.a = c.a
	return out


func _span_x(poly: PackedVector2Array, sy: float) -> PackedFloat32Array:
	var xs := PackedFloat32Array()
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		if (a.y <= sy and b.y > sy) or (b.y <= sy and a.y > sy):
			xs.append(a.x + (sy - a.y) / (b.y - a.y) * (b.x - a.x))
	xs.sort()
	return xs


func _cover(cov: PackedFloat32Array, x0: int, x1: int, xa: float, xb: float) -> void:
	var ia := maxi(x0, int(floor(xa)))
	var ib := mini(x1, int(floor(xb)))
	for x in range(ia, ib + 1):
		var left := maxf(xa, float(x))
		var right := minf(xb, float(x + 1))
		if right > left:
			cov[x - x0] += right - left


static func rect_poly(x: float, y: float, rw: float, rh: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + rw, y), Vector2(x + rw, y + rh), Vector2(x, y + rh)])


static func poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in pts:
		out.append(v)
	return out


## 위가 둥근(반원) 또는 뾰족한(고딕, 정삼각 아치) 아치 다각형. y = 꼭대기, ah = 전체 높이.
static func arch_poly(x: float, y: float, aw: float, ah: float, pointed: bool = false) -> PackedVector2Array:
	var out := PackedVector2Array([Vector2(x, y + ah)])
	var steps := 16
	if pointed:
		var spring := y + aw * 0.866
		for i in steps + 1:  # 왼쪽 호: 오른쪽 기단을 중심으로
			var a := PI - (PI / 3.0) * i / steps
			out.append(Vector2(x + aw + aw * cos(a), spring - aw * sin(a)))
		for i in range(1, steps + 1):  # 오른쪽 호
			var a := PI / 3.0 - (PI / 3.0) * i / steps
			out.append(Vector2(x + aw * cos(a), spring - aw * sin(a)))
	else:
		var r := aw / 2.0
		for i in steps + 1:
			var a := PI - PI * i / steps
			out.append(Vector2(x + r + cos(a) * r, y + r - sin(a) * r))
	out.append(Vector2(x + aw, y + ah))
	return out


static func bounds(p: PackedVector2Array) -> Rect2:
	var r := Rect2(p[0], Vector2.ZERO)
	for v in p:
		r = r.expand(v)
	return r
