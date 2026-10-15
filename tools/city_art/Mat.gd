extends RefCounted
## 재질 셰이더(Paint.fill_poly에 넘기는 (x, y) -> Color): 회벽 · 벽돌 · 다듬은 돌 · 막돌 · 판자 · 들보 · 점판암 · 기와 · 초가.
## 모두 붓결(Paint.vary)과 얼룩·빗물 자국을 얹어 손으로 칠한 느낌을 낸다. ox, oy = 무늬 기준점(벽마다 줄을 맞춘다).

const Paint := preload("res://tools/city_art/Paint.gd")


## 회벽: 붓결 + 빗물 자국(세로) + 큰 때 얼룩. peel > 0이면 얼룩이 짙은 곳에서 벗겨져 벽돌이 드러난다.
static func plaster(p: Paint, base: Color, peel: float = 0.0, brick_c: Color = Color("#6a3d2e")) -> Callable:
	var brick_sh := brick(p, brick_c, 0, 0)
	return func(x: int, y: int) -> Color:
		var c := p.vary(base, x, y, 0.2)
		var s := p.nz("vs", x, y)
		if s > 0.55:
			c = c.darkened((s - 0.55) * 0.55)
		var lo := p.nz("lo", p.w - 1 - x, y)
		if lo > 0.55:
			c = c.lerp(Color("#3e3424"), minf(0.7, (lo - 0.55) * 1.6))
		if peel > 0.0 and lo > 1.0 - peel:
			var edge := lo - (1.0 - peel)
			return Color("#2a2018") if edge < 0.025 else brick_sh.call(x, y)
		return c


## 벽돌: 줄마다 반 장 엇갈림, 장마다 다른 색, 위 밝게·아래 어둡게, 줄눈.
static func brick(p: Paint, base: Color, ox: int, oy: int, bw: int = 22, bh: int = 9, mortar: Color = Color("#2c2620")) -> Callable:
	return func(x: int, y: int) -> Color:
		var ly := y - oy
		var row := floori(float(ly) / bh)
		var lx := x - ox + (bw / 2 if row % 2 != 0 else 0)
		var col := floori(float(lx) / bw)
		var bx := posmod(lx, bw)
		var by := posmod(ly, bh)
		if bx < 2 or by < 2:
			return p.vary(mortar, x, y, 0.25)
		var tone := base.lightened((Paint.hash01(row, col) - 0.5) * 0.3)
		if by == 2:
			tone = tone.lightened(0.12)
		elif by == bh - 1:
			tone = tone.darkened(0.2)
		return p.vary(tone, x, y, 0.22)


## 다듬은 돌(마름돌): 큰 블록, 위·왼쪽 모서리 밝게, 아래·오른쪽 어둡게, 정 자국(세포 잡음).
static func ashlar(p: Paint, base: Color, ox: int, oy: int, bw: int = 46, bh: int = 22, mortar: Color = Color("#24221f")) -> Callable:
	return func(x: int, y: int) -> Color:
		var ly := y - oy
		var row := floori(float(ly) / bh)
		var rw := bw + int((Paint.hash01(row, 0, 21) - 0.5) * bw * 0.5)  # 줄마다 블록 폭이 다르다
		var lx := x - ox + int(Paint.hash01(row, 1, 22) * rw)
		var col := floori(float(lx) / rw)
		var bx := posmod(lx, rw)
		var by := posmod(ly, bh)
		var wob := int((p.nz("mid", x, y) - 0.5) * 3.0)
		if bx + wob < 2 or by + wob < 2:
			return p.vary(mortar, x, y, 0.2)
		var tone := base.lightened((Paint.hash01(row, col, 3) - 0.5) * 0.3)
		if by < 4 or bx < 4:
			tone = tone.lightened(0.14)
		elif by > bh - 4 or bx > rw - 4:
			tone = tone.darkened(0.22)
		tone = tone.darkened(p.nz("cell", x, y) * 0.12)
		return p.vary(tone, x, y, 0.2)


## 막돌(쌓은 자연석): 세포 잡음 경계 = 줄눈.
static func rubble(p: Paint, base: Color, mortar: Color = Color("#221f1b")) -> Callable:
	return func(x: int, y: int) -> Color:
		var e := p.nz("cell", x, y)
		if e < 0.06:
			return p.vary(mortar, x, y, 0.2)
		var c := base.lightened((Paint.hash01(int(p.nz("lo", x, y) * 40.0), int(e * 7.0)) - 0.5) * 0.2)
		if e < 0.12:
			c = c.darkened(0.3)
		c = c.darkened(p.nz("mid", x, y) * 0.15)
		return p.vary(c, x, y, 0.25)


## 판자: 세로(vertical) 또는 가로. 나뭇결(늘인 잡음) + 판자마다 색 + 틈.
static func planks(p: Paint, base: Color, ox: int, oy: int, vertical: bool = true, pw: int = 13) -> Callable:
	return func(x: int, y: int) -> Color:
		var along := y - oy if vertical else x - ox
		var across := x - ox if vertical else y - oy
		var idx := floori(float(across) / pw)
		var ax := posmod(across, pw)
		if ax == 0:
			return Color("#120d09")
		var tone := base.lightened((Paint.hash01(idx, 7) - 0.5) * 0.28)
		var grain := p.nz("vs" if vertical else "hs", x, y)
		tone = tone.darkened(absf(grain - 0.5) * 0.5)
		if ax == 1:
			tone = tone.lightened(0.1)
		elif ax == pw - 1:
			tone = tone.darkened(0.25)
		if Paint.hash01(idx, floori(along / 40.0), 11) > 0.93 and absf(ax - pw / 2.0) < 2.0:
			tone = tone.darkened(0.4)  # 옹이
		return p.vary(tone, x, y, 0.15)


## 들보(목조 뼈대): 짙은 나무 + 결.
static func beam(p: Paint, base: Color = Color("#2e2118")) -> Callable:
	return func(x: int, y: int) -> Color:
		var g := (p.nz("vs", x, y) + p.nz("hs", x, y)) * 0.5
		return p.vary(base.darkened(absf(g - 0.5) * 0.4), x, y, 0.2)


## 점판암 지붕: 줄마다 엇갈린 비늘, 아래 가장자리 그늘, 장마다 색, 이끼.
static func slate(p: Paint, base: Color, ox: int, oy: int, tw: int = 16, th: int = 10, moss: float = 0.3) -> Callable:
	return func(x: int, y: int) -> Color:
		var ly := y - oy
		var row := floori(float(ly) / th)
		var lx := x - ox + (tw / 2 if row % 2 != 0 else 0)
		var col := floori(float(lx) / tw)
		var by := posmod(ly, th)
		var bx := posmod(lx, tw)
		var tone := base.lightened((Paint.hash01(row, col, 5) - 0.5) * 0.25)
		if by >= th - 2:
			tone = tone.darkened(0.55)
		elif bx == 0:
			tone = tone.darkened(0.35)
		elif by == 0:
			tone = tone.lightened(0.08)
		var m := p.nz("lo", x, p.h - 1 - y)
		if moss > 0.0 and m > 1.0 - moss * 0.5:
			tone = tone.lerp(Color("#4c5530"), minf(0.8, (m - (1.0 - moss * 0.5)) * 4.0))
		return p.vary(tone, x, y, 0.18)


## 기와(점토): 아래가 둥근 비늘.
static func clay(p: Paint, base: Color, ox: int, oy: int, tw: int = 14, th: int = 11) -> Callable:
	return func(x: int, y: int) -> Color:
		var ly := y - oy
		var row := floori(float(ly) / th)
		var lx := x - ox + (tw / 2 if row % 2 != 0 else 0)
		var col := floori(float(lx) / tw)
		var by := posmod(ly, th)
		var bx := posmod(lx, tw)
		var tone := base.lightened((Paint.hash01(row, col, 9) - 0.5) * 0.3)
		var dx := (bx - tw / 2.0) / (tw / 2.0)
		var edge := th - 2 - int(dx * dx * 3.0)
		if by >= edge:
			tone = tone.darkened(0.55)
		elif bx < 2:
			tone = tone.darkened(0.2)
		else:
			tone = tone.lightened((1.0 - absf(dx)) * 0.1)
		return p.vary(tone, x, y, 0.2)


## 초가: 경사 방향 짚 줄무늬.
static func thatch(p: Paint, base: Color) -> Callable:
	return func(x: int, y: int) -> Color:
		var s := p.nz("vs", x, y)
		var c := base.darkened(absf(s - 0.5) * 0.7)
		if s > 0.7:
			c = c.lightened(0.12)
		return p.vary(c, x, y, 0.2)


## 유리: 위는 하늘빛 반사, 아래로 어두움. lit이면 따뜻한 안쪽 불빛.
static func glass(p: Paint, top: float, bottom: float, lit: bool) -> Callable:
	return func(x: int, y: int) -> Color:
		var t := clampf((y - top) / maxf(1.0, bottom - top), 0.0, 1.0)
		var c := Color("#e9b25c").lerp(Color("#9a4f1f"), t * 0.8) if lit else Color("#5a6458").lerp(Color("#121614"), t)
		if not lit and p.nz("mid", x, y) > 0.66:
			c = c.lightened(0.15)
		return p.vary(c, x, y, 0.15)
