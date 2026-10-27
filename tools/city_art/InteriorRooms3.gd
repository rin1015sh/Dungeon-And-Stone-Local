extends RefCounted
## 시설 내부 셋째 묶음(알미너스 중앙 거래소, 2026-10-27 CT54) — InteriorRooms와 같은 문법: 방을 칠하고 광원 목록을 돌려준다(Interiors.light).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Npc := preload("res://tools/city_art/Npcs.gd")

const WARM := Color("#ffc874")
const DAY := Color("#dfe8ff")
const GOLD := Color("#c9a24a")
const MARBLE := Color("#b9b2a2")


## 거래소: 대리석 벽과 기둥 · 뒷벽 높은 아치 창 셋(빛줄기) · 가운데 큰 시세판(칸마다 분필 눈금) · 놋쇠 창살 창구가 늘어선 긴 계산대 ·
## 계산대 위 큰 저울과 마석 더미 · 샹들리에 둘 · 창구 안 서기 · 체크무늬 대리석 바닥.
static func exchange(p: Paint) -> Array:
	var I := _I()
	I.room(p, Mat.ashlar(p, MARBLE, 170, 110, 60, 26, Color("#5a554c")), Mat.ashlar(p, MARBLE.darkened(0.1), 0, 0, 70, 30, Color("#4a463e")),
		Bits.checker_shader(p), p.flat(Color("#2a2620"), 0.2))
	for wx: float in [196.0, 486.0]:  # 높은 아치 창
		var win := Paint.arch_poly(wx, 128, 38, 120)
		p.fill_poly(win, Mat.glass(p, 128, 248, false))
		Ink.line(p, Vector2(wx + 19, 132), Vector2(wx + 19, 248), 2.0, Color("#2a2620"), 0.9, 0.2)
		Ink.path(p, win, 2.2)
		I.shaft(p, Vector2(wx + 4, 140), Vector2(wx + 34, 140), Vector2(wx - 60, 520), Vector2(wx + 40, 520), DAY, 0.12)
	var board := Paint.rect_poly(262, 124, 196, 132)  # 시세판
	p.fill_poly(board, p.flat(Color("#1f2a26"), 0.15))
	Ink.path(p, Paint.rect_poly(256, 118, 208, 144), 5.0, true, GOLD.darkened(0.25), 1.0, 0.1)
	for r in 6:
		var y := 136.0 + r * 20.0
		Ink.line(p, Vector2(272, y), Vector2(330, y), 1.6, Color("#d8d2c0"), 0.7, 0.4)
		for k in 3:
			var x := 350.0 + k * 34.0
			Ink.line(p, Vector2(x, y), Vector2(x + 14 + p.rng.randf() * 10.0, y), 1.6, Color("#e6c46a") if (r + k) % 3 == 0 else Color("#d8d2c0"), 0.75, 0.3)
	for s: float in [1.35]:
		for bx: float in [178.0, 542.0]:
			Bits.column(p, I.pt(Vector2(bx, 110), s), I.pt(Vector2(bx, 330), s), 22.0 * s)
	Npc.figure(p, 300, 440, 180, {"body": "male", "top": Color("#2e3446"), "bottom": Color("#262a36"), "collar": Color("#e0d8c4"), "arms": "counter", "hands_v": 0.5,
		"hair": "short", "hair_c": Color("#3a2c22"), "glasses": true, "light": 1.0})
	I.box(p, 30, 366, 700, 124, 30, Mat.planks(p, Color("#3a2618"), 30, 366, true, 24), p.flat(MARBLE.lightened(0.1), 0.1))
	for k in 4:  # 놋쇠 창살 창구
		var x0 := 70.0 + k * 160.0
		for b in 6:
			Ink.line(p, Vector2(x0 + b * 14.0, 262), Vector2(x0 + b * 14.0, 358), 2.4, GOLD.darkened(0.15), 1.0, 0.1)
		var arch := PackedVector2Array()
		for a in 13:
			arch.append(Vector2(x0 + 35, 262) + Vector2.from_angle(PI + PI * a / 12.0) * Vector2(38, 22))
		Ink.path(p, arch, 3.0, false, GOLD, 1.0, 0.1)
		Ink.line(p, Vector2(x0 - 4, 358), Vector2(x0 + 74, 358), 3.0, GOLD, 1.0, 0.1)
	Bits.scale(p, Vector2(520, 362))
	for i in 9:  # 마석 더미(보랏빛 조각)
		var q := Vector2(430 + p.rng.randf_range(-22, 22), 360 - (i % 3) * 5.0)
		var gem := Paint.poly([q + Vector2(-5, 0), q + Vector2(0, -9), q + Vector2(5, 0), q + Vector2(0, 3)])
		p.fill_poly(gem, p.flat(Color("#8a64c8"), 0.2))
		Ink.path(p, gem, 0.9, true, Ink.INK, 0.7)
	Ink.glow(p, 430, 352, 34, Color("#b090ff"), 0.3)
	Bits.coins(p, Vector2(180, 362))
	Bits.open_book(p, Vector2(330, 360), 28)
	for c: Vector2 in [Vector2(250, 60), Vector2(470, 60)]:
		Bits.chandelier(p, c, 46)
	return [[Vector2(250, 80), 300.0, WARM, 0.75], [Vector2(470, 80), 300.0, WARM, 0.7], [Vector2(360, 190), 260.0, DAY, 0.35],
		[Vector2(430, 350), 120.0, Color("#b090ff"), 0.35]]


static func _I() -> GDScript:
	return load("res://tools/city_art/Interiors.gd")
