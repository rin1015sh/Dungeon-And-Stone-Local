extends RefCounted
## 사람형 몸 빚기(Rig 관절 → Clay 덩어리): 몸통·팔·다리를 근육 덩어리로 쌓아 녹여 붙인다.
## build: thin(마른 — 갈비·관절이 튀어나옴) · normal · muscular(근육) · fat(배) · brute(어깨·등이 산처럼)
## b 키: build · bulk(굵기 배율) · hands(claw|open|fist|none) · claws(손톱 길이 비율, 0=없음) · feet(bare|boots|hoof|claw|none)
##       ribs(갈비 보임) · belly(배 크기) · veins(핏줄)
## 돌려주는 값: 그룹 번호(torso·arm_l·arm_r·leg_l·leg_r) + 갑옷·머리가 쓸 반지름(r_*)과 관절 그대로.

const Clay := preload("res://tools/monster_art/Clay.gd")

## 굵기(키 비율): 위팔 · 아래팔 시작/끝 · 허벅지 시작/끝 · 종아리 시작/끝 · 가슴 깊이 · 허리 반폭
const BUILDS := {
	"thin": [0.019, 0.017, 0.011, 0.033, 0.019, 0.022, 0.01, 0.05, 0.045],
	"normal": [0.026, 0.024, 0.014, 0.046, 0.025, 0.029, 0.013, 0.065, 0.06],
	"muscular": [0.036, 0.032, 0.017, 0.056, 0.03, 0.036, 0.016, 0.08, 0.068],
	"fat": [0.034, 0.03, 0.019, 0.06, 0.034, 0.036, 0.02, 0.09, 0.1],
	"brute": [0.044, 0.04, 0.024, 0.06, 0.036, 0.04, 0.022, 0.1, 0.08],
	"bones": [0.012, 0.011, 0.009, 0.016, 0.013, 0.013, 0.01, 0.05, 0.03],
}


static func body(cl: Clay, j: Dictionary, H: float, b: Dictionary, skin: int, nail: int) -> Dictionary:
	var build := str(b.get("build", "normal"))
	var t: Array = BUILDS.get(build, BUILDS["normal"])
	var bulk := float(b.get("bulk", 1.0))
	var out := j.duplicate()
	out["torso"] = cl.group()
	out["leg_l"] = out["torso"]  # 다리는 몸통과 녹여 붙인다(사타구니·엉덩이가 이어지게)
	out["leg_r"] = out["torso"]
	out["arm_l"] = cl.group()
	out["arm_r"] = cl.group()
	out["r_ua"] = t[0] * H * bulk
	out["r_fa"] = t[1] * H * bulk
	out["r_th"] = t[3] * H * bulk
	out["r_calf"] = t[5] * H * bulk
	out["depth"] = t[7] * H * bulk
	if build == "bones":
		_skeleton(cl, out, H, b, skin, nail)
		cl.tag = ""
		return out
	for s: int in [-1, 1]:
		var tag := "l" if s < 0 else "r"
		if str(b.get("feet", "bare")) != "none":
			cl.tag = "leg_" + tag
			_leg(cl, out, tag, s, H, t, bulk, b, skin, nail)
	cl.tag = "torso"
	_torso(cl, out, H, t, bulk, b, skin, build)
	for s: int in [-1, 1]:
		var tag := "l" if s < 0 else "r"
		cl.tag = "arm_" + tag
		_arm(cl, out, tag, s, H, t, bulk, b, skin, nail, build)
	cl.tag = ""
	return out


static func _torso(cl: Clay, j: Dictionary, H: float, t: Array, bulk: float, b: Dictionary, skin: int, build: String) -> void:
	var g: int = j["torso"]
	var ch: Vector3 = j["chest"]
	var wa: Vector3 = j["waist"]
	var pv: Vector3 = j["pelvis"]
	var nk: Vector3 = j["neck"]
	var sl: Vector3 = j["shoulder_l"]
	var sr: Vector3 = j["shoulder_r"]
	var dep: float = j["depth"]
	var shw := (sr.x - sl.x) * 0.5
	var thin := build == "thin"
	var waist := float(t[8]) * H * bulk
	# 골반 · 배 · 갈비 몸통 · 윗가슴(크게 녹여 하나의 몸통으로)
	var kk := 0.045 * H
	var hipw := absf(j["hip_r"].x - j["hip_l"].x) * 0.5 + float(t[3]) * H * bulk * 0.55
	cl.ell(g, pv + Vector3(0, -0.012 * H, -dep * 0.15), hipw * 0.92, 0.055 * H, dep * 0.6, skin, kk)
	var belly := float(b.get("belly", 1.6 if build == "fat" else 0.0))
	cl.ell(g, wa + Vector3(0, 0.012 * H * belly, dep * 0.12 * belly), waist * (1.0 + belly * 0.28), 0.085 * H * (1.0 + belly * 0.25), dep * (0.82 + belly * 0.3), skin, kk)
	cl.ell(g, ch, shw * (0.74 if thin else 0.86), 0.11 * H, dep, skin, kk)
	cl.ell(g, ch + Vector3(0, -0.06 * H, -dep * 0.2), shw * (0.9 if thin else 0.98), 0.055 * H, dep * 0.8, skin, kk * 0.7)
	# 목 · 승모근
	var hd: Vector3 = j["head"]
	var hh: float = j["head_h"]
	var nr := (0.02 if thin else (0.045 if build == "brute" else (0.034 if build == "muscular" else 0.028))) * H * bulk
	cl.cap(g, nk + Vector3(0, 0.01 * H, -dep * 0.1), hd + Vector3(0, hh * 0.25, -hh * 0.3), nr * 1.2, nr, skin, 6.0)
	var trap := (0.016 if thin else (0.05 if build == "brute" else (0.034 if build == "muscular" else 0.026))) * H * bulk
	for sv: Vector3 in [sl, sr]:
		cl.cap(g, nk + Vector3(0, 0.005 * H, -dep * 0.3), sv + Vector3(0, -0.005 * H, -dep * 0.2), trap * 1.1, trap * 0.8, skin, 7.0)
	# 근육 · 뼈 결
	var nk2 := Vector2(nk.x, nk.y)
	if thin or b.get("ribs", false):
		for k in 5:  # 갈비 사이 골
			var yy := ch.y - 0.045 * H + k * 0.026 * H
			for s: int in [-1, 1]:
				var x0 := ch.x + s * 0.012 * H
				cl.grooves(g, [Vector2(x0, yy), Vector2(x0 + s * shw * 0.35, yy + 0.008 * H), Vector2(x0 + s * shw * 0.62, yy + 0.026 * H)], 0.0055 * H, 0.0065 * H)
		cl.groove(g, Vector2(ch.x, ch.y - 0.07 * H), Vector2(ch.x, wa.y), 0.005 * H, 0.005 * H)
		cl.carve(g, Vector2(wa.x, wa.y + 0.015 * H), waist * 0.75, 0.045 * H, 0.01 * H)  # 꺼진 배
	else:
		for s: int in [-1, 1]:  # 가슴 근육
			cl.bump(g, Vector2(ch.x + s * shw * 0.42, ch.y - 0.035 * H), shw * 0.45, 0.042 * H, 0.009 * H * (1.4 if build in ["muscular", "brute"] else 0.8), skin, 0.02 * H, s * 0.25)
		cl.groove(g, Vector2(ch.x, ch.y - 0.06 * H), Vector2(ch.x, wa.y + 0.03 * H), 0.004 * H, 0.004 * H)
		if build in ["muscular", "brute"]:
			for row in 3:  # 복근
				for s: int in [-1, 1]:
					cl.bump(g, Vector2(wa.x + s * 0.017 * H, ch.y + 0.04 * H + row * 0.028 * H), 0.016 * H, 0.013 * H, 0.006 * H, skin, 3.0)
			for s: int in [-1, 1]:  # 옆구리
				cl.bump(g, Vector2(wa.x + s * waist * 0.82, wa.y - 0.005 * H), 0.018 * H, 0.04 * H, 0.008 * H, skin, 4.0, -s * 0.2)
	for s: int in [-1, 1]:  # 쇄골
		var sv: Vector3 = sr if s > 0 else sl
		cl.ridge(g, [nk2 + Vector2(s * 0.01 * H, 0.012 * H), Vector2(lerpf(nk.x, sv.x, 0.55), nk.y + 0.016 * H), Vector2(sv.x - s * 0.01 * H, sv.y + 0.004 * H)], 0.006 * H, 0.004 * H * (2.0 if thin else 1.0), skin)
	cl.carve(g, Vector2(wa.x, wa.y + 0.035 * H), 0.006 * H, 0.008 * H, 0.008 * H)  # 배꼽
	if thin:  # 골반뼈
		for s: int in [-1, 1]:
			cl.bump(g, Vector2(pv.x + s * absf(j["hip_r"].x - pv.x) * 0.9, pv.y - 0.03 * H), 0.012 * H, 0.016 * H, 0.008 * H, skin, 2.0)


static func _arm(cl: Clay, j: Dictionary, tag: String, s: int, H: float, t: Array, bulk: float, b: Dictionary, skin: int, nail: int, build: String) -> void:
	var g: int = j["arm_" + tag]
	var sh: Vector3 = j["shoulder_" + tag]
	var el: Vector3 = j["elbow_" + tag]
	var wr: Vector3 = j["wrist_" + tag]
	var ua := float(t[0]) * H * bulk
	var fa0 := float(t[1]) * H * bulk
	var fa1 := float(t[2]) * H * bulk
	var thin := build == "thin"
	var tg: int = j["torso"]  # 어깨세모근은 몸통에 녹여 붙인다(어깨가 공처럼 떨어져 보이지 않게)
	cl.tag = "shoulder_" + tag
	cl.ell(tg, sh + Vector3(s * ua * 0.3, ua * 0.55, -ua * 0.1), ua * (0.95 if thin else 1.08), ua * (1.2 if thin else 1.3), ua * 1.0, skin, 0.035 * H)
	cl.tag = "arm_" + tag
	cl.cap(g, sh + Vector3(s * ua * 0.15, ua * 1.1, -ua * 0.35), el, ua, ua * 0.78, skin, 6.0)
	var mid := sh.lerp(el, 0.55)
	var along := atan2(el.y - sh.y, el.x - sh.x)
	if not thin:  # 이두
		cl.bump(g, Vector2(mid.x - s * ua * 0.15, mid.y), ua * 1.0, ua * 0.6, ua * (0.35 if build in ["muscular", "brute"] else 0.2), skin, 4.0, along)
	cl.ell(g, el, fa0 * 0.95, fa0 * 0.9, fa0 * 0.9, skin, 0.012 * H)  # 팔꿈치
	cl.cap(g, el, wr, fa0, fa1, skin, 6.0)
	var fmid := el.lerp(wr, 0.28)
	cl.bump(g, Vector2(fmid.x + s * fa0 * 0.3, fmid.y), fa0 * 1.1, fa0 * 0.55, fa0 * (0.18 if thin else 0.3), skin, 3.0, atan2(wr.y - el.y, wr.x - el.x))
	if thin:
		cl.ridge(g, [Vector2(el.x, el.y), Vector2(wr.x, wr.y)], fa1 * 0.35, fa1 * 0.2, skin)  # 드러난 뼈
	if b.get("veins", false):
		var a := el.lerp(wr, 0.1)
		var c := el.lerp(wr, 0.9)
		cl.ridge(g, [Vector2(a.x, a.y), Vector2(lerpf(a.x, c.x, 0.5) + s * fa1 * 0.4, lerpf(a.y, c.y, 0.5)), Vector2(c.x, c.y)], fa1 * 0.12, fa1 * 0.1, skin)
	cl.tag = "hand_" + tag
	_hand(cl, j, g, tag, s, H, bulk, b, skin, nail)


## 손: 손바닥 + 손가락 4(마디 3) + 엄지. claw = 벌린 갈고리 손, fist = 쥔 손, open = 편 손.
static func _hand(cl: Clay, j: Dictionary, g: int, tag: String, s: int, H: float, bulk: float, b: Dictionary, skin: int, nail: int) -> void:
	var kind := str(b.get("hands_" + tag, b.get("hands", "open")))
	if kind == "none":
		return
	var wr: Vector3 = j["wrist_" + tag]
	var dir: Vector3 = j["hand_dir_" + tag]
	var side := Vector3(-dir.y, dir.x, 0).normalized() * s
	if side.length() < 0.1:
		side = Vector3(s, 0, 0)
	var hs := 0.027 * H * maxf(1.0, bulk * 0.9) * float(b.get("hand_k", 1.0))
	var palm := wr + dir * hs * 1.1
	cl.ell(g, palm, hs * 1.0, hs * 1.15, hs * 0.6, skin, 4.0, atan2(dir.y, dir.x) - PI / 2.0)
	j["hand_" + tag] = palm + dir * hs * 0.6
	var claw := float(b.get("claws", 0.0))
	if kind == "fist":
		for f in 4:
			var fp := palm + dir * hs * 0.8 + side * (f - 1.5) * hs * 0.48 + Vector3(0, 0, hs * 0.35)
			cl.ell(g, fp, hs * 0.3, hs * 0.38, hs * 0.35, skin, 2.0)
		cl.cap(g, palm - side * hs * 0.6, palm - side * hs * 0.5 + dir * hs * 0.8 + Vector3(0, 0, hs * 0.5), hs * 0.25, hs * 0.22, skin, 2.0)
		return
	var spread := 0.55 if kind == "claw" else 0.28
	var curl := 0.65 if kind == "claw" else 0.25
	for f in 4:
		var ang := (f - 1.5) * spread * 0.45
		var fd := dir.rotated(Vector3(0, 0, 1), ang * s)
		var base := palm + dir * hs * 0.85 + side * (f - 1.5) * hs * 0.42
		var flen := hs * (0.95 if f in [1, 2] else 0.8) * (1.15 if kind == "claw" else 1.0)
		var p1 := base + fd * flen * 0.55
		var p2 := p1 + (fd + Vector3(0, 0, curl)).normalized() * flen * 0.45
		var p3 := p2 + (fd * 0.6 + Vector3(0, curl * 0.6, curl)).normalized() * flen * 0.38
		var fr := hs * 0.17
		cl.chain(g, [base, p1, p2, p3], [fr * 1.1, fr, fr * 0.9, fr * 0.75], skin, 2.0)
		if claw > 0.0:
			var tip := p3 + (fd * 0.5 + Vector3(0, 0.6, 0.3)).normalized() * hs * claw
			cl.cap(g, p3, tip, fr * 0.7, fr * 0.12, nail, 1.0)
	var tb := palm - side * hs * 0.75
	var td := (dir * 0.5 - side * 0.7 + Vector3(0, 0, 0.4)).normalized()
	cl.chain(g, [tb, tb + td * hs * 0.6, tb + td * hs * 1.05], [hs * 0.22, hs * 0.19, hs * 0.15], skin, 2.0)


static func _leg(cl: Clay, j: Dictionary, tag: String, s: int, H: float, t: Array, bulk: float, b: Dictionary, skin: int, nail: int) -> void:
	var g: int = j["leg_" + tag]
	var hp: Vector3 = j["hip_" + tag]
	var kn: Vector3 = j["knee_" + tag]
	var an: Vector3 = j["ankle_" + tag]
	var to: Vector3 = j["toe_" + tag]
	var th0 := float(t[3]) * H * bulk
	var th1 := float(t[4]) * H * bulk
	var c0 := float(t[5]) * H * bulk
	var c1 := float(t[6]) * H * bulk
	cl.cap(g, hp + Vector3(-s * th0 * 0.3, -th0 * 0.7, float(j["depth"]) * 0.3), kn, th0, th1, skin, 0.03 * H)
	var q := hp.lerp(kn, 0.45)
	var along := atan2(kn.y - hp.y, kn.x - hp.x)
	cl.bump(g, Vector2(q.x + s * th0 * 0.35, q.y), th0 * 0.55, th0 * 1.3, th0 * 0.15, skin, 6.0, along - PI / 2.0)  # 바깥 허벅지
	var vm := hp.lerp(kn, 0.8)
	cl.bump(g, Vector2(vm.x - s * th1 * 0.45, vm.y), th1 * 0.6, th1 * 0.8, th1 * 0.22, skin, 4.0)  # 무릎 위 안쪽 근육
	cl.ell(g, kn + Vector3(0, th1 * 0.15, th1 * 0.3), th1 * 0.72, th1 * 0.8, th1 * 0.9, skin, 4.0)  # 무릎
	cl.cap(g, kn + Vector3(0, th1 * 0.4, 0), an, c0, c1, skin, 6.0)
	var cm := kn.lerp(an, 0.3)
	for side: int in [-1, 1]:  # 종아리(정면에서는 양옆으로 불룩)
		cl.bump(g, Vector2(cm.x + side * c0 * 0.45, cm.y), c0 * 0.6, c0 * 1.5, c0 * 0.18, skin, 5.0, atan2(an.y - kn.y, an.x - kn.x) - PI / 2.0)
	cl.ridge(g, [Vector2(kn.x, kn.y + th1), Vector2(an.x, an.y - c1)], c1 * 0.35, c1 * 0.12, skin)  # 정강이뼈
	var feet := str(b.get("feet", "bare"))
	cl.tag = "foot_" + tag
	match feet:
		"hoof":
			cl.ell(g, an + Vector3(0, c1 * 1.2, c1), c1 * 1.4, c1 * 1.3, c1 * 1.4, nail, 3.0)
		_:
			for k: int in [-1, 1]:  # 복사뼈
				cl.ell(g, an + Vector3(k * c1 * 0.75, 0, 0), c1 * 0.35, c1 * 0.4, c1 * 0.4, skin, 2.0)
			var fw := maxf(c1 * 1.4, 0.022 * H)
			var fr: float = j.get("foot_rot_" + tag, s * 0.45)
			var fc := an + Vector3(s * fw * 0.25 + sin(fr) * fw * 0.6, fw * 0.75, fw * 1.2)
			cl.ell(g, fc, fw * 1.25, fw * 0.72, fw * 1.0, skin, 5.0, fr * 0.5)
			cl.ell(g, an + Vector3(0, fw * 0.2, 0), fw * 0.85, fw * 0.8, fw * 0.8, skin, 6.0)  # 발꿈치·발목
			if feet in ["bare", "claw"]:
				for k in 5:
					var tp := fc + Vector3(-s * (k - 1.6) * fw * 0.42 + sin(fr) * fw * 0.5, fw * 0.45 + s * (k - 1.6) * sin(fr) * fw * 0.2, fw * 0.6)
					cl.ell(g, tp, fw * (0.26 if k == 0 else 0.2), fw * 0.24, fw * 0.3, skin, 1.5)
					if feet == "claw":
						cl.cap(g, tp + Vector3(0, 0, fw * 0.2), tp + Vector3(0, fw * 0.5, fw * 0.4), fw * 0.15, fw * 0.03, nail, 1.0)


## 해골: 등뼈 마디 · 갈비 6쌍(사이가 비어 뒤가 보임) · 골반 · 가는 팔다리 뼈와 마디 혹 · 뼈 손가락.
static func _skeleton(cl: Clay, j: Dictionary, H: float, b: Dictionary, bone: int, nail: int) -> void:
	var g: int = j["torso"]
	var pv: Vector3 = j["pelvis"]
	var ch: Vector3 = j["chest"]
	var nk: Vector3 = j["neck"]
	var dep := 0.05 * H
	cl.tag = "torso"
	for k in 14:  # 등뼈
		var t := k / 13.0
		var q := pv.lerp(nk, t) + Vector3(0, 0, -dep * 0.4)
		cl.ell(g, q, 0.014 * H, 0.009 * H, 0.012 * H, bone, 1.0)
	var shw: float = (j["shoulder_r"].x - j["shoulder_l"].x) * 0.5
	for k in 6:  # 갈비
		var y := ch.y - 0.06 * H + k * 0.024 * H
		var wdt := shw * (0.62 + sin((k + 1) / 7.0 * PI) * 0.25)
		for s: float in [-1.0, 1.0]:
			var pts := [Vector3(ch.x + s * 0.008 * H, y - 0.006 * H, -dep * 0.4), Vector3(ch.x + s * wdt * 0.8, y - 0.002 * H, 0.0), Vector3(ch.x + s * wdt, y + 0.02 * H, dep * 0.4), Vector3(ch.x + s * wdt * 0.6, y + 0.04 * H, dep * 0.75), Vector3(ch.x + s * 0.02 * H, y + 0.03 * H, dep * 0.85)]
			cl.chain(g, pts, [0.006 * H, 0.007 * H, 0.007 * H, 0.006 * H, 0.005 * H], bone, 0.5)
	cl.cap(g, Vector3(ch.x, ch.y - 0.06 * H, dep * 0.85), Vector3(ch.x, ch.y + 0.07 * H, dep * 0.8), 0.009 * H, 0.007 * H, bone, 1.0)  # 복장뼈
	for s: float in [-1.0, 1.0]:  # 골반 날개 + 쇄골
		cl.ell(g, pv + Vector3(s * 0.04 * H, -0.01 * H, 0.0), 0.04 * H, 0.03 * H, 0.02 * H, bone, 2.0, s * 0.4)
		cl.carve(g, Vector2(pv.x + s * 0.04 * H, pv.y - 0.005 * H), 0.015 * H, 0.012 * H, 0.015 * H)
		var sv: Vector3 = j["shoulder_r"] if s > 0.0 else j["shoulder_l"]
		cl.cap(g, nk + Vector3(s * 0.012 * H, 0.012 * H, dep * 0.5), sv + Vector3(0, 0, dep * 0.2), 0.007 * H, 0.008 * H, bone, 1.0)
	var hd: Vector3 = j["head"]
	cl.chain(g, [nk, hd + Vector3(0, j["head_h"] * 0.35, -j["head_h"] * 0.2)], [0.01 * H, 0.009 * H], bone, 1.0)
	for tag: String in ["l", "r"]:
		var s := -1.0 if tag == "l" else 1.0
		cl.tag = "arm_" + tag
		var ga: int = j["arm_" + tag]
		var sh: Vector3 = j["shoulder_" + tag]
		var el: Vector3 = j["elbow_" + tag]
		var wr: Vector3 = j["wrist_" + tag]
		cl.ell(ga, sh, 0.02 * H, 0.02 * H, 0.02 * H, bone, 1.0)
		cl.cap(ga, sh, el, 0.011 * H, 0.009 * H, bone, 1.0)
		cl.ell(ga, el, 0.015 * H, 0.014 * H, 0.014 * H, bone, 1.0)
		for k: float in [-1.0, 1.0]:
			cl.cap(ga, el + Vector3(k * 0.005 * H, 0, 0), wr + Vector3(k * 0.006 * H, 0, 0), 0.006 * H, 0.005 * H, bone, 0.5)
		cl.tag = "hand_" + tag
		_hand(cl, j, ga, tag, int(s), H * 0.8, 0.8, b, bone, nail)
		cl.tag = "leg_" + tag
		var hp: Vector3 = j["hip_" + tag]
		var kn: Vector3 = j["knee_" + tag]
		var an: Vector3 = j["ankle_" + tag]
		cl.ell(g, hp, 0.02 * H, 0.02 * H, 0.02 * H, bone, 1.0)
		cl.cap(g, hp, kn, 0.014 * H, 0.011 * H, bone, 1.0)
		cl.ell(g, kn + Vector3(0, 0, 0.008 * H), 0.019 * H, 0.017 * H, 0.016 * H, bone, 1.0)
		for k: float in [-1.0, 1.0]:
			cl.cap(g, kn + Vector3(k * 0.006 * H, 0.01 * H, 0), an + Vector3(k * 0.005 * H, 0, 0), 0.008 * H * (1.0 if k * s > 0 else 0.6), 0.006 * H, bone, 0.5)
		cl.tag = "foot_" + tag
		var fr: float = j.get("foot_rot_" + tag, s * 0.45)
		for k in 4:
			var b0 := an + Vector3(s * (k - 1.5) * 0.008 * H, 0.008 * H, 0.0)
			cl.chain(g, [b0, b0 + Vector3(s * (k - 1.5) * 0.006 * H + sin(fr) * 0.02 * H, 0.025 * H, 0.03 * H), b0 + Vector3(s * (k - 1.5) * 0.01 * H + sin(fr) * 0.03 * H, 0.036 * H, 0.05 * H)], [0.006 * H, 0.005 * H, 0.004 * H], bone, 0.5)
