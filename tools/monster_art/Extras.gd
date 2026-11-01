extends RefCounted
## 사람형에 덧붙이는 것: 뒤(날개·꼬리) · 앞(가시·몸에 박힌 눈·꿰맨 자국·허리 폭탄·얼음 결정) · 칠한 뒤(꿰맨 실·서리).
## extras 키: wings(색 — 박쥐 날개) · wing_span · tail(색) · spikes(색 — 어깨·등 가시) · body_eyes(개수) · stitches(true)
##            bombs(개수) · crystals(색) · frost(0~1) · lumps(울퉁불퉁 혹 개수 — 바위 피부)
##            maggots(개수) · maggot_c(색) — 몸통·팔·다리 겉에 붙어 꿈틀대는 구더기(마디진 짧은 통 — 드레드피어, V27)

const Clay := preload("res://tools/monster_art/Clay.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")


static func behind(cl: Clay, j: Dictionary, H: float, ex: Dictionary, _rng: RandomNumberGenerator) -> void:
	var dep := 0.07 * H
	if ex.has("wings"):
		var m := cl.mat(ex["wings"], "leather", {"hatch": 0.6})
		var bone := cl.mat(Color(ex["wings"]).darkened(0.35), "bone")
		var span := float(ex.get("wing_span", 1.0))
		for s: int in [-1, 1]:
			var g := cl.group()
			var sh: Vector3 = j["shoulder_" + ("l" if s < 0 else "r")]
			var root := Vector3(sh.x - s * 0.03 * H, sh.y + 0.02 * H, -dep * 1.3)
			var el := root + Vector3(s * 0.17 * H * span, -0.14 * H * span, -dep * 0.2)
			var wr := el + Vector3(s * 0.14 * H * span, 0.04 * H * span, -dep * 0.1)
			var tips := [wr + Vector3(s * 0.14 * H * span, 0.14 * H * span, 0), wr + Vector3(s * 0.09 * H * span, 0.3 * H * span, 0), wr + Vector3(-s * 0.02 * H * span, 0.38 * H * span, 0)]
			var body := root + Vector3(s * 0.05 * H, 0.3 * H, 0)
			var poly := PackedVector2Array([Vector2(root.x, root.y), Vector2(el.x, el.y), Vector2(wr.x, wr.y)])
			var prev: Vector3 = wr
			for t: Vector3 in tips:
				var mid := prev.lerp(t, 0.5)
				if prev != wr:
					poly.append(Vector2(mid.x, mid.y) + Vector2(-s * 0.03 * H, -0.02 * H))  # 막이 안으로 처진 자리
				poly.append(Vector2(t.x, t.y))
				prev = t
			var mid2: Vector3 = prev.lerp(body, 0.5)
			poly.append(Vector2(mid2.x, mid2.y) + Vector2(-s * 0.02 * H, -0.04 * H))
			poly.append(Vector2(body.x, body.y))
			cl.slab(g, poly, -dep * 1.6, 0.012 * H, m, 2.0, 0.02 * H)
			cl.chain(g, [root, el, wr], [0.016 * H, 0.012 * H, 0.009 * H], bone, 2.0)
			for t: Vector3 in tips:
				cl.cap(g, wr, t, 0.007 * H, 0.003 * H, bone, 1.0)
				cl.groove(g, Vector2(wr.x, wr.y).lerp(Vector2(t.x, t.y), 0.2), Vector2(t.x, t.y), 0.004 * H, 0.004 * H)
			cl.ell(g, el, 0.016 * H, 0.016 * H, 0.012 * H, bone, 1.0)
			cl.cap(g, el, el + Vector3(s * 0.01 * H, -0.05 * H, 0), 0.008 * H, 0.002 * H, bone, 1.0)  # 날개 발톱
	if ex.has("tail"):
		var m := cl.mat(ex["tail"], "skin")
		var g := cl.group()
		var pv: Vector3 = j["pelvis"]
		var pts := [pv + Vector3(0, 0.02 * H, -dep), pv + Vector3(0.1 * H, 0.1 * H, -dep * 1.1), pv + Vector3(0.19 * H, 0.22 * H, -dep * 0.9), pv + Vector3(0.22 * H, 0.36 * H, -dep * 0.6), pv + Vector3(0.3 * H, 0.42 * H, -dep * 0.4)]
		cl.chain(g, pts, [0.04 * H, 0.032 * H, 0.024 * H, 0.014 * H, 0.004 * H], m, 6.0)


static func front(cl: Clay, j: Dictionary, H: float, ex: Dictionary, rng: RandomNumberGenerator) -> void:
	var tg: int = j["torso"]
	if ex.has("lumps"):  # 바위 같은 혹(살갗 재질 = 첫 재질)
		for tag: String in ["torso", "arm_l", "arm_r"]:
			var g: int = tg if tag == "torso" else j[tag]
			for k in int(ex["lumps"]):
				var c := Vector2(rng.randf_range(0.2, 0.8) * cl.w, rng.randf_range(0.15, 0.85) * cl.h)
				var z := cl.surf(g, c.x, c.y)
				if z > Clay.EMPTY * 0.5:
					var r := rng.randf_range(0.02, 0.045) * H
					cl.bump(g, c, r, r * rng.randf_range(0.7, 1.1), r * 0.35, 0, 2.0, rng.randf() * PI)
	if ex.has("maggots"):
		_maggots(cl, j, H, int(ex["maggots"]), ex.get("maggot_c", Color("#ddd0aa")) as Color, rng)
	if ex.has("spikes"):
		var m := cl.mat(ex["spikes"], "bone")
		var g := cl.group()
		for s: int in [-1, 1]:
			var sh: Vector3 = j["shoulder_" + ("l" if s < 0 else "r")]
			for k in 4:
				var b := sh + Vector3(s * (0.0 + k * 0.012) * H, (-0.01 + k * 0.025) * H, -0.01 * H)
				var t := b + Vector3(s * (0.05 + k * 0.012) * H, -(0.09 - k * 0.015) * H, 0.0)
				cl.cap(g, b, t, 0.016 * H, 0.002 * H, m, 1.0)
		var nk: Vector3 = j["neck"]
		for k in 3:  # 등줄기 가시(어깨 너머로 보임)
			var b := nk + Vector3((k - 1) * 0.04 * H, 0.0, -0.06 * H)
			cl.cap(g, b, b + Vector3((k - 1) * 0.02 * H, -0.1 * H, -0.02 * H), 0.018 * H, 0.002 * H, m, 1.0)
	if ex.has("body_eyes"):
		var em := cl.mat(Color("#e8dcb0"), "eye")
		for k in int(ex["body_eyes"]):
			var tag: String = ["torso", "torso", "arm_l", "arm_r", "torso", "torso"][k % 6]
			var g: int = tg if tag == "torso" else j[tag]
			var c: Vector2
			if tag == "torso":
				var ch: Vector3 = j["chest"]
				c = Vector2(ch.x + rng.randf_range(-0.08, 0.08) * H, ch.y + rng.randf_range(-0.04, 0.12) * H)
			else:
				var el: Vector3 = j["elbow_" + tag.right(1)]
				c = Vector2(el.x, el.y) + Vector2(rng.randf_range(-0.01, 0.01), rng.randf_range(-0.06, 0.02)) * H
			cl.carve(g, c, 0.022 * H, 0.014 * H, 0.012 * H)
			cl.bump(g, c, 0.016 * H, 0.011 * H, 0.004 * H, em, 0.5)
			j["eye_spots"] = j.get("eye_spots", []) + [c]
	if ex.has("stitches"):
		var ch: Vector3 = j["chest"]
		var wa: Vector3 = j["waist"]
		var lines: Array = [[Vector2(ch.x - 0.1 * H, ch.y - 0.05 * H), Vector2(ch.x + 0.04 * H, ch.y + 0.03 * H), Vector2(wa.x + 0.09 * H, wa.y + 0.02 * H)], [Vector2(wa.x - 0.08 * H, wa.y - 0.04 * H), Vector2(wa.x + 0.02 * H, wa.y + 0.06 * H)]]
		for ln: Array in lines:
			cl.grooves(tg, ln, 0.006 * H, 0.008 * H)
		j["stitch_lines"] = lines
	if ex.has("bombs"):
		var m := cl.mat(Color("#2a2826"), "metal")
		var g := cl.group()
		var pv: Vector3 = j["pelvis"]
		for k in int(ex["bombs"]):
			var x := pv.x + (k - (int(ex["bombs"]) - 1) * 0.5) * 0.05 * H
			var z := cl.surf(tg, x, pv.y - 0.04 * H)
			cl.ell(g, Vector3(x, pv.y - 0.025 * H, z + 0.01 * H), 0.024 * H, 0.024 * H, 0.022 * H, m, 1.0)
	if ex.has("crystals"):
		var m := cl.mat(ex["crystals"], "slime", {"spec": 1.2})
		var g := cl.group()
		for k in 8:
			var tag: String = ["shoulder_l", "shoulder_r", "arm_l", "arm_r"][k % 4]
			var key: String = ("shoulder_" + tag.right(1)) if k % 4 < 2 else ("elbow_" + tag.right(1))
			var b: Vector3 = j[key]
			var s := -1.0 if tag.ends_with("l") else 1.0
			b += Vector3(rng.randf_range(-0.02, 0.02) * H, rng.randf_range(-0.02, 0.03) * H, 0.02 * H)
			var t := b + Vector3(s * rng.randf_range(0.02, 0.06) * H, -rng.randf_range(0.04, 0.1) * H, 0.01 * H)
			cl.cap(g, b, t, rng.randf_range(0.012, 0.022) * H, 0.002 * H, m, 0.5)


## 칠한 뒤: 꿰맨 실(가로 눈금) · 서리(흰 반점) · 몸에 박힌 눈의 눈꺼풀.
static func after(p: Paint, _cl: Clay, j: Dictionary, H: float, ex: Dictionary, rng: RandomNumberGenerator) -> void:
	if j.has("stitch_lines"):
		for ln: Array in j["stitch_lines"]:
			for i in ln.size() - 1:
				var a: Vector2 = ln[i]
				var b: Vector2 = ln[i + 1]
				var d := (b - a).normalized()
				var n := Vector2(-d.y, d.x)
				var cnt := int(a.distance_to(b) / (0.018 * H))
				for k in cnt:
					var q := a.lerp(b, (k + 0.5) / cnt)
					Ink.line(p, q - n * 0.012 * H - d * 0.003 * H, q + n * 0.012 * H + d * 0.003 * H, maxf(1.0, H / 350.0), Color("#1a1210"), 0.85, 0.3)
	for c: Vector2 in j.get("eye_spots", []):
		var up := PackedVector2Array()
		for k in 7:
			var t := -1.0 + k / 3.0
			up.append(c + Vector2(t * 0.02 * H, -sqrt(maxf(0.0, 1.0 - t * t)) * 0.012 * H))
		Ink.path(p, up, maxf(1.2, H / 300.0), false, Ink.INK, 0.9, 0.3)
		for yy in range(int(c.y - 0.006 * H), int(c.y + 0.006 * H) + 1):
			for xx in range(int(c.x - 0.006 * H), int(c.x + 0.006 * H) + 1):
				if Vector2(xx - c.x, yy - c.y).length() < 0.0055 * H:
					p.blend(xx, yy, Color("#1a0c08"), 0.9)
	var frost := float(ex.get("frost", 0.0))
	if frost > 0.0:
		for k in int(frost * 900):
			var x := rng.randi_range(0, p.w - 1)
			var y := rng.randi_range(0, p.h - 1)
			if p.alpha_at(x, y) > 0.9 and p.nz("mid", x, y) > 0.5:
				p.blend(x, y, Color(0.92, 0.97, 1.0), 0.7)


## 구더기: 몸 겉(그 자리에서 가장 앞에 있는 몸 덩어리의 표면) 위에 마디 4~5개 짧은 통. 몸통이 가장 많고 팔·다리에 듬성듬성.
static func _maggots(cl: Clay, j: Dictionary, H: float, n: int, col: Color, rng: RandomNumberGenerator) -> void:
	var m := cl.mat(col, "skin")
	var g := cl.group()
	var groups: Array[int] = []
	for key: String in ["torso", "arm_l", "arm_r", "leg_l", "leg_r"]:
		if j.has(key):
			groups.append(int(j[key]))
	var segs: Array = [["neck", "pelvis", 5], ["shoulder_l", "elbow_l", 2], ["shoulder_r", "elbow_r", 2], ["elbow_l", "hand_l", 1],
		["elbow_r", "hand_r", 1], ["hip_l", "knee_l", 2], ["hip_r", "knee_r", 2], ["knee_l", "ankle_l", 1], ["knee_r", "ankle_r", 1]]
	var weights: Array = segs.map(func(e: Array) -> float: return float(e[2]))
	var total := 0.0
	for w: float in weights:
		total += w
	for i in n:
		var pick := rng.randf() * total
		var si := 0
		while si < segs.size() - 1 and pick > float(weights[si]):
			pick -= float(weights[si])
			si += 1
		var a: String = segs[si][0]
		var b: String = segs[si][1]
		if not j.has(a) or not j.has(b):
			continue
		var pa: Vector3 = j[a]
		var pb: Vector3 = j[b]
		var t := rng.randf_range(0.1, 0.9)
		var spread := 0.07 if si == 0 else 0.025
		var c2 := Vector2(lerpf(pa.x, pb.x, t), lerpf(pa.y, pb.y, t)) + Vector2(rng.randf_range(-spread, spread) * H, rng.randf_range(-0.01, 0.01) * H)
		var z := Clay.EMPTY
		for gg in groups:
			z = maxf(z, cl.surf(gg, c2.x, c2.y))
		if z <= Clay.EMPTY * 0.5:
			continue
		var len := rng.randf_range(0.03, 0.05) * H
		var ang := rng.randf() * TAU
		var dir := Vector2.from_angle(ang)
		var bend := rng.randf_range(-0.6, 0.6)
		var pts: Array = []
		var radii: Array = []
		var r0 := rng.randf_range(0.0075, 0.0105) * H
		for k in 5:
			var u := float(k) / 4.0
			var off := dir.rotated(bend * u) * len * (u - 0.5)
			# 반쯤 파고든 놈(뒤쪽 끝이 살 속으로)과 붙어 기는 놈
			var sink := -r0 * 0.6 * (1.0 - u) if i % 3 == 0 else r0 * 0.15
			pts.append(Vector3(c2.x + off.x, c2.y + off.y, z + sink))
			radii.append(r0 * (0.55 + 0.45 * sin(u * PI)) + r0 * 0.15)
		cl.chain(g, pts, radii, m, 3.0)
		for k in 3:  # 마디 골
			var u := 0.25 + k * 0.22
			var q: Vector3 = (pts[1] as Vector3).lerp(pts[3] as Vector3, (u - 0.25) / 0.5)
			var nrm := dir.rotated(bend * u).orthogonal()
			cl.groove(g, Vector2(q.x, q.y) - nrm * r0, Vector2(q.x, q.y) + nrm * r0, r0 * 0.18, r0 * 0.25)
