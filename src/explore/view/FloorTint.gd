class_name FloorTint
extends RefCounted
## 거시 변화(docs/plans/map_design.md §4.3): 꼭짓점마다 곱할 색조 = 구역 색조(둘레 네 칸 평균) × 저주파 노이즈 밝기 ×
## 안전지대 둘레 어둡게(중심 기념비 공동 — ASSUMPTIONS AM5: 규칙은 그대로, 그림만 한 단계 어둡게).
## 층 JSON art.macro = {zones: {구역 id: 색}, noise: {freq, amount}, safe_dim: {radius, mult, falloff}}. 없으면 모두 흰색(변화 없음).
## 청크를 만들 때 그 청크 꼭짓점만 채운다(fill) — 지도 전체를 훑지 않는다.

var colors: PackedColorArray   ## (w+1)×(h+1) 꼭짓점 색조
var enabled: bool = false
var _map: FloorMap
var _zone_tint: PackedColorArray  # map.zone_ids 번호 -> 색조
var _noise: FastNoiseLite = null
var _amount: float = 0.0
var _dims: Array[Vector3] = []    # (중심 x, 중심 y, 반지름)
var _dim_mult: float = 1.0
var _dim_falloff: float = 4.0


func setup(map: FloorMap, floor_def: Dictionary) -> void:
	_map = map
	var macro := JsonUtil.get_dict(JsonUtil.get_dict(floor_def, "art"), "macro")
	enabled = not macro.is_empty()
	if not enabled:
		return
	colors = PackedColorArray()
	colors.resize((map.width + 1) * (map.height + 1))
	colors.fill(Color.WHITE)
	var zones := JsonUtil.get_dict(macro, "zones")
	_zone_tint = PackedColorArray()
	for id: String in map.zone_ids:
		_zone_tint.append(Color.from_string(JsonUtil.get_str(zones, id, "#ffffff"), Color.WHITE))
	var nz := JsonUtil.get_dict(macro, "noise")
	if not nz.is_empty():
		_noise = FastNoiseLite.new()
		_noise.seed = JsonUtil.get_int(JsonUtil.get_dict(floor_def, "fixed_map"), "seed", 1) + 4242
		_noise.frequency = JsonUtil.get_float(nz, "freq", 0.02)
		_noise.fractal_octaves = 3
		_amount = JsonUtil.get_float(nz, "amount", 0.1)
	var dim := JsonUtil.get_dict(macro, "safe_dim")
	if not dim.is_empty():
		_dim_mult = JsonUtil.get_float(dim, "mult", 1.0)
		_dim_falloff = maxf(0.1, JsonUtil.get_float(dim, "falloff", 4.0))
		for sz in map.safe_zones:
			var c: Vector2i = sz["center"]
			_dims.append(Vector3(c.x + 0.5, c.y + 0.5, JsonUtil.get_float(dim, "radius", 10.0)))


## 칸 사각형 cells를 둘러싼 꼭짓점의 색조를 채운다.
func fill(cells: Rect2i) -> void:
	if not enabled:
		return
	var r := cells.intersection(Rect2i(0, 0, _map.width, _map.height))
	var w := _map.width + 1
	for vy in range(r.position.y, r.end.y + 1):
		for vx in range(r.position.x, r.end.x + 1):
			colors[vy * w + vx] = at(vx, vy)


## 꼭짓점 (vx, vy)의 색조(fill 없이 바로 계산 — 테스트·도구용).
func at(vx: int, vy: int) -> Color:
	var c := Color(0, 0, 0)
	var n := 0
	for dy in 2:
		for dx in 2:
			var p := Vector2i(vx - 1 + dx, vy - 1 + dy)
			if _map.in_bounds(p):
				var z := _zone_tint[_map.zones[_map.idx(p)]] if not _zone_tint.is_empty() and _map.zones.size() > 0 else Color.WHITE
				c += z
				n += 1
	c = c / maxf(1.0, n) if n > 0 else Color.WHITE
	var k := 1.0
	if _noise != null:
		k += _noise.get_noise_2d(vx, vy) * _amount
	for d in _dims:
		var dist := Vector2(vx, vy).distance_to(Vector2(d.x, d.y))
		k *= lerpf(_dim_mult, 1.0, clampf((dist - d.z) / _dim_falloff, 0.0, 1.0))
	return Color(c.r * k, c.g * k, c.b * k, 1.0)
