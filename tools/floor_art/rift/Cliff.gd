extends RefCounted
## 균열 낭떠러지의 절벽 면(chasm.webp — Abyss·abyss.gdshader가 땅 가장자리 아래에 세계 좌표로 붙인다).
## 가로로 이어 붙여도 이음매 없는 띠: 위 = 땅이 끊긴 바로 아래(빛 받는 바위 턱), 아래로 갈수록 abyss 색에 묻힌다.
## 장소마다 specs.json places.<장소>.cliff = {kind, top, mid, deep, strata, accent}:
##   kind   rock(층진 바위) · ice(얼음 — 고드름·흘러내린 결) · masonry(꺼진 석판 층 — 위는 다듬은 돌 줄, 아래는 부서진 잡석)
##   accent timber(갱목 버팀대) · ash(재 얼룩) · crystal(라임빛 결정 점) — 없어도 된다
##   strata 바위 턱 간격 px(그림 배율 2 기준)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")


static func paint(w: int, h: int, seed_value: int, cfg: Dictionary) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var kind := str(cfg.get("kind", "rock"))
	var top := Color(str(cfg.get("top", "#5a5048")))
	var mid := Color(str(cfg.get("mid", "#2c2622")))
	var deep := Color(str(cfg.get("deep", "#060608")))
	var strata := float(cfg.get("strata", 22.0))
	var rock := Seam.field(w, h, seed_value, 0.022, 5)
	var big := Seam.field(w, h, seed_value + 1, 0.007, 3)
	var fine := Seam.field(w, h, seed_value + 2, 0.09, 2)
	var joints := Seam.field(w, h, seed_value + 3, 0.028, 1, true)
	var streak := Seam.field(w, h, seed_value + 4, 0.05, 3)
	for y in h:
		var t := float(y) / h
		var bg := top.lerp(mid, smoothstep(0.0, 0.55, t)).lerp(deep, smoothstep(0.3, 0.92, t))
		for x in w:
			var i := y * w + x
			var c := bg
			var sy := y + (big[i] - 0.5) * strata * 1.6
			var band := fposmod(sy / strata, 1.0)
			var lit := Seam.relief(rock, w, h, x, y, 7.0) * 0.5
			if kind == "ice":
				var s := Seam.at(streak, w, h, x, y / 6)  # 세로로 늘인 결 = 흘러내린 얼음
				lit += (s - 0.5) * 0.7 + (fine[i] - 0.5) * 0.12
				if band < 0.1:
					lit += 0.25 * (1.0 - t)
			else:
				if band < 0.14:
					lit += 0.32 * (1.0 - t * 0.8)  # 턱 윗면(빛)
				elif band > 0.8:
					lit -= 0.28  # 턱 아래 그늘
				lit += (fine[i] - 0.5) * 0.18
				var j := joints[i]
				if j < 0.07:
					lit -= 0.45 * (1.0 - j / 0.07)  # 바위 틈
				var s2 := Seam.at(streak, w, h, x, y / 5)
				if s2 > 0.68:
					lit -= (s2 - 0.68) * 0.9  # 흘러내린 얼룩
			var k := clampf(1.0 + lit * (1.0 - t * 0.6), 0.25, 1.9)
			c = Color(c.r * k, c.g * k, c.b * k)
			p.blend(x, y, c, 1.0)
	if kind == "masonry":
		_masonry(p, top, mid, deep, seed_value)
	if kind == "ice":
		_icicles(p, top, seed_value)
	match str(cfg.get("accent", "")):
		"timber":
			_timbers(p, Color(str(cfg.get("wood", "#5a4430"))), deep)
		"ash":
			_ash(p, seed_value)
		"crystal":
			_crystals(p, Color(str(cfg.get("glow", "#a8e060"))))
	# 아래 끝은 abyss 색으로 완전히 녹인다(셰이더 아래 어둠과 이어지게)
	for y in h:
		var f := smoothstep(0.6, 0.97, float(y) / h)
		for x in w:
			p.blend(x, y, deep, f)
	Ink.finish(p, 0.03, 0.0)
	return p


## 위쪽 0~45%: 다듬은 돌 줄(꺼진 바닥의 석판 층) — 줄마다 다른 블록 폭, 회반죽 선, 아래 끝은 열마다 들쭉날쭉 부서짐.
static func _masonry(p: Paint, top: Color, mid: Color, deep: Color, s: int) -> void:
	var rng := p.rng
	var course := 15
	var rows := 4
	var x := 0.0
	var cut := PackedFloat32Array()  # 열마다 부서진 아래 끝
	cut.resize(p.w)
	for cx in p.w:
		var u := float(cx) / p.w * TAU
		cut[cx] = course * (rows - 1) + 6.0 + sin(u * 3.0 + s) * 8.0 + sin(u * 7.0 + s * 0.3) * 5.0 + (Paint.hash01(cx / 6, 3, s) - 0.5) * 8.0
	for r in rows:
		x = rng.randf() * 30.0
		var y0 := 3 + r * course
		while x < p.w:
			var bw := rng.randf_range(24.0, 44.0)
			var shade := rng.randf_range(-0.12, 0.1) - r * 0.08
			for yy in range(y0, y0 + course - 2):
				for xx in range(int(x), int(x + bw) - 2):
					var wx := posmod(xx, p.w)
					if yy > cut[wx]:
						continue
					var c := p.get_c(wx, yy)
					var face := top.lerp(mid, float(r) / rows)
					var edge := 0.22 if yy < y0 + 2 else (-0.2 if yy > y0 + course - 5 else 0.0)
					var k := 1.0 + shade + edge + (p.nz("mid", wx, yy) - 0.5) * 0.2
					p.blend(wx, yy, Color(face.r * k, face.g * k, face.b * k).lerp(c, 0.15), 0.95)
			for yy in range(y0 - 1, y0 + course - 1):  # 세로 이음매
				var wx0 := posmod(int(x) - 1, p.w)
				if yy <= cut[wx0]:
					p.blend(wx0, yy, Ink.INK, 0.7)
					p.blend(posmod(wx0 + 1, p.w), yy, Ink.INK, 0.35)
			x += bw
		for xx in p.w:  # 가로 이음매
			if y0 - 1 <= cut[xx]:
				p.blend(xx, y0 - 1, Ink.INK, 0.65)
				p.blend(xx, y0, Ink.INK, 0.3)
	for cx in p.w:  # 부서진 끝 아래 그늘
		for d in 6:
			var yy := int(cut[cx]) + d
			if yy < p.h:
				p.blend(cx, yy, deep, 0.55 * (1.0 - d / 6.0))


## 위 가장자리에서 늘어진 고드름(가로로 이어지게 양쪽에 한 번 더).
static func _icicles(p: Paint, top: Color, s: int) -> void:
	var rng := p.rng
	for k in 38:
		var x := rng.randf() * p.w
		var ln := rng.randf_range(8.0, 46.0)
		var wd := rng.randf_range(2.0, 6.0)
		for ox: float in [-p.w, 0.0, p.w]:
			var poly := PackedVector2Array([Vector2(x + ox - wd, 0), Vector2(x + ox + wd, 0), Vector2(x + ox + wd * 0.15, ln)])
			p.fill_poly(poly, func(px: int, py: int) -> Color: return top.lightened(0.35 - py / ln * 0.3), 0.85)
			Ink.line(p, Vector2(x + ox + wd * 0.6, 1), Vector2(x + ox + wd * 0.1, ln * 0.85), 0.8, Color("#f4faff"), 0.5, 0.2)


## 갱목 버팀대: 두 기둥 + 위 들보(ㄇ자 틀) — 절벽 면에 박힌 낡은 갱목. 기둥은 아래로 갈수록 어둠에 묻힌다.
static func _timbers(p: Paint, wood: Color, deep: Color) -> void:
	var rng := p.rng
	var span := 150.0
	var x := p.w * 0.25 + rng.randf_range(-20, 20)
	for ox: float in [-p.w, 0.0, p.w]:
		for side in 2:
			var bx := x + ox + side * span
			p.fill_rect(bx - 6, 4, 12, p.h * 0.7, func(px: int, py: int) -> Color:
				var g := 0.9 + sin(py * 0.7 + px * 0.3) * 0.06 - (px - bx + 6) / 12.0 * 0.35
				return Color(wood.r * g, wood.g * g, wood.b * g).lerp(deep, clampf(py / (p.h * 0.7), 0.0, 1.0)), 0.95)
			Ink.line(p, Vector2(bx - 6, 6), Vector2(bx - 6, p.h * 0.6), 1.2, Ink.INK, 0.65, 0.3)
			Ink.line(p, Vector2(bx + 6, 6), Vector2(bx + 6, p.h * 0.6), 1.0, Ink.INK, 0.45, 0.3)
		var bx0 := x + ox - 14
		p.fill_rect(bx0, 2, span + 28, 11, func(px: int, py: int) -> Color:
			var g := 1.0 - (py - 2) / 11.0 * 0.4 + sin(px * 0.21) * 0.04
			return Color(wood.r * g, wood.g * g, wood.b * g), 0.97)
		Ink.line(p, Vector2(bx0, 13), Vector2(bx0 + span + 28, 13), 1.4, Ink.INK, 0.7, 0.3)
		Ink.line(p, Vector2(bx0, 2), Vector2(bx0 + span + 28, 2), 1.0, Ink.INK, 0.5, 0.3)


static func _ash(p: Paint, s: int) -> void:
	var rng := p.rng
	for k in 260:
		var q := Vector2(rng.randf() * p.w, rng.randf() * p.h * 0.6)
		p.blend(int(q.x), int(q.y), Color("#8a7a72"), rng.randf_range(0.1, 0.3))
	for k in 14:  # 핏빛 얼룩이 흘러내린 자국
		var x := rng.randf() * p.w
		var ln := rng.randf_range(20.0, 70.0)
		Ink.line(p, Vector2(x, rng.randf() * 10.0), Vector2(x + rng.randf_range(-3, 3), ln), rng.randf_range(1.5, 3.5), Color("#3a0e10"), 0.45, 0.6)


static func _crystals(p: Paint, glow: Color) -> void:
	var rng := p.rng
	for k in 7:
		var q := Vector2(rng.randf() * p.w, rng.randf_range(p.h * 0.1, p.h * 0.55))
		for ox: float in [-p.w, 0.0, p.w]:
			Ink.glow(p, q.x + ox, q.y, 14.0, glow, 0.25, false)
			Ink.line(p, Vector2(q.x + ox, q.y), Vector2(q.x + ox + 2, q.y - 6), 2.0, glow.lightened(0.3), 0.85, 0.1)
