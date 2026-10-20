class_name LightField
extends RefCounted
## 정적 광원(수정벽·포탈·기념비 등 빛나는 타일)의 빛을 꼭짓점 격자((w+1)×(h+1))에 미리 계산한다.
## 그리기에서 칸 네 모서리의 색을 이 값으로 섞어 부드러운 빛 번짐을 만든다(셰이더 없이).

var width: int = 0   ## 꼭짓점 격자 너비 = map.width + 1
var height: int = 0
var colors: PackedColorArray


static func build(map: FloorMap, meters_per_tile: float) -> LightField:
	var f := LightField.new()
	f.width = map.width + 1
	f.height = map.height + 1
	f.colors = PackedColorArray()
	f.colors.resize(f.width * f.height)
	f.colors.fill(Color(0, 0, 0, 0))
	# 빛나는 타일 종류마다 엔진의 find로 칸을 찾는다(큰 지도의 모든 칸을 스크립트로 훑지 않게).
	# 칸 순서(위→아래, 왼→오른)대로 더해야 색 합이 예전과 똑같으므로 찾은 칸을 모아 정렬한다.
	var found := PackedInt32Array()
	for def in map.defs:
		if not def.emits_light():
			continue
		var i := map.tiles.find(def.index)
		while i >= 0:
			if map.dark[i] == 0:
				found.append(i)
			i = map.tiles.find(def.index, i + 1)
	found.sort()
	for i in found:
		var def := map.defs[map.tiles[i]]
		f._add_light(map.pos_of(i), def.light_radius_m / maxf(meters_per_tile, 0.01), def.light_color, def.light_intensity)
	return f


## 칸 하나가 빛나는 타일이 됐을 때(균열 포탈 등) 그 빛만 더한다 — 큰 지도에서 build를 다시 부르면 수백 ms가 걸린다.
func add_cell(map: FloorMap, cell: Vector2i, meters_per_tile: float) -> void:
	var i := map.idx(cell)
	var def := map.defs[map.tiles[i]]
	if def.emits_light() and map.dark[i] == 0:
		_add_light(cell, def.light_radius_m / maxf(meters_per_tile, 0.01), def.light_color, def.light_intensity)


## 타일이 아닌 빛 하나(균열 길목 — RiftPassage). radius는 칸 단위.
func add_point(cell: Vector2i, radius: float, color: Color, intensity: float) -> void:
	_add_light(cell, radius, color, intensity)


## 꼭짓점 (vx, vy)의 정적 빛.
func at(vx: int, vy: int) -> Color:
	if vx < 0 or vy < 0 or vx >= width or vy >= height:
		return Color(0, 0, 0, 0)
	return colors[vy * width + vx]


func _add_light(cell: Vector2i, radius: float, color: Color, intensity: float) -> void:
	var c := Vector2(cell) + Vector2(0.5, 0.5)
	var r := ceili(radius) + 1
	for vy in range(maxi(0, cell.y - r), mini(height, cell.y + r + 2)):
		for vx in range(maxi(0, cell.x - r), mini(width, cell.x + r + 2)):
			var d := Vector2(vx, vy).distance_to(c)
			if d >= radius:
				continue
			var k := 1.0 - d / radius
			var i := vy * width + vx
			var cur := colors[i]
			colors[i] = Color(cur.r + color.r * k * k * intensity, cur.g + color.g * k * k * intensity,
				cur.b + color.b * k * k * intensity, 1.0)
