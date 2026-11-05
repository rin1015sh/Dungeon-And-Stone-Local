extends RefCounted
## 2층 망자의 땅 그림(A5 — Common.gd 계약, docs/plans/floor2.md §3): 핏빛성채 그리는 법을 빌리고 색은 타일 색(검은 진창 · 잿빛 흙 · 회흑 돌)이 정한다.
## 다만 길 밖 깊은 늪(blackwater)은 따로 — 피 웅덩이가 아니라 검고 차가운 물(은빛 번들거림 · 떠다니는 재 거품 · 갈대 · 물결),
## 사용자 2026-11-05 "길 경계가 흐리다 · 황량하다". 서 있는 소품은 핏빛성채 소품 그림을 이 시트에 다시 굽는다(specs.json places.f2d.stands).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const BF := preload("res://tools/floor_art/rift/bf.gd")

const WATER_DEEP := Color("#0c0e10")
const GLOSS := Color("#a8b4c0")
const SCUM := Color("#4a4842")
const REED := Color("#3a3628")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if style == "blackwater":
		_water(p, col, s)
		return
	BF.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	if style == "blackwater":
		if v in [1, 2]:  # 짝 · 홀 칸에 하나씩만(재 거품 · 갈대) — 나머지는 맨물(칸마다 무늬가 찍히면 벽지처럼 보인다)
			_water_detail(p, v)
		return
	if style in ["ash", "mudroad"] and part == "floor":  # 잔손질이 칸마다 찍히면 격자 무늬로 보인다(변형은 체스판 짝 · 홀 칸으로 나뉜다 — FloorArtLayer.variant)
		if v in [0, 1, 3, 4] or (style == "mudroad" and v == 5):  # 여섯 중 넷(진창은 다섯)은 맨땅 — 진창 웅덩이는 데칼(wet · rot)이 맡는다
			return
		v = 2 if style == "ash" else 4  # 굳은 땅 = 잔돌(짝 · 홀 칸에 하나씩), 진창 = 돌
	BF.detail(p, style, part, v, col)


static func stand(tile: String, w: int, h: int, seed_value: int) -> Paint:
	return BF.stand(tile, w, h, seed_value)


## 검은 물: 깊이(고정 무늬)로 어둡게, 물결 기복의 밝은 쪽에 차가운 은빛 번들거림, 가장 어두운 골에 먹빛.
static func _water(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var hf := Seam.field(w, h, 263, 0.025, 3)
	var rp := Seam.field(w, h, s, 0.045, 2)
	var sh := Seam.field(w, h, s + 1, 0.03, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(rp, w, h, x, y, 2.0)
			var c := WATER_DEEP.lerp(col, clampf(0.4 + hf[i] * 0.4, 0.0, 1.0))
			var gloss := pow(clampf(r * 1.6, 0.0, 1.0), 3.0) * smoothstep(0.5, 0.85, sh[i])
			c = c.lerp(GLOSS, gloss * 0.22)
			c = c.lerp(Color("#050607"), pow(clampf(-r * 1.6, 0.0, 1.0), 2.0) * 0.25)
			p.blend(x, y, c, 1.0)


## 잔손질: 1 재 거품 · 2 갈대 · 3 물결 고리 · 4 떠다니는 나무토막 · 5 기포(지금은 1 · 2만 쓴다 — detail).
static func _water_detail(p: Paint, v: int) -> void:
	var w := float(p.w)
	var u := w / 64.0
	var cx := w * 0.5
	var cy := float(p.h) * 0.5
	match v:
		1:  # 재 거품 — 흐린 얼룩 몇 덩이
			for k in 9:
				var a := Vector2(cx + (Paint.hash01(k, 1, v) - 0.5) * 60 * u, cy + (Paint.hash01(k, 2, v) - 0.5) * 50 * u)
				var r := (4.0 + Paint.hash01(k, 3, v) * 9.0) * u
				for y in range(int(a.y - r), int(a.y + r) + 1):
					for x in range(int(a.x - r * 1.4), int(a.x + r * 1.4) + 1):
						var d := Vector2((x - a.x) / 1.4, y - a.y).length() / r
						if d < 1.0 and x >= 0 and y >= 0 and x < p.w and y < p.h:
							p.blend(x, y, SCUM, (1.0 - d) * 0.3)
		2:  # 갈대 — 물에서 솟은 마른 줄기 다발
			for k in 6:
				var b := Vector2(cx + (Paint.hash01(k, 4, v) - 0.5) * 22 * u, cy + 10 * u + (Paint.hash01(k, 5, v) - 0.5) * 10 * u)
				var t := b + Vector2((Paint.hash01(k, 6, v) - 0.5) * 16 * u, -(22.0 + Paint.hash01(k, 7, v) * 24.0) * u)
				Ink.line(p, b, t, 1.6 * u, REED.lerp(Color("#6a6250"), Paint.hash01(k, 8, v)), 0.95, 0.5)
				Ink.line(p, b + Vector2(1.5 * u, 0), t + Vector2(1.0 * u, 0), 0.6 * u, Color("#14120e"), 0.5, 0.4)
			for k in 3:  # 물 위 반사(짧은 밝은 금)
				var y := cy + 14 * u + k * 3 * u
				Ink.line(p, Vector2(cx - 14 * u, y), Vector2(cx + 12 * u, y), 0.8 * u, GLOSS, 0.25, 0.6)
		3:  # 물결 고리
			for ring in 3:
				var r := (8.0 + ring * 8.0) * u
				var pts := PackedVector2Array()
				for a in 25:
					var ang := TAU * a / 24.0
					pts.append(Vector2(cx + cos(ang) * r * 1.5, cy + sin(ang) * r * 0.6))
				Ink.path(p, pts, 0.8 * u, true, GLOSS, 0.16 - ring * 0.04, 0.6)
		4:  # 떠다니는 썩은 나무토막
			var a := Vector2(cx - 22 * u, cy + 6 * u)
			var b := Vector2(cx + 20 * u, cy - 4 * u)
			Ink.line(p, a, b, 7.0 * u, Color("#2c2620"), 1.0, 0.6)
			Ink.line(p, a + Vector2(0, -2 * u), b + Vector2(0, -2 * u), 2.0 * u, Color("#4e443a"), 0.8, 0.5)
			Ink.line(p, a + Vector2(0, 4 * u), b + Vector2(0, 4 * u), 1.0 * u, GLOSS, 0.25, 0.6)
		5:  # 기포
			for k in 3:
				var a := Vector2(cx + (Paint.hash01(k, 9, v) - 0.5) * 50 * u, cy + (Paint.hash01(k, 10, v) - 0.5) * 40 * u)
				var r := (1.5 + Paint.hash01(k, 11, v) * 2.5) * u
				var pts := PackedVector2Array()
				for q in 13:
					pts.append(a + Vector2(cos(TAU * q / 12.0), sin(TAU * q / 12.0)) * r)
				Ink.path(p, pts, 0.6 * u, true, GLOSS, 0.25, 0.2)
