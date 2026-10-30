extends RefCounted
## 뒷모습 사람형(아군 — 탐험가·소환수가 전투 무대 아래 앞줄에 등을 보이고 선다): 몸 기준 3D 좌표에 뼈대·근육 덩어리를 놓고
## 몸을 turn(라디안)만큼 돌려 화면에 투영한다. 좌표(키 비율): u = 몸의 오른쪽 · v = 아래(화면 y) · w = 등 쪽(뒷모습에서 보는 사람 쪽).
## turn 0 = 등을 정면으로, 1.1 안팎 = 오른쪽(적)을 보며 비스듬히 돌아선 옆모습(오른 옆구리·옆얼굴이 보인다).
## 캡슐은 돌려도 정확하고, 타원체는 돌린 폭으로 근사한다. 옷·장구는 BackKit·BackGear, 설계는 Party.
## spec 키: height · turn · build(thin|slender|normal|muscular|brute) · bulk · sh(어깨 반폭) · head(머리 크기) · skin · shade · mottle · nail
##          pose{stance(발 벌림) · knee · hunch(앞으로 숙임) · arm_l/arm_r(hang|rest|ready|forward|spear|shield|down|slump)}

const Clay := preload("res://tools/monster_art/Clay.gd")

## 굵기(키 비율): 위팔 · 아래팔 시작/끝 · 허벅지 시작/끝 · 종아리 · 몸통 깊이 배율 · 허리 반폭
const BUILDS := {
	"thin": [0.021, 0.019, 0.012, 0.036, 0.021, 0.022, 0.8, 0.062],
	"slender": [0.024, 0.022, 0.0135, 0.046, 0.026, 0.027, 0.9, 0.056],  # 여성 탐험가 후보(RaceParts — 마른 몸 thin의 갈비·척추 마디는 없다)
	"normal": [0.029, 0.026, 0.016, 0.05, 0.03, 0.032, 1.0, 0.078],
	"muscular": [0.035, 0.031, 0.018, 0.056, 0.033, 0.036, 1.08, 0.084],
	"brute": [0.042, 0.037, 0.022, 0.062, 0.037, 0.04, 1.18, 0.094],
}


## 투영 정보: 발 가운데(화면) · 키(px) · 돌림 · pitch(위에서 내려다보는 정도 — 보는 사람 쪽 깊이만큼 화면 아래로. 전투 그림은 0,
## 탐험 맵 걷기 그림은 3/4 시점이라 앞으로 내민 발이 아래에 보이게 — tools/paint_actors.gd).
static func proj(o: Vector2, H: float, turn: float, pitch: float = 0.0) -> Dictionary:
	return {"ox": o.x, "oy": o.y, "H": H, "c": cos(turn), "s": sin(turn), "turn": turn, "pitch": pitch}


## 몸 좌표(키 비율) → 화면(px, z = 보는 사람 쪽). roll이 있으면(누운 몸 — tools/paint_motions.gd 쓰러짐) 화면에서 발 자리를 축으로 통째로 돌린다.
static func P(pr: Dictionary, v: Vector3) -> Vector3:
	var c: float = pr["c"]
	var s: float = pr["s"]
	var H: float = pr["H"]
	var toward := v.x * s + v.z * c
	var q := roll2(pr, Vector2(float(pr["ox"]) + H * (v.x * c - v.z * s), float(pr["oy"]) + H * (v.y + toward * float(pr.get("pitch", 0.0)))))
	return Vector3(q.x, q.y, H * toward)


## 화면 점 하나를 roll만큼(발 자리 축 + shift). roll이 없으면 그대로.
static func roll2(pr: Dictionary, q: Vector2) -> Vector2:
	var r := float(pr.get("roll", 0.0))
	if r == 0.0:
		return q
	var o := Vector2(float(pr["ox"]), float(pr["oy"]))
	return o + (q - o).rotated(r) + (pr.get("shift", Vector2.ZERO) as Vector2)


static func roll_poly(pr: Dictionary, pts: PackedVector2Array) -> PackedVector2Array:
	if float(pr.get("roll", 0.0)) == 0.0:
		return pts
	var out := PackedVector2Array()
	for q in pts:
		out.append(roll2(pr, q))
	return out


static func P2(pr: Dictionary, v: Vector3) -> Vector2:
	var q := P(pr, v)
	return Vector2(q.x, q.y)


## 몸 좌표 방향 n이 보는 사람 쪽을 향하는 정도(-1~1).
static func facing(pr: Dictionary, n: Vector3) -> float:
	var nn := n.normalized()
	return nn.x * float(pr["s"]) + nn.z * float(pr["c"])


static func cap(cl: Clay, pr: Dictionary, g: int, a: Vector3, b: Vector3, ra: float, rb: float, m: int, k: float = 0.008) -> void:
	var H: float = pr["H"]
	cl.cap(g, P(pr, a), P(pr, b), ra * H, rb * H, m, k * H)


static func chain(cl: Clay, pr: Dictionary, g: int, pts: Array, radii: Array, m: int, k: float = 0.008) -> void:
	for i in pts.size() - 1:
		cap(cl, pr, g, pts[i], pts[i + 1], radii[i], radii[i + 1], m, k)


## 타원체(몸 좌표 반지름 ru·rv·rw — 돌리면 화면 폭·깊이를 섞어 근사). rot = 화면에서 기울임.
static func ell(cl: Clay, pr: Dictionary, g: int, c: Vector3, ru: float, rv: float, rw: float, m: int, k: float = 0.008, rot: float = 0.0) -> void:
	var H: float = pr["H"]
	var cc: float = pr["c"]
	var ss: float = pr["s"]
	var rx := sqrt(pow(ru * cc, 2.0) + pow(rw * ss, 2.0))
	var rz := sqrt(pow(ru * ss, 2.0) + pow(rw * cc, 2.0))
	cl.ell(g, P(pr, c), rx * H, rv * H, rz * H, m, k * H, rot + float(pr.get("roll", 0.0)))


## 보이는 쪽(n)에서만: 골 · 줄 · 혹.
static func groove(cl: Clay, pr: Dictionary, g: int, pts: Array, n: Vector3, width: float, depth: float) -> void:
	var f := facing(pr, n)
	if f < 0.15:
		return
	var H: float = pr["H"]
	var sp: Array = []
	for v: Vector3 in pts:
		sp.append(P2(pr, v))
	cl.grooves(g, sp, width * H, depth * H * minf(1.0, f * 1.5))


static func ridge(cl: Clay, pr: Dictionary, g: int, pts: Array, n: Vector3, r: float, rise: float, m: int) -> void:
	if facing(pr, n) < 0.1:
		return
	var H: float = pr["H"]
	var sp: Array = []
	for v: Vector3 in pts:
		sp.append(P2(pr, v))
	cl.ridge(g, sp, r * H, rise * H, m)


static func bump(cl: Clay, pr: Dictionary, g: int, c: Vector3, n: Vector3, rx: float, ry: float, rise: float, m: int, rot: float = 0.0) -> void:
	var f := facing(pr, n)
	if f < 0.1:
		return
	var H: float = pr["H"]
	var q := P2(pr, c)
	cl.bump(g, q, rx * H * lerpf(0.5, 1.0, f), ry * H, rise * H * f, m, 3.0, rot + float(pr.get("roll", 0.0)))


## 뼈대(몸 좌표). 팔 자세: hang(조금 벌려 늘어뜨림) · rest(붙여 내림) · ready(팔꿈치 굽혀 주먹을 앞으로) · forward(두 팔을 앞으로 뻗음)
## · spear(창을 세워 쥠) · shield(방패를 앞으로).
static func skeleton(sp: Dictionary) -> Dictionary:
	var pose: Dictionary = sp.get("pose", {})
	var stance := float(pose.get("stance", 0.085))
	var knee := float(pose.get("knee", 0.15))
	var hunch := float(pose.get("hunch", 0.0))
	var sh := float(sp.get("sh", 0.125))
	var j := {}
	var hip_y := -0.49 + knee * 0.025 + hunch * 0.01
	j["pelvis"] = Vector3(0, hip_y, 0)
	j["waist"] = Vector3(0, hip_y - 0.105, -hunch * 0.03)
	j["chest"] = Vector3(0, hip_y - 0.215 + hunch * 0.02, -hunch * 0.08)
	j["neck"] = Vector3(0, hip_y - 0.345 + hunch * 0.05, -hunch * 0.13)
	j["head_h"] = 0.13 * float(sp.get("head", 1.0))
	j["head"] = Vector3(0, j["neck"].y - 0.072 + hunch * 0.02, j["neck"].z - 0.012 - hunch * 0.05)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var an := Vector3(s * stance, -0.045, 0.0)
		j["ankle_" + t] = an
		j["hip_" + t] = Vector3(s * 0.062, hip_y + 0.02, 0.0)
		j["knee_" + t] = Vector3(s * (stance * 0.8 + 0.012), lerpf(hip_y, -0.045, 0.5), -0.015 - knee * 0.06)
		j["toe_" + t] = an + Vector3(s * 0.012, 0.03, -0.1)
		var shp := Vector3(s * sh, hip_y - 0.325 + hunch * 0.04, -hunch * 0.09)
		j["shoulder_" + t] = shp
		var el: Vector3
		var wr: Vector3
		match str(pose.get("arm_" + t, "hang")):
			"rest":
				el = shp + Vector3(s * 0.012, 0.165, 0.0)
				wr = el + Vector3(s * 0.004, 0.152, -0.022)
			"ready":
				el = shp + Vector3(s * 0.055, 0.145, 0.035)
				wr = el + Vector3(-s * 0.035, 0.07, -0.13)
			"forward":
				el = shp + Vector3(s * 0.035, 0.1, -0.12)
				wr = el + Vector3(s * 0.005, -0.005, -0.15)
			"spear":
				el = shp + Vector3(s * 0.05, 0.15, 0.0)
				wr = el + Vector3(s * 0.02, 0.085, -0.1)
			"shield":
				el = shp + Vector3(s * 0.07, 0.125, -0.03)
				wr = el + Vector3(-s * 0.03, 0.03, -0.14)
			"down":  # 탐험 맵 탐험가(사용자 2026-10-26 "가만히 있을 때 팔을 완전히 아래로 — 살짝 앞에 있어 좀비 같다"): 몸 옆으로 곧게
				el = shp + Vector3(s * 0.03, 0.155, 0.0)
				wr = el + Vector3(s * 0.006, 0.145, -0.006)
			"slump":  # 탐험 맵: 어깨를 늘어뜨리고 팔꿈치를 살짝 굽혀 손이 허벅지 앞에
				el = shp + Vector3(s * 0.02, 0.15, -0.03)
				wr = el + Vector3(-s * 0.012, 0.135, -0.05)
			_:
				el = shp + Vector3(s * 0.035, 0.16, 0.012)
				wr = el + Vector3(s * 0.016, 0.15, -0.035)
		j["elbow_" + t] = el
		j["wrist_" + t] = wr
		j["hand_" + t] = wr + (wr - el).normalized() * 0.035
	return _chunky(j, sp, hip_y)


## 탐험 맵 몸 비율(피어 앤 헝거 맵 그림 — 약간 큰 머리·짧고 굵은 몸, tools/paint_actors.gd): legs = 다리 길이 배율(발은 그대로,
## 위 몸은 그만큼 내려온다), wide = 가로 배율, head(spec)로 커진 머리는 목 위로 올린다. 전투 그림은 모두 1이라 그대로.
static func _chunky(j: Dictionary, sp: Dictionary, hip_y: float) -> Dictionary:
	var lf := float(sp.get("legs", 1.0))
	var wd := float(sp.get("wide", 1.0))
	if lf == 1.0 and wd == 1.0 and float(sp.get("head", 1.0)) == 1.0 and not sp.get("map_face", false) and not sp.get("socket_eyes", false):
		return j
	for k: String in j:
		if j[k] is Vector3:
			var v: Vector3 = j[k]
			v.x *= wd
			v.y = v.y * lf if v.y > hip_y else v.y - hip_y * (1.0 - lf)
			j[k] = v
	j["head"] = j["head"] - Vector3(0, (float(j["head_h"]) - 0.13) * 0.4, 0)
	j["map_face"] = bool(sp.get("map_face", false))
	j["socket_eyes"] = bool(sp.get("socket_eyes", false))
	j["face_lift"] = float(sp.get("face_lift", 0.0))
	j["ears"] = str(sp.get("ears", ""))
	if j["map_face"]:  # 굵어진 가슴·망토가 턱을 덮지 않게 머리를 조금 앞으로
		j["head"] = j["head"] + Vector3(0, 0, -0.015)
	return j


## 걷기 한 칸(탐험 맵 걷기 그림 — tools/paint_actors.gd): phase −1~1. +1 = 왼발이 앞·오른발 뒤꿈치를 들고·오른팔이 앞, −1 = 반대, 0 = 섬(그대로).
## 몸 좌표에서 앞 = −w(z 음수). 팔다리는 어깨·엉덩이를 축으로 마디마다 각도를 정해 돌린다(길이 그대로 — 무릎이 뒤로 꺾이거나 손만 뻗지 않게).
## 각도는 옆에서 본 수직(아래)에서 앞(+)·뒤(−), 도 단위의 "걸음 칸 값"이고 phase 크기만큼 선 자세에서 옮겨 간다. 몸 높이는 맨 아래 발이 땅에 닿게 저절로 내려간다(걸음 칸이 낮다).
##   g: thigh_f/shin_f 앞다리 · thigh_b/shin_b 뒷다리 · lift 반걸음 칸에서 지나가는 뒷다리 무릎 들기(도) · twist 앞으로 간 팔 쪽 어깨가 나오는 양(키 비율)
##      arm_f/fore_f 앞으로 간 팔의 위팔/아래팔 각 · arm_b/fore_b 뒤로 간 팔
static func stride(j: Dictionary, phase: float, g: Dictionary) -> Dictionary:
	if is_zero_approx(phase):
		return j
	var out := j.duplicate()
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var k := phase * (1.0 if s < 0 else -1.0)  # 이 다리가 앞(+) 뒤(−)
		var h: Vector3 = j["hip_" + t]
		var k0: Vector3 = j["knee_" + t]
		var a0: Vector3 = j["ankle_" + t]
		var th0 := _ang(k0 - h)
		var sh0 := _ang(a0 - k0)
		var key := "_f" if k > 0.0 else "_b"
		var m := absf(k)
		var psg := 4.0 * m * (1.0 - m) * (1.0 if k < 0.0 else 0.0)  # 지나가는 다리(뒤 → 앞): 반걸음에서 가장 크다
		var th := lerpf(th0, float(g.get("thigh" + key, th0)), m) + float(g.get("lift", 0.0)) * 0.5 * psg
		var sn := lerpf(sh0, float(g.get("shin" + key, sh0)), m) - float(g.get("lift", 0.0)) * psg
		var kn := h + _swing(k0 - h, deg_to_rad(th - th0))
		var an := kn + _swing(a0 - k0, deg_to_rad(sn - sh0))
		out["knee_" + t] = kn
		out["ankle_" + t] = an
	var ground := maxf((j["ankle_l"] as Vector3).y, (j["ankle_r"] as Vector3).y)
	var low := maxf((out["ankle_l"] as Vector3).y, (out["ankle_r"] as Vector3).y)
	for s: int in [-1, 1]:  # 발끝: 뒤꿈치를 든 발은 끝을 땅에 대고, 앞발은 끝을 살짝 든다
		var t := "l" if s < 0 else "r"
		var an: Vector3 = out["ankle_" + t]
		var f0: Vector3 = (j["toe_" + t] as Vector3) - (j["ankle_" + t] as Vector3)
		var dy := clampf(f0.y + (ground - (an.y + ground - low)), -absf(f0.z) * 0.9, absf(f0.z) * 0.9)
		var fz := -sqrt(maxf(0.0, f0.z * f0.z + f0.y * f0.y - dy * dy))
		var heel_strike := 0.012 if (phase * (1.0 if s < 0 else -1.0)) > 0.0 else 0.0
		out["toe_" + t] = an + Vector3(f0.x, dy - heel_strike, fz)
	var drop := ground - low  # 몸 전체를 내려 맨 아래 발을 땅에
	for key2: String in out:
		if out[key2] is Vector3:
			out[key2] = (out[key2] as Vector3) + Vector3(0, drop, 0)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var a := -phase * (1.0 if s < 0 else -1.0)  # 팔은 같은 쪽 다리와 반대로
		var fwd := a > 0.0
		var au := deg_to_rad(float(g.get("arm_f" if fwd else "arm_b", 0.0))) * absf(a)
		var af := deg_to_rad(float(g.get("fore_f" if fwd else "fore_b", 0.0))) * absf(a)
		var sh: Vector3 = (out["shoulder_" + t] as Vector3) + Vector3(0, 0, -a * float(g.get("twist", 0.0)))
		var el: Vector3 = sh + _swing((j["elbow_" + t] as Vector3) - (j["shoulder_" + t] as Vector3), au)
		var wr: Vector3 = el + _swing((j["wrist_" + t] as Vector3) - (j["elbow_" + t] as Vector3), au + af)
		out["shoulder_" + t] = sh
		out["elbow_" + t] = el
		out["wrist_" + t] = wr
		out["hand_" + t] = wr + _swing((j["hand_" + t] as Vector3) - (j["wrist_" + t] as Vector3), au + af)
	return out


## 옆에서 본 각(도): 수직 아래 = 0, 앞(−z) = +.
static func _ang(v: Vector3) -> float:
	return rad_to_deg(atan2(-v.z, v.y))


## 옆에서 본 면(y 아래·−z 앞)에서 벡터를 앞으로 a라디안 돌린다(x는 그대로).
static func _swing(v: Vector3, a: float) -> Vector3:
	var w := -v.z
	return Vector3(v.x, -w * sin(a) + v.y * cos(a), -(w * cos(a) + v.y * sin(a)))


## 몸: 엉덩이·허리·등(견갑골·척추 골·광배근) · 목·승모근 · 어깨 · 다리(햄스트링·종아리·발뒤꿈치) · 팔(삼두·팔꿈치·주먹).
## 돌려주는 값: 그룹(torso·arm_l·arm_r) · 굵기 · 등 표면 깊이.
static func body(cl: Clay, pr: Dictionary, j: Dictionary, sp: Dictionary, skin: int, nail: int) -> Dictionary:
	var build := str(sp.get("build", "normal"))
	var t: Array = BUILDS.get(build, BUILDS["normal"])
	var bulk := float(sp.get("bulk", 1.0))
	var dep := float(t[6]) * bulk
	var thin := build == "thin"
	var big := build in ["muscular", "brute"]
	var out := {"torso": cl.group(), "arm_l": cl.group(), "arm_r": cl.group(), "dep": dep, "bulk": bulk, "build": build}
	var g: int = out["torso"]
	var B := Vector3(0, 0, 1)  # 등이 향하는 쪽
	var pv: Vector3 = j["pelvis"]
	var wa: Vector3 = j["waist"]
	var ch: Vector3 = j["chest"]
	var nk: Vector3 = j["neck"]
	var shw := absf((j["shoulder_r"] as Vector3).x - (j["shoulder_l"] as Vector3).x) * 0.5  # 어깨 반폭(몸을 옆으로 옮긴 칸에서도 — 오른 어깨 x만 재면 한쪽이 부풀었다)
	out["back_w"] = ch.z + 0.066 * dep  # 등 표면(가슴 높이)
	# 다리(몸통과 녹여 붙인다)
	for s: int in [-1, 1]:
		var tg := "l" if s < 0 else "r"
		var hp: Vector3 = j["hip_" + tg]
		var kn: Vector3 = j["knee_" + tg]
		var an: Vector3 = j["ankle_" + tg]
		cl.tag = "thigh_" + tg
		cap(cl, pr, g, hp + Vector3(0, 0.01, 0), kn, float(t[3]) * bulk, float(t[4]) * bulk, skin, 0.012)
		cl.tag = "shin_" + tg
		ell(cl, pr, g, kn + Vector3(0, 0, 0.006), 0.028 * bulk, 0.03, 0.026 * bulk, skin, 0.01)
		cap(cl, pr, g, kn, an, float(t[4]) * bulk * 0.95, 0.019 * bulk, skin, 0.01)
		ell(cl, pr, g, kn.lerp(an, 0.3) + Vector3(0, 0, 0.012), float(t[5]) * bulk, 0.068, float(t[5]) * bulk * 0.85, skin, 0.012)  # 종아리
		cl.tag = "foot_" + tg
		ell(cl, pr, g, an + Vector3(0, 0.022, 0.018), 0.021, 0.022, 0.02, skin, 0.006)  # 발뒤꿈치
		cap(cl, pr, g, an + Vector3(0, 0.025, 0.0), j["toe_" + tg], 0.022, 0.017, skin, 0.006)
		cl.tag = "thigh_" + tg
		if not thin:
			bump(cl, pr, g, hp.lerp(kn, 0.5) + Vector3(0, 0, 0.04), B, 0.03 * bulk, 0.08, 0.006, skin)  # 햄스트링
		cl.tag = ""
		groove(cl, pr, g, [kn + Vector3(-0.02, -0.01, 0.03), kn + Vector3(0, 0.005, 0.034), kn + Vector3(0.02, -0.01, 0.03)], B, 0.005, 0.006)  # 오금
		groove(cl, pr, g, [an + Vector3(0, -0.07, 0.022), an + Vector3(0, 0.0, 0.02)], Vector3(s * 0.3, 0, 1), 0.004, 0.004)  # 아킬레스
	# 몸통
	cl.tag = "pelvis"
	ell(cl, pr, g, pv, 0.1 * bulk, 0.062, 0.06 * dep, skin, 0.03)
	for s: int in [-1, 1]:
		ell(cl, pr, g, pv + Vector3(s * 0.046 * bulk, 0.035, 0.022), 0.056 * bulk, 0.06, 0.048 * dep, skin, 0.02)  # 엉덩이
	cl.tag = "torso"
	ell(cl, pr, g, wa, float(t[7]) * bulk, 0.09, 0.056 * dep, skin, 0.035)
	ell(cl, pr, g, ch, shw * 0.84, 0.112, 0.066 * dep, skin, 0.035)
	ell(cl, pr, g, ch + Vector3(0, -0.068, 0.0), shw * 0.97, 0.055, 0.06 * dep, skin, 0.03)
	for s: int in [-1, 1]:
		var lift := _arm_lift(j, "l" if s < 0 else "r")  # 팔을 들면 광배근을 안으로 좁힌다(늘어뜨린 팔이 가리던 옆구리에 둥근 혹이 드러났다)
		ell(cl, pr, g, ch + Vector3(s * shw * lerpf(0.55, 0.38, lift), 0.02, 0.012), shw * lerpf(0.42, 0.16, lift), 0.085, 0.048 * dep * lerpf(1.0, 0.45, lift), skin, 0.025, s * 0.18 * (1.0 - lift))  # 광배근(팔을 들면 가슴 윤곽 안으로)
		cap(cl, pr, g, nk + Vector3(0, 0.008, 0.012), j["shoulder_" + ("l" if s < 0 else "r")] + Vector3(-s * 0.012, -0.004, 0.0), (0.024 if thin else 0.032) * bulk, 0.022 * bulk, skin, 0.03)  # 승모근
	cl.tag = "neck"
	cap(cl, pr, g, nk + Vector3(0, 0.01, 0.004), j["head"] + Vector3(0, 0.035, 0.012), (0.024 if thin else 0.03) * bulk, 0.026 * bulk, skin, 0.02)
	for s: int in [-1, 1]:  # 어깨세모근
		cl.tag = "shoulder_" + ("l" if s < 0 else "r")
		var side := "l" if s < 0 else "r"
		var sj: Vector3 = j["shoulder_" + side]
		var up_dir := ((j["elbow_" + side] as Vector3) - sj).normalized()  # 위팔 쪽으로(팔을 들면 따라 올라간다 — 관절 아래 고정이면 겨드랑이에 혹이 생겼다)
		ell(cl, pr, g, sj + Vector3(s * 0.006, 0.0, 0.0) + up_dir * 0.028, 0.03 * bulk, lerpf(0.048, 0.036, _arm_lift(j, side)), 0.032 * bulk, skin, 0.03)
	# 등 근육 · 뼈 결(옷 겹이 덮도록 몸통 부위로 기록)
	cl.tag = "torso"
	var bw: float = out["back_w"]
	for s: int in [-1, 1]:  # 등 결은 지금 자리의 가슴·허리·골반을 따른다(쉰 자세 x에 두면 몸을 옆으로 옮긴 회피 칸에서 몸 밖에 떠 보였다 — AM53)
		var sc := Vector3(ch.x + s * shw * 0.42, ch.y - 0.035, bw)
		bump(cl, pr, g, sc, B, 0.036, 0.05, 0.012 if thin else 0.007, skin, -s * 0.15)  # 견갑골
		groove(cl, pr, g, [sc + Vector3(-s * 0.03, -0.04, 0), sc + Vector3(-s * 0.036, 0.0, 0), sc + Vector3(-s * 0.02, 0.05, 0)], B, 0.006, 0.007)
		groove(cl, pr, g, [Vector3(ch.x + s * shw * 0.7, ch.y - 0.02, bw - 0.01), Vector3(wa.x + s * shw * 0.6, wa.y - 0.02, bw - 0.012), Vector3(wa.x + s * 0.06, wa.y + 0.05, bw - 0.02)], Vector3(s * 0.5, 0, 1), 0.006, 0.006 if big else 0.004)  # 광배근 아래 골
		if not thin:
			bump(cl, pr, g, Vector3(wa.x + s * 0.024, wa.y + 0.01, ch.z + 0.056 * dep), B, 0.02, 0.07, 0.006, skin)  # 척추세움근
	groove(cl, pr, g, [Vector3(nk.x, nk.y + 0.03, bw - 0.01), Vector3(ch.x, ch.y, bw), Vector3(wa.x, wa.y, ch.z + 0.056 * dep), Vector3(pv.x, pv.y - 0.01, pv.z + 0.05 * dep)], B, 0.006, 0.009 if big else 0.006)  # 척추 골
	groove(cl, pr, g, [Vector3(pv.x, pv.y - 0.005, pv.z + 0.05 * dep), Vector3(pv.x, pv.y + 0.075, pv.z + 0.06 * dep)], B, 0.005, 0.008)  # 엉덩이 골
	for s: int in [-1, 1]:
		groove(cl, pr, g, [Vector3(s * 0.005, pv.y + 0.09, 0.05), Vector3(s * 0.05, pv.y + 0.098, 0.05), Vector3(s * 0.09, pv.y + 0.085, 0.04)], B, 0.005, 0.006)
	if thin:
		for k in 6:  # 척추 마디 · 등 갈비
			var y := nk.y + 0.04 + k * 0.035
			bump(cl, pr, g, Vector3(0, y, bw), B, 0.008, 0.009, 0.006, skin)
			if k > 0 and k < 5:
				for s: int in [-1, 1]:
					groove(cl, pr, g, [Vector3(s * 0.02, y + 0.01, bw), Vector3(s * shw * 0.5, y + 0.02, bw - 0.01), Vector3(s * shw * 0.8, y + 0.04, bw - 0.03)], Vector3(s * 0.4, 0, 1), 0.0045, 0.006)
	cl.tag = ""
	# 팔(spec arm_under = 위팔·아래팔 살갗 대신 칠할 색 — 소매 사이로 팔 안쪽 살이 드러나지 않게, 손은 살갗 그대로 — AM57)
	var hand_skin := skin
	if sp.has("arm_under"):
		skin = cl.mat(sp["arm_under"], "cloth")
	for s: int in [-1, 1]:
		var tg := "l" if s < 0 else "r"
		var ga: int = out["arm_" + tg]
		var shp: Vector3 = j["shoulder_" + tg]
		var el: Vector3 = j["elbow_" + tg]
		var wr: Vector3 = j["wrist_" + tg]
		var hd: Vector3 = j["hand_" + tg]
		cl.tag = "upper_" + tg
		cap(cl, pr, ga, shp + Vector3(s * 0.012, 0.03, 0.0), el, float(t[0]) * bulk, float(t[0]) * bulk * 0.8, skin, 0.01)
		cl.tag = "fore_" + tg
		ell(cl, pr, ga, el + Vector3(0, 0, 0.008), float(t[1]) * bulk * 0.9, float(t[1]) * bulk * 0.9, float(t[1]) * bulk, skin, 0.006)
		cap(cl, pr, ga, el, wr, float(t[1]) * bulk, float(t[2]) * bulk, skin, 0.01)
		cl.tag = "hand_" + tg
		var dr := (hd - wr).normalized()
		ell(cl, pr, ga, wr.lerp(hd, 0.55), 0.021 * bulk, 0.026, 0.02 * bulk, hand_skin, 0.006)
		cap(cl, pr, ga, wr.lerp(hd, 0.25) + Vector3(-s * 0.012, 0, -0.012), hd + Vector3(-s * 0.012, -0.005, -0.016), 0.008 * bulk, 0.007 * bulk, hand_skin, 0.004)  # 엄지
		ridge(cl, pr, ga, [hd + Vector3(-0.016, 0, 0.004), hd + Vector3(0.0, 0.004, 0.008), hd + Vector3(0.016, 0, 0.004)], B + dr, 0.006 * bulk, 0.004, hand_skin)  # 주먹 마디
		var out_n := Vector3(s * 0.6, 0, 1)
		cl.tag = "upper_" + tg
		if not thin:
			bump(cl, pr, ga, shp.lerp(el, 0.5) + Vector3(s * 0.005, 0, float(t[0]) * bulk), out_n, float(t[0]) * bulk * 0.9, 0.06, 0.008 if big else 0.005, skin)  # 삼두
		cl.tag = "fore_" + tg
		bump(cl, pr, ga, el.lerp(wr, 0.25) + Vector3(s * 0.006, 0, float(t[1]) * bulk), out_n, float(t[1]) * bulk, 0.05, 0.004, skin)
		if thin:
			ridge(cl, pr, ga, [el, wr], out_n, float(t[2]) * 0.4, float(t[2]) * 0.25, skin)
		cl.tag = ""
	skin = hand_skin
	out["nail"] = nail
	return out


## 머리(뒤통수·귀 — 돌리면 광대·턱·코·눈썹뼈가 옆으로 보인다). 돌려주는 값: 그룹 · 머리 반지름.
static func head(cl: Clay, pr: Dictionary, j: Dictionary, skin: int, mats: Dictionary) -> Dictionary:
	var g := cl.group()
	var hc: Vector3 = j["head"]
	var hh: float = j["head_h"]
	var ru := hh * 0.39
	var rv := hh * 0.48
	var rw := hh * 0.45
	var F := Vector3(0, 0, -1)
	var plain := bool(j.get("map_face", false))  # 탐험 맵 얼굴(피어 앤 헝거 맵 그림): 턱이 튀어나오지 않은 달걀형, 움푹한 눈구멍, 입 없음
	cl.tag = "skull"
	if plain:  # 맵 얼굴: 머리통은 뒤·위로 물려 작게 — 옆에서 둥근 공 윤곽이 드러나지 않게(얼굴은 아래에서 깎아 붙인다)
		ell(cl, pr, g, hc + Vector3(0, -rv * 0.2, rw * 0.1), ru * 0.95, rv * 0.78, rw * 0.88, skin, 0.01)
		ell(cl, pr, g, hc + Vector3(0, -rv * 0.1, rw * 0.3), ru * 0.88, rv * 0.7, rw * 0.75, skin, 0.01)  # 뒤통수
	else:
		ell(cl, pr, g, hc, ru, rv, rw, skin, 0.01)
		ell(cl, pr, g, hc + Vector3(0, 0.012 * hh / 0.13, rw * 0.25), ru * 0.92, rv * 0.82, rw * 0.8, skin, 0.01)  # 뒤통수
	cl.tag = "face"
	if plain:  # 깎은 얼굴(참고 그림 옆얼굴): 납작한 앞면 + 턱끝으로 좁아지는 쐐기 + 귀 밑에서 턱끝으로 곧은 턱선
		var fm: Dictionary = (cl.mats[skin] as Dictionary).duplicate()
		fm["line"] = 0.0  # 조각 이음매에 주름 선을 긋지 않는다(입·해골 턱처럼 보였다)
		fm["cav"] = 0.25
		fm["c"] = (fm["c"] as Color).lightened(float(j.get("face_lift", 0.0)))  # 옆모습 얼굴 밝게(탐험 맵 그림)
		cl.mats.append(fm)
		skin = cl.mats.size() - 1
		var chin := hc + Vector3(0, rv * 0.74, -rw * 0.52)
		# 이마 → 얼굴 가운데 → 턱끝을 한 줄로(옆에서 매끈한 볼록선, 앞에서는 턱으로 좁아지는 얼굴)
		chain(cl, pr, g, [hc + Vector3(0, -rv * 0.4, -rw * 0.38), hc + Vector3(0, rv * 0.12, -rw * 0.42), chin], [ru * 0.78, ru * 0.66, ru * 0.2], skin, 0.09)
		# 턱선은 따로 붙이지 않는다 — 좁아지는 사슬의 아래 윤곽이 곧은 턱선이 된다(따로 붙인 조각은 이음매가 입·해골 턱처럼 보였다)
		cap(cl, pr, g, hc + Vector3(0, rv * 0.5, -rw * 0.22), (j["neck"] as Vector3) + Vector3(0, -0.01, -0.012), ru * 0.5, ru * 0.42, skin, 0.09)  # 턱 밑~목(오목한 틈에 주름 선이 그어지지 않게)
	else:
		ell(cl, pr, g, hc + Vector3(0, rv * 0.62, -rw * 0.38), ru * 0.8, rv * 0.5, rw * 0.72, skin, 0.012)  # 턱
	if not plain:
		var soft := 0.55 if j.get("socket_eyes", false) else 1.0  # 맵 그림: 광대·코를 낮게(작은 그림에서 둥근 광대가 안경테처럼 빛났다)
		ell(cl, pr, g, hc + Vector3(0, -rv * 0.32, -rw * 0.82), ru * 0.8, rv * 0.18, rw * 0.25, skin, 0.008)  # 눈썹뼈
		for s: int in [-1, 1]:
			ell(cl, pr, g, hc + Vector3(s * ru * 0.68, rv * 0.08, -rw * lerpf(0.5, 0.62, soft)), ru * 0.3, rv * 0.22, rw * 0.32 * soft, skin, 0.008)  # 광대
		cap(cl, pr, g, hc + Vector3(0, -rv * 0.18, -rw * lerpf(0.95, 1.02, soft)), hc + Vector3(0, rv * 0.28, -rw * lerpf(1.05, 1.22, soft)), hh * 0.07 * lerpf(0.8, 1.0, soft), hh * 0.065 * lerpf(0.8, 1.0, soft), skin, 0.006)  # 코
	# 맵 얼굴(plain): 코·입·귀 없는 매끈한 달걀형 — 눈은 칠한 눈구멍뿐(사용자 2026-10-17 "코랑 입 귀 지워")
	if not plain:
		ell(cl, pr, g, hc + Vector3(0, rv * 0.98, -rw * 0.72), ru * 0.38, rv * 0.2, rw * 0.3, skin, 0.008)  # 턱끝
	cl.tag = "ear"
	if str(j.get("ears", "")) == "long":  # 고블린 귀: 머리 옆에서 바깥·조금 위로 뻗은 길고 뾰족한 귀
		for s: int in [-1, 1]:
			var e0 := hc + Vector3(s * ru * 0.92, rv * 0.05, rw * 0.05)
			chain(cl, pr, g, [e0, e0 + Vector3(s * hh * 0.28, -hh * 0.1, rw * 0.15), e0 + Vector3(s * hh * 0.55, -hh * 0.24, rw * 0.3)], [hh * 0.1, hh * 0.06, hh * 0.008], skin, 0.01)
	for s: int in ([] if plain else [-1, 1]):  # 맵 얼굴은 귀 없음(사용자 2026-10-17)
		var ek := 0.6 if plain else 1.0  # 큰 머리의 맵 얼굴은 귀를 작게
		ell(cl, pr, g, hc + Vector3(s * ru * 0.98, rv * 0.06, rw * 0.02), hh * 0.055 * ek, hh * 0.16 * ek, hh * 0.11 * ek, skin, 0.004)
		groove(cl, pr, g, [hc + Vector3(s * ru * 1.04, -rv * 0.18, rw * 0.0), hc + Vector3(s * ru * 1.08, rv * 0.06, -rw * 0.05), hc + Vector3(s * ru * 1.02, rv * 0.3, rw * 0.0)], Vector3(s, 0, -0.3), hh * 0.018, hh * 0.03)
	cl.tag = ""
	var eyes: Array = []
	for s: int in [-1, 1]:  # 눈두덩(옆모습에서만 보인다) — 눈은 칠한 뒤 잉크로(Party.figure)
		var e := hc + Vector3(s * ru * 0.42, rv * 0.06 if plain else -rv * 0.1, -rw * 0.84)  # 맵 얼굴은 눈이 낮다(참고 그림: 머리 위에서 72%)
		if facing(pr, Vector3(s * 0.45, 0, -1)) > 0.12:
			var q := P2(pr, e)
			if not j.get("socket_eyes", false):  # 칠한 눈구멍을 쓰면 파내지 않는다(파낸 테두리가 밝게 빛나 안경처럼 보였다)
				cl.carve(g, q, hh * 0.07 * float(pr["H"]), hh * 0.045 * float(pr["H"]), hh * 0.035 * float(pr["H"]))
			eyes.append(q)
	if plain:
		return {"g": g, "c": hc, "hh": hh, "ru": ru, "rv": rv, "rw": rw, "eyes": eyes}
	groove(cl, pr, g, [hc + Vector3(-ru * 0.3, rv * 0.62, -rw * 1.0), hc + Vector3(0, rv * 0.6, -rw * 1.06), hc + Vector3(ru * 0.3, rv * 0.62, -rw * 1.0)], F, hh * 0.02, hh * 0.03)  # 입
	return {"g": g, "c": hc, "hh": hh, "ru": ru, "rv": rv, "rw": rw, "eyes": eyes}


## 머리 표면의 점: lon 0 = 뒤통수 가운데, ±π/2 = 옆(+ = 몸의 오른쪽), π = 얼굴. lat + = 위. grow = 표면에서 띄움(키 비율).
## 팔을 든 정도 0(곧게 늘어뜨림) ~ 1(위팔이 수평보다 위 — 앞·옆·위 어느 쪽으로 들든): 몸통 근육 덩어리를 팔 자세에 맞추는 데 쓴다.
## (팔꿈치 높이만 보면 앞으로 내민 대검 자세를 못 잡아 옆구리에 둥근 혹이 남았다)
static func _arm_lift(j: Dictionary, t: String) -> float:
	var d := ((j["elbow_" + t] as Vector3) - (j["shoulder_" + t] as Vector3)).normalized()
	return clampf((0.95 - d.y) / 0.6, 0.0, 1.0)


static func on_head(hd: Dictionary, lat: float, lon: float, grow: float = 0.0) -> Vector3:
	var c: Vector3 = hd["c"]
	return c + Vector3((float(hd["ru"]) + grow) * cos(lat) * sin(lon), -(float(hd["rv"]) + grow) * sin(lat), (float(hd["rw"]) + grow) * cos(lat) * cos(lon))


static func head_n(lat: float, lon: float) -> Vector3:
	return Vector3(cos(lat) * sin(lon), -sin(lat), cos(lat) * cos(lon))


## 화면 관절(Finish·피 얼룩이 쓴다).
static func screen_joints(pr: Dictionary, j: Dictionary) -> Dictionary:
	var out := {}
	for k: String in j:
		if j[k] is Vector3:
			out[k] = P(pr, j[k])
	return out
