extends RefCounted
## 균열 솟은 외곽(타일 "rise" — Abyss rise · abyss.gdshader): 지도 바깥 둘레가 위로 솟은 벽·절벽과 그 너머 풍경.
##   face(w, h) — 땅에서 솟는 면(가로로 이어지는 띠, 위 = 꼭대기). 성가퀴 틈은 투명(셰이더가 그 자리에 꼭대기 풍경을 비춘다).
##   top(w, h)  — 꼭대기 풍경(가로·세로로 이어 붙여도 이음매 없음 — 셰이더가 세계 좌표로 깐다).
## 장소마다 specs.json places.<장소>.rise = {kind, stone, stone_dark, roof, roof_dark, ...}:
##   kind castle — 성벽(성가퀴·돌출 받침·마름돌·버팀벽·화살 구멍) + 너머 성 지붕들(경사 지붕·둥근 탑·굴뚝·좁은 골목)
##   kind ice    — 솟은 빙벽(세로 홈·눈 덮인 꼭대기·고드름) + 너머 설원(바람 결·바위·눈 덮인 전나무)
##   kind grave  — 성벽 면(마름돌 — 묘지 담) + 너머 안개 낀 묘지 들판(덤불 · 마른 나무 · 묘비 실루엣 — 망자의 땅, 사용자 2026-11-05 첨부 그림, FL10)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")


static func face(w: int, h: int, seed_value: int, cfg: Dictionary) -> Paint:
	return _ice_face(w, h, seed_value, cfg) if str(cfg.get("kind", "castle")) == "ice" else _castle_face(w, h, seed_value, cfg)


static func top(w: int, h: int, seed_value: int, cfg: Dictionary) -> Paint:
	match str(cfg.get("kind", "castle")):
		"ice":
			return _snowfield(w, h, seed_value, cfg)
		"grave":
			return _deadfield(w, h, seed_value, cfg)
	return _roofs(w, h, seed_value, cfg)


## 담 너머 묘지 들판(위에서 내려다본 3/4): 검푸른 덤불 바탕 + 안개 얼룩, 묘비(작은 둥근 머리 판) · 마른 나무(가지 선) 실루엣이 흩어져 있다.
## 가로 · 세로로 이어 붙여도 이음매 없게(바탕은 주기 잡음, 실루엣은 posmod로 감는다).
static func _deadfield(w: int, h: int, s: int, cfg: Dictionary) -> Paint:
	var p := Paint.new(w, h, s)
	var ground := Color(str(cfg.get("ground", "#1e2418")))
	var fogc := Color(str(cfg.get("fog_color", "#4a5050")))
	var hf := Seam.field(w, h, s, 0.03, 3)
	var fine := Seam.field(w, h, s + 3, 0.3, 1)
	var fog := Seam.field(w, h, s + 5, 0.012, 3)
	for y in h:
		for x in w:
			var i := y * w + x
			var c := Color("#0a0c08").lerp(ground, clampf(0.3 + hf[i] * 0.7 + (fine[i] - 0.5) * 0.4, 0.0, 1.0))
			c = c.lerp(fogc, smoothstep(0.45, 0.8, fog[i]) * 0.45)
			p.blend(x, y, c, 1.0)
	var rng := p.rng
	for k in 26:  # 묘비
		var c := Vector2(rng.randf() * w, rng.randf() * h)
		var hh := rng.randf_range(10.0, 18.0)
		var ww := hh * 0.55
		for yy in range(int(c.y - hh), int(c.y) + 1):
			for xx in range(int(c.x - ww * 0.5), int(c.x + ww * 0.5) + 1):
				var dy := (yy - (c.y - hh + ww * 0.5)) / (ww * 0.5)
				var dx := (xx - c.x) / (ww * 0.5)
				if yy > c.y - hh + ww * 0.5 or dx * dx + dy * dy <= 1.0:
					p.blend(posmod(xx, w), posmod(yy, h), Color("#3a3c36").lerp(Color("#5a5c54"), 0.3 if xx < c.x else 0.0), 0.9)
		for d in 4:
			p.blend(posmod(int(c.x) + d - 2, w), posmod(int(c.y) + 1, h), Color("#050604"), 0.5)
	for k in 9:  # 마른 나무
		var b := Vector2(rng.randf() * w, rng.randf() * h)
		var t := b + Vector2(rng.randf_range(-8, 8), -rng.randf_range(50, 80))
		_branch(p, b, t, 5.0, 3, rng)
	return p


static func _branch(p: Paint, a: Vector2, b: Vector2, wd: float, depth: int, rng: RandomNumberGenerator) -> void:
	var n := maxi(2, int(a.distance_to(b)))
	for i in n:
		var q := a.lerp(b, float(i) / float(n))
		var r := int(ceil(wd * 0.5 * (1.0 - float(i) / float(n) * 0.5)))
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				p.blend(posmod(int(q.x) + dx, p.w), posmod(int(q.y) + dy, p.h), Color("#0e0f0c"), 0.95)
	if depth <= 0:
		return
	for k in 2:
		var m := a.lerp(b, rng.randf_range(0.4, 0.8))
		var dir := (b - a).rotated(rng.randf_range(0.5, 1.0) * (-1.0 if k == 0 else 1.0)) * rng.randf_range(0.35, 0.55)
		_branch(p, m, m + dir, maxf(1.0, wd * 0.55), depth - 1, rng)


# ── 성 ─────────────────────────────────────────────────────

## 성벽 면: 위 = 성가퀴(톱니 — 틈 투명), 그 아래 돌출 받침 줄, 마름돌 벽(줄마다 다른 돌 폭), 256px마다 버팀벽, 화살 구멍, 흘러내린 때·핏자국.
static func _castle_face(w: int, h: int, s: int, cfg: Dictionary) -> Paint:
	var p := Paint.new(w, h, s)
	var stone := Color(str(cfg.get("stone", "#6a5650")))
	var dark := Color(str(cfg.get("stone_dark", "#2a1e1c")))
	var grain := Seam.field(w, h, s, 0.06, 3)
	var big := Seam.field(w, h, s + 1, 0.012, 3)
	var merlon_h := 20
	var corbel := 34
	var period := 64
	for y in h:
		var t := float(y) / h
		for x in w:
			if y < merlon_h and posmod(x, period) >= 42:
				continue  # 성가퀴 틈
			var i := y * w + x
			var c := stone.lerp(dark, smoothstep(0.15, 1.0, t) * 0.75)
			var k := 1.0 + (grain[i] - 0.5) * 0.22 + (big[i] - 0.5) * 0.2
			p.blend(x, y, Color(c.r * k, c.g * k, c.b * k), 1.0)
	# 성가퀴 윗면·모서리
	for x in w:
		var mx := posmod(x, period)
		if mx < 42:
			for y in 3:
				p.blend(x, y, stone.lightened(0.25), 0.8)
			if mx < 2 or mx > 39:
				for y in merlon_h:
					p.blend(x, y, Ink.INK, 0.55 if mx < 2 else 0.35)
	for x in w:  # 성가퀴 아래 띠·돌출 받침(작은 아치 그늘)
		for y in range(merlon_h, merlon_h + 3):
			p.blend(x, y, stone.lightened(0.15), 0.7)
		var bx := posmod(x, 32)
		for y in range(merlon_h + 3, corbel):
			if bx >= 22:
				p.blend(x, y, Ink.INK, 0.55 - (y - merlon_h) * 0.02)
		p.blend(x, corbel, Ink.INK, 0.6)
		p.blend(x, corbel + 1, Ink.INK, 0.3)
	var rng := p.rng
	var y0 := corbel + 2
	var course := 22
	while y0 < h:  # 마름돌 줄
		var x := rng.randf() * 40.0
		var xs: Array[float] = []
		while x < w + 40:
			xs.append(x)
			x += rng.randf_range(34.0, 62.0)
		for xx in w:
			p.blend(xx, y0, Ink.INK, 0.55)
			p.blend(xx, y0 + 1, stone.lightened(0.18), 0.25)
		for bx: float in xs:
			for yy in range(y0, mini(h, y0 + course)):
				p.blend(posmod(int(bx), w), yy, Ink.INK, 0.5)
				p.blend(posmod(int(bx) + 1, w), yy, stone.lightened(0.15), 0.2)
		y0 += course
	for k in 2:  # 버팀벽(밝은 기둥 + 오른쪽 그늘)
		var cx := k * w / 2 + 96
		for yy in range(corbel + 2, h):
			for dx in range(-14, 15):
				var px := posmod(cx + dx, w)
				var c := p.get_c(px, yy)
				p.blend(px, yy, c.lightened(0.12) if dx < 10 else c.darkened(0.35), 0.8)
			p.blend(posmod(cx - 15, w), yy, Ink.INK, 0.6)
			p.blend(posmod(cx + 15, w), yy, Ink.INK, 0.7)
	for k in 4:  # 화살 구멍
		var sx := k * w / 4 + 40
		var sy := int(h * 0.42)
		for yy in range(sy, sy + 22):
			for dx in range(-2, 3):
				p.blend(posmod(sx + dx, w), yy, Color("#050404"), 0.95)
		Ink.line(p, Vector2(sx - 4, sy - 2), Vector2(sx + 4, sy - 2), 1.4, stone.lightened(0.2), 0.6, 0.2)
	for k in 30:  # 흘러내린 때
		var x := rng.randf() * w
		var y := rng.randf_range(corbel, h * 0.6)
		Ink.line(p, Vector2(x, y), Vector2(x + rng.randf_range(-2, 2), y + rng.randf_range(20, 70)), rng.randf_range(2.0, 5.0), Color("#1a1210"), 0.22, 0.4)
	for k in 6:  # 핏자국
		var x := rng.randf() * w
		Ink.line(p, Vector2(x, corbel + rng.randf() * 20), Vector2(x + rng.randf_range(-3, 3), corbel + rng.randf_range(40, 110)), rng.randf_range(1.5, 3.0), Color("#4a1012"), 0.4, 0.5)
	for x in w:  # 밑동 그늘·이끼
		for d in 14:
			p.blend(x, h - 1 - d, Color("#0e0b0a"), 0.5 * (1.0 - d / 14.0))
	Ink.finish(p, 0.03, 0.0)
	return p


## 성 너머 지붕들(위에서 내려다본 3/4): 줄마다 높이가 다른 건물 몇 채 — 용마루가 가로(북쪽 경사 어둡고 남쪽 밝음)·세로(서쪽 밝음)인 지붕,
## 슬레이트·기와 결, 굴뚝, 둥근 탑, 판석 안뜰. 건물 사이는 어두운 골목. 가로·세로로 이어 붙여도 이음매 없게(줄 높이 합 = h, 건물은 가로로 감는다).
static func _roofs(w: int, h: int, s: int, cfg: Dictionary) -> Paint:
	var p := Paint.new(w, h, s)
	var roofs: Array[Color] = [Color(str(cfg.get("roof", "#4e3c3a"))), Color(str(cfg.get("roof_slate", "#44464e"))), Color(str(cfg.get("roof_clay", "#5a3a30")))]
	var roof_dark := Color(str(cfg.get("roof_dark", "#1c1414")))
	var lane := Color(str(cfg.get("lane", "#0e0a0a")))
	var stone := Color(str(cfg.get("stone", "#6a5650")))
	var grain := Seam.field(w, h, s, 0.05, 3)
	var moss := Seam.field(w, h, s + 7, 0.02, 3)
	for y in h:
		for x in w:
			p.blend(x, y, lane.lerp(Color("#1e1816"), grain[y * w + x] * 0.6), 1.0)
	var rng := p.rng
	var heights: Array[int] = [176, 160, 176]
	var y0 := 0
	for rh in heights:
		var x := rng.randf() * 80.0
		var end := x + w
		while x < end - 40:
			var bw := minf(rng.randf_range(110.0, 230.0), end - x)
			var it := rng.randf_range(5.0, 14.0)
			var ib := rng.randf_range(10.0, 30.0)
			var rect := Rect2(x + it, y0 + it, bw - it * 2, rh - it - ib)
			var roll := rng.randf()
			var col: Color = roofs[rng.randi() % roofs.size()]
			if roll < 0.16:
				_tower(p, rect, col, roof_dark, stone)
			elif roll < 0.26:
				_yard(p, rect, stone)
			else:
				_roof(p, rect, col, roof_dark, rng, roll < 0.46)
			x += bw
		y0 += rh
	for y in h:  # 지붕 이끼·때
		for x in w:
			var m := moss[y * w + x]
			if m > 0.62:
				p.blend(x, y, Color("#262a1c"), (m - 0.62) * 1.4)
	Ink.finish(p, 0.03, 0.0)
	return p


static func _roof(p: Paint, r: Rect2, roof: Color, dark: Color, rng: RandomNumberGenerator, vertical: bool) -> void:
	var ridge := (r.position.x + r.size.x * rng.randf_range(0.42, 0.58)) if vertical else (r.position.y + r.size.y * rng.randf_range(0.38, 0.5))
	var tone := rng.randf_range(-0.08, 0.08)
	for ox: float in [-p.w, 0.0, p.w]:
		var x0 := int(r.position.x + ox)
		var x1 := int(r.end.x + ox)
		var rg := ridge + (ox if vertical else 0.0)
		for yy in range(int(r.position.y), int(r.end.y)):
			for xx in range(x0, x1):
				var lit := xx < rg if vertical else yy >= rg
				var base := roof.lightened(0.14 + tone) if lit else dark.lerp(roof, 0.4 + tone)
				var c := base
				var along := (xx - int(rg)) if vertical else (yy - int(rg))
				var across := yy if vertical else xx
				if posmod(along, 7) == 0:
					c = c.darkened(0.42)  # 슬레이트 줄
				elif posmod(across + (along / 7) * 5, 11) == 0:
					c = c.darkened(0.22)
				p.blend(xx, yy, c, 1.0)
		if vertical:
			Ink.line(p, Vector2(rg, r.position.y), Vector2(rg, r.end.y), 2.0, roof.lightened(0.35), 0.7, 0.2)
		else:
			Ink.line(p, Vector2(x0, rg), Vector2(x1, rg), 2.0, roof.lightened(0.35), 0.7, 0.2)
		Ink.path(p, PackedVector2Array([Vector2(x0, r.position.y), Vector2(x1, r.position.y), Vector2(x1, r.end.y), Vector2(x0, r.end.y)]), 1.6, true, Ink.INK, 0.8, 0.4)
		for yy in range(int(r.end.y), int(r.end.y) + 7):  # 남쪽 벽 면 그림자(지붕 아래 벽이 보이는 띠)
			for xx in range(x0, x1):
				p.blend(xx, yy, Color("#2a201e") if yy < r.end.y + 4 else Color("#050404"), 0.75 * (1.0 - (yy - r.end.y) / 7.0))
	if rng.randf() < 0.7:  # 굴뚝
		var cx := r.position.x + rng.randf_range(10.0, r.size.x - 18.0)
		var cy := r.position.y + rng.randf_range(6.0, r.size.y * 0.4)
		for ox: float in [-p.w, 0.0, p.w]:
			p.fill_rect(cx + ox, cy, 10, 13, func(_x: int, py: int) -> Color: return Color("#5a4a44").darkened(0.25 if py > cy + 9 else 0.0), 1.0)
			Ink.path(p, Paint.rect_poly(cx + ox, cy, 10, 13), 1.0, true, Ink.INK, 0.7, 0.2)


## 판석 안뜰(지붕 사이 트인 곳) — 우물 하나.
static func _yard(p: Paint, r: Rect2, stone: Color) -> void:
	for ox: float in [-p.w, 0.0, p.w]:
		var x0 := int(r.position.x + ox)
		for yy in range(int(r.position.y), int(r.end.y)):
			for xx in range(x0, int(r.end.x + ox)):
				var c := stone.darkened(0.35)
				if posmod(yy, 12) == 0 or posmod(xx + (yy / 12) * 7, 17) == 0:
					c = c.darkened(0.4)
				p.blend(xx, yy, c, 1.0)
		var cc := r.get_center() + Vector2(ox, 0)
		p.fill_poly(_circle(cc, 9.0, 16), func(_x: int, _y: int) -> Color: return stone.lightened(0.05), 1.0)
		p.fill_poly(_circle(cc, 5.5, 16), func(_x: int, _y: int) -> Color: return Color("#050404"), 1.0)
		Ink.path(p, _circle(cc, 9.0, 16), 1.2, true, Ink.INK, 0.8, 0.2)


static func _tower(p: Paint, r: Rect2, roof: Color, dark: Color, stone: Color) -> void:
	var c := r.get_center()
	var rad := minf(r.size.x, r.size.y) * 0.45
	for ox: float in [-p.w, 0.0, p.w]:
		var cc := c + Vector2(ox, 0)
		for yy in range(int(cc.y - rad - 2), int(cc.y + rad + 8)):
			for xx in range(int(cc.x - rad - 2), int(cc.x + rad + 3)):
				var d := Vector2(xx, yy) - cc
				if d.length() <= rad:
					var a := atan2(d.y, d.x)  # 원뿔 지붕: 남동쪽이 밝다
					var lit := 0.5 + 0.5 * cos(a - 0.9)
					var col := dark.lerp(roof.lightened(0.2), lit)
					if posmod(int(a / TAU * 32.0), 2) == 0:
						col = col.darkened(0.12)
					p.blend(xx, yy, col, 1.0)
				elif d.length() <= rad + 3 and d.y > 0:
					p.blend(xx, yy, stone.darkened(0.3), 0.9)  # 탑 몸통 윗단
		Ink.path(p, _circle(cc, rad, 28), 1.6, true, Ink.INK, 0.8, 0.3)
		Ink.line(p, cc, cc + Vector2(0, -2), 3.0, roof.lightened(0.4), 0.9, 0.1)


static func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		out.append(c + Vector2(cos(TAU * k / n), sin(TAU * k / n)) * r)
	return out


# ── 얼음 ───────────────────────────────────────────────────

## 솟은 빙벽: 눈 덮인 꼭대기(위 10px — 아래로 늘어진 눈·고드름), 세로 홈 결, 밑으로 갈수록 짙은 청색.
static func _ice_face(w: int, h: int, s: int, cfg: Dictionary) -> Paint:
	var p := Paint.new(w, h, s)
	var ice := Color(str(cfg.get("ice", "#9ab6cc")))
	var deep := Color(str(cfg.get("ice_dark", "#2a3e52")))
	var snow := Color(str(cfg.get("snow", "#eef4fa")))
	var flute := Seam.field(w, h, s, 0.04, 3)
	var fine := Seam.field(w, h, s + 1, 0.12, 2)
	var cap := PackedFloat32Array()
	cap.resize(w)
	for x in w:
		var u := float(x) / w * TAU
		cap[x] = 9.0 + sin(u * 5.0 + s) * 3.0 + sin(u * 13.0) * 2.0
	for y in h:
		var t := float(y) / h
		for x in w:
			var i := y * w + x
			var f := Seam.at(flute, w, h, x, y / 8)  # 세로로 늘인 홈
			var c := ice.lerp(deep, smoothstep(0.1, 1.0, t))
			var k := 1.0 + (f - 0.5) * 0.55 + (fine[i] - 0.5) * 0.12
			c = Color(c.r * k, c.g * k, c.b * k)
			if y < cap[x]:
				c = snow.darkened(0.15 if cap[x] - y < 2.0 else 0.0)
			p.blend(x, y, c, 1.0)
	var rng := p.rng
	for k in 30:  # 고드름·흘러내린 얼음
		var x := rng.randf() * w
		var ln := rng.randf_range(10.0, 50.0)
		for ox: float in [-w, 0.0, w]:
			var x0 := x + ox
			var c0 := cap[posmod(int(x), w)]
			p.fill_poly(PackedVector2Array([Vector2(x0 - 3, c0), Vector2(x0 + 3, c0), Vector2(x0, c0 + ln)]), func(_x: int, py: int) -> Color: return snow.lerp(ice, (py - c0) / ln), 0.9)
	for x in w:
		p.blend(x, int(cap[x]), Ink.INK, 0.35)
		for d in 12:
			p.blend(x, h - 1 - d, Color("#0a1018"), 0.45 * (1.0 - d / 12.0))
	Ink.finish(p, 0.025, 0.0)
	return p


## 설원(솟은 빙벽 꼭대기 너머): 푸른 그늘이 섞인 눈, 바람 결, 드문드문 바위·눈 덮인 전나무.
static func _snowfield(w: int, h: int, s: int, cfg: Dictionary) -> Paint:
	var p := Paint.new(w, h, s)
	var snow := Color(str(cfg.get("snow", "#eef4fa")))
	var shade := Color(str(cfg.get("snow_shade", "#a8bccc")))
	var big := Seam.field(w, h, s, 0.01, 3)
	var wind := Seam.field(w, h, s + 1, 0.03, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.at(wind, w, h, x / 3, y)  # 가로로 늘인 바람 결
			var c := snow.lerp(shade, clampf(big[i] * 0.9 + (r - 0.5) * 0.5, 0.0, 1.0))
			p.blend(x, y, c, 1.0)
	var rng := p.rng
	for k in 9:  # 바위
		var q := Vector2(rng.randf() * w, rng.randf() * h)
		var rad := rng.randf_range(6.0, 16.0)
		for ox: float in [-w, 0.0, w]:
			for oy: float in [-h, 0.0, h]:
				var cc := q + Vector2(ox, oy)
				p.fill_poly(_circle(cc, rad, 9), func(px: int, py: int) -> Color: return Color("#3a4450").lightened(0.25 if py < cc.y - rad * 0.3 else 0.0), 1.0)
				p.fill_poly(_circle(cc + Vector2(0, -rad * 0.35), rad * 0.7, 9), func(_x: int, _y: int) -> Color: return snow.darkened(0.05), 0.9)
	for k in 7:  # 눈 덮인 전나무(위에서 본 별 모양)
		var q := Vector2(rng.randf() * w, rng.randf() * h)
		for ox: float in [-w, 0.0, w]:
			for oy: float in [-h, 0.0, h]:
				var cc := q + Vector2(ox, oy)
				for j in 8:
					var a := TAU * j / 8.0
					Ink.line(p, cc, cc + Vector2(cos(a), sin(a)) * 13.0, 5.0, Color("#26402e"), 0.85, 0.3)
				Ink.glow(p, cc.x - 3, cc.y - 3, 7.0, snow, 0.5, false)
	Ink.finish(p, 0.02, 0.0)
	return p
