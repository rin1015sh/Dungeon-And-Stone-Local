extends RefCounted
## 솟은 외곽 kind "mesa"(짐승의 소굴 — LD13, Rise.gd가 부른다): 붉은 사암 절벽 면(가로 결 · 세로 금 · 꼭대기 테두리 · 밑동 돌부스러기)과
## 메사 꼭대기(메마른 흙 평원 · 바람 결 · 바위 · 가시덤불 — 위에서 본 것). cfg = specs.json places.f2b.rise.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")


static func face(w: int, h: int, s: int, cfg: Dictionary) -> Paint:
	var p := Paint.new(w, h, s)
	var rock := Color(str(cfg.get("rock", "#9a6a4a")))
	var dark := Color(str(cfg.get("rock_dark", "#4a2e20")))
	var band := Seam.field(w, h, s, 0.03, 3)
	var fine := Seam.field(w, h, s + 1, 0.12, 2)
	var cap := PackedFloat32Array()
	cap.resize(w)
	for x in w:
		var u := float(x) / w * TAU
		cap[x] = 5.0 + sin(u * 4.0 + s) * 2.0 + sin(u * 11.0) * 1.2
	for y in h:
		var t := float(y) / h
		for x in w:
			var i := y * w + x
			var b := sin(float(y) * 0.55 + (Seam.at(band, w, h, x / 6, y) - 0.5) * 6.0) * 0.5 + 0.5  # 가로 사암 결
			var c := rock.lerp(dark, clampf(b * 0.35 + smoothstep(0.2, 1.0, t) * 0.55, 0.0, 1.0))
			var k := 1.0 + (fine[i] - 0.5) * 0.18
			c = Color(c.r * k, c.g * k, c.b * k)
			if y < cap[x]:
				c = rock.lightened(0.18)
			p.blend(x, y, c, 1.0)
	var rng := p.rng
	for k in 26:  # 세로 금
		var x := rng.randf() * w
		var y0 := cap[posmod(int(x), w)] + rng.randf_range(0.0, h * 0.3)
		var ln := rng.randf_range(h * 0.15, h * 0.6)
		for ox: float in [-w, 0.0, w]:
			Ink.line(p, Vector2(x + ox, y0), Vector2(x + ox + rng.randf_range(-4.0, 4.0), y0 + ln), 1.2, dark.darkened(0.4), 0.6, 0.6)
	for x in w:
		p.blend(x, int(cap[x]), Ink.INK, 0.4)
		for d in 14:  # 밑동 그늘 · 돌부스러기
			p.blend(x, h - 1 - d, Color("#1a100a"), 0.4 * (1.0 - d / 14.0))
	Ink.finish(p, 0.03, 0.0)
	return p


static func top(w: int, h: int, s: int, cfg: Dictionary) -> Paint:
	var p := Paint.new(w, h, s)
	var ground := Color(str(cfg.get("ground", "#8a6a4c")))
	var shade := Color(str(cfg.get("ground_dark", "#5a4232")))
	var big := Seam.field(w, h, s, 0.012, 3)
	var wind := Seam.field(w, h, s + 1, 0.035, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.at(wind, w, h, x / 3, y)
			p.blend(x, y, ground.lerp(shade, clampf(big[i] * 0.8 + (r - 0.5) * 0.4, 0.0, 1.0)), 1.0)
	var rng := p.rng
	for k in 12:  # 바위(위에서 본 둥근 덩어리 — 밝은 윗면 · 그늘)
		var q := Vector2(rng.randf() * w, rng.randf() * h)
		var rad := rng.randf_range(5.0, 13.0)
		for ox: float in [-w, 0.0, w]:
			for oy: float in [-h, 0.0, h]:
				var cc := q + Vector2(ox, oy)
				p.fill_poly(_circle(cc + Vector2(2, 3), rad, 9), func(_x: int, _y: int) -> Color: return Color(0, 0, 0, 0.35), 1.0)
				p.fill_poly(_circle(cc, rad, 9), func(_x: int, py: int) -> Color: return Color("#7a5440").lightened(0.2 if py < cc.y - rad * 0.2 else 0.0), 1.0)
	for k in 16:  # 가시덤불
		var q := Vector2(rng.randf() * w, rng.randf() * h)
		for ox: float in [-w, 0.0, w]:
			for oy: float in [-h, 0.0, h]:
				var cc := q + Vector2(ox, oy)
				for j in 7:
					var a := TAU * j / 7.0 + rng.randf() * 0.3
					Ink.line(p, cc, cc + Vector2(cos(a), sin(a)) * rng.randf_range(5.0, 9.0), 1.6, Color("#4a4028"), 0.85, 0.3)
	Ink.finish(p, 0.02, 0.0)
	return p


static func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out
