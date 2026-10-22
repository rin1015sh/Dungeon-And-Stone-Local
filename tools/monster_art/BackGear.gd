extends RefCounted
## 뒷모습 사람형(Back)의 장구: 투구(helm·plume) · 판금(armor — 등판·어깨받이·팔뚝·정강이) · 긴 망토(cape) · 붕대(wraps)
## · 허리천 뒷자락(loin) · 창(spear·lance — 쥔 손) · 방패(shield — 안쪽 면과 손잡이 끈이 보인다, shield_kind round|kite).

const BackExtras := preload("res://tools/monster_art/BackExtras.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")


static func gear(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	if kit.has("wraps"):
		_wraps(cl, pr, j, kit["wraps"], float(kit.get("wraps_amt", 0.9)), rng)
	if kit.has("loin"):
		_loin(cl, pr, j, bd, kit["loin"], rng)
	if kit.has("armor"):
		_armor(cl, pr, j, bd, kit["armor"], rng)
		j["armored"] = true
	if kit.has("cape"):
		_cape(cl, pr, j, bd, kit["cape"], rng)
	if kit.has("helm"):
		_helm(cl, pr, hd, kit, rng)
	if kit.has("weapon") and not BackExtras.HAND_WEAPONS.has(str(kit["weapon"])):  # 손 무기는 BackExtras
		if str(kit["weapon"]) == "dagger":
			_dagger(cl, pr, j, kit, str(kit.get("weapon_hand", "r")))
		else:
			_pole(cl, pr, j, kit, str(kit.get("weapon_hand", "r")))
	if kit.has("shield"):
		_shield(cl, pr, j, kit, str(kit.get("shield_hand", "l")))


## 붕대: 부위(머리·몸통·팔·다리)마다 따로, 기울기·폭이 제각각인 띠로 감는다. 띠가 겹쳐 두께가 다르고, 틈으로 어두운 살이 드러나며,
## 몸통에는 비스듬히 엇갈린 띠와 풀려 늘어진 끝자락.
static func _wraps(cl: Clay, pr: Dictionary, j: Dictionary, col: Color, amt: float, rng: RandomNumberGenerator) -> void:
	var H: float = pr["H"]
	var oy: float = pr["oy"]
	var parts := [["skull", "face", "ear"], ["neck", "torso", "pelvis", "shoulder_l", "shoulder_r"], ["upper_l", "fore_l", "hand_l"], ["upper_r", "fore_r", "hand_r"], ["thigh_l", "shin_l", "foot_l"], ["thigh_r", "shin_r", "foot_r"]]
	var tops := [j["head"].y - j["head_h"] * 0.6, j["neck"].y - 0.01, j["shoulder_l"].y - 0.02, j["shoulder_r"].y - 0.02, j["pelvis"].y - 0.02, j["pelvis"].y - 0.02]
	var bots := [j["neck"].y, j["pelvis"].y + 0.06, j["hand_l"].y + 0.03, j["hand_r"].y + 0.03, 0.0, 0.0]
	for i in parts.size():
		var y: float = tops[i] + rng.randf_range(0.0, 0.01)
		while y < float(bots[i]):
			var step := rng.randf_range(0.016, 0.03)
			if rng.randf() < amt:
				var c := col.darkened(rng.randf_range(0.0, 0.25))
				var m := cl.mat(c, "cloth", {"mottle": col.darkened(0.4), "mottle_amt": 0.5})
				var tilt := rng.randf_range(-0.022, 0.022) * H
				var y0 := oy + y * H
				var y1 := oy + (y + step * rng.randf_range(0.75, 1.05)) * H
				var poly := PackedVector2Array([Vector2(-10, y0 + tilt), Vector2(cl.w + 10, y0 - tilt), Vector2(cl.w + 10, y1 - tilt), Vector2(-10, y1 + tilt)])
				cl.shell(parts[i], rng.randf_range(0.006, 0.011) * H, m, cl.group(), poly, -1.0, 0.0, true)
			y += step
	var m2 := cl.mat(col.darkened(0.12), "cloth", {"mottle": col.darkened(0.4), "mottle_amt": 0.5})
	for k in 3:  # 엇갈린 띠
		var y := lerpf(j["neck"].y + 0.03, j["pelvis"].y - 0.06, k / 2.0)
		var s := -1.0 if k % 2 == 0 else 1.0
		var y0 := oy + y * H
		var poly := PackedVector2Array([Vector2(-10, y0 - s * 0.12 * H), Vector2(cl.w + 10, y0 + s * 0.12 * H), Vector2(cl.w + 10, y0 + s * 0.12 * H + 0.02 * H), Vector2(-10, y0 - s * 0.12 * H + 0.02 * H)])
		cl.shell(parts[1], 0.014 * H, m2, cl.group(), poly, -1.0, 0.0, true)
	var g := cl.group()
	for k in 3:  # 풀려 늘어진 끝자락
		var a: Vector3 = [j["elbow_l"], j["pelvis"] + Vector3(0.08, 0.02, 0.07), j["knee_r"]][k]
		Back.chain(cl, pr, g, [a + Vector3(0, 0, 0.03), a + Vector3(0.01, 0.05, 0.035), a + Vector3(-0.005, 0.1, 0.03)], [0.009, 0.008, 0.004], m2, 0.003)


static func _loin(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, col: Color, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "cloth")
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	BackKit.shell(cl, pr, ["pelvis", "thigh_l", "thigh_r"], 0.012, m, g, BackKit.band(cl, pr, pv.y - 0.06, pv.y + 0.03, rng, 0.012, 10), 0.006)
	var top := pv.y - 0.02
	var pts := PackedVector2Array()
	for v: Vector3 in [Vector3(-0.055, top, 0.09), Vector3(0.055, top, 0.09), Vector3(0.06, pv.y + 0.14, 0.08), Vector3(0.0, pv.y + 0.16, 0.085), Vector3(-0.06, pv.y + 0.14, 0.08)]:
		pts.append(Back.P2(pr, v))
	var z := cl.top_over(bd["torso"], pts)
	cl.slab(cl.group(), pts, z - 0.004 * float(pr["H"]), 0.008 * float(pr["H"]), m, 2.0, 0.012 * float(pr["H"]))


## 판금: 등판(아래 허리판 겹) · 어깨받이 겹판 · 팔뚝 · 허벅지 · 정강이 + 리벳.
static func _armor(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, col: Color, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "metal")
	var dark := cl.mat(col.darkened(0.35), "metal")
	var g := cl.group()
	var B := Vector3(0, 0, 1)
	var pv: Vector3 = j["pelvis"]
	var nk: Vector3 = j["neck"]
	var bw: float = bd["back_w"]
	BackKit.shell(cl, pr, ["torso", "pelvis"], 0.026, m, g, BackKit.band(cl, pr, nk.y + 0.012, pv.y - 0.04), 0.03, 0.004)
	for k in 3:  # 허리판 겹
		var y := pv.y - 0.06 + k * 0.03
		BackKit.shell(cl, pr, ["pelvis", "torso"], 0.03 + k * 0.004, m, cl.group(), BackKit.band(cl, pr, y, y + 0.032), 0.01)
	Back.ridge(cl, pr, g, [Vector3(0, nk.y + 0.03, bw + 0.03), Vector3(0, pv.y - 0.06, 0.09)], B, 0.006, 0.004, m)  # 등 가운데 능선
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var shp: Vector3 = j["shoulder_" + t]
		for k in 3:  # 어깨받이(위에서 아래로 겹친 판)
			var c := shp + Vector3(s * (0.018 + k * 0.006), 0.012 + k * 0.026, 0.0)
			Back.ell(cl, pr, cl.group(), c, 0.052 - k * 0.004, 0.034, 0.05 - k * 0.003, m, 0.004)
		var el: Vector3 = j["elbow_" + t]
		var wr: Vector3 = j["wrist_" + t]
		var ga := cl.group()
		BackKit.shell(cl, pr, ["fore_" + t], 0.01, m, ga, BackKit.band(cl, pr, minf(el.y, wr.y) + 0.02, maxf(el.y, wr.y) - 0.01), 0.004)
		Back.ell(cl, pr, ga, el + Vector3(0, 0, 0.02), 0.03, 0.03, 0.026, m, 0.004)  # 팔꿈치 판
		var kn: Vector3 = j["knee_" + t]
		var an: Vector3 = j["ankle_" + t]
		var gl := cl.group()
		BackKit.shell(cl, pr, ["shin_" + t], 0.014, m, gl, BackKit.band(cl, pr, kn.y + 0.02, an.y + 0.01), 0.006)
		BackKit.shell(cl, pr, ["thigh_" + t], 0.012, m, gl, BackKit.band(cl, pr, pv.y + 0.03, kn.y - 0.04), 0.006)
		Back.ell(cl, pr, gl, kn + Vector3(0, 0, -0.01), 0.034, 0.03, 0.03, m, 0.004)
		for k in 3:  # 정강이 판 이음매 · 리벳
			Back.groove(cl, pr, gl, [kn.lerp(an, 0.2 + k * 0.25) + Vector3(-0.03, 0, 0.03), kn.lerp(an, 0.2 + k * 0.25) + Vector3(0.03, 0, 0.03)], B, 0.003, 0.004)
		Back.bump(cl, pr, gl, an + Vector3(0, -0.04, 0.03), B, 0.005, 0.005, 0.003, dark)
	for k in 6:  # 등판 리벳
		var q := Vector3((k % 3 - 1) * 0.07, nk.y + 0.04 + int(k / 3) * 0.16, bw + 0.02)
		Back.bump(cl, pr, g, q, B, 0.005, 0.005, 0.004, dark)


## 긴 망토: 어깨에서 종아리까지 등 뒤를 덮고, 단은 찢겨 있다. 세로 주름.
static func _cape(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, col: Color, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "cloth", {"mottle": col.darkened(0.3), "mottle_amt": 0.4})
	var g := cl.group()
	var H: float = pr["H"]
	var bw: float = bd["back_w"]
	var shw := absf(j["shoulder_r"].x)
	var top: float = j["neck"].y + 0.012
	var bot := -0.11
	var wz := bw + 0.04
	var pts := PackedVector2Array()
	for i in 9:  # 위 단: 어깨선을 따라 휜다(어깨받이 안쪽에 걸림)
		var u := lerpf(-shw * 0.82, shw * 0.82, i / 8.0)
		pts.append(Back.P2(pr, Vector3(u, top + 0.03 * pow(absf(u) / shw, 1.6), wz)))
	var sides := 7
	for i in range(1, sides + 1):  # 오른쪽 가장자리: 아래로 갈수록 넓게 퍼짐
		var t := i / float(sides)
		pts.append(Back.P2(pr, Vector3(lerpf(shw * 0.82, shw * 1.3, pow(t, 0.7)), lerpf(top + 0.03, bot, t), wz - 0.03 * t)))
	var n := 14
	for i in range(1, n):
		var u := lerpf(shw * 1.3, -shw * 1.3, i / float(n))
		pts.append(Back.P2(pr, Vector3(u, bot + (rng.randf() * 0.04 if i % 2 == 0 else rng.randf() * 0.012), wz - 0.03)))
	for i in range(sides, 0, -1):
		var t := i / float(sides)
		pts.append(Back.P2(pr, Vector3(-lerpf(shw * 0.82, shw * 1.3, pow(t, 0.7)), lerpf(top + 0.03, bot, t), wz - 0.03 * t)))
	var z := Back.P(pr, Vector3(0, top, wz + (0.05 if j.has("armored") else 0.0))).z  # 판금 허리판보다 바깥
	cl.slab(g, pts, z - 0.03 * H, 0.04 * H, m, 2.0, 0.07 * H)
	var B := Vector3(0, 0, 1)
	for k in 9:  # 세로 주름(어깨에서 퍼져 내림)
		var u := lerpf(-shw * 0.9, shw * 0.9, (k + rng.randf_range(0.2, 0.8)) / 9.0)
		Back.groove(cl, pr, g, [Vector3(u * 0.6, top + 0.05, wz), Vector3(u * 1.2, (top + bot) * 0.5, wz), Vector3(u * 1.5, bot - 0.01, wz)], B, 0.008, 0.016)
	for k in 4:
		cl.erase(g, Back.P2(pr, Vector3(rng.randf_range(-shw, shw), rng.randf_range(bot - 0.08, bot - 0.02), wz)), rng.randf_range(0.01, 0.025) * H, rng.randf_range(0.015, 0.04) * H, 0.5)


## 투구: 머리를 덮은 둥근 쇠 + 목 가리개 + (plume) 붉은 깃 장식.
static func _helm(cl: Clay, pr: Dictionary, hd: Dictionary, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(kit["helm"], "metal")
	var g := cl.group()
	var c: Vector3 = hd["c"]
	var rv: float = hd["rv"]
	var H: float = pr["H"]
	var low := c.y + rv * (0.55 if kit.get("closed", false) else 0.25)
	BackKit.shell(cl, pr, ["skull", "ear"] + (["face"] if kit.get("closed", false) else []), 0.016, m, g, BackKit.band(cl, pr, c.y - rv * 2.0, low), 0.01)
	Back.ridge(cl, pr, g, [Back.on_head(hd, 1.4, PI, 0.018), Back.on_head(hd, 0.9, 0.0, 0.018), Back.on_head(hd, 0.2, 0.0, 0.018)], Vector3(0, -0.3, 1), 0.007, 0.006, m)  # 가운데 능선
	Back.ell(cl, pr, g, Back.on_head(hd, -0.15, 0.0, 0.02), float(hd["ru"]) * 0.9, rv * 0.25, float(hd["rw"]) * 0.3, m, 0.004)  # 목 가리개
	if kit.has("plume"):
		var pm := cl.mat(kit["plume"], "fur")
		var pg := cl.group()
		var pts: Array = []
		for k in 6:
			var t := k / 5.0
			pts.append(Back.on_head(hd, 1.45 - t * 1.6, 0.0, 0.03 + sin(t * PI) * 0.035) + Vector3(0, -0.01 * sin(t * PI), 0))
		Back.chain(cl, pr, pg, pts, [0.012, 0.022, 0.026, 0.024, 0.018, 0.008], pm, 0.01)
		for k in 7:
			var q: Vector3 = pts[rng.randi_range(0, 5)]
			Back.groove(cl, pr, pg, [q + Vector3(-0.01, -0.01, 0.02), q + Vector3(0.01, 0.02, 0.02)], Vector3(0, -0.3, 1), 0.003, 0.006)


## 장대 무기(창 spear · 기병창 lance): 쥔 손에서 위아래로 곧게, 끝은 쇠 날.
static func _pole(cl: Clay, pr: Dictionary, j: Dictionary, kit: Dictionary, t: String) -> void:
	var wood := cl.mat(kit.get("shaft_c", Color("#5a4632")), "wood")
	var metal := cl.mat(kit.get("weapon_c", Color("#8a9098")), "metal")
	var g := cl.group()
	var hd: Vector3 = j["hand_" + t]
	var lance := str(kit["weapon"]) == "lance"
	var up := Vector3(0.0, -1.0, -0.12).normalized()
	var top := hd + up * (0.62 if lance else 0.52)
	var bot := hd - up * (0.3 if lance else 0.4)
	Back.cap(cl, pr, g, bot, top, 0.009, 0.008 if not lance else 0.006, wood, 0.002)
	var tip := top + up * (0.09 if not lance else 0.06)
	Back.cap(cl, pr, g, top - up * 0.01, tip, 0.016, 0.001, metal, 0.002)
	if lance:
		Back.cap(cl, pr, g, hd + up * 0.02, hd + up * 0.13, 0.045, 0.01, metal, 0.002)  # 손 가리개(원뿔)
	Back.ell(cl, pr, g, hd + Vector3(0, 0, 0.01), 0.022, 0.03, 0.02, cl.mat(Color("#3a2a1e"), "leather"), 0.003)  # 쥔 손(장갑)


## 단검: 쥔 손에서 아래·앞으로 짧은 날(고블린).
static func _dagger(cl: Clay, pr: Dictionary, j: Dictionary, kit: Dictionary, t: String) -> void:
	var metal := cl.mat(kit.get("weapon_c", Color("#7a7468")), "metal")
	var grip := cl.mat(Color("#3a2a1e"), "leather")
	var g := cl.group()
	var hd: Vector3 = j["hand_" + t]
	var down := Vector3(0.0, 1.0, -0.35).normalized()
	Back.cap(cl, pr, g, hd - down * 0.03, hd + down * 0.02, 0.008, 0.008, grip, 0.002)
	Back.cap(cl, pr, g, hd + down * 0.02, hd + down * 0.14, 0.012, 0.001, metal, 0.002)


## 방패: 몸 앞에 든 방패를 뒤에서 — 안쪽 면(나무 판·가죽 손잡이)이 팔 너머로 보인다.
static func _shield(cl: Clay, pr: Dictionary, j: Dictionary, kit: Dictionary, t: String) -> void:
	var metal_face := str(kit.get("shield_mat", "wood")) == "metal"
	var m := cl.mat(kit["shield"], "metal" if metal_face else "wood")
	var strap := cl.mat(Color("#3a2618"), "leather")
	var rim := cl.mat(Color("#6a6258"), "metal")
	var g := cl.group()
	var B := Vector3(0, 0, 1)
	var el: Vector3 = j["elbow_" + t]
	var wr: Vector3 = j["wrist_" + t]
	var c := el.lerp(wr, 0.5) + Vector3(0, 0, -0.04)
	var kite := str(kit.get("shield_kind", "round")) == "kite"
	var pts := PackedVector2Array()
	var n := 28
	for i in n:
		var a := TAU * i / n
		var v := Vector3(cos(a) * 0.12, sin(a) * 0.12, 0)
		if kite:
			v = Vector3(cos(a) * 0.11 * (1.0 - maxf(0.0, sin(a)) * 0.55), sin(a) * (0.2 if sin(a) > 0.0 else 0.12), 0)
		pts.append(Back.P2(pr, c + v))
	var z := Back.P(pr, c).z
	var H: float = pr["H"]
	cl.slab(g, pts, z - 0.02 * H, 0.012 * H, m, 2.0, 0.012 * H)
	var ring: Array = []
	for i in pts.size() + 1:
		var q := pts[i % pts.size()]
		ring.append(Vector2(lerpf(q.x, Back.P2(pr, c).x, 0.04), lerpf(q.y, Back.P2(pr, c).y, 0.04)))
	cl.ridge(g, ring, 0.008 * H, 0.006 * H, rim)  # 테두리 쇠
	if not metal_face:
		for k in 4:  # 나무 판 이음매
			var u := lerpf(-0.08, 0.08, (k + 0.5) / 4.0)
			Back.groove(cl, pr, g, [c + Vector3(u, -0.11, 0.0), c + Vector3(u, 0.11, 0.0)], B, 0.003, 0.004)
	Back.ridge(cl, pr, g, [c + Vector3(-0.07, -0.02, 0), c + Vector3(0.07, 0.02, 0)], B, 0.008, 0.006, strap)  # 팔 끈
	Back.ridge(cl, pr, g, [c + Vector3(-0.05, 0.05, 0), c + Vector3(0.05, 0.06, 0)], B, 0.008, 0.006, strap)
