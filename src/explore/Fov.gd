class_name Fov
extends RefCounted
## 시야 계산: 재귀 그림자 투사(recursive shadowcasting, 8분면).
## 시야를 막는 칸(벽)은 그 자체는 보이고 뒤를 가린다. 반경은 칸 단위(원형).

const MULT := [
	[1, 0, 0, -1, -1, 0, 0, 1],
	[0, 1, -1, 0, 0, -1, 1, 0],
	[0, 1, 1, 0, 0, -1, -1, 0],
	[1, 0, 0, 1, -1, 0, 0, -1],
]


## 보이는 칸 = 1인 배열(map 크기).
static func compute(map: FloorMap, origin: Vector2i, radius: float) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(map.width * map.height)
	if not map.in_bounds(origin):
		return out
	out[map.idx(origin)] = 1
	if radius <= 0.0:
		return out
	for oct in 8:
		_cast(map, out, origin, 1, 1.0, 0.0, radius, MULT[0][oct], MULT[1][oct], MULT[2][oct], MULT[3][oct])
	return out


static func _cast(map: FloorMap, out: PackedByteArray, origin: Vector2i, row: int, start: float, end: float,
		radius: float, xx: int, xy: int, yx: int, yy: int) -> void:
	if start < end:
		return
	var r2 := radius * radius
	var new_start := 0.0
	for j in range(row, ceili(radius) + 1):
		var dx := -j - 1
		var dy := -j
		var blocked := false
		while dx <= 0:
			dx += 1
			var l_slope := (dx - 0.5) / (dy + 0.5)
			var r_slope := (dx + 0.5) / (dy - 0.5)
			if start < r_slope:
				continue
			if end > l_slope:
				break
			var p := Vector2i(origin.x + dx * xx + dy * xy, origin.y + dx * yx + dy * yy)
			if dx * dx + dy * dy <= r2 and map.in_bounds(p):
				out[map.idx(p)] = 1
			var opaque := map.blocks_sight(p)
			if blocked:
				if opaque:
					new_start = r_slope
					continue
				blocked = false
				start = new_start
			elif opaque and j < radius:
				blocked = true
				_cast(map, out, origin, j + 1, start, l_slope, radius, xx, xy, yx, yy)
				new_start = r_slope
		if blocked:
			break
