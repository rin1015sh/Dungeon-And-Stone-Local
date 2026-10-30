extends RefCounted
## 새 종족 후보의 옷 장식(사용자 2026-10-30 "종족 느낌도 안 나고 밋밋 — 휘황찬란 말고 바바리안·인간처럼 은은한 개성"):
## 한눈에 종족이 읽히는 작은 소품. Party.figure가 겉옷(BackCloak) 다음에 부른다. kit 키:
##   circlet {c, gem} 이마를 두른 가는 머리띠(엘프) · sash {c, w, tail} 왼어깨 → 오른허리 비스듬한 천 띠 + 허리 옆에 늘어진 끝
##   quiver {c, n, fletch} 등에 비스듬히 멘 화살통(깃이 오른어깨 위로) + 가슴을 가로지르는 끈 · scarf {c, tail, fur} 목에 두른 천 + 등으로 늘어진 끝(fur = 털 깃 — 끝 없이 굵게)
##   apron {c, len} 가슴 ~ 무릎 가죽 앞치마(대장장이) · buckle {c} 허리 앞 큰 네모 버클 · nasal {c} 투구 코 가리개
##   pack {c, roll, pick} 등짐(배낭 + 위에 말아 묶은 담요 + 비스듬한 곡괭이 자루)
## 양쪽 어깨받이는 BackSavage pauldron {side: "both"}.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")
const BackSavage := preload("res://tools/monster_art/BackSavage.gd")
const RaceGear := preload("res://tools/monster_art/RaceGear.gd")


static func wear(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, kit: Dictionary) -> void:
	if kit.has("apron"):
		_apron(cl, pr, j, bd, kit["apron"])
	if kit.has("sash"):
		_sash(cl, pr, j, bd, kit["sash"])
	if kit.has("buckle"):
		_buckle(cl, pr, j, bd, kit["buckle"])
	if kit.has("scarf"):
		_scarf(cl, pr, j, bd, kit["scarf"])
	if kit.has("quiver"):
		_quiver(cl, pr, j, bd, kit["quiver"])
	if kit.has("pack"):
		_pack(cl, pr, j, bd, kit["pack"])
	if kit.has("circlet"):
		_circlet(cl, pr, hd, kit["circlet"])
	RaceGear.wear(cl, pr, j, bd, kit)  # 엉덩이 띠·칼집·밧줄·메달·등 도끼
	if kit.has("nasal"):
		var hh: float = hd["hh"]
		Back.cap(cl, pr, cl.group(), Back.on_head(hd, 0.45, PI, hh * 0.1), Back.on_head(hd, -0.12, PI, hh * 0.16), hh * 0.05, hh * 0.04, cl.mat(kit["nasal"], "metal"), 0.003)


static func _mat(cl: Clay, col: Color, kind: String) -> int:
	return cl.mat(col, kind, {"mottle": col.darkened(0.25), "mottle_amt": 0.3})


## 머리띠: 머리카락 위로 이마를 한 바퀴 — 앞은 눈썹 위로 살짝 내려온 뾰족한 끝 + 작은 돌.
static func _circlet(cl: Clay, pr: Dictionary, hd: Dictionary, d: Dictionary) -> void:
	var m := cl.mat(d.get("c", Color("#a8a49a")), "metal")
	var g := cl.group()
	var hh: float = hd["hh"]
	var pts: Array = []
	var rad: Array = []
	for k in 25:
		var lon := lerpf(-PI, PI, k / 24.0)
		var face := 1.0 - absf(wrapf(lon - PI, -PI, PI)) / PI  # 1 = 이마 가운데
		pts.append(Back.on_head(hd, lerpf(0.55, 0.36, pow(face, 3.0)), lon, hh * 0.1))
		rad.append(hh * 0.04)
	Back.chain(cl, pr, g, pts, rad, m, 0.002)
	var front := Back.on_head(hd, 0.33, PI, hh * 0.12)
	Back.ell(cl, pr, g, front, hh * 0.05, hh * 0.06, hh * 0.03, cl.mat(d.get("gem", Color("#5a7a6a")), "metal"), 0.002)


## 천 띠: 왼어깨에서 오른허리로(앞·뒤 모두) + 오른허리 옆에서 허벅지까지 늘어진 끝자락.
static func _sash(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary) -> void:
	var col: Color = d["c"]
	var m := _mat(cl, col, "cloth")
	var g := cl.group()
	var ch: Vector3 = j["chest"]
	var slope := 1.0 * absf(cos(float(pr["turn"]))) + 0.35
	BackKit.shell(cl, pr, ["torso", "shoulder_l", "shoulder_r", "pelvis"], 0.014, m, g, BackSavage._slant(cl, pr, Vector3(ch.x, ch.y + 0.03, ch.z), -slope, float(d.get("w", 0.05))))
	if d.get("tail", true):
		var pv: Vector3 = j["pelvis"]
		var top := pv + Vector3(0.11, -0.05, 0.0)
		Back.chain(cl, pr, g, [top, top + Vector3(0.012, 0.09, 0.004), top + Vector3(0.016, 0.18, 0.0)], [0.022, 0.02, 0.016], m, 0.004)
		Back.ell(cl, pr, g, top + Vector3(0.0, -0.005, 0.0), 0.026, 0.02, 0.024, m, 0.004)  # 매듭


## 큰 버클: 허리띠 앞 가운데 네모 쇠(테두리 + 가운데 막대).
static func _buckle(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "metal")
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	var c := Vector3(pv.x, pv.y - 0.05, pv.z - 0.06 * float(bd["dep"]) - 0.03)
	Back.bump(cl, pr, g, c, Vector3(0, 0, -1), 0.034, 0.026, 0.014, m)
	Back.bump(cl, pr, g, c, Vector3(0, 0, -1), 0.016, 0.012, 0.01, cl.mat(col.darkened(0.45), "metal"))
	Back.bump(cl, pr, g, Vector3(c.x, c.y, pv.z + 0.06 * float(bd["dep"]) + 0.03), Vector3(0, 0, 1), 0.02, 0.016, 0.008, m)  # 뒤 고리


## 목도리: 목을 두른 굵은 천 고리 + 등으로 늘어진 두 끝.
static func _scarf(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary) -> void:
	var col: Color = d["c"]
	var fur: bool = d.get("fur", false)
	var m := _mat(cl, col, "fur" if fur else "cloth")
	var md := _mat(cl, col.darkened(0.18), "fur" if fur else "cloth")
	var g := cl.group()
	var nk: Vector3 = j["neck"] + Vector3(0, 0.025, 0.0)
	var bk := float(bd["bulk"])
	var r := (0.062 if fur else 0.05) * bk
	# 감은 바퀴: 털 깃은 한 바퀴, 천 목도리는 두 바퀴(아래는 어깨에 얹히고 위는 턱 밑 — 앞이 조금 처져 늘어진 천처럼)
	var wraps: Array = [[0.0, 1.0, 0.034 if fur else 0.026]] if fur else [[0.018, 1.12, 0.026], [-0.012, 0.98, 0.024]]
	for wi in wraps.size():
		var w: Array = wraps[wi]
		var pts: Array = []
		var rad: Array = []
		for k in 17:
			var a := k / 16.0 * TAU
			var front := maxf(0.0, -sin(a))  # 앞(−w)일수록 처진다
			pts.append(nk + Vector3(cos(a) * r * float(w[1]), float(w[0]) + front * 0.018 + sin(a * 3.0 + wi) * 0.003, sin(a) * r * float(w[1]) * 0.9))
			rad.append(float(w[2]) * (1.0 + 0.15 * sin(a * 2.0 + wi * 1.7)))  # 굵기가 고르지 않게 — 천이 접힌 듯
		Back.chain(cl, pr, g, pts, rad, md if wi == 0 else m, 0.012)
		if not fur:
			for k in 8:  # 감은 결(비스듬한 주름)
				var a := (k + 0.5) / 8.0 * TAU
				var c := nk + Vector3(cos(a) * r * float(w[1]) * 1.25, float(w[0]), sin(a) * r * float(w[1]) * 1.15)
				Back.groove(cl, pr, g, [c + Vector3(0, -0.015, 0), c + Vector3(cos(a) * 0.004, 0.015, sin(a) * 0.004)], Vector3(cos(a), 0, sin(a)), 0.004, 0.006)
	if fur or not d.get("tail", true):
		return
	var dep: float = bd["dep"]
	var fw := (j["chest"] as Vector3).z - 0.066 * dep - 0.012
	var knot := nk + Vector3(-0.035 * bk, 0.035, -r * 1.0)
	Back.ell(cl, pr, g, knot, 0.026, 0.022, 0.022, m, 0.006)  # 매듭
	# 앞 자락: 매듭에서 가슴 왼쪽으로 늘어진 넓은 천(끝이 조금 벌어진다)
	Back.chain(cl, pr, g, [knot + Vector3(0, 0.01, 0), Vector3(knot.x - 0.008, knot.y + 0.06, fw - 0.004), Vector3(knot.x - 0.004, knot.y + 0.12, fw - 0.002)], [0.022, 0.02, 0.018], m, 0.006)
	Back.ell(cl, pr, g, Vector3(knot.x - 0.004, knot.y + 0.13, fw - 0.002), 0.024, 0.01, 0.012, md, 0.004)  # 자락 끝
	Back.groove(cl, pr, g, [knot + Vector3(0, 0.02, -0.01), Vector3(knot.x - 0.006, knot.y + 0.11, fw - 0.02)], Vector3(0, 0, -1), 0.003, 0.005)
	# 등 끝자락: 하나만 왼어깨 뒤로 비스듬히(둘을 나란히 늘어뜨리면 등에 M 자처럼 보였다)
	var bw: float = bd["back_w"]
	var a0 := nk + Vector3(-0.025, 0.01, r * 0.8)
	Back.chain(cl, pr, g, [a0, Vector3(nk.x - 0.05, nk.y + 0.07, bw + 0.022), Vector3(nk.x - 0.075, nk.y + 0.15, bw + 0.018), Vector3(nk.x - 0.085, nk.y + 0.2, bw + 0.014)], [0.022, 0.02, 0.016, 0.008], md, 0.004)


## 화살통: 오른어깨 뒤에서 왼허리 뒤로 비스듬히 + 위로 삐져나온 화살 깃 + 가슴을 가로지르는 끈.
static func _quiver(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary) -> void:
	var col: Color = d["c"]
	var m := _mat(cl, col, "leather")
	var rim := cl.mat(col.darkened(0.4), "leather")
	var g := cl.group()
	var ch: Vector3 = j["chest"]
	var wa: Vector3 = j["waist"]
	var bw: float = bd["back_w"]
	var top := Vector3(ch.x + 0.06, ch.y - 0.11, bw + 0.04)
	var bot := Vector3(wa.x - 0.04, wa.y + 0.05, bw + 0.03)
	Back.cap(cl, pr, g, top, bot, 0.03, 0.026, m, 0.004)
	Back.cap(cl, pr, g, top, top + (top - bot).normalized() * 0.01, 0.034, 0.034, rim, 0.002)  # 아가리 테
	var dir := (top - bot).normalized()
	var shaft := cl.mat(Color("#5a4630"), "wood")
	var fl := cl.mat(d.get("fletch", Color("#9a9488")), "cloth")  # fletch = 깃 색
	for k in int(d.get("n", 4)):
		var off := Vector3((k - 1.5) * 0.012, 0.0, (k % 2) * 0.008)
		var a: Vector3 = top + off
		var b: Vector3 = a + dir * (0.07 + (k % 2) * 0.012)
		Back.cap(cl, pr, g, a, b, 0.004, 0.004, shaft, 0.001)
		Back.cap(cl, pr, g, a.lerp(b, 0.55), b, 0.011, 0.004, fl, 0.002)  # 깃
	BackKit.shell(cl, pr, ["torso", "shoulder_r", "shoulder_l"], 0.01, rim, cl.group(), BackSavage._slant(cl, pr, Vector3(ch.x, ch.y + 0.01, ch.z), 1.0 * absf(cos(float(pr["turn"]))) + 0.35, 0.016))


## 앞치마: 목끈 + 가슴에서 무릎까지 앞만 덮는 두꺼운 가죽 판(다리 앞에 늘어져 걸음과 따로 논다).
static func _apron(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary) -> void:
	var col: Color = d["c"]
	var m := _mat(cl, col, "leather")
	var g := cl.group()
	var dep: float = bd["dep"]
	var ch: Vector3 = j["chest"]
	var pv: Vector3 = j["pelvis"]
	var kn := ((j["knee_l"] as Vector3) + (j["knee_r"] as Vector3)) * 0.5
	var low := lerpf(pv.y + 0.05, kn.y + 0.02, float(d.get("len", 0.8)))
	var n := 22  # 촘촘히 겹쳐 매끈한 판으로(성기면 고리를 쌓은 것처럼 보였다)
	for k in n:
		var t := k / float(n - 1)
		var y := lerpf(ch.y - 0.03, low, t)
		var z := lerpf(ch.z - 0.07 * dep, pv.z - 0.075 * dep, clampf(t * 1.6, 0.0, 1.0)) - 0.012 - maxf(0.0, t - 0.6) * 0.04
		var hw := lerpf(0.07, 0.095, t) * float(bd["bulk"])
		Back.ell(cl, pr, g, Vector3(lerpf(ch.x, pv.x, t), y, z), hw, (low - ch.y) / n * 2.2, 0.012, m, 0.012)
	for k in 3:  # 세로 주름
		var u := (k - 1) * 0.045
		Back.groove(cl, pr, g, [Vector3(pv.x + u, pv.y - 0.02, pv.z - 0.075 * dep - 0.02), Vector3(pv.x + u * 1.1, low - 0.02, pv.z - 0.075 * dep - 0.04)], Vector3(0, 0, -1), 0.004, 0.006)
	for s: int in [-1, 1]:  # 목끈
		Back.cap(cl, pr, g, Vector3(ch.x + s * 0.05, ch.y - 0.03, ch.z - 0.07 * dep - 0.012), (j["neck"] as Vector3) + Vector3(s * 0.03, 0.01, 0.0), 0.006, 0.006, cl.mat(col.darkened(0.4), "leather"), 0.002)


## 등짐: 배낭(네모진 가죽 자루 + 덮개) · 위에 말아 묶은 담요 · 오른쪽으로 비스듬히 꽂은 곡괭이 자루(머리는 어깨 위).
static func _pack(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary) -> void:
	var col: Color = d["c"]
	var m := _mat(cl, col, "leather")
	var g := cl.group()
	var ch: Vector3 = j["chest"]
	var bw: float = bd["back_w"]
	var bk := float(bd["bulk"])
	var c := Vector3(ch.x, ch.y + 0.03, bw + 0.055)
	Back.ell(cl, pr, g, c, 0.08 * bk, 0.085, 0.05, m, 0.01)
	Back.ell(cl, pr, g, c + Vector3(0, -0.05, 0.012), 0.082 * bk, 0.04, 0.046, cl.mat(col.darkened(0.25), "leather"), 0.006)  # 덮개
	if d.has("roll"):
		var rm := _mat(cl, d["roll"], "cloth")
		Back.cap(cl, pr, g, c + Vector3(-0.1 * bk, -0.1, 0.0), c + Vector3(0.1 * bk, -0.1, 0.0), 0.032, 0.032, rm, 0.006)
		for s: float in [-0.5, 0.5]:  # 묶은 끈
			Back.cap(cl, pr, g, c + Vector3(s * 0.12 * bk, -0.1, -0.036), c + Vector3(s * 0.12 * bk, -0.1, 0.036), 0.035, 0.035, cl.mat(Color("#2a1c12"), "leather"), 0.002)
	if d.get("pick", false):
		var wood := cl.mat(Color("#4a3628"), "wood")
		var metal := cl.mat(Color("#6a6e72"), "metal")
		var a := c + Vector3(0.11 * bk, -0.17, 0.03)
		var b := c + Vector3(-0.07 * bk, 0.16, 0.02)
		Back.cap(cl, pr, g, a, b, 0.009, 0.009, wood, 0.002)
		Back.chain(cl, pr, g, [a + Vector3(-0.07, 0.01, 0.0), a + Vector3(0.0, -0.012, 0.0), a + Vector3(0.07, 0.03, 0.0)], [0.004, 0.014, 0.004], metal, 0.003)
	for s: int in [-1, 1]:  # 멜빵(앞에서 어깨 위로 보인다)
		var t := "l" if s < 0 else "r"
		var sh: Vector3 = j["shoulder_" + t]
		Back.cap(cl, pr, g, Vector3(sh.x - s * 0.035, sh.y - 0.005, ch.z - 0.06), Vector3(sh.x - s * 0.04, sh.y - 0.012, bw + 0.02), 0.011, 0.011, cl.mat(col.darkened(0.35), "leather"), 0.002)
