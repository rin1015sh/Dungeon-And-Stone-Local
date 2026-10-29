extends RefCounted
## 사람형(Back) 야만전사 장구 — 바바리안 옷차림 후보(tools/monster_art/MapLooks.gd b3~b8, 사용자 2026-10-29 "야만전사 느낌으로 여러 개"):
##   harness {c, x: true = 가슴·등에 X자 / false = 왼어깨 → 오른허리 한 줄, ring: 가운데 쇠고리 색} 맨몸 위 가죽 멜빵
##   kilt {c, len(0 = 엉덩이 ~ 1 = 무릎), fur, slits(갈라진 자락 수)} 가죽(털) 띠 치마
##   pauldron {c, side: l|r, kind: leather|iron|skull} 한쪽 어깨받이(skull = 짐승 머리뼈를 얹음)
##   necklace {c, n} 이빨·발톱 목걸이(앞에서 보인다) · paint {c} 팔·얼굴 전투 칠
## kit 키가 없으면 아무것도 하지 않는다.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")


static func wear(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	if kit.has("paint"):
		_paint(cl, pr, j, kit["paint"])
	if kit.has("kilt"):
		_kilt(cl, pr, j, kit["kilt"], rng)
	if kit.has("harness"):
		_harness(cl, pr, j, bd, kit["harness"])
	if kit.has("necklace"):
		_necklace(cl, pr, j, bd, kit["necklace"], rng)
	if kit.has("pauldron"):
		_pauldron(cl, pr, j, bd, kit["pauldron"], rng)


## 앞 표면(가슴 높이)의 몸 좌표 w.
static func _front_w(j: Dictionary, bd: Dictionary) -> float:
	return (j["chest"] as Vector3).z - 0.066 * float(bd["dep"])


## 화면에서 기울어진 띠(몸통 가운데 c를 지나는 기울기 slope, 두께 th — 키 비율).
static func _slant(cl: Clay, pr: Dictionary, c: Vector3, slope: float, th: float) -> PackedVector2Array:
	var H: float = pr["H"]
	var q := Back.P2(pr, c)
	var span := cl.w * 1.0
	var d := th * H * 0.5
	return PackedVector2Array([Vector2(q.x - span, q.y - slope * span - d), Vector2(q.x + span, q.y + slope * span - d),
		Vector2(q.x + span, q.y + slope * span + d), Vector2(q.x - span, q.y - slope * span + d)])


static func _harness(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary) -> void:
	var col: Color = d["c"]
	var m := cl.mat(col, "leather")
	var g := cl.group()
	var ch: Vector3 = j["chest"]
	var c := Vector3(0, ch.y + 0.01, ch.z)
	var slope := 1.15 * absf(cos(float(pr["turn"]))) + 0.35  # 옆에서 보면 몸통 폭이 줄어 더 가파르게
	var slopes: Array = [slope, -slope] if d.get("x", true) else [-slope]
	for s: float in slopes:
		BackKit.shell(cl, pr, ["torso", "shoulder_l", "shoulder_r", "pelvis"], 0.012, m, g, _slant(cl, pr, c, s, 0.03))
	var ring := cl.mat(d.get("ring", Color("#7a7064")), "metal")
	var bw: float = bd["back_w"]
	var fw := _front_w(j, bd)
	if d.get("x", true):  # 가운데 쇠고리(보이는 쪽에만)
		Back.bump(cl, pr, g, Vector3(0, c.y, bw + 0.012), Vector3(0, 0, 1), 0.022, 0.022, 0.012, ring)
		Back.bump(cl, pr, g, Vector3(0, c.y, fw - 0.012), Vector3(0, 0, -1), 0.022, 0.022, 0.012, ring)
	else:  # 버클
		Back.bump(cl, pr, g, Vector3(0.05, c.y + 0.03, fw - 0.012), Vector3(0, 0, -1), 0.016, 0.02, 0.01, ring)


## 띠 치마: 엉덩이에서 단까지 두르고, 단에서 위로 갈라진 틈(띠 자락) + 세로 골.
static func _kilt(cl: Clay, pr: Dictionary, j: Dictionary, d: Dictionary, rng: RandomNumberGenerator) -> void:
	var col: Color = d["c"]
	var fur: bool = d.get("fur", false)
	var m := cl.mat(col, "fur" if fur else "leather", {"mottle": col.darkened(0.35), "mottle_amt": 0.45})
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	var kn := ((j["knee_l"] as Vector3) + (j["knee_r"] as Vector3)) * 0.5
	var hem := lerpf(pv.y + 0.08, kn.y - 0.02, float(d.get("len", 0.6)))
	BackKit.shell(cl, pr, ["pelvis", "thigh_l", "thigh_r"], 0.024 if fur else 0.018, m, g, BackKit.band(cl, pr, pv.y - 0.07, hem, rng, 0.02 if fur else 0.008, 16))
	var top := pv.y - 0.07
	var H: float = pr["H"]
	var slits := int(d.get("slits", 6))
	for k in slits:  # 갈라진 자락: 단에서 위로 좁은 틈
		var u := lerpf(-0.13, 0.13, (k + 0.5) / slits) + rng.randf_range(-0.01, 0.01)
		for w: float in [0.07, -0.08]:
			var a := Back.P2(pr, Vector3(u, hem - 0.01, w))
			cl.erase(g, a, 0.006 * H, rng.randf_range(0.03, 0.05) * H, 0.2)
		Back.groove(cl, pr, g, [Vector3(u, top + 0.04, 0.085), Vector3(u, hem - 0.03, 0.09)], Vector3(0, 0, 1), 0.004, 0.006)
		Back.groove(cl, pr, g, [Vector3(u, top + 0.04, -0.085), Vector3(u, hem - 0.03, -0.09)], Vector3(0, 0, -1), 0.004, 0.006)
	var bm := cl.mat(col.darkened(0.45), "leather")  # 허리 둘레 접힌 단
	BackKit.shell(cl, pr, ["pelvis", "torso"], 0.03, bm, cl.group(), BackKit.band(cl, pr, top - 0.005, top + 0.03), 0.01, 0.002)


## 한쪽 어깨받이: 겹친 판 셋(가죽·쇠) 또는 짐승 머리뼈(skull — 눈구멍 둘·주둥이·송곳니) + 겨드랑이로 도는 끈.
static func _pauldron(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary, rng: RandomNumberGenerator) -> void:
	var t := str(d.get("side", "l"))
	var s := -1.0 if t == "l" else 1.0
	var kind := str(d.get("kind", "leather"))
	var col: Color = d["c"]
	var shp: Vector3 = j["shoulder_" + t]
	var strap := cl.mat(Color("#2e2016"), "leather")
	BackKit.shell(cl, pr, ["upper_" + t], 0.01, strap, cl.group(), BackKit.band(cl, pr, shp.y + 0.075, shp.y + 0.09), 0.004)
	if kind == "skull":
		var bone := cl.mat(col, "bone")
		var dark := cl.mat(Color("#1a0d0b"), "glow")
		var g := cl.group()
		var c := shp + Vector3(s * 0.025, 0.004, 0.0)
		Back.ell(cl, pr, g, c, 0.058, 0.04, 0.062, bone, 0.01)  # 머리뼈 둥근 정수리
		Back.ell(cl, pr, g, c + Vector3(s * 0.05, 0.028, 0.0), 0.04, 0.026, 0.036, bone, 0.008)  # 바깥으로 내민 주둥이
		for f: float in [1.0, -1.0]:  # 등 쪽·가슴 쪽으로 난 눈구멍
			var n := Vector3(s * 0.55, 0.0, f)
			var e := c + Vector3(s * 0.03, 0.006, f * 0.05)
			Back.bump(cl, pr, g, e + Vector3(0, -0.01, 0), n, 0.02, 0.009, 0.006, bone)  # 눈두덩
			Back.bump(cl, pr, g, e + Vector3(0, 0.006, f * 0.006), n, 0.013, 0.012, 0.006, dark)
		for k in 3:  # 송곳니
			var a := c + Vector3(s * (0.06 + k * 0.012), 0.045, (k - 1) * 0.02)
			Back.cap(cl, pr, g, a, a + Vector3(s * 0.004, 0.022, 0.0), 0.006, 0.002, bone, 0.002)
		for k in 2:  # 뿔
			var f := 1.0 if k == 0 else -1.0
			var b := c + Vector3(s * 0.0, -0.03, f * 0.035)
			Back.chain(cl, pr, g, [b, b + Vector3(s * 0.01, -0.035, f * 0.035), b + Vector3(s * 0.04, -0.06, f * 0.05), b + Vector3(s * 0.065, -0.065, f * 0.045)], [0.013, 0.01, 0.006, 0.002], bone, 0.004)
		return
	var m := cl.mat(col, "metal" if kind == "iron" else "leather")
	var rim := cl.mat(col.darkened(0.4), "metal" if kind == "iron" else "leather")
	for k in 3:  # 위에서 아래로 겹친 판(아래 판이 조금 작다)
		var c := shp + Vector3(s * (0.014 + k * 0.008), -0.004 + k * 0.03, 0.0)
		var g := cl.group()
		Back.ell(cl, pr, g, c, 0.064 - k * 0.006, 0.036, 0.062 - k * 0.005, m, 0.006)
		Back.ridge(cl, pr, g, [c + Vector3(-s * 0.03, 0.03, 0.05), c + Vector3(s * 0.04, 0.034, 0.04)], Vector3(0, 0, 1), 0.004, 0.003, rim)
		if kind == "iron":
			for f: float in [1.0, -1.0]:
				Back.bump(cl, pr, g, c + Vector3(s * 0.02, 0.014, f * 0.05), Vector3(0, 0, f), 0.006, 0.006, 0.004, rim)
	if kind == "iron":
		for k in 4:  # 판 위에 박은 가시
			var a := shp + Vector3(s * (0.0 + k * 0.016), -0.03 + k * 0.006, (k % 2 - 0.5) * 0.04)
			Back.cap(cl, pr, cl.group(), a, a + Vector3(s * 0.01, -0.03, 0.0), 0.008, 0.002, m, 0.002)


## 이빨·발톱 목걸이: 목 아래 가슴 앞을 도는 끈에 휜 송곳니가 매달린다(등에선 끈만 목덜미에).
static func _necklace(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary, rng: RandomNumberGenerator) -> void:
	var bone := cl.mat(d.get("c", Color("#c8b898")), "bone")
	var cord := cl.mat(Color("#2a1c12"), "leather")
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var fw := _front_w(j, bd)
	var shw := absf(j["shoulder_r"].x)
	var n := int(d.get("n", 7))
	var pts: Array = []
	for i in 11:
		var a := lerpf(-1.0, 1.0, i / 10.0)
		pts.append(Vector3(a * shw * 0.55, nk.y + 0.03 + 0.07 * (1.0 - a * a), fw - 0.012 + absf(a) * 0.03))
	Back.chain(cl, pr, g, pts, [0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004], cord, 0.002)
	for i in n:
		var a := lerpf(-0.75, 0.75, i / float(max(1, n - 1)))
		var top := Vector3(a * shw * 0.55, nk.y + 0.03 + 0.07 * (1.0 - a * a), fw - 0.016 + absf(a) * 0.03)
		var len := (0.04 if i % 2 == 0 else 0.028) * (1.2 - absf(a) * 0.4)
		Back.chain(cl, pr, g, [top, top + Vector3(a * 0.01, len * 0.6, -0.006), top + Vector3(a * 0.02 + 0.006, len, -0.002)], [0.008, 0.006, 0.0015], bone, 0.002)


## 전투 칠: 두 위팔에 비스듬한 줄 셋 + 얼굴 눈가를 가로지르는 띠(맵 앞모습에서 보인다).
static func _paint(cl: Clay, pr: Dictionary, j: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "skin", {"mottle": col.darkened(0.3), "mottle_amt": 0.5})
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var shp: Vector3 = j["shoulder_" + t]
		var el: Vector3 = j["elbow_" + t]
		for k in 3:
			var c := shp.lerp(el, 0.35 + k * 0.16)
			BackKit.shell(cl, pr, ["upper_" + t], 0.002, m, cl.group(), _slant(cl, pr, c, 0.35 * s, 0.022))
	var hc: Vector3 = j["head"]
	var hh: float = j["head_h"]
	BackKit.shell(cl, pr, ["face"], 0.002, m, cl.group(), _slant(cl, pr, hc + Vector3(0, -hh * 0.02, 0), 0.0, hh * 0.22))
