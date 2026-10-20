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
	var opq := PackedByteArray()  # 타일 종류마다 시야를 막는가(칸마다 함수를 부르지 않게 — 넓은 시야에서 수십 ms였다)
	opq.resize(map.defs.size())
	for d in map.defs:
		opq[d.index] = 1 if d.blocks_sight else 0
	for oct in 8:
		_cast(map, opq, out, origin, 1, 1.0, 0.0, radius, MULT[0][oct], MULT[1][oct], MULT[2][oct], MULT[3][oct])
	return out


static func _cast(map: FloorMap, opq: PackedByteArray, out: PackedByteArray, origin: Vector2i, row: int, start: float, end: float,
		radius: float, xx: int, xy: int, yx: int, yy: int) -> void:
	if start < end:
		return
	var r2 := radius * radius
	var w := map.width
	var h := map.height
	var tiles := map.tiles
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
			var px := origin.x + dx * xx + dy * xy
			var py := origin.y + dx * yx + dy * yy
			var inside := px >= 0 and py >= 0 and px < w and py < h
			if inside and dx * dx + dy * dy <= r2:
				out[py * w + px] = 1
			var opaque := not inside or opq[tiles[py * w + px]] != 0  # 지도 밖은 시야를 막는다
			if blocked:
				if opaque:
					new_start = r_slope
					continue
				blocked = false
				start = new_start
			elif opaque and j < radius:
				blocked = true
				_cast(map, opq, out, origin, j + 1, start, l_slope, radius, xx, xy, yx, yy)
				new_start = r_slope
		if blocked:
			break
