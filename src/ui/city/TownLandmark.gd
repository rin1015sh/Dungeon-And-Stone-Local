class_name TownLandmark
extends RefCounted
## 도시 동네 지도의 시설 건물 그림(CT82): 신전(고딕 — 첨탑 둘·장미창) · 도서관(원형 열람당 — 원통 벽 + 유리 돔, 사용자 2026-11-02 "원형이 예쁠듯") ·
## 나머지 시설은 상자 집(TownHouse.draw_box) 위에 큰 문과 꾸밈(길드 깃발·은행 기둥·여관 간판·잡화점 아치와 차양·대장간 화덕 불빛)을 덧그린다.
## 좌표는 TownHouse 로컬(앞면 아래 끝 y = 0).


static func _c(h: TownHouse, key: String, i: int = 0) -> Color:
	return TownBrush.col(h.render, key, i)


## 시설 꾸밈(상자 집 위).
static func dress(b: TownBrush, h: TownHouse) -> void:
	var fac := str(h.house.get("facility", ""))
	if fac.is_empty():
		return
	var f := h.front()
	var door: Vector2i = h.house["door"]
	var cx := (door.x + 0.5) * h.tile
	var storey := TownBrush.num(h.render, "storey_px", 34.0)
	var base := TownBrush.num(h.render, "base_px", 6.0)
	match str(h.house.get("style", "")):
		"stone":
			var n := maxi(3, int(f.size.x / 48.0))
			for k in n + 1:
				var px := f.position.x + 4 + (f.size.x - 8) * float(k) / n
				b.rect_v(Rect2(px - 4, f.position.y + 4, 8, f.size.y - 4), TownBrush.shade(_c(h, "stone"), 1.18), TownBrush.shade(_c(h, "stone"), 0.9), "ashlar")
			b.poly(PackedVector2Array([Vector2(cx - 30, -base - storey - 2), Vector2(cx + 30, -base - storey - 2), Vector2(cx, -base - storey - 22)]), TownBrush.shade(_c(h, "stone"), 1.15), "ashlar")
			_door(b, h, cx, base, 22.0, storey + 2, false)
			b.rect(Rect2(cx - 20, -base, 40, base), TownBrush.shade(_c(h, "stone"), 1.1), "slabs")
		"hall":
			_door(b, h, cx, base, 24.0, storey, true)
			for side: float in [-1.0, 1.0]:
				var bx := cx + side * 46.0
				b.rect_v(Rect2(bx - 7, -base - storey * 2.6, 14, storey * 1.4), _c(h, "awning"), TownBrush.shade(_c(h, "awning"), 0.7), "wood")
				b.poly(PackedVector2Array([Vector2(bx - 7, -base - storey * 1.2), Vector2(bx + 7, -base - storey * 1.2), Vector2(bx, -base - storey * 1.05)]), TownBrush.shade(_c(h, "awning"), 0.7))
			_sign(b, h, cx + 22, -base - storey + 4)
		"inn":
			_door(b, h, cx, base, 18.0, storey - 4, true)
			_sign(b, h, cx + 18, -base - storey + 2)
			b.ellipse(Vector2(cx - 15, -base - storey * 0.75), Vector2(9, 9), Color(_c(h, "lamp"), 0.25))
			b.rect(Rect2(cx - 17, -base - storey * 0.85, 4, 6), _c(h, "lamp"))
		"arcade":
			var n := maxi(3, int(f.size.x / 44.0))
			b.rect_v(Rect2(f.position.x, -base - storey - 6, f.size.x, 9), _c(h, "awning"), TownBrush.shade(_c(h, "awning"), 0.65), "wood")
			for k in n:
				var ax := f.position.x + f.size.x * (k + 0.5) / n
				_arch(b, h, ax, base, minf(30.0, f.size.x / n - 8.0), storey - 6)
		"workshop":
			var w := 34.0
			b.rect(Rect2(cx - w * 0.5 - 3, -base - storey - 3, w + 6, storey + 3), TownBrush.shade(_c(h, "stone"), 0.8), "ashlar")
			b.rect_v(Rect2(cx - w * 0.5, -base - storey, w, storey + base), Color(0.08, 0.06, 0.05), Color(0.42, 0.2, 0.08))
			b.ellipse(Vector2(cx, -base - 6), Vector2(w * 0.7, 10), Color(_c(h, "lamp"), 0.18))
			var rc: Rect2i = h.house["rect"]
			for k in 2:
				var chx := f.position.x + f.size.x * (0.25 + 0.5 * k)
				var top := -h.height() - rc.size.y * h.tile * 0.5 - 6
				b.rect_v(Rect2(chx - 8, top - 30, 16, 34), TownBrush.shade(_c(h, "brick"), 1.05), TownBrush.shade(_c(h, "brick"), 0.7), "ashlar")
				b.rect(Rect2(chx - 10, top - 34, 20, 5), TownBrush.shade(_c(h, "brick"), 0.55))
		_:
			_door(b, h, cx, base, 18.0, storey - 4, false)


static func _door(b: TownBrush, h: TownHouse, cx: float, base: float, w: float, ht: float, arch: bool) -> void:
	var pts := TownLandmark.arch_pts(cx, -base, w + 6, ht + 4) if arch else PackedVector2Array([Vector2(cx - w * 0.5 - 3, -base), Vector2(cx - w * 0.5 - 3, -base - ht - 4), Vector2(cx + w * 0.5 + 3, -base - ht - 4), Vector2(cx + w * 0.5 + 3, -base)])
	b.poly(pts, TownBrush.shade(_c(h, "stone"), 0.95), "ashlar")
	var inner := TownLandmark.arch_pts(cx, -base, w, ht) if arch else PackedVector2Array([Vector2(cx - w * 0.5, -base), Vector2(cx - w * 0.5, -base - ht), Vector2(cx + w * 0.5, -base - ht), Vector2(cx + w * 0.5, -base)])
	b.poly(inner, _c(h, "door"), "wood")
	b.line(Vector2(cx, -base), Vector2(cx, -base - ht + 2), 1.5, TownBrush.shade(_c(h, "door"), 0.5))


static func _sign(b: TownBrush, h: TownHouse, x: float, y: float) -> void:
	b.rect(Rect2(x, y - 2, 16, 2.5), _c(h, "iron"))
	b.rect_v(Rect2(x + 3, y + 1, 12, 10), _c(h, "cloth"), TownBrush.shade(_c(h, "cloth"), 0.7), "wood")


static func _arch(b: TownBrush, h: TownHouse, cx: float, base: float, w: float, ht: float) -> void:
	b.poly(TownLandmark.arch_pts(cx, -base, w + 6, ht + 3), TownBrush.shade(_c(h, "stone"), 1.05), "ashlar")
	b.poly(TownLandmark.arch_pts(cx, -base, w, ht), Color(0.07, 0.06, 0.05))


## 아치(반원 머리) 볼록 다각형 — 아래 가운데 (cx, bottom).
static func arch_pts(cx: float, bottom: float, w: float, ht: float, pointed: bool = false) -> PackedVector2Array:
	var r := w * 0.5
	var pts := PackedVector2Array([Vector2(cx - r, bottom)])
	var spring := bottom - ht + (r * (1.3 if pointed else 1.0))
	for i in 9:
		var a := PI + PI * float(i) / 8.0
		var p := Vector2(cx + cos(a) * r, spring + sin(a) * r * (1.3 if pointed else 1.0))
		if pointed and i == 4:
			p.y -= r * 0.25
		pts.append(p)
	pts.append(Vector2(cx + r, bottom))
	return pts


## 도서관 — 원형 열람당: 원통 벽(왼쪽이 밝다 · 아치 창과 기둥) + 처마 고리 + 유리 돔(납 갈빗대) + 꼭대기 등.
static func rotunda(b: TownBrush, h: TownHouse) -> void:
	var c: Array = h.house["circle"]
	var R := float(c[2]) * h.tile
	var ctr := Vector2(float(c[0]) * h.tile, float(c[1]) * h.tile - h.position.y)
	var hd := h.height()
	var stone := _c(h, "stone")
	var n := 40
	for i in n / 2:  # 원통 벽 앞쪽 반(조각마다 빛)
		var a0 := PI * float(i) / (n / 2)
		var a1 := PI * float(i + 1) / (n / 2)
		var k := 0.78 + 0.32 * -cos((a0 + a1) * 0.5)
		var p0 := ctr + Vector2(cos(a0), sin(a0)) * R
		var p1 := ctr + Vector2(cos(a1), sin(a1)) * R
		b.poly_cols(PackedVector2Array([p0, p1, p1 - Vector2(0, hd), p0 - Vector2(0, hd)]),
			PackedColorArray([TownBrush.shade(stone, k * 0.8), TownBrush.shade(stone, k * 0.8), TownBrush.shade(stone, k), TownBrush.shade(stone, k)]), "ashlar")
	var storey := TownBrush.num(h.render, "storey_px", 34.0)
	for i in 9:  # 아치 창(가장자리일수록 좁다)
		var a := PI * (float(i) + 0.5) / 9.0
		var sx := absf(sin(a))
		var p := ctr + Vector2(cos(a), sin(a)) * R
		for fl in 2:
			var w := 12.0 * sx
			var y := p.y - hd + 14 + fl * (storey + 6)
			b.poly(TownLandmark.arch_pts(p.x, y + storey - 4, w + 3, storey - 4), TownBrush.shade(stone, 1.2))
			b.poly(TownLandmark.arch_pts(p.x, y + storey - 5, w, storey - 7), _c(h, "glass_lit" if (i + fl) % 4 == 1 else "glass"))
	var door: Vector2i = h.house["door"]
	var dx := (door.x + 0.5) * h.tile
	for side: float in [-1.0, 1.0]:  # 문 앞 기둥 둘 + 박공
		b.rect_v(Rect2(dx + side * 22 - 4, -storey * 1.5, 8, storey * 1.5), TownBrush.shade(stone, 1.25), TownBrush.shade(stone, 0.95), "ashlar")
	b.poly(PackedVector2Array([Vector2(dx - 32, -storey * 1.5), Vector2(dx + 32, -storey * 1.5), Vector2(dx, -storey * 1.5 - 20)]), TownBrush.shade(stone, 1.2), "ashlar")
	_door(b, h, dx, 0.0, 20.0, storey + 4, true)
	var top := ctr - Vector2(0, hd)
	b.ellipse(top, Vector2(R + 5, R + 5), TownBrush.shade(stone, 0.95), "ashlar", 48)  # 처마 고리
	b.ellipse(top + Vector2(0, 4), Vector2(R + 5, R + 2), Color(0, 0, 0, 0.0), "", 48)
	var rd := R * 0.5
	var lead := _c(h, "lead")
	var steps := 8
	for s in steps:  # 돔: 바깥 고리부터(높이 = 반구) — 위로 갈수록 밝다(흐린 하늘빛)
		var rho := R * (1.0 - float(s) / steps)
		var lift := rd * sqrt(maxf(0.0, 1.0 - pow(rho / R, 2.0)))
		var k := 0.85 + 0.55 * float(s) / steps
		var pane := lead.lerp(_c(h, "frame"), 0.18) if s % 2 == 0 else lead
		b.ellipse(top - Vector2(0, lift), Vector2(rho, rho), TownBrush.shade(pane, k), "lead", 40)
	for j in 12:  # 갈빗대
		var a := TAU * float(j) / 12.0
		var prev := top + Vector2(cos(a), sin(a)) * R
		for s in range(1, steps + 1):
			var rho := R * (1.0 - float(s) / steps)
			var lift := rd * sqrt(maxf(0.0, 1.0 - pow(rho / R, 2.0)))
			var q := top - Vector2(0, lift) + Vector2(cos(a), sin(a)) * rho
			b.line(prev, q, 2.5, TownBrush.shade(lead, 0.6))
			prev = q
	var apex := top - Vector2(0, rd)
	b.rect_v(Rect2(apex.x - 8, apex.y - 16, 16, 16), TownBrush.shade(stone, 1.1), TownBrush.shade(stone, 0.8), "ashlar")
	b.rect(Rect2(apex.x - 4, apex.y - 12, 8, 8), _c(h, "glass_lit"))
	b.poly(PackedVector2Array([Vector2(apex.x - 11, apex.y - 15), Vector2(apex.x + 11, apex.y - 15), Vector2(apex.x, apex.y - 30)]), TownBrush.shade(lead, 0.9), "lead")


## 신전 — 고딕: 가파른 박공 지붕 · 앞면(부벽·뾰족 창·장미창·큰 문) · 앞 모서리 탑 둘과 첨탑.
static func gothic(b: TownBrush, h: TownHouse) -> void:
	var rc: Rect2i = h.house["rect"]
	var x0 := rc.position.x * h.tile
	var x1 := rc.end.x * h.tile
	var xm := (x0 + x1) * 0.5
	var hgt := h.height()
	var deep := rc.size.y * h.tile
	var rise := minf((x1 - x0) * 0.32, 230.0)
	var slate := _c(h, "slate", 1)
	var stone := _c(h, "stone_dark")
	var tw := 5.0 * h.tile
	b.poly_cols(PackedVector2Array([Vector2(x0 + tw - 6, -hgt + 2), Vector2(xm, -hgt - rise), Vector2(xm, -hgt - rise - deep), Vector2(x0 + tw - 6, -hgt - deep)]),
		PackedColorArray([TownBrush.shade(slate, 1.0), TownBrush.shade(slate, 1.15), TownBrush.shade(slate, 1.0), TownBrush.shade(slate, 0.9)]), "slate")
	b.poly_cols(PackedVector2Array([Vector2(xm, -hgt - rise), Vector2(x1 - tw + 6, -hgt + 2), Vector2(x1 - tw + 6, -hgt - deep), Vector2(xm, -hgt - rise - deep)]),
		PackedColorArray([TownBrush.shade(slate, 0.75), TownBrush.shade(slate, 0.68), TownBrush.shade(slate, 0.58), TownBrush.shade(slate, 0.66)]), "slate")
	b.line(Vector2(xm, -hgt - rise), Vector2(xm, -hgt - rise - deep), 3.0, TownBrush.shade(slate, 0.45))
	var bx0 := x0 + tw
	var bx1 := x1 - tw
	b.rect_v(Rect2(bx0, -hgt, bx1 - bx0, hgt), TownBrush.shade(stone, 1.05), TownBrush.shade(stone, 0.78), "ashlar")
	b.poly_cols(PackedVector2Array([Vector2(bx0, -hgt), Vector2(bx1, -hgt), Vector2(xm, -hgt - rise * ((bx1 - bx0) / (x1 - x0)) - 6)]),
		PackedColorArray([stone, stone, TownBrush.shade(stone, 1.1)]), "ashlar")
	var storey := TownBrush.num(h.render, "storey_px", 34.0)
	b.ellipse(Vector2(xm, -hgt + 8), Vector2(26, 26), TownBrush.shade(stone, 1.2), "ashlar")  # 장미창
	b.ellipse(Vector2(xm, -hgt + 8), Vector2(20, 20), _c(h, "glass_lit").lerp(_c(h, "awning"), 0.4))
	for j in 8:
		var a := TAU * j / 8.0
		b.line(Vector2(xm, -hgt + 8), Vector2(xm, -hgt + 8) + Vector2(cos(a), sin(a)) * 20, 2.0, TownBrush.shade(stone, 0.6))
	for side: float in [-1.0, 1.0]:
		for k in 2:
			var wx := xm + side * (70.0 + k * 90.0)
			b.poly(TownLandmark.arch_pts(wx, -24, 22, hgt - 60, true), TownBrush.shade(stone, 1.2))
			b.poly(TownLandmark.arch_pts(wx, -26, 16, hgt - 64, true), _c(h, "glass"))
			b.rect_v(Rect2(wx + side * 45 - 6, -hgt + 20, 12, hgt - 20), TownBrush.shade(stone, 1.15), TownBrush.shade(stone, 0.8), "ashlar")  # 부벽
	b.poly(TownLandmark.arch_pts(xm, 0, 54, storey * 2.2, true), TownBrush.shade(stone, 1.25), "ashlar")
	b.poly(TownLandmark.arch_pts(xm, 0, 40, storey * 2.0, true), _c(h, "door"), "wood")
	b.line(Vector2(xm, 0), Vector2(xm, -storey * 1.8), 2.0, TownBrush.shade(_c(h, "door"), 0.5))
	for tx: float in [x0, x1 - tw]:  # 탑 둘
		var th := hgt + storey * 3.0
		var tc := tx + tw * 0.5
		b.rect_v(Rect2(tx, -th, tw, th), TownBrush.shade(stone, 1.12), TownBrush.shade(stone, 0.8), "ashlar")
		b.line(Vector2(tx, -th), Vector2(tx, 0), 2.0, _c(h, "ink"))
		b.line(Vector2(tx + tw, -th), Vector2(tx + tw, 0), 2.0, _c(h, "ink"))
		for fl in 3:
			var wy := -th + 26 + fl * storey * 1.4
			b.poly(TownLandmark.arch_pts(tc, wy + storey, 18, storey, true), TownBrush.shade(stone, 1.25))
			b.poly(TownLandmark.arch_pts(tc, wy + storey - 1, 12, storey - 4, true), _c(h, "glass") if fl > 0 else Color(0.05, 0.05, 0.05))
		b.rect(Rect2(tx - 4, -th - 6, tw + 8, 8), TownBrush.shade(stone, 1.2), "ashlar")
		var sp := tw * 1.6
		b.poly(PackedVector2Array([Vector2(tx - 2, -th - 6), Vector2(tc, -th - 6 - sp), Vector2(tc, -th - 6)]), TownBrush.shade(_c(h, "lead"), 1.05), "lead")
		b.poly(PackedVector2Array([Vector2(tc, -th - 6), Vector2(tc, -th - 6 - sp), Vector2(tx + tw + 2, -th - 6)]), TownBrush.shade(_c(h, "lead"), 0.7), "lead")
		b.line(Vector2(tc, -th - 6 - sp), Vector2(tc, -th - 20 - sp), 2.0, _c(h, "iron"))
