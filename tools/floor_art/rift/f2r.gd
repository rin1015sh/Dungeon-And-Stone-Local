extends RefCounted
## 바위사막 그림(LD14 → 레벨 디자인 11차 — Common.gd 계약, docs/plans/floor2.md §4): 외곽은 RiseMesa 검은 바위산(specs rise).
## 바닥 셋 — 갈라진 굳은 흙판(hardpan — 볕에 말라 거북등처럼 갈라짐, 틈에 모래), 바람 결 모래(dunesand — 물결 등성이 · 골, 드문 자갈),
## 모래에 묻힌 옛 판석(sandflag — 횃불 옛길: 판 틈을 모래가 메움). 벽 하나 — 사암 잔해(sandstone — 망자의 땅 석조 그림을 사암 색으로).
## 서 있는 소품은 없다(화로 · 석상은 핏빛성채 그림 — 발밑만 이 바닥, 타일 f2r_fire · f2r_statue).

const Paint := preload("res://tools/city_art/Paint.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const F2D := preload("res://tools/floor_art/rift/f2d.gd")

const SAND_LIT := Color("#f2dcae")
const SAND_DARK := Color("#9a7a4e")
const CRACK := Color("#3a2a1a")
const PEBBLE := Color("#6a5440")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	match style:
		"hardpan":
			_hardpan(p, col, s)
		"dunesand":
			_dunes(p, col, s)
		"sandflag":
			_sandflag(p, col, s)
		"sandstone":
			F2D.base(p, "masonry", part, col, s)
		_:
			F2D.base(p, style, part, col, s)


static func detail(p: Paint, style: String, part: String, v: int, col: Color) -> void:
	match style:
		"dunesand", "hardpan":
			_pebbles(p, v, 3 if style == "dunesand" else 5)
		"sandflag":
			_pebbles(p, v, 2)
		"sandstone":
			return  # 망자의 땅 석조 잔손질(이끼 · 핏자국)은 사막에 맞지 않는다 — 바탕만


static func stand(_tile: String, w: int, h: int, seed_value: int) -> Paint:
	return Paint.new(w, h, seed_value)


## 거북등 흙판: 셀 경계 = 틈(어둡고 모래가 고임), 판 가장자리는 말려 올라 밝다, 판마다 밝기가 조금 다르다.
static func _hardpan(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var cell := Seam.field(w, h, s + 501, 0.05, 1, true)
	var tone := Seam.field(w, h, s + 502, 0.07, 1)
	var hf := Seam.field(w, h, s, 0.09, 3)
	var dust := Seam.field(w, h, s + 503, 0.03, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 2.5)
			var t := 0.5 + (tone[i] - 0.5) * 0.4 + r * 0.35
			var c := col.darkened(0.25).lerp(col.lightened(0.15), clampf(t, 0.0, 1.0))
			var e := cell[i]
			var lip := smoothstep(0.08, 0.16, e) * (1.0 - smoothstep(0.16, 0.26, e))  # 말려 오른 가장자리
			c = c.lightened(lip * 0.12)
			var crack := 1.0 - smoothstep(0.03, 0.08, e)
			if crack > 0.0:
				c = c.lerp(CRACK.lerp(SAND_DARK, smoothstep(0.4, 0.7, dust[i])), crack * 0.85)
			c = c.lerp(SAND_LIT, smoothstep(0.62, 0.9, dust[i]) * 0.35)  # 바람에 쌓인 모래 먼지
			p.blend(x, y, c, 1.0)


## 바람 결 모래: 비스듬한 물결 — 등성이(빛 쪽)는 밝고 골은 어둡다. 물결 방향 · 간격이 잡음으로 휘어 칸마다 같아 보이지 않게.
static func _dunes(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var warp := Seam.field(w, h, s + 601, 0.04, 2)
	var swell := Seam.field(w, h, s + 602, 0.025, 2)
	var fine := Seam.field(w, h, s + 603, 0.5, 1)
	var waves := 6.0  # 칸 하나에 물결 수(이음매 없이 — 정수)
	for y in h:
		for x in w:
			var i := y * w + x
			var u := (float(x) / w + float(y) / h * 0.5) * waves + (warp[i] - 0.5) * 0.7
			var ph := fposmod(u, 1.0)
			var ridge := smoothstep(0.0, 0.7, ph) * (1.0 - smoothstep(0.7, 1.0, ph))  # 완만히 오르고 급히 떨어지는 물결
			var lit := ridge * 0.9 + (swell[i] - 0.5) * 0.4 + (fine[i] - 0.5) * 0.1
			var c := col.darkened(0.22).lerp(col.lightened(0.16), clampf(0.35 + lit, 0.0, 1.0))
			var shade := smoothstep(0.85, 1.0, ph)  # 물결 뒤 그늘
			c = c.darkened(shade * 0.28)
			p.blend(x, y, c, 1.0)


## 모래에 묻힌 판석: 판 경계에 모래가 차고, 군데군데 판이 모래에 덮였다.
static func _sandflag(p: Paint, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var cell := Seam.field(w, h, s + 701, 0.045, 1, true)
	var tone := Seam.field(w, h, s + 702, 0.05, 1)
	var hf := Seam.field(w, h, s, 0.08, 3)
	var cover := Seam.field(w, h, s + 703, 0.035, 2)
	var fine := Seam.field(w, h, s + 2, 0.4, 1)
	for y in h:
		for x in w:
			var i := y * w + x
			var r := Seam.relief(hf, w, h, x, y, 3.0)
			var t := 0.5 + (tone[i] - 0.5) * 0.2 + r * 0.3 + (fine[i] - 0.5) * 0.12
			var c := col.darkened(0.2).lerp(col.lightened(0.08), clampf(t, 0.0, 1.0))
			var joint := 1.0 - smoothstep(0.05, 0.13, cell[i])
			c = c.lerp(SAND_DARK.lerp(SAND_LIT, fine[i] * 0.5), joint * 0.8)  # 판 틈의 모래
			var drift := smoothstep(0.55, 0.75, cover[i])
			c = c.lerp(SAND_LIT.lerp(SAND_DARK, 0.35 - r * 0.4), drift * 0.3)  # 모래가 덮은 판
			p.blend(x, y, c, 1.0)


## 자갈 몇 알(변형마다 다른 자리 — 가운데 위주, 가장자리는 Common.cell이 바탕으로 되돌린다).
static func _pebbles(p: Paint, v: int, n: int) -> void:
	var w := p.w
	var h := p.h
	for k in n:
		var hx := Paint.hash01(v * 13 + k, 17, 91)
		var hy := Paint.hash01(v * 13 + k, 29, 93)
		if Paint.hash01(v, k, 97) < 0.35:
			continue
		var cx := w * (0.2 + hx * 0.6)
		var cy := h * (0.2 + hy * 0.6)
		var rad := 1.5 + Paint.hash01(k, v, 99) * 2.5
		for y in range(int(cy - rad) - 1, int(cy + rad) + 2):
			for x in range(int(cx - rad) - 1, int(cx + rad) + 2):
				var d := Vector2(x - cx, (y - cy) * 1.3).length()
				if d > rad or x < 0 or y < 0 or x >= w or y >= h:
					continue
				var lit := clampf(0.5 - (x - cx + y - cy) / (rad * 2.0), 0.0, 1.0)
				p.blend(x, y, PEBBLE.darkened(0.3).lerp(PEBBLE.lightened(0.25), lit), 1.0 - smoothstep(rad - 1.0, rad, d))
		# 자갈 아래 그림자
		for x in range(int(cx - rad), int(cx + rad) + 1):
			var y := int(cy + rad * 0.8) + 1
			if x >= 0 and y < h and x < w:
				p.blend(x, y, CRACK, 0.25)
