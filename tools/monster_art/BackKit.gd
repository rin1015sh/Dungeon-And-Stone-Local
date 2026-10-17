extends RefCounted
## 뒷모습 사람형(Back)의 머리카락·옷: 몸 부위 기록(tag)을 부풀려 한 겹 씌우는 shell(화면 띠로 자름) + 주름 골 + 장식.
## kit 키(색): shirt(sleeves: long|rolled|short) · vest(가죽 조끼) · mantle(두건 달린 짧은 어깨 망토) · pelt(털 어깨 망토)
##            pants · belt(pouch·knife: 허리 주머니·칼집) · boots(boots_fur: 털 단) · bracers(팔목 가죽) · armband(위팔 띠)
##            leg_wraps(종아리 감은 천) · torn(옷 구멍 0~1)
## 머리카락·수염은 BackHair.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")


## 화면 가로 띠(몸 좌표 v0~v1). jag > 0이면 아래 단을 들쭉날쭉.
static func band(cl: Clay, pr: Dictionary, v0: float, v1: float, rng: RandomNumberGenerator = null, jag: float = 0.0, n: int = 10) -> PackedVector2Array:
	var H: float = pr["H"]
	var oy: float = pr["oy"]
	var y0 := oy + v0 * H
	var y1 := oy + v1 * H
	var pts := PackedVector2Array([Vector2(-10, y0), Vector2(cl.w + 10, y0)])
	for i in n + 1:
		var x := cl.w + 10 - (cl.w + 20) * i / float(n)
		var dy := 0.0
		if rng != null and jag > 0.0:
			dy = (rng.randf() - 0.3) * jag * H * (2.0 if i % 2 == 0 else 0.6)
		pts.append(Vector2(x, y1 + dy))
	return pts


## k는 받지만 쓰지 않는다 — 몸과 같은 녹임 폭이어야 덩어리 이음매(엉덩이 아래·오금)에서 살이 옷을 뚫고 나오지 않는다.
static func shell(cl: Clay, pr: Dictionary, tags: Array, grow: float, m: int, g: int, clip: PackedVector2Array, _k: float = -1.0, lift: float = 0.0, detail: bool = false) -> void:
	var H: float = pr["H"]
	cl.shell(tags, grow * H, m, g, clip, -1.0, lift * H, detail)


## 몸통을 두른 옷 단: 몸통 둘레(타원 ru·rw)에서 보이는 쪽 반 바퀴를 돌며 단 높이 hem(φ)(φ = π/2가 등 가운데)을 찍고
## 위쪽(top_v)까지 닫은 다각형. 뒷모습·옆모습 어느 쪽이든 단이 몸을 따라 휜다.
static func hem_poly(pr: Dictionary, top_v: float, ru: float, rw: float, hem: Callable) -> PackedVector2Array:
	var turn: float = pr["turn"]
	var pts := PackedVector2Array()
	var a0 := -turn - 0.35
	var a1 := PI - turn + 0.35
	for i in 25:
		var phi := lerpf(a0, a1, i / 24.0)
		var v: float = hem.call(phi)
		pts.append(Back.P2(pr, Vector3(cos(phi) * ru, v, sin(phi) * rw)))
	var H: float = pr["H"]
	var oy: float = pr["oy"]
	var dir := signf(pts[0].x - pts[pts.size() - 1].x)
	pts.append(Vector2(pts[pts.size() - 1].x - H * 0.3 * dir, oy + top_v * H))
	pts.append(Vector2(pts[0].x + H * 0.3 * dir, oy + top_v * H))
	return pts


static func dress(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	var B := Vector3(0, 0, 1)
	var pv: Vector3 = j["pelvis"]
	var nk: Vector3 = j["neck"]
	var ch: Vector3 = j["chest"]
	var bw: float = bd["back_w"]
	if kit.has("pants"):
		var m := cl.mat(kit["pants"], "cloth")
		var g := cl.group()
		shell(cl, pr, ["pelvis", "thigh_l", "thigh_r", "shin_l", "shin_r"], 0.007, m, g, band(cl, pr, pv.y - 0.06, 0.0), 0.012, 0.0, true)
		for s: int in [-1, 1]:
			var t := "l" if s < 0 else "r"
			var kn: Vector3 = j["knee_" + t]
			var hp: Vector3 = j["hip_" + t]
			for k in 3:  # 오금 주름
				var y := kn.y - 0.03 + k * 0.022
				Back.groove(cl, pr, g, [Vector3(kn.x - 0.03, y + rng.randf_range(-0.01, 0.01), kn.z + 0.03), Vector3(kn.x, y + 0.012, kn.z + 0.036), Vector3(kn.x + 0.03, y + rng.randf_range(-0.01, 0.01), kn.z + 0.03)], B, 0.005, 0.007)
			Back.groove(cl, pr, g, [hp + Vector3(s * 0.01, 0.05, 0.05), hp.lerp(kn, 0.6) + Vector3(0, 0, 0.045)], B, 0.004, 0.004)  # 솔기
			Back.groove(cl, pr, g, [kn + Vector3(-s * 0.02, 0.05, 0.03), kn.lerp(j["ankle_" + t], 0.7) + Vector3(s * 0.01, 0, 0.03)], B, 0.004, 0.004)
	if kit.has("shirt"):
		_shirt(cl, pr, j, bd, kit, rng)
	if kit.has("leg_wraps"):
		var m := cl.mat(kit["leg_wraps"], "cloth")
		var g := cl.group()
		for s: int in [-1, 1]:
			var t := "l" if s < 0 else "r"
			var kn: Vector3 = j["knee_" + t]
			var an: Vector3 = j["ankle_" + t]
			shell(cl, pr, ["shin_" + t], 0.012, m, g, band(cl, pr, kn.y + 0.05, an.y - 0.02), 0.01)
			for k in 7:  # 감은 천 결(비스듬히)
				var a := kn.lerp(an, 0.25 + k * 0.1)
				Back.groove(cl, pr, g, [a + Vector3(-0.04, -0.008 * s, 0.03), a + Vector3(0.04, 0.012 * s, 0.03)], B, 0.0035, 0.006)
	if kit.has("boots"):
		var m := cl.mat(kit["boots"], "leather")
		var g := cl.group()
		for s: int in [-1, 1]:
			var t := "l" if s < 0 else "r"
			var kn: Vector3 = j["knee_" + t]
			var an: Vector3 = j["ankle_" + t]
			var top := kn.lerp(an, 0.4).y
			shell(cl, pr, ["shin_" + t, "foot_" + t], 0.014, m, g, band(cl, pr, top, 0.05), 0.008)
			if kit.has("boots_fur"):
				var fm := cl.mat(kit["boots_fur"], "fur")
				shell(cl, pr, ["shin_" + t], 0.026, fm, cl.group(), band(cl, pr, top - 0.012, top + 0.035, rng, 0.012, 8), 0.01)
			else:
				shell(cl, pr, ["shin_" + t], 0.02, m, g, band(cl, pr, top, top + 0.028), 0.006)  # 접은 목
			Back.groove(cl, pr, g, [an + Vector3(-0.02, -0.04, 0.03), an + Vector3(0.0, -0.035, 0.034), an + Vector3(0.02, -0.04, 0.03)], B, 0.004, 0.006)
	if kit.has("vest"):
		var m := cl.mat(kit["vest"], "leather")
		var g := cl.group()
		shell(cl, pr, ["torso", "pelvis"], 0.016, m, g, band(cl, pr, nk.y + 0.015, pv.y - 0.025), 0.02, 0.002)
		Back.groove(cl, pr, g, [Vector3(0, nk.y + 0.03, bw + 0.02), Vector3(0, pv.y - 0.03, 0.08)], B, 0.004, 0.007)  # 등 솔기
		for s: int in [-1, 1]:
			Back.groove(cl, pr, g, [Vector3(s * 0.065, nk.y + 0.04, bw + 0.015), Vector3(s * 0.06, pv.y - 0.03, 0.075)], B, 0.003, 0.004)
		Back.ridge(cl, pr, g, [Vector3(-0.13, pv.y - 0.03, 0.03), Vector3(0, pv.y - 0.03, 0.08), Vector3(0.13, pv.y - 0.03, 0.03)], B, 0.005, 0.003, m)
	if kit.has("bracers"):
		var m := cl.mat(kit["bracers"], "leather")
		var g := cl.group()
		var lace := cl.mat(Color("#2a1c12"), "leather")
		for s: int in [-1, 1]:
			var t := "l" if s < 0 else "r"
			var el: Vector3 = j["elbow_" + t]
			var wr: Vector3 = j["wrist_" + t]
			var a := el.lerp(wr, 0.3)
			shell(cl, pr, ["fore_" + t], 0.008, m, g, band(cl, pr, minf(a.y, wr.y), maxf(a.y, wr.y) + 0.006), 0.004)
			for k in 4:  # 끈
				var q := a.lerp(wr, 0.15 + k * 0.22)
				Back.ridge(cl, pr, g, [q + Vector3(-0.022, -0.004, 0.02), q + Vector3(0.022, 0.004, 0.02)], Vector3(s * 0.5, 0, 1), 0.003, 0.003, lace)
	if kit.has("armband"):
		var m := cl.mat(kit["armband"], "metal")
		var g := cl.group()
		for s: int in [-1, 1]:
			var t := "l" if s < 0 else "r"
			var q: Vector3 = j["shoulder_" + t].lerp(j["elbow_" + t], 0.62)
			shell(cl, pr, ["upper_" + t], 0.007, m, g, band(cl, pr, q.y, q.y + 0.016), 0.003)
	if kit.has("belt"):
		var m := cl.mat(kit["belt"], "leather")
		var g := cl.group()
		var y0 := pv.y - 0.065
		shell(cl, pr, ["pelvis", "torso"], 0.02, m, g, band(cl, pr, y0, y0 + 0.032), 0.01, 0.002)
		var metal := cl.mat(Color("#8a7a58"), "metal")
		if kit.get("pouch", false):  # 오른쪽 뒤 허리 주머니
			var pc := Vector3(0.098, y0 + 0.05, 0.05)
			Back.ell(cl, pr, g, pc, 0.026, 0.036, 0.03, m, 0.003)
			Back.ell(cl, pr, g, pc + Vector3(0, -0.02, 0.008), 0.028, 0.014, 0.028, m, 0.002)  # 덮개
			Back.ell(cl, pr, g, pc + Vector3(0.004, -0.008, 0.032), 0.005, 0.005, 0.004, metal, 0.0)
		if kit.get("knife", false):  # 왼쪽 허리 칼집 + 손잡이
			var top := Vector3(-0.1, y0 + 0.01, 0.03)
			var bot := Vector3(-0.122, y0 + 0.17, 0.01)
			Back.cap(cl, pr, g, top, bot, 0.013, 0.008, m, 0.002)
			Back.ell(cl, pr, g, bot, 0.009, 0.01, 0.008, metal, 0.002)
			var wood := cl.mat(Color("#4a3424"), "wood")
			Back.cap(cl, pr, g, top + Vector3(0, -0.005, 0.004), top + Vector3(0.006, -0.06, 0.006), 0.009, 0.008, wood, 0.002)
			Back.cap(cl, pr, g, top + Vector3(-0.018, -0.004, 0.006), top + Vector3(0.018, -0.006, 0.006), 0.005, 0.005, metal, 0.002)
			Back.ell(cl, pr, g, top + Vector3(0.007, -0.066, 0.006), 0.011, 0.009, 0.009, metal, 0.002)
	if kit.has("pelt"):
		_pelt(cl, pr, j, bd, kit["pelt"], rng)
	if kit.has("mantle"):
		_mantle(cl, pr, j, bd, kit["mantle"], rng)


static func _shirt(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(kit["shirt"], "cloth")
	var g := cl.group()
	var B := Vector3(0, 0, 1)
	var pv: Vector3 = j["pelvis"]
	var nk: Vector3 = j["neck"]
	var ch: Vector3 = j["chest"]
	var bw: float = bd["back_w"]
	shell(cl, pr, ["torso", "shoulder_l", "shoulder_r", "pelvis"], 0.009, m, g, band(cl, pr, nk.y + 0.004, pv.y - 0.03), 0.02, 0.0, true)
	var sleeves := str(kit.get("sleeves", "rolled"))
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var el: Vector3 = j["elbow_" + t]
		var wr: Vector3 = j["wrist_" + t]
		var end_y := el.y + 0.035 if sleeves == "rolled" else (el.y - 0.04 if sleeves == "short" else wr.y - 0.012)
		var tags := ["upper_" + t] if sleeves != "long" else ["upper_" + t, "fore_" + t]
		if sleeves == "rolled":
			tags.append("fore_" + t)
		shell(cl, pr, tags, 0.008, m, g, band(cl, pr, j["shoulder_" + t].y - 0.05, end_y), 0.01)
		if sleeves == "rolled":  # 걷어 올린 소매 단
			var cuff := el.lerp(wr, 0.18)
			shell(cl, pr, ["fore_" + t], 0.016, m, g, band(cl, pr, cuff.y - 0.03, cuff.y), 0.004)
		for k in 3:  # 소매 주름
			var a: Vector3 = j["shoulder_" + t].lerp(el, 0.35 + k * 0.2)
			Back.groove(cl, pr, g, [a + Vector3(-0.02, -0.006, 0.03), a + Vector3(0.022, 0.008, 0.03)], Vector3(s * 0.5, 0, 1), 0.004, 0.006)
	for s: int in [-1, 1]:  # 등 주름(견갑골에서 허리로)
		for k in 3:
			var a := Vector3(s * (0.03 + k * 0.03), ch.y - 0.05 + k * 0.02, bw)
			Back.groove(cl, pr, g, [a, a + Vector3(s * 0.015, 0.07, -0.004), a + Vector3(s * 0.005, 0.16, -0.012)], B, 0.005, 0.006)
	var torn := float(kit.get("torn", 0.0))
	for k in int(torn * 7):
		var q := Back.P2(pr, Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(ch.y - 0.06, pv.y - 0.06), bw))
		cl.erase(g, q, rng.randf_range(0.012, 0.03) * float(pr["H"]), rng.randf_range(0.015, 0.04) * float(pr["H"]), 0.5)


## 두건 달린 짧은 어깨 망토(여행자): 어깨를 덮고 등 위쪽까지, 목 뒤에 접힌 두건.
static func _mantle(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, col: Color, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "cloth")
	var g := cl.group()
	var B := Vector3(0, 0, 1)
	var nk: Vector3 = j["neck"]
	var ch: Vector3 = j["chest"]
	var bw: float = bd["back_w"]
	var shw := absf(j["shoulder_r"].x)
	var jag: Array = []
	for i in 40:
		jag.append(rng.randf_range(-0.006, 0.006))
	var hem := func(phi: float) -> float: return ch.y + 0.035 - 0.085 * pow(absf(cos(phi)), 1.4) + float(jag[int(absf(phi) * 7.0) % 40])
	shell(cl, pr, ["torso", "shoulder_l", "shoulder_r", "neck"], 0.016, m, g, hem_poly(pr, nk.y - 0.012, shw * 1.3, bw + 0.03, hem), 0.04, 0.003)
	for s: int in [-1, 1]:  # 어깨에서 흘러내리는 주름
		for k in 3:
			var a := Vector3(s * (0.03 + k * 0.04), nk.y + 0.02, bw + 0.02)
			Back.groove(cl, pr, g, [a, a + Vector3(s * 0.02, 0.05, 0.0), a + Vector3(s * 0.03, 0.1, -0.01)], Vector3(s * 0.4, 0, 1), 0.006, 0.01)
	# 목 뒤로 젖혀 늘어진 두건(끝이 뾰족한 천 자루)
	var hg := cl.group()
	var top := nk.y - 0.005
	var hp := PackedVector2Array()
	for v: Vector3 in [Vector3(-0.07, top, bw + 0.04), Vector3(-0.04, top - 0.012, bw + 0.04), Vector3(0.04, top - 0.012, bw + 0.04), Vector3(0.07, top, bw + 0.04), Vector3(0.05, top + 0.05, bw + 0.045), Vector3(0.012, top + 0.1, bw + 0.04), Vector3(-0.012, top + 0.1, bw + 0.04), Vector3(-0.05, top + 0.05, bw + 0.045)]:
		hp.append(Back.P2(pr, v))
	var z := cl.top_over(g, hp)
	var H: float = pr["H"]
	cl.slab(hg, hp, z - 0.006 * H, 0.018 * H, m, 2.0, 0.02 * H)
	for k in 4:
		var u := lerpf(-0.045, 0.045, k / 3.0)
		Back.groove(cl, pr, hg, [Vector3(u, top + 0.005, bw + 0.06), Vector3(u * 0.6, top + 0.05, bw + 0.062), Vector3(u * 0.2, top + 0.09, bw + 0.058)], B, 0.005, 0.01)


## 털 어깨 망토(바바리안): 어깨·위팔 윗부분을 두껍게 덮은 짐승 가죽, 들쭉날쭉한 털 단.
static func _pelt(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, col: Color, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "fur", {"mottle": col.darkened(0.35), "mottle_amt": 0.5})
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var ch: Vector3 = j["chest"]
	var bw: float = bd["back_w"]
	var shw := absf(j["shoulder_r"].x)
	var jag: Array = []
	for i in 40:
		jag.append(rng.randf_range(-0.022, 0.018))
	var hem := func(phi: float) -> float: return ch.y + 0.03 - 0.13 * pow(absf(cos(phi)), 1.2) + float(jag[int(absf(phi) * 9.0) % 40])
	shell(cl, pr, ["torso", "shoulder_l", "shoulder_r", "neck"], 0.03, m, g, hem_poly(pr, nk.y - 0.03, shw * 1.35, bw + 0.035, hem), 0.03, 0.006)
	for k in 10:  # 털 결(어깨에서 아래로 처진 골)
		var q := Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(nk.y, ch.y - 0.08), bw + 0.035)
		Back.groove(cl, pr, g, [q, q + Vector3(q.x * 0.15, 0.06, 0.0)], Vector3(q.x * 4.0, 0, 1), 0.008, 0.01)
