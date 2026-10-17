class_name FloorDecor
extends RefCounted
## 탐험 맵 데칼 배치(docs/plans/map_design.md §4.2 "왜 여기 있는가") — 층 JSON art.decor:
##   {sheet, variants, kinds[](시트 줄 순서), on_tiles[](데칼을 얹는 바닥 타일), spots[], rules[]}
##   rule = {kind, chance, dense, size, zones[], near_tiles {tiles[], radius}, wall_north, near_features {ids[], radius},
##           noise {key, freq, above}, orient: "toward"(near_tiles 쪽으로 돌림)}
##   spot = {at: [x, y], radius, kind, chance, dense} — 손으로 정한 자리(이끼 물웅덩이 등). 규칙보다 먼저.
## 칸 좌표·지도에서만 결정된다(같은 칸 = 늘 같은 데칼). dense가 아니면 3×3 이웃 중 해시가 가장 큰 칸만 후보(포아송 원판 근사 —
## 맞닿은 두 칸에 함께 놓이지 않는다). 청크를 만들 때 그 청크만 계산한다(지도 전체는 도구·테스트만 — all()).
## 데칼은 그림만: 걷기·충돌·동굴 요소에 영향 없음(동굴 요소 칸·on_tiles가 아닌 칸에는 놓이지 않는다).

const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]  ## rot 0 북 · 1 동 · 2 남 · 3 서

var map: FloorMap
var sheet: String = ""
var variants: int = 1
var kinds: PackedStringArray = PackedStringArray()
var _on: PackedByteArray          # map.defs 번호 -> 데칼을 얹는 타일이면 1
var _rules: Array[Rule] = []
var _spots: Array[Rule] = []
var _noise: Dictionary = {}       # 노이즈 키 -> FastNoiseLite
var _sets: Array[PackedByteArray] = []  # 서로 다른 near_tiles 묶음(같은 묶음은 거리 계산을 한 번만)
var _set_reach: PackedInt32Array = PackedInt32Array()
var _reach: int = 1               # 가장 먼 near 반경
var _feature_cells: Dictionary = {}  # 동굴 요소 칸(함정처럼 바닥 타일인 것도) — 데칼을 놓지 않는다


## 규칙 하나(사전보다 빠르게 읽으려고 타입 있는 필드로).
class Rule:
	var kind: int = 0
	var chance: float = 1.0
	var dense: bool = false
	var size: float = 1.0
	var salt: int = 0
	var wall_north: bool = false
	var toward: bool = false
	var zones: PackedByteArray = PackedByteArray()  # map.zone_ids 번호 -> 1(비면 구역 조건 없음)
	var set_index: int = -1                          # _sets 번호(-1 = near_tiles 없음)
	var near_r: int = 0
	var feat_ids: PackedStringArray = PackedStringArray()
	var feat_r: int = 0
	var noise: FastNoiseLite = null
	var above: float = 0.0
	var at: Vector2i = Vector2i.ZERO                 # spot 가운데
	var radius: float = 0.0                          # spot 반지름


static func compile(map: FloorMap, floor_def: Dictionary) -> FloorDecor:
	var d := FloorDecor.new()
	d.map = map
	var cfg := JsonUtil.get_dict(JsonUtil.get_dict(floor_def, "art"), "decor")
	d.sheet = JsonUtil.get_str(cfg, "sheet")
	d.variants = maxi(1, JsonUtil.get_int(cfg, "variants", 1))
	for k: Variant in JsonUtil.get_array(cfg, "kinds"):
		d.kinds.append(str(k))
	for f in map.features:
		d._feature_cells[f["pos"]] = true
	d._on = PackedByteArray()
	d._on.resize(map.defs.size())
	var on_tiles := JsonUtil.get_array(cfg, "on_tiles")
	for i in map.defs.size():
		d._on[i] = 1 if on_tiles.has(map.defs[i].id) else 0
	var seed_value := JsonUtil.get_int(JsonUtil.get_dict(floor_def, "fixed_map"), "seed", 1)
	for r: Variant in JsonUtil.get_array(cfg, "rules"):
		var rd := d._compile_rule(r as Dictionary, seed_value, d._rules.size())
		if rd != null:
			d._rules.append(rd)
	for s: Variant in JsonUtil.get_array(cfg, "spots"):
		var sd := d._compile_rule(s as Dictionary, seed_value, d._rules.size())
		var at := JsonUtil.get_array(s as Dictionary, "at")
		if sd != null and at.size() == 2:
			sd.at = Vector2i(int(at[0]), int(at[1]))
			sd.radius = JsonUtil.get_float(s as Dictionary, "radius", 3.0)
			d._spots.append(sd)
	return d


func is_empty() -> bool:
	return kinds.is_empty() or (_rules.is_empty() and _spots.is_empty())


func _compile_rule(r: Dictionary, seed_value: int, order: int) -> Rule:
	var kind := kinds.find(JsonUtil.get_str(r, "kind"))
	if kind < 0:
		return null
	var out := Rule.new()
	out.kind = kind
	out.chance = JsonUtil.get_float(r, "chance", 1.0)
	out.dense = JsonUtil.get_bool(r, "dense")
	out.size = JsonUtil.get_float(r, "size", 1.0)
	out.salt = JsonUtil.get_str(r, "kind").hash() + order * 7919
	out.wall_north = JsonUtil.get_bool(r, "wall_north")
	out.toward = JsonUtil.get_str(r, "orient") == "toward"
	var zones := JsonUtil.get_array(r, "zones")
	if not zones.is_empty():
		out.zones.resize(map.zone_ids.size())
		for i in map.zone_ids.size():
			out.zones[i] = 1 if zones.has(map.zone_ids[i]) else 0
	var nt := JsonUtil.get_dict(r, "near_tiles")
	if not nt.is_empty():
		var set := PackedByteArray()
		set.resize(map.defs.size())
		for t: Variant in JsonUtil.get_array(nt, "tiles"):
			var i := map.index_of(str(t))
			if i >= 0:
				set[i] = 1
		out.near_r = JsonUtil.get_int(nt, "radius", 1)
		out.set_index = _sets.find(set)
		if out.set_index < 0:
			out.set_index = _sets.size()
			_sets.append(set)
			_set_reach.append(0)
		_set_reach[out.set_index] = maxi(_set_reach[out.set_index], out.near_r)
		_reach = maxi(_reach, out.near_r)
	var nf := JsonUtil.get_dict(r, "near_features")
	if not nf.is_empty():
		out.feat_ids = PackedStringArray(JsonUtil.get_array(nf, "ids"))
		out.feat_r = JsonUtil.get_int(nf, "radius", 3)
	var nz := JsonUtil.get_dict(r, "noise")
	if not nz.is_empty():
		var key := JsonUtil.get_str(nz, "key", "wet")
		if not _noise.has(key):
			var n := FastNoiseLite.new()
			n.seed = key.hash() ^ seed_value
			n.frequency = JsonUtil.get_float(nz, "freq", 0.04)
			n.fractal_octaves = 3
			_noise[key] = n
		out.noise = _noise[key]
		out.above = JsonUtil.get_float(nz, "above", 0.6)
	return out


## 칸 사각형 rect 안의 데칼들: [{pos, kind(시트 줄), v(변형), rot(0~3 — 90° 단위, 그림 위쪽이 가리키는 방향), flip, size, off(칸 단위 흔들림)}].
func cells(rect: Rect2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var r := rect.intersection(Rect2i(0, 0, map.width, map.height))
	if not r.has_area() or is_empty():
		return out
	var ext := r.grow(_reach).intersection(Rect2i(0, 0, map.width, map.height))
	var dist: Array[PackedInt32Array] = []
	for si in _sets.size():
		dist.append(_distance(ext, _sets[si], _set_reach[si]))
	var feats := _features_in(r.grow(8))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var i := y * map.width + x
			if _on[map.tiles[i]] == 0:
				continue
			var p := Vector2i(x, y)
			if _feature_cells.has(p):
				continue
			var zone := map.zones[i] if map.zones.size() > i else 0
			var di := (y - ext.position.y) * ext.size.x + (x - ext.position.x)
			var picked: Rule = null
			for sd in _spots:
				if Vector2(p).distance_to(Vector2(sd.at)) <= sd.radius and _passes(sd, p):
					picked = sd
					break
			if picked == null:
				for rd in _rules:
					if _matches(rd, p, zone, di, dist, feats) and _passes(rd, p):
						picked = rd
						break
			if picked != null:
				out.append(_entry(picked, p))
	return out


## 지도 전체(도구·테스트 — FloorArtCheck decor 모양).
func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var step := 64
	for cy in range(0, map.height, step):
		for cx in range(0, map.width, step):
			for e in cells(Rect2i(cx, cy, step, step)):
				out.append({"pos": e["pos"], "blocks": false, "kind": e["kind"]})
	return out


func _matches(rd: Rule, p: Vector2i, zone: int, di: int, dist: Array[PackedInt32Array], feats: Array[Dictionary]) -> bool:
	if not rd.zones.is_empty() and (zone >= rd.zones.size() or rd.zones[zone] == 0):
		return false
	if rd.wall_north and not map.is_wall(p + Vector2i(0, -1)):
		return false
	if rd.set_index >= 0 and dist[rd.set_index][di] > rd.near_r:
		return false
	if rd.toward and _side(rd, p) < 0:  # 방향이 있는 데칼(물가)은 상하좌우로 맞닿은 칸에만
		return false
	if not rd.feat_ids.is_empty():
		var ok := false
		for f in feats:
			var fp: Vector2i = f["pos"]
			if absi(fp.x - p.x) <= rd.feat_r and absi(fp.y - p.y) <= rd.feat_r and rd.feat_ids.has(str(f["id"])):
				ok = true
				break
		if not ok:
			return false
	if rd.noise != null and (rd.noise.get_noise_2d(p.x, p.y) + 1.0) * 0.5 < rd.above:
		return false
	return true


## 확률·간격(dense가 아니면 3×3 이웃 중 해시 최대 칸만). 싼 확률 검사를 먼저 한다.
func _passes(rd: Rule, p: Vector2i) -> bool:
	if float(_h(p, rd.salt + 1) % 10000) / 10000.0 >= rd.chance:
		return false
	if not rd.dense:
		var mine := _h(p, rd.salt)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if (dx != 0 or dy != 0) and _h(p + Vector2i(dx, dy), rd.salt) >= mine:
					return false
	return true


func _entry(rd: Rule, p: Vector2i) -> Dictionary:
	var h := _h(p, rd.salt + 2)
	var rot := (h >> 4) & 3
	var off := Vector2(float(h % 97) / 97.0 - 0.5, float((h >> 8) % 89) / 89.0 - 0.5) * 0.24
	if rd.toward and _side(rd, p) >= 0:  # near_tiles 쪽으로 돌리고 그쪽으로 밀어 그 칸의 직선 가장자리를 덮는다
		rot = _side(rd, p)
		off = Vector2(DIRS[rot]) * 0.28
	return {"pos": p, "kind": rd.kind, "v": h % variants, "rot": rot, "flip": ((h >> 7) & 1) == 1, "size": rd.size, "off": off}


## p와 상하좌우로 맞닿은 near_tiles 칸의 방향(DIRS 번호, 없으면 -1).
func _side(rd: Rule, p: Vector2i) -> int:
	if rd.set_index < 0:
		return -1
	var set := _sets[rd.set_index]
	for k in 4:
		var q: Vector2i = p + DIRS[k]
		if map.in_bounds(q) and set[map.tiles[q.y * map.width + q.x]] != 0:
			return k
	return -1


## ext 안에서 set 타일까지의 칸 거리(8방향 걸음, 최대 cap+1).
func _distance(ext: Rect2i, set: PackedByteArray, cap: int) -> PackedInt32Array:
	var w := ext.size.x
	var d := PackedInt32Array()
	d.resize(w * ext.size.y)
	d.fill(cap + 1)
	var queue: Array[Vector2i] = []
	for y in range(ext.position.y, ext.end.y):
		for x in range(ext.position.x, ext.end.x):
			if set[map.tiles[y * map.width + x]] != 0:
				d[(y - ext.position.y) * w + (x - ext.position.x)] = 0
				queue.append(Vector2i(x, y))
	var head := 0
	while head < queue.size():
		var q := queue[head]
		head += 1
		var dq := d[(q.y - ext.position.y) * w + (q.x - ext.position.x)]
		if dq >= cap:
			continue
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n := q + Vector2i(dx, dy)
				if not ext.has_point(n):
					continue
				var j := (n.y - ext.position.y) * w + (n.x - ext.position.x)
				if d[j] > dq + 1:
					d[j] = dq + 1
					queue.append(n)
	return d


func _features_in(r: Rect2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in map.features:
		if r.has_point(f["pos"]):
			out.append(f)
	return out


static func _h(p: Vector2i, salt: int) -> int:
	return absi(hash(Vector3i(p.x, p.y, salt)))
