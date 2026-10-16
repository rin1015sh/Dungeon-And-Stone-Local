extends RefCounted
## 시설 사람(NPC) — 피어 앤 헝거 인물화를 참고한 손그림(2026-10-15 다시 그림, ASSUMPTIONS CT29):
## 곡선 윤곽 · 거칠게 끊기는 깊은 그늘 · 빗금 · 움푹 꺼진 눈두덩 · 두꺼운 바깥 잉크선 · 빛 쪽 테두리 빛 · 옷의 때와 주름.
## 사람마다 따로 캔버스에 그린 뒤 바깥선·테두리 빛을 입혀 장면에 얹는다(배경과 떨어져 보이게) — 실내 어둠도 덜 받는다(keep).
## figure(p, 발 x, 발 y, 키 px, look). 계산대·탁자 뒤에 세우려면 그 가구보다 먼저 부른다.
## look: body(male|female|stout) · skin · top · bottom · lower(trousers|dress|robe) · apron · belt · stole · collar
##   · arms(down|counter|crossed|book) · hands_v · bare_arms · hair(short|long|bun|bald|scarf|hood) · hair_c · hood_c
##   · beard(full|mustache|stubble) · glasses · scar · old · light(-1 왼쪽에서 빛, 1 오른쪽) · back(뒷모습) · pack · spear · keep

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const P := preload("res://tools/city_art/NpcParts.gd")

const SKIN := Color("#b48a6a")
const BOOT := Color("#2f241b")
const RIM := Color("#ffe2b0")

## 몸통 왼쪽 절반 윤곽(목 가운데 → 겨드랑이 → 허리 → 엉덩이 가운데).
const TORSO := {
	"male": [[-0.026, 0.872], [-0.085, 0.855], [-0.125, 0.826], [-0.128, 0.775], [-0.104, 0.7], [-0.09, 0.62], [-0.088, 0.56], [-0.094, 0.5], [-0.092, 0.462]],
	"stout": [[-0.03, 0.872], [-0.09, 0.857], [-0.13, 0.83], [-0.136, 0.77], [-0.132, 0.68], [-0.128, 0.6], [-0.122, 0.53], [-0.112, 0.468]],
	"female": [[-0.024, 0.868], [-0.07, 0.852], [-0.1, 0.828], [-0.103, 0.78], [-0.09, 0.715], [-0.072, 0.645], [-0.068, 0.59], [-0.088, 0.53], [-0.1, 0.47]],
}
const HEAD := [[0.0, 0.998], [-0.036, 0.99], [-0.05, 0.958], [-0.052, 0.925], [-0.046, 0.893], [-0.033, 0.869], [-0.015, 0.855], [0.0, 0.852]]


static func figure(dst: Paint, cx: float, ground: float, h: float, look: Dictionary) -> void:
	var pad := int(maxf(8.0, h * 0.05))
	var lp := Paint.new(int(h * 0.62) + pad * 2, int(h * 1.42) + pad * 2, dst.rng.randi())
	var o := Vector3(lp.w / 2.0, lp.h - pad, h)
	var lit := float(look.get("light", -1.0))
	if look.get("back", false):
		_back(lp, o, look, lit)
	else:
		_front(lp, o, look, lit)
	P.rim(lp, lit, maxi(1, int(h / 90.0)), RIM, 0.22)
	Ink.silhouette(lp, maxi(2, int(h / 70.0)), Ink.INK, 0.95)
	_contact_shadow(dst, cx, ground, h)
	P.stamp(dst, lp, int(cx - lp.w / 2.0), int(ground - o.y), float(look.get("keep", 0.3)))


static func _contact_shadow(p: Paint, cx: float, ground: float, h: float) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cx + cos(a) * h * 0.2, ground + sin(a) * h * 0.035))
	p.fill_poly(pts, p.flat(Color("#0a0806"), 0.05), 0.5)


static func _sym(half: Array) -> Array:
	var out: Array = half.duplicate()
	for i in range(half.size() - 1, -1, -1):
		var a: Array = half[i]
		if absf(float(a[0])) > 0.0001:
			out.append([-float(a[0]), a[1]])
	return out


static func _front(p: Paint, o: Vector3, look: Dictionary, lit: float) -> void:
	var body := str(look.get("body", "male"))
	var top: Color = look.get("top", Color("#5a4a38"))
	var bottom: Color = look.get("bottom", top)
	var skin: Color = look.get("skin", SKIN)
	var hair := str(look.get("hair", "short"))
	var hair_c: Color = look.get("hair_c", Color("#2a2018"))
	var hood_c: Color = look.get("hood_c", Color("#8a8270"))
	var sw := 0.1 if body == "female" else 0.128
	if hair == "long":
		P.paint(p, o, P.shape(o, _sym([[0.0, 1.0], [-0.05, 0.985], [-0.066, 0.93], [-0.07, 0.85], [-0.08, 0.775], [-0.045, 0.765], [0.0, 0.79]])), hair_c, lit, 0.0, false)
	if hair == "hood":
		P.paint(p, o, P.shape(o, _sym([[0.0, 1.045], [-0.056, 1.025], [-0.082, 0.96], [-0.088, 0.89], [-0.118, 0.82], [-0.06, 0.835], [0.0, 0.85]])), hood_c, lit)
	_lower(p, o, look, body, bottom, lit)
	if look.get("spear", false):
		_spear(p, o, sw, lit)
	P.paint(p, o, P.limb(o, [[0.0, 0.875], [0.0, 0.835]], [0.022, 0.027]), skin.darkened(0.15), lit, 0.0, false)
	var torso := P.shape(o, _sym(TORSO.get(body, TORSO["male"])))
	if str(look.get("lower")) == "robe":
		torso = P.shape(o, _sym((TORSO.get(body, TORSO["male"]) as Array).slice(0, 7) + [[-0.1, 0.5], [-0.11, 0.42]]))
	P.paint(p, o, torso, top, lit)
	P.grime(p, torso, 0.22)
	if body == "female":
		P.folds(p, o, [[[-0.07, 0.74], [-0.04, 0.715], [-0.01, 0.73]], [[0.07, 0.74], [0.04, 0.715], [0.01, 0.73]]])
	P.folds(p, o, [[[-0.05, 0.84], [-0.03, 0.78], [-0.04, 0.7]], [[0.06, 0.62], [0.03, 0.58], [0.05, 0.52]]])
	_garnish(p, o, look, lit)
	_arms(p, o, look, sw, top, skin, lit)
	_head(p, o, look, body, skin, hair, hair_c, hood_c, lit)


## 아랫도리: 바지 + 장화, 또는 치마·법의(물결치는 단 + 주름, 단 밑으로 신발 코).
static func _lower(p: Paint, o: Vector3, look: Dictionary, body: String, bottom: Color, lit: float) -> void:
	var kind := str(look.get("lower", "trousers"))
	if kind == "trousers":
		var hip := 0.05 if body != "stout" else 0.058
		for s: float in [-1.0, 1.0]:
			var leg := P.limb(o, [[-0.045, 0.47], [-0.052, 0.27], [-0.046, 0.08]], [hip, 0.038, 0.031], s)
			P.paint(p, o, leg, bottom, lit)
			P.grime(p, leg, 0.3)
			P.folds(p, o, [[[-0.06, 0.29], [-0.045, 0.27], [-0.035, 0.285]]], s)
			P.paint(p, o, P.shape(o, [[-0.022, 0.11], [-0.072, 0.11], [-0.078, 0.035], [-0.094, 0.004], [-0.02, 0.0], [-0.016, 0.05]], s), BOOT, lit, 0.3, false)
		return
	var ww := 0.068 if body == "female" else 0.09
	var hem := 0.152 if kind == "dress" else 0.138
	for s: float in [-1.0, 1.0]:
		P.paint(p, o, P.shape(o, [[-0.03, 0.03], [-0.07, 0.03], [-0.08, 0.0], [-0.025, 0.0]], s), BOOT, lit, 0.3, false)
	var half := [[0.0, 0.6], [-ww, 0.6], [-0.11, 0.46], [-0.125, 0.28], [-hem, 0.04], [-hem * 0.7, 0.012], [-hem * 0.35, 0.03], [0.0, 0.012]]
	var skirt := P.shape(o, _sym(half))
	P.paint(p, o, skirt, bottom, lit)
	P.grime(p, skirt, 0.3)
	P.folds(p, o, [[[-0.03, 0.55], [-0.06, 0.3], [-0.085, 0.05]], [[0.02, 0.5], [0.03, 0.28], [0.05, 0.04]], [[0.07, 0.45], [0.1, 0.25], [0.12, 0.06]]])


## 앞치마·허리띠·영대·깃.
static func _garnish(p: Paint, o: Vector3, look: Dictionary, lit: float) -> void:
	if look.has("apron"):
		var ap := P.shape(o, _sym([[0.0, 0.7], [-0.058, 0.7], [-0.064, 0.6], [-0.1, 0.56], [-0.11, 0.2], [0.0, 0.18]]))
		P.paint(p, o, ap, look["apron"], lit, 0.3)
		P.grime(p, ap, 0.45)
		P.folds(p, o, [[[-0.04, 0.5], [-0.05, 0.35], [-0.06, 0.22]], [[0.03, 0.48], [0.04, 0.3]]])
	if look.has("belt"):
		P.paint(p, o, P.shape(o, _sym([[0.0, 0.6], [-0.094, 0.6], [-0.096, 0.565], [0.0, 0.562]])), look["belt"], lit, 0.3, false)
		P.paint(p, o, P.shape(o, [[-0.012, 0.598], [0.012, 0.598], [0.012, 0.566], [-0.012, 0.566]]), Color("#8a7a52"), lit, 0.5, false)
	if look.has("stole"):
		for s: float in [-1.0, 1.0]:
			P.paint(p, o, P.shape(o, [[-0.02, 0.858], [-0.048, 0.85], [-0.056, 0.26], [-0.03, 0.25]], s), look["stole"], lit, 0.2, false)
	if look.has("collar"):
		P.paint(p, o, P.shape(o, _sym([[0.0, 0.87], [-0.036, 0.868], [-0.056, 0.838], [0.0, 0.808]])), look["collar"], lit, 0.4, false)


static func _arms(p: Paint, o: Vector3, look: Dictionary, sw: float, sleeve: Color, skin: Color, lit: float) -> void:
	var pose := str(look.get("arms", "down"))
	var bare := bool(look.get("bare_arms", false))
	var hv := float(look.get("hands_v", 0.55))
	for s: float in [-1.0, 1.0]:
		var sh := [-sw * 0.86, 0.818]
		var el := [-sw - 0.034, 0.64]
		var wr: Array
		match pose:
			"counter":
				wr = [-0.085, hv + 0.02]
			"crossed":
				el = [-sw - 0.03, 0.635]
				wr = [-sw - 0.03, 0.635]
			"book":
				wr = [-sw - 0.026, 0.48]
				if s < 0.0:  # 오른팔은 책을 받친다(아래에서 따로)
					el = [-sw - 0.03, 0.635]
			_:
				wr = [-sw - 0.026, 0.48]
		if pose == "crossed" or (pose == "book" and s < 0.0):
			P.paint(p, o, P.limb(o, [sh, el], [0.037, 0.031], s), sleeve, lit)
			continue
		if bare:
			P.paint(p, o, P.limb(o, [sh, el], [0.037, 0.031], s), sleeve, lit)
			P.paint(p, o, P.limb(o, [el, wr], [0.029, 0.023], s), skin, lit)
		else:
			P.paint(p, o, P.limb(o, [sh, el, wr], [0.037, 0.031, 0.025], s), sleeve, lit)
		_hand(p, o, Vector2(float(wr[0]) * s, float(wr[1])), Vector2(float(wr[0]) - float(el[0]), float(wr[1]) - float(el[1])) * Vector2(s, 1.0), skin, lit)
	if pose == "crossed":
		var fc := skin if bare else sleeve
		P.paint(p, o, P.limb(o, [[-sw - 0.03, 0.63], [sw - 0.02, 0.685]], [0.028, 0.025]), fc, lit)
		P.paint(p, o, P.limb(o, [[sw + 0.03, 0.62], [-sw + 0.02, 0.665]], [0.028, 0.025]), fc, lit)
		_hand(p, o, Vector2(-sw + 0.02, 0.665), Vector2(-1, 0.2), skin, lit)
	elif pose == "book":
		P.paint(p, o, P.limb(o, [[sw + 0.03, 0.635], [-0.02, 0.665]], [0.03, 0.025]), sleeve, lit)
		P.paint(p, o, P.shape(o, [[-0.05, 0.62], [0.075, 0.6], [0.08, 0.715], [-0.046, 0.735]]), Color("#4a2a20"), lit, 0.2, false)
		Ink.line(p, P.q(o, 0.07, 0.61), P.q(o, 0.074, 0.712), P.lw(o) * 1.4, Color("#c8b88a"), 0.6, 0.3)
		_hand(p, o, Vector2(-0.03, 0.66), Vector2(-1, -0.3), skin, lit)


## 손: 손목에서 dir 쪽으로 엄지가 붙은 장갑 모양 + 손가락 선.
static func _hand(p: Paint, o: Vector3, wrist: Vector2, dir: Vector2, skin: Color, lit: float) -> void:
	var c := P.q(o, wrist.x, wrist.y)
	var d := Vector2(dir.x, -dir.y).normalized()
	var n := Vector2(-d.y, d.x)
	var r := 0.021 * o.z
	var pts := PackedVector2Array([c + n * r * 0.9, c + n * r * 1.1 + d * r * 1.2, c + n * r * 0.5 + d * r * 2.2, c - n * r * 0.5 + d * r * 2.1,
		c - n * r * 1.0 + d * r * 1.3, c - n * r * 1.5 + d * r * 0.6, c - n * r * 0.9])
	P.paint(p, o, P.spline(pts), skin, lit, 0.3, false)
	for k in 2:
		var a := c + d * r * 1.3 + n * (r * (0.35 - 0.5 * k))
		Ink.line(p, a, a + d * r * 0.8, P.lw(o) * 0.6, Ink.INK, 0.6, 0.2)


static func _spear(p: Paint, o: Vector3, sw: float, lit: float) -> void:
	var u := sw + 0.035
	P.paint(p, o, P.limb(o, [[u, -0.02], [u, 1.26]], [0.009, 0.008]), Color("#4a3624"), lit, 0.2, false)
	P.paint(p, o, P.shape(o, [[u, 1.4], [u + 0.022, 1.3], [u + 0.012, 1.25], [u - 0.012, 1.25], [u - 0.022, 1.3]]), Color("#8e8e86"), lit, 0.1, false)


## 얼굴: 광대·턱이 선 윤곽 · 움푹한 눈두덩 · 작은 눈빛 · 짙은 눈썹 · 코 그늘 · 처진 입 · 볼 그늘.
static func _head(p: Paint, o: Vector3, look: Dictionary, body: String, skin: Color, hair: String, hair_c: Color, hood_c: Color, lit: float) -> void:
	var js := 0.92 if body == "female" else (1.1 if body == "stout" else 1.0)
	var head: Array = []
	for a: Array in HEAD:
		var v := float(a[1])
		head.append([float(a[0]) * (js if v < 0.93 else 1.0), v])
	for s: float in [-1.0, 1.0]:
		P.paint(p, o, P.shape(o, [[-0.048, 0.94], [-0.061, 0.937], [-0.062, 0.913], [-0.05, 0.904]], s), skin, lit, 0.0, false)
	var face := P.shape(o, _sym(head))
	P.paint(p, o, face, skin, lit, 0.3, true)
	var sd := -lit  # 그늘 쪽
	var dark := Color("#3a2018")
	var lw := P.lw(o)
	for s: float in [-1.0, 1.0]:
		var sock := P.shape(o, [[s * 0.007, 0.934], [s * 0.02, 0.942], [s * 0.034, 0.935], [s * 0.031, 0.922], [s * 0.019, 0.918], [s * 0.008, 0.924]])
		p.fill_poly(sock, p.flat(dark, 0.08), 0.92 if s == sd else 0.78)
		Ink.line(p, P.q(o, s * 0.011, 0.93), P.q(o, s * 0.029, 0.929), lw * 1.1, Ink.INK, 0.9, 0.2)
		if o.z > 120.0:  # 눈빛 한 점
			var e := P.q(o, s * 0.02 - lit * 0.002, 0.931)
			Ink.line(p, e, e + Vector2(0.8, 0), lw * 0.9, Color("#e8dcc4"), 0.8, 0.0)
		Ink.line(p, P.q(o, s * 0.005, 0.946), P.q(o, s * 0.036, 0.943 + (0.004 if look.get("old", false) else 0.0)), lw * 1.5, hair_c.darkened(0.35), 0.9, 0.4)
	p.fill_poly(P.shape(o, [[0.0, 0.936], [sd * 0.011, 0.904], [sd * 0.004, 0.896], [-sd * 0.007, 0.899]]), p.flat(skin.darkened(0.45), 0.08), 0.75)
	Ink.line(p, P.q(o, -sd * 0.004, 0.932), P.q(o, -sd * 0.006, 0.906), lw * 0.8, skin.lightened(0.3), 0.6, 0.2)
	Ink.line(p, P.q(o, -0.007, 0.899), P.q(o, 0.007, 0.899), lw * 0.9, Ink.INK, 0.7, 0.2)
	Ink.path(p, P.spline(PackedVector2Array([P.q(o, -0.018, 0.878), P.q(o, 0.0, 0.881), P.q(o, 0.018, 0.877)]), false, 4), lw * 1.1, false, Color("#2a1410"), 0.9, 0.3)
	Ink.line(p, P.q(o, sd * 0.042, 0.912), P.q(o, sd * 0.03, 0.872), lw * 2.2, dark, 0.35, 0.4)
	if look.get("old", false):
		for k in 2:
			Ink.line(p, P.q(o, -0.022, 0.958 + k * 0.009), P.q(o, 0.022, 0.958 + k * 0.009), lw * 0.7, dark, 0.45, 1.0)
		Ink.line(p, P.q(o, sd * 0.012, 0.9), P.q(o, sd * 0.02, 0.875), lw * 0.8, dark, 0.5, 0.4)
	if look.get("scar", false):
		Ink.line(p, P.q(o, 0.008, 0.955), P.q(o, 0.034, 0.884), lw * 1.2, Color("#8a3a2e"), 0.85, 0.6)
	_hair(p, o, hair, hair_c, hood_c, lit)
	match str(look.get("beard", "")):
		"full":
			var bd := P.shape(o, _sym([[0.0, 0.9], [-0.024, 0.896], [-0.05, 0.915], [-0.052, 0.875], [-0.04, 0.83], [-0.02, 0.795], [0.0, 0.785]]))
			P.paint(p, o, bd, hair_c, lit, 0.2, false)
			for k in 7:
				var u := -0.04 + k * 0.013
				Ink.line(p, P.q(o, u, 0.89), P.q(o, u * 0.6, 0.8), lw * 0.6, hair_c.darkened(0.4), 0.5, 1.0)
			Ink.line(p, P.q(o, -0.014, 0.877), P.q(o, 0.014, 0.877), lw * 1.2, Ink.INK, 0.9, 0.3)
		"mustache":
			P.paint(p, o, P.shape(o, _sym([[0.0, 0.893], [-0.03, 0.892], [-0.042, 0.872], [0.0, 0.884]])), hair_c, lit, 0.2, false)
		"stubble":
			for k in int(o.z / 6.0):
				var a := p.rng.randf_range(PI * 1.1, PI * 1.9)
				var rr := p.rng.randf_range(0.6, 1.0)
				var pt := P.q(o, cos(a) * 0.044 * rr, 0.905 + sin(a) * 0.05 * rr)
				Ink.line(p, pt, pt + Vector2(0.6, 0.6), lw * 0.7, hair_c.darkened(0.3), 0.45, 0.0)
	if look.get("glasses", false):
		for s: float in [-1.0, 1.0]:
			var ring := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				ring.append(P.q(o, s * 0.02 + cos(a) * 0.014, 0.929 + sin(a) * 0.011))
			Ink.path(p, ring, lw * 0.8, true, Color("#2a2620"), 0.9, 0.1)
		Ink.line(p, P.q(o, -0.006, 0.931), P.q(o, 0.006, 0.931), lw * 0.7, Color("#2a2620"), 0.9, 0.1)


static func _hair(p: Paint, o: Vector3, hair: String, c: Color, hood_c: Color, lit: float) -> void:
	var lw := P.lw(o)
	match hair:
		"short", "long", "bun":
			var cap := P.shape(o, _sym([[0.0, 1.008], [-0.042, 0.998], [-0.057, 0.962], [-0.056, 0.915], [-0.049, 0.93], [-0.044, 0.952], [-0.02, 0.962], [0.0, 0.958]]))
			P.paint(p, o, cap, c, lit, 0.1, false)
			for k in 9:
				var u := -0.05 + k * 0.0125
				Ink.line(p, P.q(o, u * 0.3, 1.004), P.q(o, u, 0.955 - absf(u) * 0.4), lw * 0.6, c.lightened(0.25), 0.4, 0.8)
			if hair == "bun":
				P.paint(p, o, P.shape(o, [[0.0, 1.035], [-0.028, 1.022], [-0.03, 0.998], [0.0, 0.99], [0.03, 0.998], [0.028, 1.022]]), c, lit, 0.1, false)
		"bald":
			for s: float in [-1.0, 1.0]:
				P.paint(p, o, P.shape(o, [[-0.046, 0.945], [-0.056, 0.935], [-0.055, 0.9], [-0.046, 0.905]], s), c, lit, 0.1, false)
			Ink.glow(p, P.q(o, -lit * -0.018, 0.982).x, P.q(o, 0, 0.982).y, o.z * 0.016, Color("#f0d4b0"), 0.35)
		"scarf":
			var sc := P.shape(o, _sym([[0.0, 1.022], [-0.05, 1.006], [-0.066, 0.962], [-0.064, 0.9], [-0.058, 0.862], [-0.046, 0.876], [-0.046, 0.94], [-0.028, 0.958], [0.0, 0.962]]))
			P.paint(p, o, sc, hood_c, lit, 0.1)
			P.paint(p, o, P.limb(o, [[0.056, 0.9], [0.07, 0.85], [0.082, 0.79]], [0.02, 0.016, 0.012]), hood_c.darkened(0.12), lit, 0.0, false)
			P.folds(p, o, [[[-0.04, 1.0], [-0.055, 0.96], [-0.056, 0.9]], [[0.03, 1.005], [0.052, 0.96]]])
		"hood":
			var rim := P.shape(o, _sym([[0.0, 1.036], [-0.05, 1.016], [-0.07, 0.96], [-0.068, 0.89], [-0.062, 0.858], [-0.048, 0.892], [-0.047, 0.948], [-0.022, 0.968], [0.0, 0.97]]))
			P.paint(p, o, rim, hood_c, lit, 0.1)
			var shade := P.shape(o, _sym([[0.0, 0.97], [-0.047, 0.948], [-0.05, 0.91], [0.0, 0.915]]))
			p.fill_poly(shade, p.flat(Color("#120c0a"), 0.05), 0.72)


## 뒷모습: 다리·몸통·등짐·팔·뒤통수(머리카락이나 두건이 다 덮는다).
static func _back(p: Paint, o: Vector3, look: Dictionary, lit: float) -> void:
	var body := str(look.get("body", "male"))
	var top: Color = look.get("top", Color("#5a4a38"))
	var hair := str(look.get("hair", "short"))
	var hair_c: Color = look.get("hair_c", Color("#2a2018"))
	var hood_c: Color = look.get("hood_c", Color("#8a8270"))
	var skin: Color = look.get("skin", SKIN)
	var sw := 0.1 if body == "female" else 0.128
	_lower(p, o, look, body, look.get("bottom", top), lit)
	if look.get("spear", false):
		_spear(p, o, sw, lit)
	P.paint(p, o, P.limb(o, [[0.0, 0.875], [0.0, 0.835]], [0.022, 0.027]), skin.darkened(0.2), lit, 0.0, false)
	var torso := P.shape(o, _sym(TORSO.get(body, TORSO["male"])))
	P.paint(p, o, torso, top, lit)
	P.grime(p, torso, 0.25)
	P.folds(p, o, [[[0.0, 0.84], [0.01, 0.7], [-0.005, 0.56]], [[-0.07, 0.8], [-0.05, 0.72]]])
	if look.has("belt"):
		P.paint(p, o, P.shape(o, _sym([[0.0, 0.6], [-0.094, 0.6], [-0.096, 0.565], [0.0, 0.562]])), look["belt"], lit, 0.3, false)
	if look.has("pack"):
		var pack: Color = look["pack"]
		P.paint(p, o, P.limb(o, [[-0.07, 0.84], [0.07, 0.84]], [0.022, 0.022]), Color("#6a5a3a"), lit, 0.2, false)
		var bag := P.shape(o, _sym([[0.0, 0.81], [-0.07, 0.8], [-0.09, 0.7], [-0.092, 0.54], [-0.06, 0.5], [0.0, 0.5]]))
		P.paint(p, o, bag, pack, lit)
		P.grime(p, bag, 0.35)
		P.paint(p, o, P.shape(o, _sym([[0.0, 0.81], [-0.07, 0.8], [-0.078, 0.7], [0.0, 0.69]])), pack.darkened(0.15), lit, 0.2, false)
		for s: float in [-1.0, 1.0]:
			Ink.line(p, P.q(o, s * 0.05, 0.86), P.q(o, s * 0.065, 0.55), P.lw(o) * 1.6, Color("#2a1e14"), 0.9, 0.3)
	for s: float in [-1.0, 1.0]:
		P.paint(p, o, P.limb(o, [[-sw * 0.86, 0.818], [-sw - 0.034, 0.64], [-sw - 0.026, 0.48]], [0.037, 0.031, 0.025], s), top, lit)
		_hand(p, o, Vector2(s * (sw + 0.026), 0.48), Vector2(0, -1), skin, lit)
	if hair == "hood":
		P.paint(p, o, P.shape(o, _sym([[0.0, 1.04], [-0.058, 1.02], [-0.08, 0.95], [-0.1, 0.84], [0.0, 0.82]])), hood_c, lit)
		P.folds(p, o, [[[0.0, 1.03], [0.005, 0.9], [0.0, 0.83]]])
		return
	var head := P.shape(o, _sym(HEAD))
	P.paint(p, o, head, skin if hair == "bald" else hair_c, lit, 0.2, hair != "bald")
	if hair == "long":
		P.paint(p, o, P.shape(o, _sym([[0.0, 0.95], [-0.05, 0.94], [-0.07, 0.85], [-0.075, 0.76], [0.0, 0.75]])), hair_c, lit, 0.1)
		for k in 6:
			var u := -0.06 + k * 0.024
			Ink.line(p, P.q(o, u * 0.7, 0.94), P.q(o, u, 0.77), P.lw(o) * 0.6, hair_c.lightened(0.2), 0.4, 1.0)
	elif hair == "bun":
		P.paint(p, o, P.shape(o, [[0.0, 0.97], [-0.03, 0.958], [-0.03, 0.932], [0.0, 0.922], [0.03, 0.932], [0.03, 0.958]]), hair_c.darkened(0.1), lit, 0.1, false)
	elif hair == "bald":
		for s: float in [-1.0, 1.0]:
			P.paint(p, o, P.shape(o, [[-0.046, 0.93], [-0.054, 0.92], [-0.05, 0.88], [-0.04, 0.89]], s), Color("#3a2c22"), lit, 0.1, false)
