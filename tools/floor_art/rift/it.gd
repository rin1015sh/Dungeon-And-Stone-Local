extends RefCounted
## 균열 그림(임시 틀 — 장소 그림은 아직): Common.gd 계약대로 바탕·잔손질·소품·뒷배경을 칠한다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const Common := preload("res://tools/floor_art/rift/Common.gd")


static func base(p: Paint, _style: String, part: String, col: Color, s: int) -> void:
	var f := Seam.field(p.w, p.h, s, 0.05, 3)
	var main := p.h - (Common.skirt if part == "face" else 0)
	for y in p.h:
		for x in p.w:
			if y >= main:
				continue
			p.blend(x, y, col.darkened(0.3).lerp(col.lightened(0.2), f[y * p.w + x]), 1.0)


static func detail(_p: Paint, _style: String, _part: String, _v: int, _col: Color) -> void:
	pass


static func stand(_tile: String, w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	var foot := Vector2(w * 0.5, h - w * 0.14)
	Kit.shadow(p, foot, w * 0.22, w * 0.07)
	Kit.box(p, foot, w * 0.4, w * 0.3, w * 0.3, Color("#7a6a5a"))
	return p


static func backdrop(w: int, h: int, seed_value: int) -> Paint:
	var p := Paint.new(w, h, seed_value)
	for y in h:
		for x in w:
			p.blend(x, y, Color("#100c0c").lerp(Color("#3a2a2a"), float(y) / h), 1.0)
	return p
