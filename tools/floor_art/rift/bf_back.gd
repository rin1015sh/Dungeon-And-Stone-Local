extends RefCounted
const Paint := preload("res://tools/city_art/Paint.gd")
static func paint(w: int, h: int, s: int) -> Paint:
	return Paint.new(w, h, s)
