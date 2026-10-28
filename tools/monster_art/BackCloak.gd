extends RefCounted
## 사람형(Back) 겉옷 — 탐험 맵 몸 그림 고르기(tools/monster_art/MapLooks.gd)에서 쓴다:
##   cloak {c, len, flare, open, fur, fit} 어깨에서 늘어진 망토(fit = 몸에 붙는 망토 — 단면이 몸처럼 납작한 타원이라 옆에서 봐도 볼록하지 않고
##     어깨선을 따라 곧게 떨어진다, 사용자 2026-10-26 약탈자 "망토가 너무 볼록하게 두껍게 튀어나와 있다")(3D 원뿔 — 어느 쪽에서 봐도 덮이고, 팔은 그 안에서 흔들려 손만 나온다. 앞모습은 가운데가 트였다)
##   hood_up 쓴 두건(얼굴만 드러나고 뒤로 어깨까지 흘러내림 — 머리카락은 그리지 않는다)
##   coat {c, len} 무릎까지 오는 긴 외투(긴 소매 · 깃 · 다리 사이 자락)
##   quilt {c} 누빔 갑옷(겜베슨 — 가로 누빔 골 · 긴 소매) · chain {c} 사슬 셔츠(쇠 · 고리 결)
##   outer_belt {c} 겉옷 위 허리띠 · clasp {c} 망토 여밈 쇠
## kit 키가 없으면 아무것도 하지 않는다(전투 그림은 그대로).

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")


static func wear(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	if kit.has("chain"):
		_chain(cl, pr, j, kit["chain"], rng)
	if kit.has("quilt"):
		_quilt(cl, pr, j, bd, kit["quilt"])
	if kit.has("coat"):
		_coat(cl, pr, j, bd, kit["coat"])
	if kit.has("outer_belt"):
		_belt(cl, pr, j, kit["outer_belt"])
	if kit.has("cloak"):
		_cloak(cl, pr, j, bd, kit["cloak"], rng)
	if kit.has("hood_up"):
		_hood(cl, pr, j, hd, kit["hood_up"])


static func _front(pr: Dictionary) -> bool:
	return cos(float(pr["turn"])) < -0.6


## 화면 전체(자르지 않음).
static func _all(cl: Clay) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-10, -10), Vector2(cl.w + 10, -10), Vector2(cl.w + 10, cl.h + 10), Vector2(-10, cl.h + 10)])


## 망토: 목에서 hem까지 넓어지는 원뿔(몸 좌표) + 세로 주름. 앞모습은 가운데 V자로 트여 옷이 보이고 여밈 쇠가 목에.
static func _cloak(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary, rng: RandomNumberGenerator) -> void:
	var col: Color = d["c"]
	var m := cl.mat(col, "fur" if d.get("fur", false) else "cloth", {"mottle": col.darkened(0.3), "mottle_amt": 0.35})
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var shw := absf(j["shoulder_r"].x)
	var hem := lerpf(j["pelvis"].y, -0.04, float(d.get("len", 0.6)))
	var top := Vector3(0, nk.y + 0.02, 0.012)
	var bot := Vector3(0, hem, 0.03)
	var ra := shw + 0.085
	var rb := shw * float(d.get("flare", 1.5)) + 0.04
	var H: float = pr["H"]
	var band := BackKit.band(cl, pr, nk.y - 0.2, hem, rng, 0.012, 14)  # 둥근 아래 끝을 잘라 단까지만
	var sy: float = j["shoulder_r"].y
	var spine: Array = [Vector3(0, nk.y - 0.005, 0.01), Vector3(0, sy + 0.01, 0.015), Vector3(0, sy + 0.07, 0.02), bot]  # 목 → 어깨를 둥글게 덮고 → 단으로 퍼짐
	var radii: Array = [0.065, ra - 0.01, ra + 0.005, rb]
	var depth: Array = radii  # 앞뒤 반지름(둥근 망토는 폭과 같다)
	if d.get("fit", false):  # 몸에 붙는 망토: 폭은 어깨 바로 바깥, 깊이는 등 두께만큼, 단까지 거의 곧게
		var bw: float = bd["back_w"]
		ra = shw + 0.06  # 위팔 바깥까지(뒤에서 팔을 덮는다)
		rb = shw * float(d.get("flare", 1.05)) + 0.06
		radii = [0.06, ra - 0.005, ra, rb]
		depth = [0.055, bw + 0.03, bw + 0.032, bw + 0.035]
	if _front(pr) and float(d.get("open", 1.0)) > 0.0:  # 앞이 트인 망토: 왼쪽·오른쪽 반을 따로(가운데 V)
		var o := float(d.get("open", 1.0))
		for s: int in [-1, 1]:
			var a := Back.P2(pr, Vector3(s * 0.012, nk.y + 0.01, -0.15))
			var b := Back.P2(pr, Vector3(s * 0.11 * o, hem + 0.05, -0.2))
			var edge := float(cl.w + 10) if a.x > Back.P2(pr, Vector3(0, nk.y, 0)).x else -10.0
			var half := PackedVector2Array([Vector2(a.x, -10), Vector2(edge, -10), Vector2(edge, cl.h + 10), Vector2(b.x, cl.h + 10), b, a])
			for part: PackedVector2Array in Geometry2D.intersect_polygons(band, half):
				cl.set_clip(part)
				_echain(cl, pr, g, spine, radii, depth, m, 0.03)
		cl.set_clip(PackedVector2Array())
	else:
		cl.set_clip(band)
		_echain(cl, pr, g, spine, radii, depth, m, 0.03)
		cl.set_clip(PackedVector2Array())
	for k in 11:  # 세로 주름(어깨에서 아래로 퍼진다)
		var a := TAU * (k + rng.randf_range(0.2, 0.8)) / 11.0
		var n := Vector3(sin(a), 0, cos(a))
		var p0 := Vector3(sin(a) * float(radii[2]) * 0.9, sy + 0.05, cos(a) * float(depth[2]) * 0.9 + 0.012)
		var p1 := Vector3(sin(a) * rb, hem - 0.01, cos(a) * float(depth[3]) + 0.03)
		Back.groove(cl, pr, g, [p0, p0.lerp(p1, 0.5), p1], n, 0.007, 0.012)
	for k in 5:  # 해진 단
		var a := rng.randf_range(0.0, TAU)
		cl.erase(g, Back.P2(pr, Vector3(sin(a) * rb, hem - rng.randf_range(0.0, 0.02), cos(a) * float(depth[3]))), rng.randf_range(0.006, 0.014) * H, rng.randf_range(0.01, 0.025) * H, 0.5)
	if d.has("clasp"):  # 목 여밈 쇠
		Back.ell(cl, pr, g, Vector3(0, nk.y + 0.03, -ra * 0.85), 0.016, 0.016, 0.01, cl.mat(d["clasp"], "metal"), 0.003)
	if d.get("collar", false):  # 젖힌 두건(목 뒤 두툼한 천)
		Back.ell(cl, pr, g, Vector3(0, nk.y + 0.005, 0.07), shw * 0.75, 0.05, 0.06, m, 0.02)


## 단면이 타원인 캡슐 줄(몸 좌표 폭 us · 깊이 ws — 돌린 각도에 따라 화면 폭과 앞뒤 솟음을 섞는다, Back.ell과 같은 근사).
static func _echain(cl: Clay, pr: Dictionary, g: int, pts: Array, us: Array, ws: Array, m: int, k: float) -> void:
	var c: float = pr["c"]
	var s: float = pr["s"]
	var H: float = pr["H"]
	for i in pts.size() - 1:
		var rx := PackedFloat32Array()
		var flat := 0.0
		for j in [i, i + 1]:
			var u := float(us[j])
			var w := float(ws[j])
			var x := sqrt(pow(u * c, 2.0) + pow(w * s, 2.0))
			rx.append(x)
			flat += sqrt(pow(u * s, 2.0) + pow(w * c, 2.0)) / x * 0.5
		cl.cap(g, Back.P(pr, pts[i]), Back.P(pr, pts[i + 1]), rx[0] * H, rx[1] * H, m, k * H, flat)


## 쓴 두건: 머리를 감싼 천(얼굴은 드러남) + 뒤로 어깨까지 흘러내리는 자락 + 얼굴 둘레 테.
static func _hood(cl: Clay, pr: Dictionary, j: Dictionary, hd: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "cloth", {"mottle": col.darkened(0.3), "mottle_amt": 0.35})
	var g := cl.group()
	var c: Vector3 = hd["c"]
	var rv: float = hd["rv"]
	var ru: float = hd["ru"]
	var rw: float = hd["rw"]
	var nk: Vector3 = j["neck"]
	BackKit.shell(cl, pr, ["skull", "ear"], 0.022, m, g, BackKit.band(cl, pr, c.y - rv * 2.0, c.y + rv * 1.05), 0.03)
	Back.cap(cl, pr, g, c + Vector3(0, -rv * 0.2, rw * 0.45), nk + Vector3(0, 0.03, 0.06), ru * 1.05, absf(j["shoulder_r"].x) * 0.95, m, 0.03)  # 뒤로 흘러내림
	Back.ell(cl, pr, g, c + Vector3(0, -rv * 0.95, rw * 0.15), ru * 0.75, rv * 0.35, rw * 0.7, m, 0.02)  # 정수리 끝(살짝 뾰족)
	var rim: Array = []
	for i in 13:  # 얼굴 둘레 테(앞에서 보일 때)
		var a := lerpf(-PI * 0.55, PI * 0.55, i / 12.0)
		rim.append(c + Vector3(sin(a) * ru * 1.02, -cos(a) * rv * 0.98, -rw * 0.72))
	Back.ridge(cl, pr, g, rim, Vector3(0, 0, -1), 0.009, 0.008, m)


## 긴 외투: 몸통·허리·허벅지를 감싸 무릎까지(다리 사이는 자락이 이어진다) + 긴 소매 + 깃.
static func _coat(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary) -> void:
	var col: Color = d["c"]
	var m := cl.mat(col, str(d.get("mat", "leather")))
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	var hem := lerpf(pv.y, -0.04, float(d.get("len", 0.55)))
	BackKit.shell(cl, pr, ["torso", "pelvis", "shoulder_l", "shoulder_r", "thigh_l", "thigh_r"], 0.02, m, g, BackKit.band(cl, pr, nk.y + 0.01, hem), 0.05, 0.0)
	if float(d.get("len", 0.55)) >= 0.45:  # 다리 사이 자락 — 짧은 외투(엉덩이까지)는 없다(둥근 자락이 다리 사이에 부풀어 보였다)
		Back.cap(cl, pr, g, Vector3(0, pv.y - 0.02, 0.01), Vector3(0, hem - 0.005, 0.015), 0.12, 0.155, m, 0.04)
	for s: int in [-1, 1]:  # 긴 소매
		var t := "l" if s < 0 else "r"
		var wr: Vector3 = j["wrist_" + t]
		BackKit.shell(cl, pr, ["upper_" + t, "fore_" + t], 0.014, m, g, BackKit.band(cl, pr, j["shoulder_" + t].y - 0.06, maxf(wr.y, j["elbow_" + t].y) + 0.004), 0.012)
	Back.ell(cl, pr, g, nk + Vector3(0, 0.015, 0.0), absf(j["shoulder_r"].x) * 0.6, 0.03, 0.08, m, 0.02)  # 세운 깃
	Back.groove(cl, pr, g, [Vector3(0, nk.y + 0.04, -0.11), Vector3(0, hem, -0.15)], Vector3(0, 0, -1), 0.005, 0.01)  # 앞 여밈
	Back.groove(cl, pr, g, [Vector3(0, pv.y - 0.03, 0.1), Vector3(0, hem, 0.15)], Vector3(0, 0, 1), 0.005, 0.01)  # 뒤 트임
	for k in 4:  # 단추
		var y := lerpf(nk.y + 0.06, pv.y - 0.08, k / 3.0)
		Back.bump(cl, pr, g, Vector3(0.025, y, -0.115), Vector3(0, 0, -1), 0.006, 0.006, 0.004, cl.mat(Color("#7a6a4a"), "metal"))


## 누빔 갑옷(겜베슨): 몸통·허리·긴 소매를 두툼하게, 가로 누빔 골과 옆 솔기.
static func _quilt(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "cloth", {"mottle": col.darkened(0.25), "mottle_amt": 0.3})
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	var hem := pv.y + 0.07
	BackKit.shell(cl, pr, ["torso", "pelvis", "shoulder_l", "shoulder_r"], 0.022, m, g, BackKit.band(cl, pr, nk.y + 0.008, hem), 0.03, 0.0)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		BackKit.shell(cl, pr, ["upper_" + t, "fore_" + t], 0.016, m, g, BackKit.band(cl, pr, j["shoulder_" + t].y - 0.06, maxf(j["wrist_" + t].y, j["elbow_" + t].y) - 0.01), 0.012)
	var bw: float = bd["back_w"]
	var y := nk.y + 0.05
	while y < hem - 0.01:  # 가로 누빔(앞·뒤·옆)
		Back.groove(cl, pr, g, [Vector3(-0.12, y, -0.1), Vector3(0, y + 0.004, -0.125), Vector3(0.12, y, -0.1)], Vector3(0, 0, -1), 0.004, 0.008)
		Back.groove(cl, pr, g, [Vector3(-0.12, y, bw), Vector3(0, y + 0.004, bw + 0.025), Vector3(0.12, y, bw)], Vector3(0, 0, 1), 0.004, 0.008)
		for s: float in [-1.0, 1.0]:
			Back.groove(cl, pr, g, [Vector3(s * 0.15, y, -0.06), Vector3(s * 0.16, y, 0.04)], Vector3(s, 0, 0), 0.004, 0.008)
		y += 0.04
	Back.groove(cl, pr, g, [Vector3(0, nk.y + 0.03, -0.12), Vector3(0, hem, -0.13)], Vector3(0, 0, -1), 0.005, 0.01)  # 앞 여밈


## 사슬 셔츠: 몸통·허리·위팔을 쇠로, 촘촘한 고리 결(가로 골).
static func _chain(cl: Clay, pr: Dictionary, j: Dictionary, col: Color, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "metal", {"mottle": col.darkened(0.4), "mottle_amt": 0.4})
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	var hem := pv.y + 0.09
	BackKit.shell(cl, pr, ["torso", "pelvis", "shoulder_l", "shoulder_r"], 0.016, m, g, BackKit.band(cl, pr, nk.y + 0.01, hem, rng, 0.006, 14), 0.03, 0.0)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		BackKit.shell(cl, pr, ["upper_" + t], 0.012, m, g, BackKit.band(cl, pr, j["shoulder_" + t].y - 0.06, j["elbow_" + t].y), 0.01)
	var y := nk.y + 0.04
	while y < hem:
		for n: Vector3 in [Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
			var side := Vector3(n.z, 0, -n.x) * 0.13
			var base := n * 0.12
			Back.groove(cl, pr, g, [base - side + Vector3(0, y, 0), base + side + Vector3(0, y, 0)], n, 0.0025, 0.004)
		y += 0.018


## 겉옷 위 허리띠 + 쇠 고리.
static func _belt(cl: Clay, pr: Dictionary, j: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "leather")
	var g := cl.group()
	var y0: float = j["pelvis"].y - 0.07
	BackKit.shell(cl, pr, ["pelvis", "torso"], 0.04, m, g, BackKit.band(cl, pr, y0, y0 + 0.03), 0.02, 0.002)
	var pv: Vector3 = j["pelvis"]  # 배 앞 버클(골반을 따라 · 배 표면에 붙여 — 몸을 돌려도 몸 밖에 뜨지 않게)
	Back.ell(cl, pr, g, Vector3(pv.x, y0 + 0.015, pv.z - 0.085), 0.02, 0.018, 0.01, cl.mat(Color("#8a7a58"), "metal"), 0.003)
