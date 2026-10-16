class_name CaveDecor
extends RefCounted
## 공동 안쪽 꾸밈(CrossTerrain이 굴을 다 판 뒤 부른다): 석순 기둥(바위)·수정 무리·지하 호수(연못 물)·바위.
## 큰 공동(grand)·공동(cavern)에만, 공동 윤곽 안쪽(depth)에만 둔다 → 둘레로 늘 돌아갈 수 있다.
## 등뼈 길 둘레 keep_clear칸(keep)엔 두지 않는다 → 나침반 경로가 막히지 않는다.
## 꾸밈 칸은 벽(1)으로 바꾸고 팔 수 없음(allowed 0)으로 표시해 뒤의 벽 깎기·폭 맞추기가 지우지 않게 한다.
## 돌려줌: {"crystal": [칸 번호], "pond": […], "boulder": […]} — 바위 기둥은 그냥 바위벽이라 따로 적지 않는다.
## 값은 floors/*.json gen.chambers.decor.


static func build(carver: CaveCarver, chambers: Array[Dictionary], keep: PackedByteArray, cfg: Dictionary, rng: Rng) -> Dictionary:
	var crystal: Array[int] = []
	var pond: Array[int] = []
	var boulder: Array[int] = []
	var ponds := JsonUtil.get_dict(cfg, "pond_chance")
	for ch in chambers:
		var kind := str(ch["kind"])
		if kind != "grand" and kind != "cavern":
			continue
		if rng.chance(JsonUtil.get_float(ponds, kind)):
			_pond(carver, ch, keep, cfg, rng, pond)
		_pillars(carver, ch, keep, cfg, rng, crystal)
		_boulders(carver, ch, keep, cfg, rng, boulder)
	return {"crystal": crystal, "pond": pond, "boulder": boulder}


## 꾸밈 칸을 지도 타일로(생성기가 부른다): 수정 무리(암흑지대 둘레면 바위로 남김)·지하 호수·바위.
static func apply(map: FloorMap, lay: CrossLayout, g: Dictionary, decor: Dictionary) -> void:
	var tiles := JsonUtil.get_dict(g, "tiles")
	var no_light := lay.no_light_mask(map, JsonUtil.get_int(g, "crystal_dark_margin", 3))
	var crystal := map.index_of(JsonUtil.get_str(tiles, "crystal"))
	for i: int in decor.get("crystal", []):
		if no_light[i] == 0:
			map.tiles[i] = crystal
	var pond := map.index_of(JsonUtil.get_str(tiles, "pond", "pond_water"))
	for i: int in decor.get("pond", []):
		map.tiles[i] = pond
	var boulder := map.index_of(JsonUtil.get_str(tiles, "boulder", "boulder"))
	for i: int in decor.get("boulder", []):
		map.tiles[i] = boulder


## 등뼈 길 칸(spine)을 radius칸 넓힌 표시(1 = 꾸밈 금지).
static func keep_mask(spine: Array[int], w: int, h: int, radius: int) -> PackedByteArray:
	var keep := PackedByteArray()
	keep.resize(w * h)
	for i in spine:
		var x := i % w
		var y := i / w
		for yy in range(maxi(0, y - radius), mini(h, y + radius + 1)):
			for xx in range(maxi(0, x - radius), mini(w, x + radius + 1)):
				keep[yy * w + xx] = 1
	return keep


## 지하 호수: 공동 안쪽에 울퉁불퉁한 타원 하나(공동 반지름 × pond_ratio).
static func _pond(carver: CaveCarver, ch: Dictionary, keep: PackedByteArray, cfg: Dictionary, rng: Rng, into: Array[int]) -> void:
	var ratio := JsonUtil.get_array(cfg, "pond_ratio")
	var r := float(ch["radius"]) * (rng.randf_range(float(ratio[0]), float(ratio[1])) if ratio.size() == 2 else 0.3)
	var c: Vector2 = (ch["c"] as Vector2) + Vector2.from_angle(rng.randf_range(0.0, TAU)) * float(ch["radius"]) * rng.randf_range(0.0, 0.25)
	var lake := {"lobes": [{"c": c, "rx": r, "ry": r * rng.randf_range(0.55, 0.9), "angle": rng.randf_range(0.0, PI),
		"harm": [[2, rng.randf_range(0.0, 0.15), rng.randf_range(0.0, TAU)], [3, rng.randf_range(0.0, 0.1), rng.randf_range(0.0, TAU)]]}]}
	var max_depth := JsonUtil.get_float(cfg, "pond_max_depth", 0.62)
	var k := ceili(r) + 1
	var start := into.size()
	for y in range(int(c.y) - k, int(c.y) + k + 1):
		for x in range(int(c.x) - k, int(c.x) + k + 1):
			var p := Vector2(x, y)
			if CaveChambers.inside(lake, p, 1.0) and CaveChambers.depth(ch, p) <= max_depth:
				_block(carver, Vector2i(x, y), keep, into)
	if into.size() - start < JsonUtil.get_int(cfg, "pond_min_cells", 12):
		for n in range(start, into.size()):  # 물웅덩이 몇 칸은 통로만 좁힌다 → 되돌린다
			carver.cells[into[n]] = 0
			carver.allowed[into[n]] = 1
		into.resize(start)


## 석순 기둥: 넓이 100칸당 pillars_per_100개, 서로 pillar_spacing칸 이상. crystal_ratio는 빛나는 수정 무리(생성기가 암흑지대면 바위로).
static func _pillars(carver: CaveCarver, ch: Dictionary, keep: PackedByteArray, cfg: Dictionary, rng: Rng, crystals: Array[int]) -> void:
	var n := int(CaveChambers.area(ch) / 100.0 * JsonUtil.get_float(cfg, "pillars_per_100", 0.5))
	var rr := JsonUtil.get_array(cfg, "pillar_radius")
	var spacing := JsonUtil.get_float(cfg, "pillar_spacing", 6.0)
	var max_depth := JsonUtil.get_float(cfg, "pillar_max_depth", 0.65)
	var placed: Array[Vector2] = []
	var none: Array[int] = []
	for attempt in n * 6:
		if placed.size() >= n:
			break
		var p := (ch["c"] as Vector2) + Vector2.from_angle(rng.randf_range(0.0, TAU)) * float(ch["reach"]) * sqrt(rng.randf())
		if CaveChambers.depth(ch, p) > max_depth or not carver.is_floor(Vector2i(p)):
			continue
		if placed.any(func(q: Vector2) -> bool: return q.distance_to(p) < spacing):
			continue
		var r := rng.randf_range(float(rr[0]), float(rr[1])) if rr.size() == 2 else 1.2
		if _touches_keep(Vector2i(p), ceili(r) + 1, keep, carver.w, carver.h):
			continue
		placed.append(p)
		var lit := rng.chance(JsonUtil.get_float(cfg, "crystal_ratio", 0.3))
		var k := ceili(r)
		for dy in range(-k, k + 1):
			for dx in range(-k, k + 1):
				var q := Vector2i(p) + Vector2i(dx, dy)
				if Vector2(dx, dy).length() <= r + rng.randf_range(-0.3, 0.3):
					_block(carver, q, keep, crystals if lit else none)


## 바위: 공동 가장자리 쪽(boulder_depth 사이)에 1~2칸짜리.
static func _boulders(carver: CaveCarver, ch: Dictionary, keep: PackedByteArray, cfg: Dictionary, rng: Rng, into: Array[int]) -> void:
	var n := int(CaveChambers.area(ch) / 100.0 * JsonUtil.get_float(cfg, "boulders_per_100", 0.3))
	var band := JsonUtil.get_array(cfg, "boulder_depth")
	for attempt in n * 6:
		if n <= 0:
			break
		var p := (ch["c"] as Vector2) + Vector2.from_angle(rng.randf_range(0.0, TAU)) * float(ch["reach"]) * sqrt(rng.randf())
		var d := CaveChambers.depth(ch, p)
		if band.size() != 2 or d < float(band[0]) or d > float(band[1]) or not carver.is_floor(Vector2i(p)):
			continue
		if _touches_keep(Vector2i(p), 2, keep, carver.w, carver.h):
			continue
		n -= 1
		_block(carver, Vector2i(p), keep, into)
		if rng.chance(0.5):
			_block(carver, Vector2i(p) + Vector2i(1, 0) if rng.chance(0.5) else Vector2i(p) + Vector2i(0, 1), keep, into)


## 바닥 칸 하나를 꾸밈(벽)으로. 등뼈 길 둘레·이미 벽인 칸은 그대로.
static func _block(carver: CaveCarver, q: Vector2i, keep: PackedByteArray, into: Array[int]) -> void:
	if not carver.is_floor(q) or not carver.can(q):
		return
	var i := q.y * carver.w + q.x
	if keep[i] != 0:
		return
	carver.cells[i] = 1
	carver.allowed[i] = 0
	into.append(i)


static func _touches_keep(c: Vector2i, r: int, keep: PackedByteArray, w: int, h: int) -> bool:
	for y in range(maxi(0, c.y - r), mini(h, c.y + r + 1)):
		for x in range(maxi(0, c.x - r), mini(w, c.x + r + 1)):
			if keep[y * w + x] != 0:
				return true
	return false
