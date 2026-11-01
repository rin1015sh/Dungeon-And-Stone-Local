extends SceneTree
## 균열 상자 그림(사용자 2026-11-01 "상자 일러스트 — 연 모습·닫힌 모습", V25):
##   godot --headless --path . --script res://tools/paint_chest.gd [-- --out=<폴더>]
## → assets/floor/chest/closed.webp(쇠띠 두른 나무 궤짝, 둥근 뚜껑, 놋쇠 자물쇠) · open.webp(뚜껑이 뒤로 젖혀진 빈 궤짝 — 안이 어둡다).
## 3/4 시점(탐험 맵 — 위에서 비스듬히, 빛은 왼쪽 위), 바닥 접점 = 그림 아래 끝 가까이(LootView._foot_y). 칠 부품은 균열 소품과 같다(rift/Kit — 상자·판자·그림자 + Ink 잉크).
## 그림은 맵 칸 그림 배율(2배)보다 크게(4배) 칠해 줄여 쓴다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")

const W := 256
const H := 224
const WOOD := Color("#5e4129")
const WOOD_IN := Color("#2a1c12")
const IRON := Color("#3b3a3a")
const BRASS := Color("#8c6d32")


func _init() -> void:
	var out := "res://assets/floor/chest"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	_closed().save(out + "/closed.webp", 0.9)
	_open().save(out + "/open.webp", 0.9)
	print("상자 그림 → ", out)
	quit()


## 몸통(앞·윗·옆) — 닫힘·열림 같다. 앞면 poly들을 돌려준다.
func _body(p: Paint, foot: Vector2, w: float, d: float, h: float) -> Dictionary:
	Kit.shadow(p, foot + Vector2(6, -4), w * 0.62, d * 0.32, 0.5)
	var b: Dictionary = Kit.box(p, foot, w, d, h, WOOD, 1.4, 0.1)
	Kit.planks(p, b["front"], 3, WOOD)
	_grain(p, b["front"])
	return b


## 나뭇결(가로 짧은 붓 자국).
func _grain(p: Paint, poly: PackedVector2Array) -> void:
	var r := Paint.bounds(poly)
	for i in 34:
		var x := r.position.x + p.rng.randf() * r.size.x
		var y := r.position.y + p.rng.randf() * r.size.y
		Ink.line(p, Vector2(x, y), Vector2(x + p.rng.randf_range(8, 22), y + p.rng.randf_range(-1, 1)), 0.9, WOOD.darkened(0.5), 0.35, 0.6)


## 세로 쇠띠(앞면 위에서 아래로) + 못.
func _strap(p: Paint, x: float, top: float, bottom: float, wd: float) -> void:
	var poly := Paint.rect_poly(x - wd * 0.5, top, wd, bottom - top)
	p.fill_poly(poly, func(px: int, py: int) -> Color: return p.vary(IRON.lightened(0.08 if px < x else 0.0), px, py, 0.08))
	Ink.path(p, poly, 1.2, true, Ink.INK, 0.8, 0.3)
	Ink.line(p, Vector2(x - wd * 0.5 + 1, top + 1), Vector2(x - wd * 0.5 + 1, bottom - 1), 1.0, Kit.LIT, 0.3, 0.2)
	var y := top + 6.0
	while y < bottom - 3.0:
		_rivet(p, Vector2(x, y))
		y += 11.0


func _rivet(p: Paint, c: Vector2) -> void:
	p.fill_poly(Paint.poly([c + Vector2(-2.2, 0), c + Vector2(0, -2.2), c + Vector2(2.2, 0), c + Vector2(0, 2.2)]),
		func(_x: int, _y: int) -> Color: return Color("#6a665e"))
	p.blend(int(c.x - 1), int(c.y - 1), Kit.LIT, 0.6)


## 모서리 쇠 덧댐(앞면 네 귀).
func _corners(p: Paint, front: PackedVector2Array) -> void:
	var r := Paint.bounds(front)
	var k := 12.0
	for c: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var sx := 1.0 if c.x < r.get_center().x else -1.0
		var sy := 1.0 if c.y < r.get_center().y else -1.0
		var poly := Paint.poly([c, c + Vector2(k * sx, 0), c + Vector2(0, k * sy)])
		p.fill_poly(poly, func(px: int, py: int) -> Color: return p.vary(IRON, px, py, 0.06))
		Ink.path(p, poly, 1.0, true, Ink.INK, 0.7, 0.2)


## 놋쇠 자물쇠판 + 열쇠 구멍.
func _lock(p: Paint, c: Vector2) -> void:
	var plate := Paint.poly([c + Vector2(-11, -12), c + Vector2(11, -12), c + Vector2(13, 6), c + Vector2(0, 15), c + Vector2(-13, 6)])
	p.fill_poly(plate, func(px: int, py: int) -> Color:
		var t := clampf((py - c.y + 12.0) / 27.0, 0.0, 1.0)
		return p.vary(BRASS.lightened(0.18 * (1.0 - t)).darkened(0.25 * t), px, py, 0.08))
	Ink.path(p, plate, 1.4, true, Ink.INK, 0.85, 0.3)
	p.fill_poly(Paint.poly([c + Vector2(-2.6, -3), c + Vector2(2.6, -3), c + Vector2(1.6, 5), c + Vector2(-1.6, 5)]), func(_x: int, _y: int) -> Color: return Color("#0c0806"))
	Ink.glow(p, c.x - 4, c.y - 7, 5.0, Color("#f0dca0"), 0.35)
	for v: Vector2 in [Vector2(-8, -8), Vector2(8, -8)]:
		_rivet(p, c + v)


## 닫힌 상자: 몸통 + 둥근 뚜껑(앞으로 불룩한 반원통 — 판자 줄) + 쇠띠 셋 + 자물쇠.
func _closed() -> Paint:
	var p := Paint.new(W, H, 41)
	var foot := Vector2(W * 0.48, H - 12.0)
	var w := 168.0
	var d := 92.0
	var h := 58.0
	var b := _body(p, foot, w, d, h)
	var dd := d * Kit.DEPTH
	var fl := foot + Vector2(-w * 0.5, -h)
	var fr := foot + Vector2(w * 0.5, -h)
	var back := Vector2(dd * 0.35, -dd)
	var bulge := 30.0  # 뚜껑 둥근 높이
	var lid := PackedVector2Array()  # 앞 가장자리(fl→fr) 위로 부푼 곡면을 뒤 가장자리까지 — 옆에서 본 반원
	var n := 18
	for i in n + 1:
		var t := float(i) / n
		var a := PI * t
		var off := Vector2(0, -sin(a) * bulge) + back * (0.5 - 0.5 * cos(a))
		lid.append(fl + off)
	for i in range(n, -1, -1):
		var t := float(i) / n
		var a := PI * t
		lid.append(fr + Vector2(0, -sin(a) * bulge) + back * (0.5 - 0.5 * cos(a)))
	p.fill_poly(lid, func(x: int, y: int) -> Color:
		var t := clampf((y - (fl.y - bulge - dd)) / (bulge + dd), 0.0, 1.0)
		return p.vary(WOOD.lightened(0.24 - t * 0.3), x, y, 0.1))
	for k in range(1, 5):  # 뚜껑 판자 줄(곡면을 따라 가로)
		var a := PI * k / 5.0
		var off := Vector2(0, -sin(a) * bulge) + back * (0.5 - 0.5 * cos(a))
		Ink.line(p, fl + off + Vector2(2, 0), fr + off - Vector2(2, 0), 1.0, WOOD.darkened(0.6), 0.55, 0.5)
	var side_cap := PackedVector2Array()  # 뚜껑 오른쪽 옆면(그늘 반원)
	for i in n + 1:
		var a := PI * float(i) / n
		side_cap.append(fr + Vector2(0, -sin(a) * bulge) + back * (0.5 - 0.5 * cos(a)))
	p.fill_poly(side_cap, func(x: int, y: int) -> Color: return p.vary(WOOD.darkened(0.5), x, y, 0.08))
	Ink.path(p, lid, 1.8, true, Ink.INK, 0.85, 0.4)
	Ink.line(p, fl + Vector2(2, -1), fr + Vector2(-2, -1), 2.0, Ink.INK, 0.8, 0.3)  # 뚜껑 이음 틈
	for sx: float in [-0.36, 0.0, 0.36]:  # 쇠띠: 앞면 + 뚜껑 곡면을 넘어간다
		var x := foot.x + w * sx
		_strap(p, x, foot.y - h, foot.y, 11.0)
		var band := PackedVector2Array()
		for i in n + 1:
			var a := PI * float(i) / n
			band.append(Vector2(x - 5.5, fl.y) + Vector2(0, -sin(a) * bulge) + back * (0.5 - 0.5 * cos(a)))
		for i in range(n, -1, -1):
			var a := PI * float(i) / n
			band.append(Vector2(x + 5.5, fl.y) + Vector2(0, -sin(a) * bulge) + back * (0.5 - 0.5 * cos(a)))
		p.fill_poly(band, func(px: int, py: int) -> Color: return p.vary(IRON.lightened(0.1), px, py, 0.08))
		Ink.path(p, band, 1.1, true, Ink.INK, 0.7, 0.3)
	_corners(p, b["front"])
	_lock(p, Vector2(foot.x, foot.y - h + 4.0))
	Ink.grime(p, foot.x - w * 0.5, foot.y - 14.0, w, 12.0, 0.35)
	Ink.grade(p, 0.18, 1.08, Color("#1a1412"), Color("#e0d2b0"))
	return p


## 열린 상자: 뚜껑이 뒤로 젖혀져 섰다(안쪽 판이 보인다) · 몸통 윗면 = 어두운 빈 속.
func _open() -> Paint:
	var p := Paint.new(W, H, 42)
	var foot := Vector2(W * 0.48, H - 12.0)
	var w := 168.0
	var d := 92.0
	var h := 58.0
	var dd := d * Kit.DEPTH
	var back := Vector2(dd * 0.35, -dd)
	var bl := foot + Vector2(-w * 0.5, -h) + back  # 뒤 가장자리 왼쪽
	var br := foot + Vector2(w * 0.5, -h) + back
	var lid_h := 62.0  # 젖힌 뚜껑(안쪽 면 — 위로 서서 살짝 뒤로)
	var lean := Vector2(10, -lid_h)
	var lid := PackedVector2Array([bl, br, br + lean + Vector2(4, 0), bl + lean + Vector2(-4, 0)])
	Kit.shadow(p, foot + Vector2(6, -4), w * 0.62, d * 0.32, 0.5)
	p.fill_poly(lid, func(x: int, y: int) -> Color:
		var t := clampf((bl.y - y) / lid_h, 0.0, 1.0)
		return p.vary(WOOD.darkened(0.35 - t * 0.15), x, y, 0.1))
	Kit.planks(p, lid, 4, WOOD)
	for sx: float in [-0.36, 0.0, 0.36]:  # 뚜껑 안쪽 쇠띠 끝
		var x := bl.x + (br.x - bl.x) * (0.5 + sx)
		var poly := PackedVector2Array([Vector2(x - 5, bl.y), Vector2(x + 5, bl.y), Vector2(x + 5 + lean.x * 0.95, bl.y + lean.y * 0.95), Vector2(x - 5 + lean.x * 0.95, bl.y + lean.y * 0.95)])
		p.fill_poly(poly, func(px: int, py: int) -> Color: return p.vary(IRON, px, py, 0.08))
		Ink.path(p, poly, 1.0, true, Ink.INK, 0.6, 0.3)
	Ink.path(p, lid, 1.8, true, Ink.INK, 0.85, 0.4)
	var b := _body(p, foot, w, d, h)
	var inner := PackedVector2Array()  # 빈 속(윗면 안쪽, 테두리 두께만큼 줄임)
	var top: PackedVector2Array = b["top"]
	var cen := Paint.bounds(top).get_center()
	for v in top:
		inner.append(cen + (v - cen) * 0.86)
	p.fill_poly(inner, func(x: int, y: int) -> Color:
		var t := clampf((y - Paint.bounds(inner).position.y) / maxf(1.0, Paint.bounds(inner).size.y), 0.0, 1.0)
		return p.vary(WOOD_IN.lerp(Color("#0c0806"), 0.4 + t * 0.4), x, y, 0.06))
	Ink.path(p, inner, 1.2, true, Ink.INK, 0.8, 0.3)
	for sx: float in [-0.36, 0.0, 0.36]:
		_strap(p, foot.x + w * sx, foot.y - h, foot.y, 11.0)
	_corners(p, b["front"])
	var c := Vector2(foot.x, foot.y - h + 4.0)  # 열린 자물쇠 고리(판만, 걸쇠는 뚜껑과 함께 올라갔다)
	var plate := Paint.poly([c + Vector2(-11, -2), c + Vector2(11, -2), c + Vector2(13, 6), c + Vector2(0, 15), c + Vector2(-13, 6)])
	p.fill_poly(plate, func(px: int, py: int) -> Color: return p.vary(BRASS.darkened(0.15), px, py, 0.08))
	Ink.path(p, plate, 1.3, true, Ink.INK, 0.85, 0.3)
	Ink.grime(p, foot.x - w * 0.5, foot.y - 14.0, w, 12.0, 0.35)
	Ink.grade(p, 0.18, 1.08, Color("#1a1412"), Color("#e0d2b0"))
	return p
