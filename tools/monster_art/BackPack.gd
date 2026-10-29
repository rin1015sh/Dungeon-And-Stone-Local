extends RefCounted
## 등짐(사용자 2026-10-29 "등이 허전 — 추천 1번(배낭 + 말아 묶은 담요)에 2번(비스듬히 멘 칼집·화살통) 합쳐서", AM51 — 후보만):
##   pack {c, roll(담요 색 — 없으면 담요 없음), size, low(담요를 배낭 아래에), lantern(색), flask(색)} 망토 위 가죽 배낭 + 어깨끈
##   sheath {c, hilt(손잡이 색), side: r(오른 어깨 위로 손잡이) | l} 비스듬히 멘 칼집 — 손잡이가 어깨 위로 나온다
##   quiver {c, n(화살 수), fletch(깃 색)} 비스듬히 멘 화살통 — 화살 깃이 어깨 위로
## 몸틀(BackDrape._frame/_w)을 따라 망토 등판 바깥에 빚는다(전투 동작에서 몸을 틀어도 등에 붙어 있게). BackMantle.wear가 부른다.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackDrape := preload("res://tools/monster_art/BackDrape.gd")


## 망토 등판 바깥 깊이(몸 가운데에서 등 쪽, BackDrape ws와 같은 식) — 높이 y에서.
static func _surface(j: Dictionary, bd: Dictionary, under: float, y: float) -> float:
	var ch: Vector3 = j["chest"]
	var pv: Vector3 = j["pelvis"]
	var bw: float = bd["back_w"] - ch.z
	var t := clampf((y - ch.y) / maxf(0.01, pv.y - ch.y), 0.0, 1.0)
	return bw * 0.4 + lerpf(bw * 0.68 + 0.035, bw * 0.64 + 0.064, t) + under


static func wear(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, kit: Dictionary, under: float, rng: RandomNumberGenerator) -> void:
	var f := BackDrape._frame(pr, j)
	if kit.has("sheath"):
		_sheath(cl, pr, j, bd, f, kit["sheath"], under, kit.has("pack"))
	if kit.has("quiver"):
		_quiver(cl, pr, j, bd, f, kit["quiver"], under, kit.has("pack"), rng)
	if kit.has("pack"):
		_pack(cl, pr, j, bd, f, kit["pack"], under, rng)


## 가죽 배낭: 견갑골 사이 ~ 등 가운데에 둥근 상자(몸틀 캡슐) + 덮개 + 쇠고리 둘, 위(또는 아래)에 가로로 말아 묶은 담요, 어깨로 넘어가는 끈 둘.
static func _pack(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, f: Dictionary, d: Dictionary, under: float, rng: RandomNumberGenerator) -> void:
	var col: Color = d["c"]
	var z := float(d.get("size", 1.0))
	var m := cl.mat(col, "leather", {"mottle": col.darkened(0.35), "mottle_amt": 0.4})
	var dark := cl.mat(col.darkened(0.35), "leather")
	var metal := cl.mat(Color("#7a6e58"), "metal")
	var g := cl.group()
	var ch: Vector3 = j["chest"]
	var sy: float = (f["top"] as Vector3).y
	var bv: Vector3 = f["bv"]
	var low: bool = d.get("low", false)
	var top := lerpf(sy, ch.y, 0.45) + (0.0 if low else 0.05 * z)
	var bot := top + 0.2 * z
	var mid := (top + bot) * 0.5
	var dep := 0.045 * z
	var s0 := _surface(j, bd, under, mid) - 0.03  # 망토 등판에 붙게(그대로 재면 비스듬히 볼 때 등에서 떠 보였다)
	# 몸통: 가로 캡슐 셋을 위아래로 쌓아 모서리가 둥근 상자(세로 캡슐 하나는 달걀처럼 보였다)
	var rows := 4  # 촘촘히 겹치고 이음을 부드럽게(셋을 띄워 쌓으면 베개를 쌓은 듯 울퉁불퉁했다)
	for r in rows:
		var y := lerpf(top + dep, bot - dep, r / float(rows - 1))
		Back.cap(cl, pr, g, BackDrape._w(f, j, -0.08 * z, y, s0 + dep), BackDrape._w(f, j, 0.08 * z, y, s0 + dep), dep, dep, m, 0.07)
	# 덮개: 위쪽을 덮는 조금 큰 가로 캡슐 + 아래 끝 골, 덮개 끈 둘과 쇠고리
	var flap := lerpf(top, bot, 0.42)
	var fg := cl.group()
	Back.cap(cl, pr, fg, BackDrape._w(f, j, -0.084 * z, top + dep * 0.9, s0 + dep + 0.006), BackDrape._w(f, j, 0.084 * z, top + dep * 0.9, s0 + dep + 0.006), dep * 1.02, dep * 1.02, m, 0.02)
	Back.groove(cl, pr, fg, [BackDrape._w(f, j, -0.11 * z, flap, s0 + dep * 2.0 + 0.004), BackDrape._w(f, j, 0.11 * z, flap, s0 + dep * 2.0 + 0.004)], bv, 0.005, 0.008)
	for s: float in [-1.0, 1.0]:
		var bk := BackDrape._w(f, j, s * 0.05 * z, flap + 0.004, s0 + dep * 2.0 + 0.008)
		Back.cap(cl, pr, cl.group(), bk + Vector3(0, -0.035 * z, 0), bk, 0.007 * z, 0.007 * z, dark, 0.002)  # 덮개 끈
		Back.ell(cl, pr, cl.group(), bk, 0.009 * z, 0.008 * z, 0.006, metal, 0.002)  # 쇠고리
	for k in 3:  # 가죽 주름·박음질
		var y := lerpf(flap + 0.02, bot - 0.02, (k + 0.5) / 3.0)
		Back.groove(cl, pr, g, [BackDrape._w(f, j, -0.08 * z, y + rng.randf_range(-0.006, 0.006), s0 + dep * 2.0), BackDrape._w(f, j, 0.08 * z, y, s0 + dep * 2.0)], bv, 0.003, 0.004)
	# 어깨끈: 배낭 위 모서리에서 어깨를 넘어 앞으로
	var shw: float = f["shw"]
	for s: float in [-1.0, 1.0]:
		var a := BackDrape._w(f, j, s * 0.07 * z, top + 0.03, s0 + dep * 1.0)
		var b := BackDrape._w(f, j, s * shw * 0.55, sy - 0.012, _surface(j, bd, under, sy) - 0.02)
		var c := BackDrape._w(f, j, s * shw * 0.62, sy + 0.03, 0.0)
		Back.chain(cl, pr, cl.group(), [a, b, c], [0.011, 0.01, 0.01], dark, 0.003)
	if d.has("roll"):  # 말아 묶은 담요: 배낭 위(또는 아래)에 가로로, 묶은 끈 둘
		var rc: Color = d["roll"]
		var rm := cl.mat(rc, "cloth", {"mottle": rc.darkened(0.3), "mottle_amt": 0.4})
		var ry := (bot + 0.028 * z) if low else (top - 0.03 * z)
		var rs := s0 + dep * 1.1  # 배낭 두께 가운데쯤 — 배낭 뒤에 숨지 않게
		var rg := cl.group()
		Back.cap(cl, pr, rg, BackDrape._w(f, j, -0.14 * z, ry, rs), BackDrape._w(f, j, 0.14 * z, ry, rs), 0.034 * z, 0.034 * z, rm, 0.01)
		for s: float in [-1.0, 1.0]:
			var x := s * 0.075 * z
			Back.cap(cl, pr, cl.group(), BackDrape._w(f, j, x, ry - 0.036 * z, rs + 0.004), BackDrape._w(f, j, x, ry + 0.036 * z, rs + 0.004), 0.008 * z, 0.008 * z, dark, 0.002)
		Back.groove(cl, pr, rg, [BackDrape._w(f, j, 0.14 * z, ry - 0.02 * z, rs + 0.03 * z), BackDrape._w(f, j, 0.12 * z, ry + 0.01 * z, rs + 0.034 * z)], bv, 0.004, 0.006)  # 말린 끝
	if d.has("lantern"):  # 배낭 오른쪽에 매단 작은 등
		var lc: Color = d["lantern"]
		var lp := BackDrape._w(f, j, 0.125 * z, mid + 0.02, s0 + dep)
		var lg := cl.group()
		Back.ell(cl, pr, lg, lp, 0.022, 0.03, 0.022, cl.mat(lc, "glow"), 0.004)
		for v: float in [-0.036, 0.034]:
			Back.ell(cl, pr, lg, lp + Vector3(0, v, 0), 0.026, 0.008, 0.026, metal, 0.002)
		Back.cap(cl, pr, lg, lp + Vector3(0, -0.044, 0), lp + Vector3(-0.01, -0.07, 0), 0.003, 0.003, metal, 0.001)
	if d.has("flask"):  # 배낭 왼쪽에 매단 가죽 물통
		var fc: Color = d["flask"]
		var fp := BackDrape._w(f, j, -0.13 * z, mid + 0.03, s0 + dep * 0.8)
		Back.ell(cl, pr, cl.group(), fp, 0.03, 0.042, 0.022, cl.mat(fc, "leather"), 0.006)
		Back.cap(cl, pr, cl.group(), fp + Vector3(0, -0.04, 0), fp + Vector3(0, -0.058, 0), 0.008, 0.008, cl.mat(Color("#4a3424"), "wood"), 0.002)


## 비스듬히 멘 칼집: 한쪽 어깨 위로 손잡이(날밑·자루·자루 끝), 반대쪽 엉덩이로 칼집 끝(쇠 마개). 배낭이 있으면 그 뒤(등 쪽 안)로.
static func _sheath(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, f: Dictionary, d: Dictionary, under: float, behind_pack: bool) -> void:
	var col: Color = d["c"]
	var s := 1.0 if str(d.get("side", "r")) == "r" else -1.0
	var m := cl.mat(col, "leather")
	var metal := cl.mat(Color("#8a8478"), "metal")
	var wood := cl.mat(d.get("hilt", Color("#3a2a1c")), "leather")
	var sy: float = (f["top"] as Vector3).y
	var pv: Vector3 = j["pelvis"]
	var shw: float = f["shw"]
	var lift := 0.012 if behind_pack else 0.03
	var a := BackDrape._w(f, j, s * shw * 0.62, sy - 0.02, _surface(j, bd, under, sy) + lift)  # 칼집 입구(어깨 위)
	var b := BackDrape._w(f, j, -s * shw * 0.75, pv.y + 0.02, _surface(j, bd, under, pv.y) + lift)  # 칼집 끝
	var g := cl.group()
	Back.cap(cl, pr, g, a, b, 0.018, 0.014, m, 0.004)
	Back.ell(cl, pr, g, b + (b - a).normalized() * 0.01, 0.017, 0.017, 0.015, metal, 0.003)  # 끝 마개
	Back.ell(cl, pr, g, a, 0.021, 0.016, 0.02, metal, 0.003)  # 입구 쇠테
	var up := (a - b).normalized()
	var guard := a + up * 0.012
	var side := up.cross(Vector3(0, 0, 1)).normalized()
	var hg := cl.group()
	Back.cap(cl, pr, hg, guard - side * 0.045, guard + side * 0.045, 0.008, 0.008, metal, 0.002)  # 날밑
	Back.cap(cl, pr, hg, guard + up * 0.008, guard + up * 0.085, 0.011, 0.011, wood, 0.002)  # 자루(가죽 감은)
	for k in 4:
		var q := guard + up * (0.02 + k * 0.018)
		Back.cap(cl, pr, hg, q - side * 0.012, q + side * 0.012, 0.003, 0.003, cl.mat(Color("#1e140c"), "leather"), 0.001)
	Back.ell(cl, pr, hg, guard + up * 0.095, 0.016, 0.016, 0.014, metal, 0.003)  # 자루 끝


## 비스듬히 멘 화살통: 한쪽 어깨 위로 화살 깃이 비죽, 가죽 통 + 쇠테 + 바닥.
static func _quiver(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, f: Dictionary, d: Dictionary, under: float, behind_pack: bool, rng: RandomNumberGenerator) -> void:
	var col: Color = d["c"]
	var m := cl.mat(col, "leather", {"mottle": col.darkened(0.3), "mottle_amt": 0.3})
	var rim := cl.mat(col.darkened(0.4), "leather")
	var ch: Vector3 = j["chest"]
	var pv: Vector3 = j["pelvis"]
	var sy: float = (f["top"] as Vector3).y
	var shw: float = f["shw"]
	var lift := 0.045
	# 통 입구 = 오른 어깨 위, 바닥 = 등 가운데 아래로 비스듬히. 배낭이 있으면 배낭 오른쪽 옆에 거의 세워서(배낭 한가운데를 가로지르지 않게)
	var a := BackDrape._w(f, j, shw * (0.62 if behind_pack else 0.5), sy - 0.035, _surface(j, bd, under, sy) + lift)
	var b := BackDrape._w(f, j, shw * (0.42 if behind_pack else -0.2), lerpf(ch.y, pv.y, 0.75), _surface(j, bd, under, pv.y) + lift)
	var g := cl.group()
	Back.cap(cl, pr, g, a, b, 0.036, 0.03, m, 0.006)
	Back.ell(cl, pr, g, a, 0.04, 0.012, 0.038, rim, 0.003)
	Back.ell(cl, pr, g, b, 0.032, 0.01, 0.03, rim, 0.003)
	var up := (a - b).normalized()
	var fl: Color = d.get("fletch", Color("#b8aa90"))
	var shaft := cl.mat(Color("#6a5236"), "wood")
	var feather := cl.mat(fl, "cloth", {"mottle": fl.darkened(0.3), "mottle_amt": 0.4})
	for k in int(d.get("n", 5)):
		var off := Vector3(rng.randf_range(-0.02, 0.02), rng.randf_range(-0.004, 0.004), rng.randf_range(-0.012, 0.012))
		var tip := a + off + up * rng.randf_range(0.05, 0.08)
		var ag := cl.group()
		Back.cap(cl, pr, ag, a + off, tip, 0.004, 0.004, shaft, 0.001)
		Back.cap(cl, pr, ag, tip - up * 0.04, tip, 0.011, 0.007, feather, 0.002)  # 깃
