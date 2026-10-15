extends RefCounted
## 시설 사람(NPC): 앞을 보고 선 인물 한 명. 발 중심(cx, ground)·키 h(px)·생김새 look으로 그린다.
## 좌표는 키의 비율(u = 가로, v = 발에서 위로 0~1). 계산대·탁자 뒤에 세우려면 방 그림에서 그 가구보다 먼저 칠한다.
## look: body(male|female|stout) · skin · top · bottom · lower(trousers|dress|robe) · apron · belt · arms(down|counter|crossed|book)
##   · hands_v(counter일 때 손 높이) · bare_arms · hair(short|bald|bun|scarf|hood|long) · hair_c · hood_c · beard(full|mustache|stubble)
##   · glasses · stole · collar · scar · light(-1 = 왼쪽에서 빛, 1 = 오른쪽)
##   · back(뒷모습 — 얼굴 대신 뒤통수) · pack(등짐 색) · spear(창을 세워 든다)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

const SKIN := Color("#c09474")
const BOOT := Color("#2e2219")


static func figure(p: Paint, cx: float, ground: float, h: float, look: Dictionary) -> void:
	var o := Vector3(cx, ground, h)
	var body := str(look.get("body", "male"))
	var sw := 0.105 if body == "female" else 0.128
	var ww := 0.068 if body == "female" else (0.118 if body == "stout" else 0.088)
	var hw := 0.1 if body == "female" else (0.116 if body == "stout" else 0.092)
	var top: Color = look.get("top", Color("#5a4a38"))
	var bottom: Color = look.get("bottom", top)
	var skin: Color = look.get("skin", SKIN)
	var hair_c: Color = look.get("hair_c", Color("#2a2018"))
	var lit := float(look.get("light", -1.0))
	var lw := maxf(1.2, h / 90.0)
	var arm_c: Color = skin if look.get("bare_arms", false) else top
	_ellipse_fill(p, o, Vector2(0, 0), Vector2(0.17, 0.022), Color("#0c0907"), 0.45)
	if str(look.get("hair", "")) == "long":
		_part(p, o, [[-0.058, 0.965], [0.058, 0.965], [0.074, 0.8], [0.04, 0.78], [-0.04, 0.78], [-0.074, 0.8]], hair_c, lw, lit, false)
	match str(look.get("lower", "trousers")):
		"trousers":
			for s: float in [-1.0, 1.0]:
				_part(p, o, _m([[hw, 0.48], [0.006, 0.48], [0.014, 0.07], [0.074, 0.07]], s), bottom, lw, lit)
				_part(p, o, _m([[0.01, 0.09], [0.078, 0.09], [0.088, 0.0], [0.004, 0.0]], s), BOOT, lw, lit, false)
		_:
			var hem := 0.15 if str(look.get("lower")) == "dress" else 0.135
			_part(p, o, [[-ww, 0.58], [ww, 0.58], [hw * 1.15, 0.32], [hem, 0.012], [0.05, -0.004], [-0.05, -0.004], [-hem, 0.012], [-hw * 1.15, 0.32]], bottom, lw, lit)
			for fu: float in [-0.045, 0.02, 0.07]:
				Ink.line(p, _q(o, fu * 0.6, 0.5), _q(o, fu, 0.03), lw * 0.7, Ink.INK, 0.35, 1.2)
	_part(p, o, [[-0.022, 0.88], [0.022, 0.88], [0.028, 0.832], [-0.028, 0.832]], skin, lw, lit, false)
	var torso := [[-sw * 0.45, 0.852], [sw * 0.45, 0.852], [sw, 0.826], [sw * 0.96, 0.74], [ww, 0.58], [hw, 0.47], [-hw, 0.47], [-ww, 0.58], [-sw * 0.96, 0.74], [-sw, 0.826]]
	if str(look.get("lower")) == "robe":
		torso[5] = [hw * 1.15, 0.36]
		torso[6] = [-hw * 1.15, 0.36]
	_part(p, o, torso, top, lw, lit)
	if look.has("apron"):
		_part(p, o, [[-0.07, 0.68], [0.07, 0.68], [0.1, 0.16], [-0.1, 0.16]], look["apron"], lw, lit)
		Ink.line(p, _q(o, -ww, 0.585), _q(o, ww, 0.585), lw, Ink.INK, 0.7)
	if look.has("belt"):
		_part(p, o, [[-ww - 0.004, 0.6], [ww + 0.004, 0.6], [ww + 0.006, 0.565], [-ww - 0.006, 0.565]], look["belt"], lw * 0.8, lit, false)
	if look.has("stole"):
		for s: float in [-1.0, 1.0]:
			_part(p, o, _m([[0.022, 0.85], [0.05, 0.85], [0.056, 0.26], [0.028, 0.26]], s), look["stole"], lw * 0.8, lit, false)
	if look.has("collar"):
		_part(p, o, [[-0.034, 0.865], [0.034, 0.865], [0.05, 0.835], [0.0, 0.808], [-0.05, 0.835]], look["collar"], lw * 0.7, lit, false)
	if look.has("pack") and look.get("back", false):
		_part(p, o, [[-0.085, 0.8], [0.085, 0.8], [0.095, 0.5], [-0.095, 0.5]], look["pack"], lw, lit)
		Ink.line(p, _q(o, -0.08, 0.66), _q(o, 0.08, 0.66), lw, Ink.INK, 0.6)
	_arms(p, o, str(look.get("arms", "down")), sw, arm_c, skin, top, float(look.get("hands_v", 0.55)), lw, lit)
	if look.get("spear", false):
		Ink.line(p, _q(o, sw + 0.03, -0.02), _q(o, sw + 0.03, 1.25), lw * 1.6, Color("#3a2a1c"), 1.0, 0.3)
		_part(p, o, [[sw + 0.03, 1.36], [sw + 0.05, 1.25], [sw + 0.01, 1.25]], Color("#8a8a84"), lw * 0.7, lit, false)
	if look.get("back", false):
		_back_head(p, o, look, skin, hair_c, lw, lit)
	else:
		_head(p, o, look, skin, hair_c, lw, lit)


static func _arms(p: Paint, o: Vector3, pose: String, sw: float, c: Color, skin: Color, sleeve: Color, hv: float, lw: float, lit: float) -> void:
	for s: float in [-1.0, 1.0]:
		var upper := [[sw * 0.9, 0.836], [sw + 0.032, 0.8], [sw + 0.044, 0.64], [sw - 0.012, 0.63], [sw - 0.03, 0.76]]
		match pose:
			"down":
				_part(p, o, _m([[sw * 0.9, 0.836], [sw + 0.032, 0.8], [sw + 0.044, 0.64], [sw + 0.03, 0.47], [sw - 0.012, 0.47], [sw - 0.01, 0.63], [sw - 0.03, 0.76]], s), sleeve, lw, lit)
				_ellipse_fill(p, o, Vector2(s * (sw + 0.01), 0.445), Vector2(0.022, 0.03), skin, 1.0, lw, lit)
			"counter":
				_part(p, o, _m([[sw * 0.9, 0.836], [sw + 0.032, 0.8], [sw + 0.048, 0.63], [0.105, hv], [0.058, hv + 0.02], [sw - 0.014, 0.66], [sw - 0.03, 0.76]], s), sleeve, lw, lit)
				_ellipse_fill(p, o, Vector2(s * 0.08, hv), Vector2(0.03, 0.02), skin, 1.0, lw, lit)
			"crossed":
				_part(p, o, _m(upper, s), sleeve, lw, lit)
			"book":
				if s > 0.0:
					_part(p, o, _m([[sw * 0.9, 0.836], [sw + 0.032, 0.8], [sw + 0.044, 0.64], [sw + 0.03, 0.47], [sw - 0.012, 0.47], [sw - 0.01, 0.63], [sw - 0.03, 0.76]], s), sleeve, lw, lit)
					_ellipse_fill(p, o, Vector2(sw + 0.01, 0.445), Vector2(0.022, 0.03), skin, 1.0, lw, lit)
				else:
					_part(p, o, _m(upper, s), sleeve, lw, lit)
	if pose == "crossed":
		_part(p, o, [[-sw - 0.042, 0.61], [sw - 0.01, 0.645], [sw - 0.01, 0.695], [-sw - 0.042, 0.665]], c, lw, lit)
		_part(p, o, [[sw + 0.042, 0.6], [-sw + 0.01, 0.635], [-sw + 0.01, 0.685], [sw + 0.042, 0.655]], c, lw, lit)
		_ellipse_fill(p, o, Vector2(-sw + 0.004, 0.66), Vector2(0.024, 0.026), skin, 1.0, lw, lit)
	elif pose == "book":
		_part(p, o, [[-sw - 0.044, 0.64], [0.03, 0.62], [0.03, 0.67], [-sw - 0.01, 0.69]], sleeve, lw, lit)
		_part(p, o, [[-0.07, 0.6], [0.05, 0.62], [0.046, 0.73], [-0.074, 0.71]], Color("#4a2a20"), lw, lit, false)
		_ellipse_fill(p, o, Vector2(0.035, 0.645), Vector2(0.022, 0.024), skin, 1.0, lw, lit)


static func _head(p: Paint, o: Vector3, look: Dictionary, skin: Color, hair_c: Color, lw: float, lit: float) -> void:
	var hair := str(look.get("hair", "short"))
	var hood_c: Color = look.get("hood_c", Color("#a49c86"))
	if hair == "hood":
		_part(p, o, [[-0.1, 0.8], [-0.078, 0.9], [-0.064, 0.98], [-0.03, 1.02], [0.03, 1.02], [0.064, 0.98], [0.078, 0.9], [0.1, 0.8], [0.04, 0.83], [-0.04, 0.83]], hood_c, lw, lit)
	var face := _ellipse(o, Vector2(0, 0.925), Vector2(0.05, 0.064))
	p.fill_poly(face, p.flat(skin, 0.1))
	var r := Paint.bounds(face)
	Ink.shade(p, face, Vector2(r.position.x if lit < 0.0 else r.end.x, 0), Vector2(r.end.x if lit < 0.0 else r.position.x, 0), 0.0, 0.55)
	Ink.shade(p, face, _q(o, 0, 0.9), _q(o, 0, 0.86), 0.0, 0.3)
	Ink.path(p, face, lw)
	for s: float in [-1.0, 1.0]:  # 눈두덩 그늘·눈·눈썹
		_ellipse_fill(p, o, Vector2(s * 0.02, 0.928), Vector2(0.014, 0.008), Color("#2a1a12"), 0.55)
		Ink.line(p, _q(o, s * 0.012, 0.928), _q(o, s * 0.026, 0.929), lw * 0.8, Ink.INK, 0.9, 0.2)
		Ink.line(p, _q(o, s * 0.008, 0.944), _q(o, s * 0.032, 0.94), lw * 0.8, hair_c.darkened(0.3), 0.8, 0.3)
	Ink.line(p, _q(o, 0.0, 0.93), _q(o, -lit * 0.006, 0.9), lw * 0.7, Ink.INK, 0.6, 0.2)
	Ink.line(p, _q(o, -0.014, 0.879), _q(o, 0.014, 0.88), lw * 0.75, Color("#3a1e16"), 0.8, 0.3)
	if look.get("scar", false):
		Ink.line(p, _q(o, 0.012, 0.95), _q(o, 0.036, 0.888), lw * 0.7, Color("#7a3a2e"), 0.8, 0.4)
	match hair:
		"short", "long", "bun":
			var cap := _arc(o, Vector2(0, 0.93), Vector2(0.056, 0.07), 0.0, PI)
			cap.append_array(PackedVector2Array([_q(o, -0.05, 0.9), _q(o, -0.036, 0.952), _q(o, 0.0, 0.962), _q(o, 0.036, 0.952), _q(o, 0.05, 0.9)]))
			_poly_part(p, cap, hair_c, lw, lit, o)
			if hair == "bun":
				_ellipse_fill(p, o, Vector2(0, 1.0), Vector2(0.03, 0.026), hair_c, 1.0, lw, lit)
		"bald":
			for s: float in [-1.0, 1.0]:
				_part(p, o, _m([[0.046, 0.94], [0.056, 0.92], [0.05, 0.885], [0.042, 0.9]], s), hair_c, lw * 0.7, lit, false)
			Ink.glow(p, o.x + lit * 0.015 * o.z, o.y - 0.965 * o.z, o.z * 0.02, Color("#e8c8a0"), 0.25)
		"scarf":
			var sc := _arc(o, Vector2(0, 0.93), Vector2(0.064, 0.078), 0.0, PI)
			sc.append_array(PackedVector2Array([_q(o, -0.06, 0.87), _q(o, -0.048, 0.9), _q(o, -0.04, 0.95), _q(o, 0.0, 0.965), _q(o, 0.04, 0.95), _q(o, 0.048, 0.9), _q(o, 0.06, 0.87)]))
			_poly_part(p, sc, hood_c, lw, lit, o)
			_part(p, o, [[0.05, 0.9], [0.078, 0.86], [0.09, 0.79], [0.064, 0.8], [0.046, 0.87]], hood_c.darkened(0.15), lw, lit, false)
		"hood":
			Ink.shade(p, face, _q(o, 0, 0.99), _q(o, 0, 0.9), 0.65, 0.0)
			var rim := _arc(o, Vector2(0, 0.925), Vector2(0.06, 0.076), 0.0, PI)
			Ink.path(p, rim, lw, false)
	match str(look.get("beard", "")):
		"full":
			_part(p, o, [[-0.052, 0.915], [-0.036, 0.894], [0.036, 0.894], [0.052, 0.915], [0.048, 0.85], [0.022, 0.79], [0.0, 0.775], [-0.022, 0.79], [-0.048, 0.85]], hair_c, lw, lit, false)
			Ink.line(p, _q(o, -0.012, 0.874), _q(o, 0.012, 0.874), lw * 0.8, Ink.INK, 0.8, 0.3)
		"mustache":
			_part(p, o, [[-0.032, 0.893], [0.032, 0.893], [0.04, 0.874], [0.0, 0.886], [-0.04, 0.874]], hair_c, lw * 0.7, lit, false)
		"stubble":
			for jaw: PackedVector2Array in Geometry2D.intersect_polygons(_ellipse(o, Vector2(0, 0.885), Vector2(0.046, 0.03)), face):
				Ink.hatch(p, jaw, maxf(1.5, o.z / 110.0), 80.0, 0.3, 0.7)
	if look.get("glasses", false):
		for s: float in [-1.0, 1.0]:
			Ink.path(p, _ellipse(o, Vector2(s * 0.02, 0.928), Vector2(0.013, 0.011)), lw * 0.55, true, Color("#3a3226"), 0.9, 0.2)
		Ink.line(p, _q(o, -0.007, 0.93), _q(o, 0.007, 0.93), lw * 0.5, Color("#3a3226"), 0.9, 0.1)


## 뒷모습 머리: 목 + 뒤통수(머리카락·두건이 다 덮는다).
static func _back_head(p: Paint, o: Vector3, look: Dictionary, skin: Color, hair_c: Color, lw: float, lit: float) -> void:
	var hair := str(look.get("hair", "short"))
	var hood_c: Color = look.get("hood_c", Color("#a49c86"))
	if hair == "hood":
		_part(p, o, [[-0.1, 0.8], [-0.078, 0.9], [-0.064, 0.98], [-0.03, 1.02], [0.03, 1.02], [0.064, 0.98], [0.078, 0.9], [0.1, 0.8], [0.0, 0.79]], hood_c, lw, lit)
		return
	var head := _ellipse(o, Vector2(0, 0.925), Vector2(0.05, 0.064))
	_poly_part(p, head, skin if hair == "bald" else hair_c, lw, lit, o, false)
	if hair == "long":
		_part(p, o, [[-0.05, 0.93], [0.05, 0.93], [0.07, 0.76], [-0.07, 0.76]], hair_c, lw, lit, false)
	elif hair == "bun":
		_ellipse_fill(p, o, Vector2(0, 0.95), Vector2(0.028, 0.026), hair_c.darkened(0.15), 1.0, lw, lit)


## 한 조각: 채움(붓결) + 빛 반대쪽 그늘 + (그늘 쪽 빗금) + 잉크 윤곽.
static func _part(p: Paint, o: Vector3, pts: Array, c: Color, lw: float, lit: float, hatch: bool = true) -> void:
	_poly_part(p, _poly(o, pts), c, lw, lit, o, hatch)


static func _poly_part(p: Paint, poly: PackedVector2Array, c: Color, lw: float, lit: float, o: Vector3, hatch: bool = true) -> void:
	p.fill_poly(poly, p.flat(c, 0.16))
	var r := Paint.bounds(poly)
	var lx := r.position.x if lit < 0.0 else r.end.x
	var dx := r.end.x if lit < 0.0 else r.position.x
	Ink.shade(p, poly, Vector2(lx, r.position.y), Vector2(dx, r.end.y), 0.0, 0.5)
	if hatch and r.size.x > 6.0:
		var half := Paint.rect_poly(r.get_center().x if lit < 0.0 else r.position.x, r.position.y, r.size.x / 2.0, r.size.y)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(poly, half):
			Ink.hatch(p, part, maxf(3.0, o.z / 40.0), 62.0, 0.22, 0.9)
	Ink.path(p, poly, lw)


static func _ellipse_fill(p: Paint, o: Vector3, c: Vector2, r: Vector2, col: Color, opacity: float, lw: float = 0.0, lit: float = -1.0) -> void:
	var poly := _ellipse(o, c, r)
	if lw > 0.0:
		_poly_part(p, poly, col, lw * 0.7, lit, o, false)
	else:
		p.fill_poly(poly, p.flat(col, 0.05), opacity)


static func _q(o: Vector3, u: float, v: float) -> Vector2:
	return Vector2(o.x + u * o.z, o.y - v * o.z)


static func _poly(o: Vector3, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for a: Array in pts:
		out.append(_q(o, float(a[0]), float(a[1])))
	return out


## 가로 뒤집기(s = -1이면 왼쪽).
static func _m(pts: Array, s: float) -> Array:
	var out: Array = []
	for a: Array in pts:
		out.append([float(a[0]) * s, a[1]])
	return out


static func _ellipse(o: Vector3, c: Vector2, r: Vector2) -> PackedVector2Array:
	return _arc(o, c, r, 0.0, TAU, 24)


## 타원 호(위쪽이 +v). a0 → a1 라디안, 0 = 오른쪽.
static func _arc(o: Vector3, c: Vector2, r: Vector2, a0: float, a1: float, n: int = 14) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		out.append(_q(o, c.x + cos(a) * r.x, c.y + sin(a) * r.y))
	return out
