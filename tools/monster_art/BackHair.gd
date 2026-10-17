extends RefCounted
## 뒷모습 사람형(Back)의 머리카락·수염: 머리선(목덜미 낮게·귀 위·이마 높게)까지 뒤통수를 덮는 겹 + 결 골 + 덥수룩한 뭉치.
## spec 키: hair(short · long · ragged · none) · hair_c · hair_len(긴 머리 길이) · hair_over(등에서 띄움 — 털 망토 위로) · braids(땋은 머리 수) · beard(수염 색)

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")


## 머리카락. kind: short · long · ragged · none. 수염은 beard(색).
static func hair(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, sp: Dictionary, rng: RandomNumberGenerator) -> void:
	var kind := str(sp.get("hair", "short"))
	var col: Color = sp.get("hair_c", Color("#3a2a1e"))
	var m := cl.mat(col, "hair", {"mottle": col.lightened(0.15), "mottle_amt": 0.3})
	if sp.has("beard"):
		_beard(cl, pr, hd, cl.mat(sp["beard"], "hair"))
	if kind == "none":
		return
	var g := cl.group()
	var turn: float = pr["turn"]
	var nape := -0.55 if kind == "short" else -0.75
	var high := float(sp.get("hair_high", 0.0))  # 탐험 맵: 옆·앞 머리선을 올려 얼굴이 보이게(큰 머리에서 머리카락이 얼굴을 덮지 않게)
	var line := PackedVector2Array()
	var lon := turn - PI * 0.5 - 0.3
	while lon <= turn + PI * 0.5 + 0.3:
		line.append(Back.P2(pr, Back.on_head(hd, _hairline(lon, nape, high), lon, 0.012)))
		lon += 0.12
	var top := line[0].y
	var x0 := line[0].x
	var x1 := line[0].x
	for v in line:
		top = minf(top, v.y)
		x0 = minf(x0, v.x)
		x1 = maxf(x1, v.x)
	var H: float = pr["H"]
	line.append(Vector2(x1 + H * 0.1, top - H * 0.2))
	line.append(Vector2(x0 - H * 0.1, top - H * 0.2))
	BackKit.shell(cl, pr, ["skull"], 0.014 if kind != "ragged" else 0.006, m, g, line, 0.01)
	if kind == "ragged":
		for k in 6:
			cl.erase(g, Back.P2(pr, Back.on_head(hd, rng.randf_range(0.0, 1.0), rng.randf_range(-1.6, 1.6), 0.01)), rng.randf_range(0.01, 0.022) * H, rng.randf_range(0.01, 0.02) * H, 0.6)
	else:
		for k in 9:  # 덥수룩한 뭉치
			var la := rng.randf_range(0.25, 1.2)
			var lo := rng.randf_range(-2.1, 2.1)
			if la < _hairline(lo, nape, high) + 0.2:
				continue
			Back.ell(cl, pr, g, Back.on_head(hd, la, lo, -0.004), 0.03, 0.026, 0.03, m, 0.012)
	for k in 22:  # 머리카락 결(정수리 → 아래)
		var lo := lerpf(-2.3, 2.3, (k + rng.randf()) / 22.0)
		var la0 := _hairline(lo, nape, high)
		var pts: Array = []
		for t in 4:
			var la := lerpf(1.35, la0 + 0.05, t / 3.0)
			pts.append(Back.on_head(hd, la, lo + sin(t * 1.3 + k) * 0.08, 0.016))
		Back.groove(cl, pr, g, pts, Back.head_n(0.3, lo), 0.004, 0.006)
	if kind == "long":
		_long(cl, pr, j, bd, hd, sp, m, g, rng)
	elif kind == "ragged":
		for k in 9:  # 늘어진 가는 뭉치
			var lo := rng.randf_range(-1.7, 1.7)
			var a := Back.on_head(hd, rng.randf_range(-0.3, 0.3), lo, 0.004)
			var ln := rng.randf_range(0.04, 0.1)
			Back.chain(cl, pr, g, [a, a + Vector3(sin(lo) * 0.012, ln * 0.5, 0.006), a + Vector3(sin(lo) * 0.02, ln, 0.0)], [0.008, 0.006, 0.002], m, 0.003)


## 머리선 위도(lon: 0 뒤통수 · π 얼굴): 목덜미는 낮게, 귀 위는 귀 높이, 이마는 높게.
static func _hairline(lon: float, nape: float, high: float = 0.0) -> float:
	var a := absf(wrapf(lon, -PI, PI))
	var up := high * smoothstep(0.7, 1.7, a)
	if a < PI * 0.5:
		return lerpf(nape, 0.05, a / (PI * 0.5)) + up
	if a < 2.25:
		return lerpf(0.05, 0.28, (a - PI * 0.5) / (2.25 - PI * 0.5)) + up
	return lerpf(0.28, 0.62, (a - 2.25) / (PI - 2.25)) + up


## 긴 머리: 뒤통수에서 등 위로 흘러내린 머리 타래 + 땋은 머리.
static func _long(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, sp: Dictionary, m: int, g: int, rng: RandomNumberGenerator) -> void:
	var B := Vector3(0, 0, 1)
	var nk: Vector3 = j["neck"]
	var bw: float = bd["back_w"]
	var ln := float(sp.get("hair_len", 0.16))
	for k in 6:
		var lo := lerpf(-0.8, 0.8, (k + rng.randf_range(0.2, 0.8)) / 6.0)
		var a := Back.on_head(hd, rng.randf_range(-0.35, 0.1), lo, 0.004)
		var b := Vector3(a.x * 1.2 + rng.randf_range(-0.01, 0.01), nk.y + ln * rng.randf_range(0.7, 1.0), bw + float(sp.get("hair_over", 0.016)))
		var mid := a.lerp(b, 0.45) + Vector3(0, 0, 0.012)
		Back.chain(cl, pr, g, [a, mid, b], [0.02, 0.016, 0.005], m, 0.008)
		Back.groove(cl, pr, g, [a.lerp(mid, 0.3), mid, b.lerp(mid, 0.2)], B, 0.0035, 0.005)
	var tie := cl.mat(Color("#4a3020"), "leather")
	for i in int(sp.get("braids", 0)):
		var s := -1.0 if i % 2 == 0 else 1.0
		var a := Back.on_head(hd, -0.25, s * 1.15, 0.006)
		var pts: Array = []
		for t in 9:
			var q := a.lerp(Vector3(s * 0.07, nk.y + ln * 1.15, bw + float(sp.get("hair_over", 0.016)) + 0.01), t / 8.0)
			pts.append(q + Vector3(s * sin(t * 0.7) * 0.006, 0, 0.004))
		for t in pts.size():
			Back.ell(cl, pr, g, pts[t] + Vector3(0.004 * (1 if t % 2 == 0 else -1), 0, 0), 0.012, 0.013, 0.011, m, 0.004)
		var end: Vector3 = pts[pts.size() - 1]
		Back.ell(cl, pr, g, end + Vector3(0, 0.012, 0.004), 0.011, 0.008, 0.01, tie, 0.002)
		Back.chain(cl, pr, g, [end + Vector3(0, 0.018, 0), end + Vector3(s * 0.004, 0.04, 0.002)], [0.009, 0.003], m, 0.003)


## 수염: 턱·턱끝을 덮는 덩어리 + 구레나룻(옆모습에서 보인다).
static func _beard(cl: Clay, pr: Dictionary, hd: Dictionary, m: int) -> void:
	var g := cl.group()
	var c: Vector3 = hd["c"]
	var ru: float = hd["ru"]
	var rv: float = hd["rv"]
	var rw: float = hd["rw"]
	Back.ell(cl, pr, g, c + Vector3(0, rv * 0.78, -rw * 0.5), ru * 0.86, rv * 0.5, rw * 0.72, m, 0.01)
	Back.ell(cl, pr, g, c + Vector3(0, rv * 1.08, -rw * 0.72), ru * 0.5, rv * 0.32, rw * 0.36, m, 0.01)
	for s: int in [-1, 1]:
		Back.cap(cl, pr, g, c + Vector3(s * ru * 0.9, rv * 0.05, -rw * 0.12), c + Vector3(s * ru * 0.75, rv * 0.62, -rw * 0.4), ru * 0.2, ru * 0.3, m, 0.008)
		for k in 4:
			var a := c + Vector3(s * ru * (0.3 + k * 0.15), rv * 0.5, -rw * (0.8 - k * 0.1))
			Back.groove(cl, pr, g, [a, a + Vector3(0, rv * 0.5, -rw * 0.05)], Vector3(s * 0.6, 0.3, -0.8), 0.003, 0.005)
