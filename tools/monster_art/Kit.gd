extends RefCounted
## 사람형 몬스터의 옷·갑옷(Clay): 몸 부위 기록(tag)을 부풀려 한 겹 더 씌우는 shell + 늘어진 천 판(slab) + 주름 골.
## kit 키(색): shirt(찢어진 윗옷, shirt_len 0~1, sleeves) · robe(긴 옷) · loin(허리천) · skirt(무릎 아래까지 두른 천)
##            cape(뒤 망토) · fur(어깨 털 망토) · armor(가슴판·어깨받이·팔뚝·정강이) · plates(갑옷 부위 목록) · belt · boots
##            wraps(붕대 — 감은 정도 wraps_amt 0~1) · straps(가슴 가죽끈) · collar(목 고리) · torn(옷 구멍 0~1)
## 몸 앞에 오는 것과 뒤(망토)는 서로 다른 그룹 — 경계에 잉크 선이 생긴다.

const Clay := preload("res://tools/monster_art/Clay.gd")


static func dress(cl: Clay, j: Dictionary, H: float, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	if kit.has("cape"):
		_cape(cl, j, H, kit, rng)
	if kit.has("skirt"):
		_skirt(cl, j, H, kit["skirt"], float(kit.get("skirt_len", 0.75)), rng)
	if kit.has("robe"):
		_robe(cl, j, H, kit, rng)
	if kit.has("wraps"):
		_wraps(cl, j, H, kit["wraps"], float(kit.get("wraps_amt", 0.7)), rng, bool(kit.get("wraps_head", false)))
	if kit.has("shirt"):
		_shirt(cl, j, H, kit, rng)
	if kit.has("boots"):
		var m := cl.mat(kit["boots"], "leather")
		var g := cl.group()
		for tag: String in ["l", "r"]:
			var kn: Vector3 = j["knee_" + tag]
			var an: Vector3 = j["ankle_" + tag]
			var top := kn.lerp(an, 0.35).y
			cl.shell(["leg_" + tag, "foot_" + tag], 0.007 * H, m, g, _band(0, top, cl.w, cl.h, rng, 0.01 * H, 8), 6.0)
			cl.ridge(g, [Vector2(kn.x - 0.035 * H, top + 0.006 * H), Vector2(kn.x + 0.035 * H, top + 0.006 * H)], 0.008 * H, 0.004 * H, m)
	if kit.has("loin"):
		_loin(cl, j, H, kit["loin"], float(kit.get("loin_len", 0.12)), rng)
	if kit.has("belt"):
		var m := cl.mat(kit["belt"], "leather")
		var g := cl.group()
		var pv: Vector3 = j["pelvis"]
		var y0 := pv.y - 0.06 * H
		cl.shell(["torso"], 0.012 * H, m, g, _band(y0, y0 + 0.028 * H, cl.w, 0, rng, 0.0, 2), 4.0)
		var bz := cl.surf(g, pv.x, y0 + 0.014 * H)
		if bz > Clay.EMPTY * 0.5:
			cl.ell(g, Vector3(pv.x, y0 + 0.014 * H, bz), 0.018 * H, 0.016 * H, 0.006 * H, cl.mat(Color("#8a7a58"), "metal"), 1.0)
	if kit.has("straps"):
		var m := cl.mat(kit["straps"], "leather")
		var g := cl.group()
		var a: Vector3 = j["shoulder_r"]
		var b: Vector3 = j["hip_l"]
		var wd := 0.016 * H
		var poly := PackedVector2Array([Vector2(a.x - wd, a.y - wd * 2), Vector2(a.x + wd, a.y), Vector2(b.x + wd, b.y - 0.04 * H), Vector2(b.x - wd, b.y - 0.05 * H)])
		cl.shell(["torso"], 0.01 * H, m, g, poly, 3.0)
	if kit.has("fur"):
		_fur(cl, j, H, kit["fur"], rng)
	if kit.has("armor"):
		_armor(cl, j, H, kit, rng)
	if kit.has("collar"):
		var m := cl.mat(kit["collar"], "metal")
		var g := cl.group()
		var nk: Vector3 = j["neck"]
		cl.shell(["torso"], 0.014 * H, m, g, _band(nk.y - 0.03 * H, nk.y + 0.012 * H, cl.w, 0, rng, 0.0, 2), 3.0)


## 화면 가로 띠 다각형(y0~y1). jag > 0이면 아래 가장자리를 n번 들쭉날쭉 찢는다. w0 = 폭(0이면 캔버스 전체).
static func _band(y0: float, y1: float, w: float, _h: float, rng: RandomNumberGenerator, jag: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(-10, y0), Vector2(w + 10, y0)])
	for i in n + 1:
		var x := w + 10 - (w + 20) * i / float(n)
		var dy := 0.0
		if jag > 0.0:
			dy = (rng.randf() - 0.3) * jag * (2.0 if i % 2 == 0 else 0.6)
		pts.append(Vector2(x, y1 + dy))
	return pts


## 찢어진 단(점 a→b 사이를 n번 들쭉날쭉): 너덜너덜한 천 끝.
static func hem(a: Vector2, b: Vector2, n: int, amp: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var q := a.lerp(b, t)
		var dy := amp * (rng.randf() * (1.0 if i % 2 == 0 else 0.35)) * (1.0 if i > 0 and i < n else 0.2)
		pts.append(q + Vector2(rng.randf_range(-0.3, 0.3) * amp, dy))
	return pts


## 세로 주름(천 판 g 위): top 줄에서 bottom 줄까지 n개의 골.
static func folds(cl: Clay, g: int, top_a: Vector2, top_b: Vector2, bot_a: Vector2, bot_b: Vector2, n: int, width: float, depth: float, rng: RandomNumberGenerator) -> void:
	for i in n:
		var t := (i + 0.5 + rng.randf_range(-0.3, 0.3)) / n
		var a := top_a.lerp(top_b, t)
		var b := bot_a.lerp(bot_b, clampf(t + rng.randf_range(-0.08, 0.08), 0.0, 1.0))
		var m := a.lerp(b, 0.5) + Vector2(rng.randf_range(-1, 1) * width * 2.0, 0)
		cl.grooves(g, [a.lerp(b, rng.randf_range(0.0, 0.25)), m, b], width * rng.randf_range(0.7, 1.3), depth * rng.randf_range(0.6, 1.2))


static func _loin(cl: Clay, j: Dictionary, H: float, col: Color, ln: float, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "cloth")
	var pv: Vector3 = j["pelvis"]
	var tg: int = j["torso"]
	# 허리에 두른 띠(골반·허벅지 위쪽을 한 겹)
	var g := cl.group()
	var y0 := pv.y - 0.055 * H
	var y1 := pv.y + 0.035 * H
	cl.shell(["torso", "leg_l", "leg_r"], 0.01 * H, m, g, _band(y0, y1, cl.w, 0, rng, 0.012 * H, 10), 6.0)
	folds(cl, g, Vector2(pv.x - 0.08 * H, y0), Vector2(pv.x + 0.08 * H, y0), Vector2(pv.x - 0.09 * H, y1), Vector2(pv.x + 0.09 * H, y1), 5, 0.004 * H, 0.004 * H, rng)
	# 앞 자락(가운데로 늘어진 천)
	var g2 := cl.group()
	var fw := 0.05 * H
	var top := y0 + 0.02 * H
	var bot := pv.y + ln * H
	var flap := PackedVector2Array([Vector2(pv.x - fw, top), Vector2(pv.x + fw, top)])
	flap.append_array(hem(Vector2(pv.x + fw * 0.9, bot), Vector2(pv.x - fw * 0.9, bot), 7, 0.025 * H, rng))
	var z := cl.top_over(tg, flap)
	cl.slab(g2, flap, z - 0.004 * H, 0.008 * H, m, 2.0, 0.012 * H, Vector2(0, 0.06))
	folds(cl, g2, Vector2(pv.x - fw * 0.7, top), Vector2(pv.x + fw * 0.7, top), Vector2(pv.x - fw, bot), Vector2(pv.x + fw, bot), 3, 0.005 * H, 0.005 * H, rng)


static func _skirt(cl: Clay, j: Dictionary, H: float, col: Color, ln: float, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "cloth")
	var pv: Vector3 = j["pelvis"]
	var tg: int = j["torso"]
	var g := cl.group()
	var top := pv.y - 0.025 * H
	var bot := pv.y + ln * 0.5 * H
	var hl: Vector3 = j["knee_l"]
	var hr: Vector3 = j["knee_r"]
	var hw := absf(j["hip_r"].x - j["hip_l"].x) * 0.5 + 0.06 * H
	var bw := maxf(hw * 1.15, absf(hr.x - hl.x) * 0.5 + 0.05 * H)
	var poly := PackedVector2Array([Vector2(pv.x - hw, top), Vector2(pv.x + hw, top), Vector2(pv.x + bw, bot)])
	poly.append_array(hem(Vector2(pv.x + bw, bot), Vector2(pv.x - bw, bot), 12, 0.035 * H, rng))
	var z := cl.top_over(tg, poly)
	cl.slab(g, poly, z - 0.02 * H, 0.03 * H, m, 3.0, hw * 0.6)
	folds(cl, g, Vector2(pv.x - hw, top), Vector2(pv.x + hw, top), Vector2(pv.x - bw, bot), Vector2(pv.x + bw, bot), 9, 0.006 * H, 0.012 * H, rng)
	var sash := cl.group()  # 허리에 감아 묶은 띠(치마 윗단을 덮는다)
	cl.shell(["torso", "leg_l", "leg_r"], 0.02 * H, m, sash, _band(top - 0.045 * H, top + 0.025 * H, cl.w, 0, rng, 0.01 * H, 8), 8.0)
	folds(cl, sash, Vector2(pv.x - hw, top - 0.04 * H), Vector2(pv.x + hw, top - 0.04 * H), Vector2(pv.x - hw, top + 0.02 * H), Vector2(pv.x + hw, top + 0.02 * H), 5, 0.004 * H, 0.006 * H, rng)


static func _robe(cl: Clay, j: Dictionary, H: float, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(kit["robe"], "cloth")
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	var tg: int = j["torso"]
	# 윗몸 + 소매(손목까지)
	var clip := PackedVector2Array([Vector2(-10, nk.y - 0.01 * H), Vector2(nk.x - 0.03 * H, nk.y - 0.01 * H), Vector2(nk.x, nk.y + 0.06 * H), Vector2(nk.x + 0.03 * H, nk.y - 0.01 * H), Vector2(cl.w + 10, nk.y - 0.01 * H), Vector2(cl.w + 10, cl.h), Vector2(-10, cl.h)])
	cl.shell(["torso", "shoulder_l", "shoulder_r"], 0.02 * H, m, g, clip, 0.06 * H)
	for tag: String in ["l", "r"]:
		var ga := cl.group()
		cl.shell(["arm_" + tag], 0.014 * H, m, ga, clip, 8.0)
		var wr: Vector3 = j["wrist_" + tag]
		var el: Vector3 = j["elbow_" + tag]
		folds(cl, ga, Vector2(el.x, el.y), Vector2(el.x, el.y), Vector2(wr.x - 0.02 * H, wr.y), Vector2(wr.x + 0.02 * H, wr.y), 3, 0.004 * H, 0.006 * H, rng)
	# 아래 자락(가슴 아래부터 종 모양으로 발목까지 — 허리가 잘록하지 않게)
	var g2 := cl.group()
	var top: float = j["chest"].y + 0.03 * H
	var bot: float = maxf(j["ankle_l"].y, j["ankle_r"].y) + 0.03 * H
	var hw := absf(j["shoulder_r"].x - j["shoulder_l"].x) * 0.5 * 0.82
	var bw := maxf(hw * 1.2, absf(j["ankle_r"].x - j["ankle_l"].x) * 0.5 + 0.09 * H)
	var poly := PackedVector2Array([Vector2(pv.x - hw, top), Vector2(pv.x + hw, top), Vector2(pv.x + bw, bot)])
	poly.append_array(hem(Vector2(pv.x + bw, bot), Vector2(pv.x - bw, bot), 14, 0.03 * H * float(kit.get("torn", 0.5)) + 0.004 * H, rng))
	var z := cl.top_over(tg, poly)
	cl.slab(g2, poly, z - 0.03 * H, 0.04 * H, m, 3.0, hw * 0.7)
	folds(cl, g2, Vector2(pv.x - hw, top), Vector2(pv.x + hw, top), Vector2(pv.x - bw, bot), Vector2(pv.x + bw, bot), 10, 0.007 * H, 0.016 * H, rng)
	if kit.has("hood_back"):  # 두건이 등 뒤로 늘어진 자락
		pass


static func _shirt(cl: Clay, j: Dictionary, H: float, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(kit["shirt"], "cloth")
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	var bot := lerpf(j["chest"].y, pv.y + 0.02 * H, float(kit.get("shirt_len", 0.8)))
	var clip := PackedVector2Array([Vector2(-10, nk.y), Vector2(nk.x - 0.035 * H, nk.y), Vector2(nk.x, nk.y + 0.05 * H), Vector2(nk.x + 0.035 * H, nk.y), Vector2(cl.w + 10, nk.y)])
	clip.append_array(hem(Vector2(cl.w + 10, bot), Vector2(-10, bot), 16, 0.035 * H, rng))
	var tags := ["torso", "shoulder_l", "shoulder_r"]
	if kit.get("sleeves", true):
		var el: Vector3 = j["elbow_l"]
		for tag: String in ["l", "r"]:
			tags.append("arm_" + tag)
		clip = PackedVector2Array(clip)
		var cut := el.y + 0.02 * H  # 소매는 팔꿈치 근처까지
		var sl := PackedVector2Array()
		for v in clip:
			sl.append(v)
		cl.shell(["arm_l", "arm_r"], 0.008 * H, m, cl.group(), _band(nk.y, cut, cl.w, 0, rng, 0.02 * H, 10), 6.0)
		tags = ["torso", "shoulder_l", "shoulder_r"]
	cl.shell(tags, 0.009 * H, m, g, clip, 8.0)
	var sl3: Vector3 = j["shoulder_l"]
	var sr3: Vector3 = j["shoulder_r"]
	folds(cl, g, Vector2(sl3.x + 0.02 * H, sl3.y), Vector2(sr3.x - 0.02 * H, sr3.y), Vector2(pv.x - 0.07 * H, bot), Vector2(pv.x + 0.07 * H, bot), 6, 0.005 * H, 0.008 * H, rng)
	var torn := float(kit.get("torn", 0.4))
	for i in int(torn * 6):  # 찢어진 구멍
		var c := Vector2(lerpf(sl3.x, sr3.x, rng.randf_range(0.15, 0.85)), lerpf(nk.y + 0.06 * H, bot - 0.02 * H, rng.randf()))
		cl.erase(g, c, rng.randf_range(0.012, 0.03) * H, rng.randf_range(0.01, 0.022) * H, 0.45)


static func _cape(cl: Clay, j: Dictionary, H: float, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(kit["cape"], "cloth")
	var g := cl.group()
	var sl: Vector3 = j["shoulder_l"]
	var sr: Vector3 = j["shoulder_r"]
	var bot: float = lerpf(j["knee_l"].y, maxf(j["ankle_l"].y, j["ankle_r"].y), float(kit.get("cape_len", 0.85)))
	var spread := 0.07 * H
	var poly := PackedVector2Array([Vector2(sl.x + 0.01 * H, sl.y - 0.02 * H), Vector2(sr.x - 0.01 * H, sr.y - 0.02 * H), Vector2(sr.x + spread, bot)])
	poly.append_array(hem(Vector2(sr.x + spread, bot), Vector2(sl.x - spread, bot), 14, 0.05 * H, rng))
	var dep: float = j["depth"]
	cl.slab(g, poly, -dep * 1.3, 0.03 * H, m, 3.0, 0.05 * H)
	folds(cl, g, Vector2(sl.x, sl.y), Vector2(sr.x, sr.y), Vector2(sl.x - spread, bot), Vector2(sr.x + spread, bot), 9, 0.008 * H, 0.02 * H, rng)
	# 앞에서 보이는 어깨 위 깃
	var g2 := cl.group()
	var nk: Vector3 = j["neck"]
	for s: float in [-1.0, 1.0]:  # 어깨 위로 넘어온 자락(가슴 가운데는 비움)
		var sv: Vector3 = sr if s > 0.0 else sl
		var x0 := nk.x + s * 0.045 * H
		var x1 := sv.x + s * 0.06 * H
		var cp := PackedVector2Array([Vector2(x0, nk.y - 0.03 * H), Vector2(x1, nk.y - 0.03 * H), Vector2(x1, sv.y + 0.05 * H), Vector2(x0, sv.y + 0.02 * H)])
		cl.shell(["torso", "shoulder_l", "shoulder_r"], 0.016 * H, m, g2, cp, 8.0)


static func _fur(cl: Clay, j: Dictionary, H: float, col: Color, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "fur")
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var ch: Vector3 = j["chest"]
	cl.shell(["torso", "shoulder_l", "shoulder_r"], 0.02 * H, m, g, _band(nk.y - 0.03 * H, lerpf(nk.y, ch.y, 0.55), cl.w, 0, rng, 0.04 * H, 16), 10.0, 0.006 * H)
	j["fur_group"] = g


static func _wraps(cl: Clay, j: Dictionary, H: float, col: Color, amt: float, rng: RandomNumberGenerator, head: bool) -> void:
	var m := cl.mat(col, "cloth", {"hatch": 0.6})
	var tags := ["torso", "shoulder_l", "shoulder_r", "arm_l", "arm_r", "leg_l", "leg_r", "hand_l", "hand_r", "foot_l", "foot_r"]
	if head:
		tags.append("head")
	var sw := 0.022 * H
	var y := 0.0
	var k := 0
	while y < cl.h:
		var g := cl.group()  # 띠마다 따로 — 띠 사이에 잉크 선
		var tilt := (0.18 if k % 2 == 0 else -0.12) * cl.w
		var wd := sw * rng.randf_range(0.8, 1.2)
		if rng.randf() < amt:
			var poly := PackedVector2Array([Vector2(-10, y), Vector2(cl.w + 10, y + tilt), Vector2(cl.w + 10, y + tilt + wd), Vector2(-10, y + wd)])
			cl.shell(tags, 0.006 * H + rng.randf() * 0.003 * H, m, g, poly, 3.0)
		y += wd * rng.randf_range(0.85, 1.05)
		k += 1


static func _armor(cl: Clay, j: Dictionary, H: float, kit: Dictionary, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(kit["armor"], "metal")
	var parts: Array = kit.get("plates", ["chest", "shoulders", "arms", "legs"])
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	if parts.has("chest"):
		var g := cl.group()
		var clip := PackedVector2Array([Vector2(-10, nk.y + 0.005 * H), Vector2(nk.x - 0.03 * H, nk.y + 0.005 * H), Vector2(nk.x, nk.y + 0.03 * H), Vector2(nk.x + 0.03 * H, nk.y + 0.005 * H), Vector2(cl.w + 10, nk.y + 0.005 * H), Vector2(cl.w + 10, pv.y - 0.02 * H), Vector2(-10, pv.y - 0.02 * H)])
		cl.shell(["torso"], 0.016 * H, m, g, clip, 30.0)
		cl.ridge(g, [Vector2(nk.x, nk.y + 0.04 * H), Vector2(nk.x, j["waist"].y)], 0.008 * H, 0.004 * H, m)
		for i in 3:  # 배 판 이음매
			var yy: float = lerpf(j["waist"].y - 0.02 * H, pv.y - 0.03 * H, i / 2.0)
			cl.groove(g, Vector2(pv.x - 0.12 * H, yy), Vector2(pv.x + 0.12 * H, yy), 0.004 * H, 0.008 * H)
		# 허리 아래 판(tasset)
		var g2 := cl.group()
		for s: int in [-1, 1]:
			var x0 := pv.x + s * 0.01 * H
			var x1 := pv.x + s * 0.085 * H
			var poly := PackedVector2Array([Vector2(x0, pv.y - 0.03 * H), Vector2(x1, pv.y - 0.03 * H), Vector2(x1 + s * 0.01 * H, pv.y + 0.07 * H), Vector2(x0, pv.y + 0.065 * H)])
			cl.slab(g2, poly, cl.top_over(j["torso"], poly) - 0.002 * H, 0.008 * H, m, 1.0, 0.01 * H)
	if parts.has("shoulders"):
		var g := cl.group()
		for tag: String in ["l", "r"]:
			var s := -1.0 if tag == "l" else 1.0
			var sh: Vector3 = j["shoulder_" + tag]
			var ua: float = j["r_ua"]
			for i in 3:  # 겹친 어깨받이 판
				var c := sh + Vector3(s * ua * (0.3 + i * 0.25), ua * (0.1 + i * 0.55), ua * (1.0 - i * 0.2))
				cl.ell(g, c, ua * (1.55 - i * 0.12), ua * (1.0 - i * 0.1), ua * 0.9, m, 1.0, s * 0.35)
	if parts.has("arms"):
		var g := cl.group()
		for tag: String in ["l", "r"]:
			var el: Vector3 = j["elbow_" + tag]
			var wr: Vector3 = j["wrist_" + tag]
			cl.shell(["arm_" + tag], 0.01 * H, m, g, _seg_poly(el.lerp(wr, 0.2), wr, 0.08 * H), 3.0)
	if parts.has("legs"):
		var g := cl.group()
		for tag: String in ["l", "r"]:
			var kn: Vector3 = j["knee_" + tag]
			var an: Vector3 = j["ankle_" + tag]
			cl.shell(["leg_" + tag, "foot_" + tag], 0.01 * H, m, g, _seg_poly(kn + Vector3(0, -0.03 * H, 0), an + Vector3(0, 0.06 * H, 0), 0.09 * H), 3.0)
			cl.ell(g, kn + Vector3(0, 0, float(j["r_th"]) * 0.9), float(j["r_th"]) * 0.8, float(j["r_th"]) * 0.7, float(j["r_th"]) * 0.5, m, 1.0)


## 선분 a→b를 감싸는 사각 다각형(폭 2*w).
static func _seg_poly(a: Vector3, b: Vector3, w: float) -> PackedVector2Array:
	var d := Vector2(b.x - a.x, b.y - a.y).normalized()
	var n := Vector2(-d.y, d.x) * w
	return PackedVector2Array([Vector2(a.x, a.y) + n, Vector2(b.x, b.y) + n, Vector2(b.x, b.y) - n, Vector2(a.x, a.y) - n])
